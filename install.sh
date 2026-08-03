#!/usr/bin/env bash
set -euo pipefail

# Usage: bash ./install.sh
# Installs shared Bash config, Codex profiles, audited Herdr plugins, Zellij
# plugins, and shared agent skills for this machine/profile.

if [ -z "${BASH_VERSION:-}" ]; then
  echo "This installer must be run with bash." >&2
  exit 1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash "$script_dir/install-bash-folder.sh"
bash "$script_dir/install-codex-profiles.sh"
if command -v herdr >/dev/null 2>&1; then
  if herdr server reload-config >/dev/null 2>&1; then
    echo "Reloaded Herdr config."
  else
    echo "Herdr server is not running; config will apply on its next launch."
  fi

  herdr_platform="$(uname -s):$(uname -m)"
  if [ "$herdr_platform" = "Linux:x86_64" ]; then
    bash "$script_dir/install-herdr-plugins.sh"
  else
    echo "Skipping audited Herdr plugins because no artifact is locked for $herdr_platform."
  fi
else
  echo "Skipping Herdr plugins because herdr is not installed."
fi
bash "$script_dir/install-zellij-plugins.sh"
bash "$script_dir/install-agent-skills.sh"
