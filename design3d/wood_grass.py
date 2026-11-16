"""The Wood setting's grass, fully modelled (the owner, 2026-11-15: "commit on either fully modeled grass fields or just flat
biome grass ... if it is not insanely laggy, add fully made grass").
    python design3d/wood_grass.py <out dir>     writes WoodGrassA.json, WoodGrassB.json, WoodGrassC.json and grass_rig.json
Every clump is a few curved blades (3 triangles each, drawn from both sides, so no doubled faces). The clumps are baked into
meshes of under 20,000 triangles that follow the ground's height function, so the whole field is about twenty parts:
    A  the camp, out to 22 studs: 4 clumps a square stud, short where the cameras stand
    B  22 to 50 studs: 1.2 a square stud, larger clumps
    C  50 to 100 studs on the banks the wide shots see: 0.3 a square stud, large clumps
A scene on a low graphics level loads A only (ForgeWood). The picture is one small colour ramp: dark at the root, light at the tip."""
import json, pathlib, sys
import numpy as np
from PIL import Image

here = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(here))
import wood_world as W  # the one height function, the lake and the cabin (running it rewrites its own outputs, unchanged)

out = pathlib.Path(sys.argv[1]); out.mkdir(parents=True, exist_ok=True)
rng = np.random.default_rng(31)

# the colour ramp: 8 columns (a clump picks one), root at the bottom of the picture, tip at the top
roots = ["#2f5a36", "#35603a", "#2c5440", "#3a6634", "#335c30", "#2e5a3e", "#40683a", "#37603c"]
tips = ["#8fc866", "#a4d470", "#7fbf78", "#b6d86a", "#9acb5e", "#86c584", "#c8dc78", "#a0d06c"]
ramp = np.zeros((64, 64, 3))
for k in range(8):
    t = (np.linspace(1, 0, 64) ** 1.3)[:, None]      # row 0 (top) = tip
    ramp[:, k * 8:(k + 1) * 8] = (W.rgb(tips[k]) * t + W.rgb(roots[k]) * (1 - t))[:, None, :]
Image.fromarray(ramp.astype(np.uint8), "RGB").save(here / "tex" / "wood_grass.png")


def allowed(x, z):
    d = W.lake_sd(x, z)
    ok = (d > 1.2) & (z < 26) & (z > -118)
    ok &= np.hypot(x - W.CABIN[0], z - W.CABIN[1]) > 21            # the cabin and its porch
    ok &= np.hypot(x + 0.6, z - 3.0) > 2.5                          # the fire's trodden earth
    ok &= ~((np.abs(x - 2.6) < 2.0) & (np.abs(z - 2.2) < 1.2))      # under the log
    return ok


def ring(r0, r1, density):
    step = 1 / np.sqrt(density)
    xs = np.arange(-r1, r1, step); zs = np.arange(-r1, r1, step)
    X, Z = np.meshgrid(xs, zs)
    X = X + rng.uniform(-0.5, 0.5, X.shape) * step; Z = Z + rng.uniform(-0.5, 0.5, Z.shape) * step
    r = np.hypot(X, Z + 2)                                          # rings round the camp, a little toward the lake
    keep = (r >= r0) & (r < r1) & allowed(X, Z) & (np.abs(X) < 108)
    return X[keep], Z[keep]


def clumps(xs, zs, scale, blades, model_tris=19500):
    """-> list of parts (pos, nrm, uv, idx) each under the triangle limit, clumps sorted into ground cells"""
    ys = W.G(xs, zs)
    corridor = (np.abs(xs) < 13) & (zs > -5) & (zs < 26)            # where the cameras stand low: short grass
    tall = np.where(corridor, 0.36, 0.46 + 0.5 * W.smooth(8, 40, np.hypot(xs, zs))) * (0.75 + 0.5 * rng.random(len(xs))) * (0.8 + 0.2 * scale)
    order = np.lexsort((np.floor(xs / 16), np.floor(zs / 16)))
    parts, pos, uv, idx, n = [], [], [], [], 0
    per = blades * 3
    for i in order:
        x, y, z, h = xs[i], ys[i], zs[i], tall[i]
        col = int(rng.integers(0, 8)); u = (col + 0.5) / 8
        for b in range(blades):
            a = rng.uniform(0, 2 * np.pi); lean = rng.uniform(0.12, 0.5) * h; w = 0.07 * scale * rng.uniform(0.8, 1.3); hh = h * rng.uniform(0.6, 1.0)
            ox, oz = np.cos(a) * 0.14 * scale * rng.random(), np.sin(a) * 0.14 * scale * rng.random()
            dx, dz = np.cos(a), np.sin(a)                           # the blade leans this way (and a little with the wind, +x)
            px, pz = -dz * w, dx * w                                # its width is across the lean
            bx, bz = x + ox, z + oz
            mx, mz = bx + dx * lean * 0.35 + 0.04 * h, bz + dz * lean * 0.35
            tx, tz = bx + dx * lean + 0.12 * h, bz + dz * lean
            pos += [bx - px, y - 0.03, bz - pz, bx + px, y - 0.03, bz + pz, mx - px * 0.6, y + hh * 0.55, mz - pz * 0.6, mx + px * 0.6, y + hh * 0.55, mz + pz * 0.6, tx, y + hh, tz]
            uv += [u, 0.04, u, 0.04, u, 0.56, u, 0.56, u, 0.97]
            idx += [n, n + 1, n + 2, n + 1, n + 3, n + 2, n + 2, n + 3, n + 4]
            n += 5
        if len(idx) // 3 + per > model_tris:
            parts.append((pos, uv, idx)); pos, uv, idx, n = [], [], [], 0
    if idx: parts.append((pos, uv, idx))
    return parts


rigs, total = {}, 0
for name, r0, r1, density, scale, blades in (("WoodGrassA", 0, 22, 4.0, 1.0, 5), ("WoodGrassB", 22, 50, 1.2, 1.5, 6), ("WoodGrassC", 50, 100, 0.3, 2.2, 7)):
    xs, zs = ring(r0, r1, density)
    parts_json, man = [], []
    for k, (pos, uv, idx) in enumerate(clumps(xs, zs, scale, blades)):
        p = np.array(pos).reshape(-1, 3); lo, hi = p.min(axis=0), p.max(axis=0)
        nrm = np.tile([0.0, 1.0, 0.0], len(p))                      # lit like the ground they stand on, from either side
        bn = f"Tile{k + 1}"
        parts_json.append({"name": bn, "image": str(here / "tex" / "wood_grass.png"), "palette": [], "position": np.round(p, 3).ravel().tolist(), "normal": nrm.tolist(), "uv": uv, "index": idx})
        r = lambda v: [round(float(q), 3) for q in v]
        man.append({"name": bn, "parent": None, "joint": [0, 0, 0], "center": r((lo + hi) / 2), "size": r(hi - lo), "mat": "Grass", "color": "#ffffff", "tris": len(idx) // 3})
        total += len(idx) // 3
    json.dump({"name": name, "size": [0, 0, 0], "parts": parts_json}, open(out / f"{name}.json", "w", encoding="utf-8"))
    rigs[name] = {"bones": man}
    print(name, len(xs), "clumps,", len(man), "meshes,", sum(b["tris"] for b in man), "triangles")
json.dump(rigs, open(out / "grass_rig.json", "w", encoding="utf-8"))
print("grass field:", total, "triangles")
