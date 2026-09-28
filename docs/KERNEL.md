# Building the HUT OS kernel

HUT OS uses **upstream Linux** — we do not maintain a full kernel fork.

Current target: **Linux 7.3-rc5** (or newer stable once validated)

## Quick build

```bash
# From a Linux source tree (e.g. https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git)
git checkout v7.3-rc5

# Apply HUT OS configuration
cp /path/to/hut-os/configs/hutos_defconfig .config
# Or: make KCONFIG_CONFIG=/path/to/hut-os/configs/hutos_defconfig olddefconfig

make olddefconfig
make -j"$(nproc)" bzImage

# Output
ls -lh arch/x86/boot/bzImage
```

Point the HUT OS build at your kernel:

```bash
# Default path expected by scripts:
#   kernel/arch/x86/boot/bzImage
#
# Symlink or copy:
mkdir -p kernel/arch/x86/boot
cp /path/to/linux/arch/x86/boot/bzImage kernel/arch/x86/boot/bzImage
```

Kernel configuration for HUT OS is also published as:

https://github.com/hut-os/linux-config

## Notable config

| Option | Purpose |
|--------|---------|
| `CONFIG_LOCALVERSION="-HUTOS-Hamedan-University-of-Technology"` | Kernel branding |
| `CONFIG_EXT4_FS=y` | Persistent root |
| `CONFIG_VIRTIO_BLK=y` / `CONFIG_VIRTIO_NET=y` | QEMU virtio |
| `CONFIG_E1000=y` | QEMU e1000 NIC |
| `CONFIG_DEVTMPFS=y` | Device filesystem |

## License

Linux kernel sources are **GPL-2.0**. The defconfig in this repository is published under the same terms as the Linux kernel configuration files.
