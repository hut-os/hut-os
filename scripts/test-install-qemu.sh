#!/bin/bash
# End-to-end QEMU test:
#   1) Boot auto-install ISO → install HUT OS to virtio disk → poweroff
#   2) Boot installed disk without ISO → selftest → poweroff
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ISO="$PROJECT_ROOT/dist/hutos-x86_64.iso"
[ -f "$ISO" ] || ISO="$PROJECT_ROOT/build/hutos.iso"
TARGET="$PROJECT_ROOT/build/hutos-target.img"
LOG_INSTALL="$PROJECT_ROOT/build/test-install.log"
LOG_BOOT="$PROJECT_ROOT/build/test-disk-boot.log"
MEM="${HUTOS_MEM:-512}"
TIMEOUT_INSTALL="${HUTOS_INSTALL_TIMEOUT:-480}"
TIMEOUT_BOOT="${HUTOS_BOOT_TIMEOUT:-180}"
KERNEL="$PROJECT_ROOT/kernel/arch/x86/boot/bzImage"

mkdir -p "$PROJECT_ROOT/build" "$PROJECT_ROOT/dist"

if [ ! -f "$PROJECT_ROOT/build/initramfs.cpio.gz" ] || [ ! -f "$ISO" ]; then
  echo "[test] Building ISO (includes initramfs + installer)..."
  "$PROJECT_ROOT/build.sh" iso
fi

echo "[test] Creating fresh 2G target disk..."
rm -f "$TARGET"
qemu-img create -f raw "$TARGET" 2G >/dev/null

# Bake HUTOS_E2E=1 into a tiny wrapper by patching initramfs is heavy;
# instead set it via kernel cmdline consumed by hut-install through init.
# init calls: hut-install --auto ...
# We export HUTOS_E2E in init when hutos.e2e=1 is on cmdline.

ISODIR="$PROJECT_ROOT/build/iso-autotest"
rm -rf "$ISODIR"
mkdir -p "$ISODIR/boot/grub"
cp "$KERNEL" "$ISODIR/boot/bzImage"
cp "$PROJECT_ROOT/build/initramfs.cpio.gz" "$ISODIR/boot/initramfs.cpio.gz"
cat > "$ISODIR/boot/grub/grub.cfg" << 'EOF'
set timeout=0
set default=0
menuentry "HUT OS Auto-Install" {
    linux /boot/bzImage console=tty0 console=ttyS0 hutos.install=/dev/vda hutos.e2e=1
    initrd /boot/initramfs.cpio.gz
}
EOF
AUTO_ISO="$PROJECT_ROOT/build/hutos-autotest.iso"
echo "[test] Building auto-test ISO..."
grub-mkrescue -o "$AUTO_ISO" "$ISODIR" >/dev/null 2>&1

echo "[test] Phase 1: Auto-install via ISO → $TARGET"
rm -f "$LOG_INSTALL"
set +e
timeout "$TIMEOUT_INSTALL" qemu-system-x86_64 \
  -m "$MEM" \
  -cdrom "$AUTO_ISO" \
  -drive file="$TARGET",format=raw,if=virtio \
  -boot order=d \
  -nic user,model=e1000 \
  -display none \
  -serial file:"$LOG_INSTALL" \
  -no-reboot \
  < /dev/null
rc=$?
set -e
echo "[test] Install QEMU finished (exit $rc)"
tail -n 80 "$LOG_INSTALL" || true

if ! grep -q "Installation complete" "$LOG_INSTALL"; then
  echo "[test] FAIL: installation did not complete — see $LOG_INSTALL" >&2
  exit 1
fi

sig=$(od -An -tx1 -N2 -j510 "$TARGET" | tr -d ' \n')
if [ "$sig" != "55aa" ]; then
  echo "[test] FAIL: missing MBR signature 55AA (got $sig)" >&2
  exit 1
fi
echo "[test] MBR signature OK"

echo "[test] Phase 2: Boot installed disk (no ISO)..."
rm -f "$LOG_BOOT"
set +e
timeout "$TIMEOUT_BOOT" qemu-system-x86_64 \
  -m "$MEM" \
  -drive file="$TARGET",format=raw,if=virtio \
  -boot order=c \
  -nic user,model=e1000 \
  -display none \
  -serial file:"$LOG_BOOT" \
  -no-reboot \
  < /dev/null
rc2=$?
set -e
echo "[test] Disk boot QEMU finished (exit $rc2)"
tail -n 120 "$LOG_BOOT" || true

if ! grep -qE 'HUT OS|System ready|Starting Zsh|SELFTEST' "$LOG_BOOT"; then
  echo "[test] FAIL: installed system did not boot to HUT OS — see $LOG_BOOT" >&2
  exit 1
fi

if ! grep -q "HUTOS SELFTEST BEGIN" "$LOG_BOOT"; then
  echo "[test] FAIL: selftest did not run (is HUTOS_E2E flag missing?)" >&2
  exit 1
fi
if ! grep -q "HUTOS SELFTEST END" "$LOG_BOOT"; then
  echo "[test] FAIL: selftest did not finish" >&2
  exit 1
fi

echo ""
echo "[test] PASS: end-to-end install + disk boot + selftest succeeded"
echo "       ISO:         $ISO"
echo "       Target disk: $TARGET"
echo "       Install log: $LOG_INSTALL"
echo "       Boot log:    $LOG_BOOT"
exit 0
