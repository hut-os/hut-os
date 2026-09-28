# HUT OS Infrastructure Migration Plan

## Current state (v2.1)

- Kernel: Linux 7.3.0-rc5 (bzImage) — **unchanged**
- Boot: QEMU `-kernel` + initramfs only (no disk, no bootloader)
- Rootfs: BusyBox (static) + Zsh/Oh My Zsh + custom `/init` + `about`
- Users: minimal `/etc/passwd` (root → zsh)
- No mdev rules, no networking bring-up, few BusyBox applets linked

## Target architecture

```
Bootloader (GRUB) ──or── QEMU -kernel (dev shortcut)
        ↓
   Linux Kernel
        ↓
   /init (enhanced BusyBox ash script)
        ↓
   mounts · mdev · hostname · loopback/net
        ↓
   banner · Zsh + Oh My Zsh
        ↓
   users · devices · networking · utilities · hutinfo
```

## Component decisions

| Area | Choice | Why |
|------|--------|-----|
| Bootloader | **GRUB2** | Mature, available via `grub-pc-bin`; Limine deferred |
| Persistent FS | **ext4** disk image | Kernel has `CONFIG_EXT4_FS=y`; `mkfs.ext4` on host |
| Users | `/etc/passwd`, `/etc/group`, `/etc/shadow` | Minimal Unix account model |
| Devices | **BusyBox mdev** + existing `devtmpfs` | Already in BusyBox; lighter than udev/eudev |
| Networking | BusyBox `ip`/`ifconfig` + `udhcpc` | Enough for QEMU user/slirp networking |
| Init/services | **Keep custom `/init`** | OpenRC/BusyBox init add complexity without gain yet |
| Utilities | BusyBox applet symlinks | No new binaries |
| System info | Keep `about`; add **`hutinfo`** | Lightweight |
| Package mgr | **Deferred** | opkg/apk need full buildroot; would bloat HUTOS |

## Implementation order

1. Expand BusyBox symlinks (mount, ps, kill, dmesg, ifconfig, mdev, …)
2. User/system files (`passwd`, `group`, `shadow`, `hostname`, `os-release`, `mdev.conf`, `hosts`)
3. Upgrade `/init` (mdev, hostname, lo, optional eth0 + DHCP)
4. Add `hutinfo`; preserve `about` / banner / Zsh
5. Build scripts: rootfs → initramfs → **ext4 disk** → optional **GRUB ISO**
6. Unified `./build.sh` + `./run.sh` / `./run-disk.sh`
7. QEMU verify both boot paths

## Boot paths after upgrade

1. **Fast (unchanged):** `-kernel` + `-initrd` (initramfs)
2. **Disk:** `-kernel` + `-drive file=hutos.img` + `root=/dev/sda1`
3. **ISO (if GRUB tools present):** bootable ISO with GRUB → kernel → root on ISO/disk

## Explicitly out of scope

- Kernel changes
- Desktop / GUI
- Custom package manager
- OpenRC / systemd
- Rewriting Zsh or Oh My Zsh setup

## Version

Infrastructure upgrade → **HUT OS 3.0.0**
