#!/bin/busybox sh
# HUT OS installer — UI helpers

. "$HUTOS_INSTALL_LIB/common.sh"

ui_header() {
	clear 2>/dev/null || true
	echo ""
	echo -e "${C_CYAN}========================================${C_RESET}"
	echo -e "${C_WHITE}        HUT OS INSTALLER${C_RESET}"
	echo -e "${C_DIM} Hamedan University of Technology${C_RESET}"
	echo -e "${C_CYAN}========================================${C_RESET}"
	echo -e "${C_DIM} version $HUTOS_INSTALL_VERSION${C_RESET}"
	echo ""
}

ui_menu() {
	echo "1. Install HUT OS"
	echo "2. Disk information"
	echo "3. System information"
	echo "4. Exit"
	echo ""
	printf "Select [1-4]: "
}

ui_sysinfo() {
	echo -e "${C_WHITE}System information${C_RESET}"
	echo "--------------------"
	uname -a 2>/dev/null || true
	echo ""
	[ -f /etc/os-release ] && cat /etc/os-release
	echo ""
	free 2>/dev/null || true
	echo ""
	cat /proc/cmdline 2>/dev/null || true
}
