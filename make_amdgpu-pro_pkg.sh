#!/bin/sh

KERNEL_LOCATION=$1
KERNEL_MODULES=$2
FLAGS="$3"
START="$(pwd)"

cd $KERNEL_MODULES/lib/modules
KERNEL_VERSION="$(find * -maxdepth 0 ! -path . -type d)"

cd $START

# AMDGPU Pro module
rm -rf amdgpu_pro
git clone https://github.com/amdgpu-pro/AMDGPU-PRO-Drivers.git --depth 1
cd AMDGPU-PRO-Drivers

# Build AMDGPU Pro module
./amdgpu-pro-install -y --opencl=rocr,legacy --headless --target $(uname -m) --kernel-path $KERNEL_LOCATION

# Copy AMDGPU Pro module to kernel modules directory
cp -r $START/AMDGPU-PRO-Drivers/* $KERNEL_MODULES/

# Compress the AMDGPU Pro module
find $KERNEL_MODULES -name '*.ko' -exec xz -zf {} +

# Update module dependencies
depmod -b $KERNEL_MODULES -F $KERNEL_LOCATION/System.map $KERNEL_VERSION -C $START/dist.conf

cd $START
