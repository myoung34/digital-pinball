import importlib.util
import sys
import unittest
from unittest import mock

sys.modules["evdev"] = mock.MagicMock()  # only decode() is under test
spec = importlib.util.spec_from_file_location("fix", sys.argv.pop())
fix = importlib.util.module_from_spec(spec)
spec.loader.exec_module(fix)


def report(x, y, z, buttons):
    raw = b"".join(v.to_bytes(2, "little", signed=True) for v in (x, y, z))
    return raw + buttons.to_bytes(2, "little") + bytes(49)


class Decode(unittest.TestCase):
    def test_pulled_plunger_is_positive(self):
        axes, _ = fix.decode(report(0, 0, 31371, 0))
        self.assertEqual(axes[2], 31371)

    def test_plunger_past_rest_is_negative(self):
        axes, _ = fix.decode(report(-512, 512, -12532, 0))
        self.assertEqual(axes, [-512, 512, -12532])

    def test_launch_button_is_index_15(self):
        _, buttons = fix.decode(report(0, 0, 0, 0x8000))
        self.assertEqual(buttons.index(1), 15)
        self.assertEqual(sum(buttons), 1)


if __name__ == "__main__":
    unittest.main()
