#!/bin/bash

source ../scripts/setup.bash

if [ ! -f system/etc/.installed_su_daemon ]; then
cp -R ../root/* system

#cp system/bin/sh system/xbin/sugote-mksh
mkdir system/bin/.ext
cp system/xbin/daemonsu system/bin/.ext/.su
#cp system/xbin/su system/xbin/sugote
#cp system/xbin/su system/xbin/daemonsu

rm system/bin/app_process
ln -s /system/xbin/daemonsu system/bin/app_process

if [ ! -f system/bin/app_process64_original ]; then
  mv system/bin/app_process64 system/bin/app_process64_original
else 
  rm system/bin/app_process64
fi
ln -s /system/xbin/daemonsu system/bin/app_process64
if [ ! -f system/bin/app_process_init ]; then
  cp system/bin/app_process64_original system/bin/app_process_init
fi
fi
