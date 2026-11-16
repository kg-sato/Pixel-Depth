"""The Kiln Pickaxe setting: a potter's yard cut into a red clay cliff, terraced clay pits stepping down behind it to a
winding red river, clay hills beyond (reference: refs/forge/sheets/kiln_setting_s11.png; scene bible "Kiln").
    python design3d/kiln_world.py
Writes, from ONE height function: design3d/tex/kiln_terrain.mjs (near yard and terraces, far valley), kiln_floor.png (packed
clay yard, terrace treads and risers, wet pits, cliff strata, the river, painted from above), kiln_far.png, two skies
(afternoon, dusk) and src/ForgeKilnMap.luau (stones, bushes, reeds, dead trees, far trees). Authoring space: x to screen
right, y up, z toward the camera; the wheel stands at (1.5, 0), the kiln at (-9, -7); the cliff is on the left, the yard's
far edge is at z = -14 and the terraces fall away behind it to the river near z = -138."""
import json, pathlib
import numpy as np
from PIL import Image, ImageFilter

here = pathlib.Path(__file__).resolve().parent
tex = here / "tex"; tex.mkdir(exist_ok=True)
WATER_Y = -23.5
NEAR = (-110.0, -170.0, 110.0, 50.0)
FAR = (-1000.0, -1650.0, 1000.0, 150.0)
N = 96
STEP = 3.2          # one terrace down
TREAD = 14.0        # how deep a terrace is
LEVELS = 7


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


def terr_d(x, z):
    """studs past the yard's far edge, measured down the terraces (the edge wanders a little)"""
    return (-14.0 - z) + 5.0 * np.sin(x / 25.0) * smooth(0, 30, -14.0 - z) + (fbm(x * 0.03, z * 0.03, 4) - 0.5) * 6.0 * smooth(4, 30, -14.0 - z)


def terraces(x, z):
    """the yard (level, y = 0) and the clay pits below it: seven treads with a short rounded riser each and a low rim"""
    d = terr_d(x, z)
    k = np.clip(d / TREAD, 0, LEVELS)
    lv = np.floor(k); fr = k - lv
    h = -STEP * (lv + smooth(0.0, 0.17, fr))
    h = np.where(k >= LEVELS, -STEP * LEVELS, h)
    rim = 0.3 * smooth(0.86, 0.95, fr) * (1 - smooth(0.97, 1.0, fr)) * (k < LEVELS) * (d > 0)
    pit = -0.45 * smooth(0.5, 0.68, fbm(x * 0.07, z * 0.07, 5)) * smooth(0.28, 0.42, fr) * (1 - smooth(0.7, 0.84, fr)) * (d > 0) * (k < LEVELS)
    return np.where(d > 0, h + rim + pit, 0.0)


def river_z(x): return -138.0 + 16.0 * np.sin(x / 55.0)      # the red river's middle line
def river_d(x, z): return np.abs(z - river_z(x)) - 13.0      # studs outside the water's edge (negative in the river)


def cliff(x, z):
    """The clay cliff the yard is cut into (left), and the lower bluff on the right with the dug bank at its foot."""
    left = smooth(-22, -42, x + 4 * np.sin(z / 30.0) + (fbm(x * 0.03, z * 0.03, 7) - 0.5) * 8)
    lh = left * 52.0
    lh = lh + 1.8 * np.sin(lh * 0.6) * smooth(2, 10, lh) * (1 - smooth(40, 51, lh))       # ledges, as the rain cut them
    bank = smooth(20.5, 23.5, x) * 2.4 * smooth(-17, -13, z)                                                     # the bank she digs her clay from
    rh = smooth(31, 52, x - 3 * np.sin(z / 40.0 + 1.0) + (fbm(x * 0.03, z * 0.03, 8) - 0.5) * 8) * 44.0                 # the reference has a red cliff on both sides: the terraces are seen through the gap
    right = rh + 1.6 * np.sin(rh * 0.6 + 1.0) * smooth(2, 10, rh) * (1 - smooth(34, 43, rh))
    open_ = 1 - 0.75 * smooth(-110, -260, z)                                               # down the valley the walls fall away
    return (lh + bank + right) * open_


def hills(x, z):
    def mass(cx, cz, H, R): return H * np.clip(1 - np.hypot(x - cx, z - cz) / R, 0, 1) ** 1.4
    return mass(-300, -820, 190, 480) + mass(280, -980, 230, 540) + mass(-40, -1400, 290, 640) + mass(-820, -420, 130, 480) + mass(820, -460, 120, 480)


def G(x, z):
    x = np.asarray(x, dtype=np.float64); z = np.asarray(z, dtype=np.float64)
    t = terraces(x, z)
    d = river_d(x, z)
    bed = WATER_Y - 1.1 + (fbm(x * 0.1, z * 0.1, 3) - 0.5) * 0.3
    t = np.where(d < 0, mix(t, bed, smooth(0, -3.0, d)), t)
    beyond = smooth(0, 220, river_z(x) - 13.0 - z) * 34.0                                  # past the river the land climbs again
    return t + cliff(x, z) + beyond + hills(x, z) * smooth(-260, -480, z)


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
out = {"waterY": WATER_Y, "near": {"rect": NEAR, "h": np.round(G(NX, NZ), 3).tolist()}, "far": {"rect": FAR, "h": np.round(G(FX, FZ) - 3.0, 2).tolist()}}
(tex / "kiln_terrain.mjs").write_text("// GENERATED by design3d/kiln_world.py. Do not edit by hand.\nexport default " + json.dumps(out, separators=(",", ":")) + ";\n", encoding="utf-8")
print("wrote kiln_terrain.mjs")
assert abs(float(G(1.5, 0.0))) < 0.01 and abs(float(G(-9.0, -7.0))) < 0.01 and abs(float(G(5.0, 9.0))) < 0.01, "the yard must be level under the wheel, the kiln and the cameras"
assert 2.2 < float(G(24.0, 1.0)) < 2.6, "the dug bank stands 2.4 high at x = 24"


def strata(h, n1, n2):
    """Clay cliff colour by height: rust and ochre bands with thin cream seams and a few dark iron lines."""
    band = np.sin(h * 0.55 + n1 * 3.0) * 0.5 + 0.5
    col = mix(rgb("#9f3526"), rgb("#c85a3c"), band[..., None])
    seam = smooth(0.84, 0.97, np.sin(h * 1.7 + n2 * 4.0) * 0.5 + 0.5)
    col = col * (1 - 0.5 * seam[..., None]) + rgb("#dd8a62") * (0.5 * seam[..., None])
    iron = smooth(0.9, 0.99, np.sin(h * 0.93 + n1 * 5.0 + 1.7) * 0.5 + 0.5)
    col = col * (1 - 0.45 * iron[..., None]) + rgb("#6e2218") * (0.45 * iron[..., None])
    return col * (0.9 + 0.18 * n2[..., None])


def slope_of(h, rect, size):
    cell = (rect[2] - rect[0]) / size
    gz, gx = np.gradient(h, cell)
    return np.hypot(gx, gz)


# ---------------- the yard and the terraces, painted from above ----------------
S = 1024
X, Z = pixels(NEAR, S)
h = G(X, Z); d = terr_d(X, Z); c = cliff(X, Z); rd = river_d(X, Z); sl = slope_of(h, NEAR, S)
n1 = fbm(X * 0.05, Z * 0.05, 41); n2 = fbm(X * 0.35, Z * 0.35, 42, 3); n3 = vnoise(X * 2.1, Z * 2.1, 43)
img = mix(paint((S, S), "#b9603f"), paint((S, S), "#cf7d55"), n1[..., None]) * (0.92 + 0.16 * n3[..., None])       # the yard: packed clay, trodden pale
img = lay(img, "#dd9a74", smooth(0.55, 0.8, fbm(X * 0.12, Z * 0.12, 44)) * 0.5)                                    # dry slip dust
crack = smooth(0.47, 0.5, np.abs(fbm(X * 0.5, Z * 0.5, 45, 3) - 0.5) * -1 + 0.5)                                   # a net of drying cracks
img = lay(img, "#8a3a28", crack * 0.35)
img = lay(img, "#96452f", (1 - smooth(1.6, 4.2, np.hypot(X - 1.5, Z - 0.0))) * 0.75)                               # wet clay round the wheel
img = lay(img, "#d9cfc2", (1 - smooth(0.6, 2.4, np.hypot(X - 1.9, Z - 0.6))) * 0.55)                               # a grey slip splash by it
img = lay(img, "#5a4640", (1 - smooth(3.6, 7.5, np.hypot(X + 9.0, Z + 7.0))) * 0.6)                                # soot and ash round the kiln
img = lay(img, "#8f4a32", (1 - smooth(0.0, 2.6, np.abs(X - 21.5))) * (np.abs(Z - 1.0) < 5) * 0.6)                  # fresh dug clay at the bank's foot
lvl = np.floor(np.clip(d / TREAD, 0, LEVELS))
tcol = np.zeros((S, S, 3))
for i, colr in enumerate(("#c7754f", "#b5553a", "#cf8560", "#a84a32", "#c26a48", "#a8452e", "#bd6444", "#9c4630")):
    tcol = np.where((lvl == i)[..., None], rgb(colr), tcol)
tcol = tcol * (0.9 + 0.2 * n1[..., None]) * (0.94 + 0.12 * n3[..., None])
img = np.where((d > 0)[..., None], tcol, img)
fr = np.clip(d / TREAD, 0, LEVELS) - lvl
pitm = smooth(0.5, 0.68, fbm(X * 0.07, Z * 0.07, 5)) * smooth(0.28, 0.42, fr) * (1 - smooth(0.7, 0.84, fr)) * (d > 0) * (lvl < LEVELS)
img = lay(img, "#863a28", pitm * 0.85)                                                                             # the wet pits
img = lay(img, "#d9c9b8", smooth(0.6, 0.9, pitm) * smooth(0.5, 0.7, n2) * 0.6)                                     # pale slip water standing in them
img = lay(img, "#f0d9b5", smooth(0.86, 0.95, fr) * (1 - smooth(0.97, 1.0, fr)) * (d > 0) * (lvl < LEVELS) * 0.5)   # a sun-dried rim
img = lay(img, "#8a3524", smooth(0.45, 1.3, sl) * (c < 3.0) * 0.85)                                      # the risers: dark cut clay
img = lay(img, "#8a9a5a", smooth(0.6, 0.78, fbm(X * 0.09, Z * 0.09, 46)) * (d > 8) * (1 - pitm) * (sl < 0.4) * 0.45)   # thin dry grass further down
img = np.where((c > 3.0)[..., None], strata(h, n1, n2), img)
img = lay(img, "#6b3a2a", (1 - smooth(0.2, 2.0, np.abs(c - 3.0))) * 0.35)                                          # a shadow line where the cliff meets the ground
img = lay(img, "#a8884a", smooth(41.5, 44, c) * 0.8)                                                               # dry grass on top of the cliff
wat = mix(rgb("#b04a30"), rgb("#8f3a28"), smooth(0, -8, rd)[..., None]) * (0.9 + 0.2 * n3[..., None])              # the red river
img = np.where(((rd < 0) & (c < 3.0))[..., None], wat, img)
img = lay(img, "#7a3a28", (1 - smooth(0.0, 2.5, rd)) * (rd >= 0) * (c < 3.0) * 0.6)                                            # its wet banks
save("kiln_floor.png", img)

# ---------------- the far valley and the clay hills ----------------
X, Z = pixels(FAR, S)
h = G(X, Z); c = cliff(X, Z); hl = hills(X, Z) * smooth(-260, -480, Z); rd = river_d(X, Z); d = terr_d(X, Z)
m1 = fbm(X * 0.004, Z * 0.004, 61); m2 = fbm(X * 0.02, Z * 0.02, 62); m3 = vnoise(X * 0.3, Z * 0.3, 63)
img = mix(paint((S, S), "#b9603f"), paint((S, S), "#cf7d55"), m1[..., None])                                        # dry clay country
img = lay(img, "#a8452e", smooth(0.45, 0.6, fbm(X * 0.008, Z * 0.008, 64)) * 0.6)                                  # red earth
img = lay(img, "#9aa46a", smooth(0.5, 0.66, fbm(X * 0.006, Z * 0.006, 66)) * 0.55)                                 # dry grass and scrub
img = lay(img, "#6f8a58", smooth(0.62, 0.72, fbm(X * 0.012, Z * 0.012, 67)) * 0.6)                                 # a few woods
img = lay(img, "#a8809a", smooth(30, 150, hl) * 0.6)                                                               # the hills go dusty violet with height
img = lay(img, "#8a9ac4", smooth(120, 280, hl) * 0.65)                                                             # and blue at the top
face = smooth(0.25, 0.6, slope_of(c, FAR, S))                                                                     # only the cliff faces show their layers
img = img * (1 - face[..., None]) + strata(c, m1, m2) * face[..., None]
img = np.where(((rd < 6) & (c < 3.0))[..., None], rgb("#a8452e") * (0.9 + 0.2 * m3[..., None]), img)      # the river, wider than life so it reads from far
img = img * (0.94 + 0.12 * m3[..., None])
save("kiln_far.png", img)


# ---------------- skies ----------------
def sky(look, top, mid, hor, cdark, clight, cover, amount, band=None):
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
    refl = img[::-1] * np.array([0.7, 0.62, 0.6]) + rgb("#3a1c14") * 0.25
    save(f"kiln_sky_{look}_side.png", np.vstack([img, refl]))
    save(f"kiln_sky_{look}_up.png", np.ones((8, 8, 3)) * img[0, 0])
    save(f"kiln_sky_{look}_dn.png", np.ones((8, 8, 3)) * refl[-1, 0])


sky("afternoon", "#4f8fd0", "#a8cfe8", "#ffe2b0", "#e8c9a8", "#fff6e6", 0.6, 0.6, band=("#ffd9a0", 0.97, 0.1, 0.55))
sky("dusk", "#2b3f7c", "#6a6aa6", "#f29a78", "#4a4a7a", "#f2a890", 0.5, 0.75, band=("#ffb070", 0.99, 0.07, 0.6))

# ---------------- where things stand ----------------
items = []


def put(model, x, z, yaw=0.0, scale=1.0, lift=0.0):
    items.append((model, round(-x, 2), round(float(G(x, z)) + lift, 2), round(-z, 2), round(yaw, 1), round(scale, 3)))


def yard(x, z): return -23 < x < 25 and -15 < z < 34           # the working yard and the cameras' ground: only what is placed by hand


def on_tread(x, z):
    dd = float(terr_d(x, z))
    if dd <= 2: return False
    f = (dd / TREAD) % 1.0
    return 0.3 < f < 0.9 and float(cliff(x, z)) < 2.6 and float(river_d(x, z)) > 2


# hand-placed on the yard: stones along the cliff foot and the bank, a few pebbles at the edges, plants in the cliff's shade
for x, z, m, s in [(-19.5, -11.0, "PaleRock1", 1.6), (-20.5, 3.5, "PaleRock3", 1.3), (-18.5, 10.0, "PaleRock2", 1.1), (20.0, -6.5, "PaleRock2", 0.9),
                   (19.6, 6.5, "PaleRock1", 0.8), (17.5, 11.0, "PaleRock3", 0.7), (-17.0, -13.0, "Rock2", 1.0), (14.0, -13.2, "PaleRock1", 0.7)]:
    put(m, x, z, rng.random() * 360, s, lift=-0.25)
for x, z, m, s in [(-19.0, -4.5, "Fern", 1.2), (-19.4, 6.5, "Plant7", 1.0), (-18.0, 13.5, "Bush", 1.0), (19.2, -10.5, "Bush", 0.9), (19.4, 9.0, "WispyGrass", 1.2),
                   (-16.5, -9.5, "Plant1", 1.1), (18.8, 3.6, "GrassTuft", 1.2), (19.3, -1.8, "GrassTuft", 1.0), (6.5, -13.0, "FlowerPatch2", 1.0), (-3.0, -13.4, "WispyGrass", 1.1),
                   (13.0, -12.6, "GrassTuft", 1.2), (-12.0, 13.0, "FlowerPatch", 1.0)]:
    put(m, x, z, rng.random() * 360, s)
count = 0
while count < 46:                                              # pebbles at the yard's edges
    x = rng.uniform(-21, 23); z = rng.uniform(-14, 30)
    if -15 < x < 17 and -11 < z < 26: continue
    put(f"PalePebble{rng.integers(1, 4)}", x, z, rng.random() * 360, rng.uniform(0.6, 1.5), lift=-0.02)
    count += 1
count = 0
while count < 54:                                              # boulders: at the cliff's foot down the valley and on the treads
    x = rng.uniform(-70, 80); z = rng.uniform(-165, 30)
    cv = float(cliff(x, z))
    if yard(x, z) or cv > 9 or float(river_d(x, z)) < 1: continue
    foot = 0.5 < cv < 9
    if not foot and (not on_tread(x, z) or rng.random() < 0.6): continue
    put(f"PaleRock{rng.integers(1, 4)}" if rng.random() < 0.75 else f"Rock{rng.integers(1, 4)}", x, z, rng.random() * 360, rng.uniform(1.4, 3.6) if foot else rng.uniform(0.6, 1.5), lift=-0.3)
    count += 1
for model, n in (("Bush", 26), ("WispyGrass", 70), ("GrassTuft", 60), ("FlowerPatch2", 12), ("FlowerPatch", 8), ("Fern", 10), ("Plant1", 10), ("Plant7", 8), ("PalePebble1", 40), ("PalePebble2", 40)):
    count = 0
    while count < n:
        x = rng.uniform(-60, 70); z = rng.uniform(-168, -15)
        if yard(x, z) or not on_tread(x, z): continue
        put(model, x, z, rng.random() * 360, rng.uniform(0.8, 1.6))
        count += 1
count = 0
while count < 9:                                               # dead trees on the worked-out terraces
    x = rng.uniform(-50, 60); z = rng.uniform(-110, -24)
    if not on_tread(x, z): continue
    put(f"DeadTree{rng.integers(1, 3)}", x, z, rng.random() * 360, rng.uniform(0.7, 1.2))
    count += 1
count = 0
while count < 16:                                              # alders along the river, oaks on the land beyond it
    x = rng.uniform(-100, 100); z = rng.uniform(-168, -112)
    rd = float(river_d(x, z))
    if rd < 3 or float(cliff(x, z)) > 2: continue
    put("Alder" if rd < 14 else f"Oak{rng.integers(1, 3)}", x, z, rng.random() * 360, rng.uniform(0.9, 1.5))
    count += 1
lines = ["-- GENERATED by design3d/kiln_world.py. Do not edit by hand.", "-- Where everything of the Kiln Pickaxe setting stands, in Roblox stage space (x and z flipped from the authoring space).",
         "return {", f"\twaterY = {WATER_Y},", "\titems = {"]
for it in items: lines.append('\t\t{ "%s", %s, %s, %s, %s, %s },' % it)
lines += ["\t},", "}"]
(here.parent / "src" / "ForgeKilnMap.luau").write_text("\n".join(lines) + "\n", encoding="utf-8", newline="\n")
print("wrote ForgeKilnMap.luau:", len(items), "items")
