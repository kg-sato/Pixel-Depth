"""Pixel Depths pastel PIXEL UI kit v2 (2026-11-08, the user: "research pastel UI looks and pixel art style UI, rework the HUD,
custom interaction buttons instead of the default Roblox ones").
References (art/ui_pixel/refs.md): Sprout Lands UI pack (cupnooble), Pastel GUI bundle (penzilla), Delightful Spring GUI (rpgcookie).
What we take: a 1 px plum outline with rounded pixel corners, a chunky lilac frame with a darker bottom lip (the panel looks thick),
cream bodies with a 1 px highlight row, pill buttons with a gloss pixel and a 3 px shade lip, keycaps for key hints, a butter
tooltip bubble with a pointer, a ribbon title banner, and small flower clusters and sparkles for the panel corners.
Every logical pixel is 4 x 4 image pixels. 9-slice margins are listed in SLICE (image pixels) for the Roblox client.
Usage: python pd_ui_pixel.py <out_dir>"""
import json, os, sys
from PIL import Image

OUT = sys.argv[1] if len(sys.argv) > 1 else "ui_pixel"
os.makedirs(OUT, exist_ok=True)
K = 4
CLEAR = (0, 0, 0, 0)


def H(h, a=255):
    return tuple(int(h[i:i + 2], 16) for i in (1, 3, 5)) + (a,)


INK = H("#3e2a56")


def inside(x, y, w, h, inset, notch, bottom=0):
    x0, y0, x1, y1 = inset, inset, w - 1 - inset, h - 1 - inset - bottom
    if x < x0 or x > x1 or y < y0 or y > y1:
        return False
    dx, dy = min(x - x0, x1 - x), min(y - y0, y1 - y)
    return dx + dy >= notch  # rounded pixel corners


def shape(w, h, notch, rim, lip, c):
    """c: outline, rim_light, rim, rim_dark, inner, body_light, body, body_shade (any may be None)."""
    im = Image.new("RGBA", (w, h), CLEAR)
    px = im.load()
    for y in range(h):
        for x in range(w):
            if not inside(x, y, w, h, 0, notch):
                continue
            if not inside(x, y, w, h, 1, max(notch - 1, 0)):
                px[x, y] = c["outline"]
                continue
            if rim and not inside(x, y, w, h, 1 + rim, max(notch - 1, 0), lip):
                if y >= h - 1 - (1 + rim + lip) + 1 and lip:
                    px[x, y] = c["rim_dark"]
                elif y <= rim or x <= rim:
                    px[x, y] = c["rim_light"]  # lit top and left edges
                elif x >= w - 1 - rim:
                    px[x, y] = c.get("rim_side", c["rim"])  # shaded right edge
                else:
                    px[x, y] = c["rim"]
                continue
            inner_ok = inside(x, y, w, h, 1 + rim + (1 if c.get("inner") else 0), max(notch - 2, 0), lip)
            if c.get("inner") and not inner_ok:
                px[x, y] = c["inner"]
                continue
            # body
            top = 1 + rim + (1 if c.get("inner") else 0)
            bot = h - 2 - rim - lip - (1 if c.get("inner") else 0)
            if not rim and lip and y > bot:
                px[x, y] = c["body_shade"]  # buttons: the lip is the body's shade
            elif not rim and c.get("body_light") and inside(x, y, w, h, 1, 0) and x == 1:
                px[x, y] = c["body_light"]
            elif not rim and c.get("body_side") and x == w - 2:
                px[x, y] = c["body_side"]
            elif y == top and c.get("body_light"):
                px[x, y] = c["body_light"]
            elif y == bot and c.get("body_shade") and rim:
                px[x, y] = c["body_shade"]
            else:
                px[x, y] = c["body"]
    return im


def up(im):
    return im.resize((im.width * K, im.height * K), Image.NEAREST)


LILAC = dict(rim_light=H("#e6dcff"), rim=H("#b9a4ee"), rim_side=H("#9a86d6"), rim_dark=H("#8a72c8"), inner=H("#6c5aa8"))


def corner_flowers(im, inset):
    """Tiny pink flowers worked into the two top corners of a frame (they sit inside the 9-slice corners)."""
    px = im.load()
    for cx in (inset + 1, im.width - 2 - inset):
        cy = inset + 1
        for dx, dy in ((0, -1), (-1, 0), (1, 0), (0, 1)):
            px[cx + dx, cy + dy] = H("#ff9db0")
        px[cx, cy] = H("#ffd970")
    return im
SKINS, SLICE = {}, {}


def add(name, im, l, t, r, b):
    SKINS[name] = im
    SLICE[name] = [l * K, t * K, (im.width - r) * K, (im.height - b) * K]  # Rect(left, top, right, bottom) in image pixels


# panel: cream body in a chunky lilac frame with a thick bottom lip
add("panel", corner_flowers(shape(28, 30, 3, 3, 2, dict(outline=INK, **LILAC, body_light=H("#ffffff"), body=H("#fff7ee"), body_shade=H("#f1e2f0"))), 1), 9, 9, 9, 11)
# card: butter tooltip / tutorial card
add("card", shape(24, 24, 3, 2, 2, dict(outline=INK, rim_light=H("#fff3c0"), rim=H("#ffd970"), rim_side=H("#f2be55"), rim_dark=H("#d9962e"), inner=H("#c9852a"),
                                        body_light=H("#ffffff"), body=H("#fff6d6"), body_shade=H("#ffe9a8"))), 7, 7, 7, 9)
# pill: cream currency pill with a thin lilac rim, very round ends
add("pill", shape(24, 16, 4, 2, 1, dict(outline=INK, rim_light=H("#e6dcff"), rim=H("#c9b8f2"), rim_side=H("#b9a4ee"), rim_dark=H("#8a72c8"), inner=None,
                                         body_light=H("#ffffff"), body=H("#fdf8ff"), body_shade=H("#efe6ff"))), 7, 6, 7, 7)
# dark: translucent plum (pickup feed, scrims inside panels)
add("dark", shape(16, 16, 2, 1, 0, dict(outline=H("#2a1c3a", 230), rim_light=H("#6c5aa8", 220), rim=H("#5a4888", 220), rim_dark=H("#4a3b7a", 220),
                                         inner=None, body=H("#3e2a56", 200))), 4, 4, 4, 4)
# buttons: body, a gloss row, a 3 px shade lip, plum outline, round corners
BTN = {
    "mint": ("#7fdcb4", "#c6f7e2", "#3f9c84"), "pink": ("#ff9db0", "#ffd6de", "#c25a7a"), "lilac": ("#b9a4ee", "#e6dcff", "#6c5aa8"),
    "butter": ("#ffd970", "#fff3c0", "#d9962e"), "sky": ("#8ec8ff", "#d6ecff", "#4a7fc0"), "off": ("#c8bfd6", "#e8e2f0", "#8a7fa0"),
}
for k, (b, l, d) in BTN.items():
    im = shape(24, 20, 3, 0, 3, dict(outline=INK, body_light=H(l), body=H(b), body_shade=H(d), body_side=H(d)))
    px = im.load()
    for x, y in ((3, 2), (4, 2), (2, 3)):
        px[x, y] = H("#ffffff")  # gloss
    add(k, im, 7, 6, 7, 8)
# keycap: cream key with a lilac lip (key hints, the prompt key)
kc = shape(16, 17, 2, 0, 3, dict(outline=INK, body_light=H("#ffffff"), body=H("#fff7ee"), body_shade=H("#b9a4ee")))
add("keycap", kc, 5, 5, 5, 7)
kd = Image.new("RGBA", (16, 17), CLEAR)  # the pressed keycap: two pixels lower, a one pixel lip
kd.alpha_composite(shape(16, 15, 2, 0, 1, dict(outline=INK, body_light=H("#ffffff"), body=H("#fff7ee"), body_shade=H("#b9a4ee"))), (0, 2))
add("keycapDown", kd, 5, 5, 5, 7)
# slot: inset light lilac square
sl = shape(16, 16, 2, 0, 0, dict(outline=H("#b9a4ee"), body=H("#f3ecff")))
px = sl.load()
for x in range(2, 14):
    px[x, 1] = H("#d9ccf6")  # inner top shadow
add("slot", sl, 4, 4, 4, 4)
# tabs
add("tab", shape(20, 14, 3, 1, 1, dict(outline=INK, rim_light=H("#e6dcff"), rim=H("#b9a4ee"), rim_dark=H("#8a72c8"), inner=None,
                                         body_light=H("#d9ccf6"), body=H("#c9b8f2"), body_shade=H("#b9a4ee"))), 6, 5, 6, 5)
add("tabOn", shape(20, 14, 3, 1, 0, dict(outline=INK, rim_light=H("#e6dcff"), rim=H("#b9a4ee"), rim_dark=H("#b9a4ee"), inner=None,
                                           body_light=H("#ffffff"), body=H("#fff7ee"), body_shade=H("#fff7ee"))), 6, 5, 6, 5)


def ribbon(main, light, dark, tail):
    """A title ribbon: a band in front of two folded tails with a forked cut (9-slice: the middle stretches)."""
    w, h = 44, 17
    im = Image.new("RGBA", (w, h), CLEAR)
    px = im.load()
    for x in range(w):  # tails first (behind the band)
        ex = min(x, w - 1 - x)
        if ex > 8:
            continue
        for y in range(5, 16):
            mid = 10
            if ex <= 2 and abs(y - mid) <= 2 - ex:  # forked cut
                continue
            edge = y in (5, 15) or ex == 0 or (ex <= 3 and abs(y - mid) == 3 - ex)
            px[x, y] = INK if edge else H(tail)
    for x in range(5, w - 5):  # the band
        for y in range(1, 13):
            edge = y in (1, 12) or x in (5, w - 6)
            px[x, y] = INK if edge else (H(light) if y == 2 else (H(dark) if y >= 10 else H(main)))
    for x in (6, 7, w - 8, w - 7):  # the fold shadow where band meets tail
        px[x, 13] = INK
    return im


add("ribbonPink", ribbon("#ff9db0", "#ffd6de", "#c25a7a", "#c25a7a"), 10, 4, 10, 5)
add("ribbonLilac", ribbon("#b9a4ee", "#e6dcff", "#6c5aa8", "#6c5aa8"), 10, 4, 10, 5)


def sprite(rows, pal):
    h, w = len(rows), max(len(r) for r in rows)
    im = Image.new("RGBA", (w, h), CLEAR)
    px = im.load()
    for y, r in enumerate(rows):
        for x, ch in enumerate(r):
            if ch in pal:
                px[x, y] = pal[ch]
    return im


FLOWER_PAL = {"o": INK, "p": H("#ff9db0"), "P": H("#ffd6de"), "d": H("#c25a7a"), "y": H("#ffd970"), "l": H("#b9a4ee"), "L": H("#e6dcff"),
              "v": H("#8a72c8"), "g": H("#6ec7a6"), "G": H("#2f7f73"), "w": H("#ffffff")}
SPRITES = {
    "wisteria": sprite([
        "......oooo......",
        "....oogggGoo....",
        "...ogGgoooGgo...",
        "..oLLooLlooLLo..",
        "..olllollloLllo.",
        ".oLLlovLLlovllo.",
        ".olllooollooovo.",
        "..oLllollloo....",
        "..olllovLLlo....",
        "...ovlooLllo....",
        "....oo.olllo....",
        "........olvo....",
        ".........oo.....",
    ], FLOWER_PAL),
    "sakura": sprite([
        "...oo..oo...",
        "..oPpooPpo..",
        "..opPppPpo..",
        ".oopppyppoo.",
        "oPppyyyyppPo",
        "oppppyyppppo",
        ".ooppPPppoo.",
        "..oppoopppo.",
        "..oPpooodpo.",
        "...oo...oo..",
    ], FLOWER_PAL),
    "sparkle": sprite([
        "...o...",
        "..oyo..",
        ".oowoo.",
        "oywwwyo",
        ".oowoo.",
        "..oyo..",
        "...o...",
    ], FLOWER_PAL),
    "pointer": sprite([
        "oooooooooo",
        "oyyyyyyyyo",
        ".oddddddo.",
        "..oddddo..",
        "...oddo...",
        "....oo....",
    ], {"o": INK, "y": H("#fff6d6"), "d": H("#ffd970")}),
    "close": sprite([
        ".oooooooooo.",
        "oyyyyyyyyyyo",
        "oyoyyyyyyoyo",
        "oyooyyyyooyo",
        "oyyooyyooyyo",
        "oyyyooooyyyo",
        "oyyyyooyyyyo",
        "oyyyooooyyyo",
        "oyyooyyooyyo",
        "oddddddddddo",
        "oddddddddddo",
        ".oooooooooo.",
    ], {"o": INK, "y": H("#ffd970"), "d": H("#d9962e")}),
}

if __name__ == "__main__":
    for name, im in SKINS.items():
        up(im).save(os.path.join(OUT, name + ".png"))
    for name, im in SPRITES.items():
        up(im).save(os.path.join(OUT, "spr_" + name + ".png"))
    json.dump(SLICE, open(os.path.join(OUT, "slices.json"), "w"), indent=1)
    items = list(SKINS.items()) + [("spr_" + k, v) for k, v in SPRITES.items()]
    sheet = Image.new("RGBA", (sum(i.width + 4 for _, i in items) + 4, 32), H("#2a1f40"))
    x = 4
    for _, im in items:
        sheet.alpha_composite(im, (x, 4))
        x += im.width + 4
    sheet.resize((sheet.width * 4, sheet.height * 4), Image.NEAREST).save(os.path.join(OUT, "_sheet.png"))
    print(len(items), "kit images ->", OUT)
