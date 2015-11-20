#!/bin/bash

echo "Generator for a simple initramfs root filesystem for some ARM targets"
CURDIR=`pwd`
STAGEDIR=${CURDIR}/stage
BUILDDIR=${CURDIR}/build

STRACEVER=strace-4.7
STRACE=${CURDIR}/${STRACEVER}
BUILD_BUSYBOX=1
BUILD_LINUX_HEADERS=
BUILD_FBTEST=
BUILD_ALSA=
BUILD_PERF=
BUILD_KSELFTEST=
BUILD_IIOTOOLS=
BUILD_GPIOTOOLS=
BUILD_LIBIIO=
BUILD_TRINITY=
BUILD_LTP=
BUILD_CRASHME=
BUILD_IOZONE=
BUILD_FIO=
# If present, perf will be built and added to the filesystem
LINUX_TREE=${HOME}/linux-gpio

# Helper function to copy one level of files and then one level
# of links from a directory to another directory.
function clone_dir()
{
    local SRCDIR=$1
    local DSTDIR=$2
    local FILES=`find ${SRCDIR} -maxdepth 1 -type f`
    for file in ${FILES} ; do
	local BASE=`basename $file`
	cp $file ${DSTDIR}/${BASE}
	# ${STRIP} -s ${DSTDIR}/${BASE}
    done;
    # Clone links from the toolchain binary library dir
    local LINKS=`find ${SRCDIR} -maxdepth 1 -type l`
    cd ${DSTDIR}
    for file in ${LINKS} ; do
	local BASE=`basename $file`
	local TARGET=`readlink $file`
	ln -s ${TARGET} ${BASE}
    done;
    cd ${CURDIR}
}

function clone_to_cpio()
{
    local SRCDIR=$1
    local TARGETBASE=$2
    echo "dir ${TARGETBASE} 755 0 0" >> filelist-final.txt

    local FILES=`find ${SRCDIR} -maxdepth 1 -type f`
    for file in ${FILES} ; do
	local BASE=`basename $file`
	echo "file ${TARGETBASE}/${BASE} $file 755 0 0" >> filelist-final.txt
    done;
    local DIRS=`find ${SRCDIR} -maxdepth 1 -type d`
    for dir in ${DIRS} ; do
	local BASE=`basename $dir`
	clone_to_cpio ${SRCDIR}/${BASE} ${TARGETBASE}/${BASE}
    done;
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
	BUILD_CRASHME=1
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
	# BUILD_TRINITY=1
	# BUILD_CRASHME=1
	BUILD_IOZONE=1
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
    "pb11mp")
	echo "Building ARM RealView PB11MPCore root filesystem"
	export ARCH=arm
	CC_PREFIX=armv6l
	CC_DIR=/var/linus/cross-compiler-armv6l
	LIBCBASE=${CC_DIR}
	# Notice: no thumb VFP hardfloat on Thumb1
	CFLAGS="-marm -mabi=aapcs-linux -mno-thumb -mno-thumb-interwork -mcpu=mpcore"
	cp etc/inittab-realview etc/inittab
	echo "PB11MPCore" > etc/hostname
	;;
    "u300")
	echo "Building ST-Ericsson U300 root filesystem"
	export ARCH=arm
	CC_PREFIX=armv5l
	CC_DIR=/var/linus/cross-compiler-armv5l
	LIBCBASE=${CC_DIR}
	CFLAGS="-msoft-float -marm -mabi=aapcs-linux -mthumb -mthumb-interwork -march=armv5t -mtune=arm9tdmi"
	BUILD_KSELFTEST=1
	cp etc/inittab-u300 etc/inittab
	echo "U300" > etc/hostname
	;;
    "ux500")
	echo "Building ST-Ericsson Ux500 root filesystem"
	export ARCH=arm
	CC_PREFIX=arm-linux-gnueabihf
	CC_DIR=/var/linus/gcc-linaro-arm-linux-gnueabihf-4.9-2014.09_linux
	# CC_DIR=/var/linus/gcc-linaro-4.9-2015.02-3-x86_64_arm-linux-gnueabihf
	LIBCBASE=${CC_DIR}/${CC_PREFIX}/libc
	CFLAGS="-marm -mabi=aapcs-linux -mthumb -mthumb-interwork -mcpu=cortex-a9"
	# BUILD_ALSA=1
	# BUILD_IIOTOOLS=1
	# BUILD_LIBIIO=
	# BUILD_TRINITY=1
	# BUILD_LTP=1
	# BUILD_CRASHME=1
	# BUILD_IOZONE=1
	# BUILD_KSELFTEST=1
	# BUILD_BUSYBOX=
	BUILD_GPIOTOOLS=1
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
    "simone")
	echo "Building SIM.ONE ARMv4 root filesystem"
	export ARCH=arm
	# Rob's cross compiler
	CC_PREFIX=armv4tl
	CC_DIR=/var/linus/cross-compiler-armv4tl
	LIBCBASE=${CC_DIR}
	CFLAGS="-msoft-float -marm -mabi=aapcs-linux -mthumb -march=armv4t"
	cp etc/inittab-simone etc/inittab
	echo "SIMONE" > etc/hostname
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
	# BUILD_CRASHME=1
	# BUILD_LTP=1
	# BUILD_KSELFTEST=1
	BUILD_BUSYBOX=
	BUILD_FIO=1
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
	#CC_DIR=/var/linus/gcc-linaro-4.9-2015.02-3-x86_64_aarch64-linux-gnu
	LIBCBASE=${CC_DIR}/${CC_PREFIX}/libc
	CFLAGS="-march=armv8-a"
	cp etc/inittab-vexpress etc/inittab
	echo "AARCH64" > etc/hostname
	BUILD_CRASHME=1
	BUILD_LTP=1
	BUILD_IOZONE=1
	;;
    *)
	echo "Usage: $0 [i486|i586|h3600|footbridge|integrator|msm8660|nhk8815|pb1176|u300|ux500|exynos|versatile|vexpress|aarch64]"
	exit 1
	;;
esac

if test "${CC_PREFIX}" = "armv4tl" ; then
    CROSS_HOST="arm-linux-gnu"
else
    CROSS_HOST=${CC_PREFIX}
fi
echo "CROSS_HOST = ${CROSS_HOST}"

# Define more tools
STRIP=${CC_PREFIX}-strip
OUTFILE=${HOME}/rootfs-$1.cpio

echo "OUTFILE = ${OUTFILE}"

echo "Check prerequisites..."
echo "Set up cross compiler at: ${CC_DIR}"
export PATH="${CC_DIR}/bin:${PATH}"
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
mkdir ${STAGEDIR}/etc
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

# We need taskset though for SMP tests
sed -i -e "s/\# CONFIG_TASKSET is not set/CONFIG_TASKSET=y/g" ${BUILDDIR}/.config

# LTP needs a proper bash to run
if test ${BUILD_KSELFTEST} ; then
    sed -i -e "s/\# CONFIG_FEATURE_BASH_IS_ASH is not set/CONFIG_FEATURE_BASH_IS_ASH=y/g" ${BUILDDIR}/.config
    sed -i -e "s/CONFIG_FEATURE_BASH_IS_NONE=y/\# CONFIG_FEATURE_BASH_IS_NONE is not set/g" ${BUILDDIR}/.config
fi

# Enable for manual config
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
if test ${BUILD_FBTEST} ; then
    BUILD_LINUX_HEADERS=1
fi
if test ${BUILD_IIOTOOLS} ; then
    BUILD_LINUX_HEADERS=1
fi
if test ${BUILD_GPIOTOOLS} ; then
    BUILD_LINUX_HEADERS=1
fi
if test ${BUILD_LIBIIO} ; then
    BUILD_LINUX_HEADERS=1
fi
if test ${BUILD_TRINITY} ; then
    BUILD_LINUX_HEADERS=1
fi
if test ${BUILD_LTP} ; then
    BUILD_LINUX_HEADERS=1
fi
if test ${BUILD_CRASHME} ; then
    BUILD_LINUX_HEADERS=1
fi
if test ${BUILD_IOZONE} ; then
    BUILD_LINUX_HEADERS=1
fi
if test ${BUILD_FIO} ; then
    BUILD_LINUX_HEADERS=1
fi

if test ${BUILD_LINUX_HEADERS} ; then

if [ -d ${LINUX_TREE} ] ; then
    echo "Building linux headers..."
    if [ -d ${BUILDDIR}/include-linux ] ; then
	rf -rf ${BUILDDIR}/include-linux
    fi
    mkdir -p ${BUILDDIR}/include-linux
    if test ${ARCH} = aarch64 ; then
	LINUXARCH=arm64
    else
	LINUXARCH=${ARCH}
    fi
    make -C ${LINUX_TREE} headers_install ARCH=${LINUXARCH} INSTALL_HDR_PATH=${BUILDDIR}/include-linux
    if [ ! $? -eq 0 ] ; then
	echo "Build failed!"
	exit 1
    fi
fi

# Now use these includes in subsequent builds
CFLAGS="${CFLAGS} -I${BUILDDIR}/include-linux/include"
echo "New CFLAGS: ${CFLAGS}"

# end of building Linux headers

fi

if test ${BUILD_FBTEST} ; then

echo "Compiling fbtest..."
${CC_PREFIX}-gcc ${CFLAGS} -o ${STAGEDIR}/usr/bin/fbtest fbtest/fbtest.c
echo "file /usr/bin/fbtest ${STAGEDIR}/usr/bin/fbtest 755 0 0" >> filelist-final.txt

# End of building fbtest
fi

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
	make -C ${IIOTOOLS_DIR}
    if [ ! $? -eq 0 ] ; then
	echo "Build failed!"
	exit 1
    fi
    echo "file /usr/bin/lsiio ${IIOTOOLS_DIR}/lsiio 755 0 0" >> filelist-final.txt
    echo "file /usr/bin/generic_buffer ${IIOTOOLS_DIR}/generic_buffer 755 0 0" >> filelist-final.txt
    echo "file /usr/bin/iio_event_monitor ${IIOTOOLS_DIR}/iio_event_monitor 755 0 0" >> filelist-final.txt
fi

# end of IIO tools build
fi

if test ${BUILD_GPIOTOOLS} ; then

GPIOTOOLS_DIR=${LINUX_TREE}/tools/gpio

if [ -d ${GPIOTOOLS_DIR} ] ; then
    echo "Building GPIO tools..."
    if [ -d ${BUILDDIR}/gpiotools ] ; then
	rf -rf ${BUILDDIR}/gpiotools
    fi
    mkdir -p ${BUILDDIR}/gpiotools
    ARCH=${ARCH} \
	CROSS_COMPILE=${CC_PREFIX}- \
	O=${BUILDDIR}/gpiotools \
	CFLAGS="${CFLAGS} -I${BUILDDIR}/include-linux/include" \
	make -C ${GPIOTOOLS_DIR}
    if [ ! $? -eq 0 ] ; then
	echo "Build failed!"
	exit 1
    fi
    echo "file /usr/bin/lsgpio ${GPIOTOOLS_DIR}/lsgpio 755 0 0" >> filelist-final.txt
fi

# end of GPIO tools build
fi

if test ${BUILD_LIBIIO} ; then

if [ ! -d libiio ] ; then
    echo "It appears we're missing a libiio git, cloning it."
    git clone https://github.com/analogdevicesinc/libiio.git
    if [ ! -d libiio ] ; then
	echo "Failed. ABORTING."
	exit 1
    fi
fi

echo "Building libiio..."
cd libiio
cmake ./
echo "ARCH=${ARCH} \
    CROSS_=${CC_PREFIX}- \
    O=${BUILDDIR}/iiotools \
    CFLAGS="${CFLAGS} -I${BUILDDIR}/include-linux/include" \
    make -C ${IIOTOOLS_DIR} all"
if [ ! $? -eq 0 ] ; then
    echo "Build failed!"
    exit 1
fi
#echo "file /usr/bin/lsiio ${IIOTOOLS_DIR}/lsiio 755 0 0" >> filelist-final.txt
#echo "file /usr/bin/generic_buffer ${IIOTOOLS_DIR}/generic_buffer 755 0 0" >> filelist-final.txt
#echo "file /usr/bin/iio_event_monitor ${IIOTOOLS_DIR}/iio_event_monitor 755 0 0" >> filelist-final.txt
# end of libiio build
fi

if test ${BUILD_TRINITY} ; then

if [ ! -d trinity ] ; then
    echo "It appears we're missing a trinity git, cloning it."
    git clone https://github.com/kernelslacker/trinity.git
    if [ ! -d trinity ] ; then
	echo "Failed. ABORTING."
	exit 1
    fi
fi

echo "Building trinity..."
cd trinity
CC=gcc CROSS_COMPILE=${CC_PREFIX}- CFLAGS="$CFLAGS" ./configure.sh
make clean
echo "Cleaned up"
echo "Compiler: ${CC_PREFIX}-gcc ${CFLAGS}"
CC=gcc CROSS_COMPILE=${CC_PREFIX}- CROSS_CFLAGS="${CFLAGS}" make all
if [ ! $? -eq 0 ] ; then
    echo "Trinity build failed!"
    exit 1
fi
cd ${CURDIR}
echo "file /usr/bin/trinity ${CURDIR}/trinity/trinity 755 0 0" >> filelist-final.txt
# end of trinity build
fi

if test ${BUILD_LTP} ; then

if [ ! -d ltp ] ; then
    echo "It appears we're missing an LTP git, cloning it."
    git clone https://github.com/linux-test-project/ltp.git
    if [ ! -d ltp ] ; then
	echo "Failed. ABORTING."
	exit 1
    fi
fi

echo "Building LTP..."
cd ltp
make autotools
mkdir -p ${BUILDDIR}/ltp
cd ${BUILDDIR}/ltp
${CURDIR}/ltp/configure CC=${CC_PREFIX}-gcc CFLAGS="$CFLAGS" --build x86_64 --host=${CROSS_HOST}
cd ${CURDIR}/ltp
#cp include/config.h.default ${BUILDDIR}/ltp/include/config.h
#cp include/mk/config.mk.default ${BUILDDIR}/ltp/include/mk/config.mk
#cp include/mk/features.mk.default ${BUILDDIR}/ltp/include/mk/features.mk
make \
    -C ${BUILDDIR}/ltp \
    -f ${CURDIR}/ltp/Makefile \
    top_srcdir=${CURDIR}/ltp \
    top_builddir=${BUILDDIR}/ltp
if [ ! $? -eq 0 ] ; then
    echo "LTP build failed!"
    exit 1
fi
make \
    -C ${BUILDDIR}/ltp \
    -f ${CURDIR}/ltp/Makefile \
    top_srcdir=${CURDIR}/ltp \
    top_builddir=${BUILDDIR}/ltp \
    DESTDIR=${STAGEDIR} \
    install
cd ${CURDIR}
clone_to_cpio ${STAGEDIR}/opt/ltp /opt/ltp
# end of LTP build
fi

if test ${BUILD_CRASHME} ; then
echo "Building Crashme..."
cd crashme-2.8.5
make clean
make CC=${CC_PREFIX}-gcc CFLAGS="${CFLAGS}"
cd ${CURDIR}
echo "file /usr/bin/crashme ${CURDIR}/crashme-2.8.5/crashme 755 0 0" >> filelist-final.txt
# end of Crashme build
fi

if test ${BUILD_FIO} ; then

echo "Building fio..."
FIO_DIR=${CURDIR}/fio

if [ ! -d ${FIO_DIR} ] ; then
    echo "It appears we're missing a FIO git, cloning it."
    cd ${CURDIR}
    git clone https://github.com/axboe/fio.git
    if [ ! -d fio ] ; then
	echo "Failed. ABORTING."
	exit 1
    fi
fi

cd ${FIO_DIR}
git checkout configure
make clean
rm *.o
mkdir -p ${STAGEDIR}/fio
./configure --prefix=${STAGEDIR}/fio --cc=${CC_PREFIX}-gcc --extra-cflags="${CFLAGS}"
make
if [ ! $? -eq 0 ] ; then
    echo "Build failed!"
    exit 1
fi

cd ${CURDIR}
echo "file /usr/bin/fio ${FIO_DIR}/fio 755 0 0" >> filelist-final.txt
# end of iozone build
fi

if test ${BUILD_IOZONE} ; then

echo "Building iozone..."
IOZONE_DIR=${CURDIR}/iozone3_430/src/current

if [ ! -d ${IOZONE_DIR} ] ; then
    echo "It appears we're missing the iozone dir, fix it."
    exit 1
fi

cd ${IOZONE_DIR}
rm *.o
CC=${CC_PREFIX}-gcc GCC=${CC_PREFIX}-gcc CFLAGS="${CFLAGS}" LDFLAGS="${CFLAGS}" make -f makefile linux-arm
if [ ! $? -eq 0 ] ; then
    echo "Build failed!"
    exit 1
fi

cd ${CURDIR}
echo "file /usr/bin/iozone ${IOZONE_DIR}/iozone 755 0 0" >> filelist-final.txt
# end of fio build
fi

if test ${BUILD_KSELFTEST} ; then

SELFTEST_DIR=${LINUX_TREE}/tools/testing/selftests

if [ -d ${SELFTEST_DIR} ] ; then
    echo "Building selftests..."
    if [ -d ${BUILDDIR}/kselftest ] ; then
	rf -rf ${BUILDDIR}/kselftest
    fi
    mkdir -p ${BUILDDIR}/kselftest
    ARCH=${ARCH} CROSS_COMPILE=${CC_PREFIX}- O=${BUILDDIR}/kselftest/ \
	LDFLAGS=-static \
	CFLAGS="${CFLAGS} -I${BUILD_DIR}/include-linux" \
	make -C ${SELFTEST_DIR} all
    if [ ! $? -eq 0 ] ; then
	echo "Build failed!"
	exit 1
    fi
    mkdir -p ${STAGEDIR}/kselftest
    INSTALL_PATH=${STAGEDIR}/opt/kselftest \
		make -C ${SELFTEST_DIR} install
    # We don't need x86 tests
    if [ -d ${STAGEDIR}/opt/kselftest/x86 ] ; then
	rm -rf ${STAGEDIR}/opt/kselftest/x86
    fi
    clone_to_cpio ${STAGEDIR}/opt/kselftest /opt/kselftest
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
	echo "640x480-60-rgba5551" > ${STAGEDIR}/etc/vgamode
	echo "file /etc/vgamode ${STAGEDIR}/etc/vgamode 644 0 0" >> filelist-final.txt
	echo "file /etc/splash.ppm etc/splash-640x480.ppm 644 0 0" >> filelist-final.txt
	;;
    "msm8660")
	;;
    "nhk8815")
	;;
    "pb1176")
	# Splash image for VGA console
	# echo "file /etc/splash.ppm etc/splash-640x480-rgba5551.ppm 644 0 0" >> filelist-final.txt
	;;
    "pb11mp")
	;;
    "u300")
	;;
    "ux500")
	;;
    "exynos")
	;;
    "simone")
	echo "file /etc/init.d/simone-ledheart etc/init.d/simone-ledheart 755 0 0" >> filelist-final.txt
	echo "slink /etc/rc.d/S10_simone-ledheart /etc/init.d/simone-ledheart 755 0 0" >> filelist-final.txt
	# Splash image for VGA console
	echo "640x480-60-rgb565" > ${STAGEDIR}/etc/vgamode
	echo "file /etc/vgamode ${STAGEDIR}/etc/vgamode 644 0 0" >> filelist-final.txt
	echo "file /etc/splash.ppm etc/splash-640x480.ppm 644 0 0" >> filelist-final.txt
	;;
    "versatile")
	# Splash image for VGA console
	echo "640x480-60-rgba5551" > ${STAGEDIR}/etc/vgamode
	echo "file /etc/vgamode ${STAGEDIR}/etc/vgamode 644 0 0" >> filelist-final.txt
	echo "file /etc/splash.ppm etc/splash-640x480.ppm 644 0 0" >> filelist-final.txt
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
if [ "$1" == "aarch64" ] ; then
    # This one if for attaching to a kernel as initramfs
    cp ${HOME}/rootfs.cpio ${OUTFILE}
    # This one is for initramfs yada yada
    gzip ${HOME}/rootfs.cpio
    mv ${HOME}/rootfs.cpio.gz ${OUTFILE}.gz
elif [ -f ${HOME}/rootfs.cpio ] ; then
    mv ${HOME}/rootfs.cpio ${OUTFILE}
fi
echo "New rootfs ready in ${OUTFILE}"
