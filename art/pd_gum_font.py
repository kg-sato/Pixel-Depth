"""Gumdrop, Pixel Depth's own small-text font (2026-11-18, the owner: "remake or alter the font for the game so it's original,
matches the jelly text idea, yet stays usable"). Roblox has no official custom-font upload, so like the jelly headline letters
this is an image atlas, but drawn for reading at 14-40 px where the 3D jelly letters turn to mush (JellyText: under 17 px).
Every glyph is our own: round-capped monoline strokes on a unit grid (cap height 10, x-height 7); no font file is traced.
Jelly look in 2D: a dark rim, a body lit from the top (bright top, deeper bottom), a lit bevel along the top-left edges.
Two layers per glyph: BODY (rim + shaded body, tinted by the game with ImageColor3) and GLOSS (white bevel light, never
tinted, so coloured text keeps its shine).
    python art/pd_gum_font.py            -> art/gum_font/gum_atlas.png, gum_preview.png, src/GumGlyphs.luau
"""
import math, pathlib
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

HERE = pathlib.Path(__file__).resolve().parent
OUT = HERE / "gum_font"
OUT.mkdir(exist_ok=True)
S = 2.85          # stroke width in units (chunky: jelly reads as weight)
RIM = 0.9         # dark rim around the stroke, units
CELL = 96         # atlas cell height and width, px
SS = 4            # supersampling
EM_TOP, EM_BOT = 12.2, -4.6   # the cell spans these units vertically (cap 10, descender -3.4, plus stroke and rim)
U = CELL / (EM_TOP - EM_BOT)  # px per unit


def seg(x1, y1, x2, y2): return ("s", x1, y1, x2, y2)
def arc(cx, cy, rx, ry, a0, a1): return ("a", cx, cy, rx, ry, a0, a1)
def ell(cx, cy, rx, ry): return ("a", cx, cy, rx, ry, 0, 360)
def dot(x, y, r=1.0): return ("d", x, y, r)
def pl(*p): return [seg(*p[i], *p[i + 1]) for i in range(len(p) - 1)]


G = {  # char: (width in units, [strokes]); y up, baseline 0
    "A": (8, [seg(0, 0, 4, 10), seg(4, 10, 8, 0), seg(1.6, 3.6, 6.4, 3.6)]),
    "B": (7, [seg(0, 0, 0, 10), seg(0, 10, 3.9, 10), arc(3.9, 7.75, 2.25, 2.25, -90, 90), seg(0, 5.5, 4.2, 5.5), arc(4.2, 2.75, 2.75, 2.75, -90, 90), seg(0, 0, 4.2, 0)]),
    "C": (8.4, [arc(4.6, 5, 4.6, 5, 42, 318)]),
    "D": (8, [seg(0, 0, 0, 10), seg(0, 10, 3, 10), arc(3, 5, 5, 5, -90, 90), seg(0, 0, 3, 0)]),
    "E": (6.4, [seg(0, 0, 0, 10), seg(0, 10, 6.4, 10), seg(0, 5.2, 5.4, 5.2), seg(0, 0, 6.4, 0)]),
    "F": (6.2, [seg(0, 0, 0, 10), seg(0, 10, 6.2, 10), seg(0, 5.2, 5.2, 5.2)]),
    "G": (9.2, [arc(4.6, 5, 4.6, 5, 42, 360), seg(9.2, 5, 5.6, 5)]),
    "H": (7.6, [seg(0, 0, 0, 10), seg(7.6, 0, 7.6, 10), seg(0, 5.2, 7.6, 5.2)]),
    "I": (0, [seg(0, 0, 0, 10)]),
    "J": (5.4, [seg(5.4, 10, 5.4, 3), arc(2.7, 3, 2.7, 3, 180, 360)]),
    "K": (7, [seg(0, 0, 0, 10), seg(6.6, 10, 0.4, 3.8), seg(2.6, 5.6, 7, 0)]),
    "L": (6, [seg(0, 0, 0, 10), seg(0, 0, 6, 0)]),
    "M": (9.4, [seg(0, 0, 0, 10), seg(0, 10, 4.7, 3), seg(4.7, 3, 9.4, 10), seg(9.4, 10, 9.4, 0)]),
    "N": (7.6, [seg(0, 0, 0, 10), seg(0, 10, 7.6, 0), seg(7.6, 0, 7.6, 10)]),
    "O": (10, [ell(5, 5, 5, 5)]),
    "P": (6.8, [seg(0, 0, 0, 10), seg(0, 10, 4, 10), arc(4, 7.4, 2.6, 2.6, -90, 90), seg(0, 4.8, 4, 4.8)]),
    "Q": (10, [ell(5, 5, 5, 5), seg(6.6, 2.6, 10, -0.6)]),
    "R": (7.2, [seg(0, 0, 0, 10), seg(0, 10, 4, 10), arc(4, 7.4, 2.6, 2.6, -90, 90), seg(0, 4.8, 4, 4.8), seg(3.6, 4.8, 7.2, 0)]),
    "S": (7.4, [arc(3.7, 7.5, 3.5, 2.5, 25, 270), arc(3.7, 2.5, 3.7, 2.5, 205, 450)]),
    "T": (8, [seg(0, 10, 8, 10), seg(4, 10, 4, 0)]),
    "U": (7.6, [seg(0, 10, 0, 3.6), arc(3.8, 3.6, 3.8, 3.6, 180, 360), seg(7.6, 3.6, 7.6, 10)]),
    "V": (8.2, pl((0, 10), (4.1, 0), (8.2, 10))),
    "W": (11.4, pl((0, 10), (2.8, 0), (5.7, 7.4), (8.6, 0), (11.4, 10))),
    "X": (8, [seg(0, 10, 8, 0), seg(0, 0, 8, 10)]),
    "Y": (8, [seg(0, 10, 4, 5), seg(8, 10, 4, 5), seg(4, 5, 4, 0)]),
    "Z": (7, pl((0, 10), (7, 10), (0, 0), (7, 0))),
    "0": (7, [ell(3.5, 5, 3.5, 5)]),
    "1": (4, [seg(3, 0, 3, 10), seg(3, 10, 0.4, 7.8)]),
    "2": (7, [arc(3.5, 6.7, 3.4, 3.3, -38, 165), seg(6.18, 4.67, 0, 0), seg(0, 0, 7, 0)]),
    "3": (7, [arc(3.3, 7.6, 3.1, 2.4, -90, 155), arc(3.3, 2.75, 3.6, 2.75, -155, 90)]),
    "4": (7.4, [seg(5.2, 0, 5.2, 10), seg(5.2, 10, 0, 3), seg(0, 3, 7.4, 3)]),
    "5": (7, [seg(6.6, 10, 1.1, 10), seg(1.1, 10, 0.7, 5.7), arc(3.4, 3.3, 3.6, 3.3, -150, 133)]),
    "6": (7, [ell(3.5, 3.25, 3.5, 3.25), arc(4.8, 3.35, 4.8, 6.65, 78, 180)]),
    "7": (7, [seg(0, 10, 7, 10), seg(7, 10, 2.6, 0)]),
    "8": (7, [ell(3.5, 7.6, 2.9, 2.4), ell(3.5, 2.7, 3.5, 2.7)]),
    "9": (7, [ell(3.5, 6.75, 3.5, 3.25), arc(2.2, 6.65, 4.8, 6.65, 258, 360)]),
    "a": (6.4, [ell(3.1, 3.5, 3.1, 3.5), seg(6.4, 0, 6.4, 7)]),
    "b": (6.6, [seg(0, 0, 0, 10.4), ell(3.3, 3.5, 3.3, 3.5)]),
    "c": (6.2, [arc(3.4, 3.5, 3.4, 3.5, 45, 315)]),
    "d": (6.6, [ell(3.3, 3.5, 3.3, 3.5), seg(6.6, 0, 6.6, 10.4)]),
    "e": (6.8, [seg(0.2, 3.7, 6.8, 3.7), arc(3.4, 3.5, 3.4, 3.5, 3, 318)]),
    "f": (4.8, [seg(1.8, 0, 1.8, 8.2), arc(3.8, 8.2, 2, 2, 90, 180), seg(3.8, 10.2, 4.8, 10.1), seg(0, 6.8, 4.4, 6.8)]),
    "g": (6.4, [ell(3.1, 3.7, 3.1, 3.3), seg(6.4, 7, 6.4, -0.6), arc(3.2, -0.6, 3.2, 2.4, 190, 360)]),
    "h": (6.4, [seg(0, 0, 0, 10.4), arc(3.2, 4.2, 3.2, 2.8, 0, 180), seg(6.4, 4.2, 6.4, 0)]),
    "i": (0, [seg(0, 0, 0, 6.8), dot(0, 9.6)]),
    "j": (2.6, [seg(2.6, 6.8, 2.6, -1), arc(0.6, -1, 2, 2, 270, 360), dot(2.6, 9.6)]),
    "k": (6, [seg(0, 0, 0, 10.4), seg(5.6, 7, 0.4, 2.4), seg(2.4, 4.2, 6, 0)]),
    "l": (0, [seg(0, 0, 0, 10.4)]),
    "m": (10, [seg(0, 0, 0, 7), arc(2.5, 4.6, 2.5, 2.4, 0, 180), seg(5, 4.6, 5, 0), arc(7.5, 4.6, 2.5, 2.4, 0, 180), seg(10, 4.6, 10, 0)]),
    "n": (6.4, [seg(0, 0, 0, 7), arc(3.2, 4.2, 3.2, 2.8, 0, 180), seg(6.4, 4.2, 6.4, 0)]),
    "o": (7, [ell(3.5, 3.5, 3.5, 3.5)]),
    "p": (6.6, [seg(0, 7, 0, -3.4), ell(3.3, 3.5, 3.3, 3.5)]),
    "q": (6.6, [ell(3.3, 3.5, 3.3, 3.5), seg(6.6, 7, 6.6, -3.4)]),
    "r": (4.6, [seg(0, 0, 0, 7), arc(3.6, 3.8, 3.6, 3.2, 90, 180), seg(3.6, 7, 4.6, 6.7)]),
    "s": (5.8, [arc(2.9, 5.25, 2.7, 1.75, 25, 270), arc(2.9, 1.75, 2.9, 1.75, 205, 450)]),
    "t": (5, [seg(1.8, 9.4, 1.8, 2.2), arc(3.9, 2.2, 2.1, 2.2, 180, 270), seg(3.9, 0, 5, 0.3), seg(0, 6.8, 4.6, 6.8)]),
    "u": (6.4, [seg(0, 7, 0, 3), arc(3.2, 3, 3.2, 3, 180, 360), seg(6.4, 7, 6.4, 0)]),
    "v": (6.6, pl((0, 7), (3.3, 0), (6.6, 7))),
    "w": (9.6, pl((0, 7), (2.4, 0), (4.8, 5.2), (7.2, 0), (9.6, 7))),
    "x": (6.2, [seg(0, 7, 6.2, 0), seg(0, 0, 6.2, 7)]),
    "y": (6.6, [seg(0, 7, 3.3, 0.2), seg(6.6, 7, 2.2, -3.4)]),
    "z": (6, pl((0, 7), (6, 7), (0, 0), (6, 0))),
    ".": (0, [dot(0, 0.9)]),
    ",": (0.6, [dot(0.4, 0.9), seg(0.6, 0.6, -0.4, -1.8)]),
    "!": (0, [seg(0, 3.8, 0, 10), dot(0, 0.9)]),
    "?": (6, [arc(3, 7.3, 3, 2.7, -90, 168), seg(3, 4.6, 3, 3.4), dot(3, 0.9)]),
    ":": (0, [dot(0, 0.9), dot(0, 6.2)]),
    ";": (0.6, [dot(0.4, 6.2), dot(0.4, 0.9), seg(0.6, 0.6, -0.4, -1.8)]),
    "'": (0, [seg(0, 10, 0, 7.4)]),
    '"': (2.6, [seg(0, 10, 0, 7.4), seg(2.6, 10, 2.6, 7.4)]),
    "-": (4, [seg(0, 4.2, 4, 4.2)]),
    "+": (6, [seg(0, 4.4, 6, 4.4), seg(3, 1.4, 3, 7.4)]),
    "=": (6, [seg(0, 2.9, 6, 2.9), seg(0, 6, 6, 6)]),
    "/": (5, [seg(0, -1, 5, 10.6)]),
    "(": (3.2, [arc(4.4, 4.6, 4.4, 6.6, 118, 242)]),
    ")": (3.2, [arc(-1.2, 4.6, 4.4, 6.6, -62, 62)]),
    "%": (8.6, [ell(1.8, 8, 1.8, 2), ell(6.8, 2, 1.8, 2), seg(7.6, 10, 1, 0)]),
    "<": (5.4, pl((5.4, 8), (0, 4.4), (5.4, 0.8))),
    ">": (5.4, pl((0, 8), (5.4, 4.4), (0, 0.8))),
    "_": (6, [seg(0, -1.6, 6, -1.6)]),
    "$": (7.4, [arc(3.7, 7.5, 3.5, 2.5, 25, 270), arc(3.7, 2.5, 3.7, 2.5, 205, 450), seg(3.7, -1.4, 3.7, 11.4)]),
    "×": (5.6, [seg(0, 1.6, 5.6, 7.2), seg(0, 7.2, 5.6, 1.6)]),  # the multiply sign
    "•": (1.2, [dot(0.6, 4.4, 1.5)]),  # a bullet
}
SPACE = 4.2  # units
BEAR = 0.12  # extra gap between glyphs, units (each side)
PAD = S / 2 + RIM  # the stroke and rim stick out this far past the skeleton, units


def strokes_mask(strokes, w, inflate):
    """A supersampled mask of the strokes widened by `inflate` units each side, centred in a CELL x CELL cell."""
    big = Image.new("L", (CELL * SS, CELL * SS), 0)
    d = ImageDraw.Draw(big)
    k = U * SS
    x0 = (CELL / U - w) / 2

    def P(x, y): return ((x + x0) * k, (EM_TOP - y) * k)
    r = (S / 2 + inflate) * k

    def cap(q, rr): d.ellipse([q[0] - rr, q[1] - rr, q[0] + rr, q[1] + rr], fill=255)
    for st in strokes:
        if st[0] == "s":
            _, x1, y1, x2, y2 = st
            a, b = P(x1, y1), P(x2, y2)
            d.line([a, b], fill=255, width=int(round(2 * r)))
            cap(a, r); cap(b, r)
        elif st[0] == "d":
            _, x, y, rr = st
            cap(P(x, y), (S / 2 * 1.18 * rr + inflate) * k)
        else:
            _, cx, cy, rx, ry, a0, a1 = st
            n = max(16, int(abs(a1 - a0) / 2))
            pts = [P(cx + rx * math.cos(math.radians(a0 + (a1 - a0) * i / n)), cy + ry * math.sin(math.radians(a0 + (a1 - a0) * i / n))) for i in range(n + 1)]
            for q in pts: cap(q, r)  # a chain of round dabs: an even, round-joined curve
            d.line(pts, fill=255, width=int(round(2 * r)))
    return big


def down(img):
    return np.asarray(img.resize((img.width // SS, img.height // SS), Image.LANCZOS), dtype=np.float32) / 255


def shifted(img, dx, dy):
    m = Image.new("L", img.size, 0)
    m.paste(img, (dx, dy))
    return m


def render(strokes, w):
    outer = strokes_mask(strokes, w, RIM)
    body = strokes_mask(strokes, w, 0)
    b = np.asarray(body, np.float32)
    sh = int(U * SS * 0.5)  # the bevel: the body minus itself moved down-right = the lit top-left edge
    lit = Image.fromarray(np.clip(b - np.asarray(shifted(body, sh, sh), np.float32), 0, 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(SS * 0.8))
    deep = Image.fromarray(np.clip(b - np.asarray(shifted(body, -sh, -sh), np.float32), 0, 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(SS * 1.1))
    a_out, a_body = down(outer), down(body)
    a_lit, a_deep = down(lit) * a_body, down(deep) * a_body
    yy = np.linspace(0, 1, a_body.shape[0])[:, None]
    shade = (1.0 - 0.3 * np.clip((yy - 0.3) / 0.5, 0, 1)) * (1 - 0.38 * a_deep)  # bright top, deeper bottom and bottom-right edge
    rim = np.array([46, 22, 72], np.float32) / 255  # dark violet: multiplied by the tint it becomes a deep shade of the colour
    rgb = rim[None, None, :] * (1 - a_body[..., None]) + shade[..., None] * a_body[..., None]
    body_rgba = np.dstack([rgb, a_out])
    wash = np.clip((0.52 - yy) / 0.3, 0, 1) * 0.22 * a_body  # a soft white wash over the top of the letters, like light on a gum drop
    gloss = np.dstack([np.ones_like(a_lit)] * 3 + [np.clip(a_lit * 1.35 + wash, 0, 1)])
    return body_rgba, gloss


def main():
    chars = list(G.keys())
    cols = 10
    rows = math.ceil(len(chars) / cols)
    atlas = np.zeros((rows * 2 * CELL, cols * CELL, 4), np.float32)  # top rows BODY, bottom rows GLOSS
    meta = {}
    for i, ch in enumerate(chars):
        w, st = G[ch]
        b, g = render(st, w)
        r, c = divmod(i, cols)
        atlas[r * CELL:(r + 1) * CELL, c * CELL:(c + 1) * CELL] = b
        atlas[(rows + r) * CELL:(rows + r + 1) * CELL, c * CELL:(c + 1) * CELL] = g
        meta[ch] = (i, round((w + 2 * PAD + 2 * BEAR) * U / CELL, 4))
    img = Image.fromarray((np.clip(atlas, 0, 1) * 255).astype(np.uint8), "RGBA")
    img.save(OUT / "gum_atlas.png")
    # Roblox halves an image over 1024 px: the game gets the two halves as two images with the same cell layout
    img.crop((0, 0, cols * CELL, rows * CELL)).save(OUT / "gum_body.png")
    img.crop((0, rows * CELL, cols * CELL, 2 * rows * CELL)).save(OUT / "gum_gloss.png")
    lines = ["-- GumGlyphs (ReplicatedStorage.Shared.GumGlyphs): generated by art/pd_gum_font.py, do not edit by hand.",
             f"-- Gumdrop atlas: {CELL} px cells, {cols} columns, {rows} rows; two images with the same layout: BODY (tinted) and GLOSS (white). Ids in Config.GUM.",
             "-- glyphs[ch] = { cell index, advance as a share of the cell }. base = baseline from the cell top, cap = cap height, both as shares of the cell.",
             f"return {{ cell = {CELL}, cols = {cols}, rows = {rows}, space = {round(SPACE * U / CELL, 4)}, base = {round(EM_TOP / (EM_TOP - EM_BOT), 4)}, cap = {round(10 / (EM_TOP - EM_BOT), 4)}, glyphs = {{"]
    for ch, (i, adv) in meta.items():
        key = '["\\""]' if ch == '"' else f'["{ch}"]'
        lines.append(f"\t{key} = {{ {i}, {adv} }},")
    lines.append("} }")
    (HERE.parent / "src" / "GumGlyphs.luau").write_text("\n".join(lines) + "\n", encoding="utf-8")
    preview(img, meta, cols, rows)
    print("glyphs", len(chars), "atlas", img.size)


def preview(img, meta, cols, rows, name="gum_preview.png"):
    """Text set at several sizes on the game's dark glass, in white, gold, pink, mint and lilac, to judge readability."""
    lines = [("PIXEL DEPTH  0123456789", (255, 255, 255)), ("Walk to the minecart and ride down into the mine!", (255, 255, 255)),
             ("SPORE STORM IN 03:47   ×12   +250   99%", (255, 205, 80)), ("Daily relic chest: OPEN (F)  Quests  Pets  Shop", (255, 140, 200)),
             ("The quick brown fox jumps over the lazy dog?", (130, 240, 190)), ("ABCDEFGHIJKLMNOPQRSTUVWXYZ abcdefghijklmnopqrstuvwxyz", (190, 170, 255))]
    sizes = [14, 18, 24, 36, 56]
    W, H = 1500, 40 + sum(int(s * 1.3) * len(lines) + 16 for s in sizes)
    can = Image.new("RGBA", (W, H), (30, 20, 46, 255))
    y = 20
    for s in sizes:
        cs = max(4, round(s / 0.625 * 0.7))  # the cell size that makes the cap height about 0.7 of the text size, like Fredoka
        for text, col in lines:
            x = 20
            for ch in text:
                if ch not in meta: x += round(SPACE * U / CELL * cs); continue
                i, adv = meta[ch]
                r, c = divmod(i, cols)
                b = img.crop((c * CELL, r * CELL, (c + 1) * CELL, (r + 1) * CELL)).resize((cs, cs), Image.LANCZOS)
                g = img.crop((c * CELL, (rows + r) * CELL, (c + 1) * CELL, (rows + r + 1) * CELL)).resize((cs, cs), Image.LANCZOS)
                bt = np.asarray(b, np.float32).copy(); bt[..., :3] *= np.array(col, np.float32) / 255
                b = Image.fromarray(np.clip(bt, 0, 255).astype(np.uint8), "RGBA")
                ox = x + round(cs * adv / 2) - cs // 2
                if ox >= 0 and ox + cs < W:
                    can.alpha_composite(b, (ox, y)); can.alpha_composite(g, (ox, y))
                x += round(cs * adv)
            y += int(s * 1.3)
        y += 16
    can.convert("RGB").save(OUT / name)


if __name__ == "__main__":
    main()
