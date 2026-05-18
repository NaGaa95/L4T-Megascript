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
  sudo apt install -y build-essential git cmake \
    qt6-base-dev qt6-base-private-dev libalut-dev libevdev-dev libsqlite3-dev \
    || error "Could not install dependencies"
  ;;
Fedora)
  sudo dnf install -y --refresh @development-tools git cmake \
    qt6-qtbase-devel freealut-devel openal-soft-devel libevdev-devel sqlite-devel \
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
