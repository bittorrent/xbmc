SET WORKSPACE=%CD%
SET BUILD_DEPS_PATH=%WORKSPACE%\project\BuildDependencies
SET WGET=%BUILD_DEPS_PATH%\bin\wget
SET ZIP=%BUILD_DEPS_PATH%\..\Win32BuildSetup\tools\7z\7za

git submodule init --recursive addons\*bt*
git submodule update --recursive addons\*bt*

SET BT_TRANSCODE_FFMPEG_PATH=%WORKSPACE%\addons\script.bt.transcode\exec

cd project\BuildDependencies
call DownloadBuildDeps.bat
call DownloadMingwBuildEnv.bat

rem download, unzip and move the static built ffmpeg binary into the bt.transcode.script git submodule
SET FFMPEG_STATIC_DIR=%BUILD_DEPS_PATH%\ffmpeg-static
rmdir /S /Q %FFMPEG_STATIC_DIR%
md %FFMPEG_STATIC_DIR%
cd %FFMPEG_STATIC_DIR%
SET FFMPEG_FILENAME=ffmpeg-3.4-win32-static.zip
call %WGET% "https://ffmpeg.zeranoe.com/builds/win32/static/%FFMPEG_FILENAME%"
call %ZIP% e %FFMPEG_FILENAME%
SET FFMPEG_BINARY_FILENAME=ffmpeg.exe
SET FFMPEG_BINARY=%FFMPEG_STATIC_DIR%\%FFMPEG_BINARY_FILENAME%
del %BT_TRANSCODE_FFMPEG_PATH%\%FFMPEG_BINARY_FILENAME%
copy %FFMPEG_BINARY% %BT_TRANSCODE_FFMPEG_PATH%\%FFMPEG_BINARY_FILENAME%
cd ..\
rmdir /S /Q %FFMPEG_STATIC_DIR%

cd ..\Win32BuildSetup
call BuildSetup.bat

cd ..
