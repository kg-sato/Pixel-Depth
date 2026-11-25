"""Anti-inflation pet turntable (Master Directive v16, 2026-11-24; vault Research/3D and Art/3D Model Grading.md).
Every pet alone on a neutral mid-slate stage (RGB 58, 56, 68) under one balanced 3-point studio light: no hatch rays, bloom,
particles or rarity sparkles, so the grade is the mesh, the face and the materials. One sheet per pet, six views:
front, 3/4 hero (35 deg), side (90), back (180), the 45 deg top-down town view (the pet small in frame, as the town camera
sees a crew pet) and a 160x160 solid black silhouette on #D8D6DE.
Roles are painted as the game paints them (Shared.PetVoxels): Tex keeps its baked texture, Gold is brushed metal, Gem, Iris
and Seam glow, Crystal is glass, everything else takes its palette colour.
    python spike/pet_turntable_grade.py <glb_dir> <out_dir> [Name ...] [--blind]
--blind copies the sheets to <out_dir>/blind/P01.png... in random order; the key goes to <out_dir>/blind_key.json (never
show it to the grader). The same file is the Blender script (it runs itself inside Blender for each pet)."""
import json, os, random, shutil, subprocess, sys

SLATE = (58, 56, 68)
SIL_BG = (0xD8, 0xD6, 0xDE)
BL = r"C:\Users\kgsat\Downloads\blender-5.3.0-beta+v53.32f5c9c48bca-windows.amd64-release\blender-5.3.0-beta+v53.32f5c9c48bca-windows.amd64-release\blender.exe"
HERE = os.path.dirname(os.path.abspath(__file__))
GAME = os.path.dirname(HERE)

try:
    import bpy
except ImportError:
    bpy = None


def palette_of(name):
    """the game's palette for a pet (Role -> hex) from PET_JSON (default the v5 set pets5.json), else the v4 set pets.json"""
    rp = os.path.join(GAME, "design3d/pets/rigs.json")  # the v16 plate pets (pet_plate.py)
    if os.path.exists(rp):
        for k, d in json.load(open(rp)).items():
            if k.replace(" ", "") == name.replace(" ", ""): return d["palette"]
    for f in (os.environ.get("PET_JSON", "design3d/pets/pets5.json"), "design3d/pets/pets.json"):
        p = os.path.join(GAME, f)
        if os.path.exists(p):
            for d in json.load(open(p)):
                if d["name"].replace(" ", "") == name.replace(" ", ""):
                    return d["palette"]
    return {}


# ------------------------------------------------------------------ Blender side
def blender_main():
    import math
    from mathutils import Vector
    a = sys.argv[sys.argv.index("--") + 1:]
    glb, pre, pal = a[0], a[1], json.loads(a[2])
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=glb)
    sc = bpy.context.scene
    for o in [o for o in sc.objects if o.type == "MESH" and o.name.startswith("Icosphere")]:
        bpy.data.objects.remove(o)

    def lin(h):
        h = h.lstrip("#")
        return tuple(((int(h[i:i + 2], 16) / 255) ** 2.2) for i in (0, 2, 4)) + (1.0,)

    def mat(name, col, rough=0.75, metal=0.0, emit=0.0, alpha=1.0):
        m = bpy.data.materials.new(name); m.use_nodes = True
        b = m.node_tree.nodes["Principled BSDF"]
        b.inputs["Base Color"].default_value = col; b.inputs["Roughness"].default_value = rough; b.inputs["Metallic"].default_value = metal
        if emit > 0:
            b.inputs["Emission Color"].default_value = col; b.inputs["Emission Strength"].default_value = emit
        if alpha < 1:
            b.inputs["Alpha"].default_value = alpha
        return m

    meshes = [o for o in sc.objects if o.type == "MESH"]
    tris = 0
    for o in meshes:
        tris += sum(len(p.vertices) - 2 for p in o.data.polygons)
        role = o.name.split("__")[1].split(".")[0] if "__" in o.name else "Main"
        if role[:3] == "Tex" and role[3:].isdigit(): role = "Tex"
        for _r in ("Glow", "Crystal"):
            if role.startswith(_r) and role[len(_r):].isdigit(): role = _r
        if role == "VC" or (role.startswith("Tex") and o.data.color_attributes and not any(n.type == "TEX_IMAGE" for m in o.data.materials if m and m.use_nodes for n in m.node_tree.nodes)):  # vertex colours on a matte surface (the game sets Color white; they multiply)
            m = bpy.data.materials.new("vc"); m.use_nodes = True
            vc = m.node_tree.nodes.new("ShaderNodeVertexColor")
            if o.data.color_attributes: vc.layer_name = o.data.color_attributes[0].name
            m.node_tree.links.new(vc.outputs["Color"], m.node_tree.nodes["Principled BSDF"].inputs["Base Color"])
            m.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.72
            o.data.materials.clear(); o.data.materials.append(m)
            continue
        if role == "Tex":  # baked colour on a matte surface, as SmoothPlastic with a TextureID
            for m in o.data.materials:
                if m and m.use_nodes and "Principled BSDF" in m.node_tree.nodes:
                    m.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.72
                    m.node_tree.nodes["Principled BSDF"].inputs["Metallic"].default_value = 0.0
            continue
        hexc = pal.get(role) or pal.get("Main") or "#cccccc"
        col = lin(hexc)
        if role in ("Gem", "Iris", "Seam", "Glow"):
            dim = tuple(c * 0.65 for c in col[:3]) + (1,)
            m = mat(role, dim, 0.3, 0, emit=3.0)
        elif role in ("Gold", "Metal"):
            m = mat(role, col, 0.3, 0.9)
        elif role.startswith("Crystal"):
            m = mat(role, col, 0.08, 0, emit=0.9, alpha=0.88)
        elif role in ("Eye",):
            m = mat(role, col, 0.18)
        elif role == "Shine":
            m = mat(role, col, 0.3, emit=1.5)
        else:
            m = mat(role, col, 0.75)
        o.data.materials.clear(); o.data.materials.append(m)

    pts = [o.matrix_world @ v.co for o in meshes for v in o.data.vertices]
    mn = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    mx = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    ctr, size = (mn + mx) / 2, mx - mn
    R = size.length / 2
    print("METRICS", json.dumps({"tris": tris, "meshes": len(meshes), "size": [round(v, 2) for v in size]}))
    sc.render.engine = "CYCLES"; sc.cycles.samples = 48; sc.cycles.use_denoising = True
    try:
        pr = bpy.context.preferences.addons["cycles"].preferences
        pr.compute_device_type = "OPTIX"; pr.get_devices()
        for d in pr.devices: d.use = True
        sc.cycles.device = "GPU"
    except Exception:
        sc.cycles.device = "CPU"
    sc.render.film_transparent = True
    sc.view_settings.view_transform = "Standard"
    w = bpy.data.worlds.new("w"); sc.world = w; w.use_nodes = True
    w.node_tree.nodes["Background"].inputs[0].default_value = (0.23, 0.225, 0.26, 1); w.node_tree.nodes["Background"].inputs[1].default_value = 0.55
    # balanced 3-point studio light, neutral whites (key front-left high, fill right low, rim behind)
    for loc, e, col in (((-1.0, 1.3, 1.25), 900, (1, 0.97, 0.93)), ((1.4, 0.8, 0.35), 320, (0.93, 0.95, 1)), ((0.2, -1.5, 1.1), 650, (1, 1, 1))):
        ld = bpy.data.lights.new("l", "AREA"); ld.energy, ld.size, ld.color = e * (R / 1.6) ** 2, 1.6 * R, col
        lo = bpy.data.objects.new("l", ld); lo.location = Vector(loc) * R * 2.2 + ctr; sc.collection.objects.link(lo)
        lo.rotation_euler = (ctr - lo.location).to_track_quat("-Z", "Y").to_euler()
    cam_d = bpy.data.cameras.new("c"); cam = bpy.data.objects.new("c", cam_d); sc.collection.objects.link(cam); sc.camera = cam
    cam_d.lens = 50
    D = R / math.sin(math.radians(19.5)) * 1.02  # fits the bounding sphere in a 50 mm frame
    # the pets look +Y in Blender after the glTF round trip (the game flips them to -Z)
    views = {"front": (0, 8), "three": (35, 14), "side": (90, 8), "back": (180, 10), "town": (155, 45)}
    for name, (az, el) in views.items():
        d = D * (1.9 if name == "town" else 1.0)
        a, e = math.radians(az), math.radians(el)
        off = Vector((math.sin(a) * math.cos(e), math.cos(a) * math.cos(e), math.sin(e))) * d
        sc.render.resolution_x = sc.render.resolution_y = 480
        cam.location = ctr + off
        cam.rotation_euler = (ctr - cam.location).to_track_quat("-Z", "Y").to_euler()
        sc.render.filepath = "%s_%s.png" % (pre, name)
        bpy.ops.render.render(write_still=True)
    if os.environ.get("PET_HERO"):  # a big 3/4 hero still for the owner (PET_HERO=1), with a size reference
        # a grey block avatar at the game's town scale (a 5.2-stud R15 avatar / Config.PET_SCALE 1.5) standing beside the pet,
        # and a ground disc: without them every pet fills the frame the same and reads as a toy
        k = 1 / 1.5
        gm = mat("ref", (0.32, 0.32, 0.36, 1), 0.8)
        ax = mx.x + 1.1 * k + 0.5  # on the camera side, level with the hind legs
        for (cx, cy, cz), (sx, sy, sz) in (((ax - 0.5 * k, mn.y + 1.0, 1.0 * k), (0.9, 0.9, 2.0)), ((ax + 0.5 * k, mn.y + 1.0, 1.0 * k), (0.9, 0.9, 2.0)),
                                            ((ax, mn.y + 1.0, 3.0 * k), (2.0, 1.0, 2.0)), ((ax - 1.5 * k, mn.y + 1.0, 3.0 * k), (0.9, 0.9, 2.0)),
                                            ((ax + 1.5 * k, mn.y + 1.0, 3.0 * k), (0.9, 0.9, 2.0)), ((ax, mn.y + 1.0, 4.6 * k), (1.15, 1.15, 1.2))):
            bpy.ops.mesh.primitive_cube_add(size=1, location=(cx, cy, cz)); ob = bpy.context.active_object
            ob.scale = (sx * k, sy * k, sz * k); ob.data.materials.append(gm)
        bpy.ops.mesh.primitive_cylinder_add(vertices=64, radius=max(size.x, size.y) * 0.9 + 2, depth=0.02, location=(ctr.x - 1, ctr.y, -0.011))
        bpy.context.active_object.data.materials.append(mat("ground", (0.06, 0.055, 0.07, 1), 0.9))
        a, e = math.radians(35), math.radians(12)
        cam.location = ctr + Vector((math.sin(a) * math.cos(e), math.cos(a) * math.cos(e), math.sin(e))) * D * 1.3 + Vector((0.6, 0, 0))
        cam.rotation_euler = (ctr - cam.location).to_track_quat("-Z", "Y").to_euler()
        sc.render.resolution_x, sc.render.resolution_y = 1280, 1024
        sc.render.filepath = "%s_hero.png" % pre
        bpy.ops.render.render(write_still=True)
    # the silhouette: 3/4 view, 160 px, alpha only
    a, e = math.radians(35), math.radians(14)
    cam.location = ctr + Vector((math.sin(a) * math.cos(e), math.cos(a) * math.cos(e), math.sin(e))) * D * 0.8
    cam.rotation_euler = (ctr - cam.location).to_track_quat("-Z", "Y").to_euler()
    sc.render.resolution_x = sc.render.resolution_y = 160
    sc.cycles.samples = 8
    sc.render.filepath = "%s_sil.png" % pre
    bpy.ops.render.render(write_still=True)
    print("DONE", pre)


# ------------------------------------------------------------------ driver side
def sheet(pre, name, metrics):
    from PIL import Image, ImageDraw, ImageFont
    W = 480
    out = Image.new("RGB", (W * 3, W * 2 + 34), (30, 28, 36))
    dr = ImageDraw.Draw(out)
    try:
        f = ImageFont.truetype("arialbd.ttf", 18)
    except OSError:
        f = ImageFont.load_default()
    labels = {"front": "FRONT", "three": "3/4 HERO", "side": "SIDE", "back": "BACK", "town": "45 TOP-DOWN TOWN"}
    for i, v in enumerate(("front", "three", "side", "back", "town")):
        im = Image.open("%s_%s.png" % (pre, v)).convert("RGBA")
        bg = Image.new("RGBA", im.size, SLATE + (255,)); bg.alpha_composite(im)
        x, y = (i % 3) * W, (i // 3) * W + 34
        out.paste(bg.convert("RGB"), (x, y))
        dr.text((x + 10, y + 8), labels[v], fill=(205, 200, 215), font=f)
    sil = Image.open("%s_sil.png" % pre).convert("RGBA")
    blk = Image.new("RGB", (160, 160), SIL_BG)
    blk.paste((0, 0, 0), (0, 0), sil.split()[3].point(lambda a: 255 if a > 100 else 0))
    cell = Image.new("RGB", (W, W), SIL_BG)
    cell.paste(blk, (160, 160))
    out.paste(cell, (2 * W, W + 34))
    dr.text((2 * W + 10, W + 42), "160x160 BLACKOUT", fill=(40, 40, 50), font=f)
    dr.text((10, 8), "%s   tris %s" % (name, metrics.get("tris", "?")), fill=(235, 230, 240), font=f)
    out.save(pre + "_sheet.png")
    for v in ("front", "three", "side", "back", "town", "sil"):
        os.remove("%s_%s.png" % (pre, v))


def main():
    import re
    a = [x for x in sys.argv[1:] if not x.startswith("--")]
    src, out = os.path.abspath(a[0]), os.path.abspath(a[1])
    only = set(a[2:])
    os.makedirs(out, exist_ok=True)
    names = sorted(f[:-4] for f in os.listdir(src) if f.endswith(".glb") and (not only or f[:-4] in only))
    packet = {}
    for n in names:
        pre = os.path.join(out, n)
        r = subprocess.run([BL, "-b", "--factory-startup", "-P", os.path.abspath(__file__), "--", os.path.join(src, n + ".glb"), pre, json.dumps(palette_of(n))], capture_output=True, text=True)
        m = re.search(r"METRICS (\{.*\})", r.stdout)
        packet[n] = json.loads(m.group(1)) if m else {"error": (r.stderr or r.stdout)[-400:]}
        if not m or "DONE" not in r.stdout:
            print(n, "FAILED", (r.stderr or r.stdout)[-600:]); continue
        sheet(pre, n, packet[n])
        print(n, packet[n], flush=True)
    old = os.path.join(out, "packet.json")
    allp = json.load(open(old)) if os.path.exists(old) else {}
    allp.update(packet)
    json.dump(allp, open(old, "w"), indent=1)
    if "--blind" in sys.argv:
        bd = os.path.join(out, "blind"); shutil.rmtree(bd, ignore_errors=True); os.makedirs(bd)
        ks = [n for n in allp if "error" not in allp[n] and os.path.exists(os.path.join(out, n + "_sheet.png"))]; random.shuffle(ks)
        key = {}
        for i, n in enumerate(ks, 1):
            shutil.copy(os.path.join(out, n + "_sheet.png"), os.path.join(bd, "P%02d.png" % i)); key["P%02d" % i] = n
        json.dump(key, open(os.path.join(out, "blind_key.json"), "w"), indent=1)


if __name__ == "__main__":
    if bpy is not None:
        blender_main()
    else:
        main()
