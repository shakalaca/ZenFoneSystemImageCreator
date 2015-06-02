#!/bin/bash

OUTPUT=system/etc/permissions/platform.xml.new
INPUT=system/etc/permissions/platform.xml
PATCH_DONE=true
IFS=''

if [ -f $OUTPUT ]; then
  rm $OUTPUT
fi

while read line
do
  if [[ "$line" == *"android.permission.WRITE_EXTERNAL_STORAGE"* ]]; then
    PATCH_DONE=false
  elif !($PATCH_DONE); then
    if [[ "$line" == *"</permission>"* ]]; then
      echo "<group gid=\"media_rw\" />" >> $OUTPUT
      PATCH_DONE=true
    fi
  fi
  echo "$line" >> $OUTPUT
done < $INPUT

mv $INPUT $INPUT.orig
mv $OUTPUT $INPUT
