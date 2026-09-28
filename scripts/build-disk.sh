#!/bin/bash
# HUT OS — Build persistent ext4 disk image (no root/sudo required)
# Uses: mkfs.ext4 -d <rootfs-dir>
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ROOTFS="$PROJECT_ROOT/rootfs"
KERNEL="$PROJECT_ROOT/kernel/arch/x86/boot/bzImage"
OUT="$PROJECT_ROOT/build/hutos.img"
SIZE_MB="${HUTOS_DISK_MB:-256}"
STAGING="$PROJECT_ROOT/build/disk-root"

mkdir -p "$PROJECT_ROOT/build"

if [ ! -f "$KERNEL" ]; then
  echo "Error: kernel not found at $KERNEL" >&2
  exit 1
fi

echo "[disk] Staging rootfs → $STAGING"
rm -rf "$STAGING"
mkdir -p "$STAGING"

# Copy rootfs (preserve symlinks)
cp -a "$ROOTFS"/. "$STAGING"/

# Kernel for /boot (GRUB / manual)
mkdir -p "$STAGING/boot"
cp "$KERNEL" "$STAGING/boot/bzImage"
cp "$KERNEL" "$STAGING/boot/vmlinuz"

# Ensure standard dirs exist
mkdir -p "$STAGING"/{dev,proc,sys,tmp,run,mnt,media,var/log,var/run,home/hut}
chmod +x "$STAGING/init"

# Rough size check: rootfs must fit in image
NEED=$(du -sm "$STAGING" | awk '{print $1 + 32}')
if [ "$NEED" -gt "$SIZE_MB" ]; then
  echo "Error: staged rootfs needs ~${NEED}M but image is ${SIZE_MB}M" >&2
  echo "       Set HUTOS_DISK_MB=$((NEED + 64)) and retry." >&2
  exit 1
fi

echo "[disk] Creating ${SIZE_MB}M ext4 image (label HUTOS)..."
rm -f "$OUT"
# Preallocate then format with directory contents
dd if=/dev/zero of="$OUT" bs=1M count="$SIZE_MB" status=none
mkfs.ext4 -F -L HUTOS -d "$STAGING" -q "$OUT"

ln -sfn "build/hutos.img" "$PROJECT_ROOT/hutos.img"

SIZE=$(du -h "$OUT" | cut -f1)
echo "[disk] Done ($SIZE)"
echo "       Boot with: ./scripts/run-disk.sh"
