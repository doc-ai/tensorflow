
# Compiling TensorFlow For Android With clang

Building TensorFlow for Android on Ubuntu with a standalone clang toolchain for API 21 from NDK 19.2.5345600.

These instructions are based on the following resources:

https://becominghuman.ai/how-to-build-tensorflow-as-a-static-library-for-android-5c762dbdd5d4

https://forum.qt.io/topic/108704/building-protobuff-libs-for-android-64-bit-arm64-v8a-qt-5-12-4

For more information about the NDK:

https://developer.android.com/ndk/guides

## Package Prequisites

Install the following packages:

```
python build-essential zlib1g-dev git autoconf libtool automake curl unzip clang
```

## Toolchain

NDK 19?+ contain prebuilt toolchains, but you can build standalone toolchains as well. We'll start with standalone toolchains because that is what I have instructions for.

From Android Studio install NDK 19.2.5345600. It will be located at *~/Android/Sdk/ndk*

From the NDK 19.2.5345600 root directory create three standalone toolchains, one for arm64-v8a (on device) and two for emulator support on x86 and x86_64:

```
$ build/tools/make_standalone_toolchain.py --arch arm64 --api 21 --stl libc++ --install-dir $HOME/android-toolchains/ndk-19-api-21-arm64-clang
$ build/tools/make_standalone_toolchain.py --arch x86_64 --api 21 --stl libc++ --install-dir $HOME/android-toolchains/ndk-19-api-21-x86_64-clang
$ build/tools/make_standalone_toolchain.py --arch x86 --api 21 --stl libc++ --install-dir $HOME/android-toolchains/ndk-19-api-21-x86-clang
```

**TODO:**

Check if we had to copy one of *sysroot/usr/include* or *sysroot/usr/lib* from the NDK directory to the standalone toolchain. 

## Dependencies

Download the required dependencies. From the tensorflow root directory run:

```
$ tensorflow/contrib/makefile/download_dependencies.sh
```

For both the protobuf and nysnc dependencies we will make three builds: a local x86_64 build and then adroid arm64 (on device) and x86_64 (emulator) builds. For tensorflow we will only make the two android builds.

## Build protobuf with clang

From tensorflow and specifically tensorflow/contrib/makefile run:

```
$ mkdir gen-protobuf
$ mkdir gen-protobuf/x86_64.linux
$ mkdir gen-protobuf/arm64-v8.android
$ mkdir gen-protobuf/x86_64.android
$ mkdir gen-protobuf/x86.android
```

From downloads/protobuf run:

```
$ mkdir builds
$ ./autogen.sh
```

**Build native linux x86_64 library and protoc:**

```
$ mkdir builds/x86_64.linux
$ cd builds/x86_64.linux

$ export CC=clang
$ export CXX=clang++

$ ../../configure --prefix=/home/phildow/GitHub/tensorflow/tensorflow/contrib/makefile/gen-protobuf/x86_64.linux
$ make install -j4
```

Outputs to:

```
gen-protobuf/x86_64.linux/lib/libprotobuf.a
```

Confirm the architecture:

```
objdump -f gen-protobuf/x86_64.linux/lib/libprotobuf.a
```

**Build android arm64-v8 library**

```
$ mkdir builds/arm64-v8.android
$ cd builds/arm64-v8.android

$ export NDK_ROOT=~/android-toolchains/ndk-19-api-21-arm64-clang
$ export PATH=$NDK_ROOT/bin:$PATH

$ export CC=aarch64-linux-android21-clang
$ export CXX=aarch64-linux-android21-clang++
$ export CFLAGS="-fPIE -fPIC"
$ export CPPFLAGS="-fPIE -fPIC"
$ export LDFLAGS="-pie -llog"

$ ../../configure --host=aarch64-linux-android --prefix=/home/phildow/GitHub/tensorflow/tensorflow/contrib/makefile/gen-protobuf/arm64-v8.android --with-protoc=/home/phildow/GitHub/tensorflow/tensorflow/contrib/makefile/gen-protobuf/x86_64.linux/bin/protoc
$ make install -j4
```

Outputs to:

```
gen-protobuf/arm64-v8.android/lib/libprotobuf.a
```

Confirm the architecture:

```
~/android-toolchains/ndk-19-api-21-arm64-clang/bin/aarch64-linux-android-objdump -f gen-protobuf/arm64-v8.android/lib/libprotobuf.a
```

**Build android x86_64 library for emulator**

Patch the source according to the instructions here:

https://github.com/protocolbuffers/protobuf/issues/5144#issuecomment-688723405

Specifically, modify *src/libprotoc.map,* *src/libprotobuf.map*, and *src/libprotobuf-lite.map* so that they look like:

```
{
  global:
    extern "C++" {
      *google*;
    };
    scc_info_*;
    descriptor_table_*;

  local:
    *;
};
```

Otherwise you will run into the following error during *make install*:

```
./.libs/libprotoc.so: error: undefined reference to 'descriptor_table_google_2fprotobuf_2fdescriptor_2eproto'
./.libs/libprotoc.so: error: undefined reference to 'scc_info_FileDescriptorProto_google_2fprotobuf_2fdescriptor_2eproto'
```

Reset the PATH variable to remove the reference to the previously used NDK_ROOT, then run:

```
$ mkdir builds/x86_64.android
$ cd builds/x86_64.android

$ export NDK_ROOT=~/android-toolchains/ndk-19-api-21-x86_64-clang
$ export PATH=$NDK_ROOT/bin:$PATH

$ export CC=x86_64-linux-android21-clang
$ export CXX=x86_64-linux-android21-clang++
$ export CFLAGS="-fPIE -fPIC"
$ export CPPFLAGS="-fPIE -fPIC"
$ export LDFLAGS="-pie -llog"

$ ../../configure --host=x86_64-linux-android --prefix=/home/phildow/GitHub/tensorflow/tensorflow/contrib/makefile/gen-protobuf/x86_64.android --with-protoc=/home/phildow/GitHub/tensorflow/tensorflow/contrib/makefile/gen-protobuf/x86_64.linux/bin/protoc
$ make install -j4
```

Outputs to:

```
gen-protobuf/x86_64.android/lib/libprotobuf.a
```

Confirm the architecture:

```
$ ~/android-toolchains/ndk-19-api-21-x86_64-clang/bin/x86_64-linux-android-objdump -f gen-protobuf/x86_64.android/lib/libprotobuf.a
```

**Build android x86 library for emulator**

If you have not already done so patch the source according to the x86_64 instructions above.

Reset the PATH variable to remove the reference to the previously used NDK_ROOT, then run:

```
$ mkdir builds/x86.android
$ cd builds/x86.android

$ export NDK_ROOT=~/android-toolchains/ndk-19-api-21-x86-clang
$ export PATH=$NDK_ROOT/bin:$PATH

$ export CC=i686-linux-android21-clang
$ export CXX=i686-linux-android21-clang++
$ export CFLAGS="-fPIE -fPIC"
$ export CPPFLAGS="-fPIE -fPIC"
$ export LDFLAGS="-pie -llog"

$ ../../configure --host=i686-linux-android --prefix=/home/phildow/GitHub/tensorflow/tensorflow/contrib/makefile/gen-protobuf/x86.android --with-protoc=/home/phildow/GitHub/tensorflow/tensorflow/contrib/makefile/gen-protobuf/x86.linux/bin/protoc
$ make install -j4
```

Outputs to:

```
gen-protobuf/x86.android/lib/libprotobuf.a
```

Confirm the architecture:

```
~/android-toolchains/ndk-19-api-21-x86-clang/bin/i686-linux-android-objdump -f gen-protobuf/x86.android/lib/libprotobuf.a
```

**Cleanup**

When you are finished reset your PATH and other exported variables:

```
$ PATH=...
$ unset NDK_ROOT

$ unset CC
$ unset CXX
$ unset CFLAGS
$ unset LDFLAGS
```

## Build nsync with clang

**Build native linux x86_64 library**

From *tensorflow/contrib/makefile/downloads/nsync*

```
$ cd builds/x86_64.linux.c++11
$ make depend nsync.a
```

Outputs to (local directory):

```
tensorflow/contrib/makefile/downloads/nsync/builds/x86_64.linux.c++11/nsync.a
```

Check architecture:

```
objdump -f nsync.a
```

**Build android arm64-v8 library:**

Update the NDK_ROOT and PATH:

```
$ export NDK_ROOT=~/android-toolchains/ndk-19-api-21-arm64-clang
$ export PATH=$NDK_ROOT/bin:$PATH
```

From *downloads/nsync:*

```
$ mkdir builds/aarch64.android.clang
$ cd builds/aarch64.android.clang
$ touch Makefile
$ touch dependfile
```

Add the following to the Makefile, which is taken from the *android* target in *compile_nysnc.sh*:

```
AR=aarch64-linux-android-ar
CC=aarch64-linux-android21-clang++
PLATFORM_CPPFLAGS=-DNSYNC_USE_CPP11_TIMEPOINT -DNSYNC_ATOMIC_CPP11 \
                    -I../../platform/c++11 -I../../platform/gcc \
                    -I../../platform/posix -pthread
PLATFORM_CFLAGS=-std=c++11 -Wno-narrowing -fPIE -fPIC
PLATFORM_LDFLAGS=-pthread
MKDEP=${CC} -x c++ -M -std=c++11
PLATFORM_C=../../platform/c++11/src/nsync_semaphore_mutex.cc \
            ../../platform/posix/src/per_thread_waiter.c \
            ../../platform/c++11/src/yield.cc \
            ../../platform/c++11/src/time_rep_timespec.cc \
            ../../platform/c++11/src/nsync_panic.cc
PLATFORM_OBJS=nsync_semaphore_mutex.o per_thread_waiter.o yield.o \
                time_rep_timespec.o nsync_panic.o
TEST_PLATFORM_C=../../platform/c++11/src/start_thread.cc
TEST_PLATFORM_OBJS=start_thread.o
include ../../platform/posix/make.common
include dependfile
```

Run:

```
$ make depend nsync.a
```

Outputs to (local directory):

```
tensorflow/contrib/makefile/downloads/nsync/builds/aarch64.android.clang/nsync.a
```

Confirm the architecture:

```
$ ~/android-toolchains/ndk-19-api-21-arm64-clang/bin/aarch64-linux-android-objdump -f nsync.a
```

**Build android x86_64 library for emulator:**

First reset the PATH variable then update the NDK_ROOT and PATH:

```
$ export NDK_ROOT=~/android-toolchains/ndk-19-api-21-x86_64-clang
$ export PATH=$NDK_ROOT/bin:$PATH
```

From *downloads/nsync:*

```
$ mkdir builds/x86_64.android.clang
$ cd builds/x86_64.android.clang
$ touch Makefile
$ touch dependfile
```

Add the following to the Makefile, which is taken from the *android* target in *compile_nysnc.sh*:

```
AR=x86_64-linux-android-ar
CC=x86_64-linux-android21-clang++
PLATFORM_CPPFLAGS=-DNSYNC_USE_CPP11_TIMEPOINT -DNSYNC_ATOMIC_CPP11 \
                    -I../../platform/c++11 -I../../platform/gcc \
                    -I../../platform/posix -pthread
PLATFORM_CFLAGS=-std=c++11 -Wno-narrowing -fPIE -fPIC
PLATFORM_LDFLAGS=-pthread
MKDEP=${CC} -x c++ -M -std=c++11
PLATFORM_C=../../platform/c++11/src/nsync_semaphore_mutex.cc \
            ../../platform/posix/src/per_thread_waiter.c \
            ../../platform/c++11/src/yield.cc \
            ../../platform/c++11/src/time_rep_timespec.cc \
            ../../platform/c++11/src/nsync_panic.cc
PLATFORM_OBJS=nsync_semaphore_mutex.o per_thread_waiter.o yield.o \
                time_rep_timespec.o nsync_panic.o
TEST_PLATFORM_C=../../platform/c++11/src/start_thread.cc
TEST_PLATFORM_OBJS=start_thread.o
include ../../platform/posix/make.common
include dependfile
```

Run:

```
$ make depend nsync.a
```

Outputs to (local directory):

```
tensorflow/contrib/makefile/downloads/nsync/builds/x86_64.android.clang/nsync.a
```

Confirm the architecture:

```
$ ~/android-toolchains/ndk-19-api-21-x86_64-clang/bin/x86_64-linux-android-objdump -f nsync.a
```

**Build android x86_64 library for emulator:**

First reset the PATH variable then update the NDK_ROOT and PATH:

```
$ export NDK_ROOT=~/android-toolchains/ndk-19-api-21-x86-clang
$ export PATH=$NDK_ROOT/bin:$PATH
```

From *downloads/nsync:*

```
$ mkdir builds/x86.android.clang
$ cd builds/x86.android.clang
$ touch Makefile
$ touch dependfile
```

Add the following to the Makefile, which is taken from the *android* target in *compile_nysnc.sh*:

```
AR=i686-linux-android-ar
CC=i686-linux-android21-clang++
PLATFORM_CPPFLAGS=-DNSYNC_USE_CPP11_TIMEPOINT -DNSYNC_ATOMIC_CPP11 \
                    -I../../platform/c++11 -I../../platform/gcc \
                    -I../../platform/posix -pthread
PLATFORM_CFLAGS=-std=c++11 -Wno-narrowing -fPIE -fPIC
PLATFORM_LDFLAGS=-pthread
MKDEP=${CC} -x c++ -M -std=c++11
PLATFORM_C=../../platform/c++11/src/nsync_semaphore_mutex.cc \
            ../../platform/posix/src/per_thread_waiter.c \
            ../../platform/c++11/src/yield.cc \
            ../../platform/c++11/src/time_rep_timespec.cc \
            ../../platform/c++11/src/nsync_panic.cc
PLATFORM_OBJS=nsync_semaphore_mutex.o per_thread_waiter.o yield.o \
                time_rep_timespec.o nsync_panic.o
TEST_PLATFORM_C=../../platform/c++11/src/start_thread.cc
TEST_PLATFORM_OBJS=start_thread.o
include ../../platform/posix/make.common
include dependfile
```

Run:

```
$ make depend nsync.a
```

Outputs to (local directory):

```
tensorflow/contrib/makefile/downloads/nsync/builds/x86.android.clang/nsync.a
```

Confirm the architecture:

```
$ ~/android-toolchains/ndk-19-api-21-x86_64-clang/bin/i686-linux-android-objdump -f nsync.a
```

**Cleanup**

Unset NDK_ROOT and clean up your PATH:

```
$ PATH=...
$ unset NDK_ROOT
```

## Build TensorFlow with clang

For this we'll use the ready made Makefile that we have modified for use with clang.

**Prepare Protoc**

First tell protoc where to find the shared protobuf library. The host protoc application is used to translate a number of protobuf files into c++ files that will be compiled for android:

From the root tensorflow repo directory:

```
$ export LD_LIBRARY_PATH=./tensorflow/contrib/makefile/gen/protobuf-host/lib/
```

**Prepare Protobuf Build Dirs**

Next symlink the protobuf build dirs to the locations expected by the makefile. 

We built to *gen-protobuf/x86_64.linux* but the tensorflow Makefile expects the build results at *gen/protobuf-host*. 

Similarly we built to *gen-protobuf/arm64-v8.android* and *gen-protobuf/x86_64.android* but the Makefile expects these built results at *gen/protobuf_android/arm64-v8a* and *gen/protobuf_android/x86_64* respectively.

From *tensorflow/contrib/makefile*:

```
$ mkdir gen
$ cd gen

$ ln -s ../gen-protobuf/x86_64.linux/ protobuf-host

$ mkdir protobuf_android
$ cd protobuf_android

$ ln -s ../../gen-protobuf/arm64-v8.android/ arm64-v8a
$ ln -s ../../gen-protobuf/x86_64.android/ x86_64
$ ln -s ../../gen-protobuf/x86.android/ x86
```

**Prepare Nsync Path**

Export the host nsync path:

```
$ export HOST_NSYNC_BUILD=x86_64.linux.c++11
```

**Build Android arm64-v8 library:**

Update the NDK_ROOT but do not update PATH

```
$ export NDK_ROOT=~/android-toolchains/ndk-19-api-21-arm64-clang
```

Export the target nysnc path:

```
$ export TARGET_NSYNC_LIB=tensorflow/contrib/makefile/downloads/nsync/builds/aarch64.android.clang/nsync.a
```

From the repository's root directory, compile tensorflow and grab yourself a cup of coffee:

```
$ make -f tensorflow/contrib/makefile/Makefile TARGET=ANDROID ANDROID_ARCH=arm64-v8a
```

If you find that you must rebuild clean the all directories in *gen* that you did not create yourself. Refer to the list in the last step of this section below.

Outputs results in *tensorflow/contrib/makefile* to:

```
gen/lib/android_arm64-v8a/libtensorflow-core.a
```

Confirm architecture:

```
$ ~/android-toolchains/ndk-19-api-21-arm64-clang/bin/aarch64-linux-android-objdump -f gen/lib/android_arm64-v8a/libtensorflow-core.a
```

Clean the gen directories for the next build. We don't run *make clean* because it completely blows out the gen dir.

```
$ rm -r dep
$ rm -r host_bin
$ rm -r host_obj
$ rm -r obj
$ rm -r proto
$ rm -r proto_text
```

**Build Android x86_64 (emulator) library:**

Update the NDK_ROOT but do not update PATH

```
$ export NDK_ROOT=~/android-toolchains/ndk-19-api-21-x86_64-clang
```

Export the target nysnc path:

```
$ export TARGET_NSYNC_LIB=tensorflow/contrib/makefile/downloads/nsync/builds/x86_64.android.clang/nsync.a
```

From the repository's root directory, compile tensorflow and grab yourself a another cup of coffee:

```
$ make -f tensorflow/contrib/makefile/Makefile TARGET=ANDROID ANDROID_ARCH=x86_64
```

Outputs results in *tensorflow/contrib/makefile* to:

```
gen/lib/android_x86_64/libtensorflow-core.a
```

Confirm architecture:

```
$ ~/android-toolchains/ndk-19-api-21-x86_64-clang/bin/x86_64-linux-android-objdump -f gen/lib/android_x86_64/libtensorflow-core.a
```

Clean the gen directories for the next build. We don't run *make clean* because it completely blows out the gen dir.

```
$ rm -r dep
$ rm -r host_bin
$ rm -r host_obj
$ rm -r obj
$ rm -r proto
$ rm -r proto_text
```

**Build Android x86 (emulator) library:**

Update the NDK_ROOT but do not update PATH

```
$ export NDK_ROOT=~/android-toolchains/ndk-19-api-21-x86-clang
```

Export the target nysnc path:

```
$ export TARGET_NSYNC_LIB=tensorflow/contrib/makefile/downloads/nsync/builds/x86.android.clang/nsync.a
```

From the repository's root directory, compile tensorflow and grab yourself another cup of coffee:

```
$ make -f tensorflow/contrib/makefile/Makefile TARGET=ANDROID ANDROID_ARCH=x86
```

Outputs results in *tensorflow/contrib/makefile* to:

```
gen/lib/android_x86/libtensorflow-core.a
```

Confirm architecture:

```
$ ~/android-toolchains/ndk-19-api-21-x86-clang/bin/i686-linux-android-objdump -f gen/lib/android_x86/libtensorflow-core.a
```

## Binaries

You now have the required binaries at the following paths in *tensorflow/contrib/makefile*

**arm64-v8:**

```
gen-protobuf/arm64-v8.android/lib/libprotobuf.a
downloads/nsync/builds/aarch64.android.clang/nsync.a
gen/lib/android_arm64-v8a/libtensorflow-core.a
```

**x86_64 (emulator):**

```
gen-protobuf/x86_64.android/lib/libprotobuf.a
downloads/nsync/builds/x86-64.android.clang/libnsync.a
gen/lib/android_x86_64/libtensorflow-core.a
```

**x86 (emulator):**

```
gen-protobuf/x86.android/lib/libprotobuf.a
downloads/nsync/builds/x86.android.clang/libnsync.a
gen/lib/android_x86/libtensorflow-core.a
```