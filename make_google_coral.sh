#!/bin/sh

KERNEL_LOCATION="$1"
KERNEL_MODULES="$2"
FLAGS="$3"
START="$(pwd)"

cd $KERNEL_MODULES/lib/modules
KERNEL_VERSION="$(find * -maxdepth 0 ! -path . -type d)"

cd $START

SLKCFLAGS="-O2 -fPIC"
ARCH="x86_64"

rm -rf gasket-driver

git clone https://github.com/google/gasket-driver.git
cd gasket-driver/src

sed -i '/\.llseek = no_llseek,/d' gasket_core.c

#CC=clang LLVM=1 LLVM_IAS=1
CFLAGS="$SLKCFLAGS" make $FLAGS -C $KERNEL_LOCATION M=$(pwd) modules
#CC=clang LLVM=1 LLVM_IAS=1 

install -m 0755 -D apex.ko $KERNEL_MODULES/lib/modules/$KERNEL_VERSION/extra/coral/apex.ko
install -m 0755 -D gasket.ko $KERNEL_MODULES/lib/modules/$KERNEL_VERSION/extra/coral/gasket.ko


cd $START
