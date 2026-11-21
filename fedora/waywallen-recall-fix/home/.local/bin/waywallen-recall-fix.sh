#!/bin/bash
# Waywallen 0.6.0 race: at login Plasma's wallpaper plugin registers each screen twice
# (placeholder "qml-display", then real monitor), and the startup restore targets the
# stale display IDs -> "wallpaper/recall/N failed: display N is not registered".
# Restarting the daemon once Plasma has settled restores the wallpapers.
LOG=$HOME/.var/app/org.waywallen.waywallen/.local/state/waywallen/logs/daemon/waywallen-current.log

since_daemon_start() {  # log lines since the most recent daemon start
  awk '/DBus name acquired: org.waywallen.waywallen.Daemon/{buf=""} {buf=buf $0 "\n"} END{printf "%s", buf}' "$LOG" 2>/dev/null
}

for _ in $(seq 1 60); do  # up to ~3 min
  out=$(since_daemon_start)
  if grep -q "recall/.*failed: display .* is not registered" <<<"$out"; then
    echo "recall failed; restarting waywallen daemon"
    sleep 5
    flatpak kill org.waywallen.waywallen
    sleep 2
    systemd-run --user --collect flatpak run --command=waywallen org.waywallen.waywallen --no-ui
    exit 0
  fi
  if grep -q "task 'wallpaper/recall/.*completed" <<<"$out"; then
    echo "recall succeeded; nothing to do"
    exit 0
  fi
  sleep 3
done
echo "no recall seen within 3 min; leaving it alone"
