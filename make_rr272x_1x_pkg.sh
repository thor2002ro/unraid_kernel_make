#!/bin/sh

KERNEL_LOCATION=$1
KERNEL_MODULES=$2
START="$(pwd)"

cd $KERNEL_MODULES/lib/modules
KERNEL_VERSION="$(find * -maxdepth 0 ! -path . -type d)"

cd $START

rm -rf RR272x_1x_Linux_Src_v1.10.7_2020_08_07.tar
rm -rf rr272x_1x

#make RR272x_1x
wget https://highpoint-tech.com/BIOS_Driver/rr272x_1x/Linux/RR272x_1x_Linux_Src_v1.10.7_2020_08_07.tar
tar xf RR272x_1x_Linux_Src_v1.10.7_2020_08_07.tar
./rr272x_1x_linux_src_v1.10.7_2020_08_07.bin --keep --noexec --target rr272x_1x
cd rr272x_1x/product/rr272x/linux/
make KERNELDIR=$KERNEL_LOCATION
mkdir -p $KERNEL_MODULES/lib/modules/$KERNEL_VERSION/extra/rr272x_1x
cp rr272x_1x.ko $KERNEL_MODULES/lib/modules/*/extra/rr272x_1x/

cd $START
