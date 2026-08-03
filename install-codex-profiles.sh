#!/usr/bin/env bash
set -euo pipefail

# Usage: bash ./install-codex-profiles.sh
# Installs shared Codex config profiles into CODEX_HOME. Symlink mode keeps
# installed profiles updated whenever this repository is updated.

main() {
  local script_dir
  local source_dir
  local target_dir
  local install_mode
  local source_file
  local target_file

  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  source_dir="$script_dir/codex"
  target_dir="${MYSETUPS_CODEX_HOME:-${CODEX_HOME:-$HOME/.codex}}"
  install_mode="${MYSETUPS_INSTALL_MODE:-symlink}"

  case "$install_mode" in
    symlink|copy)
      ;;
    *)
      echo "Unsupported install mode: $install_mode" >&2
      echo "Use MYSETUPS_INSTALL_MODE=symlink or MYSETUPS_INSTALL_MODE=copy" >&2
      return 1
      ;;
  esac

  mkdir -p "$target_dir"

  while IFS= read -r -d '' source_file; do
    target_file="$target_dir/${source_file##*/}"

    if [ "$install_mode" = "symlink" ]; then
      if [ -L "$target_file" ] && [ "$(readlink "$target_file")" = "$source_file" ]; then
        echo "Already linked: $target_file -> $source_file"
        continue
      fi

      if [ -e "$target_file" ] || [ -L "$target_file" ]; then
        _backup_file "$target_file"
      fi

      ln -s "$source_file" "$target_file"
      echo "Linked $target_file -> $source_file"
      continue
    fi

    if [ -L "$target_file" ]; then
      _backup_file "$target_file"
    elif [ -f "$target_file" ] && ! cmp -s "$source_file" "$target_file"; then
      _backup_file "$target_file"
    fi

    cp -f "$source_file" "$target_file"
    echo "Copied $source_file -> $target_file"
  done < <(find "$source_dir" -maxdepth 1 -type f -name '*.config.toml' -print0)
}

_backup_file() {
  local original="$1"
  local backup="${original}.BAK"
  local timestamp

  if [ -e "$backup" ] || [ -L "$backup" ]; then
    timestamp="$(date +%Y%m%d%H%M%S)"
    backup="${backup}.${timestamp}"
  fi

  mv "$original" "$backup"
  echo "Backed up existing file: $original -> $backup"
}

main "$@"
