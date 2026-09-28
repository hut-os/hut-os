#!/bin/bash

# HUT OS Zsh Integration Setup
# This script prepares Zsh with Oh My Zsh for the HUT OS initramfs

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOTFS="$PROJECT_ROOT/rootfs"

# Colors
CYAN='\033[1;36m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
RESET='\033[0m'

echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}║          HUT OS Zsh + Oh My Zsh Setup                    ║${RESET}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${RESET}"
echo ""

# Check if Zsh is installed on host
if ! command -v zsh &> /dev/null; then
    echo -e "${RED}Error: Zsh not found on host system${RESET}"
    echo "Install with: sudo apt install zsh"
    exit 1
fi

echo -e "${GREEN}✓${RESET} Zsh found: $(which zsh)"
echo -e "  Version: $(zsh --version)"
echo ""

# Create necessary directories
echo "[1/8] Creating directory structure..."
mkdir -p "$ROOTFS"/{bin,lib,lib64,usr/{bin,lib,share},etc,root,tmp,var}
echo -e "${GREEN}✓${RESET} Directories created"
echo ""

# Copy Zsh binary
echo "[2/8] Copying Zsh binary..."
cp -v /usr/bin/zsh "$ROOTFS/bin/"
chmod +x "$ROOTFS/bin/zsh"
echo -e "${GREEN}✓${RESET} Zsh binary copied"
echo ""

# Copy required libraries
echo "[3/8] Copying Zsh dependencies..."

# Get library list
LIBS=$(ldd /usr/bin/zsh | awk '{if ($3) print $3; else if ($1 ~ /^\//) print $1}')

# Copy ELF interpreter
if [ -f /lib64/ld-linux-x86-64.so.2 ]; then
    cp -v /lib64/ld-linux-x86-64.so.2 "$ROOTFS/lib64/"
    echo -e "${GREEN}✓${RESET} ELF interpreter copied"
fi

# Copy libraries
for lib in $LIBS; do
    if [ -f "$lib" ]; then
        # Determine target directory
        if [[ "$lib" == /lib/x86_64-linux-gnu/* ]]; then
            mkdir -p "$ROOTFS/lib/x86_64-linux-gnu"
            cp -Lv "$lib" "$ROOTFS/lib/x86_64-linux-gnu/"
        elif [[ "$lib" == /usr/lib/x86_64-linux-gnu/* ]]; then
            mkdir -p "$ROOTFS/usr/lib/x86_64-linux-gnu"
            cp -Lv "$lib" "$ROOTFS/usr/lib/x86_64-linux-gnu/"
        elif [[ "$lib" == /lib/* ]]; then
            cp -Lv "$lib" "$ROOTFS/lib/"
        elif [[ "$lib" == /usr/lib/* ]]; then
            cp -Lv "$lib" "$ROOTFS/usr/lib/"
        fi
    fi
done
echo -e "${GREEN}✓${RESET} Libraries copied"
echo ""

# Download and install Oh My Zsh
echo "[4/8] Setting up Oh My Zsh..."
OMZ_DIR="$ROOTFS/root/.oh-my-zsh"

if [ -d "$OMZ_DIR" ]; then
    echo -e "${YELLOW}⚠${RESET} Oh My Zsh already exists, removing..."
    rm -rf "$OMZ_DIR"
fi

# Clone Oh My Zsh (minimal - without git history)
git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$OMZ_DIR" 2>&1 | grep -v "^Receiving\|^Resolving\|^remote:" || true

# Remove unnecessary files to save space
rm -rf "$OMZ_DIR"/.git
rm -rf "$OMZ_DIR"/.github
rm -f "$OMZ_DIR"/.gitignore

# Keep only essential plugins
ESSENTIAL_PLUGINS="git common-aliases colored-man-pages command-not-found"
cd "$OMZ_DIR/plugins"
for plugin in */; do
    plugin_name="${plugin%/}"
    if ! echo "$ESSENTIAL_PLUGINS" | grep -q "$plugin_name"; then
        rm -rf "$plugin_name"
    fi
done

# Keep only a few lightweight themes
cd "$OMZ_DIR/themes"
KEEP_THEMES="robbyrussell.zsh-theme agnoster.zsh-theme"
for theme in *.zsh-theme; do
    if ! echo "$KEEP_THEMES" | grep -q "$theme"; then
        rm -f "$theme"
    fi
done

echo -e "${GREEN}✓${RESET} Oh My Zsh installed (minimal)"
echo ""

# Create .zshrc configuration
echo "[5/8] Creating HUT OS .zshrc..."
cat > "$ROOTFS/root/.zshrc" << 'ZSHRC_EOF'
# HUT OS Zsh Configuration
# Hamedan University of Technology Operating System
# Developer: Arshia Mohammadei

# Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"

# Theme
ZSH_THEME="robbyrussell"

# Plugins (minimal for speed)
plugins=(git common-aliases)

# Load Oh My Zsh
source $ZSH/oh-my-zsh.sh

# HUT OS Custom Prompt
# Format: hut@hut-os:~#
PROMPT='%{$fg_bold[cyan]%}hut@hut-os%{$reset_color%}:%{$fg_bold[blue]%}%~%{$reset_color%}# '

# HUT OS Identity
export HUTOS_VERSION="2.1.0"
export HUTOS_NAME="HUT OS"

# Aliases
alias about='/bin/about'
alias ll='ls -lah'
alias la='ls -A'
alias l='ls -CF'
alias cls='clear'
alias huname='echo "$HUTOS_NAME - Hamedan University of Technology Operating System"'

# History configuration
HISTFILE=/root/.zsh_history
HISTSIZE=1000
SAVEHIST=1000
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY

# Key bindings
bindkey -e  # Emacs key bindings

# Colors
autoload -U colors && colors

# Completion
autoload -Uz compinit
compinit -d /tmp/.zcompdump

# Better completion
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Welcome message (only on first shell)
if [[ -z "$HUTOS_SHELL_LOADED" ]]; then
    export HUTOS_SHELL_LOADED=1
fi

# Path
export PATH=/bin:/sbin:/usr/bin:/usr/sbin

ZSHRC_EOF

chmod 644 "$ROOTFS/root/.zshrc"
echo -e "${GREEN}✓${RESET} .zshrc created"
echo ""

# Create /etc/passwd
echo "[6/8] Creating /etc/passwd..."
cat > "$ROOTFS/etc/passwd" << 'PASSWD_EOF'
root:x:0:0:root:/root:/bin/zsh
PASSWD_EOF
chmod 644 "$ROOTFS/etc/passwd"
echo -e "${GREEN}✓${RESET} /etc/passwd created (root shell: /bin/zsh)"
echo ""

# Create minimal /etc/group
echo "[7/8] Creating /etc/group..."
cat > "$ROOTFS/etc/group" << 'GROUP_EOF'
root:x:0:
GROUP_EOF
chmod 644 "$ROOTFS/etc/group"
echo -e "${GREEN}✓${RESET} /etc/group created"
echo ""

# Create symbolic links for compatibility
echo "[8/8] Creating symbolic links..."
cd "$ROOTFS/bin"

# Ensure sh still points to busybox for init script
if [ ! -e sh ]; then
    ln -sf busybox sh
fi

# Create zsh5 link if needed (some systems expect this)
if [ ! -e zsh5 ]; then
    ln -sf zsh zsh5
fi

echo -e "${GREEN}✓${RESET} Symbolic links created"
echo ""

# Summary
echo -e "${CYAN}════════════════════════════════════════════════════════════${RESET}"
echo -e "  Setup Complete!"
echo -e "${CYAN}════════════════════════════════════════════════════════════${RESET}"
echo ""
echo "Zsh binary:       $ROOTFS/bin/zsh"
echo "Oh My Zsh:        $ROOTFS/root/.oh-my-zsh"
echo "Configuration:    $ROOTFS/root/.zshrc"
echo "System config:    $ROOTFS/etc/passwd"
echo ""
echo "Next steps:"
echo "  1. Update /init to launch Zsh"
echo "  2. Run ./build-initramfs.sh"
echo "  3. Test with ./run.sh"
echo ""
