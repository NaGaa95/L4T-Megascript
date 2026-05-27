#!/bin/bash

echo "T210 MangoHud Fork script started!"

case "$__os_id" in
Raspbian | Debian | Ubuntu)
  package_available glslang-tools
  if [[ $? == "0" ]]; then
    sudo apt install glslang-tools -y || error "Could not install apt dependencies"
  else
    error "glslang-tools is not available so mangohud can not be compiled and installed"
  fi

  sudo apt install ninja-build git build-essential cmake pkg-config libx11-dev libwayland-dev libdbus-1-dev libxkbcommon-dev libgl-dev python3-mako -y || error "Could not install apt dependencies"
  if package_is_new_enough meson 0.60.0 ;then
    sudo apt install -y meson || error "Could not install apt dependencies"
  else
    pipx_install meson || exit 1
  fi
  ;;
Fedora)
  sudo dnf install -y --refresh @development-tools git cmake ninja-build meson pkgconf-pkg-config glslang libX11-devel wayland-devel dbus-devel libxkbcommon-devel mesa-libGL-devel python3-mako || error "Could not install dnf dependencies"
  ;;
*)
  error "Unsupported distro detected - MangoHud install currently supports Ubuntu/Debian and Fedora"
  ;;
esac

cd /tmp
rm -rf MangoHud
git clone https://github.com/NaGaa95/MangoHud.git --depth=1
cd MangoHud
meson build --prefix /usr -Dappend_libdir_mangohud=false -Dwith_xnvctrl=disabled || error "Could Not Configure Source"
ninja -C build || error "Could Not Build Mangohud"
sudo ninja -C build install || error "Could Not Install Mangohud"
rm -rf MangoHud
cd ~

status_green "MangoHud successfully installed"
echo ""
echo "Start mangohud by adding it before your command"
echo "mangohud %command%"
echo "or some opengl programs may need"
echo "mangohud --dlsym %command%"
echo "Replace %command% with something like chromium-browser to start chromium with the mangohud overlay"
echo ""
echo "For more info, refer to the readme: https://github.com/flightlessmango/MangoHud"
