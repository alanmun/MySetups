#!/usr/bin/env bash
# Link firefox/user.js into every default-release Firefox profile (Firefox reads
# user.js at startup and never rewrites it).
set -euo pipefail
src="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/firefox/user.js"
found=0
for p in "$HOME"/.config/mozilla/firefox/*.default-release "$HOME"/.mozilla/firefox/*.default-release; do
  [ -d "$p" ] || continue
  found=1
  [ "$(readlink -- "$p/user.js" 2>/dev/null)" = "$src" ] && continue
  [ -e "$p/user.js" ] && mv -- "$p/user.js" "$p/user.js.BAK"
  ln -s "$src" "$p/user.js"
  echo "Linked $p/user.js"
done
[ "$found" = 1 ] || echo "No Firefox profile yet; start Firefox once and re-run this component."
