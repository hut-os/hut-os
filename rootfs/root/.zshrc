# HUT OS Zsh Configuration
# Hamedan University of Technology Operating System
# Developer: Arshia Mohammadei

# Environment
export HOME="${HOME:-/root}"
export TERM=linux
export PATH=/bin:/sbin:/usr/bin:/usr/sbin

# HUT OS Identity
export HUTOS_VERSION="3.1.0"
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
PROMPT='%{%F{cyan}%}%n@%m%{%f%}:%{%F{blue}%}%~%{%f%}# '

# Right prompt (empty for simplicity)
RPROMPT=''

# Aliases
alias about='/bin/about'
alias hutinfo='/bin/hutinfo'
alias ll='ls -lah'
alias la='ls -A'
alias l='ls -CF'
alias cls='clear'
alias huname='echo "$HUTOS_NAME - Hamedan University of Technology Operating System"'

# History configuration
HISTFILE="$HOME/.zsh_history"
HISTSIZE=1000
SAVEHIST=1000
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY

# Key bindings
bindkey -e  # Emacs key bindings

# Keep Zsh's built-in history navigation. Optional Debian widgets may be
# absent or versioned differently in a minimal initramfs.

# Completion system
autoload -Uz compinit
compinit -d /tmp/.zcompdump 2>/dev/null || true

# Better completion (if available)
zstyle ':completion:*' menu select 2>/dev/null || true
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 2>/dev/null || true

# Make sure we're using UTF-8
unset LC_ALL
export LANG=C.UTF-8

# Compact welcome; set HUTOS_NO_WELCOME=1 or create ~/.config/hutos/no-welcome
# to disable it.
if [[ -z "$HUTOS_NO_WELCOME" && ! -e "$HOME/.config/hutos/no-welcome" && -o interactive ]]; then
    print -P "\n%F{cyan}HUTOS 3.1%f  %F{white}Engineering Linux%f"
    print -P "%F{green}Ready.%f  Try %F{cyan}hutos tools%f, %F{cyan}hutos about%f, or %F{cyan}hutos doctor%f.\n"
fi

# Suggest apt when a command is missing
command_not_found_handler() {
    echo "$1: command not found"
    echo "Try: sudo apt update && sudo apt install $1"
    return 127
}
