"""Bring models of Quaternius' Stylized Nature MegaKit (CC0, Overnight/downloads/forge_nature, see SOURCES.txt there) into the
forge scene pipeline, changed for our setting: scaled to our studs, split into Trunk / Leaves parts with one picture each,
the leaf and bark pictures repainted (shaded from base to tip, tinted to the reference's blue-green spruce and a white birch),
and a mirror copy of the foliage for the lake.
    python design3d/kit_import.py <out dir>     writes <Model>.json per model and kit_rig.json (same form as export.mjs)
The owner, 2026-11-15: "Use online sources for the trees and others and modify them if they are higher quality than what you made"."""
import json, pathlib, struct, sys
import numpy as np
from PIL import Image, ImageFilter

here = pathlib.Path(__file__).resolve().parent
root = here.parent.parent.parent
KIT = root / "Overnight" / "downloads" / "forge_nature" / "kit" / "glTF"
out = pathlib.Path(sys.argv[1]); out.mkdir(parents=True, exist_ok=True)
tex = here / "tex" / "kit"; tex.mkdir(parents=True, exist_ok=True)
rng = np.random.default_rng(5)

# ---- pictures: repainted copies at 1024 ----
def rgb(h): h = h.lstrip("#"); return np.array([int(h[i:i + 2], 16) for i in (0, 2, 4)], dtype=np.float64)


def leaf_picture(src, dst, dark, light, accent=None):
    """A flat leaf card gets depth: dark at the stem end, light at the tips, soft brush mottling, a paler rim."""
    im = Image.open(KIT / src).convert("RGBA").resize((1024, 1024), Image.LANCZOS)
    a = np.asarray(im, dtype=np.float64); alpha = a[..., 3] / 255.0
    yy = np.linspace(1, 0, 1024)[:, None] * np.ones((1, 1024))                    # 1 at the top of the picture
    n = np.asarray(Image.fromarray((rng.random((64, 64)) * 255).astype(np.uint8)).resize((1024, 1024), Image.BICUBIC), dtype=np.float64) / 255.0
    n2 = np.asarray(Image.fromarray((rng.random((256, 256)) * 255).astype(np.uint8)).resize((1024, 1024), Image.BICUBIC), dtype=np.float64) / 255.0
    inner = np.asarray(Image.fromarray((alpha * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(14)), dtype=np.float64) / 255.0
    t = np.clip(0.15 + 0.6 * yy + 0.35 * (n - 0.5) + 0.2 * (n2 - 0.5) + 0.45 * (1 - inner), 0, 1)      # rims and tops catch the light
    col = rgb(dark)[None, None, :] * (1 - t[..., None]) + rgb(light)[None, None, :] * t[..., None]
    if accent is not None: col = col * (1 - (n2 > 0.86)[..., None] * 0.5) + rgb(accent) * ((n2 > 0.86)[..., None] * 0.5)
    outp = np.dstack([col, a[..., 3]])
    Image.fromarray(np.clip(outp, 0, 255).astype(np.uint8), "RGBA").save(tex / dst)


def bark_picture(src, dst, tint=None, birch=False):
    im = Image.open(KIT / src).convert("RGB").resize((1024, 1024), Image.LANCZOS)
    a = np.asarray(im, dtype=np.float64)
    lum = a.mean(axis=2, keepdims=True) / 255.0
    if birch:  # a white birch: the bark's grooves become grey shade, and dark lens marks are painted across it
        col = rgb("#f1ece2") * (0.55 + 0.6 * lum)
        col = np.clip(col, 0, 250)
        marks = np.zeros((1024, 1024))
        for _ in range(70):
            cx, cy = rng.integers(0, 1024), rng.integers(0, 1024); w, h = rng.integers(30, 110), rng.integers(5, 14)
            y0, y1, x0, x1 = max(cy - h, 0), min(cy + h, 1024), max(cx - w, 0), min(cx + w, 1024)
            yy, xx = np.mgrid[y0:y1, x0:x1]
            marks[y0:y1, x0:x1] = np.maximum(marks[y0:y1, x0:x1], np.clip(1 - ((xx - cx) / w) ** 2 - ((yy - cy) / h) ** 2, 0, 1) ** 0.5)
        col = col * (1 - marks[..., None] * 0.82) + rgb("#3d3344") * (marks[..., None] * 0.82)
    else:
        col = rgb(tint) * (0.35 + 1.25 * lum) if tint else a  # the kit bark is orange-brown: ours is a cool grey-brown, as on the reference spruces
    Image.fromarray(np.clip(col, 0, 255).astype(np.uint8), "RGB").save(tex / dst)


def plain(src, dst, gain=1.0, tint=None):
    im = Image.open(KIT / src).convert("RGBA").resize((1024, 1024), Image.LANCZOS)
    a = np.asarray(im, dtype=np.float64)
    c = a[..., :3] * gain * ((rgb(tint) / 255.0) if tint else 1.0)
    Image.fromarray(np.clip(np.dstack([c, a[..., 3]]), 0, 255).astype(np.uint8), "RGBA").save(tex / dst)


leaf_picture("Leaf_Pine_C.png", "spruce_leaf.png", "#1c4030", "#6aa85c", accent="#9ccf74")  # a warmer green with pale new growth (the first grade called the blue-green cold and flat)
leaf_picture("Leaves_NormalTree_C.png", "birch_leaf.png", "#4f8a50", "#bfe28e", accent="#f3e39a")
leaf_picture("Leaves_TwistedTree_C.png", "bush_leaf.png", "#3f6f4a", "#9ecb72")
bark_picture("Bark_NormalTree.png", "spruce_bark.png", tint="#7a5c48")
bark_picture("Bark_NormalTree.png", "birch_bark.png", birch=True)
plain("Rocks_Diffuse.png", "rock.png", 0.92, "#e6e8f0")
plain("Flowers.png", "flowers.png")
plain("Leaves.png", "leaves.png", 0.95)
plain("Grass.png", "grass.png", 0.9, "#d8f0c8")
plain("Mushrooms.png", "mushrooms.png")
# more of the kit for the scenes after Wood: gnarled oaks, dead silver trees, path pebbles
leaf_picture("Leaves_TwistedTree_C.png", "oak_leaf.png", "#2c5632", "#8dbb5a", accent="#c9c070")
bark_picture("Bark_TwistedTree.png", "oak_bark.png", tint="#6e5444")
bark_picture("Bark_DeadTree.png", "dead_bark.png", birch=True)
plain("PathRocks_Diffuse.png", "pathrock.png", 0.95)


def pale(src, dst, dark="#a3958a", light="#f8f2e8"):
    """River-worn limestone for the Stone scene (reference stone_setting_s11.png: every stone is cream-white, none is grey or
    mossy): the kit picture's light and dark are kept, its colours are replaced by a ramp from warm grey shadow to cream."""
    im = Image.open(KIT / src).convert("RGBA").resize((1024, 1024), Image.LANCZOS)
    a = np.asarray(im, dtype=np.float64)
    lum = a[..., :3] @ np.array([0.3, 0.59, 0.11])
    lo, hi = np.percentile(lum, 4), np.percentile(lum, 96)
    u = np.clip((lum - lo) / max(hi - lo, 1), 0, 1) ** 0.75
    c = rgb(dark) * (1 - u[..., None]) + rgb(light) * u[..., None]
    Image.fromarray(np.clip(np.dstack([c, a[..., 3]]), 0, 255).astype(np.uint8), "RGBA").save(tex / dst)


pale("Rocks_Diffuse.png", "rock_pale.png")
pale("PathRocks_Diffuse.png", "pathrock_pale.png")
PICT = {"Leaf_Pine_C.png": "spruce_leaf.png", "Leaves_NormalTree_C.png": "birch_leaf.png", "Leaves_TwistedTree_C.png": "bush_leaf.png", "Bark_NormalTree.png": "spruce_bark.png",
        "Rocks_Diffuse.png": "rock.png", "PathRocks_Diffuse.png": "pathrock.png", "Bark_DeadTree.png": "dead_bark.png", "Bark_TwistedTree.png": "oak_bark.png", "Flowers.png": "flowers.png", "Leaves.png": "leaves.png", "Grass.png": "grass.png", "Mushrooms.png": "mushrooms.png"}

# ---- glTF reading ----
CT = {5120: ("b", 1), 5121: ("B", 1), 5122: ("h", 2), 5123: ("H", 2), 5125: ("I", 4), 5126: ("f", 4)}
NC = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT4": 16}


def read(g, bins, i):
    a = g["accessors"][i]; v = g["bufferViews"][a["bufferView"]]
    fmt, size = CT[a["componentType"]]; n = NC[a["type"]]
    off = v.get("byteOffset", 0) + a.get("byteOffset", 0); stride = v.get("byteStride") or size * n
    buf = bins[v["buffer"]]
    arr = np.empty((a["count"], n), dtype=np.float64)
    for k in range(a["count"]): arr[k] = struct.unpack_from("<" + fmt * n, buf, off + k * stride)
    if a.get("normalized"): arr /= {5121: 255.0, 5123: 65535.0}.get(a["componentType"], 1.0)
    return arr


def node_matrix(nd):
    if "matrix" in nd: return np.array(nd["matrix"], dtype=np.float64).reshape(4, 4).T
    m = np.eye(4)
    if "scale" in nd: m = np.diag(list(nd["scale"]) + [1.0]) @ m
    if "rotation" in nd:
        x, y, z, w = nd["rotation"]
        r = np.array([[1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w), 0], [2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w), 0], [2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y), 0], [0, 0, 0, 1]])
        m = r @ m
    if "translation" in nd: t = np.eye(4); t[:3, 3] = nd["translation"]; m = t @ m
    return m


def load(name):
    """-> list of { image, pos (n,3), nrm (n,3), uv (n,2), idx } per material of the model, in its own units"""
    g = json.load(open(KIT / f"{name}.gltf", encoding="utf-8"))
    bins = [open(KIT / b["uri"], "rb").read() for b in g["buffers"]]
    parts = {}
    for nd in g["nodes"]:
        if "mesh" not in nd: continue
        M = node_matrix(nd); R = M[:3, :3]
        for p in g["meshes"][nd["mesh"]]["primitives"]:
            mat = g["materials"][p["material"]]
            ti = mat["pbrMetallicRoughness"]["baseColorTexture"]["index"]
            image = g["images"][g["textures"][ti]["source"]]["uri"]
            pos = read(g, bins, p["attributes"]["POSITION"]) @ R.T + M[:3, 3]
            nrm = read(g, bins, p["attributes"]["NORMAL"]) @ np.linalg.inv(R)
            nrm /= np.maximum(np.linalg.norm(nrm, axis=1, keepdims=True), 1e-9)
            uv = read(g, bins, p["attributes"]["TEXCOORD_0"])
            idx = read(g, bins, p["indices"]).astype(np.int64).ravel()
            d = parts.setdefault(image, {"image": image, "pos": [], "nrm": [], "uv": [], "idx": [], "n": 0})
            d["idx"].append(idx + d["n"]); d["pos"].append(pos); d["nrm"].append(nrm); d["uv"].append(uv); d["n"] += len(pos)
    return [{"image": d["image"], "pos": np.vstack(d["pos"]), "nrm": np.vstack(d["nrm"]), "uv": np.vstack(d["uv"]), "idx": np.concatenate(d["idx"])} for d in parts.values()]


rigs = {}


def emit(model, bones):
    """bones: list of (bone name, parent, joint, material class, picture file, pos, nrm, uv, idx)"""
    parts, man = [], []
    for bn, parent, joint, mat, pic, pos, nrm, uv, idx in bones:
        uv2 = np.column_stack([uv[:, 0], 1 - uv[:, 1]])  # the writer flips v back
        parts.append({"name": bn, "image": str(tex / pic), "palette": [], "position": np.round(pos, 4).ravel().tolist(), "normal": np.round(nrm, 4).ravel().tolist(), "uv": np.round(uv2, 5).ravel().tolist(), "index": idx.tolist()})
        lo, hi = pos.min(axis=0), pos.max(axis=0)
        r = lambda v: [round(float(x), 3) for x in v]
        man.append({"name": bn, "parent": parent, "joint": r(joint), "center": r((lo + hi) / 2), "size": r(hi - lo), "mat": mat, "color": "#ffffff", "tris": len(idx) // 3})
        assert len(idx) // 3 < 20000, (model, bn, len(idx) // 3)
    json.dump({"name": model, "size": [0, 0, 0], "parts": parts}, open(out / f"{model}.json", "w", encoding="utf-8"))
    rigs[model] = {"bones": man}
    print(model, [(b["name"], b["tris"]) for b in man])


def mirror(pos, nrm, idx):
    p = pos * np.array([1, -1, 1]); n = nrm * np.array([1, -1, 1]); i = idx.reshape(-1, 3)[:, ::-1].ravel()
    return p, n, i


def tree(model, src, height, bark_pic, leaf_pic, canopy_bone=None, with_mirror=True):
    ps = load(src)
    lo = np.vstack([p["pos"] for p in ps]).min(axis=0); hi = np.vstack([p["pos"] for p in ps]).max(axis=0)
    s = height / (hi[1] - lo[1])
    bark = [p for p in ps if p["image"].startswith("Bark")][0]; leaf = [p for p in ps if not p["image"].startswith("Bark")][0]
    base = bark["pos"][bark["pos"][:, 1] < lo[1] + 0.05 * (hi[1] - lo[1])].mean(axis=0)   # the foot of the trunk stands on the origin
    def place(p): return (p - np.array([base[0], lo[1], base[2]])) * s
    bp, lp = place(bark["pos"]), place(leaf["pos"])
    bones = [("Trunk", None, [0, 0, 0], "Bark", bark_pic, bp, bark["nrm"], bark["uv"], bark["idx"]),
             (canopy_bone or "Leaves", "Trunk", [0, height * 0.55, 0], "Leaf", leaf_pic, lp, leaf["nrm"], leaf["uv"], leaf["idx"])]
    if with_mirror:
        mp, mn, mi = mirror(lp, leaf["nrm"], leaf["idx"])
        bones.append(("Mirror", None, [0, 0, 0], "Leaf", leaf_pic, mp, mn, leaf["uv"], mi))
    emit(model, bones)


def prop(model, src, scale, mat_of=None, bone="Body", swap=None):
    ps = load(src)
    lo = np.vstack([p["pos"] for p in ps]).min(axis=0); hi = np.vstack([p["pos"] for p in ps]).max(axis=0)
    c = np.array([(lo[0] + hi[0]) / 2, lo[1], (lo[2] + hi[2]) / 2])
    bones = []
    for k, p in enumerate(ps):
        pic = PICT[p["image"]]
        pic = (swap or {}).get(pic, pic)
        leafy = pic not in ("rock.png", "pathrock.png", "rock_pale.png", "pathrock_pale.png", "spruce_bark.png", "dead_bark.png", "oak_bark.png")
        bones.append((bone if k == 0 else f"{bone}{k + 1}", None if k == 0 else bone, [0, 0, 0], "Leaf" if leafy else "Bark", pic, (p["pos"] - c) * scale, p["nrm"], p["uv"], p["idx"]))
    emit(model, bones)


# the forest: three spruces (the kit's pines, enlarged about five times), the camp's three birches, and the small things
tree("Spruce1", "Pine_1", 40, "spruce_bark.png", "spruce_leaf.png")
tree("Spruce2", "Pine_2", 32, "spruce_bark.png", "spruce_leaf.png")
tree("Spruce3", "Pine_3", 25, "spruce_bark.png", "spruce_leaf.png")
tree("Spruce4", "Pine_4", 36, "spruce_bark.png", "spruce_leaf.png")
tree("KitBirch1", "CommonTree_3", 13.0, "birch_bark.png", "birch_leaf.png", canopy_bone="Canopy", with_mirror=False)
tree("KitBirch2", "CommonTree_1", 15.5, "birch_bark.png", "birch_leaf.png", canopy_bone="Canopy", with_mirror=False)
tree("KitBirch3", "CommonTree_5", 14.0, "birch_bark.png", "birch_leaf.png", canopy_bone="Canopy", with_mirror=False)
prop("Rock1", "Rock_Medium_1", 0.9)
prop("Rock2", "Rock_Medium_2", 0.9)
prop("Rock3", "Rock_Medium_3", 0.9)
prop("FlowerPatch", "Flower_3_Group", 0.75)
prop("FlowerPatch2", "Flower_4_Group", 0.75)
prop("GrassTuft", "Grass_Common_Tall", 0.8)
prop("GrassShort", "Grass_Common_Short", 0.9)
prop("Fern", "Fern_1", 1.2)
prop("Bush", "Bush_Common_Flowers", 1.6)
prop("Mushroom", "Mushroom_Common", 0.8)
# for the scenes after Wood (Stone, Ashcoal, Bog-Iron ...): place them by these names from a scene's map
tree("Oak1", "TwistedTree_1", 30, "oak_bark.png", "oak_leaf.png", canopy_bone="Canopy", with_mirror=False)
tree("Oak2", "TwistedTree_3", 26, "oak_bark.png", "oak_leaf.png", canopy_bone="Canopy", with_mirror=False)
tree("Alder", "CommonTree_1", 12, "spruce_bark.png", "bush_leaf.png", canopy_bone="Canopy", with_mirror=False)
prop("DeadTree1", "DeadTree_1", 16 / 9.5)
prop("DeadTree2", "DeadTree_3", 20 / 13.3)
prop("Pebble1", "Pebble_Round_1", 2.6)
prop("Pebble2", "Pebble_Square_2", 2.8)
prop("PebblePath", "RockPath_Round_Wide", 2.2)
prop("Clover", "Clover_1", 0.8)
prop("Plant1", "Plant_1_Big", 0.6)
prop("Plant7", "Plant_7_Big", 1.3)
prop("ShelfFungus", "Mushroom_Laetiporus", 0.9)
prop("WispyGrass", "Grass_Wispy_Tall", 0.8)
# the Stone scene's river-worn limestone: the same stones with the pale picture
PALE = {"rock.png": "rock_pale.png", "pathrock.png": "pathrock_pale.png"}
prop("PaleRock1", "Rock_Medium_1", 0.9, swap=PALE)
prop("PaleRock2", "Rock_Medium_2", 0.9, swap=PALE)
prop("PaleRock3", "Rock_Medium_3", 0.9, swap=PALE)
prop("PalePebble1", "Pebble_Round_1", 2.6, swap=PALE)
prop("PalePebble2", "Pebble_Square_2", 2.8, swap=PALE)
prop("PalePebble3", "Pebble_Round_3", 2.6, swap=PALE)
prop("PalePebblePath", "RockPath_Round_Wide", 2.2, swap=PALE)
# ---- the snapped birch branch and the storm's flying leaf sprig: ours, built here so they wear the same bark and leaves as the kit birches ----
def tube(points, radii, sides, vscale=1.2, bumps=0.0):
    """A tube along points with a radius at each; -> pos, nrm, uv, idx. Open at both ends."""
    pts = np.array(points, dtype=np.float64); n = len(pts)
    tang = np.gradient(pts, axis=0); tang /= np.linalg.norm(tang, axis=1, keepdims=True)
    ref = np.array([0.0, 1.0, 0.0])
    pos, nrm, uv, idx = [], [], [], []
    run = 0.0
    for i in range(n):
        if i: run += np.linalg.norm(pts[i] - pts[i - 1])
        t = tang[i]; a = np.cross(t, ref)
        if np.linalg.norm(a) < 1e-4: a = np.cross(t, np.array([1.0, 0, 0]))
        a /= np.linalg.norm(a); b = np.cross(t, a)
        for k in range(sides + 1):
            th = 2 * np.pi * k / sides
            d = np.cos(th) * a + np.sin(th) * b
            rr = radii[i] * (1 + bumps * np.sin(th * 3 + i * 1.7) * np.sin(i * 2.3))
            pos.append(pts[i] + d * rr); nrm.append(d); uv.append([k / sides, run / vscale])
    row = sides + 1
    for i in range(n - 1):
        for k in range(sides):
            a0, b0, c0, d0 = i * row + k, i * row + k + 1, (i + 1) * row + k, (i + 1) * row + k + 1
            idx += [a0, b0, c0, b0, d0, c0]  # outward faces
    return np.array(pos), np.array(nrm), np.array(uv), np.array(idx)


def curve(p0, p1, sag, n=6):
    """n points from p0 to p1, bowed by sag (a vector added at the middle)"""
    p0, p1, sag = np.array(p0, float), np.array(p1, float), np.array(sag, float)
    return [p0 + (p1 - p0) * u + sag * np.sin(np.pi * u) for u in np.linspace(0, 1, n)]


def join(parts):
    pos, nrm, uv, idx, n = [], [], [], [], 0
    for p, nn, u, i in parts:
        pos.append(p); nrm.append(nn); uv.append(u); idx.append(i + n); n += len(p)
    return np.vstack(pos), np.vstack(nrm), np.vstack(uv), np.concatenate(idx)


def card(centre, right, up, size):
    c, r, u = np.array(centre, float), np.array(right, float), np.array(up, float)
    r /= np.linalg.norm(r); u /= np.linalg.norm(u); nn = np.cross(r, u)
    pos = np.array([c - r * size / 2, c + r * size / 2, c - r * size / 2 + u * size, c + r * size / 2 + u * size])
    return pos, np.tile(nn, (4, 1)), np.array([[0, 1], [1, 1], [0, 0], [1, 0]], float), np.array([0, 1, 2, 1, 3, 2])


fibre = np.asarray(Image.fromarray((rng.random((8, 256)) * 255).astype(np.uint8)).resize((256, 256), Image.BICUBIC), dtype=np.float64)[..., None] / 255.0
Image.fromarray(np.clip(rgb("#e9d2a4")[None, None, :] * (0.82 + 0.3 * fibre), 0, 255).astype(np.uint8), "RGB").save(tex / "wood_pale.png")
brng = np.random.default_rng(9)
# the limb: thick at the break (x = -1.9), tapering to its tip (x = 2.1), with a slight kink at every fork
main_pts = [[-1.9, 0.0, 0.0], [-1.4, 0.07, 0.03], [-0.9, 0.12, 0.04], [-0.3, 0.06, -0.01], [0.2, 0.05, -0.03], [0.7, 0.14, 0.0], [1.2, 0.2, 0.02], [1.7, 0.16, 0.01], [2.1, 0.12, 0.0]]
main_r = [0.235, 0.22, 0.2, 0.185, 0.165, 0.145, 0.12, 0.095, 0.06]
bark = [tube(main_pts, main_r, 12, 1.3, bumps=0.06)]
leaf_at = []
forks = [(-0.9, [0.1, 0.9, 0.45], 1.25, 0.09), (-0.3, [0.25, 0.5, -0.8], 1.05, 0.085), (0.2, [0.35, 0.95, 0.3], 1.1, 0.08), (0.7, [0.3, 0.3, -0.75], 0.85, 0.07), (1.2, [0.45, 0.8, 0.45], 0.8, 0.06), (1.7, [0.6, 0.4, -0.5], 0.55, 0.045)]
for fx, d, ln, r0 in forks:
    base = np.array([fx, np.interp(fx, [p[0] for p in main_pts], [p[1] for p in main_pts]), 0.0]); d = np.array(d) / np.linalg.norm(d)
    end = base + d * ln
    pts = curve(base, end, [0, 0.12 * ln, 0], 6)
    bark.append(tube(pts, list(np.linspace(r0, 0.022, 6)), 7, 1.0))
    bark.append(tube([base - d * 0.02, base + d * 0.08], [r0 * 1.5, r0 * 1.05], 7, 1.0))            # the swollen collar where it leaves the limb
    leaf_at += [(pts[5], d), (pts[3], d)]
    for sgn in (-1, 1):                                                                              # two fine side twigs
        side = np.cross(d, [0, 1, 0]) * sgn + np.array([0, 0.3, 0])
        side /= np.linalg.norm(side)
        s0 = pts[3]; s1 = s0 + (d * 0.5 + side * 0.6) * ln * 0.45
        bark.append(tube(curve(s0, s1, [0, 0.05, 0], 4), [0.03, 0.024, 0.018, 0.012], 5, 0.8))
        leaf_at.append((s1, (s1 - s0)))
leaf_at.append((np.array(main_pts[-1]), np.array([1.0, 0.2, 0.0])))
# a strip of bark torn back from the break, curling away
strip = curve([-1.86, 0.2, 0.05], [-2.55, 0.42, 0.22], [0, 0.16, 0.05], 5)
bark.append(tube(strip, [0.1, 0.085, 0.07, 0.05, 0.02], 5, 0.8))
bpos, bnrm, buv, bidx = join(bark)
# the break: a short core of pale wood and a crown of long splinters, as green wood tears
brk = [tube([[-1.9, 0.0, 0.0], [-2.0, 0.0, 0.0], [-2.12, 0.01, 0.0]], [0.215, 0.17, 0.03], 10, 0.5)]
for k in range(11):
    th = 2 * np.pi * k / 11 + brng.uniform(-0.2, 0.2); rr = brng.uniform(0.07, 0.2); ln = brng.uniform(0.25, 0.75)
    s0 = np.array([-1.92, np.cos(th) * rr, np.sin(th) * rr]); s1 = s0 + np.array([-ln, np.cos(th) * rr * brng.uniform(0.2, 0.9), np.sin(th) * rr * brng.uniform(0.2, 0.9)])
    brk.append(tube([s0, (s0 + s1) / 2, s1], [0.045, 0.03, 0.004], 4, 0.4))
kpos, knrm, kuv, kidx = join(brk)
# leaf sprays: two crossed cards at each twig end, turned to the light, a few hanging
cards = []
for p, d in leaf_at:
    d = np.array(d, float); d /= np.linalg.norm(d)
    for turn in (0.0, 1.4):
        right = np.cross(d, [np.sin(turn), np.cos(turn), 0.2]); up = d * 0.75 + np.array([0, 0.5, 0]) * (1 if brng.random() > 0.25 else -0.6)
        cards.append(card(np.array(p) - d * 0.12, right, up, brng.uniform(0.75, 1.05)))
lpos, lnrm, luv, lidx = join(cards)
emit("BirchBranch", [("Branch", None, [0, 0, 0], "Bark", "birch_bark.png", bpos, bnrm, buv, bidx),
                     ("Break", "Branch", [-1.9, 0, 0], "Bark", "wood_pale.png", kpos, knrm, kuv, kidx),
                     ("Leaves", "Branch", [1.0, 0.75, 0.25], "Leaf", "birch_leaf.png", lpos, lnrm, luv, lidx)])
sp = [card([0, -0.45, 0], [1, 0, 0.2], [0, 1, 0.15], 0.9), card([0, -0.45, 0], [0.2, 0, 1], [0.15, 1, 0], 0.9)]
spos, snrm, suv, sidx = join(sp)
emit("Leaf", [("Leaf", None, [0, 0, 0], "Leaf", "birch_leaf.png", spos, snrm, suv, sidx)])
json.dump(rigs, open(out / "kit_rig.json", "w", encoding="utf-8"))
print("kit models:", len(rigs))
