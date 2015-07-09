#!/bin/sh

WORK_DIR=$(pwd)/work

if [ ! -d $WORK_DIR ]; then
  mkdir $WORK_DIR
fi

if [ ! -d src ]; then
  mkdir src
fi 
cd src

# if you do not want to fetch source again ..
#DO_NOT_FETCH=1

if [ -z "$DO_NOT_FETCH" ]; then
  BRANCH=android-5.0.0_r7
  #BRANCH=android-4.3_r3

  #git clone -b $BRANCH https://android.googlesource.com/platform/external/libselinux
  #git clone -b $BRANCH https://android.googlesource.com/platform/system/core
  #git clone -b $BRANCH https://android.googlesource.com/platform/external/zlib
  #git clone -b $BRANCH https://android.googlesource.com/platform/system/extras
  git clone https://android.googlesource.com/platform/external/libselinux
  cd libselinux; git checkout -b $BRANCH $BRANCH; cd ..
  git clone https://android.googlesource.com/platform/system/core
  cd core; git checkout -b $BRANCH $BRANCH; cd ..
  git clone https://android.googlesource.com/platform/external/zlib
  cd zlib; git checkout -b $BRANCH $BRANCH; cd ..
  git clone https://android.googlesource.com/platform/system/extras
  cd extras; git checkout -b $BRANCH $BRANCH; cd ..

  cd core; patch -p1 -i ../../assets/fs_supersu.patch; cd ..

  if [[ $(uname -s) == "CYGWIN"* ]]; then 
    patch -p1 -i ../assets/make_ext4fs.patch
  fi
fi

# for extract boot.img
#git clone https://github.com/xiaolu/intel-boot-tools.git

# build for make_ext4fs
cd libselinux/src
CFLAGS=-DHOST
if [ "$(uname)" == "Darwin" ]; then
  CFLAGS="$CFLAGS -DDARWIN"
fi
gcc $CFLAGS -I../include -I../../core/include \
    -c callbacks.c check_context.c freecon.c init.c label.c label_file.c \
       label_android_property.c
ar rcs libselinux.a *.o
cd ../..
 
cd zlib/src
gcc -O3 -DUSE_MMAP -I.. \
    -c adler32.c compress.c crc32.c deflate.c gzclose.c gzlib.c gzread.c \
       gzwrite.c infback.c inflate.c inftrees.c inffast.c trees.c uncompr.c \
       zutil.c
ar rcs libz.a *.o
cd ../..
 
cd core/libsparse
gcc -Iinclude \
    -c backed_block.c output_file.c sparse.c sparse_crc32.c sparse_err.c \
       sparse_read.c 
ar rcs libsparse.a *.o
gcc -Iinclude -I../../zlib \
    -o simg2img simg2img.c sparse_crc32.c \
    libsparse.a ../../zlib/src/libz.a
cp simg2img $WORK_DIR
cd ../..
 
cd extras/ext4_utils
gcc -DHOST -DANDROID \
    -I../../libselinux/include -I../../core/libsparse/include -I../../core/include/ \
    -o make_ext4fs \
       make_ext4fs_main.c make_ext4fs.c ext4fixup.c ext4_utils.c \
       allocate.c contents.c extent.c indirect.c uuid.c sha1.c wipe.c crc16.c \
       ext4_sb.c canned_fs_config.c \
       ../../libselinux/src/libselinux.a \
       ../../core/libsparse/libsparse.a \
       ../../zlib/src/libz.a
cp make_ext4fs $WORK_DIR
gcc -DANDROID \
    -I../../libselinux/include -I../../core/libsparse/include -I../../core/include/ \
    -o ext2simg \
       ext2simg.c \
       make_ext4fs.c ext4fixup.c ext4_utils.c allocate.c contents.c extent.c \
       indirect.c uuid.c sha1.c wipe.c crc16.c ext4_sb.c \
       ../../libselinux/src/libselinux.a \
       ../../core/libsparse/libsparse.a \
       ../../zlib/src/libz.a
cp ext2simg $WORK_DIR
cd ../..

#cd intel-boot-tools
#make
#mv unpack_intel $WORK_DIR
#mv pack_intel $WORK_DIR
#cd ..
