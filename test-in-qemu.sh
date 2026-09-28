#!/bin/bash
# Boot HUTOS in QEMU and run automated tests

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KERNEL="$PROJECT_ROOT/kernel/arch/x86/boot/bzImage"
INITRD="$PROJECT_ROOT/initramfs.cpio.gz"
TIMEOUT=60

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║          HUTOS QEMU Test Runner                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

if [ ! -f "$KERNEL" ]; then
    echo "Error: Kernel not found at $KERNEL"
    exit 1
fi

if [ ! -f "$INITRD" ]; then
    echo "Error: Initramfs not found at $INITRD"
    exit 1
fi

echo "Kernel:   $KERNEL"
echo "Initramfs: $INITRD"
echo ""
echo "Starting QEMU..."
echo "Press Ctrl-A then X to exit QEMU"
echo ""
echo "════════════════════════════════════════════════════════════"
echo ""

# Run QEMU with serial console
qemu-system-x86_64 \
    -kernel "$KERNEL" \
    -initrd "$INITRD" \
    -append "console=ttyS0 quiet" \
    -m 512M \
    -smp 2 \
    -nographic \
    -no-reboot
