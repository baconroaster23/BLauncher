@echo off
title BLauncher By CLDevs

if not exist versions mkdir versions


if exist profile.txt (
    set /p USERNAME=<profile.txt
) else (
    set /p USERNAME=Username:
    echo %USERNAME%>profile.txt
)

echo Welcome %USERNAME%
echo.


echo Installed versions:
for /d %%i in (versions\*) do echo - %%~nxi
echo.


if not exist manifest.json (
    echo Downloading global manifest...
    powershell -Command ^
    "Invoke-WebRequest 'https://piston-meta.mojang.com/mc/game/version_manifest_v2.json' -OutFile 'manifest.json'"
    echo Manifest downloaded.
) else (
    echo Manifest already exists.
)

echo.


set /p VERSION=Version:

mkdir "versions\%VERSION%" 2>nul

echo.
echo Version folder created:
echo versions\%VERSION%
echo.

pause