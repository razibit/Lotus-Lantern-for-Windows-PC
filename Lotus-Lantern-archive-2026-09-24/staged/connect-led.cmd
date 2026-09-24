@echo off
title Lotus Lantern - LED Strip Connector
color 0A

echo ============================================
echo    LOTUS LANTERN - LED STRIP CONNECTOR
echo ============================================
echo.

cd /d "%~dp0"
call config.cmd

if "%LED_DEVICE_UUID%"=="" (
    echo ERROR: Set LED_DEVICE_UUID in config.cmd first.
    pause
    exit /b 1
)

:: Kill any leftover processes
echo [1/4] Cleaning up old processes...
taskkill /f /im BLEServer.exe >nul 2>&1
if exist "connector.pid" (
    for /f "usebackq tokens=1" %%P in ("connector.pid") do taskkill /f /pid %%P >nul 2>&1
    del /q connector.pid >nul 2>&1
)

:: Install dependencies if node_modules missing
if not exist "node_modules\noble-winrt" (
    echo [2/4] Installing dependencies...
    call npm install --ignore-scripts
    call npm install noble-winrt --save --ignore-scripts
) else (
    echo [2/4] Dependencies already installed.
)

:: Patch Device.js using Node
echo [3/4] Patching Device.js for noble-winrt...
node -e "const fs=require('fs');const f='node_modules/@bjclopes/homebridge-ledstrip-bledom/Device.js';let c=fs.readFileSync(f,'utf8');if(c.includes('noble-winrt')){console.log('   Already patched.');process.exit(0);}c=c.replace('require(\"@abandonware/noble\")','require(\"noble-winrt\")');c=c.replace('this.uuid = uuid;','this.uuid = uuid.toLowerCase();');c=c.replace('noble.startScanningAsync();','noble.startScanning();');c=c.replace('await this.peripheral.connectAsync();','await connectAsync(this.peripheral);');c=c.replace('await this.peripheral.discoverSomeServicesAndCharacteristicsAsync(\n        [\"fff0\"],\n        [\"fff3\"]\n      );','await discoverSomeServicesAndCharacteristicsAsync(\n        this.peripheral, [\"fff0\"], [\"fff3\"]\n      );');c=c.replace('await this.peripheral.disconnectAsync();','await disconnectAsync(this.peripheral);');const wrappers='// Promise wrappers for noble 1.9.1 callback API\nfunction connectAsync(peripheral) {\n  return new Promise((resolve, reject) => {\n    peripheral.connect((err) => err ? reject(err) : resolve());\n  });\n}\nfunction disconnectAsync(peripheral) {\n  return new Promise((resolve, reject) => {\n    peripheral.disconnect((err) => err ? reject(err) : resolve());\n  });\n}\nfunction discoverSomeServicesAndCharacteristicsAsync(peripheral, svcUuids, charUuids) {\n  return new Promise((resolve, reject) => {\n    peripheral.discoverSomeServicesAndCharacteristics(svcUuids, charUuids, (err, services, characteristics) => {\n      if (err) return reject(err);\n      resolve({ services, characteristics });\n    });\n  });\n}\n\n';c=c.replace('function log(message) {\n  console.log(`[homebridge-ledstrip]:`, message);\n}\n\nmodule.exports','function log(message) {\n  console.log(`[homebridge-ledstrip]:`, message);\n}\n\n'+wrappers+'module.exports');c=c.replace('}, 5000);','}, 300000);');fs.writeFileSync(f,c);console.log('   Patched successfully.');"

:: Start the app
echo [4/4] Starting LED strip connector...
echo.
echo ============================================
echo   LED Strip: %LED_DEVICE_UUID%
echo   UDP Server: localhost:1920
echo   OpenRGB: Use start-openrgb-ble-sync.cmd
echo ============================================
echo.
echo Waiting for Bluetooth connection...
echo.

node index.mjs %LED_DEVICE_UUID%

pause
