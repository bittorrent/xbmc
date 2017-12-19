SET WORKSPACE=%CD%
SET BUILD_DEPS_PATH=%WORKSPACE%\project\BuildDependencies

SET BT_TRANSCODE_FFMPEG_PATH=%WORKSPACE%\addons\script.bt.transcode\exec
SET FFMPEG_BINARY_FILENAME=%WORKSPACE%\ffmpeg.exe

rem  move the static built ffmpeg binary into the bt.transcode.script git submodule
copy %FFMPEG_BINARY_FILENAME% %BT_TRANSCODE_FFMPEG_PATH%\%FFMPEG_BINARY_FILENAME%

git submodule update --init --recursive addons\*bt*

cd project\BuildDependencies
call DownloadBuildDeps.bat
call DownloadMingwBuildEnv.bat

cd ..\Win32BuildSetup
call BuildSetup.bat

cd ..
