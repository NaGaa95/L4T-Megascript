#!/bin/bash

function error {
  echo -e "\\e[91m$1\\e[39m"
  sleep 3
  exit 1
}

clear -x
echo "mGBA script started!"
echo "Source: https://github.com/mgba-emu/mgba"
sleep 3

echo "Installing dependencies..."

case "$__os_id" in
Raspbian | Debian | Ubuntu)
  case "$__os_codename" in
  bionic)
    ubuntu_ppa_installer "theofficialgman/opt-qt-5.15.2-bionic-arm"
    ppa_installer
    ubuntu_ppa_installer "theofficialgman/melonds-depends" || error "PPA failed to install"
    ubuntu_ppa_installer "theofficialgman/cmake-bionic" || error "PPA failed to install"
    ubuntu_ppa_installer "ubuntu-toolchain-r/test" || error "PPA failed to install"
    sudo apt install -y cmake gcc-13 g++-13 qt515base qt515multimedia qt515gamepad \
      || error "Could not install dependencies"
    ;;
  *)
    package_available qt5-default
    if [[ $? == "0" ]]; then
      sudo apt install -y qt5-default qtbase5-private-dev qtmultimedia5-dev \
        || error "Could not install dependencies"
    else
      sudo apt install -y qtbase5-dev qtchooser qtbase5-private-dev qtmultimedia5-dev \
        || error "Could not install dependencies"
    fi
    sudo apt install -y cmake gcc g++ || error "Could not install dependencies"
    ;;
  esac

  sudo apt install -y git libsdl2-2.0-0 libsdl2-dev ffmpeg libelf-dev \
    libepoxy-dev libzip-dev zipcmp zipmerge ziptool libedit-dev libjson-c-dev \
    libsqlite3-dev liblua5.3-dev libpng-dev zlib1g-dev \
    || error "Could not install dependencies"
  ;;
Fedora)
  sudo dnf install -y --refresh @development-tools git cmake gcc-c++ make \
    SDL2-devel qt5-qtbase-devel qt5-qtmultimedia-devel libpng-devel zlib-devel \
    lua-devel libzip-devel libedit-devel json-c-devel sqlite-devel libepoxy-devel \
    elfutils-libelf-devel libavcodec-free-devel libavformat-free-devel \
    libavutil-free-devel libswscale-free-devel libswresample-free-devel \
    desktop-file-utils \
    || error "Could not install dependencies!"
  ;;
*)
  echo -e "\\e[91mUnknown distro detected - please install mGBA dependencies manually following https://github.com/mgba-emu/mgba\\e[39m"
  sleep 5
  ;;
esac

echo "Building mGBA..."
cd ~
git clone https://github.com/mgba-emu/mgba.git
cd mgba
git pull || error "Could not pull latest source"
git submodule update --init --recursive || error "Could not update submodules"
mkdir -p build
cd build
rm -rf CMakeCache.txt
case "$__os_codename" in
bionic)
  cmake .. -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON \
    -DCMAKE_CXX_FLAGS=-mcpu=native \
    -DCMAKE_C_FLAGS=-mcpu=native \
    -DCMAKE_PREFIX_PATH=/opt/qt515 \
    -DCMAKE_BUILD_WITH_INSTALL_RPATH=FALSE \
    -DCMAKE_INSTALL_RPATH_USE_LINK_PATH=TRUE \
    -DCMAKE_C_COMPILER=gcc-13 \
    -DCMAKE_CXX_COMPILER=g++-13 \
    || error "CMake configure failed"
  ;;
*)
  cmake .. -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON \
    -DCMAKE_CXX_FLAGS=-mcpu=native \
    -DCMAKE_C_FLAGS=-mcpu=native \
    || error "CMake configure failed"
  ;;
esac
make -j$(nproc) || error "Build failed"
sudo make install || error "Install failed"

echo "Done!"
echo "Sending you back to the main menu..."
sleep 5
