@echo off
title OpenRGB - Lotus Lantern BLE
color 0B
cd /d "%~dp0"
call config.cmd

if "%LED_DEVICE_UUID%"=="" (
    echo ERROR: Set LED_DEVICE_UUID in config.cmd first.
    pause
    exit /b 1
)
if not exist "%OPENRGB_EXE%" (
    echo ERROR: OpenRGB was not found at:
    echo   %OPENRGB_EXE%
    echo Update OPENRGB_EXE in config.cmd.
    pause
    exit /b 1
)

echo Starting Lotus Lantern BLE bridge...

if exist "connector.pid" (
    for /f "usebackq tokens=1" %%P in ("connector.pid") do taskkill /f /pid %%P >nul 2>&1
    del /q connector.pid >nul 2>&1
)
taskkill /f /im BLEServer.exe >nul 2>&1

sc query OpenRGB 2>nul | findstr /c:"STATE" | findstr /c:"RUNNING" >nul
if not errorlevel 1 (
    echo Stopping the OpenRGB Windows service...
    powershell -NoProfile -Command "Start-Process -FilePath sc.exe -ArgumentList 'stop OpenRGB' -Verb RunAs -Wait"
)

taskkill /f /im OpenRGB.exe >nul 2>&1
for /l %%N in (1,1,10) do (
    tasklist /fi "imagename eq OpenRGB.exe" 2>nul | findstr /i /c:"OpenRGB.exe" >nul || goto openrgb_stopped
    timeout /t 1 /nobreak >nul
)

echo ERROR: An existing OpenRGB process or service is still running.
echo Allow the administrator prompt, or stop the OpenRGB Windows service manually.
pause
exit /b 1

:openrgb_stopped

echo Configuring the OpenRGB DDP device...
node configure-openrgb.mjs
if errorlevel 1 (
    echo ERROR: OpenRGB configuration failed.
    echo Start OpenRGB once, close it, and run this script again.
    pause
    exit /b 1
)

start "Lotus BLE Bridge" /min cmd /c "node index.mjs %LED_DEVICE_UUID%"
timeout /t 8 /nobreak >nul

start "" "%OPENRGB_EXE%" --server --server-host 127.0.0.1 --server-port 6742

echo.
echo OpenRGB is connected through:
echo   OpenRGB Effects -^> DDP 127.0.0.1:4048 -^> BLE strip
echo.
echo In OpenRGB Effects, select "Lotus Lantern BLE".
echo Do not run start-music-sync.cmd at the same time.
pause
