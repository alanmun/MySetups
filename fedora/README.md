# Fedora tweaks

Every change made to the Fedora installs (first: desktop `xbox720`, Fedora 45 KDE Plasma), with the **why** behind it. This folder is the record of what was tried, what worked and what didn't. Agents follow the `modifying-users-fedora` skill (`../agent-skills/`) to keep it current.

```bash
bash fedora/install.sh                      # list components
bash fedora/install.sh packages kde-plasma  # install some
bash fedora/install.sh --status             # drift between repo and this machine
bash fedora/install.sh --user-only <comp>   # skip anything that needs sudo
```

Home files are symlinked into the repo, so edits here are live. System files (`root/`) are copied with sudo and never symlinked, because root shouldn't run code from a user-writable folder. Re-run the component after editing one of them. The full rules are in the `install.sh` header.

## Components
Each folder's `README.md` has the why, what was tried, and the status.

| Component | What | Portable? |
|---|---|---|
| `packages` | Repos, dnf set, flatpaks, docker/syncthing, uv config | yes |
| `kde-plasma` | Power/lock/Night Light/KWin/Dolphin settings, KWin scripts, Steam rule, glass-dock theme, icon swap | yes (Scratch activity ID needs updating) |
| `browser-tweaks` | Chrome kwallet6 + autoscroll launcher, Firefox `user.js` | yes |
| `veracrypt` | Dismount on sleep/logout, detach cleaner, Ctrl+Shift+1/2 | yes |
| `ntfs-windows-drives` | ntfs3 `nocase,windows_names` mount helper, updatedb prune | yes (fstab per machine) |
| `zram` | 24 GiB zstd zram | resize for smaller RAM |
| `sudo-pwfeedback` | `*` at sudo prompts | yes |
| `ai-killswitch` | Kill all Claude Code / Codex processes | yes |
| `waywallen-recall-fix` | Restart waywallen after the login display race | if using waywallen |
| `nvidia` | akmod driver + container toolkit | NVIDIA GPU only |
| `xone` | Xbox Wireless Adapter blacklist + clean unload | Xbox dongle only |
| `gamepad-8bitdo` | Load `xpad` for the 8BitDo dongle (**ineffective**) | 8BitDo only |
| `front-usb-bt-fix` | Rebind wedged chipset USB to restore Bluetooth | xbox720 only |

Related, at the repo root: `SetDefaultBrowser.kde.py` (last-used browser as the default) and `RoyalKludgeRKS70.kde.sh` (keyboard shortcuts). The Fedora-specific `.bashrc` branches are in `bash/.bashrc`: Ctrl+V via wl-paste, the `npm()` wrapper that fixes AWS SSO's xdg-open on KDE 6, and the JAVA_HOME lookup.

`reference/` covers how xbox720 itself was built: install from WSL, disks, boot, UEFI, ComfyUI, games.

## Open items (as of 2026-11-21)
- `gamepad-8bitdo`: xpad vs the xone blacklist, unresolved.
- `nvidia`: import the container-toolkit GPG key.
- Untested: the xone patch after sleep; xone-clean-stop; front-usb-bt-fix and waywallen-recall-fix across a real reboot or login; VeraCrypt logout dismount and the Ctrl+Shift+2 double press; Scratch landing on desktop 1; the Meta+X,U,S sleep shortcut.
- Cleanup on xbox720: `~/stash-backup.hc` (200 GB), `/home/wsl-carryover/`, `/usr/local/bin/veracrypt-dismount-all.bak`, the dracut `hostonly` file, and the Windows `docker_data.vhdx` (900 GB on C:) once ComfyUI is confirmed.
