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

export CFLAGS="$SLKCFLAGS"
export $FLAGS

#make zfs
PKG_ZFS=$PWD/zfs_pkg

rm -rf $PKG_ZFS
rm -rf zfs

mkdir -p $PKG_ZFS

git clone https://github.com/openzfs/zfs.git --depth 1
cd zfs

#git clone https://github.com/robn/zfs.git -b linux-6.9-compat
#cd zfs

#git remote add 6.9 https://github.com/robn/zfs.git
#git remote update                                 
#git merge 6.9/linux-6.9-compat                    

#patch for kernel 6.5
#sed -i 's/Linux-Maximum: 6.3/Linux-Maximum: 6.5/' META

wget https://slackbuilds.org/slackbuilds/15.0/system/openzfs.tar.gz
tar xvf openzfs.tar.gz

./autogen.sh

./configure \
    --prefix=/usr \
    --localstatedir=/var \
    --sysconfdir=/etc \
    --libdir=/usr/lib64 \
    --bindir=/usr/bin \
    --sbindir=/usr/sbin \
    --includedir=/usr/include \
    --mandir=/usr/man \
    --docdir=/usr/doc/zfs \
    --with-linux=$KERNEL_LOCATION \
    --with-linux-obj=$KERNEL_LOCATION \
    --build=$ARCH-slackware-linux \
    --enable-linux-experimental

#./configure --disable-user --enable-linux-builtin

make -j$(nproc)
#make -C module/ INSTALL_MOD_PATH=$KERNEL_MODULES modules_install
make install DESTDIR=$PKG_ZFS

#move modules
mv -f $PKG_ZFS/lib/modules/$KERNEL_VERSION/extra \
    $KERNEL_MODULES/lib/modules/$KERNEL_VERSION/extra/zfs

# no such thing here
rm -fr $PKG_ZFS/usr/lib/dracut
rm -fr $PKG_ZFS/etc/init.d
rm -fr $PKG_ZFS/etc/sudoers.d
rm -fr $PKG_ZFS/lib

mkdir -p $PKG_ZFS/etc/rc.d/init.d
#install -m 0755 -D zfs-on-linux/rc.zfs $PKG_ZFS/etc/rc.d/rc.zfs
install -m 0755 -D $START/../rc.zfs $PKG_ZFS/etc/rc.d/rc.zfs
ln -s ../rc.zfs $PKG_ZFS/etc/rc.d/init.d/zfs
install -m 0755 -D $START/../zfs_doinst.sh $PKG_ZFS/install/doinst.sh

# create the lock directory
mkdir -p $PKG_ZFS/var/lock/zfs

echo -e "\e[95m MAKEPKG zfs"
cd $PKG_ZFS
#fakeroot $START/../makepkg -l n -c y $START/zfs-$(date +'%Y%m%d')-x86_64-thor.tgz

cd $START
