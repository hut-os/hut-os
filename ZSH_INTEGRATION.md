# HUT OS - Zsh Integration

## Overview

HUT OS now uses **Zsh with Oh My Zsh** as the default interactive shell, replacing BusyBox ash. This provides a modern, powerful shell experience while maintaining the minimal, self-contained nature of HUT OS.

---

## What Changed

### Version 2.1.0 - Zsh Integration

**Before:**
- Default shell: BusyBox ash
- Basic prompt: `hut@hut-os:~#`
- No shell enhancement framework

**After:**
- Default shell: **Zsh 5.9**
- Enhanced shell framework: **Oh My Zsh**
- Colored prompt: `hut@hut-os:~#` (cyan and blue)
- Better completion, history, and aliases
- Full Zsh features available

---

## Architecture

### Components Added

1. **Zsh Binary** (`/bin/zsh`)
   - Full Zsh shell (954 KB)
   - Dynamically linked

2. **Shared Libraries**
   - `libc.so.6` - C standard library
   - `libm.so.6` - Math library
   - `libtinfo.so.6` - Terminal info library
   - `libcap.so.2` - POSIX capabilities library
   - `ld-linux-x86-64.so.2` - ELF interpreter

3. **Zsh Modules** (`/usr/lib/x86_64-linux-gnu/zsh/5.9/zsh/`)
   - `zle.so` - Line editor
   - `parameter.so` - Parameter module
   - `complete.so`, `complist.so`, `computil.so` - Completion system
   - And 30+ other modules

4. **Zsh Functions** (`/usr/share/zsh/5.9/functions/`)
   - Core Zsh functions for completion and utilities

5. **Oh My Zsh** (`/root/.oh-my-zsh/`)
   - Minimal installation (~556 KB)
   - Essential plugins only
   - Lightweight themes

6. **Configuration**
   - `/root/.zshrc` - Zsh configuration
   - `/etc/passwd` - Root shell set to `/bin/zsh`
   - `/etc/group` - Basic group configuration

7. **Terminfo**
   - Linux terminal definition
   - xterm terminal definition

8. **BusyBox Command Symlinks**
   - `mkdir`, `rm`, `mv`, `cp`, `ln`, `cat`, `grep`, etc.
   - All point to BusyBox for minimal size

---

## Configuration

### `.zshrc` Features

```zsh
# HUT OS Identity
export HUTOS_VERSION="2.1.0"
export HUTOS_NAME="HUT OS"

# Custom Prompt
PROMPT='%{%F{cyan}%}hut@hut-os%{%f%}:%{%F{blue}%}%~%{%f%}# '

# Aliases
alias about='/bin/about'
alias ll='ls -lah'
alias la='ls -A'
alias huname='echo "$HUTOS_NAME - Hamedan University of Technology Operating System"'

# History
HISTFILE=/root/.zsh_history
HISTSIZE=1000
SAVEHIST=1000

# Completion
autoload -Uz compinit
compinit
```

### Oh My Zsh Configuration

- **Theme:** Custom HUT OS prompt
- **Plugins:** Minimal (none active by default for speed)
- **Auto-update:** Disabled (no network in initramfs)

---

## Size Impact

| Component | Size |
|-----------|------|
| Original initramfs | 1.1 MB |
| **Zsh initramfs** | **3.9 MB** |
| Increase | +2.8 MB |

### Breakdown
- Zsh binary: 954 KB
- Shared libraries: ~1.5 MB
- Zsh modules: ~600 KB
- Oh My Zsh: 556 KB
- Zsh functions: ~200 KB
- Terminfo: minimal

---

## Boot Flow

```
Kernel Boot
    ↓
initramfs loaded
    ↓
/init executed (BusyBox sh)
    ↓
Mount: /proc, /sys, /dev
    ↓
Display HUT OS banner
    ↓
Show welcome message
    ↓
Set environment:
  - HOME=/root
  - PATH=/bin:/sbin:/usr/bin:/usr/sbin
  - TERM=linux
    ↓
Launch: exec /bin/zsh
    ↓
Zsh starts
    ↓
Load /root/.zshrc
    ↓
Initialize Oh My Zsh
    ↓
Display Zsh welcome message
    ↓
Show colored prompt: hut@hut-os:~#
```

---

## Setup Scripts

### `setup-zsh.sh`
Installs Zsh, Oh My Zsh, and dependencies into rootfs:
- Copies Zsh binary
- Copies shared libraries
- Downloads Oh My Zsh
- Creates configuration files
- Sets up /etc/passwd

### `fix-zsh-modules.sh`
Adds Zsh modules and BusyBox command symlinks:
- Copies Zsh .so modules
- Copies Zsh function files
- Creates BusyBox symlinks for common commands

---

## Testing Checklist

✅ **Boot Test**
- Kernel boots successfully
- Init script executes
- Filesystems mount correctly
- Banner displays

✅ **Zsh Launch**
- Zsh binary found and executed
- No missing library errors
- No missing module errors
- Prompt appears correctly

✅ **Functionality**
- Colors work (cyan prompt)
- Tab completion works
- Command history works
- Aliases work (`about`, `ll`, etc.)
- BusyBox commands work (`ls`, `cat`, `grep`, etc.)

✅ **Self-Containment**
- No host dependencies at runtime
- All libraries included in initramfs
- No network required
- Works in isolated QEMU environment

---

## Troubleshooting

### Issue: "can't find terminal definition for linux"
**Solution:** Terminfo files added to `/usr/share/terminfo/l/linux`

### Issue: "command not found: mkdir/rm/etc"
**Solution:** BusyBox symlinks created in `/bin/`

### Issue: "failed to load module zsh/zle.so"
**Solution:** Zsh modules copied to `/usr/lib/x86_64-linux-gnu/zsh/5.9/zsh/`

### Issue: "compinit: function definition file not found"
**Solution:** Zsh functions copied to `/usr/share/zsh/5.9/functions/`

---

## Commands Available

### HUT OS Custom Commands
- `about` - Display HUT OS information
- `huname` - Show HUT OS name

### Shell Aliases
- `ll` - List files (long format with all)
- `la` - List almost all files
- `l` - List in columns
- `cls` - Clear screen

### BusyBox Commands
- All standard BusyBox utilities available
- File operations: `ls`, `cat`, `cp`, `mv`, `rm`, `mkdir`
- Text processing: `grep`, `sed`, `awk`, `cut`, `sort`
- System: `mount`, `ps`, `free`, `uname`

### Zsh Features
- Command completion with Tab
- History navigation with Up/Down arrows
- Emacs key bindings (Ctrl+A, Ctrl+E, etc.)
- Colored prompt
- Path expansion

---

## Comparison: ash vs Zsh

| Feature | BusyBox ash | Zsh |
|---------|-------------|-----|
| Size | ~2 MB (total) | ~4 MB (total) |
| Completion | Basic | Advanced |
| History | Basic | Advanced with search |
| Prompt | Simple | Customizable, colored |
| Scripting | POSIX | Extended |
| Plugins | None | Oh My Zsh ecosystem |
| Feel | Minimal | Modern |

---

## Development

### Rebuilding After Changes

```bash
# Make changes to rootfs/
nano rootfs/root/.zshrc

# Rebuild initramfs
./build-initramfs.sh

# Test
./run.sh
```

### Adding Zsh Plugins

1. Edit `rootfs/root/.zshrc`
2. Add plugin to `plugins=()` array
3. Ensure plugin exists in `.oh-my-zsh/plugins/`
4. Rebuild initramfs

**Note:** Keep plugins minimal to avoid size bloat

### Customizing Prompt

Edit `PROMPT` variable in `/root/.zshrc`:

```zsh
# Example: Add time
PROMPT='%{%F{cyan}%}[%*] hut@hut-os%{%f%}:%{%F{blue}%}%~%{%f%}# '

# Example: Add exit status
PROMPT='%{%F{cyan}%}hut@hut-os%{%f%}:%{%F{blue}%}%~%{%f%} %(?.%{%F{green}%}.%{%F{red}%})%#%{%f%} '
```

---

## Performance

- **Boot time:** < 3 seconds (unchanged)
- **Memory usage:** ~10 MB additional (Zsh + libraries)
- **Shell startup:** < 1 second
- **Responsiveness:** Excellent

---

## Future Enhancements

Potential improvements:

- **Zsh Themes:** Add more Oh My Zsh themes
- **Plugins:** Enable useful plugins (git, docker, etc.)
- **Syntax Highlighting:** Add zsh-syntax-highlighting
- **Auto-suggestions:** Add zsh-autosuggestions
- **Custom Functions:** HUT OS-specific Zsh functions

**Constraint:** Keep initramfs under 10 MB

---

## Credits

- **Zsh:** https://www.zsh.org/
- **Oh My Zsh:** https://ohmyz.sh/
- **HUT OS:** Arshia Mohammadei
- **University:** Hamedan University of Technology

---

## Summary

HUT OS now provides a **modern, powerful shell experience** while maintaining its identity as a **minimal, educational operating system**. Zsh with Oh My Zsh gives users:

- Better command completion
- Enhanced history
- Colored, customizable prompt
- Rich scripting capabilities
- Professional terminal feel

All while remaining **completely self-contained** in a 3.9 MB initramfs with **no external dependencies**.

**HUT OS: Now with the power of Zsh!** 🚀

---

*Proudly built at Hamedan University of Technology* 🎓

**Developer:** Arshia Mohammadei  
**GitHub:** [@itashia](https://github.com/itashia)  
**Version:** 2.1.0
