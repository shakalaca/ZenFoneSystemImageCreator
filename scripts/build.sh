#!/bin/sh

apply_overlay() {
  if [ -d ../assets/$1 ]; then
    pushd ../assets/$1 > /dev/null
      tar cf - . | (cd ../../work/system; tar xfp -)
    popd > /dev/null
  fi
}

add_new_vold() {
  apply_overlay new_vold
}

add_root_survival() {
  apply_overlay root_survival
}

move_out_image() {
  if [ -f unzipped_rom/$1.img ]; then
    mv unzipped_rom/$1.img .
  fi
}

source scripts/setup.bash

cd work

# change version here
wget -c $ROM_URL -O dl_rom.zip
if [ -n "$OTA_URL" ]; then
  wget -c $OTA_URL -O ota.zip
fi
if [ -n "$ZIP_FILE" ]; then
  unzip dl_rom.zip
  unzip $ZIP_FILE -d unzipped_rom
else
  unzip dl_rom.zip -d unzipped_rom
fi

# just to get file_contexts
#./unpack_intel UL-ASUS_T00F-WW-1.17.40.16-user/boot.img bzImage ramdisk.cpio.gz
#mkdir ramdisk; cd ramdisk
#gzcat ../ramdisk.cpio.gz | cpio -i
#cd ..

mv unzipped_rom/system .
../scripts/create_link_file.sh unzipped_rom/META-INF/com/google/android/updater-script ../scripts/$LINK_PERM_SETUP_FILE
if [ -f $ZIP_FILE ]; then
  rm -rf $ZIP_FILE
fi

move_out_image boot
move_out_image droidboot
move_out_image recovery

if [ -d unzipped_rom/recovery ]; then
  pushd unzipped_rom/recovery > /dev/null
  tar cf - . | (cd ../../system; tar xfp -)
  popd > /dev/null
  
  grep "applypatch -b" unzipped_rom/recovery/bin/install-recovery.sh > build_recovery_pass1
  sed -e 's/applypatch/.\/applypatch/' -e 's/\/system/system/g' build_recovery_pass1 > build_recovery_pass2
  sed -e 's/EMMC:\/dev\/block\/by-name\/boot.*EMMC:\/dev\/block\/by-name\/recovery/boot.img recovery.img/' build_recovery_pass2 > build_recovery_pass3
  sed -e 's/ \&\&.*//' build_recovery_pass3 > build_recovery.sh
  
  . build_recovery.sh 
   
  rm build_recovery_pass*
  rm build_recovery.sh
fi

rm -rf unzipped_rom

read -p 'Press any key to build system.img .. '

../scripts/$LINK_PERM_SETUP_FILE
../scripts/apply_ota.sh
../scripts/link_and_set_perm_root
if [ ! -z "$SLIM_DOWN" ]; then
  # Remove apps listed in exclude_apps_list
  ../scripts/exclude_apps.sh
  # Enable sdcard write permission in platform.xml
  ../scripts/enable_sdcard_write.sh
  # Install Xposed
  ../scripts/install_xposed.sh
  # Add vold with ntfs support
  add_new_vold
  # Slim down version do not need root survival
  unset ROOT_SURVIVAL
fi

if [ ! -z "$ROOT_SURVIVAL" ]; then
  add_root_survival
fi

if [ -n "$FILE_CONTEXT" ]; then
    FCOPT="-S ../assets/$FILE_CONTEXT"
    if [ ! -z "$ROOT_SURVIVAL" ] || [ ! -z "$SLIM_DOWN" ]; then
        FCOPT="$FCOPT"_fix
    fi
fi
    
./make_ext4fs -s -l $SYSTEM_SIZE -a system $FCOPT system.img system

