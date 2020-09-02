#!/bin/bash -e

# Based On
# https://github.com/protocolbuffers/protobuf/issues/5279

#
# This script is for testing and demonstration purposes only
# Use compile_android_protobuf.sh to build profobuf
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

# armeabi-v7a
# arm64-v8a
# x86_64

ARCHITECTURE=x86_64

mkdir -p "${GENDIR}"
mkdir -p "${GENDIR}/${ARCHITECTURE}"

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
# export PREFIX=${GENDIR}/${ARCHITECTURE}
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
# export PREFIX=${GENDIR}/${ARCHITECTURE}
# export PATH=$NDK_ROOT/bin:$PATH
# export SYSROOT=$NDK_ROOT/sysroot
# export CC="arm-linux-androideabi-gcc --sysroot $SYSROOT"
# export CXX="arm-linux-androideabi-g++ --sysroot $SYSROOT"
# export CXXSTL=$NDK_ROOT/sources/cxx-stl/gnu-libstdc++/4.9

# ==== **** ARCH: arm64-v8a API: 22 **** ====

# NDK_ROOT from NDK 16.1.4479499 generated with: 
# ./build/tools/make-standalone-toolchain.sh --arch=arm64 --platform=android-22 --toolchain=aarch64-linux-android-4.9 --install-dir=/Users/phildow/android-ndk/arm64-22-toolchain
# cp -r sources /Users/phildow/android-ndk/arm64-22-toolchain/sources

# export NDK_ROOT=/Users/phildow/android-ndk/arm64-22-toolchain
# export PREFIX=${GENDIR}/${ARCHITECTURE}
# export PATH=$NDK_ROOT/bin:$PATH
# export SYSROOT=$NDK_ROOT/sysroot
# export CC="aarch64-linux-android-gcc --sysroot $SYSROOT"
# export CXX="aarch64-linux-android-g++ --sysroot $SYSROOT"
# export CXXSTL=$NDK_ROOT/sources/cxx-stl/gnu-libstdc++/4.9

# ==== **** ARCH: x86_64 API: 22 **** ====
# ./build/tools/make-standalone-toolchain.sh --arch=x86_64 --platform=android-22 --toolchain=x86_64-4.9 --install-dir=/Users/phildow/android-ndk/x86_64-22-toolchain
# cp -r sources /Users/phildow/android-ndk/x86_64-22-toolchain/sources

export NDK_ROOT=/Users/phildow/android-ndk/x86_64-22-toolchain
export PREFIX=${GENDIR}/${ARCHITECTURE}
export PATH=$NDK_ROOT/bin:$PATH
export SYSROOT=$NDK_ROOT/sysroot
export CC="x86_64-linux-android-gcc --sysroot $SYSROOT"
export CXX="x86_64-linux-android-g++ --sysroot $SYSROOT"
export CXXSTL=$NDK_ROOT/sources/cxx-stl/gnu-libstdc++/4.9

# ===== ===== #

cd downloads/protobuf

./autogen.sh

# --enable-shared
# --with-protoc=protoc

# ==== ARCH: armeabi-v7a API: 21 ====

# ./configure \
# --prefix=$PREFIX \
# --host=arm-linux-androideabi \
# --with-sysroot="${SYSROOT}" \
# --disable-shared \
# --enable-cross-compile \
# --with-protoc="${PROTOC_PATH}" \
# CFLAGS="-march=armv7-a -D__ANDROID_API__=21" \
# CXXFLAGS="-frtti -fexceptions -march=armv7-a \
# -I${NDK_ROOT}/sources/android/support/include \
# -I${NDK_ROOT}/sources/cxx-stl/gnu-libstdc++/4.9/include \
# -I${NDK_ROOT}/sources/cxx-stl/gnu-libstdc++/4.9/libs/armeabi-v7a/include -D__ANDROID_API__=21" \
# LDFLAGS="-L${NDK_ROOT}/sources/cxx-stl/gnu-libstdc++/4.9/libs/armeabi-v7a" \
# LIBS="-llog -lz -lgnustl_static"

# ==== **** ARCH: arm64-v8a API: 22 **** ====

# ./configure \
# --prefix=$PREFIX \
# --host=arm-linux-androideabi \
# --with-sysroot="${SYSROOT}" \
# --disable-shared \
# --enable-cross-compile \
# --with-protoc="${PROTOC_PATH}" \
# CFLAGS="-D__ANDROID_API__=22" \
# CXXFLAGS="-frtti -fexceptions \
# -I${NDK_ROOT}/sources/android/support/include \
# -I${NDK_ROOT}/sources/cxx-stl/gnu-libstdc++/4.9/include \
# -I${NDK_ROOT}/sources/cxx-stl/gnu-libstdc++/4.9/libs/arm64-v8a/include -D__ANDROID_API__=22" \
# LDFLAGS="-L${NDK_ROOT}/sources/cxx-stl/gnu-libstdc++/4.9/libs/arm64-v8a" \
# LIBS="-llog -lz -lgnustl_static"

# ==== **** ARCH: x86_64 API: 22 **** ====

./configure \
--prefix=$PREFIX \
--host=x86_64-linux-android \
--with-sysroot="${SYSROOT}" \
--disable-shared \
--enable-cross-compile \
--with-protoc="${PROTOC_PATH}" \
CFLAGS="-D__ANDROID_API__=22" \
CXXFLAGS="-frtti -fexceptions \
-I${NDK_ROOT}/sources/android/support/include \
-I${NDK_ROOT}/sources/cxx-stl/gnu-libstdc++/4.9/include \
-I${NDK_ROOT}/sources/cxx-stl/gnu-libstdc++/4.9/libs/x86_64/include -D__ANDROID_API__=22" \
LDFLAGS="-L${NDK_ROOT}/sources/cxx-stl/gnu-libstdc++/4.9/libs/x86_64" \
LIBS="-llog -lz -lgnustl_static"

make -j2

make install