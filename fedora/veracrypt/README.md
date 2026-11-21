# veracrypt

## Why
VeraCrypt on Linux doesn't behave like it does on Windows:
- Volumes stay mounted across sleep and logout.
- A busy volume refuses to dismount.
- After a forced dismount, a volume can stay "detached but held open" by a program, so the decrypted device never closes.
The user wants the Windows behaviour: volumes always dismount, and hotkeys mount and dismount them.

## What it does
- `veracrypt-dismount-all` (root): stops every process holding a VeraCrypt mount (fuser TERM, then KILL), then runs `veracrypt -t --non-interactive -d --force`. It never reads volume contents.
- `veracrypt-dismount-sleep.service`: runs it before sleep.
- `veracrypt-dismount-logout.service`: runs it when `user@<UID>.service` stops (logout and shutdown).
- `veracrypt-detach-cleaner.service`: watches unmount events (`findmnt --poll=umount`, no polling loop) and kills processes still holding a detached `veracrypt*` dm-crypt device. It reads `/proc`, never volume contents. Test mode: `veracrypt-detach-cleaner --holders MAJ MIN`.
- `~/.local/bin/veracrypt-mount-favorites` on **Ctrl+Shift+1**: `--load-preferences --fs-options=force --auto-mount=favorites`. A command-line start doesn't read the saved "force" option, so it is passed here.
- `~/.local/bin/veracrypt-force-dismount` on **Ctrl+Shift+2, pressed twice** (second press 0.1 to 1 s after the first, which guards against accidents): runs the dismount through sudo, then shows a notification.
- `/etc/sudoers.d/20-veracrypt-dismount`: NOPASSWD for that one script only.
- The shortcuts come from `X-KDE-Shortcuts` in `vc-*.desktop`; `post-install.sh` also writes them into `kglobalshortcutsrc`.

## Not scripted
- VeraCrypt itself was installed by the user (rpm from veracrypt.fr).
- In-app preferences: `FilesystemOptions=force`, `MountNtfsWithKernelDriver=0`, and the favorites at `/media/sta`.
- The system tray hides the VeraCrypt icon (`hiddenItems`, set per panel).
- NTFS volumes get `nocase,windows_names` from `ntfs-windows-drives`.

## Tried / notes
- An earlier `veracrypt-dismount-all` asked before killing busy programs. It was replaced with kill-then-dismount. The old copy is at `/usr/local/bin/veracrypt-dismount-all.bak` on xbox720 and can be deleted.
- A sed-added `force` line for `/dev/mapper/veracrypt*` in `mount.ntfs3` (2026-11-18) is no longer present. The `--fs-options=force` path replaced it.

## Status
- 2026-11-17 to 11-19: all units enabled on xbox720. The detach cleaner was tested with fake holders.
- **Untested**: dismount on logout, and the Ctrl+Shift+2 double press with a real volume mounted.
