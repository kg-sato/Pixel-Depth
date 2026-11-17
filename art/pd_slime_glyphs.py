"""SLIME version (2026-11-16 night, the owner: the jelly text \"looks too much like a font instead of living slime\").
Reference: art/refs_slime/slime_flux_s3.png (local FLUX). Same lights, camera and materials as below, but each letter is
inflated, melted into a blob (voxel remesh + smoothing + a slow noise), has no metal rim, and some letters grow drips.
    blender -b -P art/pd_slime_glyphs.py -- <out_dir> <chars> <tone|white|pink> <size>
Original notes: Pixel Depth loading logo letters as 3D jelly glass (2026-11-12, the user: "a 3D jelly with glass and shine", reference
Instagram reel DfUpUhcuASY: puffy rounded letters, glossy pink jelly faces, a darker glass rim behind, chrome-like shine).
Each letter of PIXEL DEPTH is rendered alone on a transparent background (512 px) so the game can snap them in one by one.
    blender -b -P art/pd_logo_jelly.py -- <out_dir>
Font: Arial Rounded MT Bold (Windows). Cycles, GPU when available."""
import bpy, sys, math, os

args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
out = args[0] if args else "logo_jelly"
CHARS = args[1] if len(args) > 1 else "".join(sorted(set("PIXELDEPTH")))  # which characters to render
WHITE = len(args) > 2 and args[2] == "white"  # a pale jelly that the game tints (ImageColor3)
# a named colour: its own jelly with white highlights (a tint on the pale atlas dulls the shine into dough)
TONES = {"gold": ((1.0, 0.42, 0.02), (1.0, 0.72, 0.12), (1.0, 0.93, 0.5), (0.5, 0.2, 0.02)),
         "cyan": ((0.02, 0.4, 1.0), (0.1, 0.75, 1.0), (0.6, 0.97, 1.0), (0.03, 0.12, 0.45)),
         "violet": ((0.32, 0.1, 1.0), (0.55, 0.36, 1.0), (0.84, 0.74, 1.0), (0.12, 0.04, 0.4)),
         "mint": ((0.0, 0.6, 0.42), (0.2, 0.9, 0.62), (0.72, 1.0, 0.86), (0.02, 0.25, 0.2))}
TONE = TONES.get(args[2]) if len(args) > 2 else None
SIZE = int(args[3]) if len(args) > 3 else 512
GLOSS = len(args) > 4 and args[4] == "gloss"  # a glossier jelly: tried 2026-11-13 against reel DfUpUhcuASY, the difference was marginal, not used
os.makedirs(out, exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
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
sc.cycles.samples = 96
sc.cycles.use_denoising = True
sc.render.film_transparent = True
sc.render.resolution_x = sc.render.resolution_y = SIZE
if SIZE < 512: sc.cycles.samples = 64
sc.render.image_settings.file_format = "PNG"
sc.render.image_settings.color_mode = "RGBA"
sc.view_settings.view_transform = "Standard"

world = bpy.data.worlds.new("W")
sc.world = world
world.use_nodes = True
bg = world.node_tree.nodes["Background"]
bg.inputs[0].default_value = (0.10, 0.04, 0.16, 1)
bg.inputs[1].default_value = 0.6


def mat(name, build):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    build(m.node_tree, m.node_tree.nodes["Principled BSDF"])
    return m


def setp(b, **kw):
    for k, v in kw.items():
        key = k.replace("_", " ")
        if key in b.inputs: b.inputs[key].default_value = v


def jelly(nt, b):
    tc = nt.nodes.new("ShaderNodeTexCoord")
    sep = nt.nodes.new("ShaderNodeSeparateXYZ")
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    mp = nt.nodes.new("ShaderNodeMapRange")
    mp.inputs["From Min"].default_value, mp.inputs["From Max"].default_value = -0.4, 0.4
    ramp.color_ramp.elements[0].color = (1.0, 0.05, 0.42, 1) if not WHITE else (0.62, 0.6, 0.7, 1)  # magenta at the foot
    if TONE: ramp.color_ramp.elements[0].color = TONE[0] + (1,)
    ramp.color_ramp.elements[1].color = (0.74, 0.5, 1.0, 1) if not WHITE else (0.9, 0.9, 0.94, 1)  # lavender at the head
    mid = ramp.color_ramp.elements.new(0.5)
    mid.color = (1.0, 0.32, 0.72, 1) if not WHITE else (0.86, 0.85, 0.92, 1)
    if TONE:
        mid.color = TONE[1] + (1,)
        ramp.color_ramp.elements[2].color = TONE[2] + (1,)
    nt.links.new(tc.outputs["Object"], sep.inputs[0])
    nt.links.new(sep.outputs["Y"], mp.inputs["Value"])
    nt.links.new(mp.outputs[0], ramp.inputs[0])
    nt.links.new(ramp.outputs[0], b.inputs["Base Color"])
    setp(b, Roughness=0.04, IOR=1.4, Transmission_Weight=0.42, Subsurface_Weight=0.45, Coat_Weight=1.0, Coat_Roughness=0.01)  # slime: wetter and more see-through than the jelly
    if GLOSS: setp(b, Roughness=0.02, IOR=1.5, Transmission_Weight=0.55, Subsurface_Weight=0.55, Coat_Weight=1.0, Coat_Roughness=0.0, Specular_IOR_Level=0.9)
    if "Subsurface Radius" in b.inputs: b.inputs["Subsurface Radius"].default_value = (0.3, 0.1, 0.2)
    if "Emission Color" in b.inputs:
        nt.links.new(ramp.outputs[0], b.inputs["Emission Color"])
        b.inputs["Emission Strength"].default_value = (0.3 if TONE else 0.12) if not WHITE else 0.0  # a named colour glows from inside: radiant, not dough  # the jelly glows a little from inside


def rim(nt, b):
    b.inputs["Base Color"].default_value = (0.20, 0.05, 0.50, 1) if not WHITE else (0.16, 0.14, 0.24, 1)
    if TONE: b.inputs["Base Color"].default_value = TONE[3] + (1,)
    setp(b, Roughness=0.12, Metallic=0.75, Coat_Weight=1.0, Coat_Roughness=0.03)


def stud(nt, b):
    b.inputs["Base Color"].default_value = (1, 0.92, 1, 1)
    setp(b, Roughness=0.08, Metallic=1.0)


M_JELLY, M_RIM, M_STUD = mat("jelly", jelly), mat("rim", rim), mat("stud", stud)
FONT = bpy.data.fonts.load(r"C:\Windows\Fonts\ARLRDBD.TTF")


def light(name, loc, energy, color, size):
    d = bpy.data.lights.new(name, "AREA")
    d.energy, d.color, d.size = energy, color, size
    o = bpy.data.objects.new(name, d)
    sc.collection.objects.link(o)
    o.location = loc
    c = o.constraints.new("TRACK_TO")
    c.target = target
    c.track_axis, c.up_axis = "TRACK_NEGATIVE_Z", "UP_Y"
    return o


target = bpy.data.objects.new("Target", None)
sc.collection.objects.link(target)
light("key", (-1.6, 2.4, 4.0), 130 if not WHITE else 70, (1, 1, 1), 2.5)       # a broad white key from the upper left: the big soft shine
light("strip", (0.6, 1.2, 3.0), 60 if not GLOSS else 150, (1, 1, 1), 0.5)      # a small hard light: the sharp glint
light("rimM", (3.0, -1.0, 1.6), 220, (1, 0.1, 0.6) if not (WHITE or TONE) else (1, 1, 1), 2.0)  # magenta from the right
light("fillC", (-3.0, -2.0, 1.2), 150, (0.3, 0.9, 1) if not (WHITE or TONE) else (0.9, 0.95, 1), 2.5)  # cyan from the lower left

cam_d = bpy.data.cameras.new("Cam")
cam_d.type = "ORTHO"
cam_d.ortho_scale = 1.3
cam = bpy.data.objects.new("Cam", cam_d)
sc.collection.objects.link(cam)
cam.location = (0.05, -0.42, 5) if SIZE >= 512 else (0.0, -0.1, 5)  # the small font glyphs are seen dead on: an off-centre rim made small text look slanted
# logo letters:  # nearly straight on, a little from below: upright letters that still show their underside (the user, 2026-11-12: the first set leaned too much)
c = cam.constraints.new("TRACK_TO")
c.target = target
c.track_axis, c.up_axis = "TRACK_NEGATIVE_Z", "UP_Y"
sc.camera = cam


def text(ch, extrude, bevel, offset, z, material):
    cu = bpy.data.curves.new(ch, "FONT")
    cu.body, cu.font, cu.size = ch, FONT, 1.0
    cu.align_x, cu.align_y = "CENTER", "CENTER"
    cu.extrude, cu.bevel_depth, cu.bevel_resolution, cu.offset = extrude, bevel, 8, offset
    cu.resolution_u = 24
    o = bpy.data.objects.new(ch, cu)
    sc.collection.objects.link(o)
    o.location = (0, 0, z)
    o.data.materials.append(material)
    return o



import bmesh, random, mathutils
NAMES = {"!": "bang", "?": "ask", "+": "plus", "%": "pct", ":": "colon", "-": "dash", "/": "slash", ".": "dot", "'": "apos", ",": "comma", "(": "lpar", ")": "rpar", "&": "amp", "<": "lt", ">": "gt", "=": "eq"}
BIG = SIZE >= 512
NOISE = bpy.data.textures.new("lumps", "CLOUDS"); NOISE.noise_scale = 0.3


def slime(ch):
    """One slime letter: a fat rounded letter, a few drips under the bottoms of its strokes, all melted into one wet blob."""
    cu = bpy.data.curves.new(ch, "FONT")
    cu.body, cu.font, cu.size = ch, FONT, 1.0
    cu.align_x, cu.align_y = "CENTER", "CENTER"
    cu.extrude, cu.bevel_depth, cu.bevel_resolution = (0.1, 0.055, 6) if BIG else (0.09, 0.034, 5)
    cu.offset = 0.0  # fatter strokes, like the reference; small glyphs stay slim enough to keep A, B, R, 8 open
    cu.resolution_u = 16
    src = bpy.data.objects.new("src", cu); sc.collection.objects.link(src)
    bpy.context.view_layer.update()
    me = bpy.data.meshes.new_from_object(src.evaluated_get(bpy.context.evaluated_depsgraph_get()))
    bpy.data.objects.remove(src); bpy.data.curves.remove(cu)
    bm = bmesh.new(); bm.from_mesh(me)
    ys = [v.co.y for v in bm.verts]
    if ys:  # the letter sags: wider and a little lower toward its foot, as if it is soft and settling
        lo, hi = min(ys), max(ys)
        for v in bm.verts:
            t = (hi - v.co.y) / max(hi - lo, 1e-6)
            v.co.x *= 1 + 0.05 * t * t
    if ch.isalnum() and ys:
        rnd = random.Random(ord(ch) * 7 + 3)
        lo, hi = min(ys), max(ys)
        h = hi - lo
        bottoms = [v.co for v in bm.verts if v.co.y < lo + 0.05 * h and v.co.z > 0.02]  # the bottoms of the strokes, front half
        bins = {}
        for co in bottoms: bins.setdefault(round(co.x / 0.12), []).append(co)
        keys = sorted(bins)
        n = 0 if rnd.random() < 0.3 else (2 if rnd.random() < 0.25 and len(keys) > 2 else 1)
        for k in rnd.sample(keys, min(n, len(keys))):
            pts = bins[k]
            x = sum(p.x for p in pts) / len(pts)
            y = min(p.y for p in pts)
            L = h * rnd.uniform(0.16, 0.3)  # short: the cell has to hold them
            r = (0.07 if BIG else 0.058) * rnd.uniform(0.85, 1.15)  # a fat drop at the end, like the reference
            bmesh.ops.create_uvsphere(bm, u_segments=16, v_segments=10, radius=r, matrix=mathutils.Matrix.Translation((x, y - L, 0.04)))
            neck = bmesh.ops.create_cone(bm, cap_ends=True, segments=12, radius1=r * 0.5, radius2=r * 0.85, depth=L + r, matrix=mathutils.Matrix.Translation((x, y - L / 2 + r * 0.2, 0.04)) @ mathutils.Matrix.Rotation(math.radians(90), 4, "X"))
    bm.to_mesh(me); bm.free()
    o = bpy.data.objects.new(ch, me); sc.collection.objects.link(o)
    o.location = (0, 0, 0.06)
    o.data.materials.append(M_JELLY)
    d = o.modifiers.new("lumps", "DISPLACE"); d.texture, d.strength, d.mid_level = NOISE, 0.034 if BIG else 0.016, 0.5
    r = o.modifiers.new("melt", "REMESH"); r.mode, r.voxel_size = "VOXEL", 0.009 if BIG else 0.011
    s = o.modifiers.new("soft", "SMOOTH"); s.factor, s.iterations = 0.9, 12 if BIG else 8
    sub = o.modifiers.new("sub", "SUBSURF"); sub.levels = sub.render_levels = 1
    for p in o.data.polygons: p.use_smooth = True
    return [o]


for ch in CHARS:
    objs = slime(ch)
    bpy.context.view_layer.update()
    sc.render.filepath = os.path.join(os.path.abspath(out), NAMES.get(ch, ch) + ".png")
    bpy.ops.render.render(write_still=True)
    for o in objs:
        me = o.data
        bpy.data.objects.remove(o)
        bpy.data.meshes.remove(me)
print("done", out)
