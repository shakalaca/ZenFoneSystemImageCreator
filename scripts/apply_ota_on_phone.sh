#!/bin/sh

echo "Checking phone connection .. "
adb wait-for-device

# prepare
mkdir -p META-INF/com/google/android
cp ../assets/updater-script .
unzip -q dl_rom.zip META-INF/com/google/android/update-binary
mv META-INF/com/google/android/update-binary .
if [ ! -f boot.img ]; then
  echo "Extracting boot.img .. "
  unzip -q dl_rom.zip boot.img
fi

#DO_SKIP_PATCHING_UPDATER_SCRIPT=1
#DO_SKIP_UPLOADING_ZIP_FILE=1

if [ -z "$DO_SKIP_PATCHING_UPDATER_SCRIPT" ]; then

  if [ ! -f "system.img.ext4" ]; then
    # patch updater-script of full ROM
    echo "Updating stock ROM .. "
    cp updater-script META-INF/com/google/android
    zip -q -u dl_rom.zip META-INF/com/google/android/updater-script
  fi

  # move out modem related files
  if [ ! -d firmware-update ]; then
    echo "Moving out firmware-update folder .. "
    unzip -j -q dl_ota.zip -d firmware-update "firmware-update/*"
  fi
  
  # patch updater-script of OTA
  echo "Patching updater-script of OTA package .. "
  unzip -q -o dl_ota.zip META-INF/com/google/android/updater-script

  APPLY_PATCH_DONE=true
  while read line
  do
    if [[ "$line" == "apply_patch("* ]]; then
      APPLY_PATCH_CMD=$(echo $line | sed -e 's/\r//g')
      APPLY_PATCH_DONE=false
    elif !($APPLY_PATCH_DONE); then
      APPLY_PATCH_CMD="$APPLY_PATCH_CMD $(echo $line | sed -e 's/\r//g')"
      if [[ "$line" == *"));" ]]; then
        APPLY_PATCH_DONE=true
        echo $APPLY_PATCH_CMD >> patch_pass1
      fi
    fi
  done < META-INF/com/google/android/updater-script

  if [ -f patch_pass1 ]; then
    sed -e 's/EMMC:\/dev\/block\/bootdevice\/by-name\/boot.*\", \"-\"/\/data\/local\/tmp\/boot.img\", \"-\"/' patch_pass1 >> updater-script
    echo "Updating OTA package .. "
    cp updater-script META-INF/com/google/android
    zip -q -u dl_ota.zip META-INF/com/google/android/updater-script
  else
    echo "OTA package already patched .. "
  fi

fi # DO_SKIP_PATCHING_UPDATER_SCRIPT

if [ -z "$DO_SKIP_UPLOADING_ZIP_FILE" ]; then
  # push files to phone
  echo "Pushing stock ROM to phone .. "
  adb push dl_rom.zip /data/local/tmp/
  echo "Pushing OTA package to phone .. "
  adb push dl_ota.zip /data/local/tmp/
fi # DO_SKIP_UPLOADING_ZIP_FILE

echo "Pushing boot.img to phone .. "
adb push boot.img /data/local/tmp/
echo "Pushing scripts to phone .. "
adb push update-binary /data/local/tmp/
adb push ../assets/do_patch.sh /data/local/tmp
adb shell "chmod 755 /data/local/tmp/do_patch.sh"

# do patch !
echo "Do the work ! "
adb shell /data/local/tmp/do_patch.sh

# pull system.img
echo "Get boot.img and system.img.ext4 from phone .. "
adb pull /data/local/tmp/boot.img .
adb pull /data/local/tmp/system.img system.img.ext4

# clean up
rm patch_pass1
rm updater-script
rm update-binary
rm -rf META-INF
