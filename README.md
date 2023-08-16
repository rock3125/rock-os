

## https://github.com/nanobyte-dev/nanobyte_os

## arch install
```
sudo pacman -S qemu dosfstools qemu mtools
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
