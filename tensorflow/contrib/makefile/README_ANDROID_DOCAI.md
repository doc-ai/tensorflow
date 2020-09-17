
# Compiling TensorFlow For Android With clang

Building TensorFlow for Android on Ubuntu with a standalone clang toolchain for API 21 from NDK 19.2.5345600.

## Package Prequisites

Install the following packages:

```
python build-essential git autoconf libtool automake curl unzip clang
```

## Toolchain

NDK 19?+ contain prebuilt toolchains, but you can build standalone toolchains as well. We'll start with standalone toolchains because that is what I have instructions for.

From Android Studio install NDK 19.2.5345600. It will be located at *~/Android/Sdk/ndk*

From the NDK 19.2.5345600 root directory create two standalone toolchains, one for arm64 (on device) and one for x86_64 (emulator):

```
$ build/tools/make_standalone_toolchain.py --arch arm64 --api 21 --stl libc++ --install-dir $HOME/android-toolchains/ndk-19-api-21-arm64-clang
$ build/tools/make_standalone_toolchain.py --arch x86_64 --api 21 --stl libc++ --install-dir $HOME/android-toolchains/ndk-19-api-21-x86_64-clang
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
$ mkdir gen
$ mkdir gen/protobuf
$ mkdir gen/protobuf/x86_64.linux
$ mkdir gen/protobuf/x86_64.android
$ mkdir gen/protobuf/arm64-v8.android
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

$ ../../configure --prefix=/home/phildow/GitHub/tensorflow/tensorflow/contrib/makefile/gen/protobuf/x86_64.linux
$ make install -j4
```

Outputs to:

```
gen/protobuf/x86_64.linux/lib/libprotobuf.a
```

Confirm the architecture:

```
objdump -f gen/protobuf/x86_64.linux/lib/libprotobuf.a
```

**Build android arm64-v8 library**

```
$ mkdir builds/arm64-v8.android
$ cd builds/arm64-v8.android

$ export NDK_ROOT=/home/phildow/android-toolchains/ndk-19-api-21-arm64-clang
$ export PATH=$NDK_ROOT/bin:$PATH

$ export CC=aarch64-linux-android21-clang
$ export CXX=aarch64-linux-android21-clang++
$ export CFLAGS="-fPIE -fPIC"
$ export LDFLAGS="-pie -llog"

$ ../../configure --host=aarch64-linux-android --prefix=/home/phildow/GitHub/tensorflow/tensorflow/contrib/makefile/gen/protobuf/arm64-v8.android --with-protoc=/home/phildow/GitHub/tensorflow/tensorflow/contrib/makefile/gen/protobuf/x86_64.linux/bin/protoc
$ make install -j4
```

Outputs to:

```
gen/protobuf/arm64-v8.android/lib/libprotobuf.a
```

Confirm the architecture:

```
~/android-toolchains/ndk-19-api-21-arm64-clang/bin/aarch64-linux-android-objdump -f gen/protobuf/arm64-v8.android/lib/libprotobuf.a
```

**Build android x86_64 library for emulator**

Patch the source according to the instructions here:

https://github.com/protocolbuffers/protobuf/issues/5144#issuecomment-688723405

Otherwise you will run into the following error during *make install*:

```
./.libs/libprotoc.so: error: undefined reference to 'descriptor_table_google_2fprotobuf_2fdescriptor_2eproto'
./.libs/libprotoc.so: error: undefined reference to 'scc_info_FileDescriptorProto_google_2fprotobuf_2fdescriptor_2eproto'
```

Reset the PATH variable, then run:

```
$ mkdir builds/x86_64.android
$ cd builds/x86_64.android

$ export NDK_ROOT=/home/phildow/android-toolchains/ndk-19-api-21-x86_64-clang
$ export PATH=$NDK_ROOT/bin:$PATH

$ export CC=x86_64-linux-android21-clang
$ export CXX=x86_64-linux-android21-clang++
$ export CFLAGS="-fPIE -fPIC"
$ export LDFLAGS="-pie -llog"

$ ../../configure --host=x86_64-linux-android --prefix=/home/phildow/GitHub/tensorflow/tensorflow/contrib/makefile/gen/protobuf/x86_64.android --with-protoc=/home/phildow/GitHub/tensorflow/tensorflow/contrib/makefile/gen/protobuf/x86_64.linux/bin/protoc
$ make install -j4
```

Outputs to:

```
gen/protobuf/x86_64.android/lib/libprotobuf.a
```

Confirm the architecture:

```
$ ~/android-toolchains/ndk-19-api-21-x86_64-clang/bin/x86_64-linux-android-objdump -f gen/protobuf/x86_64.linux/lib/libprotobuf.a
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
$ cd builds/x86_64.linux.clang
$ make depend nsync.a
```

Outputs to (local directory):

```
tensorflow/contrib/makefile/downloads/nsync/builds/x86_64.linux.clang/nsync.a
```

Check architecture:

```
objdump -f nsync.a
```

**Build android arm64 library:**

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

**Cleanup**

Unset NDK_ROOT and clean up your PATH:

```
$ PATH=...
$ unset NDK_ROOT
```

## Build TensorFlow with clang

For this we'll use the ready made Makefile that we have modified for use with clang.

Copy the protobuf build dirs to the locations expected by the makefile:

```
protobuf-host
protobuf_android/arm64-v8a
```