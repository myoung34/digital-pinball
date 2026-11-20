# Re-publish the VirtuaPin Controller as a uinput joystick with signed axes.
#
# Its HID descriptor declares X/Y/Z as unsigned (0..-1), but the board sends
# signed values: the plunger is 0 at rest, ~32000 fully pulled and negative
# when it springs past rest. Linux drops/mangles those, so VPX never sees the
# analog plunger. Reading hidraw also keeps the board from resetting itself
# every few seconds when nothing polls it.
#
# Only the axes are republished. Buttons stay on the real device: a second copy
# makes VPinFE (Chromium) see every press twice, which skips wheel entries and
# relaunches a table right after it exits.
import glob
import os
import time

from evdev import AbsInfo, UInput, ecodes as e

NAME = "VirtuaPin Controller"
# Declared but never pressed: udev only tags the device as a joystick (so SDL
# sees it) when it has joystick buttons.
BUTTONS = list(range(e.BTN_TRIGGER, e.BTN_TRIGGER + 16))
AXIS = AbsInfo(value=0, min=-32768, max=32767, fuzz=0, flat=0, resolution=0)
AXES = [e.ABS_X, e.ABS_Y, e.ABS_Z]


def find_hidraw():
    for uevent in glob.glob("/sys/class/hidraw/hidraw*/device/uevent"):
        with open(uevent) as f:
            if f"HID_NAME={NAME}\n" in f.read():
                return "/dev/" + uevent.split("/")[4]
    return None


def decode(report):
    return [int.from_bytes(report[i : i + 2], "little", signed=True) for i in (0, 2, 4)]


def main():
    ui = UInput(
        {e.EV_KEY: BUTTONS, e.EV_ABS: [(a, AXIS) for a in AXES]},
        name=f"{NAME} (signed)",
        vendor=0x1234,
        product=0x0111,
        version=0x0001,
    )
    while True:
        path = find_hidraw()
        if path is None:
            time.sleep(0.5)
            continue
        try:
            fd = os.open(path, os.O_RDONLY)
        except OSError:
            time.sleep(0.5)
            continue
        try:
            while True:
                report = os.read(fd, 64)
                if len(report) < 8:
                    continue
                for code, value in zip(AXES, decode(report)):
                    ui.write(e.EV_ABS, code, value)
                ui.syn()
        except OSError:
            pass  # device reset or unplugged; reopen
        finally:
            os.close(fd)


if __name__ == "__main__":
    main()
