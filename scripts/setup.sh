#!/bin/bash

set -e

mkdir -p External

echo "Downloading p7zip..."
TEMP_BZ2=$(mktemp -t p7zip)
curl -L -o "${TEMP_BZ2}" http://sourceforge.net/projects/p7zip/files/latest/download

echo "Unpacking..."
TEMP_TAR=$(mktemp -t p7zip)
bunzip2 -c "${TEMP_BZ2}" > "${TEMP_TAR}"

tar -xf "${TEMP_TAR}" -C External

rm -rf External/p7zip
ln -s $(ls External | grep p7zip | tail -n 1) External/p7zip

rm -f "${TEMP_TAR}" "${TEMP_BZ2}"

echo "Applying patches..."
scripts/apply_patches.sh

echo "Done!"
