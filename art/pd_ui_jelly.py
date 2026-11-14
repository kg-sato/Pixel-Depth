"""Pixel Depth "jelly and shine" pieces (2026-11-13, directive v9: the HUD buttons, currency pills and hex slots must read as
glossy bouncy jelly like the loading logo, not flat glass tiles). Same sizes and 9-slice centres as art/ui_cutglass, so the
game only swaps image ids (Config.UI_GLASS.jelly, switch Config.UI_JELLY).
Recipe per piece (the directive's): a rounded jewel-toned body with a vertical gradient, a thick darker bottom lip, a 1.5 px
glowing rim, a white dome crescent over the upper third (alpha 0.55 to 0), a soft glow low in the body, a small white corner glint.
    python art/pd_ui_jelly.py        -> art/ui_jelly/*.png and _sheet.jpg"""
import math, pathlib
from PIL import Image, ImageDraw, ImageFilter, ImageChops

here = pathlib.Path(__file__).resolve().parent
out = here / "ui_jelly"
out.mkdir(exist_ok=True)
SS = 4
CLEAR = (0, 0, 0, 0)
done = []


def H(h, a=255): return tuple(int(h[i:i + 2], 16) for i in (1, 3, 5)) + (a,)
def mix(a, b, t): return tuple(int(a[i] + (b[i] - a[i]) * t + 0.5) for i in range(4))


def vgrad(size, top, bot, y0, y1):
    g = Image.new("RGBA", size)
    d = ImageDraw.Draw(g)
    for y in range(size[1]):
        t = min(max((y - y0) / max(y1 - y0, 1), 0), 1)
        d.line([(0, y), (size[0], y)], fill=mix(top, bot, t))
    return g


def shape_mask(size, pts=None, box=None, r=0):
    m = Image.new("L", size, 0)
    d = ImageDraw.Draw(m)
    if pts: d.polygon(pts, fill=255)
    else: d.rounded_rectangle(box, r, fill=255)
    return m


def put(im, src, m): im.alpha_composite(Image.composite(src, Image.new("RGBA", im.size, CLEAR), m))


def jelly(size, top, bot, rim, alpha=248, radius=16, lip=6, pts=None, lit=False):
    """One jelly piece. top, bot: the body's gradient; rim: the glowing edge; pts(scale): a polygon instead of a rounded box."""
    w, h = size
    W, Hh = w * SS, h * SS
    im = Image.new("RGBA", (W, Hh), CLEAR)
    pad, L, R = 4 * SS, lip * SS, radius * SS
    box = (pad, pad, W - 1 - pad, Hh - 1 - pad - L)
    def m_at(dy=0, grow=0):
        if pts: return shape_mask(im.size, pts=[(x, y + dy) for x, y in pts(SS, grow)])
        return shape_mask(im.size, box=(box[0] - grow, box[1] + dy - grow, box[2] + grow, box[3] + dy + grow), r=R + grow)
    body = m_at()
    sh = Image.new("RGBA", im.size, (20, 6, 40, 0))
    sh.putalpha(m_at(L + 2 * SS).point(lambda v: v * 110 // 255))
    im.alpha_composite(sh.filter(ImageFilter.GaussianBlur(2.2 * SS)))
    glow = Image.new("RGBA", im.size, rim[:3] + (0,))  # the rim's glow outside the body
    glow.putalpha(m_at(L // 2, 2 * SS).point(lambda v: v * (150 if lit else 90) // 255))
    im.alpha_composite(glow.filter(ImageFilter.GaussianBlur(2.4 * SS)))
    lipc = mix(bot, H("#000000"), 0.45)[:3] + (255,)
    put(im, Image.new("RGBA", im.size, lipc), m_at(L))  # the thick bottom lip
    put(im, vgrad(im.size, top[:3] + (alpha,), bot[:3] + (alpha,), box[1], box[3]), body)
    low = Image.new("L", im.size, 0)  # light gathered low in the jelly
    ImageDraw.Draw(low).ellipse((box[0] + (box[2] - box[0]) * 0.12, box[3] - (box[3] - box[1]) * 0.42, box[2] - (box[2] - box[0]) * 0.12, box[3] + (box[3] - box[1]) * 0.2), fill=95)
    low = ImageChops.multiply(low.filter(ImageFilter.GaussianBlur(5 * SS)), body)
    im.alpha_composite(Image.merge("RGBA", tuple(Image.new("L", im.size, c) for c in mix(top, H("#ffffff"), 0.55)[:3]) + (low,)))
    # the dome crescent: white over the upper third, fading down, its lower edge a wide shallow curve
    inset = 2.6 * SS
    dome = Image.new("L", im.size, 0)
    bh = box[3] - box[1]
    ImageDraw.Draw(dome).ellipse((box[0] - (box[2] - box[0]) * 0.35, box[1] - bh * 1.2, box[2] + (box[2] - box[0]) * 0.35, box[1] + bh * 0.44), fill=255)
    inner = m_at(0, -inset) if not pts else shape_mask(im.size, pts=pts(SS, -inset))
    dome = ImageChops.multiply(dome, inner)
    fade = Image.new("L", im.size, 0)
    fd = ImageDraw.Draw(fade)
    for y in range(int(box[1]), int(box[1] + bh * 0.46)):
        t = (y - box[1]) / (bh * 0.44)
        fd.line([(0, y), (W, y)], fill=int(max(0, 0.58 * (1 - t * 0.85)) * 255))
    dome = ImageChops.multiply(dome, fade)
    im.alpha_composite(Image.merge("RGBA", (Image.new("L", im.size, 255),) * 3 + (dome,)))
    # the rim: a bright line on the body's edge
    edge = ImageChops.subtract(body, m_at(0, -1.5 * SS) if not pts else shape_mask(im.size, pts=pts(SS, -1.5 * SS)))
    im.alpha_composite(Image.merge("RGBA", tuple(Image.new("L", im.size, c) for c in rim[:3]) + (edge,)))
    # a corner glint: a small four-point star at the upper left
    d = ImageDraw.Draw(im)
    gx, gy, g = box[0] + R * 0.62 + 2 * SS, box[1] + R * 0.5 + 2.4 * SS, 3.2 * SS
    if pts: gx, gy = W * 0.36, Hh * 0.2
    d.polygon([(gx, gy - g), (gx + g * 0.24, gy - g * 0.24), (gx + g, gy), (gx + g * 0.24, gy + g * 0.24), (gx, gy + g), (gx - g * 0.24, gy + g * 0.24), (gx - g, gy), (gx - g * 0.24, gy - g * 0.24)], fill=(255, 255, 255, 240))
    return im.resize((w, h), Image.LANCZOS)


def save(name, im):
    im.save(out / (name + ".png"))
    done.append(name)


# buttons, 160 x 100 (9-slice 42, 40, 118, 52): one jewel tone each
for n, (t, b, r) in {"mint": ("#3fe0b0", "#0e7a62", "#b8ffe8"), "pink": ("#ff5aa8", "#a01058", "#ffb0d6"), "lilac": ("#9a6cf6", "#4b1c71", "#e0b0ff"),
                     "butter": ("#ffbe3a", "#b05e08", "#fff0b0"), "sky": ("#3cc8ff", "#1260c0", "#b0f4ff"), "off": ("#7a6e98", "#3a3052", "#c4b8de")}.items():
    save(n, jelly((160, 100), H(t), H(b), H(r), radius=18, lip=7))
# pills, 176 x 80 (and 176 x 76): deep violet jelly, the rim says which
for n, (r, hgt) in {"pill": ("#e0b0ff", 76), "pillButter": ("#ffd66b", 80), "pillLilac": ("#e0b0ff", 80), "pillMint": ("#00f0ff", 80), "pillPink": ("#ff4fa0", 80)}.items():
    save(n, jelly((176, hgt), H("#4b1c71"), H("#241138"), H(r), alpha=236, radius=22, lip=5))


def hexpts(n, lip):
    def pts(ss, grow=0):
        cx, cy, r = n * ss / 2, (n - lip) * ss / 2, (n / 2 - 9) * ss + grow
        return [(cx + r * math.cos(math.radians(60 * i)), cy + r * math.sin(math.radians(60 * i)) * 0.98) for i in range(6)]
    return pts


save("hex", jelly((128, 128), H("#5a2a8c"), H("#241138"), H("#e0b0ff"), alpha=236, lip=7, pts=hexpts(128, 7)))
save("hexOn", jelly((128, 128), H("#2aa8e0"), H("#123a8c"), H("#00f0ff"), alpha=244, lip=7, pts=hexpts(128, 7), lit=True))



def orb_shell(n=160):
    """The glass ball of a status orb as jelly: a clear middle (the liquid shows through), a bright lavender rim with a soft glow,
    a white dome crescent over the upper third, a thin light arc low inside, a small glint."""
    W = n * SS
    im = Image.new("RGBA", (W, W), CLEAR)
    c, r = W / 2, (n / 2 - 9) * SS
    glow = Image.new("L", (W, W), 0)
    ImageDraw.Draw(glow).ellipse((c - r - 3 * SS, c - r - 3 * SS, c + r + 3 * SS, c + r + 3 * SS), fill=120)
    hole = Image.new("L", (W, W), 0)
    ImageDraw.Draw(hole).ellipse((c - r, c - r, c + r, c + r), fill=255)
    glow = ImageChops.subtract(glow.filter(ImageFilter.GaussianBlur(3 * SS)), hole)
    im.alpha_composite(Image.merge("RGBA", tuple(Image.new("L", (W, W), v) for v in (224, 176, 255)) + (glow,)))
    d = ImageDraw.Draw(im)
    d.ellipse((c - r, c - r, c + r, c + r), outline=(36, 17, 56, 255), width=int(4.5 * SS))  # the dark body of the rim
    d.ellipse((c - r + 1.2 * SS, c - r + 1.2 * SS, c + r - 1.2 * SS, c + r - 1.2 * SS), outline=(236, 214, 255, 255), width=int(1.6 * SS))  # the lit rim
    ri = r - 5.5 * SS
    inner = Image.new("L", (W, W), 0)
    ImageDraw.Draw(inner).ellipse((c - ri, c - ri, c + ri, c + ri), fill=255)
    dome = Image.new("L", (W, W), 0)
    ImageDraw.Draw(dome).ellipse((c - ri * 0.86, c - ri * 0.98, c + ri * 0.86, c - ri * 0.12), fill=255)
    fade = Image.new("L", (W, W), 0)
    fd = ImageDraw.Draw(fade)
    for y in range(int(c - ri), int(c)):
        t = (y - (c - ri)) / (ri * 0.9)
        fd.line([(0, y), (W, y)], fill=int(max(0, 0.62 * (1 - t)) * 255))
    dome = ImageChops.multiply(ImageChops.multiply(dome, inner), fade)
    im.alpha_composite(Image.merge("RGBA", (Image.new("L", (W, W), 255),) * 3 + (dome,)))
    low = Image.new("L", (W, W), 0)  # a thin light arc low inside the glass
    ld = ImageDraw.Draw(low)
    ld.arc((c - ri * 0.9, c - ri * 0.9, c + ri * 0.9, c + ri * 0.9), 35, 145, fill=110, width=int(2.2 * SS))
    im.alpha_composite(Image.merge("RGBA", (Image.new("L", (W, W), 255),) * 3 + (low.filter(ImageFilter.GaussianBlur(1.2 * SS)),)))
    gx, gy, g = c - ri * 0.48, c - ri * 0.56, 4.2 * SS
    d = ImageDraw.Draw(im)
    d.polygon([(gx, gy - g), (gx + g * 0.24, gy - g * 0.24), (gx + g, gy), (gx + g * 0.24, gy + g * 0.24), (gx, gy + g), (gx - g * 0.24, gy + g * 0.24), (gx - g, gy), (gx - g * 0.24, gy - g * 0.24)], fill=(255, 255, 255, 245))
    return im.resize((n, n), Image.LANCZOS)


save("orbShell", orb_shell())

sheet = Image.new("RGBA", (1240, 420), (0, 0, 0, 255))
sheet.alpha_composite(vgrad(sheet.size, H("#1a0f2a"), H("#3a5a4a"), 0, 420))
x, y, rowh = 20, 20, 0
for n in done:
    im = Image.open(out / (n + ".png"))
    if x + im.size[0] > 1220: x, y, rowh = 20, y + rowh + 16, 0
    sheet.alpha_composite(im, (x, y))
    x += im.size[0] + 16
    rowh = max(rowh, im.size[1])
sheet.convert("RGB").save(out / "_sheet.jpg", quality=92)
print("jelly pieces:", len(done), done)
