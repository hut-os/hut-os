#!/bin/bash
# HUT OS — Build initramfs from rootfs/
# Optionally bundles installer host tools (GRUB, sfdisk, blkid, mke2fs).
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ROOTFS="$PROJECT_ROOT/rootfs"
OUT="$PROJECT_ROOT/build/initramfs.cpio.gz"
KERNEL="$PROJECT_ROOT/kernel/arch/x86/boot/bzImage"

mkdir -p "$PROJECT_ROOT/build"

# Bundle GRUB / disk tools into rootfs (idempotent)
if [ "${HUTOS_SKIP_BUNDLE:-0}" != "1" ]; then
  echo "[initramfs] Bundling installer tools..."
  "$PROJECT_ROOT/scripts/bundle-installer-tools.sh"
fi

# Embed kernel into live /boot so installs work without CD access
if [ "${HUTOS_EMBED_KERNEL:-1}" = "1" ] && [ -f "$KERNEL" ]; then
  echo "[initramfs] Embedding kernel into rootfs/boot..."
  mkdir -p "$ROOTFS/boot"
  cp -f "$KERNEL" "$ROOTFS/boot/bzImage"
  cp -f "$KERNEL" "$ROOTFS/boot/vmlinuz"
fi

# /sbin/init compatibility for disk boots
mkdir -p "$ROOTFS/sbin"
ln -sfn /init "$ROOTFS/sbin/init"

echo "[initramfs] Packaging $ROOTFS → $OUT"

chmod +x "$ROOTFS/init" 2>/dev/null || true
chmod +x "$ROOTFS/bin/hut-install" 2>/dev/null || true
chmod +x "$ROOTFS/bin/about" "$ROOTFS/bin/hutinfo" 2>/dev/null || true
find "$ROOTFS/bin" -type l -exec chmod -h a+x {} \; 2>/dev/null || true

(
  cd "$ROOTFS"
  find . -print0 | cpio --null -o --format=newc 2>/dev/null | gzip -9 > "$OUT"
)

cp -f "$OUT" "$PROJECT_ROOT/initramfs.cpio.gz"

SIZE=$(du -h "$OUT" | cut -f1)
echo "[initramfs] Done ($SIZE)"
