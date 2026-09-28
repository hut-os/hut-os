#!/bin/bash
# Automated HUTOS Boot Verification

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KERNEL="$PROJECT_ROOT/kernel/arch/x86/boot/bzImage"
INITRD="$PROJECT_ROOT/initramfs.cpio.gz"
LOG_FILE="/tmp/hutos-boot-verify-$(date +%s).log"

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║          HUTOS Boot Verification Script                   ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Boot QEMU and capture output for 30 seconds
echo "Booting HUTOS in QEMU (will capture output for 30 seconds)..."
echo "Log file: $LOG_FILE"
echo ""

timeout 30 qemu-system-x86_64 \
    -m 256 \
    -kernel "$KERNEL" \
    -initrd "$INITRD" \
    -append "console=ttyS0" \
    -nographic \
    -nic user,model=e1000 \
    2>&1 | tee "$LOG_FILE" &

QEMU_PID=$!

# Wait for boot
sleep 15

# Try to send commands (this might not work perfectly but we can check the log)
echo "python3 --version" | timeout 2 socat - UNIX-CONNECT:/tmp/qemu-monitor 2>/dev/null || true
sleep 3

# Kill QEMU
kill $QEMU_PID 2>/dev/null || true
wait $QEMU_PID 2>/dev/null || true

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║          Analysis Results                                 ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Analyze the log
ERRORS=0

# Check 1: Zsh error
if grep -q "up-line-or-beginning-search: function definition file not found" "$LOG_FILE"; then
    echo "  ✗ FAIL: Zsh up-line-or-beginning-search error found"
    ERRORS=$((ERRORS + 1))
else
    echo "  ✓ PASS: No Zsh function errors detected"
fi

# Check 2: Zsh started
if grep -q "Welcome to Zsh on HUT OS" "$LOG_FILE"; then
    echo "  ✓ PASS: Zsh started successfully"
else
    echo "  ✗ FAIL: Zsh welcome message not found"
    ERRORS=$((ERRORS + 1))
fi

# Check 3: Shell prompt
if grep -q "hut@hut-os" "$LOG_FILE"; then
    echo "  ✓ PASS: Shell prompt displayed"
else
    echo "  ✗ FAIL: Shell prompt not found"
    ERRORS=$((ERRORS + 1))
fi

# Check 4: System ready
if grep -q "System ready" "$LOG_FILE"; then
    echo "  ✓ PASS: System initialization complete"
else
    echo "  ✗ FAIL: System ready message not found"
    ERRORS=$((ERRORS + 1))
fi

# Check 5: HUTOS banner
if grep -q "HUT OS Boot Sequence" "$LOG_FILE"; then
    echo "  ✓ PASS: HUTOS banner displayed"
else
    echo "  ✗ FAIL: HUTOS banner not found"
    ERRORS=$((ERRORS + 1))
fi

echo ""
if [ $ERRORS -eq 0 ]; then
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║          ✓ All checks passed!                             ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo ""
    echo "The Zsh error has been fixed and HUTOS boots successfully."
    echo ""
    echo "To verify Python 3 manually:"
    echo "  1. Run: ./run.sh"
    echo "  2. At the prompt, type: python3 --version"
    echo "  3. Then type: python3 -c 'print(\"HUTOS Python OK\")'"
    echo "  4. Press Ctrl+A then X to exit"
    echo ""
else
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║          ✗ Some checks failed ($ERRORS)                          ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo ""
    echo "Please review the log file: $LOG_FILE"
    exit 1
fi
