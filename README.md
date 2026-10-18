# HUT OS

**Hamedan University of Technology Operating System**

A minimal, educational Linux-based operating system: custom kernel config, BusyBox userspace, Zsh + Oh My Zsh, GRUB, and ext4 — built to be understandable and hackable.

[![CI](https://github.com/hut-os/hut-os/actions/workflows/ci.yml/badge.svg)](https://github.com/hut-os/hut-os/actions/workflows/ci.yml)
[![License: GPL-2.0](https://img.shields.io/badge/License-GPL%202.0-blue.svg)](LICENSE)

---

## Quick start

```bash
git clone https://github.com/hut-os/hut-os.git
cd hut-os

# Provide a kernel image (see docs/KERNEL.md)
# mkdir -p kernel/arch/x86/boot && cp /path/to/bzImage kernel/arch/x86/boot/

./build.sh          # initramfs + ext4 disk + GRUB ISO
./run.sh            # boot in QEMU (initramfs)
```

Other boot modes:

```bash
./scripts/run-disk.sh         # persistent ext4 root
./scripts/run-iso.sh          # GRUB ISO (live)
./scripts/run-install-iso.sh  # live ISO + blank disk for hut-install
./scripts/test-install-qemu.sh # end-to-end install → disk boot test
```

Installer documentation: [`docs/INSTALL.md`](docs/INSTALL.md). Artifact: `dist/hutos-x86_64.iso`.

Exit QEMU: **Ctrl+A** then **X**.

---

## Architecture

```
GRUB / QEMU -kernel
        ↓
   Linux Kernel (upstream + HUT OS config)
        ↓
   /init  →  mounts · mdev · hostname · networking
        ↓
   BusyBox init · authenticated serial/TTY login
        ↓
   Zsh · sudo/PAM · BusyBox utilities · hutos engineering CLI
```

| Component | Implementation |
|-----------|----------------|
| Kernel | Upstream Linux + [`configs/hutos_defconfig`](configs/hutos_defconfig) |
| Bootloader | GRUB2 (ISO + installed disk MBR) |
| Persistent FS | ext4 (disk image / installer target) |
| Installer | `hut-install` CLI — see [`docs/INSTALL.md`](docs/INSTALL.md) |
| Init | Custom BusyBox ash `/init` |
| Devices | BusyBox mdev + `devtmpfs` |
| Networking | loopback + eth0 DHCP |
| Shell | Zsh + Oh My Zsh |
| Package manager | `apt` / `apt-get` / `hpkg` — official Debian `.deb` feeds — see [`docs/PACKAGE_MANAGER.md`](docs/PACKAGE_MANAGER.md) |
| Privilege escalation | Upstream sudo + PAM, sudo group; setuid/root ownership preserved by image builders |
| Engineering tools | Native `hutos` CLI — see [`docs/ENGINEERING_TOOLS.md`](docs/ENGINEERING_TOOLS.md) |

## Verification status

The serial-console QEMU check verifies first-boot password setup, `hut` login,
and rejection of passwordless sudo. It currently exposes a remaining PAM
integration failure: sudo rejects the same password accepted by console
login, so authenticated escalation is **not yet verified and must not be
treated as working**. Run the check with:

```sh
python3 scripts/test-console-qemu.py
```

Package repository signatures are also not yet
verified, and the engineering toolkit is intentionally limited to the commands
listed in its documentation.

Related repositories:

- [hut-os/linux-config](https://github.com/hut-os/linux-config) — kernel configuration
- [hut-os](https://github.com/hut-os) — organization

---

## Repository layout

```
hut-os/
├── rootfs/           # Userspace root filesystem (+ hut-install)
├── installer/        # Installer overview / wrapper
├── scripts/          # Build, run, and QEMU install tests
├── configs/          # Kernel defconfig
├── docs/             # Design and install documentation
├── dist/             # ISO artifacts (gitignored)
├── build.sh          # Unified build entry point
└── run.sh            # QEMU initramfs boot
```

---

## First boot and commands

The first boot asks the owner to set passwords for the locked `root` and `hut`
accounts. HUTOS ships no default password. The installed ext4 root preserves
accounts, package state, `/etc`, `/home`, and `/var` across boots; the live
initramfs is temporary.

```text
hut@hut-os:~$ hutos about        # live system dashboard
hut@hut-os:~$ hutos tools        # interactive engineering toolkit
hut@hut-os:~$ hutos mech beam 2 1000 2e11 8e-6 center
hut@hut-os:~$ hutos chem molar-mass 'Al2(SO4)3'
hut@hut-os:~$ hutos doctor       # system health checks
hut@hut-os:~$ sudo apt update    # refresh package index over HTTPS
hut@hut-os:~$ nano notes.txt
```

Scientific command scope and formula assumptions are documented in
[`docs/ENGINEERING_TOOLS.md`](docs/ENGINEERING_TOOLS.md). Package transport is
HTTPS with SHA256 checks, but repository `InRelease` signatures are not yet
verified; see [`docs/PACKAGE_MANAGER.md`](docs/PACKAGE_MANAGER.md).

---

## Developer

**Arshia Mohammadei** · Mechanical Engineering · Hamedan University of Technology  
GitHub: [@itashia](https://github.com/itashia)

> Built from a dormitory study hall — what better name than our university?

## License

GPL-2.0 — see [LICENSE](LICENSE). Third-party components keep their upstream licenses.

## HUTOS Scheduler

Optional run-queue wait latency monitor (`CONFIG_HUTOS_SCHED_LAT`).

See [docs/SCHED.md](docs/SCHED.md). Inside HUT OS: `hutsched on` then `hutsched show`.
