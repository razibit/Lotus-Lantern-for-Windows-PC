# Lotus Lantern BLE Music Sync for Windows

Control Cheap Bluetooth LED strips from Windows PC and synchronize
them with music using either OpenRGB Effects or the included audio visualizer.

![Lotus Lantern Music Sync](https://raw.githubusercontent.com/razibit/Lotus-Lantern/main/Alice-Deejay---Megamix---YouTube.gif)

This project bridges three systems:

```text
OpenRGB Effects -> DDP/UDP -> local bridge -> Bluetooth LE -> LED controller
```

It was tested with an `ELK-BLEDDM` controller used by the Lotus Lantern mobile
app. Similar controllers often advertise as `ELK-BLEDOM`, `ELK-BLEDDM`, or
another `ELK-*` name.

## Important Compatibility Note

This does **not** support every generic Bluetooth LED strip.

The controller must use the common Lotus Lantern/ELK BLE protocol:

- BLE service: `FFF0`
- Writable characteristic: `FFF3`
- RGB command format beginning with `7E 07 05 03`

If your strip uses another app or protocol, the bridge may require a new device
adapter.

## Requirements

- Windows 10 or Windows 11
- A working Bluetooth adapter
- Node.js 18 or newer
- Python 3.10 or newer
- OpenRGB 1.0rc2 or compatible version for the OpenRGB workflow
- OpenRGB Effects plugin for music effects
- The Lotus Lantern app fully closed while the PC controls the strip

## Quick Start: OpenRGB Effects

1. Clone or download this repository.
2. Open a terminal in the project folder and install Node dependencies:

   ```powershell
   npm install
   ```

3. Install OpenRGB and the Effects plugin, then open and close OpenRGB once.
   This creates its configuration file.
4. Open [config.cmd](config.cmd).
5. Replace `BE27BA000D79` with your strip's Bluetooth address, without `:` or
   `-` characters.
6. Run:

   ```text
   start-openrgb-ble-sync.cmd
   ```

7. In OpenRGB, open **Effects**.
8. Select the device named **Lotus Lantern BLE**.
9. Select an audio-reactive effect and your Windows playback device.
10. Start the effect.

Do not run `start-music-sync.cmd` at the same time. Both applications would
compete to control the same strip.

## Quick Start: Built-in Visualizer

If you do not want OpenRGB:

1. Configure the Bluetooth address in [config.cmd](config.cmd).
2. Install dependencies:

   ```powershell
   npm install
   pip install soundcard numpy
   ```

3. Run:

   ```text
   start-music-sync.cmd
   ```

The included Python visualizer captures the default Windows speaker output:

- Red: bass
- Green: mid frequencies
- Blue: high frequencies

## Finding the Bluetooth Address

The address is usually shown in one of these places:

- Lotus Lantern device screen
- Windows Bluetooth device properties
- A BLE scanner application
- Existing controller logs

Convert an address such as `BE:27:BA:00:0D:79` to:

```text
BE27BA000D79
```

## OpenRGB Setup Performed by This Project

OpenRGB sees the BLE strip as a virtual one-LED DDP device:

```text
Name: Lotus Lantern BLE
Address: 127.0.0.1
Port: 4048
LED count: 1
```

The bridge also listens on UDP port `1920` for the included Python visualizer.
OpenRGB's SDK server uses TCP port `6742`. These ports serve different
protocols and must not be mixed.

## Scripts

| File | Purpose |
| --- | --- |
| `start-openrgb-ble-sync.cmd` | Recommended OpenRGB Effects workflow |
| `start-music-sync.cmd` | Standalone Python music visualizer |
| `connect-led.cmd` | BLE bridge only, useful for diagnostics |
| `start-visualizer.cmd` | Visualizer only; requires the bridge already running |
| `config.cmd` | Bluetooth address and OpenRGB installation path |

## Common Problems

### The strip stays one color

- Confirm an OpenRGB effect is running.
- Confirm **Lotus Lantern BLE** is selected in Effects.
- Stop the Lotus Lantern mobile app.
- Close other programs controlling the strip.
- Restart using only one launcher.

### “Another process already owns the port”

Close old command windows, then run the chosen launcher again. The scripts use:

- UDP `4048`: OpenRGB DDP
- UDP `1920`: built-in visualizer
- TCP `6742`: OpenRGB SDK

### Connected, but colors do not change

The bridge must discover `FFF3` with `writeWithoutResponse`. If logs show
characteristic `2A00`, the wrong GATT characteristic was selected.

### The strip disconnects

- Keep the strip close to the PC while testing.
- Close the mobile app.
- Remove the strip from other active Bluetooth controllers.
- Power-cycle the LED controller.
- Restart Bluetooth or the PC if Windows has retained a stale BLE connection.

See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for detailed diagnostics.

## Limitations

- The tested controller applies one RGB color to the whole strip.
- OpenRGB multi-pixel effects are averaged into one whole-strip color.
- BLE has lower update bandwidth than USB or Wi-Fi lighting controllers.
- Windows only; this project uses `noble-winrt`.

## Safety

Use the power supply specified for your strip. This software only sends
Bluetooth commands; it does not protect against an incorrect power supply,
overloaded controller, damaged wiring, or overheating.

## Credits

- [OpenRGB](https://openrgb.org/)
- [OpenRGB Effects Plugin](https://openrgb.org/plugins.html)
- [`homebridge-ledstrip-bledom`](https://github.com/bjclopes/homebridge-ledstrip-bledom)
- [`noble-winrt`](https://github.com/urish/noble-winrt)

This project is not affiliated with Lotus Lantern, OpenRGB, or the LED
controller manufacturer.
