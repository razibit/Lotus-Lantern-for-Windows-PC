@echo off
title OpenRGB Server
cd /d "%~dp0"
call config.cmd

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
start "" "%OPENRGB_EXE%" --server --server-host 127.0.0.1 --server-port 6742 --startminimized

echo OpenRGB started as an SDK server on 127.0.0.1:6742.
echo Use start-music-sync.cmd for the Lotus Lantern BLE strip.
timeout /t 3 /nobreak >nul
