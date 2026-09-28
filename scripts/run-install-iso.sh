#!/bin/bash
# Boot HUT OS live ISO with an attached blank disk for installation.
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ISO="${HUTOS_ISO:-$PROJECT_ROOT/dist/hutos-x86_64.iso}"
[ -f "$ISO" ] || ISO="$PROJECT_ROOT/build/hutos.iso"
DISK="${HUTOS_INSTALL_DISK:-$PROJECT_ROOT/build/hutos-target.img}"
SIZE_GB="${HUTOS_TARGET_GB:-2}"
MEM="${HUTOS_MEM:-512}"

if [ ! -f "$ISO" ]; then
  echo "ISO missing — building..."
  "$PROJECT_ROOT/build.sh" iso
fi

if [ ! -f "$DISK" ]; then
  echo "Creating blank target disk ($SIZE_GB GiB) at $DISK"
  mkdir -p "$(dirname "$DISK")"
  qemu-img create -f raw "$DISK" "${SIZE_GB}G"
fi

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║     HUT OS — Live ISO + install target disk              ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo "  ISO:  $ISO"
echo "  Disk: $DISK"
echo "  Tip:  hut-install"
echo "  Exit: Ctrl+A then X"
echo ""

exec qemu-system-x86_64 \
  -m "$MEM" \
  -cdrom "$ISO" \
  -drive file="$DISK",format=raw,if=virtio \
  -boot order=d \
  -nic user,model=e1000 \
  -nographic
