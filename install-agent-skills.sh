#!/usr/bin/env bash
set -euo pipefail

# Usage: bash ./install-agent-skills.sh
# Installs personal agent skills from this repo into Codex and Claude Code skill
# directories. Override targets with MYSETUPS_CODEX_SKILLS_DIR and
# MYSETUPS_CLAUDE_SKILLS_DIR, or set either to empty to skip that agent.

if [ -z "${BASH_VERSION:-}" ]; then
  echo "This installer must be run with bash." >&2
  exit 1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
src_dir="$script_dir/agent-skills"
install_mode="${MYSETUPS_INSTALL_MODE:-symlink}"
codex_default_skills_dir="${CODEX_HOME:-$HOME/.codex}/skills"
codex_skills_dir="${MYSETUPS_CODEX_SKILLS_DIR-$codex_default_skills_dir}"
claude_skills_dir="${MYSETUPS_CLAUDE_SKILLS_DIR-$HOME/.claude/skills}"

if [ ! -d "$src_dir" ]; then
  echo "Expected source folder missing: $src_dir" >&2
  exit 1
fi

case "$install_mode" in
  symlink|copy)
    ;;
  *)
    echo "Unsupported install mode: $install_mode" >&2
    echo "Use MYSETUPS_INSTALL_MODE=symlink or MYSETUPS_INSTALL_MODE=copy" >&2
    exit 1
    ;;
esac

backup_path() {
  local original="$1"
  local backup
  local timestamp

  if [ ! -e "$original" ] && [ ! -L "$original" ]; then
    return 0
  fi

  backup="${original}.BAK"
  if [ -e "$backup" ]; then
    timestamp="$(date +%Y%m%d%H%M%S)"
    backup="${original}.BAK.${timestamp}"
  fi

  mv "$original" "$backup"
  echo "Backed up existing path: $original -> $backup"
}

install_skill_to_target() {
  local skill_name="$1"
  local skill_src="$2"
  local target_dir="$3"
  local skill_dest

  if [ -z "$target_dir" ]; then
    return 0
  fi

  skill_dest="$target_dir/$skill_name"
  mkdir -p "$target_dir"

  if [ "$install_mode" = "symlink" ]; then
    if [ -L "$skill_dest" ] && [ "$(readlink "$skill_dest")" = "$skill_src" ]; then
      echo "Already linked: $skill_dest -> $skill_src"
      return 0
    fi

    if [ -e "$skill_dest" ] || [ -L "$skill_dest" ]; then
      backup_path "$skill_dest"
    fi

    ln -s "$skill_src" "$skill_dest"
    echo "Linked $skill_dest -> $skill_src"
    return 0
  fi

  if [ -L "$skill_dest" ]; then
    backup_path "$skill_dest"
  elif [ -d "$skill_dest" ]; then
    backup_path "$skill_dest"
  fi

  mkdir -p "$skill_dest"
  cp -R "$skill_src/." "$skill_dest/"
  echo "Copied $skill_src -> $skill_dest"
}

while IFS= read -r -d '' skill_file; do
  skill_src="$(dirname "$skill_file")"
  skill_name="$(basename "$skill_src")"

  install_skill_to_target "$skill_name" "$skill_src" "$codex_skills_dir"
  install_skill_to_target "$skill_name" "$skill_src" "$claude_skills_dir"
done < <(find "$src_dir" -mindepth 2 -maxdepth 2 -name SKILL.md -print0)

echo "Installed agent skills from $src_dir"
echo "Restart Codex or Claude Code sessions to pick up new skills."
