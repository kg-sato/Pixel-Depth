"""Pixel Depths UI kit for Roblox, drawn from the Claude Design board (UI kit artboard): notched navy panels with gold trim,
chunky buttons (ink outline, light top band, dark bottom band), 12 x 12 pixel icons. Each logical pixel is 4x4 image pixels.
Usage: python pd_ui.py <out_dir>  -> 9-slice PNGs + icons + _sheet.png"""
import os, sys
from PIL import Image

OUT = sys.argv[1] if len(sys.argv) > 1 else "ui"
os.makedirs(OUT, exist_ok=True)
K = 4  # image pixels per logical pixel


def H(h):
    return tuple(int(h[i:i + 2], 16) for i in (1, 3, 5)) + (255,)


INK, PANEL, RAISED, TRIM, GOLD, CREAM = H("#0b0e1f"), H("#161c3a"), H("#232c5c"), H("#c9a25c"), H("#ffce46"), H("#fff4d6")
CLEAR = (0, 0, 0, 0)


def notched(w, h, fill_fn):
    """w x h logical pixels; corners cut in a 2-step pixel notch; fill_fn(x, y, ring) gives the colour (ring = distance to edge)"""
    im = Image.new("RGBA", (w * K, h * K), CLEAR)
    px = im.load()
    for y in range(h):
        for x in range(w):
            dx, dy = min(x, w - 1 - x), min(y, h - 1 - y)
            if dx + dy < 2 and not (dx == 1 and dy == 1) and (dx < 2 and dy < 2):  # cut the outer corner steps
                if dx == 0 and dy <= 1 or dy == 0 and dx <= 1:
                    continue
            c = fill_fn(x, y, min(dx, dy), w, h)
            for yy in range(K):
                for xx in range(K):
                    px[x * K + xx, y * K + yy] = c
    return im


def panel_fill(fill, trim, top):
    def f(x, y, ring, w, h):
        if ring == 0:
            return INK
        if ring == 1 and trim:
            return trim
        if y in (2, 3) and trim and 1 < x < w - 2:
            return top
        return fill
    return f


def button_fill(fill, light, dark):
    def f(x, y, ring, w, h):
        if ring == 0:
            return INK
        if y == 1:
            return light
        if y >= h - 3:
            return dark
        return fill
    return f


SHEETS = {
    "panel": (16, 16, panel_fill(PANEL, TRIM, RAISED)),
    "card": (16, 16, panel_fill(H("#2a2010"), TRIM, H("#3a2e18"))),
    "pill": (16, 16, panel_fill(H("#10142c"), H("#3a4787"), H("#1a2148"))),
    "btn_green": (16, 16, button_fill(H("#4cc94f"), H("#8df07a"), H("#237a2c"))),
    "btn_navy": (16, 16, button_fill(H("#26306a"), H("#3b4a9a"), H("#141a3d"))),
    "btn_red": (16, 16, button_fill(H("#e2493f"), H("#ff8a7a"), H("#8a221d"))),
    "btn_off": (16, 16, button_fill(H("#4a4f66"), H("#6a7090"), H("#2a2d3c"))),
    "btn_gold": (16, 16, button_fill(H("#ffce46"), H("#fff0a0"), H("#d98b16"))),
}
for name, (w, h, fn) in SHEETS.items():
    notched(w, h, fn).save(os.path.join(OUT, name + ".png"))

# 12 x 12 icons: letters map to colours, '.' is clear
PAL = {"k": INK, "y": GOLD, "o": H("#d98b16"), "w": H("#ffffff"), "c": CREAM, "b": H("#3fd2ff"), "B": H("#1b78b4"),
       "g": H("#8a8fa8"), "G": H("#5a5f78"), "n": H("#a8703c"), "N": H("#6e4426"), "p": H("#f596be"), "P": H("#c25a7a"),
       "m": H("#8ce3c0"), "M": H("#2f7f73"), "l": H("#c9b8f2"), "L": H("#6c5aa8"), "r": H("#e2493f"), "e": H("#f8ece2"), "E": H("#b9a3b0")}
ICONS = {
    "coin": ["...kkkkkk...", "..kyyyyyyk..", ".kyywwyyyok.", "kyywyyyyyyok", "kyyyyoyyyyok", "kyyyyoyyyyok", "kyyyyoyyyyok",
             "kyyyyoyyyyok", "kyyyyyyyyook", ".kyyyyyyook.", "..koooooook.", "...kkkkkk..."],
    "gem": ["............", "...kkkkkk...", "..kwbbbbbk..", ".kwbbwbbbBk.", "kkkkkkkkkkkk", "kbwbbbbbbBBk", ".kbbbbbbbBk.",
            "..kbbbbbBk..", "...kbbbBk...", "....kbBk....", ".....kk.....", "............"],
    "pick": ["............", ".kkkk..kkkk.", "kggggkkggggk", "kgwwgggggGGk", ".kkkkgGkkkk.", ".....knk....", "....knNk....",
             "...knNk.....", "..knNk......", ".knNk.......", "knNk........", "kkk........."],
    "bag": ["....kkkk....", "...kNkkNk...", "..kkkkkkkk..", ".knnnnnnnnk.", "knnnyyyynnnk", "knnnykkynnNk", "knnnnnnnnnNk",
            "knnnnnnnnnNk", "knnnnnnnnNNk", ".kNNNNNNNNk.", "..kkkkkkkk..", "............"],
    "crew": ["..k......k..", ".kpk....kpk.", ".kppkkkkppk.", "kppppppppppk", "kppkwppkwppk", "kppkkppkkppk", "kpppppppppPk",
             "kppppkkppPPk", ".kppppppPPk.", "..kpk..kPk..", "..kk....kk..", "............"],
    "surface": ["....kkkk....", "...kmmmmk...", "..kmmmmmmk..", ".kkkkmmkkkk.", "....kmmk....", "....kmmk....", "....kmmk....",
                "....kmmk....", "...kkkkkk...", "..kcccccck..", ".kkkkkkkkkk.", "............"],
    "egg": ["....kkkk....", "...keeeek...", "..keeeEeek..", ".keweeeeeek.", ".keeeeEeeek.", "keeEeeeeeeEk", "keeeeeEeeeEk",
            "keEeeeeeeeEk", ".keeeeeeeEk.", ".kEeeeeeEEk.", "..kkEEEEkk..", "....kkkk...."],
    "star": [".....kk.....", "....kyyk....", "....kyyk....", "kkkkkyyokkkk", "kyywyyyyyyok", ".kyyyyyyyok.", "..kyyyyyyok.",
             "..kyyyooyok.", ".kyyok.kyyok", ".kyok...kyok", ".kkk.....kkk", "............"],
    "dice": ["............", ".kkkkkkkkkk.", ".kwwwwwwwwck", ".kwkwwwwkwck", ".kwwwwwwwwck", ".kwwwkkwwwck", ".kwwwkkwwwck",
             ".kwwwwwwwwck", ".kwkwwwwkwck", ".kccccccccck", ".kkkkkkkkkk.", "............"],
    "map": ["............", "kkkkkkkkkkkk", "kcccckccccck", "kcmmckcllcck", "kcmmmkclllck", "kccmmkcclcck", "kcccckccrcck",
            "kclllkcrrrck", "kcllckccrcck", "kcccckccccck", "kkkkkkkkkkkk", "............"],
}
for name, rows in ICONS.items():
    im = Image.new("RGBA", (12 * K, 12 * K), CLEAR)
    px = im.load()
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch != ".":
                for yy in range(K):
                    for xx in range(K):
                        px[x * K + xx, y * K + yy] = PAL[ch]
    im.save(os.path.join(OUT, "icon_" + name + ".png"))

files = sorted(f for f in os.listdir(OUT) if f.endswith(".png") and not f.startswith("_"))
sheet = Image.new("RGBA", (len(files) * 70, 70), (40, 40, 60, 255))
for i, f in enumerate(files):
    im = Image.open(os.path.join(OUT, f))
    sheet.paste(im, (i * 70 + 3, 3), im)
sheet.resize((sheet.width * 2, sheet.height * 2), Image.NEAREST).save(os.path.join(OUT, "_sheet.png"))
print(len(files), "ui images")
