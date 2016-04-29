#!/bin/bash

BIN_DIR=$(pwd)/bin/$(uname)

if [ ! -d $BIN_DIR ]; then
  mkdir -p $BIN_DIR
fi

if [ ! -d src ]; then
  mkdir src
fi 
cd src

# if you do not want to fetch source again ..
#DO_NOT_FETCH=1

if [ -z "$DO_NOT_FETCH" ]; then
  BRANCH=LA.BR.1.1.3.c1

  #git clone -b $BRANCH https://android.googlesource.com/platform/external/libselinux
  #git clone -b $BRANCH https://android.googlesource.com/platform/system/core
  #git clone -b $BRANCH https://android.googlesource.com/platform/external/zlib
  #git clone -b $BRANCH https://android.googlesource.com/platform/system/extras
  git clone git://codeaurora.org/quic/la/platform/external/libselinux
  cd libselinux; git checkout -b $BRANCH origin/$BRANCH; cd ..
  git clone git://codeaurora.org/quic/la/platform/external/pcre
  cd pcre; git checkout -b $BRANCH origin/$BRANCH; cd ..
  git clone git://codeaurora.org/quic/la/platform/system/core
  cd core; git checkout -b $BRANCH origin/$BRANCH; cd ..
  git clone git://codeaurora.org/quic/la/platform/external/zlib
  cd zlib; git checkout -b $BRANCH origin/$BRANCH; cd ..
  git clone git://codeaurora.org/quic/la/platform/system/extras
  cd extras; git checkout -b $BRANCH origin/$BRANCH; cd ..

  cd core; patch -p1 -i ../../assets/fs_supersu.patch; cd ..

  if [[ $(uname -s) == "CYGWIN"* ]]; then 
    patch -p1 -i ../assets/make_ext4fs.patch
  fi
fi

# for extract boot.img
#git clone https://github.com/xiaolu/intel-boot-tools.git

# build for make_ext4fs
cd pcre
gcc -DHAVE_CONFIG_H -I. -Idist -I../core/include \
    -c pcre_chartables.c \
    dist/pcre_byte_order.c dist/pcre_compile.c dist/pcre_config.c \
    dist/pcre_dfa_exec.c dist/pcre_exec.c dist/pcre_fullinfo.c \
    dist/pcre_get.c dist/pcre_globals.c dist/pcre_jit_compile.c \
    dist/pcre_maketables.c dist/pcre_newline.c dist/pcre_ord2utf8.c \
    dist/pcre_refcount.c dist/pcre_string_utils.c dist/pcre_study.c \
    dist/pcre_tables.c dist/pcre_ucd.c dist/pcre_valid_utf8.c \
    dist/pcre_version.c dist/pcre_xclass.c
cd ../
    
cd libselinux/src
CFLAGS=-DHOST
if [ "$(uname)" == "Darwin" ]; then
  CFLAGS="$CFLAGS -DDARWIN"
fi
gcc $CFLAGS -I../include -I../../core/include -I../../pcre \
    -c callbacks.c check_context.c freecon.c init.c label.c label_file.c \
       label_android_property.c
ar rcs libselinux.a *.o ../../pcre/*.o
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
cp simg2img $BIN_DIR
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
cp make_ext4fs $BIN_DIR
gcc -DANDROID \
    -I../../libselinux/include -I../../core/libsparse/include -I../../core/include/ \
    -o ext2simg \
       ext2simg.c \
       make_ext4fs.c ext4fixup.c ext4_utils.c allocate.c contents.c extent.c \
       indirect.c uuid.c sha1.c wipe.c crc16.c ext4_sb.c \
       ../../libselinux/src/libselinux.a \
       ../../core/libsparse/libsparse.a \
       ../../zlib/src/libz.a
cp ext2simg $BIN_DIR
cd ../..

#cd intel-boot-tools
#make
#mv unpack_intel $BIN_DIR
#mv pack_intel $BIN_DIR
#cd ..
