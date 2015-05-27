#!/bin/bash

trim() {
  local var="$*"
  var="${var#"${var%%[![:space:]]*}"}"
  var="${var%"${var##*[![:space:]]}"}"
  echo -n "$var"
}

ECHO=""
MV="$ECHO mv"
MKDIR="$ECHO mkdir"

while read line
do
  app=$(trim $line);
  if ! [[ "$app" == "#"* ]] && ! [[ -z $app ]]; then
    APPS[$index]="$app"
    index=`expr $index + 1`
  fi
done < ../scripts/exclude_apps_list

if [ ! -d excluded_apps ]; then
  $MKDIR -p excluded_apps/app
  $MKDIR -p excluded_apps/priv-app
fi

for ((index = 0; index < ${#APPS[@]}; index++)); do
  app=${APPS[$index]}
  if [ -d system/app/$app ]; then
    $MV system/app/$app excluded_apps/app/
  else
    $MV system/priv-app/$app excluded_apps/priv-app/
  fi
  echo "Excluding $app .."
done
