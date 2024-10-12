#!/bin/sh

KERNEL_LOCATION=$1
KERNEL_MODULES=$2
START="$(pwd)"

cd $KERNEL_MODULES/lib/modules
KERNEL_VERSION="$(find * -maxdepth 0 ! -path . -type d)"

cd $START

SLKCFLAGS="-O2 -fPIC"
ARCH="x86_64"

#make r8152

PKG_r8152=$PWD/r8152_pkg

rm -rf $PKG_r8152
rm -rf realtek-r8152-linux

#pkgver=v2.13.0

git clone https://github.com/wget/realtek-r8152-linux.git --depth 1
cd realtek-r8152-linux

#CFLAGS="$SLKCFLAGS" make -C $KERNEL_LOCATION M=$(pwd) EXTRA_CFLAGS='-DCONFIG_R8152_NAPI -DCONFIG_R8152_VLAN -DRTL8152_S5_WOL' modules

#install -m 0755 -D r8152.ko $KERNEL_MODULES/lib/modules/$KERNEL_VERSION/extra/r8152.ko

install -D -m644 50-usb-realtek-net.rules $PKG_r8152/lib/udev/rules.d/50-usb-realtek-net.rules

echo -e "\e[95m MAKEPKG r8152"
cd $PKG_r8152
fakeroot $START/../makepkg -l n -c y $START/r8152-v2.13.0-x86_64-thor.tgz

cd $START
