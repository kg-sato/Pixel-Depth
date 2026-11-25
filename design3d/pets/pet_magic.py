"""The v16 pets, magical fantasy edition (the owner, 2026-11-24: "base ours more on magical and fantasy instead of the metallic
version"). Same craft as pet_plate.py (big creatures, many animatable bones, limbs as segment chains, layered plates, fine detail,
no triangle cap while designing: export() splits anything over the MeshPart limit) but enchanted materials: bark and moss, jade,
living crystal, pearl, feathers, fur tufts, gold filigree, glowing runes and floating parts. No rivets, windows or machinery.
Concepts: Overnight/refs/pets_v16/magic/concepts.json (Gemini), renders magic/concepts/<Name>_s21|s22.png, picks in magic/picks.json.
    blender -b -P design3d/pets/pet_magic.py -- <out_dir> [Name ...]
Writes <Name>.glb and merges the rig data into design3d/pets/rigs.json (same contract as pet_plate.py)."""
import json, math, os, sys
import bmesh
here = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, here)
import plate_kit as K
from plate_kit import V, look
from mathutils import Euler

args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = os.path.abspath(args[0] if args else os.path.join(here, "out_magic"))
ONLY = set(a for a in args[1:] if not a.startswith("-"))
os.makedirs(OUT, exist_ok=True)
D = {}


def pet(name, pal):
    def deco(fn): D[name] = (pal, fn); return fn
    return deco


def E(rx=0, ry=0, rz=0):
    return Euler((math.radians(rx), math.radians(ry), math.radians(rz))).to_matrix()


def leg(c, limb, hip, knee, ank, r=(0.5, 0.4, 0.32), colour="Main", thigh=None, foot="paw", claws=3, parent="Body", band=None, toe=0.35):
    """a three-bone leg: limb1 thigh (an optional muscle shell), limb2 shin, limb3 a paw with claws or a hoof"""
    hip, knee, ank = V(hip), V(knee), V(ank)
    c.joint(limb + "1", tuple(hip), parent, "leg")
    if thigh:
        c.armor(limb + "1", tuple(hip.lerp(knee, 0.4)), (r[0] * 1.3, r[0] * 1.35, (hip - knee).length * 0.6), seg=18, rings=12, colour=thigh, inset=0, lift=0.02)
    c.limb(limb + "1", hip, knee, r[0], r[1], seg=12, colour=colour, bands=0, facets=False)
    c.joint(limb + "2", tuple(knee), limb + "1", "leg")
    c.limb(limb + "2", knee, ank, r[1], r[2], seg=12, colour=colour, bands=1 if band else 0, band_colour=band or colour, facets=False)
    c.joint(limb + "3", tuple(ank), limb + "2", "leg")
    if foot == "hoof":
        c.block(limb + "3", ank + V(0, 0.05, -ank.z / 2 + 0.02), (r[2] * 2.3, r[2] * 2.4, max(0.3, ank.z + 0.1)), bevel=0.18, colour="Bone", taper=0.85)
    else:
        c.foot(limb + "3", ank + V(0, toe, -ank.z * 0.55), r[2] * 1.7, claws=claws, L=r[2] * 1.4, colour=colour)


def chain_tube(c, prefix, pts, radii, colour, parent, group, seg=8, shell=None):
    """a smooth swept chain (tails, necks, ribbons): one bone per segment; shell = (colour, scale) adds an ellipsoid puff per bone"""
    names = []
    for i in range(len(pts) - 1):
        nm = f"{prefix}{i + 1}"
        c.joint(nm, tuple(pts[i]), parent if i == 0 else names[-1], group)
        a, b = V(pts[i]), V(pts[i + 1])
        c.tube(nm, [a, a.lerp(b, 0.5), b], [radii[i], (radii[i] + radii[i + 1]) / 2, radii[i + 1]], colour=colour, seg=seg)
        if shell:
            d = b - a
            c.armor(nm, tuple(a.lerp(b, 0.5)), (radii[i] * shell[1], d.length * 0.62, radii[i] * shell[1]), seg=10, rings=8, colour=shell[0], rot=look(d), inset=0.02, lift=0.015)
        names.append(nm)
    return names


def moss_blanket(c, part, centre, radii, n=30, colours=("Moss", "MossTop"), zmin=0.45, r=(0.3, 0.55), seed=1):
    """a carpet of moss clumps over the top of an ellipsoid (smooth domes of two greens)"""
    import random as _r
    rnd = _r.Random(seed)
    C, R = V(centre), V(radii)
    made = tries = 0
    while made < n and tries < n * 50:
        tries += 1
        u = rnd.uniform(zmin, 1.0); th = rnd.uniform(0, math.tau); sq = math.sqrt(1 - u * u)
        q = C + V(sq * math.cos(th) * R.x, sq * math.sin(th) * R.y, u * R.z)
        c.moss(part, q, rnd.uniform(*r), n=5, colour=colours[made % len(colours)], seed=seed * 100 + made)
        made += 1


# ---------------------------------------------------------------- TOSK: Mossbark Boar-Cart (Common hauler; concept B)
@pet("Tosk", {"Bark": "#3e2c1f", "BarkTop": "#5e4532", "Dark": "#221710", "DarkTop": "#33241a", "Moss": "#4a7d2e", "MossTop": "#86b84a",
              "Tusk": "#e8d3a8", "TuskTop": "#fff4d6", "Bone": "#d8c29a", "BoneTop": "#f4e4c2", "Root": "#6e4b2c", "RootTop": "#94703f",
              "Snout": "#7a4f3c", "SnoutTop": "#9a6a52", "Crystal": "#ffb03a", "Glow": "#ffb52e", "Edge": "#c8b088",
              "_noseams": True, "_smooth": ["Bark", "Dark", "Moss", "MossTop", "Tusk", "Snout", "Root", "Bone"]})
def tosk(c):
    c.joint("Body", (0, 0, 2.4))
    # a stocky bark boar (magic/concepts/Tosk_s22): a high shoulder hump under a carpet of moss, root vines over the flanks,
    # glowing amber runes, and a basket of living roots on its back heaped with glowing amber
    c.armor("Body", (0, 0.2, 2.45), (1.75, 2.2, 1.35), seg=28, rings=18, colour="Bark", inset=0)
    c.armor("Body", (0, 0.95, 3.15), (1.55, 1.3, 1.05), seg=26, rings=16, colour="Bark", inset=0)
    c.armor("Body", (0, -1.35, 2.4), (1.45, 1.05, 1.1), seg=26, rings=16, colour="Bark", inset=0)
    c.armor("Body", (0, 0.2, 1.7), (1.3, 1.9, 0.6), seg=22, rings=14, colour="Dark", inset=0)
    moss_blanket(c, "Body", (0, 0.2, 2.5), (1.72, 2.15, 1.32), n=26, zmin=0.55, seed=3)
    moss_blanket(c, "Body", (0, 0.95, 3.15), (1.52, 1.28, 1.02), n=18, zmin=0.5, r=(0.3, 0.5), seed=4)
    for s in (-1, 1):
        c.tube("Body", [(s * 1.4, 1.7, 3.35), (s * 1.78, 0.8, 2.6), (s * 1.72, -0.3, 2.8), (s * 1.6, -1.2, 2.25), (s * 1.3, -1.95, 1.95)], [0.14, 0.16, 0.14, 0.11, 0.06], colour="Root", seg=8)
        c.tube("Body", [(s * 1.68, 0.3, 2.05), (s * 1.75, -0.6, 2.0), (s * 1.45, -1.65, 2.85)], [0.1, 0.11, 0.05], colour="Root", seg=8)
        c.tube("Body", [(s * 1.5, 1.4, 2.1), (s * 1.72, 1.0, 2.6), (s * 1.6, 0.3, 3.3)], [0.08, 0.09, 0.04], colour="Root", seg=8)
        for k, (y, z) in enumerate(((0.9, 2.5), (-0.5, 2.35))):
            c.rune("Body", (s * 1.76, y, z), (s, 0, 0.1), 0.34, glyph=k + (2 if s > 0 else 0))
    # the root basket on the back, heaped with glowing amber
    B = V(0, -0.35, 4.0)
    c.ring("Body", B, 0.95, 0.17, 0.2, 16, normal=(0, 0, 1), colour="Root")
    c.ring("Body", B + V(0, 0, 0.48), 1.12, 0.17, 0.2, 18, normal=(0, 0, 1), colour="Root")
    for k in range(10):
        a = k / 10 * math.tau
        c.tube("Body", [B + V(math.cos(a) * 0.85, math.sin(a) * 0.85, -0.4), B + V(math.cos(a) * 1.02, math.sin(a) * 1.02, 0.25), B + V(math.cos(a) * 1.18, math.sin(a) * 1.18, 0.78)], [0.08, 0.09, 0.04], colour="Root", seg=6)
    c.cluster("Body", B + V(0, 0, 0.1), (0, 0, 1), 1.2, n=7, colour="Crystal", spread=0.6, seed=4)
    c.cluster("Body", B + V(0.5, -0.3, 0.2), (0.4, -0.2, 1), 0.7, n=4, colour="Crystal", seed=7)
    c.cluster("Body", B + V(-0.45, 0.35, 0.2), (-0.4, 0.3, 1), 0.6, n=4, colour="Crystal", seed=8)
    c.anchors["back"] = ("Body", B + V(0, 0, 0.9))
    # the head: big and low, a long snout with a pink disc nose, amber eyes under a heavy brow, leaf ears and two great tusks
    # curving forward and up
    c.joint("Head", (0, 2.0, 2.6), "Body", "head")
    c.armor("Head", (0, 2.75, 2.55), (1.15, 1.1, 1.0), seg=24, rings=16, colour="Bark", inset=0)
    c.armor("Head", (0, 2.95, 3.2), (1.05, 0.75, 0.42), seg=20, rings=12, colour="Bark", inset=0, rot=E(-12, 0, 0))
    c.limb("Head", (0, 3.0, 2.3), (0, 4.25, 2.1), 0.62, 0.48, seg=16, colour="Bark", bands=0, facets=False)
    c.armor("Head", (0, 4.28, 2.1), (0.5, 0.14, 0.4), seg=20, rings=12, colour="Snout", inset=0)
    c.armor("Head", (0, 3.6, 1.72), (0.62, 0.75, 0.28), seg=18, rings=10, colour="Dark", inset=0)
    moss_blanket(c, "Head", (0, 2.8, 2.75), (1.0, 0.85, 0.85), n=9, zmin=0.6, r=(0.22, 0.38), seed=9)
    for s in (-1, 1):
        c.armor("Head", (s * 0.17, 4.38, 2.12), (0.07, 0.05, 0.1), seg=10, rings=6, colour="Dark", inset=0)
        c.orb("Head", (s * 0.5, 3.6, 2.82), 0.13, colour="Glow")
        c.armor("Head", (s * 0.5, 3.6, 3.0), (0.3, 0.22, 0.1), seg=14, rings=8, colour="Dark", inset=0, rot=E(0, s * -14, 0))
        c.feather("Head", (s * 0.75, 2.4, 3.25), (s * 1.6, 2.0, 3.8), 0.34, colour="MossTop", thick=0.06, bend=V(0, 0, 0.15))
        c.tube("Head", [(s * 0.45, 3.85, 1.85), (s * 0.72, 4.35, 1.95), (s * 0.88, 4.7, 2.45), (s * 0.82, 4.55, 3.05), (s * 0.6, 4.15, 3.35)], [0.25, 0.23, 0.18, 0.11, 0.03], colour="Tusk", seg=12)
        c.tube("Head", [(s * 0.62, 4.15, 1.9), (s * 0.66, 4.22, 1.92)], [0.3, 0.3], colour="Root", seg=10)
    c.rune("Head", (0, 3.55, 3.32), (0, 1, 0.9), 0.3, glyph=2)
    c.anchors["eyes"] = ("Head", V(0, 3.7, 2.82))
    # four stout bark legs on hooves
    for limb, x, y in (("LegFL", -1.1, 1.35), ("LegFR", 1.1, 1.35), ("LegBL", -1.05, -1.35), ("LegBR", 1.05, -1.35)):
        s = 1 if x > 0 else -1
        leg(c, limb, (x, y, 2.05), (x + s * 0.08, y + 0.12, 1.05), (x + s * 0.08, y + 0.05, 0.38), r=(0.56, 0.44, 0.38), colour="Bark", thigh="Bark", foot="hoof", band="Root")
        c.moss(f"{limb}1", (x + s * 0.35, y, 2.25), 0.35, n=5, colour="Moss", seed=3)
    # a short root tail with a leaf tuft
    chain_tube(c, "Tail", [V(0, -2.3, 2.55), V(0, -2.8, 2.4), V(0, -3.1, 2.0)], [0.2, 0.14, 0.08], "Root", "Body", "tail", seg=10)
    for k in range(5):
        a = k / 5 * math.tau
        c.feather("Tail2", (0, -3.1, 2.0), (math.cos(a) * 0.38, -3.5, 1.75 + math.sin(a) * 0.32), 0.16, colour="MossTop", thick=0.04)

# ---------------------------------------------------------------- KEPRI SCARAB: Jewel-Carapace Jade Scarab (Common fast digger; A)
@pet("Kepri Scarab", {"Jade": "#0e6a4e", "JadeTop": "#16a87c", "Dark": "#08281f", "DarkTop": "#0f3d30", "Gold": "#c99a2e", "GoldTop": "#ffe08a",
                      "Quartz": "#e8f6ee", "QuartzTop": "#ffffff", "Leg": "#0b3a2c", "LegTop": "#14614a", "Bone": "#d4a83a", "BoneTop": "#ffe08a",
                      "Crystal": "#3ee8a8", "Glow": "#5dffb8", "Edge": "#a8f0d0", "_noseams": True, "_smooth": ["Jade", "Dark", "Gold", "Leg"]})
def kepri(c):
    c.joint("Body", (0, 0, 1.6))
    # a jewelled scarab (magic/concepts/KepriScarab_s21): split jade wing cases with gold filigree swirls, a heart gem in a gold
    # bezel, crystal winglets, curled gold horns over a quartz drill and six gold-shod legs
    for s in (-1, 1):
        c.armor("Body", (s * 0.6, -0.45, 1.75), (0.82, 1.65, 0.95), seg=24, rings=16, colour="Jade", zmin=-0.2, inset=0, lift=0.04, rot=(0, s * -0.12, 0))
        c.tube("Body", [(s * 1.25, 1.0, 1.6), (s * 1.38, 0.0, 1.85), (s * 1.3, -1.2, 1.7), (s * 0.8, -2.0, 1.4), (s * 0.05, -2.15, 1.35)], [0.06, 0.07, 0.07, 0.06, 0.04], colour="Gold", seg=6)
        c.spiral("Body", (s * 0.72, -0.75, 2.62), (s * 0.35, 0, 1), 0.06, 0.5, turns=1.6, w0=0.03, w1=0.06, colour="Gold", seg=5, start=0 if s > 0 else math.pi)
        c.spiral("Body", (s * 0.62, -1.6, 2.2), (s * 0.3, -0.5, 1), 0.05, 0.3, turns=1.3, w0=0.025, w1=0.05, colour="Gold", seg=5)
        for k in range(3):
            c.gem("Body", (s * (0.95 - 0.1 * k), 0.2 - 0.7 * k, 2.35 - 0.12 * k), 0.09, stretch=(1, 1, 0.7), colour="Glow")
    c.tube("Body", [(0, 0.9, 2.45), (0, 0.0, 2.75), (0, -1.1, 2.55), (0, -1.95, 1.9)], [0.07, 0.08, 0.07, 0.05], colour="Gold", seg=6)
    c.armor("Body", (0, 0.95, 1.65), (1.02, 0.72, 0.72), seg=22, rings=14, colour="Jade", inset=0, lift=0.035)
    c.ring("Body", (0, 1.15, 1.85), 0.88, 0.1, 0.12, 18, normal=(0, 0.6, 0.8), colour="Gold")
    c.armor("Body", (0, -0.3, 1.12), (1.1, 1.7, 0.45), seg=18, rings=12, colour="Dark", inset=0)
    c.gem("Body", (0, 0.62, 2.42), 0.34, stretch=(0.85, 1, 1.25), colour="Glow", rot=E(-55, 0, 0))
    c.ring("Body", (0, 0.6, 2.36), 0.36, 0.09, 0.1, 12, normal=(0, 0.55, 0.84), colour="Gold")
    c.anchors["gem"] = ("Body", V(0, 0.75, 2.5))
    # crystal winglets on their own bones
    for s, w in ((-1, "WingL"), (1, "WingR")):
        root = V(s * 0.55, 0.35, 2.35)
        c.joint(w, tuple(root), "Body", "wing")
        for k, (tx, ty, tz, wd) in enumerate(((2.25, -0.2, 2.95, 0.5), (2.05, -0.95, 2.6, 0.42), (1.6, -1.55, 2.3, 0.32))):
            tip = V(s * tx, ty, tz)
            c.feather(w, root, tip, wd, colour="Crystal", thick=0.03, bend=V(0, 0.15, 0.15), role="Crystal")
            c.tube(w, [root, root.lerp(tip, 0.55) + V(0, 0.1, 0.12), tip], [0.035, 0.03, 0.01], colour="Gold", seg=5)
    # the head: jade dome, glowing eyes, mandibles, two curled gold horns and a fluted quartz drill
    c.joint("Head", (0, 1.45, 1.6), "Body", "head")
    c.armor("Head", (0, 1.78, 1.5), (0.66, 0.52, 0.5), seg=22, rings=14, colour="Jade", inset=0, lift=0.03)
    c.crystal("Head", (0, 2.1, 1.55), (0, 1, 0.22), 1.15, 0.2, colour="Quartz", role="Tex", sides=8)
    c.spiral("Head", (0, 2.15, 1.56), (0, 1, 0.22), 0.2, 0.05, turns=2.4, w0=0.04, w1=0.025, colour="Gold", seg=5, drift=0.95)
    for s in (-1, 1):
        c.orb("Head", (s * 0.42, 2.0, 1.68), 0.11, colour="Glow")
        c.tube("Head", [(s * 0.28, 1.95, 1.9), (s * 0.55, 2.15, 2.45), (s * 0.78, 1.95, 2.95), (s * 0.7, 1.55, 3.1), (s * 0.48, 1.5, 2.88), (s * 0.5, 1.68, 2.72)], [0.11, 0.1, 0.08, 0.06, 0.045, 0.02], colour="Gold", seg=7)
        c.claw("Head", (s * 0.32, 2.05, 1.2), (s * 0.12, 2.55, 1.1), 0.1, colour="Gold", curl=V(-s * 0.2, 0, 0))
        c.tube("Head", [(s * 0.2, 2.1, 1.8), (s * 0.5, 2.6, 2.2), (s * 0.85, 2.8, 2.25)], [0.03, 0.025, 0.015], colour="Gold", seg=4)
        c.orb("Head", (s * 0.87, 2.82, 2.25), 0.06, colour="Glow")
    c.anchors["eyes"] = ("Head", V(0, 2.05, 1.7))
    # six legs (tripod gait names LegL1_ .. LegR3_), jade shins with gold bands, gold claws
    for s in (-1, 1):
        for i, y in enumerate((0.85, 0.05, -0.75)):
            nm = f"Leg{'L' if s < 0 else 'R'}{i + 1}_"
            hip, knee, ank, tip = V(s * 0.85, y, 1.3), V(s * 1.75, y + 0.15 - 0.1 * i, 1.75), V(s * 2.15, y + 0.3 - 0.2 * i, 0.55), V(s * 2.3, y + 0.5 - 0.3 * i, 0.02)
            c.joint(nm + "1", tuple(hip), "Body", "leg")
            c.limb(nm + "1", hip, knee, 0.17, 0.14, seg=6, colour="Leg", bands=1, band_colour="Gold")
            c.joint(nm + "2", tuple(knee), nm + "1", "leg")
            c.limb(nm + "2", knee, ank, 0.14, 0.1, seg=6, colour="Leg", bands=2, band_colour="Jade")
            for k in range(3): c.claw(nm + "2", knee + (ank - knee) * (0.25 + 0.2 * k) + V(s * 0.08, 0, 0.06), knee + (ank - knee) * (0.25 + 0.2 * k) + V(s * 0.32, 0.05, 0.12), 0.045, colour="Gold")
            c.joint(nm + "3", tuple(ank), nm + "2", "leg")
            c.claw(nm + "3", ank, tip, 0.11, colour="Gold", curl=V(s * 0.1, 0.1, 0))


# ---------------------------------------------------------------- SHINEMANE: Prismatic Crystal Lurcher (Uncommon light; A)
@pet("Shinemane", {"Fur": "#1d2c78", "FurTop": "#3150c0", "Dark": "#0d1440", "DarkTop": "#16205e", "Belly": "#3446a8", "BellyTop": "#5a76e6",
                   "Amethyst": "#8b6cf0", "AmethystTop": "#c4b2ff", "Bone": "#bfe6ff", "BoneTop": "#ffffff", "Crystal": "#5ee6ff", "Glow": "#8af4ff",
                   "Edge": "#9ab4ff", "_noseams": True, "_smooth": ["Fur", "FurTop", "Dark", "Belly", "BellyTop"]})
def shinemane(c):
    c.joint("Body", (0, 0, 2.6))
    # a lean indigo crystal fox (magic/concepts/Shinemane_s21): a crown-collar of crystal shards round its neck, tall ears, a
    # big sweeping brush tail tipped with crystals, crystal bracers and glowing starmaps on its flanks
    c.armor("Body", (0, 0.85, 2.78), (0.88, 1.0, 0.98), seg=28, rings=18, colour="Fur", inset=0)
    c.armor("Body", (0, -0.25, 2.66), (0.7, 1.2, 0.74), seg=28, rings=18, colour="Fur", inset=0)
    c.armor("Body", (0, -1.25, 2.66), (0.82, 0.85, 0.86), seg=28, rings=18, colour="Fur", inset=0)
    c.armor("Body", (0, 0.5, 2.2), (0.62, 1.2, 0.5), seg=22, rings=14, colour="Belly", inset=0)
    c.tufts("Body", (0, 1.15, 2.6), (0.78, 0.8, 0.85), n=28, length=0.5, width=0.2, colour="BellyTop", where=lambda n: n.y > 0.35, back=-0.2, droop=0.9, seed=11, solid=True)
    for s in (-1, 1):
        stars = [V(s * 0.76, 0.1, 2.9), V(s * 0.72, -0.35, 2.6), V(s * 0.76, -0.8, 2.85), V(s * 0.84, -1.25, 2.55), V(s * 0.66, -0.4, 3.12)]
        for q in stars: c.orb("Body", q + V(s * 0.05, 0, 0), 0.065, colour="Glow")
        for a, b in ((0, 1), (1, 2), (2, 3), (1, 4)):
            c.tube("Body", [stars[a] + V(s * 0.04, 0, 0), stars[b] + V(s * 0.04, 0, 0)], [0.02, 0.02], colour="Glow", seg=4, role="Glow")
    # neck, the crystal collar and the head
    c.joint("Neck", (0, 1.3, 3.0), "Body", "neck")
    c.limb("Neck", (0, 1.2, 2.85), (0, 1.85, 3.8), 0.5, 0.38, seg=16, colour="Fur", bands=0, facets=False)
    N0 = V(0, 1.55, 3.32)
    for k in range(18):
        a = k / 18 * math.tau
        out = V(math.cos(a), -0.3, math.sin(a) * 0.95 + 0.2).normalized()
        L = 0.75 + 0.45 * (0.5 + 0.5 * math.sin(a)) + (0.2 if k % 2 else 0)
        col, role = ("Crystal", "Crystal") if k % 3 else ("Amethyst", "Tex")
        c.crystal("Neck", N0 + out * 0.42, out, L, 0.14 if k % 2 else 0.1, colour=col, role=role)
    c.anchors["mane"] = ("Neck", N0)
    c.joint("Head", (0, 1.85, 3.8), "Neck", "head")
    c.armor("Head", (0, 2.15, 4.0), (0.58, 0.62, 0.52), seg=26, rings=16, colour="Fur", inset=0)
    c.limb("Head", (0, 2.45, 3.92), (0, 3.25, 3.74), 0.3, 0.12, seg=14, colour="Fur", bands=0, facets=False)
    c.limb("Head", (0, 2.45, 3.74), (0, 3.05, 3.62), 0.22, 0.09, seg=12, colour="BellyTop", bands=0, facets=False)
    c.armor("Head", (0, 3.27, 3.76), (0.09, 0.07, 0.07), seg=12, rings=8, colour="Dark", inset=0)
    c.crystal("Head", (0, 2.45, 4.42), (0, 0.4, 1), 0.5, 0.1, colour="Crystal")
    for s in (-1, 1):
        c.gem("Head", (s * 0.32, 2.66, 4.1), 0.12, stretch=(1.5, 0.6, 0.85), colour="Glow", rot=E(0, 0, s * 25))
        c.segment("Head", (s * 0.28, 2.02, 4.3), (s * 0.62, 1.86, 5.35), 0.52, 0.06, colour="Fur", depth=0.32, bevel=0.2)
        c.segment("Head", (s * 0.29, 2.1, 4.35), (s * 0.57, 1.98, 5.12), 0.3, 0.04, colour="Amethyst", depth=0.2, bevel=0.2)
        c.tufts("Head", (s * 0.48, 2.3, 3.82), (0.2, 0.3, 0.25), n=6, length=0.38, width=0.14, colour="BellyTop", where=lambda n, s=s: n.x * s > 0.3, back=0.9, seed=13 + s, solid=True)
    c.anchors["eyes"] = ("Head", V(0, 2.7, 4.1))
    # slender legs with crystal bracers and icy claws
    for limb, x, y, z, kn, an in (("LegFL", -0.48, 1.0, 2.3, 1.15, 1.0), ("LegFR", 0.48, 1.0, 2.3, 1.15, 1.0), ("LegBL", -0.52, -1.3, 2.4, -1.0, -1.55), ("LegBR", 0.52, -1.3, 2.4, -1.0, -1.55)):
        s = 1 if x > 0 else -1
        leg(c, limb, (x, y, z), (x + s * 0.04, kn, 1.3), (x + s * 0.04, an, 0.38), r=(0.32, 0.22, 0.17), colour="Fur", thigh="Fur", claws=3, toe=0.3)
        c.crystal(f"{limb}2", (x + s * 0.18, (kn + an) / 2, 0.85), (s * 0.6, -0.3, 0.75), 0.45, 0.08, colour="Crystal")
        c.crystal(f"{limb}2", (x + s * 0.15, (kn + an) / 2 + 0.15, 0.65), (s * 0.7, -0.2, 0.5), 0.3, 0.06, colour="Amethyst", role="Tex")
    # the brush tail: four bones sweeping up and back into a big plume, solid fur clumps, a crown of crystals at the tip
    pts = [V(0, -1.95, 2.95), V(0, -2.7, 3.3), V(0, -3.35, 3.85), V(0, -3.6, 4.55), V(0, -3.4, 5.2)]
    names = chain_tube(c, "Tail", pts, [0.22, 0.38, 0.5, 0.46, 0.2], "Fur", "Body", "tail", seg=16)
    for i, nm in enumerate(names):
        a, b = pts[i], pts[i + 1]
        r = 0.22 + 0.16 * i if i < 3 else 0.5
        c.armor(nm, tuple(a.lerp(b, 0.5)), (r, (b - a).length * 0.7, r), seg=22, rings=14, colour="Fur" if i < 2 else "FurTop", rot=look(b - a), inset=0)
        c.tufts(nm, tuple(a.lerp(b, 0.5)), (r, (b - a).length * 0.6, r), n=8 + 3 * i, length=0.4 + 0.08 * i, width=0.2, colour="FurTop" if i % 2 else "BellyTop", back=0.9, droop=-0.3, seed=20 + i, solid=True)
    c.cluster("Tail4", pts[4], (0, 0.2, 1), 0.85, n=6, colour="Crystal", seed=9)
    c.anchors["tail"] = ("Tail4", pts[4] + V(0, 0, 0.5))

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
