#!/bin/busybox sh
# HUT OS installer — shared helpers
# shellcheck disable=SC2034

HUTOS_INSTALL_VERSION="1.0.0"
HUTOS_INSTALL_LIB="${HUTOS_INSTALL_LIB:-/usr/lib/hutos-install}"
HUTOS_TARGET_MNT="${HUTOS_TARGET_MNT:-/mnt/hutos-target}"
HUTOS_LIVE_ROOT="${HUTOS_LIVE_ROOT:-/}"

C_RESET="\033[0m"
C_CYAN="\033[1;36m"
C_GREEN="\033[1;32m"
C_YELLOW="\033[1;33m"
C_RED="\033[1;31m"
C_WHITE="\033[1;37m"
C_DIM="\033[2;37m"

die() {
	echo -e "${C_RED}ERROR:${C_RESET} $*" >&2
	exit 1
}

info() { echo -e "${C_CYAN}[INFO]${C_RESET} $*" >&2; }
ok()   { echo -e "${C_GREEN}[ OK ]${C_RESET} $*" >&2; }
warn() { echo -e "${C_YELLOW}[WARN]${C_RESET} $*" >&2; }

require_cmd() {
	command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

confirm_yes() {
	prompt="$1"
	default="${2:-N}"
	printf "%s " "$prompt"
	read -r ans || ans=""
	ans=$(echo "$ans" | tr '[:upper:]' '[:lower:]')
	if [ -z "$ans" ]; then
		ans=$(echo "$default" | tr '[:upper:]' '[:lower:]')
	fi
	case "$ans" in
		y|yes) return 0 ;;
		*) return 1 ;;
	esac
}

# Return 0 if path is a whole-disk device (not a partition).
# Prefer /sys/block/<name> which exists only for whole disks.
is_whole_disk() {
	dev="$1"
	base=$(basename "$dev")
	[ -b "$dev" ] || return 1
	[ -d "/sys/block/$base" ] && return 0
	return 1
}

partition_name() {
	disk="$1"
	partnum="$2"
	base=$(basename "$disk")
	# Names that already end with a digit need a 'p' separator (nvme0n1p1, mmcblk0p1)
	case "$base" in
		nvme*|mmcblk*|loop*|*[0-9])
			# virtio/sd/hd never end in digit as whole disks (vda, sda)
			case "$base" in
				nvme*|mmcblk*|loop*)
					echo "${disk}p${partnum}"
					;;
				*)
					# e.g. sda, vda, hda — but also reject if somehow a partition slipped through
					echo "${disk}${partnum}"
					;;
			esac
			;;
		*)
			echo "${disk}${partnum}"
			;;
	esac
}
