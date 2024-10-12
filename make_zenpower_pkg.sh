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

#make r8125

rm -rf zenpower3

#pkgver=9.003.05

#git clone https://github.com/ocerman/zenpower.git
#git clone https://github.com/thor2002ro/zenpower.git
git clone https://github.com/Ta180m/zenpower3.git
cd zenpower3

#git revert 184c4c7797a8e1f63f6649645dd31d975e9c4d3f -n

#CC=clang LLVM=1 LLVM_IAS=1 
CFLAGS="$SLKCFLAGS" make $FLAGS -C $KERNEL_LOCATION M=$(pwd) modules
#CC=clang LLVM=1 LLVM_IAS=1 

install -m 0755 -D zenpower.ko $KERNEL_MODULES/lib/modules/$KERNEL_VERSION/extra/zenpower.ko

cd $START
