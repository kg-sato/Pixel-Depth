"""Pixel Depth soft pastel UI kit v3 (2026-11-09, the user: "the pixel art style doesn't really fit the HUD; research high quality
pastel coloured UI and generate or use a set of them; icons are fine for now, change the backgrounds and make sure overlap is fine").
Look (casual soft GUI kits: Unco Games "Casual Soft GUI" / "Casual GUI", Beavy "UI Kit Pro Kawaii", plus the FLUX sheet
art/ui_soft/refs/pdui3_kit_*.png): smooth rounded shapes, a thick outline in a deeper shade of each element's own colour (never
black), a soft top-to-bottom gradient, a glossy highlight band on the upper half, a darker 3D lip along the bottom, cream panels
framed in lilac, a rounded friendly font (Fredoka One in game).
Every image is drawn at 4x and scaled down (anti-aliased). Sizes are 4 image pixels per design point at 720 px screen height:
the client sets SliceScale = 0.25 * screenHeight / 720. SLICE (image pixels) is written to slices.json.
Usage: python pd_ui_soft.py <out_dir>"""
import json, os, sys
from PIL import Image, ImageDraw, ImageFilter

OUT = sys.argv[1] if len(sys.argv) > 1 else "ui_soft"
os.makedirs(OUT, exist_ok=True)
SS = 4  # supersampling


def H(h, a=255):
    return tuple(int(h[i:i + 2], 16) for i in (1, 3, 5)) + (a,)


def mix(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t + 0.5) for i in range(4))


def rr_mask(size, box, r):
    m = Image.new("L", size, 0)
    ImageDraw.Draw(m).rounded_rectangle(box, r, fill=255)
    return m


def vgrad(size, top, bot):
    g = Image.new("RGBA", size)
    d = ImageDraw.Draw(g)
    for y in range(size[1]):
        d.line([(0, y), (size[0], y)], fill=mix(top, bot, y / max(size[1] - 1, 1)))
    return g


def layer(im, box, r, fill_top, fill_bot=None):
    m = rr_mask(im.size, box, r)
    im.alpha_composite(Image.composite(vgrad(im.size, fill_top, fill_bot or fill_top), Image.new("RGBA", im.size, (0, 0, 0, 0)), m))


def shape(w, h, r, ol, lip, outline, lip_c, top, bot, gloss=0.42, inner=None, frame=0, frame_top=None, frame_bot=None, shadow=True):
    """A rounded element: drop shadow, outline, bottom lip, optional frame band, face gradient, gloss band, optional inner line."""
    W, Hh, R, O, L, F = w * SS, h * SS, r * SS, ol * SS, lip * SS, frame * SS
    pad = 0
    im = Image.new("RGBA", (W, Hh), (0, 0, 0, 0))
    if shadow:  # a soft plum shadow just under the lip
        sh = Image.new("RGBA", (W, Hh), (0, 0, 0, 0))
        ImageDraw.Draw(sh).rounded_rectangle((O, O * 2, W - 1 - O, Hh - 1), R, fill=(30, 18, 50, 120))
        im.alpha_composite(sh.filter(ImageFilter.GaussianBlur(SS * 3)))
    body_bottom = Hh - 1 - (SS * 2 if shadow else 0)
    layer(im, (pad, pad, W - 1 - pad, body_bottom), R, outline)  # outline
    layer(im, (O, O, W - 1 - O, body_bottom - O), max(R - O, 1), lip_c)  # lip shows below the face
    face = (O, O, W - 1 - O, body_bottom - O - L)
    if frame:
        layer(im, face, max(R - O, 1), frame_top, frame_bot)
        face = (O + F, O + F, W - 1 - O - F, body_bottom - O - L - F)
        layer(im, (face[0] - SS, face[1] - SS, face[2] + SS, face[3] + SS), max(R - O - F + SS, 1), mix(frame_bot, outline, 0.35))  # inner edge
    fr = max(R - O - F, 1)
    layer(im, face, fr, top, bot)
    if inner:  # a thin light line just inside the face top
        hl = Image.new("RGBA", im.size, (0, 0, 0, 0))
        ImageDraw.Draw(hl).rounded_rectangle(face, fr, outline=inner, width=SS * 2)
        cut = rr_mask(im.size, (face[0], face[1] + (face[3] - face[1]) // 2, face[2], face[3]), fr)  # keep only the upper half
        hl.putalpha(Image.composite(Image.new("L", im.size, 0), hl.getchannel("A"), cut))
        im.alpha_composite(hl)
    if gloss:  # a glossy band on the upper part of the face
        gh = int((face[3] - face[1]) * gloss)
        gb = (face[0] + SS * 3, face[1] + SS * 2, face[2] - SS * 3, face[1] + SS * 2 + gh)
        g = Image.new("RGBA", im.size, (255, 255, 255, 0))
        ImageDraw.Draw(g).rounded_rectangle(gb, max(min(fr - SS * 2, gh // 2), 1), fill=(255, 255, 255, 85))
        im.alpha_composite(g)
    return im.resize((w, h), Image.LANCZOS)


SLICES, SIZES = {}, {}


def save(name, im, slice_box):
    im.save(os.path.join(OUT, name + ".png"))
    SLICES[name] = list(slice_box)
    SIZES[name] = list(im.size)


INK = H("#3e2a56")
P = {  # name: outline, lip, face top, face bottom
    "mint": (H("#3f9c7c"), H("#5bbf98"), H("#a8f0d0"), H("#7fdcb4")),
    "pink": (H("#c25674"), H("#e07893"), H("#ffc4d1"), H("#ff9db0")),
    "lilac": (H("#6f58b0"), H("#8f78d0"), H("#d6c9fb"), H("#b9a4ee")),
    "butter": (H("#c48a2e"), H("#e5b14e"), H("#ffeaa6"), H("#ffd970")),
    "sky": (H("#4a83c4"), H("#68a3e0"), H("#c3e2ff"), H("#8ec8ff")),
    "off": (H("#7c6f93"), H("#9a8fb0"), H("#e0dbe9"), H("#c6bfd3")),
}
# buttons 160 x 100: radius 34, outline 6, lip 10 (+ 8 shadow)
for n, (o, l, t, b) in P.items():  # softer outline (toward the lip colour) and a white rim along the top, like the FLUX refs
    save(n, shape(160, 100, 34, 5, 10, mix(o, l, 0.3), l, t, b, gloss=0.42, inner=H("#ffffff", 150)), (42, 40, 118, 52))
# HUD pill: lilac-white, rounded ends
save("pill", shape(176, 76, 30, 5, 7, H("#7d64b8"), H("#c9b9f2"), H("#ffffff"), H("#efe8ff"), gloss=0.0, inner=H("#ffffff")), (40, 31, 136, 37))
# puffy tone-on-tone HUD pills (kit round 4, 2026-11-08): face, lip and outline all in one hue, a taller lip and a gloss band
for n, (o_, l_, t_, b_) in {"pillButter": ("#c48a2e", "#e9b95a", "#fff6d6", "#ffe39a"), "pillLilac": ("#6f58b0", "#a690e2", "#f5f0ff", "#ddd0fb"),
                            "pillMint": ("#3f9c7c", "#6fcca6", "#effff8", "#c4f1dc"), "pillPink": ("#c25674", "#e98aa2", "#fff1f4", "#ffd0db")}.items():
    save(n, shape(176, 80, 32, 5, 9, H(o_), H(l_), H(t_), H(b_), gloss=0.36, inner=H("#ffffff")), (40, 33, 136, 41))
# popup panel: cream face inside a lilac frame band
save("panel", shape(200, 200, 46, 6, 10, H("#6f58b0"), H("#8f78d0"), H("#fffaf3"), H("#fbefe3"), gloss=0.0, frame=12, frame_top=H("#d2c4fb"), frame_bot=H("#b29cec"), inner=H("#ffffff", 200)), (64, 64, 136, 126))
# card: cream face in a butter frame (tooltips, banners)
save("card", shape(176, 136, 34, 5, 8, H("#c48a2e"), H("#e5b14e"), H("#fffaf0"), H("#fff1d6"), gloss=0.0, frame=9, frame_top=H("#ffeaa6"), frame_bot=H("#ffd970")), (50, 50, 126, 78))
# dark: deep plum panel for hints and counters
save("dark", shape(112, 112, 28, 5, 6, H("#1e1430"), H("#2a1d40"), H("#56437a"), H("#3e2d5c"), gloss=0.0, inner=H("#7a64a3")), (36, 36, 76, 64))
# keycaps
save("keycap", shape(72, 76, 18, 4, 9, H("#6f58b0"), H("#c9b9f2"), H("#ffffff"), H("#f1ebff"), gloss=0.0, inner=H("#ffffff")), (24, 24, 48, 44))
save("keycapDown", shape(72, 76, 18, 4, 3, H("#6f58b0"), H("#c9b9f2"), H("#ece4ff"), H("#e0d6fb"), gloss=0.0), (24, 24, 48, 50))
# slot: a sunken lilac well for icons
save("slot", shape(104, 104, 26, 4, 0, H("#8f78d0"), H("#8f78d0"), H("#cbbdf3"), H("#ded3fb"), gloss=0.0, shadow=False), (32, 32, 72, 72))
# tabs
save("tab", shape(136, 84, 28, 5, 8, H("#6f58b0"), H("#8f78d0"), H("#cfc3f2"), H("#b9a4ee"), gloss=0.3), (38, 36, 98, 46))
save("tabOn", shape(136, 84, 28, 5, 8, H("#c48a2e"), H("#e5b14e"), H("#fffaf0"), H("#ffeaa6"), gloss=0.3), (38, 36, 98, 46))


def ribbon(top, bot, outline, lip):  # a title banner with folded tails, 352 x 104
    w, h = 352, 104
    W, Hh = w * SS, h * SS
    im = Image.new("RGBA", (W, Hh), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    tail = [(0, 22 * SS), (52 * SS, 22 * SS), (52 * SS, 92 * SS), (0, 92 * SS), (18 * SS, 57 * SS)]  # left tail with a V notch
    for poly in (tail, [(W - x, y) for x, y in tail]):
        d.polygon(poly, fill=outline)
        cx, cy = sum(p[0] for p in poly) / 5, sum(p[1] for p in poly) / 5
        d.polygon([(cx + (x - cx) * 0.78, cy + (y - cy) * 0.8) for x, y in poly], fill=lip)  # the folded-back colour inside
    body = shape(w - 76, 88, 26, 6, 9, outline, lip, top, bot, gloss=0.4).resize(((w - 76) * SS, 88 * SS), Image.LANCZOS)
    im.alpha_composite(body, (38 * SS, 0))
    return im.resize((w, h), Image.LANCZOS)


save("ribbonPink", ribbon(H("#ffc4d1"), H("#ff9db0"), H("#c25674"), H("#e07893")), (100, 30, 252, 50))
save("ribbonLilac", ribbon(H("#d6c9fb"), H("#b9a4ee"), H("#6f58b0"), H("#8f78d0")), (100, 30, 252, 50))


# sprites (no 9-slice): close button, tooltip pointer, sparkle
def sprite_close():
    im = shape(96, 100, 46, 6, 9, H("#c25674"), H("#e07893"), H("#ffc4d1"), H("#ff9db0"), gloss=0.4)
    big = im.resize((96 * SS, 100 * SS), Image.LANCZOS)
    d = ImageDraw.Draw(big)
    c, k = (48 * SS, 44 * SS), 15 * SS
    for col, wd in ((H("#c25674"), 17), (H("#ffffff"), 10)):  # both outlines first, then both white strokes
        for a, b in (((-1, -1), (1, 1)), ((-1, 1), (1, -1))):
            d.line([(c[0] + a[0] * k, c[1] + a[1] * k), (c[0] + b[0] * k, c[1] + b[1] * k)], fill=col, width=wd * SS)
    return big.resize((96, 100), Image.LANCZOS)


def sprite_pointer():  # the butter tooltip's tail, pointing down
    W, Hh = 80 * SS, 48 * SS
    im = Image.new("RGBA", (W, Hh), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.polygon([(0, 0), (W, 0), (W / 2 + 7 * SS, Hh - 9 * SS), (W / 2 - 7 * SS, Hh - 9 * SS)], fill=H("#c48a2e"))
    d.ellipse((W / 2 - 9 * SS, Hh - 19 * SS, W / 2 + 9 * SS, Hh - 1), fill=H("#c48a2e"))  # a round tip, not a sharp cone
    d.polygon([(9 * SS, 0), (W - 9 * SS, 0), (W / 2 + 4 * SS, Hh - 15 * SS), (W / 2 - 4 * SS, Hh - 15 * SS)], fill=H("#ffe39a"))
    d.ellipse((W / 2 - 5 * SS, Hh - 21 * SS, W / 2 + 5 * SS, Hh - 9 * SS), fill=H("#ffe39a"))
    return im.resize((80, 48), Image.LANCZOS)


def sprite_star(fill_top, fill_bot, outline):  # a plump five-point star with a gloss, for grades and rewards
    import math
    W = 96 * SS
    im = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    c = (W / 2, W / 2 + 4 * SS)

    def pts(r_out, r_in):
        p = []
        for i in range(10):
            a = -math.pi / 2 + i * math.pi / 5
            r = r_out if i % 2 == 0 else r_in
            p.append((c[0] + math.cos(a) * r, c[1] + math.sin(a) * r))
        return p
    m = Image.new("L", (W, W), 0)
    ImageDraw.Draw(m).polygon(pts(44 * SS, 22 * SS), fill=255)
    m = m.filter(ImageFilter.GaussianBlur(SS * 3)).point(lambda v: 255 if v > 110 else 0)  # round the points
    im.paste(outline, (0, 0), m)
    m2 = Image.new("L", (W, W), 0)
    ImageDraw.Draw(m2).polygon(pts(36 * SS, 18 * SS), fill=255)
    m2 = m2.filter(ImageFilter.GaussianBlur(SS * 3)).point(lambda v: 255 if v > 110 else 0)
    im.paste(vgrad((W, W), fill_top, fill_bot), (0, 0), m2)
    g = Image.new("L", (W, W), 0)
    ImageDraw.Draw(g).ellipse((c[0] - 16 * SS, c[1] - 24 * SS, c[0] + 8 * SS, c[1] - 6 * SS), fill=110)
    im.paste((255, 255, 255, 255), (0, 0), Image.composite(g, Image.new("L", (W, W), 0), m2))
    return im.resize((96, 96), Image.LANCZOS)


def sprite_sparkle():
    W = 64 * SS
    im = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    c = W / 2
    for r, col in ((30, H("#c48a2e")), (24, H("#fff4c8"))):
        k = r * SS
        q = k * 0.22
        d.polygon([(c, c - k), (c + q, c - q), (c + k, c), (c + q, c + q), (c, c + k), (c - q, c + q), (c - k, c), (c - q, c - q)], fill=col)
    return im.resize((64, 64), Image.LANCZOS)


SPRITES = (("spr_close", sprite_close()), ("spr_pointer", sprite_pointer()), ("spr_sparkle", sprite_sparkle()),
           ("spr_star", sprite_star(H("#fff1b8"), H("#ffc94a"), H("#c48a2e"))), ("spr_starOff", sprite_star(H("#ddd6ea"), H("#b9aed0"), H("#7c6f93"))))
for n, im in SPRITES:
    im.save(os.path.join(OUT, n + ".png"))
    SIZES[n] = list(im.size)

json.dump({"slices": SLICES, "sizes": SIZES}, open(os.path.join(OUT, "slices.json"), "w"), indent=1)

# a contact sheet on the cave night background for the board and grading
names = list(SLICES) + [n for n, _ in SPRITES]
sheet = Image.new("RGBA", (1400, 560), H("#2a1f40"))
x, y, rowh = 20, 20, 0
for n in names:
    im = Image.open(os.path.join(OUT, n + ".png"))
    if x + im.width > 1380:
        x, y, rowh = 20, y + rowh + 20, 0
    sheet.alpha_composite(im, (x, y))
    x += im.width + 20
    rowh = max(rowh, im.height)
sheet.save(os.path.join(OUT, "_sheet.png"))
print("wrote", len(names), "images to", OUT)
