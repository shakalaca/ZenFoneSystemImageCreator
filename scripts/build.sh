#!/bin/sh

apply_overlay() {
  if [ -d ../assets/overlay ]; then
    pushd ../assets/overlay > /dev/null
      tar cf - . | (cd ../../work/system; tar xfp -)
    popd > /dev/null
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
rm -rf unzipped_rom

cp -R ../root/* system

read -p 'Press any key to build system.img .. '

../scripts/$LINK_PERM_SETUP_FILE
../scripts/apply_ota.sh
../scripts/link_and_set_perm_root
# Uncomment to remove apps listed in exclude_apps_list
#../scripts/exclude_apps.sh
# Uncomment to enable sdcard write permission in platform.xml
#../scripts/enable_sdcard_write.sh
# Uncomment to override files in assets/overlay
#apply_overlay

if [ -n "$FILE_CONTEXT" ]; then
    FCOPT="-S ../assets/$FILE_CONTEXT"
    if [ ! -z "$FIX_SU_NOTIFICATION" ]; then
        FCOPT="$FCOPT"_fix
    fi
fi
    
./make_ext4fs -s -l $SYSTEM_SIZE -a system $FCOPT system.img system

