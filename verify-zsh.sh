#!/bin/bash

# HUT OS Zsh Integration Verification Script
# Tests all requirements for Zsh integration

# Don't use set -e so all tests can run

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOTFS="$PROJECT_ROOT/rootfs"

# Colors
CYAN='\033[1;36m'
GREEN='\033[1;32m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
RESET='\033[0m'

echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}║          HUT OS Zsh Integration Verification             ║${RESET}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${RESET}"
echo ""

PASS=0
FAIL=0

# Test function
test_item() {
    local description="$1"
    local test_cmd="$2"
    
    if eval "$test_cmd" &>/dev/null; then
        echo -e "${GREEN}✓${RESET} $description"
        ((PASS++))
    else
        echo -e "${RED}✗${RESET} $description"
        ((FAIL++))
    fi
}

echo "Testing Zsh Components..."
echo ""

# Zsh binary
test_item "Zsh binary exists" "[ -f '$ROOTFS/bin/zsh' ]"
test_item "Zsh is executable" "[ -x '$ROOTFS/bin/zsh' ]"

# Shared libraries
test_item "ELF interpreter exists" "[ -f '$ROOTFS/lib64/ld-linux-x86-64.so.2' ]"
test_item "libc.so.6 exists" "[ -f '$ROOTFS/usr/lib/x86_64-linux-gnu/libc.so.6' ]"
test_item "libm.so.6 exists" "[ -f '$ROOTFS/usr/lib/x86_64-linux-gnu/libm.so.6' ]"
test_item "libtinfo.so.6 exists" "[ -f '$ROOTFS/usr/lib/x86_64-linux-gnu/libtinfo.so.6' ]"
test_item "libcap.so.2 exists" "[ -f '$ROOTFS/usr/lib/x86_64-linux-gnu/libcap.so.2' ]"

# Zsh modules
test_item "Zsh modules directory exists" "[ -d '$ROOTFS/usr/lib/x86_64-linux-gnu/zsh/5.9/zsh' ]"
test_item "zle.so module exists" "[ -f '$ROOTFS/usr/lib/x86_64-linux-gnu/zsh/5.9/zsh/zle.so' ]"
test_item "parameter.so module exists" "[ -f '$ROOTFS/usr/lib/x86_64-linux-gnu/zsh/5.9/zsh/parameter.so' ]"
test_item "complete.so module exists" "[ -f '$ROOTFS/usr/lib/x86_64-linux-gnu/zsh/5.9/zsh/complete.so' ]"

# Zsh functions
test_item "Zsh functions directory exists" "[ -d '$ROOTFS/usr/share/zsh/5.9/functions' ]"

# Oh My Zsh
test_item "Oh My Zsh installed" "[ -d '$ROOTFS/root/.oh-my-zsh' ]"
test_item "Oh My Zsh main script exists" "[ -f '$ROOTFS/root/.oh-my-zsh/oh-my-zsh.sh' ]"

# Configuration
test_item ".zshrc exists" "[ -f '$ROOTFS/root/.zshrc' ]"
test_item "/etc/passwd exists" "[ -f '$ROOTFS/etc/passwd' ]"
test_item "Root shell is /bin/zsh" "grep -q '/bin/zsh' '$ROOTFS/etc/passwd'"

# Terminfo
test_item "Linux terminfo exists" "[ -f '$ROOTFS/usr/share/terminfo/l/linux' ]"

# BusyBox commands
test_item "BusyBox exists" "[ -f '$ROOTFS/bin/busybox' ]"
test_item "mkdir symlink exists" "[ -L '$ROOTFS/bin/mkdir' ]"
test_item "rm symlink exists" "[ -L '$ROOTFS/bin/rm' ]"
test_item "cat symlink exists" "[ -L '$ROOTFS/bin/cat' ]"
test_item "grep symlink exists" "[ -L '$ROOTFS/bin/grep' ]"

# HUT OS specific
test_item "about command exists" "[ -f '$ROOTFS/bin/about' ]"
test_item "HUT banner exists" "[ -f '$ROOTFS/etc/hut-banner.txt' ]"
test_item "init script exists" "[ -f '$ROOTFS/init' ]"
test_item "init launches Zsh" "grep -q 'exec /bin/zsh' '$ROOTFS/init'"

# Initramfs
test_item "initramfs.cpio.gz exists" "[ -f '$PROJECT_ROOT/initramfs.cpio.gz' ]"

echo ""
echo -e "${CYAN}════════════════════════════════════════════════════════════${RESET}"
echo -e "  Results: ${GREEN}$PASS passed${RESET}, ${RED}$FAIL failed${RESET}"
echo -e "${CYAN}════════════════════════════════════════════════════════════${RESET}"
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed!${RESET}"
    echo ""
    echo "HUT OS is ready with Zsh integration."
    echo "Run ./run.sh to boot and test."
    echo ""
    exit 0
else
    echo -e "${RED}✗ Some checks failed${RESET}"
    echo ""
    echo "Please run:"
    echo "  ./setup-zsh.sh"
    echo "  ./fix-zsh-modules.sh"
    echo "  ./build-initramfs.sh"
    echo ""
    exit 1
fi
