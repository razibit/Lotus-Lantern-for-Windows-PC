import socket
import time

UDP_IP = "127.0.0.1"
UDP_PORT = 1920

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

def send_color(r, g, b):
    packet = bytes([0x00, r, g, b, 0x00, 0x00])
    print(f"Sending: R={r}, G={g}, B={b}")
    sock.sendto(packet, (UDP_IP, UDP_PORT))

print("Testing colors - watch your LED strip!")
print()

# Slow test with big changes
tests = [
    (255, 0, 0, "BRIGHT RED"),
    (0, 255, 0, "BRIGHT GREEN"),
    (0, 0, 255, "BRIGHT BLUE"),
    (255, 255, 0, "YELLOW"),
    (255, 0, 255, "MAGENTA"),
    (0, 255, 255, "CYAN"),
    (255, 255, 255, "WHITE"),
    (0, 0, 0, "OFF")
]

for r, g, b, name in tests:
    print(f"{name}...")
    send_color(r, g, b)
    time.sleep(3)

print("\nTest complete!")
sock.close()
