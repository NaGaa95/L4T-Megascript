#!/bin/bash

function error {
  echo -e "\\e[91m$1\\e[39m"
  sleep 3
  exit 1
}

clear -x
echo "Azahar script successfully started!"
echo "Credits: https://github.com/azahar-emu/azahar/wiki/Building-From-Source#linux"
sleep 3

echo "Installing dependencies..."
sleep 1

case "$__os_id" in
Raspbian | Debian | Ubuntu)

  case "$__os_codename" in
  bionic | focal)
    echo "Adding GCC/G++ 11 repo..."
    ubuntu_ppa_installer "ubuntu-toolchain-r/test" || error "PPA failed to install"
    echo "Adding QT6 repo..."
    #it's not redneck if it works.
    #TODO: get https://github.com/oskirby/qt6-packaging/issues/2 resolved, or just build QT6 ourselves
    ubuntu_ppa_installer "okirby/qt6-backports" || error "PPA failed to install"
    ubuntu_ppa_installer "okirby/qt6-testing" || error "PPA failed to install"
    #installs LLVM-19 toolchain
    curl https://apt.llvm.org/llvm.sh | sudo bash -s "19" || error "apt.llvm.org installer failed!"

    sudo apt install -y libc++-19-dev libc++abi-19-dev libstdc++6 libclang-19-dev clang-19 llvm-19 || error "Could not install dependencies"
    echo /usr/lib/llvm-19/lib | sudo tee /etc/ld.so.conf.d/llvm19.conf
    sudo ldconfig
    ;;
  jammy)
    sudo apt install -y libc++-19-dev libc++abi-19-dev clang llvm || error "Could not install dependencies"
    ;;
  *)
    sudo apt install -y clang llvm libc++-dev || error "Could not install dependencies"
    ;;
  esac

  # refer to https://github.com/azahar-emu/azahar/blob/d59ea25cbe75161fd90f7f5cd56279176d456d2d/src/common/dynamic_library/ffmpeg.h#L7-L16 for required ffmpeg development headers
  sudo apt-get install git libsdl2-2.0-0 libsdl2-dev libfdk-aac-dev build-essential cmake libswscale-dev libavformat-dev libavcodec-dev libavfilter-dev libssl-dev glslang-tools glslang-dev spirv-tools spirv-headers -y || error "Could not install dependencies"

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
  sudo dnf install -y --refresh git cmake SDL2-devel openssl-devel libXext-devel qt6-qtbase-devel qt6-qtbase-private-devel qt6-qtmultimedia-devel cmake make clang llvm glslang-devel spirv-tools-devel spirv-headers-devel || error "Could not install dependencies!"
  ;;
*)
  echo -e "\\e[91mUnknown distro detected - this script should work, but please press Ctrl+C now and install necessary dependencies yourself following https://github.com/azahar-emu/azahar/wiki/Building-From-Source#linux if you haven't already...\\e[39m"
  sleep 5
  ;;
esac

echo "Building Azahar..."
sleep 1
cd ~
# if [ -d "$HOME/azahar" ] && (cd "$HOME/azahar"; git remote get-url origin | grep -q "azahar-emu/azahar"); then
#   rm -rf ~/azahar
# fi
git clone --recurse-submodules -j$(nproc) https://github.com/azahar-emu/azahar
cd azahar
git pull --recurse-submodules -j$(nproc) || error "Could Not Pull Latest Source Code"
git submodule update --init --recursive || error "Could Not Pull All Submodules"
mkdir -p build
cd build
rm -rf CMakeCache.txt
case "$__os_codename" in
bionic | focal)
  cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH=/usr/local/qt6 -DCMAKE_INSTALL_RPATH=/usr/local/qt6/lib -DCMAKE_INSTALL_RPATH_USE_LINK_PATH=ON -DENABLE_OPENGL=ON -DCMAKE_CXX_FLAGS=-mcpu=native -DCMAKE_C_FLAGS=-mcpu=native -DCMAKE_C_COMPILER=clang-19 -DCMAKE_CXX_COMPILER=clang++-19 -DUSE_SYSTEM_GLSLANG=ON -DSIRIT_USE_SYSTEM_SPIRV_HEADERS=ON
  ;;
*)
  cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH=/usr/local/qt6 -DCMAKE_INSTALL_RPATH=/usr/local/qt6/lib -DCMAKE_INSTALL_RPATH_USE_LINK_PATH=ON -DENABLE_OPENGL=ON -DCMAKE_CXX_FLAGS=-mcpu=native -DCMAKE_C_FLAGS=-mcpu=native -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ -DUSE_SYSTEM_GLSLANG=ON -DSIRIT_USE_SYSTEM_SPIRV_HEADERS=ON
  ;;
esac
if [ "$?" != 0 ]; then
  # add debug logs about integrity of repo
  git fsck --no-dangling --full
  git submodule foreach --recursive git fsck --no-dangling --full
  error "Calling cmake failed"
fi

make -j$(nproc) || error "Compilation failed"
sudo make install || error "Make install failed"

echo "Done!"
echo "Sending you back to the main menu..."
sleep 5
