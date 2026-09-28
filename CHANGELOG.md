# Changelog

## 3.0.0 — Infrastructure base (2026-09-28)

### Added
- **GRUB2** bootable ISO (`build/hutos.iso`)
- **ext4** persistent disk image (`build/hutos.img`)
- Unified **`./build.sh`** (initramfs | disk | iso | all)
- BusyBox **mdev** device management
- Hostname, `/etc/hosts`, `/etc/resolv.conf`, `/etc/os-release`
- Users: `root`, `hut`, `nobody` + `/etc/shadow` + groups
- Networking: loopback + eth0 DHCP (QEMU user net)
- Essential BusyBox applet symlinks (`ps`, `kill`, `dmesg`, `ifconfig`, …)
- **`hutinfo`** system information command
- Shell restart loop (exit no longer kills PID 1)
- `docs/PACKAGE_MANAGER.md` — package manager deferred by design
- `MIGRATION_PLAN.md` — architecture decisions

### Preserved
- Kernel unchanged
- Zsh + Oh My Zsh
- ASCII banner, `about`, developer identity

### Boot paths verified
1. `./run.sh` — initramfs
2. `./scripts/run-disk.sh` — ext4 on virtio
3. `./scripts/run-iso.sh` — GRUB → kernel → initramfs

---

## 2.1.0 — Zsh + Oh My Zsh

Zsh as default interactive shell with Oh My Zsh configuration.

## 2.0.0 — Polished boot experience

Custom `/init` banner, `about`, HUT identity.
