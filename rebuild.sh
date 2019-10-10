#!/bin/sh
export HOST_TRIPLET=x86_64-linux-gnu
export HOST_TAG=linux-x86_64

export PYMAJOR=3
export PYMINOR=7
export PYVER=3.7.5rc1
PYTHON3_HASH=6b9707901204a2ab87236a03e3ec5d060318cb988df6307f4468d307b17948e5

#OPENSSL_VERSION="1.1.1d"
#OPENSSL_HASH=1e3a91bc1f9dfce01af26026f856e064eab4c8ee0a8f457b5ae30b40b8b711f2

export OPENSSL_VERSION="1.0.2t"
OPENSSL_HASH=14cb464efe7ac6b54799b34456bd69558a749a4931ecfd9cf9f71d7881cac7bc

LIBFFI_HASH=403d67aabf1c05157855ea2b1d9950263fb6316536c8c333f5b9ab1eb2f20ecf
BZ2_HASH=ab5a03176ee106d3f0fa90e381da478ddae405918153cca248e682cd0c4a2269

# above are the defaults, can be overridden via CONFIG

if [ -f "CONFIG" ]
then
pwd
    . $(pwd)/CONFIG
fi

# optionnal urls for sources packages
if [ -f "CACHE_URL" ]
then
    . $(pwd)/CACHE_URL
else
    LIBFFI_URL="https://github.com/libffi/libffi/releases/download/v3.3-rc0/libffi-3.3-rc0.tar.gz"
    OPENSSL_URL="https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz"
    BZ2_URL="https://sourceware.org/pub/bzip2/bzip2-1.0.8.tar.gz"
    PYTHON3_URL="https://github.com/python/cpython/archive/v${PYVER}.tar.gz"
fi


export NDK_HOME=${NDK_HOME:-$(pwd)/android-sdk/ndk-bundle}
export DN=org.beeware
export APP=small


if grep "^Pkg.Revision = 20" $NDK_HOME/source.properties
then
    echo NDK found
else
    echo Only NDK 20 has been tested and is expected to be found in NDK_HOME=$NDK_HOME
    read cont
fi

OLD_PATH=$PATH

ORIGIN=$(pwd)
ROOT="${ORIGIN}/beeware"
BUILD_PREFIX="${ROOT}/build"
BUILD=${BUILD_PREFIX}-src

PYSRC="${BUILD}/python3-prefix/src/python3"
export PYDROID="${BUILD}/python3-android"

export APK=/data/data/${DN}.${APP}

export PYTHONDONTWRITEBYTECODE=1

for py in 8 7 6 5
do
    if which python3.${py}
    then
        export PYTHON=$(which python3.${py})
        break
    fi
done


if [ -d beeware ]
then
    echo " * using previous build dir ${ROOT}"
    cd ${ROOT}

else
    echo " * create venv ${ROOT}"
    $PYTHON -m venv beeware --prompt beeware-python-build
    cd ${ROOT}
    touch new_env
fi

. bin/activate

cd ${ROOT}

mkdir -p ${BUILD}

date > ${BUILD}/build.log
env >> ${BUILD}/build.log
echo  >> ${BUILD}/build.log
echo  >> ${BUILD}/build.log


if [ -f new_env ]
then

    if pip install scikit-build
    then
        if pip install cmake==3.10.3
        then
            rm new_env
        fi
    fi
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





# == create a fake cmake project for the purpose of downloading sources and building host python


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
    bz2
    URL ${BZ2_URL}
    URL_HASH SHA256=${BZ2_HASH}

    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ""
)

ExternalProject_Add(
    openssl
    URL ${OPENSSL_URL}
    URL_HASH SHA256=${OPENSSL_HASH}

    PATCH_COMMAND patch -p1 < ${ORIGIN}/patch/openssl-${OPENSSL_VERSION}/Configure.diff
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ""
)

ExternalProject_Add(
    libffi
    URL ${LIBFFI_URL}
    URL_HASH SHA256=${LIBFFI_HASH}

    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ""
)

ExternalProject_Add(
    python3
    DEPENDS openssl
    DEPENDS libffi
    DEPENDS bz2
    #GIT_REPOSITORY https://github.com/python/cpython.git
    #GIT_TAG 4082f600a5bd69c8f4a36111fa5eb197d7547756 # 3.7.5rc1

    URL ${PYTHON3_URL}
    URL_HASH SHA256=${PYTHON3_HASH}

    PATCH_COMMAND sh -c "/bin/cp -aRfxp ${PYSRC} ${PYDROID}"

    CONFIGURE_COMMAND sh -c "cd ${PYSRC} && CC=clang ./configure --prefix=${ROOT}/python3.host --with-cxx-main=clang --disable-ipv6 --without-ensurepip --with-c-locale-coercion --disable-shared >/dev/null"

    BUILD_COMMAND sh -c "cd ${PYSRC} && make"

    INSTALL_COMMAND sh -c "cd ${PYSRC} && make install >/dev/null 2>&1"
)


END

    cd ${BUILD}
    cmake ..
    make && make install

fi



# == can't save space - patching an existing source tree after a cleanup - because we may need a full sourcetree+host python too
cd ${PYDROID}

if [ -f Patched ]
then
    echo " * Python-${PYVER} tree already patched"
else
    for PATCH in ${ORIGIN}/patch/Python-${PYVER}/*.diff
    do
        echo " * applying ${PATCH}"
        patch -p1 < ${PATCH}
    done
    touch Patched
    #echo "All patches applied, press enter"
    #read cont
fi

cd ${ROOT}



Building () {
    cd ${BUILD_PREFIX}-${TARGET_ARCH_ABI}

    echo " * configure target==$1 ${PLATFORM_TRIPLET}"

    mkdir -p $1-${TARGET_ARCH_ABI}
    cd $1-${TARGET_ARCH_ABI}
    /bin/cp -aRfxp ${BUILD}/$1-prefix/src/$1/. ./

}




for TARGET_ARCH_ABI in armeabi-v7a arm64-v8a x86 x86-64
do
    unset NDK_PREFIX
    export PREBUILT=${ROOT}/prebuilt-${TARGET_ARCH_ABI}

    export TOOLCHAIN=$NDK_HOME/toolchains/llvm/prebuilt/$HOST_TAG

    mkdir -p ${BUILD_PREFIX}-${TARGET_ARCH_ABI}
    cd ${BUILD_PREFIX}-${TARGET_ARCH_ABI}

    case "$TARGET_ARCH_ABI" in
        armeabi-v7a)
            PLATFORM_TRIPLET=armv7a-linux-androideabi
            API=19
            BITS=32
            export NDK_PREFIX="arm-linux-androideabi"
            ;;
        arm64-v8a)
            PLATFORM_TRIPLET=aarch64-linux-android
            API=21
            BITS=64
            ;;
        x86)
            PLATFORM_TRIPLET=i686-linux-android
            API=19
            BITS=32
            ;;
        x86-64)
            PLATFORM_TRIPLET=x86_64-linux-android
            API=21
            BITS=64
            ;;
    esac

    export CC=$TOOLCHAIN/bin/${PLATFORM_TRIPLET}${API}-clang
    export CXX=$TOOLCHAIN/bin/${PLATFORM_TRIPLET}${API}-clang++

    BUILD_TYPE=$PLATFORM_TRIPLET

    if echo $NDK_PREFIX|grep -q abi
    then
        PLATFORM_TRIPLET=$NDK_PREFIX
    else
        NDK_PREFIX=$PLATFORM_TRIPLET
    fi

    export LD=$TOOLCHAIN/bin/${NDK_PREFIX}-ld
    export READELF=$TOOLCHAIN/bin/${NDK_PREFIX}-readelf
    export AR=$TOOLCHAIN/bin/${NDK_PREFIX}-ar
    export AS=$TOOLCHAIN/bin/${NDK_PREFIX}-as
    export RANLIB=$TOOLCHAIN/bin/${NDK_PREFIX}-ranlib
    export STRIP=$TOOLCHAIN/bin/${NDK_PREFIX}-strip

    # eventually restore full PLATFORM_TRIPLET
    export PLATFORM_TRIPLET=$BUILD_TYPE


    # that env file can be handy for debugging compile failures.

    cat > $ROOT/${TARGET_ARCH_ABI}.sh <<END
#!/bin/sh
export STRIP=$STRIP
export READELF=$READELF
export AR=$AR
export AS=$AS
export LD=$LD
export CXX=$CXX
export CC=$CC
export RANLIB=$RANLIB

export PATH=/bin:/usr/bin:/usr/local/bin

END

    # == building bzip2

    if [ -f ${PREBUILT}/lib/libbz2.a ]
    then
        echo "    -> libbz2 already built for $ABI"
    else
        Building bz2

        make CC=$CC AR=$AR RANLIB=$RANLIB PREFIX=${PREBUILT} bzip2 install
    fi



    # == building libffi

    if [ -f ${PREBUILT}/lib/libffi.a ]
    then
        echo "    -> libffi already built for $ABI"
    else
        Building libffi

        export CFLAGS="-m${BITS} -fPIC -Wno-multichar -funwind-tables -target ${PLATFORM_TRIPLET}${API} -isysroot $TOOLCHAIN/sysroot -isystem $TOOLCHAIN/sysroot/usr/include"
        #env |grep TRIPLE
        #read cont
        if ./configure --target=${PLATFORM_TRIPLET} --host=${PLATFORM_TRIPLET} --build=${HOST_TRIPLET} --prefix=${PREBUILT} && make && make install
        then
            echo "done"
        else
            break
        fi
    fi


    # == building openssl

    # poc https://github.com/ph4r05/android-openssl

    if [ -f  ${PREBUILT}/lib/libssl.a ]
    then
        echo "    -> openssl-${OPENSSL_VERSION} already built for $ABI"
    else
        Building openssl
        unset CFLAGS
        # no-ssl2 no-ssl3 no-comp
        CROSS_COMPILE="" ./Configure android shared no-hw --prefix=${PREBUILT} && CROSS_COMPILE="" make depend && CROSS_COMPILE="" make install
        ln -sf . lib
    fi

    #export SSL=${BUILD_PREFIX}-${TARGET_ARCH_ABI}/openssl-${TARGET_ARCH_ABI}




    # == building cpython


    if [ -f ${PREBUILT}/lib/libpython${PYMAJOR}.${PYMINOR}.a ]
    then

        echo "    -> python3 already built for $ABI"

    else
        cd ${BUILD_PREFIX}-${TARGET_ARCH_ABI}

        mkdir -p python3-${TARGET_ARCH_ABI}
        cd python3-${TARGET_ARCH_ABI}

        _PYTHON_PROJECT_SRC=${PYDROID}
        _PYTHON_PROJECT_BASE=$(pwd)

    #for arm: ac_cv_mixed_endian_double=yes
    # ac_cv_little_endian_double=yes

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

ac_cv_header_uuid_h=no
ac_cv_header_uuid_uuid_h=no
END

mkdir -p Modules
cat <<END > Modules/Setup.local
*static*

_struct _struct.c   # binary structure packing/unpacking
_sre _sre.c             # Fredrik Lundh's new regular expressions
_datetime _datetimemodule.c # datetime accelerator
_codecs _codecsmodule.c         # access to the builtin codecs and codec registry
_weakref _weakref.c         # weak references

array arraymodule.c # array objects
cmath cmathmodule.c _math.c # -lm # complex math library functions
math mathmodule.c _math.c # -lm # math library functions, e.g. sin()
_contextvars _contextvarsmodule.c
_struct _struct.c   # binary structure packing/unpacking
_weakref _weakref.c
time timemodule.c # -lm # time operations and variables
_operator _operator.c   # operator.add() and similar goodies
_random _randommodule.c # Random number generator
_collections _collectionsmodule.c # Container types
_functools _functoolsmodule.c   # Tools for working with functions and callable objects
itertools itertoolsmodule.c    # Functions creating iterators for efficient looping
_bisect _bisectmodule.c # Bisection algorithms
_json _json.c
binascii binascii.c
#asyncio req
select selectmodule.c
fcntl fcntlmodule.c
_sha1 sha1module.c
_sha256 sha256module.c
_sha512 sha512module.c
_md5 md5module.c
#
termios termios.c
_sha3 _sha3/sha3module.c
_blake2 _blake2/blake2module.c _blake2/blake2b_impl.c _blake2/blake2s_impl.c
#aiohttp
unicodedata unicodedata.c
zlib zlibmodule.c -DUSE_ZLIB_CRC32 -lz
#future_builtins future_builtins.c

_heapq _heapqmodule.c   # Heap queue algorithm
_pickle _pickle.c   # pickle accelerator
_posixsubprocess _posixsubprocess.c  # POSIX subprocess module helper

_socket socketmodule.c

_bz2 _bz2module.c -I$PREBUILT/include $PREBUILT/lib/libbz2.a

_ssl _ssl.c -DUSE_SSL -I${PREBUILT}/include ${PREBUILT}/lib/libssl.a ${PREBUILT}/lib/libcrypto.a

_elementtree -I${PYDROID}/Modules/expat -DHAVE_EXPAT_CONFIG_H -DUSE_PYEXPAT_CAPI _elementtree.c # elementtree accelerator

_ctypes _ctypes/_ctypes.c \
 _ctypes/callbacks.c \
 _ctypes/callproc.c \
 _ctypes/stgdict.c \
 _ctypes/cfield.c -I${PYDROID}/Modules/_ctypes -I$PREBUILT/include $PREBUILT/lib/libffi.a

_decimal _decimal/_decimal.c \
 _decimal/libmpdec/basearith.c \
 _decimal/libmpdec/constants.c \
 _decimal/libmpdec/context.c \
 _decimal/libmpdec/convolute.c \
 _decimal/libmpdec/crt.c \
 _decimal/libmpdec/difradix2.c \
 _decimal/libmpdec/fnt.c \
 _decimal/libmpdec/fourstep.c \
 _decimal/libmpdec/io.c \
 _decimal/libmpdec/memory.c \
 _decimal/libmpdec/mpdecimal.c \
 _decimal/libmpdec/numbertheory.c \
 _decimal/libmpdec/sixstep.c \
 _decimal/libmpdec/transpose.c \
 -DCONFIG_${BITS} -DANSI -I${PYDROID}/Modules/_decimal/libmpdec

END

        echo " * configure target==python $PLATFORM_TRIPLET"


        PYOPTS="--without-gcc --disable-ipv6 --without-ensurepip --with-c-locale-coercion --without-pymalloc --disable-shared --with-computed-gotos"

        [ -f Makefile ] && make clean && rm Makefile

        #cp -vf $PYSRC/python $PYDROID/host_python

        export CFLAGS="-m${BITS} -fPIC -Wno-multichar -funwind-tables -target ${PLATFORM_TRIPLET}${API} -isysroot $TOOLCHAIN/sysroot -isystem $TOOLCHAIN/sysroot/usr/include"



        cp $ROOT/${TARGET_ARCH_ABI}.sh ./build.sh

        cat >> ./build.sh <<END

export _PYTHON_PROJECT_SRC=${PYDROID}
export _PYTHON_PROJECT_BASE=$(pwd)

PKG_CONFIG_PATH=${PREBUILT}/lib/pkgconfig \\
PLATFORM_TRIPLET=${PLATFORM_TRIPLET} \\
CONFIG_SITE=config.site \\
 CFLAGS="$CFLAGS" \\
 \${_PYTHON_PROJECT_SRC}/configure --with-libs='-lz -lm' --with-openssl=${PREBUILT} --host=${PLATFORM_TRIPLET} --build=${HOST_TRIPLET} --prefix=${PREBUILT} $PYOPTS 2>&1 >> ${BUILD}/build.log

if [ -f Makefile ]
then
    TERM=linux reset
    > \${_PYTHON_PROJECT_SRC}/Lib/compileall.py
    make install
else
    echo ================== ${BUILD}/build.log ===================
    tail -n 30 ${BUILD}/build.log
    echo "Configuration failed for $PLATFORM_TRIPLET"
    env
fi
END

        # need a very clean env for true reproducibility

        env -i sh build.sh

    fi

    #break
done



