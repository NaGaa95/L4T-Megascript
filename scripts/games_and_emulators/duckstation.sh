#!/bin/bash

function error {
  echo -e "\\e[91m$1\\e[39m"
  sleep 3
  exit 1
}

clear -x
echo "DuckStation script started!"
echo "Source: https://github.com/stenzek/duckstation"
sleep 3

deps_archive="deps-linux-cross-arm64.tar.xz"
deps_target="linux-arm64"

echo "Installing dependencies..."

case "$__os_id" in
Raspbian | Debian | Ubuntu)
  sudo apt install -y autoconf automake build-essential clang cmake curl extra-cmake-modules git \
    libasound2-dev libcurl4-openssl-dev libdbus-1-dev libdecor-0-dev libegl-dev libevdev-dev \
    libfontconfig-dev libfreetype-dev libgtk-3-dev libgudev-1.0-dev libharfbuzz-dev libinput-dev \
    libopengl-dev libpipewire-0.3-dev libpulse-dev libssl-dev libudev-dev libwayland-dev libx11-dev \
    libx11-xcb-dev libxcb1-dev libxcb-composite0-dev libxcb-cursor-dev libxcb-damage0-dev \
    libxcb-glx0-dev libxcb-icccm4-dev libxcb-image0-dev libxcb-keysyms1-dev libxcb-present-dev \
    libxcb-randr0-dev libxcb-render0-dev libxcb-render-util0-dev libxcb-shape0-dev libxcb-shm0-dev \
    libxcb-sync-dev libxcb-util-dev libxcb-xfixes0-dev libxcb-xinput-dev libxcb-xkb-dev libxext-dev \
    libxkbcommon-x11-dev libxrandr-dev libxss-dev libtool lld llvm nasm ninja-build pkg-config zlib1g-dev \
    || error "Could not install dependencies"
  ;;
Fedora)
  sudo dnf install -y --refresh @development-tools alsa-lib-devel autoconf automake brotli-devel \
    clang cmake dbus-devel egl-wayland-devel extra-cmake-modules fontconfig-devel gcc-c++ gtk3-devel \
    libavcodec-free-devel libavformat-free-devel libavutil-free-devel libcurl-devel libdecor-devel \
    libevdev-devel libICE-devel libinput-devel libSM-devel libswresample-free-devel libswscale-free-devel \
    libX11-devel libXau-devel libxcb-devel libXcomposite-devel libXcursor-devel libXext-devel \
    libXfixes-devel libXft-devel libXi-devel libxkbcommon-devel libxkbcommon-x11-devel libXpresent-devel \
    libXrandr-devel libXrender-devel libXScrnSaver-devel libtool lld llvm make mesa-libEGL-devel \
    mesa-libGL-devel nasm ninja-build openssl-devel patch pcre2-devel perl-Digest-SHA pipewire-devel \
    pulseaudio-libs-devel systemd-devel wayland-devel xcb-util-cursor-devel xcb-util-devel \
    xcb-util-errors-devel xcb-util-image-devel xcb-util-keysyms-devel xcb-util-renderutil-devel \
    xcb-util-wm-devel xcb-util-xrm-devel zlib-devel \
    || error "Could not install dependencies!"
  ;;
*)
  echo -e "\\e[91mUnknown distro detected - this script should work, but please press Ctrl+C now and install necessary dependencies yourself following https://github.com/stenzek/duckstation#building if you haven't already...\\e[39m"
  sleep 5
  ;;
esac

echo "Cloning DuckStation..."
cd ~
git clone https://github.com/stenzek/duckstation.git
cd duckstation
git pull || error "Could not pull latest source"

echo "Downloading prebuilt dependencies pack..."
rm -rf "dep/prebuilt/$deps_target"
mkdir -p "dep/prebuilt/$deps_target"
curl -L --fail --output /tmp/duckstation-deps.tar.xz \
  "https://github.com/duckstation/dependencies/releases/latest/download/$deps_archive" \
  || error "Failed to download dependencies pack"
tar -xJf /tmp/duckstation-deps.tar.xz --strip-components=1 -C "dep/prebuilt/$deps_target" \
  || error "Failed to extract dependencies pack"
rm -f /tmp/duckstation-deps.tar.xz

echo "Setting up Qt6..."
qt_version=6.11.1
case "$__os_id" in
Fedora)
  sudo dnf install -y qt6-qtbase-devel qt6-qtbase-private-devel qt6-qttools-devel \
    || error "Could not install system Qt6"
  ;;
Raspbian | Debian | Ubuntu)
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
esac
rm -rf "dep/prebuilt/$deps_target/lib/cmake/Qt6"* \
       "dep/prebuilt/$deps_target/include/Qt"* \
       "dep/prebuilt/$deps_target/lib/libQt6"*
sed -i \
  -e 's|Qt6 [0-9.]\+ REQUIRED|Qt6 6.10.0 REQUIRED|g' \
  -e '\|NO_DEFAULT_PATH PATHS "${DEPS_PATH}/lib/cmake/Qt6"$|d' \
  -e '/Have to verify it down here/,/^endif()$/d' \
  CMakeModules/DuckStationDependencies.cmake
grep -q 'Using incorrect Qt library' CMakeModules/DuckStationDependencies.cmake \
  && error "Failed to patch DuckStationDependencies.cmake - upstream layout may have changed"

echo "Building DuckStation..."
rm -rf build-release
cmake -B build-release \
  -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ \
  -DCMAKE_PREFIX_PATH=/usr/local/qt6 \
  -DCMAKE_EXE_LINKER_FLAGS_INIT="-fuse-ld=lld" \
  -DCMAKE_MODULE_LINKER_FLAGS_INIT="-fuse-ld=lld" \
  -DCMAKE_SHARED_LINKER_FLAGS_INIT="-fuse-ld=lld" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON \
  -DCMAKE_C_FLAGS=-mcpu=native \
  -DCMAKE_CXX_FLAGS=-mcpu=native \
  -G Ninja \
  || error "CMake configure failed"
ninja -C build-release || error "Build failed"

binary="$HOME/duckstation/build-release/bin/duckstation-qt"
[ -x "$binary" ] || error "Build did not produce a duckstation-qt binary at $binary"

sudo tee /usr/local/bin/duckstation >/dev/null <<'EOF'
#!/bin/sh
cd "$HOME/duckstation/build-release/bin" && exec ./duckstation-qt "$@"
EOF
sudo chmod 755 /usr/local/bin/duckstation

if [ -f "$HOME/duckstation/scripts/appimage/org.duckstation.DuckStation.png" ]; then
  sudo install -Dm644 "$HOME/duckstation/scripts/appimage/org.duckstation.DuckStation.png" \
    /usr/share/pixmaps/duckstation.png
  icon_name="duckstation"
else
  icon_name="applications-games"
fi

sudo tee /usr/local/share/applications/duckstation.desktop >/dev/null <<EOF
[Desktop Entry]
Type=Application
Name=DuckStation
GenericName=PlayStation 1 Emulator
Comment=Fast PlayStation 1 emulator
Exec=/usr/local/bin/duckstation %f
Icon=$icon_name
TryExec=/usr/local/bin/duckstation
Terminal=false
Categories=Game;Emulator;Qt;
EOF

echo "Done!"
echo "Sending you back to the main menu..."
sleep 5
