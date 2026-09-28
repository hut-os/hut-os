#!/bin/bash
# HUT OS — Build bootable GRUB ISO (live environment + hut-install)
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
KERNEL="$PROJECT_ROOT/kernel/arch/x86/boot/bzImage"
INITRD="$PROJECT_ROOT/build/initramfs.cpio.gz"
OUT="$PROJECT_ROOT/build/hutos.iso"
DIST_ISO="$PROJECT_ROOT/dist/hutos-x86_64.iso"
ISODIR="$PROJECT_ROOT/build/iso"

if ! command -v grub-mkrescue >/dev/null; then
  echo "Error: grub-mkrescue not found. Install grub-pc-bin xorriso." >&2
  exit 1
fi

if [ ! -f "$KERNEL" ]; then
  echo "Error: kernel missing at $KERNEL" >&2
  exit 1
fi

echo "[iso] Ensuring initramfs (with installer tools)..."
"$PROJECT_ROOT/scripts/build-initramfs.sh"

echo "[iso] Assembling ISO tree..."
rm -rf "$ISODIR"
mkdir -p "$ISODIR/boot/grub"

cp "$KERNEL" "$ISODIR/boot/bzImage"
cp "$INITRD" "$ISODIR/boot/initramfs.cpio.gz"

cat > "$ISODIR/boot/grub/grub.cfg" << 'EOF'
set timeout=2
set default=0

# ttyS0 last so /dev/console uses serial — required for -nographic
menuentry "HUT OS 3.0 (Live / Installer)" {
    linux /boot/bzImage console=tty0 console=ttyS0
    initrd /boot/initramfs.cpio.gz
}

menuentry "HUT OS 3.0 (VGA console)" {
    linux /boot/bzImage console=ttyS0 console=tty0
    initrd /boot/initramfs.cpio.gz
}

# Automated install onto first virtio disk (QEMU testing)
menuentry "HUT OS Auto-Install (/dev/vda)" {
    linux /boot/bzImage console=tty0 console=ttyS0 hutos.install=/dev/vda
    initrd /boot/initramfs.cpio.gz
}
EOF

echo "[iso] Running grub-mkrescue..."
grub-mkrescue -o "$OUT" "$ISODIR" 2>&1 | grep -vE '^(xorriso|libisofs|GNU xorriso|Drive current)' || true

mkdir -p "$PROJECT_ROOT/dist"
cp -f "$OUT" "$DIST_ISO"
ln -sfn "build/hutos.iso" "$PROJECT_ROOT/hutos.iso"
ln -sfn "dist/hutos-x86_64.iso" "$PROJECT_ROOT/hutos-x86_64.iso" 2>/dev/null || true

SIZE=$(du -h "$OUT" | cut -f1)
echo "[iso] Done ($SIZE)"
echo "      Artifacts:"
echo "        $OUT"
echo "        $DIST_ISO"
echo "      Boot: ./scripts/run-iso.sh"
echo "      Install test: ./scripts/test-install-qemu.sh"
