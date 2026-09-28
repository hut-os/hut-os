#!/bin/bash
# Test HUTOS commands by piping to QEMU

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KERNEL="$PROJECT_ROOT/kernel/arch/x86/boot/bzImage"
INITRD="$PROJECT_ROOT/initramfs.cpio.gz"

echo "Testing HUTOS Zsh commands..."

# Create command sequence
cat > /tmp/hutos-cmds.txt << 'EOF'

about

hutinfo

clear

zsh --version

echo "=== All commands tested ==="

poweroff
EOF

# Run QEMU with command input
timeout 45 qemu-system-x86_64 \
    -kernel "$KERNEL" \
    -initrd "$INITRD" \
    -append "console=ttyS0 quiet" \
    -m 512M \
    -smp 2 \
    -nographic \
    -no-reboot < /tmp/hutos-cmds.txt 2>&1 | tee /tmp/hutos-test-output.txt

echo ""
echo "═══════════════════════════════════════════"
echo "Checking test results..."
echo "═══════════════════════════════════════════"

if grep -q "HUT OS" /tmp/hutos-test-output.txt; then
    echo "✓ 'about' command works"
else
    echo "✗ 'about' command failed"
fi

if grep -q "OS Version" /tmp/hutos-test-output.txt; then
    echo "✓ 'hutinfo' command works"
else
    echo "✗ 'hutinfo' command failed"
fi

if grep -q "zsh.*5\." /tmp/hutos-test-output.txt; then
    echo "✓ 'zsh --version' works"
else
    echo "✗ 'zsh --version' failed"
fi

if grep -q "All commands tested" /tmp/hutos-test-output.txt; then
    echo "✓ Command execution successful"
else
    echo "✗ Commands may not have executed"
fi

echo ""
echo "Full output saved to: /tmp/hutos-test-output.txt"
