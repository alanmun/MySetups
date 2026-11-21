# zram

## Why
Compressed RAM swap headroom for ComfyUI and Docker workloads on the 64 GB desktop.

## What it does
`/etc/systemd/zram-generator.conf`: `zram-size = 24576` (MiB), `compression-algorithm = zstd`. Applies at the next boot, or `sudo systemctl restart systemd-zram-setup@zram0`.

## Notes
- Fedora's default is min(RAM, 8 GiB). On a laptop with less RAM, lower the size or skip this component.

## Status
- 2026-11-18: active on xbox720 (zram0 = 24G). The user wrote the file via `!` on Claude's advice.
