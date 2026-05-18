#!/bin/bash

function error {
  echo -e "\\e[91m$1\\e[39m"
  sleep 3
  exit 1
}

clear -x
echo "RPCS3 (L4T fork) script started!"
echo "Source: https://github.com/mrcmunir/rpcs3 (nvidia-l4t branch)"
sleep 3

echo "Installing dependencies..."
sleep 1

case "$__os_id" in
Raspbian | Debian | Ubuntu)
  sudo apt install -y build-essential cmake ninja-build git \
    libasound2-dev libpulse-dev libopenal-dev libglew-dev zlib1g-dev libedit-dev \
    libvulkan-dev libudev-dev libevdev-dev libjack-dev libsndio-dev \
    libcurl4-openssl-dev libxkbcommon-dev \
    || error "Could not install dependencies"

  cd ~
  [ -d SDL ] || git clone https://github.com/libsdl-org/SDL.git
  cd SDL
  git fetch --tags
  latest_tag=$(git tag -l 'release-3.*' --sort=-v:refname | head -n1)
  if [ "$(pkg-config --modversion sdl3 2>/dev/null)" != "${latest_tag#release-}" ]; then
    echo "Building SDL3 $latest_tag from source..."
    git checkout "$latest_tag" || error "Could not checkout SDL3 $latest_tag"
    rm -rf build
    cmake -S . -B build -GNinja -DCMAKE_BUILD_TYPE=Release -DSDL_STATIC=OFF \
      || error "SDL3 configure failed"
    cmake --build build -j$(nproc) || error "SDL3 build failed"
    sudo cmake --install build || error "SDL3 install failed"
    sudo ldconfig
  fi
  cd ~

  qt_version=6.11.1
  if [ "$(/usr/local/qt6/bin/qmake -query QT_VERSION 2>/dev/null)" != "$qt_version" ]; then
    echo "Downloading prebuilt Qt $qt_version for aarch64..."
    curl -L --fail \
      "https://raw.githubusercontent.com/$repository_username/L4T-Megascript/$repository_branch/assets/qt/qt-$qt_version-aarch64.tar.xz" \
      -o /tmp/qt6-aarch64.tar.xz || error "Failed to download prebuilt Qt6"
    sudo mkdir -p /usr/local/qt6
    sudo tar -xJf /tmp/qt6-aarch64.tar.xz -C /usr/local/qt6 --strip-components=1 \
      || error "Failed to extract Qt6"
    rm /tmp/qt6-aarch64.tar.xz
  fi
  export PATH="/usr/local/qt6/bin:/usr/local/qt6/libexec:$PATH"
  ;;
Fedora)
  sudo dnf install -y --refresh @development-tools git cmake ninja-build \
    alsa-lib-devel glew glew-devel libatomic libevdev-devel libudev-devel \
    openal-soft-devel vulkan-devel pipewire-jack-audio-connection-kit-devel \
    llvm-devel libcurl-devel SDL3-devel \
    qt6-qtbase-devel qt6-qtbase-private-devel qt6-qtmultimedia-devel qt6-qtsvg-devel \
    || error "Could not install dependencies!"
  ;;
*)
  echo -e "\\e[91mUnknown distro detected - this script should work, but please press Ctrl+C now and install necessary dependencies yourself following https://github.com/RPCS3/rpcs3/blob/master/BUILDING.md if you haven't already...\\e[39m"
  sleep 5
  ;;
esac

echo "Cloning RPCS3..."
cd ~
git clone --recurse-submodules -j$(nproc) -b nvidia-l4t https://github.com/mrcmunir/rpcs3.git
cd rpcs3
git pull --recurse-submodules -j$(nproc) || error "Could not pull latest source"
git submodule update --init --recursive || error "Could not update submodules"

echo "Building RPCS3..."
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DUSE_NATIVE_INSTRUCTIONS=OFF \
  -DCMAKE_PREFIX_PATH=/usr/local/qt6 \
  -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON \
  -DCMAKE_C_FLAGS=-mcpu=native \
  -DCMAKE_CXX_FLAGS=-mcpu=native \
  || error "CMake configure failed"
cmake --build build || error "Build failed"

binary="$HOME/rpcs3/build/bin/rpcs3"
[ -x "$binary" ] || error "Build did not produce an rpcs3 binary at $binary"

sudo tee /usr/local/bin/rpcs3 >/dev/null <<'EOF'
#!/bin/sh
cd "$HOME/rpcs3/build/bin" && exec ./rpcs3 "$@"
EOF
sudo chmod 755 /usr/local/bin/rpcs3

if [ -f "$HOME/rpcs3/rpcs3/rpcs3.png" ]; then
  sudo install -Dm644 "$HOME/rpcs3/rpcs3/rpcs3.png" /usr/share/pixmaps/rpcs3.png
  icon_name="rpcs3"
else
  icon_name="applications-games"
fi

sudo tee /usr/local/share/applications/rpcs3.desktop >/dev/null <<EOF
[Desktop Entry]
Type=Application
Name=RPCS3
GenericName=PlayStation 3 Emulator
Comment=An open-source PlayStation 3 emulator/debugger written in C++.
Exec=/usr/local/bin/rpcs3 %f
Icon=$icon_name
TryExec=/usr/local/bin/rpcs3
Terminal=false
Categories=Game;Emulator;
Keywords=PS3;Playstation;
StartupWMClass=rpcs3
EOF

echo "Done!"
echo "Sending you back to the main menu..."
sleep 5
