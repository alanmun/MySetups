#!/usr/bin/env bash
set -euo pipefail

# Fetch Zellij plugins that are not vendored in git (mirrors how
# install-bash-folder.sh clones the tmux plugins). Safe to re-run.

ZJSTATUS_VERSION="v0.23.0" # pinned: built against zellij-tile 0.44.x (matches Zellij 0.44.3)

target_home="${MYSETUPS_TARGET_HOME:-$HOME}"
plugins_dir="$target_home/.config/zellij/plugins"
wasm="$plugins_dir/zjstatus.wasm"
url="https://github.com/dj95/zjstatus/releases/download/${ZJSTATUS_VERSION}/zjstatus.wasm"

mkdir -p "$plugins_dir"

echo "Fetching zjstatus ${ZJSTATUS_VERSION} ..."
if command -v curl >/dev/null 2>&1; then
  curl -fL "$url" -o "$wasm"
elif command -v wget >/dev/null 2>&1; then
  wget -qO "$wasm" "$url"
else
  echo "Need curl or wget to download zjstatus." >&2
  exit 1
fi

# Sanity check: a real wasm module is well over 1 MB; a failed download is tiny.
size="$(wc -c < "$wasm")"
if [ "$size" -lt 1000000 ]; then
  echo "Downloaded file is only ${size} bytes — download likely failed." >&2
  rm -f "$wasm"
  exit 1
fi

echo "Installed zjstatus -> $wasm (${size} bytes)"
