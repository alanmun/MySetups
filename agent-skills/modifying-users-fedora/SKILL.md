---
name: modifying-users-fedora
description: Rules for changing the user's Fedora machines (system config, drivers, systemd units, KDE settings, scripts, packages, workarounds). Use before making or proposing any such change, and when revisiting a past Fedora fix.
---

# Modifying the user's Fedora

1. **Read first.** Check `~/Repositories/MySetups/fedora/` (top-level `README.md` and the component's `README.md`) before changing anything. Don't redo something already marked as failed.
2. **Mirror the work.** Put every script, unit, config file and settings command you create into `MySetups/fedora/<component>/` (layout: `fedora/install.sh` header). Mirror as much as you realistically can. Where a change can't be captured as a file (a DKMS build, a BIOS setting, a one-off command), write down the exact steps.
3. **Document the why.** Every component `README.md` records:
   - **Why**: the problem, its symptoms, and the root cause if known.
   - **What it does**: the files and commands involved.
   - **Tried and failed**: approaches that didn't work, and why.
   - **Status**: verified, untested, or superseded, with dates (YYYY-MM-DD).
   Update it when anything changes, including reverts. Don't delete the history.
4. **Keep it reproducible.** Mark hardware-specific components with `machine:` in `about`. Check that `bash fedora/install.sh --status` shows no drift.
