#!/bin/bash

apply_overlay() {
  if [ -d $ASSETSDIR/$1 ]; then
    pushd $ASSETSDIR/$1 > /dev/null
      tar cf - . | (cd $BASEDIR/system; tar xfp -)
    popd > /dev/null
  fi
}

add_new_vold() {
  apply_overlay new_vold
}

add_root_survival() {
  apply_overlay root_survival
}

add_byeselinux() {
  cp $ASSETSDIR/byeselinux/byselinux.ko $1
}

add_stop_service() {
  apply_overlay stop_service
}

cleanup_launcher() {
  find system/vendor -name default_allapp.xml -delete
  find system/vendor -name phone_workspace.xml -exec cp $ASSETSDIR/phone_workspace.xml {} \;
}

force_adoptable_storage() {
  echo "persist.fw.force_adoptable=true" >> system/build.prop
}

move_out_image() {
  if [ -f $UNZIPPED_STOCK_ROM_DIR/$1.img ]; then
    echo "Move out stock $1.img .. "
    cp $UNZIPPED_STOCK_ROM_DIR/$1.img .
  fi
}

build_recovery_from_patch() {
  # Prepare script
  grep "applypatch -b" system/bin/install-recovery.sh > build_recovery_pass1
  sed -e 's/applypatch/$BIN_DIR\/applypatch/' \
      -e 's/\/system/system/g' \
      -e 's/EMMC:\/dev\/block\/bootdevice\/by-name\/boot.*EMMC:\/dev\/block\/bootdevice\/by-name\/recovery/boot.img recovery.img/' \
      -e 's/ \&\&.*//' build_recovery_pass1 > build_recovery.sh

  . build_recovery.sh > /dev/null
 
  # Clean up
  rm build_recovery_pass*
  rm build_recovery.sh
}

link_system_files() {
  UPDATER_SCRIPT=$1
  
  cat $1 | sed 's/        /symlink("toolbox", /' > link_pass1
  grep 'symlink' link_pass1 > link_pass2
  cat link_pass2 | sed -e 's/symlink(\"/symlink /' -e 's/\", \"/ /g' -e 's/\");//' -e 's/\",//' > link.sh
  
  . link.sh

  rm link_pass*
  rm link.sh
}

symlink() {
  SOURCE=$1
  shift
  for TARGET in "$@"
  do
    TARGET=${TARGET:1}
    XPATH=${TARGET%/*}
    XFILE=${TARGET##*/}
    
    if [ ! -d $XPATH ]; then
      mkdir -p $XPATH
    fi

    pushd $XPATH > /dev/null
      ln -s $SOURCE $XFILE
    popd > /dev/null
  done
}

source scripts/setup.bash

BIN_DIR=$(pwd)/bin/$(uname)

cd work

BASEDIR=$(pwd)

SCRIPTDIR=../scripts
ASSETSDIR=../assets
UNZIPPED_STOCK_ROM_DIR=unzipped_rom

STOCK_ROM=dl_rom.zip
STOCK_OTA=dl_ota.zip

if [ ! -d system ]; then
  # Download stock ROM
  if [ ! -f $STOCK_ROM ]; then
    wget -c $ROM_URL -O $STOCK_ROM
  fi
  
  # Download OTA package
  if [ -n "$OTA_URL" ]; then
    if [ ! -f $STOCK_OTA ]; then
      wget -c $OTA_URL -O $STOCK_OTA
    fi
  fi

  if [ ! -f system.img.ext4 ]; then
    if [ -f $STOCK_OTA ]; then
      $SCRIPTDIR/apply_ota_on_phone.sh
    else 
      echo "Extracting stock ROM .. "
      unzip -q $STOCK_ROM -d $UNZIPPED_STOCK_ROM_DIR

      echo "Move out system images .. "
      mv $UNZIPPED_STOCK_ROM_DIR/system.* .

      echo "Move out modem images .. "      
      mv $UNZIPPED_STOCK_ROM_DIR/firmware-update .
      
      move_out_image boot

      echo "Clean up .. "
      rm -rf $UNZIPPED_STOCK_ROM_DIR

      echo "Converting system.new.dat to raw ext4 image .. "
      mv system.transfer.list system.transfer.list.orig
      grep -v zero system.transfer.list.orig > system.transfer.list
      $SCRIPTDIR/sdat2img.py system.transfer.list system.new.dat system.img.ext4
      rm -f system.transfer.list.orig system.transfer.list system.new.dat system.patch.dat
    fi
  elif [ ! -f boot.img ]; then
    echo "Move out stock boot.img .. "
    unzip -q $STOCK_ROM boot.img
  fi

#  echo "Making backup header of system.img.ext4 .. "
  # to restore header:
  # dd if=header.bak of=system.img.ext4 conv=notrunc
#  dd if=system.img.ext4 of=header.bak count=1 bs=4096
  
  echo "Mount raw image .. "
  mkdir mnt
  sudo mount -o loop,ro system.img.ext4 mnt

  echo "Copy system directory .. "
  sudo cp -r mnt system  

  if [ ! -z "$EXCLUDE_UPDATE" ]; then 
    echo "Removing SystemUpdate & DMClient by default .. "
    mkdir -p excluded_apps/app
    mv -f system/app/SystemUpdate excluded_apps/app
    mv -f system/app/DMClient excluded_apps/app
  fi
  
  echo "Un-mount raw image .. "
  sudo umount mnt
  rmdir mnt
  
  echo "Building recovery .. "
  build_recovery_from_patch
  
  read -p 'Press any key to build system.img .. '
fi

if [ -f system.img.ext4 ]; then
  SYSTEM_SIZE=$(stat -c%s system.img.ext4)
  echo "Update SYSTEM_SIZE to $SYSTEM_SIZE .. "
fi

#echo "Disable SELinux .. "
#add_byeselinux system/lib/modules/adsprpc.ko

echo "Install SuperSU .. "
$SCRIPTDIR/install_supersu.sh

# For slim down version
if [ ! -z "$SLIM_DOWN" ]; then
  echo "Remove apps listed in exclude_apps_list .. "
  $SCRIPTDIR/exclude_apps.sh
  
  echo "Enable sdcard write permission in platform.xml .. "
  $SCRIPTDIR/enable_sdcard_write.sh
  
  echo "Clean up launcher workspace .. "
  cleanup_launcher
  
  echo "Install Xposed .. "
  $SCRIPTDIR/install_xposed.sh

#  echo "Enable Adoptable Storage .. "
#  force_adoptable_storage

  add_stop_service
fi

# Set the right file_context file for SELinux permission
if [ -n "$FILE_CONTEXT" ]; then
  FCOPT="-S $ASSETSDIR/$FILE_CONTEXT"
fi

echo "Build system.img .. "
echo $BIN_DIR/make_ext4fs -s -l $SYSTEM_SIZE -a system $FCOPT system.img system
$BIN_DIR/make_ext4fs -s -l $SYSTEM_SIZE -a system $FCOPT system.img system

echo "Finish building $VERSION .. "
if [ ! -d $VERSION ]; then
  mkdir $VERSION
fi

if [ -d firmware-update ]; then
  mv firmware-update $VERSION
fi
mv *.img $VERSION

# ZIP and md5sum
if [ -n "$SPLIT_SIZE" ] || [ -n "$SLIM_DOWN" ]; then
  $SCRIPTDIR/prepare_upload.sh
fi
