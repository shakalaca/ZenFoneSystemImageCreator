#!/bin/bash

source ../scripts/setup.bash

cp -R ../root/* system

cp system/bin/sh system/xbin/sugote-mksh
mkdir system/bin/.ext
cp system/xbin/su system/bin/.ext/.su
cp system/xbin/su system/xbin/sugote
cp system/xbin/su system/xbin/daemonsu

rm system/bin/app_process
ln -s /system/xbin/daemonsu system/bin/app_process

if [ ! -z "$ROOT_SURVIVAL" ] || [ ! -z "$SLIM_DOWN" ]; then
  mv system/bin/app_process32 system/bin/app_process32_original
  ln -s /system/xbin/daemonsu system/bin/app_process32
  cp system/bin/app_process32_original system/bin/app_process_init
  
  cp system/etc/install-recovery.sh system/etc/install-recovery.sh.bak  
fi
