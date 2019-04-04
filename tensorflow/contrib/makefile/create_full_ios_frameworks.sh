#! /bin/sh

#!/usr/bin/env bash
# Copyright 2015 The TensorFlow Authors. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ==============================================================================

# Must be run after: build_all_ios.sh
# Creates an iOS framework which is placed under:
#    gen/ios_frameworks/tensorflow.framework.zip

set -e
pushd .

echo "Starting full build"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TMP_DIR=$(mktemp -d)
echo "Package dir: " $TMP_DIR
FW_DIR=$TMP_DIR/tensorflow_ios_frameworks
FW_DIR_TFCORE=$FW_DIR/tensorflow.framework
FW_DIR_TFCORE_HDRS=$FW_DIR_TFCORE/Headers

echo "Creating target Headers directories"
mkdir -p $FW_DIR_TFCORE_HDRS

echo "Copy existing LICENSE file to target"
cp $SCRIPT_DIR/../../../LICENSE \
   $FW_DIR_TFCORE

echo "Copying static libraries"
cp $SCRIPT_DIR/gen/lib/libtensorflow-core.a \
   $FW_DIR_TFCORE/tensorflow
cp $SCRIPT_DIR/gen/protobuf_ios/lib/libprotobuf.a \
   $FW_DIR_TFCORE/libprotobuf

# Copy nsync (forget where this is built from and generated to)
# ...

chmod +x $FW_DIR_TFCORE/tensorflow
chmod +x $FW_DIR_TFCORE/libprotobuf
# chmod +x $FW_DIR_TFCORE/nsync

# tensorflow

echo "Headers, populating: tensorflow (core)"
cd $SCRIPT_DIR/../../..
find tensorflow -name "*.h" | tar -cf $FW_DIR_TFCORE_HDRS/tmp.tar -T -
cd $FW_DIR_TFCORE_HDRS
tar xf tmp.tar
rm -f tmp.tar

# ./downloads/nsync/public

echo "Headers, populating: nsync"
cd $SCRIPT_DIR/downloads/nsync/public
find . -name "*.h" | tar -cf $FW_DIR_TFCORE_HDRS/tmp.tar -T -
cd $FW_DIR_TFCORE_HDRS
tar xf tmp.tar
rm -f tmp.tar

# eigen :: this is ridiculous

mkdir -p $FW_DIR_TFCORE_HDRS/third_party

# third_party/ eigen3

echo "Headers, populating: eigen (third party)"
cd $SCRIPT_DIR/../../../third_party
tar -cf $FW_DIR_TFCORE_HDRS/third_party/tmp.tar eigen3
cd $FW_DIR_TFCORE_HDRS/third_party
tar xf tmp.tar
rm -f tmp.tar

# ./downloads/eigen/ unsupported -> unsupported

echo "Headers, populating: eigen (unsupported)"
cd $SCRIPT_DIR/downloads/eigen
tar -cf $FW_DIR_TFCORE_HDRS/tmp.tar unsupported
cd $FW_DIR_TFCORE_HDRS
tar xf tmp.tar
rm -f tmp.tar

# ./downloads/eigen/ Eigen -> Eigen

echo "Headers, populating: eigen"
cd $SCRIPT_DIR/downloads/eigen
tar -cf $FW_DIR_TFCORE_HDRS/tmp.tar Eigen
cd $FW_DIR_TFCORE_HDRS
tar xf tmp.tar
rm -f tmp.tar

# ./downloads/absl/ absl

echo "Headers, populating: absl"
cd $SCRIPT_DIR/downloads/absl
find absl -name "*.h" | tar -cf $FW_DIR_TFCORE_HDRS/tmp.tar -T -
cd $FW_DIR_TFCORE_HDRS
tar xf tmp.tar
rm -f tmp.tar

# ./downloads/protobuf/src/ google

echo "Headers, populating: google (proto src)"
cd $SCRIPT_DIR/downloads/protobuf/src
find google -name "*.h" | tar -cf $FW_DIR_TFCORE_HDRS/tmp.tar -T -
cd $FW_DIR_TFCORE_HDRS
tar xf tmp.tar
rm -f tmp.tar

# ./gen/proto/ tensorflow

echo "Headers, populating: tensorflow (protos)"
cd $SCRIPT_DIR/gen/proto
find tensorflow -name "*.h" | tar -cf $FW_DIR_TFCORE_HDRS/tmp.tar -T -
cd $FW_DIR_TFCORE_HDRS
tar xf tmp.tar
rm -f tmp.tar

# Don't include the auto downloaded/generated to build this library

rm -rf tensorflow/contrib/makefile

# This is required, otherwise they interfere with the documentation of the
# pod at cocoapods.org

echo "Remove all README files"
cd $FW_DIR_TFCORE_HDRS
find . -type f -name README\* -exec rm -f {} \;
find . -type f -name readme\* -exec rm -f {} \;

# Move to target location

TARGET_GEN_LOCATION="$SCRIPT_DIR/gen/ios_frameworks"
echo "Moving results to target: " $TARGET_GEN_LOCATION
cd $FW_DIR
zip -q -r tensorflow.framework.zip tensorflow.framework -x .DS_Store
rm -rf $TARGET_GEN_LOCATION
mkdir -p $TARGET_GEN_LOCATION
cp -r tensorflow.framework.zip $TARGET_GEN_LOCATION

echo "Cleaning up"
popd
rm -rf $TMP_DIR

echo "Finished"
