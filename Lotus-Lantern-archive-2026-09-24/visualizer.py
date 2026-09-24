"""
Audio Visualizer for Lotus Lantern LED Strip
Captures system audio (YouTube Music, etc.) and sends colors to the LED strip via UDP.

Usage:
  1. Run connect-led.cmd first to connect the LED strip
  2. Run this script: python visualizer.py
  3. Play music on your PC - lights will sync!

Press Ctrl+C to stop.
"""

import soundcard as sc
import numpy as np
import socket
import time
import sys
import warnings
from pathlib import Path
import os

# Suppress soundcard buffer warnings
warnings.filterwarnings("ignore")

UDP_IP = "127.0.0.1"
UDP_PORT = 1920
SAMPLE_RATE = 44100
BLOCK_SIZE = 1024
UPDATE_RATE = 10

SMOOTHING = 0.3
MIN_BRIGHTNESS = 18
NOISE_GATE = 0.003

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
PID_FILE = Path(__file__).with_name("visualizer.pid")


def analyze_audio(data, band_peak):
    """Analyze audio and return (r, g, b) values 0-255."""
    if len(data) < BLOCK_SIZE:
        return (0, 0, 0), band_peak

    # Mix to mono if stereo
    if data.ndim > 1:
        mono = np.mean(data, axis=1)
    else:
        mono = data.flatten()

    mono = mono[:BLOCK_SIZE]
    rms = float(np.sqrt(np.mean(mono * mono)))
    if rms < NOISE_GATE:
        return (0, 0, 0), band_peak

    # A Hann window prevents energy from leaking across frequency bands.
    fft = np.abs(np.fft.rfft(mono * np.hanning(len(mono))))
    freqs = np.fft.rfftfreq(BLOCK_SIZE, 1.0 / SAMPLE_RATE)

    # Frequency bands
    bass = fft[(freqs >= 20) & (freqs < 250)]
    mid = fft[(freqs >= 250) & (freqs < 2000)]
    treble = fft[(freqs >= 2000) & (freqs < 8000)]

    levels = np.array([
        np.sqrt(np.mean(bass * bass)) if len(bass) else 0,
        np.sqrt(np.mean(mid * mid)) if len(mid) else 0,
        np.sqrt(np.mean(treble * treble)) if len(treble) else 0,
    ])

    band_peak = np.maximum(levels, band_peak * 0.96)
    normalized = np.divide(
        levels, band_peak, out=np.zeros_like(levels), where=band_peak > 1e-9
    )
    strongest = float(np.max(levels))
    if strongest > 0:
        normalized *= levels / strongest
    normalized = np.sqrt(np.clip(normalized, 0, 1))
    rgb = np.where(
        normalized > 0.03,
        MIN_BRIGHTNESS + normalized * (255 - MIN_BRIGHTNESS),
        0,
    )

    return tuple(rgb.astype(int)), band_peak


def send_color(r, g, b):
    """Send RGB color to LED strip via UDP."""
    packet = bytes([0x00, r, g, b, 0x00, 0x00])
    sock.sendto(packet, (UDP_IP, UDP_PORT))


def main():
    PID_FILE.write_text(str(os.getpid()), encoding="ascii")
    prev_r, prev_g, prev_b = 0, 0, 0
    band_peak = np.full(3, 1e-6)

    print("=" * 50)
    print("  LOTUS LANTERN - AUDIO VISUALIZER")
    print("=" * 50)
    print(f"  Sending colors to: {UDP_IP}:{UDP_PORT}")
    print(f"  Update rate: {UPDATE_RATE} fps")
    print(f"  Press Ctrl+C to stop")
    print("=" * 50)
    print()

    # Find the loopback device for the default speaker
    speaker = sc.default_speaker()
    print(f"Speaker: {speaker.name}")

    loopback = sc.get_microphone(id=str(speaker.name), include_loopback=True)
    if loopback is None:
        # Fallback: try first loopback device
        mics = sc.all_microphones(include_loopback=True)
        loopback_mics = [m for m in mics if m.isloopback]
        if loopback_mics:
            loopback = loopback_mics[0]
            print(f"Loopback device: {loopback.name}")
        else:
            print("ERROR: No loopback device found!")
            sys.exit(1)
    else:
        print(f"Loopback: {loopback.name}")

    print()
    print("Listening for system audio... Play some music!")
    print()

    frame_time = 1.0 / UPDATE_RATE
    last_send = 0

    with loopback.recorder(samplerate=SAMPLE_RATE, channels=2) as mic:
        try:
            while True:
                now = time.time()
                if now - last_send >= frame_time:
                    last_send = now

                    data = mic.record(numframes=BLOCK_SIZE)

                    (r, g, b), band_peak = analyze_audio(data, band_peak)

                    r = int(prev_r + SMOOTHING * (r - prev_r))
                    g = int(prev_g + SMOOTHING * (g - prev_g))
                    b = int(prev_b + SMOOTHING * (b - prev_b))

                    prev_r, prev_g, prev_b = r, g, b

                    send_color(r, g, b)

                    # Visual feedback bars
                    bar_r = "#" * (r // 16)
                    bar_g = "#" * (g // 16)
                    bar_b = "#" * (b // 16)
                    print(f"\r  R:[{bar_r:<16}] G:[{bar_g:<16}] B:[{bar_b:<16}] ({r:3d},{g:3d},{b:3d})", end="", flush=True)

                time.sleep(0.005)
        except KeyboardInterrupt:
            print("\n\nStopped. Turning off LED...")
            send_color(0, 0, 0)
            sock.close()
        finally:
            PID_FILE.unlink(missing_ok=True)


if __name__ == "__main__":
    main()
