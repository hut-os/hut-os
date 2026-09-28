#!/bin/busybox sh
# HUTOS Common Library
# Shared functions for HUTOS system tools

# ANSI Colors
C_RESET="\033[0m"
C_CYAN="\033[1;36m"
C_GREEN="\033[1;32m"
C_WHITE="\033[1;37m"
C_DIM="\033[2;37m"
C_YELLOW="\033[1;33m"
C_RED="\033[1;31m"
C_BLUE="\033[1;34m"

# Constants
HUTOS_VERSION="3.0.0"
HUTOS_NAME="HUT OS"

# Source os-release if available
if [ -f /etc/os-release ]; then
	# shellcheck disable=SC1091
	. /etc/os-release
	[ -n "$PRETTY_NAME" ] && HUTOS_NAME="$PRETTY_NAME"
	[ -n "$VERSION_ID" ] && HUTOS_VERSION="$VERSION_ID"
fi

# Print colored status message
# Usage: print_status <type> <message>
print_status() {
	local type="$1"
	shift
	local message="$*"
	
	case "$type" in
		ok)   echo -e "${C_GREEN}[ OK ]${C_RESET} $message" ;;
		info) echo -e "${C_CYAN}[INFO]${C_RESET} $message" ;;
		warn) echo -e "${C_YELLOW}[WARN]${C_RESET} $message" ;;
		fail) echo -e "${C_RED}[FAIL]${C_RESET} $message" ;;
		*)    echo -e "${C_DIM}[ -- ]${C_RESET} $message" ;;
	esac
}

# Print header
# Usage: print_header <title>
print_header() {
	local title="$1"
	echo ""
	echo -e "${C_CYAN}╔══════════════════════════════════════════════════════════════╗${C_RESET}"
	printf "${C_CYAN}║ %-60s ║${C_RESET}\n" "$title"
	echo -e "${C_CYAN}╚══════════════════════════════════════════════════════════════╝${C_RESET}"
	echo ""
}

# Print section
# Usage: print_section <title>
print_section() {
	echo ""
	echo -e "${C_WHITE}$1${C_RESET}"
}

# Print key-value pair
# Usage: print_kv <key> <value>
print_kv() {
	printf "  ${C_GREEN}%-15s${C_RESET} %s\n" "$1:" "$2"
}

# Check if running as root
is_root() {
	[ "$(id -u)" -eq 0 ]
}

# Get CPU info
get_cpu_info() {
	if [ -f /proc/cpuinfo ]; then
		awk -F: '/model name/ {gsub(/^[ \t]+/, "", $2); print $2; exit}' /proc/cpuinfo || \
		awk -F: '/Hardware|Processor|vendor_id/ {gsub(/^[ \t]+/, "", $2); print $2; exit}' /proc/cpuinfo || \
		echo "unknown"
	else
		echo "unknown"
	fi
}

# Get CPU count
get_cpu_count() {
	if [ -f /proc/cpuinfo ]; then
		grep -c "^processor" /proc/cpuinfo 2>/dev/null || echo "1"
	else
		echo "1"
	fi
}

# Get memory info (returns total and free in human readable format)
get_memory_total() {
	if [ -f /proc/meminfo ]; then
		awk '/MemTotal:/ {printf "%.1f MiB", $2/1024}' /proc/meminfo
	else
		echo "unknown"
	fi
}

get_memory_free() {
	if [ -f /proc/meminfo ]; then
		awk '/MemAvailable:/ {printf "%.1f MiB", $2/1024} /^MemFree:/ && !found {printf "%.1f MiB", $2/1024; found=1}' /proc/meminfo | head -1
	else
		echo "unknown"
	fi
}

# Get system uptime
get_uptime() {
	uptime 2>/dev/null | sed 's/.*up //;s/,.*//' || echo "unknown"
}

# Get kernel version
get_kernel_version() {
	uname -r 2>/dev/null || echo "unknown"
}

# Get architecture
get_architecture() {
	uname -m 2>/dev/null || echo "unknown"
}

# Get hostname
get_hostname() {
	hostname 2>/dev/null || echo "hut-os"
}

# Get load average
get_load_average() {
	awk '{print $1", "$2", "$3}' /proc/loadavg 2>/dev/null || echo "n/a"
}

# Check if file/directory exists and is accessible
check_exists() {
	local path="$1"
	[ -e "$path" ]
}

# Format nanoseconds to human readable
format_ns() {
	local ns="$1"
	if [ -z "$ns" ] || [ "$ns" = "0" ]; then
		echo "0 ns"
	elif [ "$ns" -lt 1000 ]; then
		echo "${ns} ns"
	elif [ "$ns" -lt 1000000 ]; then
		echo "$((ns / 1000)) μs"
	elif [ "$ns" -lt 1000000000 ]; then
		echo "$((ns / 1000000)) ms"
	else
		echo "$((ns / 1000000000)) s"
	fi
}

# Print separator
print_separator() {
	echo -e "${C_CYAN}────────────────────────────────────────────────────────────${C_RESET}"
}

# Print double separator
print_double_separator() {
	echo -e "${C_CYAN}════════════════════════════════════════════════════════════${C_RESET}"
}

# Show error and exit
die() {
	echo -e "${C_RED}Error:${C_RESET} $*" >&2
	exit 1
}
