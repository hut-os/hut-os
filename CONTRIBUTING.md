# Contributing to HUT OS

Thank you for helping improve HUT OS.

## Workflow

1. Fork [hut-os/hut-os](https://github.com/hut-os/hut-os) (or use a branch with write access).
2. Create a feature branch from `main`.
3. Make focused commits using [Conventional Commits](https://www.conventionalcommits.org/).
4. Open a Pull Request against `main`.
5. Keep PRs reviewable — prefer small, clear changes.

## Commit style

```
feat: add hutinfo memory summary
fix: prevent mdev hang on CD-ROM coldplug
docs: explain kernel build from upstream
```

## What belongs where

| Change | Repository |
|--------|------------|
| Rootfs, init, build scripts, docs | [hut-os/hut-os](https://github.com/hut-os/hut-os) |
| Kernel `.config` / build notes | [hut-os/linux-config](https://github.com/hut-os/linux-config) |

Do **not** vendor the full Linux kernel tree here. Use upstream Linux + `configs/hutos_defconfig`.

## Testing

```bash
./build.sh initramfs
./run.sh
# Inside HUT OS: about, hutinfo, ifconfig, ls
```

## Code of conduct

Be respectful. This is a student-led educational OS project from Hamedan University of Technology.
