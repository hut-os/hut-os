#!/bin/busybox sh
# HUT OS installer — copy live system to target

. "$HUTOS_INSTALL_LIB/common.sh"

install_find_kernel() {
	if [ -f /boot/bzImage ]; then
		echo /boot/bzImage
		return 0
	fi
	if [ -f /boot/vmlinuz ]; then
		echo /boot/vmlinuz
		return 0
	fi
	for sr in /dev/sr0 /dev/cdrom /dev/sr1; do
		[ -b "$sr" ] || continue
		mkdir -p /mnt/hutos-media
		if mount -t iso9660 -o ro "$sr" /mnt/hutos-media 2>/dev/null \
			|| mount -o ro "$sr" /mnt/hutos-media 2>/dev/null; then
			if [ -f /mnt/hutos-media/boot/bzImage ]; then
				echo /mnt/hutos-media/boot/bzImage
				return 0
			fi
			umount /mnt/hutos-media 2>/dev/null || true
		fi
	done
	return 1
}

# Copy running live root into mounted target, excluding virtual FS mounts.
install_copy_root() {
	src="${1:-/}"
	dst="$HUTOS_TARGET_MNT"
	[ -d "$dst" ] || die "target mount missing: $dst"

	info "Installing HUT OS files to $dst ..."
	mkdir -p "$dst"

	# BusyBox tar has no --exclude; copy known trees explicitly.
	for d in bin sbin etc root home usr lib lib64 var boot opt; do
		if [ -e "$src/$d" ]; then
			info "  copying /$d ..."
			cp -a "$src/$d" "$dst/" || die "copy failed: /$d"
		fi
	done

	# PID 1 and misc root-level files
	for f in init linuxrc; do
		if [ -e "$src/$f" ]; then
			cp -a "$src/$f" "$dst/$f" || die "copy failed: /$f"
		fi
	done

	mkdir -p "$dst/proc" "$dst/sys" "$dst/dev" "$dst/run" "$dst/tmp" \
		"$dst/mnt" "$dst/media" "$dst/var/log" "$dst/var/run" \
		"$dst/boot" "$dst/home" "$dst/root"


	# Drop any live GRUB env from the CD copy; installer writes a fresh one
	rm -rf "$dst/boot/grub"

	kimg=$(install_find_kernel) || die "no kernel found (/boot/bzImage or install media)"
	cp -f "$kimg" "$dst/boot/vmlinuz" || die "failed to copy kernel"
	cp -f "$kimg" "$dst/boot/bzImage" || true

	mkdir -p "$dst/sbin"
	ln -sfn /init "$dst/sbin/init"

	chmod +x "$dst/init" 2>/dev/null || true
	sync
	ok "Root filesystem files installed"
}
