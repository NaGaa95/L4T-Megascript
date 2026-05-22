#!/bin/bash

function error {
  echo -e "\\e[91m$1\\e[39m"
  sleep 3
  exit 1
}

clear -x
echo "MarathonRecomp (Sonic the Hedgehog 2006 recompilation) script started!"
echo "Source: https://github.com/sonicnext-dev/MarathonRecomp"
sleep 3

vcpkg_triplet="arm64-linux"

echo "Installing dependencies..."

case "$__os_id" in
Raspbian | Debian | Ubuntu)
  sudo apt install -y autoconf automake libtool pkg-config curl cmake ninja-build \
    clang clang-tools libgtk-3-dev git zip unzip tar build-essential \
    linux-libc-dev icnsutils \
    || error "Could not install dependencies"
  ;;
Fedora)
  sudo dnf install -y --refresh @development-tools git \
    autoconf automake libtool pkgconf-pkg-config curl cmake ninja-build \
    clang clang-tools-extra gtk3-devel zip unzip tar \
    perl-IPC-Cmd perl-FindBin libicns-utils \
    || error "Could not install dependencies!"
  ;;
*)
  echo -e "\\e[91mUnknown distro detected - install MarathonRecomp dependencies manually\\e[39m"
  sleep 5
  ;;
esac

echo "Cloning MarathonRecomp..."
cd ~
git clone --recurse-submodules -j$(nproc) https://github.com/sonicnext-dev/MarathonRecomp.git
cd MarathonRecomp
git pull --recurse-submodules -j$(nproc) || error "Could not pull latest source"
git submodule update --init --recursive || error "Could not update submodules"

private_dir="$HOME/MarathonRecomp/MarathonRecompLib/private"
mkdir -p "$private_dir"
required_files=(default.xex shader.arc shader_lt.arc)
missing=()
for f in "${required_files[@]}"; do
  [ -f "$private_dir/$f" ] || missing+=("$f")
done

if [ ${#missing[@]} -gt 0 ]; then
  echo
  echo -e "\\e[93m=== Game files required ===\\e[39m"
  echo "Copy these files from your legally-owned Sonic the Hedgehog (2006) Xbox 360 disc dump:"
  echo "  default.xex      (disc root)        -> $private_dir/"
  echo "  shader.arc       (/xenon/archives/) -> $private_dir/"
  echo "  shader_lt.arc    (/xenon/archives/) -> $private_dir/"
  echo
  read -rp "Press Enter when done to continue..."
  for f in "${required_files[@]}"; do
    [ -f "$private_dir/$f" ] || error "Still missing: $f"
  done
fi

dxc_lib="$HOME/MarathonRecomp/tools/XenosRecomp/thirdparty/dxc-bin/lib/arm64/libdxcompiler.so"
dxc_exe="$HOME/MarathonRecomp/tools/XenosRecomp/thirdparty/dxc-bin/bin/arm64/dxc-linux"
if [ ! -f "$dxc_lib" ] || [ ! -f "$dxc_exe" ]; then
  echo "Downloading prebuilt DXC for aarch64..."
  curl -L --fail \
    "https://raw.githubusercontent.com/$repository_username/L4T-Megascript/$repository_branch/assets/dxc/dxc-aarch64.tar.xz" \
    -o /tmp/dxc-aarch64.tar.xz || error "Failed to download prebuilt DXC"
  tmpdir=$(mktemp -d)
  tar -xJf /tmp/dxc-aarch64.tar.xz -C "$tmpdir" || error "Failed to extract DXC"
  mkdir -p "$(dirname "$dxc_lib")" "$(dirname "$dxc_exe")"
  cp "$tmpdir/libdxcompiler.so" "$dxc_lib"
  cp "$tmpdir/dxc" "$dxc_exe"
  chmod +x "$dxc_exe"
  rm -rf "$tmpdir" /tmp/dxc-aarch64.tar.xz
fi

echo "Building MarathonRecomp (this is LONG - vcpkg builds many deps from source)..."
sleep 2
export VCPKG_FORCE_SYSTEM_BINARIES=1

mkdir -p triplets-overlay
cat > triplets-overlay/arm64-linux.cmake <<'EOF'
set(VCPKG_TARGET_ARCHITECTURE arm64)
set(VCPKG_CRT_LINKAGE dynamic)
set(VCPKG_LIBRARY_LINKAGE dynamic)
set(VCPKG_CMAKE_SYSTEM_NAME Linux)
set(VCPKG_BUILD_TYPE release)
set(VCPKG_C_FLAGS "-mcpu=native -flto")
set(VCPKG_CXX_FLAGS "-mcpu=native -flto")
set(VCPKG_LINKER_FLAGS "-flto")
EOF
export VCPKG_OVERLAY_TRIPLETS="$PWD/triplets-overlay"

cmake --preset linux-release -DVCPKG_TARGET_TRIPLET="$vcpkg_triplet" \
  -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON \
  -DCMAKE_C_FLAGS=-mcpu=native \
  -DCMAKE_CXX_FLAGS=-mcpu=native \
  || error "CMake configure failed"
cmake --build ./out/build/linux-release --target MarathonRecomp \
  || error "Build failed"

binary="$HOME/MarathonRecomp/out/build/linux-release/MarathonRecomp/MarathonRecomp"
[ -x "$binary" ] || error "Build did not produce a MarathonRecomp binary at $binary"

install_dir="$HOME/.local/share/l4t-megascript/marathonrecomp"
rm -rf "$install_dir"
mkdir -p "$install_dir" || error "Could not create install directory"
cp -aL "$HOME/MarathonRecomp/out/build/linux-release/MarathonRecomp/." "$install_dir/" \
  || error "Could not copy MarathonRecomp runtime files"
[ -x "$install_dir/MarathonRecomp" ] || error "Install did not produce a MarathonRecomp binary at $install_dir/MarathonRecomp"

sudo tee /usr/local/bin/marathonrecomp >/dev/null <<'EOF'
#!/bin/sh
cd "$HOME/.local/share/l4t-megascript/marathonrecomp" && exec ./MarathonRecomp "$@"
EOF
sudo chmod 755 /usr/local/bin/marathonrecomp

icns_src="$HOME/MarathonRecomp/MarathonRecomp/res/macos/game_icon.icns"
if [ -f "$icns_src" ]; then
  rm -rf /tmp/marathonrecomp-icon
  mkdir -p /tmp/marathonrecomp-icon
  icns2png -x -o /tmp/marathonrecomp-icon "$icns_src" 2> >(grep -v '^libicns:' >&2)
  largest=$(ls -S /tmp/marathonrecomp-icon/*.png | head -1)
  sudo install -Dm644 "$largest" /usr/share/pixmaps/marathonrecomp.png
  rm -rf /tmp/marathonrecomp-icon
  icon_name="marathonrecomp"
else
  icon_name="applications-games"
fi

sudo tee /usr/local/share/applications/marathonrecomp.desktop >/dev/null <<EOF
[Desktop Entry]
Type=Application
Name=Marathon Recompiled
Exec=/usr/local/bin/marathonrecomp
Icon=$icon_name
Comment=Static recompilation of Sonic the Hedgehog (2006)
Terminal=false
Categories=Game;
StartupWMClass=MarathonRecomp
EOF

echo "Done!"
echo "Sending you back to the main menu..."
sleep 5
