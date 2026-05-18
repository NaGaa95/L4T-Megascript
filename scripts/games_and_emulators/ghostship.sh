#!/bin/bash

function error {
  echo -e "\\e[91m$1\\e[39m"
  sleep 3
  exit 1
}

clear -x
echo "Ghostship (Super Mario 64 port) script started!"
echo "Source: https://github.com/HarbourMasters/Ghostship"
sleep 3

echo "Installing dependencies..."

case "$__os_id" in
Raspbian | Debian | Ubuntu)
  sudo apt install -y gcc g++ git cmake ninja-build lsb-release \
    libsdl2-dev libsdl2-net-dev libpng-dev libzip-dev zipcmp zipmerge ziptool \
    nlohmann-json3-dev libtinyxml2-dev libspdlog-dev libopengl-dev \
    libboost-dev libogg-dev libvorbis-dev \
    || error "Could not install dependencies"
  ;;
Fedora)
  sudo dnf install -y --refresh @development-tools git cmake ninja-build lsb_release \
    SDL2-devel libpng-devel libzip-devel libzip-tools \
    nlohmann-json-devel tinyxml2-devel spdlog-devel boost-devel \
    libogg-devel libvorbis-devel \
    || error "Could not install dependencies!"
  ;;
*)
  echo -e "\\e[91mUnknown distro detected - install Ghostship dependencies manually\\e[39m"
  sleep 5
  ;;
esac

echo "Cloning Ghostship..."
cd ~
git clone https://github.com/HarbourMasters/Ghostship.git
cd Ghostship
git pull || error "Could not pull latest source"
git submodule update --init --recursive || error "Could not update submodules"

rom_path="$HOME/Ghostship/baserom.us.z64"
if [ ! -f "$rom_path" ]; then
  echo
  echo -e "\\e[93m=== Game ROM required ===\\e[39m"
  echo "Place your legally-owned Super Mario 64 (NTSC-US) ROM here, renamed to baserom.us.z64:"
  echo "  $rom_path"
  echo
  read -rp "Press Enter when the ROM is in place..."
  [ -f "$rom_path" ] || error "ROM not found at $rom_path"
fi

echo "Configuring CMake..."
cmake -H. -Bbuild-cmake -GNinja -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON \
  -DCMAKE_C_FLAGS=-mcpu=native \
  -DCMAKE_CXX_FLAGS=-mcpu=native \
  || error "CMake configure failed"

echo "Extracting game assets..."
cmake --build build-cmake --target ExtractAssets \
  || error "Asset extraction failed (incompatible ROM?)"

echo "Generating port assets..."
cmake --build build-cmake --target GeneratePortO2R \
  || error "Port asset generation failed"

echo "Building Ghostship..."
cmake --build build-cmake -j$(nproc) || error "Build failed"

binary="$HOME/Ghostship/build-cmake/Ghostship"
[ -x "$binary" ] || error "Build did not produce a Ghostship binary at $binary"

sudo tee /usr/local/bin/ghostship >/dev/null <<'EOF'
#!/bin/sh
cd "$HOME/Ghostship/build-cmake" && exec ./Ghostship "$@"
EOF
sudo chmod 755 /usr/local/bin/ghostship

sudo install -Dm644 "$HOME/Ghostship/logo.png" /usr/share/pixmaps/ghostship.png

sudo tee /usr/local/share/applications/ghostship.desktop >/dev/null <<EOF
[Desktop Entry]
Type=Application
Name=Ghostship
Exec=/usr/local/bin/ghostship
Icon=ghostship
Comment=PC port of Super Mario 64
Terminal=false
Categories=Game;
StartupWMClass=Ghostship
EOF

echo "Done!"
echo "Sending you back to the main menu..."
sleep 5
