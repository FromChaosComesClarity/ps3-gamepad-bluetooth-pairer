#!/bin/bash
# Remove PS3 Gamepad Bluetooth Pairer. Paired controllers stay paired, and
# /etc/bluetooth/input.conf is left as is (a backup from `ps3pair fix-clone`
# sits next to it as input.conf.ps3pair.bak).

DATA="${XDG_DATA_HOME:-$HOME/.local/share}"

rm -f "$HOME/.local/bin/ps3pair" "$HOME/.local/bin/ps3pair-tui" "$HOME/.local/bin/ps3pair-gui"
rm -f "$DATA/applications/ps3pair-tui.desktop" "$DATA/applications/ps3pair-gui.desktop"
rm -rf "$DATA/ps3pair"
update-desktop-database "$DATA/applications" &>/dev/null || true
echo "PS3 Gamepad Bluetooth Pairer removed."
