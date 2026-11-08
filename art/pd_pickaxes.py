"""Five elemental pickaxes after the user's sword reference (2026-11-08): Verdant (vines), Arcane (runes),
Frost (snow and icicles), Starlight (sparkles), Thunder (lightning). Floating over glow rings in a dark cave,
wrapped in spiral light ribbons. Rendered at 2x and downsampled. Usage: python pd_pickaxes.py <out_dir>"""
import math, os, random, sys
import numpy as np
from PIL import Image, ImageDraw
from scipy.ndimage import gaussian_filter

OUT = sys.argv[1] if len(sys.argv) > 1 else "out"
S = 2  # supersample
W, H_ = 1536 * S, 864 * S


def hx(h):
    return tuple(int(h[i:i + 2], 16) for i in (1, 3, 5))


THEMES = [
    ("VERDANT", hx("#6dff3c"), hx("#9fcf8c"), hx("#2f5a2a")),
    ("ARCANE", hx("#a46cff"), hx("#8f72d0"), hx("#3d2a70")),
    ("FROST", hx("#86d8ff"), hx("#8fc8ec"), hx("#2f5f86")),
    ("STARLIGHT", hx("#ff7cc4"), hx("#e48cb6"), hx("#7a2f58")),
    ("THUNDER", hx("#ffcf2e"), hx("#d8b048"), hx("#6a4a10")),
]
XS = [210, 480, 768, 1056, 1326]


def blank():
    return Image.new("RGB", (W, H_), (0, 0, 0))


def arr(im):
    return np.asarray(im).astype(np.float32) / 255


def background():
    im = Image.new("RGB", (W, H_))
    d = ImageDraw.Draw(im)
    for y in range(H_):
        t = y / H_
        c = tuple(int(a + (b - a) * t) for a, b in zip((12, 15, 22), (24, 29, 40)))
        d.line([(0, y), (W, y)], fill=c)
    rnd = random.Random(4)
    for _ in range(14):  # cave rocks behind
        x, y, r = rnd.randrange(0, W), rnd.randrange(0, int(H_ * 0.8)), rnd.randrange(120, 320) * S
        d.ellipse([x - r, y - r, x + r, y + int(r * 1.3)], fill=(22 + rnd.randrange(10), 26 + rnd.randrange(10), 34 + rnd.randrange(12)))
    fy = int(H_ * 0.86)  # stone floor with perspective seams
    d.rectangle([0, fy, W, H_], fill=(20, 22, 28))
    for k in range(-12, 13):
        d.line([(W / 2 + k * 60 * S, fy), (W / 2 + k * 200 * S, H_)], fill=(30, 33, 41), width=S)
    for yy in (fy + 22 * S, fy + 60 * S, fy + 110 * S):
        d.line([(0, yy), (W, yy)], fill=(30, 33, 41), width=S)
    a = arr(im)
    return gaussian_filter(a, (1.5 * S, 1.5 * S, 0))


def pick_head(cx, cy, theme):
    """Crescent pick head polygon (two curved points) plus themed edge shape."""
    name = theme[0]
    top, bot = [], []
    for i in range(41):
        t = i / 40 * 2 - 1  # -1 .. 1 along the head
        x = cx + t * 128 * S
        sag = (t * t) ** 1.15 * 62 * S  # tips droop down
        th = (1 - abs(t) ** 1.3) * 46 * S + 4 * S  # thick in the middle, sharp at the tips
        if name == "THUNDER" and abs(t) > 0.2:
            th += (6 * S if i % 4 < 2 else -3 * S) * (1 - abs(t))  # jagged edge
        if name == "VERDANT":
            th *= 1 + 0.25 * math.sin(abs(t) * math.pi)  # leaf-like bulge
        top.append((x, cy + sag - th * 0.7))
        bot.append((x, cy + sag + th * 0.3))
    return top + bot[::-1]


def draw_model(d, cx, theme, glow_d):
    name, glow, body, dark = theme
    cy = 205 * S
    hy0, hy1 = cy + 18 * S, 760 * S
    lit = tuple(min(255, int(c * 1.25 + 30)) for c in body)
    shadow = tuple(int(c * 0.62) for c in body)
    # handle with a wrapped grip on the lower half
    d.rectangle([cx - 9 * S, hy0, cx + 9 * S, hy1 - 40 * S], fill=shadow)
    d.rectangle([cx - 9 * S, hy0, cx - 2 * S, hy1 - 40 * S], fill=body)
    for y in range(int(hy0 + 300 * S), int(hy1 - 40 * S), 14 * S):
        d.polygon([(cx - 11 * S, y), (cx + 11 * S, y + 6 * S), (cx + 11 * S, y + 11 * S), (cx - 11 * S, y + 5 * S)], fill=(40, 34, 30))
        d.line([(cx - 11 * S, y), (cx + 11 * S, y + 6 * S)], fill=dark, width=2 * S)
    # pommel crystal
    p = [(cx, hy1 - 46 * S), (cx + 13 * S, hy1 - 20 * S), (cx, hy1 + 10 * S), (cx - 13 * S, hy1 - 20 * S)]
    d.polygon(p, fill=body)
    d.polygon([p[0], p[2], p[3]], fill=lit)
    glow_d.polygon(p, fill=tuple(int(c * 0.6) for c in glow))
    # collar wings under the head (the sword guard, reshaped)
    for sgn in (-1, 1):
        wing = [(cx, cy + 40 * S), (cx + sgn * 46 * S, cy + 30 * S), (cx + sgn * 64 * S, cy + 52 * S), (cx + sgn * 30 * S, cy + 56 * S), (cx, cy + 66 * S)]
        d.polygon(wing, fill=body if sgn < 0 else shadow)
    d.ellipse([cx - 13 * S, cy + 38 * S, cx + 13 * S, cy + 64 * S], fill=lit)
    glow_d.ellipse([cx - 8 * S, cy + 43 * S, cx + 8 * S, cy + 59 * S], fill=glow)
    # head: left half lit, right half in shadow, bright top edge, emissive core line
    poly = pick_head(cx, cy, theme)
    d.polygon(poly, fill=shadow)
    d.polygon([q for q in poly if q[0] <= cx] + [(cx, cy + 30 * S)], fill=body)
    n = len(poly) // 2
    mid = [((poly[i][0] + poly[-1 - i][0]) / 2, (poly[i][1] * 0.6 + poly[-1 - i][1] * 0.4)) for i in range(n)]
    d.polygon(poly[:n] + mid[::-1], fill=lit)  # upper facet catches the light
    d.line(mid, fill=tuple(min(255, c + 60) for c in lit), width=2 * S)  # centre ridge
    d.line(poly[n:], fill=dark, width=3 * S)
    d.line(poly[:n], fill=lit, width=3 * S)
    glow_d.line(poly[:n], fill=tuple(int(c * 0.7) for c in glow), width=2 * S)
    d.rectangle([cx - 20 * S, cy - 26 * S, cx + 20 * S, cy + 36 * S], fill=body)  # socket
    d.rectangle([cx - 20 * S, cy - 26 * S, cx - 4 * S, cy + 36 * S], fill=lit)
    d.polygon([(cx, cy - 46 * S), (cx + 14 * S, cy - 24 * S), (cx - 14 * S, cy - 24 * S)], fill=lit)  # top spike
    glow_d.line([(cx, cy - 40 * S), (cx, cy + 30 * S)], fill=glow, width=3 * S)
    return cy


def helix(cx, y0, y1, turns, phase, r0, seed=0):
    """A loose, uneven spiral: radius breathes, the ribbon fades in and out (t carries an opacity)."""
    pts = []
    n = 1200
    for i in range(n + 1):
        t = i / n
        y = y0 + (y1 - y0) * t
        a = 2 * math.pi * turns * t + phase + 0.5 * math.sin(t * 7 + seed)
        r = r0 * (0.55 + 0.3 * math.sin(math.pi * t) + 0.18 * math.sin(t * 11 + seed * 2))
        op = max(0.0, min(1.0, 0.65 + 0.5 * math.sin(t * 9 + seed * 3)))
        pts.append((cx + r * math.sin(a), y, math.cos(a), t, op))
    return pts


def stroke_points(d, pts, col, w0, front, dim=0.4):
    for (x, y, z, t, op) in pts:
        if (z > 0) != front:
            continue
        k = ((0.55 + 0.45 * z) if front else dim * (0.6 + 0.4 * -z)) * op
        w = w0 * (0.25 + 0.75 * math.sin(math.pi * t)) * (0.6 + 0.4 * abs(z)) * (0.6 + 0.6 * op)
        c = tuple(int(v * k) for v in col)
        d.ellipse([x - w, y - w, x + w, y + w], fill=c)


def snowflake(d, x, y, r, col):
    for k in range(6):
        a = k * math.pi / 3
        ex, ey = x + r * math.cos(a), y + r * math.sin(a)
        d.line([(x, y), (ex, ey)], fill=col, width=S)
        for f in (0.55,):
            bx, by = x + r * f * math.cos(a), y + r * f * math.sin(a)
            for s_ in (-0.6, 0.6):
                d.line([(bx, by), (bx + r * 0.3 * math.cos(a + s_), by + r * 0.3 * math.sin(a + s_))], fill=col, width=S)


def sparkle(d, x, y, r, col):
    d.polygon([(x, y - r), (x + r * 0.16, y - r * 0.16), (x + r, y), (x + r * 0.16, y + r * 0.16), (x, y + r), (x - r * 0.16, y + r * 0.16), (x - r, y), (x - r * 0.16, y - r * 0.16)], fill=col)


def rune(d, x, y, sz, col, rnd):
    segs = [((0, 0), (0, 1)), ((0, 0), (0.6, 0.3)), ((0.6, 0.3), (0, 0.55)), ((0, 0.5), (0.6, 1)), ((0.6, 0), (0.6, 1)), ((0, 0.3), (0.6, 0.6))]
    for (a, b) in rnd.sample(segs, 3):
        d.line([(x + a[0] * sz, y + a[1] * sz), (x + b[0] * sz, y + b[1] * sz)], fill=col, width=max(1, S))


def bolt(d, x0, y0, x1, y1, col, rnd, depth=0):
    n = 8
    pts = [(x0, y0)]
    for i in range(1, n):
        t = i / n
        pts.append((x0 + (x1 - x0) * t + rnd.uniform(-34, 34) * S, y0 + (y1 - y0) * t + rnd.uniform(-10, 10) * S))
    pts.append((x1, y1))
    d.line(pts, fill=col, width=(3 if depth == 0 else 2) * S)
    d.line(pts, fill=(255, 250, 225), width=S)
    if depth < 1:
        for _ in range(2):
            i = rnd.randrange(2, n - 2)
            bx, by = pts[i]
            bolt(d, bx, by, bx + rnd.uniform(-70, 70) * S, by + rnd.uniform(30, 90) * S, col, rnd, depth + 1)


def render():
    bg = background()
    model = blank()
    glow_back, glow_front, emit = blank(), blank(), blank()
    md, gb, gf, em = ImageDraw.Draw(model), ImageDraw.Draw(glow_back), ImageDraw.Draw(glow_front), ImageDraw.Draw(emit)
    floor = blank()
    fd = ImageDraw.Draw(floor)
    mask = Image.new("L", (W, H_), 0)
    mdk = ImageDraw.Draw(mask)
    for k, (cx1, theme) in enumerate(zip(XS, THEMES)):
        cx = cx1 * S
        name, glow, body, dark = theme
        rnd = random.Random(10 + k)
        fy = 800 * S  # glow ring and pool on the floor
        fd.ellipse([cx - 92 * S, fy - 12 * S, cx + 92 * S, fy + 12 * S], outline=glow, width=3 * S)
        fd.ellipse([cx - 70 * S, fy - 8 * S, cx + 70 * S, fy + 8 * S], fill=tuple(int(c * 0.35) for c in glow))
        ribbons = [helix(cx, 130 * S, 800 * S, 2.0, ph, 108 * S, k + ph) for ph in (0.0, 2.1, 4.2)]
        thin = [helix(cx, 110 * S, 810 * S, 2.8, ph, 125 * S, k * 2 + ph) for ph in (1.6,)]
        if name == "VERDANT":  # dark vines wind round it, behind and in front
            vine = helix(cx, 170 * S, 760 * S, 3, 0.7, 48 * S, 5)
            stroke_points(md, vine, (40, 66, 30), 7 * S, False, 1.0)
        for rb in ribbons:
            stroke_points(gb, rb, glow, 7 * S, False)
        for rb in thin:
            stroke_points(gb, rb, tuple(int(c * 0.8) for c in glow), 2 * S, False)
        draw_model(md, cx, theme, em)
        mdk.rectangle([cx - 130 * S, 120 * S, cx + 130 * S, 780 * S], fill=0)
        if name == "VERDANT":
            stroke_points(md, vine, (52, 88, 38), 7 * S, True, 1.0)
            for (x, y, z, t, op) in vine[::45]:
                if z > 0:
                    md.ellipse([x - 7 * S, y - 3 * S, x + 7 * S, y + 3 * S], fill=(70, 130, 50))
        for rb in ribbons:
            stroke_points(gf, rb, glow, 7 * S, True)
        for rb in thin:
            stroke_points(gf, rb, tuple(int(c * 0.8) for c in glow), 2 * S, True)
        # theme particles and details
        for _ in range(90):
            x, y = cx + rnd.gauss(0, 85) * S, rnd.uniform(110, 800) * S
            r = rnd.choice((1, 1, 2, 2, 3)) * S
            col = glow if rnd.random() < 0.7 else (255, 255, 255)
            em.ellipse([x - r, y - r, x + r, y + r], fill=col)
        if name == "VERDANT":
            for _ in range(26):
                x, y = cx + rnd.gauss(0, 70) * S, rnd.uniform(140, 760) * S
                em.line([(x, y), (x + rnd.uniform(-8, 8) * S, y - rnd.uniform(4, 12) * S)], fill=glow, width=2 * S)
            for i in range(6):  # glowing cracks in the head
                y = (190 + i * 6) * S
                em.line([(cx - (40 + i * 12) * S, y + 20 * S), (cx - (20 + i * 10) * S, y + 26 * S)], fill=glow, width=S)
        if name == "ARCANE":
            for i in range(7):
                rune(em, cx - 5 * S, (250 + i * 38) * S, 11 * S, (230, 210, 255), rnd)
            for _ in range(10):
                rune(em, cx + rnd.gauss(0, 95) * S, rnd.uniform(130, 760) * S, 9 * S, glow, rnd)
            for _ in range(3):  # thin orbit arcs
                r = rnd.uniform(110, 150) * S
                y = rnd.uniform(200, 600) * S
                em.arc([cx - r, y - r, cx + r, y + r], rnd.uniform(200, 260), rnd.uniform(300, 340), fill=(140, 160, 255), width=S)
        if name == "FROST":
            for _ in range(14):
                snowflake(em, cx + rnd.gauss(0, 95) * S, rnd.uniform(130, 760) * S, rnd.uniform(5, 10) * S, (220, 245, 255))
            for i in range(-6, 7):  # icicles hanging from the head and collar
                x = cx + i * 17 * S
                y = (245 + (i * i) * 1.2) * S
                ln = rnd.uniform(14, 34) * S
                md.polygon([(x - 4 * S, y), (x + 4 * S, y), (x, y + ln)], fill=(214, 240, 255))
                em.line([(x, y), (x, y + ln * 0.8)], fill=(150, 210, 255), width=S)
        if name == "STARLIGHT":
            for _ in range(16):
                sparkle(em, cx + rnd.gauss(0, 100) * S, rnd.uniform(130, 780) * S, rnd.uniform(6, 15) * S, (255, 245, 252))
            em.ellipse([cx - 7 * S, 243 * S, cx + 7 * S, 257 * S], fill=(255, 220, 240))
        if name == "THUNDER":
            for j in range(3):
                sx = cx + rnd.uniform(-110, 110) * S
                bolt(gf, sx, rnd.uniform(110, 300) * S, sx + rnd.uniform(-60, 60) * S, rnd.uniform(560, 760) * S, (255, 206, 60), rnd)
            for _ in range(20):
                x, y = cx + rnd.gauss(0, 90) * S, rnd.uniform(400, 800) * S
                em.rectangle([x, y, x + 2 * S, y + 4 * S], fill=(255, 150, 60))
    a = bg + arr(floor) * 0.6 + gaussian_filter(arr(floor), (8 * S, 8 * S, 0)) * 1.4
    gbk = arr(glow_back)
    a = a + gaussian_filter(gbk, (10 * S, 10 * S, 0)) * 0.7 + gaussian_filter(gbk, (2 * S, 2 * S, 0)) * 0.55
    mod = arr(model)
    msk = (mod.sum(-1) > 0)[..., None]
    a = np.where(msk, mod * 0.95 + a * 0.05, a)  # the model occludes what is behind it
    a = a + gaussian_filter(mod, (10 * S, 10 * S, 0)) * 0.12  # soft light spill from the model
    gfr, emi = arr(glow_front), arr(emit)
    for layer, k1, k2 in ((gfr, 0.95, 0.9), (emi, 0.9, 0.6)):
        core = gaussian_filter(layer, (0.8 * S, 0.8 * S, 0))
        a = a + core * k1 + gaussian_filter(layer, (7 * S, 7 * S, 0)) * k2 + gaussian_filter(layer, (24 * S, 24 * S, 0)) * 0.35
        white = gaussian_filter(np.clip(layer.max(-1, keepdims=True) - 0.55, 0, 1), (0.6 * S, 0.6 * S, 0)) * 0.6  # hot core only where strokes are brightest
        a = a + white
    a = a + gaussian_filter(np.clip(mod * 0.25, 0, 1), (16 * S, 16 * S, 0)) * 0.0
    a = np.clip(a / (1 + a * 0.6), 0, 1) ** 0.92  # soft shoulder tone map
    im = Image.fromarray((a * 255).astype(np.uint8), "RGB").resize((W // S, H_ // S), Image.LANCZOS)
    dl = ImageDraw.Draw(im)
    return im


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    render().save(os.path.join(OUT, "pickaxes_vfx.png"))
    print("ok")
