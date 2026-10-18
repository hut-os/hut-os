#!/usr/bin/env python3
"""Boot a fresh HUTOS disk and verify first-boot password setup, login and sudo."""
import os
import pty
import re
import select
import subprocess
import sys
import termios
import time
import tty
from pathlib import Path

root = Path(__file__).resolve().parent.parent
disk = root / "build/hutos-login-test.img"
log_path = root / "build/test-console-login.log"
password = os.environ.get("HUTOS_TEST_PASSWORD", "Engineering!7391")
timeout = int(os.environ.get("HUTOS_LOGIN_TIMEOUT", "150"))

env = os.environ.copy()
if os.environ.get("HUTOS_SKIP_DISK_BUILD") != "1":
    env["HUTOS_DISK_IMAGE"] = str(disk)
    env["HUTOS_DISK_MB"] = "512"
    subprocess.run([str(root / "scripts/build-disk.sh")], cwd=root, env=env, check=True)

master, slave = pty.openpty()
tty.setraw(slave)
log_path.parent.mkdir(parents=True, exist_ok=True)
cmd = [
    "qemu-system-x86_64", "-m", "512", "-kernel", str(root / "kernel/arch/x86/boot/bzImage"),
    "-drive", f"file={disk},format=raw,if=virtio",
    "-append", "root=/dev/vda rw rootwait console=ttyS0 init=/init",
    "-nic", "user,model=e1000", "-display", "none", "-serial", "stdio", "-no-reboot",
]
proc = subprocess.Popen(cmd, cwd=root, stdin=slave, stdout=slave, stderr=slave, close_fds=True)
os.close(slave)
transcript = bytearray()

def expect(pattern, timeout_seconds=timeout):
    expression = re.compile(pattern.encode(), re.I | re.S)
    start = len(transcript)
    deadline = time.monotonic() + timeout_seconds
    while time.monotonic() < deadline:
        if expression.search(transcript, start):
            return
        if proc.poll() is not None:
            raise RuntimeError(f"QEMU exited ({proc.returncode}) before matching {pattern!r}")
        ready, _, _ = select.select([master], [], [], 0.25)
        if ready:
            try:
                chunk = os.read(master, 65536)
            except OSError:
                chunk = b""
            if chunk:
                transcript.extend(chunk)
                log_path.write_bytes(transcript)
    raise TimeoutError(f"Timed out waiting for {pattern!r}; see {log_path}")

def send(line):
    os.write(master, (line + "\n").encode())

try:
    expect(r"New password:")
    send(password)
    expect(r"Retype.*password:")
    send(password)
    expect(r"New password:")
    send(password)
    expect(r"Retype.*password:")
    send(password)
    expect(r"login:")
    send("hut")
    expect(r"Password:")
    send(password)
    expect(r"HUTOS 3\.1|Engineering Linux")
    send("echo __CONSOLE_READY__")
    expect(r"(?m)^__CONSOLE_READY__\r*$")

    send("sudo -n /bin/sh -c 'echo __PASSWORDLESS_ESCALATION__' 2>/dev/null || echo __AUTH_REQUIRED__")
    expect(r"(?m)^(__AUTH_REQUIRED__|__PASSWORDLESS_ESCALATION__)\r*$")
    if re.search(rb"(?m)^__PASSWORDLESS_ESCALATION__\r*$", transcript):
        raise RuntimeError("sudo allowed a command without authentication")

    send("sudo -k; sudo -l")
    expect(r"password for hut:")
    send(password)
    expect(r"may run the following commands")

    send("sudo -k; sudo -u root id -u")
    expect(r"password for hut:")
    send(password)
    expect(r"(?m)^0\r*$")

    send("sudo -k; sudo -v && echo __SUDO_VALIDATED__")
    expect(r"password for hut:")
    send(password)
    expect(r"(?m)^__SUDO_VALIDATED__\r*$")
    if password.encode() in transcript:
        raise RuntimeError("password was echoed to the console log")
    send("sudo -n /sbin/poweroff")
    proc.wait(timeout=20)
    log_path.write_bytes(transcript)
    print("PASS: first boot password setup, hut login, sudo -n denial, sudo -l, -u, and -v")
    print(f"Log: {log_path}")
except Exception as exc:
    try:
        log_path.write_bytes(transcript)
    except OSError:
        pass
    proc.terminate()
    print(f"FAIL: {exc}\nSee {log_path}", file=sys.stderr)
    sys.exit(1)
finally:
    os.close(master)
