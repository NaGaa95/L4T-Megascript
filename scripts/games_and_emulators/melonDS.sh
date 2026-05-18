#!/bin/bash

clear -x
echo "MelonDS script started!"
echo "Source: https://github.com/melonDS-emu/melonDS"
sleep 3

echo "Installing dependencies..."

case "$__os_id" in
Raspbian | Debian | Ubuntu)
  case "$__os_codename" in
  bionic | focal)
    ubuntu_ppa_installer "theofficialgman/opt-qt-5.15.2-bionic-arm"
    ppa_installer
    ubuntu_ppa_installer "theofficialgman/melonds-depends" || error "PPA failed to install"
    ubuntu_ppa_installer "theofficialgman/cmake-bionic" || error "PPA failed to install"
    ubuntu_ppa_installer "ubuntu-toolchain-r/test" || error "PPA failed to install"
    sudo apt install -y cmake gcc-13 g++-13 qt515base qt515multimedia qt515gamepad qt515svg || error "Could not install dependencies"
    ;;
  jammy)
    ubuntu_ppa_installer "ubuntu-toolchain-r/test" || error "PPA failed to install"
    sudo apt install -y cmake gcc-13 g++-13 qt6-base-dev qt6-base-private-dev qt6-multimedia-dev libqt6svg6-dev || error "Could not install dependencies"
    ;;
  *)
    sudo apt install -y cmake gcc g++ qt6-base-dev qt6-base-private-dev qt6-multimedia-dev qt6-svg-dev || error "Could not install dependencies"
    ;;
  esac

  sudo apt install -y cmake extra-cmake-modules libcurl4-openssl-dev libpcap0.8-dev libsdl2-dev libslirp-dev libarchive-dev libepoxy-dev libzstd-dev libwayland-dev libenet-dev libfaad-dev || error "Could not install dependencies"
  ;;
Fedora)
  sudo dnf install -y --refresh git gcc-c++ cmake extra-cmake-modules SDL2-devel \
    libarchive-devel enet-devel libzstd-devel faad2-devel wayland-devel \
    qt6-qtbase-devel qt6-qtbase-private-devel qt6-qtmultimedia-devel qt6-qtsvg-devel \
    || error "Could not install dependencies!"
  ;;
*)
  echo -e "\\e[91mUnknown distro detected - this script should work, but please press Ctrl+C now and install necessary dependencies yourself following https://github.com/melonDS-emu/melonDS/blob/master/BUILD.md if you haven't already...\\e[39m"
  sleep 5
  ;;
esac

echo "Building MelonDS..."
cd ~
git clone https://github.com/melonDS-emu/melonDS.git
cd melonDS
git pull || error "Could not pull latest source"
mkdir -p build
cd build
rm -rf CMakeCache.txt
case "$__os_codename" in
bionic | focal)
  cmake .. -DCMAKE_CXX_FLAGS=-mcpu=native -DCMAKE_C_FLAGS=-mcpu=native -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON -DCMAKE_PREFIX_PATH=/opt/qt515 -DCMAKE_BUILD_WITH_INSTALL_RPATH=FALSE -DCMAKE_INSTALL_RPATH_USE_LINK_PATH=TRUE -DCMAKE_C_COMPILER=gcc-13 -DCMAKE_CXX_COMPILER=g++-13 -DUSE_QT6=OFF || error "CMake configure failed"
  ;;
*)
  cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON -DCMAKE_CXX_FLAGS=-mcpu=native -DCMAKE_C_FLAGS=-mcpu=native || error "CMake configure failed"
  ;;
esac
make -j$(nproc) || error "Build failed"
sudo make install || error "Install failed"

echo "Done!"
echo "Sending you back to the main menu..."
sleep 5
