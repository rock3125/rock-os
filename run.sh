#!/bin/bash

# install qemu full
# sudo pacman -S qemu

make

qemu-system-i386 -fda build/main_floppy.img

