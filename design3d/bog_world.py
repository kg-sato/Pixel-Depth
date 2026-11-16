"""The Bog-Iron Pickaxe setting: a blackwater bog at dawn (reference: refs/forge/sheets/bog_setting_s11.png).
    python design3d/bog_world.py
Writes, all from ONE height function so the ground, its painted pictures and every placed object agree:
    design3d/tex/bog_terrain.mjs    heights of the near bog and the far moor (read by bog.mjs)
    design3d/tex/bog_ground.png     the bog painted from above: peat moss, cranberry mats, cotton grass, mud, the black bed
    design3d/tex/bog_far.png        the moor and the pine forest behind, painted from above
    design3d/tex/bog_sky_<look>_side|up|dn.png   three skies (mist = milky dawn, fire = the dim hour while the furnace burns,
                                    morning = clear); the lower half of a side is the mirrored sky that shows in the water
    src/ForgeBogMap.luau            where every dead tree, spruce, lily pad, cotton grass tuft and rock stands (Roblox stage space)
Space here is the authoring space of bog.mjs: x to screen right, y up, z toward the camera. The furnace island is at the origin
(level, about 9 studs radius); a plank walkway leaves it to screen left (-x) for a spit of land; the water lies 1 stud lower."""
import json, pathlib
import numpy as np
from PIL import Image, ImageFilter

here = pathlib.Path(__file__).resolve().parent
tex = here / "tex"; tex.mkdir(exist_ok=True)
WATER_Y = -1.0
NEAR = (-110.0, -170.0, 110.0, 50.0)   # x0, z0, x1, z1
FAR = (-1000.0, -1650.0, 1000.0, 150.0)
N = 96
SPIT = (-36.0, 1.0)                     # where the walkway lands


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


# ---- land and water: each is a signed distance in studs, positive on land ----
def island(x, z): return 12.5 - np.hypot(x, z) * (1 + 0.1 * (fbm(x * 0.15, z * 0.15, 5) - 0.5))


def spit(x, z): return 8.5 - np.hypot((x - SPIT[0]) * 0.6, z - SPIT[1])


def bank(x, z):  # the bog's far rim: an uneven ring, wider behind the island than in front of it
    return np.hypot(x * 0.82, (z + 28) * 0.95) - (76 + 22 * (fbm(x * 0.02, z * 0.02, 6) - 0.5))


def tussock(x, z):  # small moss islets; none close round the island, so the furnace has open water about it
    t = (fbm(x * 0.075, z * 0.075, 7) - 0.665) * 55
    return np.where(np.hypot(x, z) < 19, -5.0, t)


def land(x, z): return np.maximum(np.maximum(island(x, z), spit(x, z)), np.maximum(bank(x, z), tussock(x, z)))


def G(x, z):
    x = np.asarray(x, dtype=np.float64); z = np.asarray(z, dtype=np.float64)
    edge = WATER_Y - 0.4
    b = bank(x, z)
    hi = mix(edge, 0.0, smooth(0, 3.5, island(x, z)))                                  # the furnace island: level at 0
    hs = mix(edge, WATER_Y + 0.75, smooth(0, 3, spit(x, z)))
    ht = mix(edge, WATER_Y + 0.5 + 0.3 * fbm(x * 0.3, z * 0.3, 8), smooth(0, 2.5, tussock(x, z)))
    rise = smooth(0, 90, b) * 10 + (fbm(x * 0.03, z * 0.03, 1) - 0.5) * 3 * smooth(2, 25, b)
    hills = smooth(120, 700, b) * 70 * (0.5 + fbm(x * 0.004, z * 0.004, 31)) + smooth(500, 1300, -z) * 110 * (0.4 + fbm(x * 0.003, z * 0.003, 33))
    hb = mix(edge, WATER_Y + 0.8 + rise + hills, smooth(0, 5, b))
    h = np.maximum(np.maximum(hi, hs), np.maximum(ht, hb))
    d = land(x, z)
    return np.where(d < 0, np.maximum(edge + d * 0.3, WATER_Y - 3.0), h)                 # the peat bed


def grid(rect, n):
    x0, z0, x1, z1 = rect
    return np.meshgrid(np.linspace(x0, x1, n + 1), np.linspace(z0, z1, n + 1))


def pixels(rect, size):
    x0, z0, x1, z1 = rect
    xs = x0 + (np.arange(size) + 0.5) / size * (x1 - x0); zs = z0 + (np.arange(size) + 0.5) / size * (z1 - z0)
    return np.meshgrid(xs, zs)


def rgb(h): h = h.lstrip("#"); return np.array([int(h[i:i + 2], 16) for i in (0, 2, 4)], dtype=np.float64)


def paint(shape, col): return np.ones(shape + (3,)) * rgb(col)


def lay(img, col, a):
    c = rgb(col) if isinstance(col, str) else col
    return img * (1 - a[..., None]) + c * a[..., None]


def save(name, img, mode="RGB"):
    Image.fromarray(np.clip(img, 0, 255).astype(np.uint8), mode).save(tex / name)
    print("wrote", name)


def specks(mask, size, blur=0.5):
    return np.asarray(Image.fromarray((mask * 255).astype(np.uint8)).filter(ImageFilter.MaxFilter(size)).filter(ImageFilter.GaussianBlur(blur))) / 255.0


if __name__ == "__main__":
    rng = np.random.default_rng(17)

    # ---------------- heights ----------------
    NX, NZ = grid(NEAR, N); FX, FZ = grid(FAR, N)
    out = {"waterY": WATER_Y,
           "near": {"rect": NEAR, "h": np.round(G(NX, NZ), 3).tolist(), "d": np.round(land(NX, NZ), 2).tolist()},
           "far": {"rect": FAR, "h": np.round(G(FX, FZ) - 3.0, 2).tolist()}}
    (tex / "bog_terrain.mjs").write_text("// GENERATED by design3d/bog_world.py. Do not edit by hand.\nexport default " + json.dumps(out, separators=(",", ":")) + ";\n", encoding="utf-8")
    print("wrote bog_terrain.mjs")

    # ---------------- the bog, painted from above ----------------
    S = 1024
    X, Z = pixels(NEAR, S)
    d = land(X, Z); b = bank(X, Z)
    n1 = fbm(X * 0.05, Z * 0.05, 41); n2 = fbm(X * 0.4, Z * 0.4, 42, 3); n3 = vnoise(X * 2.3, Z * 2.3, 43)
    img = mix(paint((S, S), "#565a36"), paint((S, S), "#78793f"), n1[..., None])                 # peat moss, olive to sage
    img = lay(img, "#8a7a4a", smooth(0.55, 0.8, fbm(X * 0.03, Z * 0.03, 44)) * 0.5)              # dry sedge
    img = lay(img, "#7a3a3e", smooth(0.6, 0.78, fbm(X * 0.09, Z * 0.09, 45)) * 0.55 * (d > 0.5) * (d < 9))   # cranberry mats near the water
    img = img * (0.88 + 0.24 * n3[..., None])
    cot = specks((rng.random((S, S)) < 0.03 * smooth(0.5, 0.7, fbm(X * 0.04, Z * 0.04, 46)) * (d > 1.5)).astype(np.float64), 3)
    img = lay(img, "#eef0e6", np.clip(cot * 1.2, 0, 1))                                          # cotton grass heads
    img = lay(img, "#22282e", smooth(40, 110, b) * 0.6)                                          # under the pines
    img = lay(img, "#3a332c", (1 - smooth(0.2, 2.6, d)) * (d > -1))                              # wet peat at the water line
    img = lay(img, "#17130f", smooth(0.4, -2.0, d))                                              # the black bed
    img = lay(img, "#0b0a09", smooth(-2, -8, d))
    img = lay(img, "#6a5240", (1 - smooth(2.2, 5.0, np.hypot(X - 1.6, Z + 0.8))) * 0.85)         # trodden, baked earth round the furnace
    img = lay(img, "#9a4a26", (1 - smooth(0.8, 2.4, np.hypot(X - 4.6, Z - 0.8))) * 0.6)          # rust under the ore heap
    save("bog_ground.png", img)

    # ---------------- the moor and the forest behind ----------------
    X, Z = pixels(FAR, S)
    h = G(X, Z); bf = bank(X, Z)
    m1 = fbm(X * 0.004, Z * 0.004, 61); m3 = vnoise(X * 0.31, Z * 0.31, 63); m4 = vnoise(X * 0.9, Z * 0.9, 64)
    img = mix(paint((S, S), "#5a5c40"), paint((S, S), "#7c7c50"), m1[..., None])
    forest = smooth(0.5, 0.64, fbm(X * 0.006, Z * 0.006, 66) * 0.6 + fbm(X * 0.024, Z * 0.024, 67) * 0.4 + 0.2 * smooth(10, 120, bf) * smooth(-10, -130, Z))
    edge = (m4 < forest * 1.25).astype(np.float64)
    img = lay(img, mix(rgb("#232c33"), rgb("#343b41"), m3[..., None]), np.clip(forest * edge, 0, 1) * 0.96)
    img = lay(img, "#17130f", smooth(1.0, -3.0, land(X, Z)))                                     # the bog's water, where the far field shows it
    save("bog_far.png", img * (0.92 + 0.16 * m4[..., None]))
    forest_far = forest

    def forest_at(x, z):
        j = np.clip(((np.asarray(z) - FAR[1]) / (FAR[3] - FAR[1]) * S).astype(int), 0, S - 1); i = np.clip(((np.asarray(x) - FAR[0]) / (FAR[2] - FAR[0]) * S).astype(int), 0, S - 1)
        return forest_far[j, i]

    # ---------------- skies ----------------
    def sky(look, top, mid, hor, cdark, clight, cover, amount, band=None):
        W = 1024; Hh = 512
        u = (np.arange(W) + 0.5) / W; t = (np.arange(Hh) + 0.5) / Hh
        U, T = np.meshgrid(u, t)
        k = smooth(0, 0.62, T)[..., None]; k2 = smooth(0.62, 1, T)[..., None]
        img = mix(mix(rgb(top), rgb(mid), k), rgb(hor), k2)
        if band is not None: img = lay(img, band[0], np.exp(-((T - band[1]) / band[2]) ** 2) * band[3])
        P = 6
        yy = 1.6 / (1.12 - T)
        n = fbm(U * P, yy * 1.3, 71, 5, px=P) * 0.65 + fbm(U * P * 2 + 3.1, yy * 2.6, 72, 4, px=P * 2) * 0.35
        a = smooth(cover, cover + 0.22, n) * amount * smooth(0.04, 0.2, T)
        lit = smooth(0.35, 0.75, fbm(U * P + 0.37, yy * 1.3 - 0.25, 71, 5, px=P))
        cc = mix(rgb(cdark), rgb(clight), (lit * smooth(0.2, 1.0, T))[..., None])
        img = img * (1 - a[..., None]) + cc * a[..., None]
        refl = img[::-1] * np.array([0.44, 0.42, 0.46]) + rgb("#0e0a10") * 0.4          # blackwater: the sky upside down, much darker
        save(f"bog_sky_{look}_side.png", np.vstack([img, refl]))
        save(f"bog_sky_{look}_up.png", np.ones((8, 8, 3)) * img[0, 0])
        save(f"bog_sky_{look}_dn.png", np.ones((8, 8, 3)) * refl[-1, 0])

    sky("mist", "#e9c2bc", "#f5d6c6", "#fbe0cc", "#b9a9b8", "#f6e4dc", 0.46, 0.6, band=("#ffe6cc", 0.97, 0.08, 0.5))   # peach dawn, lilac cloud (measured on the reference)
    sky("fire", "#5e5570", "#84728a", "#c4a4a0", "#4a4260", "#9a8898", 0.4, 0.85, band=("#e0b49c", 0.98, 0.06, 0.4))
    sky("morning", "#6a9cc8", "#a6c9e0", "#f6e8c6", "#c8d4dc", "#fff4dc", 0.5, 0.55, band=("#fff0c8", 0.98, 0.07, 0.5))

    # ---------------- where things stand ----------------
    items = []

    def put(model, x, z, yaw=0.0, scale=1.0, lift=0.0, mirror=False, y=None):
        yy = float(G(x, z)) + lift if y is None else y
        items.append({"m": model, "p": [round(-x, 2), round(yy, 2), round(-z, 2)], "yaw": round(yaw, 1), "s": round(scale, 3), "mir": mirror})  # Roblox stage space: x and z flip

    def clear(x, z):  # not on the island's working ground, not on the walkway's line
        return np.hypot(x, z) > 10.5 and not (-34 < x < -8 and abs(z - 1.5) < 3.5)

    def scatter(model, n, pick, smin, smax, lift=0.0, mirror=False, y=None):
        count, tries = 0, 0
        while count < n and tries < 40000:
            tries += 1
            x, z = pick()
            if not clear(x, z): continue
            ok = y is not None or land(x, z) > 0.8
            if y is not None and land(x, z) > -1.5: continue          # things on the water keep off every shore
            if not ok: continue
            put(model, x, z, rng.random() * 360, rng.uniform(smin, smax), lift, mirror, y)
            count += 1

    ring = lambda r0, r1: (lambda: (lambda a, r: (np.cos(a) * r, np.sin(a) * r - 6))(rng.uniform(0, 2 * np.pi), rng.uniform(r0, r1)))
    box = lambda x0, x1, z0, z1: (lambda: (rng.uniform(x0, x1), rng.uniform(z0, z1)))
    # dead silver trees: on the tussocks and the rim, thick behind and at the sides, a few framing the view in front
    scatter("DeadTree1", 26, ring(22, 92), 0.7, 1.5, lift=-0.3)
    scatter("DeadTree2", 22, ring(26, 96), 0.7, 1.4, lift=-0.3)
    for (x, z, s, k) in [(-17, 9, 1.25, 2), (19, 6, 1.1, 1), (-25, -9, 0.9, 1), (24, -14, 1.0, 2), (-43, 5, 1.3, 2)]:
        if land(x, z) > 0.5: put(f"DeadTree{k}", x, z, rng.random() * 360, s, lift=-0.3)
    # the pine forest line behind the bog, with its reflection, and stands of it on the moor
    count = 0
    while count < 60:
        x = rng.uniform(-108, 108); z = rng.uniform(-166, -70)
        if bank(x, z) < 6: continue
        put(f"Spruce{rng.integers(1, 5)}", x, z, rng.random() * 360, rng.uniform(0.6, 1.15), mirror=bank(x, z) < 45)
        count += 1
    count, tries = 0, 0
    while count < 110 and tries < 30000:
        tries += 1
        z = rng.uniform(-1000, -150); x = rng.uniform(-1, 1) * (abs(z) * 0.95 + 170)
        if NEAR[0] < x < NEAR[2] and z > NEAR[1]: continue
        if forest_at(x, z) < 0.5: continue
        put("PineClump", x, z, rng.random() * 360, float(np.clip(0.9 + np.hypot(x, z) / 520, 1.0, 3.0)), lift=-1.0)
        count += 1
    # the bog's own small things
    scatter("CottonGrass", 90, ring(11, 80), 0.8, 1.4)
    scatter("WispyGrass", 60, ring(11, 84), 0.7, 1.2)
    scatter("GrassTuft", 40, ring(11, 60), 0.6, 1.0)
    scatter("Pitcher", 16, ring(11, 50), 0.8, 1.3)
    scatter("Clover", 18, ring(11, 44), 0.8, 1.2)
    scatter("Fern", 14, ring(40, 90), 0.9, 1.4)
    scatter("Mushroom", 8, ring(11, 40), 0.7, 1.1)
    scatter("Rock1", 8, ring(12, 70), 0.4, 0.9, lift=-0.2)
    scatter("BogLily", 70, box(-60, 60, -62, 30), 0.8, 1.6, y=WATER_Y + 0.03)
    # on the island, hand placed clear of the furnace, the bellows, the ore and the cameras
    for (m, x, z, s) in [("CottonGrass", -6.5, -5.0, 1.0), ("CottonGrass", 7.5, -4.5, 1.1), ("CottonGrass", -8.5, 3.5, 0.9), ("WispyGrass", 8.6, 2.2, 0.9), ("WispyGrass", -4.0, -8.0, 1.0),
                         ("Pitcher", 6.0, -7.0, 1.0), ("Clover", -7.5, -1.5, 1.0), ("Rock1", 7.2, 5.6, 0.5), ("Pebble1", 3.6, 3.4, 1.0), ("Pebble2", -2.4, 4.6, 1.0), ("Mushroom", -9.0, -3.5, 0.8)]:
        put(m, x, z, rng.random() * 360, s)

    lines = ["-- GENERATED by design3d/bog_world.py. Do not edit by hand.", "-- Where everything of the Bog-Iron Pickaxe setting stands, in Roblox stage space (x and z flipped from the authoring space).",
             "return {", f"\twaterY = {WATER_Y},", "\titems = {"]
    for it in items:
        lines.append(f'\t\t{{ "{it["m"]}", {it["p"][0]}, {it["p"][1]}, {it["p"][2]}, {it["yaw"]}, {it["s"]}{", true" if it["mir"] else ""} }},')
    lines += ["\t},", "}"]
    (here.parent / "src" / "ForgeBogMap.luau").write_text("\n".join(lines) + "\n", encoding="utf-8", newline="\n")
    print("wrote ForgeBogMap.luau:", len(items), "items")
