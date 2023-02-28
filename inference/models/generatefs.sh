#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

while getopts ":d:k:i:" options; do
    case $options in 
        d)dataPath=$OPTARG;;
        k)keyFilePath=$OPTARG;;
        i)encryptedImage=$OPTARG;;
    esac
done

echo Encrypting $dataPath with key $keyFilePath and generating $encryptedImage
deviceName=cryptdevice1
deviceNamePath="/dev/mapper/$deviceName"

if [ -f "$keyFilePath" ]; then
    echo "keyfile exists"
else
    echo "[!] Generating keyfile..."
    dd if=/dev/random of="$keyFilePath" count=1 bs=32
fi

echo "Key in hex string format"

python hexstring.py $keyFilePath

truncate -s 32 "$keyFilePath"

echo "[!] Creating encrypted image..."

response=`du -s $dataPath`
read -ra arr <<< "$response"
size=`echo "x=l($arr)/l(2); scale=0; 2^((x+0.5)/1)*2" | bc -l;`
size=$size"K"
echo "Model repository size: $size"

rm -f "$encryptedImage"
touch "$encryptedImage"
truncate --size $size "$encryptedImage"

sudo cryptsetup luksFormat --type luks2 "$encryptedImage" \
    --key-file "$keyFilePath" -v --batch-mode --sector-size 4096 \
    --cipher aes-xts-plain64 \
    --pbkdf pbkdf2 --pbkdf-force-iterations 1000

sudo cryptsetup luksOpen "$encryptedImage" "$deviceName" \
    --key-file "$keyFilePath" \
    --integrity-no-journal --persistent

echo "[!] Formatting as ext4..."

sudo mkfs.ext4 "$deviceNamePath"

echo "[!] Mounting..."

mountPoint=`mktemp -d`
sudo mount -t ext4 "$deviceNamePath" "$mountPoint" -o loop

echo "[!] Copying contents to encrypted device..."

# The /* is needed to copy folder contents instead of the folder + contents
sudo cp -r $dataPath/* "$mountPoint"
sudo rm -rf "$mountPoint/lost+found"
ls "$mountPoint"

echo "[!] Closing device..."

sudo umount "$mountPoint"

sudo cryptsetup luksClose "$deviceName"
