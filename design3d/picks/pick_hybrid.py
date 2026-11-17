"""Hybrid pickaxes (2026-11-17): the mass of a real pick-mattock with our magical dressing. The owner: the old heroes were
"just a stick" (thin crescent blades on a 0.15-stud stick), the voxel remake had none of the high-quality effects; "a medium
between the 2 art styles". Reference: The Forge's pickaxe set (art/refs_picks/forge_sheet.jpg, gamewith.net/the-forge/72034):
smooth low-poly, a thick wrapped handle with metal rings, a socket block, deep curved blades with bevels, a themed silhouette.
    blender -b -P design3d/picks/pick_hybrid.py -- <out_dir> [Name ...]
Tiers, colours, variants, marks and glows come from design3d/picks/picks.py (TIERS). One GLB per tier; objects are named
"<Part>__<Role>" like the pets, so the game paints them (Shared.PickVoxels: roles Head/Dark/Light/Handle/Grip/Band/Accent/Gem).
Axes (Blender): x across the head, z up the handle (the foot at 0), y the depth. 1 unit = 1 stud."""
import bpy, bmesh, math, os, sys
from mathutils import Vector, Matrix

here = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, here)
from picks import TIERS

args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = os.path.abspath(args[0] if args else os.path.join(here, "out_hybrid"))
ONLY = set(args[1:])
os.makedirs(OUT, exist_ok=True)

HL = 3.3  # handle length
HR = 0.13  # handle radius (was 0.075 on the heroes)
TOP = HL + 0.1  # head centre line


class Builder:
    def __init__(self):
        self.groups = {}  # (part, role) -> bmesh

    def bm(self, part, role):
        k = (part, role)
        if k not in self.groups: self.groups[k] = bmesh.new()
        return self.groups[k]

    def cyl(self, part, role, z0, z1, r0, r1=None, seg=8, x=0.0, y=0.0):
        b = self.bm(part, role)
        r1 = r0 if r1 is None else r1
        bmesh.ops.create_cone(b, cap_ends=True, segments=seg, radius1=r0, radius2=r1, depth=z1 - z0, matrix=Matrix.Translation((x, y, (z0 + z1) / 2)))

    def box(self, part, role, c, s, bevel=0.0, rot=None):
        b = bmesh.new()
        bmesh.ops.create_cube(b, size=1.0)
        bmesh.ops.scale(b, vec=Vector(s), verts=b.verts)
        if bevel > 0:
            bmesh.ops.bevel(b, geom=list(b.edges), offset=bevel, segments=1, affect="EDGES")
        if rot: bmesh.ops.rotate(b, verts=b.verts, cent=Vector((0, 0, 0)), matrix=rot)
        bmesh.ops.translate(b, vec=Vector(c), verts=b.verts)
        self.merge(part, role, b)

    def merge(self, part, role, b):
        me = bpy.data.meshes.new("tmp"); b.to_mesh(me); b.free()
        self.bm(part, role).from_mesh(me)
        bpy.data.meshes.remove(me)

    def sweep(self, part, role, spine, secs, seg=6):
        """a tapered, bevelled blade along a spine of (x, z) points; secs: (half height, half depth) per point.
        The cross section is a squashed hexagon, so the blade has a sharp top and bottom edge and a thick middle."""
        b = bmesh.new()
        rings = []
        for i, ((x, z), (h, d)) in enumerate(zip(spine, secs)):
            if i < len(spine) - 1:
                tx, tz = spine[i + 1][0] - x, spine[i + 1][1] - z
            else:
                tx, tz = x - spine[i - 1][0], z - spine[i - 1][1]
            L = math.hypot(tx, tz) or 1
            nx, nz = -tz / L, tx / L  # the up direction of the section
            ring = []
            for k in range(seg):
                a = k / seg * math.pi * 2
                u, v = math.cos(a) * h, math.sin(a) * d
                ring.append(b.verts.new((x + nx * u, v, z + nz * u)))
            rings.append(ring)
        for r0, r1 in zip(rings, rings[1:]):
            for k in range(seg):
                b.faces.new([r0[k], r0[(k + 1) % seg], r1[(k + 1) % seg], r1[k]])
        b.faces.new(list(reversed(rings[0])))
        b.faces.new(rings[-1])
        bmesh.ops.recalc_face_normals(b, faces=b.faces)
        self.merge(part, role, b)

    def gem(self, part, role, c, r, subd=1):
        b = bmesh.new()
        bmesh.ops.create_icosphere(b, subdivisions=subd, radius=r, matrix=Matrix.Translation(c))
        self.merge(part, role, b)

    def prism(self, part, role, pts2d, c, depth, scale=1.0):
        """an extruded flat shape (star, heart, moon ...) facing the y axis"""
        b = bmesh.new()
        f = [b.verts.new((c[0] + px * scale, c[1] - depth / 2, c[2] + pz * scale)) for px, pz in pts2d]
        face = b.faces.new(f)
        ext = bmesh.ops.extrude_face_region(b, geom=[face])
        bmesh.ops.translate(b, vec=Vector((0, depth, 0)), verts=[v for v in ext["geom"] if isinstance(v, bmesh.types.BMVert)])
        bmesh.ops.recalc_face_normals(b, faces=b.faces)
        self.merge(part, role, b)


def star_pts(n=5, r0=1.0, r1=0.45):
    return [((r0 if i % 2 == 0 else r1) * math.sin(i * math.pi / n), (r0 if i % 2 == 0 else r1) * math.cos(i * math.pi / n)) for i in range(n * 2)]


def heart_pts():
    pts = []
    for i in range(24):
        t = i / 24 * math.pi * 2
        pts.append((16 * math.sin(t) ** 3 / 17, (13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t)) / 17))
    return pts


def moon_pts():
    pts = [(math.cos(a) * 1.0, math.sin(a) * 1.0) for a in [math.pi / 2 + i / 12 * math.pi for i in range(13)]]
    pts += [(math.cos(a) * 0.62 - 0.3, math.sin(a) * 0.7) for a in [math.pi * 1.5 - i / 12 * math.pi for i in range(13)]]
    return pts


def blade(B, t, side, length, pointed=True, droop=0.55):
    """one arm: thick at the socket, curving down and thinning to a point (or a squared hammer face)"""
    n = 9
    spine, secs = [], []
    for i in range(n):
        u = i / (n - 1)
        x = side * (0.28 + u * length)
        z = TOP - droop * u ** 1.8
        h = (0.33 * (1 - 0.84 * u) + 0.02) if pointed else 0.26
        d = (0.24 * (1 - 0.72 * u) + 0.03) if pointed else 0.22
        spine.append((x, z)); secs.append((h, d))
    B.sweep("Head", "Head", spine, secs)
    # a bright edge along the top of the arm (the "sharpened" highlight) and a dark keel underneath
    B.sweep("Head", "Light", [(x, z + h * 0.82) for (x, z), (h, d) in zip(spine, secs)][:-1], [(h * 0.22, d * 0.55) for h, d in secs][:-1], seg=4)
    if t["glow"] in ("runes", "veins", "aurora", "prism", "crystal", "cracks", "specks"):  # a glowing inlay along the arm
        B.sweep("Head", "Accent", [(x, z) for (x, z) in spine][1:-2], [(h * 0.18, d * 1.04) for h, d in secs][1:-2], seg=4)
    return spine, secs


def build(t):
    B = Builder()
    k = t["size"]
    # HANDLE: a thick, slightly tapered shaft, leather wraps, metal ferrules, a pommel ornament
    B.cyl("Handle", "Handle", 0.25, HL, HR * 1.05, HR * 0.95)
    for i in range(7):  # the grip wraps: rings that stand proud of the shaft
        z = 0.42 + i * 0.13
        B.cyl("Handle", "Grip", z, z + 0.1, HR * 1.22, HR * 1.22)
    for z in (0.3, 1.38, HL - 0.25):
        B.cyl("Handle", "Band", z - 0.06, z + 0.06, HR * 1.35, HR * 1.35)
    B.cyl("Handle", "Band", 0.0, 0.25, HR * 0.9, HR * 1.4, seg=8)  # the pommel cap
    B.gem("Handle", "Gem" if t["mark"] else "Band", (0, 0, -0.08), 0.13)
    # HEAD: the socket block, then the arms
    B.box("Head", "Dark", (0, 0, TOP), (0.5 * k, 0.46 * k, 0.62 * k), bevel=0.06)
    B.box("Head", "Band", (0, 0, TOP - 0.33 * k), (0.56 * k, 0.5 * k, 0.1), bevel=0.02)
    B.box("Head", "Band", (0, 0, TOP + 0.33 * k), (0.56 * k, 0.5 * k, 0.1), bevel=0.02)
    v = t["variant"]
    if v != "hammer": blade(B, t, 1, 1.25 * k, True)
    if v == "double":
        blade(B, t, -1, 1.25 * k, True)
    elif v == "hammer":  # a heavy hammer block both sides
        for s in (-1, 1):
            B.box("Head", "Head", (s * 0.62 * k, 0, TOP), (0.62 * k, 0.6 * k, 0.72 * k), bevel=0.07)
            B.box("Head", "Light", (s * 0.95 * k, 0, TOP), (0.06, 0.64 * k, 0.76 * k), bevel=0.02)
            B.box("Head", "Band", (s * 0.48 * k, 0, TOP), (0.08, 0.66 * k, 0.8 * k), bevel=0.02)
    else:  # pickhammer: a squared hammer on the other side
        B.box("Head", "Head", (-0.55, 0, TOP), (0.55, 0.42, 0.5), bevel=0.06)
        B.box("Head", "Light", (-0.84, 0, TOP), (0.05, 0.46, 0.54), bevel=0.015)
    # MARK on both faces of the socket, raised
    m = t["mark"]
    shapes = {"star": star_pts(), "sun": star_pts(8, 1.0, 0.6), "heart": heart_pts(), "moon": moon_pts(), "flame": star_pts(3, 1.0, 0.5)}
    if m in shapes:
        for yy in (0.26 * k, -0.26 * k):
            B.prism("Head", "Accent", shapes[m], (0, yy, TOP), 0.06, scale=0.2 * k)
    elif m in ("gem", "geode"):
        for yy in (0.25 * k, -0.25 * k):
            B.gem("Head", "Gem", (0, yy, TOP), 0.14 * k)
    elif m == "wings":
        for s in (-1, 1):  # three feather blades fanning up and out from the socket
            for i in range(3):
                a = math.radians(25 + i * 22)
                L = 0.9 - i * 0.18
                x0, z0 = s * 0.2, TOP + 0.25
                B.sweep("Head", "Light" if i else "Accent", [(x0, z0), (x0 + s * math.sin(a) * L * 0.5, z0 + math.cos(a) * L * 0.5), (x0 + s * math.sin(a) * L, z0 + math.cos(a) * L)], [(0.09, 0.04), (0.08, 0.035), (0.01, 0.01)], seg=4)
    elif m == "moss":
        for i in range(6):
            B.gem("Head", "Accent", (-0.5 + i * 0.28, 0, TOP + 0.3 + (i % 2) * 0.04), 0.09, subd=1)
    if t["glow"] == "crystal":  # crystal shards growing out of the socket top
        for i, (x, a) in enumerate(((-0.12, -0.35), (0.05, 0.1), (0.18, 0.45))):
            L = 0.45 - i * 0.08
            B.sweep("Head", "Gem", [(x, TOP + 0.3), (x + math.sin(a) * L * 0.6, TOP + 0.3 + math.cos(a) * L * 0.6), (x + math.sin(a) * L, TOP + 0.3 + math.cos(a) * L)], [(0.07, 0.07), (0.06, 0.06), (0.005, 0.005)], seg=6)
    # objects
    bpy.ops.wm.read_factory_settings(use_empty=True)
    tris = 0
    for (part, role), b in B.groups.items():
        bmesh.ops.remove_doubles(b, verts=b.verts, dist=1e-5)
        bmesh.ops.triangulate(b, faces=b.faces)
        me = bpy.data.meshes.new(f"{part}__{role}")
        b.to_mesh(me); b.free()
        for p in me.polygons: p.use_smooth = False
        tris += len(me.polygons)
        o = bpy.data.objects.new(f"{part}__{role}", me)
        bpy.context.scene.collection.objects.link(o)
    path = os.path.join(OUT, t["name"] + ".glb")
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", export_yup=True)
    return tris, path


for t in TIERS:
    if ONLY and t["name"] not in ONLY: continue
    tris, path = build(t)
    assert tris < 20000, (t["name"], tris)
    print(f"{t['name']}: {tris} triangles -> {path}")
