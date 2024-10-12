#!/bin/sh

KERNEL_LOCATION=$1
KERNEL_MODULES=$2
START="$(pwd)"

cd $KERNEL_MODULES/lib/modules
KERNEL_VERSION="$(find * -maxdepth 0 ! -path . -type d)"

cd $START

SLKCFLAGS="-O2 -fPIC"
ARCH="x86_64"

#make tn40xx

rm -rf tn40xx

tnver=0.3.6.17.3

wget http://www.tehutinetworks.net/images/UL240756/tn40xx-$tnver.tgz
tar xvf tn40xx-$tnver.tgz

cd tn40xx-$tnver

CFLAGS="$SLKCFLAGS" make -C $KERNEL_LOCATION M=$(pwd) modules

install -m 0755 -D tn40xx.ko $KERNEL_MODULES/lib/modules/$KERNEL_VERSION/extra/tn40xx.ko

cd $START
