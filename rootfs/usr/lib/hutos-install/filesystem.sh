#!/bin/busybox sh
# HUT OS installer — filesystem creation & mounting

. "$HUTOS_INSTALL_LIB/common.sh"

fs_format_ext4() {
	part="$1"
	label="${2:-HUTOS}"
	[ -b "$part" ] || die "not a block device: $part"

	info "Creating ext4 filesystem on $part (label=$label)..."
	if command -v mkfs.ext4 >/dev/null 2>&1; then
		mkfs.ext4 -F -L "$label" "$part" >/tmp/hutos-mkfs.log 2>&1 \
			|| die "mkfs.ext4 failed (see /tmp/hutos-mkfs.log)"
	else
		# BusyBox mke2fs
		mke2fs -t ext4 -F -L "$label" "$part" >/tmp/hutos-mkfs.log 2>&1 \
			|| die "mke2fs ext4 failed (see /tmp/hutos-mkfs.log)"
	fi
	sync
	ok "Filesystem created on $part"
}

fs_get_uuid() {
	part="$1"
	if command -v blkid >/dev/null 2>&1; then
		blkid -s UUID -o value "$part" 2>/dev/null && return 0
	fi
	echo ""
}

fs_get_partuuid() {
	part="$1"
	if command -v blkid >/dev/null 2>&1; then
		blkid -s PARTUUID -o value "$part" 2>/dev/null && return 0
	fi
	echo ""
}

fs_mount_target() {
	part="$1"
	mnt="$HUTOS_TARGET_MNT"
	mkdir -p "$mnt" || die "cannot create $mnt"
	mount -t ext4 "$part" "$mnt" || die "failed to mount $part on $mnt"
	ok "Mounted $part → $mnt"
}

fs_umount_target() {
	mnt="$HUTOS_TARGET_MNT"
	sync
	umount "$mnt" 2>/dev/null || umount -l "$mnt" 2>/dev/null || true
}
