#!/bin/bash

function error {
  echo -e "\\e[91m$1\\e[39m"
  sleep 3
  exit 1
}

clear -x
echo "BanjoRecomp (Banjo-Kazooie N64 recompilation) script started!"
echo "Source: https://github.com/BanjoRecomp/BanjoRecomp"
sleep 3

echo "Installing dependencies..."

case "$__os_id" in
Raspbian | Debian | Ubuntu)
  sudo apt install -y cmake ninja-build git build-essential clang lld llvm \
    libsdl2-dev libgtk-3-dev rustc cargo \
    || error "Could not install dependencies"
  ;;
Fedora)
  sudo dnf install -y --refresh @development-tools git cmake ninja-build \
    clang lld llvm-devel SDL2-devel gtk3-devel rust cargo \
    || error "Could not install dependencies!"
  ;;
*)
  echo -e "\\e[91mUnknown distro detected - install BanjoRecomp dependencies manually\\e[39m"
  sleep 5
  ;;
esac

echo "Cloning BanjoRecomp..."
cd ~
git clone --recurse-submodules -j$(nproc) https://github.com/BanjoRecomp/BanjoRecomp.git
cd BanjoRecomp
git pull --recurse-submodules -j$(nproc) || error "Could not pull latest source"
git submodule update --init --recursive || error "Could not update submodules"

required_rom="$HOME/BanjoRecomp/banjo.us.v10.decompressed.z64"
user_rom="$HOME/BanjoRecomp/banjo.z64"

if [ ! -f "$required_rom" ]; then
  if [ ! -f "$user_rom" ]; then
    echo
    echo -e "\\e[93m=== Game ROM required ===\\e[39m"
    echo "Place your legally-owned Banjo-Kazooie NTSC-U 1.0 ROM here (any z64/n64/v64):"
    echo "  $user_rom"
    echo
    read -rp "Press Enter when the ROM is in place..."
    [ -f "$user_rom" ] || error "ROM still not found at $user_rom"
  fi

  cache_decomp="$HOME/.cache/megascript/bk_rom_decompress"
  if [ ! -x "$cache_decomp" ]; then
    echo "Building bk_rom_decompress (one-time)..."
    cd ~
    [ -d bk_rom_compressor ] || git clone https://github.com/MittenzHugg/bk_rom_compressor.git || error "Failed to clone bk_rom_compressor"
    cd bk_rom_compressor
    git fetch origin
    git checkout 272180b527b01c0023dc2ab02bdfdfd373670906 \
      || error "Failed to checkout pinned bk_rom_compressor commit"
    git submodule update --init --recursive
    make -C rarezip CC=clang gzip/librarezip.a || error "librarezip.a build failed"
    cargo build --release --bin bk_rom_decompress || error "bk_rom_decompress build failed"
    mkdir -p "$(dirname "$cache_decomp")"
    cp target/release/bk_rom_decompress "$cache_decomp"
    chmod +x "$cache_decomp"
    cd ~
    rm -rf "$HOME/bk_rom_compressor"
    cd "$HOME/BanjoRecomp"
  fi

  echo "Decompressing ROM..."
  "$cache_decomp" "$user_rom" "$required_rom" \
    || error "ROM decompression failed (expected NTSC-U 1.0)"
fi

if [ ! -x "$HOME/BanjoRecomp/N64Recomp" ] || [ ! -x "$HOME/BanjoRecomp/RSPRecomp" ]; then
  echo "Building N64Recomp tools (one-time)..."
  cd ~
  [ -d N64Recomp ] || git clone --recurse-submodules -j$(nproc) https://github.com/N64Recomp/N64Recomp.git
  cd N64Recomp
  git pull --recurse-submodules -j$(nproc) || true
  git submodule update --init --recursive
  cmake -S . -B build -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ \
    -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON \
    -DCMAKE_C_FLAGS=-mcpu=native \
    -DCMAKE_CXX_FLAGS=-mcpu=native \
    || error "N64Recomp cmake configure failed"
  cmake --build build -j$(nproc) || error "N64Recomp build failed"
  cp build/N64Recomp "$HOME/BanjoRecomp/N64Recomp"
  cp build/RSPRecomp "$HOME/BanjoRecomp/RSPRecomp"
  chmod +x "$HOME/BanjoRecomp/N64Recomp" "$HOME/BanjoRecomp/RSPRecomp"
fi

cd "$HOME/BanjoRecomp"

echo "Generating C code from the ROM..."
./N64Recomp banjo.us.rev0.toml || error "N64Recomp code generation failed"
./RSPRecomp n_aspMain.us.rev0.toml || error "RSPRecomp code generation failed"

echo "Building BanjoRecomp..."
cmake -S . -B build-cmake -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ \
  -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON \
  -DCMAKE_C_FLAGS=-mcpu=native \
  -DCMAKE_CXX_FLAGS=-mcpu=native \
  || error "CMake configure failed"
cmake --build build-cmake --target BanjoRecompiled -j$(nproc) \
  || error "Build failed"

binary="$HOME/BanjoRecomp/build-cmake/BanjoRecompiled"
[ -x "$binary" ] || error "Build did not produce a BanjoRecompiled binary at $binary"

sudo tee /usr/local/bin/banjorecompiled >/dev/null <<'EOF'
#!/bin/sh
cd "$HOME/BanjoRecomp" && exec ./build-cmake/BanjoRecompiled "$@"
EOF
sudo chmod 755 /usr/local/bin/banjorecompiled

sudo install -Dm644 "$HOME/BanjoRecomp/assets/Logo.svg" \
  /usr/share/icons/hicolor/scalable/apps/banjorecompiled.svg

sudo tee /usr/local/share/applications/banjorecompiled.desktop >/dev/null <<EOF
[Desktop Entry]
Type=Application
Name=Banjo Recompiled
Exec=/usr/local/bin/banjorecompiled
Icon=banjorecompiled
Comment=Static recompilation of Banjo-Kazooie (N64)
Terminal=false
Categories=Game;
StartupWMClass=BanjoRecompiled
EOF

echo "Done!"
echo "Sending you back to the main menu..."
sleep 5
