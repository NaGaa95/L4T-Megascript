#!/bin/bash

function error {
  echo -e "\\e[91m$1\\e[39m"
  sleep 3
  exit 1
}

clear -x
echo "Rosalie's Mupen GUI script started!"
echo "Source: https://github.com/Rosalie241/RMG"
sleep 3

echo "Installing dependencies..."

case "$__os_id" in
Raspbian | Debian | Ubuntu)
  sudo apt install -y cmake ninja-build git build-essential nasm zip pkg-config \
    libusb-1.0-0-dev libhidapi-dev libsamplerate0-dev libspeex-dev libspeexdsp-dev \
    libminizip-dev libfreetype-dev libgl1-mesa-dev libglu1-mesa-dev \
    zlib1g-dev binutils-dev libvulkan-dev \
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
    qt_archive=""
    for candidate in \
      "$PWD/assets/qt/qt-$qt_version-aarch64.tar.xz" \
      "$HOME/L4T-Megascript-master/assets/qt/qt-$qt_version-aarch64.tar.xz" \
      "$HOME/L4T-Megascript/assets/qt/qt-$qt_version-aarch64.tar.xz"; do
      [ -f "$candidate" ] && { qt_archive="$candidate"; break; }
    done
    if [ -n "$qt_archive" ]; then
      echo "Using local Qt archive: $qt_archive"
    else
      echo "Downloading prebuilt Qt $qt_version for aarch64..."
      curl -L --fail \
        "https://raw.githubusercontent.com/$repository_username/L4T-Megascript/$repository_branch/assets/qt/qt-$qt_version-aarch64.tar.xz" \
        -o /tmp/qt6-aarch64.tar.xz || error "Failed to download prebuilt Qt6"
      qt_archive=/tmp/qt6-aarch64.tar.xz
    fi
    sudo mkdir -p /usr/local/qt6
    sudo tar -xJf "$qt_archive" -C /usr/local/qt6 --strip-components=1 \
      || error "Failed to extract Qt6"
    [ "$qt_archive" = /tmp/qt6-aarch64.tar.xz ] && rm "$qt_archive"
  fi
  export PATH="/usr/local/qt6/bin:/usr/local/qt6/libexec:$PATH"
  ;;
Fedora)
  sudo dnf install -y --refresh --disablerepo='getpagespeed*' \
    @development-tools git cmake ninja-build gcc-c++ nasm pkgconfig \
    libusb1-devel hidapi-devel libsamplerate-devel speexdsp-devel \
    minizip-compat-devel SDL3-devel freetype-devel \
    mesa-libGL-devel mesa-libGLU-devel zlib-ng-devel binutils-devel vulkan-devel \
    qt6-qtbase-devel qt6-qtsvg-devel qt6-qtwebsockets-devel \
    || error "Could not install dependencies!"
  ;;
*)
  echo -e "\\e[91mUnknown distro detected - this script should work, but please press Ctrl+C now and install necessary dependencies yourself following https://github.com/Rosalie241/RMG if you haven't already...\\e[39m"
  sleep 5
  ;;
esac

echo "Cloning RMG..."
cd ~
git clone --recurse-submodules -j$(nproc) https://github.com/Rosalie241/RMG.git
cd RMG
git pull --recurse-submodules -j$(nproc) || error "Could not pull latest source"
git submodule update --init --recursive || error "Could not update submodules"

echo "Building RMG..."
mkdir -p Build/Release
cmake -S . -B Build/Release -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_PREFIX_PATH=/usr/local/qt6 \
  -DCMAKE_INSTALL_RPATH=/usr/local/qt6/lib \
  -DCMAKE_INSTALL_RPATH_USE_LINK_PATH=ON \
  -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON \
  -DCMAKE_INSTALL_PREFIX=/usr \
  -DPORTABLE_INSTALL=OFF \
  -DUSE_ANGRYLION=ON \
  -DCMAKE_C_FLAGS=-mcpu=native \
  -DCMAKE_CXX_FLAGS=-mcpu=native \
  || error "CMake configure failed"
cmake --build Build/Release -j$(nproc) || error "Build failed"
sudo cmake --install Build/Release --strip || error "Install failed"

echo "Done!"
echo "Sending you back to the main menu..."
sleep 5
