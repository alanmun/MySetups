#!/usr/bin/env bash
set -euo pipefail

# Usage: bash ./install.sh
# Installs shared bash config, zellij plugins, and shared agent skills for this
# machine/profile.

if [ -z "${BASH_VERSION:-}" ]; then
  echo "This installer must be run with bash." >&2
  exit 1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash "$script_dir/install-bash-folder.sh"
bash "$script_dir/install-zellij-plugins.sh"
bash "$script_dir/install-agent-skills.sh"
