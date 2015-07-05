#!/bin/bash

STOCK_OTA="$1"

if [ ! -f $STOCK_OTA ]; then
  echo OTA package not found !
  exit 1
fi

BASEDIR=$(pwd)
UNZIPPED_STOCK_OTA_DIR=unzipped_ota

apply_patch() {
  RES=""
  if [ "$1" == "-b" ]; then
    RES="-b ${2}"
    shift
    shift
  fi
  if [[ "$1" == "EMMC:/dev/block/by-name/boot"* ]]; then
    SOURCE=boot.img
  else
    SOURCE=${1:1}
  fi
  if [ "$2" == "EMMC:/dev/block/by-name/recovery" ]; then
    TARGET=recovery.img
    shift
  else
    TARGET=$SOURCE
  fi
  ./applypatch $RES $SOURCE $TARGET $2 $3 $4
}

delete() {
  for TARGET in "$@"
  do
    TARGET=${TARGET:1}
    if [ -d $TARGET ]; then
      rmdir $TARGET
    elif [ -f $TARGET ]; then
      rm $TARGET
    fi
  done
}

rename() {
  SOURCE=$1
  TARGET=$2
  XPATH=${TARGET%/*}
  if [ ! -d $XPATH ]; then
    mkdir -p $XPATH
  fi
  mv $SOURCE $TARGET
}

move_out_image() {
  if [ -f $UNZIPPED_STOCK_OTA_DIR/$1.img ]; then
    echo "Move out $1.img .. "
    cp $UNZIPPED_STOCK_OTA_DIR/$1.img .
  fi
}

echo "Unzipping OTA package .. "
unzip -q $STOCK_OTA -d $UNZIPPED_STOCK_OTA_DIR

move_out_image boot
move_out_image droidboot
move_out_image recovery

APPLY_PATCH_DONE=true
DELETE_CMD_DONE=true

while read line
do
  if [[ "$line" == "apply_patch("* ]]; then
    APPLY_PATCH_CMD=$(echo $line | sed -e 's/\r//g')
    APPLY_PATCH_DONE=false
  elif [[ "$line" == "delete("* ]]; then
    DELETE_CMD=$line
    if [[ "$line" == *");" ]]; then
      DELETE_CMD_DONE=true
      echo $DELETE_CMD >> delete_pass1
    else
      DELETE_CMD_DONE=false
    fi
  elif [[ "$line" == "rename"* ]]; then
    echo $line >> rename_pass1
  elif !($APPLY_PATCH_DONE); then
    APPLY_PATCH_CMD="$APPLY_PATCH_CMD $(echo $line | sed -e 's/\r//g')"
    if [[ "$line" == *"));" ]]; then
      APPLY_PATCH_DONE=true
      echo $APPLY_PATCH_CMD >> patch_pass1
    fi
  elif !($DELETE_CMD_DONE); then
    DELETE_CMD=$DELETE_CMD$line
    if [[ "$line" == *");" ]]; then
      DELETE_CMD_DONE=true
      echo $DELETE_CMD >> delete_pass1
    fi
  fi
done < $UNZIPPED_STOCK_OTA_DIR/META-INF/com/google/android/updater-script

echo "Patching system files .."
sed -e 's/apply_patch(\"/apply_patch /' -e 's/, package_extract_file(\"/:\$UNZIPPED_STOCK_OTA_DIR\//' patch_pass1 > patch_pass2
sed -e 's/\", \"-\",//' -e 's/\"));//' -e 's/,//g' patch_pass2 > patch.sh

. patch.sh

rm -f patch_pass*
rm -f patch.sh

if [ -f delete_pass1 ]; then
  echo "Removing unneeded files .."
  sed -e 's/delete(//' -e 's/);//' -e 's/\", \"/\",\"/g' delete_pass1 | tr , '\n' | tac > delete_pass2
  sed -e 's/\"\/system/delete \/system/' -e 's/\"//g' delete_pass2 > delete.sh

  . delete.sh

  rm -f delete_pass*
  rm -f delete.sh
fi

if [ -d $UNZIPPED_STOCK_OTA_DIR/system ]; then
  echo "Unpacking new system files .."
  pushd $UNZIPPED_STOCK_OTA_DIR/system > /dev/null
    tar cf - . | (cd $BASEDIR/system; tar xfp -)
  popd > /dev/null
fi

if [ -d $UNZIPPED_STOCK_OTA_DIR/recovery ]; then
  echo "Unpacking new recovery .."
  pushd $UNZIPPED_STOCK_OTA_DIR/recovery > /dev/null
    tar cf - . | (cd $BASEDIR/system; tar xfp -)
  popd > /dev/null

  echo "Building new recovery.img .."  
  grep "applypatch -b" $UNZIPPED_STOCK_OTA_DIR/recovery/bin/install-recovery.sh >  build_recovery_pass1
  sed -e 's/applypatch/apply_patch/' -e 's/\/system/system/g' -e 's/ \&\&.*//' build_recovery_pass1 > build_recovery.sh
  
  . build_recovery.sh > /dev/null
   
  rm build_recovery_pass*
  rm build_recovery.sh
fi

if [ -f rename_pass1 ]; then
  echo "Renaming files .. "
  sed -e 's/rename(\"/rename /' -e 's/\", \"/ /g' -e 's/\");//' -e 's/\",//' rename_pass1 > rename.sh

  . rename.sh

  rm -f rename_pass*
  rm -f rename.sh
fi
