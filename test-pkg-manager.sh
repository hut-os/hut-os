#!/bin/bash
# Host-side tests for the HUT OS package manager (no QEMU required).
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
ROOTFS="$PROJECT_ROOT/rootfs"
export HUTOS_SYSROOT="$ROOTFS"

PASS=0
FAIL=0

check() {
  name="$1"
  shift
  if "$@"; then
    echo "  OK   $name"
    PASS=$((PASS + 1))
  else
    echo "  FAIL $name"
    FAIL=$((FAIL + 1))
  fi
}

echo "HUT OS package manager tests"
echo ""

chmod +x "$ROOTFS/bin/apt" "$ROOTFS/bin/sudo" \
         "$PROJECT_ROOT/scripts/bundle-userland-tools.sh"
"$PROJECT_ROOT/scripts/bundle-userland-tools.sh" >/dev/null

check "apt help" grep -q "package manager" < <("$ROOTFS/bin/apt" --help)
check "apt version" grep -q "HUT OS" < <("$ROOTFS/bin/apt" --version)
check "apt-get symlink" test -L "$ROOTFS/bin/apt-get"
check "hpkg symlink" test -L "$ROOTFS/bin/hpkg"
check "upstream sudo ELF" grep -q "ELF 64-bit" < <(file "$ROOTFS/bin/sudo")
check "sudoers policy plugin" test -f "$ROOTFS/usr/libexec/sudo/sudoers.so"
check "PAM shadow helper" test -x "$ROOTFS/sbin/unix_chkpwd"
check "sources.list exists" test -f "$ROOTFS/etc/apt/sources.list"
check "sources.list has debian" grep -q "deb.debian.org" "$ROOTFS/etc/apt/sources.list"
check "dpkg status exists" test -f "$ROOTFS/var/lib/dpkg/status"
check "busybox registered" grep -q "^Package: busybox$" "$ROOTFS/var/lib/dpkg/status"
check "wget applet" test -e "$ROOTFS/bin/wget"
check "dpkg applet" test -e "$ROOTFS/bin/dpkg"
check "ssl_client applet" test -e "$ROOTFS/bin/ssl_client"
check "nano binary" test -x "$ROOTFS/usr/bin/nano"
check "sudoers" test -f "$ROOTFS/etc/sudoers"
check "hut in sudo group" grep -q "^sudo:.*hut" "$ROOTFS/etc/group"
check "list installed" grep -q "busybox" < <("$ROOTFS/bin/apt" list --installed)
check "install without index fails clearly" \
  grep -q "apt update" < <("$ROOTFS/bin/apt" install --yes does-not-exist 2>&1 || true)

echo ""
echo "Passed: $PASS   Failed: $FAIL"
[ "$FAIL" -eq 0 ]
