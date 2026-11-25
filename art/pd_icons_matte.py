"""Unified matte-enamel icon suite (Master Directive v16 phase 2, 2026-11-24; vault Research/3D and Art/Pet Models and Icon Craft
Audit (2026-11-24).md section 4). One pipeline replaces icons_notebook / icons_soft / icons_jelly / icons_jelly2 so every HUD,
hotbar, quest and forge icon matches Config.UI_TEXT = "flat" and Config.UI_SKIN = "matte".
The look (sheet_2_icons_ui: Moonlighter, Forager, Core Keeper, Nova Lands; @omelpixela's 4-step value ramp):
  * one deep-plum keyline (#161024), 11 px at 256 (about 2.75 px at 64) round every silhouette
  * every part shaded with the same 4 steps: a cool plum-shifted shadow on its lower right, the clean base, a warm lighter
    chamfer band on its upper left, and a tiny glint only on cut gems and metal rims. No gloss domes, no gradients
  * tools drawn bold at 45 degrees with oversized heads
Drawn as vector masks at 1024 px and downsampled to 256 px RGBA.
    python art/pd_icons_matte.py [name ...]      -> art/icons_matte/<name>.png, art/icons_matte/_grade_sheet.png"""
import math, os, sys
from PIL import Image, ImageDraw, ImageChops, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "icons_matte")
S = 1024          # drawing size
K = S / 256       # one output pixel in drawing pixels
KEY = (0x16, 0x10, 0x24, 255)
KEYW = 14 * K     # keyline width (14 px at 256, about 2 px at 32)
HALO = (0x5e, 0x4c, 0x8a, 255)  # a lighter plum ring just outside the keyline


def hx(h):
    h = h.lstrip("#"); return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def mix(a, b, t):
    return tuple(int(round(x + (y - x) * t)) for x, y in zip(a, b))


# materials: base colour -> the 4-step ramp (shadow toward plum, light toward warm cream, glint)
MAT = {k: hx(v) for k, v in {
    "gold": "#e8b43a", "steel": "#9aa6c0", "iron": "#6e7490", "wood": "#bb7a42", "leather": "#a0643a", "ruby": "#e0386a",
    "teal": "#3cc8b4", "sky": "#58a8ff", "green": "#5cb85a", "moss": "#7ac04a", "bone": "#efe6d2", "paper": "#f2e8d0",
    "red": "#e2483e", "violet": "#9a5ae0", "plum": "#4a3a6e", "orange": "#f08a2e", "pink": "#ff8ab0", "white": "#f4f2fa",
    "flame": "#ffb13a", "ember": "#ff6a2a", "cream": "#ffe7b0", "clay": "#c87a52", "slate": "#6a6488", "mint": "#7ae0b0",
}.items()}
PLUM, WARM = hx("#2a1840"), hx("#fff4d8")


def ramp(m):
    base = MAT[m]
    return {"shadow": mix(base, PLUM, 0.38), "base": base, "light": mix(base, WARM, 0.42), "glint": mix(base, (255, 255, 255), 0.85)}


# ---------------------------------------------------------------- shape helpers (all in 0..256 units, scaled by K)
def P(pts): return [(x * K, y * K) for x, y in pts]


def rot(pts, ang, c=(128, 128)):
    ca, sa = math.cos(math.radians(ang)), math.sin(math.radians(ang))
    return [(c[0] + (x - c[0]) * ca - (y - c[1]) * sa, c[1] + (x - c[0]) * sa + (y - c[1]) * ca) for x, y in pts]


def circle_pts(cx, cy, r, n=48, a0=0, a1=360, ry=None):
    ry = r if ry is None else ry
    return [(cx + r * math.cos(math.radians(a0 + (a1 - a0) * i / n)), cy + ry * math.sin(math.radians(a0 + (a1 - a0) * i / n))) for i in range(n + 1)]


def rrect(x0, y0, x1, y1, r, n=8):
    pts = []
    for cx, cy, a in ((x1 - r, y0 + r, -90), (x1 - r, y1 - r, 0), (x0 + r, y1 - r, 90), (x0 + r, y0 + r, 180)):
        pts += circle_pts(cx, cy, r, n, a, a + 90)
    return pts


def capsule(a, b, r, n=10):
    ang = math.degrees(math.atan2(b[1] - a[1], b[0] - a[0]))
    return circle_pts(b[0], b[1], r, n, ang - 90, ang + 90) + circle_pts(a[0], a[1], r, n, ang + 90, ang + 270)


def star_pts(cx, cy, r0, r1, n=5, a0=-90):
    return [(cx + (r0 if i % 2 == 0 else r1) * math.cos(math.radians(a0 + i * 180 / n)), cy + (r0 if i % 2 == 0 else r1) * math.sin(math.radians(a0 + i * 180 / n))) for i in range(n * 2)]


def dilate(m, px):
    """grow a mask by about px pixels with repeated 9x9 max filters (one big MaxFilter is O(k^2) and took minutes)"""
    n = max(1, int(round(px / 4)))
    for _ in range(n): m = m.filter(ImageFilter.MaxFilter(9))
    return m


def mask(pts):
    m = Image.new("L", (S, S), 0); ImageDraw.Draw(m).polygon(P(pts), fill=255); return m


class Icon:
    """layers drawn in order: each a polygon in a material; shading comes from the layer's own mask (the 4-step ramp)"""
    def __init__(self):
        self.layers = []   # (mask, material, bevel)
        self.lines = []    # detail strokes (pts, width, colour key: "key" or material step)
        self.glints = []

    def part(self, pts, mat, bevel=9, light=True):
        self.layers.append((mask(pts), mat, bevel, light)); return self

    def ell(self, cx, cy, rx, ry, mat, bevel=9):
        return self.part(circle_pts(cx, cy, rx, 56, ry=ry), mat, bevel)

    def line(self, pts, w=4, col="key"):
        self.lines.append((pts, w, col)); return self

    def glint(self, pts):
        self.glints.append(pts); return self

    def render(self):
        img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
        union = Image.new("L", (S, S), 0)
        for m, _, _, _ in self.layers: union = ImageChops.lighter(union, m)
        # the keyline: the whole silhouette grown by KEYW, in deep plum, under everything
        key = dilate(union, KEYW)
        halo = dilate(key, 5 * K)
        # holes: background the silhouette encloses (not reachable from the border)
        inv = union.point(lambda a: 255 if a < 128 else 0)
        outside = inv.copy(); ImageDraw.floodfill(outside, (0, 0), 128)
        holes = outside.point(lambda a: 255 if a == 255 else 0)
        if holes.getbbox():
            keep = holes.filter(ImageFilter.MinFilter(9))
            for _ in range(max(1, int(KEYW * 0.4 / 4)) - 1): keep = keep.filter(ImageFilter.MinFilter(9))
            key = ImageChops.subtract(key, keep); halo = ImageChops.subtract(halo, keep)
        img.paste(Image.new("RGBA", (S, S), HALO), (0, 0), halo)
        img.paste(Image.new("RGBA", (S, S), KEY), (0, 0), key)
        for m, mat, bev, light in self.layers:
            r = ramp(mat)
            d = int(bev * K)
            img.paste(Image.new("RGBA", (S, S), r["shadow"] + (255,)), (0, 0), m)
            # base: the mask moved up-left leaves the shadow rim on the lower right
            base = ImageChops.multiply(m, ImageChops.offset(m, -d, -d))
            img.paste(Image.new("RGBA", (S, S), r["base"] + (255,)), (0, 0), base)
            if light:  # the warm chamfer band on the upper left: inside the mask but not inside the mask moved down-right
                band = ImageChops.subtract(m, ImageChops.offset(m, int(d * 0.6), int(d * 0.6)))
                band = ImageChops.multiply(band, ImageChops.offset(m, -d // 3, -d // 3))
                img.paste(Image.new("RGBA", (S, S), r["light"] + (255,)), (0, 0), band)
            # a thin keyline between overlapping parts keeps each part readable
            edge = ImageChops.subtract(dilate(m, 3 * K), m)
            img.paste(Image.new("RGBA", (S, S), KEY), (0, 0), ImageChops.multiply(edge, union))
        dr = ImageDraw.Draw(img)
        for pts, w, col in self.lines:
            c = KEY if col == "key" else ramp(col[0])[col[1]] + (255,)
            dr.line(P(pts), fill=c, width=int(w * K), joint="curve")
        for pts in self.glints:
            dr.polygon(P(pts), fill=(255, 255, 250, 255))
        return img.resize((256, 256), Image.LANCZOS)


ICONS = {}


def icon(name):
    def deco(fn): ICONS[name] = fn; return fn
    return deco


# ---------------------------------------------------------------- tools at 45 degrees
def tool(handle_mat="wood"):
    ic = Icon()
    h = rot([(122, 120), (134, 120), (134, 236), (122, 236)], 45)
    ic.part(capsule((70, 194), (176, 88), 13), handle_mat, 7)
    ic.line([(84, 180), (98, 166)], 6, (handle_mat, "shadow"))
    return ic


@icon("pick")
def _pick():
    ic = Icon()
    ic.part(capsule((44, 214), (168, 90), 14), "wood", 7)
    ic.line([(64, 194), (78, 180)], 4, ("wood", "shadow")); ic.line([(84, 174), (98, 160)], 4, ("wood", "shadow"))
    head = [(92, 54), (124, 50), (164, 60), (204, 80), (232, 112), (238, 140), (214, 120), (184, 102), (164, 98), (150, 112), (132, 98), (110, 82), (82, 74), (62, 76)]
    ic.part(head, "steel", 10)
    ic.part(rot(rrect(140, 74, 180, 112, 7), 45, (160, 93)), "iron", 6)
    return ic


@icon("hammer")
def _hammer():
    ic = Icon()
    ic.part(capsule((44, 214), (156, 102), 15), "wood", 7)
    ic.line([(64, 194), (78, 180)], 4, ("wood", "shadow"))
    head = rot(rrect(104, 40, 236, 112, 14), 45, (170, 76))
    ic.part(head, "iron", 12)
    ic.part(rot(rrect(126, 46, 146, 106, 4), 45, (170, 76)), "steel", 5)
    ic.part(rot(rrect(194, 46, 214, 106, 4), 45, (170, 76)), "steel", 5)
    return ic


@icon("chisel")
def _chisel():
    ic = Icon()
    ic.part(capsule((56, 204), (120, 140), 24), "wood", 9)
    ic.part(rot([(108, 112), (160, 112), (166, 30), (134, 6), (102, 30)], 45, (134, 112)), "steel", 12)
    ic.part(rot(rrect(110, 106, 158, 124, 5), 45, (134, 112)), "gold", 6)
    ic.line([(80, 180), (110, 150)], 4, ("wood", "shadow"))
    return ic


@icon("coin")
def _coin():
    ic = Icon()
    ic.ell(128, 136, 92, 92, "gold", 14)
    ic.ell(128, 136, 62, 62, "gold", 9)
    ic.part(star_pts(128, 136, 40, 18), "cream", 6)
    return ic


@icon("gem")
def _gem():
    ic = Icon()
    ic.part([(70, 70), (186, 70), (228, 122), (128, 228), (28, 122)], "ruby", 16)
    ic.part([(96, 70), (160, 70), (176, 122), (128, 196), (80, 122)], "ruby", 8)
    for pts in ([(28, 122), (228, 122)], [(70, 70), (80, 122), (128, 228)], [(186, 70), (176, 122), (128, 228)], [(96, 70), (80, 122)], [(160, 70), (176, 122)]):
        ic.line(pts, 3.5)
    ic.glint([(84, 84), (110, 80), (92, 108)])
    return ic


@icon("surface")
def _surface():
    ic = Icon()
    # one idea: a big up arrow rising out of a dark cave mouth onto the grass line (icons_r2: the hoist cage was noise at 32 px)
    ic.part(rrect(20, 168, 236, 232, 16), "moss", 10)
    ic.part(circle_pts(128, 232, 96, 30, 180, 360), "plum", 6)
    ic.part([(128, 20), (214, 112), (162, 112), (162, 200), (94, 200), (94, 112), (42, 112)], "mint", 14)
    return ic


@icon("sonar")
def _sonar():
    ic = Icon()
    # a handheld pinger and two thick ping arcs with wide gaps (icons_r3: three thin arcs were noise)
    ic.part([(40, 176), (82, 134), (106, 158), (64, 200)], "iron", 8)
    ic.ell(80, 168, 40, 40, "steel", 12)
    ic.ell(80, 168, 16, 16, "sky", 5)
    for r, th in ((82, 26), (150, 28)):
        pts = circle_pts(80, 168, r + th, 26, -84, -6) + list(reversed(circle_pts(80, 168, r, 26, -84, -6)))
        ic.part(pts, "teal", 8)
    return ic


@icon("gear")
def _gear():
    ic = Icon()
    pts = []
    for i in range(8):
        a = i * 45
        for da, r in ((-15, 78), (-9, 104), (9, 104), (15, 78)):
            pts.append((128 + r * math.cos(math.radians(a + da)), 128 + r * math.sin(math.radians(a + da))))
    ic.part(pts, "gold", 12)
    ic.ell(128, 128, 54, 54, "gold", 8)
    ic.ell(128, 128, 26, 26, "plum", 6)
    return ic


@icon("skull")
def _skull():
    ic = Icon()
    ic.part(circle_pts(128, 110, 84, 48, 160, 380) + [(196, 150), (182, 176), (166, 182), (166, 214), (90, 214), (90, 182), (74, 176), (60, 150)], "bone", 14)
    ic.ell(96, 128, 22, 26, "plum", 4); ic.ell(160, 128, 22, 26, "plum", 4)
    ic.part([(128, 150), (140, 172), (116, 172)], "plum", 3)
    for x in (110, 128, 146): ic.line([(x, 188), (x, 212)], 4)
    return ic


@icon("boot")
def _boot():
    ic = Icon()
    # a winged speed boot: the ankle, a long toe, a thick sole, and a wing that stands clear of the shaft
    ic.part([(66, 40), (134, 40), (138, 146), (214, 164), (224, 204), (44, 204), (56, 146)], "leather", 13)
    ic.part(rrect(36, 194, 230, 226, 8), "iron", 7)
    ic.part(rrect(58, 34, 142, 64, 8), "leather", 7)
    ic.part([(156, 54), (232, 20), (220, 52), (240, 60), (210, 90), (156, 92)], "white", 8)
    ic.part(rrect(70, 98, 128, 112, 5), "gold", 4)
    return ic


@icon("root")
def _root():
    ic = Icon()
    # a big forked root: one thick light trunk splitting into three bold roots, a sprout on top
    ic.part(capsule((128, 70), (128, 150), 30), "wood", 12)
    ic.part(capsule((128, 140), (54, 222), 22), "wood", 10)
    ic.part(capsule((128, 140), (202, 222), 22), "wood", 10)
    ic.part(capsule((128, 150), (128, 232), 20), "wood", 9)
    ic.part([(124, 70), (84, 24), (60, 52), (96, 76)], "moss", 8)
    ic.part([(132, 70), (172, 18), (200, 46), (160, 76)], "moss", 8)
    return ic


@icon("bag")
def _bag():
    ic = Icon()
    # a satchel with a tall carry handle: its open loop survives the keyline at 32 px
    ic.part(circle_pts(128, 76, 68, 30, 180, 360) + [(196, 124), (168, 124)] + list(reversed(circle_pts(128, 76, 40, 30, 180, 360))) + [(88, 124), (60, 124)], "leather", 6)
    ic.part(rrect(28, 114, 228, 234, 22), "leather", 14)
    ic.part(rrect(28, 114, 228, 168, 22), "clay", 8)
    ic.part(rrect(108, 148, 148, 188, 8), "gold", 6)
    return ic


@icon("crew")
def _crew():
    ic = Icon()
    # one big miner's face under a lamp helmet (icons_r3: two figures at 32 px were mud)
    ic.part(rrect(48, 170, 208, 236, 30), "sky", 10)  # shoulders
    ic.ell(128, 136, 72, 70, "cream", 12)
    ic.part(circle_pts(128, 120, 84, 30, 180, 360) + [(212, 126), (44, 126)], "gold", 10)
    ic.part(rrect(36, 112, 220, 134, 10), "orange", 6)  # the brim
    ic.ell(128, 66, 24, 20, "white", 6)  # the lamp
    for x in (102, 154): ic.ell(x, 160, 10, 14, "plum", 2)
    ic.line([(110, 192), (128, 200), (146, 192)], 7)
    return ic


@icon("egg")
def _egg():
    ic = Icon()
    pts = []
    for a in range(0, 361, 8):
        ca, sa = math.cos(math.radians(a)), math.sin(math.radians(a))
        pts.append((128 + 80 * sa * (1 - 0.12 * ca), 140 - 96 * ca * (1.0 if ca > 0 else 0.86)))
    ic.part(pts, "cream", 14)
    ic.part([(56, 144), (90, 124), (118, 150), (148, 122), (178, 148), (202, 132), (204, 160), (178, 172), (148, 150), (118, 178), (90, 152), (54, 170)], "teal", 6)
    return ic


@icon("star")
def _star():
    ic = Icon()
    ic.part(star_pts(128, 134, 104, 48), "gold", 14)
    return ic


@icon("dice")
def _dice():
    ic = Icon()
    # lit from the upper left like the rest of the set: top lightest, left face lit, right face in shadow
    ic.part([(128, 26), (222, 76), (222, 180), (128, 230), (34, 180), (34, 76)], "white", 8)
    ic.part([(128, 26), (222, 76), (128, 126), (34, 76)], "white", 4)
    ic.part([(222, 76), (128, 126), (128, 230), (222, 180)], "slate", 4)
    for x, y in ((128, 76), (90, 152), (66, 124), (166, 146), (190, 112), (178, 182)):
        ic.ell(x, y, 12, 10, "plum", 2)
    return ic


@icon("map")
def _map():
    ic = Icon()
    ic.part([(28, 60), (96, 36), (160, 60), (228, 36), (228, 196), (160, 220), (96, 196), (28, 220)], "paper", 10)
    ic.part([(96, 36), (160, 60), (160, 220), (96, 196)], "cream", 4)
    ic.line([(52, 172), (82, 140), (112, 150), (146, 110), (176, 118)], 9, ("red", "base"))
    ic.line([(180, 88), (214, 122)], 9)
    ic.line([(214, 88), (180, 122)], 9)
    return ic


@icon("camp")
def _camp():
    ic = Icon()
    ic.part([(128, 30), (226, 206), (30, 206)], "orange", 14)
    ic.part([(128, 30), (164, 206), (92, 206)], "clay", 6)
    ic.part([(128, 118), (152, 206), (104, 206)], "plum", 4)
    ic.part(rrect(22, 198, 234, 222, 8), "wood", 6)
    ic.line([(128, 30), (128, 12)], 5)
    ic.part([(128, 12), (164, 22), (128, 32)], "flame", 4)
    return ic


@icon("lock")
def _lock():
    ic = Icon()
    # a tall shackle so its open loop survives the keyline at 32 px (icons_r2: the loop was plugged)
    outer = circle_pts(128, 84, 64, 30, 180, 360) + [(192, 140), (164, 140)]
    inner = list(reversed(circle_pts(128, 84, 36, 30, 180, 360)))
    ic.part(outer + inner + [(92, 140), (64, 140)], "steel", 8)
    ic.part(rrect(44, 126, 212, 234, 22), "gold", 14)
    ic.ell(128, 168, 18, 18, "plum", 3)
    ic.part([(119, 174), (137, 174), (143, 210), (113, 210)], "plum", 3)
    return ic


@icon("shirt")
def _shirt():
    ic = Icon()
    ic.part([(84, 36), (104, 50), (152, 50), (172, 36), (232, 76), (206, 124), (184, 110), (184, 222), (72, 222), (72, 110), (50, 124), (24, 76)], "teal", 14)
    ic.part([(104, 50), (128, 82), (152, 50)], "cream", 4)
    ic.part(rrect(112, 140, 144, 172, 6), "gold", 5)
    return ic


@icon("pin")
def _pin():
    ic = Icon()
    ic.part(circle_pts(128, 100, 74, 40, 150, 390) + [(128, 232)], "red", 14)
    ic.ell(128, 100, 30, 30, "cream", 6)
    return ic


@icon("chest")
def _chest():
    ic = Icon()
    ic.part(rrect(30, 104, 226, 222, 12), "wood", 12)
    ic.part(circle_pts(128, 112, 98, 30, 180, 360, ry=60), "wood", 10)
    for x in (54, 202): ic.part(rrect(x - 12, 56, x + 12, 222, 4), "gold", 6)
    ic.part(rrect(30, 104, 226, 124, 6), "gold", 6)
    ic.part(rrect(110, 112, 146, 160, 8), "gold", 8)
    ic.ell(128, 134, 7, 9, "plum", 2)
    return ic


@icon("book")
def _book():
    ic = Icon()
    # a closed spellbook (icons_r3: thin page lines turned to haze): bold cover, page block, a gold gem clasp and ribbon
    ic.part(rrect(54, 30, 214, 226, 14), "red", 14)
    ic.part(rrect(196, 44, 224, 214, 6), "paper", 6)
    ic.part(rrect(40, 30, 76, 226, 10), "plum", 6)
    ic.part(star_pts(136, 122, 46, 20, n=4), "gold", 8)
    ic.ell(136, 122, 14, 14, "teal", 4)
    ic.part([(150, 210), (174, 210), (174, 246), (162, 234), (150, 246)], "gold", 5)
    return ic


@icon("kiln")
def _kiln():
    ic = Icon()
    ic.part([(30, 226), (56, 120), (88, 70), (168, 70), (200, 120), (226, 226)], "clay", 14)  # a flared dome kiln
    ic.part(rrect(150, 22, 188, 86, 6), "clay", 6)  # the chimney, off-centre
    ic.part(rrect(144, 16, 194, 32, 6), "iron", 4)
    ic.part(circle_pts(128, 176, 52, 24, 180, 360) + [(180, 226), (76, 226)], "plum", 4)  # the arched firebox
    ic.part([(98, 222), (110, 186), (124, 204), (136, 170), (150, 200), (160, 222)], "flame", 4)
    for y in (106, 134): ic.line([(66, y), (190, y)], 4, ("clay", "shadow"))
    return ic


@icon("gift")
def _gift():
    ic = Icon()
    ic.part(rrect(42, 108, 214, 224, 10), "pink", 12)
    ic.part(rrect(30, 80, 226, 116, 8), "pink", 8)
    ic.part(rrect(114, 80, 142, 224, 4), "gold", 5)
    ic.part([(128, 82), (82, 36), (62, 58), (92, 82)], "gold", 5)
    ic.part([(128, 82), (174, 36), (194, 58), (164, 82)], "gold", 5)
    return ic


@icon("home")
def _home():
    ic = Icon()
    ic.part([(128, 26), (232, 116), (204, 116), (204, 222), (52, 222), (52, 116), (24, 116)], "clay", 14)
    ic.part([(128, 26), (232, 116), (24, 116)], "red", 8)
    ic.part(rrect(106, 150, 150, 222, 8), "wood", 6)
    ic.part(rrect(160, 134, 188, 162, 4), "flame", 4)
    return ic


@icon("trophy")
def _trophy():
    ic = Icon()
    # loop handles with real holes, a deep cup, a short stem and a plinth
    for sx in (-1, 1):
        cx = 128 + sx * 84
        ic.part(circle_pts(cx, 88, 40, 30) + list(reversed(circle_pts(cx, 88, 18, 30))), "gold", 6)
    ic.part(circle_pts(128, 52, 76, 30, 0, 180, ry=104) + [(52, 52)], "gold", 14)
    ic.part(rrect(110, 150, 146, 188, 4), "gold", 6)
    ic.part(rrect(66, 186, 190, 226, 8), "wood", 8)
    ic.part(star_pts(128, 96, 28, 12), "cream", 4)
    return ic


@icon("stopwatch")
def _stopwatch():
    ic = Icon()
    ic.part(rrect(110, 18, 146, 44, 6), "steel", 5)
    ic.ell(128, 142, 90, 90, "steel", 14)
    ic.ell(128, 142, 70, 70, "white", 6)
    ic.line([(128, 142), (128, 92)], 8)
    ic.line([(128, 142), (164, 160)], 8)
    ic.ell(128, 142, 8, 8, "red", 2)
    return ic


@icon("cart")
def _cart():
    ic = Icon()
    for x, m in ((84, "gold"), (124, "teal"), (164, "ruby")):
        ic.part([(x - 24, 92), (x - 10, 58), (x + 14, 52), (x + 24, 92)], m, 7)
    ic.part([(36, 92), (220, 92), (196, 192), (60, 192)], "iron", 12)
    ic.part(rrect(26, 84, 230, 104, 6), "slate", 6)
    ic.ell(80, 204, 22, 22, "steel", 6)
    ic.ell(176, 204, 22, 22, "steel", 6)
    return ic


@icon("spore")
def _spore():
    ic = Icon()
    ic.part(rrect(102, 128, 154, 224, 14), "cream", 8)
    ic.part(circle_pts(128, 132, 100, 30, 180, 360, ry=92) + [(228, 140), (28, 140)], "violet", 14)
    for x, y, r in ((88, 92, 16), (150, 68, 14), (184, 110, 12), (120, 116, 10)): ic.ell(x, y, r, r, "pink", 3)
    return ic


@icon("scroll")
def _scroll():
    ic = Icon()
    ic.part(rrect(54, 48, 202, 208, 10), "paper", 12)
    ic.part(rrect(36, 30, 220, 62, 14), "wood", 8)
    ic.part(rrect(36, 196, 220, 228, 14), "wood", 8)
    for y in (96, 132, 168): ic.line([(80, y), (176, y)], 8, ("paper", "shadow"))
    return ic


@icon("pouch")
def _pouch():
    ic = Icon()
    body = []
    for a in range(0, 361, 10):
        ca, sa = math.cos(math.radians(a)), math.sin(math.radians(a))
        body.append((128 + 90 * sa, 160 + 68 * ca * (1 if ca > 0 else 0.7)))
    ic.part(body, "leather", 14)
    ic.part([(96, 98), (160, 98), (182, 50), (150, 70), (128, 40), (106, 70), (74, 50)], "leather", 8)  # the gathered top
    ic.part(rrect(88, 90, 168, 114, 10), "gold", 6)  # the cinch
    ic.part(star_pts(128, 170, 34, 15), "gold", 6)
    return ic


@icon("check")
def _check():
    ic = Icon()
    ic.part([(30, 132), (72, 92), (110, 132), (196, 40), (236, 82), (110, 210)], "mint", 14)
    return ic


@icon("heart")
def _heart():
    ic = Icon()
    pts = []
    for i in range(60):
        t = i / 60 * math.tau
        pts.append((128 + 100 * math.sin(t) ** 3, 124 - 100 * (13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t)) / 17))
    ic.part(pts, "red", 14)
    return ic


@icon("torch")
def _torch():
    ic = Icon()
    ic.part(capsule((58, 222), (140, 120), 20), "wood", 8)
    ic.part(rot(rrect(118, 84, 184, 132, 8), 45, (151, 108)), "iron", 8)
    ic.part([(150, 100), (128, 62), (150, 18), (170, 50), (206, 26), (214, 74), (184, 112)], "flame", 11)
    ic.part([(160, 94), (154, 62), (170, 50), (188, 80)], "cream", 5)
    ic.line([(84, 196), (102, 178)], 4, ("wood", "shadow"))
    return ic


@icon("flare")
def _flare():
    ic = Icon()
    # a red signal flare held at 45 degrees like the other tools, a white-hot star burst at its tip
    ic.part(capsule((52, 214), (148, 118), 24), "red", 11)
    ic.part(rot(rrect(84, 168, 124, 186, 4), -45, (104, 177)), "cream", 4)
    ic.part(star_pts(176, 82, 66, 28, n=8, a0=-67), "flame", 10)
    ic.ell(176, 82, 26, 26, "white", 6)
    return ic


def _face(kind):
    ic = Icon()
    col = {"calm": "mint", "uneasy": "flame", "scared": "bone", "happy": "gold", "curious": "sky", "greedy": "orange", "hurt": "red", "proud": "orange", "sleepy": "steel"}[kind]
    ic.ell(128, 128, 104, 104, col, 14)
    ic.ell(128, 136, 78, 76, "cream", 8)
    if kind in ("calm", "sleepy"):
        for x in (98, 158): ic.line([(x - 16, 124), (x, 132), (x + 16, 124)], 7)
    elif kind in ("happy", "proud"):
        for x in (98, 158): ic.line([(x - 15, 130), (x, 116), (x + 15, 130)], 7)
    elif kind == "greedy":
        for x in (98, 158):
            ic.part(star_pts(x, 124, 26, 12), "plum", 3)
            ic.part(star_pts(x, 124, 17, 8), "cream", 3)
    else:
        ic.ell(98, 124, 11, 15, "plum", 2)
        ic.ell(158, 124, 11, 15, "plum", 2)
    if kind == "scared":
        ic.line([(80, 102), (112, 92)], 6); ic.line([(176, 102), (144, 92)], 6)
    elif kind in ("uneasy", "hurt"):
        ic.line([(76, 96), (112, 108)], 6); ic.line([(180, 96), (144, 108)], 6)
    if kind in ("happy", "proud", "greedy"): ic.part(circle_pts(128, 158, 32, 20, 0, 180), "plum", 3)
    elif kind == "calm": ic.line([(104, 166), (128, 176), (152, 166)], 7)
    elif kind == "curious": ic.ell(128, 170, 12, 14, "plum", 2)
    elif kind == "sleepy":
        ic.line([(112, 170), (144, 170)], 7)
        ic.line([(150, 76), (176, 76), (150, 102), (176, 102)], 8)
    elif kind == "uneasy": ic.line([(100, 172), (116, 164), (132, 172), (148, 164), (160, 170)], 6)
    elif kind == "scared": ic.ell(128, 172, 18, 22, "plum", 2)
    elif kind == "hurt":
        ic.line([(104, 174), (128, 162), (152, 174)], 7)
        ic.ell(176, 150, 10, 16, "sky", 2)
    if kind == "proud": ic.part(star_pts(200, 52, 24, 10), "gold", 3)
    return ic


def _mk(k):
    return lambda: _face(k)


for _k in ("calm", "uneasy", "scared"):
    ICONS[_k] = _mk(_k)
for _k in ("calm", "curious", "greedy", "happy", "hurt", "proud", "scared", "sleepy"):
    ICONS["face_" + _k] = _mk(_k)
ICONS["smile"] = _mk("happy")


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    names = sys.argv[1:] or list(ICONS)
    for n in names:
        ICONS[n]().render().save(os.path.join(OUT, n + ".png"))
        print("icon", n)
    # the verification sheet: 64 px, 32 px, 32 px silhouette per icon on dark HUD plum
    ALIASES = {"calm", "scared", "smile"}
    allp = sorted(f[:-4] for f in os.listdir(OUT) if f.endswith(".png") and not f.startswith("_") and f[:-4] not in ALIASES)
    cols = 4
    cw, ch = 3 * 64 + 4 * 12, 64 + 28
    rows = (len(allp) + cols - 1) // cols
    sheet = Image.new("RGB", (cols * cw, rows * ch), (0x1A, 0x13, 0x2B))
    d = ImageDraw.Draw(sheet)
    for i, n in enumerate(allp):
        im = Image.open(os.path.join(OUT, n + ".png")).convert("RGBA")
        x, y = (i % cols) * cw + 12, (i // cols) * ch + 6
        sheet.paste(im.resize((64, 64), Image.LANCZOS), (x, y), im.resize((64, 64), Image.LANCZOS))
        s32 = im.resize((32, 32), Image.LANCZOS)
        sheet.paste(s32, (x + 76, y + 16), s32)
        blk = Image.new("RGBA", (32, 32), (0, 0, 0, 255)); al = s32.split()[3]
        sheet.paste((0xD8, 0xD6, 0xDE), (x + 120, y + 16, x + 152, y + 48))
        sheet.paste(blk, (x + 120, y + 16), al.point(lambda a: 255 if a > 110 else 0))
        d.text((x, y + 66), n, fill=(210, 204, 224))
    sheet.save(os.path.join(OUT, "_grade_sheet.png"))
