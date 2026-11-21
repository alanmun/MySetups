# waywallen-recall-fix

## Why
Waywallen 0.6.0 (flatpak `org.waywallen.waywallen`) on KDE Plasma (Wayland) autostarts, but the wallpapers don't come back at login.
Root cause, from `~/.var/app/org.waywallen.waywallen/.local/state/waywallen/logs/daemon/waywallen-current.log`: Plasma's `org.waywallen.kde` plugin registers each screen twice. The first registration is a placeholder `qml-display` 1920x1080 that disconnects about 0.5 s later. The second is the real monitor. The startup recall targets the stale display IDs: `task 'wallpaper/recall/N' failed: display N is not registered`. This is an upstream bug.

## What it does
`~/.config/systemd/user/waywallen-recall-fix.service` (WantedBy=graphical-session.target) runs `~/.local/bin/waywallen-recall-fix.sh`. The script polls the daemon log for up to 3 minutes after login. It restarts the daemon only if the recall failed: `flatpak kill`, then `systemd-run --user --collect flatpak run --command=waywallen org.waywallen.waywallen --no-ui`.

## Tried / avoid
- Editing `~/.config/autostart/org.waywallen.waywallen.desktop` (e.g. adding a delay) doesn't stick: waywallen rewrites that file through the portal whenever its UI opens.

## Status
- 2026-11-17: manual restart workaround verified. Script installed, and the healthy path ("recall succeeded; nothing to do") was checked.
- The restart path at a real login is **untested**. Remove this component once upstream fixes the race.

## Related setup (manual)
- Flatpak `org.waywallen.waywallen` with `flatpak override --user --filesystem=/mnt/x/SteamLibrary:ro`.
- The KDE plugin `org.waywallen.kde` comes from `waywallen-kde-0.4.6-x86_64.zip` via `kpackagetool6 --type Plasma/Wallpaper -i`. The open-wallpaper-engine plugin 0.3.3 was installed in the app's UI.
