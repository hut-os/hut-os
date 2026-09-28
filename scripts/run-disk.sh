#!/bin/bash
# Boot HUT OS from persistent ext4 disk (kernel + root=/dev/vda)
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
KERNEL="$PROJECT_ROOT/kernel/arch/x86/boot/bzImage"
DISK="$PROJECT_ROOT/build/hutos.img"

if [ ! -f "$DISK" ]; then
  echo "Disk image missing — building..."
  "$PROJECT_ROOT/build.sh" disk
fi

echo "Booting HUT OS from disk (root=/dev/vda)..."
echo "Exit QEMU: Ctrl+A then X"
echo ""

exec qemu-system-x86_64 \
  -m 256 \
  -kernel "$KERNEL" \
  -drive file="$DISK",format=raw,if=virtio \
  -append "root=/dev/vda rw rootwait console=ttyS0 init=/init" \
  -nic user,model=e1000 \
  -nographic
