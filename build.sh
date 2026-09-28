#!/bin/bash
# HUT OS — Unified build entry point
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_ROOT"

CYAN='\033[1;36m'
GREEN='\033[1;32m'
RESET='\033[0m'

TARGET="${1:-all}"

echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}║              HUT OS 3.0 — Build System                   ║${RESET}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${RESET}"
echo ""

build_initramfs() {
  echo -e "${GREEN}→${RESET} Building initramfs..."
  "$PROJECT_ROOT/scripts/build-initramfs.sh"
}

build_disk() {
  echo -e "${GREEN}→${RESET} Building ext4 disk image..."
  "$PROJECT_ROOT/scripts/build-disk.sh"
}

build_iso() {
  echo -e "${GREEN}→${RESET} Building GRUB ISO..."
  "$PROJECT_ROOT/scripts/build-iso.sh"
}

case "$TARGET" in
  initramfs|ramfs)
    build_initramfs
    ;;
  disk|img)
    build_initramfs
    build_disk
    ;;
  iso)
    build_initramfs
    build_iso
    ;;
  all)
    build_initramfs
    build_disk
    build_iso
    ;;
  *)
    echo "Usage: $0 [all|initramfs|disk|iso]"
    exit 1
    ;;
esac

echo ""
echo -e "${CYAN}════════════════════════════════════════════════════════════${RESET}"
echo -e "  Build complete. Artifacts:"
for f in "$PROJECT_ROOT/build/initramfs.cpio.gz" \
         "$PROJECT_ROOT/build/hutos.img" \
         "$PROJECT_ROOT/build/hutos.iso"; do
  [ -f "$f" ] && echo "    $(basename "$f")  ($(du -h "$f" | cut -f1))"
done
echo -e "${CYAN}════════════════════════════════════════════════════════════${RESET}"
echo ""
echo "Boot options:"
echo "  ./run.sh                      # initramfs (fast)"
echo "  ./scripts/run-disk.sh         # persistent ext4 disk"
echo "  ./scripts/run-iso.sh          # GRUB ISO (live)"
echo "  ./scripts/run-install-iso.sh  # ISO + blank disk (installer)"
echo "  ./scripts/test-install-qemu.sh # end-to-end install test"
echo ""
echo "ISO artifact: dist/hutos-x86_64.iso"
echo ""
