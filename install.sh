#!/usr/bin/env bash
set -euo pipefail

# Usage: bash ./install.sh
# Installs shared bash config, audited Herdr plugins, zellij plugins, and shared
# agent skills for this machine/profile.

if [ -z "${BASH_VERSION:-}" ]; then
  echo "This installer must be run with bash." >&2
  exit 1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash "$script_dir/install-bash-folder.sh"
if command -v herdr >/dev/null 2>&1; then
  bash "$script_dir/install-herdr-plugins.sh"
else
  echo "Skipping Herdr plugins because herdr is not installed."
fi
bash "$script_dir/install-zellij-plugins.sh"
bash "$script_dir/install-agent-skills.sh"
