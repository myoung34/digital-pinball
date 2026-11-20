# Show a placeholder on the real DMD while the VPinFE wheel is up.
#
# Sends one RGB24 frame to dmdserver with the "buffered" flag: dmdserver shows
# it now, and goes back to it whenever a game disconnects instead of blanking.
import socket
import struct
import sys
import time

from PIL import Image, ImageDraw, ImageFont

WIDTH, HEIGHT = 128, 32
COLOR = (128, 44, 16)  # same ~50% tint as the game frames (DMD brownouts)


def frame(font_path):
    img = Image.new("RGB", (WIDTH, HEIGHT))
    draw = ImageDraw.Draw(img)
    for text, y, size in (("PINBALL", 1, 16), ("PRESS START", 20, 10)):
        font = ImageFont.truetype(font_path, size)
        width = draw.textlength(text, font=font)
        draw.text(((WIDTH - width) / 2, y), text, fill=COLOR, font=font)
    return img.tobytes()


def header(length):
    # DMDUtil::DMD::StreamHeader: packed, network byte order,
    # mode 2 = RGB24, buffered = 1.
    return struct.pack(
        "!10sBiHHBBI", b"DMDStream", 1, 2, WIDTH, HEIGHT, 1, 0, length
    )


def main(font_path, port=6789):
    data = frame(font_path)
    for _ in range(30):
        try:
            with socket.create_connection(("127.0.0.1", port), timeout=2) as sock:
                sock.sendall(header(len(data)) + data)
                time.sleep(0.5)  # let dmdserver read it before we hang up
            return 0
        except OSError:
            time.sleep(1)
    print("dmdserver not reachable", file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1]))
