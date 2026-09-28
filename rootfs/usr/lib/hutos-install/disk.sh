#!/bin/busybox sh
# HUT OS installer — disk detection & partitioning (MBR, single Linux partition)

. "$HUTOS_INSTALL_LIB/common.sh"

# Print lines: INDEX\tDEVICE\tSIZE\tMODEL
disk_list() {
	idx=1
	for path in /sys/block/*; do
		[ -d "$path" ] || continue
		name=$(basename "$path")
		case "$name" in
			loop*|ram*|fd*|sr*|dm-*|md*) continue ;;
		esac
		# skip removable optical-ish; allow virtio/scsi/ide/nvme
		dev="/dev/$name"
		[ -b "$dev" ] || continue
		size_sectors=$(cat "$path/size" 2>/dev/null || echo 0)
		# size in bytes (512-byte sectors)
		size_bytes=$((size_sectors * 512))
		size_h=$(disk_human_size "$size_bytes")
		model=$(cat "$path/device/model" 2>/dev/null | tr -s ' ' | sed 's/^ *//;s/ *$//')
		[ -n "$model" ] || model="disk"
		echo -e "${idx}\t${dev}\t${size_h}\t${model}"
		idx=$((idx + 1))
	done
}

disk_human_size() {
	bytes="$1"
	if [ "$bytes" -ge 1073741824 ]; then
		echo "$((bytes / 1073741824))G"
	elif [ "$bytes" -ge 1048576 ]; then
		echo "$((bytes / 1048576))M"
	else
		echo "${bytes}B"
	fi
}

disk_show() {
	echo -e "${C_WHITE}Available disks${C_RESET}"
	echo "---------------"
	list=$(disk_list)
	if [ -z "$list" ]; then
		warn "No suitable block devices found."
		return 1
	fi
	echo -e "Idx\tDevice\tSize\tModel"
	echo "$list"
	return 0
}

disk_by_index() {
	want="$1"
	# Avoid pipe/subshell so the match is reliable under BusyBox ash
	found=""
	while IFS=$(printf '\t') read -r i dev size model; do
		if [ "$i" = "$want" ]; then
			found="$dev"
			break
		fi
	done <<EOF
$(disk_list)
EOF
	[ -n "$found" ] || return 1
	echo "$found"
}

# Create DOS partition table with one primary Linux partition covering the disk.
# Sets bootable flag.
disk_partition_mbr_single() {
	disk="$1"
	is_whole_disk "$disk" || die "refusing to partition non-disk device: $disk"
	require_cmd fdisk
	require_cmd sync

	info "Creating MBR partition table on $disk (single Linux partition)..."

	parted_ok=0
	if command -v sfdisk >/dev/null 2>&1; then
		if sfdisk --force "$disk" >/tmp/hutos-fdisk.log 2>&1 <<EOF
label: dos
unit: sectors
, , L, *
EOF
		then
			parted_ok=1
		else
			warn "sfdisk failed — falling back to BusyBox fdisk (see /tmp/hutos-fdisk.log)"
			cat /tmp/hutos-fdisk.log >&2 || true
		fi
	fi

	if [ "$parted_ok" -ne 1 ]; then
		require_cmd fdisk
		printf 'o\nn\np\n1\n\n\na\nw\n' | fdisk "$disk" >/tmp/hutos-fdisk.log 2>&1 \
			|| die "fdisk failed on $disk (see /tmp/hutos-fdisk.log)"
	fi

	sync
	partprobe "$disk" 2>/dev/null || true
	# Allow kernel to refresh partitions
	sleep 1
	mdev -s 2>/dev/null || true
	sleep 1

	part=$(partition_name "$disk" 1)
	[ -b "$part" ] || die "partition not found after partitioning: $part"
	ok "Partition ready: $part"
	printf '%s\n' "$part"
}
