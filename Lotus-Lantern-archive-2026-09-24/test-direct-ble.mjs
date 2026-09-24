import Device from "@bjclopes/homebridge-ledstrip-bledom/Device.js";

console.log("Testing direct BLE connection to LED strip...");

const device = new Device("BE27BA000D79");

// Wait for connection
await new Promise(resolve => setTimeout(resolve, 5000));

if (!device.connected) {
  console.log("❌ Device not connected!");
  process.exit(1);
}

console.log("✓ Device connected!");
console.log("Device state:", {
  connected: device.connected,
  peripheral: !!device.peripheral,
  write: !!device.write
});

// Test sequence with delays
const colors = [
  { r: 255, g: 0, b: 0, name: "RED" },
  { r: 0, g: 255, b: 0, name: "GREEN" },
  { r: 0, g: 0, b: 255, name: "BLUE" },
  { r: 255, g: 255, b: 255, name: "WHITE" },
  { r: 0, g: 0, b: 0, name: "OFF" }
];

for (const color of colors) {
  console.log(`\nSending ${color.name}...`);
  try {
    await device.set_rgb(color.r, color.g, color.b);
    console.log(`✓ ${color.name} sent successfully`);
    await new Promise(resolve => setTimeout(resolve, 2000));
  } catch (err) {
    console.error(`❌ Failed to send ${color.name}:`, err.message);
  }
}

console.log("\nTest complete!");
process.exit(0);
