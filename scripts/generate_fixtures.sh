#!/bin/bash

TEST_DATA="$1"
TARGET_DIR="$2"

if [ -z "${TARGET_DIR}" ]; then
    TARGET_DIR="."
fi

COMPRESSION_LEVELS="0 1 3 5 7 9"
METHODS="LZMA LZMA2 PPMd BZip2 Deflate Copy"
FILTERS="off Delta:128 BCJ BCJ2 ARM ARMT IA64 PPC SPARC"

for METHOD in ${METHODS}
do
    for FILTER in ${FILTERS}
    do
        for COMPRESSION_LEVEL in ${COMPRESSION_LEVELS}
        do
            TARGET_FILE="${TARGET_DIR}/${METHOD}_${FILTER}_${COMPRESSION_LEVEL}.7z"
            echo "Generating ${TARGET_FILE}..."
            echo -n "${TEST_DATA}" | \
                7z a -sitest.dat -m0=${METHOD} -mf=${FILTER} -mx${COMPRESSION_LEVEL} "${TARGET_FILE}" > /dev/null
        done
    done
done
