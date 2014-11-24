if [ $# -gt 0 ]; then
echo $1 > .version
fi
 
echo "Setting up working locations";
if [ "${1}" != "" ]; then
	export KERNEL_DIR=`readlink -f ${1}`;
else
	export KERNEL_DIR=`readlink -f .`;
fi;

export MODEL=v500;
export TYPE=stock;
export ANYKERNEL_DIR=~/Documentos/anykernel-lollipop/;
export CROSS_COMPILE=~/Documentos/linaro_toolchains_2014/arm-cortex_a15-linux-gnueabihf-linaro_4.9.1-2014.07/bin/arm-cortex_a15-linux-gnueabihf-
export ARCH=arm
export KERNEL_CONFIG=wr_defconfig;
make $KERNEL_CONFIG;

echo "Getting version from config file";
GETVER=`grep 'wrKernel-r' .config | sed 's/.*wrKernel-\(r[0-9]*\).*/\1/g'`;

echo "Removing old zImage file";
if [ -e "$KERNEL_DIR/arch/arm/boot/zImage" ]; then
	rm "$KERNEL_DIR/arch/arm/boot/zImage";
fi;

echo "Removing old modules files from kernel folder";
for i in `find "$KERNEL_DIR/" -name "*.ko"`; do
	rm -f $i;
done;

echo "Removing old modules files from anykernel-lollipop folder";
for i in `find "$ANYKERNEL_DIR/system/lib/modules/" -name "*.ko"`; do
	rm -f $i;
done;

echo "Calculating how many cpus will be used to build the kernel";
HOST_CHECK=`uname -n`
NCPU=$(expr `grep processor /proc/cpuinfo | wc -l` + 1);
echo $HOST_CHECK

#echo "Building the kernel with modules inside of zImage";
#make zImage -j${NCPU} || exit 1;

echo "Building the kernel with modules separately from zImage";
make -j${NCPU} || exit 1;
 
echo "Copying zImage to anykernel-lollipop folder";
cp arch/arm/boot/zImage "$ANYKERNEL_DIR/kernel"

echo "Copying modules to anykernel-lollipop folder";
for i in `find $KERNEL_DIR -name '*.ko'`; do
	cp -av $i "$ANYKERNEL_DIR/system/lib/modules/";
done;

echo "Stripping uneeded stuff from modules";
for i in `find $ANYKERNEL_DIR/system/lib/modules/ -name '*.ko'`; do
	${CROSS_COMPILE}strip --strip-unneeded $i;
	${CROSS_COMPILE}strip --strip-debug $i;
done;
 
cd "$ANYKERNEL_DIR"
 
zipfile="wrKernel-$MODEL-$TYPE-$GETVER.zip"
echo "making zip file"
 
cd zip/
rm -f *.zip
zip -r $zipfile *
rm -f /tmp/*.zip
cp *.zip /tmp
