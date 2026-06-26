@echo off
title Blauncher By CLDevs



if exist profile.txt (
    set /p USERNAME=<profile.txt
) else (
    set /p USERNAME=username:
    echo %USERNAME%>profile.txt
)

echo Welcome %USERNAME%
pause

echo Installed versions:
for /d %%i in (versions\*) do echo %%~nxi
pause


set /p VERSION=Version:

mkdir versions\%VERSION% 2>nul

echo Downloading global manifest...
powershell -Command ^
"Invoke-WebRequest 'https://piston-meta.mojang.com/mc/game/version_manifest_v2.json' -OutFile 'manifest.json'"

echo Version folder created:
echo versions\%VERSION%

pause







