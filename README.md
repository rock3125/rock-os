

## https://github.com/nanobyte-dev/nanobyte_os

## arch install
```
sudo pacman -S dosfstools mtools nasm qemu-system-x86
```

## make disk image
```
make
```

## view contents of disk image
```
mdir -i build/main_floppy.img
```

## boot disk image in qemu for testing
```
./run.sh
```

or alternatively

```
qemu-system-i386 -fda build/main_floppy.img
```
