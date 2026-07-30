#!/usr/bin/env bash

# Shared internal backup helpers for MySetups installers.

backup_path() {
  local original="$1"
  local backup="${original}.BAK"

  if [ ! -e "$original" ] && [ ! -L "$original" ]; then
    return 0
  fi

  prune_timestamped_backups "$original"
  _remove_backup_path "$backup"
  mv -- "$original" "$backup"
  echo "Backed up existing path: $original -> $backup"
}

prune_timestamped_backups() {
  local original="$1"
  local old_backup
  local timestamp

  for old_backup in "${original}.BAK."*; do
    if [ ! -e "$old_backup" ] && [ ! -L "$old_backup" ]; then
      continue
    fi

    timestamp="${old_backup#"${original}.BAK."}"
    if [[ "$timestamp" =~ ^[0-9]{14}$ ]]; then
      _remove_backup_path "$old_backup"
      echo "Removed legacy timestamped backup: $old_backup"
    fi
  done
}

_remove_backup_path() {
  local backup="$1"

  if [ ! -e "$backup" ] && [ ! -L "$backup" ]; then
    return 0
  fi

  if [ -d "$backup" ] && [ ! -L "$backup" ]; then
    rm -rf -- "$backup"
  else
    rm -f -- "$backup"
  fi
}
