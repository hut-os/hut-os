#!/bin/bash
# Verify HUTOS Zsh Fix
# This script boots HUTOS in QEMU to verify Zsh is working

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KERNEL="$PROJECT_ROOT/kernel/arch/x86/boot/bzImage"
INITRD="$PROJECT_ROOT/initramfs.cpio.gz"

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║          HUTOS Zsh Fix Verification                      ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "This will boot HUTOS in QEMU to verify:"
echo "  ✓ No '/bin/zsh: not found' error"
echo "  ✓ Zsh prompt appears"
echo "  ✓ System boots successfully"
echo ""
echo "After boot, you can test these commands:"
echo "  • about      - Display system info"
echo "  • hutinfo    - Show HUT OS details"
echo "  • clear      - Clear screen"
echo "  • zsh --version - Show Zsh version"
echo ""
echo "Press Ctrl-A then X to exit QEMU"
echo ""
echo "Booting in 3 seconds..."
sleep 3

# Boot HUTOS
qemu-system-x86_64 \
    -kernel "$KERNEL" \
    -initrd "$INITRD" \
    -append "console=ttyS0 quiet" \
    -m 512M \
    -smp 2 \
    -nographic \
    -no-reboot

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║          HUTOS Zsh verification complete                  ║"
echo "╚═══════════════════════════════════════════════════════════╝"
