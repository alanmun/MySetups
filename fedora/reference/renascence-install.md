# renascence: how this install was built

Backup desktop: Ryzen 5 3600X, Gigabyte GA-AB350-Gaming 3 (BIOS F52e), RTX 3070 Ti. Fedora 45 KDE on an external USB HDD (Seagate BUP Slim 500 GB, serial NA4TAK4L), the machine's only storage for now. Built 2026-11-22/23 from the Windows laptop, same approach as `xbox720-install.md`.

## Install
- Built **from WSL** with no USB stick. The `FedoraLinux-45` WSL distro (`wsl --install FedoraLinux-45`) was the build host instead of a docker container. The disk was attached with `wsl --mount \\.\PHYSICALDRIVE<n> --bare` (elevated).
- `dnf --installroot=/mnt/sysroot --releasever=45 --use-host-config install @kde-desktop-environment fedora-release-kde plasma-setup kernel kernel-modules-extra kernel-devel grub2-efi-x64 grub2-efi-x64-modules grub2-tools shim-x64 efibootmgr dracut-config-generic btrfs-progs e2fsprogs dosfstools glibc-langpack-en langpacks-en linux-firmware amd-ucode-firmware firefox flatpak git sudo usbutils pciutils`
- Written **before** the dnf run, so the kernel scriptlets pick them up: `/etc/fstab`, `/etc/kernel/cmdline`, `/etc/machine-id`, and `/etc/dracut.conf.d/00-generic.conf` (`hostonly="no"`). With those in place the BLS entry and initramfs came out right with no fix-up (on xbox720 `root=` had to be sed-fixed). `/proc`, `/sys`, `/dev` were bind-mounted into the target first.
- Then, in the chroot: `systemctl preset-all`, `set-default graphical.target`, `passwd -l root`, hostname `renascence`, `LANG=en_US.UTF-8`, `KEYMAP=us`, `/etc/default/grub` copied from `xbox720-default-grub`, `grub2-mkconfig`, `setfiles -F` plus `/.autorelabel`.
- The user account is created by `plasma-setup` on first boot.
- Keep `00-generic.conf`: the generic initramfs is what lets the disk boot over USB and later from an internal SSD.

## Disk (GPT)
- p1 ESP 1G vfat `/boot/efi`. p2 `/boot` 2G ext4. p3 btrfs label `renascence`, subvolumes `root` and `home`, `compress=zstd:1,noatime`. Everything is mounted by UUID.

## Boot
- No UEFI entry was written from the build machine. The firmware finds `\EFI\BOOT\BOOTX64.EFI` (shim) on the USB disk; shim's fallback then registers an entry from `EFI/fedora/BOOTX64.CSV` and puts it first.
- That CSV was edited so the entry is named **RENASCENCE** (original saved at `/root/BOOTX64.CSV.orig`). A `shim-x64` update rewrites the CSV, but the entry already in NVRAM keeps its name.
- BIOS: CSM off (or pick the `UEFI:` entry in the F12 menu), Secure Boot **off** (akmod-nvidia and xone DKMS are unsigned).
- Kernel command line: `root=UUID=bb12eec4-… ro rootflags=subvol=root rhgb quiet` plus the nouveau/nova_core blacklist.

## Software installed at build time (chroot)
- Repo files from `packages/root/etc/yum.repos.d/`, RPM Fusion free and nonfree, everything in `packages/dnf-packages.txt`, `google-chrome-stable` (Google's rpm), `akmod-nvidia` + `xorg-x11-drv-nvidia-cuda` + `libva-nvidia-driver` + `xorg-x11-drv-nvidia-libs.i686`, `nvidia-container-toolkit`. docker and containerd enabled. Flathub remote added system-wide.
- The NVIDIA module (620.70.06) was pre-built for kernel 7.3.4-300.fc45 with `akmods --force --kernels <kver>` in the chroot, so the first boot doesn't wait for it. `akmods.service` is enabled for later kernels.
- A clone of MySetups at `/opt/MySetups-seed`.
- `/etc/resolv.conf` was a plain file during the build and was put back to the `../run/systemd/resolve/stub-resolv.conf` symlink at the end.

## First login
`renascence-finish-setup` (this folder; installed to `/usr/local/bin`). It copies the seed to `~/Repositories/MySetups`, runs the root `install.sh`, then `fedora/install.sh packages kde-plasma browser-tweaks sudo-pwfeedback ai-killswitch waywallen-recall-fix nvidia xone` (which also installs the flatpaks, waywallen included), builds the xone DKMS driver, and checks the NVIDIA module.

2026-11-23: `xone` was taken out of the default run. The board has no Wi-Fi, and the Xbox Wireless Adapter works as the Wi-Fi dongle through `mt76x2u`, which xone blacklists. The copy in `/usr/local/bin` was patched by hand with sed to match. To give the adapter back to controllers: `bash fedora/install.sh xone && renascence-finish-setup build_xone`.

Not applied here: `front-usb-bt-fix` (xbox720 only), `ntfs-windows-drives` (no Windows disks), `veracrypt`, `zram` (Fedora default kept), `gamepad-8bitdo`.

Still manual: the waywallen KDE wallpaper plugin (`kpackagetool6`, see `packages/README.md`), Mullvad login, the per-machine KDE items in `kde-plasma/README.md`, `SetDefaultBrowser.kde.py --install`, timezone if `plasma-setup` didn't ask.

## Moving to an internal SSD later
1. Partition the SSD the same way (ESP 1G, `/boot` 2G, rest). Copy the ESP and `/boot` contents and give the new partitions fresh filesystems; update their two UUIDs in `/etc/fstab` and the `search --fs-uuid` line in `EFI/fedora/grub.cfg` and `EFI/BOOT/grub.cfg`.
2. Move the root filesystem live: `sudo btrfs replace start <hdd-p3> <ssd-p3> /`, then `sudo btrfs filesystem resize max /`. The btrfs UUID stays the same, so the kernel command line and fstab root lines need no change.
3. Unplug the HDD and boot; shim's fallback registers the SSD's entry.

## Status
- 2026-11-23: built, and booted on the real hardware from the USB HDD.
- First boot: after the `plasma-setup` wizard finished, the screen stayed on a bare text console (keys echo, no login manager) for hours. **Ctrl+Alt+Del** rebooted it and the next boot reached the login screen normally. Cause not investigated; the handoff from `plasma-setup` to `plasmalogin` did not happen on its own.
- The Xbox Wireless Adapter works as a Wi-Fi dongle (`mt76x2u`) while xone is not installed.
- 2026-11-23: first runs of `renascence-finish-setup`. MySetups `install.sh` and the NVIDIA check were OK. The `packages` component failed twice on the Xbox-adapter Wi-Fi (Spotify flatpak download died; then `Could not resolve hostname` for Flathub), and because `fedora/install.sh` stops at the first error, kde-plasma, browser-tweaks, sudo-pwfeedback, ai-killswitch, waywallen-recall-fix and nvidia never ran. The script now runs components one at a time so a failure doesn't skip the rest.
- The hand-typed sed for xone (see above) lost a space, so the xone step still ran; xone's own installer then took the adapter away from Wi-Fi. xone was removed again (`dkms remove`, blacklist deleted). `/usr/src/xone-0.5.8` is left over and harmless.
- 2026-11-25, disk back on the laptop (mounted from the Ubuntu WSL distro, chroot): installed the XnView MP, waywallen and Discord flatpaks system-wide; replaced `/usr/local/bin/renascence-finish-setup` with the fixed version; wrote `/etc/systemd/zram-generator.conf` with `zram-size = ram` and zstd (16 GB RAM, so the `zram` component's fixed 24 GiB doesn't fit). `gamemode` was already installed (use `gamemoderun %command%` in Steam launch options).
- Spotify's flatpak can't be installed from a chroot (`apply_extra script failed`: its extra-data step needs a real sandbox). It installs on the machine itself when `packages` runs with a working connection.
- Ubuntu's `journalctl` can't read the Fedora 45 journal ("unsupported feature"), so the first-boot black screen wasn't diagnosed from the laptop.
- **Still to do on the machine:** `renascence-finish-setup run_fedora_components`. Planned for the SSD move: a 16 GB swap file on the NVMe at lower priority than zram.
