#!/usr/bin/env bash
set -euo pipefail

# Usage: invoked by herdr as the `http` link handler's action; never run this by hand.
#
# VS Code's terminal opens a Ctrl-clicked URL from its own xterm.js link layer, and herdr opens the
# same URL from herdr::platform::linux::open_url, so inside VS Code one click produced two browser
# tabs. The manifest's link handler takes the URL away from herdr's opener; this script hands it
# back only when the click did not come from a herdr client running inside VS Code.

url="${HERDR_PLUGIN_CLICKED_URL:-}"
if [[ -z "${url}" ]]; then
    exit 0
fi

# Clients run as a bare `herdr`; the server they spawn runs as `herdr server` and inherits the env of
# whichever client happened to start it, so matching on the server would suppress every open forever.
for pid in $(pgrep -x herdr); do
    if [[ "$(tr '\0' ' ' < "/proc/${pid}/cmdline" 2>/dev/null)" == *" server "* ]]; then
        continue
    fi

    if grep -qz 'TERM_PROGRAM=vscode' "/proc/${pid}/environ" 2>/dev/null; then
        exit 0
    fi
done

exec xdg-open "${url}"
