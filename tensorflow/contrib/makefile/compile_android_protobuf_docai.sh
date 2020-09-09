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

# Create a standalone toolchain with the following commands:

# ARCH: armeabi-v7a API: 22 NDK: 16.1.4479499
# ./build/tools/make-standalone-toolchain.sh --arch=arm --platform=android-22 --toolchain=arm-linux-androideabi-4.9 --install-dir=/Users/phildow/android-ndk/arm-22-toolchain
# cp -r sources /Users/phildow/android-ndk/arm-22-toolchain/sources

# ARCH: arm64-v8a API: 22 NDK: 16.1.4479499
# ./build/tools/make-standalone-toolchain.sh --arch=arm64 --platform=android-22 --toolchain=aarch64-linux-android-4.9 --install-dir=/Users/phildow/android-ndk/arm64-22-toolchain
# cp -r sources /Users/phildow/android-ndk/arm64-22-toolchain/sources

# ARCH: x86_64 API: 22 NDK: 16.1.4479499
# ./build/tools/make-standalone-toolchain.sh --arch=x86_64 --platform=android-22 --toolchain=x86_64-4.9 --install-dir=/Users/phildow/android-ndk/x86_64-22-toolchain
# cp -r sources /Users/phildow/android-ndk/x86_64-22-toolchain/sources

# Example executions:

# NDK_ROOT=/Users/phildow/android-ndk/arm-22-toolchain ./compile_android_protobuf_docai.sh -a armeabi-v7a
# NDK_ROOT=/Users/phildow/android-ndk/arm64-22-toolchain ./compile_android_protobuf_docai.sh -a arm64-v8a
# NDK_ROOT=/Users/phildow/android-ndk/x86_64-22-toolchain ./compile_android_protobuf_docai.sh -a x86_64

# Pare Command Line Options

# ARCHITECTURE is one of:
# armeabi-v7a
# arm64-v8a
# x86_64

while getopts "a:c" opt_name; do
  case "$opt_name" in
    a) ARCHITECTURE=$OPTARG;;
    c) clean=true;;
  esac
done
shift $((OPTIND - 1))

# Ensure NDK_ROOT is set

if [[ -z "${NDK_ROOT}" ]]
then
  echo "You must set NDK_ROOT"
  exit 1
fi

# Prepare local variables

SCRIPT_DIR=$(dirname $0)
GENDIR="$(pwd)/gen/protobuf_android"
HOST_GENDIR="$(pwd)/gen/protobuf-host"

# must run compile_android_protobuf.sh first
PROTOC_PATH="${HOST_GENDIR}/bin/protoc"

# Prepare gen dirs

mkdir -p "${GENDIR}"
mkdir -p "${GENDIR}/${ARCHITECTURE}"

# Prepare exports

export PREFIX=${GENDIR}/${ARCHITECTURE}
export PATH=$NDK_ROOT/bin:$PATH
export SYSROOT=$NDK_ROOT/sysroot

if [[ ${ARCHITECTURE} == "arm64-v8a" ]]; then
    # toolchain="aarch64-linux-android-4.9"
    # sysroot_arch="arm64"
    bin_prefix="aarch64-linux-android"
elif [[ ${ARCHITECTURE} == "armeabi-v7a" ]]; then
    # toolchain="arm-linux-androideabi-4.9"
    # sysroot_arch="arm"
    bin_prefix="arm-linux-androideabi"
    march_option="-march=armv7-a"
elif [[ ${ARCHITECTURE} == "x86_64" ]]; then
    # toolchain="x86_64-4.9"
    # sysroot_arch="x86_64"
    bin_prefix="x86_64-linux-android"
else
    echo "architecture ${ARCHITECTURE} is not supported." 1>&2
    usage
    exit 1
fi

export CC="${bin_prefix}-gcc --sysroot $SYSROOT"
export CXX="${bin_prefix}-g++ --sysroot $SYSROOT"
export CXXSTL=$NDK_ROOT/sources/cxx-stl/gnu-libstdc++/4.9

ANDROID_API_VERSION=22
HOST=${bin_prefix}

# Build

echo "Building ARCH=${ARCHITECTURE} API=${ANDROID_API_VERSION} HOST=${HOST} NDK_ROOT=${NDK_ROOT}"

cd downloads/protobuf

./autogen.sh

./configure \
--prefix=$PREFIX \
--host="${HOST}" \
--with-sysroot="${SYSROOT}" \
--disable-shared \
--enable-cross-compile \
--with-protoc="${PROTOC_PATH}" \
CFLAGS="${march_option} -D__ANDROID_API__=${ANDROID_API_VERSION}" \
CXXFLAGS="-frtti -fexceptions ${march_option} \
-I${NDK_ROOT}/sources/android/support/include \
-I${NDK_ROOT}/sources/cxx-stl/gnu-libstdc++/4.9/include \
-I${NDK_ROOT}/sources/cxx-stl/gnu-libstdc++/4.9/libs/${ARCHITECTURE}/include \
-D__ANDROID_API__=${ANDROID_API_VERSION}" \
LDFLAGS="-L${NDK_ROOT}/sources/cxx-stl/gnu-libstdc++/4.9/libs/${ARCHITECTURE}" \
LIBS="-llog -lz -lgnustl_static"

make -j2

make install