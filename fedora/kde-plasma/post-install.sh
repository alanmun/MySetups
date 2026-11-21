#!/usr/bin/env bash
# Apply the KDE Plasma settings that live in rc files KDE rewrites itself, so
# they can't be symlinked. Safe to re-run. See README.md for the why of each.
set -euo pipefail

command -v kwriteconfig6 >/dev/null 2>&1 || { echo "KDE Plasma 6 not found; skipping."; exit 0; }
w() { kwriteconfig6 "$@"; }

# Power (AC only; battery profiles untouched): never auto-suspend, dim after
# 5 min, screens off after 30 min, don't lock when the screens turn off.
w --file powerdevilrc --group AC --group SuspendAndShutdown --key AutoSuspendAction 0
w --file powerdevilrc --group AC --group Display --key DimDisplayWhenIdle true
w --file powerdevilrc --group AC --group Display --key DimDisplayIdleTimeoutSec 300
w --file powerdevilrc --group AC --group Display --key TurnOffDisplayWhenIdle true
w --file powerdevilrc --group AC --group Display --key TurnOffDisplayIdleTimeoutSec 1800
w --file powerdevilrc --group AC --group Display --key LockBeforeTurnOffDisplay false

# Screen locker: no idle autolock, but lock after waking from sleep.
w --file kscreenlockerrc --group Daemon --key Autolock false
w --file kscreenlockerrc --group Daemon --key LockOnResume true

# Night Light (replaces f.lux): 3400 K from 18:00 to 07:00.
w --file knighttimerc --group General --key Source Times
w --file knighttimerc --group Times --key SunsetStart 18:00:00
w --file knighttimerc --group Times --key SunriseStart 07:00:00
w --notify --file kwinrc --group NightColor --key NightTemperature 3400
w --notify --file kwinrc --group NightColor --key Active true

# KWin: the two scripts from home/.local/share/kwin/scripts, and no blue
# screen-edge glow.
w --file kwinrc --group Plugins --key no-attentionEnabled true
w --file kwinrc --group Plugins --key activity-first-desktopEnabled true
w --file kwinrc --group Plugins --key screenedgeEnabled false

# Window rule: Steam games fullscreen with no title bar.
rule=baa9e6de-9b66-4a78-8080-e5a88baa857d
order="$(kreadconfig6 --file kwinrulesrc --group General --key Order)"
if ! grep -q "$rule" <<<"$order"; then
  w --file kwinrulesrc --group General --key Order "${order:+$order,}$rule"
fi
w --file kwinrulesrc --group "$rule" --key Description "Steam games: fullscreen, no title bar"
w --file kwinrulesrc --group "$rule" --key wmclass '^steam_app_\d+$'
w --file kwinrulesrc --group "$rule" --key wmclassmatch 3
w --file kwinrulesrc --group "$rule" --key wmclasscomplete false
w --file kwinrulesrc --group "$rule" --key types 1
w --file kwinrulesrc --group "$rule" --key fullscreen true
w --file kwinrulesrc --group "$rule" --key fullscreenrule 2
w --file kwinrulesrc --group "$rule" --key decorationpolicy none
w --file kwinrulesrc --group "$rule" --key decorationpolicyrule 2

dbus-send --session --dest=org.kde.KWin /KWin org.kde.KWin.reconfigure 2>/dev/null || true

# Dolphin: one view setting for every folder, with hidden files shown.
w --file dolphinrc --group General --key GlobalViewProps true
g="$HOME/.local/share/dolphin/view_properties/global"
mkdir -p "$g"
if command -v setfattr >/dev/null 2>&1 &&
   ! getfattr --only-values -n 'user.kde.fm.viewproperties#1' "$g" 2>/dev/null | grep -q 'HiddenFilesShown=true'; then
  setfattr -n 'user.kde.fm.viewproperties#1' \
    -v "$(printf '[Dolphin]\nVersion=4\n\n[Settings]\nHiddenFilesShown=true\n')" "$g" || true
fi

# Silence the "remote desktop started" popup that yada's paste triggers.
w --file xdg-desktop-portal-kde.notifyrc --group Event/remotedesktopstarted --key Action ""

# Plasma style with the translucent dock.
plasma-apply-desktoptheme glass-dock >/dev/null 2>&1 || echo "Could not apply the glass-dock theme (is Plasma running?)."

# AirPods: stay on A2DP instead of switching to the poor headset profile.
command -v wpctl >/dev/null 2>&1 && wpctl settings --save bluetooth.autoswitch-to-headset-profile false >/dev/null || true

# Images open in XnView MP, if installed.
if flatpak info com.xnview.XnViewMP >/dev/null 2>&1; then
  # shellcheck disable=SC2046
  xdg-mime default com.xnview.XnViewMP.desktop $(grep '^image/' /usr/share/mime/types) 2>/dev/null
fi

# The activity-first-desktop script names the Scratch activity by ID.
id="$(grep -o '[0-9a-f-]\{36\}' "$HOME/.local/share/kwin/scripts/activity-first-desktop/contents/code/main.js" | head -1)"
if ! dbus-send --session --print-reply --dest=org.kde.ActivityManager /ActivityManager/Activities \
     org.kde.ActivityManager.Activities.ListActivities 2>/dev/null | grep -q "$id"; then
  echo "Note: activity $id (Scratch) doesn't exist here; see kde-plasma/README.md."
fi
echo "KDE settings applied. Some take effect after logging out and back in."
