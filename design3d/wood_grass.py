"""The Wood setting's grass, fully modelled (the owner, 2026-11-15), second version after "the grass does not feel natural".
    python design3d/wood_grass.py <out dir>     writes WoodGrassA.json, WoodGrassB.json, WoodGrassC.json and grass_rig.json
Built the way large games build grass, as far as Roblox allows (vault: Research/VFX and Animation/Dense Grass in Games):
  * clumps: the field is cut into Voronoi cells; a cell shares its height, colour and lean, and stands as a tussock (tall in
    the middle, short at its rim); about one cell in twelve is nearly bare; height and colour also drift in large patches
  * blades: thin and tapered, four levels with the bend near the tip (a curve, not a straight spike)
  * light: normals tilted along the blade's lean near the camera, straight up on the far rings (no sparkle at distance)
  * colour: a root-to-tip ramp per blade, 16 columns from deep green through fresh green to dry yellow
  * distance: fewer, wider blades (ring A camp, B meadow, C far banks); a low graphics level loads fewer rings (ForgeWood)
  * wind: every mesh has four wind bones; a blade follows one of them more the higher up it is, so ForgeWood sways the tips
Meshes stay under 20,000 triangles; blades are drawn from both sides (no doubled faces)."""
import json, pathlib, sys
import numpy as np
from PIL import Image

here = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(here))
import wood_world as W  # the one height function, the lake and the cabin (running it rewrites its own outputs, unchanged)

out = pathlib.Path(sys.argv[1]); out.mkdir(parents=True, exist_ok=True)
rng = np.random.default_rng(31)
COLS = 16
roots = ["#24482c", "#2a5230", "#2f5a36", "#2c5440", "#35603a", "#335c30", "#3a6634", "#2e5a3e", "#40683a", "#37603c", "#466c38", "#4c7038", "#566f36", "#5f7238", "#6a733a", "#74733c"]
tips = ["#5fa85a", "#6fb860", "#7fbf78", "#86c584", "#8fc866", "#9acb5e", "#a4d470", "#a0d06c", "#b0d868", "#b6d86a", "#c0dc70", "#c8dc78", "#d2d878", "#dcd47a", "#e2cc78", "#e6c474"]
ramp = np.zeros((64, COLS * 4, 3))
for k in range(COLS):
    t = (np.linspace(1, 0, 64) ** 1.25)[:, None]      # row 0 (top) = tip
    ramp[:, k * 4:(k + 1) * 4] = (W.rgb(tips[k]) * t + W.rgb(roots[k]) * (1 - t) * (0.55 + 0.45 * t))[:, None, :]  # the root sits in its own shade
Image.fromarray(ramp.astype(np.uint8), "RGB").save(here / "tex" / "wood_grass.png")
LEVELS = np.array([0.0, 0.45, 0.8, 1.0]); WIDTHS = np.array([1.0, 0.8, 0.45, 0.0])


def allowed(x, z):
    d = W.lake_sd(x, z)
    ok = (d > 1.0) & (z < 26) & (z > -118)
    ok &= np.hypot(x - W.CABIN[0], z - W.CABIN[1]) > 16
    ok &= np.hypot(x + 0.6, z - 3.0) > 2.3                          # the fire's trodden earth
    ok &= ~((np.abs(x - 2.6) < 1.9) & (np.abs(z - 2.2) < 1.0))      # under the log
    return ok


def hash01(a, b, s):
    n = (a.astype(np.int64) * 374761393 + b.astype(np.int64) * 668265263 + s * 1442695041) & 0xFFFFFFFF
    n = ((n ^ (n >> 13)) * 1274126177) & 0xFFFFFFFF
    return ((n ^ (n >> 16)) & 0xFFFF) / 65535.0


def build(r0, r1, density, cell, half_w, near):
    # blades on a jittered grid
    step = 1 / np.sqrt(density)
    xs = np.arange(-r1, r1, step); zs = np.arange(-r1, r1, step)
    X, Z = np.meshgrid(xs, zs)
    X = (X + rng.uniform(-0.5, 0.5, X.shape) * step).ravel(); Z = (Z + rng.uniform(-0.5, 0.5, Z.shape) * step).ravel()
    r = np.hypot(X, Z + 2)
    keep = (r >= r0) & (r < r1) & allowed(X, Z) & (np.abs(X) < 108)
    X, Z = X[keep], Z[keep]
    # the Voronoi cell each blade belongs to: nearest of the 9 jittered sites round it
    ci, cj = np.floor(X / cell).astype(np.int64), np.floor(Z / cell).astype(np.int64)
    best = np.full(len(X), 1e9); si, sj, sx, sz = ci.copy(), cj.copy(), X.copy(), Z.copy()
    for di in (-1, 0, 1):
        for dj in (-1, 0, 1):
            a, b = ci + di, cj + dj
            px = (a + 0.15 + 0.7 * hash01(a, b, 1)) * cell; pz = (b + 0.15 + 0.7 * hash01(a, b, 2)) * cell
            d = np.hypot(X - px, Z - pz)
            m = d < best
            best = np.where(m, d, best); si = np.where(m, a, si); sj = np.where(m, b, sj); sx = np.where(m, px, sx); sz = np.where(m, pz, sz)
    q = np.clip(best / (cell * 0.75), 0, 1)                         # 0 at the tussock's heart, 1 at its rim
    # what the clump shares, with slow drifts across the meadow
    drift_h = W.fbm(sx * 0.035, sz * 0.035, 91); drift_c = W.fbm(sx * 0.02, sz * 0.02, 92)
    c_height = (0.55 + 1.0 * hash01(si, sj, 3) ** 1.6) * (0.7 + 0.7 * drift_h)
    c_col = np.clip(np.round((drift_c * 1.3 - 0.15) * (COLS - 1) + (hash01(si, sj, 4) - 0.5) * 5), 0, COLS - 1)
    c_dir = 3.14159 + (hash01(si, sj, 5) - 0.5) * 2.2             # combed toward -x: the wind's lee (screen left in the game)
    c_tilt = 0.5 + 0.9 * hash01(si, sj, 6)
    bare = hash01(si, sj, 7) < 0.085
    live = ~(bare & (rng.random(len(X)) > 0.12)) & (rng.random(len(X)) > 0.25 * q)   # bald cells, and thinner rims
    X, Z, sx, sz, q = X[live], Z[live], sx[live], sz[live], q[live]
    c_height, c_col, c_dir, c_tilt, si, sj = c_height[live], c_col[live], c_dir[live], c_tilt[live], si[live], sj[live]
    X = X + (sx - X) * 0.22; Z = Z + (sz - Z) * 0.22              # pulled toward the heart
    Y = W.G(X, Z)
    corridor = (np.abs(X) < 13) & (Z > -5) & (Z < 26)             # where the cameras stand low: short grass
    base_h = np.where(corridor, 0.4, 0.5 + 0.55 * W.smooth(8, 45, np.hypot(X, Z)))
    H = base_h * c_height * (1 - 0.45 * q * q) * rng.uniform(0.75, 1.1, len(X)) * (1.0 if near else 1.25)
    H = np.clip(H, 0.14, 1.9)
    ang = c_dir + rng.normal(0, 0.8, len(X))
    lean = H * c_tilt * rng.uniform(0.2, 0.55, len(X))
    wid = half_w * rng.uniform(0.75, 1.3, len(X))
    col = np.clip(c_col + rng.integers(-1, 2, len(X)), 0, COLS - 1)
    bone = 1 + ((si * 3 + sj * 7) % 4)
    cellkey = np.floor(X / 16) * 1000 + np.floor(Z / 16)
    order = np.argsort(cellkey, kind="stable")
    dx, dz = np.cos(ang), np.sin(ang); px, pz = -dz, dx           # lean direction and the blade's width direction
    n = len(X)
    # 7 vertices a blade: two at each of three levels and the tip
    P = np.zeros((n, 7, 3)); N = np.zeros((n, 7, 3)); UV = np.zeros((n, 7, 2)); Wt = np.zeros((n, 7))
    for k, (t, wf) in enumerate(zip(LEVELS, WIDTHS)):
        off = lean * t ** 2.2
        cx, cy, cz = X + dx * off, Y - 0.04 + H * t * (1 - 0.1 * t), Z + dz * off
        vs = (2 * k, 2 * k + 1) if k < 3 else (6,)
        for v, s in zip(vs, (-1, 1)):
            P[:, v, 0], P[:, v, 1], P[:, v, 2] = cx + px * wid * wf * s, cy, cz + pz * wid * wf * s
            tilt = (0.55 if near else 0.0) * (1 - 0.5 * t)
            N[:, v, 0], N[:, v, 1], N[:, v, 2] = dx * tilt + px * s * tilt * 0.5, 1.0, dz * tilt + pz * s * tilt * 0.5
            UV[:, v, 0], UV[:, v, 1] = (col + 0.5) / COLS, 0.04 + 0.93 * t
            Wt[:, v] = t ** 1.8
    N /= np.linalg.norm(N, axis=2, keepdims=True)
    TRI = np.array([0, 1, 2, 1, 3, 2, 2, 3, 4, 3, 5, 4, 4, 5, 6])
    parts = []
    per = 3800                                                    # blades a mesh: 19,000 triangles
    for a in range(0, n, per):
        sel = order[a:a + per]; m = len(sel)
        pos = P[sel].reshape(-1, 3)
        idx = (TRI[None, :] + (np.arange(m) * 7)[:, None]).ravel()
        joints = np.zeros((m, 7, 4), dtype=np.int64); joints[:, :, 1] = bone[sel][:, None]
        weights = np.zeros((m, 7, 4)); weights[:, :, 1] = Wt[sel]; weights[:, :, 0] = 1 - Wt[sel]
        parts.append((pos, N[sel].reshape(-1, 3), UV[sel].reshape(-1, 2), idx, joints.reshape(-1, 4), weights.reshape(-1, 4)))
    return parts, n


rigs, total = {}, 0
for name, r0, r1, density, cell, half_w, near in (("WoodGrassA", 0, 22, 15.0, 1.5, 0.034, True), ("WoodGrassB", 22, 50, 4.2, 2.6, 0.058, True), ("WoodGrassC", 50, 100, 1.15, 4.6, 0.105, False)):
    parts, blades = build(r0, r1, density, cell, half_w, near)
    parts_json, man = [], []
    for k, (pos, nrm, uv, idx, joints, weights) in enumerate(parts):
        lo, hi = pos.min(axis=0), pos.max(axis=0); mid = ((lo + hi) / 2).tolist()
        bn = f"Tile{k + 1}"
        bones = [{"name": f"{name}_{bn}_Root", "pos": mid}] + [{"name": f"{name}_{bn}_W{w}", "pos": mid} for w in (1, 2, 3, 4)]
        parts_json.append({"name": bn, "image": str(here / "tex" / "wood_grass.png"), "palette": [], "position": np.round(pos, 3).ravel().tolist(), "normal": np.round(nrm, 3).ravel().tolist(), "uv": np.round(uv, 4).ravel().tolist(), "index": idx.tolist(),
                           "skin": {"bones": bones, "joints": joints.ravel().tolist(), "weights": np.round(weights, 3).ravel().tolist()}})
        r = lambda v: [round(float(q), 3) for q in v]
        man.append({"name": bn, "parent": None, "joint": [0, 0, 0], "center": r((lo + hi) / 2), "size": r(hi - lo), "mat": "Grass", "color": "#ffffff", "tris": len(idx) // 3})
        total += len(idx) // 3
    json.dump({"name": name, "size": [0, 0, 0], "parts": parts_json}, open(out / f"{name}.json", "w", encoding="utf-8"))
    rigs[name] = {"bones": man}
    print(name, blades, "blades,", len(man), "meshes,", sum(b["tris"] for b in man), "triangles")
json.dump(rigs, open(out / "grass_rig.json", "w", encoding="utf-8"))
print("grass field:", total, "triangles")
