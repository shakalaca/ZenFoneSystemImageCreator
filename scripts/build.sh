#!/bin/sh

cd work

# change version here
wget -c http://dlcdnet.asus.com/pub/ASUS/ZenFone/A500CG/UL_ASUS_T00F_WW_1_17_40_16.zip
unzip UL_ASUS_T00F_WW_1_17_40_16.zip
unzip UL-ASUS_T00F-WW-1.17.40.16-user.zip -d UL-ASUS_T00F-WW-1.17.40.16-user

# just to get file_contexts
#./unpack_intel UL-ASUS_T00F-WW-1.17.40.16-user/boot.img bzImage ramdisk.cpio.gz
#mkdir ramdisk; cd ramdisk
#gzcat ../ramdisk.cpio.gz | cpio -i
#cd ..

mv UL-ASUS_T00F-WW-1.17.40.16-user/system .
cp -R ../root/* system

read -p 'Press any key to build system.img ..'

sudo ../scripts/link_and_set_perm
sudo ../scripts/link_and_set_perm_root

# not sure if needed in 4.4
#sudo ./make_ext4fs -s -l 1363148800 -a system  -S ../file_contexts system.img system
sudo ./make_ext4fs -s -l 1363148800 -a system system.img system
