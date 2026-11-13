"""Pixel Depth cut-glass UI kit (2026-11-12, directive v8: back to frosted and cut glass after the Field Notebook kit).
Same image sizes and 9-slice centres as the glass and notebook kits (pd_ui_glass.py, pd_ui_notebook.py), so the client only
swaps image ids. Look (refs: Instagram Dd8V7dTJzF_, DfbjiL-TBuK, DeFJqVLj_wV, Dfi90zAEuB5, notes in the vault): frosted lavender
glass with cut (chamfered) corners, an eight-facet bevel like a cut gem (bright top and top-left facets, deep bottom facets),
a crisp deep outline, a white hairline inside the bevel, one diagonal sheen. Faces stay milky so dark ink text still reads.
Extras: hex (hotbar slot), orbShell and orbLiquid (status orbs), ring (wheel and radar body), close, grid (plan tile).
Usage: python pd_ui_cutglass.py <out_dir>"""
import json, math, os, sys
from PIL import Image, ImageDraw, ImageFilter, ImageChops

OUT = sys.argv[1] if len(sys.argv) > 1 else "ui_cutglass"
os.makedirs(OUT, exist_ok=True)
SS = 4
SIZES, SLICES = {}, {}
CLEAR = (0, 0, 0, 0)


def H(h, a=255):
    return tuple(int(h[i:i + 2], 16) for i in (1, 3, 5)) + (a,)


def mix(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t + 0.5) for i in range(4))


def octa(box, c):
    x0, y0, x1, y1 = box
    return [(x0 + c, y0), (x1 - c, y0), (x1, y0 + c), (x1, y1 - c), (x1 - c, y1), (x0 + c, y1), (x0, y1 - c), (x0, y0 + c)]


def mask(size, pts):
    m = Image.new("L", size, 0)
    ImageDraw.Draw(m).polygon(pts, fill=255)
    return m


def vgrad(size, top, bot, y0, y1):
    g = Image.new("RGBA", size)
    d = ImageDraw.Draw(g)
    for y in range(size[1]):
        t = min(max((y - y0) / max(y1 - y0, 1), 0), 1)
        d.line([(0, y), (size[0], y)], fill=mix(top, bot, t))
    return g


def put(im, src, m):
    im.alpha_composite(Image.composite(src, Image.new("RGBA", im.size, CLEAR), m))


def cut(w, h, c, tint, deep, a_top=232, a_bot=214, bevel=5.0, shadow=True, inset=False, dark=False, sheen=True, face=None):
    """One cut-glass piece. c = corner cut, bevel = facet width (image pixels)."""
    W, Hh = w * SS, h * SS
    im = Image.new("RGBA", (W, Hh), CLEAR)
    pad = 3 * SS
    box = (pad, pad, W - 1 - pad, Hh - 1 - pad - (0 if inset else 2 * SS))
    C, B = c * SS, bevel * SS
    outer = octa(box, C)
    ibox = (box[0] + B, box[1] + B, box[2] - B, box[3] - B)
    inner = octa(ibox, max(C - 0.586 * B, 1.5 * SS))
    if shadow and not inset:
        sh = Image.new("RGBA", im.size, CLEAR)
        ImageDraw.Draw(sh).polygon(octa((box[0] + SS, box[1] + 4 * SS, box[2] - SS, box[3] + 2 * SS), C), fill=(24, 10, 44, 95))
        im.alpha_composite(sh.filter(ImageFilter.GaussianBlur(2.6 * SS)))
    body = mask(im.size, outer)
    white = H("#ffffff")
    top = mix(tint, white, 0.12 if dark else 0.62)[:3] + (a_top,)
    bot = (deep if dark else mix(tint, white, 0.25))[:3] + (a_bot,)
    put(im, vgrad(im.size, top, bot, box[1], box[3]), body)
    if face:  # a milkier reading face inside the bevel (panels and cards)
        put(im, vgrad(im.size, face[0], face[1], ibox[1], ibox[3]), mask(im.size, inner))
    # the eight facets, clockwise from the top edge
    lit, mid, low = (white, mix(tint, white, 0.45), mix(tint, deep, 0.75)) if not dark else (mix(tint, white, 0.75), mix(tint, white, 0.2), mix(deep, H("#000000"), 0.35))
    shades = [lit[:3] + (235,), mid[:3] + (190,), mix(tint, deep, 0.35)[:3] + (200,), low[:3] + (225,),
              low[:3] + (240,), mix(tint, deep, 0.55)[:3] + (215,), mid[:3] + (215,), lit[:3] + (250,)]
    if inset:
        shades = shades[4:] + shades[:4]  # a slot is cut into the surface: the light falls on the lower facets
    fl = Image.new("RGBA", im.size, CLEAR)
    fd = ImageDraw.Draw(fl)
    for i in range(8):
        j = (i + 1) % 8
        fd.polygon([outer[i], outer[j], inner[j], inner[i]], fill=shades[i])
    im.alpha_composite(fl)
    d = ImageDraw.Draw(im)
    for i in range(8):  # facet joints: fine lines from each outer corner to its inner corner
        d.line([outer[i], inner[i]], fill=white[:3] + (120 if not dark else 70,), width=max(1, int(0.5 * SS)))
    d.line(inner + [inner[0]], fill=white[:3] + (230 if not dark else 130,), width=max(1, int(0.8 * SS)))  # hairline inside the bevel
    if sheen:
        st = Image.new("L", im.size, 0)
        x0 = ibox[0] + (ibox[2] - ibox[0]) * 0.2
        ImageDraw.Draw(st).polygon([(x0, ibox[1]), (x0 + 13 * SS, ibox[1]), (x0 - 7 * SS, ibox[3]), (x0 - 20 * SS, ibox[3])], fill=58 if not dark else 30)
        st = ImageChops.multiply(st.filter(ImageFilter.GaussianBlur(1.6 * SS)), mask(im.size, inner))
        im.alpha_composite(Image.merge("RGBA", (Image.new("L", im.size, 255),) * 3 + (st,)))
    d = ImageDraw.Draw(im)
    d.line(outer + [outer[0]], fill=mix(deep, H("#000000"), 0.25)[:3] + (235,), width=int(1.3 * SS))  # crisp outline
    return im.resize((w, h), Image.LANCZOS)


def save(name, im, slice_box=None):
    im.save(os.path.join(OUT, name + ".png"))
    if slice_box: SLICES[name] = list(slice_box)
    SIZES[name] = list(im.size)


FACE = (H("#fbf9ff", 228), H("#e9e1ff", 216))
BTN = {"mint": ("#7fe6c6", "#1f8f72"), "pink": ("#ff9fbd", "#c2416f"), "lilac": ("#bfa8ff", "#6a4fc4"),
       "butter": ("#ffd66b", "#b9791c"), "sky": ("#8fd2ff", "#2f78c4"), "off": ("#cfc8dc", "#7f7592")}
for n, (t, dp) in BTN.items():
    save(n, cut(160, 100, 16, H(t), H(dp), a_top=252, a_bot=246, bevel=7), (42, 40, 118, 52))  # buttons are nearly solid: at 226 they went dull tan over a dark cave
save("pill", cut(176, 76, 14, H("#e6dcff"), H("#6a4fc4"), a_top=206, a_bot=186, bevel=4.5), (40, 31, 136, 37))
for n, (t, dp) in {"pillButter": ("#ffe39a", "#b9791c"), "pillLilac": ("#d6c8ff", "#6a4fc4"), "pillMint": ("#b4f0dc", "#1f8f72"), "pillPink": ("#ffc8d8", "#c2416f")}.items():
    save(n, cut(176, 80, 15, H(t), H(dp), a_top=210, a_bot=190, bevel=4.5), (40, 33, 136, 41))
save("panel", cut(200, 200, 26, H("#cdbcff"), H("#5a41b0"), a_top=228, a_bot=214, bevel=9, face=FACE), (64, 64, 136, 126))
save("card", cut(176, 136, 20, H("#ffe6a6"), H("#b9791c"), a_top=226, a_bot=210, bevel=6, face=(H("#f7f3ff", 214), H("#e6defc", 198))), (50, 50, 126, 78))
save("dark", cut(112, 112, 16, H("#4a3a72"), H("#160d28"), a_top=226, a_bot=214, bevel=5, dark=True), (36, 36, 76, 64))
save("keycap", cut(72, 76, 10, H("#ffffff"), H("#6a4fc4"), a_top=244, a_bot=232, bevel=5, sheen=False), (24, 24, 48, 44))
save("keycapDown", cut(72, 76, 10, H("#e4daff"), H("#6a4fc4"), a_top=240, a_bot=230, bevel=3, sheen=False), (24, 24, 48, 50))
save("slot", cut(104, 104, 14, H("#d2c4f8"), H("#6a4fc4"), a_top=150, a_bot=178, bevel=5, sheen=False, inset=True), (32, 32, 72, 72))
save("tab", cut(136, 84, 14, H("#cfc0f6"), H("#5a41b0"), a_top=205, a_bot=188, bevel=5), (38, 36, 98, 46))
save("tabOn", cut(136, 84, 14, H("#ffe9a8"), H("#b9791c"), a_top=242, a_bot=228, bevel=5), (38, 36, 98, 46))


def ribbon(tint, deep):  # a slanted cut-glass title bar with two side fins, 352 x 104
    w, h = 352, 104
    im = Image.new("RGBA", (w * SS, h * SS), CLEAR)
    d = ImageDraw.Draw(im)
    for sx in (0, 1):
        x0 = 8 * SS if sx == 0 else (w - 62) * SS
        pts = [(x0 + 18 * SS, 30 * SS), (x0 + 54 * SS, 30 * SS), (x0 + 54 * SS, 90 * SS), (x0, 90 * SS)] if sx == 0 else \
              [(x0, 30 * SS), (x0 + 36 * SS, 30 * SS), (x0 + 54 * SS, 90 * SS), (x0, 90 * SS)]
        d.polygon(pts, fill=deep[:3] + (225,))
        d.line(pts + [pts[0]], fill=mix(deep, H("#000000"), 0.3)[:3] + (235,), width=int(1.2 * SS))
    body = cut(w - 76, 88, 16, tint, deep, a_top=240, a_bot=230, bevel=6)
    im.alpha_composite(body.resize(((w - 76) * SS, 88 * SS), Image.LANCZOS), (38 * SS, 4 * SS))
    return im.resize((w, h), Image.LANCZOS)


save("ribbonPink", ribbon(H("#ffb4cb"), H("#b23a66")), (100, 30, 252, 50))
save("ribbonLilac", ribbon(H("#cbb9ff"), H("#5a41b0")), (100, 30, 252, 50))


# ---- extras (not 9-sliced) ----
def hexpts(cx, cy, r, rot=0):
    return [(cx + r * math.cos(math.radians(rot + 60 * i)), cy + r * math.sin(math.radians(rot + 60 * i))) for i in range(6)]


def hexslot(tint, deep, lit=False):  # the hotbar's hexagonal cut-glass slot, flat top and bottom
    n = 128
    im = Image.new("RGBA", (n * SS, n * SS), CLEAR)
    cx = cy = n * SS / 2
    o, i_ = hexpts(cx, cy, 58 * SS), hexpts(cx, cy, 49 * SS)
    sh = Image.new("RGBA", im.size, CLEAR)
    ImageDraw.Draw(sh).polygon(hexpts(cx, cy + 3 * SS, 58 * SS), fill=(24, 10, 44, 110))
    im.alpha_composite(sh.filter(ImageFilter.GaussianBlur(2.5 * SS)))
    put(im, vgrad(im.size, mix(tint, H("#ffffff"), 0.35)[:3] + (170 if not lit else 225,), mix(tint, deep, 0.5)[:3] + (190 if not lit else 225,), cy - 58 * SS, cy + 58 * SS), mask(im.size, o))
    w = H("#ffffff")
    shades = [mix(tint, deep, 0.4)[:3] + (215,), mix(tint, deep, 0.8)[:3] + (235,), mix(tint, deep, 0.6)[:3] + (225,),
              mix(tint, w, 0.5)[:3] + (220,), w[:3] + (245,), mix(tint, w, 0.7)[:3] + (230,)]  # edges from the right vertex, clockwise on screen
    d = ImageDraw.Draw(im)
    for k in range(6):
        j = (k + 1) % 6
        d.polygon([o[k], o[j], i_[j], i_[k]], fill=shades[k])
        d.line([o[k], i_[k]], fill=w[:3] + (110,), width=max(1, int(0.5 * SS)))
    d.line(i_ + [i_[0]], fill=w[:3] + (220,), width=max(1, int(0.8 * SS)))
    d.line(o + [o[0]], fill=mix(deep, H("#000000"), 0.3)[:3] + (240,), width=int(1.3 * SS))
    return im.resize((n, n), Image.LANCZOS)


save("hex", hexslot(H("#bfaeff"), H("#3d2a86")))
save("hexOn", hexslot(H("#ffe39a"), H("#b9791c"), lit=True))


def orb_shell():  # the glass ball of a status orb: clear centre, rim, two highlights (the liquid sits behind it)
    n = 160
    im = Image.new("RGBA", (n * SS, n * SS), CLEAR)
    c, R = n * SS / 2, 72 * SS
    sh = Image.new("RGBA", im.size, CLEAR)
    ImageDraw.Draw(sh).ellipse((c - R, c - R + 4 * SS, c + R, c + R + 4 * SS), fill=(20, 8, 40, 120))
    hole = Image.new("L", im.size, 0)
    ImageDraw.Draw(hole).ellipse((c - R + 7 * SS, c - R + 7 * SS, c + R - 7 * SS, c + R - 7 * SS), fill=255)
    full = Image.new("L", im.size, 0)
    ImageDraw.Draw(full).ellipse((c - R, c - R, c + R, c + R), fill=255)
    im.alpha_composite(Image.composite(sh.filter(ImageFilter.GaussianBlur(3 * SS)), Image.new("RGBA", im.size, CLEAR), ImageChops.invert(full)))  # the shadow only outside the ball: the centre stays clear for the liquid
    put(im, vgrad(im.size, H("#ffffff", 250), H("#8f7bd6", 240), c - R, c + R), ImageChops.subtract(full, hole))  # the rim
    inner = Image.new("RGBA", im.size, CLEAR)  # inner shade so the ball reads round: darker towards the lower edge
    idr = ImageDraw.Draw(inner)
    idr.ellipse((c - R + 7 * SS, c - R + 7 * SS, c + R - 7 * SS, c + R - 7 * SS), fill=(30, 14, 60, 80))
    idr.ellipse((c - R + 12 * SS, c - R, c + R - 12 * SS, c + R - 20 * SS), fill=CLEAR)
    im.alpha_composite(Image.composite(inner.filter(ImageFilter.GaussianBlur(5 * SS)), Image.new("RGBA", im.size, CLEAR), hole))
    gl = Image.new("RGBA", im.size, CLEAR)
    gd = ImageDraw.Draw(gl)
    gd.ellipse((c - 44 * SS, c - 56 * SS, c - 4 * SS, c - 30 * SS), fill=(255, 255, 255, 215))  # main highlight
    gd.ellipse((c + 28 * SS, c + 34 * SS, c + 44 * SS, c + 46 * SS), fill=(255, 255, 255, 120))  # bounce light
    gd.arc((c - R + 12 * SS, c - R + 12 * SS, c + R - 12 * SS, c + R - 12 * SS), 20, 80, fill=(255, 255, 255, 140), width=int(2.4 * SS))
    im.alpha_composite(gl.filter(ImageFilter.GaussianBlur(1.6 * SS)))
    d = ImageDraw.Draw(im)
    d.ellipse((c - R, c - R, c + R, c + R), outline=(34, 20, 70, 240), width=int(1.4 * SS))
    return im.resize((n, n), Image.LANCZOS)


def orb_liquid():  # white swirl disc, tinted and spun in the game: soft bands so the turn is visible
    n = 160
    im = Image.new("RGBA", (n * SS, n * SS), CLEAR)
    c, R = n * SS / 2, 66 * SS
    d = ImageDraw.Draw(im)
    d.ellipse((c - R, c - R, c + R, c + R), fill=(255, 255, 255, 255))
    sw = Image.new("RGBA", im.size, CLEAR)
    sd = ImageDraw.Draw(sw)
    for k in range(5):
        a0 = k * 72
        for s in range(60):  # one spiral arm, darker
            t = s / 59
            ang, rad = math.radians(a0 + t * 250), R * (0.12 + 0.86 * t)
            x, y = c + rad * math.cos(ang), c + rad * math.sin(ang)
            r2 = SS * (3 + 9 * t)
            sd.ellipse((x - r2, y - r2, x + r2, y + r2), fill=(90, 90, 130, 135))
    im.alpha_composite(sw.filter(ImageFilter.GaussianBlur(3 * SS)))
    m = Image.new("L", im.size, 0)
    ImageDraw.Draw(m).ellipse((c - R, c - R, c + R, c + R), fill=255)
    out = Image.new("RGBA", im.size, CLEAR)
    put(out, im, m)
    return out.resize((n, n), Image.LANCZOS)


save("orbShell", orb_shell())
save("orbLiquid", orb_liquid())


def ring():  # smoked glass disc with a smooth bright glass rim: the wheel body and the radar case, 512 px
    n, s_ = 512, 3
    im = Image.new("RGBA", (n * s_, n * s_), CLEAR)
    c, R = n * s_ / 2, 246 * s_
    sh = Image.new("RGBA", im.size, CLEAR)
    ImageDraw.Draw(sh).ellipse((c - R, c - R + 5 * s_, c + R, c + R + 5 * s_), fill=(14, 6, 30, 120))
    im.alpha_composite(sh.filter(ImageFilter.GaussianBlur(5 * s_)))
    full = Image.new("L", im.size, 0)
    ImageDraw.Draw(full).ellipse((c - R, c - R, c + R, c + R), fill=255)
    Ri = R - 20 * s_
    hole = Image.new("L", im.size, 0)
    ImageDraw.Draw(hole).ellipse((c - Ri, c - Ri, c + Ri, c + Ri), fill=255)
    put(im, vgrad(im.size, (44, 32, 86, 222), (22, 14, 48, 232), c - Ri, c + Ri), hole)  # the smoked face
    put(im, vgrad(im.size, H("#ffffff", 250), H("#8068d8", 245), c - R, c + R), ImageChops.subtract(full, hole))  # the rim: white at the top, violet below
    d = ImageDraw.Draw(im)
    d.ellipse((c - Ri - 2 * s_, c - Ri - 2 * s_, c + Ri + 2 * s_, c + Ri + 2 * s_), outline=(60, 40, 130, 200), width=int(2 * s_))  # the rim's inner shade
    d.ellipse((c - R + 5 * s_, c - R + 5 * s_, c + R - 5 * s_, c + R - 5 * s_), outline=(255, 255, 255, 150), width=int(2 * s_))  # a hairline of light along the rim
    g = Image.new("RGBA", im.size, CLEAR)
    ImageDraw.Draw(g).ellipse((c - Ri * 0.9, c - Ri * 0.97, c + Ri * 0.9, c + Ri * 0.1), fill=(255, 255, 255, 30))  # a soft sheen on the upper face
    im.alpha_composite(Image.composite(g.filter(ImageFilter.GaussianBlur(18 * s_)), Image.new("RGBA", im.size, CLEAR), hole))
    gl = Image.new("RGBA", im.size, CLEAR)
    ImageDraw.Draw(gl).arc((c - R + 9 * s_, c - R + 9 * s_, c + R - 9 * s_, c + R - 9 * s_), 200, 250, fill=(255, 255, 255, 235), width=int(6 * s_))  # a glint on the rim
    im.alpha_composite(gl.filter(ImageFilter.GaussianBlur(1.5 * s_)))
    ImageDraw.Draw(im).ellipse((c - R, c - R, c + R, c + R), outline=(24, 12, 50, 245), width=int(2 * s_))
    return im.resize((n, n), Image.LANCZOS)


save("ring", ring())


def close():  # a rose cut-glass gem with a white cross, 96 x 100 like the other kits
    im = cut(96, 100, 16, H("#ff8fb0"), H("#b02a5c"), a_top=246, a_bot=240, bevel=7, sheen=False).resize((96 * SS, 100 * SS), Image.LANCZOS)
    d = ImageDraw.Draw(im)
    cx, cy, r = 48 * SS, 48 * SS, 15 * SS
    for a, b in (((cx - r, cy - r), (cx + r, cy + r)), ((cx - r, cy + r), (cx + r, cy - r))):
        d.line([a, b], fill=(120, 20, 60, 255), width=int(11 * SS))
    for a, b in (((cx - r, cy - r), (cx + r, cy + r)), ((cx - r, cy + r), (cx + r, cy - r))):
        d.line([a, b], fill=(255, 255, 255, 255), width=int(6.5 * SS))
    return im.resize((96, 100), Image.LANCZOS)


save("close", close())


def grid():  # plan tile: faint cyan lines on clear, tiled over smoked glass (the forge plan and the Soul Tree)
    n = 96
    im = Image.new("RGBA", (n, n), CLEAR)
    d = ImageDraw.Draw(im)
    for k in range(0, n, 24):
        a = 120 if k == 0 else 46
        d.line([(k, 0), (k, n)], fill=(150, 232, 255, a)); d.line([(0, k), (n, k)], fill=(150, 232, 255, a))
    return im


save("grid", grid())

json.dump({"slices": SLICES, "sizes": SIZES}, open(os.path.join(OUT, "slices.json"), "w"), indent=1)

sheet = Image.new("RGBA", (1500, 900), (0, 0, 0, 255))
sheet.alpha_composite(vgrad(sheet.size, H("#1a0f2a"), H("#5f8f5a"), 0, 900))
x, y, rowh = 20, 20, 0
for n in SIZES:
    im = Image.open(os.path.join(OUT, n + ".png"))
    if im.size[0] > 300: im = im.resize((256, 256), Image.LANCZOS)
    if x + im.size[0] > 1480:
        x, y, rowh = 20, y + rowh + 20, 0
    sheet.alpha_composite(im, (x, y))
    x += im.size[0] + 20
    rowh = max(rowh, im.size[1])
sheet.convert("RGB").save(os.path.join(OUT, "_sheet.jpg"), quality=92)
print("cut-glass kit:", len(SIZES), "images ->", OUT)
