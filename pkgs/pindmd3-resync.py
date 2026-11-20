# Get the PinDMD3 back in sync before dmdserver opens it.
#
# A warm reboot doesn't reset the DMD, so it can still be halfway through a
# 12290-byte frame from before. Whatever is sent next gets eaten as pixel data:
# dmdserver's identify fails and the display shows garbage until power-cycled.
# Padding out any partial frame with zeros, then checking identify, fixes it.
import sys
import time

import serial

FRAME = 1 + 128 * 32 * 3 + 1  # start byte, RGB24 pixels, end byte


def identify(port):
    port.reset_input_buffer()
    port.write(b"\x42\x42")
    time.sleep(0.1)
    return port.read(64)


def main(device):
    for _ in range(5):
        try:
            with serial.Serial(device, 8176000, timeout=0.3, write_timeout=2) as port:
                if b"vPin" in identify(port):
                    return 0
                port.write(bytes(FRAME))
                time.sleep(0.2)
                if b"vPin" in identify(port):
                    return 0
        except (OSError, serial.SerialException) as err:
            print(err, file=sys.stderr)
        time.sleep(1)
    print("PinDMD3 did not answer; starting dmdserver anyway", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1]))
