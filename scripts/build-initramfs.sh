#!/bin/bash
# HUT OS — Build initramfs from rootfs/
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ROOTFS="$PROJECT_ROOT/rootfs"
OUT="$PROJECT_ROOT/build/initramfs.cpio.gz"

mkdir -p "$PROJECT_ROOT/build"

echo "[initramfs] Packaging $ROOTFS → $OUT"

# Ensure critical permissions
chmod +x "$ROOTFS/init" 2>/dev/null || true
chmod +x "$ROOTFS/bin/about" "$ROOTFS/bin/hutinfo" 2>/dev/null || true
find "$ROOTFS/bin" -type l -exec chmod -h a+x {} \; 2>/dev/null || true

(
  cd "$ROOTFS"
  find . -print0 | cpio --null -o --format=newc 2>/dev/null | gzip -9 > "$OUT"
)

# Keep a copy at project root for backward compatibility
cp -f "$OUT" "$PROJECT_ROOT/initramfs.cpio.gz"

SIZE=$(du -h "$OUT" | cut -f1)
echo "[initramfs] Done ($SIZE)"
