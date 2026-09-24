# Architecture

`start-openrgb-ble-sync.cmd` loads `config.cmd`, configures OpenRGB's one-LED DDP device, starts `index.mjs`, and opens OpenRGB.

```text
OpenRGB Effects -> DDP/UDP 127.0.0.1:4048 -> index.mjs -> src/ble-device.cjs -> BLE FFF3 -> strip
```

The bridge retains only the newest RGB value and limits BLE writes to about five per second. When DDP contains multiple pixels, it averages them because the tested controller applies one RGB color to the entire strip.

The local BLE device implementation is the preserved Windows adaptation of `@bjclopes/homebridge-ledstrip-bledom`'s `Device.js`. It uses `noble-winrt` and writes to a writable `FFF3` characteristic on service `FFF0`. A typical RGB command is `7E 07 05 03 RR GG BB 10 EF`.

OpenRGB's SDK server uses TCP `6742`; the bridge does not use that port for color data.
