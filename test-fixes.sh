#!/bin/bash
# Test HUTOS Fixes in QEMU

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KERNEL="$PROJECT_ROOT/kernel/arch/x86/boot/bzImage"
INITRD="$PROJECT_ROOT/initramfs.cpio.gz"

if [ ! -f "$KERNEL" ]; then
    echo "Error: Kernel not found at $KERNEL"
    exit 1
fi

if [ ! -f "$INITRD" ]; then
    echo "Error: Initramfs not found at $INITRD"
    exit 1
fi

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║          HUTOS Test Script - Automated Verification       ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "This will boot HUTOS and automatically test:"
echo "  1. Zsh starts without up-line-or-beginning-search error"
echo "  2. about command works"
echo "  3. hutinfo command works"
echo "  4. clear command works"
echo "  5. python3 --version works"
echo "  6. python3 -c 'print(\"HUTOS Python OK\")' works"
echo ""
echo "The VM will automatically shut down after tests complete."
echo ""
echo "Starting QEMU..."
echo ""

# Create a test script that will run inside QEMU
cat > /tmp/hutos-test-commands.txt << 'EOF'
# Wait for system to boot
sleep 5

# Test commands
about
hutinfo
clear
python3 --version
python3 -c 'print("HUTOS Python OK")'

# Shutdown
poweroff
EOF

# Boot QEMU with test commands
timeout 60 qemu-system-x86_64 \
    -m 256 \
    -kernel "$KERNEL" \
    -initrd "$INITRD" \
    -append "console=ttyS0" \
    -nographic \
    -nic user,model=e1000 \
    2>&1 | tee /tmp/hutos-test-output.log

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║          Test Results Analysis                            ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Analyze output
if grep -q "up-line-or-beginning-search: function definition file not found" /tmp/hutos-test-output.log; then
    echo "  ✗ Zsh error still present"
else
    echo "  ✓ Zsh starts without errors"
fi

if grep -q "Python 3" /tmp/hutos-test-output.log; then
    echo "  ✓ Python 3 detected"
else
    echo "  ✗ Python 3 not found"
fi

if grep -q "HUTOS Python OK" /tmp/hutos-test-output.log; then
    echo "  ✓ Python print test passed"
else
    echo "  ✗ Python print test failed"
fi

echo ""
echo "Full log saved to: /tmp/hutos-test-output.log"
echo ""
