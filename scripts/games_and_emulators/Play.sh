#!/bin/bash

function error {
  echo -e "\\e[91m$1\\e[39m"
  sleep 3
  exit 1
}

clear -x
echo "Play! (PlayStation 2 emulator) script started!"
echo "Source: https://github.com/jpd002/Play-"
sleep 3

echo "Installing dependencies..."

case "$__os_id" in
Raspbian | Debian | Ubuntu)
  sudo apt install -y build-essential git cmake curl \
    qt6-base-dev qt6-base-private-dev libalut-dev libevdev-dev libsqlite3-dev \
    || error "Could not install dependencies"

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
  sudo dnf install -y --refresh @development-tools git cmake \
    qt6-qtbase-devel freealut-devel openal-soft-devel libevdev-devel sqlite-devel \
    libstdc++-static \
    || error "Could not install dependencies!"
  ;;
*)
  echo -e "\\e[91mUnknown distro detected - install Play! dependencies manually\\e[39m"
  sleep 5
  ;;
esac

echo "Cloning Play!..."
cd ~
git clone --recurse-submodules https://github.com/jpd002/Play-.git
cd Play-
git pull --recurse-submodules || error "Could not pull latest source"
git submodule update --init --recursive

echo "Building Play!..."
cmake_extra_args=()
cmake_c_flags="-mcpu=native -Wno-error=implicit-function-declaration -Wno-error=int-conversion"
cmake_cxx_flags="-mcpu=native"
case "$__os_id" in
Raspbian | Debian | Ubuntu)
  cmake_extra_args+=(
    "-DCMAKE_PREFIX_PATH=/usr/local/qt6"
    "-DCMAKE_INSTALL_RPATH=/usr/local/qt6/lib"
    "-DCMAKE_INSTALL_RPATH_USE_LINK_PATH=ON"
  )
  ;;
Fedora)
  cmake_extra_args+=("-DCMAKE_DISABLE_FIND_PACKAGE_ZLIB=ON")
  ;;
esac
rm -rf build
mkdir -p build
cd build
cmake .. -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON \
  -DBUILD_TESTS=OFF \
  "${cmake_extra_args[@]}" \
  -DCMAKE_C_FLAGS="$cmake_c_flags" \
  -DCMAKE_CXX_FLAGS="$cmake_cxx_flags" \
  || error "CMake configure failed"
cmake --build . -j$(nproc) || error "Build failed"

sudo cmake --install . || error "Install failed"

echo "Done!"
echo "Sending you back to the main menu..."
sleep 5
