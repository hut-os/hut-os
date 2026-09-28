#!/bin/bash
# Boot HUT OS from GRUB ISO
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ISO="$PROJECT_ROOT/build/hutos.iso"

if [ ! -f "$ISO" ]; then
  echo "ISO missing — building..."
  "$PROJECT_ROOT/build.sh" iso
fi

echo "Booting HUT OS from ISO (GRUB)..."
echo "Exit QEMU: Ctrl+A then X"
echo ""

exec qemu-system-x86_64 \
  -m 256 \
  -cdrom "$ISO" \
  -boot d \
  -nic user,model=e1000 \
  -nographic
