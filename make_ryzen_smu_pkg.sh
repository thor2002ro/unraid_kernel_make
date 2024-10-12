#!/bin/sh

KERNEL_LOCATION=$1
KERNEL_MODULES=$2
FLAGS="$3"
START="$(pwd)"

cd $KERNEL_MODULES/lib/modules
KERNEL_VERSION="$(find * -maxdepth 0 ! -path . -type d)"

cd $START

ARCH="x86_64"

#ryzen_smu module
rm -rf ryzen_smu

git clone https://gitlab.com/leogx9r/ryzen_smu.git --depth 1
cd ryzen_smu

make $FLAGS -C $KERNEL_LOCATION M=$(pwd) modules

install -m 0755 -D ryzen_smu.ko $KERNEL_MODULES/lib/modules/$KERNEL_VERSION/extra/ryzen_smu.ko

cd $START

#ryzen_monitor util
PKG_RYZEN_MONITOR=$PWD/ryzen_monitor_pkg

rm -rf $PKG_RYZEN_MONITOR
rm -rf ryzen_monitor

mkdir -p $PKG_RYZEN_MONITOR

#develop or master
git clone https://github.com/hattedsquirrel/ryzen_monitor.git --depth 1
cd ryzen_monitor

make $FLAGS

install -m 0755 -D src/ryzen_monitor $PKG_RYZEN_MONITOR/usr/bin/ryzen_monitor

echo -e "\e[95m MAKEPKG RYZEN_MONITOR"
cd $PKG_RYZEN_MONITOR
fakeroot $START/../makepkg -l n -c y $START/ryzen_monitor-$ARCH-thor.tgz

cd $START
