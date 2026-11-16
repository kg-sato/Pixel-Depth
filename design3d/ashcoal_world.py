"""The Ashcoal Pickaxe setting: a clearing on a hillside in an old oak wood, at night, with a misty valley below
(reference: refs/forge/sheets/ashcoal_setting_s11.png; scene bible entry "Ashcoal").
    python design3d/ashcoal_world.py
Writes, all from ONE height function so the ground, its painted pictures and every placed object agree:
    design3d/tex/ashcoal_terrain.mjs   heights of the clearing (near) and of the valley with its far hills (read by ashcoal.mjs)
    design3d/tex/ashcoal_floor.png     the wood floor painted from above: leaf litter, moss, fallen oak leaves, the trodden
                                       clearing, the ash ring round the mound
    design3d/tex/ashcoal_valley.png    the valley and the far hills painted from above: dark oak forest, paler valley meadows
    design3d/tex/ashcoal_sky_<look>_side|up|dn.png   three skies: dusk, night, dawn (a pale foggy sunrise)
    src/ForgeAshcoalMap.luau           where every oak, fern, bush and rock stands (Roblox stage space)
Space here is the authoring space of ashcoal.mjs: x to screen right, y up, z toward the camera; the mound's clearing is at the
origin and the hillside falls away behind it (toward -z) into the valley. The helpers are copies of wood_world.py's (that file
writes the Wood scene's outputs when imported, so it is not imported here)."""
import json, pathlib
import numpy as np
from PIL import Image, ImageFilter

here = pathlib.Path(__file__).resolve().parent
tex = here / "tex"; tex.mkdir(exist_ok=True)
NEAR = (-110.0, -170.0, 110.0, 50.0)   # x0, z0, x1, z1
FAR = (-1000.0, -1650.0, 1000.0, 150.0)
N = 96
MOUND = (-2.6, -1.5)                    # authoring x, z of the charcoal mound (Roblox stage 2.6, 1.5)


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


def hills(x, z):  # the far side of the valley and the ridges that close it
    def mass(cx, cz, H, R): return H * np.clip(1 - np.hypot(x - cx, z - cz) / R, 0, 1) ** 1.3
    m = mass(120, -640, 230, 500) + mass(-420, -580, 200, 470) + mass(520, -900, 260, 560) + mass(-800, -1100, 280, 560) + mass(60, -1350, 300, 600)
    return m * (0.8 + 0.35 * (1 - np.abs(fbm(x * 0.004, z * 0.004, 31) * 2 - 1))) + (fbm(x * 0.012, z * 0.012, 37) - 0.5) * 20 * smooth(4, 60, m)


def G(x, z):
    x = np.asarray(x, dtype=np.float64); z = np.asarray(z, dtype=np.float64)
    base = (fbm(x * 0.03, z * 0.03, 1) - 0.5) * 3.2 + (fbm(x * 0.11, z * 0.11, 2) - 0.5) * 0.6
    flat = smooth(11, 26, np.hypot(x, np.where(z < 0, z, z * 0.3)))                  # the clearing and the camera's ground are level
    h = base * flat
    drop = smooth(-16, -120, z)                                                       # the hillside falls away to the valley
    h = h - drop * (34 + (fbm(x * 0.015, z * 0.015, 3) - 0.5) * 10)
    h = h + smooth(34, 110, np.abs(x)) * 10 * (1 - 0.5 * drop) + smooth(14, 50, z) * 6  # the hill's shoulders, and the rise behind the camera
    return h + hills(x, z)


def grid(rect, n):
    x0, z0, x1, z1 = rect
    return np.meshgrid(np.linspace(x0, x1, n + 1), np.linspace(z0, z1, n + 1))


def pixels(rect, size):
    x0, z0, x1, z1 = rect
    xs = x0 + (np.arange(size) + 0.5) / size * (x1 - x0); zs = z0 + (np.arange(size) + 0.5) / size * (z1 - z0)
    return np.meshgrid(xs, zs)


def rgb(h): h = h.lstrip("#"); return np.array([int(h[i:i + 2], 16) for i in (0, 2, 4)], dtype=np.float64)


def paint(shape, col): return np.ones(shape + (3,)) * rgb(col)


def lay(img, col, a):  # blend a colour over the picture by a mask
    c = rgb(col) if isinstance(col, str) else col
    return img * (1 - a[..., None]) + c * a[..., None]


def specks(mask, size=3, blur=0.5):
    return np.asarray(Image.fromarray((mask * 255).astype(np.uint8)).filter(ImageFilter.MaxFilter(size)).filter(ImageFilter.GaussianBlur(blur)), dtype=np.float64) / 255.0


def save(name, img, mode="RGB"):
    Image.fromarray(np.clip(img, 0, 255).astype(np.uint8), mode).save(tex / name)
    print("wrote", name)


if __name__ == "__main__":
    rng = np.random.default_rng(21)

    # ---------------- heights ----------------
    NX, NZ = grid(NEAR, N); FX, FZ = grid(FAR, N)
    out = {"near": {"rect": NEAR, "h": np.round(G(NX, NZ), 3).tolist()}, "far": {"rect": FAR, "h": np.round(G(FX, FZ) - 3.0, 2).tolist()}}
    (tex / "ashcoal_terrain.mjs").write_text("// GENERATED by design3d/ashcoal_world.py. Do not edit by hand.\nexport default " + json.dumps(out, separators=(",", ":")) + ";\n", encoding="utf-8")
    print("wrote ashcoal_terrain.mjs")

    # ---------------- the wood floor, painted from above ----------------
    S = 1024
    X, Z = pixels(NEAR, S)
    n1 = fbm(X * 0.05, Z * 0.05, 41); n2 = fbm(X * 0.4, Z * 0.4, 42, 3); n3 = vnoise(X * 2.3, Z * 2.3, 43)
    img = mix(paint((S, S), "#3b4630"), paint((S, S), "#5a5a3a"), n1[..., None])          # leaf litter, brown-green
    img = lay(img, "#4f6b3c", smooth(0.55, 0.78, fbm(X * 0.03, Z * 0.03, 44)) * 0.7)      # moss in the damp places
    img = lay(img, "#6a6a44", smooth(0.62, 0.85, n2) * 0.3)
    img = img * (0.88 + 0.24 * n3[..., None])
    img = lay(img, "#5f7046", smooth(-40, -120, Z) * 0.5)                                 # paler grass down the open slope
    r = rng.random((S, S)); dens = 0.2 + 0.5 * smooth(0.4, 0.7, fbm(X * 0.06, Z * 0.06, 45))
    for colr, lo, hi in (("#8a5a30", 0.0, 0.035), ("#a8742e", 0.035, 0.06), ("#6e4426", 0.06, 0.085), ("#c08a3a", 0.085, 0.094)):
        img = lay(img, colr, np.clip(specks(((r >= lo) & (r < hi)) * (rng.random((S, S)) < dens)) * 1.2, 0, 1) * 0.85)  # fallen oak leaves
    clear = 1 - smooth(6.5, 12, np.hypot(X * 0.85, np.where(Z < 0, Z, Z * 0.55)))        # the trodden clearing, longer toward the camera
    img = lay(img, mix(rgb("#5a4a3a"), rgb("#6a5844"), n2[..., None]), clear * 0.85)
    dm = np.hypot(X - MOUND[0], Z - MOUND[1])
    img = lay(img, "#2b2726", (1 - smooth(3.2, 5.6, dm)) * 0.9)                           # ash and charcoal dust round the mound
    img = lay(img, "#4a4038", (1 - smooth(0.6, 1.6, np.abs(Z - 2.2 + (X - 3) * 0.1))) * ((X > -1) & (X < 9)) * (1 - clear * 0.3) * 0.5)  # the path to the cordwood
    save("ashcoal_floor.png", img)

    # ---------------- the valley and the far hills, painted from above ----------------
    X, Z = pixels(FAR, S)
    h = G(X, Z)
    m1 = fbm(X * 0.004, Z * 0.004, 61); m2 = fbm(X * 0.02, Z * 0.02, 62); m3 = vnoise(X * 0.31, Z * 0.31, 63); m4 = vnoise(X * 0.9, Z * 0.9, 64)
    img = mix(paint((S, S), "#4e6a48"), paint((S, S), "#6a8052"), m1[..., None])          # valley meadows
    img = lay(img, "#7f8c5a", smooth(0.55, 0.8, m2) * 0.35)
    forest = smooth(0.34, 0.5, fbm(X * 0.006, Z * 0.006, 66) * 0.6 + fbm(X * 0.02, Z * 0.02, 67) * 0.25 + 0.3 * smooth(-30, 40, h))  # oak forest on every slope
    edge = (m4 < forest * 1.3).astype(np.float64)
    img = lay(img, mix(rgb("#1c3528"), rgb("#33543a"), m3[..., None] * 0.85 + 0.15 * m4[..., None]), np.clip(forest * edge, 0, 1) * 0.96)
    img = lay(img, "#6f6a60", smooth(200, 290, h + (m2 - 0.5) * 80) * 0.6)                # bare tops
    img = img * (0.9 + 0.2 * m4[..., None])
    save("ashcoal_valley.png", img)
    forest_far = forest

    def forest_at(x, z):
        j = np.clip(((np.asarray(z) - FAR[1]) / (FAR[3] - FAR[1]) * S).astype(int), 0, S - 1); i = np.clip(((np.asarray(x) - FAR[0]) / (FAR[2] - FAR[0]) * S).astype(int), 0, S - 1)
        return forest_far[j, i]

    # ---------------- skies ----------------
    def sky(look, top, mid, hor, cdark, clight, cover, amount, stars=0, band=None, below="#0c1210"):
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
        P = 6                                                              # the cloud lattice is periodic in u, so the four sides join
        yy = 1.6 / (1.12 - T)
        n = fbm(U * P, yy * 1.3, 71, 5, px=P) * 0.65 + fbm(U * P * 2 + 3.1, yy * 2.6, 72, 4, px=P * 2) * 0.35
        a = smooth(cover, cover + 0.22, n) * amount * smooth(0.04, 0.2, T)
        lit = smooth(0.35, 0.75, fbm(U * P + 0.37, yy * 1.3 - 0.25, 71, 5, px=P))
        cc = mix(rgb(cdark), rgb(clight), (lit * smooth(0.2, 1.0, T))[..., None])
        img = img * (1 - a[..., None]) + cc * a[..., None]
        low = mix(img[-1:, :, :] * 0.7, rgb(below), smooth(0, 0.5, T)[..., None])   # below the horizon: the horizon colour sinking into dark (only seen past the world's edge)
        save(f"ashcoal_sky_{look}_side.png", np.vstack([img, low]))
        save(f"ashcoal_sky_{look}_up.png", np.ones((8, 8, 3)) * img[0, 0])
        save(f"ashcoal_sky_{look}_dn.png", np.ones((8, 8, 3)) * low[-1, 0])

    sky("dusk", "#1c2148", "#5a3f6e", "#f29a5c", "#3a2c52", "#f2b07a", 0.5, 0.75, stars=160, band=("#ffd08a", 0.98, 0.06, 0.6))
    sky("night", "#070b1c", "#101c3a", "#35506e", "#0c1428", "#2c4466", 0.52, 0.6, stars=1100, band=("#6f8ca8", 0.97, 0.07, 0.3))
    sky("dawn", "#8f9bb0", "#c2bcc4", "#f2d6c0", "#8a8c9c", "#f4e2d4", 0.38, 0.85, band=("#ffe8cc", 0.97, 0.09, 0.5), below="#3a4038")

    # ---------------- where things stand ----------------
    items = []

    def put(model, x, z, yaw=0.0, scale=1.0, lift=0.0):
        items.append({"m": model, "p": [round(-x, 2), round(float(G(x, z)) + lift, 2), round(-z, 2)], "yaw": round(yaw, 1), "s": round(scale, 3)})  # Roblox stage space: x and z flip

    def free(x, z):  # not in the clearing's action, not where the cameras stand, not on the view down to the valley
        return not (-12 < x < 11 and -9 < z < 24) and not (abs(x) < 15 + (-z) * 0.12 and z < -9)

    # the old oaks that ring the clearing: giants left and right of the frame, the view to the valley left open between them
    for (x, z, s, k) in [(-21, -5, 1.0, 1), (-30, 6, 1.15, 2), (-17, 9, 0.8, 2), (20, -7, 1.1, 2), (30, 5, 1.2, 1), (16, 10, 0.75, 1), (-36, -18, 1.25, 1), (36, -20, 1.2, 2), (-44, 16, 1.1, 2), (46, 18, 1.15, 1)]:
        put(f"Oak{k}", x, z, rng.random() * 360, s, lift=-0.4)
    count = 0
    while count < 34:  # the wood on the hill's two shoulders, thinning down the slope
        side = rng.choice([-1, 1]); x = side * rng.uniform(26, 106); z = rng.uniform(-150, 30)
        if not free(x, z): continue
        put(f"Oak{rng.integers(1, 3)}", x, z, rng.random() * 360, rng.uniform(0.7, 1.3), lift=-0.4)
        count += 1
    for (x, z, s) in [(-24, -62, 0.8), (22, -74, 0.9), (-9, -104, 0.7), (12, -128, 0.8)]: put("Oak1", x, z, rng.random() * 360, s, lift=-0.4)  # a few low on the slope: only their crowns show
    count, tries = 0, 0
    while count < 150 and tries < 60000:  # stands of trees on the painted forest of the valley and the far hills
        tries += 1
        z = rng.uniform(-1150, -170); x = rng.uniform(-1, 1) * (abs(z) * 0.95 + 170)
        if NEAR[0] < x < NEAR[2] and z > NEAR[1]: continue
        if forest_at(x, z) < 0.8: continue
        put("PineClump", x, z, rng.random() * 360, float(np.clip(0.9 + np.hypot(x, z) / 520, 1.0, 3.0)), lift=-1.0)
        count += 1
    # the wood floor round the clearing: bracken, foxglove-pink flowers, bushes, toadstools, rocks, wispy grass
    for model, n, rmax, s0, s1 in (("Fern", 46, 40, 0.9, 1.6), ("FlowerPatch2", 16, 30, 0.9, 1.4), ("Bush", 12, 46, 0.9, 1.5), ("Mushroom", 10, 26, 0.7, 1.1), ("WispyGrass", 40, 44, 0.7, 1.2), ("Clover", 20, 30, 0.8, 1.2), ("Plant1", 9, 40, 0.7, 1.1)):
        count = 0
        while count < n:
            a = rng.uniform(0, 2 * np.pi); rr = rng.uniform(9, rmax)
            x = np.cos(a) * rr * 1.2; z = np.sin(a) * rr
            if not free(x, z): continue
            put(model, x, z, rng.random() * 360, rng.uniform(s0, s1))
            count += 1
    for (x, z, s, k) in [(-13, -4, 1.1, 1), (12, -3, 0.9, 2), (-15, 8, 1.3, 3), (14, 12, 1.0, 1), (-26, -30, 1.6, 2), (28, -36, 1.4, 3), (9, 16, 0.7, 2)]: put(f"Rock{k}", x, z, rng.random() * 360, s, lift=-0.25)
    for (x, z) in [(-20.2, -4.2), (19.3, -6.4), (-29.4, 5.2), (29.2, 4.4)]: put("ShelfFungus", x, z, rng.random() * 360, 1.2, lift=1.4)  # bracket fungus at the feet of the nearest oaks
    # a little bracken and clover inside the clearing's rim, hand placed clear of the action and the cameras
    for (x, z) in [(-9.5, -6.5), (8.5, -7.5), (-10.5, 3.0), (-11.0, 9.0), (9.5, 14.0), (-7.0, -9.5)]: put("Fern", x, z, rng.random() * 360, 1.0)
    for (x, z) in [(-8.6, 0.6), (7.6, 8.0), (-6.6, 12.0)]: put("Clover", x, z, rng.random() * 360, 0.9)

    lines = ["-- GENERATED by design3d/ashcoal_world.py. Do not edit by hand.", "-- Where everything of the Ashcoal Pickaxe setting stands, in Roblox stage space (x and z flipped from the authoring space).",
             "return {", "\titems = {"]
    for it in items:
        lines.append(f'\t\t{{ "{it["m"]}", {it["p"][0]}, {it["p"][1]}, {it["p"][2]}, {it["yaw"]}, {it["s"]} }},')
    lines += ["\t},", "}"]
    (here.parent / "src" / "ForgeAshcoalMap.luau").write_text("\n".join(lines) + "\n", encoding="utf-8", newline="\n")
    print("wrote ForgeAshcoalMap.luau:", len(items), "items")
