#!/bin/bash

function error {
  echo -e "\\e[91m$1\\e[39m"
  sleep 3
  exit 1
}

clear -x
echo "Dusk (Twilight Princess reimplementation) script started!"
echo "Source: https://github.com/TwilitRealm/dusk"
sleep 3

echo "Installing dependencies..."

case "$__os_id" in
Raspbian | Debian | Ubuntu)
  sudo apt install -y build-essential curl git ninja-build clang lld cmake \
    zlib1g-dev libcurl4-openssl-dev libglu1-mesa-dev libdbus-1-dev libvulkan-dev \
    libxi-dev libxrandr-dev libasound2-dev libpulse-dev libudev-dev libpng-dev \
    libncurses5-dev libx11-xcb-dev libclang-dev libfreetype-dev libxinerama-dev \
    libxcursor-dev libgtk-3-dev libxss-dev libxtst-dev \
    python3 python-is-python3 python3-markupsafe \
    || error "Could not install dependencies"

  [ -x "$HOME/.cargo/bin/rustup" ] || \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable --profile minimal \
    || error "Failed to install rustup"
  source "$HOME/.cargo/env"
  rustup update stable
  ;;
Fedora)
  sudo dnf install -y --refresh @development-tools git \
    cmake vulkan-headers ninja-build clang-devel llvm-devel libpng-devel \
    turbojpeg-devel rust cargo \
    || error "Could not install dependencies!"
  ;;
*)
  echo -e "\\e[91mUnknown distro detected - install Dusk dependencies manually\\e[39m"
  sleep 5
  ;;
esac

echo "Cloning Dusk..."
cd ~
git clone --recursive https://github.com/TwilitRealm/dusk.git
cd dusk
git pull --recurse-submodules || error "Could not pull latest source"
git submodule update --init --recursive || error "Could not update submodules"

echo "Configuring CMake..."
cmake --preset linux-default-relwithdebinfo \
  -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON \
  -DCMAKE_C_FLAGS=-mcpu=native \
  -DCMAKE_CXX_FLAGS=-mcpu=native \
  || error "CMake configure failed"

echo "Building Dusk..."
cmake --build --preset linux-default-relwithdebinfo -j$(nproc) \
  || error "Build failed"

build_dir="$HOME/dusk/build/linux-default-relwithdebinfo"
binary="$build_dir/dusklight"
[ -x "$binary" ] || error "Build did not produce a dusklight binary at $binary"

install_dir="$HOME/.local/share/l4t-megascript/dusk"
rm -rf "$install_dir"
mkdir -p "$install_dir" || error "Could not create install directory"
install -Dm755 "$binary" "$install_dir/dusklight" \
  || error "Could not install dusklight binary"
cp -aL "$HOME/dusk/res" "$install_dir/" \
  || error "Could not copy Dusk runtime files"

sudo tee /usr/local/bin/dusk >/dev/null <<'EOF'
#!/bin/sh
cd "$HOME/.local/share/l4t-megascript/dusk" && exec ./dusklight "$@"
EOF
sudo chmod 755 /usr/local/bin/dusk

freedesktop_dir="$HOME/dusk/platforms/freedesktop"
icon_name="dev.twilitrealm.dusk"
for size in 16x16 32x32 48x48 64x64 128x128 256x256 512x512 1024x1024; do
  icon_src="$freedesktop_dir/$size/apps/$icon_name.png"
  sudo install -Dm644 "$icon_src" "/usr/share/icons/hicolor/$size/apps/$icon_name.png" \
    || error "Could not install Dusk $size icon"
done
sudo gtk-update-icon-cache /usr/share/icons/hicolor 2>/dev/null || true

desktop_file="/usr/local/share/applications/dusklight.desktop"
desktop_src="$freedesktop_dir/$icon_name.desktop"
sudo install -Dm644 "$desktop_src" "$desktop_file" \
  || error "Could not install Dusk desktop file"
sudo sed -i \
  -e 's|^Exec=.*|Exec=/usr/local/bin/dusk %f|' \
  -e "s|^Icon=.*|Icon=$icon_name|" \
  "$desktop_file"

echo "Done!"
echo "Sending you back to the main menu..."
sleep 5
