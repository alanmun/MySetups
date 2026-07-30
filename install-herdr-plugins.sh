#!/usr/bin/env bash
set -euo pipefail

# Usage: bash ./install-herdr-plugins.sh
# Installs the audited Herdr plugins at their exact locked commits and verifies
# the installed binaries. Set MYSETUPS_REPLACE_HERDR_PLUGINS=1 only after
# reviewing and updating the corresponding lock file.

if [ -z "${BASH_VERSION:-}" ]; then
  echo "This installer must be run with bash." >&2
  exit 1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
lock_file="$script_dir/herdr-plugins/herdr-reviewr.lock.json"
replace_plugins="${MYSETUPS_REPLACE_HERDR_PLUGINS:-0}"

case "$replace_plugins" in
  0|1)
    ;;
  *)
    echo "Unsupported MYSETUPS_REPLACE_HERDR_PLUGINS value: $replace_plugins" >&2
    echo "Use 1 to replace an installed revision or 0 to refuse replacement." >&2
    exit 1
    ;;
esac

for command_name in herdr jq sha256sum; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "Required command is not installed: $command_name" >&2
    exit 1
  fi
done

if [ "$(uname -s)" != "Linux" ] || [ "$(uname -m)" != "x86_64" ]; then
  echo "No audited herdr-reviewr artifact is locked for $(uname -s)/$(uname -m)." >&2
  exit 1
fi

plugin_id="$(jq -er '.plugin_id' "$lock_file")"
source_repo="$(jq -er '.source' "$lock_file")"
expected_version="$(jq -er '.version' "$lock_file")"
expected_commit="$(jq -er '.commit' "$lock_file")"
expected_binary_sha256="$(jq -er '.artifacts["x86_64-unknown-linux-musl"].binary_sha256' "$lock_file")"

plugin_json="$(herdr plugin list --plugin "$plugin_id" --json)"
plugin_count="$(jq -er '.result.plugins | length' <<<"$plugin_json")"
restore_disabled=0

if [ "$plugin_count" -gt 1 ]; then
  echo "Herdr returned multiple installations for $plugin_id." >&2
  exit 1
fi

if [ "$plugin_count" -eq 1 ]; then
  installed_commit="$(jq -er '.result.plugins[0].source.resolved_commit' <<<"$plugin_json")"
  requested_ref="$(jq -er '.result.plugins[0].source.requested_ref' <<<"$plugin_json")"
  installed_version="$(jq -er '.result.plugins[0].version' <<<"$plugin_json")"

  if [ "$installed_commit" != "$expected_commit" ] ||
    [ "$requested_ref" != "$expected_commit" ] ||
    [ "$installed_version" != "$expected_version" ]; then
    if [ "$replace_plugins" != "1" ]; then
      echo "$plugin_id does not match the audited lock." >&2
      echo "Installed: version=$installed_version requested_ref=$requested_ref commit=$installed_commit" >&2
      echo "Locked:    version=$expected_version requested_ref=$expected_commit commit=$expected_commit" >&2
      echo "Review the new revision, update the lock, then rerun with MYSETUPS_REPLACE_HERDR_PLUGINS=1." >&2
      exit 1
    fi

    if [ "$(jq -er '.result.plugins[0].enabled' <<<"$plugin_json")" = "false" ]; then
      restore_disabled=1
    fi
    herdr plugin disable "$plugin_id"
    herdr plugin uninstall "$plugin_id"
    plugin_count=0
  fi
fi

if [ "$plugin_count" -eq 0 ]; then
  herdr plugin install "$source_repo" --ref "$expected_commit" -y
  if [ "$restore_disabled" = "1" ]; then
    herdr plugin disable "$plugin_id"
  fi
  plugin_json="$(herdr plugin list --plugin "$plugin_id" --json)"
fi

plugin_root="$(jq -er --arg commit "$expected_commit" --arg version "$expected_version" '
  .result.plugins[0]
  | select(.source.requested_ref == $commit)
  | select(.source.resolved_commit == $commit)
  | select(.version == $version)
  | .plugin_root
' <<<"$plugin_json")"
binary="$plugin_root/bin/herdr-reviewr"
actual_binary_sha256="$(sha256sum "$binary" | cut -d ' ' -f 1)"

if [ "$actual_binary_sha256" != "$expected_binary_sha256" ]; then
  herdr plugin disable "$plugin_id"
  echo "Installed binary digest does not match the audited lock; disabled $plugin_id." >&2
  echo "Expected: $expected_binary_sha256" >&2
  echo "Actual:   $actual_binary_sha256" >&2
  exit 1
fi

plugin_config_dir="$(herdr plugin config-dir "$plugin_id")"
HERDR_PLUGIN_CONFIG_DIR="$plugin_config_dir" "$binary" --resolve-plugin-config >/dev/null

echo "Verified $plugin_id $expected_version at $expected_commit"
echo "Binary SHA-256: $actual_binary_sha256"
