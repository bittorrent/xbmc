#!/bin/bash

git submodule update --init --recursive addons/*bt*

# Build Dependencies
cd tools/depends
./bootstrap
./configure --host=x86_64-apple-darwin
#make
#make -C target/binary-addons
cd ../..

FFMPEG="/Users/Shared/xbmc-depends/ffmpeg"
if [ ! -f $FFMPEG ]; then
wget https://evermeet.cx/ffmpeg/ffmpeg-3.4.1.7z
7z x ffmpeg-3.4.1.7z
cp ffmpeg $FFMPEG
fi
cp $FFMPEG addons/script.bt.transcode/exec/

make -C tools/depends/target/cmakebuildsys
make -j 4 -C build

cd build
make dmg

