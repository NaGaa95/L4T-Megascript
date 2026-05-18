#!/bin/bash

function error {
  echo -e "\\e[91m$1\\e[39m"
  sleep 3
  exit 1
}

clear -x
echo "NooDS (Nintendo DS / GBA emulator) script started!"
echo "Source: https://github.com/Hydr8gon/NooDS"
sleep 3

echo "Installing dependencies..."

case "$__os_id" in
Raspbian | Debian | Ubuntu)
  sudo apt install -y build-essential git pkg-config \
    libwxgtk3.2-dev libportaudio2 portaudio19-dev libgl1-mesa-dev \
    || error "Could not install dependencies"
  ;;
Fedora)
  sudo dnf install -y --refresh @development-tools git pkgconf-pkg-config \
    wxGTK-devel wxGTK-gl portaudio-devel mesa-libGL-devel \
    || error "Could not install dependencies!"
  [ -x /usr/bin/wx-config ] && export PATH="/usr/bin:$PATH"
  ;;
*)
  echo -e "\\e[91mUnknown distro detected - install wxWidgets and PortAudio manually\\e[39m"
  sleep 5
  ;;
esac

echo "Cloning NooDS..."
cd ~
git clone https://github.com/Hydr8gon/NooDS.git
cd NooDS
git pull || error "Could not pull latest source"

echo "Building NooDS..."
make clean || error "Clean failed"
make -j$(nproc) ARGS="-mcpu=native -Ofast -flto -std=c++11 -DUSE_GL_CANVAS -DLOG_LEVEL=0" || error "Build failed"

sudo make install DESTDIR=/usr/local || error "Install failed"

echo "Done!"
echo "Sending you back to the main menu..."
sleep 5
