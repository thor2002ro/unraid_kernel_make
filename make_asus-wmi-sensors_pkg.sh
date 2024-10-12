#!/bin/sh

KERNEL_LOCATION=$1
KERNEL_MODULES=$2
START="$(pwd)"

cd $KERNEL_MODULES/lib/modules
KERNEL_VERSION="$(find * -maxdepth 0 ! -path . -type d)"

cd $START

SLKCFLAGS="-O2 -fPIC"
ARCH="x86_64"

#make asus-wmi-sensors

rm -rf asus-wmi-sensors

#pkgver=9.003.05

git clone https://github.com/electrified/asus-wmi-sensors.git --depth 1
cd asus-wmi-sensors

CFLAGS="$SLKCFLAGS" make CC=clang LLVM=1 LLVM_IAS=1 -C $KERNEL_LOCATION M=$(pwd) modules
#CC=clang LLVM=1 LLVM_IAS=1 

install -m 0755 -D asus-wmi-sensors.ko $KERNEL_MODULES/lib/modules/$KERNEL_VERSION/extra/asus-wmi-sensors.ko

cd $START
