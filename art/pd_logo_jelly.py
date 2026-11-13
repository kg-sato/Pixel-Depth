"""Pixel Depth loading logo letters as 3D jelly glass (2026-11-12, the user: "a 3D jelly with glass and shine", reference
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
    setp(b, Roughness=0.05, IOR=1.42, Transmission_Weight=0.3, Subsurface_Weight=0.35, Coat_Weight=1.0, Coat_Roughness=0.02)
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
light("strip", (0.6, 1.2, 3.0), 60, (1, 1, 1), 0.5)      # a small hard light: the sharp glint
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


NAMES = {"!": "bang", "?": "ask", "+": "plus", "%": "pct", ":": "colon", "-": "dash", "/": "slash", ".": "dot", "'": "apos", ",": "comma", "(": "lpar", ")": "rpar", "&": "amp", "<": "lt", ">": "gt", "=": "eq"}
for ch in CHARS:
    # the small font glyphs are slimmer than the logo letters: fat bevels closed the holes of A, B, R and turned S into 8
    objs = [text(ch, 0.13, 0.085, 0.0, 0.06, M_JELLY), text(ch, 0.07, 0.06, 0.085, -0.12, M_RIM)] if SIZE >= 512 else [text(ch, 0.12, 0.03, 0.0, 0.06, M_JELLY), text(ch, 0.07, 0.022, 0.036, -0.1, M_RIM)]  # slim: at 0.05 the S read as 8 in small titles
    bpy.context.view_layer.update()
    sc.render.filepath = os.path.join(os.path.abspath(out), NAMES.get(ch, ch) + ".png")
    bpy.ops.render.render(write_still=True)
    for o in objs:
        cu = o.data
        bpy.data.objects.remove(o)
        bpy.data.curves.remove(cu)
print("done", out)
