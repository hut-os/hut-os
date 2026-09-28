# HUT OS - Quick Start Guide

## 🚀 Boot HUT OS with Zsh Right Now

```bash
cd /home/arshiamohammadei/home/projects/HUTOS
./run.sh
```

That's it! You'll boot into Zsh with Oh My Zsh! 🎉

---

## 📝 Common Tasks

### Rebuild the System
```bash
./build-initramfs.sh
```

### Inspect What's Inside
```bash
./inspect-initramfs.sh
```

### Boot in QEMU Manually
```bash
qemu-system-x86_64 \
    -kernel kernel/arch/x86/boot/bzImage \
    -initrd initramfs.cpio.gz \
    -append "console=ttyS0" \
    -nographic
```

### Exit QEMU
Press: **Ctrl+A** then **X**

---

## 🛠️ Make Changes

### Edit Boot Sequence
```bash
nano rootfs/init
./build-initramfs.sh
./run.sh
```

### Edit About Command
```bash
nano rootfs/bin/about
./build-initramfs.sh
./run.sh
```

### Change ASCII Banner
```bash
nano rootfs/etc/hut-banner.txt
./build-initramfs.sh
./run.sh
```

### Add New Command
```bash
nano rootfs/bin/mycommand
chmod +x rootfs/bin/mycommand
./build-initramfs.sh
./run.sh
```

---

## 💡 Inside HUT OS

Once booted, you'll be in **Zsh with Oh My Zsh**! Try these commands:

```bash
about          # Show system info
ll             # List files (long format)
huname         # Show HUT OS name
help           # BusyBox commands
uname -a       # Kernel version
free           # Memory usage
cat /etc/hut-banner.txt    # View banner
```

**Zsh Features:**
- Tab completion (press Tab)
- Command history (Up/Down arrows)
- Colored prompt: `hut@hut-os:~#`

---

## 📁 Project Structure

```
HUTOS/
├── run.sh                  ← Boot HUT OS
├── build-initramfs.sh      ← Rebuild system
├── inspect-initramfs.sh    ← Inspect contents
├── rootfs/                 ← Source files
│   ├── init               ← Boot script
│   ├── bin/about          ← About command
│   └── etc/hut-banner.txt ← ASCII art
├── initramfs.cpio.gz       ← Built system
└── kernel/arch/x86/boot/
    └── bzImage            ← Linux kernel
```

---

## 📚 Documentation

- **README.md** - Complete documentation
- **CHANGELOG.md** - Version history
- **IMPLEMENTATION_SUMMARY.md** - Technical details
- **BOOT_EXPERIENCE.md** - What you'll see
- **QUICK_START.md** - This file

---

## 🎨 What Makes HUT OS Special

✅ Custom boot sequence with colors  
✅ HUT University ASCII art banner  
✅ Personal developer story  
✅ Professional terminal aesthetics  
✅ Custom `about` command  
✅ Geeky but polished experience  

---

## 🎓 About

**HUT OS** - Hamedan University of Technology Operating System

Built by **Arshia Mohammadei** (Mechanical Engineering, 2nd Semester)  
GitHub: [@itashia](https://github.com/itashia)

> "One day I was sitting in the dormitory study hall,  
> had nothing better to do, and started building my own  
> operating system. And what better name could it have  
> than our university? Welcome to HUT OS."

---

## ⚡ One-Line Summary

**HUT OS is a minimal Linux-based OS with a polished terminal boot experience, showcasing university pride and personal achievement.**

---

*Proudly built at Hamedan University of Technology* 🎓
