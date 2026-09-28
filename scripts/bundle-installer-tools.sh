#!/bin/bash
# Bundle host GRUB + partitioning tools into the HUT OS rootfs for live install.
# These binaries run inside the QEMU guest (x86_64 Linux userspace).
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ROOTFS="$PROJECT_ROOT/rootfs"
HOST="$ROOTFS/usr/lib/hutos-install/host"
BIN="$HOST/bin"
LIB="$HOST/lib"
GRUB_MOD="$ROOTFS/usr/lib/grub"

echo "[bundle] Preparing installer host tools → $HOST"
rm -rf "$HOST"
mkdir -p "$BIN" "$LIB" "$GRUB_MOD"

copy_bin() {
  src="$1"
  name=$(basename "$src")
  if [ -x "$src" ]; then
    cp -L "$src" "$BIN/$name"
    echo "  bin: $name"
  else
    echo "Error: missing required tool: $src" >&2
    exit 1
  fi
}

# Core tools (prefer util-linux / e2fsprogs over BusyBox where quality matters)
copy_bin /usr/sbin/grub-install
copy_bin /usr/sbin/grub-probe
[ -x /usr/sbin/grub-mkimage ] && copy_bin /usr/sbin/grub-mkimage || true
[ -x /usr/bin/grub-mkimage ] && copy_bin /usr/bin/grub-mkimage || true
copy_bin /usr/sbin/blkid
copy_bin /usr/sbin/sfdisk
# Real mke2fs for reliable UUIDs/labels
if [ -x /usr/sbin/mke2fs ]; then
  cp -a /usr/sbin/mke2fs "$BIN/mke2fs"
  ln -sfn mke2fs "$BIN/mkfs.ext4"
  echo "  bin: mke2fs (+ mkfs.ext4)"
fi
# Optional helpers
[ -x /usr/sbin/partprobe ] && copy_bin /usr/sbin/partprobe || true
[ -x /usr/bin/lsblk ] && copy_bin /usr/bin/lsblk || true

# Collect shared libraries for each binary
echo "[bundle] Collecting shared libraries..."
need_libs() {
  for b in "$BIN"/*; do
    [ -f "$b" ] && [ -x "$b" ] || continue
    file "$b" | grep -q 'dynamically linked' || continue
    ldd "$b" 2>/dev/null | awk '/=>/ {print $3} /^\// {print $1}' | grep -E '^/' || true
  done
}

# Resolve recursively a few rounds (devmapper → etc.)
: > "$HOST/lib-list.txt"
for _ in 1 2 3; do
  need_libs | sort -u >> "$HOST/lib-list.txt"
  sort -u "$HOST/lib-list.txt" -o "$HOST/lib-list.txt"
  while read -r so; do
    [ -n "$so" ] && [ -f "$so" ] || continue
    base=$(basename "$so")
    [ -f "$LIB/$base" ] && continue
    cp -L "$so" "$LIB/$base"
    # Also pull deps of this .so
    ldd "$so" 2>/dev/null | awk '/=>/ {print $3}' | grep -E '^/' || true
  done < "$HOST/lib-list.txt" >> "$HOST/lib-list.txt"
  sort -u "$HOST/lib-list.txt" -o "$HOST/lib-list.txt"
done

# Dynamic linker — must be a real ELF file at /lib64 (never a relative symlink)
for ld in /lib64/ld-linux-x86-64.so.2 /lib/x86_64-linux-gnu/ld-linux-x86-64.so.2; do
  if [ -e "$ld" ]; then
    mkdir -p "$ROOTFS/lib64" "$ROOTFS/lib/x86_64-linux-gnu"
    rm -f "$ROOTFS/lib64/ld-linux-x86-64.so.2"
    rm -f "$ROOTFS/lib/x86_64-linux-gnu/ld-linux-x86-64.so.2"
    # -L dereferences host symlink so the guest gets a real loader binary
    cp -L "$ld" "$ROOTFS/lib64/ld-linux-x86-64.so.2"
    cp -L "$ld" "$ROOTFS/lib/x86_64-linux-gnu/ld-linux-x86-64.so.2"
    cp -L "$ld" "$LIB/ld-linux-x86-64.so.2" 2>/dev/null || true
    echo "  ldso: $(file "$ROOTFS/lib64/ld-linux-x86-64.so.2" | cut -d: -f2)"
    break
  fi
done

# Ensure zsh runtime libs exist in standard multiarch paths
for need in libtinfo.so.6 libcap.so.2 libc.so.6 libm.so.6; do
  if [ ! -e "$ROOTFS/usr/lib/x86_64-linux-gnu/$need" ]; then
    src=$(ldconfig -p 2>/dev/null | awk -v n="$need" '$1==n {print $NF; exit}')
    if [ -n "$src" ] && [ -f "$src" ]; then
      mkdir -p "$ROOTFS/usr/lib/x86_64-linux-gnu"
      cp -L "$src" "$ROOTFS/usr/lib/x86_64-linux-gnu/"
      echo "  lib: $need"
    fi
  fi
done

# GRUB i386-pc modules (BIOS)
if [ -d /usr/lib/grub/i386-pc ]; then
  echo "[bundle] Copying GRUB i386-pc modules..."
  rm -rf "$GRUB_MOD/i386-pc"
  mkdir -p "$GRUB_MOD"
  cp -a /usr/lib/grub/i386-pc "$GRUB_MOD/"
else
  echo "Error: /usr/lib/grub/i386-pc missing (install grub-pc-bin)" >&2
  exit 1
fi

# Ensure hut-install is executable
chmod +x "$ROOTFS/bin/hut-install" 2>/dev/null || true
chmod +x "$ROOTFS/usr/lib/hutos-install/"*.sh 2>/dev/null || true

# Symlink host tools into PATH for convenience (optional)
mkdir -p "$ROOTFS/usr/sbin"
for t in grub-install blkid sfdisk; do
  if [ -x "$BIN/$t" ]; then
    ln -sfn /usr/lib/hutos-install/host/bin/$t "$ROOTFS/usr/sbin/$t"
  fi
done
# Prefer real mkfs.ext4 when bundled
if [ -x "$BIN/mkfs.ext4" ]; then
  ln -sfn /usr/lib/hutos-install/host/bin/mkfs.ext4 "$ROOTFS/usr/sbin/mkfs.ext4"
fi

SIZE=$(du -sh "$HOST" "$GRUB_MOD/i386-pc" 2>/dev/null | awk '{print $1}' | tr '\n' ' ')
echo "[bundle] Done ($SIZE)"
