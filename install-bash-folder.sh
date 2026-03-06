#!/usr/bin/env bash
set -euo pipefail

if [ -z "${BASH_VERSION:-}" ]; then
  echo "This installer must be run with bash." >&2
  exit 1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
src_dir="$script_dir/bash"
target_home="${MYSETUPS_TARGET_HOME:-$HOME}"

if [ ! -d "$src_dir" ]; then
  echo "Expected source folder missing: $src_dir" >&2
  exit 1
fi

mkdir -p "$target_home"

backup_file() {
  local original="$1"
  local backup
  local timestamp

  [ -f "$original" ] || return 0

  backup="${original}.BAK"
  if [ -e "$backup" ]; then
    timestamp="$(date +%Y%m%d%H%M%S)"
    backup="${original}.BAK.${timestamp}"
  fi

  cp -p "$original" "$backup"
  echo "Backed up existing file: $original -> $backup"
}

while IFS= read -r -d '' rel_path; do
  src_file="$src_dir/$rel_path"
  dest_file="$target_home/$rel_path"
  mkdir -p "$(dirname "$dest_file")"
  if [ -f "$dest_file" ] && ! cmp -s "$src_file" "$dest_file"; then
    backup_file "$dest_file"
  fi
  cp -f "$src_file" "$dest_file"
done < <(cd "$src_dir" && find . -type f -print0 | sed -z 's#^\./##')
echo "Installed files from $src_dir into target home: $target_home"
echo "Existing files were backed up to *.BAK before overwrite."
