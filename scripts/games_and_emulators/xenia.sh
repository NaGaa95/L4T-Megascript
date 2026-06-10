#!/bin/bash

function error {
  echo -e "\\e[91m$1\\e[39m"
  sleep 3
  exit 1
}

clear -x
echo "Xenia Edge (Xbox 360 emulator) script started!"
echo "Source: https://github.com/has207/xenia-edge"
sleep 3

echo "Installing dependencies..."

case "$__os_id" in
Raspbian | Debian | Ubuntu)
  sudo apt install -y build-essential git python3 cmake ninja-build clang lld pkg-config \
    libgtk-3-dev libsdl2-dev libasound2-dev libx11-dev libx11-xcb-dev libxcb1-dev \
    libfontconfig1-dev libxtst-dev liblz4-dev zlib1g-dev libexpat1-dev libpng-dev \
    libgl1-mesa-dev libvulkan-dev mesa-vulkan-drivers \
    || error "Could not install dependencies"
  ;;
Fedora)
  sudo dnf install -y --refresh @development-tools git python3 cmake ninja-build \
    clang lld pkgconf-pkg-config gtk3-devel SDL2-devel alsa-lib-devel \
    libX11-devel libxcb-devel fontconfig-devel libXtst-devel lz4-devel \
    zlib-devel expat-devel libpng-devel mesa-libGL-devel \
    vulkan-loader vulkan-loader-devel mesa-vulkan-drivers \
    || error "Could not install dependencies!"
  ;;
*)
  echo -e "\\e[91mUnknown distro detected - install Xenia Edge dependencies manually\\e[39m"
  sleep 5
  ;;
esac

echo "Cloning Xenia Edge..."
cd ~
[ -d xenia-edge ] || git clone -b edge https://github.com/has207/xenia-edge.git || error "Could not clone Xenia Edge"
cd xenia-edge || error "Could not enter xenia-edge source directory"
git fetch origin edge || error "Could not fetch latest source"
git checkout edge || error "Could not checkout edge branch"
git pull --ff-only origin edge || error "Could not pull latest source"

echo "Updating submodules..."
submodules="$(awk '/path = / { print $3 }' .gitmodules | grep -v '^third_party/DirectXShaderCompiler$')"
git submodule sync || error "Could not sync submodules"
git submodule update --init --depth=1 -j$(nproc) $submodules || error "Could not update submodules"

echo "Fetching Xenia data repositories..."
python3 xenia-build.py fetchdata || error "Could not fetch data repositories"

echo "Building Xenia Edge..."
export CC=clang
export CXX=clang++
export CFLAGS="-mcpu=native ${CFLAGS:-}"
export CXXFLAGS="-mcpu=native ${CXXFLAGS:-}"
rm -rf build
python3 xenia-build.py build --config=Release --target=xenia-app || error "Build failed"

binary="$HOME/xenia-edge/build/bin/Linux/Release/xenia_edge"
[ -x "$binary" ] || error "Build did not produce a Xenia Edge binary at $binary"

install_dir="$HOME/.local/share/l4t-megascript/xenia-edge"
rm -rf "$install_dir"
mkdir -p "$install_dir" || error "Could not create install directory"
cp -aL "$HOME/xenia-edge/build/bin/Linux/Release/." "$install_dir/" \
  || error "Could not copy Xenia Edge runtime files"
if [ -f "$HOME/xenia-edge/assets/icon/256.png" ]; then
  install -Dm644 "$HOME/xenia-edge/assets/icon/256.png" "$install_dir/assets/icon/256.png" \
    || error "Could not copy Xenia Edge icon"
fi
[ -x "$install_dir/xenia_edge" ] || error "Install did not produce a Xenia Edge binary at $install_dir/xenia_edge"

sudo tee /usr/local/bin/xenia_edge >/dev/null <<'EOF'
#!/bin/sh
cd "$HOME/.local/share/l4t-megascript/xenia-edge" && exec ./xenia_edge "$@"
EOF
sudo chmod 755 /usr/local/bin/xenia_edge

if [ -f "$install_dir/assets/icon/256.png" ]; then
  sudo install -Dm644 "$install_dir/assets/icon/256.png" /usr/share/pixmaps/xenia_edge.png
  icon_name="xenia_edge"
else
  icon_name="applications-games"
fi

sudo install -d /usr/local/share/applications
sudo tee /usr/local/share/applications/xenia_edge.desktop >/dev/null <<EOF
[Desktop Entry]
Type=Application
Name=Xenia Edge
GenericName=Xbox 360 Emulator
Comment=Xbox 360 research emulator
Exec=/usr/local/bin/xenia_edge %f
Icon=$icon_name
TryExec=/usr/local/bin/xenia_edge
Terminal=false
Categories=Game;Emulator;
Keywords=Xbox;Xbox360;Xenia;
MimeType=application/x-xbox360-executable;application/x-xbox360-iso;
StartupNotify=true
StartupWMClass=xenia_edge
EOF

echo "Done!"
echo "Sending you back to the main menu..."
sleep 5
