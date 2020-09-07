#!/bin/bash -e

# Compiles protobuf using a standalone toolchain 
# Based On https://github.com/protocolbuffers/protobuf/issues/5279
#
# This script is for testing and demonstration purposes only
# Use compile_android_protobuf.sh to build profobuf (not currenly working)
#
# Before running this script you must run compile_android_protobuf.sh up to
# the make_host_protoc command. I recommend adding an exit command after it
# You should end up with a gen/protobuf-host directory that contains 
# gen/protobuf-host/bin/protoc. This is the file used for PROTOC_PATH

SCRIPT_DIR=$(dirname $0)
GENDIR="$(pwd)/gen/protobuf_android"
HOST_GENDIR="$(pwd)/gen/protobuf-host"

# must run compile_android_protobuf.sh first
PROTOC_PATH="${HOST_GENDIR}/bin/protoc"

# 1) Set Architecture

# armeabi-v7a
# arm64-v8a
# x86_64

ARCH=arm64-v8a

mkdir -p "${GENDIR}"
mkdir -p "${GENDIR}/${ARCH}"

# 2) Choose Build Exports

# ==== Source Example ====

# export NDK_ROOT=~/Android/android-ndk-r16b
# export PREFIX=$HOME/Android/protobuf-3.5.1/
# export PATH=$HOME/Android/arm-21-toolchain/bin:$PATH
# export SYSROOT=$HOME/Android/arm-21-toolchain/sysroot
# export CC="arm-linux-androideabi-gcc --sysroot $SYSROOT"
# export CXX="arm-linux-androideabi-g++ --sysroot $SYSROOT"
# export CXXSTL=$NDK_ROOT/sources/cxx-stl/gnu-libstdc++/4.9

# ==== ARCH: armeabi-v7a API: 21 ====

# NDK_ROOT from NDK 16.1.4479499 generated with: 
# ./build/tools/make-standalone-toolchain.sh --arch=arm --platform=android-21 --toolchain=arm-linux-androideabi-4.9 --install-dir=/Users/phildow/android-ndk/arm-21-toolchai
# cp -r sources /Users/phildow/android-ndk/arm-21-toolchain/sources

# export NDK_ROOT=/Users/phildow/android-ndk/arm-21-toolchain
# export PREFIX=${GENDIR}/${ARCH}
# export PATH=$NDK_ROOT/bin:$PATH
# export SYSROOT=$NDK_ROOT/sysroot
# export CC="arm-linux-androideabi-gcc --sysroot $SYSROOT"
# export CXX="arm-linux-androideabi-g++ --sysroot $SYSROOT"
# export CXXSTL=$NDK_ROOT/sources/cxx-stl/gnu-libstdc++/4.9

# ==== ARCH: armeabi-v7a API: 22 ====

# NDK_ROOT from NDK 16.1.4479499 generated with: 
# ./build/tools/make-standalone-toolchain.sh --arch=arm --platform=android-22 --toolchain=arm-linux-androideabi-4.9 --install-dir=/Users/phildow/android-ndk/arm-22-toolchain
# cp -r sources /Users/phildow/android-ndk/arm-22-toolchain/sources

# export NDK_ROOT=/Users/phildow/android-ndk/arm-22-toolchain
# export PREFIX=${GENDIR}/${ARCH}
# export PATH=$NDK_ROOT/bin:$PATH
# export SYSROOT=$NDK_ROOT/sysroot
# export CC="arm-linux-androideabi-gcc --sysroot $SYSROOT"
# export CXX="arm-linux-androideabi-g++ --sysroot $SYSROOT"
# export CXXSTL=$NDK_ROOT/sources/cxx-stl/gnu-libstdc++/4.9

# ==== **** ARCH: arm64-v8a API: 22 **** ====

# NDK_ROOT from NDK 16.1.4479499 generated with: 
# ./build/tools/make-standalone-toolchain.sh --arch=arm64 --platform=android-22 --toolchain=aarch64-linux-android-4.9 --install-dir=/Users/phildow/android-ndk/arm64-22-toolchain
# cp -r sources /Users/phildow/android-ndk/arm64-22-toolchain/sources

export NDK_ROOT=/Users/phildow/android-ndk/arm64-22-toolchain
export PREFIX=${GENDIR}/${ARCH}
export PATH=$NDK_ROOT/bin:$PATH
export SYSROOT=$NDK_ROOT/sysroot
export CC="aarch64-linux-android-gcc --sysroot $SYSROOT"
export CXX="aarch64-linux-android-g++ --sysroot $SYSROOT"
export CXXSTL=$NDK_ROOT/sources/cxx-stl/gnu-libstdc++/4.9

# ==== **** ARCH: x86_64 API: 22 **** ====
# ./build/tools/make-standalone-toolchain.sh --arch=x86_64 --platform=android-22 --toolchain=x86_64-4.9 --install-dir=/Users/phildow/android-ndk/x86_64-22-toolchain
# cp -r sources /Users/phildow/android-ndk/x86_64-22-toolchain/sources

# export NDK_ROOT=/Users/phildow/android-ndk/x86_64-22-toolchain
# export PREFIX=${GENDIR}/${ARCH}
# export PATH=$NDK_ROOT/bin:$PATH
# export SYSROOT=$NDK_ROOT/sysroot
# export CC="x86_64-linux-android-gcc --sysroot $SYSROOT"
# export CXX="x86_64-linux-android-g++ --sysroot $SYSROOT"
# export CXXSTL=$NDK_ROOT/sources/cxx-stl/gnu-libstdc++/4.9

# ===== ===== #

cd downloads/protobuf

./autogen.sh

# 3) Configure Build

# ==== ARCH: armeabi-v7a API: 21 ====

# HOST=arm-linux-androideabi
# C_MARCH_FLAG=-march=armv7-a
# API=21

# ==== **** ARCH: arm64-v8a API: 22 **** ====

HOST=aarch64-linux-android
API=22

# ==== **** ARCH: x86_64 API: 22 **** ====

# HOST=x86_64-linux-android
# API=22

# --enable-shared
# --with-protoc=protoc

./configure \
--prefix=$PREFIX \
--host="${HOST}" \
--with-sysroot="${SYSROOT}" \
--disable-shared \
--enable-cross-compile \
--with-protoc="${PROTOC_PATH}" \
CFLAGS="${MARCH_FLAG} -D__ANDROID_API__=${API}" \
CXXFLAGS="-frtti -fexceptions ${MARCH_FLAG} \
-I${NDK_ROOT}/sources/android/support/include \
-I${NDK_ROOT}/sources/cxx-stl/gnu-libstdc++/4.9/include \
-I${NDK_ROOT}/sources/cxx-stl/gnu-libstdc++/4.9/libs/${ARCH}/include -D__ANDROID_API__=${API}" \
LDFLAGS="-L${NDK_ROOT}/sources/cxx-stl/gnu-libstdc++/4.9/libs/${ARCH}" \
LIBS="-llog -lz -lgnustl_static"

echo "Building ARCH=${ARCH} API=${API} HOST=${HOST}"

make -j2

make install