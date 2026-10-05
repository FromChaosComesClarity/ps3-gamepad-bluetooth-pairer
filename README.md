<div align="center">

# PS3 Gamepad Bluetooth Pairer

### *a PS3 controller on Omarchy, without the cable*

![version](https://img.shields.io/github/v/release/FromChaosComesClarity/ps3-gamepad-bluetooth-pairer?label=version&color=2fe0d6&style=flat-square)
![platform](https://img.shields.io/badge/platform-Omarchy-0e1113?style=flat-square)

</div>

Pairs a DualShock 3, a Sixaxis or one of the many clones with your machine over Bluetooth.
There is a terminal UI, a Quickshell window that follows your Omarchy theme, and the CLI
underneath both.

## Why

A PS3 controller has no pairing mode. You can hold every button on it and nothing happens.
What it has instead is a slot for exactly one host address, written over USB. Plug it in, the
host writes its own address there, and from then on pressing PS makes the controller go looking
for that machine. BlueZ also has to know the controller exists and trust it, and that only
happens if something answers its authorization request at the right moment.

None of this is hard. It is just four steps nobody tells you about, in an order nobody tells
you either. This does them.

Clones are their own story. Mine is a SHANWAN that calls itself
`PLAYSTATION(R)3Conteroller-PANHAI` over Bluetooth, typo included. Clones connect without
bonding, which BlueZ refuses by default, so there is a fix for that too.

## Install

```bash
git clone https://github.com/FromChaosComesClarity/ps3-gamepad-bluetooth-pairer.git
cd ps3-gamepad-bluetooth-pairer
./install.sh
```

It installs what is missing with `omarchy pkg add`, puts the commands in `~/.local/bin` and adds
**PS3 Gamepad Pairer** to the launcher (Super+Space), as a TUI and as a GUI. `./uninstall.sh`
takes it all back out.

## Pair it

1. Plug the controller in with a data cable. Plenty of cables only charge.
2. Open the pairer and pick **Pair**.
3. If it is a clone, say yes to the clone fix. It asks for your password once.
4. Unplug and replug when it tells you to.
5. Unplug, press PS. The LEDs stop blinking and you are on player 1.

It stays paired after that, PS button and done. A PS3 controller remembers one host only, so
pairing it somewhere else unpairs it here.

## From a shell

```bash
ps3pair status              # adapter, controller, who it is paired to
ps3pair pair                # the guided version of the above
ps3pair fix-clone           # ClassicBondedOnly=false, backup kept, bluetooth restarted
ps3pair forget <address>    # make BlueZ forget a controller
ps3pair --events pair       # JSON lines, which is what the GUI reads
```

The clone fix lets any HID device this machine already knows connect without bonding, not just
the controller. That is the trade.

## When it breaks

If the controller vanishes from USB along with other things on the same ports, check
`journalctl -k | grep "HC died"`. My laptop's USB controller died mid-pairing and took the
webcam with it. A reboot brings it back, and so does unbinding and rebinding `xhci_hcd`.

---

<div align="center">

**one cable · one button · zero pairing mode**

Built by J.R.A.

</div>
