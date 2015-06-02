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
done < ../assets/exclude_apps_list

if [ ! -d excluded_apps ]; then
  $MKDIR -p excluded_apps/app
  $MKDIR -p excluded_apps/priv-app
fi

for ((index = 0; index < ${#APPS[@]}; index++)); do
  app=${APPS[$index]}
  if [ -d system/app/$app ]; then
    $MV system/app/$app excluded_apps/app/
  elif [ -d system/priv-app/$app ]; then
    $MV system/priv-app/$app excluded_apps/priv-app/
  elif [ -f system/app/$app.apk ]; then
    $MV system/app/$app.apk excluded_apps/app/
    if [ -f system/app/$app.odex ]; then
      $MV system/app/$app.odex excluded_apps/app/
    fi
  elif [ -f system/priv-app/$app.apk ]; then
    $MV system/priv-app/$app.apk excluded_apps/priv-app/
    if [ -f system/priv-app/$app.odex ]; then
      $MV system/priv-app/$app.odex excluded_apps/priv-app/
    fi  
  fi
  echo "Excluding $app .."
done
