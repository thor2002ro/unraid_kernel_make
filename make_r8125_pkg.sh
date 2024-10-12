#!/bin/sh

KERNEL_LOCATION=$1
KERNEL_MODULES=$2
START="$(pwd)"

cd $KERNEL_MODULES/lib/modules
KERNEL_VERSION="$(find * -maxdepth 0 ! -path . -type d)"

cd $START

SLKCFLAGS="-O2 -fPIC"
ARCH="x86_64"

#make r8125

rm -rf r8125

#pkgver=9.003.05

git clone https://github.com/ibmibmibm/r8125.git --depth 1
cd r8125

cd src

CFLAGS="$SLKCFLAGS" make -C $KERNEL_LOCATION M=$(pwd) modules

install -m 0755 -D r8125.ko $KERNEL_MODULES/lib/modules/$KERNEL_VERSION/extra/r8125.ko

cd $START
