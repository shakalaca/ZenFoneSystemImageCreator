#!/bin/sh
# Copyright (C) 2015 by Gwenhael Le Moine

case $1 in
    "")
	echo "Usage $0 </path/SuperSU.zip>"
	;;
    *)
	SUPERSU_ZIP=$1

	TEMP_SUPERSU=new_supersu
	SU_ARCH=x86

	mv root root.orig_$(date +%F)
	[ -e $TEMP_SUPERSU ] && rm -r $TEMP_SUPERSU

	mkdir -p root/{app,etc,lib,xbin}

	unzip $SUPERSU_ZIP -d $TEMP_SUPERSU

	cp $TEMP_SUPERSU/common/Superuser.apk root/app/Superuser.apk
	cp $TEMP_SUPERSU/common/install-recovery.sh root/etc/
	cp $TEMP_SUPERSU/$SU_ARCH/libsupol.so root/lib/
	cp $TEMP_SUPERSU/$SU_ARCH/{su,supolicy} root/xbin/
	echo 1 > root/etc/.installed_su_daemon

	rm -fr $TEMP_SUPERSU
esac
