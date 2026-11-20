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
        self.assertEqual(fix.decode(report(0, 0, 31371, 0))[2], 31371)

    def test_plunger_past_rest_is_negative(self):
        self.assertEqual(fix.decode(report(-512, 512, -12532, 0x8000)), [-512, 512, -12532])


if __name__ == "__main__":
    unittest.main()
