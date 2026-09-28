#!/bin/bash
# HUT OS — Quick Boot (initramfs path)
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
KERNEL="$PROJECT_ROOT/kernel/arch/x86/boot/bzImage"
INITRD="$PROJECT_ROOT/build/initramfs.cpio.gz"

# Fallback to legacy location
[ -f "$INITRD" ] || INITRD="$PROJECT_ROOT/initramfs.cpio.gz"

if [ ! -f "$KERNEL" ]; then
  echo "Error: kernel not found" >&2
  exit 1
fi

if [ ! -f "$INITRD" ]; then
  echo "Initramfs missing — building..."
  "$PROJECT_ROOT/build.sh" initramfs
fi

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║              HUT OS 3.0 — Quick Boot                     ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "  Mode: initramfs"
echo "  Tip:  about | hutinfo | ifconfig"
echo "  Exit: Ctrl+A then X"
echo ""

exec qemu-system-x86_64 \
  -m 256 \
  -kernel "$KERNEL" \
  -initrd "$INITRD" \
  -append "console=ttyS0" \
  -nic user,model=e1000 \
  -nographic
