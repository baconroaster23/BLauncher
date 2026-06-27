@echo off
title Blauncher Made By BaconRoaster
setlocal enabledelayedexpansion
cd /d "%~dp0"

if not exist "config.json" (
    echo {"client_id": "PUT-YOUR-AZURE-CLIENT-ID-HERE", "game_dir": "game", "java_path": "java"} > config.json
    echo [!!] Created a default config.json. If you plan to use Microsoft login, edit "client_id" first - see README.md.
)

for /f "usebackq delims=" %%C in (`powershell -NoProfile -Command "(Get-Content config.json -Raw | ConvertFrom-Json).game_dir"`) do set "GAME_DIR=%%C"
for /f "usebackq delims=" %%J in (`powershell -NoProfile -Command "(Get-Content config.json -Raw | ConvertFrom-Json).java_path"`) do set "JAVA_PATH=%%J"

set /p "VERSION_ID=Enter the Minecraft version ID to play (e.g. 1.21): "
if "%VERSION_ID%"=="" (
    echo Version ID cannot be empty.
    pause
    exit /b
)

echo.
echo [1/3] Downloading version files...
powershell -NoProfile -ExecutionPolicy Bypass -File "scripts\Download.ps1" -VersionId "%VERSION_ID%" -RootDir "%CD%\%GAME_DIR%"
if errorlevel 1 (
    echo [!!] Download failed.
    pause
    exit /b
)

echo.
echo  [1] Microsoft account login
echo  [2] Offline / guest profile (singleplayer + offline-mode servers only)
set /p "MODE=Choose a mode (1 or 2): "

if "%MODE%"=="2" goto :OFFLINE
if "%MODE%"=="1" goto :ONLINE
echo Invalid choice.
pause
exit /b

:ONLINE
echo.
echo [2/3] Signing in with your Microsoft account...
powershell -NoProfile -ExecutionPolicy Bypass -File "scripts\Auth.ps1" -ConfigPath "%CD%\config.json"
if errorlevel 1 (
    echo [!!] Login failed.
    pause
    exit /b
)
echo.
echo [3/3] Launching the game...
powershell -NoProfile -ExecutionPolicy Bypass -File "scripts\Launch.ps1" -VersionId "%VERSION_ID%" -RootDir "%CD%\%GAME_DIR%" -JavaPath "%JAVA_PATH%"
goto :END

:OFFLINE
set /p "OFFLINE_NAME=Enter a username for your offline profile: "
if "%OFFLINE_NAME%"=="" (
    echo Username cannot be empty.
    pause
    exit /b
)
echo.
echo [3/3] Launching the game in offline mode as %OFFLINE_NAME%...
powershell -NoProfile -ExecutionPolicy Bypass -File "scripts\Launch.ps1" -VersionId "%VERSION_ID%" -RootDir "%CD%\%GAME_DIR%" -JavaPath "%JAVA_PATH%" -Offline -Username "%OFFLINE_NAME%"
goto :END

:END
pause
