#!/bin/bash

set -e

if [ ! -f External/p7zip/CPP/include_windows/windows.h ]; then
    echo "error: windows.h not found, make sure you have the p7zip source in place."
    exit 1
fi

patch -p1 < scripts/windows_h_patch.diff

if [ ! -f External/p7zip/C/7zCrc.c ]; then
    echo "error: 7zCrc.c not found, make sure you have the p7zip source in place."
    exit 1
fi

patch -p1 < scripts/7zCrc_c_patch.diff

if [ ! -f External/p7zip/C/7zTypes.h ]; then
    echo "error: 7zTypes.h not found, make sure you have the p7zip source in place."
    exit 1
fi

patch -p1 < scripts/7zTypes_h_patch.diff

if [ ! -f External/p7zip/CPP/Windows/FileDir.h ]; then
    echo "error: FileDir.h not found, make sure you have the p7zip source in place."
    exit 1
fi

patch -p1 < scripts/FileDir_h_patch.diff
