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

rm -rf tbsecp3-driver

git clone https://github.com/AlexanderS/tbsecp3-driver.git --depth 1
cd tbsecp3-driver

#CFLAGS="$SLKCFLAGS" KCFLAGS=-DCONFIG_DVB_MB86A16 make -C $KERNEL_LOCATION M=$(pwd) modules
CFLAGS="$SLKCFLAGS" KDIR=$KERNEL_LOCATION make KCFLAGS=-DCONFIG_DVB_MB86A16 -j$(nproc)

#install -m 0755 -D r8125.ko $KERNEL_MODULES/lib/modules/$KERNEL_VERSION/extra/r8125.ko

find . -name '*.ko' -exec install -m 0755 -D {} $KERNEL_MODULES/lib/modules/$KERNEL_VERSION/extra/tbsecp3/{} \;

cd $START
