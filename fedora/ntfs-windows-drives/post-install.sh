#!/usr/bin/env bash
# Keep plocate's updatedb out of /mnt: crawling the Windows drives made ntfs3
# rewrite link counts on them.
set -euo pipefail
[ "${MYSETUPS_USER_ONLY:-0}" = 1 ] && exit 0
f=/etc/updatedb.conf
[ -f "$f" ] || exit 0
if ! grep -qE '^PRUNEPATHS *=.*[" ]/mnt[" ]' "$f"; then
  sudo cp -a "$f" "$f.bak-$(date +%F)"
  sudo sed -i -E 's|^(PRUNEPATHS *= *"[^"]*)"|\1 /mnt"|' "$f"
  echo "Added /mnt to PRUNEPATHS in $f"
fi
echo "fstab entries are per machine: see ntfs-windows-drives/fstab.example."
