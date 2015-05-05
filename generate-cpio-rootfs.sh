#!/bin/bash

echo "Generator for a simple initramfs root filesystem for some ARM targets"
CURDIR=`pwd`
STAGEDIR=${CURDIR}/stage
BUILDDIR=${CURDIR}/build

STRACEVER=strace-4.7
STRACE=${CURDIR}/${STRACEVER}
BUILD_BUSYBOX=1
BUILD_LINUX_HEADERS=
BUILD_ALSA=
BUILD_PERF=
BUILD_SELFTEST=
BUILD_IIOTOOLS=
# If present, perf will be built and added to the filesystem
LINUX_TREE=${HOME}/linux

# Helper function to copy one level of files and then one level
# of links from a directory to another directory.
function clone_dir()
{
    SRCDIR=$1
    DSTDIR=$2
    FILES=`find ${SRCDIR} -maxdepth 1 -type f`
    for file in ${FILES} ; do
	BASE=`basename $file`
	cp $file ${DSTDIR}/${BASE}
	# ${STRIP} -s ${DSTDIR}/${BASE}
    done;
    # Clone links from the toolchain binary library dir
    LINKS=`find ${SRCDIR} -maxdepth 1 -type l`
    cd ${DSTDIR}
    for file in ${LINKS} ; do
	BASE=`basename $file`
	TARGET=`readlink $file`
	ln -s ${TARGET} ${BASE}
    done;
    cd ${CURDIR}
}

case $1 in
    "i486")
	echo "Building Intel i486 root filesystem"
	export ARCH=i486
	CC_PREFIX=i486
	CC_DIR=/var/linus/cross-compiler-i486
	LIBCBASE=${CC_DIR}
	CFLAGS="-march=i486 -mtune=i486 -m32"
	cp etc/inittab-pc etc/inittab
	echo "i486" > etc/hostname
	;;
    "i586")
	echo "Building Intel i586 Pentium root filesystem"
	export ARCH=i586
	CC_PREFIX=i586
	CC_DIR=/var/linus/cross-compiler-i586
	LIBCBASE=${CC_DIR}
	# Skip -mtune pentium-mmx for generic Pentium image
	CFLAGS="-march=i586 -mtune=pentium-mmx -m32"
	cp etc/inittab-pc etc/inittab
	echo "i586" > etc/hostname
	;;
    "h3600")
	echo "Building SA1110 Compaq h3600 ARMv4 root filesystem"
	export ARCH=arm
	# Use ARMv4l base for SA1100 rootfs builds
	# This is the convention of Rob Landley's binaries
	CC_PREFIX=armv4l
	CC_DIR=/var/linus/cross-compiler-armv4l
	LIBCBASE=${CC_DIR}
	CFLAGS="-msoft-float -marm -mabi=aapcs-linux -mno-thumb-interwork -mcpu=strongarm1100"
	cp etc/inittab-sa1100 etc/inittab
	echo "h3600" > etc/hostname
	;;
    "footbridge")
	echo "Building SA110 Footbridge ARMv4 root filesystem"
	export ARCH=arm
	# Use ARMv4l base for SA110 rootfs builds
	# This is the convention of Rob Landley's binaries
	CC_PREFIX=armv4l
	CC_DIR=/var/linus/cross-compiler-armv4l
	LIBCBASE=${CC_DIR}
	CFLAGS="-msoft-float -marm -mabi=aapcs-linux -mno-thumb-interwork -mcpu=strongarm110"
	cp etc/inittab-footbridge etc/inittab
	echo "footbridge" > etc/hostname
	;;
    "nslu2")
	echo "Building NSLU2 ARMv5TE XScale root filesystem"
	export ARCH=arm
	# This big-endian toolchain was generated with crosstool-ng
	# configured for bigendian ARM and Linux as operating system
	CC_PREFIX=armeb-unknown-linux-gnueabi
	CC_DIR=/home/linus/x-tools/armeb-unknown-linux-gnueabi
	LIBCBASE=${CC_DIR}/${CC_PREFIX}/sysroot
	CFLAGS="-msoft-float -marm -mthumb -mthumb-interwork -march=armv5te -mtune=xscale -mbig-endian"
	cp etc/inittab-xscale etc/inittab
	echo "nslu2" > etc/hostname
	;;
    "integrator")
	echo "Building Integrator ARMv4 root filesystem"
	export ARCH=arm

	# Use ARMv4T base for Integrator rootfs builds
	#CC_PREFIX=armv4tl
	#CC_DIR=/var/linus/cross-compiler-armv4tl
	#LIBCBASE=${CC_DIR}
	#CFLAGS="-msoft-float -marm -mabi=aapcs-linux -mthumb -mthumb-interwork -march=armv4t -mtune=arm9tdmi"

	# Works but no framebuffer... (error on mmap)
	#CC_PREFIX=armv4l
	#CC_DIR=/var/linus/cross-compiler-armv4l
	#LIBCBASE=${CC_DIR}
	#CFLAGS="-msoft-float -marm -mabi=aapcs-linux -mno-thumb-interwork -mcpu=arm920t"

	# Code Sourcery
	CC_PREFIX=arm-none-linux-gnueabi
	CC_DIR=/var/linus/arm-2010q1
	LIBCBASE=${CC_DIR}/${CC_PREFIX}/libc/armv4t
	CFLAGS="-msoft-float -marm -mabi=aapcs-linux -mthumb -mthumb-interwork -march=armv4t -mtune=arm9tdmi"

	cp etc/inittab-integrator etc/inittab
	echo "integrator" > etc/hostname
	;;
    "msm8660")
	echo "Building Qualcomm MSM8660 root filesystem"
	export ARCH=arm
	CC_PREFIX=arm-linux-gnueabihf
	CC_DIR=/var/linus/gcc-linaro-arm-linux-gnueabihf-4.9-2014.09_linux
	LIBCBASE=${CC_DIR}/${CC_PREFIX}/libc
	CFLAGS="-marm -mabi=aapcs-linux -mthumb -mthumb-interwork -mcpu=cortex-a9"
	cp etc/inittab-msm8660 etc/inittab
	echo "msm8660" > etc/hostname
	;;
    "nhk8815")
	echo "Building Nomadik NHK8815 root filesystem"
	export ARCH=arm
	CC_PREFIX=armv5l
	CC_DIR=/var/linus/cross-compiler-armv5l
	LIBCBASE=${CC_DIR}
	CFLAGS="-msoft-float -marm -mabi=aapcs-linux -mno-thumb-interwork -march=armv5te -mtune=arm926ej-s"
	cp etc/inittab-nhk8815 etc/inittab
	echo "NHK8815" > etc/hostname
	;;
    "pb1176")
	echo "Building ARM RealView PB1176 root filesystem"
	export ARCH=arm
	CC_PREFIX=armv6l
	CC_DIR=/var/linus/cross-compiler-armv6l
	LIBCBASE=${CC_DIR}
	# Notice: no thumb VFP hardfloat on Thumb1
	CFLAGS="-marm -mabi=aapcs-linux -mno-thumb -mno-thumb-interwork -mcpu=arm1176jzf-s"
	cp etc/inittab-realview etc/inittab
	echo "PB1176" > etc/hostname
	;;
    "u300")
	echo "Building ST-Ericsson U300 root filesystem"
	export ARCH=arm
	CC_PREFIX=armv5l
	CC_DIR=/var/linus/cross-compiler-armv5l
	LIBCBASE=${CC_DIR}
	CFLAGS="-msoft-float -marm -mabi=aapcs-linux -mthumb -mthumb-interwork -march=armv5t -mtune=arm9tdmi"
	BUILD_SELFTEST=1
	cp etc/inittab-u300 etc/inittab
	echo "U300" > etc/hostname
	;;
    "ux500")
	echo "Building ST-Ericsson Ux500 root filesystem"
	export ARCH=arm
	CC_PREFIX=arm-linux-gnueabihf
	CC_DIR=/var/linus/gcc-linaro-arm-linux-gnueabihf-4.9-2014.09_linux
	LIBCBASE=${CC_DIR}/${CC_PREFIX}/libc
	CFLAGS="-marm -mabi=aapcs-linux -mthumb -mthumb-interwork -mcpu=cortex-a9"
	# BUILD_ALSA=1
	BUILD_IIOTOOLS=1
	cp etc/inittab-ux500 etc/inittab
	echo "Ux500" > etc/hostname
	;;
    "exynos")
	echo "Building Samsung Exynos root filesystem"
	export ARCH=arm
	CC_PREFIX=arm-linux-gnueabihf
	CC_DIR=/var/linus/gcc-linaro-arm-linux-gnueabihf-4.9-2014.09_linux
	LIBCBASE=${CC_DIR}/${CC_PREFIX}/libc
	CFLAGS="-marm -mabi=aapcs-linux -mthumb -mthumb-interwork -mcpu=cortex-a15"
	cp etc/inittab-exynos etc/inittab
	echo "Exynos" > etc/hostname
	;;
    "versatile")
	echo "Building ARM Versatile root filesystem"
	export ARCH=arm
	CC_PREFIX=arm-none-linux-gnueabi
	CC_DIR=/var/linus/arm-2010q1
	LIBCBASE=${CC_DIR}/${CC_PREFIX}/libc
	CFLAGS="-msoft-float -marm -mabi=aapcs-linux -mthumb -mthumb-interwork -march=armv5t -mtune=arm9tdmi"
	cp etc/inittab-versatile etc/inittab
	echo "Versatile" > etc/hostname
	;;
    "vexpress")
	echo "Building Versatile Express root filesystem"
	export ARCH=arm
	CC_PREFIX=arm-linux-gnueabihf
	CC_DIR=/var/linus/gcc-linaro-arm-linux-gnueabihf-4.9-2014.09_linux
	LIBCBASE=${CC_DIR}/${CC_PREFIX}/libc
	CFLAGS="-marm -mabi=aapcs-linux -mthumb -mthumb-interwork -mcpu=cortex-a15"
	cp etc/inittab-vexpress etc/inittab
	echo "Vexpress" > etc/hostname
	;;
    "aarch64")
	echo "Building AARCH64 root filesystem"
	export ARCH=aarch64
	CC_PREFIX=aarch64-linux-gnu
	CC_DIR=/var/linus/gcc-linaro-aarch64-linux-gnu-4.9-2014.09_linux
	LIBCBASE=${CC_DIR}/${CC_PREFIX}/libc
	CFLAGS="-march=armv8-a"
	cp etc/inittab-vexpress etc/inittab
	echo "AARCH64" > etc/hostname
	;;
    *)
	echo "Usage: $0 [i486|i586|h3600|footbridge|integrator|msm8660|nhk8815|pb1176|u300|ux500|exynos|versatile|vexpress|aarch64]"
	exit 1
	;;
esac

# Define more tools
STRIP=${CC_PREFIX}-strip
OUTFILE=${HOME}/rootfs-$1.cpio

echo "OUTFILE = ${OUTFILE}"

echo "Check prerequisites..."
echo "Set up cross compiler at: ${CC_DIR}"
export PATH="$PATH:${CC_DIR}/bin"
echo -n "Check crosscompiler ... "
which ${CC_PREFIX}-gcc > /dev/null ; if [ ! $? -eq 0 ] ; then
    echo "ERROR: cross-compiler ${CC_PREFIX}-gcc not in PATH=$PATH!"
    echo "ABORTING."
    exit 1
else
    echo "OK"
fi

echo -n "gen_init_cpio ... "
which gen_init_cpio > /dev/null ; if [ ! $? -eq 0 ] ; then
    echo "ERROR: gen_init_cpio not in PATH=$PATH!"
    echo "Copy this binary from the Linux build tree."
    echo "Or set your PATH into the Linux kernel tree, I don't care..."
    echo "ABORTING."
    exit 1
else
    echo "OK"
fi

# Copy the template of static files to be used
cp filelist.txt filelist-final.txt

# Prep dirs
if [ -d ${STAGEDIR} ] ; then
    echo "Scrathing old ${STAGEDIR}"
    rm -rf ${STAGEDIR}
fi
if [ -d ${BUILDDIR} ] ; then
    echo "Scrathing old ${BUILDDIR}"
    rm -rf ${BUILDDIR}
fi
mkdir ${STAGEDIR}
mkdir ${STAGEDIR}/bin
mkdir ${STAGEDIR}/lib
mkdir ${STAGEDIR}/sbin
mkdir ${STAGEDIR}/usr
mkdir ${STAGEDIR}/usr/bin
mkdir ${STAGEDIR}/usr/lib
mkdir ${STAGEDIR}/usr/sbin
mkdir ${STAGEDIR}/usr/share
mkdir ${BUILDDIR}

if test ${BUILD_BUSYBOX} ; then

# Clone the busybox git if we don't have it...
if [ ! -d busybox ] ; then
    echo "It appears we're missing a busybox git, cloning it."
    git clone git://busybox.net/busybox.git busybox
    if [ ! -d busybox ] ; then
	echo "Failed. ABORTING."
	exit 1
    fi
fi

cd busybox
make O=${BUILDDIR} defconfig
echo "Configuring cross compiler etc..."
# Comment in this line to create a statically linked busybox
#sed -i "s/^#.*CONFIG_STATIC.*/CONFIG_STATIC=y/" ${BUILDDIR}/.config
sed -i -e "s/CONFIG_CROSS_COMPILER_PREFIX=\"\"/CONFIG_CROSS_COMPILER_PREFIX=\"${CC_PREFIX}-\"/g" ${BUILDDIR}/.config
sed -i -e "s/CONFIG_EXTRA_CFLAGS=\"\"/CONFIG_EXTRA_CFLAGS=\"${CFLAGS}\"/g" ${BUILDDIR}/.config
sed -i -e "s/CONFIG_PREFIX=\".*\"/CONFIG_PREFIX=\"..\/stage\"/g" ${BUILDDIR}/.config
# Turn off "eject" command, we don't have a CDROM
sed -i -e "s/CONFIG_EJECT=y/\# CONFIG_EJECT is not set/g" ${BUILDDIR}/.config
sed -i -e "s/CONFIG_FEATURE_EJECT_SCSI=y/\# CONFIG_FEATURE_EJECT_SCSI is not set/g" ${BUILDDIR}/.config
# We need taskset thoug for SMP tests
sed -i -e "s/\# CONFIG_TASKSET is not set/CONFIG_TASKSET=y/g" ${BUILDDIR}/.config
#make O=${BUILDDIR} menuconfig
make O=${BUILDDIR}
make O=${BUILDDIR} install
cd ${CURDIR}

fi

# First the flat library where arch-independent stuff will
# end up
clone_dir ${LIBCBASE}/lib ${STAGEDIR}/lib

# The C library may be in a per-arch subdir (multiarch)
# OR it may not...
if [ -d ${LIBCBASE}/lib/${CC_PREFIX} ] ; then
    mkdir -p ${STAGEDIR}/lib/${CC_PREFIX}
    echo "dir /lib/${CC_PREFIX} 755 0 0" >> filelist-final.txt
    clone_dir ${LIBCBASE}/lib/${CC_PREFIX} ${STAGEDIR}/lib/${CC_PREFIX}
fi

# Add files by searching stage directory
BINFILES=`find ${STAGEDIR}/bin -maxdepth 1 -type f`
for file in ${BINFILES} ; do
    BASE=`basename $file`
    echo "file /bin/${BASE} $file 755 0 0" >> filelist-final.txt
done;
SBINFILES=`find ${STAGEDIR}/sbin -maxdepth 1 -type f`
for file in ${SBINFILES} ; do
    BASE=`basename $file`
    echo "file /sbin/${BASE} $file 755 0 0" >> filelist-final.txt
done;
LIBFILES=`find ${STAGEDIR}/lib -maxdepth 1 -type f`
for file in ${LIBFILES} ; do
    BASE=`basename $file`
    echo "file /lib/${BASE} $file 755 0 0" >> filelist-final.txt
done;
LIBLINKS=`find ${STAGEDIR}/lib -maxdepth 1 -type l`
for file in ${LIBLINKS} ; do
    BASE=`basename $file`
    TARGET=`readlink $file`
    echo "slink /lib/${BASE} ${TARGET} 755 0 0" >> filelist-final.txt
done;

# Add multiarch library dir
if [ -d ${STAGEDIR}/lib/${CC_PREFIX} ] ; then
echo "dir /lib/${CC_PREFIX} 755 0 0" >> filelist-final.txt
CLIBFILES=`find ${STAGEDIR}/lib/${CC_PREFIX} -maxdepth 1 -type f`
for file in ${CLIBFILES} ; do
    BASE=`basename $file`
    echo "file /lib/${CC_PREFIX}/${BASE} $file 755 0 0" >> filelist-final.txt
done;
CLIBLINKS=`find ${STAGEDIR}/lib/${CC_PREFIX} -maxdepth 1 -type l`
for file in ${CLIBLINKS} ; do
    BASE=`basename $file`
    TARGET=`readlink $file`
    echo "slink /lib/${CC_PREFIX}/${BASE} ${TARGET} 755 0 0" >> filelist-final.txt
done;
fi

# Add links by searching stage directory
LINKSBIN=`find ${STAGEDIR}/bin -maxdepth 1 -type l`
for file in ${LINKSBIN} ; do
    BASE=`basename $file`
    TARGET=`readlink $file`
    echo "slink /bin/${BASE} ${TARGET} 755 0 0" >> filelist-final.txt
done;
LINKSSBIN=`find ${STAGEDIR}/sbin -maxdepth 1 -type l`
for file in ${LINKSSBIN} ; do
    BASE=`basename $file`
    TARGET=`readlink $file`
    echo "slink /sbin/${BASE} ${TARGET} 755 0 0" >> filelist-final.txt
done;
LINKSUSRBIN=`find ${STAGEDIR}/usr/bin -maxdepth 1 -type l`
for file in ${LINKSUSRBIN} ; do
    BASE=`basename $file`
    TARGET=`readlink $file`
    echo "slink /usr/bin/${BASE} ${TARGET} 755 0 0" >> filelist-final.txt
done;
LINKSUSRSBIN=`find ${STAGEDIR}/usr/sbin -maxdepth 1 -type l`
for file in ${LINKSUSRSBIN} ; do
    BASE=`basename $file`
    TARGET=`readlink $file`
    echo "slink /sbin/${BASE} ${TARGET} 755 0 0" >> filelist-final.txt
done;

# Trigger all header builds like this
if test ${BUILD_IIOTOOLS} ; then
    BUILD_LINUX_HEADERS=1
fi

if test ${BUILD_LINUX_HEADERS} ; then

if [ -d ${LINUX_TREE} ] ; then
    echo "Building linux headers..."
    if [ -d ${BUILDDIR}/include-linux ] ; then
	rf -rf ${BUILDDIR}/include-linux
    fi
    mkdir -p ${BUILDDIR}/include-linux
    make -C ${LINUX_TREE} headers_install ARCH=${ARCH} INSTALL_HDR_PATH=${BUILDDIR}/include-linux
    if [ ! $? -eq 0 ] ; then
	echo "Build failed!"
	exit 1
    fi
fi

# end of building Linux headers

fi

echo "Compiling fbtest..."
${CC_PREFIX}-gcc ${CFLAGS} -o ${STAGEDIR}/usr/bin/fbtest fbtest/fbtest.c
echo "file /usr/bin/fbtest ${STAGEDIR}/usr/bin/fbtest 755 0 0" >> filelist-final.txt

if test ${BUILD_ALSA} ; then

# Clone the tinyalsa git if we don't have it...
if [ ! -d tinyalsa ] ; then
    echo "It appears we're missing a tinyalsa git, cloning it."
    git clone https://github.com/tinyalsa/tinyalsa.git tinyalsa
    if [ ! -d tinyalsa ] ; then
	echo "Failed. ABORTING."
	exit 1
    fi
fi
echo "Compiling tinyalsa..."
cd tinyalsa
make clean
git checkout Makefile
# Augment CFLAGS in the Makefile!
sed -i -e "s/^CFLAGS =.*$/CFLAGS = ${CFLAGS} -c -fPIC -Wall/g" Makefile
make CROSS_COMPILE=${CC_PREFIX}-
cd ${CURDIR}
echo "file /usr/lib/libtinyalsa.so ${CURDIR}/tinyalsa/libtinyalsa.so 755 0 0" >> filelist-final.txt
echo "file /usr/bin/tinycap ${CURDIR}/tinyalsa/tinycap 755 0 0" >> filelist-final.txt
echo "file /usr/bin/tinymix ${CURDIR}/tinyalsa/tinymix 755 0 0" >> filelist-final.txt
echo "file /usr/bin/tinypcminfo ${CURDIR}/tinyalsa/tinypcminfo 755 0 0" >> filelist-final.txt
echo "file /usr/bin/tinyplay ${CURDIR}/tinyalsa/tinyplay 755 0 0" >> filelist-final.txt
echo "file /usr/share/doriano48_low.wav ${CURDIR}/share/doriano48_low.wav 644 0 0" >> filelist-final.txt

#end of ALSA build
fi

if test ${BUILD_PERF} ; then

if [ -d ${LINUX_TREE}/tools/perf ] ; then
    echo "Building perf..."
    if [ -d ${BUILDDIR}/perf ] ; then
	rf -rf ${BUILDDIR}/perf
    fi
    mkdir -p ${BUILDDIR}/perf
    ARCH=${ARCH} CROSS_COMPILE=${CC_PREFIX}- O=${BUILDDIR}/perf/ \
	NO_NEWT=1 NO_SLANG=1 NO_GTK2=1 NO_LIBPERL=1 NO_LIBPYTHON=1 NO_LIBELF=1 NO_LIBBIONIC=1 \
	LDFLAGS=-static \
	make -C ${LINUX_TREE}/tools/perf
    if [ ! $? -eq 0 ] ; then
	echo "Build failed!"
	exit 1
    fi
    echo "file /usr/bin/perf ${BUILDDIR}/perf/perf 755 0 0" >> filelist-final.txt
fi

# end of perf build
fi

if test ${BUILD_IIOTOOLS} ; then

IIOTOOLS_DIR=${LINUX_TREE}/tools/iio

if [ -d ${IIOTOOLS_DIR} ] ; then
    echo "Building IIO tools..."
    if [ -d ${BUILDDIR}/iiotools ] ; then
	rf -rf ${BUILDDIR}/iiotools
    fi
    mkdir -p ${BUILDDIR}/iiotools
    ARCH=${ARCH} \
	CROSS_COMPILE=${CC_PREFIX}- \
	O=${BUILDDIR}/iiotools \
	CFLAGS="${CFLAGS} -I${BUILDDIR}/include-linux/include" \
	LDFLAGS=-static \
	make -C ${IIOTOOLS_DIR} all
    if [ ! $? -eq 0 ] ; then
	echo "Build failed!"
	exit 1
    fi
    echo "file /usr/bin/lsiio ${IIOTOOLS_DIR}/lsiio 755 0 0" >> filelist-final.txt
    echo "file /usr/bin/generic_buffer ${IIOTOOOLS_DIR}/generic_buffer 755 0 0" >> filelist-final.txt
    echo "file /usr/bin/iio_event_monitor ${IIOTOOLS_DIR}/iio_event_monitor 755 0 0" >> filelist-final.txt
fi

# end of IIO tools build
fi

if test ${BUILD_SELFTEST} ; then

SELFTEST_DIR=${LINUX_TREE}/tools/testing/selftests

if [ -d ${SELFTEST_DIR} ] ; then
    echo "Building selftests..."
    if [ -d ${BUILDDIR}/selftest ] ; then
	rf -rf ${BUILDDIR}/selftest
    fi
    mkdir -p ${BUILDDIR}/selftest
    ARCH=${ARCH} CROSS_COMPILE=${CC_PREFIX}- O=${BUILDDIR}/selftest/ \
	LDFLAGS=-static \
	CFLAGS="${CFLAGS} -I${BUILD_DIR}/include-linux" \
	make -C ${SELFTEST_DIR} all
    if [ ! $? -eq 0 ] ; then
	echo "Build failed!"
	exit 1
    fi
    # echo "file /usr/bin/perf ${BUILDDIR}/perf/perf 755 0 0" >> filelist-final.txt
fi

# end of selftest build
fi

# Extra stuff per platform
case $1 in
    "i486")
	;;
    "i586")
	;;
    "h3600")
	# Splash image for VGA console
	echo "file /etc/splash-320x240.ppm etc/splash-320x240.ppm 644 0 0" >> filelist-final.txt
	;;
    "footbridge")
	;;
    "nslu2")
	;;
    "integrator")
	# Splash image for VGA console
	echo "file /etc/splash.ppm etc/splash-640x480-rgba5551.ppm 644 0 0" >> filelist-final.txt
	;;
    "msm8660")
	;;
    "nhk8815")
	;;
    "pb1176")
	# Splash image for VGA console
	# echo "file /etc/splash.ppm etc/splash-640x480-rgba5551.ppm 644 0 0" >> filelist-final.txt
	;;
    "u300")
	;;
    "ux500")
	;;
    "exynos")
	;;
    "versatile")
	# Splash image for VGA console
	echo "file /etc/splash.ppm etc/splash-640x480-rgba5551.ppm 644 0 0" >> filelist-final.txt
	;;
    "vexpress")
	;;
    "aarch64")
	;;
    *)
	echo "Forgot to update special per-platform rules."
	exit 1
	;;
esac

gen_init_cpio filelist-final.txt > ${HOME}/rootfs.cpio
#rm filelist-final.txt
if [ "$1" == "aarch64"  ] ; then
    gzip ${HOME}/rootfs.cpio
    mv ${HOME}/rootfs.cpio.gz ${OUTFILE}.gz
fi
if [ -f ${HOME}/rootfs.cpio ] ; then
    mv ${HOME}/rootfs.cpio ${OUTFILE}
fi
echo "New rootfs ready in ${OUTFILE}"
