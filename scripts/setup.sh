#!/bin/bash

set -e

mkdir -p External

echo "Downloading p7zip..."
TEMP_BZ2=$(mktemp -t p7zip)
curl -L -o "${TEMP_BZ2}" https://kent.dl.sourceforge.net/project/p7zip/p7zip/16.02/p7zip_16.02_src_all.tar.bz2

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
