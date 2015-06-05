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
  #BRANCH=android-4.4.4_r2
  #BRANCH=android-4.3_r3

  git clone https://android.googlesource.com/platform/system/core
  cd core; git checkout -b $BRANCH $BRANCH; cd ..
  git clone https://android.googlesource.com/platform/external/bzip2
  cd bzip2; git checkout -b $BRANCH $BRANCH; cd ..
  git clone https://android.googlesource.com/platform/external/zlib
  cd zlib; git checkout -b $BRANCH $BRANCH; cd ..
  git clone https://android.googlesource.com/platform/bootable/recovery
  cd recovery; git checkout -b $BRANCH $BRANCH; cd ..

  patch -p1 -i ../assets/applypatch.patch
fi

cd zlib/src
gcc -O3 -DUSE_MMAP -I.. \
    -c adler32.c compress.c crc32.c deflate.c gzclose.c gzlib.c gzread.c \
       gzwrite.c infback.c inflate.c inftrees.c inffast.c trees.c uncompr.c \
       zutil.c
ar rcs libz.a *.o
cd ../..

cd bzip2
gcc -O3 -DUSE_MMAP \
    -c blocksort.c huffman.c crctable.c randtable.c compress.c decompress.c bzlib.c
ar rcs libbz.a *.o
cd ..

cd core/libmincrypt
gcc -c rsa.c sha.c sha256.c -I ../include
ar rcs libmincrypt.a *.o
cd ../..

if [ "$(uname)" != "Darwin" ] && [[ $(uname -s) != "CYGWIN"* ]]; then
  cd recovery/mtdutils
  gcc -O3 -DUSE_MMAP -c {mounts,mtdutils}.{h,c}
  ar rcs libmtdutils.a *.o
  cd ../..
  LIB_MTDUTILS=../mtdutils/libmtdutils.a
fi

cd recovery/applypatch
gcc -I ../../core/include -I .. \
    -o applypatch \
    main.c applypatch.c bsdiff.c freecache.c imgpatch.c utils.c bspatch.c \
    ../../core/libmincrypt/libmincrypt.a \
    ../../zlib/src/libz.a \
    ../../bzip2/libbz.a $LIB_MTDUTILS
cp applypatch $WORK_DIR
cd ../..
