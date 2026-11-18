"""Voxel pets for Pixel Depth (2026-11-17, brief: vault Projects/Pixel-_/Briefs/Egg Hatching v3 (2026-11-17).md).
One small voxel language builds all 13 pets; `python design3d/pets/pets.py` writes design3d/pets/pets.json, which drives
both the design board (design3d/pets/board.html, live three.js preview) and the Blender build (design3d/pets/build_pets.py).
Coordinates are voxels: x across (0 is the middle), y up (0 is the floor), z forward (+z is where the pet looks).
Each voxel belongs to a PART (moves as one piece: Body, Head, legs, Tail, wings, ...) and a ROLE (its colour in PALETTES).
Design rules (research note Craft Videos for Weak Grades (2026-11-17)):
  * head about 45% of the height, eyes 2 voxels tall with a 1-voxel shine, set low on the face (cute = big low eyes)
  * shape language by role: round for gentle helpers (Selkie, Kepri, Glimwisp), square for sturdy workers (Tosk, Kobold),
    pointed for fierce rares (Zharbird, Fafnir, Kirin, Ouro)
  * one signature silhouette feature each (tusks, helmet lamp, shell, mane, bristles, horn, fins, crest, wings, rings)
  * 4 to 6 colours each: Main, Dark (underside and shade), Light (belly and top), Accent (the glowing signature), Eye, Shine"""
import json, math, os

VOX = 0.16  # studs per voxel


class Pet:
    def __init__(self, name):
        self.name, self.v, self.pivots = name, {}, {}

    def put(self, x, y, z, part, role):
        self.v[(x, y, z)] = (part, role)

    def box(self, part, role, x0, x1, y0, y1, z0, z1, sym=False):
        for x in range(min(x0, x1), max(x0, x1) + 1):
            for y in range(min(y0, y1), max(y0, y1) + 1):
                for z in range(min(z0, z1), max(z0, z1) + 1):
                    self.put(x, y, z, part, role)
                    if sym: self.put(-x, y, z, part, role)

    def ell(self, part, role, cx, cy, cz, rx, ry, rz, cut=None):
        for x in range(math.floor(cx - rx), math.ceil(cx + rx) + 1):
            for y in range(math.floor(cy - ry), math.ceil(cy + ry) + 1):
                for z in range(math.floor(cz - rz), math.ceil(cz + rz) + 1):
                    if ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 + ((z - cz) / rz) ** 2 <= 1.0 and (cut is None or cut(x, y, z)):
                        self.put(x, y, z, part, role)

    def paint(self, role, test, part=None):
        """recolour voxels already placed that pass test(x, y, z) (and belong to part, if given)"""
        for k, (p, r) in list(self.v.items()):
            if test(*k) and (part is None or p == part):
                self.v[k] = (p, role)

    def eyes(self, part, y, z, dx=2, h=3):
        """two big eyes on the face, bottom at height y, on the front face z: 2 wide and h tall from x = dx outward, a
        2-voxel shine at the top inner corner (big low eyes read as cute; 1-wide eyes vanished in the preview)"""
        for s in (-1, 1):
            for xx in (dx - 1, dx):
                for yy in range(y, y + h):
                    self.put(s * xx, yy, z, part, "Eye")
                    self.put(s * xx, yy, z + 1, part, "Eye")
            self.put(s * (dx - 1), y + h - 1, z + 1, part, "Shine")
            self.put(s * dx, y + h - 1, z + 1, part, "Shine")
            self.put(s * (dx - 1), y + h - 2, z + 1, part, "Shine")

    def legs(self, y1, xs, zs, w=1, part="Leg", role="Dark"):
        n = 0
        for z in zs:
            for x in xs:
                n += 1
                nm = f"{part}{n}"
                self.box(nm, role, x, x + w - 1, 0, y1, z, z + w - 1)
                self.pivots[nm] = (x + (w - 1) / 2, y1 + 0.5, z + (w - 1) / 2)

    def stilts(self, dy):
        """raise everything but the legs by dy voxels and lengthen the legs to match (a taller, leggier silhouette)"""
        moved = {}
        for (x, y, z), (part, role) in self.v.items():
            if part.startswith("Leg"):
                moved[(x, y, z)] = (part, role)
            else:
                moved[(x, y + dy, z)] = (part, role)
        legs = {}
        for (x, y, z), (part, role) in self.v.items():
            if part.startswith("Leg"):
                top = max(yy for (xx, yy, zz), (pp, rr) in self.v.items() if pp == part)
                if y == top:
                    for k in range(1, dy + 1): legs[(x, y + k, z)] = (part, "Main" if role == "Hoof" else role)
        moved.update(legs)
        self.v = moved
        self.pivots = {k: (v[0], v[1] + dy, v[2]) for k, v in self.pivots.items()}

    def data(self):
        parts = {}
        for (x, y, z), (p, r) in self.v.items():
            parts.setdefault(p, []).append([x, y, z, r])
        ys = [k[1] for k in self.v]
        return {"name": self.name, "vox": VOX, "height": max(ys) + 1, "parts": parts, "pivots": self.pivots}


PALETTES = {
    "Tosk": {"Main": "#a8622f", "Dark": "#6e3c1e", "Light": "#d79a5f", "Accent": "#78ffc8", "Tusk": "#f3ead2", "Pack": "#5a4a78", "Eye": "#1c1026", "Shine": "#ffffff"},
    "Kobold": {"Main": "#7f9446", "Dark": "#55652c", "Light": "#b7c46f", "Accent": "#ff9a3c", "Helmet": "#d8a23a", "Eye": "#1c1026", "Shine": "#ffffff"},
    "Kepri Scarab": {"Main": "#7a5e2c", "Dark": "#4a3818", "Light": "#b0904a", "Accent": "#ffd24f", "Eye": "#1c1026", "Shine": "#ffffff"},
    "Shinemane": {"Main": "#f2f0fa", "Dark": "#c8c2dc", "Light": "#ffffff", "Accent": "#fff0a0", "Hoof": "#8a7aa8", "Eye": "#1c1026", "Shine": "#ffffff"},
    "Goldbristle": {"Main": "#d6a034", "Dark": "#9c6c1c", "Light": "#f4d79a", "Accent": "#ffe66e", "Nose": "#3a2418", "Eye": "#1c1026", "Shine": "#ffffff"},
    "Pixiu": {"Main": "#3c9a6e", "Dark": "#256646", "Light": "#8fd8a8", "Accent": "#ffd25a", "Eye": "#1c1026", "Shine": "#ffffff"},
    "Glimwisp": {"Main": "#3cc8aa", "Dark": "#1f8a78", "Light": "#b4fff0", "Accent": "#e6fffa", "Eye": "#103a34", "Shine": "#ffffff"},
    "Selkie": {"Main": "#46507a", "Dark": "#2c3252", "Light": "#c8dcff", "Accent": "#9fe0ff", "Eye": "#0e0c1c", "Shine": "#ffffff"},
    "Zharbird": {"Main": "#e65a1e", "Dark": "#a8340e", "Light": "#ffb04a", "Accent": "#ffe050", "Beak": "#ffd27a", "Eye": "#1c1026", "Shine": "#ffffff"},
    "Fafnir": {"Main": "#46784a", "Dark": "#2a4c2e", "Light": "#9cc87a", "Accent": "#ffc83c", "Horn": "#f0e2b4", "Eye": "#1c1026", "Shine": "#ffffff"},
    "Kirin": {"Main": "#5aa0c8", "Dark": "#356c92", "Light": "#cfe8f6", "Accent": "#ff963c", "Horn": "#ffe6a0", "Hoof": "#3a2c4c", "Eye": "#1c1026", "Shine": "#ffffff"},
    "Ouro": {"Main": "#4a3474", "Dark": "#2c1e44", "Light": "#7a5aa8", "Accent": "#ff5a8c", "Eye": "#ffd6ea", "Shine": "#ffffff"},
    "Ninering": {"Main": "#efe6f6", "Dark": "#b8a4d0", "Light": "#ffffff", "Accent": "#ffffff", "Ring": "#ffd24a", "Blush": "#ffb0c4", "Eye": "#3c2a10", "Shine": "#ffffff"},
}


def tosk():  # square: a stocky boar hauler, tusks and a cargo pack
    p = Pet("Tosk")
    p.box("Body", "Main", -4, 4, 3, 8, -5, 3)
    p.box("Body", "Light", -3, 3, 3, 3, -4, 2)
    p.box("Body", "Pack", -3, 3, 9, 11, -4, 1)
    p.box("Body", "Accent", -1, 1, 12, 12, -2, -1)  # a glowing ore on the pack
    p.box("Head", "Main", -4, 4, 4, 11, 4, 9)
    p.box("Head", "Light", -2, 2, 4, 6, 10, 11)  # snout
    p.put(-1, 5, 12, "Head", "Dark"); p.put(1, 5, 12, "Head", "Dark")
    for s in (-1, 1):
        p.box("Head", "Tusk", s * 3, s * 3, 5, 8, 10, 10)
        p.put(s * 3, 8, 11, "Head", "Accent")
        p.box("Head", "Dark", s * 4, s * 4, 11, 12, 6, 7)  # ears
    p.eyes("Head", 8, 10, dx=2)
    p.pivots["Head"] = (0, 7, 4)
    p.legs(2, [-4, 3], [-5, 2], w=2)
    p.box("Body", "Main", -5, 5, 4, 7, -4, 2)  # a wide barrel body: the low, heavy hauler
    p.box("Tail", "Dark", 0, 0, 7, 9, -6, -6); p.pivots["Tail"] = (0, 7, -5.5)
    return p


def kobold():  # square: an upright little digger with a helmet lamp
    p = Pet("Kobold")
    p.box("Body", "Main", -3, 3, 3, 9, -2, 2)
    p.box("Body", "Light", -2, 2, 3, 8, 3, 3)
    p.box("Head", "Main", -4, 4, 10, 16, -3, 4)
    p.box("Head", "Light", -2, 2, 10, 12, 5, 6)  # snout
    p.box("Head", "Helmet", -4, 4, 17, 18, -3, 4)
    p.box("Head", "Helmet", -5, 5, 16, 16, -4, 5)
    p.box("Head", "Accent", -1, 1, 16, 18, 5, 5)  # the lamp
    p.eyes("Head", 13, 5, dx=2)
    p.pivots["Head"] = (0, 10, 0)
    p.legs(2, [-3, 2], [-1], w=2)
    for s, nm in ((-1, "ArmL"), (1, "ArmR")):
        p.box(nm, "Main", s * 4, s * 5, 5, 8, 0, 1); p.pivots[nm] = (s * 4.5, 8.5, 0.5)
    p.box("Tail", "Dark", 0, 0, 3, 4, -6, -3); p.box("Tail", "Accent", 0, 0, 5, 5, -6, -6); p.pivots["Tail"] = (0, 4, -2.5)
    return p


def kepri():  # round: a shiny dome beetle
    p = Pet("Kepri Scarab")
    p.ell("Body", "Main", 0, 5, 0, 5.5, 4.5, 6, cut=lambda x, y, z: y >= 2)
    p.paint("Accent", lambda x, y, z: abs(x) in (4, 5) and y in (5, 6), part="Body")
    p.paint("Light", lambda x, y, z: x == 0 and y >= 7, part="Body")  # shell seam
    p.paint("Dark", lambda x, y, z: y == 2, part="Body")
    p.box("Head", "Dark", -3, 3, 2, 6, 5, 8)
    p.eyes("Head", 4, 8, dx=2)
    for s in (-1, 1):
        p.box("Head", "Accent", s * 2, s * 2, 7, 8, 8, 8)  # antennae
        p.put(s * 3, 9, 8, "Head", "Accent")
    p.pivots["Head"] = (0, 4, 5)
    p.legs(1, [-5, 4], [-3, 2], w=2)
    return p


def shinemane():  # round and soft: a pony with a glowing mane
    p = Pet("Shinemane")
    p.box("Body", "Main", -3, 3, 5, 9, -5, 3)
    p.box("Body", "Light", -2, 2, 5, 5, -4, 2)
    p.box("Head", "Main", -3, 3, 9, 16, 2, 7)
    p.box("Head", "Light", -2, 2, 9, 11, 8, 9)  # muzzle
    p.box("Head", "Accent", -1, 1, 12, 18, -1, 2)  # mane down the back of the head
    p.box("Head", "Accent", -1, 1, 17, 17, 3, 6)
    for s in (-1, 1): p.box("Head", "Dark", s * 3, s * 3, 16, 17, 3, 4)  # ears
    p.eyes("Head", 12, 7, dx=2)
    p.pivots["Head"] = (0, 9, 3)
    p.legs(4, [-3, 2], [-5, 2], w=2, role="Main")
    for k in range(1, 5): p.paint("Hoof", lambda x, y, z: y == 0, part=f"Leg{k}")
    p.box("Tail", "Accent", -1, 1, 6, 9, -7, -6); p.box("Tail", "Accent", 0, 0, 2, 5, -7, -7); p.pivots["Tail"] = (0, 8, -5.5)
    p.box("Head", "Accent", -1, 1, 9, 12, -2, -1)  # the mane runs down the neck
    p.stilts(3)  # long legs: a pony, not a box (Gemini n17_hatch: the quadrupeds read as one brick)
    return p


def goldbristle():  # round with spikes: a lucky hedgehog
    p = Pet("Goldbristle")
    p.ell("Body", "Main", 0, 5, -1, 5, 4.5, 5.5, cut=lambda x, y, z: y >= 1)
    for x in range(-4, 5, 2):
        for z in range(-5, 3, 2):
            top = max((y for (vx, y, vz) in p.v if vx == x and vz == z), default=None)
            if top is not None and top >= 6: p.box("Body", "Accent", x, x, top + 1, top + 2, z, z)
    p.box("Head", "Light", -3, 3, 1, 6, 3, 7)
    p.box("Head", "Light", -1, 1, 2, 3, 8, 9)
    p.put(0, 3, 10, "Head", "Nose")
    p.eyes("Head", 4, 7, dx=2)
    p.pivots["Head"] = (0, 3, 3)
    p.legs(0, [-3, 2], [-3, 2], w=2)
    return p


def pixiu():  # pointed: a jade treasure lion cub, curly mane and one gold horn
    p = Pet("Pixiu")
    p.box("Body", "Main", -3, 3, 3, 8, -5, 2)
    p.box("Body", "Light", -2, 2, 3, 3, -4, 1)
    p.box("Head", "Main", -4, 4, 7, 14, 1, 7)
    p.box("Head", "Accent", -5, 5, 9, 15, 0, 1)  # gold mane ruff
    p.box("Head", "Accent", -4, 4, 15, 15, 1, 3)
    p.box("Head", "Light", -2, 2, 7, 9, 8, 8)
    p.box("Head", "Accent", 0, 0, 15, 17, 5, 5); p.put(0, 18, 6, "Head", "Accent")  # horn
    p.eyes("Head", 10, 7, dx=2)
    p.pivots["Head"] = (0, 8, 2)
    p.legs(2, [-3, 2], [-5, 1], w=2, role="Dark")
    p.box("Head", "Accent", -6, 6, 8, 16, -1, 0)  # a big round ruff: the lion cub
    p.box("Tail", "Accent", 0, 0, 7, 10, -6, -6); p.box("Tail", "Accent", -1, 1, 10, 11, -7, -6); p.pivots["Tail"] = (0, 7, -5.5)
    return p


def glimwisp():  # round, floating: a teardrop spirit with a fox face and a glowing tail
    p = Pet("Glimwisp")
    p.ell("Body", "Main", 0, 9, 0, 5, 5, 5)
    p.paint("Light", lambda x, y, z: z >= 3 and y <= 9, part="Body")
    for s in (-1, 1): p.box("Body", "Main", s * 3, s * 4, 14, 15, 0, 1)  # fox ears
    p.eyes("Body", 9, 5, dx=2)
    p.box("Tail", "Main", -2, 2, 4, 6, -3, 0)
    p.box("Tail", "Accent", -1, 1, 1, 4, -4, -2)
    p.box("Tail", "Accent", 0, 0, 0, 1, -5, -5)
    p.pivots["Tail"] = (0, 6, -1)
    return p


def selkie():  # round: a seal pup on its belly, flippers
    p = Pet("Selkie")
    p.ell("Body", "Main", 0, 4, -2, 4.5, 4, 6.5, cut=lambda x, y, z: y >= 0)
    p.paint("Light", lambda x, y, z: y <= 2 or (z >= 2 and y <= 4), part="Body")
    p.box("Head", "Main", -4, 4, 4, 10, 2, 7)
    p.box("Head", "Light", -2, 2, 4, 6, 8, 8)
    p.put(0, 6, 9, "Head", "Eye")
    p.eyes("Head", 7, 7, dx=2)
    p.pivots["Head"] = (0, 5, 3)
    for s, nm in ((-1, "FinL"), (1, "FinR")):
        p.box(nm, "Dark", s * 4, s * 6, 0, 1, 1, 3); p.pivots[nm] = (s * 4, 1, 2)
    p.box("Tail", "Dark", -2, 2, 0, 1, -9, -8); p.box("Tail", "Accent", -3, 3, 0, 0, -10, -10); p.pivots["Tail"] = (0, 1, -7.5)
    p.box("Body", "Accent", -1, 1, 9, 9, -2, -1)  # a bubble on its back
    return p


def zharbird():  # pointed: a firebird chick with a flame crest and plumes
    p = Pet("Zharbird")
    p.ell("Body", "Main", 0, 6, -1, 4, 4, 4.5, cut=lambda x, y, z: y >= 2)
    p.paint("Light", lambda x, y, z: z >= 2 and y <= 7, part="Body")
    p.box("Head", "Main", -3, 3, 9, 14, -1, 4)
    p.box("Head", "Beak", -1, 1, 10, 11, 5, 6); p.put(0, 10, 7, "Head", "Beak")
    for i, h in enumerate((3, 5, 4)):  # flame crest
        p.box("Head", "Accent", i - 1, i - 1, 15, 14 + h, 0 + i, 0 + i)
    p.eyes("Head", 12, 4, dx=2)
    p.pivots["Head"] = (0, 9, 1)
    for s, nm in ((-1, "WingL"), (1, "WingR")):
        p.box(nm, "Dark", s * 4, s * 5, 4, 8, -3, 1); p.box(nm, "Light", s * 5, s * 5, 4, 5, -3, 1); p.pivots[nm] = (s * 4, 8, -1)
    p.legs(1, [-2, 1], [0], w=1, role="Beak")
    for i, (x, h) in enumerate(((-2, 6), (0, 8), (2, 6))):  # tail plumes
        p.box("Tail", "Accent" if i == 1 else "Light", x, x, 5, 5 + h // 2, -6 - h // 2, -5)
    p.pivots["Tail"] = (0, 5, -5)
    return p


def fafnir():  # pointed: a chubby little dragon with curled horns, a plated belly, ribbed wings and a spade tail (v2 2026-11-18)
    p = Pet("Fafnir")
    p.ell("Body", "Main", 0, 7, -1, 4.6, 4.2, 5.2)
    p.paint("Light", lambda x, y, z: z >= 1 and abs(x) <= 2 and y <= 9, part="Body")  # the plated belly
    p.paint("Dark", lambda x, y, z: z >= 1 and abs(x) <= 2 and y <= 9 and y % 2 == 0, part="Body")
    for i, z in enumerate(range(-5, 3, 2)):  # back spines, tallest over the shoulders
        top = max(y for (x, y, zz) in p.v if x == 0 and zz == z)
        for k in range(1, 2 + (i + 1) // 2 + 1): p.put(0, top + k, z, "Body", "Accent")
    p.ell("Head", "Main", 0, 14, 4, 4.6, 4.0, 3.8)
    p.box("Head", "Main", -2, 2, 11, 13, 7, 9)  # snout
    p.box("Head", "Light", -2, 2, 10, 11, 5, 8)  # jaw, a step behind the snout
    p.box("Head", "Light", -1, 1, 9, 12, 3, 6)  # pale throat
    p.put(-1, 13, 10, "Head", "Dark"); p.put(1, 13, 10, "Head", "Dark")  # nostrils
    for s in (-1, 1):
        for (x, y, z) in ((3, 17, 3), (3, 18, 2), (3, 19, 1), (3, 19, 0), (3, 18, -1)): p.put(s * x, y, z, "Head", "Horn")  # horns curl back
        p.box("Head", "Accent", s * 5, s * 5, 13, 15, 2, 3)  # ear frills
    p.eyes("Head", 13, 7, dx=2)
    p.pivots["Head"] = (0, 10, 2)
    for s, nm in ((-1, "WingL"), (1, "WingR")):
        for dx in range(0, 6):  # a raised bat wing: three bone fingers fanning up and out, scalloped membrane between them
            x, ytop = s * (4 + dx), 11 + dx + (2 if dx >= 2 else 0)
            ybot = 9 + dx // 2 + (1 if dx in (2, 4) else 0)
            p.box(nm, "Dark", x, x, ybot, ytop, -3, -3)
            for zz in (-3, -2): p.put(x, ytop, zz, nm, "Accent" if dx in (1, 3, 5) else "Light")
        p.box(nm, "Light", s * 4, s * 4, 11, 17, -2, -2)  # the leading bone
        p.box(nm, "Dark", s * 3, s * 4, 9, 11, -4, -1)  # the shoulder the wing hinges on
        p.pivots[nm] = (s * 4.5, 10, -2.5)
    p.legs(2, [-4, 3], [-4, 1], w=2, role="Dark")
    for n in range(1, 5): p.paint("Horn", lambda x, y, z: y == 0 and z in (2, -3), part=f"Leg{n}")  # pale claws
    for i in range(8):  # a tapering tail that curls up into a spade
        z, y, w = -6 - i, 5 + i // 2, 1 if i < 4 else 0
        p.box("Tail", "Main", -w, w, y, y + 1, z, z)
    p.box("Tail", "Accent", -2, 2, 9, 10, -15, -15); p.box("Tail", "Accent", -1, 1, 9, 11, -16, -16); p.put(0, 10, -17, "Tail", "Accent")
    p.pivots["Tail"] = (0, 6, -5.5)
    return p


def kirin():  # pointed: a scaled fawn with an antler horn, a flame mane that runs down the back, a beard and fetlock flames (v2 2026-11-18)
    p = Pet("Kirin")
    p.box("Body", "Main", -3, 3, 6, 10, -5, 3)
    p.box("Body", "Light", -2, 2, 6, 6, -4, 2)
    p.paint("Dark", lambda x, y, z: (x + z) % 3 == 0 and y >= 9, part="Body")  # scales on the back
    for z in (-4, -1, 2): p.box("Body", "Accent", 0, 0, 11, 12 if z != 2 else 13, z, z)  # flames along the spine
    p.box("Head", "Main", -3, 3, 11, 17, 2, 7)
    p.box("Head", "Light", -2, 2, 11, 13, 8, 9)
    p.box("Head", "Accent", -1, 1, 12, 19, -1, 1)  # flame mane
    p.box("Head", "Accent", -2, 2, 16, 18, 0, 0)
    p.box("Head", "Accent", 0, 0, 9, 10, 8, 9)  # beard
    p.box("Head", "Light", -1, 1, 11, 12, 10, 10)  # a stepped dragon snout
    for s in (-1, 1): p.put(s * 3, 12, 9, "Head", "Accent"); p.put(s * 4, 12, 9, "Head", "Accent"); p.put(s * 5, 11, 9, "Head", "Accent")  # whiskers
    p.box("Head", "Horn", 0, 0, 18, 21, 5, 5); p.put(0, 22, 6, "Head", "Horn")
    for s in (-1, 1): p.put(s * 1, 20, 5, "Head", "Horn"); p.put(s * 2, 21, 5, "Head", "Horn")  # antler tines
    for s in (-1, 1): p.box("Head", "Main", s * 4, s * 4, 15, 16, 3, 4)  # ears
    p.eyes("Head", 14, 7, dx=2)
    p.pivots["Head"] = (0, 11, 3)
    p.legs(5, [-3, 2], [-5, 2], w=2, role="Main")
    for k in range(1, 5):
        p.paint("Hoof", lambda x, y, z: y <= 1, part=f"Leg{k}")
        xs = sorted({x for (x, y, z), (pp, rr) in p.v.items() if pp == f"Leg{k}"}); zb = min(z for (x, y, z), (pp, rr) in p.v.items() if pp == f"Leg{k}")
        for x in xs: p.put(x, 2, zb - 1, f"Leg{k}", "Accent"); p.put(x, 3, zb - 1, f"Leg{k}", "Accent"); p.put(x, 3, zb - 2, f"Leg{k}", "Accent"); p.put(x, 4, zb - 2, f"Leg{k}", "Accent")  # fetlock flames, stepped like embers
    p.box("Tail", "Accent", -1, 1, 8, 12, -7, -6); p.box("Tail", "Accent", 0, 0, 12, 16, -9, -7); p.box("Tail", "Accent", 0, 0, 16, 17, -6, -5); p.box("Tail", "Light", 0, 0, 9, 11, -8, -8); p.pivots["Tail"] = (0, 9, -5.5)
    p.box("Head", "Horn", 0, 0, 22, 24, 6, 6)
    p.stilts(2)
    return p


def ouro():  # pointed: a serpent coiled in a tapering ring, biting the tip of its own tail, pale belly and glowing diamonds (v2 2026-11-18)
    p = Pet("Ouro")
    R = 6.5
    for a in range(70, 392, 3):
        t, f = math.radians(a), (a - 70) / 322
        r = 2.5 - 1.6 * f
        cy, cz = 9 + R * math.sin(t), R * math.cos(t)
        p.ell("Body", "Main", 0, cy, cz, r * 1.05, r, r)
    for (x, y, z) in list(p.v):  # the belly on the inside of the ring, diamonds on the outside
        d = math.hypot(y - 9, z)
        if d < R - 0.8: p.v[(x, y, z)] = ("Body", "Light")
        elif d > R + 0.9 and abs(x) <= 1 and int(math.degrees(math.atan2(y - 9, z))) % 45 < 12: p.v[(x, y, z)] = ("Body", "Accent")
    p.ell("Head", "Main", 0, 16, 6, 3.8, 3.2, 3.6)
    p.box("Head", "Main", -2, 2, 14, 16, 8, 11)  # upper jaw
    p.box("Head", "Light", -2, 2, 11, 12, 7, 10)  # lower jaw, open around the tail tip
    for (x, y, z) in list(p.v):
        if y == 13 and z >= 8: del p.v[(x, y, z)]  # the open mouth
    p.box("Body", "Dark", 0, 0, 13, 13, 7, 11)  # the tail tip it bites
    p.box("Head", "Accent", 0, 0, 18, 18, 7, 8)  # the forehead gem
    for s in (-1, 1):
        for (x, y, z) in ((2, 19, 4), (3, 20, 3), (3, 21, 2), (3, 21, 1)): p.put(s * x, y, z, "Head", "Accent")  # swept horns
        p.put(s * 1, 13, 11, "Head", "Light"); p.put(s * 2, 13, 10, "Head", "Light")  # fangs over the tail
        p.put(s * 2, 19, 5, "Head", "Accent"); p.put(s * 2, 20, 4, "Head", "Accent")  # thicker horn roots
    p.eyes("Head", 16, 8, dx=2)
    p.pivots["Head"] = (0, 15, 5)
    return p


def ninering():  # secret: a round pearl spirit with a halo, small paws and a flame tuft, inside nine crisp gold rings (v2 2026-11-18)
    p = Pet("Ninering")
    p.ell("Body", "Main", 0, 8, 0, 4.6, 5.0, 4.4)
    p.paint("Light", lambda x, y, z: y >= 10, part="Body")
    p.box("Body", "Light", -3, -2, 3, 4, 3, 4); p.box("Body", "Light", 2, 3, 3, 4, 3, 4)  # paws
    p.box("Body", "Ring", -2, 2, 13, 13, -1, 1)  # a three-prong coronet
    for x, h in ((-2, 15), (0, 16), (2, 15)): p.box("Body", "Ring", x, x, 14, h, 0, 0)
    p.put(0, 17, 0, "Body", "Accent")
    for k in range(0, 360, 20):  # the halo
        u = math.radians(k); p.put(round(3 * math.cos(u)), 18, round(3 * math.sin(u)), "Body", "Ring")
    p.eyes("Body", 8, 4, dx=2)
    for s in (-1, 1): p.put(s * 4, 7, 3, "Body", "Blush")
    p.put(0, 11, 4, "Body", "Ring")  # forehead star
    for i in range(9):
        t = math.radians(i * 40)
        cx, cz = round(10 * math.cos(t)), round(10 * math.sin(t))
        y, nm = 6 + (i % 3) * 3, f"Ring{i + 1}"
        for k in range(0, 360, 15):
            u = math.radians(k)
            p.put(cx + round(1.8 * math.cos(u) * math.sin(t)), y + round(1.8 * math.sin(u)), cz - round(1.8 * math.cos(u) * math.cos(t)), nm, "Ring")  # each loop faces the spirit
        p.pivots[nm] = (cx, y, cz)
    return p


BUILDERS = [tosk, kobold, kepri, shinemane, goldbristle, pixiu, glimwisp, selkie, zharbird, fafnir, kirin, ouro, ninering]

if __name__ == "__main__":
    out = []
    for b in BUILDERS:
        p = b()
        d = p.data(); d["palette"] = PALETTES[p.name]
        missing = {r for vs in d["parts"].values() for *_, r in vs} - set(d["palette"])
        assert not missing, (p.name, missing)
        assert "Body" in d["parts"], p.name
        out.append(d)
        print(f"{p.name:14} {len(p.v):5} voxels  {d['height']:2} tall  parts {sorted(d['parts'])}")
    here = os.path.dirname(os.path.abspath(__file__))
    json.dump(out, open(os.path.join(here, "pets.json"), "w"), separators=(",", ":"))
