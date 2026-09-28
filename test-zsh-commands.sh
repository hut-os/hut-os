#!/bin/bash
# Test HUTOS Zsh commands

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KERNEL="$PROJECT_ROOT/kernel/arch/x86/boot/bzImage"
INITRD="$PROJECT_ROOT/initramfs.cpio.gz"

echo "Testing HUTOS Zsh commands in QEMU..."
echo ""

# Create expect script for automated testing
cat > /tmp/hutos-test.exp << 'EOF'
#!/usr/bin/expect

set timeout 30

spawn qemu-system-x86_64 \
    -kernel [lindex $argv 0] \
    -initrd [lindex $argv 1] \
    -append "console=ttyS0 quiet" \
    -m 512M \
    -smp 2 \
    -nographic \
    -no-reboot

expect {
    timeout { puts "\nERROR: Timeout waiting for prompt"; exit 1 }
    "hut@hut-os:~#" { puts "\n✓ Zsh prompt appeared" }
}

sleep 1

# Test about command
send "about\r"
expect {
    timeout { puts "\nERROR: about command timeout"; exit 1 }
    "HUT OS" { puts "\n✓ about command works" }
}

sleep 1

# Test hutinfo command
send "hutinfo\r"
expect {
    timeout { puts "\nERROR: hutinfo command timeout"; exit 1 }
    "OS Version" { puts "\n✓ hutinfo command works" }
}

sleep 1

# Test clear command
send "clear\r"
expect {
    timeout { puts "\nERROR: clear command timeout"; exit 1 }
    "hut@hut-os:~#" { puts "\n✓ clear command works" }
}

sleep 1

# Test zsh version
send "zsh --version\r"
expect {
    timeout { puts "\nERROR: zsh version timeout"; exit 1 }
    "zsh" { puts "\n✓ zsh --version works" }
}

sleep 1

puts "\n═══════════════════════════════════"
puts "All tests passed! Zsh is working."
puts "═══════════════════════════════════\n"

# Shutdown
send "poweroff\r"
expect eof
EOF

chmod +x /tmp/hutos-test.exp

if command -v expect >/dev/null 2>&1; then
    /tmp/hutos-test.exp "$KERNEL" "$INITRD"
else
    echo "WARNING: 'expect' not installed - running manual test instead"
    echo "You'll need to test the commands manually:"
    echo "  about"
    echo "  hutinfo"
    echo "  clear"
    echo ""
    timeout 60 qemu-system-x86_64 \
        -kernel "$KERNEL" \
        -initrd "$INITRD" \
        -append "console=ttyS0 quiet" \
        -m 512M \
        -smp 2 \
        -nographic \
        -no-reboot || true
fi
