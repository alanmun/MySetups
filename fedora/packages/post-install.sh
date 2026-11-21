#!/usr/bin/env bash
# Repos, then dnf packages, flatpaks and services. Safe to re-run.
set -euo pipefail
[ "${MYSETUPS_USER_ONLY:-0}" = 1 ] && { echo "Skipping package installs (--user-only)."; exit 0; }
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
v="$(rpm -E %fedora)"
rpm -q rpmfusion-free-release >/dev/null 2>&1 || sudo dnf install -y \
  "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$v.noarch.rpm" \
  "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$v.noarch.rpm"
mapfile -t pkgs < <(grep -vE '^\s*(#|$)' "$here/dnf-packages.txt")
sudo dnf install -y "${pkgs[@]}"
sudo systemctl enable --now docker containerd
id -nG | grep -qw docker || { sudo usermod -aG docker "$USER"; echo "Added $USER to docker (log out and back in)."; }
systemctl --user enable --now syncthing.service || true
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
mapfile -t apps < <(grep -vE '^\s*(#|$)' "$here/flatpaks.txt")
flatpak install -y --noninteractive flathub "${apps[@]}"
echo "Not covered here: veracrypt, google-chrome-stable, LM Studio (see packages/README.md)."
