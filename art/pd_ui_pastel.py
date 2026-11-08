"""Pixel Depths pastel UI kit (2026-11-08, the user: "rework the UI to match the pastel theme"). Same pixel-notch shapes
as pd_ui.py, recoloured to the key art palette: cream panels with lilac trim, mint / pink / lilac / butter / sky buttons,
plum ink outlines instead of navy. Each logical pixel is 4x4 image pixels; 16x16 logical = 64 px 9-slice with 16 px margins.
Usage: python pd_ui_pastel.py <out_dir>"""
import os, sys
from PIL import Image

OUT = sys.argv[1] if len(sys.argv) > 1 else "ui_pastel"
os.makedirs(OUT, exist_ok=True)
K = 4


def H(h):
    return tuple(int(h[i:i + 2], 16) for i in (1, 3, 5)) + (255,)


INK = H("#3e2a56")
CLEAR = (0, 0, 0, 0)


def notched(w, h, fill_fn):
    im = Image.new("RGBA", (w * K, h * K), CLEAR)
    px = im.load()
    for y in range(h):
        for x in range(w):
            dx, dy = min(x, w - 1 - x), min(y, h - 1 - y)
            if (dx == 0 and dy <= 1) or (dy == 0 and dx <= 1):
                continue  # pixel notch on each corner
            c = fill_fn(x, y, min(dx, dy), w, h)
            for yy in range(K):
                for xx in range(K):
                    px[x * K + xx, y * K + yy] = c
    return im


def panel_fill(fill, trim, top, shade):
    def f(x, y, ring, w, h):
        if ring == 0:
            return INK
        if ring == 1:
            return trim
        if y == 2 and 1 < x < w - 2:
            return top
        if y >= h - 3:
            return shade
        return fill
    return f


def button_fill(fill, light, dark):
    def f(x, y, ring, w, h):
        if ring == 0:
            return INK
        if y in (1, 2) and 1 <= x <= w - 2:
            return light if y == 1 else fill
        if y >= h - 4:
            return dark
        return fill
    return f


SHEETS = {
    "panel": panel_fill(H("#fff7ee"), H("#c9b8f2"), H("#ffffff"), H("#f1e2f0")),
    "card": panel_fill(H("#fff3d0"), H("#ffcf8a"), H("#ffffff"), H("#f7e2b4")),
    "pill": panel_fill(H("#f6f0ff"), H("#c9b8f2"), H("#ffffff"), H("#e6dcf8")),
    "dark": panel_fill(H("#4a3866"), H("#8a72c8"), H("#5c4880"), H("#3a2c52")),
    "btn_mint": button_fill(H("#7fdcb4"), H("#c6f7e2"), H("#3f9c84")),
    "btn_pink": button_fill(H("#ff9db0"), H("#ffd6de"), H("#c25a7a")),
    "btn_lilac": button_fill(H("#b9a4ee"), H("#e6dcff"), H("#6c5aa8")),
    "btn_butter": button_fill(H("#ffd970"), H("#fff3c0"), H("#d9962e")),
    "btn_sky": button_fill(H("#8ec8ff"), H("#d6ecff"), H("#4a7fc0")),
    "btn_off": button_fill(H("#c8bfd6"), H("#e8e2f0"), H("#8a7fa0")),
}
for name, fn in SHEETS.items():
    notched(16, 16, fn).save(os.path.join(OUT, name + ".png"))
files = sorted(f for f in os.listdir(OUT) if f.endswith(".png") and not f.startswith("_"))
sheet = Image.new("RGBA", (len(files) * 70, 70), (60, 44, 84, 255))
for i, f in enumerate(files):
    im = Image.open(os.path.join(OUT, f))
    sheet.paste(im, (i * 70 + 3, 3), im)
sheet.resize((sheet.width * 2, sheet.height * 2), Image.NEAREST).save(os.path.join(OUT, "_sheet.png"))
print(len(files), "pastel ui images")
