# nvidia

## Why
RTX 4090 on xbox720: the proprietary driver for gaming and CUDA, and GPU access from Docker (ComfyUI).

## What it does
`post-install.sh` installs `akmod-nvidia xorg-x11-drv-nvidia-cuda libva-nvidia-driver xorg-x11-drv-nvidia-libs.i686` from RPM Fusion. It then installs `nvidia-container-toolkit` (repo file in `root/`) and runs `nvidia-ctk runtime configure --runtime=docker`, which writes `/etc/docker/daemon.json`. The akmod adds the nouveau blacklist to the kernel command line itself.

## Notes
- No modeset or NVreg tweaks were needed.
- Secure Boot is off on xbox720. With it on, you need MOK enrolment for akmods.
- **Open**: the container-toolkit GPG key was never imported, so dnf prompts. On xbox720 it was worked around with `--disablerepo=nvidia-container-toolkit`. Fingerprint: C95B 321B 61E8 8C18 09C4 F759 DDCA E044 F796 ECB0.

## Status
- 2026-11-16: driver 620.70.06 installed during the chroot install. Docker GPU works.
