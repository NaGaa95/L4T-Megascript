#!/bin/bash

function error {
  echo -e "\\e[91m$1\\e[39m"
  sleep 3
  exit 1
}

clear -x
echo "Cemu script started!"
echo "Source: https://github.com/SSimco/Cemu"
sleep 3

echo "Installing dependencies..."

case "$__os_id" in
Raspbian | Debian | Ubuntu)
  sudo apt install -y libboost-all-dev libzip4 libzip-dev zipcmp zipmerge ziptool \
    glslang-dev glslang-tools libgcrypt20-dev libglm-dev libgtk-3-dev libpulse-dev libsecret-1-dev \
    libsystemd-dev libtool nasm libwxgtk3.2-dev libwxbase3.2-1t64 \
    libsdl2-dev libpugixml-dev rapidjson-dev libbluetooth-dev libusb-1.0-0-dev \
    cmake ninja-build clang git \
    || error "Could not install dependencies"

  if ! pkg-config --atleast-version=3.2.18 sdl3 2>/dev/null; then
    cd ~
    [ -d SDL ] || git clone https://github.com/libsdl-org/SDL.git
    cd SDL
    git fetch --tags
    sdl_tag=$(git tag -l 'release-3.*' --sort=-v:refname | head -n1)
    echo "Building SDL3 $sdl_tag from source..."
    git checkout "$sdl_tag" || error "Could not checkout SDL3 $sdl_tag"
    rm -rf build
    cmake -S . -B build -GNinja -DCMAKE_BUILD_TYPE=Release -DSDL_STATIC=OFF \
      || error "SDL3 configure failed"
    cmake --build build -j$(nproc) || error "SDL3 build failed"
    sudo cmake --install build || error "SDL3 install failed"
    sudo ldconfig
    cd ~
  fi

  if ! pkg-config --atleast-version=10.2.0 fmt 2>/dev/null || pkg-config --atleast-version=11.0.0 fmt 2>/dev/null; then
    cd ~
    [ -d fmt ] || git clone https://github.com/fmtlib/fmt.git
    cd fmt
    git fetch --tags
    fmt_tag=$(git tag -l '10.*' --sort=-v:refname | head -n1)
    echo "Building fmt $fmt_tag from source..."
    git checkout "$fmt_tag" || error "Could not checkout fmt $fmt_tag"
    rm -rf build
    cmake -S . -B build -GNinja -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON -DFMT_TEST=OFF \
      || error "fmt configure failed"
    cmake --build build -j$(nproc) || error "fmt build failed"
    sudo cmake --install build || error "fmt install failed"
    sudo ldconfig
    cd ~
  fi
  ;;
Fedora)
  sudo dnf install -y --refresh @development-tools git cmake ninja-build clang \
    boost-devel libzip-devel libzip-tools glslang-devel libgcrypt-devel glm-devel \
    gtk3-devel glib2-devel libpng-devel libjpeg-turbo-devel \
    pulseaudio-libs-devel libsecret-devel systemd-devel libtool nasm \
    fmt-devel SDL2-devel SDL3-devel bluez-libs-devel libusb1-devel pugixml-devel rapidjson-devel \
    || error "Could not install dependencies!"
  ;;
*)
  echo -e "\\e[91mUnknown distro detected - install Cemu dependencies manually first\\e[39m"
  sleep 5
  ;;
esac

need_wx_build=true
if wx_ver=$(wx-config --version 2>/dev/null); then
  wx_major=${wx_ver%%.*}
  wx_minor_rest=${wx_ver#*.}
  wx_minor=${wx_minor_rest%%.*}
  if [ "$wx_major" -gt 3 ] || { [ "$wx_major" -eq 3 ] && [ "$wx_minor" -ge 3 ]; }; then
    need_wx_build=false
  fi
fi

if [ "$need_wx_build" = true ]; then
  echo "Building wxWidgets 3.3.2 from source..."
  cd ~
  [ -d wxWidgets ] || git clone --recurse-submodules -j$(nproc) -b v3.3.2 https://github.com/wxWidgets/wxWidgets.git
  cd wxWidgets
  git fetch --tags
  git checkout v3.3.2 || error "Could not checkout wxWidgets v3.3.2 tag"
  git submodule update --init --recursive
  mkdir -p build-gtk
  cd build-gtk
  rm -rf config.cache CMakeCache.txt
  ../configure --with-gtk=3 --enable-shared \
    --disable-tests --disable-webview --without-libtiff \
    || error "wxWidgets configure failed"
  make -j$(nproc) || error "wxWidgets build failed"
  sudo make install || error "wxWidgets install failed"
  sudo ldconfig
  cd ~
fi

echo "Cloning Cemu..."
cd ~
git clone --recurse-submodules -j$(nproc) -b main https://github.com/SSimco/Cemu.git
cd Cemu
git pull --recurse-submodules -j$(nproc) || error "Could not pull latest source"
git submodule update --init --recursive || error "Could not update submodules"

echo "Building Cemu..."
export CC=clang
export CXX=clang++

sed -i 's/set(CMAKE_INTERPROCEDURAL_OPTIMIZATION_\(RELEASE\|RELWITHDEBINFO\) ON)/set(CMAKE_INTERPROCEDURAL_OPTIMIZATION_\1 OFF)/' CMakeLists.txt

cmake -S . -B build_arm -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_FLAGS=-mcpu=native \
  -DCMAKE_CXX_FLAGS=-mcpu=native \
  -DENABLE_VCPKG=OFF \
  -DENABLE_WAYLAND=OFF \
  -DENABLE_HIDAPI=OFF \
  -DENABLE_NSYSHID_LIBUSB=OFF \
  -DCMAKE_EXE_LINKER_FLAGS="-Wl,--start-group" \
  -DCMAKE_CXX_STANDARD_LIBRARIES="-lSPIRV-Tools -Wl,--end-group" \
  || error "CMake configure failed"
cmake --build build_arm -j$(nproc) || error "Build failed"

binary="$HOME/Cemu/bin/Cemu_release"
[ -x "$binary" ] || error "Build did not produce a Cemu binary at $binary"

install_dir="$HOME/.local/share/l4t-megascript/cemu"
rm -rf "$install_dir"
mkdir -p "$install_dir" || error "Could not create install directory"
cp -aL "$HOME/Cemu/bin/." "$install_dir/" \
  || error "Could not copy Cemu runtime files"
wx_lib_dir="$HOME/wxWidgets/build-gtk/lib"
if compgen -G "$wx_lib_dir/libwx*.so*" >/dev/null; then
  mkdir -p "$install_dir/lib" || error "Could not create Cemu library directory"
  cp -aL "$wx_lib_dir"/libwx*.so* "$install_dir/lib/" \
    || error "Could not copy wxWidgets runtime libraries"
fi
[ -x "$install_dir/Cemu_release" ] || error "Install did not produce a Cemu binary at $install_dir/Cemu_release"

sudo tee /usr/local/bin/cemu >/dev/null <<'EOF'
#!/bin/sh
LD_LIBRARY_PATH="$HOME/.local/share/l4t-megascript/cemu/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export LD_LIBRARY_PATH
cd "$HOME/.local/share/l4t-megascript/cemu" && exec ./Cemu_release "$@"
EOF
sudo chmod 755 /usr/local/bin/cemu

if [ -f "$HOME/Cemu/dist/linux/info.cemu.Cemu.png" ]; then
  sudo install -Dm644 "$HOME/Cemu/dist/linux/info.cemu.Cemu.png" /usr/share/pixmaps/cemu.png
  icon_name="cemu"
else
  icon_name="applications-games"
fi

sudo tee /usr/local/share/applications/cemu.desktop >/dev/null <<EOF
[Desktop Entry]
Type=Application
Name=Cemu
GenericName=Wii U Emulator
Comment=Software to emulate Wii U games and applications on PC
Exec=/usr/local/bin/cemu %f
Icon=$icon_name
TryExec=/usr/local/bin/cemu
Terminal=false
Categories=Game;Emulator;
Keywords=Nintendo;
MimeType=application/x-wii-u-rom;
StartupWMClass=Cemu
EOF

echo "Done!"
echo "Sending you back to the main menu..."
sleep 5
