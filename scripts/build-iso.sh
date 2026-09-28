#!/bin/bash
# HUT OS — Build bootable GRUB ISO (kernel + initramfs)
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
KERNEL="$PROJECT_ROOT/kernel/arch/x86/boot/bzImage"
INITRD="$PROJECT_ROOT/build/initramfs.cpio.gz"
OUT="$PROJECT_ROOT/build/hutos.iso"
ISODIR="$PROJECT_ROOT/build/iso"

if ! command -v grub-mkrescue >/dev/null; then
  echo "Error: grub-mkrescue not found. Install grub-pc-bin xorriso." >&2
  exit 1
fi

if [ ! -f "$KERNEL" ]; then
  echo "Error: kernel missing" >&2
  exit 1
fi

if [ ! -f "$INITRD" ]; then
  echo "[iso] initramfs missing — building..."
  "$PROJECT_ROOT/scripts/build-initramfs.sh"
fi

echo "[iso] Assembling ISO tree..."
rm -rf "$ISODIR"
mkdir -p "$ISODIR/boot/grub"

cp "$KERNEL" "$ISODIR/boot/bzImage"
cp "$INITRD" "$ISODIR/boot/initramfs.cpio.gz"

cat > "$ISODIR/boot/grub/grub.cfg" << 'EOF'
set timeout=1
set default=0

# ttyS0 last so /dev/console (and init stdout) uses serial — required for -nographic
menuentry "HUT OS 3.0 (Hamedan University of Technology)" {
    linux /boot/bzImage console=tty0 console=ttyS0
    initrd /boot/initramfs.cpio.gz
}

menuentry "HUT OS 3.0 (VGA console)" {
    linux /boot/bzImage console=ttyS0 console=tty0
    initrd /boot/initramfs.cpio.gz
}
EOF

echo "[iso] Running grub-mkrescue..."
grub-mkrescue -o "$OUT" "$ISODIR" 2>&1 | grep -vE '^(xorriso|libisofs|GNU xorriso|Drive current)' || true

ln -sfn "build/hutos.iso" "$PROJECT_ROOT/hutos.iso"

SIZE=$(du -h "$OUT" | cut -f1)
echo "[iso] Done ($SIZE)"
echo "      Boot with: ./scripts/run-iso.sh"
