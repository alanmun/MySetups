#!/usr/bin/env bash
# Register the Ctrl+Shift+1 / Ctrl+Shift+2 shortcuts from the vc-*.desktop files.
# kbuildsycoca6 picks up X-KDE-Shortcuts; the kglobalshortcutsrc entries are a
# fallback for when kglobalaccel hasn't seen the launchers yet.
set -euo pipefail

command -v kbuildsycoca6 >/dev/null 2>&1 || { echo "KDE not found; skipping shortcut registration."; exit 0; }
kbuildsycoca6 >/dev/null 2>&1 || true

set_shortcut() {
  local desktop="$1" keys="$2"
  if ! kreadconfig6 --file kglobalshortcutsrc --group services --group "$desktop" --key _launch | grep -q .; then
    kwriteconfig6 --file kglobalshortcutsrc --group services --group "$desktop" --key _launch "$keys"
    echo "Registered $keys for $desktop (log out and back in if it doesn't fire)."
  fi
}
set_shortcut vc-mount-favorites.desktop "Ctrl+Shift+1"
set_shortcut vc-force-dismount.desktop "Ctrl+Shift+2"

command -v veracrypt >/dev/null 2>&1 || echo "Note: veracrypt is not installed yet (see fedora/README.md)."
