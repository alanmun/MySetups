# xbox720: how this install was built

Reference only. Most of this is tied to this machine's disks. A laptop should use the normal Fedora KDE installer and then `fedora/install.sh`.

## Install (2026-11-16)
- Installed **from WSL** with no USB stick: a `fedora:latest` docker container (`fedinst`) chrooted into the target at `/mnt/sysroot`.
  `dnf --installroot --releasever=45 install @kde-desktop-environment fedora-release-kde plasma-setup kernel kernel-modules-extra grub2-efi-x64 grub2-efi-x64-modules grub2-tools shim-x64 efibootmgr dracut-config-generic btrfs-progs e2fsprogs dosfstools glibc-langpack-en langpacks-en`
- A GNOME Workstation install came first and was wiped. Pop!_OS was deleted to make room.
- Then: SELinux relabel (`setfiles -F` plus `/.autorelabel`), `systemctl preset-all`, `set-default graphical.target`, hostname `xbox720`, `LANG=en_US.UTF-8`, `KEYMAP=us`.
- `/etc/dracut.conf.d/00-install-generic.conf` (`hostonly="no"`) was needed because of the chroot install. It can be removed now.
- `reference/finish-wsl-carryover`: the one-time first-login script. It moved WSL files into `~`, fixed `/home/alanmun` paths, ran MySetups, and installed nvm, Node, Codex and Claude Code, Syncthing and the ComfyUI data. The leftover `/home/wsl-carryover/` can be deleted.

## Disks (Samsung 970 EVO Plus 2 TB, nvme0n1)
- p6 ESP 1G vfat, mounted at `/boot/efi`. p7 `/boot` 2G ext4. p8 btrfs label `fedora`, subvolumes `root` and `home`, `compress=zstd:1`.
- 2026-11-18: D: (p4, NTFS TWOTEEBEE) was shrunk from 1400G to 400G (`ntfsresize`, `sfdisk`, then `ntfsresize --force` and `ntfsfix -d` to fix up). The new p9 (1000G) was added to the root btrfs with `btrfs device add`, so root now spans p8+p9. Partition-table backups are in `/root/nvme0n1-partition-table-*.sfdisk`.
- 2026-11-18: `EFI/Microsoft` was removed from the old ESP on this disk, because Windows Automatic Repair kept targeting the dead Windows on D:. Backup: `/root/esp2tb-backup-2026-11-18.tar`.

## Boot
- Kernel command line (`/etc/kernel/cmdline` and the BLS entries): `root=UUID=95b5064d-… ro rootflags=subvol=root rhgb quiet` plus the nouveau blacklist that akmod-nvidia adds. `grub2-mkconfig` inside the container wrote `root=/dev/sdg8`, which was sed-fixed to the UUID.
- `/etc/default/grub`: see `xbox720-default-grub` (5 s timeout, saved default, os-prober off).
- UEFI entry: added from Windows with `bcdedit /copy {bootmgr} /d Fedora` and `path \EFI\fedora\shimx64.efi`, last in `{fwbootmgr}`. The old `GRUB_via_Pop_OS` entry was deleted. Don't re-run `fedora-detach.ps1`; it would duplicate the entry.
- Secure Boot is **off**, because the akmod-nvidia and xone DKMS modules are unsigned.

## ComfyUI / Docker (lives in `~/Repositories/ss2/Comfy-Container`)
- `run` is the Linux port of `start_comfy.ps1`. Image `yanwk/comfyui-boot:cu130-slim-py312`, volume `comfy_storage`.
- ACLs let `me` browse the volume without sudo: `setfacl -m u:me:--x /var/lib/docker /var/lib/docker/volumes /var/lib/docker/volumes/comfy_storage`, plus recursive and default `u:me:rwX` on `_data/ComfyUI`. `run` reapplies them on every start.

## Games (manual)
- Mewtator 0.6.0 is in `~/Downloads/Mewtator` (launcher `mewtator.desktop`; `config.json` points at the Fedora Steam paths and Proton Experimental).
- Isaac Repentance `options.ini` in the Proton prefix of appid 250900: `Fullscreen=1 Filter=0 MaxScale=99 MaxRenderScale=99`. Proton 11 is selected in Steam. Picture quality is still unresolved.
