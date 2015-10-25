#!/bin/bash

source ../scripts/setup.bash

XPOSED_DIR=../xposed

install_overwrite() {
  TARGET=${1:1}
  BACKUP="${1:1}.orig"
  NO_ORIG="${1:1}.no_orig"
  if [ ! -f $TARGET ]; then
    touch $NO_ORIG
  elif [ ! -f $BACKUP -a ! -f $NO_ORIG ]; then
    mv $TARGET $BACKUP
  fi
  cp $XPOSED_DIR/$TARGET $TARGET
}

cp $XPOSED_DIR/system/xposed.prop system/
cp $XPOSED_DIR/system/framework/XposedBridge.jar system/framework/
cp $XPOSED_DIR/system/bin/app_process32_xposed system/bin/
cp $XPOSED_DIR/system/bin/app_process64_xposed system/bin/
cp -r $XPOSED_DIR/system/app/XposedInstaller system/app/

install_overwrite /system/bin/dex2oat
install_overwrite /system/bin/oatdump
install_overwrite /system/bin/patchoat
install_overwrite /system/lib/libart.so
install_overwrite /system/lib/libart-compiler.so
install_overwrite /system/lib/libart-disassembler.so
install_overwrite /system/lib/libsigchain.so
install_overwrite /system/lib/libxposed_art.so

install_overwrite /system/lib64/libart.so
install_overwrite /system/lib64/libart-compiler.so
install_overwrite /system/lib64/libart-disassembler.so
install_overwrite /system/lib64/libsigchain.so
install_overwrite /system/lib64/libxposed_art.so
