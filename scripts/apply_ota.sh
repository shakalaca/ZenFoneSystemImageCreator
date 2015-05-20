#!/bin/bash

if [ ! -f ota.zip ]; then
  echo ota.zip not found
  exit
fi

ECHO=""
APPLYPATCH="$ECHO ./applypatch"
CHOWN="$ECHO chown"
CHMOD="$ECHO chmod"
FIND="$ECHO find"
RM="$ECHO rm"
RMDIR="$ECHO rmdir"
RENAME="$ECHO mv"

apply_patch() {
  TARGET=${1:1}
  $APPLYPATCH $TARGET $TARGET $2 $3 $4
}

delete() {
  for TARGET in "$@"
  do
    TARGET=${TARGET:1}
    if [ -d $TARGET ]; then
      $RMDIR $TARGET
    else
      $RM $TARGET
    fi
  done
}

set_metadata_recursive() {
  TARGET=${1:1}
  $CHOWN -R $2:$3 $TARGET
  $FIND $TARGET -type d -exec chmod $4 {} +
  $FIND $TARGET -type f -exec chmod $5 {} +
}

set_metadata() {
  TARGET=${1:1}
  $CHOWN $2:$3 $TARGET
  $CHMOD $4 $TARGET
}

rename() {
  SOURCE=$1
  TARGET=$2
  XPATH=${TARGET%/*}
  if [ ! -d $XPATH ]; then
    mkdir -p $XPATH
  fi
  $RENAME $SOURCE $TARGET
}

APPLY_PATCH_DONE=true
DELETE_CMD_DONE=true

unzip ota.zip -d ota

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
  elif [[ "$line" == "set_metadata"* ]]; then
    echo $line >> set_perm_pass1
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
done < ota/META-INF/com/google/android/updater-script

sed -e 's/apply_patch(\"/apply_patch /' -e 's/, package_extract_file(\"/:ota\//' patch_pass1 > patch_pass2
sed -e 's/\", \"-\",//' -e 's/\"));//' -e 's/,//g' patch_pass2 > patch_pass3
grep -v 'EMMC:/dev/block/by-name/boot:' patch_pass3 >> patch.sh

. patch.sh

rm -f patch_pass*
rm -f patch.sh

sed -e 's/delete(//' -e 's/);//' -e 's/\", \"/\",\"/g' delete_pass1 | tr , '\n' | tac > delete_pass2
sed -e 's/\"\/system/delete \/system/' -e 's/\"//g' delete_pass2 > delete.sh

. delete.sh

rm -f delete_pass*
rm -f delete.sh

if [ -d ota/system ]; then
  pushd ota/system > /dev/null
  tar cf - . | (cd ../../system; tar xfp -)
  popd > /dev/null
fi

if [ -d ota/recovery ]; then
  pushd ota/recovery > /dev/null
  tar cf - . | (cd ../../system; tar xfp -)
  popd > /dev/null
fi

sed -e 's/rename(\"/rename /' -e 's/\", \"/ /g' -e 's/\");//' -e 's/\",//' rename_pass1 > rename.sh

. rename.sh

rm -f rename_pass*
rm -f rename.sh

sed -e 's/set_metadata_recursive(\"/set_metadata_recursive /' -e 's/set_metadata(\"/set_metadata /' set_perm_pass1 >  set_perm_pass2
sed -e 's/\", \"uid\",//' -e 's/, \"gid\",//' -e 's/, \"dmode\",//' -e 's/, \"fmode\",//' -e 's/, \"mode\",//' set_perm_pass2 > set_perm_pass3
sed -e 's/\", \"/ /g' -e 's/\");//' -e 's/\",//' set_perm_pass3 > set_perm_pass4
awk -F , '{print $1}' set_perm_pass4 > set_perm.sh

. set_perm.sh

rm -f set_perm_pass*
rm -f set_perm.sh

