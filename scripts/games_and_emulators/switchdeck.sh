#!/bin/bash

function error {
  echo -e "\\e[91m$1\\e[39m"
  sleep 3
  exit 1
}

clear -x
echo "Switchdeck script successfully started!"
echo "Credits: https://github.com/SildurFX/Switchdeck"
echo
echo "Switchdeck Script"
sleep 4

case "$architecture" in
aarch64) ;;
*) error "Switchdeck is aarch64-only (Switch L4T target)" ;;
esac

bash -c "$(curl -fsSL https://raw.githubusercontent.com/SildurFX/Switchdeck/main/install-steam.sh)" \
  || error "Switchdeck install failed"

echo "Done!"
echo "Sending you back to the main menu..."
sleep 5
