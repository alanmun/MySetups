# MySetups
Personal setup repo for:
- AutoHotkey scripts
- Shared Bash environment config (Debian RPi, WSL2 Ubuntu, MSYS2 UCRT64 on Windows)
- Shared Codex config profiles
- Audited and commit-pinned Herdr plugins
- Shared agent skills for Codex and Claude Code

Run the full setup with:

```bash
bash ./install.sh
```

## AutoHotkey Notes
In short:
- `BetterKeys.ahk` is for laptops (includes brightness changes).
- `BetterKeysMediaOnly.ahk` is for desktops.
- `SetDefaultBrowser.ahk` keeps a per-machine table of Browser Tamer profile ids, because Chrome numbers profile folders in creation order. Add a machine by its computer name (`echo %COMPUTERNAME%`); unlisted machines use the defaults and the script warns on startup if its Chrome profile folder is missing.

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
- Keeps one rolling `.BAK` per managed target, overwriting the previous backup
  before relinking and removing legacy timestamped backups.
- Installs or updates the tmux plugin manager at `~/.tmux/plugins/tpm`.
- Installs or updates `tmux-resurrect` and `tmux-continuum` at `~/.tmux/plugins/` so tmux persistence works immediately on each machine.
- On MSYS2, replaces `tmux-continuum`'s status-bar polling with one lightweight
  sleeping worker that autosaves every 15 minutes. This preserves automatic
  persistence without process storms during redraw-heavy terminal apps.
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
- `bash/.config/herdr/config.toml`
- `bash/.config/nvim/init.lua`

The Herdr config installs to `~/.config/herdr/config.toml`. Under MSYS2, the
installer also hard-links it to `%APPDATA%\herdr\config.toml`, which is where
native Windows Herdr reads configuration. If the repo and AppData are on
different filesystems, it copies the file instead; rerun the installer after
pulling config changes to refresh that copy.

## Audited Herdr Plugins

Install the locked Herdr plugins separately with:

```bash
bash ./install-herdr-plugins.sh
```

The installer reads the audited revision and artifact digests from
`herdr-plugins/herdr-reviewr.lock.json`. It installs the exact commit, verifies
Herdr's requested and resolved revisions, verifies the installed binary's
SHA-256 digest, and validates the plugin configuration. It never follows the
plugin's `main` branch.

An installed revision that differs from the lock is left untouched. After
auditing a new release and updating its lock, permit that one replacement with:

```bash
MYSETUPS_REPLACE_HERDR_PLUGINS=1 bash ./install-herdr-plugins.sh
```

The current lock covers Linux x86-64 only. The full setup skips plugin
installation on other platforms. A release for another platform must be audited
and added to the lock before installation.

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
- Keeps one rolling `.BAK` per managed skill, overwriting the previous backup
  before relinking and removing legacy timestamped backups.
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
- `agent-skills/tldr`
