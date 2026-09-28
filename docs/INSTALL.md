# HUT OS Installation Guide

Status: **implemented** for BIOS/legacy x86_64 in QEMU.

## Overview

HUT OS can be installed from a live GRUB ISO using the CLI installer `hut-install`.

```text
HUTOS ISO
   ↓
Boot live environment (initramfs)
   ↓
hut-install
   ↓
Partition → ext4 → copy root → GRUB → reboot
   ↓
Boot installed HUT OS from disk (no ISO)
```

## Build the ISO

Requirements on the build host:

- `grub-mkrescue` (`grub-pc-bin`)
- `xorriso`
- `qemu-system-x86_64`, `qemu-img`
- util-linux (`sfdisk`, `blkid`), e2fsprogs (`mke2fs`)

```bash
./build.sh iso
```

Artifacts:

| Path | Description |
|------|-------------|
| `build/hutos.iso` | Bootable live/installer ISO |
| `dist/hutos-x86_64.iso` | Same ISO (distribution name) |
| `build/initramfs.cpio.gz` | Live root (includes installer + tools) |

Generated ISO files are gitignored.

## Launch live ISO with a target disk

```bash
./scripts/run-install-iso.sh
```

Creates `build/hutos-target.img` (2G by default) and boots the ISO with that disk attached as virtio (`/dev/vda` in the guest).

Inside the guest:

```bash
hut-install
```

## Installer UI

```text
========================================
        HUT OS INSTALLER
 Hamedan University of Technology
========================================

1. Install HUT OS
2. Disk information
3. System information
4. Exit
```

Destructive disk operations always require confirmation unless `--yes` is passed (automation only).

### Automated install

```bash
hut-install --auto --yes --disk /dev/vda --hostname hutos
```

Kernel cmdline (used by QEMU tests):

```text
hutos.install=/dev/vda
hutos.e2e=1          # leave a one-shot selftest flag on the installed system
```

## Disk layout (v1)

```text
Whole disk (e.g. /dev/vda)
└── /dev/vda1   MBR primary, type Linux, bootable
    └── ext4 (label HUTOS) → /
```

No separate `/boot` or swap in v1.

Kernel cmdline uses `root=PARTUUID=…` (not `UUID=`), because the installed system boots without an initramfs and the kernel cannot resolve filesystem UUIDs by itself. `/etc/fstab` still uses `UUID=` for userspace.

## Filesystem layout (installed)

```text
/
├── boot/          vmlinuz, bzImage, grub/
├── etc/           hostname, fstab, passwd, shadow, shells, hutos/
├── bin/, sbin/, usr/
├── var/, home/, root/, tmp/
├── proc/, sys/, dev/, run/
└── init           PID 1 (also /sbin/init → /init)
```

`/etc/fstab` uses `UUID=` when `blkid` is available.

## Bootloader

- GRUB BIOS (`i386-pc`) installed to the disk MBR
- Config: `/boot/grub/grub.cfg`
- Kernel args include `root=UUID=…`, `rootwait`, `init=/init`, dual console

## End-to-end QEMU test

```bash
./scripts/test-install-qemu.sh
```

This will:

1. Build the ISO if needed
2. Create a fresh 2G disk
3. Boot an auto-install ISO (`hutos.install=/dev/vda`)
4. Install HUT OS + GRUB
5. Boot the disk **without** the ISO
6. Run the HUTOS selftest (`uname`, `about`, `hutinfo`, …)
7. Pass/fail based on serial logs under `build/test-*.log`

## Architecture

```text
rootfs/bin/hut-install
rootfs/usr/lib/hutos-install/
  common.sh, ui.sh, disk.sh, filesystem.sh,
  copy.sh, config.sh, bootloader.sh
scripts/bundle-installer-tools.sh   # host GRUB/sfdisk/blkid/mke2fs → rootfs
scripts/build-initramfs.sh
scripts/build-iso.sh
scripts/run-install-iso.sh
scripts/test-install-qemu.sh
installer/install.sh                # wrapper → hut-install
```

## Implemented

- Persistent ext4 root
- GRUB BIOS install from live environment
- CLI installer with disk detection (no hardcoded `/dev/sda`)
- Bootable ISO + QEMU install/boot test workflow
- Preservation of Zsh, Oh My Zsh, and HUTOS tools in the installed system

## Experimental

- Auto-install via kernel cmdline (`hutos.install=`)
- One-shot selftest flag (`hutos.e2e=1`)

## Planned (not in this version)

- UEFI / GPT
- Separate `/boot` and swap
- Networking during install
- GUI installer
- Physical hardware certification

## Known limitations

- BIOS/legacy only (no UEFI)
- Single ext4 partition
- Installer host tools are bundled from the build machine (x86_64 Linux)
- Live environment is initramfs-based; large because it embeds the kernel and GRUB modules
- Not yet validated on bare metal
