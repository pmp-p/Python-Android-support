#!/bin/sh

export OPENSSL_VERSION="1.0.2t"
export OPENSSL_HASH=14cb464efe7ac6b54799b34456bd69558a749a4931ecfd9cf9f71d7881cac7bc

export SRC=Python-3.7.5rc1
export NDK_HOME=${NDK_HOME:-$(pwd)/android-ndk-r20}
export DN=org.beeware
export APP=small

if grep "^Pkg.Revision = 20" $NDK_HOME/source.properties
then
    echo NDK found
else
    echo Only NDK 20 has been tested and is expected to be found in NDK_HOME=$NDK_HOME
    read continue
fi


ORIGIN=$(pwd)
ROOT="${ORIGIN}/beeware"
BUILD="${ROOT}/build"
PYSRC="${BUILD}/python3-prefix/src/python3"
PYDROID="${BUILD}/python3-android"


#export APK=/data/data/${DN}.${APP}
export APK=${ROOT}/prebuilt/$ABI

export PYTHONDONTWRITEBYTECODE=1

for py in 8 7 6
do
    if which python3.${py}
    then
        export PYTHON=python3.${py}
        break
    fi
done

if [ -d beeware ]
then
    echo " * using previous build dir ${ORIGIN}/beeware"
else
    $PYTHON -m venv beeware --prompt beeware-python-build

    cd beeware
    . bin/activate


    pip install scikit-build
    pip install cmake==3.10.3

    # == create a skeleton for a minimal application with a gradle build system.

    # apk will live in /data/data/$DN.$APP on device


    mkdir $DN.$APP/src/main -p
cat > $DN.$APP/src/main/AndroidManifest.xml  <<END
    <?xml version="1.0" encoding="utf-8"?>
    <manifest xmlns:android="http://schemas.android.com/apk/res/android"
        package="$DN.$APP">
        <application android:label="Minimal">
            <activity android:name="MainActivity">
                <intent-filter>
                    <action android:name="android.intent.action.MAIN" />
                    <category android:name="android.intent.category.LAUNCHER" />
                </intent-filter>
            </activity>
        </application>
    </manifest>
END
fi




# == create a fake cmake project for the purpose of download cpython source and building host python



cd "${ROOT}"


if [ -f CMakeLists.txt ]
then
    echo " * using previous CMakeLists.txt in $(pwd)"
else

cat > CMakeLists.txt <<END

cmake_minimum_required(VERSION 3.10.2)

project(beeware)

include(ExternalProject)

ExternalProject_Add(
    openssl
    #URL https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz
    URL http://192.168.1.66/cfake/openssl-${OPENSSL_VERSION}.tar.gz
    URL_HASH SHA256=${OPENSSL_HASH}

    PATCH_COMMAND patch -p1 < ${ORIGIN}/patch/openssl-${OPENSSL_VERSION}/Configure.diff
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ""
)

ExternalProject_Add(
    python3
    DEPENDS openssl

    #GIT_REPOSITORY https://github.com/python/cpython.git
    #GIT_TAG 4082f600a5bd69c8f4a36111fa5eb197d7547756 # 3.7.5rc1
    #URL https://github.com/python/cpython/archive/v3.7.5rc1.tar.gz

    URL http://192.168.1.66/cfake/v3.7.5rc1.tar.gz
    URL_HASH SHA256=6b9707901204a2ab87236a03e3ec5d060318cb988df6307f4468d307b17948e5

    CONFIGURE_COMMAND sh -c "cd ${PYSRC} && CC=clang ./configure --prefix=${ROOT}/python3.host --with-cxx-main=clang --disable-ipv6 --without-ensurepip --with-c-locale-coercion --disable-shared >/dev/null"

    BUILD_COMMAND sh -c "cd ${PYSRC} && make"

    INSTALL_COMMAND sh -c "cd ${PYSRC} && make install >/dev/null 2>&1 && /bin/cp -aRfxp ${PYSRC} ${PYDROID} "
)


END

    rm -rf build

    mkdir -p build
    cd build
    cmake ..
    make && make install

fi

export HOST_TAG=linux-x86_64


#export PYTHONHOME=${BUILD}/python3.host

#export HOSTPYTHON=${BUILD}/python3.host/bin/python3
export HOSTPYTHON=${PYSRC}/python

#note that this one must be a executable from a source tree, not an installed one.
export PYTHON_FOR_BUILD=${PYSRC}/python
export CROSS_COMPILE=yes



# == can't save space - patching an existing source tree after a cleanup - because we need a full sourcetree+host python too
cd ${PYDROID}

[ -f Makefile ] && make clean

if [ -f Patched ]
then
    echo " * ${SRC} tree already patched"
else
    for PATCH in ${ORIGIN}/patch/${SRC}/*.diff
    do
        patch -p1 < ${PATCH}
    done
    touch Patched
fi

cd ${ROOT}

export API=19


for ABI in armeabi-v7a arm64-v8a x86 x86-64
do
    unset NDK_PREFIX

    export TOOLCHAIN=$NDK_HOME/toolchains/llvm/prebuilt/$HOST_TAG

    case "$ABI" in
        armeabi-v7a)
            TRIPLE=armv7a-linux-androideabi
            _PYTHON_HOST_PLATFORM=linux-arm
            export NDK_PREFIX="arm-linux-androideabi"
            ;;
        arm64-v8a)
            TRIPLE=aarch64-linux-android
            _PYTHON_HOST_PLATFORM=linux-arm64
            ;;
        x86)
            TRIPLE=i686-linux-android
            _PYTHON_HOST_PLATFORM=linux-x86
            ;;
        x86-64)
            TRIPLE=x86_64-linux-android
            _PYTHON_HOST_PLATFORM=linux-x86_64
            ;;
    esac


    export CC=$TOOLCHAIN/bin/${TRIPLE}${API}-clang
    export CXX=$TOOLCHAIN/bin/${TRIPLE}${API}-clang++


    export CFLAGS="-target ${TRIPLE}${API} -isysroot $TOOLCHAIN/sysroot -isystem $TOOLCHAIN/sysroot/usr/include"
    export CFLAGS="$CFLAGS -Wno-multichar -funwind-tables"

    export BUILD_TYPE=$TRIPLE

    if echo $NDK_PREFIX|grep -q abi
    then
        TRIPLE=$NDK_PREFIX
    else
        NDK_PREFIX=$TRIPLE
    fi

    export LD=$TOOLCHAIN/bin/${NDK_PREFIX}-ld
    export READELF=$TOOLCHAIN/bin/${NDK_PREFIX}-readelf
    export AR=$TOOLCHAIN/bin/${NDK_PREFIX}-ar
    export AS=$TOOLCHAIN/bin/${NDK_PREFIX}-as
    export RANLIB=$TOOLCHAIN/bin/${NDK_PREFIX}-ranlib
    export STRIP=$TOOLCHAIN/bin/${NDK_PREFIX}-strip

    # eventually restore full triple
    export TRIPLE=$BUILD_TYPE

    # == building openssl
    echo " * configure target==openssl $TRIPLE"
    mkdir -p openssl-${ABI}
    cd openssl-${ABI}
    /bin/cp -aRfxp ${BUILD}/openssl-prefix/src/openssl/. ./
    CROSS_COMPILE="" ./Configure android shared no-ssl2 no-ssl3 no-comp no-hw && CROSS_COMPILE="" make depend && CROSS_COMPILE="" make

    # == building cpython
if false
then
    mkdir -p python3-${ABI}
    cd python3-${ABI}

cat >config.site <<END
ac_cv_little_endian_double=yes
ac_cv_file__dev_ptmx=yes
ac_cv_file__dev_ptc=no


ac_cv_func_pwrite=no
ac_cv_func_pwritev=no
ac_cv_func_pwritev2=no


ac_cv_lib_util_forkpty=no

ac_cv_func_getspnam=no
ac_cv_func_getspent=no
ac_cv_func_getgrouplist=no
END

    export CONFIG_SITE='config.site'
    # --with-system-ffi
    PYOPTS="--without-gcc --disable-ipv6 --without-ensurepip --with-c-locale-coercion --without-pymalloc --disable-shared --with-computed-gotos"
    echo " * configure target==python $TRIPLE"
    if ${PYDROID}/configure --host=${TRIPLE} --build=x86_64-pc-linux-gnu --prefix=$APK $PYOPTS >/dev/null 2>&1
    then
        reset
        > Lib/compileall.py
        make _PYTHON_HOST_PLATFORM=$_PYTHON_HOST_PLATFORM install
    else
        echo "Configuration failed for $TRIPLE"
        env|grep $TOOLCHAIN
    fi

fi

    break
done



