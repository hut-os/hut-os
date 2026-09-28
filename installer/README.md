# HUT OS Installer

Real CLI installer for BIOS/legacy x86_64 (QEMU).

See [../docs/INSTALL.md](../docs/INSTALL.md) for the full guide.

Quick start:

```bash
./build.sh iso
./scripts/run-install-iso.sh
# inside guest:
hut-install
```

Automated test:

```bash
./scripts/test-install-qemu.sh
```
