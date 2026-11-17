"""Build the voxel pets from design3d/pets/pets.json into one GLB per pet (Blender, headless).
    blender -b -P design3d/pets/build_pets.py -- <out_dir> [Name ...]
Each pet is one GLB whose objects are named "<Part>__<Role>": the Part says what moves together (Body, Head, Leg1, Tail,
WingL, Ring3, ...), the Role says the colour (the game paints it from the palette in pets.json, Shared.PetVoxels).
Only faces that touch air or another part are kept, and coplanar faces of one object are merged, so a pet stays a few
thousand triangles. Every object's origin is its part's pivot (the joint it turns about), in studs.
Axes: voxel x -> Roblox x, voxel y (up) -> Roblox y, voxel z (where the pet looks) -> Roblox -Z (a model's LookVector)."""
import bpy, bmesh, json, os, sys

here = os.path.dirname(os.path.abspath(__file__))
args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
out = args[0] if args else os.path.join(here, "out")
only = set(args[1:])
os.makedirs(out, exist_ok=True)
pets = json.load(open(os.path.join(here, "pets.json")))
FACES = [((1, 0, 0), [(1, 0, 0), (1, 1, 0), (1, 1, 1), (1, 0, 1)]), ((-1, 0, 0), [(0, 0, 0), (0, 0, 1), (0, 1, 1), (0, 1, 0)]),
         ((0, 1, 0), [(0, 1, 0), (0, 1, 1), (1, 1, 1), (1, 1, 0)]), ((0, -1, 0), [(0, 0, 0), (1, 0, 0), (1, 0, 1), (0, 0, 1)]),
         ((0, 0, 1), [(0, 0, 1), (1, 0, 1), (1, 1, 1), (0, 1, 1)]), ((0, 0, -1), [(0, 0, 0), (0, 1, 0), (1, 1, 0), (1, 0, 0)])]


def to_blender(x, y, z, s):  # voxel (x, y up, z forward) in studs -> Blender (x, y = forward, z = up); glTF export turns Blender y into -z
    return (x * s, z * s, y * s)


report = []
for pet in pets:
    if only and pet["name"] not in only: continue
    bpy.ops.wm.read_factory_settings(use_empty=True)
    s = pet["vox"]
    owner = {}
    for part, vs in pet["parts"].items():
        for x, y, z, r in vs: owner[(x, y, z)] = (part, r)
    xs = [k[0] for k in owner]; zs = [k[2] for k in owner]
    cx, cz = (min(xs) + max(xs) + 1) / 2, (min(zs) + max(zs) + 1) / 2  # centre the pet on its foot
    tris = 0
    groups = {}
    for (x, y, z), (part, role) in owner.items():
        groups.setdefault((part, role), []).append((x, y, z))
    for (part, role), cells in groups.items():
        px, py, pz = pet["pivots"].get(part, (cx - 0.5, 0, cz - 0.5))
        piv = (px + 0.5 - cx, py, pz + 0.5 - cz)  # pivots are voxel centres; move into the centred frame
        bm = bmesh.new()
        vcache = {}

        def vert(p):
            if p not in vcache:
                vcache[p] = bm.verts.new(to_blender(p[0] - cx - piv[0], p[1] - piv[1], p[2] - cz - piv[2], s))
            return vcache[p]
        for (x, y, z) in cells:
            for n, quad in FACES:
                nb = owner.get((x + n[0], y + n[1], z + n[2]))
                if nb and nb[0] == part: continue  # inside the same moving piece
                try:
                    bm.faces.new([vert((x + a, y + b, z + c)) for a, b, c in reversed(quad)])  # reversed: the (x, z, y) axis swap mirrors the winding; unreversed, Roblox culled every outer face (seen 2026-11-17)
                except ValueError:
                    pass
        bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
        bmesh.ops.dissolve_limit(bm, angle_limit=0.001, verts=bm.verts, edges=bm.edges, delimit={"NORMAL"})
        bmesh.ops.triangulate(bm, faces=bm.faces)
        me = bpy.data.meshes.new(f"{part}__{role}")
        bm.to_mesh(me); bm.free()
        tris += len(me.polygons)
        o = bpy.data.objects.new(f"{part}__{role}", me)
        o.location = to_blender(piv[0], piv[1], piv[2], s)
        bpy.context.scene.collection.objects.link(o)
    path = os.path.join(out, pet["name"].replace(" ", "") + ".glb")
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", export_apply=True, export_yup=True)
    report.append(f"{pet['name']}: {len(groups)} objects, {tris} triangles -> {path}")
    assert tris < 5000, (pet["name"], tris)

print("\n".join(report))
