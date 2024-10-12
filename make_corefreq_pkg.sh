#!/bin/sh

KERNEL_LOCATION="$1"
KERNEL_MODULES="$2"
FLAGS="$3"
START="$(pwd)"

cd ${KERNEL_MODULES}/lib/modules
KERNEL_VERSION="$(find * -maxdepth 0 ! -path . -type d)"

cd $START

SLKCFLAGS="-O2 -fPIC"
ARCH="x86_64"

#make CoreFreq

PKG_COREFREQ=$PWD/CoreFreq_pkg

rm -rf $PKG_COREFREQ
rm -rf CoreFreq

mkdir -p $PKG_COREFREQ

#develop or master
git clone https://github.com/cyring/CoreFreq --branch master --depth 1
cd CoreFreq

#CC=clang LLVM=1 LLVM_IAS=1
#patch -p1 -i $START/../0001-corefreq-5.14-update.patch
make $FLAGS DELAY_TSC=1 OPTIM_LVL=2 WARNING="-Wall -Wfatal-errors -static -pthread" KERNELDIR=$KERNEL_LOCATION all
#CC=clang LLVM=1 LLVM_IAS=1 

mkdir -p $PKG_COREFREQ/usr/bin
#mkdir -p $PKG_COREFREQ/etc/rc.d
cd build
install -m 0755 -D corefreq-cli $PKG_COREFREQ/usr/bin/corefreq-cli
install -m 0755 -D corefreqd $PKG_COREFREQ/usr/bin/corefreqd
#install -m 0755 -D $START/rc.corefreq $PKG_COREFREQ/etc/rc.d/rc.corefreq
install -m 0755 -D $START/../corefreq-cli-run $PKG_COREFREQ/usr/bin/corefreq-cli-run

install -m 0755 -D corefreqk.ko ${KERNEL_MODULES}/lib/modules/${KERNEL_VERSION}/extra/corefreqk.ko

#mkdir -p $PKG_COREFREQ/var/lock/CoreFreq

echo -e "\e[95m MAKEPKG CoreFreq"
cd $PKG_COREFREQ
fakeroot $START/../makepkg -l n -c y $START/corefreq-dev-x86_64-thor.tgz

cd $START
