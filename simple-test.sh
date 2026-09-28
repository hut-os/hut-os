#!/bin/bash
# Simple HUTOS Test

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KERNEL="$PROJECT_ROOT/kernel/arch/x86/boot/bzImage"
INITRD="$PROJECT_ROOT/initramfs.cpio.gz"

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║          HUTOS Simple Test - Manual Verification          ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "Booting HUTOS..."
echo ""
echo "Once booted, please test manually:"
echo "  1. Check if Zsh starts without 'up-line-or-beginning-search' error"
echo "  2. Type: python3 --version"
echo "  3. Type: python3 -c 'print(\"HUTOS Python OK\")'"
echo "  4. Type: about"
echo "  5. Type: hutinfo"
echo "  6. Type: clear"
echo "  7. Type: python --version"
echo "  8. Use arrow keys to test history"
echo ""
echo "Press Ctrl+A then X to exit QEMU"
echo ""
read -p "Press Enter to boot HUTOS..." 

exec qemu-system-x86_64 \
    -m 256 \
    -kernel "$KERNEL" \
    -initrd "$INITRD" \
    -append "console=ttyS0" \
    -nographic \
    -nic user,model=e1000
