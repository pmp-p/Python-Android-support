#!/bin/sh
export HOST_TRIPLET=x86_64-linux-gnu
export HOST_TAG=linux-x86_64
export ENV=aosp

export ARCHITECTURES="armeabi-v7a arm64-v8a x86 x86_64"


export ANDROID_HOME=${ANDROID_HOME:-$(pwd)/android-sdk}
export NDK_HOME=${NDK_HOME:-${ANDROID_HOME}/ndk-bundle}
export DN=org.${DN}

export PYMAJOR=3

if true
then
    export PYMINOR=7
    export PYVER=3.${PYMINOR}.5
    PYTHON3_HASH=349ac7b4a9d399302542163fdf5496e1c9d1e5d876a4de771eec5acde76a1f8a

    export OPENSSL_VERSION="1.0.2t"
    OPENSSL_HASH=14cb464efe7ac6b54799b34456bd69558a749a4931ecfd9cf9f71d7881cac7bc
else
    export PYMINOR=8
    export PYVER=3.8.0
    PYTHON3_HASH=fc00204447b553c2dd7495929411f567cc480be00c49b11a14aee7ea18750981

    export OPENSSL_VERSION="1.1.1d"
    OPENSSL_HASH=1e3a91bc1f9dfce01af26026f856e064eab4c8ee0a8f457b5ae30b40b8b711f2
fi

export LIBPYTHON=libpython${PYMAJOR}.${PYMINOR}.so


LIBFFI_HASH=403d67aabf1c05157855ea2b1d9950263fb6316536c8c333f5b9ab1eb2f20ecf
BZ2_HASH=ab5a03176ee106d3f0fa90e381da478ddae405918153cca248e682cd0c4a2269
PATCHELF_HASH=b3cb6bdedcef5607ce34a350cf0b182eb979f8f7bc31eae55a93a70a3f020d13
LZMA_HASH=3313fd2a95f43d88e44264e6b015e7d03053e681860b0d5d3f9baca79c57b7bf
SQLITE_HASH=8c5a50db089bd2a1b08dbc5b00d2027602ca7ff238ba7658fabca454d4298e60

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
    PATCHELF_URL="https://github.com/NixOS/patchelf/archive/0.10.tar.gz"
    LZMA_URL="https://tukaani.org/xz/xz-5.2.4.tar.bz2"
    SQLITE_URL="https://www.sqlite.org/2019/sqlite-autoconf-3300100.tar.gz"
fi


if grep "^Pkg.Revision = 20" $NDK_HOME/source.properties
then
    echo NDK 20+ found
else
    echo "
WARNING:

Only NDK 20 has been tested and is expected to be found in :
   NDK_HOME=$NDK_HOME or ANDROID_HOME=${ANDROID_HOME} + ndk-bundle

press enter to continue anyway
"
    read cont
fi

OLD_PATH=$PATH

ORIGIN=$(pwd)
ROOT="${ORIGIN}/${ENV}"
HOST="${ORIGIN}/${ENV}/host"
BUILD_PREFIX="${ROOT}/build"
BUILD_SRC=${ROOT}/src


PYSRC="${BUILD_SRC}/python3-prefix/src/python3"
PATCHELF_SRC="${BUILD_SRC}/patchelf-prefix/src/patchelf"
ADBFS_SRC="${BUILD_SRC}/adbfs-prefix/src/adbfs"
LZMA_SRC="${BUILD_SRC}/lzma-prefix/src/lzma"

export PYDROID="${BUILD_SRC}/python3-android"

export APK=/data/data/${DN}.${APP}

export PYTHONDONTWRITEBYTECODE=1

for py in 8 7 6 5
do
    if command -v python3.${py}
    then
        export PYTHON=$(command -v python3.${py})
        break
    fi
done


if [ -d ${ENV} ]
then
    echo " * using previous build dir ${ROOT}"
else
    echo " * create venv ${ROOT}"
    $PYTHON -m venv --prompt pydk-${ENV} ${ENV}
    touch ${ENV}/new_env
fi

cd ${ROOT}

. bin/activate

cd ${ROOT}

mkdir -p ${BUILD_SRC}

date > ${BUILD_SRC}/build.log
env >> ${BUILD_SRC}/build.log
echo  >> ${BUILD_SRC}/build.log
echo  >> ${BUILD_SRC}/build.log

pip install --upgrade pip

if [ -f new_env ]
then

    if pip install scikit-build
    then
        if pip install cmake==3.10.3
        then
            rm new_env
        fi
    fi
fi







# == create a fake cmake project for the purpose of downloading sources
# == and building host python, patchelf and adbfs


cd "${ROOT}"

# because libpython is shared
export LD_LIBRARY_PATH=${HOST}/lib:$LD_LIBRARY_PATH

if [ -f CMakeLists.txt ]
then
    echo " * using previous CMakeLists.txt in $(pwd)"
else

cat > CMakeLists.txt <<END

cmake_minimum_required(VERSION 3.10.2)

project(${ENV})

include(ExternalProject)

set(_downloadOptions SHOW_PROGRESS)

ExternalProject_Add(
    patchelf
    URL ${PATCHELF_URL}
    URL_HASH SHA256=${PATCHELF_HASH}
    PATCH_COMMAND "./bootstrap.sh"
    CONFIGURE_COMMAND sh -c "cd ${PATCHELF_SRC} && ./configure --prefix=${HOST}"
    BUILD_COMMAND sh -c "cd ${PATCHELF_SRC} && make"
    INSTALL_COMMAND sh -c "cd ${PATCHELF_SRC} && make install"
)


# license BSD https://github.com/spion/adbfs-rootless/blob/master/license

ExternalProject_Add(
    adbfs
    GIT_REPOSITORY https://github.com/spion/adbfs-rootless.git
    GIT_TAG ba64c22dbd373499eea9c9a9d2a9dd1cd25c33e1 # 14 july 2019
    CONFIGURE_COMMAND sh -c "mkdir -p ${HOST}/bin"
    BUILD_COMMAND sh -c "cd ${ADBFS_SRC} && make"
    INSTALL_COMMAND sh -c "cd ${ADBFS_SRC} && cp -vf adbfs ${HOST}/bin/"
)

ExternalProject_Add(
    bz2
    URL ${BZ2_URL}
    URL_HASH SHA256=${BZ2_HASH}

    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ""
)

ExternalProject_Add(
    lzma
    URL ${LZMA_URL}
    URL_HASH SHA256=${LZMA_HASH}

    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ""
)


ExternalProject_Add(
    openssl
    DEPENDS patchelf
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
    DEPENDS lzma
    #GIT_REPOSITORY https://github.com/python/cpython.git
    #GIT_TAG 4082f600a5bd69c8f4a36111fa5eb197d7547756 # 3.7.5rc1

    URL ${PYTHON3_URL}
    URL_HASH SHA256=${PYTHON3_HASH}

    PATCH_COMMAND sh -c "/bin/cp -aRfxp ${PYSRC} ${PYDROID}"

    #CONFIGURE_COMMAND ""
    CONFIGURE_COMMAND sh -c "cd ${PYSRC} && CC=clang ./configure --prefix=${HOST} --with-cxx-main=clang $PYOPTS >/dev/null"

    BUILD_COMMAND sh -c "cd ${PYSRC} && make"
    #BUILD_COMMAND ""

    INSTALL_COMMAND sh -c "cd ${PYSRC} && make install >/dev/null 2>&1"
    #INSTALL_COMMAND ""
)


END

    cd ${BUILD_SRC}
    cmake ..
    make && make install

fi



# == can't save space here with patching an existing source tree after a cleanup
# == because we may need a full sourcetree+host python too for some complex libs (eg Panda3D )


. ${ORIGIN}/patch/Python-${PYVER}.config

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
    > /Lib/compileall.py

    #remove the binary blobs
    rm -f ./Python/importlib.h ./Python/importlib_external.h
fi

# without regen importlib is a binary blob ! Use the host python build process to regen the target one then clean up
# make regen-importlib
if [ -f ./Python/importlib_external.h ]
then
    echo
    echo "  ***********************************************************************"
    echo "  **    warning : you have binary blobs in your python source tree     **"
    echo "  ***********************************************************************"
    echo
else
    echo " - regenerating imporlib binary blobs -"

    #make it closer to target parameters
    python_ac_cv_patch config.site
    echo "CONFIG_SITE=config.site CC=clang ./configure --prefix=${HOST} --with-cxx-main=clang $PYOPTS" > build.sh
    chmod +x build.sh

    if ./build.sh >/dev/null
    then
        cat >> pyconfig.h << END
#ifdef HAVE_CRYPT_H
#undef HAVE_CRYPT_H
#endif
END
        make regen-importlib
        make clean
    fi
fi
cd ${ROOT}




Building () {
    cd ${BUILD_PREFIX}-${ANDROID_NDK_ABI_NAME}

    echo " * configure target==$1 ${PLATFORM_TRIPLET}"

    mkdir -p $1-${ANDROID_NDK_ABI_NAME}
    cd $1-${ANDROID_NDK_ABI_NAME}
    /bin/cp -aRfxp ${BUILD_SRC}/$1-prefix/src/$1/. ./

}



for ANDROID_NDK_ABI_NAME in $ARCHITECTURES
do
    unset NDK_PREFIX


    export TOOLCHAIN=$NDK_HOME/toolchains/llvm/prebuilt/$HOST_TAG


    mkdir -p ${BUILD_PREFIX}-${ANDROID_NDK_ABI_NAME}
    cd ${BUILD_PREFIX}-${ANDROID_NDK_ABI_NAME}

    TARGET_ARCH_ABI=$ANDROID_NDK_ABI_NAME

    # except for armv7
    ABI=android

    case "$ANDROID_NDK_ABI_NAME" in
        armeabi-v7a)
            PLATFORM_TRIPLET=armv7a-linux-androideabi
            ARCH=armv7a
            ABI=androideabi
            API=19
            BITS=32
            export NDK_PREFIX="arm-linux-androideabi"
            ;;
        arm64-v8a)
            PLATFORM_TRIPLET=aarch64-linux-android
            ARCH=aarch64
            API=21
            BITS=64
            ;;
        x86)
            PLATFORM_TRIPLET=i686-linux-android
            ARCH=i686
            API=19
            BITS=32
            ;;
        x86_64)
            PLATFORM_TRIPLET=x86_64-linux-android
            ARCH=x86_64
            API=21
            BITS=64
            ;;
    esac

    export APKUSR=${ROOT}/apkroot-${ANDROID_NDK_ABI_NAME}/usr

    export DISPOSE=${ROOT}/apkroot-${ANDROID_NDK_ABI_NAME}-discard

    mkdir -p ${APKUSR} ${DISPOSE}


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

    # == eventually restore full PLATFORM_TRIPLET

    export PLATFORM_TRIPLET=${BUILD_TYPE}



    # == that env file can be handy for debugging compile failures.

    cat > $ROOT/${ANDROID_NDK_ABI_NAME}.sh <<END
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

    if [ -f ${APKUSR}/lib/libbz2.a ]
    then
        echo "    -> libbz2 already built for $ANDROID_NDK_ABI_NAME"
    else
        Building bz2

        unset CFLAGS
        make CC=$CC AR=$AR RANLIB=$RANLIB PREFIX=${APKUSR} bzip2 install
        unset CFLAGS

    fi

    # == building xz liblzma

    if [ -f ${APKUSR}/lib/liblzma.a ]
    then
        echo "    -> liblzma already built for $ANDROID_NDK_ABI_NAME"
    else
        Building lzma

        export CFLAGS="-m${BITS} -fPIC -target ${PLATFORM_TRIPLET}${API} -isysroot $TOOLCHAIN/sysroot -isystem $TOOLCHAIN/sysroot/usr/include"
        if ./configure --target=${PLATFORM_TRIPLET} --host=${PLATFORM_TRIPLET} --build=${HOST_TRIPLET} --prefix=${APKUSR} && make && make install
        then
            echo done
        else
            break
        fi

        unset CFLAGS
    fi


    # == building libffi

    if [ -f ${APKUSR}/lib/libffi.so ]
    then
        echo "    -> libffi already built for $ANDROID_NDK_ABI_NAME"
    else
        Building libffi

        # NDK also defines -ffunction-sections -funwind-tables but they result in worse OpenCV performance (Amos Wenger)
        export CFLAGS="-m${BITS} -fPIC -target ${PLATFORM_TRIPLET}${API} -isysroot $TOOLCHAIN/sysroot -isystem $TOOLCHAIN/sysroot/usr/include"

        if ./configure --target=${PLATFORM_TRIPLET} --host=${PLATFORM_TRIPLET} --build=${HOST_TRIPLET} --prefix=${APKUSR} && make && make install
        then
            echo "done"
        else
            break
        fi

        unset CFLAGS
    fi

    # == building openssl

    # poc https://github.com/ph4r05/android-openssl

    if [ -f  ${APKUSR}/lib/libsslpython.so ]
    then
        echo "    -> openssl-${OPENSSL_VERSION} already built for $ANDROID_NDK_ABI_NAME"
    else
        Building openssl
        unset CFLAGS
        # no-ssl2 no-ssl3 no-comp
        CROSS_COMPILE="" ./Configure android shared no-hw --prefix=${APKUSR} && CROSS_COMPILE="" make depend && CROSS_COMPILE="" make install
        ln -sf . lib


        # == fix android libraries are not version numbered

        chmod u+w ${APKUSR}/lib/lib*.so

        if [ -L ${APKUSR}/lib/libssl.so ]
        then
            rm ${APKUSR}/lib/libssl.so
            mv ${APKUSR}/lib/libssl.so.1.0.0 ${APKUSR}/lib/libsslpython.so
            ${HOST}/bin/patchelf --set-soname libsslpython.so ${APKUSR}/lib/libsslpython.so
            ${HOST}/bin/patchelf --replace-needed libcrypto.so.1.0.0 libcryptopython.so ${APKUSR}/lib/libsslpython.so
        fi

        if [ -L ${APKUSR}/lib/libcrypto.so ]
        then
            rm ${APKUSR}/lib/libcrypto.so
            mv ${APKUSR}/lib/libcrypto.so.1.0.0 ${APKUSR}/lib/libcryptopython.so
            ${HOST}/bin/patchelf --set-soname libcryptopython.so ${APKUSR}/lib/libcryptopython.so
        fi

    fi

    # == building cpython


    # prebuilt/<arch>/ is the final place for libpython
    # but prefix is set to <apk>/usr
    # because a lot of python <prefix>/lib/* can't go in apk private <apk>/lib folder on device

    # in case of on board sdk it may be usefull to keep the <apk>/usr full tree
    # with the static libs without conflicting with that "apk root" lib folder

    if [ -f ${APKUSR}/lib/$LIBPYTHON ]
    then

        echo "    -> python3 already built for $ANDROID_NDK_ABI_NAME"

    else

        echo " * configure target==python $PLATFORM_TRIPLET"

        cd ${BUILD_PREFIX}-${ANDROID_NDK_ABI_NAME}

        mkdir -p python3-${ANDROID_NDK_ABI_NAME}
        cd python3-${ANDROID_NDK_ABI_NAME}

        _PYTHON_PROJECT_SRC=${PYDROID}
        _PYTHON_PROJECT_BASE=$(pwd)

        # defined in ${ORIGIN}/patch/Python-${PYVER}.config

        python_ac_cv_patch config.site

        mkdir -p Modules

        python_module_setup_local Modules/Setup.local



        [ -f Makefile ] && make clean && rm Makefile


# NDK also defines -ffunction-sections -funwind-tables but they result in worse OpenCV performance (Amos Wenger)

        export CFLAGS="-m${BITS} -D__USE_GNU -fPIC -target ${PLATFORM_TRIPLET}${API} -include ${ORIGIN}/patch/ndk_api19/ndk_fix.h -isysroot $TOOLCHAIN/sysroot -isystem $TOOLCHAIN/sysroot/usr/include"





        export PYLIB=${APKUSR}/lib/python${PYMAJOR}.${PYMINOR}

        # == layout a specific folder that will merge all platforms specifics.

        export PYASSETS=${ORIGIN}/assets/python${PYMAJOR}.${PYMINOR}

        mkdir -p ${PYASSETS}

        # == prepare the cross configure + build file for cpython

        python_configure ./build.sh


        # == need a very clean env for true reproducibility

        env -i sh build.sh

        unset CFLAGS


        # == cleanup a bit, as PYTHONDONTWRITEBYTECODE respect may not be perfect

        echo " * cleanup pycache folders"

        rm -rf $(find ${_PYTHON_PROJECT_SRC}/Lib/ -type d|grep __pycache__$)
        rm -rf $(find ${PYLIB}/ -type d|grep __pycache__$)


        # we could just want to keep lib-dynload later
        # sysconfig has already been moved.

        # idea : keep testsuite support on cdn ?
        MOVE_TO_USR="site-packages lib-dynload test unittest lib2to3 contextlib.py argparse.py"

        echo " * move files not suitable for zipimport usage"

        for move in $MOVE_TO_USR
        do
            mv -vf ${PYLIB}/${move} ${DISPOSE}/
        done

        #mv -vf ${PYLIB} ${DISPOSE}/  ?Directory not empty?
        rm -rf ${PYLIB}

        mkdir -p ${PYLIB}

        # those cannot be loaded from the apk zip archive while running testsuite
        # could also be optionnal in most use cases.
        for move in $MOVE_TO_USR
        do
            mv -vf ${DISPOSE}/${move} ${PYLIB}/
        done

        echo " * copy final libs to prebuilt folder"

        if [ -f ${APKUSR}/lib/${LIBPYTHON} ]
        then

            # == default rights would prevent patching.

            chmod u+w ${APKUSR}/lib/lib*.so


            # == this will fix most ndk link problems
            # == also get rid of unfriendly (IMPORTED_NO_SONAME ON) requirement with cmake

            ${HOST}/bin/patchelf --set-soname ${LIBPYTHON} ${APKUSR}/lib/${LIBPYTHON}

            mkdir -p ${ORIGIN}/prebuilt/${ANDROID_NDK_ABI_NAME}
            #mv ${APKUSR}/lib/lib*.so ${ORIGIN}/prebuilt/${ANDROID_NDK_ABI_NAME}/

            # keep a copy so module can cross compile

            /bin/cp -vf ${APKUSR}/lib/lib*.so ${ORIGIN}/prebuilt/${ANDROID_NDK_ABI_NAME}/
            echo " done"
        else
            break
        fi
    fi

    . ${ORIGIN}/cross-build.sh

done


