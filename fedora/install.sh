#!/usr/bin/env bash
set -euo pipefail

# Install Fedora tweaks from this folder, one component at a time.
#
#   bash fedora/install.sh                       list components
#   bash fedora/install.sh veracrypt xone        install those components
#   bash fedora/install.sh --status [comp...]    show drift between repo and system
#   bash fedora/install.sh --user-only comp...   skip the parts that need sudo
#
# Each component folder can hold:
#   about              line 1: description; optional "machine: ..." line warns
#                      that the component is tied to specific hardware
#   home/...           files for $HOME. Plain files are symlinked, so edits in
#                      the repo take effect immediately. Files that contain
#                      @HOME@, @USER@ or @UID@ are rendered and copied instead.
#                      Symlinks in the repo are recreated as the same symlink.
#   root/...           files for /. Always copied as root (never symlinked: root
#                      must not run code from a user-writable repo). Placeholders
#                      are rendered. Files in etc/sudoers.d are validated first.
#   enable             lines of "system <unit>" or "user <unit>" to enable
#   post-install.sh    run (as the user) after the files are in place; it gets
#                      MYSETUPS_USER_ONLY=1 when sudo steps must be skipped
#
# Safe to re-run: files that already match are left alone, and a differing
# file in $HOME is moved to <name>.BAK before it is replaced.

if [ -z "${BASH_VERSION:-}" ]; then
  echo "This installer must be run with bash." >&2
  exit 1
fi

fedora_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_dir="$(dirname "$fedora_dir")"
# shellcheck source=../scripts/_backup-path.sh
source "$repo_dir/scripts/_backup-path.sh"

mode=install
user_only=0
components=()

for arg in "$@"; do
  case "$arg" in
    --status) mode=status ;;
    --user-only) user_only=1 ;;
    -h|--help) mode=list ;;
    -*) echo "Unknown option: $arg" >&2; exit 1 ;;
    *) components+=("$arg") ;;
  esac
done

all_components() {
  local d
  for d in "$fedora_dir"/*/; do
    d="${d%/}"
    [ -f "$d/about" ] && basename "$d"
  done
}

list_components() {
  local c desc machine
  echo "Usage: bash fedora/install.sh [--status] [--user-only] <component>..."
  echo
  echo "Components:"
  for c in $(all_components); do
    desc="$(sed -n 1p "$fedora_dir/$c/about")"
    machine="$(sed -n 's/^machine: *//p' "$fedora_dir/$c/about")"
    printf '  %-22s %s\n' "$c" "$desc"
    [ -n "$machine" ] && printf '  %-22s (hardware-specific: %s)\n' "" "$machine"
  done
  return 0
}

has_placeholders() {
  grep -qE '@(HOME|USER|UID)@' "$1"
}

render() {
  sed -e "s|@HOME@|$HOME|g" -e "s|@USER@|$(id -un)|g" -e "s|@UID@|$(id -u)|g" "$1"
}

file_mode() {
  local rel="$1" src="$2"
  case "$rel" in
    etc/sudoers.d/*) echo 0440 ;;
    *) [ -x "$src" ] && echo 0755 || echo 0644 ;;
  esac
}

# Status of one managed file: prints OK, DIFFERS or MISSING.
file_state() {
  local src="$1" dest="$2" kind="$3"
  if [ -L "$src" ]; then
    if [ "$(readlink -- "$dest" 2>/dev/null)" = "$(readlink -- "$src")" ]; then echo OK
    elif [ -e "$dest" ] || [ -L "$dest" ]; then echo DIFFERS
    else echo MISSING; fi
    return
  fi
  if [ "$kind" = link ]; then
    if [ "$(readlink -- "$dest" 2>/dev/null)" = "$src" ]; then echo OK
    elif [ -e "$dest" ] || [ -L "$dest" ]; then echo DIFFERS
    else echo MISSING; fi
    return
  fi
  if [ ! -e "$dest" ]; then
    # Root-only directories (e.g. /etc/sudoers.d) can't be read without sudo.
    if [ -r "$(dirname "$dest")" ]; then echo MISSING; else echo UNREADABLE; fi
  elif [ ! -r "$dest" ]; then echo UNREADABLE
  elif render "$src" | cmp -s - "$dest"; then echo OK
  else echo DIFFERS; fi
}

walk_files() {
  # walk_files <component> <home|root> -> prints relative paths
  local base="$fedora_dir/$1/$2"
  [ -d "$base" ] || return 0
  (cd "$base" && find . \( -type f -o -type l \) | sed 's|^\./||' | sort)
}

status_component() {
  local c="$1" rel src dest kind scope unit state
  echo "== $c"
  while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    src="$fedora_dir/$c/home/$rel"; dest="$HOME/$rel"
    if [ ! -L "$src" ] && has_placeholders "$src"; then kind="copy"; else kind="link"; fi
    printf '  %-10s ~/%s\n' "$(file_state "$src" "$dest" "$kind")" "$rel"
  done < <(walk_files "$c" home)
  while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    src="$fedora_dir/$c/root/$rel"; dest="/$rel"
    printf '  %-10s /%s\n' "$(file_state "$src" "$dest" copy)" "$rel"
  done < <(walk_files "$c" root)
  if [ -f "$fedora_dir/$c/enable" ]; then
    while read -r scope unit; do
      [ -n "${unit:-}" ] || continue
      if [ "$scope" = user ]; then state="$(systemctl --user is-enabled "$unit" 2>/dev/null || true)"
      else state="$(systemctl is-enabled "$unit" 2>/dev/null || true)"; fi
      printf '  %-10s %s unit %s\n' "${state:-not-found}" "$scope" "$unit"
    done < "$fedora_dir/$c/enable"
  fi
}

install_home_file() {
  local src="$1" dest="$2" tmp target
  mkdir -p "$(dirname "$dest")"
  if [ -L "$src" ]; then
    target="$(readlink -- "$src")"
    if [ "$(readlink -- "$dest" 2>/dev/null)" = "$target" ]; then return 0; fi
    backup_path "$dest"
    ln -s "$target" "$dest"
    echo "Linked $dest -> $target"
  elif has_placeholders "$src"; then
    tmp="$(mktemp)"
    render "$src" > "$tmp"
    if [ -f "$dest" ] && [ ! -L "$dest" ] && cmp -s "$tmp" "$dest"; then
      rm -f "$tmp"; return 0
    fi
    backup_path "$dest"
    install -m "$(file_mode "" "$src")" "$tmp" "$dest"
    rm -f "$tmp"
    echo "Rendered $dest"
  else
    if [ "$(readlink -- "$dest" 2>/dev/null)" = "$src" ]; then return 0; fi
    backup_path "$dest"
    ln -s "$src" "$dest"
    echo "Linked $dest -> $src"
  fi
}

install_root_file() {
  local rel="$1" src="$2" dest="/$1" tmp target
  if [ -L "$src" ]; then
    target="$(readlink -- "$src")"
    if [ "$(readlink -- "$dest" 2>/dev/null)" = "$target" ]; then return 1; fi
    sudo mkdir -p "$(dirname "$dest")"
    sudo ln -sfn "$target" "$dest"
    echo "Linked $dest -> $target"
    return 0
  fi
  tmp="$(mktemp)"
  render "$src" > "$tmp"
  if sudo cmp -s "$tmp" "$dest" 2>/dev/null; then rm -f "$tmp"; return 1; fi
  case "$rel" in
    etc/sudoers.d/*)
      if ! sudo visudo -cqf "$tmp"; then
        echo "Refusing to install invalid sudoers file: $rel" >&2
        rm -f "$tmp"; exit 1
      fi ;;
  esac
  sudo install -D -m "$(file_mode "$rel" "$src")" -o root -g root "$tmp" "$dest"
  rm -f "$tmp"
  echo "Installed $dest"
  return 0
}

install_component() {
  local c="$1" rel scope unit machine changed_root=0 changed_user=0
  echo "== $c"
  machine="$(sed -n 's/^machine: *//p' "$fedora_dir/$c/about")"
  [ -n "$machine" ] && echo "Note: hardware-specific component ($machine)."

  while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    install_home_file "$fedora_dir/$c/home/$rel" "$HOME/$rel"
    case "$rel" in .config/systemd/user/*) changed_user=1 ;; esac
  done < <(walk_files "$c" home)

  if [ -d "$fedora_dir/$c/root" ]; then
    if [ "$user_only" = 1 ]; then
      echo "Skipping system files (--user-only)."
    else
      while IFS= read -r rel; do
        [ -n "$rel" ] || continue
        if install_root_file "$rel" "$fedora_dir/$c/root/$rel"; then
          case "$rel" in etc/systemd/system/*) changed_root=1 ;; esac
        fi
      done < <(walk_files "$c" root)
    fi
  fi

  [ "$changed_root" = 1 ] && sudo systemctl daemon-reload
  [ "$changed_user" = 1 ] && systemctl --user daemon-reload

  if [ -f "$fedora_dir/$c/enable" ]; then
    while read -r scope unit; do
      [ -n "${unit:-}" ] || continue
      if [ "$scope" = user ]; then
        systemctl --user is-enabled -q "$unit" 2>/dev/null || systemctl --user enable "$unit"
      elif [ "$user_only" = 0 ]; then
        systemctl is-enabled -q "$unit" 2>/dev/null || sudo systemctl enable "$unit"
      fi
    done < "$fedora_dir/$c/enable"
  fi

  if [ -f "$fedora_dir/$c/post-install.sh" ]; then
    MYSETUPS_USER_ONLY="$user_only" bash "$fedora_dir/$c/post-install.sh"
  fi
}

if [ "$mode" = list ] || { [ "$mode" = install ] && [ ${#components[@]} -eq 0 ]; }; then
  list_components
  exit 0
fi

if [ ${#components[@]} -eq 0 ]; then
  mapfile -t components < <(all_components)
fi

for c in "${components[@]}"; do
  if [ ! -f "$fedora_dir/$c/about" ]; then
    echo "Unknown component: $c (run without arguments for the list)" >&2
    exit 1
  fi
done

for c in "${components[@]}"; do
  if [ "$mode" = status ]; then status_component "$c"; else install_component "$c"; fi
done
