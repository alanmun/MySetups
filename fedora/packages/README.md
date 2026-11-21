# packages

## What it does
- Repo files in `root/etc/yum.repos.d/`: VS Code, Docker CE, Mullvad. RPM Fusion free and nonfree come from their release RPMs. Flathub is added for the whole system.
- `dnf-packages.txt`: the curated package set installed on xbox720. `flatpaks.txt`: Flathub apps.
- Enables docker and containerd, adds the user to `docker`, enables the syncthing user unit.
- `~/.config/uv/uv.toml`: `python-downloads = "automatic"`. It overrides Fedora's `/etc/uv/uv.toml` ("manual"), so uv fetches the Python a project pins (Shed pins 3.12).
- `snapshot-userinstalled.txt`: the full `dnf repoquery --userinstalled` on 2026-11-21, for reference only. It includes the base install, because the chroot install marked everything as user-installed.

## Not scripted
- **veracrypt**: rpm from veracrypt.fr.
- **google-chrome-stable**: Google's rpm, which adds its own repo.
- **LM Studio**: AppImage at `/opt/lm-studio/LM-Studio.AppImage`, with `/usr/share/applications/lm-studio.desktop` (`Exec=/opt/lm-studio/LM-Studio.AppImage %U`, `Icon=applications-science`).
- **Mullvad**: log in and run `mullvad lan set allow`, so Docker's bridge network works.
- **waywallen**: `flatpak override --user --filesystem=/mnt/x/SteamLibrary:ro org.waywallen.waywallen` (Wallpaper Engine workshop content). Install the KDE wallpaper plugin with `kpackagetool6 --type Plasma/Wallpaper -i waywallen-kde-*.zip`.
- **NVIDIA**: see `nvidia`.

## Status
- 2026-11-16 to 11-20: installed on xbox720. Java 17 and pandoc weren't available in F45 repos at install time.
