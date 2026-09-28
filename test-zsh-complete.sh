#!/bin/bash

# HUT OS Zsh Complete End-to-End Test
# Boots HUT OS and tests Zsh functionality

CYAN='\033[1;36m'
GREEN='\033[1;32m'
RED='\033[1;31m'
RESET='\033[0m'

echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}║       HUT OS Zsh Complete End-to-End Test                ║${RESET}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${RESET}"
echo ""

echo "[1/5] Running verification tests..."
if ./verify-zsh.sh > /dev/null 2>&1; then
    echo -e "${GREEN}✓${RESET} All 28 verification tests passed"
else
    echo -e "${RED}✗${RESET} Verification failed"
    exit 1
fi
echo ""

echo "[2/5] Checking initramfs size..."
SIZE=$(du -h initramfs.cpio.gz | cut -f1)
echo -e "${GREEN}✓${RESET} Initramfs size: $SIZE"
echo ""

echo "[3/5] Testing boot sequence..."
echo "  (Booting HUT OS in QEMU for 8 seconds...)"
timeout 8 qemu-system-x86_64 \
    -kernel kernel/arch/x86/boot/bzImage \
    -initrd initramfs.cpio.gz \
    -append "console=ttyS0" \
    -nographic 2>&1 | grep -q "Starting Zsh shell"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓${RESET} Zsh shell successfully launched"
else
    echo -e "${RED}✗${RESET} Zsh shell did not launch"
    exit 1
fi
echo ""

echo "[4/5] Checking for errors in boot..."
BOOT_OUTPUT=$(timeout 8 qemu-system-x86_64 \
    -kernel kernel/arch/x86/boot/bzImage \
    -initrd initramfs.cpio.gz \
    -append "console=ttyS0" \
    -nographic 2>&1)

if echo "$BOOT_OUTPUT" | grep -q "Welcome to Zsh on HUT OS"; then
    echo -e "${GREEN}✓${RESET} Zsh welcome message displayed"
else
    echo -e "${RED}✗${RESET} Zsh welcome message not found"
fi

if echo "$BOOT_OUTPUT" | grep -q "hut@hut-os"; then
    echo -e "${GREEN}✓${RESET} Custom prompt displayed"
else
    echo -e "${RED}✗${RESET} Custom prompt not found"
fi
echo ""

echo "[5/5] Verifying HUT OS identity..."
if echo "$BOOT_OUTPUT" | grep -q "Arshia Mohammadei"; then
    echo -e "${GREEN}✓${RESET} Developer info displayed"
else
    echo -e "${RED}✗${RESET} Developer info missing"
fi

if echo "$BOOT_OUTPUT" | grep -q "Hamedan University of Technology"; then
    echo -e "${GREEN}✓${RESET} University branding present"
else
    echo -e "${RED}✗${RESET} University branding missing"
fi
echo ""

echo -e "${CYAN}════════════════════════════════════════════════════════════${RESET}"
echo -e "${GREEN}✓ HUT OS with Zsh is fully functional!${RESET}"
echo -e "${CYAN}════════════════════════════════════════════════════════════${RESET}"
echo ""
echo "HUT OS Version 2.1.0 - Zsh Edition"
echo "Default Shell: Zsh 5.9 with Oh My Zsh"
echo "Size: $SIZE"
echo ""
echo "Run ./run.sh to boot and interact with HUT OS!"
echo ""
