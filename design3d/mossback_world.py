"""The Mossback Pickaxe setting: a terraced clay canyon with a trickle of a stream (scene bible "Mossback"; reference
refs/forge/sheets/mossback_setting_s11.png when it exists).
    python design3d/mossback_world.py
Writes, from ONE height function: design3d/tex/mossback_terrain.mjs (near terraces and far canyon), mossback_floor.png (dry
clay terrace tops, banded ochre and rust faces, moss round the shelf), mossback_far.png, three skies (dust, rain, morning) and
src/ForgeMossbackMap.luau (stones, dry and green plants, clay ledges, cave mouths, waterfalls, the rope bridge, the snail's
route and the boulder's fall line). Authoring space: x to screen right, y up, z toward the camera. The mossy shelf where the
pickaxe is named is at the origin; the canyon climbs away from the camera in terraces; the stream runs down its left side."""
import json, pathlib
import numpy as np
from PIL import Image

here = pathlib.Path(__file__).resolve().parent
tex = here / "tex"; tex.mkdir(exist_ok=True)
NEAR = (-110.0, -190.0, 110.0, 30.0)
FAR = (-1000.0, -1650.0, 1000.0, 150.0)
N = 96
RISERS = [(-14.0, 9.0), (-44.0, 8.0), (-78.0, 9.0), (-116.0, 8.0), (-160.0, 9.0), (-210.0, 8.0), (-270.0, 10.0), (-340.0, 10.0)]   # z of each terrace face, and its height
RAMPS = {0: 16.0, 1: -4.0, 2: 20.0, 3: -10.0}                    # x where a face is worn into a ramp (the snail's way down)
LIP_DROP = 16.0                                                  # the shelf ends in a drop in front of the camera's ground
WALL_H, BENCH = 64.0, 8.0


def vnoise(x, y, seed=0, px=None):
    xi = np.floor(x).astype(np.int64); yi = np.floor(y).astype(np.int64)
    xf = x - xi; yf = y - yi

    def h(a, b):
        if px: a = a % px
        n = (a * 374761393 + b * 668265263 + seed * 1442695041) & 0xFFFFFFFF
        n = ((n ^ (n >> 13)) * 1274126177) & 0xFFFFFFFF
        return ((n ^ (n >> 16)) & 0xFFFF) / 65535.0
    u = xf * xf * (3 - 2 * xf); v = yf * yf * (3 - 2 * yf)
    return (h(xi, yi) * (1 - u) + h(xi + 1, yi) * u) * (1 - v) + (h(xi, yi + 1) * (1 - u) + h(xi + 1, yi + 1) * u) * v


def fbm(x, y, seed=0, octaves=4, px=None):
    s, a, f, tot = 0.0, 0.5, 1.0, 0.0
    for o in range(octaves):
        s = s + a * vnoise(x * f, y * f, seed + o * 17, px * int(f) if px else None); tot += a; a *= 0.5; f *= 2.0
    return s / tot


def smooth(a, b, t):
    x = np.clip((t - a) / (b - a), 0, 1)
    return x * x * (3 - 2 * x)


def mix(a, b, t): return a + (b - a) * t
def rgb(h): h = h.lstrip("#"); return np.array([int(h[i:i + 2], 16) for i in (0, 2, 4)], dtype=np.float64)
def paint(shape, col): return np.ones(shape + (3,)) * rgb(col)


def lay(img, col, a):
    c = rgb(col) if isinstance(col, str) else col
    return img * (1 - a[..., None]) + c * a[..., None]


def save(name, img, mode="RGB"):
    Image.fromarray(np.clip(img, 0, 255).astype(np.uint8), mode).save(tex / name); print("wrote", name)


def riser_z(k, x): return RISERS[k][0] + 4.0 * np.sin(x / 23.0 + k * 1.7)     # the face of terrace k is a wavy line
def lip_z(x): return 17.0 + 3.0 * np.sin(x / 19.0)
def stream_x(z): return -9.0 + 3.0 * np.sin(z / 30.0)
POOL = (float(stream_x(-10.5)), -10.5)                           # the pool the fall behind the shelf drops into


def terraces(x, z):
    """The canyon floor: level ground in steps, each face a short steep bank, worn into a ramp at one place."""
    h = 0.0
    for k, (zk, hk) in enumerate(RISERS):
        zr = riser_z(k, x)
        w = 1.6 if k not in RAMPS else mix(1.6, 9.0, np.exp(-((x - RAMPS[k]) / 7.0) ** 2))
        h = h + hk * smooth(zr + w, zr - w, z)
    return h - LIP_DROP * smooth(lip_z(x), lip_z(x) + 3.0, z)


def wall(x, z):
    """The canyon sides: benches of clay, eight studs to a step, up to the rim."""
    left = smooth(-34, -84, x + 8 * np.sin(z / 60.0) + (fbm(x * 0.02, z * 0.02, 7) - 0.5) * 14)
    right = smooth(38, 88, x - 7 * np.sin(z / 52.0 + 1.0) + (fbm(x * 0.02, z * 0.02, 8) - 0.5) * 14)
    h = np.maximum(left, right) * WALL_H
    q = np.floor(h / BENCH); f = h / BENCH - q
    return (q + smooth(0.5, 0.95, f)) * BENCH                    # flat benches and steep faces


def hills(x, z):
    def mass(cx, cz, H, R): return H * np.clip(1 - np.hypot(x - cx, z - cz) / R, 0, 1) ** 1.4
    return mass(-300, -980, 180, 520) + mass(340, -1100, 230, 560) + mass(0, -1500, 280, 640) + mass(-820, -420, 110, 500) + mass(840, -440, 110, 500)


def G(x, z):
    x = np.asarray(x, dtype=np.float64); z = np.asarray(z, dtype=np.float64)
    d = np.abs(x - stream_x(z))
    rough = (fbm(x * 0.09, z * 0.09, 1) - 0.5) * 0.5 + (fbm(x * 0.03, z * 0.03, 2) - 0.5) * 0.6
    flat = smooth(7, 15, np.hypot(x - 1.5, z))                    # the shelf itself is level
    h = terraces(x, z) + rough * flat
    h = h - 0.55 * (1 - smooth(0.8, 2.4, d))                      # the stream's shallow channel
    h = h - 1.0 * (1 - smooth(2.0, 4.4, np.hypot(x - POOL[0], z - POOL[1])))   # the pool under the fall
    return h + wall(x, z) + hills(x, z) * smooth(-380, -620, z)


def grid(rect, n):
    x0, z0, x1, z1 = rect
    return np.meshgrid(np.linspace(x0, x1, n + 1), np.linspace(z0, z1, n + 1))


def pixels(rect, size):
    x0, z0, x1, z1 = rect
    xs = x0 + (np.arange(size) + 0.5) / size * (x1 - x0); zs = z0 + (np.arange(size) + 0.5) / size * (z1 - z0)
    return np.meshgrid(xs, zs)


rng = np.random.default_rng(31)

# ---------------- heights ----------------
NX, NZ = grid(NEAR, N); FX, FZ = grid(FAR, N)
out = {"near": {"rect": NEAR, "h": np.round(G(NX, NZ), 3).tolist()}, "far": {"rect": FAR, "h": np.round(G(FX, FZ) - 3.0, 2).tolist()}}
(tex / "mossback_terrain.mjs").write_text("// GENERATED by design3d/mossback_world.py. Do not edit by hand.\nexport default " + json.dumps(out, separators=(",", ":")) + ";\n", encoding="utf-8")
print("wrote mossback_terrain.mjs")


def strata(h, n1, n2):
    """Clay by height: terracotta bands with thin dark seams. Measured on mossback_setting_s11.png: lit clay #cb8369, faces
    #a95037 to #8b4c3d, deep shadow #6c2417 (redder than the bible's #c98b5e, which stays as the pale band)."""
    band = np.sin(h * 0.78 + n1 * 3.0) * 0.5 + 0.5
    col = mix(rgb("#8b3f2e"), rgb("#b55a40"), band[..., None])
    pale = smooth(0.78, 0.95, np.sin(h * 0.31 + 1.3 + n1 * 2.0) * 0.5 + 0.5)
    col = col * (1 - 0.7 * pale[..., None]) + rgb("#d08a6c") * (0.7 * pale[..., None])
    seam = smooth(0.84, 0.97, np.sin(h * 2.3 + n2 * 4.0) * 0.5 + 0.5)
    col = col * (1 - 0.5 * seam[..., None]) + rgb("#6c2a1e") * (0.5 * seam[..., None])
    return col * (0.9 + 0.16 * n2[..., None])


def slope(h, rect, size):
    gz, gx = np.gradient(h, (rect[3] - rect[1]) / size, (rect[2] - rect[0]) / size)
    return np.hypot(gx, gz)


def ground(rect, S, seeds, detail):
    X, Z = pixels(rect, S)
    h = G(X, Z); st = slope(h, rect, S)
    n1 = fbm(X * 0.05 * detail, Z * 0.05 * detail, seeds[0]); n2 = fbm(X * 0.35 * detail, Z * 0.35 * detail, seeds[1], 3); n3 = vnoise(X * 2.1 * detail, Z * 2.1 * detail, seeds[2])
    img = mix(paint((S, S), "#b9634a"), paint((S, S), "#d08a6c"), n1[..., None]) * (0.9 + 0.2 * n3[..., None])   # dry clay on the terrace tops
    crack = smooth(0.9, 0.99, np.abs(np.sin(X * 0.8 + fbm(X * 0.11, Z * 0.11, seeds[3]) * 9.0)) * np.abs(np.sin(Z * 0.7 + fbm(X * 0.13, Z * 0.13, seeds[3] + 1) * 9.0)) ** 0.3)
    img = lay(img, "#8b3f2e", crack * 0.35)                                                                       # sun cracks
    face = smooth(0.45, 1.3, st)
    img = img * (1 - face[..., None]) + strata(h, n1, n2) * face[..., None]                                       # every face shows its bands
    d = np.abs(X - stream_x(Z)); onfloor = (wall(X, Z) < 0.5)
    green = np.exp(-np.hypot(X, Z + 2) / 30.0)                                                                    # the moss: thickest round the shelf, gone up the canyon
    patch = smooth(0.38, 0.62, fbm(X * 0.07, Z * 0.07, seeds[4]))
    moss = np.clip(green * 2.0, 0, 1) * mix(0.3, 1.0, patch) * mix(1.0, 0.45, face)
    img = lay(img, mix(rgb("#6f7c2e"), rgb("#aab444"), n2[..., None]), np.clip(moss, 0, 0.94))
    damp = (1 - smooth(1.2, 5.5, d)) * onfloor                                                                    # the stream's damp margin, greener the nearer the shelf
    img = lay(img, mix(rgb("#8b4c3d"), rgb("#7c8a34"), np.clip(green * 2.2, 0, 1)[..., None]), damp * 0.7)
    img = lay(img, "#6f9088", (1 - smooth(0.6, 1.5, d)) * onfloor * 0.9)                                          # the water line
    img = lay(img, "#5c8a86", (1 - smooth(2.2, 4.0, np.hypot(X - POOL[0], Z - POOL[1]))) * 0.95)                  # the pool
    img = lay(img, "#66782e", smooth(lip_z(X) + 2.0, lip_z(X) + 6.0, Z) * 0.75)                                   # the green ground below the shelf's drop
    return img, h


img, _ = ground(NEAR, 1024, (41, 42, 43, 44, 45), 1.0)
save("mossback_floor.png", img)
img, h = ground(FAR, 1024, (61, 62, 63, 64, 65), 0.12)
X, Z = pixels(FAR, 1024)
hl = hills(X, Z) * smooth(-380, -620, Z)
plateau = smooth(WALL_H - 3, WALL_H, wall(X, Z))
img = lay(img, mix(rgb("#c9a86a"), rgb("#b8b070"), fbm(X * 0.004, Z * 0.004, 66)[..., None]), plateau * 0.85)   # dry grass on the plateau above the rim
img = lay(img, "#9a8fb0", smooth(30, 200, hl) * 0.75)                                                           # the far hills go violet with height
save("mossback_far.png", img)


# ---------------- skies ----------------
def sky(look, top, mid, hor, cdark, clight, cover, amount, ground_, band=None):
    W = 1024; Hh = 512
    U, T = np.meshgrid((np.arange(W) + 0.5) / W, (np.arange(Hh) + 0.5) / Hh)
    img = mix(mix(rgb(top), rgb(mid), smooth(0, 0.62, T)[..., None]), rgb(hor), smooth(0.62, 1, T)[..., None])
    if band is not None: img = lay(img, band[0], np.exp(-((T - band[1]) / band[2]) ** 2) * band[3])
    P = 6; yy = 1.6 / (1.12 - T)
    n = fbm(U * P, yy * 1.3, 71, 5, px=P) * 0.65 + fbm(U * P * 2 + 3.1, yy * 2.6, 72, 4, px=P * 2) * 0.35
    a = smooth(cover, cover + 0.22, n) * amount * smooth(0.04, 0.2, T)
    lit = smooth(0.35, 0.75, fbm(U * P + 0.37, yy * 1.3 - 0.25, 71, 5, px=P))
    cc = mix(rgb(cdark), rgb(clight), (lit * smooth(0.2, 1.0, T))[..., None])
    img = img * (1 - a[..., None]) + cc * a[..., None]
    below = mix(rgb(hor), rgb(ground_), smooth(0, 0.5, T)[..., None])       # under the horizon: haze going down into the land's own colour (no water to mirror the sky here)
    save(f"mossback_sky_{look}_side.png", np.vstack([img, below]))
    save(f"mossback_sky_{look}_up.png", np.ones((8, 8, 3)) * img[0, 0])
    save(f"mossback_sky_{look}_dn.png", np.ones((8, 8, 3)) * below[-1, 0])


sky("dust", "#4f8ccc", "#b9cbd0", "#ecd6a8", "#d8c8a8", "#fff4dc", 0.62, 0.45, "#a9573a", band=("#f6dca8", 0.97, 0.12, 0.6))
sky("rain", "#56606c", "#858e98", "#b4b8b6", "#5a626e", "#aab0b6", 0.3, 0.95, "#6a665e")
sky("morning", "#5a96d0", "#b4d4e8", "#e9e1d1", "#c4d6e6", "#ffffff", 0.56, 0.65, "#8a9a50", band=("#fff2d6", 0.98, 0.08, 0.5))

# ---------------- the snail's route and the boulder's fall ----------------
def densify(poly, step):
    pts = []
    for (ax, az), (bx, bz) in zip(poly, poly[1:]):
        n = max(1, int(round(np.hypot(bx - ax, bz - az) / step)))
        for i in range(n): pts.append((ax + (bx - ax) * i / n, az + (bz - az) * i / n))
    pts.append(poly[-1])
    return pts


def chaikin(poly, times=2):                                      # round the corners: a snail does not turn on the spot
    for _ in range(times):
        q = [poly[0]]
        for a, b in zip(poly, poly[1:]):
            q.append((a[0] * 0.75 + b[0] * 0.25, a[1] * 0.75 + b[1] * 0.25)); q.append((a[0] * 0.25 + b[0] * 0.75, a[1] * 0.25 + b[1] * 0.75))
        q.append(poly[-1]); poly = q
    return poly


ROUTE = [(22, -62), (12, -57), (2, -54), (-4, -51), (-4, -30), (6, -27), (14, -25), (16, -22), (15.5, -3), (10, 1.5), (2.5, 0.5)]
route = densify(chaikin(ROUTE), 1.5)
FALL = densify([(88, -66), (22, -62)], 2.0)
stage = lambda pts: [(round(-x, 2), round(float(G(x, z)), 2), round(-z, 2)) for x, z in pts]
RXZ = np.array(route)

# ---------------- where things stand ----------------
items = []


def put(model, x, z, yaw=0.0, scale=1.0, lift=0.0, y=None):
    items.append((model, round(-x, 2), round((float(G(x, z)) if y is None else y) + lift, 2), round(-z, 2), round(yaw, 1), round(scale, 3)))


def off_route(x, z, r=4.0): return float(np.min(np.hypot(RXZ[:, 0] - x, RXZ[:, 1] - z))) > r
def clear(x, z): return off_route(x, z) and not (-8 < x < 9 and -7 < z < 16) and np.hypot(x - FALL[-1][0], z - FALL[-1][1]) > 7
def green_at(x, z): return float(np.exp(-np.hypot(x, z + 2) / 30.0))
def on_floor(x, z): return wall(x, z) < 0.4 and z < lip_z(x) - 2 and abs(x - stream_x(z)) > 1.8
def flat_at(x, z): return abs(float(G(x + 1.2, z)) - float(G(x - 1.2, z))) < 0.5 and abs(float(G(x, z + 1.2)) - float(G(x, z - 1.2))) < 0.5


def scatter(model, n, xr, zr, scale, want, lift=0.0, need_clear=True):
    count = tries = 0
    while count < n and tries < n * 400:
        tries += 1
        x = rng.uniform(*xr); z = rng.uniform(*zr)
        if not on_floor(x, z) or not flat_at(x, z) or (need_clear and not clear(x, z)) or rng.random() > want(x, z): continue
        put(model if isinstance(model, str) else model(), x, z, rng.random() * 360, rng.uniform(*scale), lift)
        count += 1


dry = lambda x, z: 1 - min(1.0, green_at(x, z) * 1.6)            # the upper canyon: stones, dead wood, wiry grass
wet = lambda x, z: min(1.0, green_at(x, z) * 1.8)                 # round the shelf: ferns, clover, flowers, moss stones
scatter(lambda: f"PalePebble{rng.integers(1, 4)}", 260, (-40, 44), (-170, 16), (0.8, 2.4), lambda x, z: (0.3 + 0.7 * dry(x, z)) if off_route(x, z, 1.9) and np.hypot(x + 0.5, z - 3.1) > 3 else 0.0, -0.02, need_clear=False)
scatter(lambda: f"PaleRock{rng.integers(1, 4)}", 34, (-44, 48), (-175, -20), (0.8, 2.6), dry, -0.3)
scatter(lambda: f"Rock{rng.integers(1, 4)}", 16, (-30, 34), (-40, 14), (0.7, 1.8), wet, -0.3)                    # the kit's mossy stones, only where it is green
scatter(lambda: f"DeadTree{rng.integers(1, 3)}", 9, (-40, 44), (-175, -46), (0.7, 1.2), dry)
scatter("WispyGrass", 70, (-44, 48), (-175, 14), (0.7, 1.3), lambda x, z: 0.5)
scatter("GrassTuft", 60, (-40, 44), (-80, 15), (0.8, 1.4), lambda x, z: 0.15 + wet(x, z))
scatter("Bush", 16, (-40, 44), (-70, 12), (0.8, 1.4), lambda x, z: 0.2 + wet(x, z))
scatter("Fern", 34, (-30, 34), (-44, 15), (0.8, 1.5), wet)
scatter("Clover", 40, (-26, 30), (-34, 15), (0.8, 1.4), wet)
scatter("Plant1", 12, (-26, 30), (-34, 14), (0.8, 1.3), wet)
scatter("Plant7", 12, (-26, 30), (-34, 14), (0.7, 1.2), wet)
scatter("Mushroom", 14, (-22, 26), (-28, 14), (0.8, 1.4), wet)
scatter("FlowerPatch", 14, (-24, 28), (-30, 14), (0.8, 1.4), wet)
scatter("FlowerPatch2", 12, (-24, 28), (-30, 14), (0.8, 1.4), wet)
for x, z, s in [(-20, 4, 1.1), (24, 6, 1.25), (26, -28, 1.0)]: put("Alder", x, z, rng.random() * 360, s)          # shade trees by the shelf (dappled light at the end)
put("Oak1", -24, -30, 140, 0.75)
for x, z, s in [(6.5, -4.5, 0.9), (-3.5, 5.0, 0.7), (11, 8, 1.2)]: put("Rock2", x, z, rng.random() * 360, s, lift=-0.25)


def wall_x(side, z, h):
    """the x where the canyon side (-1 left, +1 right) first reaches height h"""
    for x in np.arange(20.0, 109.0, 0.5):
        if wall(side * x, z) >= h: return side * x
    return side * 109.0


for side in (-1, 1):                                             # rounded clay ledges on the bench edges, so the sides are sculpted and not only painted
    for z in np.arange(22.0, -180.0, -17.0):
        zz = z + rng.uniform(-3, 3)
        for k in range(1, 8):
            if rng.random() < 0.25: continue
            hgt = k * BENCH - rng.uniform(0.6, 1.8)
            x = wall_x(side, zz, hgt) + side * rng.uniform(0.5, 3.0)
            zc = zz + rng.uniform(-5, 5)
            put("ClaySlab" + "ABC"[int(rng.integers(0, 3))], x, zc, 90 + rng.uniform(-14, 14), rng.uniform(0.8, 1.3), y=float(terraces(x, zc)) + hgt)
for side, z, k in [(-1, -24, 1), (1, -36, 2), (-1, -70, 2), (1, -96, 1), (-1, -120, 3), (1, -6, 1)]:            # cave mouths in the bench faces, looking into the canyon
    x = wall_x(side, z, k * BENCH + 0.5)
    put("CaveMouth", x + side * 0.6, z, 90 if side < 0 else 270, rng.uniform(0.9, 1.3), y=float(terraces(x, z)) + k * BENCH)
for k in range(0, 4):                                            # each terrace edge is a stack of rounded plates, as in the reference
    for x in np.arange(-38.0, 44.0, 11.0):
        xx = x + rng.uniform(-3, 3); zr = float(riser_z(k, xx))
        if (k in RAMPS and abs(xx - RAMPS[k]) < 13) or abs(xx - float(stream_x(zr))) < 5 or wall(xx, zr) > 6: continue
        topy = float(terraces(xx, zr - 4.0))
        for j, back in enumerate((0.4, -0.5)):
            put("ClaySlab" + "ABC"[int(rng.integers(0, 3))], xx, zr - back, rng.uniform(-10, 10), rng.uniform(0.75, 1.05), y=topy - 1.3 - j * rng.uniform(3.0, 4.2))
falls = []
for k in range(0, 5):                                            # the stream goes over every terrace face
    hk = RISERS[k][1]
    x = float(stream_x(RISERS[k][0])); zr = float(riser_z(k, x))
    yfoot = float(terraces(x, zr + 3.0))
    put("Waterfall", x, zr + 1.4, 0, hk / 9.0, y=yfoot - 0.6)
    falls.append((round(-x, 2), round(yfoot, 2), round(-(zr + 1.4), 2), hk))
put("RopeBridge", 2.0, -30.0, 0, 1.09, y=float(terraces(0, -30.0)) + 30.0)                                        # high across the canyon, bench to bench

L = ["-- GENERATED by design3d/mossback_world.py. Do not edit by hand.",
     "-- Where everything of the Mossback Pickaxe setting stands, in Roblox stage space (x and z flipped from the authoring space).",
     "-- route: the snail's way from where the boulder lands down to the shelf, a point every 1.5 studs. fall: the boulder's line down the canyon side.",
     "-- levels: the terraces the monsoon fills { y, z of the middle, depth along z }. falls: { x, y of the foot, z, height }.",
     "return {", "\tpool = { %s, %s, %s }," % (round(-POOL[0], 2), round(float(G(*POOL)), 2), round(-POOL[1], 2))]
L.append("\troute = { " + ", ".join("{ %s, %s, %s }" % p for p in stage(route)) + " },")
L.append("\tfall = { " + ", ".join("{ %s, %s, %s }" % p for p in stage(FALL)) + " },")
lv = []
for k in (0, 1):                                                 # terrace k+1 lies between face k and face k+1
    z0, z1 = RISERS[k][0] - 6.0, RISERS[k + 1][0] + 6.0
    lv.append("{ %s, %s, %s }" % (round(sum(r[1] for r in RISERS[:k + 1]), 2), round(-(z0 + z1) / 2, 2), round(z0 - z1, 2)))
L.append("\tlevels = { " + ", ".join(lv) + " },")
L.append("\tfalls = { " + ", ".join("{ %s, %s, %s, %s }" % f for f in falls) + " },")
L.append("\titems = {")
for it in items: L.append('\t\t{ "%s", %s, %s, %s, %s, %s },' % it)
L += ["\t},", "}"]
(here.parent / "src" / "ForgeMossbackMap.luau").write_text("\n".join(L) + "\n", encoding="utf-8", newline="\n")
# self-check: the route never jumps (a gap here would teleport the snail), and it ends on the level shelf
ys = [p[1] for p in stage(route)]
assert max(abs(a - b) for a, b in zip(ys, ys[1:])) < 1.6, "route has a step in it"
assert abs(ys[-1]) < 0.4 and abs(ys[0] - 17.0) < 0.8, ("route ends", ys[0], ys[-1])
print("wrote ForgeMossbackMap.luau:", len(items), "items,", len(route), "route points")
