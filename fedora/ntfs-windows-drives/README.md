# ntfs-windows-drives

## Why
The Windows drives (and NTFS VeraCrypt volumes) should behave as they do on Windows: case-insensitive, and with no file names Windows can't handle. That needs the kernel `ntfs3` driver with `nocase,windows_names` on every NTFS mount, including ones started from Dolphin or VeraCrypt that never read fstab.

## What it does
- `/usr/bin/mount.ntfs3` (with a `mount.ntfs` symlink to it) is a local mount helper. It adds `nocase,windows_names`, strips ntfs-3g-only options, then runs the real ntfs3 mount. Pass `case` in the options to opt out for one volume. Delete both files to go back to stock behaviour. `ntfs-3g` is not installed.
- `post-install.sh` adds `/mnt` to `PRUNEPATHS` in `/etc/updatedb.conf`. The plocate crawl made ntfs3 rewrite link counts on the Windows drives.
- `fstab.example` has xbox720's five drives by label (manual, per machine).

## Status
- Active on xbox720 since 2026-11-17 (helper), 2026-11-18 (updatedb).
- Which session wrote the helper is unknown; it isn't in any transcript on disk.
