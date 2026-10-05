#!/bin/bash
# Install PS3 Gamepad Bluetooth Pairer for the current user.
#
#   git clone https://github.com/<you>/ps3-gamepad-bluetooth-pairer && cd ps3-gamepad-bluetooth-pairer && ./install.sh
#
# Installs to ~/.local/share/ps3pair, links ps3pair / ps3pair-tui / ps3pair-gui into
# ~/.local/bin and adds two launcher entries (TUI and GUI) for the Omarchy app
# launcher (Super+Space). Nothing here is tied to one machine.

set -euo pipefail

SRC=$(cd "$(dirname "$0")" && pwd)
DATA="${XDG_DATA_HOME:-$HOME/.local/share}"
DEST="$DATA/ps3pair"
BIN="$HOME/.local/bin"
APPS="$DATA/applications"

# package -> what proves it's there
declare -A NEEDS=(
  [bluez]="test -x /usr/lib/bluetooth/bluetoothd"
  [bluez-utils]="command -v bluetoothctl"
  [python]="command -v python3"
  [python-dbus]="python3 -c 'import dbus'"
  [python-gobject]="python3 -c 'from gi.repository import GLib'"
  [gum]="command -v gum"
  [jq]="command -v jq"
  [quickshell]="command -v qs"
)

missing=()
for pkg in "${!NEEDS[@]}"; do
  eval "${NEEDS[$pkg]}" &>/dev/null || missing+=("$pkg")
done

if ((${#missing[@]})); then
  echo "Installing missing packages: ${missing[*]}"
  if command -v omarchy &>/dev/null; then
    omarchy pkg add "${missing[@]}"
  else
    sudo pacman -S --needed --noconfirm "${missing[@]}"
  fi
fi

mkdir -p "$DEST" "$BIN" "$APPS"
rm -rf "$DEST/bin" "$DEST/gui"
cp -r "$SRC/bin" "$SRC/gui" "$DEST/"
chmod +x "$DEST"/bin/*

for exe in ps3pair ps3pair-tui ps3pair-gui; do
  ln -sf "$DEST/bin/$exe" "$BIN/$exe"
done

# TUI.float is an app-id Omarchy already floats and centers.
cat >"$APPS/ps3pair-tui.desktop" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=PS3 Gamepad Pairer
Comment=Pair a PlayStation 3 controller over Bluetooth (terminal)
Exec=xdg-terminal-exec --app-id=TUI.float -e $BIN/ps3pair-tui
Icon=input-gaming
Terminal=false
Categories=Settings;HardwareSettings;
Keywords=ps3;dualshock;sixaxis;gamepad;controller;bluetooth;pair;
StartupNotify=true
EOF

cat >"$APPS/ps3pair-gui.desktop" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=PS3 Gamepad Pairer (GUI)
Comment=Pair a PlayStation 3 controller over Bluetooth
Exec=$BIN/ps3pair-gui
Icon=input-gaming
Terminal=false
Categories=Settings;HardwareSettings;
Keywords=ps3;dualshock;sixaxis;gamepad;controller;bluetooth;pair;
EOF

update-desktop-database "$APPS" &>/dev/null || true

echo "Installed. Launch \"PS3 Gamepad Pairer\" from the app launcher (Super+Space),"
echo "or run: ps3pair-tui · ps3pair-gui · ps3pair --help"
case ":$PATH:" in *":$BIN:"*) ;; *) echo "Note: $BIN is not on your PATH." ;; esac
