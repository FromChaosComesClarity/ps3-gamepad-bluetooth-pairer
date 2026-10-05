# PS3 Gamepad Bluetooth Pairer

Pair a PlayStation 3 controller (DualShock 3 / Sixaxis, including SHANWAN, Gasia
and other clones) with an [Omarchy](https://omarchy.org) machine over Bluetooth.
You get a terminal UI, a Quickshell GUI that follows your Omarchy theme, and a
scriptable CLI.

## Install (any Omarchy machine)

```bash
git clone https://github.com/FromChaosComesClarity/ps3-gamepad-bluetooth-pairer.git
cd ps3-gamepad-bluetooth-pairer
./install.sh
```

The installer adds any missing packages (`bluez-utils python-dbus python-gobject gum jq quickshell`)
with `omarchy pkg add`, links the commands into `~/.local/bin`, and adds
**PS3 Gamepad Pairer** (TUI) and **PS3 Gamepad Pairer (GUI)** to the app launcher (Super+Space).
`./uninstall.sh` removes everything it installed.

## Pairing

1. Plug the controller in with a USB **data** cable.
2. Open the pairer (`ps3pair-tui`, `ps3pair-gui`, or `ps3pair pair`) and choose **Pair**.
3. If it's a clone, apply the **clone fix** when asked. This needs your password once.
4. When prompted, **unplug and re-plug** the cable. BlueZ registers the controller at that point.
5. When prompted, **unplug** the cable and press the **PS button**. The tool waits until the
   controller is connected over Bluetooth.

After that, pressing PS reconnects the controller to this machine. A PS3 controller
remembers only one host, so pairing it with another machine (or a PS3) unpairs it here.

## Why it works this way

A PS3 controller has no Bluetooth pairing mode. While it's on USB, the host writes its
own Bluetooth address into the controller (HID feature report `0xF5`), and the controller
then connects to that host when PS is pressed. `ps3pair`:

- reads the controller's address (`0xF2`) and its current host (`0xF5`) through `/dev/hidraw*`
  (no root needed: logind grants the seated user access),
- writes this machine's adapter address into it,
- registers a temporary BlueZ agent that authorizes **only that controller**. This lets BlueZ's
  sixaxis plugin register it on re-plug, and marks it trusted,
- waits for the Bluetooth connection, and watches the BlueZ log for rejections.

**Clone controllers** connect without bonding, and BlueZ rejects that by default.
`ps3pair fix-clone` sets `ClassicBondedOnly=false` in `/etc/bluetooth/input.conf`
(with a backup at `input.conf.ps3pair.bak`) and restarts Bluetooth. Note that this setting
allows unbonded connections from any HID device the machine already knows.

## CLI

```
ps3pair status [--json]        adapter, USB controllers, BlueZ state (default command)
ps3pair prepare                turn Bluetooth on (omarchy bluetooth power on)
ps3pair pair [--device X]      guided pairing; X = /dev/hidrawN or controller address
ps3pair fix-clone [--pkexec]   ClassicBondedOnly=false + restart bluetooth
ps3pair set-master [--address] only write the host address into the controller
ps3pair forget <address>       remove a controller from BlueZ
ps3pair --events <command>     JSON-lines progress output (used by the GUI)
```

## Troubleshooting

- **No controller found**: try another cable. Many cables are charge-only.
- **"BlueZ never registered the controller"**: run `journalctl -u bluetooth | grep sixaxis`. The
  sixaxis plugin must be enabled, which it is in Arch's bluez.
- **Connects and drops at once, or the LEDs keep blinking**: apply the clone fix and pair again.
- **Was paired before but won't connect**: `ps3pair forget <address>`, then pair again.
