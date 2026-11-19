#!/usr/bin/env bash
# KDE Plasma 6 port of RoyalKludgeRKS70.ahk (the RK S70 has no fn row).
#
#   Alt+1 file manager   Alt+2 YouTube      Alt+3 new email   Alt+4 calculator
#   Alt+5 Spotify        Alt+6 stop         Alt+7 previous    Alt+8 play/pause
#   Alt+9 next           Alt+0 mute         Alt+- volume down Alt+= volume up
#
# Volume and media keys are added as extra shortcuts on Plasma's own actions, so
# they get Plasma's volume step and OSD and the real media keys keep working.
# Alt+1..5 are .desktop launchers bound through kglobalaccel, the same way
# System Settings > Shortcuts > "Add Command" does it.
#
# Usage: bash ./RoyalKludgeRKS70.kde.sh            # apply (safe to re-run)
#        bash ./RoyalKludgeRKS70.kde.sh --remove   # undo everything it added
set -euo pipefail

if ! command -v gdbus >/dev/null || ! gdbus introspect --session --dest org.kde.kglobalaccel \
    --object-path /kglobalaccel >/dev/null 2>&1; then
  echo "kglobalaccel is not running; this needs a KDE Plasma session." >&2
  exit 1
fi

ALT=$((0x08000000))
key() { echo $((ALT + $(printf '%d' "'$1"))); }  # Qt key code for Alt+<char>

accel() {
  gdbus call --session --dest org.kde.kglobalaccel --object-path /kglobalaccel \
    --method "org.kde.KGlobalAccel.$1" "${@:2}"
}

# Current key codes bound to an action, one per line (first int of each QKeySequence).
current_keys() {
  accel shortcutKeys "$1" | grep -oE '\[[0-9]+' | tr -d '[' | grep -v '^0$' || true
}

# set_keys <actionId-gvariant> <codes...>
set_keys() {
  local id=$1; shift
  local seqs=() k
  for k in "$@"; do seqs+=("([$k, 0, 0, 0],)"); done
  local IFS=, arr="@a(ai) []"
  [ ${#seqs[@]} -gt 0 ] && arr="[${seqs[*]}]"
  accel setForeignShortcutKeys "$id" "$arr" >/dev/null
}

# add_or_remove <component> <action> <componentFriendly> <actionFriendly> <char>
builtin_binding() {
  local id="['$1', '$2', '$3', '$4']" ours; ours=$(key "$5")
  mapfile -t keep < <(current_keys "$id" | grep -vx "$ours")
  if [ "$MODE" = apply ]; then keep+=("$ours"); fi
  set_keys "$id" "${keep[@]}"
}

APPS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
ALT_N_LAUNCHERS=(
  "1|rks70-file-manager|File Manager|dolphin"
  "2|rks70-youtube|YouTube|xdg-open https://www.youtube.com"
  "3|rks70-new-email|New Email|xdg-open mailto:"
  "4|rks70-calculator|Calculator|kcalc"
  "5|rks70-spotify|Spotify|bash -c \"command -v spotify >/dev/null && exec spotify || flatpak run com.spotify.Client || exec xdg-open https://open.spotify.com\""
)

MODE=apply
[ "${1:-}" = --remove ] && MODE=remove

builtin_binding kmix decrease_volume "Audio Volume" "Decrease Volume" -
builtin_binding kmix increase_volume "Audio Volume" "Increase Volume" =
builtin_binding kmix mute            "Audio Volume" "Mute"            0
builtin_binding mediacontrol stopmedia      "Media Controller" "Stop media playback"       6
builtin_binding mediacontrol previousmedia  "Media Controller" "Media playback previous"   7
builtin_binding mediacontrol playpausemedia "Media Controller" "Play/Pause media playback" 8
builtin_binding mediacontrol nextmedia      "Media Controller" "Media playback next"       9

mkdir -p "$APPS_DIR"
for entry in "${ALT_N_LAUNCHERS[@]}"; do
  IFS='|' read -r n name label exec <<<"$entry"
  file="$name.desktop"
  if [ "$MODE" = apply ]; then
    cat >"$APPS_DIR/$file" <<EOF
[Desktop Entry]
Type=Application
Name=$label (RK S70 Alt+$n)
Exec=$exec
NoDisplay=true
X-KDE-GlobalAccel-CommandShortcut=true
EOF
  fi
done
command -v kbuildsycoca6 >/dev/null && kbuildsycoca6 >/dev/null 2>&1 || true

for entry in "${ALT_N_LAUNCHERS[@]}"; do
  IFS='|' read -r n name label _ <<<"$entry"
  file="$name.desktop"
  id="['$file', '_launch', '$label (RK S70 Alt+$n)', 'Launch $label']"
  if [ "$MODE" = apply ]; then
    accel doRegister "$id" >/dev/null
    set_keys "$id" "$(key "$n")"
  else
    accel unregister "$file" _launch >/dev/null 2>&1 || true
    rm -f "$APPS_DIR/$file"
  fi
done
[ "$MODE" = remove ] && { command -v kbuildsycoca6 >/dev/null && kbuildsycoca6 >/dev/null 2>&1 || true; }

echo "RK S70 hotkeys: ${MODE} done."
