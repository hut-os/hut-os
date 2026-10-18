#!/bin/bash

# HUT OS Initramfs Build Script
# This script packages the rootfs directory into an initramfs

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOTFS_DIR="$PROJECT_ROOT/rootfs"
OUTPUT_FILE="$PROJECT_ROOT/initramfs.cpio.gz"

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║          HUT OS Initramfs Build Script                   ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Check if rootfs exists
if [ ! -d "$ROOTFS_DIR" ]; then
    echo "Error: rootfs directory not found at $ROOTFS_DIR"
    exit 1
fi

echo "[1/4] Verifying rootfs structure..."
if [ ! -f "$ROOTFS_DIR/init" ]; then
    echo "Error: /init not found in rootfs"
    exit 1
fi

if [ ! -x "$ROOTFS_DIR/init" ]; then
    echo "Warning: /init is not executable, fixing..."
    chmod +x "$ROOTFS_DIR/init"
fi

if [ ! -f "$ROOTFS_DIR/bin/busybox" ]; then
    echo "Error: BusyBox binary not found"
    exit 1
fi

# Ensure HUTOS tools are executable
for tool in about hutctl hutinfo hutsched hutbench hutdiag apt sudo hutos; do
    if [ -f "$ROOTFS_DIR/bin/$tool" ]; then
        chmod +x "$ROOTFS_DIR/bin/$tool"
    fi
done

chmod 04755 "$ROOTFS_DIR/bin/sudo"
chmod 0440 "$ROOTFS_DIR/etc/sudoers"
chmod 0640 "$ROOTFS_DIR/etc/shadow"
chmod 0700 "$ROOTFS_DIR/var/lib/sudo"

if [ -x "$PROJECT_ROOT/scripts/bundle-userland-tools.sh" ]; then
    "$PROJECT_ROOT/scripts/bundle-userland-tools.sh"
fi
"$PROJECT_ROOT/scripts/build-hutos-tools.sh"

# Ensure common library is present
if [ -f "$ROOTFS_DIR/lib/hutos-common.sh" ]; then
    chmod +x "$ROOTFS_DIR/lib/hutos-common.sh"
    echo "  ✓ HUTOS tools configured"
fi

# Check for banner
if [ -f "$ROOTFS_DIR/etc/hut-banner.txt" ]; then
    echo "  ✓ HUT banner found"
else
    echo "  ⚠ Warning: HUT banner not found (will use fallback)"
fi

echo "  ✓ Rootfs structure verified"
echo ""

echo "[2/4] Creating initramfs archive..."
cd "$ROOTFS_DIR"

# Create the cpio archive and compress it
{
    find . -path ./home/hut -prune -o -print0 |
        cpio --null -o --format=newc --owner=0:0 2>/dev/null
    find ./home/hut -print0 |
        cpio --null -o --format=newc --owner=1000:1000 2>/dev/null
} | gzip -9 > "$OUTPUT_FILE"

if [ $? -ne 0 ]; then
    echo "Error: Failed to create initramfs"
    exit 1
fi

echo "  ✓ Archive created"
echo ""

echo "[3/4] Verifying output..."
if [ ! -f "$OUTPUT_FILE" ]; then
    echo "Error: Output file not created"
    exit 1
fi

FILE_SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)
echo "  ✓ Initramfs size: $FILE_SIZE"
echo ""

echo "[4/4] Build complete!"
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  Output: $OUTPUT_FILE"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "To test HUT OS, run:"
echo "  qemu-system-x86_64 -m 512 -kernel kernel/arch/x86/boot/bzImage \\"
echo "                     -initrd initramfs.cpio.gz \\"
echo "                     -append \"console=ttyS0\" \\"
echo "                     -nographic"
echo ""
