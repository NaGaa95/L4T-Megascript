#!/bin/bash

function error {
  echo -e "\\e[91m$1\\e[39m"
  sleep 3
  exit 1
}

clear -x
echo "Xash3D FWGS (Half-Life engine reimplementation) script started!"
echo "Source: https://github.com/FWGS/xash3d-fwgs"
sleep 3

echo "Installing dependencies..."

case "$__os_id" in
Raspbian | Debian | Ubuntu)
  sudo apt install -y git build-essential cmake python3 libsdl2-dev libfreetype6-dev \
    libopus-dev libbz2-dev libvorbis-dev libopusfile-dev libogg-dev rsync \
    || error "Could not install dependencies"
  ;;
Fedora)
  sudo dnf install -y --refresh @development-tools git gcc gcc-c++ cmake python3 \
    SDL2-devel opus-devel freetype-devel bzip2-devel libvorbis-devel \
    opusfile-devel libogg-devel rsync \
    || error "Could not install dependencies!"
  ;;
*)
  echo -e "\\e[91mUnknown distro detected - install Xash3D dependencies manually\\e[39m"
  sleep 5
  ;;
esac

echo "Cloning Xash3D FWGS..."
cd ~
git clone --recursive https://github.com/FWGS/xash3d-fwgs.git
cd xash3d-fwgs
git pull --recurse-submodules || error "Could not pull latest source"
git submodule update --init --recursive || error "Could not update submodules"

echo "Configuring..."
export CFLAGS="-mcpu=native -flto ${CFLAGS:-}"
export CXXFLAGS="-mcpu=native -flto ${CXXFLAGS:-}"
export LDFLAGS="-flto ${LDFLAGS:-}"
./waf configure || error "waf configure failed"

echo "Building Xash3D..."
./waf build || error "Build failed"

install_dir="$HOME/xash3d"
./waf install --destdir="$install_dir" || error "Install failed"

binary=$(find "$install_dir" -name 'xash3d' -type f -executable | head -1)
[ -x "$binary" ] || error "xash3d binary not found in $install_dir"
binary_dir="$(dirname "$binary")"

echo "Building hlsdk-portable (ARM64 Half-Life game libraries)..."
cd ~
[ -d hlsdk-portable ] || git clone --recursive https://github.com/FWGS/hlsdk-portable.git || error "Failed to clone hlsdk-portable"
cd hlsdk-portable
git pull --recurse-submodules || true
git submodule update --init --recursive
cmake -B build -S . -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON \
  -DCMAKE_C_FLAGS=-mcpu=native \
  -DCMAKE_CXX_FLAGS=-mcpu=native \
  || error "hlsdk-portable cmake configure failed"
cmake --build build -j$(nproc) || error "hlsdk-portable build failed"

mkdir -p "$binary_dir/valve/dlls" "$binary_dir/valve/cl_dlls"
cp build/dlls/hl_arm64.so "$binary_dir/valve/dlls/hl_arm64.so" \
  || error "hl_arm64.so missing from hlsdk-portable build"
cp build/cl_dll/client_arm64.so "$binary_dir/valve/cl_dlls/client_arm64.so" \
  || error "client_arm64.so missing from hlsdk-portable build"
cd ~
rm -rf "$HOME/hlsdk-portable"

sudo tee /usr/local/bin/xash3d >/dev/null <<EOF
#!/bin/sh
cd "$binary_dir" && exec ./xash3d "\$@"
EOF
sudo chmod 755 /usr/local/bin/xash3d

icon_src=$(find "$HOME/xash3d-fwgs" -name 'xash3d.png' -o -name 'xash.png' 2>/dev/null | head -1)
if [ -n "$icon_src" ]; then
  sudo install -Dm644 "$icon_src" /usr/share/pixmaps/xash3d.png
  icon_name="xash3d"
else
  icon_name="applications-games"
fi

sudo tee /usr/local/share/applications/xash3d.desktop >/dev/null <<EOF
[Desktop Entry]
Type=Application
Name=Xash3D FWGS
Exec=/usr/local/bin/xash3d
Icon=$icon_name
Comment=Half-Life engine reimplementation
Terminal=false
Categories=Game;
StartupWMClass=xash3d
EOF

echo
echo -e "\\e[93m=== Half-Life game data required ===\\e[39m"
echo "Xash3D needs data from a legal Half-Life install (Steam/retail/etc)."
echo "Common paths:"
echo "  ~/.steam/steam/steamapps/common/Half-Life/valve/"
echo "  /run/media/<user>/<usb>/Half-Life/valve/"
echo
echo "Enter the path to your valve/ folder (or press Enter to skip):"
read -rp "> " hl_src

if [ -n "$hl_src" ]; then
  hl_src="${hl_src/#\~/$HOME}"
  [ -d "$hl_src" ] || error "Not a directory: $hl_src"
  [ -d "$hl_src/maps" ] || error "$hl_src is missing maps/ - not a valid valve/ folder"

  echo "Copying game data..."
  rsync -a --exclude='dlls/' --exclude='cl_dlls/' "$hl_src/" "$binary_dir/valve/" \
    || error "Failed to copy game data"
  echo -e "\\e[32mGame data installed.\\e[39m"
else
  echo "Skipped. Copy maps/sound/models/etc. from your Half-Life valve/ into:"
  echo "  $binary_dir/valve/  (skip dlls/ and cl_dlls/)"
fi

echo "Done!"
echo "Sending you back to the main menu..."
sleep 5
