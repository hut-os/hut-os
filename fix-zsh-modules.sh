#!/bin/bash

# Fix Zsh modules and missing commands for HUT OS

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOTFS="$PROJECT_ROOT/rootfs"

# Colors
CYAN='\033[1;36m'
GREEN='\033[1;32m'
RESET='\033[0m'

echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}║          HUT OS Zsh Modules Fix                          ║${RESET}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${RESET}"
echo ""

# Copy Zsh modules
echo "[1/3] Copying Zsh modules..."
ZSH_MODULE_DIR="$ROOTFS/usr/lib/x86_64-linux-gnu/zsh/5.9/zsh"
mkdir -p "$ZSH_MODULE_DIR"
cp -rv /usr/lib/x86_64-linux-gnu/zsh/5.9/zsh/*.so "$ZSH_MODULE_DIR/" 2>&1 | grep -v "^'" || true

# Also copy subdirectories if they exist
if [ -d /usr/lib/x86_64-linux-gnu/zsh/5.9/zsh/db ]; then
    cp -r /usr/lib/x86_64-linux-gnu/zsh/5.9/zsh/db "$ZSH_MODULE_DIR/"
fi

echo -e "${GREEN}✓${RESET} Zsh modules copied"
echo ""

# Copy Zsh function files
echo "[2/3] Copying Zsh functions..."
FPATH_DIR="$ROOTFS/usr/share/zsh/5.9/functions"
mkdir -p "$FPATH_DIR"
if [ -d /usr/share/zsh/5.9/functions ]; then
    cp -r /usr/share/zsh/5.9/functions/* "$FPATH_DIR/" 2>/dev/null || true
fi
echo -e "${GREEN}✓${RESET} Zsh functions copied"
echo ""

# Create symlinks for missing commands
echo "[3/3] Creating command symlinks..."
cd "$ROOTFS/bin"

# BusyBox provides these, just need symlinks
BUSYBOX_CMDS="mkdir rm rmdir mv cp ln cat grep sed awk cut sort uniq head tail tr"
for cmd in $BUSYBOX_CMDS; do
    if [ ! -e "$cmd" ]; then
        ln -sf busybox "$cmd"
        echo "  Created: $cmd -> busybox"
    fi
done

echo -e "${GREEN}✓${RESET} Command symlinks created"
echo ""

echo -e "${CYAN}════════════════════════════════════════════════════════════${RESET}"
echo -e "  Zsh modules and commands fixed!"
echo -e "${CYAN}════════════════════════════════════════════════════════════${RESET}"
echo ""
