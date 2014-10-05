#!/bin/bash

# Add Colors to unhappiness
green='\033[01;32m'
red='\033[01;31m'
restore='\033[0m'

clear

# Kernel Version
BASE_KVER="mani"
VER="_v19"
KVER=$BASE_KVER$VER
DEFCONF="mani_v500_defconfig"

# Directories & jobs
JOBS=`grep -c "processor" /proc/cpuinfo`
KERNEL_DIR="$HOME/android/v500_kernel_aosp"
ZIP_DIR="$HOME/android/boot_aosp"

# start building
echo -e "${green}"
echo ">>> set prerequisites"
echo -e "${restore}"
export LOCALVERSION="-"`echo $KVER`
export ARCH=arm
export SUBARCH=arm
#export CROSS_COMPILE="$HOME/android/a15-linaro-4.9.2/bin/arm-cortex_a15-linux-gnueabihf-"
export CROSS_COMPILE="$HOME/android/arm-linux-4.8/bin/arm-eabi-"

echo -e "${green}"
echo ">>> build zImage"
echo -e "${restore}"
make $DEFCONF
make -j$JOBS

echo -e "${green}"
echo ">>> copy zImage to boot/kernel/<"
echo -e "${restore}"
cp arch/arm/boot/zImage $ZIP_DIR/kernel/

echo -e "${green}"
echo ">>> copy modules to boot/system/lib/modules<"
echo -e "${restore}"
find $KERNEL_DIR -name "*.ko" -exec cp {} $ZIP_DIR/system/lib/modules/ \;

zipfile=$KVER
echo -e "${green}"
echo ">>> build zipfile"
echo -e "${restore}"
cd $ZIP_DIR
rm -f *.zip
zip -9 -r $zipfile *
rm -f /tmp/*.zip
cp *.zip /tmp

echo -e "${red}"
echo ">>> ZIP is ready"
echo -e "${restore}"
