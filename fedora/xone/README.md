# xone (Xbox Wireless Adapter)

## Why
The Xbox Wireless Adapter (045e:02fe) needs the out-of-tree `xone` driver. The in-kernel `mt76x2u` Wi-Fi driver claims the dongle (MT7612U inside) and breaks it.

## What it does
- `/etc/modprobe.d/xone-blacklist.conf`: `blacklist xpad`, `blacklist mt76x2u`. xone's own `install.sh` wrote it. Side effects: no MT7612U Wi-Fi dongles, and no `xpad` (see `gamepad-8bitdo`).
- `xone-clean-stop.service`: `modprobe -r xone_dongle` at shutdown, so the next boot can start the adapter without a replug (workaround from dlundqvist/xone issue #227).

## Manual install (not scripted)
1. `sudo dnf install dkms bsdtar kernel-devel`
2. Clone the dlundqvist fork (v0.5.8 on xbox720; unmaintained since Jul 2026), then run `sudo ./install.sh` and `sudo install/firmware.sh --skip-disclaimer`. Firmware lands in `/lib/firmware/xone_dongle_*.bin`.
3. Optional local patch, `xone-stale-client-fix.patch` (2026-11-20). It adds a stale-client reaper to `transport/dongle.c`. Problem it fixes: after sleep, the driver kept a dead controller slot ("power off failed") and ignored reconnects. Apply it in `/usr/src/xone-0.5.8`, then run `sudo dkms build/install xone/0.5.8 --force`. On xbox720 the original is at `dongle.c.orig-2026-11-20`. Reinstalling xone drops the patch.
4. With Secure Boot on, the DKMS module needs a MOK key. Secure Boot is off on xbox720.
A Fedora kernel update can break the DKMS build. Check `dkms status`.

## Tried / failed
- After `mt76x2u` has pushed its firmware to the dongle, xone fails (`init radio failed: -110`) until you physically unplug and replug.
- In the front USB port, the dongle wedges the chipset controller whichever driver binds it (see `front-usb-bt-fix`).
- Temporary debugging (dynamic_debug, `pm_print_times`, s2idle) was all reverted. s2idle fails on this board (amdgpu -22), so `mem_sleep` stays `deep`.
- Idea, not built: a sleep hook that unloads/reloads `xone_dongle` around suspend.

## Status
- 2026-11-17: DKMS built for kernels 7.3.3 and 7.3.4.
- 2026-11-20: patch installed, **untested** after a sleep. xone-clean-stop is **untested** across a reboot.
