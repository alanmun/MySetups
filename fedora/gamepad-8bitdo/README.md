# gamepad-8bitdo

## Why
The 8BitDo 2.4 GHz dongle (2dc8:3106) needs the `xpad` driver.

## What it does
`/etc/modules-load.d/xpad.conf` loads `xpad` at boot.

## Status
- 2026-11-20: **ineffective and unresolved**. `xone-blacklist.conf` blacklists `xpad`, and systemd-modules-load respects blacklists, so `xpad` wasn't loaded after the next reboot. `sudo modprobe xpad` works for one session.
- Options: drop `blacklist xpad` from the xone blacklist (xone and xpad might both claim Xbox pads), or load xpad through a udev rule or softdep for 2dc8:3106 only. Decide, then record the result here.
