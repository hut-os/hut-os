#!/bin/bash
# Bundle everyday CLI tools (nano, certs, BusyBox applets) into the HUT OS rootfs.
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ROOTFS="$PROJECT_ROOT/rootfs"
BIN="$ROOTFS/bin"
USRBIN="$ROOTFS/usr/bin"

CYAN='\033[1;36m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RESET='\033[0m'

echo -e "${CYAN}[bundle] Userland tools → $ROOTFS${RESET}"

mkdir -p "$BIN" "$USRBIN" "$ROOTFS/etc/ssl/certs" \
         "$ROOTFS/usr/share/nano" "$ROOTFS/var/lib/dpkg/info" \
         "$ROOTFS/var/lib/apt/lists" "$ROOTFS/var/cache/apt/archives"

# Bundle upstream sudo and the PAM files it needs. The old rootfs/bin/sudo
# shell script was not sudo: it skipped authentication and ignored policy.
bundle_sudo() {
  local sudo_src plugin_dir lib_src rel dest
  sudo_src="$(readlink -f /usr/bin/sudo.ws 2>/dev/null || true)"
  plugin_dir="/usr/libexec/sudo"
  if [ ! -x "$sudo_src" ] || [ ! -f "$plugin_dir/sudoers.so" ]; then
    echo "Error: upstream sudo with its sudoers plugin is required on the build host" >&2
    exit 1
  fi

  mkdir -p "$ROOTFS/usr/libexec/sudo" "$ROOTFS/usr/lib/x86_64-linux-gnu/security" \
           "$ROOTFS/etc/pam.d" "$ROOTFS/etc/security" "$ROOTFS/var/lib/sudo/lectured" \
           "$ROOTFS/sbin"
  install -m 0755 "$sudo_src" "$BIN/sudo"
  cp -a "$plugin_dir"/. "$ROOTFS/usr/libexec/sudo/"

  # pam_unix delegates shadow checks from an unprivileged real UID to this
  # setuid helper. Without it console login may work while sudo auth fails.
  local unix_chkpwd
  unix_chkpwd="$(command -v unix_chkpwd || true)"
  if [ -z "$unix_chkpwd" ] || [ ! -x "$unix_chkpwd" ]; then
    echo "Error: unix_chkpwd from the host PAM package is required" >&2
    exit 1
  fi
  install -m 4755 "$unix_chkpwd" "$ROOTFS/sbin/unix_chkpwd"

  # Copy the complete shared-library closure for sudo, its policy plugin and
  # the Unix PAM modules. This is host-toolchain specific, so fail on missing
  # dependencies rather than emit a broken image.
  copy_library() {
    local binary path
    binary="$1"
    while IFS= read -r path; do
      [ -f "$path" ] || continue
      case "$path" in
        */ld-linux-*.so*) dest="$ROOTFS/lib64/$(basename "$path")" ;;
        *) dest="$ROOTFS/usr/lib/x86_64-linux-gnu/$(basename "$path")" ;;
      esac
      mkdir -p "$(dirname "$dest")"
      cp -L "$path" "$dest"
    done < <(ldd "$binary" 2>/dev/null | awk '{ for (i=1; i<=NF; i++) if ($i ~ /^\//) print $i }' | sort -u)
  }

  copy_library "$BIN/sudo"
  copy_library "$ROOTFS/sbin/unix_chkpwd"
  for binary in "$ROOTFS/usr/libexec/sudo/sudoers.so" \
                "$ROOTFS/usr/libexec/sudo/sesh"; do
    [ -f "$binary" ] && copy_library "$binary"
  done

  # glibc loads these NSS backends at runtime rather than listing them in ldd.
  # PAM needs files for passwd/shadow/group; curl needs DNS name resolution.
  for module in libnss_files.so.2 libnss_dns.so.2 libnss_compat.so.2; do
    lib_src=$(ldconfig -p 2>/dev/null | awk -v n="$module" '$1==n {print $NF; exit}')
    if [ -n "$lib_src" ] && [ -f "$lib_src" ]; then
      mkdir -p "$ROOTFS/lib/x86_64-linux-gnu"
      cp -L "$lib_src" "$ROOTFS/lib/x86_64-linux-gnu/$module"
    fi
  done

  for module in pam_unix.so pam_permit.so pam_deny.so pam_env.so; do
    lib_src="/usr/lib/x86_64-linux-gnu/security/$module"
    if [ -f "$lib_src" ]; then
      cp -L "$lib_src" "$ROOTFS/usr/lib/x86_64-linux-gnu/security/$module"
      copy_library "$lib_src"
    fi
  done
  if [ ! -f "$ROOTFS/usr/lib/x86_64-linux-gnu/security/pam_unix.so" ]; then
    echo "Error: PAM's pam_unix module is required for password authentication" >&2
    exit 1
  fi

  cat > "$ROOTFS/etc/pam.d/sudo" <<'EOF'
# Minimal PAM stack: verify the invoking user's shadow password.
auth    required pam_unix.so
account required pam_unix.so
session required pam_permit.so
EOF
  cat > "$ROOTFS/etc/pam.d/other" <<'EOF'
# Deny PAM services that do not have an explicit policy.
auth    required pam_deny.so
account required pam_deny.so
password required pam_deny.so
session required pam_deny.so
EOF

  cat > "$ROOTFS/etc/sudo.conf" <<'EOF'
# sudoers policy plugin
Plugin sudoers_policy /usr/libexec/sudo/sudoers.so
EOF
  chmod 0700 "$ROOTFS/var/lib/sudo" "$ROOTFS/var/lib/sudo/lectured"
  chown -h 0:0 "$BIN/sudo" "$ROOTFS/etc/sudo.conf" "$ROOTFS/etc/pam.d/sudo" 2>/dev/null || true
  echo "  bin: upstream sudo + sudoers policy + PAM authentication"
}

# --- BusyBox applets needed by apt / editors / networking ---
APPLETS="
wget dpkg dpkg-deb ar ssl_client xz xzcat unzip
strings hexdump diff nslookup sha256sum
"

if [ ! -x "$BIN/busybox" ]; then
  echo "Error: $BIN/busybox is missing" >&2
  exit 1
fi

for applet in $APPLETS; do
  if [ ! -e "$BIN/$applet" ]; then
    ln -sfn busybox "$BIN/$applet"
    echo "  applet: $applet"
  fi
done

# --- nano (real GNU nano from the host, or a Debian .deb) ---
copy_nano_from_host() {
  src="$1"
  cp -L "$src" "$USRBIN/nano"
  chmod 0755 "$USRBIN/nano"
  ln -sfn /usr/bin/nano "$BIN/nano"
  echo "  bin: nano ($(du -h "$USRBIN/nano" | cut -f1))"
}

if [ -x /usr/bin/nano ]; then
  copy_nano_from_host /usr/bin/nano
elif [ -x /bin/nano ]; then
  copy_nano_from_host /bin/nano
else
  echo -e "${YELLOW}  nano not on host — skipping binary copy (install later with apt)${RESET}"
fi

if [ -f /etc/nanorc ]; then
  cp -L /etc/nanorc "$ROOTFS/etc/nanorc"
  echo "  conf: /etc/nanorc"
fi

# A few syntax files keep the image small but useful
if [ -d /usr/share/nano ]; then
  copied=0
  for syn in sh.nanorc python.nanorc c.nanorc makefile.nanorc \
             json.nanorc xml.nanorc markdown.nanorc git.nanorc; do
    if [ -f "/usr/share/nano/$syn" ]; then
      cp -L "/usr/share/nano/$syn" "$ROOTFS/usr/share/nano/"
      copied=$((copied + 1))
    fi
  done
  [ "$copied" -gt 0 ] && echo "  nano syntax: $copied files"
fi

# nano only needs libncursesw + libtinfo — already in the rootfs for zsh.
# Copy them again if a rebuild wiped usr/lib.
for need in libncursesw.so.6 libtinfo.so.6 libc.so.6; do
  if [ ! -e "$ROOTFS/usr/lib/x86_64-linux-gnu/$need" ] && [ ! -e "$ROOTFS/lib/$need" ]; then
    src=$(ldconfig -p 2>/dev/null | awk -v n="$need" '$1==n {print $NF; exit}')
    if [ -n "${src:-}" ] && [ -f "$src" ]; then
      mkdir -p "$ROOTFS/usr/lib/x86_64-linux-gnu"
      cp -L "$src" "$ROOTFS/usr/lib/x86_64-linux-gnu/"
      echo "  lib: $need"
    fi
  fi
done

# --- CA certificates for HTTPS networking ---
if [ -f /etc/ssl/certs/ca-certificates.crt ]; then
  cp -L /etc/ssl/certs/ca-certificates.crt "$ROOTFS/etc/ssl/certs/ca-certificates.crt"
  echo "  certs: ca-certificates.crt ($(du -h "$ROOTFS/etc/ssl/certs/ca-certificates.crt" | cut -f1))"
fi

bundle_sudo

# curl validates HTTPS server certificates using the bundled CA store. BusyBox
# wget's TLS applet does not provide the certificate verification guarantees
# required for package downloads, so package operations require this binary.
curl_src=$(readlink -f "$(command -v curl 2>/dev/null || true)" 2>/dev/null || true)
if [ -z "$curl_src" ] || [ ! -x "$curl_src" ]; then
  echo "Error: curl is required to build verified HTTPS package downloads" >&2
  exit 1
fi
install -m 0755 "$curl_src" "$USRBIN/curl"
copy_library "$curl_src"
echo "  bin: curl (verified HTTPS client)"

# --- Register bundled nano in the dpkg status database ---
STATUS="$ROOTFS/var/lib/dpkg/status"
if [ -x "$USRBIN/nano" ] && [ -f "$STATUS" ]; then
  if ! grep -q '^Package: nano$' "$STATUS"; then
    ver=$(nano --version 2>/dev/null | awk 'NR==1 {print $NF; exit}' || echo "8.0")
    cat >> "$STATUS" <<EOF

Package: nano
Status: install ok installed
Priority: optional
Section: editors
Architecture: amd64
Version: ${ver}-hutos
Description: GNU nano text editor (bundled)
 Small, friendly editor shipped with HUT OS. Reinstall with
 \`sudo apt install nano\` to get the latest Debian package.
EOF
    echo "  dpkg: registered nano ${ver}"
  fi
fi

chmod 0755 "$ROOTFS/bin/apt" 2>/dev/null || true
ln -sfn apt "$BIN/apt-get"
ln -sfn apt "$BIN/hpkg"
# Also expose under /usr/bin (Debian layout)
ln -sfn /bin/apt "$USRBIN/apt"
ln -sfn /bin/apt-get "$USRBIN/apt-get"
ln -sfn /bin/sudo "$USRBIN/sudo"
[ -e "$USRBIN/nano" ] && ln -sfn /usr/bin/nano "$BIN/nano" || true

echo -e "${GREEN}[bundle] Userland tools ready${RESET}"
