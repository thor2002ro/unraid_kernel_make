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

rm -rf ugreen_dx4600_leds_controller

git clone https://github.com/miskcoo/ugreen_dx4600_leds_controller.git
cd ugreen_dx4600_leds_controller/kmod


#CC=clang LLVM=1 LLVM_IAS=1
CFLAGS="$SLKCFLAGS" make $FLAGS -C $KERNEL_LOCATION M=$(pwd) modules
#CC=clang LLVM=1 LLVM_IAS=1 

install -m 0755 -D led-ugreen.ko $KERNEL_MODULES/lib/modules/$KERNEL_VERSION/extra/led-ugreen.ko


cd $START
