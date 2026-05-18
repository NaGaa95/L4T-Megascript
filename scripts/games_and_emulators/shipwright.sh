#!/bin/bash

function error {
  echo -e "\\e[91m$1\\e[39m"
  sleep 3
  exit 1
}

clear -x
echo "Ship of Harkinian (Ocarina of Time port) script started!"
echo "Source: https://github.com/HarbourMasters/Shipwright"
sleep 3

echo "Installing dependencies..."

case "$__os_id" in
Raspbian | Debian | Ubuntu)
  sudo apt install -y gcc g++ git cmake ninja-build lsb-release \
    libsdl2-dev libsdl2-net-dev libpng-dev libzip-dev zipcmp zipmerge ziptool \
    nlohmann-json3-dev libtinyxml2-dev libspdlog-dev libopengl-dev \
    libopusfile-dev libvorbis-dev \
    || error "Could not install dependencies"
  ;;
Fedora)
  sudo dnf install -y --refresh @development-tools git cmake ninja-build lsb_release \
    SDL2-devel SDL2_net-devel libpng-devel libzip-devel libzip-tools \
    nlohmann-json-devel tinyxml2-devel spdlog-devel mesa-libGL-devel \
    opusfile-devel libvorbis-devel \
    || error "Could not install dependencies!"
  ;;
*)
  echo -e "\\e[91mUnknown distro detected - install Shipwright dependencies manually\\e[39m"
  sleep 5
  ;;
esac

echo "Cloning Shipwright..."
cd ~
git clone https://github.com/HarbourMasters/Shipwright.git
cd Shipwright
git pull || error "Could not pull latest source"
git submodule update --init --recursive || error "Could not update submodules"

otr_dir="$HOME/Shipwright/OTRExporter"
mkdir -p "$otr_dir"
if ! ls "$otr_dir"/*.{z64,n64,v64} 2>/dev/null | grep -q .; then
  echo
  echo -e "\\e[93m=== Game ROM required ===\\e[39m"
  echo "Place your legally-owned Ocarina of Time ROM (any z64/n64/v64) here:"
  echo "  $otr_dir/"
  echo
  read -rp "Press Enter when the ROM is in place..."
  ls "$otr_dir"/*.{z64,n64,v64} 2>/dev/null | grep -q . \
    || error "No ROM found in $otr_dir"
fi

echo "Configuring CMake..."
cmake -H. -Bbuild-cmake -GNinja -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON \
  -DCMAKE_C_FLAGS=-mcpu=native \
  -DCMAKE_CXX_FLAGS=-mcpu=native \
  || error "CMake configure failed"

echo "Extracting game assets..."
cmake --build build-cmake --target GenerateSohOtr \
  || error "Asset extraction failed (incompatible ROM?)"

echo "Building Shipwright..."
cmake --build build-cmake -j$(nproc) || error "Build failed"

binary="$HOME/Shipwright/build-cmake/soh/soh.elf"
[ -x "$binary" ] || error "Build did not produce a soh.elf binary at $binary"

sudo tee /usr/local/bin/shipwright >/dev/null <<'EOF'
#!/bin/sh
cd "$HOME/Shipwright/build-cmake/soh" && exec ./soh.elf "$@"
EOF
sudo chmod 755 /usr/local/bin/shipwright

sudo install -Dm644 "$HOME/Shipwright/soh/macosx/sohIcon.png" \
  /usr/share/pixmaps/shipwright.png

sudo tee /usr/local/share/applications/shipwright.desktop >/dev/null <<EOF
[Desktop Entry]
Type=Application
Name=Ship of Harkinian
Exec=/usr/local/bin/shipwright
Icon=shipwright
Comment=PC port of The Legend of Zelda: Ocarina of Time
Terminal=false
Categories=Game;
StartupWMClass=soh.elf
EOF

echo "Done!"
echo "Sending you back to the main menu..."
sleep 5
