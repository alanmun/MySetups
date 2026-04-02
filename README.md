# MySetups
Personal setup repo for:
- AutoHotkey scripts
- Shared Bash environment config (Debian RPi, WSL2 Ubuntu, MSYS2 UCRT64 on Windows)

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
Common environment files live under `bash/` and are installed by running:

```bash
bash ./install-bash-folder.sh
```

What the installer currently does:
- Symlinks every file from repo `bash/` into your target home (default: `~`), preserving paths.
- Backs up an existing target file to `.BAK` (or `.BAK.<timestamp>` if `.BAK` already exists) before relinking.
- Does not delete unrelated existing files in the target home.
- Because the target files are symlinked, pulling new changes in this repo updates `~/.bashrc`, `~/.vimrc`, `~/.tmux.conf`, etc. automatically.

If you still want the old copy behavior for a one-off install, run:

```bash
MYSETUPS_INSTALL_MODE=copy bash ./install-bash-folder.sh
```

Current files in `bash/` include:
- `bash/.bashrc`
- `bash/.vimrc`
- `bash/.tmux.conf`
