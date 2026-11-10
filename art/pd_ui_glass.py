"""Pixel Depth glass UI kit (2026-11-09 overnight, the user: "For UI and atmosphere ... get glass and reflections ... applied in all
parts of the game ... UI, HUD"). Same image sizes and 9-slice centres as the soft kit (pd_ui_soft.py, slices.json), so the client
only swaps image ids. Look (refs: Apple Liquid Glass, boatbomber's GlassmorphicUI, our own Codex refs in art/glass/refs_own):
pastel-tinted frosted glass, more opaque at the top, a bright white rim that fades to a deeper tint at the bottom, a thin deep
outline so it reads on light backgrounds, an inner highlight band, one diagonal specular streak, two fresnel glints on opposite
corners, a faint pink/cyan dispersion line inside the side edges, a soft drop shadow. Text stays on the most opaque part.
Usage: python pd_ui_glass.py <out_dir>"""
import json, os, sys
from PIL import Image, ImageDraw, ImageFilter, ImageChops

OUT = sys.argv[1] if len(sys.argv) > 1 else "ui_glass"
os.makedirs(OUT, exist_ok=True)
SS = 4
SIZES, SLICES = {}, {}


def H(h, a=255):
    return tuple(int(h[i:i + 2], 16) for i in (1, 3, 5)) + (a,)


def mix(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t + 0.5) for i in range(4))


def rr(size, box, r):
    m = Image.new("L", size, 0)
    ImageDraw.Draw(m).rounded_rectangle(box, r, fill=255)
    return m


def vgrad(size, top, bot, y0=0, y1=None):
    y1 = size[1] if y1 is None else y1
    g = Image.new("RGBA", size)
    d = ImageDraw.Draw(g)
    for y in range(size[1]):
        t = min(max((y - y0) / max(y1 - y0, 1), 0), 1)
        d.line([(0, y), (size[0], y)], fill=mix(top, bot, t))
    return g


def put(im, src, mask):
    im.alpha_composite(Image.composite(src, Image.new("RGBA", im.size, (0, 0, 0, 0)), mask))


def glass(w, h, r, tint, deep, a_top=205, a_bot=165, rim=3.0, lip=0, frame=0, frame_tint=None, streak=True, dark=False, inset=False):
    W, Hh, R = w * SS, h * SS, r * SS
    im = Image.new("RGBA", (W, Hh), (0, 0, 0, 0))
    pad = 3 * SS
    box = (pad, pad, W - 1 - pad, Hh - 1 - pad - (2 * SS if not inset else 0))
    # soft drop shadow
    if not inset:
        sh = Image.new("RGBA", im.size, (0, 0, 0, 0))
        ImageDraw.Draw(sh).rounded_rectangle((box[0] + SS, box[1] + 3 * SS, box[2] - SS, box[3] + 2 * SS), R, fill=(40, 20, 60, 70))
        im.alpha_composite(sh.filter(ImageFilter.GaussianBlur(3 * SS)))
    body = rr(im.size, box, R)
    # glass body: lighter and more opaque at the top
    top = mix(tint, H("#ffffff"), 0.5 if not dark else 0.12)
    top = top[:3] + (a_top,)
    bot = deep[:3] + (a_bot,) if dark else mix(tint, deep, 0.12)[:3] + (a_bot,)
    put(im, vgrad(im.size, top, bot, box[1], box[3]), body)
    if inset:  # a slot: an inner shadow along the top edge
        sh = Image.new("RGBA", im.size, (0, 0, 0, 0))
        ImageDraw.Draw(sh).rounded_rectangle((box[0], box[1] - 6 * SS, box[2], box[1] + 10 * SS), R, fill=deep[:3] + (90,))
        put(im, sh.filter(ImageFilter.GaussianBlur(4 * SS)), body)
    # a frosted frame ring (panels and cards)
    if frame:
        F = frame * SS
        inner = rr(im.size, (box[0] + F, box[1] + F, box[2] - F, box[3] - F), max(R - F, 4))
        ring = ImageChops.subtract(body, inner)
        ft = frame_tint or tint
        put(im, vgrad(im.size, mix(ft, H("#ffffff"), 0.35)[:3] + (225,), ft[:3] + (205,), box[1], box[3]), ring)
        # the face inside the frame: light frosted glass, nearly opaque for text
        put(im, vgrad(im.size, H("#ffffff", 236), mix(tint, H("#ffffff"), 0.7)[:3] + (226,), box[1], box[3]), inner)
        # a fine rim on the inner edge of the frame
        rim_in = ImageChops.subtract(inner, rr(im.size, (box[0] + F + SS, box[1] + F + SS, box[2] - F - SS, box[3] - F - SS), max(R - F - SS, 4)))
        put(im, Image.new("RGBA", im.size, H("#ffffff", 170)), rim_in)
    # a 3D lip along the bottom (buttons): a deeper band inside the glass
    if lip:
        L = lip * SS
        lipm = ImageChops.subtract(body, rr(im.size, (box[0], box[1], box[2], box[3] - L), R))
        put(im, Image.new("RGBA", im.size, deep[:3] + (150,)), lipm)
    # inner highlight band on the upper part
    hb = rr(im.size, (box[0] + 3 * SS, box[1] + 2 * SS, box[2] - 3 * SS, box[1] + (box[3] - box[1]) * 0.48), max(R - 3 * SS, 4))
    put(im, vgrad(im.size, H("#ffffff", 120 if not dark else 60), H("#ffffff", 0), box[1], box[1] + (box[3] - box[1]) * 0.48), hb)
    # the diagonal specular streak
    if streak:
        st = Image.new("L", im.size, 0)
        x0 = box[0] + (box[2] - box[0]) * 0.18
        ImageDraw.Draw(st).polygon([(x0, box[1]), (x0 + 16 * SS, box[1]), (x0 - 6 * SS, box[3]), (x0 - 22 * SS, box[3])], fill=70 if not dark else 35)
        st = ImageChops.multiply(st.filter(ImageFilter.GaussianBlur(3 * SS)), body)
        im.alpha_composite(Image.merge("RGBA", (Image.new("L", im.size, 255),) * 3 + (st,)))
    # dispersion: faint pink inside the left edge, cyan inside the right
    for side, col in ((0, H("#ff9db0", 90)), (1, H("#8ee6ff", 90))):
        disp = Image.new("L", im.size, 0)
        x = box[0] + 2.5 * SS if side == 0 else box[2] - 2.5 * SS
        ImageDraw.Draw(disp).line([(x, box[1] + R * 0.7), (x, box[3] - R * 0.7)], fill=255, width=int(1.2 * SS))
        disp = ImageChops.multiply(disp.filter(ImageFilter.GaussianBlur(SS)), body)
        im.alpha_composite(Image.composite(Image.new("RGBA", im.size, col), Image.new("RGBA", im.size, (0, 0, 0, 0)), disp))
    # the rim: bright white at the top fading to a deeper tint at the bottom, plus a thin deep outline outside it
    RW = rim * SS
    ring = ImageChops.subtract(body, rr(im.size, (box[0] + RW, box[1] + RW, box[2] - RW, box[3] - RW), max(R - RW, 4)))
    put(im, vgrad(im.size, H("#ffffff", 245), mix(tint, deep, 0.5)[:3] + (200,), box[1], box[3]), ring)
    outer = ImageChops.subtract(rr(im.size, (box[0] - SS, box[1] - SS, box[2] + SS, box[3] + SS), R + SS), body)
    put(im, Image.new("RGBA", im.size, deep[:3] + (190 if not inset else 140,)), outer)
    # fresnel glints: a bright arc hugging the top-left corner and a softer one at the bottom-right
    gl = Image.new("RGBA", im.size, (0, 0, 0, 0))
    gd = ImageDraw.Draw(gl)
    rr_ = max(R - 3.2 * SS, 6 * SS)
    gd.arc((box[0] + 3.2 * SS, box[1] + 3.2 * SS, box[0] + 3.2 * SS + 2 * rr_, box[1] + 3.2 * SS + 2 * rr_), 185, 265, fill=(255, 255, 255, 240), width=int(2.2 * SS))
    gd.arc((box[2] - 3.2 * SS - 2 * rr_, box[3] - 3.2 * SS - 2 * rr_, box[2] - 3.2 * SS, box[3] - 3.2 * SS), 15, 75, fill=(255, 255, 255, 150), width=int(1.6 * SS))
    im.alpha_composite(gl.filter(ImageFilter.GaussianBlur(0.7 * SS)))
    return im.resize((w, h), Image.LANCZOS)


def save(name, im, slice_box):
    im.save(os.path.join(OUT, name + ".png"))
    SLICES[name] = list(slice_box)
    SIZES[name] = list(im.size)


BTN = {"mint": ("#8fe3c4", "#2f9c78"), "pink": ("#ffb3c4", "#d0607e"), "lilac": ("#cbb9f6", "#7a62c2"),
       "butter": ("#ffe08a", "#c48a2e"), "sky": ("#a9d8ff", "#3f86c8"), "off": ("#d9d3e3", "#8a7f99")}
for n, (t, d) in BTN.items():
    save(n, glass(160, 100, 34, H(t), H(d), a_top=228, a_bot=210, lip=8), (42, 40, 118, 52))
save("pill", glass(176, 76, 30, H("#efe8ff"), H("#7d64b8"), a_top=226, a_bot=205), (40, 31, 136, 37))
for n, (t, d) in {"pillButter": ("#ffe8a3", "#c48a2e"), "pillLilac": ("#ddd0fb", "#7a62c2"), "pillMint": ("#bff0dc", "#2f9c78"), "pillPink": ("#ffd0dc", "#d0607e")}.items():
    save(n, glass(176, 80, 32, H(t), H(d), a_top=226, a_bot=205), (40, 33, 136, 41))
save("panel", glass(200, 200, 46, H("#e9e0ff"), H("#6f58b0"), frame=12, frame_tint=H("#c2b0f4"), streak=True), (64, 64, 136, 126))
save("card", glass(176, 136, 34, H("#fff4d6"), H("#c48a2e"), frame=9, frame_tint=H("#ffd970")), (50, 50, 126, 78))
save("dark", glass(112, 112, 28, H("#5a4680"), H("#1e1430"), a_top=215, a_bot=200, dark=True), (36, 36, 76, 64))
save("keycap", glass(72, 76, 18, H("#ffffff"), H("#6f58b0"), a_top=235, a_bot=215, lip=7, streak=False), (24, 24, 48, 44))
save("keycapDown", glass(72, 76, 18, H("#ece4ff"), H("#6f58b0"), a_top=230, a_bot=215, lip=2, streak=False), (24, 24, 48, 50))
save("slot", glass(104, 104, 26, H("#ded3fb"), H("#8f78d0"), a_top=170, a_bot=195, streak=False, inset=True), (32, 32, 72, 72))
save("tab", glass(136, 84, 28, H("#d6caf6"), H("#6f58b0"), a_top=190, a_bot=170, lip=6), (38, 36, 98, 46))
save("tabOn", glass(136, 84, 28, H("#fff1c4"), H("#c48a2e"), a_top=235, a_bot=210, lip=6), (38, 36, 98, 46))


def ribbon(tint, deep):  # a glass title banner with folded tails, 352 x 104
    w, h = 352, 104
    W, Hh = w * SS, h * SS
    im = Image.new("RGBA", (W, Hh), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    for sx in (0, 1):  # the folded tails behind the body
        x0 = 6 * SS if sx == 0 else W - 64 * SS
        pts = [(x0, 30 * SS), (x0 + 58 * SS, 30 * SS), (x0 + 58 * SS, 92 * SS), (x0, 92 * SS), (x0 + 20 * SS, 61 * SS)] if sx == 0 else \
              [(x0, 30 * SS), (x0 + 58 * SS, 30 * SS), (x0 + 38 * SS, 61 * SS), (x0 + 58 * SS, 92 * SS), (x0, 92 * SS)]
        d.polygon(pts, fill=deep[:3] + (210,))
    body = glass(w - 76, 88, 26, tint, deep, a_top=225, a_bot=200, lip=8)
    im.alpha_composite(body.resize(((w - 76) * SS, 88 * SS), Image.LANCZOS), (38 * SS, 4 * SS))
    return im.resize((w, h), Image.LANCZOS)


save("ribbonPink", ribbon(H("#ffc4d1"), H("#c25674")), (100, 30, 252, 50))
save("ribbonLilac", ribbon(H("#d6c9fb"), H("#6f58b0")), (100, 30, 252, 50))

json.dump({"slices": SLICES, "sizes": SIZES}, open(os.path.join(OUT, "slices.json"), "w"), indent=1)

# preview sheet over a cave-like backdrop (glass must read over dark plum and over light town ground)
names = list(SIZES)
sheet = Image.new("RGBA", (1400, 700), (0, 0, 0, 255))
bg = vgrad(sheet.size, H("#2b2140"), H("#5f8f5a"))
sheet.alpha_composite(bg)
x, y, rowh = 20, 20, 0
for n in names:
    im = Image.open(os.path.join(OUT, n + ".png"))
    if x + im.size[0] > 1380:
        x, y, rowh = 20, y + rowh + 20, 0
    sheet.alpha_composite(im, (x, y))
    x += im.size[0] + 20
    rowh = max(rowh, im.size[1])
sheet.save(os.path.join(OUT, "_sheet.png"))
print("glass kit:", len(names), "images ->", OUT)
