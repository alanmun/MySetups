#!/usr/bin/env bash
set -euo pipefail

# Usage: bash ./install-tailscale.sh [--install] [--check]
# Prepares this machine's Tailscale for T3 Code remote access (see README).
#   --install  Install Tailscale first when it is missing (winget on Windows,
#              Tailscale's install script on Linux; asks for admin or sudo).
#   --check    Report only. Change nothing and never ask for sudo.
# Exits 0 when Tailscale is missing or logged out, so the full setup can call it
# on any machine.

main() {
  local install=false check=false arg
  for arg in "$@"; do
    case "$arg" in
      --install) install=true ;;
      --check) check=true ;;
      *) echo "Unknown option: $arg" >&2; return 1 ;;
    esac
  done

  local windows=false
  case "$(uname -s)" in MSYS*|MINGW*) windows=true ;; esac

  local ts
  ts="$(find_tailscale)"
  if [ -z "$ts" ] && $install && ! $check; then
    if $windows; then
      winget install --id Tailscale.Tailscale --exact --accept-source-agreements --accept-package-agreements
    else
      curl -fsSL https://tailscale.com/install.sh | sh
    fi
    ts="$(find_tailscale)"
  fi
  if [ -z "$ts" ]; then
    echo "Tailscale is not installed; skipping. Install it with: bash ./install-tailscale.sh --install"
    return 0
  fi

  local status
  if ! status="$("$ts" status --json 2>/dev/null)" || ! grep -q '"BackendState": "Running"' <<<"$status"; then
    echo "Tailscale is installed but not signed in; skipping. Sign in with 'tailscale up' (Linux: sudo), then run this again."
    return 0
  fi

  local prefs
  prefs="$("$ts" debug prefs 2>/dev/null || true)"

  # T3 Code runs 'tailscale serve' as the logged-in user. Linux allows that only
  # for root or the operator user.
  if ! $windows && ! grep -q "\"OperatorUser\": \"$USER\"" <<<"$prefs"; then
    if $check; then
      echo "Tailscale operator is not $USER, so T3 Code cannot publish itself. Fix: bash ./install-tailscale.sh"
    else
      sudo "$ts" set --operator="$USER"
      echo "Set Tailscale operator to $USER."
    fi
  fi

  if ! $check; then
    # Shields-up would block the phone from reaching Tailscale Serve.
    "$ts" set --shields-up=false
    # Some Linux packages leave updates to the package manager and refuse this.
    "$ts" set --auto-update=true 2>/dev/null || echo "Tailscale auto-update is not available here; update it with the package manager."
  elif grep -q '"ShieldsUp": true' <<<"$prefs"; then
    echo "Tailscale shields-up is on, which blocks remote access. Fix: bash ./install-tailscale.sh"
  fi

  local domain
  domain="$(grep -A1 '"CertDomains": \[' <<<"$status" | sed -n 's/^ *"\(.*\)",\{0,1\}$/\1/p')"
  if [ -z "$domain" ]; then
    echo "HTTPS certificates are off for this tailnet. Turn them on at https://login.tailscale.com/admin/dns"
  else
    echo "Tailscale is ready. T3 Code publishes itself at https://$domain"
  fi
}

find_tailscale() {
  if command -v tailscale >/dev/null 2>&1; then
    command -v tailscale
  elif [ -x "/c/Program Files/Tailscale/tailscale.exe" ]; then
    echo "/c/Program Files/Tailscale/tailscale.exe"
  fi
}

main "$@"
