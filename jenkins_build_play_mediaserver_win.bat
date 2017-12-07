git submodule init addons\*bt*
git submodule update addons\*bt*

cd project\BuildDependencies
call DownloadBuildDeps.bat
call DownloadMingwBuildEnv.bat


cd ..\Win32BuildSetup
Call BuildSetup.bat

cd ..
