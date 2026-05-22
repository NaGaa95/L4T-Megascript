#!/bin/bash

function error {
  echo -e "\\e[91m$1\\e[39m"
  sleep 3
  exit 1
}

clear -x
echo "Starship (Star Fox 64 port) script started!"
echo "Source: https://github.com/HarbourMasters/Starship"
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
    SDL2-devel SDL2_net-devel libpng-devel libzip-devel libzip-tools \
    nlohmann-json-devel tinyxml2-devel spdlog-devel mesa-libGL-devel \
    boost-devel libogg-devel libvorbis-devel \
    || error "Could not install dependencies!"
  ;;
*)
  echo -e "\\e[91mUnknown distro detected - install Starship dependencies manually\\e[39m"
  sleep 5
  ;;
esac

echo "Cloning Starship..."
cd ~
git clone https://github.com/HarbourMasters/Starship.git
cd Starship
git pull || error "Could not pull latest source"
git submodule update --init --recursive || error "Could not update submodules"

rom_path="$HOME/Starship/baserom.z64"
if [ ! -f "$rom_path" ]; then
  echo
  echo -e "\\e[93m=== Game ROM required ===\\e[39m"
  echo "Place your legally-owned Star Fox 64 ROM here, renamed to baserom.z64:"
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

echo "Building Starship..."
cmake --build build-cmake -j$(nproc) || error "Build failed"

binary="$HOME/Starship/build-cmake/Starship"
[ -x "$binary" ] || error "Build did not produce a Starship binary at $binary"

install_dir="$HOME/.local/share/l4t-megascript/starship"
rm -rf "$install_dir"
mkdir -p "$install_dir" || error "Could not create install directory"
cp -aL "$HOME/Starship/build-cmake/." "$install_dir/" \
  || error "Could not copy Starship runtime files"
find "$install_dir" -type d -name CMakeFiles -prune -exec rm -rf {} + 2>/dev/null || true
find "$install_dir" -type f \( -name CMakeCache.txt -o -name cmake_install.cmake -o -name build.ninja -o -name rules.ninja -o -name .ninja_deps -o -name .ninja_log \) -delete 2>/dev/null || true
[ -x "$install_dir/Starship" ] || error "Install did not produce a Starship binary at $install_dir/Starship"

sudo tee /usr/local/bin/starship >/dev/null <<'EOF'
#!/bin/sh
cd "$HOME/.local/share/l4t-megascript/starship" && exec ./Starship "$@"
EOF
sudo chmod 755 /usr/local/bin/starship

sudo install -Dm644 "$HOME/Starship/logo.png" /usr/share/pixmaps/starship.png

sudo tee /usr/local/share/applications/starship.desktop >/dev/null <<EOF
[Desktop Entry]
Type=Application
Name=Starship
Exec=/usr/local/bin/starship
Icon=starship
Comment=PC port of Star Fox 64
Terminal=false
Categories=Game;
StartupWMClass=Starship
EOF

echo "Done!"
echo "Sending you back to the main menu..."
sleep 5
