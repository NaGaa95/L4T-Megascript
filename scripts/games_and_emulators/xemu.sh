#!/bin/bash

function error {
  echo -e "\\e[91m$1\\e[39m"
  sleep 3
  exit 1
}

clear -x
echo "Xemu (Original Xbox emulator) script started!"
echo "Source: https://github.com/xemu-project/xemu"
sleep 3

echo "Installing dependencies..."

case "$__os_id" in
Raspbian | Debian | Ubuntu)
  sudo apt install -y git build-essential cmake libsdl2-dev libcurl4-gnutls-dev libepoxy-dev libpixman-1-dev libgtk-3-dev libssl-dev libsamplerate0-dev libpcap-dev ninja-build python3-pip python3-tomli python3-yaml libslirp-dev libvulkan-dev python3-setuptools build-essential libaio-dev libslirp-dev libglu1-mesa-dev spirv-tools glslang-dev libshaderc-dev || error "Could not install dependencies!"
  #this script updates SDL2 for aarch64 devices and does nothing for others
  bash -c "$(curl -s https://raw.githubusercontent.com/$repository_username/L4T-Megascript/$repository_branch/scripts/sdl2_install_helper.sh)"
  ;;
Fedora)
  sudo dnf install -y --refresh @development-tools git cmake gcc-c++ ninja-build \
    pkgconf-pkg-config libdrm-devel libslirp-devel mesa-libGLU-devel gtk3-devel \
    libpcap-devel libsamplerate-devel libaio-devel SDL2-devel libepoxy-devel \
    pixman-devel openssl-devel python3-pyyaml python3-tomli libcurl-devel \
    vulkan-loader-devel glslang-devel spirv-tools-devel pipewire-devel \
    || error "Could not install dependencies!"
  ;;
*)
  echo -e "\\e[91mUnknown distro detected - install Xemu dependencies manually\\e[39m"
  sleep 5
  ;;
esac

echo "Cloning Xemu..."
cd ~
[ -d xemu ] || git clone --recurse-submodules -j$(nproc) https://github.com/xemu-project/xemu.git || error "Could not clone Xemu"
cd xemu || error "Could not enter Xemu source directory"
git pull --recurse-submodules -j$(nproc) || error "Could not pull latest source"
git submodule update --init --recursive || error "Could not update submodules"

echo "Building Xemu..."
export CFLAGS="-mcpu=native ${CFLAGS:-}"
export CXXFLAGS="-mcpu=native ${CXXFLAGS:-}"
xemu_build_args=("--enable-lto")
sed -i "s|libglslang = dependency('glslang', version: '>=15.0.0', required: false)|libglslang = declare_dependency(link_args: ['-Wl,--start-group', '-lglslang', '-lSPIRV-Tools-opt', '-lSPIRV-Tools', '-Wl,--end-group'])|" meson.build
rm -rf build dist
case "$__os_codename" in
bionic)
  sed -i -e 's/python3 /python3.8 /g' build.sh
  python3.8 -m pip install --upgrade pip meson PyYAML
  CC=gcc-13 CXX=g++-13 ./build.sh "${xemu_build_args[@]}" || error "Build failed"
  ;;
*)
  ./build.sh "${xemu_build_args[@]}" || error "Build failed"
  ;;
esac

binary="$HOME/xemu/dist/xemu"
[ -x "$binary" ] || error "Build did not produce a xemu binary at $binary"

sudo install -Dm755 "$binary" /usr/local/bin/xemu
sudo install -Dm644 "$HOME/xemu/ui/icons/xemu.svg" \
  /usr/local/share/icons/hicolor/scalable/apps/xemu.svg

for size in 16 24 32 48 64 128 256 512; do
  sudo install -Dm644 "$HOME/xemu/ui/icons/xemu_${size}x${size}.png" \
    "/usr/local/share/icons/hicolor/${size}x${size}/apps/xemu.png"
done

sudo install -Dm644 "$HOME/xemu/ui/xemu.desktop" \
  /usr/local/share/applications/xemu.desktop
sudo sed -i 's|^Exec=.*|Exec=/usr/local/bin/xemu %f|' \
  /usr/local/share/applications/xemu.desktop
grep -q '^TryExec=' /usr/local/share/applications/xemu.desktop \
  || sudo sed -i '/^Exec=/a TryExec=/usr/local/bin/xemu' \
    /usr/local/share/applications/xemu.desktop

echo "Done!"
echo "Sending you back to the main menu..."
sleep 5
