"""Hybrid pickaxes, round 2 (2026-11-17 night). Gemini graded round 1 at 3.8 (n17_picks): one silhouette recycled for every
tier, flat SmoothPlastic with no edge light or occlusion, neon "stickers" instead of real magical ornaments. This round:
  * a silhouette per tier from a kit (FEAT): lashed branch and flint for the first picks, langets, roots, a geode socket, bone
    claws, crystal and glass blades, flame tips, feather blades, a crescent moon, an orbit ring, wings and a halo
  * the old set's charm back as 3D ornaments: ribbons that hang and curl, pendants on chains (lantern, star, moon, heart),
    filigree arcs and a crown
  * a tapered handle (a thick pommel, a waist at the grip) and a flared collar with metal langets
  * a baked texture: every solid part is joined into one mesh, unwrapped and baked in Cycles with its colour darkened in the
    crevices (ambient occlusion) and lit along its edges (a bevel-normal edge mask), the hand-painted edge light The Forge has.
    Glowing parts (Accent, Neon in game) and gems (Glass) stay separate meshes the game paints.
    blender -b -P design3d/picks/pick_hybrid2.py -- <out_dir> [Name ...]
Outputs <Name>.glb with objects Body__Tex (textured), Head__Accent and Head__Gem. Axes as round 1 (z up the handle)."""
import bpy, bmesh, math, os, sys
from mathutils import Vector, Matrix

here = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, here)
from picks import TIERS

args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = os.path.abspath(args[0] if args else os.path.join(here, "out_h2"))
ONLY = set(a for a in args[1:] if not a.startswith("-"))
NOBAKE = "-nobake" in args
TEX = 512
os.makedirs(OUT, exist_ok=True)

HL, HR = 3.3, 0.13
TOP = HL + 0.1

# the kit per tier: handle, head, socket, extras
FEAT = {
    "WoodPickaxe": dict(handle="branch", head="flint", socket="lash", extras=[]),
    "StonePickaxe": dict(handle="branch", head="flint2", socket="lash", extras=["pendant:gem"]),
    "AshcoalPickaxe": dict(handle="wrapped", head="pickhammer", socket="collar", extras=["chains"]),
    "CopperPickaxe": dict(handle="wrapped", head="pickhammer", socket="collar", extras=["pendant:lantern"]),
    "BogIronPickaxe": dict(handle="wrapped", head="double", socket="langet", extras=["spikes"]),
    "RootheartPickaxe": dict(handle="roots", head="pickhammer", socket="heart", extras=["leaves"]),
    "MossbackPickaxe": dict(handle="wrapped", head="double", socket="collar", extras=["moss", "mushrooms"]),
    "KilnPickaxe": dict(handle="wrapped", head="hammerpick", socket="collar", extras=["drips"]),
    "RuneTinPickaxe": dict(handle="fluted", head="double", socket="langet", extras=["filigree"]),
    "GeodePickaxe": dict(handle="wrapped", head="pickhammer", socket="geode", extras=[]),
    "FossilPickaxe": dict(handle="bone", head="claw", socket="skull", extras=["pendant:gem"]),
    "TitanHammerPickaxe": dict(handle="fluted", head="hammer", socket="langet", extras=["filigree"]),
    "FrostquartzPickaxe": dict(handle="twist", head="crystal", socket="collar", extras=["icicles"]),
    "AmethystPickaxe": dict(handle="twist", head="crystal", socket="geode", extras=[]),
    "SongcrystalPickaxe": dict(handle="metal", head="fork", socket="collar", extras=["ribbon"]),
    "SapphirePickaxe": dict(handle="fluted", head="gemframe", socket="langet", extras=["filigree"]),
    "PrismPickaxe": dict(handle="twist", head="crystal", socket="collar", extras=["ribbon"]),
    "AuroraPickaxe": dict(handle="metal", head="sweep", socket="collar", extras=["ribbon", "ribbon2"]),
    "SurtshardPickaxe": dict(handle="wrapped", head="jagged", socket="langet", extras=["spikes"]),
    "FireglassPickaxe": dict(handle="twist", head="crystal", socket="collar", extras=["flames"]),
    "EmberPickaxe": dict(handle="wrapped", head="flame", socket="collar", extras=["flames"]),
    "RubyPickaxe": dict(handle="fluted", head="gemframe", socket="langet", extras=["filigree", "crown"]),
    "PhoenixPickaxe": dict(handle="metal", head="feather", socket="collar", extras=["wings", "ribbon"]),
    "SunforgePickaxe": dict(handle="fluted", head="hammer", socket="sun", extras=["rays"]),
    "StarlightPickaxe": dict(handle="metal", head="sweep", socket="star", extras=["ribbon", "pendant:star"]),
    "MoonlitPickaxe": dict(handle="metal", head="crescent", socket="collar", extras=["chains", "pendant:moon"]),
    "GalaxyPickaxe": dict(handle="twist", head="sweep", socket="orbit", extras=["pendant:star"]),
    "RoyalHeartPickaxe": dict(handle="metal", head="sweep", socket="heart", extras=["crown", "ribbon", "pendant:heart"]),
    "SilverWingPickaxe": dict(handle="metal", head="feather", socket="collar", extras=["wings", "halo", "ribbon"]),
}


class Builder:
    def __init__(self):
        self.groups = {}

    def bm(self, role):
        if role not in self.groups: self.groups[role] = bmesh.new()
        return self.groups[role]

    def merge(self, role, b):
        me = bpy.data.meshes.new("tmp"); b.to_mesh(me); b.free()
        self.bm(role).from_mesh(me); bpy.data.meshes.remove(me)

    def cyl(self, role, z0, z1, r0, r1=None, seg=8, x=0.0, y=0.0):
        b = bmesh.new()
        bmesh.ops.create_cone(b, cap_ends=True, segments=seg, radius1=r0, radius2=r0 if r1 is None else r1, depth=z1 - z0, matrix=Matrix.Translation((x, y, (z0 + z1) / 2)))
        self.merge(role, b)

    def box(self, role, c, s, bevel=0.0, rot=None):
        b = bmesh.new()
        bmesh.ops.create_cube(b, size=1.0)
        bmesh.ops.scale(b, vec=Vector(s), verts=b.verts)
        if bevel > 0: bmesh.ops.bevel(b, geom=list(b.edges), offset=bevel, segments=1, affect="EDGES")
        if rot: bmesh.ops.rotate(b, verts=b.verts, cent=Vector((0, 0, 0)), matrix=rot)
        bmesh.ops.translate(b, vec=Vector(c), verts=b.verts)
        self.merge(role, b)

    def gem(self, role, c, r, subd=1, squash=1.0):
        b = bmesh.new()
        bmesh.ops.create_icosphere(b, subdivisions=subd, radius=r)
        bmesh.ops.scale(b, vec=Vector((1, squash, 1)), verts=b.verts)
        bmesh.ops.translate(b, vec=Vector(c), verts=b.verts)
        self.merge(role, b)

    def tube(self, role, pts, radii, seg=6, flat=1.0, rot45=False):
        """a swept tube along 3D points; radii per point (rx, ry) or r; flat squashes the section across its side vector"""
        b = bmesh.new()
        rings = []
        up0 = Vector((0, 1, 0))
        for i, p in enumerate(pts):
            p = Vector(p)
            t = (Vector(pts[min(i + 1, len(pts) - 1)]) - Vector(pts[max(i - 1, 0)])).normalized()
            side = t.cross(up0)
            if side.length < 1e-4: side = t.cross(Vector((1, 0, 0)))
            side.normalize()
            up = side.cross(t).normalized()
            r = radii[i]
            rx, ry = (r, r * flat) if not isinstance(r, tuple) else r
            ring = [b.verts.new(p + up * math.cos(a) * rx + side * math.sin(a) * ry) if rot45 else b.verts.new(p + side * math.cos(a) * rx + up * math.sin(a) * ry) for a in [k / seg * math.pi * 2 for k in range(seg)]]
            rings.append(ring)
        for r0, r1 in zip(rings, rings[1:]):
            for k in range(seg):
                b.faces.new([r0[k], r0[(k + 1) % seg], r1[(k + 1) % seg], r1[k]])
        b.faces.new(list(reversed(rings[0]))); b.faces.new(rings[-1])
        bmesh.ops.recalc_face_normals(b, faces=b.faces)
        self.merge(role, b)

    def prism(self, role, pts2d, c, depth, scale=1.0, axis="y"):
        b = bmesh.new()
        if axis == "y":
            f = [b.verts.new((c[0] + px * scale, c[1] - depth / 2, c[2] + pz * scale)) for px, pz in pts2d]
            dv = Vector((0, depth, 0))
        else:
            f = [b.verts.new((c[0] - depth / 2, c[1] + px * scale, c[2] + pz * scale)) for px, pz in pts2d]
            dv = Vector((depth, 0, 0))
        face = b.faces.new(f)
        ext = bmesh.ops.extrude_face_region(b, geom=[face])
        bmesh.ops.translate(b, vec=dv, verts=[v for v in ext["geom"] if isinstance(v, bmesh.types.BMVert)])
        bmesh.ops.recalc_face_normals(b, faces=b.faces)
        self.merge(role, b)


def star_pts(n=5, r0=1.0, r1=0.45):
    return [((r0 if i % 2 == 0 else r1) * math.sin(i * math.pi / n), (r0 if i % 2 == 0 else r1) * math.cos(i * math.pi / n)) for i in range(n * 2)]


def heart_pts():
    return [(16 * math.sin(t) ** 3 / 17, (13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t)) / 17) for t in [i / 24 * math.pi * 2 for i in range(24)]]


def moon_pts():
    pts = [(math.cos(a), math.sin(a)) for a in [math.pi / 2 + i / 12 * math.pi for i in range(13)]]
    return pts + [(math.cos(a) * 0.62 - 0.3, math.sin(a) * 0.7) for a in [math.pi * 1.5 - i / 12 * math.pi for i in range(13)]]


def arm(B, side, length, k, h0=0.33, d0=0.24, droop=0.55, role="Head", tipRole="Light", taper=0.84, n=9, jag=0.0, lift=0.0):
    """one blade from the socket: thick at the root, curving down and thinning to a point; jag adds a saw edge underneath"""
    pts, rad = [], []
    for i in range(n):
        u = i / (n - 1)
        x = side * (0.3 + u * length * k)
        z = TOP + lift * u - droop * u ** 1.8
        h = h0 * (1 - taper * u) + 0.02
        d = d0 * (1 - 0.72 * u) + 0.03
        pts.append((x, 0, z)); rad.append((h, d))
    B.tube(role, pts, [(h, d * 1.25) for h, d in rad], seg=4, rot45=True)  # a diamond section: a wedge with a real cutting edge (Gemini r2: blades read flat)
    # the bright upper edge: a narrow ridge along the top (the sharpened face catches light)
    B.tube(tipRole, [(x, y, z + h * 0.8) for (x, y, z), (h, d) in zip(pts, rad)][:-1], [(h * 0.2, d * 0.5) for h, d in rad][:-1], seg=4)
    if jag > 0:  # teeth under the arm
        for i in range(2, n - 2):
            (x, y, z), (h, d) = pts[i], rad[i]
            B.tube(role, [(x, 0, z - h * 0.7), (x + side * 0.05, 0, z - h - jag)], [(0.06, d * 0.7), (0.005, 0.005)], seg=4)
    return pts, rad


def build(t):
    F = FEAT[t["name"]]
    B = Builder()
    k = t["size"]
    ex = F["extras"]
    # ---- HANDLE
    h = F["handle"]
    if h == "branch":  # a crooked branch with knots
        pts = [(0.03 * math.sin(i * 1.3), 0.02 * math.cos(i * 0.9), 0.15 + i * (HL - 0.15) / 10) for i in range(11)]
        B.tube("Handle", pts, [HR * (1.15 - 0.15 * i / 10) for i in range(11)], seg=7)
        for z in (1.2, 2.3):
            B.gem("Handle", (HR * 0.9, 0, z), 0.07, subd=1)
    elif h == "roots":
        B.cyl("Handle", 0.25, HL, HR, HR * 0.9)
        for s in range(3):  # three roots spiralling up the shaft
            pts = [(math.cos(s * 2.1 + u * 9) * HR * 1.05, math.sin(s * 2.1 + u * 9) * HR * 1.05, 0.3 + u * (HL - 0.4)) for u in [i / 24 for i in range(25)]]
            B.tube("Grip", pts, [0.045] * 25, seg=5)
    elif h == "bone":
        B.cyl("Handle", 0.25, HL, HR * 0.95, HR * 0.85)
        for z in [0.6 + i * 0.45 for i in range(6)]:
            B.cyl("Handle", z - 0.05, z + 0.05, HR * 1.25, HR * 1.25, seg=8)  # knuckled vertebrae
    elif h == "twist":  # a twisted crystal-and-metal shaft for the gem tiers
        B.cyl("Handle", 0.25, HL, HR * 0.8, HR * 0.75)
        for s2 in range(2):
            pts = [(math.cos(s2 * math.pi + u * 14) * HR * 0.85, math.sin(s2 * math.pi + u * 14) * HR * 0.85, 0.3 + u * (HL - 0.45)) for u in [i / 40 for i in range(41)]]
            B.tube("Crystal" if s2 == 0 else "Band", pts, [0.06] * 41, seg=5)
    elif h == "fluted":  # an octagonal metal shaft with raised ribs
        B.cyl("Handle", 0.25, HL, HR * 1.05, HR * 0.9, seg=8)
        for a in range(4):
            ang = a / 4 * math.pi * 2
            B.tube("Band", [(math.cos(ang) * HR * 1.0, math.sin(ang) * HR * 1.0, 1.5), (math.cos(ang) * HR * 0.95, math.sin(ang) * HR * 0.95, HL - 0.3)], [0.03, 0.03], seg=4)
        for i in range(5):
            z = 0.45 + i * 0.2
            B.cyl("Grip", z, z + 0.14, HR * 1.2, HR * 1.12)
    else:  # wrapped / metal: a taper with a waist at the grip
        B.tube("Handle", [(0, 0, 0.25), (0, 0, 0.9), (0, 0, 1.6), (0, 0, HL)], [HR * 1.12, HR * 0.95, HR * 1.0, HR * 0.95], seg=8)
        if h == "wrapped":  # leather wraps: a spiral strap, standing proud
            pts = [(math.cos(u * 44) * HR * 1.06, math.sin(u * 44) * HR * 1.06, 0.4 + u * 1.0) for u in [i / 90 for i in range(91)]]
            B.tube("Grip", pts, [(0.035, 0.03)] * 91, seg=4)  # a close leather wrap (7 turns read as a spring)
        else:
            for i in range(6):
                z = 0.45 + i * 0.17
                B.cyl("Grip", z, z + 0.11, HR * 1.18, HR * 1.18)
    for z in (0.3, HL - 0.2):
        B.cyl("Band", z - 0.07, z + 0.07, HR * 1.4, HR * 1.4)
    B.cyl("Band", -0.05, 0.25, HR * 0.8, HR * 1.5, seg=8)  # the pommel
    B.gem("Gem" if t["mark"] else "Band", (0, 0, -0.12), 0.14)
    # ---- SOCKET
    so = F["socket"]
    if so == "lash":  # the head lashed on with rope
        B.box("Head", (0, 0, TOP), (0.42, 0.36, 0.5), bevel=0.05)
        for i in range(4):
            B.tube("Grip", [(math.cos(a) * 0.27, math.sin(a) * 0.23, TOP - 0.15 + i * 0.1 + a * 0.01) for a in [j / 12 * math.pi * 2 for j in range(13)]], [0.035] * 13, seg=4)
    elif so == "geode":  # a cracked rock with crystals bursting out
        B.gem("Dark", (0, 0, TOP), 0.42, subd=1, squash=0.85)
        for i, (x, z, a) in enumerate(((-0.15, 0.3, -0.5), (0.05, 0.38, 0.05), (0.2, 0.28, 0.6), (0, 0.1, 0))):
            L = 0.55 - i * 0.09
            B.tube("Crystal", [(x, 0, TOP + z), (x + math.sin(a) * L, 0, TOP + z + math.cos(a) * L)], [0.09, 0.005], seg=6)
    elif so == "skull":
        B.gem("Light", (0, 0, TOP + 0.05), 0.36, subd=2, squash=0.9)
        for s in (-1, 1): B.gem("Dark", (s * 0.13, -0.28, TOP + 0.08), 0.08)
    else:  # a flared collar with bands; langets run down the handle
        B.tube("Dark", [(0, 0, TOP - 0.42 * k), (0, 0, TOP - 0.2 * k), (0, 0, TOP + 0.2 * k), (0, 0, TOP + 0.4 * k)], [0.2 * k, 0.27 * k, 0.29 * k, 0.24 * k], seg=10)  # a forged sleeve that clasps the blades (Gemini r2: box sockets)
        B.tube("Band", [(0, 0, TOP - 0.46 * k), (0, 0, TOP - 0.36 * k)], [0.25 * k, 0.25 * k], seg=10)
        B.tube("Band", [(0, 0, TOP + 0.36 * k), (0, 0, TOP + 0.46 * k)], [0.27 * k, 0.22 * k], seg=10)
        B.gem("Band", (0, 0, TOP + 0.5 * k), 0.1 * k)
        if so == "langet":
            for s in (-1, 1):
                B.box("Band", (s * (HR + 0.03), 0, TOP - 0.62), (0.05, 0.16, 0.7), bevel=0.015)
                B.gem("Band", (s * (HR + 0.06), 0, TOP - 0.45), 0.035)
                B.gem("Band", (s * (HR + 0.06), 0, TOP - 0.8), 0.035)
        marks = {"star": star_pts(), "sun": star_pts(8, 1.0, 0.6), "heart": heart_pts()}
        if so in marks:
            for yy in (0.27 * k, -0.27 * k):
                B.prism("Accent", marks[so], (0, yy, TOP), 0.07, scale=0.22 * k)
        elif so == "orbit":  # a ring with two planets circling the socket
            B.tube("Band", [(math.cos(a) * 0.6, math.sin(a) * 0.6 * 0.4, TOP + math.sin(a) * 0.18) for a in [j / 24 * math.pi * 2 for j in range(25)]], [0.035] * 25, seg=5)
            B.gem("Accent", (0.6, 0, TOP), 0.09); B.gem("Gem", (-0.42, 0.18, TOP + 0.1), 0.07)
            B.gem("Gem", (0, 0.27, TOP), 0.13)
        elif t["mark"] in ("gem", "geode") or so == "collar":
            if t["mark"]: B.gem("Gem", (0, 0.26 * k, TOP), 0.13 * k); B.gem("Gem", (0, -0.26 * k, TOP), 0.13 * k)
    # ---- HEAD
    hd = F["head"]
    L = 1.25
    if hd in ("pickhammer", "double", "hammerpick", "fork", "sweep", "crescent", "jagged", "flint", "flint2", "claw", "gemframe", "crystal", "flame", "feather"):
        pass
    if hd == "flint" or hd == "flint2":  # knapped stone: a faceted wedge each side
        for s in ((1,) if hd == "flint" else (1, -1)):
            pts = [(s * (0.25 + u * 0.95), 0, TOP - 0.35 * u ** 1.6) for u in [i / 6 for i in range(7)]]
            B.tube("Head", pts, [(0.3 * (1 - 0.8 * u) + 0.03, 0.2 * (1 - 0.6 * u) + 0.03) for u in [i / 6 for i in range(7)]], seg=5)
        if hd == "flint": B.box("Head", (-0.4, 0, TOP), (0.4, 0.34, 0.42), bevel=0.08, rot=Matrix.Rotation(0.2, 3, "Y"))
    elif hd == "pickhammer":
        arm(B, 1, L, k)
        B.box("Head", (-0.55, 0, TOP), (0.55, 0.44, 0.52), bevel=0.07)
        B.box("Light", (-0.84, 0, TOP), (0.05, 0.48, 0.56), bevel=0.015)
    elif hd == "hammerpick":  # a heavier hammer than pick
        arm(B, 1, 0.85, k, h0=0.3)
        B.box("Head", (-0.6, 0, TOP), (0.7, 0.56, 0.66), bevel=0.08)
        B.box("Light", (-0.97, 0, TOP), (0.05, 0.6, 0.7), bevel=0.015)
    elif hd in ("double", "jagged"):
        for s in (1, -1): arm(B, s, L, k, jag=0.12 if hd == "jagged" else 0.0)
    elif hd == "hammer":
        for s in (-1, 1):
            B.box("Head", (s * 0.64 * k, 0, TOP), (0.66 * k, 0.64 * k, 0.78 * k), bevel=0.08)
            B.box("Light", (s * 0.99 * k, 0, TOP), (0.06, 0.68 * k, 0.82 * k), bevel=0.02)
            B.box("Band", (s * 0.5 * k, 0, TOP), (0.08, 0.7 * k, 0.86 * k), bevel=0.02)
    elif hd == "claw":  # bone claws, notched
        for s in (1, -1):
            arm(B, s, 1.15, k, h0=0.28, droop=0.8, role="Light", tipRole="Head")
            for i in range(3): B.gem("Dark", (s * (0.6 + i * 0.25), 0.12, TOP - 0.1 - i * 0.12), 0.04)
    elif hd in ("crystal", "gemframe"):  # translucent crystal blades (Gem = Glass in game) set in a metal frame
        for s in (1, -1):
            pts, rad = arm(B, s, L, k, role="Crystal", tipRole="Accent", h0=0.34, d0=0.2)
            B.tube("Band", [(x, y, z + h * 0.95) for (x, y, z), (h, d) in zip(pts, rad)][:-2], [0.035] * (len(pts) - 2), seg=4)  # a metal spine on top
            if hd == "gemframe":
                B.tube("Band", [(x, y, z - h * 0.95) for (x, y, z), (h, d) in zip(pts, rad)][:-2], [0.035] * (len(pts) - 2), seg=4)
    elif hd == "flame":  # the pick splits into three flame tongues
        pts, rad = arm(B, 1, 0.9, k)
        x0, _, z0 = pts[-3]
        for j, (dz, dx) in enumerate(((0.25, 0.35), (0.0, 0.5), (-0.25, 0.35))):
            B.tube("Accent", [(x0, 0, z0), (x0 + dx * 0.6, 0, z0 + dz * 0.6 + 0.12), (x0 + dx, 0, z0 + dz + 0.2)], [0.09, 0.06, 0.005], seg=5)
        B.box("Head", (-0.55, 0, TOP), (0.55, 0.44, 0.52), bevel=0.07)
    elif hd == "feather":  # blades of overlapping feathers
        for s in (1, -1):
            for i in range(5):
                u = i / 4
                L2 = 0.55 + 0.6 * (1 - abs(u - 0.4))
                a = math.radians(95 + i * 9)
                x0, z0 = s * (0.25 + u * 0.5), TOP + 0.05 - u * 0.15
                B.tube("Head" if i % 2 else "Light", [(x0, 0.02 * i, z0), (x0 + s * math.sin(a) * L2 * 0.6, 0.02 * i, z0 + math.cos(a) * L2 * 0.6), (x0 + s * math.sin(a) * L2, 0.02 * i, z0 + math.cos(a) * L2)], [(0.12, 0.04), (0.1, 0.035), (0.01, 0.01)], seg=4)
    elif hd == "crescent":  # the blade is a crescent moon, both horns up
        pts = [(math.cos(a) * 1.25 * k, 0, TOP + 0.15 - math.sin(a) * 0.55) for a in [math.pi * (0.06 + 0.88 * i / 16) for i in range(17)]]
        B.tube("Head", pts, [(0.07 + 0.26 * math.sin(math.pi * i / 16), 0.05 + 0.15 * math.sin(math.pi * i / 16)) for i in range(17)], seg=6)
        B.tube("Light", [(x, y, z + 0.03) for x, y, z in pts][1:-1], [(0.03, 0.12 * math.sin(math.pi * (i + 1) / 16) + 0.02) for i in range(15)], seg=4)
    elif hd == "fork":  # twin prongs that sing (tuning fork)
        for s in (1, -1):
            for dz in (0.14, -0.14):
                arm(B, s, 1.1, k, h0=0.13, d0=0.13, droop=0.35, lift=dz * 0.5)
    elif hd == "sweep":  # long elegant swept blades, a little upturned at the tips
        for s in (1, -1): arm(B, s, 1.35, k, h0=0.3, droop=0.25, lift=0.0, taper=0.88)
    # ---- EXTRAS (the old set's charm, in 3D)
    for e in ex:
        if e == "ribbon" or e == "ribbon2":  # a ribbon tied under the socket that hangs and curls
            s = 1 if e == "ribbon" else -1
            pts = [(s * (0.2 + 0.25 * u + 0.15 * math.sin(u * 5)), 0.08 + 0.12 * math.sin(u * 4), TOP - 0.35 - u * 1.3) for u in [i / 12 for i in range(13)]]
            B.tube("Accent" if t["name"] in ("AuroraPickaxe",) else "Light", pts, [(0.12 * (1 - 0.3 * u), 0.012) for u in [i / 12 for i in range(13)]], seg=4)
            B.gem("Band", (s * 0.18, 0.1, TOP - 0.33), 0.08)  # the knot
        elif e.startswith("pendant:"):  # a chain from the socket with a charm at its end
            kind = e.split(":")[1]
            for i in range(6):
                B.gem("Band", (-0.35 - i * 0.02, 0.0, TOP - 0.35 - i * 0.11), 0.035, subd=1)
            cz = TOP - 1.05
            if kind == "lantern":
                B.box("Band", (-0.47, 0, cz + 0.12), (0.2, 0.2, 0.05), bevel=0.01)
                B.gem("Accent", (-0.47, 0, cz - 0.02), 0.09, squash=1.0)
                B.box("Band", (-0.47, 0, cz - 0.16), (0.2, 0.2, 0.05), bevel=0.01)
            elif kind == "gem":
                B.gem("Gem", (-0.47, 0, cz), 0.1)
            else:
                shp = {"star": star_pts(), "moon": moon_pts(), "heart": heart_pts()}[kind]
                B.prism("Accent", shp, (-0.47, 0, cz), 0.05, scale=0.13)
        elif e == "chains":
            for s in (1, -1):
                for i in range(7):
                    u = i / 6
                    B.gem("Band", (s * (0.35 + u * 0.7), 0.15, TOP - 0.2 - math.sin(u * math.pi) * 0.25), 0.03)
        elif e == "filigree":  # curling gold arcs on both faces of the socket
            for yy in (0.25, -0.25):
                for s in (1, -1):
                    pts = [(s * (0.12 + 0.25 * math.sin(a)), yy, TOP + 0.25 * math.cos(a) * 0.9) for a in [j / 10 * math.pi for j in range(11)]]
                    B.tube("Band", pts, [0.022] * 11, seg=4)
        elif e == "crown":
            for i in range(5):
                a = i / 5 * math.pi * 2
                B.tube("Band", [(math.cos(a) * 0.2, math.sin(a) * 0.2, TOP + 0.33), (math.cos(a) * 0.24, math.sin(a) * 0.24, TOP + 0.58)], [0.05, 0.01], seg=4)
                B.gem("Gem", (math.cos(a) * 0.24, math.sin(a) * 0.24, TOP + 0.6), 0.035)
            B.cyl("Band", TOP + 0.3, TOP + 0.4, 0.24, 0.24, seg=10)
        elif e == "halo":
            B.tube("Accent", [(math.cos(a) * 0.38, math.sin(a) * 0.38, TOP + 0.75) for a in [j / 24 * math.pi * 2 for j in range(25)]], [0.035] * 25, seg=5)
        elif e == "wings":
            for s in (-1, 1):
                for i in range(4):
                    a = math.radians(15 + i * 18)
                    L2 = 1.1 - i * 0.18
                    x0, z0 = s * 0.22, TOP + 0.28
                    B.tube("Light" if i else "Accent", [(x0, -0.05, z0), (x0 + s * math.sin(a) * L2 * 0.5, -0.05, z0 + math.cos(a) * L2 * 0.5), (x0 + s * math.sin(a) * L2, -0.05, z0 + math.cos(a) * L2)], [(0.11, 0.035), (0.1, 0.03), (0.01, 0.01)], seg=4)
        elif e == "spikes":
            for s in (1, -1):
                for i in range(3):
                    B.tube("Light", [(s * (0.4 + i * 0.3), 0, TOP + 0.2), (s * (0.45 + i * 0.3), 0, TOP + 0.45)], [0.06, 0.005], seg=4)
        elif e == "moss" or e == "mushrooms" or e == "leaves":
            for i in range(5):
                B.gem("Accent" if e != "moss" else "Light", (-0.4 + i * 0.2, 0.05 * (i % 2), TOP + 0.33 + 0.03 * (i % 2)), 0.08 if e != "mushrooms" else 0.06, subd=1, squash=0.6)
            if e == "mushrooms":
                for x in (-0.25, 0.25):
                    B.cyl("Light", TOP + 0.3, TOP + 0.5, 0.03, 0.03, x=x)
                    B.gem("Accent", (x, 0, TOP + 0.52), 0.1, squash=1.0)
        elif e == "drips":  # glaze drips running off the hammer
            for i in range(4):
                B.tube("Accent", [(-0.4 - i * 0.12, 0.25, TOP + 0.2), (-0.4 - i * 0.12, 0.27, TOP - 0.1 - (i % 2) * 0.1)], [0.04, 0.03], seg=5)
        elif e == "icicles":
            for s in (1, -1):
                for i in range(4):
                    x = s * (0.45 + i * 0.22)
                    B.tube("Gem", [(x, 0, TOP - 0.2 - i * 0.04), (x, 0, TOP - 0.45 - i * 0.03)], [0.05, 0.005], seg=5)
        elif e == "flames":
            for i in range(3):
                B.tube("Accent", [(0.2 * (i - 1), 0, TOP + 0.3), (0.2 * (i - 1) + 0.05, 0, TOP + 0.55 + 0.12 * (i == 1))], [0.08, 0.005], seg=5)
        elif e == "rays":
            for i in range(8):
                a = i / 8 * math.pi * 2
                B.tube("Accent", [(math.cos(a) * 0.32, 0.36, TOP + math.sin(a) * 0.32), (math.cos(a) * 0.5, 0.36, TOP + math.sin(a) * 0.5)], [0.05, 0.005], seg=4)
            B.gem("Accent", (0, 0.35, TOP), 0.2, squash=0.4)
    return B


def bake(objs, img_path):
    """join the solid parts, unwrap, and bake colour x occlusion + an edge light into one texture"""
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs: o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.join()
    body = bpy.context.view_layer.objects.active
    body.name = body.data.name = "Body__Tex"
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=math.radians(60), island_margin=0.02)
    bpy.ops.object.mode_set(mode="OBJECT")
    img = bpy.data.images.new("bake", TEX, TEX)
    for m in body.data.materials:
        nt = m.node_tree
        for n in list(nt.nodes): nt.nodes.remove(n)
        out = nt.nodes.new("ShaderNodeOutputMaterial")
        em = nt.nodes.new("ShaderNodeEmission")
        base = m["base"]
        rgb = nt.nodes.new("ShaderNodeRGB"); rgb.outputs[0].default_value = base
        ao = nt.nodes.new("ShaderNodeAmbientOcclusion"); ao.inputs["Distance"].default_value = 0.25; ao.samples = 16
        bev = nt.nodes.new("ShaderNodeBevel"); bev.inputs["Radius"].default_value = 0.035; bev.samples = 8
        geo = nt.nodes.new("ShaderNodeNewGeometry")
        dot = nt.nodes.new("ShaderNodeVectorMath"); dot.operation = "DOT_PRODUCT"
        nt.links.new(bev.outputs[0], dot.inputs[0]); nt.links.new(geo.outputs["Normal"], dot.inputs[1])
        edge = nt.nodes.new("ShaderNodeMapRange"); edge.inputs["From Min"].default_value, edge.inputs["From Max"].default_value = 0.985, 0.85
        nt.links.new(dot.outputs["Value"], edge.inputs["Value"])
        # the top faces a touch lighter (a painted key light from above)
        sep = nt.nodes.new("ShaderNodeSeparateXYZ"); nt.links.new(geo.outputs["Normal"], sep.inputs[0])
        upl = nt.nodes.new("ShaderNodeMapRange"); upl.inputs["From Min"].default_value, upl.inputs["From Max"].default_value = -1, 1
        upl.inputs["To Min"].default_value, upl.inputs["To Max"].default_value = 0.78, 1.12
        nt.links.new(sep.outputs["Z"], upl.inputs["Value"])
        aom = nt.nodes.new("ShaderNodeMapRange"); aom.inputs["To Min"].default_value, aom.inputs["To Max"].default_value = 0.45, 1.0
        nt.links.new(ao.outputs["AO"], aom.inputs["Value"])
        m1 = nt.nodes.new("ShaderNodeMath"); m1.operation = "MULTIPLY"
        nt.links.new(aom.outputs[0], m1.inputs[0]); nt.links.new(upl.outputs[0], m1.inputs[1])
        mix = nt.nodes.new("ShaderNodeMix"); mix.data_type = "RGBA"; mix.blend_type = "MULTIPLY"; mix.inputs["Factor"].default_value = 1.0
        nt.links.new(rgb.outputs[0], mix.inputs[6]); nt.links.new(m1.outputs[0], mix.inputs[7])
        hi = nt.nodes.new("ShaderNodeMix"); hi.data_type = "RGBA"; hi.blend_type = "SCREEN"
        nt.links.new(edge.outputs[0], hi.inputs["Factor"]); nt.links.new(mix.outputs[2], hi.inputs[6])
        hi.inputs[7].default_value = (1, 0.97, 0.9, 1)
        sc = nt.nodes.new("ShaderNodeMath"); sc.operation = "MULTIPLY"; sc.inputs[1].default_value = 0.7
        nt.links.new(edge.outputs[0], sc.inputs[0]); nt.links.new(sc.outputs[0], hi.inputs["Factor"])
        nt.links.new(hi.outputs[2], em.inputs["Color"])
        nt.links.new(em.outputs[0], out.inputs[0])
        tex = nt.nodes.new("ShaderNodeTexImage"); tex.image = img
        nt.nodes.active = tex
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"; sc.cycles.samples = 16; sc.cycles.device = "CPU"
    sc.render.bake.margin = 4
    bpy.ops.object.select_all(action="DESELECT"); body.select_set(True); bpy.context.view_layer.objects.active = body
    bpy.ops.object.bake(type="EMIT")
    img.filepath_raw = img_path; img.file_format = "PNG"; img.save()
    # one plain material with the baked image for export
    mat = bpy.data.materials.new("PickTex"); mat.use_nodes = True
    nt = mat.node_tree; bsdf = nt.nodes["Principled BSDF"]
    t2 = nt.nodes.new("ShaderNodeTexImage"); t2.image = img
    nt.links.new(t2.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 0.6
    body.data.materials.clear(); body.data.materials.append(mat)
    return body


def hexlin(h):
    h = h.lstrip("#")
    return tuple(((int(h[i:i + 2], 16) / 255) ** 2.2) for i in (0, 2, 4)) + (1.0,)


for t in TIERS:
    if ONLY and t["name"] not in ONLY: continue
    B = build(t)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    pal = {"Head": t["head"], "Dark": t["dark"], "Light": t["light"], "Handle": t["handle"], "Grip": t["grip"], "Band": t["band"]}
    solids, tris = [], 0
    for role, b in B.groups.items():
        bmesh.ops.remove_doubles(b, verts=b.verts, dist=1e-5)
        bmesh.ops.triangulate(b, faces=b.faces)
        nm = f"Head__{role}" if role in ("Accent", "Gem", "Crystal") else f"Solid_{role}"
        me = bpy.data.meshes.new(nm); b.to_mesh(me); b.free()
        tris += len(me.polygons)
        o = bpy.data.objects.new(nm, me); bpy.context.scene.collection.objects.link(o)
        if role not in ("Accent", "Gem", "Crystal"):
            m = bpy.data.materials.new(role); m.use_nodes = True; m["base"] = hexlin(pal[role])
            me.materials.append(m); solids.append(o)
    if solids and not NOBAKE:
        bake(solids, os.path.join(OUT, t["name"] + "_tex.png"))
    elif solids:
        bpy.ops.object.select_all(action="DESELECT")
        for o in solids: o.select_set(True)
        bpy.context.view_layer.objects.active = solids[0]; bpy.ops.object.join()
        bpy.context.view_layer.objects.active.name = "Body__Tex"
    assert tris < 20000, (t["name"], tris)
    path = os.path.join(OUT, t["name"] + ".glb")
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", export_yup=True)
    print(f"{t['name']}: {tris} triangles -> {path}", flush=True)
