#!/bin/bash

cp -R ../root/* system

cp system/bin/mksh system/xbin/sugote-mksh
mkdir system/bin/.ext
cp system/xbin/su system/bin/.ext/.su
cp system/xbin/su system/xbin/sugote
cp system/xbin/su system/xbin/daemonsu
