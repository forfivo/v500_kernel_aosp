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
export PARENT_DIR=`readlink -f ..`
export INITRAMFS_TMP=~/Documentos/tmp/initramfs_source_$MODEL;
export INITRAMFS_SOURCE=$PARENT_DIR/wr-kernel-v500-stock-ramdisk
export PACKAGE_DIR=$KERNEL_DIR/OUTPUT
export CROSS_COMPILE=~/Documentos/android_prebuilt_toolchains/arm-linux-androideabi-4.7/bin/arm-linux-androideabi-
export ARCH=arm
export KERNEL_CONFIG=wr_defconfig;

make $KERNEL_CONFIG;

echo "Getting version from config file";
GETVER=`grep 'wrKernel-r' .config | sed 's/.*wrKernel-\(r[0-9]*\).*/\1/g'`;

echo "Setup Package Directory"
mkdir -p $PACKAGE_DIR/system/lib/modules

if [ -d $INITRAMFS_TMP ]; then
	echo "removing old temp initramfs_source";
	rm -rf $INITRAMFS_TMP;
fi;

echo "Removing old zImage file";
if [ -e "$KERNEL_DIR/arch/arm/boot/zImage" ]; then
	rm "$KERNEL_DIR/arch/arm/boot/zImage";
fi;

echo "Remove old boot.img file";
# remove previous zImage files
if [ -e $PACKAGE_DIR/boot.img ]; then
	rm $PACKAGE_DIR/boot.img;
fi;

echo "Removing old modules files from kernel folder";
for i in `find "$KERNEL_DIR/" -name "*.ko"`; do
	rm -f $i;
done;

echo "Removing old modules files from package folder";
for i in `find "$PACKAGE_DIR/system/lib/modules/" -name "*.ko"`; do
	rm -f $i;
done;

# copy initramfs files to tmp directory
cp -ax $INITRAMFS_SOURCE $INITRAMFS_TMP;

# clear git repository from tmp-initramfs
if [ -d $INITRAMFS_TMP/.git ]; then
	rm -rf $INITRAMFS_TMP/.git;
fi;

# clear mercurial repository from tmp-initramfs
if [ -d $INITRAMFS_TMP/.hg ]; then
	rm -rf $INITRAMFS_TMP/.hg;
fi;

# remove empty directory placeholders from tmp-initramfs
for i in `find $INITRAMFS_TMP -name EMPTY_DIRECTORY`; do
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

echo "Copying modules to package folder";
for i in `find $KERNEL_DIR -name '*.ko'`; do
	cp -av $i "$PACKAGE_DIR/system/lib/modules/";
done;

echo "Stripping uneeded stuff from modules";
for i in `find $PACKAGE_DIR/system/lib/modules/ -name '*.ko'`; do
	${CROSS_COMPILE}strip --strip-unneeded $i;
	${CROSS_COMPILE}strip --strip-debug $i;
done;

chmod 644 $PACKAGE_DIR/system/lib/modules/*;

if [ -e $KERNEL_DIR/arch/arm/boot/zImage ]; then
	echo "Copy zImage to Package folder"
	cp arch/arm/boot/zImage $PACKAGE_DIR/zImage

	echo "Make boot.img file"
	./mkbootfs $INITRAMFS_TMP | gzip > $PACKAGE_DIR/ramdisk.gz
	./mkbootimg --base 0 --pagesize 2048 --kernel_offset 0x80208000 --ramdisk_offset 0x82200000 --second_offset 0x81100000 --tags_offset 0x80200100 --cmdline 'console=ttyHSL0,115200,n8 user_debug=31 msm_rtb.filter=0x3F ehci-hcd.park=3 lpj=67677 androidboot.hardware=awifi vmalloc=600M' --kernel $PACKAGE_DIR/zImage --ramdisk $PACKAGE_DIR/ramdisk.gz  --output $PACKAGE_DIR/boot.img
	cd $PACKAGE_DIR

	if [ -e ramdisk.gz ]; then
		rm ramdisk.gz;
	fi;

	if [ -e zImage ]; then
		rm zImage;
	fi;

	echo "Remove old zip files from package folder"
	rm -f *.zip

	zipfile="wrKernel-$MODEL-$TYPE-$GETVER.zip"
	echo "making zip file"
	zip -r $zipfile *
	
	cd $KERNEL_DIR
else
	echo "KERNEL DID NOT BUILD! no zImage exist"
fi;