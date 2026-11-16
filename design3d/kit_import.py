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
PICT = {"Leaf_Pine_C.png": "spruce_leaf.png", "Leaves_NormalTree_C.png": "birch_leaf.png", "Leaves_TwistedTree_C.png": "bush_leaf.png", "Bark_NormalTree.png": "spruce_bark.png",
        "Rocks_Diffuse.png": "rock.png", "Flowers.png": "flowers.png", "Leaves.png": "leaves.png", "Grass.png": "grass.png", "Mushrooms.png": "mushrooms.png"}

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


def prop(model, src, scale, mat_of=None, bone="Body"):
    ps = load(src)
    lo = np.vstack([p["pos"] for p in ps]).min(axis=0); hi = np.vstack([p["pos"] for p in ps]).max(axis=0)
    c = np.array([(lo[0] + hi[0]) / 2, lo[1], (lo[2] + hi[2]) / 2])
    bones = []
    for k, p in enumerate(ps):
        pic = PICT[p["image"]]
        leafy = pic not in ("rock.png", "spruce_bark.png")
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
json.dump(rigs, open(out / "kit_rig.json", "w", encoding="utf-8"))
print("kit models:", len(rigs))
