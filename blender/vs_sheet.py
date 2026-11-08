"""vs_sheet.py <pick_XX> : concept | hero | front | side (+ a game-size inset) -> out/<pick_XX>/_vs.jpg"""
import glob, os, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFilter


def bloom(im):
    """soft glow: blur the bright parts twice and add them back (stands in for Roblox Bloom)"""
    a = np.asarray(im).astype(np.float32) / 255
    lum = (a * np.array([0.2126, 0.7152, 0.0722], np.float32)).sum(axis=2, keepdims=True)
    hi = Image.fromarray((np.clip((lum - 0.8) / 0.2, 0, 1) * a * 255).astype(np.uint8))  # only near-white highlights and emitters glow
    g = sum(np.asarray(hi.filter(ImageFilter.GaussianBlur(r))).astype(np.float32) / 255 * k for r, k in ((5, 0.45), (20, 0.5)))
    return Image.fromarray((np.clip(1 - (1 - a) * (1 - g), 0, 1) * 255).astype(np.uint8))
HERE = os.path.dirname(os.path.abspath(__file__))
tag = sys.argv[1]
out = os.path.join(HERE, "out", tag)
H = 900
def fit(p):
    im = Image.open(p).convert("RGB")
    return im.resize((int(im.width * H / im.height), H), Image.LANCZOS)
tiles = [fit(os.path.join(HERE, "..", "art", "gen", tag + ".png"))]
for lab in ("hero", "front", "side"):
    for p in glob.glob(os.path.join(out, f"*_{lab}.png")):
        fx = bloom(Image.open(p).convert("RGB"))
        fx.save(p[:-4] + "_fx.jpg", quality=90)
        tiles.append(fx.resize((int(fx.width * H / fx.height), H), Image.LANCZOS))
sheet = Image.new("RGB", (sum(t.width for t in tiles), H), (20, 16, 34))
x = 0
for t in tiles:
    sheet.paste(t, (x, 0))
    x += t.width
hero = tiles[1]
small = hero.resize((int(hero.width * 110 / H), 110), Image.LANCZOS)  # about the on-screen size in game
bx = tiles[0].width + hero.width - small.width - 10
sheet.paste(small, (bx, H - small.height - 10))
ImageDraw.Draw(sheet).rectangle([bx - 1, H - small.height - 11, bx + small.width, H - 10], outline=(255, 255, 255))
sheet.save(os.path.join(out, "_vs.jpg"), quality=88)
print(os.path.join(out, "_vs.jpg"))
