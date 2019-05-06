
PROJECT_DIR=$(shell pwd)

BUILD_NUMBER=1

# PYTHON_VERSION=3.6.6
PYTHON_VERSION=3.7.1
PYTHON_VER=$(basename $(PYTHON_VERSION))

ABIS=armeabi-v7a # arm64-v8a x86 x86_64

BUILD_TAG=darwin-x86_64
BUILD_TRIPLE=x86_64-apple-darwin

# BUILD_TAG=linux-x86_64
# BUILD_TRIPLE=i686-pc-linux-gnu

# BUILD_TAG=windows
# BUILD_TRIPLE=...

# BUILD_TAG=windows-x86_64
# BUILD_TRIPLE=...

ANDROID_NDK_ROOT=$(ANDROID_SDK_ROOT)/ndk-bundle
BUILD_NDK_TOOLCHAIN=$(ANDROID_NDK_ROOT)/toolchains/llvm/prebuilt/$(BUILD_TAG)
ANDROID_API=21

# Common settings
CFLAGS=-fPIC -DANDROID -D__ANDROID_API__=$(ANDROID_API)
LDFLAGS=-pthread -Wl,-O1 -Wl,-Bsymbolic-functions -Wl,-soname,libpython3.7m.so

# # ABI=x86
# HOST_TRIPLE-x86=i686-linux-android
# CC-x86=$(BUILD_NDK_TOOLCHAIN)/clang --target=i686-linux-android$(ANDROID_API) --gcc-toolchain=$(ANDROID_NDK_ROOT)/toolchains/llvm/prebuilt/$(BUILD_TAG)
# CXX-x86=$(BUILD_NDK_TOOLCHAIN)/i686-linux-android$(ANDROID_API)-clang++
# LD-x86=$(BUILD_NDK_TOOLCHAIN)/i686-linux-android-ld
# AR-x86=$(BUILD_NDK_TOOLCHAIN)/i686-linux-android-ar

# # ABI=x86_64
# HOST_TRIPLE-x86_64=x86_64-linux-android
# CC-x86_64=$(BUILD_NDK_TOOLCHAIN)/clang --target=x86_64-linux-android$(ANDROID_API) --gcc-toolchain=$(ANDROID_NDK_ROOT)/toolchains/llvm/prebuilt/$(BUILD_TAG)
# CXX-x86_64=$(BUILD_NDK_TOOLCHAIN)/x86_64-linux-android$(ANDROID_API)-clang++
# LD-x86_64=$(BUILD_NDK_TOOLCHAIN)/x86_64-linux-android-ld
# AR-x86_64=$(BUILD_NDK_TOOLCHAIN)/x86_64-linux-android-ar

# ABI=armeabi-v7a
HOST_TRIPLE-armeabi-v7a=arm-linux-androideabi
CC-armeabi-v7a=$(BUILD_NDK_TOOLCHAIN)/bin/clang -target armv7a-linux-androideabi$(ANDROID_API) -gcc-toolchain $(ANDROID_NDK_ROOT)/toolchains/arm-linux-androideabi-4.9/prebuilt/darwin-x86_64
CXX-armeabi-v7a=$(BUILD_NDK_TOOLCHAIN)/bin/clang++ -target armv7a-linux-androideabi$(ANDROID_API) -gcc-toolchain $(ANDROID_NDK_ROOT)/toolchains/arm-linux-androideabi-4.9/prebuilt/darwin-x86_64
LD-armeabi-v7a=$(BUILD_NDK_TOOLCHAIN)/bin/arm-linux-androideabi-ld
AR-armeabi-v7a=$(BUILD_NDK_TOOLCHAIN)/bin/arm-linux-androideabi-ar
RANLIB-armeabi-v7a=$(BUILD_NDK_TOOLCHAIN)/bin/arm-linux-androideabi-ranlib
READELF-armeabi-v7a=$(BUILD_NDK_TOOLCHAIN)/bin/readelf

CFLAGS-armeabi-v7a=-I$(ANDROID_NDK_ROOT)/sysroot/usr/include -isystem $(ANDROID_NDK_ROOT)/sysroot/usr/include/arm-linux-androideabi
LDFLAGS-armeabi-v7a=-L$(ANDROID_NDK_ROOT)/platforms/android-$(ANDROID_API)/arch-arm/usr/lib --sysroot=$(ANDROID_NDK_ROOT)/platforms/android-$(ANDROID_API)/arch-arm


# # ABI=arm64-v8a
# HOST_TRIPLE-arm64-v8a=aarch64-linux-android
# # CC-arm64-v8a=$(BUILD_NDK_TOOLCHAIN)/aarch64-linux-android$(ANDROID_API)-clang
# CC-arm64-v8a=$(BUILD_NDK_TOOLCHAIN)/clang --target=aarch64-none-linux-android$(ANDROID_API) --gcc-toolchain=$(ANDROID_NDK_ROOT)/toolchains/llvm/prebuilt/$(BUILD_TAG)
# # CFLAGS-arm64-v8a=-isystem $(ANDROID_NDK_ROOT)sysroot/usr/include/$(HOST_TRIPLE-arm64-v8a)
# # CFLAGS-=
# CXX-arm64-v8a=$(BUILD_NDK_TOOLCHAIN)/aarch64-linux-android$(ANDROID_API)-clang++
# LD-arm64-v8a=$(BUILD_NDK_TOOLCHAIN)/aarch64-linux-android-ld
# AR-arm64-v8a=$(BUILD_NDK_TOOLCHAIN)/aarch64-linux-android-ar


all: dist/Python-Android-support.b$(BUILD_NUMBER).tar.gz

clean:
	rm -rf build dist

# Download original Python source code archive.
downloads/Python-$(PYTHON_VERSION).tgz:
	mkdir -p downloads
	if [ ! -e downloads/Python-$(PYTHON_VERSION).tgz ]; then curl -L https://www.python.org/ftp/python/$(PYTHON_VERSION)/Python-$(PYTHON_VERSION).tgz > downloads/Python-$(PYTHON_VERSION).tgz; fi

# Define the HOST build
build/host:
	mkdir -p build/host

build/host/Python-$(PYTHON_VERSION)/configure: build/host downloads/Python-$(PYTHON_VERSION).tgz
	tar zxf downloads/Python-$(PYTHON_VERSION).tgz -C build/host

build/host/Python-$(PYTHON_VERSION)/Makefile: build/host/Python-$(PYTHON_VERSION)/configure
	cd build/host/Python-$(PYTHON_VERSION) && ./configure --prefix=$(PROJECT_DIR)/build/host --without-ensurepip

build/host/bin/python$(PYTHON_VER): build/host/Python-$(PYTHON_VERSION)/Makefile
	cd build/host/Python-$(PYTHON_VERSION) && make -j 2 all install

# Define the a build command for all the target platforms
define build
PYTHON_DIR-$1=build/$1/Python-$(PYTHON_VERSION)

$$(PYTHON_DIR-$1)/configure: downloads/Python-$$(PYTHON_VERSION).tgz
	mkdir -p $$(PYTHON_DIR-$1)
	tar zxf downloads/Python-$(PYTHON_VERSION).tgz -C build/$1

$$(PYTHON_DIR-$1)/Makefile: build/host/bin/python$$(PYTHON_VER) $$(PYTHON_DIR-$1)/configure
	cd $$(PYTHON_DIR-$1) && PATH=$$(PROJECT_DIR)/build/host/bin:$$(PATH) ./configure \
		CC="$$(CC-$1)" \
		CXX="$$(CXX-$1)" \
		LD="$$(LD-$1)" \
		AR="$$(AR-$1)" \
		RANLIB="$$(RANLIB-$1)" \
		READELF="$$(READELF-$1)" \
		CFLAGS="$$(CFLAGS) $$(CFLAGS-$1)" \
		CXXFLAGS="$$(CFLAGS) $$(CFLAGS-$1)" \
		LDFLAGS="$$(LDFLAGS)" \
		--host=$$(HOST_TRIPLE-$1) \
		--build=$$(BUILD_TRIPLE) \
		--prefix=$$(PROJECT_DIR)/build/$1 \
		--enable-shared --disable-ipv6 --disable-make --without-ensurepip \
		ac_cv_file__dev_ptmx=yes ac_cv_file__dev_ptc=no ac_cv_little_endian_double=yes

build/$1/bin/python$$(PYTHON_VER): $$(PYTHON_DIR-$1)/Makefile
	cd $$(PYTHON_DIR-$1) && \
		PATH=$$(PROJECT_DIR)/build/host/bin:$$(PATH) make all install -j 2 INSTSONAME="libpython$$(PYTHON_VER)m.so"

build/include/$1: build/$1/bin/python$$(PYTHON_VER) build/include
	ln -s ../$1/include build/include/$1

build/lib/$1:
	mkdir -p build/lib/$1

build/lib/$1/libpython$(PYTHON_VER)m.so: build/$1/bin/python$$(PYTHON_VER) build/lib/$1
	cp build/$1/lib/libpython$(PYTHON_VER)m.so build/lib/$1

build/home/$1:
	mkdir -p build/home/$1

build/home/$1/python$(PYTHON_VER).zip: build/$1/bin/python$$(PYTHON_VER) build/lib/$1 build/home/$1
	cd build/$1/lib && zip -r ../../home/$1/python$(PYTHON_VER).zip pkgconfig python$(PYTHON_VER)

endef
# Expand the target build command for each target ABI
$(foreach abi,$(ABIS),$(eval $(call build,$(abi))))

build/include:
	mkdir -p build/include

build/VERSIONS: build/host
	# Create the VERSIONS tracking file
	echo "Python version: $(PYTHON_VERSION) " > build/VERSIONS
	echo "Build: $(BUILD_NUMBER)" >> build/VERSIONS
	echo "---------------------" >> build/VERSIONS
	echo "BZip2: $(BZIP2_VERSION)" >> build/VERSIONS
	echo "OpenSSL: $(OPENSSL_VERSION)" >> build/VERSIONS
	echo "XZ: $(XZ_VERSION)" >> build/VERSIONS

dist/Python-Android-support.b$(BUILD_NUMBER).tar.gz: build/VERSIONS $(foreach abi,$(ABIS),build/include/$(abi))  $(foreach abi,$(ABIS),build/lib/$(abi)/libpython$(PYTHON_VER)m.so)  $(foreach abi,$(ABIS),build/home/$(abi)/python$(PYTHON_VER).zip)
	mkdir -p dist
	tar zcvhf $@ -C build VERSIONS lib include home
