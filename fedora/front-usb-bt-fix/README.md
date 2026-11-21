# front-usb-bt-fix (xbox720 only)

## Why
On desktop `xbox720`, the Xbox Wireless Adapter (045e:02fe, MT7612U inside) sits in front-panel port `usb1-port2`. At boot it can wedge the chipset xHCI controller (PCI `0000:0b:00.0`, USB buses 1+2): the port gets stuck in state `default` with endless -110/-71 enumeration errors. The MediaTek MT7925 Bluetooth is on the same controller and dies with it (`hci0: Failed to send wmt func ctrl (-110)`).
It happens whichever driver binds the dongle. With `mt76x2u` it reads `ASIC revision: ffffffff`. With `xone` the errors are `xone_mt76_write_register ... -121` and `load firmware failed: -19`. The user wants to keep the dongle in the front port.

## What it does
`front-usb-bt-fix.timer` (OnBootSec=25s) runs `/usr/local/sbin/front-usb-bt-fix.sh`. If `bluetoothctl list` shows no controller, the script unbinds and rebinds `0000:0b:00.0` up to 3 times, polling up to 45 s after each attempt (BT setup takes about 15 s).
The controller address and port path are hard-coded. Find the right ones on another machine with `lspci -nn | grep -i usb` and `/sys/bus/usb/devices/*/usb*-port*`.

## Tried / failed
- Reloading `btusb`, or toggling the port's disable flag: doesn't unstick port 2. Only a controller rebind or a reboot does.
- Checking the port-2 wedge as well: removed. The dongle re-wedges right after a rebind (`init radio failed: -110`), so rebinding never fixed the dongle and only dropped BT devices (the MX Vertical mouse).
- Blaming Windows Fast Startup: wrong. Hibernation is off and there's no `hiberfil.sys`.
- Moving the dongle to a rear port (bus 5, CPU controller) works, but the user declined it.

## Status
- 2026-11-17: installed. BT recovered via the script in manual runs. Not yet verified across a real reboot.
- Caution: a rebind drops all Bluetooth devices.
