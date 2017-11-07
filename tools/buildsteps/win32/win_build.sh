#!/bin/bash

ROOT_BUILD_FOLDER=$PWD
BUILDDEPS_FOLDER=$ROOT_BUILD_FOLDER/project/BuildDependencies
WIN32BUILD_FOLDER=$ROOT_BUILD_FOLDER/project/Win32BuildSetup

pushd $BUILDDEPS_FOLDER

powershell.exe ./DownloadBuildDeps.bat
powershell.exe ./DownloadMingwBuildEnv.bat

MINGWLIBS=( \
          "mingw-w64-i686-ffmpeg-3.1.3-1-any.pkg.tar.xz"  \
          "mingw-w64-i686-libdvdcss-1.4.0-1-any.pkg.tar.xz" \
          "mingw-w64-i686-libdvdnav-5.0.3-1-any.pkg.tar.xz" \
          "mingw-w64-i686-libdvdread-5.0.3-1-any.pkg.tar.xz" \
          "mingw-w64-i686-pcre-8.37-2-any.pkg.tar.xz"
          )

http://repo.msys2.org/mingw/i686/
for lib in "${MINGWLIBS[@]}"
do
  liburl="http://repo.msys2.org/mingw/i686/"$lib
  wget $liburl
  tar xJvf $lib
  rm $lib
done

exit 0

# Rename all precompiled lib*.dll.a -> *.lib, so MSVC will find them
for file in mingw32/lib/lib*.dll.a
do
  DIRNAME=$(dirname $file)\
  NEWNAME=$(echo $(basename $file) | cut -f 1 -d '.')
  mv $file $DIRNAME/$name.lib
done

# Copy all libs and includes under Kodi's dependencies folder
cp -r ./mingw32/* .
cp ./mingw32/bin/*.dll $ROOT_BUILD_FOLDER/system/

#export PATH=$BUILDDEPS_FOLDER\msys64\bin;$BUILDDEPS_FOLDER\msys64\usr\bin;$PATH

# bash -lc "pacman --needed --noconfirm -Sy"

#cd $WIN32BUILD_FOLDER
#powershell.exe ./BuildSetup.bat noclean nomingwlibs
