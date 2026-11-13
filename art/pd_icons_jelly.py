"""Pixel Depth jelly icon set (2026-11-12, the user: "Remake all the icons so that they match" the jelly text).
Each icon is a few flat filled shapes (SVG paths on a 128 grid, drawn here) that Blender extrudes and bevels into puffy
jelly glass, with a darker rim behind, lit and rendered like the jelly letters (pd_logo_jelly.py). 256 px, transparent.
    blender -b -P art/pd_icons_jelly.py -- <out_dir> [name ...]
"""
import bpy, sys, os, math, tempfile

args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
out = os.path.abspath(args[0] if args else "icons_jelly")
only = set(args[1:])
os.makedirs(out, exist_ok=True)


def circ(cx, cy, r):
    return f"M{cx - r} {cy} a{r} {r} 0 1 0 {2 * r} 0 a{r} {r} 0 1 0 {-2 * r} 0 Z"


def ring(cx, cy, r, w):  # a filled band: an outer circle with an inner hole
    return circ(cx, cy, r) + " " + circ(cx, cy, r - w)


def poly(*p):
    return "M" + " L".join(f"{x} {y}" for x, y in p) + " Z"


def rrect(x, y, w, h, r):
    return f"M{x + r} {y} H{x + w - r} Q{x + w} {y} {x + w} {y + r} V{y + h - r} Q{x + w} {y + h} {x + w - r} {y + h} H{x + r} Q{x} {y + h} {x} {y + h - r} V{y + r} Q{x} {y} {x + r} {y} Z"


def star(cx, cy, R, r, n=5, rot=-90):
    pts = []
    for i in range(n * 2):
        a = math.radians(rot + i * 180 / n)
        q = R if i % 2 == 0 else r
        pts.append((round(cx + q * math.cos(a), 1), round(cy + q * math.sin(a), 1)))
    return poly(*pts)


GOLD, GOLD_D, PINK, PINK_L, STEEL, WOOD, WOOD_D, LEATHER, TEAL, CREAM, LILAC, LILAC_D, CYAN, FLAME, FLAME_L, RED, INK, MINT, WHITE = (
    "#ffc83a", "#e08a1a", "#ff4f9a", "#ffa6cc", "#c9d2e6", "#c8824a", "#8a5230", "#d98a5a", "#2fd0b4", "#fff0d2", "#b79bff", "#7a58e0", "#5fe0ff", "#ff8a2a", "#ffe066", "#ff4a5a", "#3a2a52", "#7df0c0", "#ffffff")

# name: list of (path, colour), back to front
ICONS = {
    "coin": [(circ(64, 64, 48), GOLD), (ring(64, 64, 36, 7), GOLD_D), (star(64, 64, 19, 8), CREAM)],
    "gem": [(poly((34, 28), (94, 28), (118, 58), (64, 114), (10, 58)), PINK), (poly((40, 34), (88, 34), (76, 56), (52, 56)), PINK_L)],
    "pick": [(poly((22, 100), (32, 110), (88, 52), (78, 42)), WOOD), ("M30 34 Q76 8 114 56 Q84 40 62 48 Q44 54 30 34 Z", STEEL)],
    "bag": [(ring(64, 34, 22, 9), WOOD_D), (rrect(20, 36, 88, 78, 22), LEATHER), ("M20 60 Q64 86 108 60 V56 Q108 36 86 36 H42 Q20 36 20 56 Z", WOOD), (rrect(52, 62, 24, 26, 6), GOLD)],
    "crew": [("M18 86 Q18 30 64 30 Q110 30 110 86 Z", GOLD), (rrect(8, 80, 112, 22, 10), GOLD_D), (circ(64, 54, 15), CREAM)],
    "surface": [("M64 8 L96 46 H78 V68 H50 V46 H32 Z", TEAL), (poly((18, 74), (110, 74), (100, 104), (28, 104)), WOOD), (circ(42, 110, 11), STEEL), (circ(86, 110, 11), STEEL)],
    "egg": [("M64 12 C94 12 108 60 108 80 C108 104 90 118 64 118 C38 118 20 104 20 80 C20 60 34 12 64 12 Z", CREAM), (circ(46, 62, 10), PINK_L), (circ(80, 88, 12), LILAC), (circ(76, 46, 7), MINT)],
    "star": [(star(64, 66, 54, 24), GOLD), (star(64, 66, 24, 11), FLAME_L)],
    "dice": [(rrect(18, 18, 92, 92, 20), WHITE), (circ(42, 42, 9), LILAC_D), (circ(86, 86, 9), LILAC_D), (circ(64, 64, 9), LILAC_D), (circ(86, 42, 9), LILAC_D), (circ(42, 86, 9), LILAC_D)],
    "map": [(poly((12, 30), (46, 18), (82, 30), (116, 18), (116, 98), (82, 110), (46, 98), (12, 110)), CREAM), (poly((46, 18), (82, 30), (82, 110), (46, 98)), "#ffd9a0"), (poly((88, 44), (96, 36), (112, 52), (104, 60)), RED), (poly((104, 36), (112, 44), (96, 60), (88, 52)), RED)],
    "camp": [(poly((14, 100), (24, 88), (112, 104), (104, 116)), WOOD_D), (poly((114, 100), (104, 88), (16, 104), (24, 116)), WOOD), ("M64 10 C92 42 100 62 86 84 C76 98 52 98 42 84 C28 62 44 46 52 34 C56 46 62 44 64 10 Z", FLAME), ("M64 48 C76 62 78 74 70 84 C62 90 54 84 54 74 C54 64 62 60 64 48 Z", FLAME_L)],
    "chisel": [(poly((70, 14), (114, 58), (100, 72), (56, 28)), WOOD), (poly((56, 28), (100, 72), (86, 80), (48, 42)), GOLD_D), (poly((48, 42), (86, 80), (40, 106), (22, 88)), STEEL)],
    "hammer": [(poly((28, 106), (40, 116), (82, 60), (70, 50)), WOOD), (poly((50, 20), (104, 58), (86, 84), (32, 46)), STEEL)],
    "lock": [("M34 62 V44 A30 30 0 0 1 94 44 V62 H78 V44 A14 14 0 0 0 50 44 V62 Z", STEEL), (rrect(20, 56, 88, 60, 14), GOLD), (circ(64, 80, 9), INK), (poly((59, 84), (69, 84), (72, 102), (56, 102)), INK)],
    "heart": [("M64 112 C10 76 8 42 30 26 C46 16 60 26 64 42 C68 26 82 16 98 26 C120 42 118 76 64 112 Z", PINK), ("M30 46 C30 36 38 30 46 32 C40 36 36 42 36 50 Z", PINK_L)],
    "torch": [(rrect(50, 84, 28, 36, 8), WOOD), ("M64 6 C94 40 104 60 88 84 C78 98 50 98 40 84 C24 60 42 44 50 30 C54 44 62 42 64 6 Z", FLAME), ("M64 46 C76 60 80 74 70 84 C62 90 54 84 54 74 C54 62 62 58 64 46 Z", FLAME_L)],
    "flare": [(poly((18, 104), (30, 116), (78, 62), (66, 50)), RED), (star(88, 40, 36, 15, 6), FLAME), (star(88, 40, 16, 8, 6), FLAME_L)],
    "sonar": [(ring(64, 64, 54, 11), CYAN), (ring(64, 64, 34, 10), CYAN), (circ(64, 64, 11), WHITE)],
    "gear": [(star(64, 64, 56, 40, 8, -90) + " " + circ(64, 64, 18), LILAC), (ring(64, 64, 34, 9), LILAC_D)],
    "shirt": [(poly((40, 16), (54, 24), (74, 24), (88, 16), (120, 40), (104, 62), (92, 54), (92, 114), (36, 114), (36, 54), (24, 62), (8, 40)), LILAC), (poly((54, 24), (74, 24), (64, 40)), LILAC_D)],
    "pin": [("M64 118 C40 84 22 70 22 48 A42 42 0 0 1 106 48 C106 70 88 84 64 118 Z " + circ(64, 48, 16), PINK)],
    "smile": [(circ(64, 64, 52), GOLD), (circ(46, 52, 8), INK), (circ(82, 52, 8), INK), ("M36 72 Q64 108 92 72 Q64 90 36 72 Z", INK)],
    "calm": [(circ(64, 64, 52), CREAM), (circ(46, 56, 7), INK), (circ(82, 56, 7), INK), ("M44 78 Q64 96 84 78 Q64 88 44 78 Z", INK), (circ(34, 74, 8), PINK_L), (circ(94, 74, 8), PINK_L)],
    "uneasy": [(circ(64, 64, 52), CREAM), (circ(46, 56, 8), INK), (circ(82, 56, 8), INK), (rrect(46, 82, 36, 8, 4), INK)],
    "scared": [(circ(64, 64, 52), LILAC), (circ(44, 54, 11), WHITE), (circ(84, 54, 11), WHITE), (circ(44, 56, 5), INK), (circ(84, 56, 5), INK), (circ(64, 90, 12), INK)],
    # pet faces (2026-11-13, plan phase A): eyes and a mouth only, on clear; shown on the front of a pet's head. Every shape gets a rim.
    "face_calm": [(circ(40, 56, 13), INK), (circ(88, 56, 13), INK), (circ(44, 51, 4.5), WHITE), (circ(92, 51, 4.5), WHITE), ("M52 84 Q64 96 76 84 Q64 90 52 84 Z", INK)],
    "face_happy": [("M24 62 Q40 38 56 62 L49 62 Q40 50 31 62 Z", INK), ("M72 62 Q88 38 104 62 L97 62 Q88 50 79 62 Z", INK), ("M46 78 Q64 104 82 78 Z", RED)],
    "face_greedy": [(star(40, 56, 17, 7), GOLD), (star(88, 56, 17, 7), GOLD), ("M44 80 Q64 104 84 80 Q64 90 44 80 Z", INK)],
    "face_scared": [(circ(40, 54, 16), WHITE), (circ(88, 54, 16), WHITE), (circ(40, 56, 5), INK), (circ(88, 56, 5), INK), (circ(64, 90, 9), INK)],
    "face_sleepy": [(rrect(26, 54, 28, 7, 3), INK), (rrect(74, 54, 28, 7, 3), INK), (circ(64, 88, 5), INK)],
    "face_proud": [("M24 52 Q40 76 56 52 L49 52 Q40 64 31 52 Z", INK), ("M72 52 Q88 76 104 52 L97 52 Q88 64 79 52 Z", INK), ("M50 84 Q66 98 82 80 Q66 90 50 84 Z", INK), (star(108, 30, 10, 4, 4), GOLD)],
    "face_hurt": [(poly((28, 46), (34, 40), (52, 62), (46, 68)), INK), (poly((46, 40), (52, 46), (34, 68), (28, 62)), INK), (poly((76, 46), (82, 40), (100, 62), (94, 68)), INK), (poly((94, 40), (100, 46), (82, 68), (76, 62)), INK), ("M48 96 Q64 78 80 96 Q64 88 48 96 Z", INK)],
    "face_curious": [(circ(40, 54, 16), INK), (circ(88, 58, 10), INK), (circ(45, 48, 5.5), WHITE), (circ(91, 55, 3.5), WHITE), (circ(66, 90, 6), INK)],
    "chest": [(rrect(14, 52, 100, 62, 10), WOOD), ("M14 60 V46 Q14 18 42 18 H86 Q114 18 114 46 V60 Z", WOOD_D), (rrect(28, 18, 14, 96, 4), GOLD), (rrect(86, 18, 14, 96, 4), GOLD), (rrect(52, 50, 24, 28, 6), GOLD_D)],
}

bpy.ops.wm.read_factory_settings(use_empty=True)
try: bpy.ops.preferences.addon_enable(module="io_curve_svg")
except Exception as e: print("svg addon:", e)
sc = bpy.context.scene
sc.render.engine = "CYCLES"
try:
    prefs = bpy.context.preferences.addons["cycles"].preferences
    for kind in ("OPTIX", "CUDA"):
        try:
            prefs.compute_device_type = kind
            prefs.get_devices()
            for d in prefs.devices: d.use = True
            sc.cycles.device = "GPU"
            break
        except Exception:
            pass
except Exception:
    pass
sc.cycles.samples = 64
sc.cycles.use_denoising = True
sc.render.film_transparent = True
sc.render.resolution_x = sc.render.resolution_y = 256
sc.render.image_settings.file_format = "PNG"
sc.render.image_settings.color_mode = "RGBA"
sc.view_settings.view_transform = "Standard"
world = bpy.data.worlds.new("W")
sc.world = world
world.use_nodes = True
world.node_tree.nodes["Background"].inputs[0].default_value = (0.12, 0.08, 0.18, 1)
world.node_tree.nodes["Background"].inputs[1].default_value = 0.7

target = bpy.data.objects.new("Target", None)
sc.collection.objects.link(target)


def light(name, loc, energy, color, size):
    d = bpy.data.lights.new(name, "AREA")
    d.energy, d.color, d.size = energy, color, size
    o = bpy.data.objects.new(name, d)
    sc.collection.objects.link(o)
    o.location = loc
    c = o.constraints.new("TRACK_TO")
    c.target, c.track_axis, c.up_axis = target, "TRACK_NEGATIVE_Z", "UP_Y"


light("key", (-1.6, 2.4, 4.0), 110, (1, 1, 1), 2.5)
light("strip", (0.6, 1.2, 3.0), 50, (1, 1, 1), 0.5)
light("rim", (3.0, -1.0, 1.6), 120, (1, 0.7, 0.9), 2.0)
light("fill", (-3.0, -2.0, 1.2), 110, (0.7, 0.9, 1), 2.5)
cam_d = bpy.data.cameras.new("Cam")
cam_d.type, cam_d.ortho_scale = "ORTHO", 1.32
cam = bpy.data.objects.new("Cam", cam_d)
sc.collection.objects.link(cam)
cam.location = (0.2, -0.75, 5)
c = cam.constraints.new("TRACK_TO")
c.target, c.track_axis, c.up_axis = target, "TRACK_NEGATIVE_Z", "UP_Y"
sc.camera = cam

mats = {}


def hexrgb(h):
    v = [int(h[i:i + 2], 16) / 255 for i in (1, 3, 5)]
    return tuple(x ** 2.2 for x in v) + (1,)  # sRGB to linear


def jelly(col):
    if col in mats: return mats[col]
    m = bpy.data.materials.new(col)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = hexrgb(col)
    for k, v in {"Roughness": 0.06, "IOR": 1.42, "Transmission Weight": 0.22, "Subsurface Weight": 0.3, "Coat Weight": 1.0, "Coat Roughness": 0.02, "Emission Strength": 0.1}.items():
        if k in b.inputs: b.inputs[k].default_value = v
    if "Emission Color" in b.inputs: b.inputs["Emission Color"].default_value = hexrgb(col)
    mats[col] = m
    return m


rimM = bpy.data.materials.new("rim")
rimM.use_nodes = True
rb = rimM.node_tree.nodes["Principled BSDF"]
rb.inputs["Base Color"].default_value = (0.12, 0.05, 0.3, 1)
for k, v in {"Roughness": 0.14, "Metallic": 0.7, "Coat Weight": 1.0}.items():
    if k in rb.inputs: rb.inputs[k].default_value = v

tmp = tempfile.mkdtemp()
# measure the importer once: a square covering the whole 128 page tells the size of one SVG unit and where the page sits
probe = os.path.join(tmp, "probe.svg")
with open(probe, "w") as f:
    f.write('<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128"><path d="M0 0 H128 V128 H0 Z" fill="#ffffff"/></svg>')
before = set(bpy.data.objects)
bpy.ops.import_curve.svg(filepath=probe)
bpy.context.view_layer.update()
from mathutils import Vector
pts = [o.matrix_world @ Vector(c) for o in set(bpy.data.objects) - before for c in o.bound_box]
PX = (max(p.x for p in pts) - min(p.x for p in pts)) / 128
OX, OY = min(p.x for p in pts), max(p.y for p in pts)
for o in set(bpy.data.objects) - before: bpy.data.objects.remove(o)
print("svg unit", PX, OX, OY)
for name, shapes in ICONS.items():
    if only and name not in only: continue
    made = []
    for i, (d, col) in enumerate(shapes):
        svg = os.path.join(tmp, f"{name}_{i}.svg")
        with open(svg, "w") as f:
            f.write(f'<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128"><path d="{d}" fill="{col}" fill-rule="evenodd"/></svg>')
        before = set(bpy.data.objects)
        bpy.ops.import_curve.svg(filepath=svg)
        for o in set(bpy.data.objects) - before:
            for coll in list(o.users_collection): coll.objects.unlink(o)
            sc.collection.objects.link(o)
            made.append((o, i, col))
    # normalise: the 128 grid becomes 1 unit, centred (the importer's scale is its own; measure the first object's curve space)
    bpy.context.view_layer.update()
    objs = []
    for o, i, col in made:
        cu = o.data
        cu.dimensions, cu.fill_mode = "2D", "BOTH"
        cu.resolution_u = 16
        cu.extrude, cu.bevel_depth, cu.bevel_resolution = 0.0, 0.0, 6
        objs.append((o, i, col))
    s = 1.0 / (128 * PX)
    cx, cy = OX + 64 * PX, OY - 64 * PX
    final = []
    for o, i, col in objs:
        o.scale = (o.scale[0] * s, o.scale[1] * s, o.scale[2] * s)
        o.location = ((o.location.x - cx) * s, (o.location.y - cy) * s, 0.02 + i * (0.012 if name.startswith("face_") else 0.07))  # a face is flat: its parts must not slide apart
        cu = o.data
        cu.extrude, cu.bevel_depth = 0.035 / s, 0.03 / s
        cu.materials.clear()
        cu.materials.append(jelly(col))
        final.append(o)
        if i == 0 and not name.startswith("face_"):  # the darker rim behind the back shape (faces have none: their parts sit on the pet's own head)
            r = o.copy()
            r.data = cu.copy()
            sc.collection.objects.link(r)
            r.data.offset = 0.045 / s
            r.data.extrude, r.data.bevel_depth = 0.02 / s, 0.02 / s
            r.location.z = -0.09
            r.data.materials.clear()
            r.data.materials.append(rimM)
            final.append(r)
    cam.location = (0.0, -0.08, 5) if name.startswith("face_") else (0.2, -0.75, 5)  # faces are seen dead on
    bpy.context.view_layer.update()
    sc.render.filepath = os.path.join(out, name + ".png")
    bpy.ops.render.render(write_still=True)
    for o in final:
        d_ = o.data
        bpy.data.objects.remove(o)
        if d_.users == 0: bpy.data.curves.remove(d_)
print("done", out)
