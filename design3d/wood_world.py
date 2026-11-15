"""The Wood Pickaxe setting: a mountain lake at the edge of a spruce forest (reference: refs/forge/scene_cabin_lake.jpg).
    python design3d/wood_world.py
Writes, all from ONE height function so the ground, its painted pictures and every placed object agree:
    design3d/tex/wood_terrain.mjs   heights of the near meadow and the far valley (read by wood.mjs)
    design3d/tex/wood_meadow.png    the meadow painted from above: grass, wildflowers, wet shore, lake bed, camp dirt
    design3d/tex/wood_valley.png    the mountains painted from above: alpine grass, spruce forest, scree
    design3d/tex/wood_sky_<look>_side|up|dn.png   three skies (storm, night, dawn); the lower half of a side is the mirrored
                                    sky that shows in the lake
    design3d/tex/wood_ripple.png, wood_rain.png
    src/ForgeWoodMap.luau           where every tree, flower patch, rock and the cabin stands (Roblox stage space)
Space here is the authoring space of wood.mjs: x to screen right, y up, z toward the camera; the camp is at the origin."""
import json, pathlib
import numpy as np
from PIL import Image, ImageFilter

here = pathlib.Path(__file__).resolve().parent
tex = here / "tex"; tex.mkdir(exist_ok=True)
LAKE_Y = -2.2
CABIN = (20.0, -92.0)
NEAR = (-110.0, -170.0, 110.0, 50.0)   # x0, z0, x1, z1
FAR = (-1000.0, -1650.0, 1000.0, 150.0)
N = 96


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


def lake_sd(x, z):  # about studs: negative inside the lake
    u = (x + 12) / 52.0; v = (z + 54 + 7 * np.sin((x + 12) / 28.0)) / 24.0
    return (np.sqrt(u * u + v * v) - 1 - 0.16 * (fbm(x * 0.035, z * 0.035, 5) - 0.5)) * 24.0


def mountains(x, z):
    def mass(cx, cz, H, R): return H * np.clip(1 - np.hypot(x - cx, z - cz) / R, 0, 1) ** 1.35
    m = mass(440, -560, 350, 570) + mass(-480, -520, 300, 530) + mass(40, -1420, 300, 620) + mass(940, -1000, 300, 520) + mass(-960, -1100, 320, 540)
    ridged = 1 - np.abs(fbm(x * 0.0035, z * 0.0035, 31) * 2 - 1)
    return m * (0.78 + 0.4 * ridged) + (fbm(x * 0.011, z * 0.011, 37) - 0.5) * 26 * smooth(4, 60, m)


def G(x, z):
    x = np.asarray(x, dtype=np.float64); z = np.asarray(z, dtype=np.float64)
    base = (fbm(x * 0.03, z * 0.03, 1) - 0.5) * 3.0 + (fbm(x * 0.11, z * 0.11, 2) - 0.5) * 0.5
    flat = smooth(10, 24, np.hypot(x, np.where(z < 0, z, z * 0.3)))          # the camp and the camera's ground are level
    h = base * flat
    d = lake_sd(x, z)
    h = mix(LAKE_Y - 0.55, h, smooth(-1.5, 13, d))                             # the bank runs down to the water
    h = np.where(d < 0, np.maximum(LAKE_Y - 0.55 + d * 0.3, LAKE_Y - 4.0), h)  # the bed
    back = smooth(-86, -175, z)
    h = h + back * (24 + (fbm(x * 0.02, z * 0.02, 3) - 0.5) * 8) + smooth(62, 115, np.abs(x)) * 9
    cab = smooth(9, 22, np.hypot(x - CABIN[0], z - CABIN[1]))                  # a level terrace for the cabin
    h = mix(LAKE_Y + 1.7, h, cab)
    return h + mountains(x, z)


def grid(rect, n):
    x0, z0, x1, z1 = rect
    xs = np.linspace(x0, x1, n + 1); zs = np.linspace(z0, z1, n + 1)
    X, Z = np.meshgrid(xs, zs)
    return X, Z


def pixels(rect, size):
    x0, z0, x1, z1 = rect
    xs = x0 + (np.arange(size) + 0.5) / size * (x1 - x0); zs = z0 + (np.arange(size) + 0.5) / size * (z1 - z0)
    return np.meshgrid(xs, zs)


def rgb(h): h = h.lstrip("#"); return np.array([int(h[i:i + 2], 16) for i in (0, 2, 4)], dtype=np.float64)


def paint(shape, col): return np.ones(shape + (3,)) * rgb(col)


def lay(img, col, a):  # blend a colour over the picture by a mask
    c = rgb(col) if isinstance(col, str) else col
    return img * (1 - a[..., None]) + c * a[..., None]


def save(name, img, mode="RGB"):
    Image.fromarray(np.clip(img, 0, 255).astype(np.uint8), mode).save(tex / name)
    print("wrote", name)


rng = np.random.default_rng(11)

# ---------------- heights ----------------
NX, NZ = grid(NEAR, N); nearH = G(NX, NZ)
nearD = lake_sd(NX, NZ)
FX, FZ = grid(FAR, N); farH = G(FX, FZ) - 3.0
out = {
    "lakeY": LAKE_Y, "cabin": [CABIN[0], float(G(*CABIN)), CABIN[1]],
    "near": {"rect": NEAR, "h": np.round(nearH, 3).tolist(), "d": np.round(nearD, 2).tolist()},
    "far": {"rect": FAR, "h": np.round(farH, 2).tolist()},
}
(tex / "wood_terrain.mjs").write_text("// GENERATED by design3d/wood_world.py. Do not edit by hand.\nexport default " + json.dumps(out, separators=(",", ":")) + ";\n", encoding="utf-8")
print("wrote wood_terrain.mjs")

# ---------------- the meadow, painted from above ----------------
S = 1024
X, Z = pixels(NEAR, S)
d = lake_sd(X, Z)
n1 = fbm(X * 0.05, Z * 0.05, 41); n2 = fbm(X * 0.4, Z * 0.4, 42, 3); n3 = vnoise(X * 2.3, Z * 2.3, 43)
img = mix(paint((S, S), "#4a6a44"), paint((S, S), "#6f8a4c"), n1[..., None])
img = lay(img, "#3c5a40", smooth(0.55, 0.8, fbm(X * 0.02, Z * 0.02, 44)) * 0.6)          # darker, damper patches
img = lay(img, "#8a9a52", smooth(0.6, 0.85, n2) * 0.35)                                  # dry, lighter blades
img = img * (0.9 + 0.2 * n3[..., None])
img = lay(img, "#35523f", smooth(-95, -150, Z) * 0.55)                                   # forest floor under the far trees
# wildflowers: carpets of yellow and orange specks, thick near the camera and on the far bank (as in the reference)
field = smooth(0.5, 0.74, fbm(X * 0.028, Z * 0.028, 51)) * smooth(2.5, 7, d) * (1 - smooth(-100, -135, Z))
field = field * smooth(34, 52, np.hypot(X, Z + 2))  # the camp and the camera ground stay grass: real flowers stand there
r = rng.random((S, S))
for colr, lo, hi in (("#e8a516", 0.0, 0.07), ("#f2c230", 0.07, 0.13), ("#d98510", 0.13, 0.16), ("#f6e08a", 0.16, 0.175), ("#f4f0e0", 0.175, 0.183)):
    spot = ((r >= lo) & (r < hi * 1.0)).astype(np.float64) * (rng.random((S, S)) < field * 0.32)
    spot = np.asarray(Image.fromarray((spot * 255).astype(np.uint8)).filter(ImageFilter.MaxFilter(3)).filter(ImageFilter.GaussianBlur(0.5))) / 255.0
    img = lay(img, colr, np.clip(spot * 1.3, 0, 1))
# the shore: wet earth and pebbles, then the bed under the water
img = lay(img, "#4d4a3c", (1 - smooth(0.3, 3.2, d)) * (d > -1))
peb = (rng.random((S, S)) < 0.05 * (1 - smooth(0.2, 2.6, d)) * (d > -3)).astype(np.float64)
peb = np.asarray(Image.fromarray((peb * 255).astype(np.uint8)).filter(ImageFilter.MaxFilter(3)).filter(ImageFilter.GaussianBlur(0.6))) / 255.0
img = lay(img, mix(rgb("#6c6c66"), rgb("#9a968c"), n3[..., None]), np.clip(peb * 1.4, 0, 1))
img = lay(img, "#2c3b34", smooth(0.5, -2.5, d))
img = lay(img, "#18241f", smooth(-2, -9, d))
# the camp: trodden earth round the fire (authoring x = -0.6, z = 3.0), a worn path to the log
img = lay(img, "#5c4a3a", (1 - smooth(1.4, 3.0, np.hypot(X + 0.6, Z - 3.0))) * 0.9)
img = lay(img, "#6a5a42", (1 - smooth(0.8, 2.2, np.abs(X - 1.0 - (Z - 2.6) * 0.3))) * (1 - smooth(4, 7, np.hypot(X - 1, Z - 2.6))) * 0.35)
save("wood_meadow.png", img * 0.96)

# ---------------- the mountains, painted from above ----------------
X, Z = pixels(FAR, S)
h = G(X, Z)
gy, gx = np.gradient(h, (FAR[3] - FAR[1]) / S, (FAR[2] - FAR[0]) / S)
slope = np.hypot(gx, gy)
m1 = fbm(X * 0.004, Z * 0.004, 61); m2 = fbm(X * 0.02, Z * 0.02, 62); m3 = vnoise(X * 0.31, Z * 0.31, 63); m4 = vnoise(X * 0.9, Z * 0.9, 64)
img = mix(paint((S, S), "#557a4e"), paint((S, S), "#7b9659"), m1[..., None])
img = lay(img, "#8fa064", smooth(0.5, 0.8, m2) * 0.4)
img = lay(img, "#c9a23a", smooth(0.62, 0.8, fbm(X * 0.012, Z * 0.012, 65)) * 0.25 * (h < 60))      # far flower meadows, a yellow cast
scree = smooth(150, 300, h + (m2 - 0.5) * 120) * 0.85 + smooth(0.75, 1.2, slope) * 0.6
img = lay(img, mix(rgb("#8a6a5a"), rgb("#7a7672"), m1[..., None]), np.clip(scree, 0, 1) * (0.55 + 0.45 * m3))
forest = smooth(0.42, 0.54, fbm(X * 0.0055, Z * 0.0055, 66) * 0.7 + fbm(X * 0.022, Z * 0.022, 67) * 0.3 + 0.22 * (1 - np.clip(h / 240, 0, 1)) - 0.25 * smooth(200, 300, h))
forest = forest * smooth(6, 30, h + m2 * 20)                                                  # none on the valley floor meadows
edge = (m4 < forest * 1.25).astype(np.float64)                                               # a ragged tree line: single trees at the edge
img = lay(img, mix(rgb("#16302e"), rgb("#2c4c40"), m3[..., None] * 0.9 + 0.1 * m4[..., None]), np.clip(forest * edge, 0, 1) * 0.96)
img = img * (0.92 + 0.16 * m4[..., None])
save("wood_valley.png", img * 1.05)
forest_far = forest  # kept for placing the 3D clumps


def forest_at(x, z):
    j = np.clip(((np.asarray(z) - FAR[1]) / (FAR[3] - FAR[1]) * S).astype(int), 0, S - 1); i = np.clip(((np.asarray(x) - FAR[0]) / (FAR[2] - FAR[0]) * S).astype(int), 0, S - 1)
    return forest_far[j, i]


# ---------------- skies ----------------
def sky(look, top, mid, hor, cdark, clight, cover, amount, stars=0, band=None):
    W = 1024; Hh = 512
    u = (np.arange(W) + 0.5) / W; t = (np.arange(Hh) + 0.5) / Hh       # t: 0 zenith .. 1 horizon
    U, T = np.meshgrid(u, t)
    k = smooth(0, 0.62, T)[..., None]; k2 = smooth(0.62, 1, T)[..., None]
    img = mix(mix(rgb(top), rgb(mid), k), rgb(hor), k2)
    if band is not None: img = lay(img, band[0], np.exp(-((T - band[1]) / band[2]) ** 2) * band[3])
    if stars:
        st = np.zeros((Hh, W))
        ys = (rng.random(stars) ** 1.6 * Hh * 0.8).astype(int); xs = rng.integers(0, W, stars)
        st[ys, xs] = rng.random(stars) * 0.8 + 0.2
        big = np.zeros((Hh, W)); pick = rng.random(stars) < 0.12; big[ys[pick], xs[pick]] = 1
        st = np.maximum(st, np.asarray(Image.fromarray((big * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(1.1))) / 255.0 * 3.2)
        img = lay(img, "#fff6dc", np.clip(st, 0, 1) * (1 - smooth(0.55, 0.85, T)))
    # clouds flatten toward the horizon; the lattice is periodic in u so the four sides join
    P = 6
    yy = 1.6 / (1.12 - T)
    n = fbm(U * P, yy * 1.3, 71, 5, px=P) * 0.65 + fbm(U * P * 2 + 3.1, yy * 2.6, 72, 4, px=P * 2) * 0.35
    a = smooth(cover, cover + 0.22, n) * amount * smooth(0.04, 0.2, T)
    lit = smooth(0.35, 0.75, fbm(U * P + 0.37, yy * 1.3 - 0.25, 71, 5, px=P))            # the same clouds, shifted: their lit side
    cc = mix(rgb(cdark), rgb(clight), (lit * smooth(0.2, 1.0, T))[..., None])
    img = img * (1 - a[..., None]) + cc * a[..., None]
    refl = img[::-1] * np.array([0.5, 0.58, 0.6]) + rgb("#0e1a1c") * 0.35               # what the lake shows: the sky upside down, darker and greener
    save(f"wood_sky_{look}_side.png", np.vstack([img, refl]))
    save(f"wood_sky_{look}_up.png", np.ones((8, 8, 3)) * img[0, 0])
    save(f"wood_sky_{look}_dn.png", np.ones((8, 8, 3)) * refl[-1, 0])


sky("storm", "#39444e", "#55626b", "#aab4b8", "#27303a", "#69757d", 0.36, 0.95)
sky("night", "#0c1630", "#1c3152", "#5d7f98", "#101c33", "#3b5878", 0.5, 0.7, stars=900, band=("#b89a8c", 0.97, 0.06, 0.35))
sky("dawn", "#4b5f93", "#b98ba6", "#ffd9a0", "#6b5a86", "#ffc79a", 0.47, 0.8, band=("#fff0c0", 0.98, 0.07, 0.6))

# ripples: thin horizontal glints (alpha); rain: one soft streak
W = 512
U, V = np.meshgrid(np.arange(W) / W, np.arange(W) / W)
rp = smooth(0.62, 0.8, fbm(U * 6, V * 40, 81, 4, px=6)) * 0.9
save("wood_ripple.png", np.dstack([np.ones((W, W, 3)) * 255, rp * 255]), "RGBA")
yy, xx = np.meshgrid(np.linspace(0, 1, 256), np.linspace(-1, 1, 32), indexing="ij")
a = np.exp(-(xx / 0.28) ** 2) * np.sin(np.pi * yy) ** 0.6
save("wood_rain.png", np.dstack([np.ones((256, 32, 3)) * 255, a * 255]), "RGBA")

# ---------------- where things stand ----------------
items = []


def put(model, x, z, yaw=0.0, scale=1.0, lift=0.0, mirror=False):
    y = float(G(x, z)) + lift
    items.append({"m": model, "p": [round(-x, 2), round(y, 2), round(-z, 2)], "yaw": round(yaw, 1), "s": round(scale, 3), "mir": mirror})  # Roblox stage space: x and z flip


def free(x, z):  # not in the action, not in the water, not on the cabin
    return not (-11 < x < 9 and -8 < z < 20) and lake_sd(x, z) > 2.5 and np.hypot(x - CABIN[0], z - CABIN[1]) > 15


# the giants that frame the view (the dark spruce at the reference's left edge), then the forest edge behind the cabin
for (x, z, s, k) in [(-27, -3, 1.3, 1), (-36, -15, 1.12, 2), (-21, -19, 0.78, 3), (31, -7, 1.05, 2), (41, -19, 1.2, 1), (26, -22, 0.7, 3), (-48, 6, 1.2, 1), (52, 4, 1.1, 2)]:
    put(f"Spruce{k}", x, z, rng.random() * 360, s)
count = 0
while count < 46:
    x = rng.uniform(-104, 104); z = rng.uniform(-162, -84)
    if not free(x, z) or abs(x - CABIN[0]) < 20 and z > -104: continue
    put(f"Spruce{rng.integers(1, 4)}", x, z, rng.random() * 360, rng.uniform(0.75, 1.35), mirror=z > -128)
    count += 1
count = 0
while count < 16:  # the lake's side banks
    side = rng.choice([-1, 1]); x = side * rng.uniform(52, 104); z = rng.uniform(-82, -18)
    if not free(x, z) or lake_sd(x, z) < 6: continue
    put(f"Spruce{rng.integers(1, 4)}", x, z, rng.random() * 360, rng.uniform(0.7, 1.25), mirror=True)
    count += 1
# clumps of small spruces on the painted forest of the slopes
count, tries = 0, 0
while count < 90 and tries < 20000:
    tries += 1
    x = rng.uniform(-940, 940); z = rng.uniform(-1500, -150)
    if NEAR[0] < x < NEAR[2] and z > NEAR[1]: continue
    if forest_at(x, z) < 0.75: continue
    dist = np.hypot(x, z)
    put("PineClump", x, z, rng.random() * 360, float(np.clip(0.9 + dist / 520, 1.0, 3.0)), lift=-1.0)
    count += 1
# wildflowers, grass and rocks round the camp, thick toward the camera and down the bank
for model, n, rmax in (("FlowerPatch", 70, 44), ("GrassTuft", 90, 40)):
    count = 0
    while count < n:
        a = rng.uniform(0, 2 * np.pi); rr = rng.uniform(4.5, rmax) ** 1.0
        x = np.cos(a) * rr * 1.25; z = np.sin(a) * rr - 4
        if not free(x, z): continue
        put(model, x, z, rng.random() * 360, rng.uniform(0.8, 1.35) * (0.6 if model == "GrassTuft" else 1.0))
        count += 1
count = 0
while count < 22:  # boulders on the near shore and in the meadow
    x = rng.uniform(-70, 60); z = rng.uniform(-34, -8)
    dd = lake_sd(x, z)
    if dd < -1.5 or dd > 7: continue
    put(f"Rock{rng.integers(1, 3)}", x, z, rng.random() * 360, rng.uniform(0.6, 1.7), lift=-0.25)
    count += 1
for (x, z, s) in [(-12, -9, 1.2), (10.5, -9, 0.9), (-15.5, 3, 1.0)]: put("Rock1", x, z, rng.random() * 360, s, lift=-0.2)
for (x, z) in [(-4.5, -1.5), (6.5, -1.0), (8.5, 3.5), (-3.2, -5.5), (4.6, -5.2), (-8.6, 1.0), (0.5, -6.5), (7.4, -6.6)]: put("FlowerPatch", x, z, rng.random() * 360, 0.9)
for (x, z) in [(-3.4, 0.6), (5.6, 0.4), (-6.5, -3.0), (2.0, -4.6), (8.0, 0.8), (-1.5, -7.5)]: put("GrassTuft", x, z, rng.random() * 360, 0.55)
put("Cabin", CABIN[0], CABIN[1], -14, 1.0, lift=0.0, mirror=True)

lines = ["-- GENERATED by design3d/wood_world.py. Do not edit by hand.", "-- Where everything of the Wood Pickaxe setting stands, in Roblox stage space (x and z flipped from the authoring space).",
         "return {", f"\tlakeY = {LAKE_Y},", "\titems = {"]
for it in items:
    lines.append(f'\t\t{{ "{it["m"]}", {it["p"][0]}, {it["p"][1]}, {it["p"][2]}, {it["yaw"]}, {it["s"]}{", true" if it["mir"] else ""} }},')
lines += ["\t},", "}"]
(here.parent / "src" / "ForgeWoodMap.luau").write_text("\n".join(lines) + "\n", encoding="utf-8", newline="\n")
print("wrote ForgeWoodMap.luau:", len(items), "items")
