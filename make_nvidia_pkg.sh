#!/bin/sh
COMPAT32="no"

KERNEL_LOCATION=$1
KERNEL_MODULES=$2
START="$(pwd)"

cd ${KERNEL_MODULES}/lib/modules
KERNEL_VERSION="$(find * -maxdepth 0 ! -path . -type d)"

cd $START

#make nvidia driver
# https://download.nvidia.com/XFree86/Linux-x86_64/latest.txt
nvidia_version="535.104.05"

rm -r NVIDIA-Linux-x86_64-$nvidia_version
wget https://us.download.nvidia.com/XFree86/Linux-x86_64/$nvidia_version/NVIDIA-Linux-x86_64-$nvidia_version.run
chmod +x NVIDIA-Linux-x86_64-$nvidia_version.run
./NVIDIA-Linux-x86_64-$nvidia_version.run --extract-only
cd NVIDIA-Linux-x86_64-$nvidia_version

NVIDIA_DIR="$(pwd)"

#wget https://gitlab.com/EULA/snippets/-/raw/master/NVIDIA/$nvidia_version/kernel-5.9.patch
#wget https://gitlab.com/EULA/snippets/-/raw/master/NVIDIA/$nvidia_version/mmu.patch
#patch -p1 -i kernel-5.9.patch
#patch -p1 -i mmu.patch
cd kernel
https://gist.githubusercontent.com/joanbm/2ec3c512a1ac21f5f5c6b3c1a4dbef35/raw/615feaefed2de3a28bd12fe9783894b84a7c86e4/nvidia-470xx-fix-linux-6.6.patch
patch -p1 -i nvidia-470xx-fix-linux-6.6.patch
cd ..

#sed -i '/MODULE_LICENSE("NVIDIA");/c\MODULE_LICENSE("GPL");' kernel/nvidia-modeset/nvidia-modeset-linux.c
#sed -i '/MODULE_LICENSE("MIT");/c\MODULE_LICENSE("GPL");' kernel/nvidia-drm/nvidia-drm-linux.c

echo -e "\e[95m Compile nvidia kernel modules"

cd kernel
make SYSSRC=${KERNEL_LOCATION} -j$(nproc) module
mkdir -p ${KERNEL_MODULES}/lib/modules/$KERNEL_VERSION/extra/nvidia
cp *.ko* ${KERNEL_MODULES}/lib/modules/*/extra/nvidia/
cd ${NVIDIA_DIR}

PKG="${NVIDIA_DIR}/pkg-usr"
mkdir -p ${PKG}/usr/share/X11/xorg.conf.d/
cat nvidia-drm-outputclass.conf > ${PKG}/usr/share/X11/xorg.conf.d/10-nvidia.conf

#wget https://download.nvidia.com/XFree86/nvidia-installer/nvidia-installer-$nvidia_version.tar.bz2
#wget https://download.nvidia.com/XFree86/nvidia-modprobe/nvidia-modprobe-$nvidia_version.tar.bz2
#wget https://download.nvidia.com/XFree86/nvidia-persistenced/nvidia-persistenced-$nvidia_version.tar.bz2
#wget https://download.nvidia.com/XFree86/nvidia-settings/nvidia-settings-$nvidia_version.tar.bz2
#wget https://download.nvidia.com/XFree86/nvidia-xconfig/nvidia-xconfig-$nvidia_version.tar.bz2
#tar xvf nvidia-installer-$nvidia_version.tar.bz2
cd ${NVIDIA_DIR}

wget https://download.nvidia.com/XFree86/nvidia-installer/nvidia-installer-$nvidia_version.tar.bz2
wget https://download.nvidia.com/XFree86/nvidia-modprobe/nvidia-modprobe-$nvidia_version.tar.bz2
wget https://download.nvidia.com/XFree86/nvidia-persistenced/nvidia-persistenced-$nvidia_version.tar.bz2
wget https://download.nvidia.com/XFree86/nvidia-settings/nvidia-settings-$nvidia_version.tar.bz2
wget https://download.nvidia.com/XFree86/nvidia-xconfig/nvidia-xconfig-$nvidia_version.tar.bz2
tar xvf nvidia-installer-$nvidia_version.tar.bz2
#git clone https://github.com/thor2002ro/nvidia-installer.git nvidia-installer-$nvidia_version --depth 1
tar xvf nvidia-settings-$nvidia_version.tar.bz2
#git clone https://github.com/NVIDIA/nvidia-settings.git nvidia-settings-$nvidia_version --depth 1
tar xvf nvidia-xconfig-$nvidia_version.tar.bz2
#git clone https://github.com/NVIDIA/nvidia-xconfig.git nvidia-xconfig-$nvidia_version --depth 1
tar xvf nvidia-modprobe-$nvidia_version.tar.bz2
#git clone https://github.com/NVIDIA/nvidia-modprobe.git nvidia-modprobe-$nvidia_version --depth 1
tar xvf nvidia-persistenced-$nvidia_version.tar.bz2
#git clone https://github.com/NVIDIA/nvidia-persistenced.git nvidia-persistenced-$nvidia_version --depth 1

wget https://slackbuilds.org/slackbuilds/15.0/system/nvidia-driver.tar.gz
wget https://slackbuilds.org/slackbuilds/15.0/system/nvidia-firmware.tar.gz
wget https://slackbuilds.org/slackbuilds/15.0/system/nvidia-kernel.tar.gz
tar xvf nvidia-driver.tar.gz
tar xvf nvidia-firmware.tar.gz
tar xvf nvidia-kernel.tar.gz

SLKCFLAGS="-O2 -fPIC"

echo -e "\e[95m Compile nvidia-installer"

cd nvidia-installer-$nvidia_version
#patch -p0 < ${NVIDIA_DIR}/nvidia-driver/skip_conflict-GPU_detect.patch
CFLAGS="$SLKCFLAGS" LDFLAGS="-lz" make

mkdir -p ${PKG}/usr/bin/
mkdir -p ${PKG}/usr/man/man1/

install -m 755 _out/Linux_x86_64/nvidia-installer ${PKG}/usr/bin/
install -m 644 _out/Linux_x86_64/nvidia-installer.1.gz ${PKG}/usr/man/man1/
mv -f ${PKG}/usr/bin/nvidia-installer ../
mv -f ${PKG}/usr/man/man1/nvidia-installer.1.gz ../

if [ "${COMPAT32}" = "yes" ]; then
    COMP32="--install-compat32-libs --compat32-prefix=${PKG}/usr"
    MULTI="_multilib"
else
    COMP32="--no-install-compat32-libs --compat32-prefix=${PKG}/usr"
    MULTI=""
fi

LIBDIRSUFFIX="64"

cd ${NVIDIA_DIR}

mkdir -p ${PKG}/var/log

echo -e "\e[95m RUN nvidia-installer"

./nvidia-installer -s --no-kernel-module --no-drm --no-unified-memory \
  -z -n -b --no-rpms --no-distro-scripts \
  --no-kernel-module-source --no-x-check --force-libglx-indirect \
  --x-prefix=$PKG/usr \
  --x-module-path=$PKG/usr/lib${LIBDIRSUFFIX}/xorg/modules \
  --x-library-path=$PKG/usr/lib${LIBDIRSUFFIX} \
  --x-sysconfig-path=$PKG/etc/X11/xorg.conf.d \
  --opengl-prefix=$PKG/usr \
  --utility-prefix=$PKG/usr \
  --utility-libdir=lib${LIBDIRSUFFIX} \
  --documentation-prefix=$PKG/usr \
  --application-profile-path=$PKG/usr/share/nvidia \
  --glvnd-egl-config-path=$PKG/etc/X11/glvnd/egl_vendor.d \
  --log-file-name=$PKG/var/log/nvidia-installer.log \
  --egl-external-platform-config-path=$PKG/usr/share/egl/egl_external_platform.d \
  --no-nvidia-modprobe \
  --no-install-libglvnd \
  --no-wine-files \
  --no-systemd \
  --no-peermem \
  $COMP32

#sed -i "s|${PKG}||" ${PKG}/usr/lib${LIBDIRSUFFIX}/libGL.la
#sed -i "s|${PKG}/usr|/usr/lib|" ${PKG}/usr/lib/libGL.la

#cd ${PKG}/usr/lib$LIBDIRSUFFIX
#mv libGL.la libGL.la-nvidia
#cd -
#cd ${PKG}/usr/lib
#mv libGL.la libGL.la-nvidia
#cd -

mkdir -p ${PKG}/usr/sbin/
install -m 0755 ${NVIDIA_DIR}/nvidia-driver/nvidia-switch ${PKG}/usr/sbin/
sed -i s/PKGVERSION/$nvidia_version/g ${PKG}/usr/sbin/nvidia-switch
sed -i s/LIBDIRSUFFIX/$LIBDIRSUFFIX/g ${PKG}/usr/sbin/nvidia-switch
if [ ${COMPAT32} = "yes" ]; then
    sed -i s/LIB32FLAG/yes/g ${PKG}/usr/sbin/nvidia-switch
else
    sed -i s/LIB32FLAG/no/g ${PKG}/usr/sbin/nvidia-switch
fi

cd ${NVIDIA_DIR}

#nvidia-settings
echo -e "\e[95m Compiling nvidia-settings"
cd nvidia-settings-$nvidia_version
cd src/libXNVCtrl
CFLAGS="$SLKCFLAGS" \
    make
cd ../../

CFLAGS="$SLKCFLAGS" \
    make

mkdir -p ${PKG}/usr/bin/
mkdir -p ${PKG}/usr/man/man1/
mkdir -p ${PKG}/usr/share/applications/
mkdir -p ${PKG}/usr/share/pixmaps/
mkdir -p ${PKG}/usr/lib$LIBDIRSUFFIX

install -m 755 src/_out/Linux_x86_64/nvidia-settings ${PKG}/usr/bin/

# For nvidia-settings GUI support
install -m 755 src/_out/Linux_x86_64/libnvidia-gtk2.so ${PKG}/usr/lib$LIBDIRSUFFIX/libnvidia-gtk2.so.$nvidia_version
install -m 755 src/_out/Linux_x86_64/libnvidia-gtk3.so ${PKG}/usr/lib$LIBDIRSUFFIX/libnvidia-gtk3.so.$nvidia_version

cd ${NVIDIA_DIR}

#nvidia-xconfig
echo -e "\e[95m Compiling nvidia-xconfig"
cd nvidia-xconfig-$nvidia_version
CFLAGS="$SLKCFLAGS" \
    make

mkdir -p ${PKG}/usr/bin/
mkdir -p ${PKG}/usr/man/man1/

install -m 755 _out/Linux_x86_64/nvidia-xconfig ${PKG}/usr/bin/
install -m 644 _out/Linux_x86_64/nvidia-xconfig.1.gz ${PKG}/usr/man/man1/

cd ${NVIDIA_DIR}

#modprobe
cd nvidia-modprobe-$nvidia_version
CFLAGS="$SLKCFLAGS" make

mkdir -p ${PKG}/usr/bin/
mkdir -p ${PKG}/usr/man/man1/

# must be installed suid root for nvidia-persistenced to work properly
install -m 4755 _out/Linux_x86_64/nvidia-modprobe ${PKG}/usr/bin/
install -m 644 _out/Linux_x86_64/nvidia-modprobe.1.gz ${PKG}/usr/man/man1/

cd ${NVIDIA_DIR}

# Compiling nvidia-persistenced
echo -e "\e[95m Compiling nvidia-persistenced"
cd nvidia-persistenced-$nvidia_version
CFLAGS="$SLKCFLAGS" make

mkdir -p ${PKG}/usr/bin/
mkdir -p ${PKG}/usr/man/man1/

install -m 755 _out/Linux_x86_64/nvidia-persistenced ${PKG}/usr/bin/
install -m 644 _out/Linux_x86_64/nvidia-persistenced.1.gz ${PKG}/usr/man/man1/

cd ${NVIDIA_DIR}

#libseccomp-git
echo -e "\e[95m libseccomp-git"
git clone https://github.com/seccomp/libseccomp.git --depth 1
cd libseccomp
./autogen.sh
./configure --prefix="/usr" --libdir="/usr/lib64"
CFLAGS="$SLKCFLAGS" make -j$(nproc)
make DESTDIR="${PKG}" install

#libtool --finish ${PKG}/usr/lib

cd ${NVIDIA_DIR}

#libnvidia-container-git
echo -e "\e[95m libnvidia-container-git"
git clone https://github.com/NVIDIA/libnvidia-container.git --depth 1
#--branch v1.3.1
LIBNV_CONT=${NVIDIA_DIR}/libnvidia-container
cd $LIBNV_CONT

_elfver=0.7.1
_nvmpver=$nvidia_version
deps_dir="deps/src/"

wget https://aur.archlinux.org/cgit/aur.git/plain/fix_libelf_so_name.patch?h=libnvidia-container -O fix_libelf_so_name.patch
wget https://aur.archlinux.org/cgit/aur.git/plain/fix_git_rev_unavail.patch?h=libnvidia-container -O fix_git_rev_unavail.patch
wget https://aur.archlinux.org/cgit/aur.git/plain/fix_rpc_flags.patch?h=libnvidia-container -O fix_rpc_flags.patch
wget https://aur.archlinux.org/cgit/aur.git/plain/fix_elftoolchain.patch?h=libnvidia-container -O fix_elftoolchain.patch

wget https://sourceforge.net/projects/elftoolchain/files/Sources/elftoolchain-${_elfver}/elftoolchain-${_elfver}.tar.bz2
wget https://github.com/NVIDIA/nvidia-modprobe/archive/${_nvmpver}.tar.gz

for dep in "elftoolchain-${_elfver}.tar.bz2" "${_nvmpver}.tar.gz"; do
    dep_dir="${deps_dir}/${dep%.tar*}"
    mkdir -p ${dep_dir}
    # untar the download into the deps dir
    tar -xf "${dep}" -C "${dep_dir}" --strip-components=1
    # tell make to ignore this target, it's already done
    touch "${dep_dir}/.download_stamp"
done

# the tar isn't named correctly, so the dir needs moving
if [ ! -d "${deps_dir}/nvidia-modprobe-${_nvmpver}" ]; then
    mv "${deps_dir}/${_nvmpver}" "${deps_dir}/nvidia-modprobe-${_nvmpver}"
    patch -d "${deps_dir}/nvidia-modprobe-${_nvmpver}" -p1 < "mk/nvidia-modprobe.patch"
fi

#patch -Np1 -i "fix_rpc_flags.patch"
patch -Np1 -i "fix_git_rev_unavail.patch"
patch -Np1 -i "fix_libelf_so_name.patch"
patch -Np1 -i "fix_elftoolchain.patch"

#fix for unraid
sed -i '/if (syscall(SYS_pivot_root, ".", ".") < 0)/,+1 d' src/nvc_ldcache.c
sed -i '/if (umount2(".", MNT_DETACH) < 0)/,+1 d' src/nvc_ldcache.c

CFLAGS="$SLKCFLAGS" \
    make \
    dist \
    prefix="/usr" \
    libdir="/usr/lib64" \
    libdbgdir="/usr/lib64/debug/usr/lib64"

cd $LIBNV_CONT

# untar into ${PKG}dir
tar -xf dist/*.tar.xz -C ${PKG} --strip-components=1

cd ${NVIDIA_DIR}

#setup go runc
echo -e "\e[95m setup go runc"
mkdir -p gopath/src
git clone https://github.com/opencontainers/runc gopath/src/github.com/opencontainers/runc --depth 1
cd gopath/src/github.com/opencontainers/runc
make

cd ${NVIDIA_DIR}

#nvidia-container-toolkit-git
echo -e "\e[95m nvidia-container-toolkit-git"
git clone https://github.com/NVIDIA/nvidia-container-toolkit.git --depth 1
#--branch v1.3.1
NV_TOOLKIT_DIR=${NVIDIA_DIR}/nvidia-container-toolkit
cd $NV_TOOLKIT_DIR
ln -rTsf pkg ${NVIDIA_DIR}/gopath/src/nvidia-container-toolkit

GOPATH=${NVIDIA_DIR}/gopath \
    go build -v \
    -buildmode=pie \
    -gcflags "all=-trimpath=${PWD}" \
    -asmflags "all=-trimpath=${PWD}" \
    -ldflags "-s -w" \
    -o nvidia-container-toolkit ./pkg

install -D -m755 $NV_TOOLKIT_DIR/nvidia-container-toolkit ${PKG}/usr/bin/nvidia-container-toolkit
cd ${PKG}/usr/bin/
ln -sf nvidia-container-toolkit nvidia-container-runtime-hook
cd -
install -D -m644 $NV_TOOLKIT_DIR/config/config.toml.centos ${PKG}/etc/nvidia-container-runtime/config.toml
install -D -m644 $NV_TOOLKIT_DIR/oci-nvidia-hook.json ${PKG}/usr/share/containers/oci/hooks.d/00-oci-nvidia-hook.json

install -D -m644 $NV_TOOLKIT_DIR/LICENSE ${PKG}/usr/share/licenses/nvidia-container-toolkit/LICENSE

cd ${NVIDIA_DIR}

#nvidia-container-runtime-git
echo -e "\e[95m nvidia-container-runtime-git"
git clone https://github.com/NVIDIA/nvidia-container-runtime.git --depth 1
#--branch v3.4.0
NV_RUNTIME_DIR=${NVIDIA_DIR}/nvidia-container-runtime
cd $NV_RUNTIME_DIR
ln -rTsf src ${NVIDIA_DIR}/gopath/src/nvidia-container-runtime

cd src
GOPATH=${NVIDIA_DIR}/gopath \
    go build -v \
    -buildmode=pie \
    -gcflags "all=-trimpath=${PWD}" \
    -asmflags "all=-trimpath=${PWD}" \
    -ldflags "-s -w" \
    -trimpath
#-extldflags ${LDFLAGS}
install -D -m755 $NV_RUNTIME_DIR/src/container-runtime ${PKG}/usr/bin/nvidia-container-runtime
install -D -m644 $NV_RUNTIME_DIR/LICENSE ${PKG}/usr/share/licenses/nvidia-container-runtime/LICENSE

cd ${NVIDIA_DIR}

#nvidia-docker-git
echo -e "\e[95m nvidia-docker-git"
git clone https://github.com/NVIDIA/nvidia-docker.git --depth 1
NV_DOCKER_DIR=${NVIDIA_DIR}/nvidia-docker
cd $NV_DOCKER_DIR

install -D -m755 nvidia-docker ${PKG}/usr/bin/nvidia-docker
install -D -m644 daemon.json ${PKG}/etc/docker/daemon.json
install -D -m644 LICENSE ${PKG}/usr/share/licenses/nvidia-docker/LICENSE

cd ${NVIDIA_DIR}

#patch stupid nvidia
cd ${PKG}/usr/lib64
#sed -i 's/\x85\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/\x31\xc0\x89\xc3\x0f\x85\xa9\xfa\xff\xff/' libnvidia-fbc.so
sed -i 's/\x83\xfe\x01\x73\x08\x48/\x83\xfe\x00\x72\x08\x48/' libnvidia-fbc.so*
sed -i 's/\x22\xff\xff\x85\xc0\x41\x89\xc4\x0f\x85/\x22\xff\xff\x31\xc0\x41\x89\xc4\x0f\x85/g' libnvidia-encode.so*
cd ${NVIDIA_DIR}

    rm -f ${PKG}/usr/lib${LIBDIRSUFFIX}/*.la
#   rm -f ${PKG}/usr/lib${LIBDIRSUFFIX}/libOpenCL.so.1.0.0
    rm -f ${PKG}/usr/lib/*.la
#   rm -f ${PKG}/usr/lib/libOpenCL.so.1.0.0

    rm -f ${PKG}/usr/lib${LIBDIRSUFFIX}/*.a
    rm -f ${PKG}/usr/lib/*.a

for WORK_LIBS in libnvidia-encode libnvidia-fbc; do
    rm -f ${PKG}/usr/lib${LIBDIRSUFFIX}/$WORK_LIBS.so
    rm -f ${PKG}/usr/lib${LIBDIRSUFFIX}/$WORK_LIBS.so.1
    ln -s $WORK_LIBS.so.$nvidia_version ${PKG}/usr/lib${LIBDIRSUFFIX}/$WORK_LIBS.so
    ln -s $WORK_LIBS.so.$nvidia_version ${PKG}/usr/lib${LIBDIRSUFFIX}/$WORK_LIBS.so.1
done

( cd $PKG/usr/lib${LIBDIRSUFFIX}/gbm
rm -f nvidia-drm_gbm.so
  ln -sf ../libnvidia-allocator.so.1 nvidia-drm_gbm.so
)    

install -m 0755 -D $START/../nvidia_doinst.sh ${PKG}/install/doinst.sh

# Flag multlib as needed and build package.
echo -e "\e[95m MAKEPKG NVIDIA"
cd ${PKG}
rm -rf var
fakeroot $START/../makepkg -l n -c y $START/nvidia-driver-utils-$nvidia_version$MULTI-x86_64-thor.tgz

#end nvidia

cd $START
depmod -b ${KERNEL_MODULES} -F ${KERNEL_LOCATION}/System.map $KERNEL_VERSION
