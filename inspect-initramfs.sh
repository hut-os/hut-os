#!/bin/bash

# HUT OS - Initramfs Inspector
# View contents of the initramfs without booting

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INITRAMFS="$PROJECT_ROOT/initramfs.cpio.gz"
TEMP_DIR="/tmp/hutos-inspect-$$"

# Colors
CYAN='\033[1;36m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RESET='\033[0m'

echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}║           HUT OS - Initramfs Inspector                   ║${RESET}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${RESET}"
echo ""

if [ ! -f "$INITRAMFS" ]; then
    echo -e "${YELLOW}Error: Initramfs not found${RESET}"
    echo "Run ./build-initramfs.sh first"
    exit 1
fi

echo -e "${GREEN}✓${RESET} Extracting initramfs to temporary directory..."
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"
gunzip -c "$INITRAMFS" | cpio -idm 2>/dev/null

echo -e "${GREEN}✓${RESET} Extraction complete"
echo ""

# Show structure
echo -e "${CYAN}════════════════════════════════════════════════════════════${RESET}"
echo -e "  Directory Structure:"
echo -e "${CYAN}════════════════════════════════════════════════════════════${RESET}"
tree -L 2 2>/dev/null || find . -maxdepth 2 -type d | sort
echo ""

# Show important files
echo -e "${CYAN}════════════════════════════════════════════════════════════${RESET}"
echo -e "  Important Files:"
echo -e "${CYAN}════════════════════════════════════════════════════════════${RESET}"

if [ -f init ]; then
    echo -e "${GREEN}✓${RESET} /init ($(wc -l < init) lines)"
fi

if [ -f bin/about ]; then
    echo -e "${GREEN}✓${RESET} /bin/about ($(wc -l < bin/about) lines)"
fi

if [ -f bin/busybox ]; then
    SIZE=$(du -h bin/busybox | cut -f1)
    echo -e "${GREEN}✓${RESET} /bin/busybox ($SIZE)"
fi

if [ -f etc/hut-banner.txt ]; then
    LINES=$(wc -l < etc/hut-banner.txt)
    echo -e "${GREEN}✓${RESET} /etc/hut-banner.txt ($LINES lines)"
fi

echo ""

# Show total size
echo -e "${CYAN}════════════════════════════════════════════════════════════${RESET}"
echo -e "  Statistics:"
echo -e "${CYAN}════════════════════════════════════════════════════════════${RESET}"
echo -e "  Total files:    $(find . -type f | wc -l)"
echo -e "  Total size:     $(du -sh . | cut -f1)"
echo -e "  Initramfs size: $(du -h "$INITRAMFS" | cut -f1)"
echo ""

# Offer to view specific files
echo -e "${CYAN}════════════════════════════════════════════════════════════${RESET}"
echo -e "  Quick Views:"
echo -e "${CYAN}════════════════════════════════════════════════════════════${RESET}"
echo ""
echo "  To view /init:"
echo "    cat $TEMP_DIR/init"
echo ""
echo "  To view /bin/about:"
echo "    cat $TEMP_DIR/bin/about"
echo ""
echo "  To view banner:"
echo "    cat $TEMP_DIR/etc/hut-banner.txt"
echo ""
echo -e "${YELLOW}Note: Files extracted to $TEMP_DIR${RESET}"
echo -e "${YELLOW}      (will be cleaned up on next reboot)${RESET}"
echo ""
