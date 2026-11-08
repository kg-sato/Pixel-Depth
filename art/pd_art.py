"""Pixel Depths art source (Claude-authored, shown on the Claude Design board).
Makes the 32 px block textures, the voxel character renders and the Rootholm world scene.
Usage: python pd_art.py <out_dir>
Palette: "Twilight Hollow" pastels. Lights lean peach/cream, shadows lean lavender/plum (never grey or black)."""
import math, os, random, sys
from PIL import Image, ImageDraw

OUT = sys.argv[1] if len(sys.argv) > 1 else "out"
os.makedirs(OUT, exist_ok=True)


def H(h):
    return (int(h[1:3], 16), int(h[3:5], 16), int(h[5:7], 16))


def lerp(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3))


INK = H("#2a1c3a")
WARM = (255, 240, 222)
COOL = (52, 34, 82)


def shade(c, f):  # f > 1 warms toward cream, f < 1 cools toward plum
    return lerp(c, WARM, f - 1) if f >= 1 else lerp(c, COOL, 1 - f)


R = {  # ramps dark -> light
    "dirt": [H(h) for h in ("#3d2a45", "#5e3f55", "#7f5560", "#a2706a", "#c49482", "#e2b99c")],
    "dirt_deep": [H(h) for h in ("#2a1d36", "#3f2b48", "#583c55", "#74505f", "#916a70")],
    "cave": [H(h) for h in ("#1b1329", "#241935", "#2e2142", "#3a2a50", "#4a3760")],
    "pebble": [H(h) for h in ("#4b4566", "#7b74a0", "#aaa3cc", "#d6d0ee")],
    "root": [H(h) for h in ("#3f2a3c", "#5f4250", "#82605f", "#a8836f")],
    "moss": [H(h) for h in ("#2b6662", "#459985", "#6ec7a6", "#a6ead0", "#dafbec")],
    "copper": [H(h) for h in ("#7a3d3f", "#b9605a", "#e5906c", "#ffc196", "#fff0dd")],
    "coal": [H(h) for h in ("#1f1a33", "#342c55", "#4f4680", "#7a70b8", "#b9b0ee")],
    "gold": [H(h) for h in ("#8a5a2e", "#c98a3a", "#f2be55", "#ffe08a", "#fffbe6")],
    "egg": [H(h) for h in ("#7d6a86", "#b9a3b0", "#e2d0cc", "#f8ece2", "#ffffff")],
    "mint": [H(h) for h in ("#2f7f73", "#55b89d", "#8ce3c0", "#c6f7e2", "#f2fff9")],
    "lilac": [H(h) for h in ("#4a3b7a", "#6c5aa8", "#9a86d6", "#c9b8f2", "#efe6ff")],
    "rose": [H(h) for h in ("#8a3d5c", "#c25a7a", "#ff9db0", "#ffc9d4")],
    "wood": [H(h) for h in ("#4a2f36", "#6e4a45", "#93685a", "#b98a72")],
}
BAYER = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]


def pick(ramp, t, x, y, dither=0.08):
    t += (BAYER[y % 4][x % 4] / 16 - 0.47) * dither
    return ramp[max(0, min(len(ramp) - 1, int(t * len(ramp))))]


def hsh(x, y, s):
    h = (x * 374761393 + y * 668265263 + s * 2246822519) & 0xFFFFFFFF
    h = ((h ^ (h >> 13)) * 3266489917) & 0xFFFFFFFF
    return ((h ^ (h >> 16)) & 0xFFFF) / 65535.0


def vnoise(x, y, s, wrap=None):
    x0, y0 = math.floor(x), math.floor(y)
    fx, fy = x - x0, y - y0
    fx, fy = fx * fx * (3 - 2 * fx), fy * fy * (3 - 2 * fy)

    def g(i, j):
        if wrap:
            i, j = i % wrap, j % wrap
        return hsh(i, j, s)

    a, b, c, d = g(x0, y0), g(x0 + 1, y0), g(x0, y0 + 1), g(x0 + 1, y0 + 1)
    return (a * (1 - fx) + b * fx) * (1 - fy) + (c * (1 - fx) + d * fx) * fy


def fbm(u, v, s, base=4, octs=3, tile=True):
    tot = norm = 0
    amp = 1
    for o in range(octs):
        f = base * 2 ** o
        tot += amp * vnoise(u * f, v * f, s + o * 101, f if tile else None)
        norm += amp
        amp *= 0.5
    return tot / norm


def inside(px, py, pts):
    c = False
    j = len(pts) - 1
    for i in range(len(pts)):
        xi, yi = pts[i]
        xj, yj = pts[j]
        if (yi > py) != (yj > py) and px < (xj - xi) * (py - yi) / (yj - yi) + xi:
            c = not c
        j = i
    return c


def outline_mask(mask, w, h):
    edge = set()
    for (x, y) in mask:
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            if (x + dx, y + dy) not in mask and 0 <= x + dx < w and 0 <= y + dy < h:
                edge.add((x, y))
                break
    return edge


# ---------------------------------------------------------------- block textures (32 x 32)
N = 32


BEVEL = [True]  # make_textures(bevel=False) gives seamless rock for cave walls


def tex_dirt(seed, ramp=None, pebbles=6, roots=1, bevel=None, base=3):
    ramp = ramp or R["dirt"]
    bevel = BEVEL[0] if bevel is None else bevel
    im = [[None] * N for _ in range(N)]
    for y in range(N):
        for x in range(N):
            n = fbm(x / N, y / N, seed, base=base)
            n2 = fbm(x / N, y / N, seed + 7, base=8, octs=2)
            t = 0.12 + n * 0.55 + n2 * 0.3
            if bevel:
                t += {0: 0.3, 1: 0.12}.get(min(x, y), 0)
                t -= {N - 1: 0.42, N - 2: 0.16}.get(max(x, y), 0)
            im[y][x] = pick(ramp, t, x, y)
    rnd = random.Random(seed)
    rr = R["root"]
    for _ in range(roots):  # a thin root fibre wandering down
        x, y = rnd.randrange(4, N - 4), 2
        for _ in range(rnd.randrange(14, 24)):
            if 1 < x < N - 2 and 1 < y < N - 2:
                im[y][x] = rr[2]
                im[y + 1][x] = rr[0]
                if rnd.random() < 0.3:
                    im[y][x] = rr[3]
            y += 1 if rnd.random() < 0.7 else 0
            x += rnd.choice((-1, 0, 0, 1))
    pr = R["pebble"]
    for _ in range(pebbles):
        w, h = rnd.choice(((3, 2), (4, 3), (2, 2), (5, 3), (3, 3)))
        cx, cy = rnd.randrange(3, N - w - 3), rnd.randrange(3, N - h - 3)
        for yy in range(h):
            for xx in range(w):
                if w > 2 and h > 2 and xx in (0, w - 1) and yy in (0, h - 1):
                    continue
                c = pr[1]
                if yy == 0 or xx == 0:
                    c = pr[2]
                if yy == h - 1 or xx == w - 1:
                    c = pr[0]
                if xx == 1 and yy == 0 and w > 2:
                    c = pr[3]
                im[cy + yy][cx + xx] = c
        for xx in range(1, w + 1):
            im[cy + h][cx + xx] = ramp[0]
    return im


def to_img(im):
    out = Image.new("RGB", (len(im[0]), len(im)))
    px = out.load()
    for y, row in enumerate(im):
        for x, c in enumerate(row):
            px[x, y] = c
    return out


def glow_halo(im, cx, cy, r, col, amt=0.28):
    for y in range(N):
        for x in range(N):
            d = math.hypot(x - cx, y - cy)
            if d < r:
                step = 1 if d < r * 0.6 else 0.5  # stepped ring, not a smooth gradient
                im[y][x] = lerp(im[y][x], col, amt * step)


def crystal(im, bx, by, ang, L, Wd, ramp, outline=True):
    dx, dy = math.sin(ang), -math.cos(ang)
    px_, py_ = math.cos(ang), math.sin(ang)
    pts = [(bx - px_ * Wd / 2, by - py_ * Wd / 2), (bx + px_ * Wd / 2, by + py_ * Wd / 2),
           (bx + dx * L * 0.7 + px_ * Wd / 2, by + dy * L * 0.7 + py_ * Wd / 2), (bx + dx * L, by + dy * L),
           (bx + dx * L * 0.7 - px_ * Wd / 2, by + dy * L * 0.7 - py_ * Wd / 2)]
    mask = {}
    for y in range(N):
        for x in range(N):
            if inside(x + 0.5, y + 0.5, pts):
                rx, ry = x + 0.5 - bx, y + 0.5 - by
                side = rx * px_ + ry * py_
                along = rx * dx + ry * dy
                k = 2 if side < -Wd * 0.12 else (1 if side > Wd * 0.12 else 2)
                if side < -Wd * 0.12:
                    k = 3
                if along > L * 0.72:
                    k += 1
                mask[(x, y)] = ramp[min(k, len(ramp) - 1)]
    edge = outline_mask(mask, N, N) if outline else set()
    for (x, y), c in mask.items():
        im[y][x] = ramp[0] if (x, y) in edge else c
    tip = (int(bx + dx * L * 0.8 - px_ * Wd * 0.2), int(by + dy * L * 0.8 - py_ * Wd * 0.2))
    if tip in mask and tip not in edge:
        im[tip[1]][tip[0]] = ramp[-1]


def nugget(im, cx, cy, rx, ry, ramp, spots=None):
    L = (-0.55, -0.65, 0.52)
    mask = {}
    for y in range(N):
        for x in range(N):
            nx, ny = (x + 0.5 - cx) / rx, (y + 0.5 - cy) / ry
            r2 = nx * nx + ny * ny
            if r2 <= 1:
                nz = math.sqrt(1 - r2)
                d = max(0, nx * L[0] + ny * L[1] + nz * L[2])
                k = 1 + int(d * (len(ramp) - 1.4))
                mask[(x, y)] = ramp[min(k, len(ramp) - 1)]
    edge = outline_mask(mask, N, N)
    for (x, y), c in mask.items():
        im[y][x] = ramp[0] if (x, y) in edge else c
    for (sx, sy) in spots or ():
        if (sx, sy) in mask and (sx, sy) not in edge:
            im[sy][sx] = R["lilac"][1]
    sp = (int(cx - rx * 0.4), int(cy - ry * 0.45))
    if sp in mask:
        im[sp[1]][sp[0]] = ramp[-1]
    return mask


def sparkle(im, x, y, ramp):
    im[y][x] = ramp[-1]
    for ddx, ddy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        if 0 <= x + ddx < N and 0 <= y + ddy < N:
            im[y + ddy][x + ddx] = ramp[-2]


def make_textures(var=0, bevel=True):
    BEVEL[0] = bevel
    T = {}
    rv = random.Random(1000 + var)
    jit = lambda a: a + rv.randint(-2, 2)
    T["rootflint"] = tex_dirt(11 + var * 97, pebbles=rv.choice((2, 3, 4)), roots=1 if var == 3 else 0)
    g = tex_dirt(12 + var * 97, pebbles=2, roots=0)  # surface block: mint moss with hanging tufts and flowers
    rnd = random.Random(5)
    mr = R["moss"]
    for x in range(N):
        hgt = 7 + int(fbm(x / N, 0.3, 77, base=4) * 5)
        for y in range(hgt):
            t = 1 - y / hgt
            g[y][x] = pick(mr, 0.25 + t * 0.7, x, y, 0.12)
        g[hgt][x] = mr[0]
        if rnd.random() < 0.35:
            for k in range(rnd.randrange(1, 4)):
                if hgt + 1 + k < N:
                    g[hgt + 1 + k][x] = mr[1] if k == 0 else mr[0]
        g[0][x] = mr[4] if x % 3 else mr[3]
    for (fx, fy, col) in ((5, 2, R["rose"]), (17, 3, R["gold"]), (26, 2, R["rose"]), (11, 4, R["lilac"])):
        g[fy][fx] = col[-1]
        for ddx, ddy in ((1, 0), (-1, 0), (0, -1), (0, 1)):
            g[fy + ddy][fx + ddx] = col[-2]
        g[fy][fx] = R["gold"][3] if col is not R["gold"] else R["rose"][3]
    T["grass"] = g
    a = tex_dirt(21 + var * 97, pebbles=3, roots=0)
    glow_halo(a, 15, 17, 13, R["coal"][3], 0.18)
    for (bx, by, ang, L, Wd) in ((jit(9), 26, -0.5 + rv.uniform(-.2, .2), 13, 8), (jit(19), 25, 0.35 + rv.uniform(-.2, .2), 15, 9), (jit(15), 27, rv.uniform(-.2, .2), 9, 6)):
        crystal(a, bx, by, ang, L, Wd, R["coal"])
    T["ashcoal"] = a
    c = tex_dirt(31 + var * 97, pebbles=3, roots=0)
    glow_halo(c, 15, 17, 12, R["copper"][3], 0.2)
    nugget(c, jit(11), jit(19), 6.5, 5.5, R["copper"])
    nugget(c, jit(21), jit(12), 4.5, 4.0, R["copper"])
    nugget(c, jit(22), jit(24), 3.0, 2.6, R["copper"])
    T["copper"] = c
    gl = tex_dirt(41 + var * 97, pebbles=2, roots=0)
    glow_halo(gl, 16, 17, 15, R["gold"][3], 0.38)
    for (bx, by, ang, L, Wd) in ((10, 27, -0.45, 15, 8), (20, 27, 0.4, 17, 9), (15, 28, -0.05, 12, 7)):
        crystal(gl, bx, by, ang, L, Wd, R["gold"])
    for (sx, sy) in ((5, 6), (26, 9), (27, 22), (4, 21)):
        sparkle(gl, sx, sy, R["gold"])
    T["gilded"] = gl
    e = tex_dirt(51 + var * 97, pebbles=2, roots=0)
    glow_halo(e, 16, 16, 15, R["egg"][4], 0.22)
    em = nugget(e, 16, 16, 9.0, 11.0, R["egg"], spots=[(13, 11), (14, 11), (19, 15), (12, 19), (13, 19), (18, 22), (20, 21)])
    for (x, y) in ((17, 6), (18, 7), (17, 8), (18, 9)):  # hairline crack
        if (x, y) in em:
            e[y][x] = R["egg"][0]
    T["egg"] = e
    T["wall"] = tex_dirt(61 + var * 97, ramp=R["dirt_deep"], pebbles=7, roots=3, bevel=False, base=2)
    cv = [[pick(R["cave"], 0.15 + fbm(x / N, y / N, 71, base=2) * 0.6 + fbm(x / N, y / N, 72, base=8, octs=2) * 0.25, x, y, 0.1) for x in range(N)] for y in range(N)]
    T["cave"] = cv
    BEVEL[0] = True
    return T


# ---------------------------------------------------------------- voxel characters
class Vox(dict):
    def box(self, x0, y0, z0, x1, y1, z1, c):
        for x in range(x0, x1 + 1):
            for y in range(y0, y1 + 1):
                for z in range(z0, z1 + 1):
                    self[(x, y, z)] = c

    def ell(self, cx, cy, cz, rx, ry, rz, cf):
        for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
            for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
                for z in range(int(cz - rz) - 1, int(cz + rz) + 2):
                    if ((x + 0.5 - cx) / rx) ** 2 + ((y + 0.5 - cy) / ry) ** 2 + ((z + 0.5 - cz) / rz) ** 2 <= 1:
                        c = cf(x, y, z)
                        if c:
                            self[(x, y, z)] = c

    def front(self, x, y):  # z of the front (camera side, smallest z) surface at (x, y)
        zs = [k[2] for k in self if k[0] == x and k[1] == y]
        return min(zs) if zs else None

    def paint_front(self, x, y, c, depth=0):
        z = self.front(x, y)
        if z is not None:
            self[(x, y, z + depth)] = c


GLOW = set()


def glow(c):
    GLOW.add(c)
    return c


def kobold():
    v = Vox()
    fur, fur_d, fur_l = H("#f2a57e"), H("#c9746a"), H("#ffd2ae")
    belly, pink, ink, nose = H("#fff0dc"), H("#ff9db0"), INK, H("#7a3d56")
    v.box(4, 0, 4, 6, 1, 8, fur_d)
    v.box(9, 0, 4, 11, 1, 8, fur_d)
    v.box(4, 0, 4, 6, 0, 4, fur_l)
    v.box(9, 0, 4, 11, 0, 4, fur_l)
    v.ell(8, 6, 7, 4.6, 4.4, 3.9, lambda x, y, z: belly if z < 5 and abs(x + 0.5 - 8) < 3 and 2 <= y <= 8 else fur)
    v.box(2, 4, 5, 3, 7, 7, fur)
    v.box(13, 4, 5, 14, 7, 7, fur)
    v.box(2, 4, 5, 3, 4, 6, fur_l)
    v.box(13, 4, 5, 14, 4, 6, fur_l)
    v.ell(8, 14, 7, 5.8, 4.8, 5.0, lambda x, y, z: fur_l if (z < 4 and y < 14 and abs(x + 0.5 - 8) < 3.2) else fur)
    v.box(7, 11, 1, 9, 12, 1, fur_l)  # muzzle
    v.box(7, 12, 0, 8, 12, 0, nose)
    for ex in (5, 10):  # 2x3 eyes with a highlight
        for dx in (0, 1):
            for dy in (0, 1, 2):
                v.paint_front(ex + dx, 13 + dy, ink)
        v.paint_front(ex, 15, H("#ffffff"))
        v.paint_front(ex + 1, 13, R["lilac"][1])
    v.paint_front(4, 13, pink)
    v.paint_front(12, 13, pink)
    ear = [(17, 3, 5), (18, 3, 5), (19, 3, 4), (20, 3, 4), (21, 3, 3), (22, 3, 3)]  # tall pointed ears, pink inside
    for (y, a, b) in ear:
        for x in range(a, b + 1):
            for xx in (x, 15 - x + 1):
                v[(xx, y, 7)] = fur
                v[(xx, y, 6)] = pink if (y <= 20 and x == 4) else fur_d if x == a else fur
    helm, helm_l = H("#6c5aa8"), H("#9a86d6")
    v.ell(8, 18.0, 7, 3.4, 1.5, 3.4, lambda x, y, z: helm_l if y >= 18 else helm)  # little candle cap
    for x in range(4, 13):
        for z in range(3, 12):
            if ((x + 0.5 - 8) / 4.6) ** 2 + ((z + 0.5 - 7) / 4.6) ** 2 <= 1 and (x, 17, z) not in v:
                v[(x, 17, z)] = helm
    v.box(8, 20, 6, 8, 22, 6, H("#fff3d6"))
    v[(7, 20, 6)] = H("#fff3d6")
    v[(8, 23, 6)] = glow(H("#ffd98a"))
    v[(8, 24, 6)] = glow(H("#fffbe6"))
    v.box(15, 2, 4, 15, 10, 4, R["wood"][2])  # copper pick in the right hand
    v.box(13, 10, 4, 17, 10, 4, R["copper"][2])
    v[(13, 9, 4)] = R["copper"][1]
    v[(17, 9, 4)] = R["copper"][1]
    v[(15, 11, 4)] = R["copper"][3]
    for p in ((8, 3, 11), (8, 3, 12), (9, 4, 13), (10, 5, 13), (10, 6, 12), (10, 7, 12)):  # tail
        v[p] = fur
    v[(10, 8, 12)] = glow(R["copper"][3])
    return v


def dwarf(with_pick=True):
    v = Vox()
    boot, boot_l = H("#5a3f52"), H("#7e5f6e")
    denim, denim_d = H("#8296d8"), H("#5f6fb0")
    shirt, skin, skin_d = H("#f29fb0"), H("#f8cfae"), H("#e3a28c")
    beard, beard_l, beard_d = H("#f2a97c"), H("#ffd0a8"), H("#c9786a")
    hat, hat_d = H("#ffd98a"), H("#e0a85a")
    v.box(4, 0, 4, 7, 2, 8, boot)
    v.box(9, 0, 4, 12, 2, 8, boot)
    v.box(4, 0, 3, 7, 1, 3, boot_l)
    v.box(9, 0, 3, 12, 1, 3, boot_l)
    v.box(4, 3, 5, 12, 8, 8, denim)
    v.box(8, 3, 5, 8, 6, 5, denim_d)
    v.box(3, 9, 4, 13, 15, 9, denim)
    v.box(4, 13, 4, 12, 15, 4, shirt)
    v.box(3, 9, 4, 13, 9, 9, R["wood"][2])  # belt
    v.box(7, 9, 3, 9, 9, 3, R["gold"][3])
    v.box(1, 9, 5, 2, 15, 8, shirt)
    v.box(14, 9, 5, 15, 15, 8, shirt)
    v.box(1, 8, 5, 2, 8, 7, skin)
    v.box(14, 8, 5, 15, 8, 7, skin)
    v.box(4, 10, 10, 12, 16, 11, R["lilac"][1])  # backpack
    v.box(5, 11, 12, 11, 15, 12, R["lilac"][2])
    v.box(4, 16, 4, 12, 23, 9, skin)
    for ex in (5, 10):  # eyes with a highlight, bushy brows, rosy cheeks
        for dx in (0, 1):
            v[(ex + dx, 20, 3)] = INK
            v[(ex + dx, 21, 3)] = INK
            v[(ex + dx, 22, 3)] = beard_d
        v[(ex, 21, 3)] = H("#ffffff")
    v[(4, 19, 3)] = R["rose"][2]
    v[(12, 19, 3)] = R["rose"][2]
    v.box(7, 18, 2, 9, 19, 2, skin_d)  # nose bulb
    v[(8, 19, 1)] = skin_d
    for y in range(8, 18):  # beard: wavy strands, darker underside, pointed tip
        hw = 5 if y >= 13 else max(1, 5 - (13 - y) // 2)
        for x in range(8 - hw, 9 + hw):
            c = beard_l if x % 3 == 1 else beard
            if y in (10, 11) and x % 3 == 2:
                c = beard_d
            if y <= 9:
                c = beard_d
            for z in (2, 3):
                v[(x, y, z)] = c
    for x in list(range(4, 8)) + list(range(9, 13)):  # mustache wings
        v[(x, 17, 1)] = beard_l if x in (4, 12) else beard
    v.box(3, 23, 3, 13, 25, 10, hat)
    v.box(2, 23, 2, 14, 23, 11, hat_d)
    v.box(5, 26, 5, 11, 26, 8, hat)
    v.box(7, 24, 2, 9, 25, 2, glow(R["mint"][3]))  # mint helmet lamp
    v[(6, 24, 2)] = R["lilac"][1]
    v[(10, 24, 2)] = R["lilac"][1]
    if not with_pick:
        return v
    v.box(16, 4, 6, 16, 18, 6, R["wood"][2])  # mint crystal pickaxe (signature)
    v.box(13, 17, 6, 19, 18, 6, glow(R["mint"][2]))
    v[(12, 17, 6)] = glow(R["mint"][3])
    v[(20, 17, 6)] = glow(R["mint"][3])
    v[(16, 19, 6)] = glow(R["mint"][4])
    return v


def face_right(v):
    """Turn a model that faces the camera (-z) to face +x (walking right): the 2.5D side pose."""
    zmax = max(k[2] for k in v)
    out = Vox()
    for (x, y, z), c in v.items():
        out[(zmax - z, y, x)] = c
    return out


def walk_pose(v, phase):
    """Shift the two boots/legs forward and back (in +x after face_right) and bob the body."""
    out = Vox()
    for (x, y, z), c in v.items():
        if y <= 2:
            near = z < 8
            dx = phase if near else -phase
            out[(x + dx, y, z)] = c
        else:
            out[(x, y + (1 if phase == 0 else 0), z)] = c
    return out


def render_iso(v, s=4, pad=4):
    """MagicaVoxel-style render seen from front-left: top, front (-z) and right (+x) faces."""
    pts = []
    for (x, y, z), c in v.items():
        u, w = x, -z
        pts.append(((u - w) * s, (u + w) * s / 2 - y * s))
    minx = min(p[0] for p in pts) - s * 2 - pad
    miny = min(p[1] for p in pts) - s * 2 - pad
    maxx = max(p[0] for p in pts) + s * 2 + pad
    maxy = max(p[1] for p in pts) + s * 2 + pad
    W, Ht = int(maxx - minx), int(maxy - miny)
    img = Image.new("RGBA", (W, Ht), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    order = sorted(v.items(), key=lambda kv: (kv[0][0] - kv[0][2], kv[0][1]))
    order = sorted(v.items(), key=lambda kv: ((kv[0][0] + (-kv[0][2])), kv[0][1]))
    for (x, y, z), c in order:
        u, w = x, -z
        ox, oy = (u - w) * s - minx, (u + w) * s / 2 - y * s - miny
        g = c in GLOW
        top = [(ox, oy - s / 2), (ox + s, oy), (ox, oy + s / 2), (ox - s, oy)]
        front = [(ox - s, oy), (ox, oy + s / 2), (ox, oy + s / 2 + s), (ox - s, oy + s)]
        right = [(ox, oy + s / 2), (ox + s, oy), (ox + s, oy + s), (ox, oy + s / 2 + s)]
        occl = sum(1 for p in ((x + 1, y + 1, z), (x - 1, y + 1, z), (x, y + 1, z + 1), (x, y + 1, z - 1)) if p in v)
        if (x, y + 1, z) not in v:
            d.polygon([(int(a), int(b)) for a, b in top], fill=c if g else shade(c, 1.12 - occl * 0.05))
        if (x, y, z - 1) not in v:
            d.polygon([(int(a), int(b)) for a, b in front], fill=c if g else shade(c, 0.95))
        if (x + 1, y, z) not in v:
            d.polygon([(int(a), int(b)) for a, b in right], fill=shade(c, 0.9) if g else shade(c, 0.74))
    return add_outline(img)


def add_outline(img, col=INK):
    px = img.load()
    W, Ht = img.size
    out = img.copy()
    po = out.load()
    for y in range(Ht):
        for x in range(W):
            if px[x, y][3] == 0:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    if 0 <= x + dx < W and 0 <= y + dy < Ht and px[x + dx, y + dy][3] > 0:
                        po[x, y] = col + (255,)
                        break
    return out


def render_oblique(v, s=2, k=0.5):
    """Front view with a little top and right side, matching the in-game camera. Used in the scene."""
    xs = [p[0] for p in v]
    ys = [p[1] for p in v]
    zs = [p[2] for p in v]
    dz = max(zs) - min(zs) + 1
    W = (max(xs) - min(xs) + 1) * s + int(dz * k * s) + 4
    Ht = (max(ys) - min(ys) + 1) * s + int(dz * k * s) + 4
    img = Image.new("RGBA", (W, Ht), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    x0, y1, z0 = min(xs), max(ys), min(zs)
    for (x, y, z), c in sorted(v.items(), key=lambda kv: (-kv[0][2], kv[0][1], kv[0][0])):
        g = c in GLOW
        ox = (x - x0) * s + (z - z0) * k * s + 2
        oy = (y1 - y) * s - (z - z0) * k * s + dz * k * s + 2
        if (x, y + 1, z) not in v:
            d.polygon([(ox, oy), (ox + s, oy), (ox + s + k * s, oy - k * s), (ox + k * s, oy - k * s)], fill=c if g else shade(c, 1.12))
        if (x + 1, y, z) not in v:
            d.polygon([(ox + s, oy), (ox + s + k * s, oy - k * s), (ox + s + k * s, oy + s - k * s), (ox + s, oy + s)], fill=shade(c, 0.9) if g else shade(c, 0.74))
        if (x, y, z - 1) not in v:
            d.rectangle([ox, oy, ox + s - 1, oy + s - 1], fill=c if g else shade(c, 0.97))
    return add_outline(img)


# ---------------------------------------------------------------- world scene
def scene(TV, kob, dwa):
    T = TV[0]
    W, Hh, B = 1280, 592, 32
    GROUND, SX0, COLS, ROWS = 156, 256, 24, 14
    img = Image.new("RGB", (W, Hh))
    px = img.load()
    sky = [H(h) for h in ("#8d9fe0", "#a4aee6", "#bdb3e6", "#d4b6dd", "#ecbccd", "#ffc9b8", "#ffdcc4")]
    for y in range(GROUND):
        for x in range(W):
            px[x, y] = pick(sky, y / GROUND, x, y, 0.22)
    d = ImageDraw.Draw(img)

    def blob(cx, cy, rs, top, bot):
        for (ox, oy, r) in rs:
            for yy in range(-r, r + 1):
                for xx in range(-r, r + 1):
                    if xx * xx + yy * yy <= r * r:
                        X, Y = cx + ox + xx, cy + oy + yy
                        if 0 <= X < W and 0 <= Y < GROUND:
                            px[X, Y] = bot if Y > cy + 2 else top

    for (cx, cy, sc) in ((420, 40, 1.0), (760, 70, 0.8), (1090, 34, 1.2), (600, 22, 0.6)):  # clouds
        rs = [(int(o * sc), int(q * sc), max(3, int(r * sc))) for o, q, r in ((0, 0, 14), (18, 4, 11), (-17, 5, 10), (34, 8, 7), (-31, 9, 6))]
        blob(cx, cy, rs, H("#fff3ec"), H("#e4cfe6"))
    for (amp, base_y, col, seed) in ((22, GROUND - 26, H("#b9a6d8"), 3), (16, GROUND - 12, H("#a48ec8"), 9)):  # far hills
        for x in range(W):
            hy = int(base_y - amp * fbm(x / W, 0.5, seed, base=5, tile=False))
            for y in range(max(0, hy), GROUND):
                px[x, y] = col
    trunk, trunk_l, trunk_d = H("#8f78a8"), H("#ab95c6"), H("#715c8c")  # the world tree, hazy with distance
    for y in range(0, GROUND):
        flare = max(0, (y - 90)) ** 1.6 * 0.35  # roots spread where it meets the ground
        half = 62 + int(6 * math.sin(y / 23)) + int(flare)
        cx = 118 + int(6 * math.sin(y / 41))
        for x in range(cx - half, cx + half):
            if 0 <= x < W:
                rel = (x - (cx - half)) / (2 * half)
                groove = (x * 3 + int(8 * math.sin(y / 17 + x / 9))) % 13 == 0
                c = trunk_d if rel < 0.18 else (trunk_l if rel > 0.8 else trunk)
                px[x, y] = trunk_d if groove and 0.1 < rel < 0.92 else c
    for i in range(0, 300):  # big branch across the top
        bx = 160 + i
        by = int(26 - 18 * math.sin(i / 120) + 0.0004 * i * i)
        th = max(3, 11 - i // 32)
        for t in range(-th, th + 1):
            if 0 <= by + t < GROUND:
                px[bx, by + t] = trunk_l if t < -th // 3 else (trunk_d if t > th // 2 else trunk)
    leaf_t, leaf_b = H("#b4e6d2"), H("#8cc7b8")
    for (cx, cy) in ((60, -10), (130, 4), (210, -6), (290, 10), (370, 2), (440, 22), (20, 20)):
        blob(cx, cy, [(0, 0, 30), (24, 8, 22), (-22, 10, 20), (8, 18, 16)], leaf_t, leaf_b)
    for i in range(160):  # leaf sparkle pixels
        x, y = random.Random(i).randrange(0, 470), random.Random(i * 7).randrange(0, 40)
        if px[x, y] in (leaf_t, leaf_b):
            px[x, y] = H("#e6fff4")

    # underground: the cut-away earth beside the shaft, then the cave behind the dug cells
    for y in range(GROUND, Hh):
        for x in range(W):
            in_shaft = SX0 <= x < SX0 + COLS * B
            tv = TV[((x // N) * 7 + ((y - GROUND) // N) * 3) % len(TV)]
            c = (tv["cave"] if in_shaft else tv["wall"])[(y - GROUND) % N][x % N]
            if not in_shaft:  # strata: wavy darker and lighter bands in the cut-away earth
                band = math.sin((y - GROUND) / 26 + math.sin(x / 90) * 1.4)
                c = shade(c, 1.06) if band > 0.75 else (shade(c, 0.88) if band < -0.8 else c)
            px[x, y] = c

    def root(points, wdt):  # thick shaded root along a polyline
        for i in range(len(points) - 1):
            (x1, y1), (x2, y2) = points[i], points[i + 1]
            n = int(max(abs(x2 - x1), abs(y2 - y1)))
            for j in range(n + 1):
                x = x1 + (x2 - x1) * j / max(n, 1)
                y = y1 + (y2 - y1) * j / max(n, 1)
                for t in range(-wdt, wdt + 1):
                    X, Y = int(x), int(y + t)
                    if 0 <= X < W and GROUND <= Y < Hh and not (SX0 <= X < SX0 + COLS * B):
                        tt = (t + wdt) / (2 * wdt)
                        c = R["root"][3] if tt < 0.18 else (R["root"][2] if tt < 0.45 else (R["root"][1] if tt < 0.85 else R["root"][0]))
                        if (X + int(t * 1.5)) % 11 == 0 and 0.15 < tt < 0.85:
                            c = R["root"][0]  # bark groove
                        px[X, Y] = c

    root([(0, 190), (50, 214), (120, 228), (190, 270), (256, 292)], 14)
    root([(150, 160), (170, 200), (160, 250), (190, 300)], 6)
    root([(0, 440), (90, 418), (170, 446), (256, 486)], 10)
    root([(1280, 222), (1200, 252), (1120, 244), (1024, 298)], 15)
    root([(1100, 160), (1080, 210), (1100, 260)], 6)
    root([(1280, 486), (1180, 512), (1090, 492), (1024, 530)], 9)
    gw = random.Random(3)  # glow worms in the earth
    for _ in range(70):
        x = gw.choice((gw.randrange(6, 250), gw.randrange(1030, 1274)))
        y = gw.randrange(GROUND + 20, Hh - 10)
        col = R["mint"][3] if gw.random() < 0.6 else R["lilac"][3]
        px[x, y] = col
        if gw.random() < 0.4:
            px[x + 1, y] = shade(col, 0.8)
    # fossil ammonite in the left wall
    for a in range(0, 900):
        th = a / 60
        r = 2 + th * 2.2
        X, Y = int(110 + r * math.cos(th)), int(340 + r * math.sin(th))
        if GROUND < Y < Hh:
            px[X, Y] = R["egg"][2] if a % 7 else R["egg"][0]
    # crystal pocket in the right wall
    cav = [(1140, 360), (1210, 345), (1240, 380), (1200, 420), (1135, 405)]
    for y in range(340, 430):
        for x in range(1120, 1250):
            if inside(x + 0.5, y + 0.5, cav):
                px[x, y] = R["cave"][1]
    for (bx, by, ang, L, wd, rp) in ((1160, 410, -0.4, 34, 12, R["mint"]), (1185, 412, 0.15, 44, 14, R["mint"]), (1212, 408, 0.5, 30, 11, R["lilac"])):
        dx, dy, pxx, pyy = math.sin(ang), -math.cos(ang), math.cos(ang), math.sin(ang)
        pts = [(bx - pxx * wd / 2, by - pyy * wd / 2), (bx + pxx * wd / 2, by + pyy * wd / 2), (bx + dx * L * .7 + pxx * wd / 2, by + dy * L * .7 + pyy * wd / 2), (bx + dx * L, by + dy * L), (bx + dx * L * .7 - pxx * wd / 2, by + dy * L * .7 - pyy * wd / 2)]
        for y in range(int(by - L - 2), int(by + 4)):
            for x in range(int(bx - L), int(bx + L)):
                if inside(x + .5, y + .5, pts):
                    side = (x + .5 - bx) * pxx + (y + .5 - by) * pyy
                    px[x, y] = rp[3] if side < -wd * .12 else (rp[1] if side > wd * .12 else rp[2])

    # the shaft grid
    rnd = random.Random(7)
    dug = {(0, 12), (1, 12), (2, 12), (3, 12), (3, 11), (3, 10), (3, 9), (3, 13), (3, 14), (4, 14), (5, 14), (4, 9)}
    kinds = {}
    for r in range(ROWS):
        for c in range(COLS):
            x = rnd.random()
            kinds[(r, c)] = "grass" if r == 0 else ("ashcoal" if x < .14 else ("copper" if x < .24 else "rootflint"))
    for c in (15, 16, 17):
        kinds[(6, c)] = "gilded"
    kinds[(7, 12)] = "egg"
    kinds[(4, 8)] = "copper"
    for r in range(ROWS):
        for c in range(COLS):
            if (r, c) in dug:
                continue
            t = TV[(r * 5 + c * 3 + (r * c) % 4) % len(TV)][kinds[(r, c)]]
            flip = (r * 7 + c) % 3 == 0 and kinds[(r, c)] in ("rootflint", "ashcoal", "copper")
            patch = fbm(c / COLS, r / ROWS, 404, base=3, tile=False)
            f = 0.9 + patch * 0.2
            X0, Y0 = SX0 + c * B, GROUND + r * B
            for y in range(B):
                if Y0 + y < Hh:
                    for x in range(B):
                        col = t[y][B - 1 - x if flip else x]
                        px[X0 + x, Y0 + y] = shade(col, f) if kinds[(r, c)] in ("rootflint", "grass") else col
    D, SK = 9, 6  # oblique top and side faces inside dug cells (the camera looks down and to the right)
    for r in range(ROWS):
        for c in range(COLS):
            if (r, c) in dug:
                continue
            t = TV[0][kinds[(r, c)]]
            X0, Y0 = SX0 + c * B, GROUND + r * B
            if (r - 1, c) in dug:
                for i in range(D):
                    sh = int((D - i) * SK / D)
                    for x in range(B):
                        X = X0 + x + sh
                        if X < SX0 + COLS * B:
                            px[X, Y0 - D + i] = shade(t[1 + (i * 3) // D][x], 1.1 if i < D - 1 else 1.0)
            if (r, c + 1) in dug:
                for j in range(SK):
                    lift = int(j * D / SK)
                    for y in range(B):
                        Y = Y0 + y - lift
                        if GROUND <= Y < Hh:
                            px[X0 + B + j, Y] = shade(t[y][B - 1 - j % 3], 0.72)
    # glowing mushrooms on the floor of the kobold pocket, hanging roots in the dug tunnel
    for (mx, my, mc) in ((SX0 + 9 * B + 6, GROUND + 5 * B - D, R["rose"]), (SX0 + 9 * B + 18, GROUND + 5 * B - D + 2, R["lilac"]), (SX0 + 14 * B + 20, GROUND + 6 * B - D, R["mint"])):
        for y in range(6):
            px[mx + 2, my - y] = R["egg"][2]
        for xx in range(-4, 9):
            for yy in range(-4, 0):
                if (xx - 2) ** 2 / 36 + (yy + 4) ** 2 / 16 <= 1:
                    px[mx + xx, my - 6 + yy + 4] = mc[2] if yy > -3 else mc[3]
    for (rx0, ln) in ((SX0 + 12 * B + 8, 26), (SX0 + 12 * B + 22, 18), (SX0 + 10 * B + 14, 14)):
        ry0 = GROUND + 3 * B if rx0 < SX0 + 12 * B else GROUND
        for k in range(ln):
            X = rx0 + int(2 * math.sin(k / 4))
            px[X, ry0 + k] = R["root"][2]
            px[X + 1, ry0 + k] = R["root"][1]
    # surface: grass lip over the side earth, a camp tent and a lantern post, the lift frame
    for x in list(range(0, SX0)) + list(range(SX0 + COLS * B, W)):
        hgt = 8 + int(fbm(x / 97, 0.2, 5, base=6, tile=False) * 6)
        for y in range(hgt):
            px[x, GROUND - 2 + y] = pick(R["moss"], 0.9 - y / hgt * 0.75, x, y, 0.12)
        if x % 5 == 0:
            px[x, GROUND - 3] = R["moss"][3]
    d.polygon([(150, GROUND - 2), (196, GROUND - 52), (242, GROUND - 2)], fill=R["lilac"][2])
    d.polygon([(196, GROUND - 52), (242, GROUND - 2), (214, GROUND - 2)], fill=R["lilac"][1])
    d.polygon([(186, GROUND - 2), (196, GROUND - 26), (206, GROUND - 2)], fill=R["cave"][1])
    for i in range(3):
        d.line([(160 + i * 26, GROUND - 2), (196, GROUND - 52)], fill=R["rose"][2], width=1)
    d.rectangle([60, GROUND - 60, 63, GROUND - 2], fill=R["wood"][1])
    d.rectangle([54, GROUND - 70, 69, GROUND - 58], fill=R["wood"][0])
    d.rectangle([57, GROUND - 67, 66, GROUND - 61], fill=R["gold"][3])
    lx0 = SX0 + COLS * B - 2  # lift A-frame at the shaft edge
    d.line([(lx0 - 60, GROUND - 2), (lx0 - 30, GROUND - 74)], fill=R["wood"][2], width=5)
    d.line([(lx0, GROUND - 2), (lx0 - 30, GROUND - 74)], fill=R["wood"][1], width=5)
    d.rectangle([lx0 - 42, GROUND - 82, lx0 - 18, GROUND - 70], fill=R["wood"][3])
    d.line([(lx0 - 30, GROUND - 70), (lx0 - 30, GROUND + 3 * B)], fill=R["egg"][1], width=1)

    # characters
    ds = render_oblique(dwa, s=2)
    ks = render_oblique(kob, s=2)
    floor = GROUND + 4 * B - D + 3
    img.paste(ds, (SX0 + 12 * B + 16 - ds.width // 2, floor - ds.height + 2), ds)
    img.paste(ks, (SX0 + 10 * B + 2 - ks.width // 2, floor - ks.height + 2), ks)

    # light: stepped bands, dark with depth, warm around the helmet lamp, glows on crystals, gilded vein and the egg
    lights = [(SX0 + 12 * B + 20, GROUND + 3 * B + 4, 120, (1.0, 0.98, 0.9)), (SX0 + 16 * B + 16, GROUND + 6 * B + 16, 90, (1.0, 0.92, 0.6)),
              (SX0 + 12 * B + 16, GROUND + 7 * B + 16, 60, (1.0, 0.95, 0.9)), (1190, 395, 90, (0.7, 1.0, 0.9)), (SX0 + 9 * B + 12, GROUND + 4 * B + 10, 70, (1.0, 0.8, 0.95)), (62, GROUND - 64, 50, (1.0, 0.95, 0.75))]
    for y in range(GROUND, Hh):
        depth = (y - GROUND) / (Hh - GROUND)
        for x in range(W):
            amb = 0.86 - 0.36 * depth
            tint = [amb * 0.95, amb * 0.9, amb * 1.05]
            for (lx, ly, lr, lc) in lights:
                dd = math.hypot(x - lx, (y - ly) * 1.1)
                if dd < lr:
                    band = 0.3 if dd < lr * 0.33 else (0.17 if dd < lr * 0.66 else 0.07)
                    tint = [tint[i] + band * lc[i] for i in range(3)]
            c = px[x, y]
            px[x, y] = tuple(max(0, min(255, int(c[i] * min(tint[i], 1.25)))) for i in range(3))
    # haze at the bottom for depth
    for y in range(Hh - 60, Hh):
        a = (y - (Hh - 60)) / 60 * 0.35
        for x in range(W):
            if (x + y) % 2 == 0 or a > 0.2:
                px[x, y] = lerp(px[x, y], R["lilac"][0], a)
    return img


if __name__ == "__main__":
    TV = [make_textures(v) for v in range(4)]
    T = TV[0]
    for v, TT in enumerate(TV):
        for k, t in TT.items():
            to_img(t).save(os.path.join(OUT, f"tex_{k}_{v}.png"))
    kob, dwa = kobold(), dwarf()
    render_iso(kob, s=6).save(os.path.join(OUT, "char_kobold_iso.png"))
    render_iso(dwa, s=5).save(os.path.join(OUT, "char_dwarf_iso.png"))
    render_oblique(kob, s=6).save(os.path.join(OUT, "char_kobold_front.png"))
    render_oblique(dwa, s=5).save(os.path.join(OUT, "char_dwarf_front.png"))
    scene(TV, kob, dwa).save(os.path.join(OUT, "scene_rootholm.png"))
    print("ok", sorted(os.listdir(OUT)))


# ---------------------------------------------------------------- rare blocks: whole, glowing, easy for kids to spot
def _voronoi(seed, n, size=N):
    rnd = random.Random(seed)
    pts = [(rnd.uniform(0, size), rnd.uniform(0, size), rnd.uniform(0.35, 1.0)) for _ in range(n)]
    ids = [[min(range(n), key=lambda i: (x + .5 - pts[i][0]) ** 2 + (y + .5 - pts[i][1]) ** 2) for x in range(size)] for y in range(size)]
    return pts, ids


def _faceted(seed, ramp, n=7):
    pts, ids = _voronoi(seed, n)
    im = [[None] * N for _ in range(N)]
    for y in range(N):
        for x in range(N):
            i = ids[y][x]
            t = pts[i][2] * 0.95 + 0.12 * (1 - (x + y) / (2 * N)) - 0.25
            c = ramp[max(1, min(len(ramp) - 2, int(t * (len(ramp) - 1)) + 1))]
            if x + 1 < N and ids[y][x + 1] != i or y + 1 < N and ids[y + 1][x] != i:
                c = ramp[0]  # facet seam
            elif x > 0 and ids[y][x - 1] != i or y > 0 and ids[y - 1][x] != i:
                c = ramp[-1]  # lit facet edge
            im[y][x] = c
    for i in range(N):  # whole-block bevel so it reads as one solid gem block
        im[0][i] = im[i][0] = ramp[-1]
        im[N - 1][i] = im[i][N - 1] = ramp[0]
    return im


def tex_gilded_full(seed=5):
    im = _faceted(seed, [H("#5a3418")] + R["gold"], n=9)
    for (sx, sy) in ((7, 6), (22, 11), (12, 23), (26, 25)):
        sparkle(im, sx, sy, R["gold"])
    return im


def tex_geode(seed=6):
    """A cracked-open geode: rough stone shell, a ring of crystal teeth, a glowing crystal heart."""
    im = [[None] * N for _ in range(N)]
    shell = [H(h) for h in ("#2a2440", "#463e66", "#665d8e", "#8a82b2")]
    gem = R["lilac"]
    for y in range(N):
        for x in range(N):
            dx, dy = x + 0.5 - N / 2, y + 0.5 - N / 2
            ang = math.atan2(dy, dx)
            r = math.hypot(dx, dy) / (N / 2) + (hsh(int(ang * 9), 0, seed) - 0.5) * 0.12
            if r > 0.86 or x in (0, N - 1) or y in (0, N - 1):
                c = pick(shell, 0.35 + fbm(x / N, y / N, seed, base=4) * 0.5 - (0.25 if (x == N - 1 or y == N - 1) else 0), x, y)
                if x == 0 or y == 0:
                    c = shell[3]
            elif r > 0.58:
                tooth = ((ang / (2 * math.pi) * 14) % 1) < (1 - (r - 0.58) / 0.28)
                c = (gem[3] if dx < 0 else gem[2]) if tooth else shell[0]
            else:
                c = gem[4] if r < 0.18 else (R["mint"][3] if r < 0.32 else gem[3])
            im[y][x] = c
    for (sx, sy) in ((14, 13), (18, 17)):
        im[sy][sx] = (255, 255, 255)
    return im


def tex_amber_egg(seed=7):
    """The fossil egg sealed in a whole block of glowing amber."""
    amber = [H(h) for h in ("#7a3a1e", "#b8642a", "#e69a3e", "#ffc970", "#fff0c4")]
    im = _faceted(seed, amber, n=5)
    egg = R["egg"]
    for y in range(N):
        for x in range(N):
            nx, ny = (x + 0.5 - 16) / 8.5, (y + 0.5 - 17) / 10.5
            if nx * nx + ny * ny <= 1:
                k = 3 if (nx < -0.2 and ny < -0.1) else 2
                im[y][x] = lerp(egg[k], amber[3], 0.35)
                if (x, y) in ((13, 12), (19, 15), (12, 20), (18, 22)):
                    im[y][x] = lerp(R["lilac"][1], amber[2], 0.4)
    for (bx, by) in ((5, 7), (25, 6), (27, 20), (6, 26)):  # bubbles in the amber
        im[by][bx] = amber[4]
    return im
