#!/bin/bash
# Automated HUTOS scheduler latency monitor smoke test
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
KERNEL="$ROOT/kernel/arch/x86/boot/bzImage"
INITRD="$ROOT/build/initramfs.cpio.gz"
OUT=/tmp/hutos-sched-test.log

# Commands fed after boot (Zsh will eat some timing; send with delays via expect-like printf)
# Use a here-doc piped after sleep by using qemu with a script that waits

SCRIPT=/tmp/hutos-sched-guest.sh
cat > "$SCRIPT" << 'EOF'
#!/bin/busybox sh
# This runs poorly as stdin; instead we check dmesg line in host log
EOF

echo "Booting HUT OS for scheduler test..."
# Feed commands: wait for prompt is hard; send after boot with newline spam then commands
{
  sleep 4
  printf '\n\n'
  sleep 1
  printf 'dmesg | grep HUTOS-SCHED\n'
  sleep 1
  printf 'cat /proc/hutos_sched\n'
  sleep 1
  printf 'echo 1 > /proc/sys/kernel/hutos_sched_lat\n'
  sleep 1
  printf 'echo reset > /proc/hutos_sched\n'
  sleep 1
  # Generate scheduling activity
  printf 'i=0; while [ $i -lt 200 ]; do /bin/busybox true; i=$((i+1)); done\n'
  sleep 2
  printf 'cat /proc/hutos_sched\n'
  sleep 1
  printf 'echo 0 > /proc/sys/kernel/hutos_sched_lat\n'
  sleep 1
  printf 'hutsched show\n'
  sleep 1
  printf 'poweroff -f\n'
  sleep 2
} | timeout 35 qemu-system-x86_64 \
  -m 256 \
  -kernel "$KERNEL" \
  -initrd "$INITRD" \
  -append "console=ttyS0 hutos_sched_lat=0" \
  -nic user,model=e1000 \
  -nographic \
  > "$OUT" 2>&1 || true

echo "==== Results (filtered) ===="
sed 's/\x1b\[[0-9;]*[a-zA-Z]//g' "$OUT" | grep -E 'HUTOS-SCHED|hutos_sched|enabled:|samples|avg_ns|cpu |total|run-queue' | head -60

echo ""
echo "Full log: $OUT"
