#!/usr/bin/env bash
# Needs RPM Fusion (install the "packages" component first). Secure Boot must be
# off, or the akmod needs a MOK key enrolled (not done on xbox720: SB is off).
set -euo pipefail
[ "${MYSETUPS_USER_ONLY:-0}" = 1 ] && exit 0
sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda libva-nvidia-driver xorg-x11-drv-nvidia-libs.i686
# Container toolkit. Its GPG key was never imported on xbox720; dnf asks to
# trust it (fingerprint C95B 321B 61E8 8C18 09C4 F759 DDCA E044 F796 ECB0).
sudo dnf install -y nvidia-container-toolkit
if command -v docker >/dev/null 2>&1; then
  sudo nvidia-ctk runtime configure --runtime=docker
  sudo systemctl restart docker
fi
echo "Wait for the akmod build (a few minutes), then reboot: modinfo -F version nvidia"
