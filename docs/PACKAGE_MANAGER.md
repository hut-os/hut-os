# Package management — deferred for HUT OS 3.0

## Decision

HUT OS does **not** ship a package manager in v3.0.

## Why

Lightweight candidates (opkg, apk, pacman) each need a full package
repository / buildroot-style toolchain. Adding one cleanly would:

- Multiply initramfs/disk size
- Require host-side package build pipelines
- Pull in libc/ABI policies beyond BusyBox + hosted Zsh

## Future options (when needed)

| Manager | Fit | Notes |
|---------|-----|-------|
| **opkg** | Good for embedded | Needs OpenWrt-style feeds |
| **apk** (Alpine) | Clean, small | Needs Alpine package index + musl alignment |
| **static binaries** | Simplest now | Drop files into rootfs and rebuild |

## Current workflow

Add software by placing binaries/scripts in `rootfs/` and running:

```bash
./build.sh
```

This keeps HUT OS educational, reproducible, and small.
