#!/bin/bash

# Test script to verify the about command

echo "about" | timeout 5 qemu-system-x86_64 \
    -kernel kernel/arch/x86/boot/bzImage \
    -initrd initramfs.cpio.gz \
    -append "console=ttyS0" \
    -nographic 2>/dev/null | tail -100
