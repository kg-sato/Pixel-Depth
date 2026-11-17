"""Low-poly cave props for Pixel Depth (2026-11-17 night; reference art/refs_props/props_flux_s12.png; Gemini n17_r1 asked for
faceted crystal clusters, domed low-poly mushrooms and tumbled rock piles instead of stepped blocks).
    blender -b -P design3d/cave_props.py -- <out_dir>
Writes one GLB per prop, its parts named by role so the game sets the look (Shared material by name in ServerScriptService.CaveProps):
  Crystal1..3: Shell (tinted glass), Core (neon light inside), Rock (the socket it grows from)
  Mushroom1..2: Cap, Gill (neon under the cap), Stem, Spot (neon dots)
  Rubble1..2: Rock, Gem (neon)
Sizes are in studs (1 unit = 1 stud); the model's origin is the middle of its foot."""
import bpy, bmesh, math, os, random, sys
from mathutils import Matrix, Vector

out = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else "props_out"
os.makedirs(out, exist_ok=True)


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def obj(name, bm):
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me); bm.free()
    for p in me.polygons: p.use_smooth = False  # flat facets: the low-poly look
    o = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(o)
    return o


def shard(bm, base, r, h, tilt, yaw, sides=6):
    """A crystal shard: a six-sided prism that narrows a little, with a pointed tip."""
    m = Matrix.Translation(base) @ Matrix.Rotation(yaw, 4, "Z") @ Matrix.Rotation(tilt[0], 4, "X") @ Matrix.Rotation(tilt[1], 4, "Y")
    bmesh.ops.create_cone(bm, cap_ends=True, segments=sides, radius1=r, radius2=r * 0.86, depth=h, matrix=m @ Matrix.Translation((0, 0, h / 2)))
    bmesh.ops.create_cone(bm, cap_ends=True, segments=sides, radius1=r * 0.86, radius2=0.0, depth=r * 1.6, matrix=m @ Matrix.Translation((0, 0, h + r * 0.8)))


def rocky(bm, at, s, rnd, flat=1.0):
    """A faceted rock: an icosphere, squashed, its corners pushed about."""
    res = bmesh.ops.create_icosphere(bm, subdivisions=1, radius=s, matrix=Matrix.Translation(at))
    for v in res["verts"]:
        v.co = at + (v.co - at) * Vector((rnd.uniform(0.8, 1.15), rnd.uniform(0.8, 1.15), rnd.uniform(0.55, 0.9) * flat))


def crystal(i):
    rnd = random.Random(10 + i)
    shell, core, rock = bmesh.new(), bmesh.new(), bmesh.new()
    n = rnd.randint(5, 7)
    for k in range(n):
        big = k == 0
        h = (4.6 if big else rnd.uniform(1.6, 3.6)) * rnd.uniform(0.85, 1.15)
        r = h * rnd.uniform(0.17, 0.22)
        ang = rnd.uniform(0, 2 * math.pi)
        d = 0 if big else rnd.uniform(0.6, 1.5)
        base = Vector((math.cos(ang) * d, math.sin(ang) * d, -0.2))
        tilt = (0, 0) if big else (math.cos(ang + math.pi / 2) * rnd.uniform(0.25, 0.6), math.sin(ang + math.pi / 2) * -rnd.uniform(0.25, 0.6))
        tilt = (rnd.uniform(-0.12, 0.12), rnd.uniform(-0.12, 0.12)) if big else (-math.sin(ang) * rnd.uniform(0.3, 0.65), math.cos(ang) * rnd.uniform(0.3, 0.65))
        yaw = rnd.uniform(0, math.pi)
        shard(shell, base, r, h, tilt, yaw)
        shard(core, base + Vector((0, 0, 0.15)), r * 0.5, h * 0.85, tilt, yaw)
    for k in range(4):
        ang = k * math.pi / 2 + rnd.uniform(-0.4, 0.4)
        rocky(rock, Vector((math.cos(ang) * 1.0, math.sin(ang) * 1.0, 0.05)), rnd.uniform(0.6, 0.9), rnd)
    return [obj("Shell", shell), obj("Core", core), obj("Rock", rock)]


def mushroom(i):
    rnd = random.Random(30 + i)
    cap, gill, stem, spot = bmesh.new(), bmesh.new(), bmesh.new(), bmesh.new()
    for k in range(3 if i == 1 else 4):
        s = (1.0 if k == 0 else rnd.uniform(0.45, 0.75))
        ang = rnd.uniform(0, 2 * math.pi)
        d = 0 if k == 0 else rnd.uniform(1.2, 2.0)
        at = Vector((math.cos(ang) * d, math.sin(ang) * d, 0))
        lean = Matrix.Rotation(rnd.uniform(-0.15, 0.15), 4, "X") @ Matrix.Rotation(rnd.uniform(-0.15, 0.15), 4, "Y")
        h = 2.6 * s
        m = Matrix.Translation(at) @ lean
        bmesh.ops.create_cone(stem, cap_ends=True, segments=8, radius1=0.38 * s, radius2=0.28 * s, depth=h, matrix=m @ Matrix.Translation((0, 0, h / 2)))
        # the cap: the top of a sphere, squashed into a dome, faceted
        res = bmesh.ops.create_uvsphere(cap, u_segments=10, v_segments=6, radius=1.4 * s, matrix=m @ Matrix.Translation((0, 0, h)))
        top = h
        for v in res["verts"]:
            rel = v.co - (m @ Vector((0, 0, h)))
            z = rel.z
            if z < 0: z *= 0.08  # the underside is nearly flat
            v.co = (m @ Vector((0, 0, h))) + Vector((rel.x * (1.0 if rel.z > 0 else 1.02), rel.y, z * 0.62))
        bmesh.ops.create_cone(gill, cap_ends=True, segments=10, radius1=1.25 * s, radius2=0.3 * s, depth=0.18 * s, matrix=m @ Matrix.Translation((0, 0, h - 0.12 * s)))
        for _ in range(4 if k == 0 else 2):
            a = rnd.uniform(0, 2 * math.pi)
            rr = rnd.uniform(0.4, 0.95) * 1.4 * s
            zz = math.sqrt(max(0, 1 - (rr / (1.4 * s)) ** 2)) * 1.4 * s * 0.62
            bmesh.ops.create_icosphere(spot, subdivisions=1, radius=0.17 * s, matrix=m @ Matrix.Translation((math.cos(a) * rr, math.sin(a) * rr, h + zz)))
    return [obj("Cap", cap), obj("Gill", gill), obj("Stem", stem), obj("Spot", spot)]


def rubble(i):
    rnd = random.Random(50 + i)
    rock, gem = bmesh.new(), bmesh.new()
    for k in range(rnd.randint(6, 8)):
        ang = rnd.uniform(0, 2 * math.pi)
        d = rnd.uniform(0, 1.5) if k else 0
        s = rnd.uniform(0.9, 1.3) if k == 0 else rnd.uniform(0.45, 0.85)
        rocky(rock, Vector((math.cos(ang) * d, math.sin(ang) * d, s * 0.35 + (0.5 if k in (1, 2) and d < 0.8 else 0))), s, rnd)
    for k in range(3):
        ang = rnd.uniform(0, 2 * math.pi)
        at = Vector((math.cos(ang) * rnd.uniform(0.4, 1.2), math.sin(ang) * rnd.uniform(0.4, 1.2), rnd.uniform(0.6, 1.1)))
        g = bmesh.ops.create_icosphere(gem, subdivisions=0, radius=rnd.uniform(0.22, 0.32), matrix=Matrix.Translation(at))
        for v in g["verts"]: v.co = at + (v.co - at) * Vector((0.8, 0.8, 1.5))  # a long gem crystal poking out
    return [obj("Rock", rock), obj("Gem", gem)]


def export(name, objs):
    for o in bpy.context.scene.objects: o.select_set(o in objs)
    bpy.context.view_layer.objects.active = objs[0]
    path = os.path.join(out, name + ".glb")
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", use_selection=True, export_apply=True, export_yup=True)
    tris = sum(sum(len(p.vertices) - 2 for p in o.data.polygons) for o in objs)
    print(name, tris, "tris", path)


for name, make, idx in [("Crystal1", crystal, 1), ("Crystal2", crystal, 2), ("Crystal3", crystal, 3), ("Mushroom1", mushroom, 1), ("Mushroom2", mushroom, 2), ("Rubble1", rubble, 1), ("Rubble2", rubble, 2)]:
    reset()
    export(name, make(idx))
print("done")
