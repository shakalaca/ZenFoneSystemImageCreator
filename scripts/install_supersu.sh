#!/bin/bash

source ../scripts/setup.bash

cp -R ../root/* system

mkdir system/bin/.ext
cp system/xbin/su system/bin/.ext/.su
cp system/xbin/su system/xbin/daemonsu

rm system/bin/app_process
ln -s /system/xbin/daemonsu system/bin/app_process
if [ ! -f system/bin/app_process32_original ]; then
  mv system/bin/app_process32 system/bin/app_process32_original
else 
  rm system/bin/app_process32
fi
ln -s /system/xbin/daemonsu system/bin/app_process32
if [ ! -f system/bin/app_process_init ]; then
  cp system/bin/app_process32_original system/bin/app_process_init
fi

cp system/etc/install-recovery.sh system/etc/install-recovery.sh.bak  
