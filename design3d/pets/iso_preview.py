"""Quick isometric preview of design3d/pets/pets.json (or VOXEL_JSON): python iso_preview.py out.png [Name,Name]
Painter's-order cube faces with simple top/left/right shading, so a design change can be graded before the Blender bake."""
import json, os, sys
from PIL import Image, ImageDraw

here = os.path.dirname(os.path.abspath(__file__))
pets = json.load(open(os.environ.get("VOXEL_JSON") or os.path.join(here, "pets.json")))
only = set(sys.argv[2].split(",")) if len(sys.argv) > 2 else None
pets = [p for p in pets if not only or p["name"] in only]
S, W, H = 9, 520, 520
FLIP = os.environ.get("ISO_SIDE", "left") == "left"  # pixels per voxel edge, cell size


def hexc(h, f):
    h = h.lstrip("#"); return tuple(min(255, int(int(h[i:i + 2], 16) * f)) for i in (0, 2, 4))


def render(p):
    img = Image.new("RGB", (W, H), (34, 20, 48)); d = ImageDraw.Draw(img)
    cells = {(x, y, z): r for vs in p["parts"].values() for x, y, z, r in vs}
    # view from front-left-top: the pet looks +z, so the camera sits at +z, -x
    def proj(x, y, z):
        return (W / 2 + (x + z) * S * 0.866, H * 0.78 - y * S + (z - x) * S * 0.5 - (x + z) * 0)
    def P(x, y, z):
        sx = W / 2 + (z - x) * S * 0.866
        sy = H * 0.8 - y * S + (x + z) * S * 0.5
        return (sx, sy)
    if FLIP:  # camera at front-left (-x, +z) like the board preview: mirror x, then the same front-right drawing
        cells = {(-x - 1, y, z): r for (x, y, z), r in cells.items()}
    for (x, y, z) in sorted(cells, key=lambda c: (c[0] + c[2], c[1])):
        col = p["palette"][cells[(x, y, z)]]
        if (x, y + 1, z) not in cells:
            d.polygon([P(x, y + 1, z), P(x + 1, y + 1, z), P(x + 1, y + 1, z + 1), P(x, y + 1, z + 1)], fill=hexc(col, 1.0))
        if (x + 1, y, z) not in cells:
            d.polygon([P(x + 1, y, z), P(x + 1, y + 1, z), P(x + 1, y + 1, z + 1), P(x + 1, y, z + 1)], fill=hexc(col, 0.62))
        if (x, y, z + 1) not in cells:
            d.polygon([P(x, y, z + 1), P(x + 1, y, z + 1), P(x + 1, y + 1, z + 1), P(x, y + 1, z + 1)], fill=hexc(col, 0.82))
    d.text((8, 6), p["name"], fill=(230, 220, 250))
    return img


cols = min(4, len(pets)); rows = (len(pets) + cols - 1) // cols
sheet = Image.new("RGB", (W * cols, H * rows), (20, 12, 30))
for i, p in enumerate(pets): sheet.paste(render(p), ((i % cols) * W, (i // cols) * H))
sheet.save(sys.argv[1]); print("saved", sys.argv[1])
