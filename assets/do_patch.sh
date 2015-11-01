#!/system/bin/sh

echo "Generating empty system.img .. "
dd if=/dev/zero of=/data/local/tmp/system.img count=3145728 bs=1024
chmod 755 /data/local/tmp/update-binary

# generate system.img
echo "Dumping full ROM .. "
/data/local/tmp/update-binary 3 1 /data/local/tmp/dl_rom.zip

# apply ota patch
echo "Applying patch .. "
/data/local/tmp/update-binary 3 1 /data/local/tmp/dl_ota.zip


