"""The v16 pets in the owner's reference style (Overnight/refs/pets_v16: the Lure a Pet Showcase video; concepts by Gemini in
concepts.json, FLUX concept renders in concepts/). Built with plate_kit.py.
    blender -b -P design3d/pets/pet_plate.py -- <out_dir> [Name ...]
Writes <Name>.glb + <Name>_atlas.png and merges the rig data (parents, joint pivots, groups, anchors) into design3d/pets/rigs.json."""
import json, math, os, sys
import bmesh
here = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, here)
import plate_kit as K
from plate_kit import V, look
from mathutils import Euler

args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = os.path.abspath(args[0] if args else os.path.join(here, "out_plate"))
ONLY = set(a for a in args[1:] if not a.startswith("-"))
os.makedirs(OUT, exist_ok=True)
D = {}


def pet(name, pal):
    def deco(fn): D[name] = (pal, fn); return fn
    return deco


def E(rx=0, ry=0, rz=0):
    return Euler((math.radians(rx), math.radians(ry), math.radians(rz))).to_matrix()


def leg4(c, limb, hip, knee, ankle, foot, widths, claws=3, claw_len=0.55, parent="Body", colour="Main", spikes=0):
    """a 3-segment armoured leg (limb1 thigh, limb2 shin, limb3 foot) with a broad clawed foot"""
    names = c.chain(limb, [hip, knee, ankle], widths[:3], colour=colour, parent=parent, group="leg", spikes=spikes)
    nm = f"{limb}{len(names) + 1}"
    c.joint(nm, ankle, names[-1], "leg")
    c.segment(nm, ankle, foot, widths[2], widths[2] * 0.95, colour=colour)
    c.foot(nm, V(foot) + V(0, 0.1, 0), widths[2] * 1.05, claws=claws, L=claw_len)
    return names + [nm]


# ---------------------------------------------------------------- TOSK: Trench-Ram Bulldozer (Common hauler)
@pet("Tosk", {"Main": "#1c1f23", "MainTop": "#2e333c", "Dark": "#0e1013", "Bone": "#ece6d0", "BoneTop": "#fffaf0", "Plate": "#23272e",
              "PlateTop": "#3a404b", "Stud": "#c2b088", "StudTop": "#efe0b0", "Glow": "#ffa500", "Edge": "#8a92a8", "Iron": "#3a3e46", "IronTop": "#545a66"})
def tosk(c):
    c.joint("Body", (0, 0, 2.6))
    # a front-heavy knuckle-walking titan (concepts/Tosk_s12, Gemini critique round 1): huge high shoulders, the back sloping
    # down to a small rump, the wedge head low between pillar forelegs; brass rivets along the plate seams; recessed windows
    c.armor("Body", (0, 0.45, 3.0), (2.15, 1.65, 1.6), seg=10, rings=8, colour="Main", rivets="Stud")
    c.armor("Body", (0, 0.55, 3.75), (1.75, 1.35, 0.85), seg=10, rings=6, colour="Plate", zmin=-0.1, rivets="Stud")
    c.armor("Body", (0, -1.35, 2.35), (1.45, 1.3, 1.05), seg=10, rings=7, colour="Main", rivets="Stud")
    c.armor("Body", (0, -1.4, 2.95), (1.2, 1.05, 0.55), seg=8, rings=5, colour="Plate", zmin=-0.1)
    c.armor("Body", (0, -0.3, 1.85), (1.45, 2.0, 0.6), seg=8, rings=5, colour="Dark", inset=0.03)
    for s in (-1, 1):
        c.armor("Body", (s * 2.0, 0.6, 3.55), (1.15, 1.35, 0.9), seg=8, rings=6, colour="Plate", zmin=-0.25, rot=(0, s * 0.42, 0), rivets="Stud")
        c.armor("Body", (s * 2.15, 0.6, 3.85), (0.8, 1.0, 0.6), seg=8, rings=5, colour="Iron", zmin=0.0, rot=(0, s * 0.5, 0))
        for wy in (-0.2, -0.75):
            c.window("Body", (s * 1.85, wy, 2.75), 0.3, 0.3, (s, 0, 0), depth=0.2)
        c.window("Body", (s * 1.4, -1.5, 2.35), 0.28, 0.28, (s, 0, 0), depth=0.2)
    c.block("Body", (0, 2.0, 2.65), (1.6, 0.34, 1.0), bevel=0.1, colour="Iron", panel=0.05)  # the chest furnace
    for x in (-0.48, -0.16, 0.16, 0.48): c.block("Body", (x, 2.12, 2.65), (0.18, 0.14, 0.72), bevel=0.0, colour="Glow", role="Glow")
    for x in (-0.32, 0.0, 0.32): c.block("Body", (x, 2.18, 2.65), (0.1, 0.15, 0.85), bevel=0.1, colour="Dark")
    for k in range(6):  # a stepped dorsal keel: plates rising to the shoulders
        y = 1.0 - k * 0.55
        c.block("Body", (0, y, 4.45 - 0.22 * k), (0.42, 0.5, 0.36), rot=E(-12, 0, 0), bevel=0.18, colour="Iron", taper=0.6)
    c.anchors["back"] = ("Body", V(0, -0.6, 4.3)); c.anchors["furnace"] = ("Body", V(0, 2.3, 2.65))
    # the head: a stepped wedge ram helm low between the forelegs, a heavy jaw, curved tusks, amber slits under an angry brow
    c.joint("Head", (0, 1.7, 2.6), "Body", "head")
    c.armor("Head", (0, 2.5, 2.35), (1.1, 1.05, 0.9), seg=8, rings=6, colour="Main")
    c.block("Head", (0, 2.75, 2.75), (2.0, 1.9, 1.05), rot=E(-20, 0, 0), bevel=0.12, colour="Plate", taper=0.6, panel=0.06)
    c.block("Head", (0, 2.55, 3.2), (1.5, 1.4, 0.45), rot=E(-14, 0, 0), bevel=0.15, colour="Iron", taper=0.66, panel=0.05)
    c.block("Head", (0, 3.15, 1.75), (1.3, 1.1, 0.42), bevel=0.15, colour="Dark", taper=0.8)
    c.studs("Head", [(x, 2.0 + 0.38 * k, 3.35 - 0.1 * k) for x in (-0.85, 0.85) for k in range(3)], r=0.13, colour="Stud")
    for s in (-1, 1):
        c.window("Head", (s * 0.45, 3.55, 2.62), 0.36, 0.12, (s * 0.2, 1, 0.15), depth=0.18)
        c.block("Head", (s * 0.45, 3.5, 2.8), (0.62, 0.34, 0.16), rot=E(0, 0, s * 12), bevel=0.15, colour="Dark")
        c.claw("Head", (s * 0.62, 3.4, 1.9), (s * 1.2, 4.45, 2.45), 0.36, curl=V(s * 0.25, 0, 0.6))
        c.segment("Head", (s * 0.68, 3.55, 1.98), (s * 0.78, 3.75, 2.05), 0.44, 0.44, colour="Iron")
        for k in range(3): c.claw("Head", (s * (0.18 + 0.2 * k), 3.65, 1.85), (s * (0.18 + 0.2 * k), 3.72, 2.15), 0.08)
    c.anchors["eyes"] = ("Head", V(0, 3.7, 2.62))
    # pillar forelegs (thicker than the head is wide) and smaller hind legs; broad feet with four ivory claws
    for limb, x, y, big in (("LegFL", -1.7, 1.05, 1), ("LegFR", 1.7, 1.05, 1), ("LegBL", -1.25, -1.55, 0), ("LegBR", 1.25, -1.55, 0)):
        s = 1 if x > 0 else -1
        r = 1.0 if big else 0.7
        hip, knee, ank = V(x, y, 2.7 if big else 2.1), V(x + s * 0.15, y + 0.2, 1.35 if big else 1.0), V(x + s * 0.15, y + 0.1, 0.5)
        c.joint(f"{limb}1", hip, "Body", "leg")
        c.armor(f"{limb}1", tuple((hip + knee) / 2), (r, r * 1.05, (hip - knee).length * 0.6), seg=8, rings=6, colour="Main", rivets="Stud")
        c.armor(f"{limb}1", tuple(knee + V(s * 0.1, 0.3, 0.2)), (r * 0.85, r * 0.75, 0.5), seg=8, rings=5, colour="Plate", zmin=-0.2, rivets="Stud")
        c.claw(f"{limb}1", knee + V(s * r * 0.8, 0.3, 0.35), knee + V(s * (r * 0.8 + 0.45), 0.25, 0.8), 0.17)
        c.joint(f"{limb}2", knee, f"{limb}1", "leg")
        c.limb(f"{limb}2", knee, ank, r * 0.8, r * 0.75, seg=8, colour="Plate", bands=2, band_colour="Iron")
        c.window(f"{limb}2", (x + s * r * 0.78, y + 0.15, 0.95), 0.2, 0.2, (s, 0, 0), depth=0.16)
        c.joint(f"{limb}3", ank, f"{limb}2", "leg")
        c.foot(f"{limb}3", ank + V(0, 0.3, -0.25), r * 0.95, claws=4, L=0.85 * r + 0.2, colour="Plate")
    for i, (a, b2, r0, r1) in enumerate((((0, -2.5, 2.6), (0, -2.95, 2.45), 0.5, 0.42), ((0, -2.95, 2.45), (0, -3.3, 2.2), 0.42, 0.34), ((0, -3.3, 2.2), (0, -3.5, 1.9), 0.34, 0.26))):
        nm = f"Tail{i + 1}"
        c.joint(nm, a, "Body" if i == 0 else f"Tail{i}", "tail")
        c.limb(nm, a, b2, r0, r1, seg=6, colour="Main", bands=1)
    c.claw("Tail3", (0, -3.5, 1.9), (0, -3.85, 1.7), 0.2)


# ---------------------------------------------------------------- NINERING: Chrono-Fractal Engine Relic (Secret ore copier)
@pet("Ninering", {"Main": "#16151c", "MainTop": "#27252f", "Plate": "#1d1b24", "PlateTop": "#2e2b38", "Brass": "#8a6a2e", "BrassTop": "#c8a050",
                  "Dark": "#0c0b10", "Bone": "#e6e2ea", "BoneTop": "#ffffff", "Stud": "#b8963f", "StudTop": "#e0c070", "Glow": "#c040ff", "Edge": "#7a6a90"})
def ninering(c):
    cz = 3.3
    C = V(0, 0, cz)
    c.joint("Body", tuple(C))
    # the core: a violet singularity crystal held in a brass cage of four claws, a dark socket behind it
    c.armor("Body", tuple(C - V(0, 0.2, 0)), (0.72, 0.5, 0.72), seg=8, rings=6, colour="Dark", inset=0.03)
    c.gem("Body", tuple(C + V(0, 0.55, 0)), 0.55, stretch=(1, 0.7, 1), rot=(math.pi / 2, 0, 0))
    for k in range(4):
        a = k * math.pi / 2 + math.pi / 4
        d = V(math.cos(a), 0, math.sin(a))
        c.claw("Body", C + d * 0.45 + V(0, 0.3, 0), C + d * 0.75 + V(0, 1.05, 0), 0.13, colour="Brass")
    # nine rings: brass inner rings, dark obsidian outer rings, stepped plates, studs, ivory teeth and glowing slots on the outer three
    # nine rings stacked into a stepped disc facing forward (concepts/Ninering_s13): brass inner rings, obsidian outer rings,
    # the inner rings stand proud of the outer ones; each ring leans a little off the disc so they precess when they spin
    specs = [(0.95, 0.24, 0.62, 14, "Brass"), (1.22, 0.26, 0.56, 16, "Plate"), (1.5, 0.26, 0.5, 18, "Brass"), (1.78, 0.28, 0.46, 20, "Plate"),
             (2.06, 0.28, 0.42, 22, "Brass"), (2.34, 0.3, 0.4, 24, "Plate"), (2.64, 0.32, 0.38, 26, "Plate"), (2.95, 0.34, 0.36, 28, "Main"), (3.28, 0.36, 0.34, 30, "Main")]
    for i, (R, w, h, n, col) in enumerate(specs):
        tilt = math.radians(4 + 2.5 * i)
        az = i * 2.35
        nrm = (math.sin(tilt) * math.cos(az), math.cos(tilt), math.sin(tilt) * math.sin(az))
        part = f"Ring{i + 1}"
        c.joint(part, tuple(C), "Body", "ring")
        c.axes[part] = nrm
        ring_plates(c, part, C + V(0, 0.08 * (8 - i), 0), R, w, h, n, nrm, colour=col, teeth=(3 if i >= 7 else 0), studs=(i % 2 == 0), tooth_len=0.45 + 0.08 * (i - 6), glow_every=(4 if i in (3, 5, 7) else 0))
    # four stabiliser pikes below and a crown of horns above (the relic's silhouette)
    for k in range(4):
        a = k * math.pi / 2
        c.claw("Body", C + V(math.cos(a) * 0.4, math.sin(a) * 0.4, -0.5), C + V(math.cos(a) * 0.9, math.sin(a) * 0.9, -2.2), 0.2)
    c.anchors["core"] = ("Body", C + V(0, 0.4, 0))


def tendril(c, prefix, pts, r0, r1, parent, colour="Tendril", band="Plate", tip=0.35, group="tentacle"):
    """a hanging segmented tendril / tentacle: one Part per segment, banded prisms, an ivory claw at the tip"""
    n = len(pts) - 1
    for i in range(n):
        nm = f"{prefix}{i + 1}"
        c.joint(nm, pts[i], parent if i == 0 else f"{prefix}{i}", group)
        ra, rb = r0 + (r1 - r0) * i / n, r0 + (r1 - r0) * (i + 1) / n
        c.limb(nm, pts[i], pts[i + 1], ra, rb, seg=6, colour=colour, bands=1, band_colour=band)
    a, b = V(pts[-2]), V(pts[-1])
    d = (b - a).normalized()
    c.claw(f"{prefix}{n}", b - d * 0.05, b + d * tip, r1 * 1.1, curl=V(0, 0.15, 0))


# ---------------------------------------------------------------- GLIMWISP: Hollow Bell-Wraith (Rare light spirit)
@pet("Glimwisp", {"Main": "#171b22", "MainTop": "#2a313c", "Plate": "#1f242d", "PlateTop": "#34404e", "Dark": "#0b0d11", "Bone": "#e4eaee",
                  "BoneTop": "#ffffff", "Stud": "#7f8ea0", "StudTop": "#aebccc", "Tendril": "#3a4a52", "TendrilTop": "#55707a", "Glow": "#16e8ff", "Edge": "#7a8aa0"})
def glimwisp(c):
    cz = 3.0
    c.joint("Body", (0, 0, cz))
    # the bell: a dark inner dome under five stepped tiers of radial plates, a crown spike, ivory claws round the rim
    c.armor("Body", (0, 0, cz + 0.15), (1.55, 1.55, 1.0), seg=12, rings=8, colour="Dark", zmin=-0.25, inset=0.03)
    for k, (z, R, w, h, n) in enumerate(((cz - 0.15, 1.62, 0.3, 0.42, 22), (cz + 0.25, 1.5, 0.32, 0.4, 20), (cz + 0.62, 1.25, 0.32, 0.38, 18), (cz + 0.95, 0.95, 0.3, 0.34, 14), (cz + 1.2, 0.58, 0.28, 0.3, 10))):
        ring_plates(c, "Body", (0, 0, z), R, w, h, n, (0, 0, 1), colour="Plate" if k % 2 == 0 else "Main", studs=(k % 2 == 1), glow_every=(5 if k == 1 else 0))
    c.claw("Body", (0, 0, cz + 1.35), (0, -0.1, cz + 2.1), 0.22)
    for k in range(6):
        a = k / 6 * math.tau + 0.4
        c.claw("Body", (math.cos(a) * 0.5, math.sin(a) * 0.5, cz + 1.3), (math.cos(a) * 0.7, math.sin(a) * 0.7, cz + 1.7), 0.1)
    for k in range(12):
        a = k / 12 * math.tau
        d = V(math.cos(a), math.sin(a), 0)
        c.claw("Body", d * 1.6 + V(0, 0, cz - 0.3), d * 2.05 + V(0, 0, cz - 0.85), 0.13)
    # the face: a glowing visor of three windows on the front of the bell, the spirit core hanging inside
    c.window("Body", (0, 1.58, cz + 0.35), 0.7, 0.22, (0, 1, 0.15))
    for s in (-1, 1): c.window("Body", (s * 0.62, 1.45, cz + 0.12), 0.26, 0.18, (s * 0.35, 1, 0.1))
    c.gem("Body", (0, 0, cz - 0.55), 0.5, stretch=(1, 1, 1.3))
    c.anchors["core"] = ("Body", V(0, 0, cz - 0.55)); c.anchors["visor"] = ("Body", V(0, 1.7, cz + 0.35))
    # six hanging tendrils, four segments each, drifting back, ivory claw tips
    for k in range(6):
        a = k / 6 * math.tau + math.pi / 6
        d = V(math.cos(a), math.sin(a), 0)
        p0 = d * 1.0 + V(0, 0, cz - 0.45)
        pts = [p0 + d * 0.15 * i + V(0, -0.18 * i * i, -0.62 * i) for i in range(5)]
        tendril(c, f"Tent{k + 1}_", pts, 0.2, 0.11, "Body")


# ---------------------------------------------------------------- KOBOLD: Trench-Gouger (Common digger)
@pet("Kobold", {"Main": "#22262c", "MainTop": "#343a44", "Plate": "#2a2f37", "PlateTop": "#3f4652", "Dark": "#111317", "Bone": "#e6dfcc",
                "BoneTop": "#fbf6ea", "Stud": "#8f949f", "StudTop": "#c0c4ce", "Iron": "#3a3530", "IronTop": "#54493e", "Glow": "#1cff9a", "Edge": "#86909e"})
def kobold(c):
    c.joint("Body", (0, 0, 2.0))
    # a hunched armoured brute (concepts/Kobold_s12): a barrel chest, a riveted belly plate, a hooded head with a glowing visor
    c.armor("Body", (0, 0.1, 2.5), (1.3, 1.0, 1.15), seg=10, rings=8, colour="Main", rivets="Stud")
    c.armor("Body", (0, 0.25, 1.65), (1.05, 0.85, 0.75), seg=10, rings=6, colour="Plate", rivets="Stud")
    c.armor("Body", (0, -0.45, 2.7), (1.1, 0.7, 0.9), seg=8, rings=6, colour="Plate", zmin=-0.3)  # the back plate
    c.block("Body", (0, 0.95, 2.2), (1.0, 0.25, 1.1), bevel=0.12, colour="Iron", panel=0.05)
    for z in (1.85, 2.2, 2.55): c.window("Body", (0, 1.1, z), 0.28, 0.12, (0, 1, 0))
    c.armor("Body", (0, -0.7, 2.2), (0.75, 0.45, 0.65), seg=8, rings=6, colour="Iron")  # a pack of ore canisters
    for x in (-0.35, 0.35): c.limb("Body", (x, -1.05, 1.8), (x, -1.05, 2.75), 0.18, 0.18, seg=8, colour="Plate", bands=2)
    for k in range(5): c.claw("Body", (0, 0.3 - k * 0.25, 3.55 - 0.08 * k), (0, 0.15 - k * 0.25, 3.95 - 0.1 * k), 0.13)
    c.anchors["back"] = ("Body", V(0, -1.05, 2.9))
    c.joint("Head", (0, 0.5, 3.2), "Body", "head")
    c.armor("Head", (0, 0.75, 3.35), (0.75, 0.7, 0.62), seg=8, rings=6, colour="Main")
    c.armor("Head", (0, 0.65, 3.6), (0.9, 0.85, 0.55), seg=8, rings=6, colour="Plate", zmin=-0.2, rivets="Stud")  # the hood
    c.block("Head", (0, 1.32, 3.35), (0.8, 0.22, 0.5), bevel=0.15, colour="Dark", panel=0.03)
    c.block("Head", (0, 1.42, 3.4), (0.48, 0.1, 0.2), bevel=0.0, colour="Glow", role="Glow")  # the visor slit
    c.block("Head", (0, 1.45, 3.12), (0.16, 0.12, 0.16), bevel=0.0, colour="Glow", role="Glow")
    for s in (-1, 1): c.claw("Head", (s * 0.6, 0.6, 3.85), (s * 0.85, 0.2, 4.25), 0.12)
    c.anchors["visor"] = ("Head", V(0, 1.5, 3.4))
    # two huge pick-arms: pauldron, upper arm, a forearm ending in a fused ivory pick blade
    for s, arm in ((-1, "ArmL"), (1, "ArmR")):
        sh = V(s * 1.25, 0.25, 2.95)
        el = V(s * 1.75, 0.6, 2.0)
        wr = V(s * 1.6, 1.35, 1.35)
        c.armor("Body", tuple(sh + V(s * 0.1, 0, 0.25)), (0.75, 0.8, 0.55), seg=8, rings=6, colour="Plate", zmin=-0.2, rivets="Stud")
        c.joint(f"{arm}1", tuple(sh), "Body", "arm")
        c.limb(f"{arm}1", sh, el, 0.42, 0.36, seg=8, colour="Main", bands=2, band_colour="Iron")
        c.joint(f"{arm}2", tuple(el), f"{arm}1", "arm")
        c.limb(f"{arm}2", el, wr, 0.4, 0.46, seg=8, colour="Plate", bands=2, band_colour="Iron")
        c.armor(f"{arm}2", tuple(wr), (0.42, 0.42, 0.42), seg=8, rings=6, colour="Iron")
        c.claw(f"{arm}2", wr + V(0, 0.15, 0.1), wr + V(s * 0.25, 1.35, 1.0), 0.32, curl=V(0, 0.3, -0.9))  # the pick blade
        c.claw(f"{arm}2", wr + V(s * 0.1, 0.25, -0.15), wr + V(s * 0.35, 0.8, -0.65), 0.15)
        c.window(f"{arm}2", tuple((el + wr) / 2 + V(s * 0.42, 0, 0)), 0.16, 0.16, (s, 0, 0))
    # short digger legs, three-toed ivory feet
    for s, leg in ((-1, "LegL"), (1, "LegR")):
        hip = V(s * 0.6, 0.0, 1.3); kn = V(s * 0.72, 0.25, 0.75); an = V(s * 0.72, 0.05, 0.3)
        c.joint(f"{leg}1", tuple(hip), "Body", "leg")
        c.limb(f"{leg}1", hip, kn, 0.42, 0.36, seg=8, colour="Main", bands=1, band_colour="Iron")
        c.joint(f"{leg}2", tuple(kn), f"{leg}1", "leg")
        c.limb(f"{leg}2", kn, an, 0.36, 0.32, seg=8, colour="Plate", bands=1, band_colour="Iron")
        c.foot(f"{leg}2", an + V(0, 0.2, -0.1), 0.5, claws=3, L=0.4, colour="Iron")


# ---------------------------------------------------------------- FAFNIR: Hoard-Bastion Drake (Legendary)
@pet("Fafnir", {"Main": "#1b1d22", "MainTop": "#2c3038", "Plate": "#23262d", "PlateTop": "#383d48", "Dark": "#0d0e11", "Bone": "#ece4d0",
                "BoneTop": "#fffaf0", "Stud": "#8c919c", "StudTop": "#c2c6d0", "Wing": "#191b21", "WingTop": "#2a2e38", "Iron": "#2e3036", "IronTop": "#454852",
                "Glow": "#ff2440", "Edge": "#8a90a0"})
def fafnir(c):
    c.joint("Body", (0, 0, 2.8))
    # a massive armoured drake (concepts/Fafnir_s13): a deep chest, spined back, a horned head on a thick neck, bat wings,
    # pillar legs with ivory claws, a spiked tail, a red hoard core glowing in the chest
    c.armor("Body", (0, 0.6, 2.8), (1.9, 1.7, 1.55), seg=12, rings=8, colour="Main", rivets="Stud")
    c.armor("Body", (0, -1.1, 2.6), (1.6, 1.6, 1.3), seg=10, rings=8, colour="Main", rivets="Stud")
    c.armor("Body", (0, 0.1, 3.45), (1.6, 2.4, 0.9), seg=10, rings=6, colour="Plate", zmin=0.0, rivets="Stud")
    c.armor("Body", (0, 0.4, 1.65), (1.3, 2.3, 0.55), seg=10, rings=5, colour="Dark", inset=0.03)
    for k in range(6):  # stepped belly scutes
        c.block("Body", (0, 1.7 - k * 0.55, 1.55 + 0.06 * k), (1.5 - 0.06 * k, 0.48, 0.28), rot=E(-15, 0, 0), bevel=0.15, colour="Plate", panel=0.04)
    c.block("Body", (0, 2.32, 2.6), (1.2, 0.3, 1.1), bevel=0.12, colour="Iron", panel=0.05)
    c.gem("Body", (0, 2.5, 2.6), 0.36, stretch=(1, 0.6, 1.3))
    c.anchors["chest"] = ("Body", V(0, 2.6, 2.6))
    for k in range(9):  # a crest of big ivory dorsal spines
        y = 1.6 - k * 0.55
        h = 0.9 - 0.08 * abs(k - 3)
        c.claw("Body", (0, y, 4.15 - 0.12 * k), (0, y - 0.35, 4.15 - 0.12 * k + h), 0.24)
        for s in (-1, 1): c.claw("Body", (s * 0.8, y, 3.85 - 0.12 * k), (s * 1.0, y - 0.2, 4.15 - 0.12 * k), 0.11)
    # neck and head
    c.joint("Neck", (0, 1.9, 3.3), "Body", "neck")
    c.limb("Neck", (0, 1.8, 3.2), (0, 2.6, 4.1), 0.78, 0.62, seg=8, colour="Main", bands=3, band_colour="Plate")
    c.joint("Head", (0, 2.6, 4.1), "Neck", "head")
    c.armor("Head", (0, 3.0, 4.25), (0.85, 0.9, 0.7), seg=8, rings=6, colour="Main", rivets="Stud")
    c.block("Head", (0, 3.7, 4.05), (1.0, 1.2, 0.62), rot=E(-8, 0, 0), bevel=0.12, colour="Plate", taper=0.7, panel=0.05)
    c.block("Head", (0, 3.6, 3.72), (0.85, 1.0, 0.32), bevel=0.12, colour="Dark", taper=0.75)  # the jaw
    for s in (-1, 1):
        c.window("Head", (s * 0.4, 3.45, 4.45), 0.3, 0.11, (s * 0.4, 1, 0.3))
        c.block("Head", (s * 0.42, 3.4, 4.6), (0.5, 0.3, 0.14), rot=E(0, 0, s * 14), bevel=0.15, colour="Dark")
        c.claw("Head", (s * 0.55, 2.8, 4.7), (s * 1.3, 2.0, 5.7), 0.3, curl=V(s * 0.3, -0.3, 0.4))  # the great horns
        c.claw("Head", (s * 0.65, 3.0, 4.3), (s * 1.2, 2.6, 4.6), 0.14)
        for k in range(4): c.claw("Head", (s * (0.15 + 0.13 * k), 4.15 - 0.15 * k, 3.88), (s * (0.15 + 0.13 * k), 4.2 - 0.15 * k, 3.6), 0.06)
    c.anchors["snout"] = ("Head", V(0, 4.35, 4.0))
    # wings: an arm bone, three finger spars, a membrane between them (WingL1 inner, WingL2 outer)
    for s, w in ((-1, "WingL"), (1, "WingR")):
        sh = V(s * 1.3, 0.5, 3.8); wr = V(s * 2.8, -0.1, 5.0)
        c.joint(f"{w}1", tuple(sh), "Body", "wing")
        c.limb(f"{w}1", sh, wr, 0.26, 0.2, seg=6, colour="Plate", bands=2, band_colour="Iron")
        c.joint(f"{w}2", tuple(wr), f"{w}1", "wing")
        tips = [wr + V(s * 1.6, -0.6, 0.2), wr + V(s * 1.4, -1.5, -0.8), wr + V(s * 0.6, -1.8, -1.6)]
        for t in tips:
            c.limb(f"{w}2", wr, t, 0.14, 0.07, seg=6, colour="Plate", bands=1, band_colour="Iron")
            c.claw(f"{w}2", t, t + (t - wr).normalized() * 0.4, 0.08)
        prev = sh + V(0, -1.4, -0.6)
        c.claw(f"{w}2", wr, wr + V(s * 0.1, 0.2, 0.55), 0.14)
        for a, b in zip([sh + V(0, -0.5, -0.3)] + tips, tips + [sh + V(0, -1.6, -0.7)]):
            mid = (a + b) / 2 + (wr - (a + b) / 2) * 0.25
            for tri in ((wr, a, mid), (wr, mid, b)):
                bm = bmesh.new()
                vs = [bm.verts.new(p) for p in tri]
                bm.faces.new(vs)
                bmesh.ops.solidify(bm, geom=list(bm.faces), thickness=0.05)
                c.add(f"{w}2" if a in tips or b in tips else f"{w}1", "Tex", bm, "Wing")
    # pillar legs
    for limb, x, y in (("LegFL", -1.4, 1.3), ("LegFR", 1.4, 1.3), ("LegBL", -1.35, -1.3), ("LegBR", 1.35, -1.3)):
        s = 1 if x > 0 else -1
        hip, knee, ank = V(x, y, 2.4), V(x + s * 0.25, y + 0.2, 1.3), V(x + s * 0.25, y + 0.05, 0.45)
        c.joint(f"{limb}1", tuple(hip), "Body", "leg")
        c.armor(f"{limb}1", tuple((hip + knee) / 2), (0.75, 0.8, 0.85), seg=8, rings=6, colour="Main", rivets="Stud")
        c.claw(f"{limb}1", knee + V(s * 0.55, 0.3, 0.3), knee + V(s * 0.95, 0.25, 0.7), 0.13)
        c.joint(f"{limb}2", tuple(knee), f"{limb}1", "leg")
        c.limb(f"{limb}2", knee, ank, 0.6, 0.55, seg=8, colour="Plate", bands=2, band_colour="Iron")
        c.joint(f"{limb}3", tuple(ank), f"{limb}2", "leg")
        c.foot(f"{limb}3", ank + V(0, 0.3, -0.2), 0.68, claws=4, L=0.7, colour="Plate")
    # the tail: five plated segments with spikes, ending in a spiked mace
    pts = [V(0, -2.4, 2.7), V(0, -3.1, 2.4), V(0, -3.75, 2.0), V(0, -4.3, 1.55), V(0, -4.75, 1.15), V(0, -5.1, 0.85)]
    for i in range(5):
        nm = f"Tail{i + 1}"
        c.joint(nm, tuple(pts[i]), "Body" if i == 0 else f"Tail{i}", "tail")
        r0 = 0.75 - 0.12 * i
        c.limb(nm, pts[i], pts[i + 1], r0, r0 - 0.1, seg=8, colour="Main", bands=1, band_colour="Plate")
        c.claw(nm, pts[i] + V(0, -0.1, r0 * 0.9), pts[i] + V(0, -0.45, r0 * 0.9 + 0.45), 0.13)
    c.armor("Tail5", tuple(pts[5]), (0.5, 0.5, 0.5), seg=8, rings=6, colour="Iron", rivets="Stud")
    for d in (V(1, 0, 0), V(-1, 0, 0), V(0, 0, 1), V(0, -1, 0), V(0.7, 0, -0.7), V(-0.7, 0, -0.7)):
        c.claw("Tail5", pts[5] + d * 0.4, pts[5] + d * 0.95, 0.14)


def quad(c, legs, thigh=0.75, shin=0.55, claws=3, claw_len=0.6, foot=0.62, colour="Main", spur=True, hoof=False):
    """four armoured legs: legs = [(limb, hip, knee, ankle)]"""
    for limb, hip, knee, ank in legs:
        hip, knee, ank = V(hip), V(knee), V(ank)
        s = 1 if hip.x > 0 else -1
        c.joint(f"{limb}1", tuple(hip), "Body", "leg")
        c.armor(f"{limb}1", tuple((hip + knee) / 2), (thigh, thigh * 1.05, (hip - knee).length * 0.62), seg=8, rings=6, colour=colour, rivets="Stud")
        if spur: c.claw(f"{limb}1", knee + V(s * thigh * 0.7, 0.2, 0.25), knee + V(s * (thigh * 0.7 + 0.35), 0.15, 0.6), 0.12)
        c.joint(f"{limb}2", tuple(knee), f"{limb}1", "leg")
        c.limb(f"{limb}2", knee, ank, shin, shin * 0.88, seg=8, colour="Plate", bands=2, band_colour="Iron")
        c.joint(f"{limb}3", tuple(ank), f"{limb}2", "leg")
        if hoof:
            c.block(f"{limb}3", ank + V(0, 0.05, -0.18), (shin * 1.6, shin * 1.6, 0.36), bevel=0.15, colour="Bone", taper=0.85)
        else:
            c.foot(f"{limb}3", ank + V(0, 0.25, -0.18), foot, claws=claws, L=claw_len, colour="Plate")


# ---------------------------------------------------------------- KEPRI SCARAB: Rotary Trench-Borer (Common fast digger)
@pet("Kepri Scarab", {"Main": "#1c1f24", "MainTop": "#2e333c", "Plate": "#23272e", "PlateTop": "#39404b", "Bronze": "#5a4128", "BronzeTop": "#8a6a40",
                      "Dark": "#0e1013", "Bone": "#e8e2d2", "BoneTop": "#ffffff", "Stud": "#8e939e", "StudTop": "#c4c8d2", "Iron": "#2e2c2a", "IronTop": "#46423c",
                      "Glow": "#10e77e", "Edge": "#8a909e"})
def kepri(c):
    c.joint("Body", (0, 0, 1.4))
    # a domed carapace of stepped plates over bronze side armour, a spade head, six jointed ivory-tipped legs
    c.armor("Body", (0, -0.2, 1.45), (1.55, 2.0, 1.15), seg=12, rings=8, colour="Plate", zmin=-0.2, rivets="Stud")
    for k, (z, R) in enumerate(((1.9, 1.35), (2.2, 1.05), (2.45, 0.7))):
        c.armor("Body", (0, -0.3 - 0.1 * k, z), (R, R * 1.35, 0.35), seg=10, rings=5, colour="Main" if k % 2 else "Plate", zmin=-0.1)
    c.block("Body", (0, -0.2, 2.5), (0.16, 3.6, 0.2), bevel=0.2, colour="Bronze")  # the seam between the wing cases
    for s in (-1, 1):
        c.armor("Body", (s * 1.25, -0.1, 1.1), (0.5, 1.75, 0.55), seg=8, rings=6, colour="Bronze", rivets="Stud")
        for wy in (0.6, -0.1, -0.8): c.window("Body", (s * 1.6, wy, 1.15), 0.18, 0.16, (s, 0, 0))
    c.armor("Body", (0, 0.2, 0.75), (1.2, 1.7, 0.45), seg=10, rings=5, colour="Dark", inset=0.03)
    c.anchors["back"] = ("Body", V(0, -0.4, 2.7))
    c.joint("Head", (0, 1.6, 1.3), "Body", "head")
    c.armor("Head", (0, 1.95, 1.3), (0.9, 0.75, 0.6), seg=8, rings=6, colour="Main", rivets="Stud")
    c.armor("Head", (0, 1.8, 1.7), (1.05, 0.65, 0.4), seg=8, rings=5, colour="Plate", zmin=-0.2)
    c.block("Head", (0, 2.75, 1.0), (1.5, 1.1, 0.22), rot=E(28, 0, 0), bevel=0.12, colour="Bone", taper=0.45, panel=0.03)  # the spade clypeus
    for s in (-1, 1):
        c.window("Head", (s * 0.42, 2.55, 1.45), 0.22, 0.14, (s * 0.4, 1, 0.2))
        c.claw("Head", (s * 0.5, 2.4, 0.95), (s * 0.15, 3.0, 0.75), 0.13, curl=V(-s * 0.2, 0, 0))
        c.claw("Head", (s * 0.6, 1.9, 1.85), (s * 0.95, 1.6, 2.4), 0.12)
    c.anchors["eyes"] = ("Head", V(0, 2.6, 1.45))
    for i, (y, sp) in enumerate(((0.9, 0.4), (0.0, 0.0), (-0.9, -0.4))):
        for s in (-1, 1):
            nm = f"Leg{'L' if s < 0 else 'R'}{i + 1}_"
            hip = V(s * 1.1, y, 1.0); knee = V(s * 2.0, y + sp * 0.5, 1.55); foot = V(s * 2.5, y + sp, 0.05)
            c.joint(nm + "1", tuple(hip), "Body", "leg")
            c.limb(nm + "1", hip, knee, 0.26, 0.22, seg=6, colour="Plate", bands=1, band_colour="Bronze")
            c.joint(nm + "2", tuple(knee), nm + "1", "leg")
            c.limb(nm + "2", knee, foot + V(0, 0, 0.35), 0.19, 0.13, seg=6, colour="Plate", bands=1, band_colour="Bronze")
            c.claw(nm + "2", foot + V(0, 0, 0.35), foot, 0.14)
            c.claw(nm + "1", knee, knee + V(s * 0.3, 0, 0.35), 0.08)


# ---------------------------------------------------------------- SHINEMANE: Prismatic Candelabra Lion-Drake (Uncommon light)
@pet("Shinemane", {"Main": "#1d1f25", "MainTop": "#30343e", "Plate": "#25282f", "PlateTop": "#3b404b", "Dark": "#0e0f12", "Bone": "#ece6d4",
                   "BoneTop": "#ffffff", "Stud": "#8e939e", "StudTop": "#c4c8d2", "Iron": "#2c2a26", "IronTop": "#4a4438", "Crystal": "#ffc23a", "Glow": "#ffc23a", "Edge": "#8a909e"})
def shinemane(c):
    c.joint("Body", (0, 0, 2.3))
    # a regal armoured big cat: a deep chest with a glowing hexagonal heart plate, a crown of amber crystal horns, a whip tail
    c.armor("Body", (0, 0.5, 2.35), (1.35, 1.5, 1.2), seg=10, rings=8, colour="Main", rivets="Stud")
    c.armor("Body", (0, -1.0, 2.3), (1.2, 1.35, 1.05), seg=10, rings=8, colour="Main", rivets="Stud")
    c.armor("Body", (0, -0.1, 2.95), (1.15, 2.0, 0.6), seg=10, rings=6, colour="Plate", zmin=0.0)
    hexp = [(0.0, 0.42), (0.36, 0.21), (0.36, -0.21), (0.0, -0.42), (-0.36, -0.21), (-0.36, 0.21)]
    c.block("Body", (0, 1.75, 2.2), (0.95, 0.3, 0.95), bevel=0.2, colour="Iron", panel=0.04)
    c.gem("Body", (0, 1.95, 2.2), 0.42, stretch=(1, 0.45, 1.15))
    for s in (-1, 1):
        c.armor("Body", (s * 1.2, 0.8, 2.75), (0.7, 0.85, 0.55), seg=8, rings=6, colour="Plate", zmin=-0.2, rot=(0, s * 0.3, 0), rivets="Stud")
        for wy in (-0.2, -0.8): c.window("Body", (s * 1.33, wy, 2.3), 0.2, 0.2, (s, 0, 0))
    for k in range(6): c.claw("Body", (0, 0.8 - k * 0.45, 3.5 - 0.08 * k), (0, 0.6 - k * 0.45, 3.85 - 0.08 * k), 0.12)
    c.anchors["heart"] = ("Body", V(0, 2.05, 2.2))
    c.joint("Head", (0, 1.4, 3.0), "Body", "head")
    c.armor("Head", (0, 1.9, 3.3), (0.75, 0.8, 0.65), seg=8, rings=6, colour="Main", rivets="Stud")
    c.block("Head", (0, 2.55, 3.1), (0.75, 0.9, 0.55), rot=E(-10, 0, 0), bevel=0.15, colour="Plate", taper=0.7, panel=0.04)
    c.block("Head", (0, 2.5, 2.8), (0.62, 0.8, 0.25), bevel=0.15, colour="Dark", taper=0.8)
    for s in (-1, 1):
        c.window("Head", (s * 0.32, 2.4, 3.42), 0.22, 0.09, (s * 0.4, 1, 0.25))
        for k in range(3): c.claw("Head", (s * (0.12 + 0.12 * k), 2.85 - 0.1 * k, 2.85), (s * (0.12 + 0.12 * k), 2.9 - 0.1 * k, 2.6), 0.05)
    # the candelabra crown: amber crystal horns branching up and back round the head
    for k in range(9):
        a = math.radians(-80 + k * 20)
        base = V(math.sin(a) * 0.65, 1.8 - 0.25 * math.cos(a), 3.75)
        tip = base + V(math.sin(a) * 0.6, -0.35, 0.9 - 0.25 * abs(math.sin(a)))
        c.claw("Head", base, tip, 0.13, colour="Crystal")
    c.anchors["crown"] = ("Head", V(0, 1.6, 4.5))
    quad(c, [("LegFL", (-0.85, 1.0, 1.9), (-0.95, 1.2, 1.0), (-0.95, 1.1, 0.4)), ("LegFR", (0.85, 1.0, 1.9), (0.95, 1.2, 1.0), (0.95, 1.1, 0.4)),
             ("LegBL", (-0.8, -1.3, 1.9), (-0.9, -1.55, 1.0), (-0.9, -1.35, 0.4)), ("LegBR", (0.8, -1.3, 1.9), (0.9, -1.55, 1.0), (0.9, -1.35, 0.4))],
         thigh=0.55, shin=0.4, foot=0.48, claws=3, claw_len=0.45)
    pts = [V(0, -2.2, 2.6), V(0, -2.75, 2.85), V(0, -3.2, 3.2), V(0, -3.45, 3.65), V(0, -3.4, 4.05)]
    for i in range(4):
        nm = f"Tail{i + 1}"
        c.joint(nm, tuple(pts[i]), "Body" if i == 0 else f"Tail{i}", "tail")
        c.limb(nm, pts[i], pts[i + 1], 0.3 - 0.05 * i, 0.25 - 0.05 * i, seg=6, colour="Main", bands=1, band_colour="Plate")
    c.claw("Tail4", pts[4], pts[4] + V(0, 0.25, 0.5), 0.16, colour="Crystal")


# ---------------------------------------------------------------- GOLDBRISTLE: Pyrite Porcupine (Uncommon lucky)
@pet("Goldbristle", {"Main": "#1b1d22", "MainTop": "#2c3038", "Plate": "#22252c", "PlateTop": "#363b46", "Dark": "#0d0e11", "Bone": "#e8e2d0",
                     "BoneTop": "#ffffff", "Stud": "#8e939e", "StudTop": "#c4c8d2", "Gold": "#b8892a", "GoldTop": "#f0c860", "Glow": "#ffb424", "Edge": "#8a909e"})
def goldbristle(c):
    c.joint("Body", (0, 0, 1.5))
    c.armor("Body", (0, -0.1, 1.55), (1.6, 2.0, 1.2), seg=12, rings=8, colour="Main", rivets="Stud")
    c.armor("Body", (0, 0.4, 0.85), (1.25, 1.5, 0.5), seg=10, rings=5, colour="Dark", inset=0.03)
    for s in (-1, 1):
        for wy in (0.7, 0.0, -0.7): c.window("Body", (s * 1.55, wy, 1.35), 0.22, 0.22, (s, 0, 0))
    # rows of faceted pyrite quills fanned back over the whole back, longest along the spine
    for r in range(6):
        y = 1.2 - r * 0.5
        for k in range(-4, 5):
            a = k * 0.32
            base = V(math.sin(a) * 1.25 * (1 - 0.06 * r), y, 1.55 + math.cos(a) * 1.05 * (1 - 0.05 * r))
            L = (0.95 - 0.12 * abs(k)) * (1.1 - 0.05 * r)
            tip = base + V(math.sin(a) * L * 0.55, -L * 0.6, math.cos(a) * L * 0.7)
            c.claw("Body", base, tip, 0.16 - 0.008 * abs(k), colour="Gold" if (k + r) % 3 else "Bone")
    c.anchors["back"] = ("Body", V(0, -0.4, 3.0))
    c.joint("Head", (0, 1.5, 1.4), "Body", "head")
    c.armor("Head", (0, 1.95, 1.35), (0.7, 0.75, 0.6), seg=8, rings=6, colour="Plate", rivets="Stud")
    c.block("Head", (0, 2.6, 1.15), (0.55, 0.8, 0.4), rot=E(-8, 0, 0), bevel=0.15, colour="Main", taper=0.5, panel=0.03)
    c.block("Head", (0, 3.02, 1.12), (0.22, 0.12, 0.16), bevel=0.2, colour="Dark")
    for s in (-1, 1):
        c.window("Head", (s * 0.35, 2.35, 1.5), 0.2, 0.1, (s * 0.5, 1, 0.3))
        c.claw("Head", (s * 0.45, 1.75, 1.8), (s * 0.7, 1.4, 2.3), 0.1, colour="Gold")
    c.anchors["snout"] = ("Head", V(0, 3.05, 1.12))
    quad(c, [("LegFL", (-0.9, 0.9, 1.0), (-1.05, 1.05, 0.55), (-1.05, 1.0, 0.3)), ("LegFR", (0.9, 0.9, 1.0), (1.05, 1.05, 0.55), (1.05, 1.0, 0.3)),
             ("LegBL", (-0.85, -1.1, 1.0), (-1.0, -1.2, 0.55), (-1.0, -1.1, 0.3)), ("LegBR", (0.85, -1.1, 1.0), (1.0, -1.2, 0.55), (1.0, -1.1, 0.3))],
         thigh=0.48, shin=0.36, foot=0.5, claws=3, claw_len=0.45, spur=False)
    c.joint("Tail1", (0, -2.05, 1.3), "Body", "tail")
    c.block("Tail1", (0, -2.35, 1.2), (0.8, 0.6, 0.35), bevel=0.15, colour="Plate", panel=0.03)
    for k in (-1, 0, 1): c.claw("Tail1", (k * 0.25, -2.55, 1.3), (k * 0.4, -3.0, 1.55), 0.1, colour="Gold")


# ---------------------------------------------------------------- PIXIU: Gilded Vault-Gargoyle (Rare treasure hauler)
@pet("Pixiu", {"Main": "#1a2622", "MainTop": "#2b3b35", "Plate": "#22302b", "PlateTop": "#364841", "Dark": "#0c110f", "Bone": "#e8e4d4",
               "BoneTop": "#ffffff", "Stud": "#8e9a94", "StudTop": "#c4d0ca", "Gold": "#8a6a2c", "GoldTop": "#c8a24c", "Glow": "#00ffb7", "Edge": "#88a098"})
def pixiu(c):
    c.joint("Body", (0, 0, 2.4))
    # a hunched jade gargoyle: huge shoulders, a studded vault-door chest plate, curled horns, a mace tail
    c.armor("Body", (0, 0.4, 2.6), (1.65, 1.4, 1.35), seg=10, rings=8, colour="Main", rivets="Stud")
    c.armor("Body", (0, -1.0, 2.1), (1.25, 1.2, 1.05), seg=10, rings=8, colour="Main", rivets="Stud")
    c.block("Body", (0, 1.65, 2.45), (1.6, 0.4, 1.55), bevel=0.12, colour="Gold", panel=0.06)  # the vault door
    c.armor("Body", (0, 1.88, 2.45), (0.38, 0.12, 0.38), seg=10, rings=4, colour="Iron" if "Iron" in c.pal else "Plate")
    for x in (-0.6, -0.2, 0.2, 0.6):
        for z in (1.85, 3.05): c.studs("Body", [(x, 1.88, z)], r=0.09, colour="Stud")
    for s in (-1, 1):
        c.armor("Body", (s * 1.45, 0.6, 3.1), (0.95, 1.0, 0.75), seg=8, rings=6, colour="Plate", zmin=-0.2, rot=(0, s * 0.35, 0), rivets="Stud")
        c.claw("Body", (s * 1.7, 0.6, 3.6), (s * 2.1, 0.4, 4.0), 0.14)
        c.window("Body", (s * 1.25, -0.9, 2.2), 0.24, 0.24, (s, 0, 0))
    for k in range(6): c.claw("Body", (0, 0.6 - k * 0.45, 3.9 - 0.15 * k), (0, 0.4 - k * 0.45, 4.3 - 0.15 * k), 0.15)
    c.anchors["vault"] = ("Body", V(0, 1.95, 2.45))
    c.joint("Head", (0, 1.3, 3.3), "Body", "head")
    c.armor("Head", (0, 1.85, 3.55), (0.85, 0.85, 0.72), seg=8, rings=6, colour="Main", rivets="Stud")
    c.block("Head", (0, 2.55, 3.3), (0.95, 0.9, 0.6), rot=E(-10, 0, 0), bevel=0.15, colour="Plate", taper=0.7, panel=0.04)
    c.block("Head", (0, 2.45, 2.95), (0.85, 0.85, 0.3), bevel=0.15, colour="Dark", taper=0.8)
    for s in (-1, 1):
        c.window("Head", (s * 0.36, 2.3, 3.75), 0.22, 0.12, (s * 0.4, 1, 0.3))
        c.claw("Head", (s * 0.55, 1.75, 4.1), (s * 0.95, 1.2, 4.75), 0.2, curl=V(s * 0.2, -0.5, 0.3))
        for k in range(3): c.claw("Head", (s * (0.15 + 0.14 * k), 2.9 - 0.12 * k, 3.0), (s * (0.15 + 0.14 * k), 2.95 - 0.12 * k, 2.72), 0.06)
    quad(c, [("LegFL", (-1.1, 1.0, 2.0), (-1.3, 1.25, 1.1), (-1.3, 1.15, 0.42)), ("LegFR", (1.1, 1.0, 2.0), (1.3, 1.25, 1.1), (1.3, 1.15, 0.42)),
             ("LegBL", (-0.9, -1.3, 1.7), (-1.0, -1.5, 0.95), (-1.0, -1.3, 0.4)), ("LegBR", (0.9, -1.3, 1.7), (1.0, -1.5, 0.95), (1.0, -1.3, 0.4))],
         thigh=0.68, shin=0.5, foot=0.6, claws=3, claw_len=0.55)
    pts = [V(0, -2.0, 2.3), V(0, -2.6, 2.1), V(0, -3.1, 1.75), V(0, -3.5, 1.35)]
    for i in range(3):
        nm = f"Tail{i + 1}"
        c.joint(nm, tuple(pts[i]), "Body" if i == 0 else f"Tail{i}", "tail")
        c.limb(nm, pts[i], pts[i + 1], 0.32 - 0.05 * i, 0.27 - 0.05 * i, seg=6, colour="Main", bands=1, band_colour="Plate")
    c.armor("Tail3", tuple(pts[3]), (0.38, 0.38, 0.38), seg=8, rings=6, colour="Gold", rivets="Stud")
    for d in (V(1, 0, 0), V(-1, 0, 0), V(0, 0, 1), V(0, -1, 0)): c.claw("Tail3", pts[3] + d * 0.3, pts[3] + d * 0.7, 0.1)


# ---------------------------------------------------------------- SELKIE: Trench-Torpedo Amphipod (Rare oxygen diver)
@pet("Selkie", {"Main": "#16202c", "MainTop": "#24344a", "Plate": "#1c2836", "PlateTop": "#2e4258", "Dark": "#0a0e14", "Bone": "#e4eaee",
                "BoneTop": "#ffffff", "Stud": "#7f8ea0", "StudTop": "#aebccc", "Gill": "#1a5260", "GillTop": "#2a7a8a", "Glow": "#00e5ff", "Edge": "#7a8ca8"})
def selkie(c):
    c.joint("Body", (0, 0, 1.9))
    # a streamlined armoured torpedo (concepts/Selkie_s13): a great curved ivory dorsal fin, gill cowls of glowing filter plates,
    # four clawed paddle limbs, a forked tail fin
    c.armor("Body", (0, 0.3, 1.9), (1.2, 2.2, 1.05), seg=12, rings=8, colour="Main", rivets="Stud")
    c.armor("Body", (0, -1.6, 1.85), (0.85, 1.3, 0.75), seg=10, rings=7, colour="Main", rivets="Stud")
    c.armor("Body", (0, 0.3, 1.25), (0.95, 2.0, 0.45), seg=10, rings=5, colour="Dark", inset=0.03)
    for k in range(5):  # overlapping dorsal plates
        c.armor("Body", (0, 1.3 - k * 0.65, 2.55 - 0.05 * k), (0.95 - 0.08 * k, 0.5, 0.35), seg=8, rings=5, colour="Plate", zmin=-0.1)
    fin = [V(0, 0.6 - 0.35 * i, 2.8 + 0.42 * i - 0.06 * i * i) for i in range(7)]
    for a, b in zip(fin, fin[1:]): c.limb("Body", a, b, 0.26 - 0.025 * fin.index(a), 0.24 - 0.025 * fin.index(a), seg=6, colour="Bone", bands=0)
    c.claw("Body", fin[-1], fin[-1] + V(0, -0.6, -0.15), 0.12)
    for s in (-1, 1):  # gill cowls: three stepped plates with glowing slots
        for k in range(3):
            y = 1.55 - k * 0.38
            c.block("Body", (s * 1.05, y, 2.05), (0.18, 0.32, 0.75 - 0.1 * k), rot=E(0, 0, s * 12), bevel=0.15, colour="Gill")
            c.block("Body", (s * 1.12, y - 0.17, 2.05), (0.06, 0.08, 0.55 - 0.1 * k), rot=E(0, 0, s * 12), bevel=0.0, colour="Glow", role="Glow")
        for wy in (0.2, -0.5, -1.2): c.gem("Body", (s * 1.02, wy, 1.9), 0.14, stretch=(0.5, 1, 1.2))
    c.anchors["gills"] = ("Body", V(0, 1.3, 2.6))
    c.joint("Head", (0, 2.0, 1.95), "Body", "head")
    c.armor("Head", (0, 2.65, 1.95), (0.85, 0.95, 0.7), seg=10, rings=7, colour="Main", rivets="Stud")
    c.block("Head", (0, 3.35, 1.8), (0.7, 0.9, 0.5), rot=E(-6, 0, 0), bevel=0.15, colour="Plate", taper=0.55, panel=0.03)
    for s in (-1, 1):
        c.window("Head", (s * 0.42, 3.1, 2.15), 0.24, 0.1, (s * 0.5, 1, 0.2))
        c.claw("Head", (s * 0.3, 3.45, 1.55), (s * 0.25, 3.7, 1.0), 0.09)
    c.anchors["snout"] = ("Head", V(0, 3.8, 1.8))
    for limb, hip, tip, y in (("FinFL", (-0.95, 1.1, 1.5), (-2.0, 1.6, 0.25), 1.1), ("FinFR", (0.95, 1.1, 1.5), (2.0, 1.6, 0.25), 1.1),
                              ("FinBL", (-0.75, -1.3, 1.5), (-1.7, -1.6, 0.25), -1.3), ("FinBR", (0.75, -1.3, 1.5), (1.7, -1.6, 0.25), -1.3)):
        hip, tip = V(hip), V(tip)
        mid = (hip + tip) / 2 + V(0, 0, 0.35)
        c.joint(limb + "1", tuple(hip), "Body", "leg")
        c.limb(limb + "1", hip, mid, 0.34, 0.28, seg=6, colour="Plate", bands=1, band_colour="Gill")
        c.joint(limb + "2", tuple(mid), limb + "1", "leg")
        c.block(limb + "2", (mid + tip) / 2, (0.75, 0.55, (tip - mid).length * 1.05), rot=look(tip - mid), bevel=0.15, colour="Main", taper=0.8, panel=0.04)
        for k in (-1, 0, 1): c.claw(limb + "2", tip + V(k * 0.18, 0.1, 0.05), tip + V(k * 0.26, 0.45, -0.15), 0.07)
    pts = [V(0, -2.6, 1.9), V(0, -3.2, 1.95), V(0, -3.7, 2.05)]
    for i in range(2):
        nm = f"Tail{i + 1}"
        c.joint(nm, tuple(pts[i]), "Body" if i == 0 else f"Tail{i}", "tail")
        c.limb(nm, pts[i], pts[i + 1], 0.42 - 0.12 * i, 0.32 - 0.1 * i, seg=8, colour="Main", bands=1, band_colour="Plate")
    for s in (-1, 1):
        c.block("Tail2", pts[2] + V(s * 0.45, -0.35, 0.3 * s), (0.18, 0.9, 0.5), rot=E(s * 35, 0, s * 25), bevel=0.15, colour="Plate", taper=0.4)
        c.claw("Tail2", pts[2] + V(s * 0.7, -0.6, 0.55 * s), pts[2] + V(s * 0.9, -1.0, 0.85 * s), 0.08)


# ---------------------------------------------------------------- ZHARBIRD: Kiln-Born Magma Raptor (Epic heat-proof)
@pet("Zharbird", {"Main": "#1f1717", "MainTop": "#342626", "Plate": "#2a1d1c", "PlateTop": "#40302c", "Dark": "#0e0a0a", "Bone": "#ece4d4",
                  "BoneTop": "#ffffff", "Stud": "#8c7e78", "StudTop": "#c0b0a8", "Brick": "#5a2a20", "BrickTop": "#86402c", "Glow": "#ff4a12", "Edge": "#9a8480"})
def zharbird(c):
    c.joint("Body", (0, 0, 2.6))
    # an upright armoured raptor (concepts/Zharbird_s12): a chevron-plated breast glowing with magma, kiln-tile wings of
    # stepped blade feathers, an ivory crown crest, talons
    c.armor("Body", (0, 0.1, 2.75), (1.05, 0.9, 1.3), seg=10, rings=8, colour="Main", rivets="Stud")
    c.armor("Body", (0, -0.35, 2.0), (0.85, 0.75, 0.8), seg=8, rings=6, colour="Plate")
    for k in range(4):  # the glowing chevron breast plates
        z = 3.3 - k * 0.42
        for s in (-1, 1):
            c.block("Body", (s * 0.25, 0.92 - 0.04 * k, z), (0.5, 0.18, 0.3), rot=E(0, s * 32, 0), bevel=0.15, colour="Brick", panel=0.02)
        c.block("Body", (0, 1.0 - 0.04 * k, z - 0.12), (0.22, 0.1, 0.18), bevel=0.0, colour="Glow", role="Glow")
    c.anchors["breast"] = ("Body", V(0, 1.1, 2.9))
    c.joint("Head", (0, 0.4, 3.9), "Body", "head")
    c.armor("Head", (0, 0.65, 4.35), (0.6, 0.65, 0.58), seg=8, rings=6, colour="Main", rivets="Stud")
    c.claw("Head", (0, 1.15, 4.35), (0, 1.75, 4.0), 0.26, curl=V(0, 0, -0.5))  # the beak
    for s in (-1, 1):
        c.window("Head", (s * 0.33, 1.05, 4.5), 0.2, 0.09, (s * 0.5, 1, 0.2))
        c.block("Head", (s * 0.33, 1.0, 4.65), (0.36, 0.2, 0.1), rot=E(0, 0, s * 18), bevel=0.15, colour="Dark")
    for k in range(7):  # the crown crest of ivory spikes, raked back
        a = math.radians(-60 + k * 20)
        base = V(math.sin(a) * 0.35, 0.55, 4.8)
        c.claw("Head", base, base + V(math.sin(a) * 0.35, -0.5, 0.95 - 0.2 * abs(math.sin(a))), 0.11)
    c.anchors["crest"] = ("Head", V(0, 0.3, 5.5))
    for s, w in ((-1, "WingL"), (1, "WingR")):
        sh = V(s * 0.95, 0.0, 3.4); el = V(s * 2.0, -0.2, 3.9); tip = V(s * 3.2, -0.5, 4.2)
        c.joint(f"{w}1", tuple(sh), "Body", "wing")
        c.limb(f"{w}1", sh, el, 0.3, 0.25, seg=6, colour="Plate", bands=1, band_colour="Brick")
        for k in range(5):
            u = k / 4
            b0 = sh.lerp(el, u)
            c.block(f"{w}1", b0 + V(0, -0.2, -0.55), (0.32, 0.18, 1.0 + 0.2 * u), rot=E(-8, s * (10 + 12 * u), 0), bevel=0.15, colour="Brick" if k % 2 else "Plate", taper=0.5)
        c.joint(f"{w}2", tuple(el), f"{w}1", "wing")
        c.limb(f"{w}2", el, tip, 0.24, 0.16, seg=6, colour="Plate", bands=1, band_colour="Brick")
        for k in range(6):
            u = k / 5
            b0 = el.lerp(tip, u)
            L = 1.6 - 0.5 * u
            c.block(f"{w}2", b0 + V(s * 0.15, -0.2, -L * 0.42), (0.26, 0.16, L), rot=E(-6, s * (28 + 18 * u), 0), bevel=0.15, colour="Plate" if k % 2 else "Brick", taper=0.4)
            if k % 2 == 0: c.block(f"{w}2", b0 + V(s * 0.15, -0.12, -L * 0.3), (0.06, 0.06, L * 0.5), rot=E(-6, s * (28 + 18 * u), 0), bevel=0.0, colour="Glow", role="Glow")
        c.claw(f"{w}2", tip, tip + V(s * 0.6, -0.1, 0.25), 0.14)
    for s, leg in ((-1, "LegL"), (1, "LegR")):
        hip = V(s * 0.5, -0.2, 1.9); kn = V(s * 0.6, 0.2, 1.05); an = V(s * 0.6, -0.15, 0.35)
        c.joint(f"{leg}1", tuple(hip), "Body", "leg")
        c.armor(f"{leg}1", tuple((hip + kn) / 2), (0.45, 0.45, 0.55), seg=8, rings=6, colour="Main", rivets="Stud")
        c.joint(f"{leg}2", tuple(kn), f"{leg}1", "leg")
        c.limb(f"{leg}2", kn, an, 0.22, 0.18, seg=6, colour="Plate", bands=2, band_colour="Brick")
        c.foot(f"{leg}2", an + V(0, 0.2, -0.15), 0.42, claws=3, L=0.5, colour="Plate")
    for k, x in enumerate((-0.35, 0.0, 0.35)):  # tail plumes of stepped blades
        nm = f"Tail{k + 1}"
        c.joint(nm, (x * 0.3, -0.9, 2.1), "Body", "tail")
        c.block(nm, (x, -1.6, 1.85 + 0.1 * (k == 1)), (0.24, 1.4, 0.16), rot=E(-15, 0, x * 30), bevel=0.15, colour="Brick" if k == 1 else "Plate", taper=0.35)
        c.block(nm, (x, -1.75, 1.92 + 0.1 * (k == 1)), (0.06, 0.8, 0.06), rot=E(-15, 0, x * 30), bevel=0.0, colour="Glow", role="Glow")


# ---------------------------------------------------------------- KIRIN: Sacred Gloom-Purging Qilin (Legendary cleanser)
@pet("Kirin", {"Main": "#171b2a", "MainTop": "#252c44", "Plate": "#1d2336", "PlateTop": "#2f3a58", "Dark": "#0b0d14", "Bone": "#ece8dc",
               "BoneTop": "#ffffff", "Stud": "#8a94ae", "StudTop": "#bcc6de", "Gold": "#8a6a2c", "GoldTop": "#d0a650", "Glow": "#00f5ff", "Edge": "#8090b4"})
def kirin(c):
    c.joint("Body", (0, 0, 2.7))
    # a slender armoured stag-dragon (concepts/Kirin_s13): scale-plated body with a gold saddle plate, glowing seams, branching
    # ivory antlers, long legs with ivory hooves, a ribbon tail
    c.armor("Body", (0, 0.5, 2.75), (1.0, 1.35, 0.95), seg=10, rings=8, colour="Main", rivets="Stud")
    c.armor("Body", (0, -1.0, 2.7), (0.9, 1.2, 0.88), seg=10, rings=8, colour="Main", rivets="Stud")
    for k in range(6):  # overlapping scale bands
        c.armor("Body", (0, 1.2 - k * 0.48, 3.0), (1.0 - 0.03 * k, 0.32, 0.72), seg=10, rings=5, colour="Plate", zmin=0.1)
    c.block("Body", (0, -0.2, 3.62), (1.3, 1.3, 0.22), bevel=0.2, colour="Gold", panel=0.05)
    for s in (-1, 1):
        c.block("Body", (s * 0.95, -0.2, 3.1), (0.12, 1.25, 0.8), rot=E(0, s * 20, 0), bevel=0.2, colour="Gold", panel=0.04)
        c.block("Body", (s * 0.93, 0.6, 2.55), (0.05, 1.4, 0.06), rot=E(10, 0, 0), bevel=0.0, colour="Glow", role="Glow")
        c.block("Body", (s * 0.88, -1.0, 2.5), (0.05, 1.1, 0.06), rot=E(-10, 0, 0), bevel=0.0, colour="Glow", role="Glow")
    c.anchors["back"] = ("Body", V(0, -0.2, 3.8))
    c.joint("Neck", (0, 1.4, 3.1), "Body", "neck")
    c.limb("Neck", (0, 1.35, 3.0), (0, 2.0, 4.0), 0.5, 0.4, seg=8, colour="Main", bands=3, band_colour="Plate")
    for k in range(4): c.claw("Neck", (0, 1.5 + 0.15 * k, 3.4 + 0.2 * k), (0, 1.15 + 0.15 * k, 3.75 + 0.2 * k), 0.08)
    c.joint("Head", (0, 2.0, 4.0), "Neck", "head")
    c.armor("Head", (0, 2.3, 4.25), (0.5, 0.6, 0.5), seg=8, rings=6, colour="Main", rivets="Stud")
    c.block("Head", (0, 2.95, 4.05), (0.55, 0.95, 0.38), rot=E(-12, 0, 0), bevel=0.15, colour="Plate", taper=0.55, panel=0.03)
    for s in (-1, 1):
        c.window("Head", (s * 0.3, 2.65, 4.4), 0.2, 0.08, (s * 0.5, 1, 0.25))
        # branched ivory antlers: a main beam and three tines
        b0 = V(s * 0.3, 2.15, 4.65)
        m1 = b0 + V(s * 0.35, -0.15, 0.65); m2 = m1 + V(s * 0.45, -0.35, 0.6); m3 = m2 + V(s * 0.3, -0.35, 0.45)
        for a, b in ((b0, m1), (m1, m2), (m2, m3)): c.limb("Head", a, b, 0.08, 0.065, seg=6, colour="Bone", bands=0)
        for base, d in ((m1, V(s * -0.1, 0.25, 0.45)), (m2, V(s * 0.1, 0.3, 0.5)), (m2.lerp(m3, 0.5), V(s * 0.35, 0.05, 0.3))):
            c.claw("Head", base, base + d, 0.06)
        c.claw("Head", m3, m3 + V(s * 0.1, -0.25, 0.3), 0.05)
        c.claw("Head", (s * 0.18, 3.25, 3.9), (s * 0.55, 3.35, 3.55), 0.04)  # whiskers
    c.anchors["antlers"] = ("Head", V(0, 1.8, 5.6))
    quad(c, [("LegFL", (-0.6, 1.0, 2.2), (-0.65, 1.3, 1.25), (-0.65, 1.1, 0.35)), ("LegFR", (0.6, 1.0, 2.2), (0.65, 1.3, 1.25), (0.65, 1.1, 0.35)),
             ("LegBL", (-0.55, -1.3, 2.2), (-0.6, -1.65, 1.25), (-0.6, -1.4, 0.35)), ("LegBR", (0.55, -1.3, 2.2), (0.6, -1.65, 1.25), (0.6, -1.4, 0.35))],
         thigh=0.45, shin=0.24, hoof=True, spur=True)
    pts = [V(0, -2.1, 2.9), V(0, -2.65, 2.75), V(0, -3.1, 2.4), V(0, -3.4, 1.95), V(0, -3.55, 1.5)]
    for i in range(4):
        nm = f"Tail{i + 1}"
        c.joint(nm, tuple(pts[i]), "Body" if i == 0 else f"Tail{i}", "tail")
        c.limb(nm, pts[i], pts[i + 1], 0.2 - 0.03 * i, 0.17 - 0.03 * i, seg=6, colour="Main", bands=1, band_colour="Gold")
    for k in (-1, 0, 1): c.claw("Tail4", pts[4], pts[4] + V(k * 0.3, -0.35, -0.35), 0.08)


# ---------------------------------------------------------------- OURO: World-Coil Leviathan (Mythic all-rounder)
@pet("Ouro", {"Main": "#12161a", "MainTop": "#222a30", "Plate": "#192026", "PlateTop": "#2c3842", "Dark": "#080a0c", "Bone": "#e6e2cc",
              "BoneTop": "#ffffff", "Belly": "#a8a07c", "BellyTop": "#d0c8a0", "Stud": "#7c8a90", "StudTop": "#b0bec4", "Glow": "#00ff88", "Edge": "#7a9098"})
def ouro(c):
    # a coiled armoured serpent-dragon (concepts/Ouro_s11): a two-turn coil on the ground rising into a reared neck and a horned
    # head, ivory belly scutes, dorsal spikes, glowing green slots; every vertebra is its own segment (Spine1..Spine18)
    pts = []
    for i in range(19):
        t = i / 18
        a = t * math.tau * 1.55 + 0.6
        R = 2.1 - 0.75 * t
        pts.append(V(math.cos(a) * R, math.sin(a) * R - 0.2, 0.55 + 0.38 * t * t))
    c.joint("Body", tuple(pts[0]))
    c.claw("Body", pts[0], pts[0] + (pts[0] - pts[1]).normalized() * 0.7, 0.16)  # the tail tip (the root piece of the chain)
    for i in range(18):
        nm = f"Spine{i + 1}"
        c.joint(nm, tuple(pts[i]), "Body" if i == 0 else f"Spine{i}", "spine")
        r = 0.18 + 0.42 * (i / 17)
        a, b = pts[i], pts[i + 1]
        c.limb(nm, a, b, r, r + 0.025, seg=8, colour="Main", bands=1, band_colour="Plate")
        d = (b - a).normalized(); side = d.cross(V(0, 0, 1)).normalized()
        mid = (a + b) / 2
        c.block(nm, mid + V(0, 0, -r * 0.85), (r * 1.3, (b - a).length * 0.85, r * 0.3), rot=look(d), bevel=0.15, colour="Belly")
        c.claw(nm, mid + V(0, 0, r * 0.9), mid + V(0, 0, r * 0.9 + 0.25 + r * 0.5) - d * 0.15, r * 0.35)
        if i % 3 == 1: c.block(nm, mid + side * r * 1.0, (0.06, (b - a).length * 0.5, r * 0.4), rot=look(d), bevel=0.0, colour="Glow", role="Glow")
    # the reared neck and head
    n0 = pts[-1]
    neck = [n0, n0 + V(0.2, 0.3, 0.9), n0 + V(0.25, 0.75, 1.7), n0 + V(0.2, 1.25, 2.3)]
    for i in range(3):
        nm = f"Neck{i + 1}"
        c.joint(nm, tuple(neck[i]), "Spine18" if i == 0 else f"Neck{i}", "neck")
        c.limb(nm, neck[i], neck[i + 1], 0.62 - 0.08 * i, 0.55 - 0.08 * i, seg=8, colour="Main", bands=2, band_colour="Plate")
        c.block(nm, (neck[i] + neck[i + 1]) / 2 + V(0, 0.45, 0), (0.6, 0.25, (neck[i + 1] - neck[i]).length * 0.85), rot=look(neck[i + 1] - neck[i], V(0, 1, 0)), bevel=0.15, colour="Belly")
        c.claw(nm, (neck[i] + neck[i + 1]) / 2 + V(0, -0.45, 0.1), (neck[i] + neck[i + 1]) / 2 + V(0, -0.95, 0.35), 0.13)
    h = neck[-1]
    c.joint("Head", tuple(h), "Neck3", "head")
    c.armor("Head", tuple(h + V(0, 0.45, 0.25)), (0.65, 0.75, 0.55), seg=8, rings=6, colour="Main", rivets="Stud")
    c.block("Head", h + V(0, 1.15, 0.12), (0.7, 1.1, 0.45), rot=E(-8, 0, 0), bevel=0.15, colour="Plate", taper=0.55, panel=0.03)
    c.block("Head", h + V(0, 1.05, -0.18), (0.6, 0.95, 0.22), bevel=0.15, colour="Dark", taper=0.6)
    for s in (-1, 1):
        c.window("Head", tuple(h + V(s * 0.35, 0.95, 0.45)), 0.22, 0.09, (s * 0.5, 1, 0.25))
        c.claw("Head", h + V(s * 0.4, 0.3, 0.6), h + V(s * 0.85, -0.55, 1.45), 0.18, curl=V(s * 0.2, -0.3, 0.3))
        c.claw("Head", h + V(s * 0.55, 0.2, 0.3), h + V(s * 1.0, -0.3, 0.55), 0.1)
        for k in range(3): c.claw("Head", h + V(s * (0.12 + 0.12 * k), 1.5 - 0.15 * k, -0.25), h + V(s * (0.12 + 0.12 * k), 1.55 - 0.15 * k, -0.5), 0.05)
    c.gem("Head", tuple(h + V(0, 0.55, 0.85)), 0.2, stretch=(0.8, 0.5, 1.3))
    c.anchors["gem"] = ("Head", h + V(0, 0.6, 0.85))


if __name__ == "__main__":
    rp = os.path.join(here, "rigs.json")
    db = json.load(open(rp)) if os.path.exists(rp) else {}
    for name, (pal, fn) in D.items():
        if ONLY and name not in ONLY and name.replace(" ", "") not in ONLY: continue
        c = K.Creature(name, pal)
        fn(c)
        d = K.export(c, OUT)
        db[name] = d
        print(f"{name}: {d['tris']} triangles, {d['parts']} parts, {d['objects']} objects, biggest {d['maxPart']}, size {d['size']}", flush=True)
    json.dump(db, open(rp, "w"), indent=1)
