#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/scripts/_backup-path.sh"
src="$script_dir/claude/CLAUDE.md"
config_dir="${CLAUDE_CONFIG_DIR:-${MYSETUPS_TARGET_HOME:-$HOME}/.claude}"
dest="$config_dir/CLAUDE.md"

if [[ -L "$dest" && "$dest" -ef "$src" ]]; then
  echo "Claude persona already linked: $dest"
  exit 0
fi

mkdir -p "$config_dir"
# Create the link first so a permissions failure leaves existing instructions intact.
stage="$(mktemp -d "$config_dir/.persona.XXXXXXXX")"
trap 'rm -f -- "$stage/CLAUDE.md"; rmdir -- "$stage"' EXIT
MSYS="winsymlinks:nativestrict ${MSYS:-}" ln -s "$src" "$stage/CLAUDE.md"
backup_path "$dest"
mv -- "$stage/CLAUDE.md" "$dest"
echo "Linked Claude persona: $dest"
