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

rm -rf vendor-reset

git clone https://github.com/gnif/vendor-reset.git
cd vendor-reset
#git am ../../vendor-reset-update-5.16.patch

#git merge origin/feature/polaris_baco
#git merge origin/feature/navi10_baco
#git merge origin/feature/audio_reset
#git commit -a

sed -i 's/strlcpy/strscpy/g' src/amd/amdgpu/atom.c

#fix kernel 6.12
sed -i 's|#include <asm/unaligned.h>|#include <linux/unaligned.h>|' src/amd/amdgpu/atom.c


#CC=clang LLVM=1 LLVM_IAS=1
CFLAGS="$SLKCFLAGS" make $FLAGS -C $KERNEL_LOCATION M=$(pwd) modules
#CC=clang LLVM=1 LLVM_IAS=1 

install -m 0755 -D vendor-reset.ko $KERNEL_MODULES/lib/modules/$KERNEL_VERSION/extra/vendor-reset.ko

cd $START
