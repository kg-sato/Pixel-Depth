"""Named NPCs as hi-detail voxel characters (Master Directive v17, 2026-11-26; built 2026-11-27): the pets' own pipeline
(design3d/pets/vox_kit.py + plate_kit.py, cell 0.1 studs, form shading, no smooth blobs), so they share the rig loader
(Shared.PetVoxels builds and animates them from Shared.PetRigData) and Shared.CharRigs stands them in for the part-built
placeholders. Blender axes: x right, y forward (the face), z up; feet at z 0.
    blender -b -P design3d/chars/npcs_vox.py -- <out_dir> [Name ...]
Writes <Name>.glb and merges the rig data into design3d/pets/rigs.json (make_rig_lua.py then writes Shared.PetRigData)."""
import json, math, os, sys
here = os.path.dirname(os.path.abspath(__file__))
pets = os.path.join(os.path.dirname(here), "pets")
sys.path.insert(0, pets)
import plate_kit as K
import vox_kit as X
from plate_kit import V
import pet_vox as P  # its helpers (palette, shade, E, surf, foot_paw, ground); its own pets build only when run directly

args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = os.path.abspath(args[0] if args else os.path.join(here, "out_vox"))
ONLY = set(a for a in args[1:] if not a.startswith("-"))
os.makedirs(OUT, exist_ok=True)
D = {}


def char(name, pal):
    def deco(fn): D[name] = (pal, fn); return fn
    return deco


# ---------------------------------------------------------------- BOLT: the raccoon master smith (the Forge)
@char("Bolt", P.palette(form=("Fur", "Shirt", "Apron"), Fur="#8d8a9c", FurDark="#4a4656", Mask="#25212c", White="#eeedf3", Shirt="#3a4790",
                        Apron="#e6cb92", Strap="#8a5a34", Iron="#5c5e6c", Brass="#d9a843", Pink="#b04a52", Blush="#e88a9a", Glow="#ff9a36", Nose="#18131c",
                        Claw="#d8d0c4", Ember="#ff5a1e", Crystal="#ffb050", Edge="#b8b0c8", Eye="#1a1020", Iris="#ffb43a", IronLo="#3e404c"))
def bolt(v):
    E = P.E
    v.joint("Body", (0, 0, 2.05))
    # a broad husky smith: a barrel chest in a rolled-sleeve indigo shirt, a cream leather apron with an iron buckle and straps
    v.muscle("Body", "Shirt", (0, 0.05, 3.05), (1.05, 0.78, 0.82))
    v.muscle("Body", "Shirt", (0, 0.0, 2.35), (0.92, 0.72, 0.62))
    for s in (-1, 1): v.muscle("Body", "Shirt", (s * 0.78, 0.0, 3.4), (0.48, 0.5, 0.42))  # the shoulder masses
    v.muscle("Body", "FurDark", (0, -0.05, 1.75), (0.82, 0.62, 0.42))  # the hips
    P.shade(v, "Shirt")
    # round 3 (Gemini: "a paper-thin plate"): the apron wraps the barrel chest: a thick curved bib, a skirt that flares, side panels
    v.ell("Body", "Apron", (0, 0.64, 2.6), (0.88, 0.4, 1.05), cut=lambda x, y, z: y < 0.62)  # round 4: proud of the chest, so the bib shows
    v.ell("Body", "Apron", (0, 0.5, 1.5), (1.0, 0.38, 0.62), cut=lambda x, y, z: y < 0.48 or z > 1.95)
    for s2 in (-1, 1): v.box("Body", "ApronLo", (s2 * 0.86, 0.38, 1.9), (0.14, 0.5, 1.3))
    v.paint("ApronLo", lambda x, y, z: z < 1.25 or abs(x) > 0.66, part="Body", only={"Apron"})
    for z in (2.1, 1.3): v.box("Body", "Strap", (0, 0.86, z), (1.5, 0.08, 0.1))  # stitched seams
    v.box("Body", "Iron", (0, 0.86, 3.05), (0.46, 0.14, 0.34))  # the buckle
    v.box("Body", "Brass", (0, 0.94, 3.05), (0.26, 0.08, 0.16))
    for s in (-1, 1):
        v.curve("Body", "Strap", [(s * 0.55, 0.72, 3.2), (s * 0.72, 0.45, 3.7), (s * 0.55, -0.2, 3.75), (s * 0.35, -0.62, 2.9)], [0.07, 0.07, 0.07, 0.07])
        v.box("Body", "ApronLo", (s * 0.5, 0.95, 1.55), (0.5, 0.12, 0.42))  # a pocket
        if s > 0: v.box("Body", "Iron", (s * 0.62, 1.0, 1.8), (0.16, 0.1, 0.55))  # a file in it (round 9: the tongs moved to the off paw)
    v.box("Body", "Strap", (0, 0.05, 1.98), (1.7, 1.38, 0.16))  # the belt
    for s in (-1, 1):  # round 8: a crossed tool harness on the back, and a hammer loop pouch at the belt
        v.curve("Body", "Strap", [(s * 0.62, -0.62, 3.65), (s * 0.2, -0.86, 3.0), (-s * 0.3, -0.84, 2.45), (-s * 0.6, -0.7, 2.05)], [0.08, 0.08, 0.08, 0.08])
    v.box("Body", "Iron", (0, -0.9, 2.85), (0.22, 0.1, 0.22))
    v.box("Body", "ApronLo", (0.55, -0.78, 1.82), (0.42, 0.2, 0.4))
    v.box("Body", "Brass", (0.55, -0.9, 1.92), (0.12, 0.06, 0.1))
    v.box("Body", "Brass", (0, 0.72, 1.98), (0.26, 0.08, 0.2))
    for s in (-1, 1): v.ell("Body", "Strap", (s * 0.62, -0.05, 3.72), (0.5, 0.62, 0.14), rot=E(0, s * 16, 0))  # round 9: a leather yoke over each shoulder (Gemini r8: the torso a blue blob from the town camera)
    v.box("Body", "Brass", (0, -0.72, 3.7), (0.3, 0.08, 0.12))  # its back clasp
    v.anchor("chest", "Body", (0, 0.8, 3.0))
    # the head: a big raccoon head, grey fur, a dark bandit mask round amber eyes, white cheek tufts and muzzle, notched ears
    v.joint("Head", (0, 0.1, 3.85), "Body", "head")
    v.muscle("Head", "Fur", (0, 0.05, 4.65), (0.98, 0.86, 0.82))
    v.muscle("Head", "Fur", (0, 0.35, 4.45), (0.8, 0.72, 0.62))
    P.shade(v, "Fur", parts={"Head"})
    for s in (-1, 1):
        v.ell("Head", "White", (s * 0.62, 0.55, 4.3), (0.42, 0.34, 0.32))  # cheek tufts
        for k in range(3): v.crystal("Head", "White", V(s * (0.8 + 0.08 * k), 0.45 - 0.12 * k, 4.18 + 0.12 * k), (s * 1, -0.2, -0.3), 0.32, 0.12, sides=4)
        v.ell("Head", "Mask", (s * 0.4, 0.78, 4.78), (0.36, 0.2, 0.24), rot=E(0, 0, s * -14))  # the mask band over each eye
        v.ell("Head", "Edge", (s * 0.37, 0.9, 4.8), (0.26, 0.06, 0.24))  # round 8: a pale rim so the eye reads against the mask
        v.eye("Head", (s * 0.37, 0.92, 4.8), (s * 0.35, 1, 0.12), w=0.34, h=0.32, iris="Iris")  # round 2: bigger, so the face reads from the town camera
        v.ell("Head", "Blush", (s * 0.62, 0.86, 4.42), (0.13, 0.05, 0.08))  # blush
        # notched ears with dark backs and pale insides
        v.ell("Head", "FurDark", (s * 0.6, -0.05, 5.5), (0.3, 0.16, 0.36), rot=E(0, s * -18, 0))
        v.ell("Head", "White", (s * 0.6, 0.06, 5.48), (0.18, 0.06, 0.24), rot=E(0, s * -18, 0))
    v.box("Head", "Mask", (0, 0.86, 4.8), (0.4, 0.12, 0.16))  # the mask's bridge
    v.ell("Head", "FurHi", (0, 0.72, 5.0), (0.62, 0.22, 0.14))  # round 6: a brow ridge one voxel proud over the mask
    v.ell("Head", "White", (0, 0.95, 4.38), (0.42, 0.38, 0.3))  # the muzzle
    v.ell("Head", "Nose", (0, 1.3, 4.5), (0.15, 0.1, 0.11))
    v.box("Head", "FurDark", (0, 1.2, 4.2), (0.24, 0.05, 0.05))  # the mouth line
    v.box("Head", "FurDark", (0, 0.4, 5.2), (0.2, 0.5, 0.2))  # a dark stripe up the brow
    for k in range(5): v.crystal("Body", "White", V(-0.3 + 0.15 * k, 0.55, 3.72), (0, 0.4, 1), 0.22, 0.08, sides=4)  # chest fur at the collar
    # the pink headband with brass smith goggles pushed up on it
    v.torus("Head", "Pink", (0, 0.02, 5.08), (0, 0, 1), 0.86, 0.09)
    for s in (-1, 1):
        v.torus("Head", "Brass", (s * 0.27, 0.78, 5.22), (0, 0.85, 0.5), 0.2, 0.06)
        v.ell("Head", "Crystal", (s * 0.27, 0.82, 5.24), (0.13, 0.04, 0.13))
    v.box("Head", "Brass", (0, 0.84, 5.22), (0.18, 0.06, 0.06))
    v.anchor("eyes", "Head", (0, 0.95, 4.8)); v.anchor("speech", "Head", (0, 0.0, 5.9))
    # arms: indigo sleeves rolled to the elbow (a cream cuff), grey furred forearms, dark paws; the right paw holds a forge hammer
    for s, A in ((-1, "ArmL"), (1, "ArmR")):
        sh, el, wr = V(s * 1.05, 0.05, 3.45), (V(s * 1.9, 0.1, 3.05) if s > 0 else V(s * 1.85, 0.25, 2.95)), (V(s * 2.45, 0.2, 3.65) if s > 0 else V(s * 2.4, 0.45, 3.5))  # round 12: the off paw raised too, showing the hot ingot (r11: the lowered tongs clumped with the tail)  # round 3: arms clear of the body; the right one raises the hammer
        v.joint(A + "1", tuple(sh), "Body", "arm")
        v.cap(A + "1", "Shirt", sh, el, 0.42, 0.35)  # round 2: heavier smith's arms
        v.torus(A + "1", "Apron", el + (sh - el) * 0.12, (sh - el).normalized(), 0.31, 0.07)
        P.shade(v, "Shirt", parts={A + "1"})
        v.joint(A + "2", tuple(el), A + "1", "arm")
        v.cap(A + "2", "Fur", el, wr, 0.33, 0.27)
        v.ell(A + "2", "Mask", wr + V(0, 0.08, -0.08), (0.24, 0.24, 0.22))
        bm = el.lerp(wr, 0.62)
        v.torus(A + "2", "Brass", bm, (wr - el).normalized(), 0.3, 0.09)  # round 6: a brass forge bracer with a glowing rune line
        v.torus(A + "2", "Glow", el.lerp(wr, 0.5), (wr - el).normalized(), 0.31, 0.035)
        for k in (-1, 0, 1): v.crystal(A + "2", "Claw", wr + V(k * 0.09, 0.2, -0.16), (0, 0.6, -1), 0.14, 0.05, sides=4)
        P.shade(v, "Fur", parts={A + "2"})
        v.anchor("hand" + A[3:], A + "2", wr + V(0, 0.15, -0.1))
    hand = V(2.45, 0.4, 3.6)  # round 8: in the raised paw (round 7 moved the wrist)
    # round 2 (the hammer read as a small yellow block): a heavy smith's hammer resting on the shoulder line, a long haft, a
    # stepped iron head with a glowing ember striking face and a brass collar
    up = E(0, 18, 0)  # the haft leans out a little
    v.box("ArmR2", "Strap", hand + V(0.18, 0.0, 0.7), (0.18, 0.18, 1.7), rot=up)
    v.box("ArmR2", "Iron", hand + V(0.45, 0.0, 1.55), (1.0, 0.5, 0.5), rot=up)
    v.box("ArmR2", "IronLo", hand + V(0.45, 0.0, 1.55), (1.08, 0.38, 0.38), rot=up)
    v.box("ArmR2", "Glow", hand + V(1.0, 0.0, 1.38), (0.1, 0.42, 0.42), rot=up)  # the glowing striking face
    v.box("ArmR2", "Ember", hand + V(1.04, 0.0, 1.37), (0.06, 0.28, 0.28), rot=up)
    v.box("ArmR2", "Brass", hand + V(0.33, 0.0, 1.22), (0.28, 0.28, 0.14), rot=up)
    v.box("ArmR2", "Brass", hand + V(0.0, 0.0, -0.1), (0.24, 0.24, 0.16), rot=up)  # the pommel
    v.anchor("hammer", "ArmR2", hand + V(1.05, 0.0, 1.4))
    # round 9: forge tongs in the off paw, jaws angled down and out, a glowing ingot in their grip (r8: the flank read as one bulge)
    lh = V(-2.42, 0.62, 3.45)
    td = V(-0.55, 0.22, 0.8).normalized()  # up and out, a V with the hammer
    sd = td.cross(V(0, 1, 0)).normalized()
    for k in (-1, 1):  # round 13: real tongs (r12: "an ambiguous glowing bar"): leather grips in the paw, iron reins, a hinge, jaws that open round the ingot
        v.cap("ArmL2", "Strap", lh - td * 0.25 + sd * (k * 0.1), lh + td * 0.35 + sd * (k * 0.1), 0.1, 0.1)
        v.cap("ArmL2", "Iron", lh + td * 0.35 + sd * (k * 0.1), lh + td * 0.95 + sd * (k * 0.06), 0.09, 0.09)
        v.cap("ArmL2", "IronLo", lh + td * 0.95 + sd * (k * 0.06), lh + td * 1.45 + sd * (k * 0.3), 0.1, 0.08)
    v.ell("ArmL2", "Brass", lh + td * 0.95, (0.14, 0.14, 0.14))  # the hinge pin
    ing = lh + td * 1.58
    v.box("ArmL2", "Ember", ing, (0.5, 0.36, 0.3))  # a red-hot ingot, wider than the jaws
    v.box("ArmL2", "Glow", ing + V(0, 0.02, 0.08), (0.36, 0.3, 0.16))
    # stout legs in dark trousers, big paws
    for s, L in ((-1, "LegL"), (1, "LegR")):
        hip, knee, foot = V(s * 0.52, 0.0, 1.62), V(s * 0.64, 0.28, 0.82), V(s * 0.76, 0.14, 0.0)  # round 11: a wider smith's stance, a gap between the boots  # round 8: a bent knee
        v.joint(L + "1", tuple(hip), "Body", "leg")
        v.cap(L + "1", "FurDark", hip, knee, 0.38, 0.32)
        v.joint(L + "2", tuple(knee), L + "1", "leg")
        v.cap(L + "2", "FurDark", knee, foot + V(0, 0, 0.2), 0.3, 0.22)  # tapers to the ankle
        v.ell(L + "2", "Mask", foot + V(0, 0.16, 0.17), (0.36, 0.44, 0.19))  # round 9: a domed paw, not a slab
        v.torus(L + "2", "Strap", foot + V(0, 0.04, 0.62), (0, 0, 1), 0.3, 0.08)  # round 13: a leather boot cuff at the ankle
        v.torus(L + "2", "Brass", foot + V(0, 0.04, 0.5), (0, 0, 1), 0.27, 0.04)
        for k in (-1, 0, 1): v.ell(L + "2", "Mask", foot + V(k * 0.17, 0.52, 0.12), (0.11, 0.12, 0.12))  # three toes
        for k in (-1, 0, 1): v.crystal(L + "2", "Claw", foot + V(k * 0.17, 0.62, 0.08), (0, 1, -0.3), 0.1, 0.045, sides=4)
        v.anchor("foot" + L[3:], L + "2", foot + V(0, 0.2, 0.1))
    # the banded tail: two bones, thick and curled up behind, dark rings on grey
    tp = [V(-0.3, -0.6, 1.75), V(-1.3, -1.15, 1.3), V(-2.6, -1.0, 1.35), V(-3.5, -0.8, 1.9), V(-3.75, -0.6, 2.6)]  # round 12: a low curl under the raised off arm; round 11 rose past the tongs  # round 11: the curl rises past the tongs to above the shoulder, so the blackout shows it (r9 graders: the tail hid behind the off arm)  # round 8: the tip a little further out and back; round 7: flared out to the side so it reads from the front (round 6 hid it behind the body)  # round 5: farther out and back, clear of the leg (Gemini: the tail clumped into the hip in the blackout)
    for i, (a, b2, nm) in enumerate(((0, 2, "Tail1"), (2, 4, "Tail2"))):
        v.joint(nm, tuple(tp[a]), "Body" if i == 0 else "Tail1", "tail")
        v.tube(nm, "Fur", tp[a:b2 + 1], [0.3, 0.5, 0.56][:b2 - a + 1] if i == 0 else [0.56, 0.42, 0.14])
    for k in range(5):
        t = (k + 0.5) / 5
        seg = int(t * 4); u = t * 4 - seg
        c = tp[seg].lerp(tp[seg + 1], u); d = (tp[seg + 1] - tp[seg]).normalized()
        v.torus("Tail1" if seg < 2 else "Tail2", "Mask", c, d, [0.46, 0.55, 0.54, 0.44, 0.3][k], 0.1)
    for k in range(9):  # round 9: tufts notched along the outer edge, so the side view is fur and not an extrusion
        t = 0.12 + k * 0.095; seg = min(int(t * 4), 3); u = t * 4 - seg
        c = tp[seg].lerp(tp[seg + 1], u); d = (tp[seg + 1] - tp[seg]).normalized()
        out = d.cross(V(0, 0, 1)).normalized() * (1 if k % 2 else -1) + V(0, 0, 0.6)
        v.crystal("Tail1" if seg < 2 else "Tail2", "Fur", c + out.normalized() * [0.3, 0.45, 0.52, 0.52, 0.5, 0.44, 0.36, 0.28, 0.18][k], tuple(out), 0.22, 0.09, sides=4)
    v.ell("Tail2", "Edge", tp[4] + (tp[4] - tp[3]).normalized() * 0.05, (0.16, 0.16, 0.2))  # a pale tip
    v.anchor("tail", "Tail2", tp[4])
    P.ground(v)



# ---------------------------------------------------------------- MARIBEL: the hatchery keeper (the Egg Hatchery)
# a lop-eared rabbit (2026-11-27: the brief leaves the species open; the town's named folk are creatures like Bolt) in a layered
# mint-and-lavender hooded cloak with a scalloped trim and a brass egg clasp, a wide-brimmed botanist hat with glowing crystal
# feathers, cradling a woven straw nest with a softly glowing spotted egg
@char("Maribel", dict(P.palette(form=("Fur", "Cloak", "Cape"), Fur="#f2e4d4", FurDark="#c8ad94", White="#fffaf2", Cloak="#86dcb8", CloakDark="#4f9f86",
                           Cape="#b9a6ec", CapeDark="#7d68c0", Trim="#fff1d6", Hat="#5d4a8e", HatDark="#3c2f62", Band="#86dcb8", Brass="#e0b04a",
                           Straw="#c48c3e", StrawDark="#7a4c1c", Egg="#b4f4ff", Spot="#6a44d0", Glow="#bdf4ff", Crystal="#9ff0ff", Pink="#f4b2c6",
                           Blush="#f39ab4", Nose="#d86a8a", Eye="#1c1230", Iris="#4a2c8a", Shine="#ffffff", Boot="#6a4a3a"), FurLo="#dcc4ae", FurLoTop="#e2cab4", FurCrease="#bf9f86", FurCreaseTop="#c6a78e"))  # m5: warm face shading (the cool Lo read olive)
def maribel(v):
    E = P.E
    v.joint("Body", (0, 0, 1.9))
    # the cloak: a bell that flares to the ground, mint, in two tiers, with a lavender capelet over the shoulders
    v.muscle("Body", "Cloak", (0, 0, 1.1), (1.15, 1.0, 1.0), cut=lambda x, y, z: z >= 0.12)
    v.muscle("Body", "Cloak", (0, 0, 2.3), (0.9, 0.78, 0.85))
    P.shade(v, "Cloak")
    v.ell("Body", "Cloak", (0, 0, 0.55), (1.42, 1.24, 0.6), cut=lambda x, y, z: z >= 0.12)  # m3: the skirt flares at the hem
    for k in range(18):  # the scalloped hem: a ring of cream scallops round the cloak's foot
        a = k / 18 * math.tau
        v.ell("Body", "Trim", (math.cos(a) * 1.4, math.sin(a) * 1.22, 0.3), (0.27, 0.27, 0.2))
    v.ell("Body", "CloakDark", (0, 0.92, 1.0), (0.12, 0.1, 0.8))  # the front seam
    v.carve(lambda x, y, z: 1.92 < z < 2.22 and (x / 0.84) ** 2 + (y / 0.74) ** 2 > 1, part="Body")  # m7: a nipped waist (m6: a blocky slab from chest to skirt)
    v.torus("Body", "CapeDark", (0, 0.0, 2.07), (0, 0, 1), 0.8, 0.1)  # a sash in the notch
    v.ell("Body", "Trim", (0, 1.06, 1.15), (0.62, 0.3, 0.72), cut=lambda x, y, z: y >= 1.04)  # m7: a cream apron panel breaks the bell
    v.box("Body", "CapeDark", (0, 1.34, 1.05), (0.36, 0.06, 0.24))  # its pocket
    v.ell("Body", "Cape", (0, -0.05, 2.75), (1.12, 0.98, 0.62), cut=lambda x, y, z: z >= 2.35)
    P.shade(v, "Cape")
    v.torus("Body", "CapeDark", (0, -0.05, 2.42), (0, 0, 1), 1.06, 0.1)  # m6: a dark border, so the capelet parts from the mint skirt
    for k in range(12):  # the capelet's scalloped edge
        a = k / 12 * math.tau
        v.ell("Body", "Trim", (math.cos(a) * 1.08, math.sin(a) * 0.95, 2.3), (0.2, 0.2, 0.14))
    v.torus("Body", "Brass", (0, 0.9, 3.0), (0, 1, 0.2), 0.2, 0.06)  # the brass egg clasp
    v.ell("Body", "Egg", (0, 0.95, 3.0), (0.13, 0.08, 0.17))
    # the hood falls in folds down her back, under the hat
    v.ell("Body", "HatDark", (0, -0.78, 3.25), (0.78, 0.36, 0.62))  # m10: the hood in the hat's deep plum, apart from the lavender cape from behind
    v.ell("Body", "Hat", (0, -0.86, 3.4), (0.62, 0.3, 0.46))
    v.ell("Body", "White", (0, -1.28, 0.95), (0.34, 0.3, 0.32))  # a cotton tail peeking out of the cloak
    for s in (-1, 1):  # m3: a big lavender bow at the small of the back, its ribbons down the skirt
        v.ell("Body", "CapeDark", (s * 0.42, -1.02, 2.12), (0.38, 0.16, 0.24), rot=E(0, s * -20, 0))
        v.ell("Body", "Cape", (s * 0.42, -1.08, 2.14), (0.3, 0.12, 0.18), rot=E(0, s * -20, 0))
        v.cap("Body", "Cape", V(s * 0.12, -1.0, 2.0), V(s * 0.45, -1.22, 1.15), 0.1, 0.12)
    v.ell("Body", "Brass", (0, -1.08, 2.1), (0.14, 0.1, 0.14))
    v.anchor("chest", "Body", (0, 0.9, 2.9))
    # the head: a round rabbit head, cream fur, white muzzle, big violet eyes, long lop ears hanging past the cheeks
    v.joint("Head", (0, 0.05, 3.45), "Body", "head")
    v.muscle("Head", "Fur", (0, 0.05, 4.3), (0.92, 0.84, 0.8))
    v.muscle("Head", "Fur", (0, 0.32, 4.1), (0.74, 0.66, 0.6))
    P.shade(v, "Fur", parts={"Head"})
    v.ell("Head", "White", (0, 0.98, 3.98), (0.42, 0.36, 0.32))  # the muzzle, a step forward (m5)
    v.ell("Head", "Nose", (0, 1.3, 4.14), (0.13, 0.08, 0.09))
    v.box("Head", "FurDark", (0, 1.3, 3.9), (0.05, 0.05, 0.16))  # the mouth line
    for s in (-1, 1):
        v.box("Head", "FurDark", (s * 0.1, 1.3, 3.82), (0.16, 0.05, 0.05))
        v.eye("Head", (s * 0.38, 0.86, 4.42), (s * 0.35, 1, 0.1), w=0.4, h=0.48, iris="Iris")
        v.ell("Head", "Blush", (s * 0.6, 0.78, 4.08), (0.15, 0.06, 0.09))
        for k in range(3): v.crystal("Head", "White", V(s * (0.82 + 0.06 * k), 0.45 - 0.1 * k, 4.0 + 0.1 * k), (s * 1, -0.1, -0.2), 0.26, 0.1, sides=4)  # cheek fluff
        # a lop ear: from the crown over the hat brim, falling down the side of the face past the jaw
        ear = [V(s * 0.5, -0.05, 4.95), V(s * 1.4, 0.0, 5.0), V(s * 2.2, 0.1, 4.7), V(s * 2.75, 0.16, 4.2)]  # m10: tips further out from the cheeks  # m5: the tips sweep out like wings, clear of the shoulders  # m4: wide wing ears out past the brim (m3 graders: ears hidden in the blackout)  # m3: flared out past the cheeks, so the blackout shows them
        v.tube("Head", "Fur", ear, [0.24, 0.32, 0.36, 0.26])
        v.tube("Head", "Pink", [e + V(s * -0.12, 0.2, 0) for e in ear[1:]], [0.14, 0.17, 0.1])  # the pale inside, turned to the front
        v.ell("Head", "FurDark", ear[3] + V(0, 0, -0.08), (0.2, 0.2, 0.12))  # a darker tip
    v.anchor("eyes", "Head", (0, 0.9, 4.42)); v.anchor("speech", "Head", (0, 0.0, 6.3))
    # the hat: a wide soft brim (the silhouette), a tall plum crown, a mint band, glowing crystal feathers and an egg charm
    tilt = E(16, 0, 0)  # m4: the brim tips up at the front, off the eyes and open to the town camera (m3: a flat slab shading the face)
    v.ell("Head", "Hat", (0, 0.0, 5.12), (1.42, 1.32, 0.18), rot=tilt)
    v.ell("Head", "HatDark", (0, 0.0, 5.0), (1.36, 1.26, 0.1), rot=tilt)
    v.torus("Head", "HatDark", (0, 0.0, 5.2), (0, -0.28, 0.96), 1.38, 0.15)  # the brim's thick rolled edge
    v.muscle("Head", "Hat", (0, -0.05, 5.62), (0.72, 0.66, 0.62), cut=lambda x, y, z: z >= 5.1)
    v.ell("Head", "Hat", (0.1, -0.15, 6.12), (0.42, 0.4, 0.34), rot=E(0, 14, 0))  # the crown flops a little to one side
    v.crystal("Head", "Hat", V(0.2, -0.2, 6.3), (0.45, -0.35, 1), 0.75, 0.24, sides=5)  # m9: a pointed tip bending back (graders: sharpen the hat cone)
    v.torus("Head", "Band", (0, -0.05, 5.32), (0, 0, 1), 0.72, 0.12)
    for k, (dx, dy, L) in enumerate(((0.45, -0.35, 0.95), (0.62, -0.12, 0.75), (0.3, -0.55, 0.62))):  # crystal feathers tucked in the band
        v.crystal("Head", "Crystal", V(dx, dy, 5.35), (0.35 + 0.1 * k, -0.25, 1), L, 0.13, sides=4)
        v.crystal("Head", "Glow", V(dx, dy, 5.35), (0.35 + 0.1 * k, -0.25, 1), L * 0.55, 0.07, sides=4)
    v.ell("Head", "Egg", (-0.55, 0.45, 5.34), (0.13, 0.11, 0.16))  # an egg charm on the band
    v.ell("Head", "Spot", (-0.55, 0.56, 5.36), (0.05, 0.03, 0.05))
    # arms: cloak sleeves with cream cuffs, cream paws, both cradling the nest in front of the belly
    nest = V(0, 2.75, 1.95)  # m9: further out and lower, daylight between nest, arms and body (7.0 from both graders; m10's 3.0 read as stiff arms)  # m4: held out in front, a gap under the arms (m3: the prop merged with the body)
    for s, A in ((-1, "ArmL"), (1, "ArmR")):
        sh, el, wr = V(s * 0.95, 0.15, 2.95), V(s * 1.55, 1.2, 2.2), V(s * 1.0, 2.55, 2.0)  # m5: elbows out, a window between arms and body
        v.joint(A + "1", tuple(sh), "Body", "arm")
        v.cap(A + "1", "Cape", sh, el, 0.34, 0.3)
        v.joint(A + "2", tuple(el), A + "1", "arm")
        v.cap(A + "2", "Cloak", el, wr, 0.3, 0.32)
        v.torus(A + "2", "Trim", wr + (el - wr).normalized() * 0.08, (wr - el).normalized(), 0.3, 0.08)
        v.ell(A + "2", "Fur", wr + V(-s * 0.05, 0.1, -0.05), (0.22, 0.2, 0.2))
        v.anchor("hand" + A[3:], A + "2", wr)
    # the nest: a woven straw bowl with a twisted rim and loose straws, a glowing spotted egg in it
    v.ell("ArmR2", "Straw", nest, (0.82, 0.66, 0.4), cut=lambda x, y, z: z <= nest.z + 0.12)
    v.torus("ArmR2", "StrawDark", nest + V(0, 0, 0.12), (0, 0, 1), 0.76, 0.11)
    for k in range(10):
        a = k / 10 * math.tau
        v.crystal("ArmR2", "Straw" if k % 2 else "StrawDark", nest + V(math.cos(a) * 0.62, math.sin(a) * 0.5, 0.1), (math.cos(a), math.sin(a), 0.5), 0.3, 0.05, sides=4)
    for k in range(4): v.ell("ArmR2", "StrawDark", nest + V(-0.5 + k * 0.33, 0.0, -0.1), (0.06, 0.55, 0.06), rot=E(0, 0, 30 * (k % 2 * 2 - 1)))  # the weave
    egg = nest + V(0, 0.0, 0.5)
    v.ell("ArmR2", "Egg", egg, (0.36, 0.32, 0.46))
    v.ell("ArmR2", "Glow", tuple(egg + V(0.1, 0.18, 0.12)), (0.14, 0.12, 0.16))  # m10: a lit side, so the egg glows against the sleeves
    for d in ((0.2, 0.25, 0.12), (-0.18, 0.26, -0.05), (0.05, 0.3, 0.28), (0.3, 0.05, -0.1), (-0.3, 0.02, 0.18)):
        v.ell("ArmR2", "Spot", egg + V(*d), (0.08, 0.05, 0.08))
    v.anchor("egg", "ArmR2", egg)
    # little boots peeking under the hem
    for s, L in ((-1, "LegL"), (1, "LegR")):
        hip, foot = V(s * 0.42, 0.1, 0.9), V(s * 0.6, 1.2, 0.0)  # m6: the toes well past the hem
        v.joint(L + "1", tuple(hip), "Body", "leg")
        v.cap(L + "1", "Fur", hip, foot + V(0, -0.3, 0.18), 0.26, 0.22)
        v.ell(L + "1", "Fur", foot + V(0, 0.25, 0.15), (0.3, 0.55, 0.17))  # m5: long rabbit feet out under the hem
        for k in (-1, 0, 1): v.ell(L + "1", "FurLo", foot + V(k * 0.12, 0.74, 0.1), (0.09, 0.1, 0.1))
        v.anchor("foot" + L[3:], L + "1", foot + V(0, 0.2, 0.1))
    P.ground(v)



# ---------------------------------------------------------------- WICK: the elder glowworm (Camp 1, by the rail station)
# a chubby ringed mint-jade glowworm coiled on the ground and rising into an S, oversized eyes behind tiny brass spectacles, a
# tattered rust knit beanie between two curled feelers with amber glow bulbs, a patchwork travel cape, a tin camp mug in its
# stubby hands, and the lantern bulb of its tail held up behind it
@char("Wick", P.palette(form=("Body", "Head"), Body="#7cd6b2", Head="#86dcb8", Ring="#3d977b", Belly="#dcf6cc", Eye="#1a1228", Iris="#ffb347",
                        Shine="#ffffff", Brass="#e0b04a", BrassLo="#a87a2a", Beanie="#c8643c", BeanieDark="#86381f", Patch="#e3bf5e", Patch2="#6f7fd0",
                        Cape="#7a5a9c", CapeDark="#4e3a70", Tin="#b2b6c4", TinDark="#6c7080", Cocoa="#5e3420", Glow="#ffd27a", Ember="#ff9a30",
                        Blush="#f39ab4", Mouth="#2a1a2a", Stitch="#f4e6c8"))
def wick(v):
    E = P.E
    # the spine from the tail's lantern to the neck: on the ground it coils round to the left, then the front rises in an S
    sp = [V(1.95, -0.95, 1.6), V(1.72, -1.25, 0.72), V(0.45, -1.45, 0.48), V(-0.55, -1.0, 0.5), V(-0.7, -0.05, 0.6), V(-0.15, 0.35, 1.15), V(0.0, 0.3, 2.05), V(0.0, 0.25, 2.7)]  # w2: the lantern swung wide of the cape
    rad = [0.24, 0.34, 0.46, 0.54, 0.6, 0.62, 0.6, 0.52]
    v.joint("Body", tuple(sp[5]))
    v.joint("Seg2", tuple(sp[4]), "Body", "tail")
    v.joint("Tail", tuple(sp[2]), "Seg2", "tail")
    owner = ["Tail", "Tail", "Tail", "Seg2", "Seg2", "Body", "Body", "Body"]
    n = 30
    rings = []
    for k in range(n + 1):  # chubby segments: a ball every step along the spine, ringed every third
        t = k / n * (len(sp) - 1); i = min(int(t), len(sp) - 2); u = t - i
        c = sp[i].lerp(sp[i + 1], u); r = rad[i] + (rad[i + 1] - rad[i]) * u
        part = owner[i if u < 0.5 else i + 1]
        v.muscle(part, "Body", tuple(c), (r, r, r))
        if k % 3 == 0 and 2 < k < n - 1:
            d = (sp[i + 1] - sp[i]).normalized()
            rings.append((part, c, d, r))
    P.shade(v, "Body")
    for part, c0, d0, r0 in rings:  # w2: a groove cut between the segments (w1: "a smooth extruded tube"), its floor dark
        def cut(x, y, z, c0=c0, d0=d0, r0=r0):
            q = V(x, y, z) - c0; h = q.dot(d0)
            return abs(h) < 0.07 and (q - d0 * h).length > r0 * 0.86
        v.carve(cut, part=part)
        v.torus(part, "Ring", c0, tuple(d0), r0 * 0.84, 0.06)
    for k in range(6):  # the pale belly scutes up the front of the rising neck
        z = 1.0 + k * 0.3
        v.ell("Body", "Belly", (0, 0.62 + (0.12 if 1 < k < 4 else 0), z), (0.34, 0.12, 0.13))
    # the tail lantern: a glass bulb with a glowing heart and a brass cap
    v.ell("Tail", "Glow", tuple(sp[0] + V(0.05, -0.05, 0.25)), (0.36, 0.36, 0.42))
    v.ell("Tail", "Ember", tuple(sp[0] + V(0.05, -0.05, 0.25)), (0.2, 0.2, 0.24))
    v.torus("Tail", "Brass", sp[0] + V(0, 0, -0.05), (0.1, 0.1, 1), 0.28, 0.07)
    v.box("Tail", "Brass", tuple(sp[0] + V(0.05, -0.05, 0.72)), (0.14, 0.14, 0.14))
    v.anchor("tail", "Tail", tuple(sp[0] + V(0, 0, 0.3)))
    # the cape: a patchwork shoulder cape down the back of the rising neck
    v.ell("Body", "Cape", (0, -0.28, 2.3), (0.74, 0.5, 0.55), cut=lambda x, y, z: y < -0.05 and z < 2.6)  # w3: shorter, clear of the tail loop
    v.ell("Body", "CapeDark", (0, -0.2, 2.65), (0.66, 0.5, 0.12))  # its collar
    for (x, z, col) in ((-0.35, 1.85, "Patch"), (0.3, 2.2, "Patch2"), (-0.1, 1.6, "Patch2")):
        v.box("Body", col, (x, -0.78, z), (0.32, 0.1, 0.28))
        v.box("Body", "Stitch", (x, -0.84, z + 0.13), (0.3, 0.04, 0.04))
    # the head: big and round, giant amber eyes behind round brass spectacles, a small smile, blush
    v.joint("Head", (0, 0.25, 2.85), "Body", "head")
    v.muscle("Head", "Head", (0, 0.3, 3.45), (0.86, 0.78, 0.74))
    P.shade(v, "Head", parts={"Head"})
    for s in (-1, 1):
        v.eye("Head", (s * 0.34, 0.98, 3.5), (s * 0.3, 1, 0.08), w=0.38, h=0.46, iris="Iris")
        v.torus("Head", "Brass", V(s * 0.34, 1.06, 3.5), (s * 0.3, 1, 0.08), 0.32, 0.055)  # spectacles
        v.cap("Head", "Brass", V(s * 0.64, 0.95, 3.55), V(s * 0.8, 0.55, 3.6), 0.04, 0.04)  # the arms of the spectacles
        v.ell("Head", "Blush", (s * 0.6, 0.86, 3.12), (0.15, 0.06, 0.08))
        # feelers: up through the beanie, curling outward, each ending in a glowing bulb
        fe = [V(s * 0.3, 0.15, 4.05), V(s * 0.45, 0.2, 4.6), V(s * 0.75, 0.3, 4.95), V(s * 1.0, 0.45, 4.85)]
        v.tube("Head", "Ring", fe, [0.07, 0.06, 0.055, 0.05])
        v.ell("Head", "Glow", tuple(fe[3] + V(s * 0.08, 0.04, 0.02)), (0.17, 0.17, 0.17))
        v.ell("Head", "Ember", tuple(fe[3] + V(s * 0.08, 0.04, 0.02)), (0.08, 0.08, 0.08))
    v.box("Head", "Brass", (0, 1.07, 3.55), (0.18, 0.05, 0.05))  # the bridge
    v.box("Head", "Mouth", (0, 1.04, 3.08), (0.22, 0.05, 0.05))
    for s in (-1, 1): v.box("Head", "Mouth", (s * 0.14, 1.02, 3.12), (0.06, 0.05, 0.05))  # the smile's turned-up corners
    # the beanie: a knit cap with ribbed stripes, a folded brim, a patch, a frayed hole and a little pompom
    v.ell("Head", "Beanie", (0, 0.2, 3.95), (0.8, 0.74, 0.52), cut=lambda x, y, z: z >= 3.82)
    v.torus("Head", "BeanieDark", (0, 0.2, 3.88), (0, 0, 1), 0.78, 0.13)  # the folded brim
    for k in range(4): v.torus("Head", "BeanieDark", (0, 0.2, 4.05 + k * 0.1), (0, 0, 1), 0.74 - k * 0.1, 0.03)
    v.box("Head", "Patch", (0.4, 0.75, 4.12), (0.24, 0.1, 0.2), rot=E(0, 0, -30))
    v.box("Head", "Stitch", (0.4, 0.8, 4.12), (0.26, 0.04, 0.04), rot=E(0, 0, -30))
    v.ell("Head", "Beanie", (-0.15, 0.1, 4.5), (0.2, 0.2, 0.2))  # the pompom
    v.ell("Head", "BeanieDark", (-0.15, 0.1, 4.46), (0.14, 0.22, 0.14))
    v.anchor("eyes", "Head", (0, 1.0, 3.5)); v.anchor("speech", "Head", (0, 0.2, 5.3))
    # stubby arms from the front of the neck holding a tin camp mug of cocoa
    mug = V(0.0, 1.95, 2.3)  # w3: further out (w2 1.62), a window under the arms
    for s, A in ((-1, "ArmL"), (1, "ArmR")):
        sh, el, wr = V(s * 0.52, 0.55, 2.3), V(s * 0.95, 1.15, 2.1), V(s * 0.36, 1.82, 2.25)
        v.joint(A + "1", tuple(sh), "Body", "arm")
        v.cap(A + "1", "Body", sh, el, 0.17, 0.16)
        v.cap(A + "1", "Body", el, wr, 0.16, 0.15)
        v.ell(A + "1", "Belly", tuple(wr + V(0, 0.05, 0)), (0.14, 0.12, 0.12))
        v.anchor("hand" + A[3:], A + "1", tuple(wr))
    v.cap("ArmR1", "Tin", mug - V(0, 0, 0.22), mug + V(0, 0, 0.18), 0.24, 0.24)
    v.torus("ArmR1", "TinDark", mug + V(0, 0, 0.18), (0, 0, 1), 0.24, 0.04)
    v.ell("ArmR1", "Cocoa", tuple(mug + V(0, 0, 0.17)), (0.19, 0.19, 0.03))
    v.torus("ArmR1", "TinDark", mug + V(0.3, 0, 0.0), (0, 1, 0), 0.11, 0.035)  # the handle
    v.anchor("mug", "ArmR1", tuple(mug))
    P.ground(v)



# ---------------------------------------------------------------- KILN KEEPER: the mole potter (Camp 2, the Kiln Camp)
# a round plush plum-velvet mole in a terracotta tunic under a clay-smudged cream apron, a big pink digging nose, tiny round
# brass spectacles low on the snout, a tilted terracotta beret, wide pale digging paws cradling a freshly painted clay pot
@char("KilnKeeper", dict(P.palette(form=("Velvet", "Tunic"), Velvet="#6e4a86", VelvetDark="#4a2f5e", Snout="#8c68a2", Nose="#f49ab2", NoseLo="#d8708e",
                              Tunic="#c86a44", TunicDark="#8e4428", Apron="#f2e2c2", ApronLo="#d8c4a0", Smudge="#b8643e", Paw="#f2dcd2", Claw="#fff6e8",
                              Brass="#e0b04a", Eye="#1a1228", Iris="#3a2450", Shine="#ffffff", Pot="#cc7c4c", PotDark="#8e4c2c", Paint="#5fd0c0",
                              PaintHi="#c8fff4", Beret="#3e3446", BeretDark="#2a2232", White="#fff8ee", Blush="#f39ab4"), TunicLo="#a8553a", TunicLoTop="#b05c40", TunicCrease="#7a3a26", TunicCreaseTop="#82402a", VelvetLo="#5c3c74", VelvetLoTop="#62427a", VelvetCrease="#3e2652", VelvetCreaseTop="#442a58"))  # k2: warm shading (the cool Lo read olive)
def keeper(v):
    E = P.E
    v.joint("Body", (0, 0, 1.6))
    # a round pear of a body: velvet, a terracotta tunic over the trunk, a cream apron proud of the front
    v.muscle("Body", "Velvet", (0, 0, 1.45), (1.12, 0.98, 1.2))
    v.muscle("Body", "Tunic", (0, 0, 1.75), (1.16, 1.02, 0.86))
    P.shade(v, "Velvet", "Tunic")
    v.ell("Body", "Apron", (0, 0.55, 1.45), (0.9, 0.5, 1.0), cut=lambda x, y, z: y >= 0.58 and z >= 0.35)
    v.torus("Body", "TunicDark", (0, 0.0, 2.55), (0, 0, 1), 0.72, 0.1)  # the tunic's collar
    for (x, z, w) in ((-0.32, 1.85, 0.22), (0.28, 1.2, 0.3), (0.05, 1.6, 0.14), (-0.4, 0.95, 0.16), (0.42, 2.05, 0.12)):
        v.ell("Body", "Smudge", (x, 1.05, z), (w, 0.06, w * 0.7))  # clay smudges and thumbprints
    v.box("Body", "ApronLo", (0, 1.04, 2.28), (0.7, 0.06, 0.08))  # the apron's hem stitch at the bib
    for s in (-1, 1): v.cap("Body", "ApronLo", V(s * 0.42, 0.95, 2.3), V(s * 0.62, 0.2, 2.6), 0.06, 0.06)  # its neck straps
    v.box("Body", "ApronLo", (0.38, 1.04, 1.25), (0.38, 0.08, 0.32))  # a pocket with brushes in it
    for k in range(3): v.cap("Body", "PotDark", V(0.28 + k * 0.09, 1.04, 1.3), V(0.25 + k * 0.12, 1.08, 1.7), 0.035, 0.03)
    v.ell("Body", "Paint", (0.37, 1.08, 1.72), (0.05, 0.05, 0.06))
    v.ell("Body", "VelvetDark", (0, -0.95, 1.0), (0.2, 0.2, 0.24))  # a stubby tail
    for s in (-1, 1):  # k3: the apron's straps cross the back to a tied bow, and a potter's tool roll on the belt (k2: a bare back)
        v.curve("Body", "ApronLo", [(s * 0.62, 0.2, 2.6), (s * 0.4, -0.9, 2.2), (-s * 0.25, -1.08, 1.55)], [0.07, 0.07, 0.07])
        v.ell("Body", "Apron", (s * 0.3, -1.12, 1.5), (0.26, 0.12, 0.16), rot=E(0, s * -25, 0))
        v.cap("Body", "Apron", V(s * 0.06, -1.12, 1.45), V(s * 0.22, -1.08, 1.05), 0.07, 0.08)
    v.ell("Body", "ApronLo", (0, -1.14, 1.5), (0.1, 0.08, 0.1))
    v.torus("Body", "TunicDark", (0, 0.0, 1.32), (0, 0, 1), 1.02, 0.08)  # a belt
    v.box("Body", "Smudge", (0.62, -0.82, 1.3), (0.5, 0.2, 0.34), rot=E(0, 0, 32))  # the tool roll
    for k in range(3): v.cap("Body", "PotDark", V(0.5 + k * 0.1, -0.88, 1.4), V(0.45 + k * 0.12, -0.95, 1.72), 0.035, 0.03)
    v.anchor("chest", "Body", (0, 1.0, 2.0))
    # the head: no neck, a round velvet head, a long snout, the big pink digging nose, tiny eyes behind low brass spectacles
    v.joint("Head", (0, 0.2, 2.65), "Body", "head")
    v.muscle("Head", "Velvet", (0, 0.2, 3.2), (0.86, 0.82, 0.72))
    P.shade(v, "Velvet", parts={"Head"})
    v.cap("Head", "Snout", V(0, 0.75, 3.12), V(0, 1.45, 3.02), 0.42, 0.24)
    v.ell("Head", "Nose", (0, 1.62, 3.03), (0.3, 0.14, 0.24))
    v.ell("Head", "NoseLo", (0, 1.7, 2.98), (0.18, 0.08, 0.12))
    for s in (-1, 1):
        v.ell("Head", "NoseLo", (s * 0.09, 1.76, 3.05), (0.04, 0.03, 0.05))  # nostrils
        v.eye("Head", (s * 0.27, 0.94, 3.42), (s * 0.4, 1, 0.15), w=0.2, h=0.22, iris="Iris")
        v.torus("Head", "Brass", V(s * 0.27, 1.02, 3.38), (s * 0.3, 1, 0.1), 0.21, 0.06)  # the spectacles, round, a little low (k1: thin rims read as yellow brows)
        v.cap("Head", "Brass", V(s * 0.46, 0.96, 3.4), V(s * 0.74, 0.55, 3.45), 0.04, 0.04)
        v.ell("Head", "Blush", (s * 0.42, 1.08, 3.0), (0.14, 0.06, 0.08))
    v.box("Head", "Brass", (0, 1.12, 3.4), (0.14, 0.05, 0.05))
    # the beret: soft, tilted to one side, a little stem on top
    v.ell("Head", "Beret", (0.18, 0.12, 3.88), (0.86, 0.82, 0.26), rot=E(-6, 16, 0))
    v.ell("Head", "BeretDark", (0.12, 0.12, 3.74), (0.78, 0.74, 0.08), rot=E(-6, 16, 0))
    v.cap("Head", "BeretDark", V(0.26, 0.1, 4.1), V(0.3, 0.08, 4.32), 0.07, 0.05)
    v.anchor("eyes", "Head", (0, 0.95, 3.42)); v.anchor("speech", "Head", (0, 0.1, 4.8))
    # arms: short tunic sleeves, big pale shovel paws with claws, cradling the pot in front of the belly
    pot = V(0, 1.85, 2.3)  # k3: raised and forward so its rim breaks the outline
    for s, A in ((-1, "ArmL"), (1, "ArmR")):
        sh, el, wr = V(s * 1.0, 0.2, 2.3), V(s * 1.62, 0.72, 1.98), V(s * 0.92, 1.72, 2.05)  # k3: elbows out
        v.joint(A + "1", tuple(sh), "Body", "arm")
        v.cap(A + "1", "Tunic", sh, el, 0.3, 0.27)
        v.joint(A + "2", tuple(el), A + "1", "arm")
        v.cap(A + "2", "Velvet", el, wr, 0.25, 0.24)
        v.ell(A + "2", "Paw", tuple(wr + V(-s * 0.08, 0.08, -0.05)), (0.36, 0.32, 0.16), rot=E(0, s * 30, 0))  # a wide flat digging paw
        for k in range(4): v.crystal(A + "2", "Claw", wr + V(-s * 0.08 + (k - 1.5) * 0.14, 0.34, -0.08), (0, 1, -0.3), 0.22, 0.05, sides=4)
        v.anchor("hand" + A[3:], A + "2", tuple(wr))
    # the pot: a round clay pot with a neck and rim, painted with a mint band and dots, still wet
    v.ell("ArmR2", "Pot", tuple(pot), (0.5, 0.48, 0.44))
    v.torus("ArmR2", "PotDark", pot + V(0, 0, 0.4), (0, 0, 1), 0.3, 0.09)  # the neck
    v.torus("ArmR2", "Pot", pot + V(0, 0, 0.52), (0, 0, 1), 0.34, 0.07)  # the rim
    v.torus("ArmR2", "Paint", pot + V(0, 0, 0.05), (0, 0, 1), 0.5, 0.06)
    for k in range(8):
        a = k / 8 * math.tau
        v.ell("ArmR2", "PaintHi" if k % 2 else "Paint", tuple(pot + V(math.cos(a) * 0.44, math.sin(a) * 0.42, -0.18)), (0.06, 0.06, 0.06))
    v.anchor("pot", "ArmR2", tuple(pot))
    # short legs with pale clawed feet
    for s, L in ((-1, "LegL"), (1, "LegR")):
        hip, foot = V(s * 0.55, 0.05, 0.7), V(s * 0.62, 0.35, 0.0)
        v.joint(L + "1", tuple(hip), "Body", "leg")
        v.cap(L + "1", "VelvetDark", hip, foot + V(0, 0, 0.2), 0.3, 0.26)
        v.ell(L + "1", "Paw", tuple(foot + V(0, 0.2, 0.13)), (0.32, 0.42, 0.15))
        for k in (-1, 0, 1): v.crystal(L + "1", "Claw", foot + V(k * 0.13, 0.58, 0.08), (0, 1, -0.3), 0.14, 0.045, sides=4)
        v.anchor("foot" + L[3:], L + "1", tuple(foot + V(0, 0.2, 0.1)))
    P.ground(v)



# ---------------------------------------------------------------- MOSS: the lost apprentice miner (layer 1, by the Swallow Hole)
# a young hedgehog (2026-11-27: the town's named folk are creatures; spines give him a silhouette) crouched a little, scared:
# an oversized dented butter-brass helmet with a working headlamp, a long moss-green knit scarf trailing down one shoulder,
# a dusty lilac coat, a leather field satchel, wide anxious eyes, a glowing hand lantern clutched to his chest
@char("Moss", P.palette(form=("Coat", "Face"), Coat="#a998d4", CoatDark="#6f5f9a", Face="#efd4b0", FaceDark="#c9a882", Spine="#7a5236",
                        SpineTip="#d6a878", Nose="#2a1a1a", Helm="#f0c85a", HelmDark="#a8822a", Lamp="#fff2b0", Glow="#ffd27a", Ember="#ffa040",
                        Scarf="#6aa84f", ScarfDark="#3f7a32", Leather="#8a5a34", LeatherDark="#5e3a20", Boot="#4a3a44", Brass="#e0b04a",
                        Eye="#1a1228", Iris="#4a2e18", Shine="#ffffff", Blush="#f39ab4", Brow="#5a3a2a", Smudge="#7a6a80"))
def moss(v):
    E = P.E
    v.joint("Body", (0, 0, 1.45))
    # the coat: a dusty lilac coat over a round little body, its skirt flared, dust on the hem
    v.muscle("Body", "Coat", (0, 0.0, 1.6), (0.86, 0.74, 0.82))
    v.ell("Body", "Coat", (0, 0.0, 1.0), (0.94, 0.82, 0.5), cut=lambda x, y, z: z >= 0.6)
    P.shade(v, "Coat")
    v.box("Body", "CoatDark", (0, 0.8, 1.45), (0.08, 0.06, 0.95))  # the button placket
    for z in (1.15, 1.5, 1.85): v.ell("Body", "Brass", (0, 0.84, z), (0.07, 0.05, 0.07))
    for (x, z) in ((-0.5, 0.72), (0.35, 0.68), (0.6, 0.9)): v.ell("Body", "Smudge", (x, 0.86, z), (0.14, 0.05, 0.1))  # dust
    # spines: a mane of brown quills over the back and shoulders, pale tips, pointing back and up
    for row in range(5):
        for k in range(7):
            a = math.radians(-150 + k * 50)  # round the back, from one shoulder to the other
            z = 1.35 + row * 0.24
            base = V(math.sin(a) * 0.72, -math.cos(a) * 0.62 - 0.05, z) * (1 - row * 0.04)
            d = V(math.sin(a) * 0.4, -0.9, 0.55).normalized()
            v.crystal("Body", "Spine", base, tuple(d), 0.62 - row * 0.04, 0.12, sides=4)
            v.crystal("Body", "SpineTip", base + d * 0.4, tuple(d), 0.22, 0.06, sides=4)
    # the satchel: a strap across the chest, a leather bag at the left hip with a brass buckle
    v.curve("Body", "Leather", [(0.55, 0.45, 2.25), (0.1, 0.8, 1.75), (-0.5, 0.65, 1.25)], [0.07, 0.07, 0.07])
    v.box("Body", "Leather", (-0.82, 0.25, 1.1), (0.3, 0.6, 0.52))
    v.box("Body", "LeatherDark", (-0.96, 0.25, 1.25), (0.06, 0.62, 0.28))  # the flap
    v.box("Body", "Brass", (-1.0, 0.25, 1.15), (0.04, 0.12, 0.1))
    v.anchor("chest", "Body", (0, 0.8, 1.9))
    # the head: round, a cream face with a pointed snout, a black nose, big worried eyes, little round ears, quills behind
    v.joint("Head", (0, 0.1, 2.35), "Body", "head")
    v.muscle("Head", "Face", (0, 0.18, 2.9), (0.74, 0.7, 0.66))
    P.shade(v, "Face", parts={"Head"})
    v.cap("Head", "Face", V(0, 0.65, 2.8), V(0, 1.18, 2.72), 0.34, 0.16)
    v.ell("Head", "Nose", (0, 1.26, 2.74), (0.11, 0.08, 0.09))
    for s in (-1, 1):
        v.eye("Head", (s * 0.3, 0.74, 2.98), (s * 0.3, 1, 0.05), w=0.38, h=0.46, iris="Iris")
        v.box("Head", "Brow", (s * 0.3, 0.8, 3.27), (0.26, 0.06, 0.06), rot=E(0, s * -22, 0))  # brows up in the middle: worried
        v.ell("Head", "Blush", (s * 0.5, 0.66, 2.68), (0.13, 0.06, 0.07))
        v.ell("Head", "FaceDark", (s * 0.8, 0.12, 3.02), (0.2, 0.12, 0.2))  # s2: a round ear out below the helmet rim (s1: hidden under it)
        v.ell("Head", "Blush", (s * 0.82, 0.2, 3.02), (0.1, 0.05, 0.1))
        for k in range(4):  # quills behind the head
            a = math.radians(-60 + k * 40) * s
            v.crystal("Head", "Spine", V(math.sin(a) * 0.5, -0.4, 2.75 + k * 0.08), (math.sin(a) * 0.5, -1, 0.3), 0.5, 0.11, sides=4)
    v.box("Head", "Nose", (0, 1.08, 2.58), (0.14, 0.05, 0.04))  # a small wobbly mouth
    # the helmet: oversized butter brass, a dent on one side, a rim, a working headlamp
    v.ell("Head", "Helm", (0.08, 0.12, 3.3), (0.86, 0.84, 0.6), rot=E(-8, 10, 0), cut=lambda x, y, z: z >= 3.16 + x * 0.12)  # s2: tipped over one eye, too big for him
    v.torus("Head", "HelmDark", (0, 0.12, 3.2), (0, 0, 1), 0.86, 0.09)  # the rim
    v.carve(lambda x, y, z: (V(x, y, z) - V(0.78, 0.35, 3.62)).length < 0.24, part="Head")  # the dent
    v.ell("Head", "HelmDark", (0.66, 0.3, 3.55), (0.12, 0.12, 0.12))
    v.box("Head", "HelmDark", (0, 0.12, 3.78), (0.12, 1.3, 0.08))  # a ridge front to back
    v.cap("Head", "Brass", V(0, 0.78, 3.45), V(0, 1.0, 3.48), 0.2, 0.2)  # the headlamp
    v.ell("Head", "Lamp", (0, 1.02, 3.48), (0.15, 0.04, 0.15))
    v.anchor("lamp", "Head", (0, 1.06, 3.48))
    v.anchor("eyes", "Head", (0, 0.8, 2.98)); v.anchor("speech", "Head", (0, 0.1, 4.4))
    # the scarf: a knit loop round the neck, one long tail down the right shoulder and behind, fringe at the end
    v.torus("Body", "Scarf", (0, 0.05, 2.28), (0, 0, 1), 0.6, 0.18)
    for k in range(5): v.torus("Body", "ScarfDark", (0, 0.05, 2.18 + k * 0.05), (0, 0, 1), 0.66, 0.025) if k % 2 else None
    tail = [V(0.5, 0.35, 2.2), V(0.85, 0.1, 1.8), V(1.0, -0.45, 1.25), V(1.05, -0.95, 0.85)]
    v.tube("Body", "Scarf", tail, [0.17, 0.16, 0.15, 0.14])
    for t in (0.33, 0.66): v.torus("Body", "ScarfDark", tail[1].lerp(tail[2], t), tuple((tail[2] - tail[1]).normalized()), 0.16, 0.04)
    for k in range(4): v.crystal("Body", "ScarfDark", tail[3] + V(-0.12 + k * 0.08, -0.05, -0.05), (0, -0.4, -1), 0.24, 0.04, sides=4)
    # arms: coat sleeves; the right paw clutches the lantern to his chest, the left grips the satchel strap
    lan = V(1.95, 0.85, 2.05)  # s2: held out at arm's length into the dark, apart from the body (s1: it merged with the chest)
    for s, A, wr in ((-1, "ArmL", V(-0.2, 0.85, 1.72)), (1, "ArmR", V(1.85, 0.75, 2.5))):
        sh, el = V(s * 0.8, 0.1, 2.1), (V(s * 0.95, 0.55, 1.6) if s < 0 else V(1.35, 0.35, 2.2))
        v.joint(A + "1", tuple(sh), "Body", "arm")
        v.cap(A + "1", "Coat", sh, el, 0.22, 0.2)
        v.joint(A + "2", tuple(el), A + "1", "arm")
        v.cap(A + "2", "Coat", el, wr, 0.2, 0.18)
        v.ell(A + "2", "Face", tuple(wr + V(0, 0.08, 0)), (0.16, 0.15, 0.15))
        v.anchor("hand" + A[3:], A + "2", tuple(wr))
    # the hand lantern: a brass cage round a glowing heart, a ring handle in his paw
    v.box("ArmR2", "Brass", tuple(lan + V(0, 0, -0.38)), (0.4, 0.4, 0.08))
    v.box("ArmR2", "Brass", tuple(lan + V(0, 0, 0.22)), (0.34, 0.34, 0.08))
    for cx in (-1, 1):
        for cy in (-1, 1): v.box("ArmR2", "Brass", tuple(lan + V(cx * 0.16, cy * 0.16, -0.08)), (0.05, 0.05, 0.56))
    v.ell("ArmR2", "Glow", tuple(lan + V(0, 0, -0.08)), (0.15, 0.15, 0.22))
    v.ell("ArmR2", "Ember", tuple(lan + V(0, 0, -0.1)), (0.07, 0.07, 0.1))
    v.torus("ArmR2", "Brass", lan + V(0, 0, 0.32), (1, 0, 0), 0.12, 0.035)
    v.anchor("lantern", "ArmR2", tuple(lan))
    # crouched legs in dark boots, knees bent
    for s, L in ((-1, "LegL"), (1, "LegR")):
        hip, knee, foot = V(s * 0.38, 0.0, 0.95), V(s * 0.5, 0.4, 0.55), V(s * 0.52, 0.22, 0.0)
        v.joint(L + "1", tuple(hip), "Body", "leg")
        v.cap(L + "1", "CoatDark", hip, knee, 0.24, 0.22)
        v.joint(L + "2", tuple(knee), L + "1", "leg")
        v.cap(L + "2", "Boot", knee, foot + V(0, 0, 0.2), 0.21, 0.2)
        v.ell(L + "2", "Boot", tuple(foot + V(0, 0.18, 0.13)), (0.24, 0.36, 0.15))
        v.torus(L + "2", "LeatherDark", foot + V(0, 0.05, 0.42), (0, 0, 1), 0.22, 0.05)
        v.anchor("foot" + L[3:], L + "2", tuple(foot + V(0, 0.2, 0.1)))
    P.ground(v)



# ---------------------------------------------------------------- SMUDGE: the shy soot-sprite (Camp 1, behind the lantern post)
# a timid charcoal-violet fluffball: wispy jagged fur all round, jagged tufted ears, big wide butter-gold eyes, a crooked
# oversized miner cap with a tiny lamp, a warm glowing pebble held in both little paws, a wispy curl of a tail
@char("Smudge", P.palette(form=("Soot",), Soot="#4a3c5c", SootLo="#2e2440", Wisp="#6c5a84", WispTip="#9a88b4", Eye="#1a1228", Iris="#ffd24a",
                          Shine="#ffffff", Cap="#e8c25a", CapDark="#a8822a", Lamp="#fff2b0", Pebble="#ff9a40", PebbleHot="#ffd27a", Blush="#e888b0",
                          Paw="#5c4c70"))
def smudge(v):
    E = P.E
    v.joint("Body", (0, 0, 0.7))
    v.muscle("Body", "Soot", (0, 0, 0.72), (0.66, 0.6, 0.6))
    P.shade(v, "Soot")
    for row, (z, n, L) in enumerate(((0.45, 6, 0.48), (0.9, 7, 0.5))):  # s2: two rows of big soot tufts (d1 random wisps and three thin rows read as noise)
        for q in range(n):
            a = (q + row * 0.5) / n * math.tau
            d = V(math.cos(a), math.sin(a), 0.35 + row * 0.25)
            if d.y > 0.6 and row < 2: continue  # the belly front stays clear for the paws and pebble
            base = V(math.cos(a) * 0.6, math.sin(a) * 0.54, z + 0.1)
            v.crystal("Body", "Wisp" if q % 2 else "WispTip", base, tuple(d), L, 0.2, sides=4)
    # the wispy tail: a curl behind, ending in a pale flick
    tl = [V(0, -0.5, 0.45), V(0.15, -0.95, 0.55), V(0.35, -1.1, 0.95), V(0.2, -0.95, 1.2)]
    v.joint("Tail", tuple(tl[0]), "Body", "tail")
    v.tube("Tail", "Soot", tl, [0.16, 0.14, 0.11, 0.07])
    v.crystal("Tail", "WispTip", tl[3], (-0.3, 0.6, 0.8), 0.3, 0.08, sides=4)
    v.anchor("tail", "Tail", tuple(tl[3]))
    # the head: round, big golden eyes, tufted ears, the cap pushed crooked
    v.joint("Head", (0, 0.05, 1.12), "Body", "head")
    v.muscle("Head", "Soot", (0, 0.05, 1.45), (0.6, 0.56, 0.52))
    P.shade(v, "Soot", parts={"Head"})
    for s in (-1, 1):
        v.eye("Head", (s * 0.25, 0.48, 1.45), (s * 0.3, 1, 0.05), w=0.34, h=0.42, iris="Iris")
        v.ell("Head", "Blush", (s * 0.42, 0.46, 1.22), (0.12, 0.05, 0.06))
        for k in range(3):  # a jagged tufted ear: three wisps fanned out
            v.crystal("Head", "Wisp" if k != 1 else "WispTip", V(s * 0.38, -0.05, 1.82), (s * (0.5 + 0.25 * k), -0.2 + 0.15 * k, 1), 0.55 - 0.1 * k, 0.1, sides=4)
    v.box("Head", "SootLo", (0, 0.56, 1.18), (0.12, 0.05, 0.04))  # a small worried mouth
    # the cap: oversized, crooked over one eye, a brim, a tiny lamp
    tilt = E(0, -18, 10)
    v.ell("Head", "Cap", (-0.1, 0.0, 1.82), (0.56, 0.54, 0.4), rot=tilt, cut=lambda x, y, z: z >= 1.74 - x * 0.3)
    v.ell("Head", "CapDark", (-0.08, 0.22, 1.72), (0.6, 0.45, 0.07), rot=tilt)  # the brim
    v.cap("Head", "CapDark", V(-0.2, 0.48, 1.92), V(-0.22, 0.6, 1.94), 0.11, 0.11)
    v.ell("Head", "Lamp", (-0.22, 0.62, 1.94), (0.08, 0.03, 0.08))
    v.anchor("eyes", "Head", (0, 0.5, 1.45)); v.anchor("speech", "Head", (0, 0.0, 2.6))
    # little paws holding a warm pebble against the belly
    peb = V(0, 0.66, 0.78)
    for s, A in ((-1, "ArmL"), (1, "ArmR")):
        sh, wr = V(s * 0.45, 0.35, 0.92), V(s * 0.2, 0.68, 0.82)
        v.joint(A + "1", tuple(sh), "Body", "arm")
        v.cap(A + "1", "Paw", sh, wr, 0.11, 0.1)
        v.anchor("hand" + A[3:], A + "1", tuple(wr))
    v.ell("ArmR1", "Pebble", tuple(peb), (0.16, 0.13, 0.13))
    v.ell("ArmR1", "PebbleHot", tuple(peb + V(0.02, 0.06, 0.04)), (0.08, 0.06, 0.06))
    v.anchor("pebble", "ArmR1", tuple(peb))
    for s, L in ((-1, "LegL"), (1, "LegR")):  # stubby feet peeking out under the fluff
        v.joint(L + "1", (s * 0.25, 0.1, 0.2), "Body", "leg")
        v.ell(L + "1", "Paw", (s * 0.27, 0.25, 0.1), (0.16, 0.22, 0.11))
        v.anchor("foot" + L[3:], L + "1", (s * 0.27, 0.25, 0.05))
    P.ground(v)



# ---------------------------------------------------------------- PIP: the town scout and messenger (the notice plaza)
# a sprightly red squirrel (2026-11-27: the named folk are creatures; the big tail is the silhouette): a layered coral scarf,
# a navy postman cap with a brass badge, a leather shoulder bag stuffed with rolled map scrolls, one paw up in a wave
@char("Pip", P.palette(form=("Fur", "Vest"), Fur="#d8743a", FurDark="#9a4a24", Cream="#f6e2c4", Vest="#3e5a9c", VestDark="#28386a",
                       Scarf="#ff7a6a", ScarfDark="#c84a46", Cap="#2e3e72", CapDark="#1c2648", Brass="#e8b84a", Leather="#8a5a34",
                       LeatherDark="#5e3a20", Paper="#f8eed8", PaperDark="#d8c8a4", Ribbon="#e84a5a", Eye="#1a1228", Iris="#5a3418",
                       Shine="#ffffff", Blush="#f39ab4", Nose="#3a2020", Boot="#4a3430"))
def pip(v):
    E = P.E
    v.joint("Body", (0, 0, 1.55))
    v.muscle("Body", "Fur", (0, 0, 1.55), (0.72, 0.62, 0.8))
    v.muscle("Body", "Vest", (0, 0.02, 1.75), (0.76, 0.66, 0.62))
    P.shade(v, "Fur", "Vest")
    v.ell("Body", "Cream", (0, 0.5, 1.3), (0.42, 0.18, 0.5))  # the cream belly
    v.box("Body", "VestDark", (0, 0.66, 1.78), (0.07, 0.05, 0.6))
    for z in (1.55, 1.8, 2.05): v.ell("Body", "Brass", (0, 0.68, z), (0.06, 0.04, 0.06))
    # the scarf: two layered coral wraps and a long end flying back over the shoulder
    v.torus("Body", "Scarf", (0, 0.0, 2.25), (0, 0, 1), 0.56, 0.17)
    v.torus("Body", "ScarfDark", (0.02, 0.02, 2.08), (0.1, 0, 1), 0.6, 0.12)
    v.tube("Body", "Scarf", [V(-0.35, -0.35, 2.25), V(-0.75, -0.85, 2.35), V(-1.05, -1.25, 2.6)], [0.14, 0.13, 0.11])
    for k in range(3): v.crystal("Body", "ScarfDark", V(-1.05, -1.25, 2.6), (-0.4 + k * 0.2, -1, 0.3), 0.26, 0.04, sides=4)
    # the bag: a strap from the right shoulder to the left hip, a leather satchel stuffed with rolled maps
    v.curve("Body", "Leather", [(0.48, 0.3, 2.2), (0.1, 0.66, 1.7), (-0.55, 0.42, 1.15)], [0.07, 0.07, 0.07])
    v.box("Body", "Leather", (-0.78, 0.1, 1.05), (0.34, 0.7, 0.56))
    v.box("Body", "LeatherDark", (-0.92, 0.1, 1.24), (0.08, 0.72, 0.22))
    v.box("Body", "Brass", (-0.97, 0.1, 1.15), (0.04, 0.12, 0.1))
    for k, (dy, h) in enumerate(((-0.2, 0.7), (0.05, 0.85), (0.28, 0.6))):  # rolled maps sticking out of the bag
        c0 = V(-0.74 + (k - 1) * 0.06, dy, 1.3)
        v.cap("Body", "Paper", c0, c0 + V(-0.12, 0.02, h), 0.1, 0.1)
        v.torus("Body", "Ribbon", c0 + V(-0.08, 0.01, h * 0.55), (-0.15, 0, 1), 0.11, 0.03)
        v.ell("Body", "PaperDark", tuple(c0 + V(-0.12, 0.02, h + 0.04)), (0.07, 0.07, 0.03))
    v.anchor("chest", "Body", (0, 0.66, 1.9))
    # the tail: a huge bushy S-curve up behind, a darker underside, a cream tip
    tp = [V(-0.1, -0.55, 1.0), V(-0.65, -1.3, 0.95), V(-1.55, -1.45, 1.6), V(-2.05, -1.2, 2.5), V(-1.85, -0.8, 3.05)]  # p3: out past the flank, a gap at the root, the S plume clear of the back  # p2: a thin root, swept to one side under the hat line (d1: a blob behind the head)
    v.joint("Tail", tuple(tp[0]), "Body", "tail")
    v.tube("Tail", "Fur", tp, [0.2, 0.42, 0.58, 0.5, 0.3])
    for t in (0.35, 0.55, 0.75): v.torus("Tail", "Cream", tp[1].lerp(tp[3], t), tuple((tp[3] - tp[1]).normalized()), 0.55 - 0.1 * abs(t - 0.55) * 4, 0.07)  # cream bands
    v.tube("Tail", "FurDark", [t + V(0, 0.12, -0.05) for t in tp[1:4]], [0.36, 0.42, 0.36])
    for k in range(10):  # tufts round the tail's edge so it reads as fur
        t = 0.1 + k * 0.085; i = min(int(t * 4), 3); u = t * 4 - i
        c = tp[i].lerp(tp[i + 1], u); d = (tp[i + 1] - tp[i]).normalized()
        out = d.cross(V(1, 0, 0)).normalized() * (1 if k % 2 else -1)
        v.crystal("Tail", "Fur", c + out * 0.45, tuple(out + V(0.3 * (1 if k % 3 else -1), 0, 0)), 0.3, 0.1, sides=4)
    v.ell("Tail", "Cream", tuple(tp[4] + V(0, 0.08, 0.05)), (0.3, 0.26, 0.24))
    v.anchor("tail", "Tail", tuple(tp[4]))
    # the head: round, a cream muzzle, big eyes, tufted ears, the postman cap with a brass badge and a short peak
    v.joint("Head", (0, 0.1, 2.4), "Body", "head")
    v.muscle("Head", "Fur", (0, 0.12, 2.98), (0.66, 0.62, 0.6))
    P.shade(v, "Fur", parts={"Head"})
    v.ell("Head", "Cream", (0, 0.6, 2.78), (0.36, 0.22, 0.26))
    v.ell("Head", "Nose", (0, 0.82, 2.86), (0.08, 0.05, 0.06))
    v.box("Head", "Nose", (0, 0.8, 2.66), (0.12, 0.05, 0.04))
    for s in (-1, 1):
        v.eye("Head", (s * 0.27, 0.6, 3.05), (s * 0.3, 1, 0.05), w=0.32, h=0.4, iris="Iris")
        v.ell("Head", "Blush", (s * 0.45, 0.52, 2.78), (0.12, 0.05, 0.06))
        v.ell("Head", "FurDark", (s * 0.42, -0.05, 3.62), (0.14, 0.1, 0.24))  # an ear
        v.crystal("Head", "FurDark", V(s * 0.44, -0.05, 3.8), (s * 0.2, -0.1, 1), 0.3, 0.07, sides=4)  # its tuft
        v.ell("Head", "Cream", (s * 0.42, 0.04, 3.6), (0.07, 0.04, 0.14))
    v.ell("Head", "Cap", (0, 0.08, 3.42), (0.6, 0.58, 0.26), cut=lambda x, y, z: z >= 3.32)
    v.ell("Head", "CapDark", (0, 0.42, 3.36), (0.5, 0.34, 0.06), cut=lambda x, y, z: y >= 0.3)  # the peak
    v.torus("Head", "CapDark", (0, 0.08, 3.36), (0, 0, 1), 0.6, 0.06)
    v.ell("Head", "Brass", (0, 0.66, 3.5), (0.1, 0.04, 0.09))
    v.anchor("eyes", "Head", (0, 0.62, 3.05)); v.anchor("speech", "Head", (0, 0.1, 4.2))
    # arms: the right waves high, the left rests on the bag
    for s, A, el, wr in ((1, "ArmR", V(1.15, 0.15, 2.5), V(1.55, 0.3, 3.15)), (-1, "ArmL", V(-0.85, 0.3, 1.55), V(-0.62, 0.55, 1.4))):
        sh = V(s * 0.66, 0.05, 2.05)
        v.joint(A + "1", tuple(sh), "Body", "arm")
        v.cap(A + "1", "Vest", sh, el, 0.17, 0.15)
        v.joint(A + "2", tuple(el), A + "1", "arm")
        v.cap(A + "2", "Fur", el, wr, 0.14, 0.13)
        v.ell(A + "2", "Cream", tuple(wr + V(0, 0.04, 0.05)), (0.15, 0.12, 0.16))
        v.anchor("hand" + A[3:], A + "2", tuple(wr))
    for s, L in ((-1, "LegL"), (1, "LegR")):
        hip, foot = V(s * 0.32, 0.0, 0.95), V(s * 0.4, 0.2, 0.0)
        v.joint(L + "1", tuple(hip), "Body", "leg")
        v.cap(L + "1", "Fur", hip, foot + V(0, 0, 0.2), 0.2, 0.15)
        v.ell(L + "1", "Boot", tuple(foot + V(0, 0.2, 0.12)), (0.2, 0.34, 0.14))
        v.anchor("foot" + L[3:], L + "1", tuple(foot + V(0, 0.2, 0.1)))
    P.ground(v)



# ---------------------------------------------------------------- JUNIPER and TOCK: the marshmallow roasters (the town campfire)
# two townsfolk toasting marshmallows on long sticks: Juniper a badger in a knit pom beanie and a mossy shawl, Tock a fox in
# a dusk hood and a buttoned vest. One body plan, its own head, clothes and colours each.
def roaster(v, fox):
    E = P.E
    v.joint("Body", (0, 0, 1.5))
    v.muscle("Body", "Fur", (0, 0, 1.45), (0.74, 0.64, 0.82))
    v.muscle("Body", "Cloth", (0, 0.02, 1.68), (0.8, 0.7, 0.66))
    P.shade(v, "Fur", "Cloth")
    v.ell("Body", "Belly", (0, 0.52, 1.2), (0.44, 0.18, 0.5))
    if fox:  # Tock: a buttoned dusk vest with a pocket watch chain, a big white-tipped brush tail
        v.box("Body", "ClothDark", (0, 0.72, 1.75), (0.07, 0.05, 0.6))
        for z in (1.5, 1.75, 2.0): v.ell("Body", "Brass", (0, 0.74, z), (0.06, 0.04, 0.06))
        v.curve("Body", "Brass", [(0.05, 0.74, 1.62), (0.3, 0.74, 1.5), (0.42, 0.7, 1.62)], [0.03, 0.03, 0.03])
        tp = [V(-0.1, -0.55, 0.95), V(-0.75, -1.2, 0.85), V(-1.45, -1.3, 1.4), V(-1.6, -0.95, 2.05)]  # d2: flared out past the flank
        v.joint("Tail", tuple(tp[0]), "Body", "tail")
        v.tube("Tail", "Fur", tp, [0.22, 0.42, 0.44, 0.28])
        v.ell("Tail", "Belly", tuple(tp[3] + V(0, 0.05, 0.12)), (0.3, 0.28, 0.3))
        v.anchor("tail", "Tail", tuple(tp[3]))
    else:  # Juniper: a mossy knitted shawl over the shoulders with a leaf brooch, a short striped tail
        v.ell("Body", "Shawl", (0, 0.0, 2.05), (0.92, 0.82, 0.5), cut=lambda x, y, z: z >= 1.75)
        v.torus("Body", "ShawlDark", (0, 0.0, 1.78), (0, 0, 1), 0.86, 0.08)
        for k in range(12):  # its fringe
            a = k / 12 * math.tau
            v.crystal("Body", "ShawlDark", V(math.cos(a) * 0.86, math.sin(a) * 0.78, 1.74), (math.cos(a) * 0.2, math.sin(a) * 0.2, -1), 0.22, 0.04, sides=4)
        v.ell("Body", "Leaf", (0.3, 0.74, 2.05), (0.14, 0.05, 0.1), rot=E(0, 30, 0))
        v.joint("Tail", (0, -0.6, 0.95), "Body", "tail")
        v.cap("Tail", "Fur", V(0, -0.6, 0.95), V(0, -0.95, 0.75), 0.2, 0.12)
        v.anchor("tail", "Tail", (0, -0.95, 0.75))
    v.anchor("chest", "Body", (0, 0.7, 1.9))
    # the head
    v.joint("Head", (0, 0.1, 2.3), "Body", "head")
    v.muscle("Head", "Fur", (0, 0.12, 2.9), (0.7, 0.64, 0.6))
    P.shade(v, "Fur", parts={"Head"})
    if fox:
        v.cap("Head", "Belly", V(0, 0.5, 2.72), V(0, 1.05, 2.66), 0.32, 0.12)  # a long pale muzzle
        v.ell("Head", "Nose", (0, 1.12, 2.68), (0.08, 0.06, 0.06))
        for s in (-1, 1):
            v.crystal("Head", "Fur", V(s * 0.42, 0.0, 3.3), (s * 0.35, 0.05, 1), 0.62, 0.22, sides=4)  # tall pointed ears
            v.crystal("Head", "Ear", V(s * 0.42, 0.06, 3.32), (s * 0.35, 0.05, 1), 0.42, 0.12, sides=4)
            v.ell("Head", "Belly", (s * 0.48, 0.4, 2.68), (0.18, 0.14, 0.14))  # white cheek tufts
        # the dusk hood, pushed back off the ears, draping to the shoulders
        v.ell("Head", "Hood", (0, -0.42, 2.85), (0.78, 0.5, 0.7), cut=lambda x, y, z: y <= -0.12)
        v.torus("Head", "HoodDark", (0, -0.2, 2.85), (0, 1, 0.15), 0.72, 0.09)
    else:
        v.cap("Head", "Belly", V(0, 0.45, 2.8), V(0, 0.98, 2.72), 0.3, 0.13)  # d2: a wedge muzzle
        v.box("Head", "Belly", (0, 0.3, 3.15), (0.2, 0.7, 0.5))  # the white stripe up over the head
        for s in (-1, 1):
            v.box("Head", "Stripe", (s * 0.3, 0.3, 3.05), (0.18, 0.7, 0.55))  # the dark badger bands over the eyes
            v.ell("Head", "Stripe", (s * 0.66, 0.0, 3.22), (0.18, 0.1, 0.17))  # d2: round badger ears out beside the beanie
            v.ell("Head", "Belly", (s * 0.66, 0.07, 3.22), (0.1, 0.05, 0.1))
        v.ell("Head", "Nose", (0, 1.04, 2.74), (0.1, 0.07, 0.08))
        # the knit beanie with ribs and a big pom
        v.ell("Head", "Hat", (0, 0.05, 3.3), (0.68, 0.64, 0.46), cut=lambda x, y, z: z >= 3.24)
        v.torus("Head", "HatDark", (0, 0.05, 3.27), (0, 0, 1), 0.66, 0.1)
        for k in range(4): v.torus("Head", "HatDark", (0, 0.05, 3.42 + k * 0.09), (0, 0, 1), 0.62 - k * 0.1, 0.025)
        v.ell("Head", "Pom", (0, 0.0, 3.85), (0.22, 0.22, 0.2))
    for s in (-1, 1):
        v.eye("Head", (s * 0.27, 0.58, 3.0), (s * 0.3, 1, 0.05), w=0.3, h=0.36, iris="Iris")
        v.ell("Head", "Blush", (s * 0.46, 0.5, 2.74), (0.12, 0.05, 0.06))
    v.box("Head", "Nose", (0, 0.68 if not fox else 0.95, 2.6), (0.12, 0.05, 0.04))
    v.anchor("eyes", "Head", (0, 0.6, 3.0)); v.anchor("speech", "Head", (0, 0.1, 4.2))
    # arms: both paws on a long roasting stick held out over the fire, a toasted marshmallow at its end
    for s, A in ((-1, "ArmL"), (1, "ArmR")):
        sh, el, wr = V(s * 0.7, 0.05, 2.05), V(s * 0.85, 0.5, 1.6), V(s * 0.25 + 0.3, 0.95, 1.75)
        v.joint(A + "1", tuple(sh), "Body", "arm")
        v.cap(A + "1", "Cloth", sh, el, 0.17, 0.15)
        v.joint(A + "2", tuple(el), A + "1", "arm")
        v.cap(A + "2", "Fur", el, wr, 0.15, 0.13)
        v.ell(A + "2", "Paw", tuple(wr + V(0, 0.05, 0)), (0.14, 0.13, 0.13))
        v.anchor("hand" + A[3:], A + "2", tuple(wr))
    st0, st1 = V(0.2, 0.75, 1.6), V(0.55, 3.2, 2.55)
    v.cap("ArmR2", "Stick", st0, st1, 0.1, 0.08)  # d2: a branch, not a wire
    v.ell("ArmR2", "Mallow", tuple(st1 + V(0, 0.18, 0.05)), (0.24, 0.26, 0.22))
    v.ell("ArmR2", "Toast", tuple(st1 + V(0, 0.36, 0.02)), (0.18, 0.1, 0.16))
    v.anchor("marshmallow", "ArmR2", tuple(st1 + V(0, 0.18, 0.05)))
    for s, L in ((-1, "LegL"), (1, "LegR")):
        hip, foot = V(s * 0.34, 0.0, 0.9), V(s * 0.42, 0.2, 0.0)
        v.joint(L + "1", tuple(hip), "Body", "leg")
        v.cap(L + "1", "Fur" if fox else "Stripe", hip, foot + V(0, 0, 0.2), 0.22, 0.16)
        v.ell(L + "1", "Boot", tuple(foot + V(0, 0.2, 0.12)), (0.21, 0.34, 0.14))
        v.anchor("foot" + L[3:], L + "1", tuple(foot + V(0, 0.2, 0.1)))
    P.ground(v)


@char("Juniper", P.palette(form=("Fur", "Cloth"), Fur="#8a8494", Stripe="#2e2a36", Belly="#f4f0ea", Cloth="#d86a8a", ClothDark="#9a4060",
                           Shawl="#6aa06a", ShawlDark="#3e6e44", Leaf="#9ad86a", Hat="#e0a03a", HatDark="#a8701e", Pom="#fff4dc",
                           Nose="#1e1a22", Eye="#1a1228", Iris="#3a2a1a", Shine="#ffffff", Blush="#f39ab4", Paw="#4a4452", Boot="#5a3a30",
                           Stick="#8a5a30", Mallow="#fff6ec", Toast="#c88a4a", Brass="#e0b04a", Ear="#2e2a36", Hood="#5a4a7a", HoodDark="#3a2e56"))
def juniper(v): roaster(v, False)


@char("Tock", P.palette(form=("Fur", "Cloth"), Fur="#e0783a", Stripe="#3a2a2a", Belly="#fff4e6", Cloth="#4a5a8c", ClothDark="#2c3660",
                        Shawl="#6aa06a", ShawlDark="#3e6e44", Leaf="#9ad86a", Hat="#e0a03a", HatDark="#a8701e", Pom="#fff4dc",
                        Nose="#1e1a22", Eye="#1a1228", Iris="#3a2a1a", Shine="#ffffff", Blush="#f39ab4", Paw="#3a2a2e", Boot="#3a2e36",
                        Stick="#8a5a30", Mallow="#fff6ec", Toast="#c88a4a", Brass="#e0b04a", Ear="#3a2a2e", Hood="#6a5aa0", HoodDark="#40346a"))
def tock(v): roaster(v, True)



# ---------------------------------------------------------------- GLOOMLING: the layer 1 darkness prowler (an enemy)
# a hunched shadow-cat gremlin: jagged soot fur, tall tufted cat ears, a curled smoke tail that pales to its tip, sharp pale
# claws, glowing amber ring eyes with dark slit pupils, a jagged grin
@char("Gloomling", P.palette(form=("Soot",), Soot="#2c2438", SootHi="#4a3c5e", Smoke="#5e4e78", Smoke2="#8e7eac", Smoke3="#c4b8dc",
                             Ring="#ffb030", Pupil="#0a0610", Claw="#e4dcec", Teeth="#f4eefa", Mouth="#120a18", Inner="#ff6a8a",
                             Eye="#0a0610", Shine="#ffffff"))
def gloomling(v):
    E = P.E
    import random
    rnd = random.Random(11)
    v.joint("Body", (0, 0, 1.2))
    # hunched: the chest pitched forward over bent legs, the back a high arch
    v.muscle("Body", "Soot", (0, 0.1, 1.35), (0.72, 0.8, 0.62), rot=E(-25, 0, 0))
    v.muscle("Body", "Soot", (0, -0.45, 1.05), (0.6, 0.55, 0.5))
    P.shade(v, "Soot")
    for k in range(80):  # jagged fur: spiky soot tufts along the back, shoulders and flanks
        a = rnd.uniform(-2.6, 2.6); h = rnd.uniform(0.85, 1.75)
        base = V(math.sin(a) * 0.62, -math.cos(a) * 0.55 + 0.05, h)
        d = V(math.sin(a) * 0.6, -0.8, 0.6).normalized()
        v.crystal("Body", "SootHi" if k % 4 == 0 else "Soot", base, tuple(d), rnd.uniform(0.25, 0.5), 0.09, sides=4)
    for k in range(4):  # d3: four smoke plates down the spine (d2's seven thin shards read as noise)
        v.crystal("Body", "Smoke2", V(0, -0.4 - k * 0.16, 1.9 - k * 0.22), (0, -0.4, 1), 0.55 - k * 0.07, 0.17, sides=4)
    # the smoke tail: segments that curl up and pale from soot to smoke, ending in a wisp
    tp = [V(0, -0.85, 0.95), V(0.2, -1.45, 0.85), V(0.55, -1.8, 1.35), V(0.6, -1.6, 2.1), V(0.3, -1.2, 2.45)]
    v.joint("Tail", tuple(tp[0]), "Body", "tail")
    cols = ["Soot", "Smoke", "Smoke", "Smoke2", "Smoke3"]
    for k in range(13):
        t = k / 12 * 3.999; i = int(t); u = t - i
        c = tp[i].lerp(tp[i + 1], u); r = 0.26 * (1 - k / 16)
        v.ell("Tail", cols[min(int(k / 13 * 5), 4)], tuple(c), (r, r, r))
    for k in range(3): v.crystal("Tail", "Smoke3", tp[4], (-0.3 + k * 0.3, 0.4, 1), 0.4 - k * 0.08, 0.07, sides=4)
    v.anchor("tail", "Tail", tuple(tp[4]))
    # the head: low and forward, ring eyes, slit pupils, tall tufted ears, a jagged grin
    v.joint("Head", (0, 0.65, 1.7), "Body", "head")
    v.muscle("Head", "Soot", (0, 0.85, 1.95), (0.58, 0.52, 0.48))
    P.shade(v, "Soot", parts={"Head"})
    for s in (-1, 1):
        v.eye("Head", (s * 0.25, 1.28, 2.04), (s * 0.35, 1, 0.05), w=0.3, h=0.3, iris="Ring")  # d3: the kit's eye (d1/d2 boxes read as goggles)
        v.ell("Head", "SootHi", (s * 0.27, 1.22, 2.27), (0.2, 0.08, 0.06), rot=E(0, s * -18, 0))  # a heavy brow over it
        v.crystal("Head", "Soot", V(s * 0.32, 0.75, 2.35), (s * 0.35, -0.1, 1), 0.85, 0.22, sides=4)  # tall cat ears
        v.crystal("Head", "Inner", V(s * 0.32, 0.82, 2.4), (s * 0.35, -0.1, 1), 0.5, 0.09, sides=4)
        v.crystal("Head", "SootHi", V(s * 0.45, 0.72, 3.1), (s * 0.4, 0, 1), 0.3, 0.05, sides=4)  # ear tufts
    v.box("Head", "Mouth", (0, 1.27, 1.72), (0.5, 0.06, 0.12))
    for k in range(5): v.crystal("Head", "Teeth", V(-0.2 + k * 0.1, 1.3, 1.78), (0, 0.2, -1), 0.12, 0.035, sides=4)  # the jagged grin
    v.anchor("eyes", "Head", (0, 1.3, 2.02)); v.anchor("speech", "Head", (0, 0.8, 3.0))
    # long thin arms reaching forward, sharp pale claws
    for s, A in ((-1, "ArmL"), (1, "ArmR")):
        sh, el, wr = V(s * 0.6, 0.45, 1.55), V(s * 0.85, 0.95, 1.0), V(s * 0.6, 1.35, 0.4)
        v.joint(A + "1", tuple(sh), "Body", "arm")
        v.cap(A + "1", "Soot", sh, el, 0.17, 0.13)
        v.joint(A + "2", tuple(el), A + "1", "arm")
        v.cap(A + "2", "Soot", el, wr, 0.13, 0.12)
        for k in range(3): v.crystal(A + "2", "Claw", wr + V((k - 1) * 0.08, 0.1, -0.05), ((k - 1) * 0.3, 1, -0.8), 0.3, 0.04, sides=4)
        v.anchor("hand" + A[3:], A + "2", tuple(wr))
    for s, L in ((-1, "LegL"), (1, "LegR")):  # crouched hind legs
        hip, knee, foot = V(s * 0.4, -0.4, 0.85), V(s * 0.5, 0.1, 0.45), V(s * 0.48, -0.15, 0.0)
        v.joint(L + "1", tuple(hip), "Body", "leg")
        v.cap(L + "1", "Soot", hip, knee, 0.24, 0.17)
        v.cap(L + "1", "Soot", knee, foot + V(0, 0, 0.12), 0.15, 0.12)
        v.ell(L + "1", "Soot", tuple(foot + V(0, 0.15, 0.08)), (0.16, 0.28, 0.1))
        for k in range(3): v.crystal(L + "1", "Claw", foot + V((k - 1) * 0.08, 0.3, 0.06), (0, 1, -0.4), 0.14, 0.04, sides=4)  # d3: on the toes, not on the floor in front
        v.anchor("foot" + L[3:], L + "1", tuple(foot))
    P.ground(v)


# ---------------------------------------------------------------- CLAYLING: the layer 2 weeping-angel pottery idol (an enemy)
# a fired-clay guardian jar on chunky legs: a cracked terracotta amphora torso with mint glaze drips and glowing amber seams
# in the cracks, a carved lid-crown head with slanted brow fissures and a jagged glowing grin, chunky clawed arms
@char("Clayling", P.palette(form=("Clay",), Clay="#c4643a", ClayDark="#8a3e22", ClayLi="#e08a5a", Glaze="#7ae8c8", GlazeDark="#3ea88a",
                            Seam="#ffb040", SeamHot="#fff0a0", Crack="#3a1a10", Eye="#1a0c08", Shine="#ffffff", Claw="#f0e0c8"))
def clayling(v):
    E = P.E
    v.joint("Body", (0, 0, 1.6))
    # the amphora: a round belly, a waist, a shoulder, a neck
    v.muscle("Body", "Clay", (0, 0, 1.55), (0.85, 0.85, 0.85))
    v.ell("Body", "Clay", (0, 0, 2.35), (0.6, 0.6, 0.28))
    v.cap("Body", "Clay", V(0, 0, 0.75), V(0, 0, 1.0), 0.45, 0.6)
    P.shade(v, "Clay")
    v.torus("Body", "ClayDark", (0, 0, 2.12), (0, 0, 1), 0.72, 0.07)
    v.torus("Body", "ClayLi", (0, 0, 1.25), (0, 0, 1), 0.82, 0.05)
    # mint glaze poured over the shoulder, running down in drips
    v.ell("Body", "Glaze", (0, 0, 2.3), (0.66, 0.66, 0.2))
    for k in range(9):
        a = k / 9 * math.tau + 0.2; L = 0.35 + (k * 37 % 5) * 0.12
        top = V(math.cos(a) * 0.74, math.sin(a) * 0.74, 2.2)
        v.cap("Body", "Glaze" if k % 2 else "GlazeDark", top, top + V(math.cos(a) * 0.1, math.sin(a) * 0.1, -L), 0.07, 0.09)
    # cracks with molten seams: zigzag lines on the belly, dark rims round glowing cores
    for pts in ([(-0.5, 0.7, 1.9), (-0.3, 0.8, 1.6), (-0.45, 0.75, 1.3), (-0.2, 0.82, 1.0)], [(0.35, 0.75, 2.0), (0.5, 0.68, 1.7), (0.3, 0.78, 1.45)],
                [(0.6, -0.55, 1.8), (0.75, -0.35, 1.5), (0.55, -0.6, 1.2)], [(-0.7, -0.4, 1.7), (-0.55, -0.62, 1.35)]):
        v.line("Body", "Crack", pts, r=0.07)
        v.line("Body", "Seam", [(x * 1.03, y * 1.03, z) for (x, y, z) in pts], r=0.04)
    v.anchor("chest", "Body", (0, 0.85, 1.7))
    # the head: a carved lid crown on the neck, slanted brow fissures over glowing eyes, a jagged glowing grin
    v.joint("Head", (0, 0, 2.5), "Body", "head")
    v.cap("Head", "Clay", V(0, 0, 2.5), V(0, 0, 2.75), 0.36, 0.42)
    v.ell("Head", "Clay", (0, 0.05, 3.1), (0.56, 0.5, 0.42))
    P.shade(v, "Clay", parts={"Head"})
    for k in range(6):  # the crown's carved points
        a = k / 6 * math.tau
        v.crystal("Head", "ClayLi" if k % 2 else "ClayDark", V(math.cos(a) * 0.42, math.sin(a) * 0.38, 3.4), (math.cos(a) * 0.3, math.sin(a) * 0.3, 1), 0.36, 0.1, sides=4)
    v.ell("Head", "Glaze", (0, 0.0, 3.45), (0.3, 0.28, 0.12))
    for s in (-1, 1):
        v.box("Head", "Crack", (s * 0.22, 0.5, 3.22), (0.32, 0.08, 0.08), rot=E(0, s * 28, 0))  # slanted brow fissures
        v.carve(lambda x, y, z, s=s: abs(x - s * 0.2) < 0.14 and y > 0.4 and 3.0 < z < 3.16, part="Head")  # d2: a socket (d1: proud pegs)
        v.ell("Head", "Seam", (s * 0.2, 0.38, 3.08), (0.12, 0.05, 0.08))
        v.ell("Head", "SeamHot", (s * 0.2, 0.42, 3.08), (0.06, 0.03, 0.04))
    v.box("Head", "Crack", (0, 0.52, 2.86), (0.46, 0.08, 0.14))
    for k in range(5): v.crystal("Head", "Seam", V(-0.18 + k * 0.09, 0.56, 2.93 if k % 2 else 2.79), (0, 0.3, -1 if k % 2 else 1), 0.1, 0.03, sides=4)
    v.anchor("eyes", "Head", (0, 0.55, 3.08)); v.anchor("speech", "Head", (0, 0.0, 4.0))
    # chunky arms: clay segments, banded joints, three-fingered claws
    for s, A in ((-1, "ArmL"), (1, "ArmR")):
        sh, el, wr = V(s * 0.82, 0.0, 2.15), V(s * 1.5, 0.35, 1.6), V(s * 1.55, 0.85, 1.05)  # d2: daylight under the arms
        v.joint(A + "1", tuple(sh), "Body", "arm")
        v.cap(A + "1", "Clay", sh, el, 0.24, 0.2)
        v.torus(A + "1", "ClayDark", el, tuple((el - sh).normalized()), 0.2, 0.05)
        v.joint(A + "2", tuple(el), A + "1", "arm")
        v.cap(A + "2", "ClayLi", el, wr, 0.2, 0.22)
        for k in range(3): v.crystal(A + "2", "Claw", wr + V((k - 1) * 0.1, 0.1, -0.08), ((k - 1) * 0.4, 0.8, -1), 0.32, 0.06, sides=4)
        v.anchor("hand" + A[3:], A + "2", tuple(wr))
    for s, L in ((-1, "LegL"), (1, "LegR")):
        hip, foot = V(s * 0.38, 0.0, 0.8), V(s * 0.5, 0.15, 0.0)
        v.joint(L + "1", tuple(hip), "Body", "leg")
        v.cap(L + "1", "ClayDark", hip, foot + V(0, 0, 0.2), 0.24, 0.22)
        v.ell(L + "1", "Clay", tuple(foot + V(0, 0.18, 0.12)), (0.26, 0.36, 0.14))
        v.anchor("foot" + L[3:], L + "1", tuple(foot))
    P.ground(v)



# ---------------------------------------------------------------- ROOT WARDEN: the Camp 1 deep gate boss (13 studs, 0.17-stud voxels)
# a hunched slate-and-moss titan: a forward-pitched wedge chest laced with twisted petrified root cords, a heavy brow over
# turquoise slit eyes, a hinged moss-rock jaw, asymmetric turquoise crystal spires out of the spine, shoulders and crest,
# huge gorilla arms ending in root-bound boulder fists with crystal knuckles and glowing fissures, short pillar legs,
# and three dark sockets (left shoulder, right chest, solar plexus) where the amber knot hearts lock in
SCALE = {"RootWarden": 0.17, "KilnGolem": 0.17}


@char("RootWarden", P.palette(form=("Slate", "Moss"), Slate="#4c5668", SlateDark="#30384a", Moss="#5a8c4c", MossDark="#3a6a34", Bark="#3c2c24",
                              BarkHi="#5c4434", Crystal="#4ae0d8", CrystalHi="#c8fff8", Glow="#7afff0", Socket="#1a1418", Amber="#ffb040",
                              Teeth="#cfc6b4", Eye="#0a1418", Shine="#ffffff"))
def warden(v):
    E = P.E
    v.joint("Body", (0, 0, 6.2))
    v.muscle("Body", "Slate", (0, 0.7, 7.6), (3.1, 2.2, 2.4), rot=E(-22, 0, 0))  # the wedge chest, pitched forward
    v.muscle("Body", "Slate", (0, -0.3, 5.3), (2.3, 1.9, 1.7))  # the hips
    for s in (-1, 1): v.muscle("Body", "Slate", (s * 2.5, 0.3, 8.6), (1.4, 1.4, 1.2))  # shoulder masses
    v.muscle("Body", "Moss", (0, -0.4, 9.0), (2.6, 1.8, 0.8))  # moss over the shoulders and upper back
    for s in (-1, 1): v.muscle("Body", "Moss", (s * 2.6, 0.1, 9.55), (1.2, 1.1, 0.45))
    P.shade(v, "Slate", "Moss")
    # twisted petrified root cords across the chest and over the shoulders
    for s in (-1, 1):
        v.tube("Body", "Bark", [V(s * 3.0, 0.9, 9.2), V(s * 1.6, 2.4, 8.2), V(-s * 0.4, 2.7, 6.9), V(-s * 1.8, 2.0, 5.6)], [0.32, 0.36, 0.32, 0.26])
        v.tube("Body", "BarkHi", [V(s * 3.1, 0.7, 9.4), V(s * 2.6, -0.8, 9.5), V(s * 1.2, -2.0, 8.4)], [0.26, 0.3, 0.22])
    v.tube("Body", "Bark", [V(-2.2, -1.6, 7.5), V(0, -2.2, 6.8), V(2.2, -1.7, 6.0)], [0.3, 0.34, 0.28])
    # crystal spires: asymmetric clusters out of the spine and the left shoulder
    for (x, y, z, dx, dy, dz, L, w) in ((-0.6, -1.6, 9.2, -0.2, -0.6, 1, 3.4, 0.55), (0.5, -1.8, 8.6, 0.3, -0.7, 1, 2.6, 0.45), (-0.1, -2.1, 7.6, 0, -1, 0.6, 2.2, 0.4),
                                        (-2.9, 0.0, 9.8, -0.5, -0.2, 1, 2.8, 0.5), (-3.3, 0.5, 9.4, -1, 0.1, 0.8, 1.8, 0.35), (2.9, -0.4, 9.7, 0.3, -0.4, 1, 1.5, 0.3),
                                        (0.0, -2.0, 6.0, 0.2, -1, 0.3, 1.6, 0.35)):
        v.crystal("Body", "Crystal", V(x, y, z), (dx, dy, dz), L, w, sides=5)
        v.crystal("Body", "CrystalHi", V(x, y, z) + V(dx, dy, dz).normalized() * L * 0.35, (dx, dy, dz), L * 0.45, w * 0.35, sides=4)
    # the knot sockets: dark rings where the amber hearts lock in
    for key, c, n in (("Knot1", V(-2.7, 1.2, 9.1), (-0.4, 0.6, 0.6)), ("Knot2", V(1.5, 2.6, 7.7), (0.2, 1, 0.1)), ("Knot3", V(0, 2.25, 6.1), (0, 1, -0.1))):
        v.torus("Body", "Socket", c, n, 0.55, 0.16)
        v.ell("Body", "Socket", tuple(c), (0.45, 0.45, 0.45))
        v.ell("Body", "Amber", tuple(c + V(*n).normalized() * 0.2), (0.3, 0.3, 0.3))
        v.anchor(key, "Body", tuple(c))
    # the head: low and forward between the shoulders, a heavy brow, slit eyes, a crest of crystals
    v.joint("Head", (0, 1.9, 8.9), "Body", "head")
    v.muscle("Head", "Slate", (0, 2.6, 9.3), (1.45, 1.3, 1.2))
    P.shade(v, "Slate", parts={"Head"})
    v.box("Head", "SlateDark", (0, 3.55, 9.75), (2.6, 0.7, 0.55), rot=E(-10, 0, 0))  # the brow ridge
    v.muscle("Head", "Moss", (0, 2.4, 10.25), (1.2, 1.1, 0.4))
    for s in (-1, 1):
        v.box("Head", "Eye", (s * 0.62, 3.92, 9.3), (0.9, 0.24, 0.42))  # a socket at the face (d2: the eyes sat inside the head)
        v.box("Head", "Glow", (s * 0.62, 4.04, 9.3), (0.78, 0.12, 0.24))  # the turquoise slit
        v.box("Head", "CrystalHi", (s * 0.62, 4.09, 9.3), (0.36, 0.06, 0.1))
    for k, (x, L) in enumerate(((-0.4, 1.6), (0.15, 2.2), (0.6, 1.3))):  # the forehead crest
        v.crystal("Head", "Crystal", V(x, 2.6, 10.4), (x * 0.4, -0.3, 1), L, 0.32, sides=5)
    v.anchor("eyes", "Head", (0, 3.8, 9.32)); v.anchor("speech", "Head", (0, 2.0, 12.5))
    # the jaw: a hinged moss-rock mandible with stone teeth
    v.joint("Jaw", (0, 2.6, 8.45), "Head", "head")
    v.ell("Jaw", "Slate", (0, 3.1, 8.3), (1.25, 1.05, 0.55))
    v.ell("Jaw", "Moss", (0, 3.0, 7.95), (1.0, 0.9, 0.25))
    for k, (x, L) in enumerate(((-0.75, 0.5), (-0.2, 0.3), (0.35, 0.55), (0.8, 0.25))):  # d4: a few uneven stone teeth (d3: an even white "radiator")
        v.crystal("Jaw", "SlateDark" if k % 2 else "Teeth", V(x, 3.85, 8.6), (0.1 * (k - 1.5), 0.25, 1), L, 0.16, sides=4)
    # arms: huge gorilla arms knuckling forward, root-bound forearms, boulder fists with crystal knuckles
    for s, A in ((-1, "ArmL"), (1, "ArmR")):
        sh, el, wr = V(s * 3.1, 0.6, 8.5), V(s * 4.9, 1.5, 6.2), V(s * 4.9, 2.6, 2.8)  # d2: flared out, daylight under the arms
        v.joint(A, tuple(sh), "Body", "arm")
        v.cap(A, "Slate", sh, el, 1.15, 0.95)
        v.muscle(A, "Moss", tuple(sh + V(0, 0, 0.7)), (1.0, 1.0, 0.5))
        v.joint(A + "2", tuple(el), A, "arm")
        v.cap(A + "2", "Slate", el, wr, 0.95, 1.05)
        for t in (0.25, 0.55, 0.8): v.torus(A + "2", "Bark", el.lerp(wr, t), tuple((wr - el).normalized()), 1.0, 0.18)  # root bindings
        fist = wr + V(0, 0.3, -1.0)
        v.muscle(A + "2", "Slate", tuple(fist), (1.55, 1.5, 1.35))
        for k in range(4): v.crystal(A + "2", "Crystal", fist + V((k - 1.5) * 0.65, 1.1, -0.2), ((k - 1.5) * 0.2, 1, -0.5), 1.0, 0.3, sides=5)  # crystal knuckles
        v.line(A + "2", "Glow", [fist + V(s * 1.3, 0.4, 0.6), fist + V(s * 1.45, 0.1, 0.0), fist + V(s * 1.3, 0.5, -0.6)], r=0.12)  # a glowing fissure
        v.anchor("hand" + A[3:], A + "2", tuple(fist))
    # short pillar legs, wide feet
    for s, L in ((-1, "LegL"), (1, "LegR")):
        hip, foot = V(s * 1.7, -0.6, 4.6), V(s * 2.1, -0.2, 0.0)
        v.joint(L, tuple(hip), "Body", "leg")
        v.cap(L, "Slate", hip, foot + V(0, 0, 0.8), 1.2, 1.0)
        v.ell(L, "SlateDark", tuple(foot + V(0, 0.4, 0.5)), (1.25, 1.55, 0.6))
        v.ell(L, "Moss", tuple(hip + V(0, 0, 0.2)), (1.0, 0.9, 0.4))
        v.anchor("foot" + L[3:], L, tuple(foot + V(0, 0.4, 0.3)))
    P.ground(v)



# ---------------------------------------------------------------- KILN GOLEM: the Camp 2 Clay Caves boss (14 studs, 0.17-stud voxels)
# a barrel-chested furnace colossus: fired terracotta and smoked bronze, banded amphora-rim bronze collars, riveted iron boiler
# straps, cream glaze bands, magma seams, an open iron grille in the belly full of glowing coals, a kiln-dome head under a heavy
# clay visor with molten slit eyes, a hinged bronze chimney lid on top, colossal forge-hammer fists studded with rivets,
# and three vent sockets (Knot1..3) for the glowing kiln vents
@char("KilnGolem", P.palette(form=("Clay", "Bronze"), Clay="#c4643a", ClayDark="#8a3e22", Cream="#f0e0c0", Bronze="#8a6a3a", BronzeDark="#4e3a22",
                             Iron="#4a4650", IronDark="#2c2a32", Rivet="#d8b060", Coal="#ff7a20", CoalHot="#ffd060", Seam="#ffb040", Socket="#1a1210",
                             Smoke="#5a5058", Eye="#120806", Shine="#ffffff"))
def golem(v):
    E = P.E
    v.joint("Body", (0, 0, 6.5))
    v.muscle("Body", "Clay", (0, 0.2, 7.4), (3.2, 2.6, 2.9))  # the barrel chest
    v.muscle("Body", "Clay", (0, 0.0, 5.0), (2.6, 2.2, 1.6))  # the belly and hips
    for s in (-1, 1): v.muscle("Body", "Bronze", (s * 2.9, 0.1, 9.0), (1.4, 1.4, 1.1))  # bronze shoulder caps
    P.shade(v, "Clay", "Bronze")
    for z0, z1, col in ((9.25, 9.55, "Bronze"), (8.05, 8.4, "Bronze"), (5.85, 6.15, "Bronze"), (7.1, 7.3, "Cream")):  # banded collars painted on the barrel (d1: round rings floated off the oval chest)
        v.paint(col, lambda x, y, z, z0=z0, z1=z1: z0 <= z <= z1, part="Body", only={"Clay", "ClayHi", "ClayLo", "ClayCrease"})
    for s in (-1, 1):  # riveted iron boiler straps over the shoulders
        v.tube("Body", "Iron", [V(s * 1.4, 2.2, 9.0), V(s * 1.6, 2.65, 7.4), V(s * 1.3, 2.4, 5.6)], [0.22, 0.24, 0.22])
        for z in (8.6, 7.8, 7.0, 6.2): v.ell("Body", "Rivet", (s * 1.55, 2.82 if z > 6.5 else 2.55, z), (0.12, 0.08, 0.12))
    # the furnace: an open iron grille across the lower chest, coals glowing behind the bars
    v.ell("Body", "IronDark", (0, 2.2, 6.4), (1.5, 0.5, 0.9))
    v.ell("Body", "Coal", (0, 2.35, 6.35), (1.25, 0.35, 0.72))
    for k in range(6): v.ell("Body", "CoalHot", (-1.0 + k * 0.4, 2.55, 6.1 + (k % 2) * 0.35), (0.16, 0.1, 0.14))
    for k in range(5): v.box("Body", "Iron", (-0.96 + k * 0.48, 2.75, 6.4), (0.14, 0.14, 1.7))  # the bars
    v.box("Body", "Iron", (0, 2.75, 7.2), (2.4, 0.16, 0.16)); v.box("Body", "Iron", (0, 2.75, 5.6), (2.4, 0.16, 0.16))
    # magma seams in the clay
    for pts in ([(-2.4, 1.6, 8.6), (-2.0, 1.9, 7.9), (-2.3, 1.7, 7.4)], [(2.2, 1.7, 8.8), (2.5, 1.4, 8.0)], [(1.8, -1.9, 7.5), (2.2, -1.5, 6.8), (1.9, -1.8, 6.2)]):
        v.line("Body", "Seam", pts, r=0.12)
    for key, c, n in (("Knot1", V(-2.0, 1.9, 8.9), (-0.4, 0.8, 0.4)), ("Knot2", V(2.1, 2.0, 7.4), (0.4, 1, 0.1)), ("Knot3", V(0, -2.4, 7.6), (0, -1, 0.2))):
        v.torus("Body", "Bronze", c, n, 0.6, 0.18)
        v.ell("Body", "Socket", tuple(c), (0.48, 0.48, 0.48))
        v.ell("Body", "Seam", tuple(c + V(*n).normalized() * 0.2), (0.3, 0.3, 0.3))
        v.anchor(key, "Body", tuple(c))
    # the head: a kiln dome under a heavy visor brow, molten slit eyes
    v.joint("Head", (0, 0.4, 9.6), "Body", "head")
    v.muscle("Head", "Clay", (0, 0.5, 10.6), (1.7, 1.6, 1.4))
    P.shade(v, "Clay", parts={"Head"})
    v.box("Head", "ClayDark", (0, 2.0, 11.2), (3.0, 0.8, 0.5), rot=E(-8, 0, 0))  # the visor brow, raised off the eyes (g4)
    for s in (-1, 1):
        v.carve(lambda x, y, z, s=s: abs(x - s * 0.68) < 0.55 and y > 1.75 and 10.36 < z < 10.86, part="Head")  # g5: a socket cut into the dome (g4 proud blocks read as googly eyes)
        v.box("Head", "Eye", (s * 0.68, 1.7, 10.61), (1.1, 0.12, 0.5))  # its dark back
        v.box("Head", "Seam", (s * 0.68, 1.78, 10.61), (0.9, 0.1, 0.3))  # the molten slit glowing in it
        v.box("Head", "Coal", (s * 0.68, 1.84, 10.61), (0.5, 0.06, 0.14))
    v.box("Head", "IronDark", (0, 2.0, 10.0), (1.4, 0.2, 0.2))  # the mouth vent
    v.torus("Head", "Bronze", (0, 0.5, 11.6), (0, 0, 1), 1.25, 0.18)
    v.anchor("eyes", "Head", (0, 2.1, 10.5)); v.anchor("speech", "Head", (0, 0.4, 14.0))
    # the chimney lid: a hinged bronze damper stack on the crown
    v.joint("Lid", (0, -0.4, 11.8), "Head", "head")
    v.cap("Lid", "Bronze", V(0, 0.3, 11.7), V(0, 0.3, 12.7), 0.75, 0.6)
    v.torus("Lid", "BronzeDark", V(0, 0.3, 12.7), (0, 0, 1), 0.62, 0.14)
    v.ell("Lid", "BronzeDark", (0, 0.3, 12.85), (0.85, 0.85, 0.18))
    v.ell("Lid", "Smoke", (0.1, 0.25, 13.3), (0.45, 0.45, 0.35))
    v.ell("Lid", "Smoke", (-0.2, 0.15, 13.75), (0.32, 0.32, 0.26))
    # arms: bronze-banded clay arms ending in colossal forge-hammer fists studded with rivets
    for s, A in ((-1, "ArmL"), (1, "ArmR")):
        sh, el, wr = V(s * 3.4, 0.2, 8.6), V(s * 5.0, 0.9, 6.4), V(s * 5.1, 1.8, 3.6)  # g3: flared out, daylight under the arms (d2: one block in the blackout)
        v.joint(A, tuple(sh), "Body", "arm")
        v.cap(A, "Clay", sh, el, 1.15, 1.0)
        v.joint(A + "2", tuple(el), A, "arm")
        v.cap(A + "2", "Clay", el, wr, 1.0, 1.1)
        for t in (0.2, 0.6): v.torus(A + "2", "Bronze", el.lerp(wr, t), tuple((wr - el).normalized()), 1.08, 0.2)
        fist = wr + V(0, 0.2, -1.2)
        v.muscle(A + "2", "Bronze", tuple(fist), (1.25, 1.15, 1.0))  # g3: a gauntlet fist, not a block
        for k in range(4): v.cap(A + "2", "BronzeDark", fist + V((k - 1.5) * 0.55, 0.9, 0.4), fist + V((k - 1.5) * 0.6, 1.35, -0.6), 0.32, 0.28)  # curled fingers
        v.cap(A + "2", "BronzeDark", fist + V(-s * 1.0, 0.6, 0.2), fist + V(-s * 1.2, 1.2, -0.3), 0.3, 0.26)  # the thumb
        for cx in (-0.8, 0, 0.8):
            for cz in (-0.6, 0.6): v.ell(A + "2", "Rivet", tuple(fist + V(cx, 1.12, cz)), (0.18, 0.1, 0.18))
        v.line(A + "2", "Seam", [fist + V(s * 1.22, 0.6, 0.7), fist + V(s * 1.25, -0.2, 0.0), fist + V(s * 1.22, 0.4, -0.7)], r=0.12)
        v.anchor("hand" + A[3:], A + "2", tuple(fist))
    for s, L in ((-1, "LegL"), (1, "LegR")):
        hip, foot = V(s * 1.8, -0.2, 4.4), V(s * 2.2, 0.1, 0.0)
        v.joint(L, tuple(hip), "Body", "leg")
        v.cap(L, "Clay", hip, foot + V(0, 0, 0.9), 1.25, 1.1)
        v.torus(L, "Bronze", hip.lerp(foot, 0.55), (0, 0, 1), 1.2, 0.2)
        v.ell(L, "ClayDark", tuple(foot + V(0, 0.4, 0.5)), (1.3, 1.6, 0.6))
        v.anchor("foot" + L[3:], L, tuple(foot + V(0, 0.4, 0.3)))
    P.ground(v)


HERE_CHARS = os.path.dirname(os.path.abspath(__file__))


if __name__ == "__main__":
    rp = os.path.join(HERE_CHARS, "rigs_npc.json")  # NPC rigs stay out of the pets' rigs.json (make_rig_lua.py would list them as pets)
    db = json.load(open(rp)) if os.path.exists(rp) else {}
    for name, (pal, fn) in D.items():
        if ONLY and name not in ONLY: continue
        v = X.Vox(name, pal, s=SCALE.get(name, 0.1))  # the bosses build in chunkier 0.17-stud voxels (v17 brief)
        fn(v)
        c = v.build()
        d = K.export(c, OUT)
        d["cells"] = len(v.cells); d["proportions"] = P.proportions(v); d["npc"] = True
        db[name] = d
        print(f"{name}: {len(v.cells)} cells, {d['tris']} triangles, {d['parts']} parts, {d['objects']} objects, size {d['size']}", flush=True)
    json.dump(db, open(rp, "w"), indent=1)
