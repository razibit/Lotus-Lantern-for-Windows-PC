import { createSocket } from "node:dgram";
import { writeFileSync, unlinkSync } from "node:fs";
import Device from "./src/ble-device.cjs";

if (!process.argv[2]) {
  throw new Error("pls enter uuid");
}

const ddpServer = createSocket("udp4");
const uuid = process.argv[2];
writeFileSync("connector.pid", String(process.pid));
process.on("exit", () => {
  try {
    unlinkSync("connector.pid");
  } catch {}
});
console.log(`[lotus-lantern] Initializing LED strip with UUID: ${uuid}`);
const device = new Device(uuid);

// Keep only the newest color. Music data becomes stale immediately, so it
// should never build up in the BLE command queue.
const MIN_COMMAND_INTERVAL = 200;
let pendingColor = null;
let isProcessing = false;

// Log connection status
setInterval(() => {
  if (device.connected && !device.lastLoggedConnected) {
    console.log(`[lotus-lantern] ✓ BLE Connected and ready!`);
    device.lastLoggedConnected = true;
  } else if (!device.connected && device.lastLoggedConnected) {
    console.log(`[lotus-lantern] ✗ BLE Disconnected`);
    device.lastLoggedConnected = false;
  }
}, 1000);

function handleServerError(name, err) {
  if (err.code === "EADDRINUSE") {
    console.error(`[lotus-lantern] Another process already owns the ${name} port.`);
  } else {
    console.error(`${name} server error: ${err.stack}`);
  }
  process.exit(1);
}

ddpServer.on("error", (err) => handleServerError("OpenRGB DDP 4048", err));

ddpServer.on("listening", () => {
  console.log("[lotus-lantern] OpenRGB DDP listening on UDP 4048");
});

ddpServer.on("message", (msg) => {
  if (msg.length < 13 || (msg[0] & 0xc0) !== 0x40) return;

  const dataLength = msg.readUInt16BE(8);
  const payload = msg.subarray(10, Math.min(msg.length, 10 + dataLength));
  const pixelCount = Math.floor(payload.length / 3);
  if (pixelCount === 0) return;

  let red = 0;
  let green = 0;
  let blue = 0;
  for (let i = 0; i < pixelCount * 3; i += 3) {
    red += payload[i];
    green += payload[i + 1];
    blue += payload[i + 2];
  }

  pendingColor = {
    r: Math.round(red / pixelCount),
    g: Math.round(green / pixelCount),
    b: Math.round(blue / pixelCount),
  };
});

async function sendLatestColor() {
  if (isProcessing || !pendingColor) return;
  isProcessing = true;

  const color = pendingColor;
  pendingColor = null;

  try {
    if (!device.connected) {
      await device.connect();
    }
    if (!device.connected) {
      pendingColor = color;
      return;
    }

    await device.set_rgb(color.r, color.g, color.b);
    console.log(`[lotus-lantern] Applied RGB ${color.r},${color.g},${color.b}`);
  } catch (err) {
    console.error(`[lotus-lantern] RGB write failed: ${err.message}`);
  } finally {
    isProcessing = false;
  }
}

setInterval(sendLatestColor, MIN_COMMAND_INTERVAL);

ddpServer.bind(4048, "127.0.0.1");
