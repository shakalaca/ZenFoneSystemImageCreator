#!/bin/bash

source ../scripts/setup.bash

if [ ! -z "$SLIM_DOWN" ]; then
  VARIANT=slim
else
  VARIANT=full
fi

cd $VERSION
md5sum boot.img > md5sum
md5sum droidboot.img >> md5sum
md5sum recovery.img >> md5sum

if [ -n "$SPLIT_SIZE" ]; then
#  7z a -mx9 -v$SPLIT_SIZE system.img.zip system.img
  zip ${VERSION}_system_w_root.zip system.img -s $SPLIT_SIZE
  md5sum *.z* >> md5sum
else
  zip system-${VARIANT}.img.zip system.img
  md5sum system-${VARIANT}.img.zip >> md5sum
fi
