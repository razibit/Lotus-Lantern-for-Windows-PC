# Troubleshooting

## Expected path

```text
OpenRGB Audio Party -> Lotus Lantern BLE virtual device -> DDP/UDP 127.0.0.1:4048 -> bridge -> BLE FFF3 -> strip
```

1. Turn on the LED controller and Windows Bluetooth.
2. Close the Lotus Lantern mobile app and other strip controllers.
3. Confirm the strip address in `config.cmd` and the OpenRGB executable path.
4. Run `start-openrgb-ble-sync.cmd` and wait for BLE discovery.
5. In OpenRGB Effects, select **Lotus Lantern BLE**, load an Audio Party profile, select the correct audio output, and start the effect.

## OpenRGB does not show the strip

The launcher configures a DDP device named `Lotus Lantern BLE` at `127.0.0.1:4048` with one LED. OpenRGB must have been opened once to create its configuration. In **Settings > Supported Devices**, enable DDP, then restart OpenRGB if needed.

The OpenRGB SDK server is TCP `6742`. Do not configure its Client page to use DDP port `4048`.

## Connected but colors do not change

Check that Audio Party is running, the right playback device is selected, and **Lotus Lantern BLE** is selected in Effects. The bridge must discover characteristic `FFF3` with `writeWithoutResponse`. Characteristic `2A00` is not the LED write target.

The bridge listens only on `127.0.0.1:4048/UDP`. Another process owning that port prevents startup. `connector.pid` is generated while the bridge runs; the launcher uses it to stop a previous bridge instance. Avoid terminating unrelated Node processes.

## Strip disconnects

Keep the controller near the laptop, close the mobile app, and power-cycle the strip if Windows holds a stale BLE connection. Restart Bluetooth if discovery still fails.

## Compatibility

The tested controller advertises as `ELK-BLEDDM`, exposes service `FFF0`, and has a writable `FFF3` characteristic. A strip using another app or BLE protocol may need a different adapter.
