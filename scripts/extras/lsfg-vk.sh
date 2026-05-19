#!/bin/bash

function error {
  echo -e "\\e[91m$1\\e[39m"
  sleep 3
  exit 1
}

clear -x
echo "lsfg-vk (Lossless Scaling Frame Generation) script started!"
echo "Source: https://github.com/masies-hack/lsfg-vk"
sleep 3

echo "Installing dependencies..."

case "$__os_id" in
Raspbian | Debian | Ubuntu)
  sudo apt install -y git curl llvm clang cmake ninja-build pkg-config \
    libvulkan-dev mesa-common-dev \
    || error "Could not install dependencies"
  ;;
Fedora)
  sudo dnf install -y --refresh @development-tools git llvm clang \
    cmake ninja-build pkgconf-pkg-config vulkan-loader-devel mesa-libGL-devel \
    || error "Could not install dependencies!"
  ;;
*)
  echo -e "\\e[91mUnknown distro detected - install lsfg-vk dependencies manually\\e[39m"
  sleep 5
  ;;
esac

echo "Cloning lsfg-vk..."
cd ~
[ -d lsfg-vk ] || git clone -b frozen-7113d7d https://github.com/masies-hack/lsfg-vk.git || error "Failed to clone lsfg-vk"
cd lsfg-vk
git pull || error "Could not pull latest source"

echo "Building lsfg-vk..."
cmake -B build -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_COMPILER=clang \
  -DCMAKE_CXX_COMPILER=clang++ \
  -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON \
  -DCMAKE_C_FLAGS=-mcpu=native \
  -DCMAKE_CXX_FLAGS=-mcpu=native \
  || error "CMake configure failed"
cmake --build build -j$(nproc) || error "Build failed"
sudo cmake --install build || error "Install failed"

sudo sed -i 's|"library_path": "liblsfg-vk.so"|"library_path": "/usr/local/lib/liblsfg-vk.so"|' \
  /usr/local/share/vulkan/implicit_layer.d/VkLayer_LS_frame_generation.json

sudo ldconfig

dll_dir="$HOME/.local/share/lsfg-vk"
dll_path="$dll_dir/Lossless.dll"
mkdir -p "$dll_dir"

if [ ! -f "$dll_path" ]; then
  echo
  echo -e "\\e[93m=== Lossless.dll required ===\\e[39m"
  echo "lsfg-vk needs Lossless.dll from your legally-owned Lossless Scaling install."
  echo "Enter the full path to your Lossless.dll:"
  read -rp "> " src_dll
  src_dll="${src_dll/#\~/$HOME}"
  [ -f "$src_dll" ] || error "Not a file: $src_dll"
  cp "$src_dll" "$dll_path" || error "Failed to copy Lossless.dll"
fi

mkdir -p "$HOME/.config/lsfg-vk"
cat > "$HOME/.config/lsfg-vk/conf.toml" <<EOF
version = 1
[global]
dll = "$dll_path"
EOF

echo
echo "To enable frame generation for a game/app, prefix the command with:"
echo "  VK_INSTANCE_LAYERS=VK_LAYER_LSVK_frame_generation <command>"
echo
echo "Done!"
echo "Sending you back to the main menu..."
sleep 5
