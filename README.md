# MySetups
Personal setup repo for:
- AutoHotkey scripts
- Shared Bash environment config (Debian RPi, WSL2 Ubuntu, MSYS2 UCRT64 on Windows)
- Shared Codex config profiles
- Shared agent skills for Codex and Claude Code

Run the full setup with:

```bash
bash ./install.sh
```

## AutoHotkey Notes
In short:
- `BetterKeys.ahk` is for laptops (includes brightness changes).
- `BetterKeysMediaOnly.ahk` is for desktops.

To auto-start a script on Windows:
1. Find your script, right-click it, then select "Create Shortcut".
2. Press `Win + R`.
3. Run `shell:startup`.
4. Drag and drop the shortcut into that startup folder.
5. If needed, try `shell:common startup` instead.

To use original function keys (`F5`, `F6`, `F10`, `F11`, `F12`) that are rebound, hold `Shift` while pressing them.

## Shared Bash Folder
Common environment files live under `bash/` and can be installed separately by running:

```bash
bash ./install-bash-folder.sh
```

What the installer currently does:
- Symlinks every file from repo `bash/` into your target home (default: `~`), preserving paths.
- Backs up an existing target file to `.BAK` (or `.BAK.<timestamp>` if `.BAK` already exists) before relinking.
- Installs or updates the tmux plugin manager at `~/.tmux/plugins/tpm`.
- Installs or updates `tmux-resurrect` and `tmux-continuum` at `~/.tmux/plugins/` so tmux persistence works immediately on each machine.
- Does not delete unrelated existing files in the target home.
- Because the target files are symlinked, pulling new changes in this repo updates `~/.bashrc`, `~/.vimrc`, `~/.tmux.conf`, etc. automatically.

If you still want the old copy behavior for a one-off install, run:

```bash
MYSETUPS_INSTALL_MODE=copy bash ./install-bash-folder.sh
```

If you want to skip TPM installation or update during bootstrap, run:

```bash
MYSETUPS_INSTALL_TMUX_TPM=0 bash ./install-bash-folder.sh
```

If you want to skip installing or updating `tmux-resurrect` and `tmux-continuum`, run:

```bash
MYSETUPS_INSTALL_TMUX_PLUGINS=0 bash ./install-bash-folder.sh
```

Current files in `bash/` include:
- `bash/.bashrc`
- `bash/.vimrc`
- `bash/.tmux.conf`
- `bash/.config/nvim/init.lua`

The Neovim config installs to `~/.config/nvim/init.lua`, which Neovim picks up by default on Linux, WSL, and MSYS2. On a machine running Windows-native Neovim (outside MSYS2), point it at this same file by setting `XDG_CONFIG_HOME` to `%USERPROFILE%\.config` or junctioning `%LOCALAPPDATA%\nvim` to `%USERPROFILE%\.config\nvim`.

## Shared Codex Profiles

Personal Codex config profiles live under `codex/` and can be installed separately by running:

```bash
bash ./install-codex-profiles.sh
```

The installer symlinks each `*.config.toml` profile into `${CODEX_HOME:-~/.codex}`. The shared Bash config aliases `codex` to `codex --profile claude-style`, so interactive Codex CLI sessions automatically load `codex/claude-style.config.toml`. Because the installed profile is a symlink, pulling changes in this repository updates the active profile immediately.

For one-off copy behavior or a different Codex home, run:

```bash
MYSETUPS_INSTALL_MODE=copy \
MYSETUPS_CODEX_HOME="$HOME/.codex-work" \
bash ./install-codex-profiles.sh
```

Current shared Codex profiles include:
- `codex/claude-style.config.toml`

## Shared Agent Skills
Personal, non-project-specific agent skills live under `agent-skills/` and can be installed separately by running:

```bash
bash ./install-agent-skills.sh
```

What the installer currently does:
- Symlinks each skill folder into Codex skills at `${CODEX_HOME:-~/.codex}/skills`.
- Symlinks each skill folder into Claude Code skills at `~/.claude/skills`.
- Backs up an existing target skill folder to `.BAK` (or `.BAK.<timestamp>` if `.BAK` already exists) before relinking.
- Does not delete unrelated existing skills.
- Because the target folders are symlinked, pulling new changes in this repo updates the installed skills automatically.

If you want copy behavior for a one-off install, run:

```bash
MYSETUPS_INSTALL_MODE=copy bash ./install-agent-skills.sh
```

If you want to install into a different profile or skip one agent, set the target directory env vars:

```bash
MYSETUPS_CODEX_SKILLS_DIR="$HOME/.codex-work/skills" \
MYSETUPS_CLAUDE_SKILLS_DIR="" \
bash ./install-agent-skills.sh
```

Current shared agent skills include:
- `agent-skills/grill-me`
