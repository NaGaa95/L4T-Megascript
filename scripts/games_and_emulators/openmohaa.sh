#!/bin/bash

function error {
  echo -e "\\e[91m$1\\e[39m"
  sleep 3
  exit 1
}

clear -x
echo "OpenMoHAA (Medal of Honor: Allied Assault reimplementation) script started!"
echo "Source: https://github.com/openmoh/openmohaa"
sleep 3

echo "Installing dependencies..."

case "$__os_id" in
Raspbian | Debian | Ubuntu)
  sudo apt install -y cmake ninja-build clang lld flex bison \
    libsdl2-dev libopenal-dev libcurl4-openssl-dev git innoextract \
    || error "Could not install dependencies"
  ;;
Fedora)
  sudo dnf install -y --refresh @development-tools git cmake ninja-build \
    clang lld flex bison SDL2-devel openal-soft-devel libcurl-devel innoextract \
    || error "Could not install dependencies!"
  ;;
*)
  echo -e "\\e[91mUnknown distro detected - install OpenMoHAA dependencies manually\\e[39m"
  sleep 5
  ;;
esac

echo "Cloning OpenMoHAA..."
cd ~
git clone https://github.com/openmoh/openmohaa.git
cd openmohaa
git pull || error "Could not pull latest source"

echo "Configuring CMake..."
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ \
  -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON \
  -DCMAKE_C_FLAGS=-mcpu=native \
  -DCMAKE_CXX_FLAGS=-mcpu=native \
  || error "CMake configure failed"

echo "Building OpenMoHAA..."
cmake --build build -j$(nproc) || error "Build failed"

sudo cmake --install build || error "Install failed"

install_dir="/opt/mohaa/lib/openmohaa"
[ -x "$install_dir/launch_openmohaa_base" ] \
  || error "Expected launchers not found in $install_dir/"

sudo install -Dm644 "$HOME/openmohaa/misc/openmohaa.png" /usr/share/pixmaps/openmohaa.png

for variant in base spearhead breakthrough; do
  case "$variant" in
    base)         pretty="Medal of Honor: Allied Assault";        assets_dir="main"   ;;
    spearhead)    pretty="MoHAA: Spearhead";                      assets_dir="mainta" ;;
    breakthrough) pretty="MoHAA: Breakthrough";                   assets_dir="maintt" ;;
  esac
  sudo tee /usr/local/bin/openmohaa-$variant >/dev/null <<EOF
#!/bin/sh
cd "$install_dir" && exec ./launch_openmohaa_$variant "\$@"
EOF
  sudo chmod 755 /usr/local/bin/openmohaa-$variant
  sudo tee /usr/local/share/applications/openmohaa-$variant.desktop >/dev/null <<EOF
[Desktop Entry]
Type=Application
Name=$pretty
Exec=/usr/local/bin/openmohaa-$variant
Icon=openmohaa
Comment=Open-source reimplementation - assets dir: $assets_dir/
Terminal=false
Categories=Game;
StartupWMClass=launch_openmohaa_$variant
EOF
done

echo
echo -e "\\e[93m=== Install game data from GOG installer ===\\e[39m"
echo "OpenMoHAA needs game data (.pk3) from a legal copy of MoHAA."
echo "GOG War Chest is required (retail/EA/Origin disc versions are not supported)."
echo
echo "Enter the path to your GOG installer .exe (or press Enter to skip):"
read -rp "> " gog_exe

if [ -n "$gog_exe" ]; then
  [ -f "$gog_exe" ] || error "File not found: $gog_exe"

  echo "Extracting via innoextract..."
  extract_dir="/tmp/openmohaa-extract"
  rm -rf "$extract_dir"
  mkdir -p "$extract_dir"
  innoextract -d "$extract_dir" "$gog_exe" || error "innoextract failed"

  found_any=0
  for dir in main mainta maintt; do
    src=$(find "$extract_dir" -maxdepth 4 -type d -iname "$dir" | head -1)
    if [ -n "$src" ]; then
      echo "  Installing $dir/ from $src"
      sudo cp -r "$src" "$install_dir/"
      sudo chmod -R a+rX "$install_dir/$dir"
      found_any=1
    fi
  done

  rm -rf "$extract_dir"
  [ "$found_any" = 1 ] || error "No main/mainta/maintt folders found - use GOG MoHAA War Chest"
  echo -e "\\e[32mGame assets installed.\\e[39m"
else
  echo "Skipped. Copy your pk3 folders manually into:"
  echo "  $install_dir/main/    (Allied Assault)"
  echo "  $install_dir/mainta/  (Spearhead)"
  echo "  $install_dir/maintt/  (Breakthrough)"
fi

echo "Done!"
echo "Sending you back to the main menu..."
sleep 5
