#!/bin/bash

function error {
  echo -e "\\e[91m$1\\e[39m"
  sleep 3
  exit 1
}

clear -x
echo "Vita3K script started!"
echo "Source: https://github.com/Vita3K/Vita3K"
sleep 3

echo "Installing dependencies..."

case "$__os_id" in
Raspbian | Debian | Ubuntu)

  case "$__os_codename" in
  bionic | focal)
    curl https://apt.llvm.org/llvm.sh | sudo bash -s "19" || error "apt.llvm.org installer failed"
    sudo apt install -y libc++-19-dev libc++abi-19-dev libstdc++6 libclang-19-dev clang-19 clang-tools-19 llvm-19 || error "Could not install dependencies"
    sudo apt install -y git cmake ninja-build libsdl2-dev pkg-config libgtk-3-dev xdg-desktop-portal openssl libssl-dev || error "Could not install dependencies"
    echo /usr/lib/llvm-19/lib | sudo tee /etc/ld.so.conf.d/llvm19.conf
    sudo ldconfig
    ;;
  *)
    sudo apt install -y git cmake ninja-build libsdl2-dev pkg-config libgtk-3-dev clang clang-tools lld xdg-desktop-portal openssl libssl-dev || error "Could not install dependencies"
    ;;
  esac

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
  sudo dnf install -y git cmake ninja-build SDL2-devel pkg-config gtk3-devel clang lld \
    xdg-desktop-portal openssl openssl-devel libstdc++-static boost-devel boost-static \
    || error "Could not install dependencies!"
  ;;
*)
  echo -e "\\e[91mUnknown distro detected - this script should work, but please press Ctrl+C now and install necessary dependencies yourself following https://github.com/Vita3K/Vita3K/blob/master/building.md#linux if you haven't already...\\e[39m"
  sleep 5
  ;;
esac

echo "Building Vita3K..."
cd ~
git clone --recurse-submodules -j$(nproc) https://github.com/Vita3K/Vita3K
cd Vita3K
git pull --recurse-submodules -j$(nproc) || error "Could not pull latest source"
git submodule update --init --recursive || error "Could not update submodules"

clang_scan_deps=$(ls /usr/bin/clang-scan-deps-[0-9]* 2>/dev/null | sort -V | tail -1)

case "$__os_codename" in
bionic | focal)
  CC=clang-19 CXX=clang++-19 cmake --preset linux-ninja-clang \
    -DCMAKE_PREFIX_PATH=/usr/local/qt6 \
    -DCMAKE_CXX_COMPILER_CLANG_SCAN_DEPS=$clang_scan_deps \
    -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON \
    -DCMAKE_C_FLAGS=-mcpu=native \
    -DCMAKE_CXX_FLAGS=-mcpu=native \
    || error "CMake configure failed"
  cmake --build build/linux-ninja-clang --config Release || error "Build failed"
  ;;
*)
  cmake --preset linux-ninja-clang \
    -DCMAKE_PREFIX_PATH=/usr/local/qt6 \
    -DCMAKE_CXX_COMPILER_CLANG_SCAN_DEPS=$clang_scan_deps \
    -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON \
    -DCMAKE_C_FLAGS=-mcpu=native \
    -DCMAKE_CXX_FLAGS=-mcpu=native \
    || error "CMake configure failed"
  cmake --build build/linux-ninja-clang --config Release || error "Build failed"
  ;;
esac

binary="$HOME/Vita3K/build/linux-ninja-clang/bin/Release/Vita3K"
[ -x "$binary" ] || error "Build did not produce a Vita3K binary at $binary"

sudo tee /usr/local/bin/vita3k >/dev/null <<'EOF'
#!/bin/sh
cd "$HOME/Vita3K/build/linux-ninja-clang/bin/Release" && exec ./Vita3K "$@"
EOF
sudo chmod 755 /usr/local/bin/vita3k

if [ -f "$HOME/Vita3K/data/image/icon.png" ]; then
  sudo install -Dm644 "$HOME/Vita3K/data/image/icon.png" /usr/share/pixmaps/vita3k.png
  icon_name="vita3k"
else
  icon_name="applications-games"
fi

sudo tee /usr/local/share/applications/vita3k.desktop >/dev/null <<EOF
[Desktop Entry]
Name=Vita3K
Comment=PlayStation Vita emulator
Exec=/usr/local/bin/vita3k
Icon=$icon_name
Terminal=false
Type=Application
Categories=Game;Emulator;
EOF

echo "Done!"
echo "Sending you back to the main menu..."
sleep 5
