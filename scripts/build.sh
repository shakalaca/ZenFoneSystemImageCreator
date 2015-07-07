#!/bin/sh

apply_overlay() {
  if [ -d $ASSETSDIR/$1 ]; then
    pushd $ASSETSDIR/$1 > /dev/null
      tar cf - . | (cd $BASEDIR/system; tar xfp -)
    popd > /dev/null
  fi
}

add_new_vold() {
  apply_overlay new_vold
}

move_out_image() {
  if [ -f $UNZIPPED_STOCK_ROM_DIR/$1.img ]; then
    echo "Move out stock $1.img .. "
    cp $UNZIPPED_STOCK_ROM_DIR/$1.img .
  fi
}

link_system_files() {
  UPDATER_SCRIPT=$1
  
  cat $1 | sed 's/        /symlink("toolbox", /' > link_pass1
  grep 'symlink' link_pass1 > link_pass2
  cat link_pass2 | sed -e 's/symlink(\"/symlink /' -e 's/\", \"/ /g' -e 's/\");//' -e 's/\",//' > link.sh
  
  . link.sh

  rm link_pass*
  rm link.sh
}

symlink() {
  SOURCE=$1
  shift
  for TARGET in "$@"
  do
    TARGET=${TARGET:1}
    XPATH=${TARGET%/*}
    XFILE=${TARGET##*/}
    
    if [ ! -d $XPATH ]; then
      mkdir -p $XPATH
    fi

    pushd $XPATH > /dev/null
      ln -s $SOURCE $XFILE
    popd > /dev/null
  done
}

source scripts/setup.bash

cd work

BASEDIR=$(pwd)
SCRIPTDIR=../scripts
ASSETSDIR=../assets
UNZIPPED_STOCK_ROM_DIR=unzipped_rom

STOCK_ROM=dl_rom.zip

if [ ! -d system ]; then
  # Download stock ROM
  wget -c $ROM_URL -O $STOCK_ROM

  echo "Extracting stock ROM .. "
  unzip -q $STOCK_ROM -d $UNZIPPED_STOCK_ROM_DIR

  echo "Move out system directory .."
  mv $UNZIPPED_STOCK_ROM_DIR/system .

  move_out_image boot
  move_out_image fastboot
  move_out_image recovery

  echo "Link system files .. "
  link_system_files $UNZIPPED_STOCK_ROM_DIR/META-INF/com/google/android/updater-script

  echo "Clean up .. "
  rm -rf $UNZIPPED_STOCK_ROM_DIR

  read -p 'Press any key to build system.img .. '
fi

echo "Install SuperSU .. "
$SCRIPTDIR/install_supersu.sh

# For slim down version
if [ ! -z "$SLIM_DOWN" ]; then
  echo "Remove apps listed in exclude_apps_list .. "
  $SCRIPTDIR/exclude_apps.sh
  
  echo "Enable sdcard write permission in platform.xml .. "
  $SCRIPTDIR/enable_sdcard_write.sh

  # echo "Add vold with ntfs support .. "
  #add_new_vold
fi

# Set the right file_context file for SELinux permission
if [ -n "$FILE_CONTEXT" ]; then
  FCOPT="-S $ASSETSDIR/$FILE_CONTEXT"
fi

echo "Build system.img .. "    
./make_ext4fs -s -l $SYSTEM_SIZE -a system $FCOPT system.img system

echo "Finish building $VERSION .. "
if [ ! -d $VERSION ]; then
  mkdir $VERSION
fi

mv *.img $VERSION
