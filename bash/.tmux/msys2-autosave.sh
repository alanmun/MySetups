#!/usr/bin/env bash

# Lightweight tmux-resurrect autosave loop for MSYS2.
#
# tmux-continuum normally checks its timer through a status-bar #() command.
# Redraw-heavy TUIs cause that command to run repeatedly, and each MSYS2 fork
# is expensive. Keep one sleeping worker per tmux server instead.

set -u

server_pid="$(tmux display-message -p '#{pid}' 2>/dev/null)" || exit 0
lock_dir="${TMPDIR:-/tmp}/tmux-msys2-autosave-${server_pid}.lock"
sleep_pid=""

# Reloading tmux.conf must not start a second worker for the same server.
mkdir "$lock_dir" 2>/dev/null || exit 0
cleanup() {
  if [ -n "$sleep_pid" ]; then
    kill "$sleep_pid" 2>/dev/null || true
  fi
  rmdir "$lock_dir" 2>/dev/null || true
}
trap cleanup EXIT HUP INT TERM

autosave_interval_seconds() {
  local interval_minutes

  # The seconds override exists for a fast isolated test; normal config uses
  # the interval in minutes.
  if [[ "${TMUX_MSYS2_AUTOSAVE_INTERVAL_SECONDS:-}" =~ ^[1-9][0-9]*$ ]]; then
    printf '%s\n' "$TMUX_MSYS2_AUTOSAVE_INTERVAL_SECONDS"
    return
  fi

  interval_minutes="$(tmux show-option -gqv @msys2-autosave-interval)"
  if ! [[ "$interval_minutes" =~ ^[1-9][0-9]*$ ]]; then
    interval_minutes=15
  fi
  printf '%s\n' "$((interval_minutes * 60))"
}

same_tmux_server_is_running() {
  [ "$(tmux display-message -p '#{pid}' 2>/dev/null)" = "$server_pid" ]
}

while same_tmux_server_is_running; do
  sleep "$(autosave_interval_seconds)" &
  sleep_pid=$!
  wait "$sleep_pid" || break
  sleep_pid=""
  same_tmux_server_is_running || break

  save_script="$(tmux show-option -gqv @resurrect-save-script-path)"
  if [ -n "$save_script" ] && [ -f "$save_script" ]; then
    bash "$save_script" quiet >/dev/null 2>&1
  fi
done
