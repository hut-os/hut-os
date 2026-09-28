# HUT OS Zsh Configuration
# Hamedan University of Technology Operating System
# Developer: Arshia Mohammadei

# Environment
export HOME=/root
export TERM=linux
export PATH=/bin:/sbin:/usr/bin:/usr/sbin

# HUT OS Identity
export HUTOS_VERSION="2.1.0"
export HUTOS_NAME="HUT OS"

# Oh My Zsh (minimal configuration)
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="" # We'll use custom prompt

# Disable auto-update
DISABLE_AUTO_UPDATE="true"
DISABLE_UPDATE_PROMPT="true"

# Minimal plugins
plugins=()

# Source Oh My Zsh if available (but don't fail if it has issues)
if [ -f "$ZSH/oh-my-zsh.sh" ]; then
    source "$ZSH/oh-my-zsh.sh" 2>/dev/null || true
fi

# HUT OS Custom Prompt
# Format: hut@hut-os:~#
# Use simple ANSI codes instead of Zsh prompt expansion for reliability
autoload -U colors && colors 2>/dev/null || true

# Simple, reliable prompt
PROMPT='%{%F{cyan}%}hut@hut-os%{%f%}:%{%F{blue}%}%~%{%f%}# '

# Right prompt (empty for simplicity)
RPROMPT=''

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

# Completion system
autoload -Uz compinit
compinit -d /tmp/.zcompdump 2>/dev/null || true

# Better completion (if available)
zstyle ':completion:*' menu select 2>/dev/null || true
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 2>/dev/null || true

# Make sure we're using UTF-8
export LC_ALL=C
export LANG=C

# Welcome message (only on first shell)
if [[ -z "$HUTOS_SHELL_LOADED" ]]; then
    export HUTOS_SHELL_LOADED=1
    echo ""
    echo -e "\033[1;36m╔══════════════════════════════════════════════════════════════╗\033[0m"
    echo -e "\033[1;36m║               Welcome to Zsh on HUT OS                       ║\033[0m"
    echo -e "\033[1;36m╚══════════════════════════════════════════════════════════════╝\033[0m"
    echo ""
    echo -e "\033[1;32mZsh with Oh My Zsh is now running!\033[0m"
    echo ""
    echo "Try these commands:"
    echo "  • about      - Display HUT OS information"
    echo "  • ll         - List files (long format)"
    echo "  • huname     - Show HUT OS name"
    echo ""
fi
