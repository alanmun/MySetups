# sudo-pwfeedback

## Why
User preference: show `*` for each character typed at a sudo password prompt.

## What it does
Installs `/etc/sudoers.d/10-pwfeedback` with `Defaults pwfeedback` (validated with `visudo -c` before install).

## Status
- Active on xbox720 since ~2026-11-16. The repo copy is reconstructed from `sudo -l` because the live file is root-only, so `--status` shows UNREADABLE. Check it with `sudo cat /etc/sudoers.d/10-pwfeedback`.
