#!/bin/bash
# HUTOS Fix Script
# Fixes Zsh up-line-or-beginning-search error and adds Python 3

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOTFS="$PROJECT_ROOT/rootfs"

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║          HUTOS Fix Script - Zsh + Python 3                ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# ============================================================================
# PART 1: Fix Zsh function loading error
# ============================================================================

echo "[1/5] Fixing Zsh up-line-or-beginning-search error..."

# Create Zsh functions directory if it doesn't exist
ZSH_FUNC_DIR="$ROOTFS/usr/share/zsh/5.9/functions/Zle"
mkdir -p "$ZSH_FUNC_DIR"

# Copy required Zsh functions from host system
if [ -f /usr/share/zsh/functions/Zle/up-line-or-beginning-search ]; then
    cp /usr/share/zsh/functions/Zle/up-line-or-beginning-search "$ZSH_FUNC_DIR/"
    echo "  ✓ Copied up-line-or-beginning-search"
else
    echo "  ✗ Error: up-line-or-beginning-search not found on host"
    exit 1
fi

if [ -f /usr/share/zsh/functions/Zle/down-line-or-beginning-search ]; then
    cp /usr/share/zsh/functions/Zle/down-line-or-beginning-search "$ZSH_FUNC_DIR/"
    echo "  ✓ Copied down-line-or-beginning-search"
else
    echo "  ✗ Error: down-line-or-beginning-search not found on host"
    exit 1
fi

# Copy other commonly used Zsh functions to prevent similar errors
for func in edit-command-line; do
    if [ -f /usr/share/zsh/functions/Zle/$func ]; then
        cp /usr/share/zsh/functions/Zle/$func "$ZSH_FUNC_DIR/"
        echo "  ✓ Copied $func"
    fi
done

echo "  ✓ Zsh functions installed"
echo ""

# ============================================================================
# PART 2: Add Python 3 runtime
# ============================================================================

echo "[2/5] Adding Python 3 runtime..."

# Check if Python 3 exists on host
PYTHON_BIN=""
if [ -f /usr/bin/python3.14 ]; then
    PYTHON_BIN="/usr/bin/python3.14"
    PYTHON_VER="3.14"
elif [ -f /usr/bin/python3.12 ]; then
    PYTHON_BIN="/usr/bin/python3.12"
    PYTHON_VER="3.12"
elif [ -f /usr/bin/python3.11 ]; then
    PYTHON_BIN="/usr/bin/python3.11"
    PYTHON_VER="3.11"
elif [ -f /usr/bin/python3 ]; then
    PYTHON_BIN="/usr/bin/python3"
    PYTHON_VER=$(python3 --version 2>&1 | cut -d' ' -f2 | cut -d'.' -f1,2)
else
    echo "  ✗ Error: Python 3 not found on host system"
    exit 1
fi

echo "  Found Python $PYTHON_VER at $PYTHON_BIN"

# Copy Python binary
mkdir -p "$ROOTFS/usr/bin"
cp "$PYTHON_BIN" "$ROOTFS/usr/bin/"
PYTHON_BASENAME=$(basename "$PYTHON_BIN")
echo "  ✓ Copied $PYTHON_BASENAME"

# Create symlinks
cd "$ROOTFS/usr/bin"
ln -sf "$PYTHON_BASENAME" python3
ln -sf python3 python
cd "$PROJECT_ROOT"
echo "  ✓ Created symlinks: python3 -> $PYTHON_BASENAME, python -> python3"

# Copy required libraries for Python
echo "  Copying Python dependencies..."

# Get Python dependencies
PYTHON_DEPS=$(ldd "$PYTHON_BIN" | awk '{print $3}' | grep -v '^$')

for lib in $PYTHON_DEPS; do
    if [ -f "$lib" ]; then
        # Check if library already exists in rootfs/lib
        lib_basename=$(basename "$lib")
        if [ ! -f "$ROOTFS/lib/$lib_basename" ]; then
            cp "$lib" "$ROOTFS/lib/"
            echo "    ✓ $lib_basename"
        fi
    fi
done

# Copy additional required libraries
for lib in libexpat.so.1 libz.so.1; do
    lib_path=$(find /usr/lib /lib -name "$lib" 2>/dev/null | head -1)
    if [ -n "$lib_path" ] && [ -f "$lib_path" ]; then
        if [ ! -f "$ROOTFS/lib/$lib" ]; then
            cp "$lib_path" "$ROOTFS/lib/"
            echo "    ✓ $lib"
        fi
    fi
done

echo "  ✓ Python dependencies installed"

# ============================================================================
# PART 3: Add Python standard library (minimal)
# ============================================================================

echo "[3/5] Adding Python standard library..."

PYTHON_LIB_SRC="/usr/lib/python$PYTHON_VER"
PYTHON_LIB_DST="$ROOTFS/usr/lib/python$PYTHON_VER"

if [ ! -d "$PYTHON_LIB_SRC" ]; then
    echo "  ✗ Error: Python library directory not found: $PYTHON_LIB_SRC"
    exit 1
fi

# Create Python lib directory
mkdir -p "$PYTHON_LIB_DST"

# Copy minimal essential Python modules
# These are required for basic Python functionality
ESSENTIAL_MODULES=(
    "os.py"
    "sys.py"
    "io.py"
    "abc.py"
    "codecs.py"
    "encodings"
    "collections"
    "importlib"
    "_collections_abc.py"
    "_weakrefset.py"
    "types.py"
    "re.py"
    "sre_*.py"
    "enum.py"
    "functools.py"
    "operator.py"
    "keyword.py"
    "heapq.py"
    "reprlib.py"
    "copyreg.py"
    "builtins.py"
)

# Copy lib-dynload for compiled modules
if [ -d "$PYTHON_LIB_SRC/lib-dynload" ]; then
    cp -r "$PYTHON_LIB_SRC/lib-dynload" "$PYTHON_LIB_DST/"
    echo "  ✓ Copied lib-dynload (compiled modules)"
fi

# Copy essential modules
for module in "${ESSENTIAL_MODULES[@]}"; do
    # Use find to handle both files and directories
    find "$PYTHON_LIB_SRC" -maxdepth 1 -name "$module" 2>/dev/null | while read item; do
        if [ -e "$item" ]; then
            cp -r "$item" "$PYTHON_LIB_DST/"
            echo "  ✓ Copied $(basename "$item")"
        fi
    done
done

# Copy the site-packages structure (but keep it minimal)
if [ -d "$PYTHON_LIB_SRC/site-packages" ]; then
    mkdir -p "$PYTHON_LIB_DST/site-packages"
fi

echo "  ✓ Python standard library (minimal) installed"
echo ""

# ============================================================================
# PART 4: Verify installation
# ============================================================================

echo "[4/5] Verifying installation..."

# Check Zsh functions
if [ -f "$ROOTFS/usr/share/zsh/5.9/functions/Zle/up-line-or-beginning-search" ]; then
    echo "  ✓ Zsh functions present"
else
    echo "  ✗ Zsh functions missing"
    exit 1
fi

# Check Python binary
if [ -f "$ROOTFS/usr/bin/python3" ]; then
    echo "  ✓ Python 3 binary present"
else
    echo "  ✗ Python 3 binary missing"
    exit 1
fi

# Check Python libraries
if [ -d "$ROOTFS/usr/lib/python$PYTHON_VER" ]; then
    echo "  ✓ Python standard library present"
else
    echo "  ✗ Python standard library missing"
    exit 1
fi

echo "  ✓ All components verified"
echo ""

# ============================================================================
# PART 5: Rebuild initramfs
# ============================================================================

echo "[5/5] Rebuilding initramfs..."

"$PROJECT_ROOT/build-initramfs.sh"

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                  Fix Complete!                            ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "Changes made:"
echo "  1. Added Zsh functions: up-line-or-beginning-search, down-line-or-beginning-search"
echo "  2. Added Python $PYTHON_VER runtime"
echo "  3. Added Python dependencies and minimal standard library"
echo "  4. Rebuilt initramfs.cpio.gz"
echo ""
echo "Test with:"
echo "  ./run.sh"
echo ""
echo "In QEMU, verify:"
echo "  • Zsh starts without errors"
echo "  • python3 --version"
echo "  • python3 -c 'print(\"HUTOS Python OK\")'"
echo ""
