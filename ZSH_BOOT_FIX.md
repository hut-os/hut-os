# HUTOS Zsh Boot Fix Summary

**Date:** September 28, 2026  
**Issue:** `/init: line 246: /bin/zsh: not found`  
**Status:** ✅ **FIXED**

---

## Problem

The HUTOS initramfs was attempting to start Zsh at boot, but the Zsh executable was missing required runtime dependencies, causing the boot to fail with:

```
/init: line 246: /bin/zsh: not found
```

While the Zsh binary itself existed at `/bin/zsh`, the dynamic linker couldn't locate its shared library dependencies.

---

## Root Cause

1. **Zsh binary was present** (`rootfs/bin/zsh` - 976KB)
2. **Initial libraries copied** (libc.so.6, libm.so.6, libtinfo.so.6, libcap.so.2) to `/usr/lib/x86_64-linux-gnu/`
3. **Missing additional dependencies**:
   - libncursesw.so.6 (for Zsh modules)
   - libpcre2-8.so.0 (for Zsh modules)
   - libgdbm.so.6 (for Zsh gdbm module)
4. **Library search path issue**: Libraries were in `/usr/lib/x86_64-linux-gnu/` but the dynamic linker wasn't searching there by default

---

## Solution Applied

### 1. Added Missing Libraries

Copied three additional shared libraries required by Zsh modules:

```bash
# From host system to rootfs
/usr/lib/x86_64-linux-gnu/libncursesw.so.6  (239 KB)
/usr/lib/x86_64-linux-gnu/libpcre2-8.so.0   (683 KB)
/usr/lib/x86_64-linux-gnu/libgdbm.so.6      (75 KB)
```

### 2. Created Library Symlinks

Created symlinks in `/lib/` to ensure the dynamic linker can find all libraries:

```bash
rootfs/lib/libc.so.6 -> ../usr/lib/x86_64-linux-gnu/libc.so.6
rootfs/lib/libcap.so.2 -> ../usr/lib/x86_64-linux-gnu/libcap.so.2
rootfs/lib/libgdbm.so.6 -> ../usr/lib/x86_64-linux-gnu/libgdbm.so.6
rootfs/lib/libm.so.6 -> ../usr/lib/x86_64-linux-gnu/libm.so.6
rootfs/lib/libncursesw.so.6 -> ../usr/lib/x86_64-linux-gnu/libncursesw.so.6
rootfs/lib/libpcre2-8.so.0 -> ../usr/lib/x86_64-linux-gnu/libpcre2-8.so.0
rootfs/lib/libtinfo.so.6 -> ../usr/lib/x86_64-linux-gnu/libtinfo.so.6
```

### 3. Created System Configuration Files

Added essential configuration files:

#### `/etc/ld.so.conf`
```
/lib
/lib64
/usr/lib
/usr/lib/x86_64-linux-gnu
/lib/x86_64-linux-gnu
```

#### `/etc/shells`
```
/bin/sh
/bin/ash
/bin/zsh
```

### 4. Rebuilt Initramfs

```bash
./scripts/build-initramfs.sh
```

**Result:** 40M compressed initramfs containing all necessary Zsh dependencies

---

## Verification

### Boot Test Results

✅ **QEMU Boot Successful:**
```
[1;32m[ OK ][0m Starting Zsh shell

╔══════════════════════════════════════════════════════════════╗
║               Welcome to Zsh on HUT OS                       ║
╚══════════════════════════════════════════════════════════════╝

Zsh with Oh My Zsh is now running!

hut@hut-os:~#
```

### All Requirements Met

✅ Zsh exists at `/bin/zsh` (976KB ELF 64-bit executable)  
✅ All runtime dependencies present and accessible  
✅ Dynamic linker can find all libraries  
✅ Directory structure correct (`/lib`, `/lib64`, `/usr/lib`)  
✅ `/etc/passwd`, `/etc/group`, `/etc/shells` exist  
✅ Zsh + Oh My Zsh configuration preserved  
✅ HUTOS branding and `/init` script preserved  
✅ No WSL host file dependencies at runtime  
✅ Initramfs rebuilt successfully (40M)  
✅ QEMU boot successful with Zsh prompt appearing  

### Working Commands

The following commands are verified working in the Zsh shell:

- `about` - Display HUT OS information ✅
- `hutinfo` - Show system details ✅
- `clear` - Clear screen ✅
- `zsh --version` - Show Zsh version ✅
- `ll` - List files (Oh My Zsh alias) ✅
- `huname` - HUT OS custom command ✅

---

## Files Modified

### New Files Created:
```
rootfs/etc/ld.so.conf                           # Dynamic linker config
rootfs/etc/shells                               # Valid shells list
rootfs/lib/libc.so.6                           # Symlink
rootfs/lib/libcap.so.2                         # Symlink
rootfs/lib/libgdbm.so.6                        # Symlink
rootfs/lib/libm.so.6                           # Symlink
rootfs/lib/libncursesw.so.6                    # Symlink
rootfs/lib/libpcre2-8.so.0                     # Symlink
rootfs/lib/libtinfo.so.6                       # Symlink
rootfs/usr/lib/x86_64-linux-gnu/libgdbm.so.6   # Library
rootfs/usr/lib/x86_64-linux-gnu/libncursesw.so.6 # Library
rootfs/usr/lib/x86_64-linux-gnu/libpcre2-8.so.0  # Library
build/initramfs.cpio.gz                        # Rebuilt
initramfs.cpio.gz                              # Rebuilt
```

### Unchanged (Preserved):
```
rootfs/init                                     # Init script with Zsh
rootfs/bin/zsh                                 # Zsh binary
rootfs/root/.zshrc                             # Zsh config
rootfs/root/.oh-my-zsh/                        # Oh My Zsh installation
rootfs/usr/lib/x86_64-linux-gnu/zsh/           # Zsh modules
rootfs/usr/share/zsh/                          # Zsh data files
```

---

## Rebuild & Test Commands

### Rebuild Initramfs:
```bash
cd /home/arshiamohammadei/home/projects/HUTOS
./scripts/build-initramfs.sh
```

### Test Boot in QEMU:
```bash
# Quick test (exits after 30 seconds)
./test-in-qemu.sh

# Interactive verification
./verify-zsh-fix.sh
```

### Manual QEMU Test:
```bash
qemu-system-x86_64 \
    -kernel kernel/arch/x86/boot/bzImage \
    -initrd initramfs.cpio.gz \
    -append "console=ttyS0 quiet" \
    -m 512M \
    -smp 2 \
    -nographic \
    -no-reboot
```

**Exit QEMU:** Press `Ctrl-A` then `X`

---

## Technical Details

### Zsh Dependencies (Complete List)

**Main Zsh binary dependencies:**
```
libcap.so.2        (51 KB)   - Capabilities library
libtinfo.so.6      (208 KB)  - Terminal info library
libm.so.6          (1.2 MB)  - Math library
libc.so.6          (2.1 MB)  - C standard library
ld-linux-x86-64.so.2 (255 KB) - Dynamic linker
```

**Zsh module dependencies:**
```
libncursesw.so.6   (239 KB)  - Wide-char ncurses (for curses.so module)
libpcre2-8.so.0    (683 KB)  - PCRE2 regex (for pcre.so module)
libgdbm.so.6       (75 KB)   - GNU DBM (for db/gdbm.so module)
```

**Total library size:** ~4.8 MB

### Library Search Path

The dynamic linker (`ld-linux-x86-64.so.2`) searches for libraries in:
1. `/lib` (via symlinks)
2. `/lib64` (contains dynamic linker itself)
3. `/usr/lib` (standard location)
4. `/usr/lib/x86_64-linux-gnu` (multiarch location, actual libraries)

---

## Key Insights

1. **BusyBox shell is still available** as fallback at `/bin/sh`
2. **Oh My Zsh is fully functional** with themes and plugins
3. **No WSL dependencies** - all libraries self-contained in initramfs
4. **Initramfs is self-contained** - no external mounting required
5. **Dynamic linking works** - all shared libraries properly resolved

---

## Success Criteria ✅

| Requirement | Status |
|-------------|--------|
| No `/bin/zsh: not found` error | ✅ Fixed |
| Zsh starts successfully | ✅ Working |
| Zsh prompt appears | ✅ Working |
| `about` command works | ✅ Working |
| `hutinfo` command works | ✅ Working |
| `clear` command works | ✅ Working |
| Oh My Zsh functional | ✅ Working |
| HUTOS branding preserved | ✅ Preserved |
| No BusyBox fallback needed | ✅ Zsh is default |
| Boots in QEMU | ✅ Verified |

---

## Conclusion

The HUTOS boot failure has been **completely resolved**. Zsh now starts successfully on boot with all its dependencies properly configured. The system maintains its original design with Zsh as the default shell, Oh My Zsh configuration, and all HUTOS custom commands functional.

**No workarounds or compromises were needed** - the original Zsh implementation is fully working as intended.
