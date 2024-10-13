#!/bin/sh

# Define paths and variables
KERNEL_LOCATION="$(pwd)/unraid_kernel"
KERNEL_MODULES="$(pwd)/modules"
START="$(pwd)"
#FLAGS="CC=clang-18 LLVM=1 LLVM_IAS=1"
#FLAGS="CC=clang-18 LLVM=-18 LLVM_IAS=1"
#FLAGS="CC=clang-16 CXX=clang++-16 HOSTCC=clang-16 HOSTCXX=clang++-16 LD=ld.lld-16 LLVM=-16 LLVM_IAS=1"
#FLAGS="LLVM=-18 LLVM_IAS=1"

# Get kernel version from the Makefile
KERNEL_VERSION=$(make -s -C $KERNEL_LOCATION kernelversion)

# Clean old builds
sudo rm -r extras modules
rm -rf bz*

# Unpack bzmodules
unsquashfs -f -d bzmodules.install unraid_bzmodules.6.12.13

cd bzmodules.install/firmware/
mkdir -p ../keep
mv ast_dp501_fw.bin BCM2033-FW.bin BCM2033-MD.hex ../keep/
rm -r *
mv ../keep/* .
find . -type f \( -name "*.bin" -o -name "*.fw" -o -name "*.hex" -o -name "*.inp" -o -name "*.ucode" \) -exec xz -z {} \; -exec mv {}.xz {}.xz \;
rm -r ../keep

cd $START

# Update firmware
rm -rf linux-firmware dvb-firmware
git clone https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git --depth 1
#rm -rf linux-firmware/.git
cd linux-firmware/
./copy-firmware.sh --xz ../bzmodules.install/firmware/

cd $START

git clone https://github.com/LibreELEC/dvb-firmware.git --depth 1
#rm -rf dvb-firmware/.git
cd dvb-firmware/firmware/
rm s2250_loader.fw s2250.fw
# Find and compress all .bin and .fw files with xz
find . -type f \( -name "*.bin" -o -name "*.fw" -o -name "*.hex" -o -name "*.inp" -o -name "*.ucode" \) -exec xz -z {} \; -exec mv {}.xz {}.xz \;
cd $START
rsync -a --force dvb-firmware/firmware/ bzmodules.install/firmware/

cd $START

# Build kernel
cd $KERNEL_LOCATION
make clean $FLAGS
make -j$(nproc) $FLAGS

# Install kernel modules
rm -rf $KERNEL_MODULES
make INSTALL_MOD_PATH=$KERNEL_MODULES modules_install

cd $START

# Set up modules
cd $KERNEL_MODULES/lib/modules
KERNEL_MODULES_VERSION="$(find * -maxdepth 0 ! -path . -type d)"
mkdir -p $KERNEL_MODULES/lib/modules/$KERNEL_MODULES_VERSION/extra

cd $START

# Create extras folder
rm -rf extras
mkdir -p extras
cd extras

# CoreFreq package
$START/make_corefreq_pkg.sh $KERNEL_LOCATION $KERNEL_MODULES "$FLAGS"

# ZFS package
$START/make_zfs_pkg.sh $KERNEL_LOCATION $KERNEL_MODULES "$FLAGS"

# Ryzen SMU package
$START/make_ryzen_smu_pkg.sh $KERNEL_LOCATION $KERNEL_MODULES "$FLAGS"

# Vendor reset package
$START/make_vendor_reset_pkg.sh $KERNEL_LOCATION $KERNEL_MODULES "$FLAGS"

# Google Coral driver
$START/make_google_coral.sh $KERNEL_LOCATION $KERNEL_MODULES

# Ugreen LEDs module
$START/make_ugreen_leds_module.sh $KERNEL_LOCATION $KERNEL_MODULES

cd $START

# Compress kernel modules
find $KERNEL_MODULES/lib/modules/$KERNEL_MODULES_VERSION/extra -name '*.ko' -exec xz -zf {} +

# Run depmod
depmod -b $KERNEL_MODULES -F $KERNEL_LOCATION/System.map $KERNEL_MODULES_VERSION -C $pwd/dist.conf

# Package bzmodules
rm -r bzmodules.install/modules
mv modules/lib/modules bzmodules.install
mksquashfs bzmodules.install/* bzmodules -keep-as-directory -noappend -root-owned -no-xattrs

# Package bzImage
cp -f $KERNEL_LOCATION/arch/x86/boot/bzImage bzimage

# Generate checksums
sha256sum bzmodules > bzmodules.sha256
sha256sum bzimage > bzimage.sha256

# Package final output
7z a $KERNEL_VERSION-$(date +'%Y%m%d')-gcc.7z bzimage bzimage.sha256 bzmodules bzmodules.sha256 extras/*.tgz
