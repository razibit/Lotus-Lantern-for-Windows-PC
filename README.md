# Lotus Lantern BLE Music Sync for Windows

Sync a Lotus Lantern/ELK Bluetooth LED strip with laptop audio through OpenRGB Effects. The supported path is:

```text
OpenRGB Audio Party -> DDP on 127.0.0.1:4048 -> local BLE bridge -> LED strip
```

## Requirements

- Windows 10 or 11 with Bluetooth enabled
- Node.js 18 or newer
- OpenRGB with the Effects plugin installed
- A compatible strip exposing the `FFF0` service and writable `FFF3` characteristic
- The Lotus Lantern mobile app closed while the PC controls the strip

The bridge was tested with an `ELK-BLEDDM` controller. Other controllers may use a different protocol.

## Setup

1. Run `npm ci` in this folder.
2. Install OpenRGB and its Effects plugin. Open and close OpenRGB once so its configuration exists.
3. Set your strip's Bluetooth address without `:` or `-` in [config.cmd](config.cmd). Set `OPENRGB_EXE` there if OpenRGB is installed elsewhere.
4. Turn on Bluetooth and the LED strip, then run `start-openrgb-ble-sync.cmd`.
5. In OpenRGB, open **Effects**, select **Lotus Lantern BLE**, choose **Audio Party**, and load one of the saved profiles in [OpenRGB-MusicTYPE-sync-Profile](OpenRGB-MusicTYPE-sync-Profile).
6. Select the correct Windows playback device in Audio Party and play music.

The launcher configures a one-LED DDP device in OpenRGB at `127.0.0.1:4048`, starts the BLE bridge, and opens OpenRGB. The bridge averages multi-pixel colors into one color for the whole strip. OpenRGB also starts its SDK server on TCP `6742`; that is separate from DDP.

The bridge uses the Windows BLE implementation in [src/ble-device.cjs](src/ble-device.cjs). It is a preserved, locally adapted version of `@bjclopes/homebridge-ledstrip-bledom`'s device implementation. It relies on the `noble-winrt` package installed by `npm ci`. This local source is necessary for reproducible installs; do not replace it with the unmodified upstream package.

## Troubleshooting

See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for connection, OpenRGB, and port checks. The bridge writes `connector.pid` while running; this generated file is ignored by Git.

## Safety and credits

Use the power supply specified for your strip. This software sends Bluetooth commands and does not protect against wiring or power supply faults.

OpenRGB and its Effects plugin are separate applications. The BLE device implementation derives from [`homebridge-ledstrip-bledom`](https://github.com/bjclopes/homebridge-ledstrip-bledom) and uses [`noble-winrt`](https://github.com/urish/noble-winrt). This project is not affiliated with those projects or the LED controller manufacturer.
