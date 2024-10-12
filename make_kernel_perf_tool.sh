#!/bin/sh

KERNEL_LOCATION=$1
KERNEL_MODULES=$2
START="$(pwd)"

cd $KERNEL_MODULES/lib/modules
KERNEL_VERSION="$(find * -maxdepth 0 ! -path . -type d)"

cd $START

SLKCFLAGS="-O2 -fPIC"
ARCH="x86_64"

cd $KERNEL_LOCATION

#LDFLAGS=-static
CFLAGS="$SLKCFLAGS" make -j$(nproc) -C tools/ install DESTDIR=$START/kernel-tools prefix=/usr/

echo -e "\e[95m MAKEPKG perf"
cd $START/kernel-tools
#echo $START/kernel-tools
fakeroot $START/../makepkg -l n -c y $START/kernel-tools-$KERNEL_VERSION-x86_64-thor.tgz

cd $START
