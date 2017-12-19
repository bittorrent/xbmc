SET WORKSPACE=%CD%
SET BUILD_DEPS_PATH=%WORKSPACE%\project\BuildDependencies
SET WGET=%BUILD_DEPS_PATH%\bin\wget
SET ZIP=%BUILD_DEPS_PATH%\..\Win32BuildSetup\tools\7z\7za

git submodule update --init --recursive addons\*bt*

SET BT_TRANSCODE_FFMPEG_PATH=%WORKSPACE%\addons\script.bt.transcode\exec
SET FFMPEG_BINARY_FILENAME=ffmpeg.exe

cd project\BuildDependencies
call DownloadBuildDeps.bat
call DownloadMingwBuildEnv.bat

rem  move the static built ffmpeg binary into the bt.transcode.script git submodule
copy %FFMPEG_BINARY_FILENAME% %BT_TRANSCODE_FFMPEG_PATH%\%FFMPEG_BINARY_FILENAME%

cd ..\Win32BuildSetup
call BuildSetup.bat

cd ..
