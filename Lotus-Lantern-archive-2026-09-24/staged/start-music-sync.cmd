@echo off
title Lotus Lantern - Music Sync
color 0E

echo.
echo ====================================================
echo       LOTUS LANTERN - ONE-CLICK MUSIC SYNC
echo ====================================================
echo.
echo NOTE: OpenRGB does not control this BLE strip directly.
echo       Do not configure OpenRGB Client to port 1920.
echo.

cd /d "%~dp0"
call config.cmd

if "%LED_DEVICE_UUID%"=="" (
    echo ERROR: Set LED_DEVICE_UUID in config.cmd first.
    pause
    exit /b 1
)

:: Stop only processes previously started by this project.
echo [1/5] Cleaning up old processes...
if exist "visualizer.pid" (
    for /f "usebackq tokens=1" %%P in ("visualizer.pid") do taskkill /f /pid %%P >nul 2>&1
    del /q visualizer.pid >nul 2>&1
)
if exist "connector.pid" (
    for /f "usebackq tokens=1" %%P in ("connector.pid") do taskkill /f /pid %%P >nul 2>&1
    del /q connector.pid >nul 2>&1
)
taskkill /f /im BLEServer.exe >nul 2>&1
timeout /t 2 /nobreak >nul

:: Install npm dependencies if needed
if not exist "node_modules\noble-winrt" (
    echo [2/5] Installing Node.js dependencies...
    call npm install --ignore-scripts
    call npm install noble-winrt --save --ignore-scripts
) else (
    echo [2/5] Node.js dependencies OK.
)

:: Install Python soundcard if needed
python -c "import soundcard" >nul 2>&1
if errorlevel 1 (
    echo [3/5] Installing Python audio library...
    pip install soundcard numpy
) else (
    echo [3/5] Python audio library OK.
)

:: Patch Device.js using Node
echo [4/5] Patching BLE module...
node -e "const fs=require('fs');const f='node_modules/@bjclopes/homebridge-ledstrip-bledom/Device.js';let c=fs.readFileSync(f,'utf8');if(c.includes('noble-winrt')){process.exit(0);}c=c.replace('require(\"@abandonware/noble\")','require(\"noble-winrt\")');c=c.replace('this.uuid = uuid;','this.uuid = uuid.toLowerCase();');c=c.replace('noble.startScanningAsync();','noble.startScanning();');c=c.replace('await this.peripheral.connectAsync();','await connectAsync(this.peripheral);');c=c.replace('await this.peripheral.discoverSomeServicesAndCharacteristicsAsync(\n        [\"fff0\"],\n        [\"fff3\"]\n      );','await discoverSomeServicesAndCharacteristicsAsync(\n        this.peripheral, [\"fff0\"], [\"fff3\"]\n      );');c=c.replace('await this.peripheral.disconnectAsync();','await disconnectAsync(this.peripheral);');const w='function connectAsync(p){return new Promise((y,n)=>{p.connect(e=>e?n(e):y())});}\nfunction disconnectAsync(p){return new Promise((y,n)=>{p.disconnect(e=>e?n(e):y())});}\nfunction discoverSomeServicesAndCharacteristicsAsync(p,s,c){return new Promise((y,n)=>{p.discoverSomeServicesAndCharacteristics(s,c,(e,sv,ch)=>{if(e)return n(e);y({services:sv,characteristics:ch})})});}\n\n';c=c.replace('function log(message) {\n  console.log(`[homebridge-ledstrip]:`, message);\n}\n\nmodule.exports','function log(message) {\n  console.log(`[homebridge-ledstrip]:`, message);\n}\n\n'+w+'module.exports');c=c.replace('}, 5000);','}, 300000);');fs.writeFileSync(f,c);"

:: Start LED connector in background
echo [5/5] Connecting LED strip and starting visualizer...
echo.

start "Lotus LED Connector" /min cmd /c "node index.mjs %LED_DEVICE_UUID%"

:: Wait for connection
echo   Waiting for LED strip to connect (8s)...
timeout /t 8 /nobreak >nul

:: Start visualizer in foreground
echo.
echo ====================================================
echo   LED STRIP: %LED_DEVICE_UUID%
echo   AUDIO: Capturing system audio (what you hear)
echo   SYNC: Bass=Red, Mid=Green, Treble=Blue
echo.
echo   Now play YouTube Music - lights will sync!
echo   Press Ctrl+C to stop
echo ====================================================
echo.

python visualizer.py

:: Cleanup: kill the background node process
taskkill /f /fi "WINDOWTITLE eq Lotus LED Connector" >nul 2>&1
taskkill /f /im BLEServer.exe >nul 2>&1

echo.
echo Done. LED strip turned off.
pause
