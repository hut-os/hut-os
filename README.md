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
   banner · Zsh + Oh My Zsh
        ↓
   about · hutinfo · BusyBox utilities
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
| Package manager | Deferred — see [`docs/PACKAGE_MANAGER.md`](docs/PACKAGE_MANAGER.md) |

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

## Inside HUT OS

```text
hut@hut-os:~# about      # project story
hut@hut-os:~# hutinfo    # version, kernel, memory, uptime
hut@hut-os:~# ifconfig
hut@hut-os:~# ps
```

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
