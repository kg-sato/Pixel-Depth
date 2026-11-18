"""Build the voxel pets from design3d/pets/pets.json into one GLB per pet (Blender, headless).
    blender -b -P design3d/pets/build_pets.py -- <out_dir> [Name ...]
Each pet is one GLB whose objects are named "<Part>__<Role>": the Part says what moves together (Body, Head, Leg1, Tail,
WingL, Ring3, ...), the Role says the colour (the game paints it from the palette in pets.json, Shared.PetVoxels).
Only faces that touch air or another part are kept, and coplanar faces of one object are merged, so a pet stays a few
thousand triangles. Every object's origin is its part's pivot (the joint it turns about), in studs.
Axes: voxel x -> Roblox x, voxel y (up) -> Roblox y, voxel z (where the pet looks) -> Roblox -Z (a model's LookVector)."""
import bpy, bmesh, json, math, os, sys

here = os.path.dirname(os.path.abspath(__file__))
args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
out = os.path.abspath(args[0]) if args else os.path.join(here, "out")
only = set(args[1:])
os.makedirs(out, exist_ok=True)
pets = json.load(open(os.environ.get("VOXEL_JSON") or os.path.join(here, "pets.json")))  # VOXEL_JSON: another set in the same format (design3d/picks/picks.json)
FACES = [((1, 0, 0), [(1, 0, 0), (1, 1, 0), (1, 1, 1), (1, 0, 1)]), ((-1, 0, 0), [(0, 0, 0), (0, 0, 1), (0, 1, 1), (0, 1, 0)]),
         ((0, 1, 0), [(0, 1, 0), (0, 1, 1), (1, 1, 1), (1, 1, 0)]), ((0, -1, 0), [(0, 0, 0), (1, 0, 0), (1, 0, 1), (0, 0, 1)]),
         ((0, 0, 1), [(0, 0, 1), (1, 0, 1), (1, 1, 1), (0, 1, 1)]), ((0, 0, -1), [(0, 0, 0), (0, 1, 0), (1, 1, 0), (1, 0, 0)])]


def to_blender(x, y, z, s):  # voxel (x, y up, z forward) in studs -> Blender (x, y = forward, z = up); glTF export turns Blender y into -z
    return (x * s, z * s, y * s)


KEEP = {"Eye", "Shine"} | set(filter(None, os.environ.get("VOXEL_KEEP", "").split(",")))  # the eyes stay their own painted parts (they blink by resizing); VOXEL_KEEP adds roles the game tints


def hexlin(h):
    h = h.lstrip("#")
    return tuple(((int(h[i:i + 2], 16) / 255) ** 2.2) for i in (0, 2, 4)) + (1.0,)


def bake_mat(m, base, img):
    nt = m.node_tree
    for n in list(nt.nodes): nt.nodes.remove(n)
    out = nt.nodes.new("ShaderNodeOutputMaterial"); em = nt.nodes.new("ShaderNodeEmission")
    rgb = nt.nodes.new("ShaderNodeRGB"); rgb.outputs[0].default_value = base
    ao = nt.nodes.new("ShaderNodeAmbientOcclusion"); ao.inputs["Distance"].default_value = 0.3; ao.samples = 16
    bev = nt.nodes.new("ShaderNodeBevel"); bev.inputs["Radius"].default_value = 0.02; bev.samples = 8
    geo = nt.nodes.new("ShaderNodeNewGeometry")
    dot = nt.nodes.new("ShaderNodeVectorMath"); dot.operation = "DOT_PRODUCT"
    nt.links.new(bev.outputs[0], dot.inputs[0]); nt.links.new(geo.outputs["Normal"], dot.inputs[1])
    edge = nt.nodes.new("ShaderNodeMapRange"); edge.inputs["From Min"].default_value, edge.inputs["From Max"].default_value = 0.985, 0.85
    nt.links.new(dot.outputs["Value"], edge.inputs["Value"])
    sep = nt.nodes.new("ShaderNodeSeparateXYZ"); nt.links.new(geo.outputs["Normal"], sep.inputs[0])
    upl = nt.nodes.new("ShaderNodeMapRange"); upl.inputs["From Min"].default_value, upl.inputs["From Max"].default_value = -1, 1
    upl.inputs["To Min"].default_value, upl.inputs["To Max"].default_value = 0.8, 1.1
    nt.links.new(sep.outputs["Z"], upl.inputs["Value"])
    aom = nt.nodes.new("ShaderNodeMapRange"); aom.inputs["To Min"].default_value, aom.inputs["To Max"].default_value = 0.62, 1.0  # 0.5 made white coats muddy (Shinemane read beige)
    nt.links.new(ao.outputs["AO"], aom.inputs["Value"])
    m1 = nt.nodes.new("ShaderNodeMath"); m1.operation = "MULTIPLY"
    nt.links.new(aom.outputs[0], m1.inputs[0]); nt.links.new(upl.outputs[0], m1.inputs[1])
    mix = nt.nodes.new("ShaderNodeMix"); mix.data_type = "RGBA"; mix.blend_type = "MULTIPLY"; mix.inputs["Factor"].default_value = 1.0
    nt.links.new(rgb.outputs[0], mix.inputs[6]); nt.links.new(m1.outputs[0], mix.inputs[7])
    hi = nt.nodes.new("ShaderNodeMix"); hi.data_type = "RGBA"; hi.blend_type = "SCREEN"
    sc = nt.nodes.new("ShaderNodeMath"); sc.operation = "MULTIPLY"; sc.inputs[1].default_value = 0.45
    nt.links.new(edge.outputs[0], sc.inputs[0]); nt.links.new(sc.outputs[0], hi.inputs["Factor"])
    nt.links.new(mix.outputs[2], hi.inputs[6]); hi.inputs[7].default_value = (1, 1, 1, 1)
    nt.links.new(hi.outputs[2], em.inputs["Color"]); nt.links.new(em.outputs[0], out.inputs[0])
    tex = nt.nodes.new("ShaderNodeTexImage"); tex.image = img; nt.nodes.active = tex


def bake_parts(pet, stem):
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"; sc.cycles.samples = 16; sc.cycles.device = "CPU"; sc.render.bake.margin = 3
    objs = [o for o in sc.objects if o.type == "MESH"]
    for o in objs:  # the eyes sit on the face: hidden from the bake, or their occlusion stains the whole face (Shinemane's tan face, 2026-11-17)
        if o.name.split("__")[1] in ("Eye", "Shine"): o.hide_render = True
    parts = sorted({o.name.split("__")[0] for o in objs})
    for part in parts:
        group = [o for o in objs if o.name.split("__")[0] == part and o.name.split("__")[1] not in KEEP]
        if not group: continue
        size = int(os.environ.get("VOXEL_TEX", 0)) or (256 if part in ("Body", "Head") else 128)
        img = bpy.data.images.new(f"{part}_bake", size, size)
        for o in group:
            role = o.name.split("__")[1]
            m = bpy.data.materials.new(f"{part}_{role}"); m.use_nodes = True
            bake_mat(m, hexlin(pet["palette"][role]), img)
            o.data.materials.clear(); o.data.materials.append(m)
        bpy.ops.object.select_all(action="DESELECT")
        for o in group: o.select_set(True)
        bpy.context.view_layer.objects.active = group[0]
        if len(group) > 1: bpy.ops.object.join()
        body = bpy.context.view_layer.objects.active
        body.name = body.data.name = f"{part}__Tex"
        bpy.ops.object.mode_set(mode="EDIT"); bpy.ops.mesh.select_all(action="SELECT")
        bpy.ops.uv.smart_project(angle_limit=math.radians(60), island_margin=0.03)
        bpy.ops.object.mode_set(mode="OBJECT")
        bpy.ops.object.select_all(action="DESELECT"); body.select_set(True); bpy.context.view_layer.objects.active = body
        bpy.ops.object.bake(type="EMIT")
        img.filepath_raw = f"{stem}_{part}.png"; img.file_format = "PNG"; img.save()
        mat = bpy.data.materials.new(f"{part}_tex"); mat.use_nodes = True
        t2 = mat.node_tree.nodes.new("ShaderNodeTexImage"); t2.image = img
        mat.node_tree.links.new(t2.outputs["Color"], mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"])
        body.data.materials.clear(); body.data.materials.append(mat)
        objs = [o for o in sc.objects if o.type == "MESH"]
    for o in sc.objects: o.hide_render = False


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
    if os.environ.get("VOXEL_BAKE"):  # 2026-11-17 night: bake colour x occlusion + edge light per moving part (the MagicaVoxel-render look)
        bake_parts(pet, os.path.join(out, pet["name"].replace(" ", "")))
    path = os.path.join(out, pet["name"].replace(" ", "") + ".glb")
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", export_apply=True, export_yup=True)
    report.append(f"{pet['name']}: {len(groups)} objects, {tris} triangles -> {path}")
    assert tris < int(os.environ.get("VOXEL_TRI_LIMIT", 5000)), (pet["name"], tris)
    for o in bpy.context.scene.objects: o.select_set(False)

print("\n".join(report))
