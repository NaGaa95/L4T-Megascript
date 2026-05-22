#!/bin/bash

function error {
  echo -e "\\e[91m$1\\e[39m"
  sleep 3
  exit 1
}

clear -x
echo "PPSSPP script started!"
echo "Source: https://github.com/hrydgard/ppsspp"
sleep 3

echo "Installing dependencies..."

case "$__os_id" in
Raspbian | Debian | Ubuntu)
  sudo apt install -y build-essential cmake git libgl1-mesa-dev libsdl2-dev libsdl2-ttf-dev libfontconfig1-dev libvulkan-dev libglew-dev || error "Could not install dependencies"
  ;;
Fedora)
  sudo dnf install -y --refresh git cmake SDL2-devel SDL2_ttf-devel fontconfig-devel vulkan-loader-devel vulkan-headers glew-devel mesa-libGL-devel @development-tools || error "Could not install dependencies!"
  ;;
*)
  echo -e "\\e[91mUnknown distro detected - this script should work, but please press Ctrl+C now and install necessary dependencies yourself following https://github.com/hrydgard/ppsspp/wiki/Build-instructions if you haven't already...\\e[39m"
  sleep 5
  ;;
esac

echo "Building PPSSPP..."
cd ~
git clone --recurse-submodules -j$(nproc) https://github.com/hrydgard/ppsspp.git
cd ppsspp
git pull --recurse-submodules -j$(nproc) || error "Could not pull latest source"
git submodule update --init --recursive || error "Could not update submodules"

mkdir -p build
cd build
rm -rf CMakeCache.txt
cmake -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON \
  -DCMAKE_C_FLAGS=-mcpu=native \
  -DCMAKE_CXX_FLAGS=-mcpu=native \
  .. || error "CMake configure failed"
make -j$(nproc) || error "Build failed"

binary="$HOME/ppsspp/build/PPSSPPSDL"
[ -x "$binary" ] || error "Build did not produce a PPSSPPSDL binary at $binary"

install_dir="$HOME/.local/share/l4t-megascript/ppsspp"
rm -rf "$install_dir"
mkdir -p "$install_dir" || error "Could not create install directory"
install -Dm755 "$binary" "$install_dir/PPSSPPSDL" \
  || error "Could not install PPSSPP binary"
[ -d "$HOME/ppsspp/assets" ] \
  && cp -aL "$HOME/ppsspp/assets" "$install_dir/" \
  || error "Could not copy PPSSPP assets"
[ -x "$install_dir/PPSSPPSDL" ] || error "Install did not produce a PPSSPPSDL binary at $install_dir/PPSSPPSDL"

sudo tee /usr/local/bin/ppsspp >/dev/null <<'EOF'
#!/bin/sh
cd "$HOME/.local/share/l4t-megascript/ppsspp" && exec ./PPSSPPSDL "$@"
EOF
sudo chmod 755 /usr/local/bin/ppsspp

if [ -d "$HOME/ppsspp/icons/hicolor" ]; then
  sudo cp -r "$HOME/ppsspp/icons/hicolor/." /usr/share/icons/hicolor/
  sudo gtk-update-icon-cache /usr/share/icons/hicolor 2>/dev/null || true
  icon_name="ppsspp"
else
  icon_name="applications-games"
fi

sudo tee /usr/local/share/applications/ppsspp.desktop >/dev/null <<EOF
[Desktop Entry]
Name=PPSSPP
Comment=PlayStation Portable emulator
Exec=/usr/local/bin/ppsspp
Icon=$icon_name
Terminal=false
Type=Application
Categories=Game;Emulator;
EOF

echo "Done!"
echo "Sending you back to the main menu..."
sleep 5
