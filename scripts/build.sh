#!/bin/sh

source scripts/setup.bash

cd work

# change version here
wget -c $ROM_URL -O dl_rom.zip
unzip dl_rom.zip
unzip $ZIP_FILE -d unzipped_rom

# just to get file_contexts
#./unpack_intel UL-ASUS_T00F-WW-1.17.40.16-user/boot.img bzImage ramdisk.cpio.gz
#mkdir ramdisk; cd ramdisk
#gzcat ../ramdisk.cpio.gz | cpio -i
#cd ..

mv unzipped_rom/system .
rm -rf $ZIP_FILE
rm -rf unzipped_rom

cp -R ../root/* system

read -p 'Press any key and enter sudo password to build system.img .. '

sudo ../scripts/$LINK_PERM_SETUP_FILE
sudo ../scripts/link_and_set_perm_root

if [ -n "$FILE_CONTEXT" ]; then
    FCOPT="-S ../scripts/$FILE_CONTEXT"
fi
    
# not sure if needed in 4.4
#sudo ./make_ext4fs -s -l 1363148800 -a system  -S ../file_contexts system.img system
sudo ./make_ext4fs -s -l $SYSTEM_SIZE -a system $FCOPT system.img system

