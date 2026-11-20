# Give every table without a .directb2s a static one built from VPinFE's
# medias/bg.png, so VPX shows backglass art during play (VPinFE hides its own).
# Real .directb2s files dropped next to the .vpx always win.
import base64
import io
import sys
from pathlib import Path
from xml.sax.saxutils import quoteattr

from PIL import Image, ImageOps

SIZE = 1920  # the backglass screen is 1920x1920


def directb2s(name, png):
    image = quoteattr(base64.b64encode(png).decode())
    return f"""<?xml version="1.0" encoding="utf-8"?>
<DirectB2SData Version="1.2">
  <Name Value={quoteattr(name)} />
  <TableType Value="3" />
  <DMDType Value="1" />
  <GrillHeight Value="0" />
  <Images>
    <BackglassImage Value={image} />
  </Images>
</DirectB2SData>
"""


def square_png(path):
    art = ImageOps.fit(Image.open(path).convert("RGB"), (SIZE, SIZE))
    out = io.BytesIO()
    art.save(out, "PNG")
    return out.getvalue()


def main(root):
    for vpx in Path(root).glob("*/*.vpx"):
        bg = vpx.parent / "medias" / "bg.png"
        if any(vpx.parent.glob("*.directb2s")) or not bg.exists():
            continue
        target = vpx.with_suffix(".directb2s")
        target.write_text(directb2s(vpx.parent.name, square_png(bg)))
        print(f"wrote {target}")


if __name__ == "__main__":
    main(sys.argv[1])
