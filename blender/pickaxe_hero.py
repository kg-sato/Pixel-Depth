"""Build one magical pickaxe from a JSON Build spec (the Build spec on the Claude Design board), render it and export it (v2, 2026-11-08).
blender -b -P pickaxe_hero.py -- <spec.json> <ABSOLUTE out_dir> [samples] [game]
Axes: Blender z up (the handle), x across the head, -y toward the camera. 1 unit = 1 Roblox stud.
Head points in the spec are [x, z] offsets from the top of the handle (z = length). Spec keys: see specs/README.md.
Everything is built as low-poly bmesh geometry so a whole pickaxe stays far under the 20k-triangle MeshPart limit;
`game` merges the parts per material and writes <name>.glb + <name>_manifest.json (Roblox material and colour per part)."""
import bpy, json, math, os, random, sys
from mathutils import Vector

sys.path.insert(0, r"C:\Users\kgsat\Documents\Roblox\Blender")
import hero_lib as HL

argv = sys.argv[sys.argv.index("--") + 1:]
S = json.load(open(argv[0], encoding="utf-8"))
OUT = argv[1]
SAMPLES = int(argv[2]) if len(argv) > 2 else 64
GAME = "game" in argv[3:]
ICON = "icon" in argv[3:]  # forge card art: one transparent square render, tilted diagonal, then stop
os.makedirs(OUT, exist_ok=True)
scene = bpy.context.scene
for o in list(bpy.data.objects):
    bpy.data.objects.remove(o)
RNG = random.Random(S.get("seed", 7))
LEN = S.get("length", 3.6)
HR = S.get("handle_r", 0.075)
TRI_LIMIT = 20000


# ---------------------------------------------------------------- materials
def hexrgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


METAL = {"gold": "#e6bb6a", "rosegold": "#eba792", "silver": "#dfe3ef"}
ROBLOX = {"crystal": "Glass", "gold": "Metal", "rosegold": "Metal", "silver": "Metal"}
MATS = {}  # material name -> info for the manifest


def material(kind, c=None, glow=0.0):
    c = (c or METAL.get(kind, "#ffffff")).lower()
    name = f"{kind}_{c.lstrip('#')}_{int(glow * 10)}"
    if name in bpy.data.materials:
        return bpy.data.materials[name]
    v = hexrgb(c)
    m = bpy.data.materials.new(name)
    n, b = HL.principled(m)
    b.inputs["Base Color"].default_value = HL.rgb(*v)
    metal = kind in METAL
    b.inputs["Metallic"].default_value = 1.0 if metal else 0.0
    b.inputs["Roughness"].default_value = {"crystal": 0.05, "satin": 0.42, "irid": 0.38, "glitter": 0.45, "pearl": 0.18, "dark": 0.3, "wood": 0.6, "stone": 0.5}.get(kind, 0.26)
    if not metal:
        b.inputs["Specular IOR Level"].default_value = 0.3  # broad soft highlights wash pastel blades out
    b.inputs["Coat Weight"].default_value = 0.0 if (kind in ("satin", "wood") or metal) else 0.25
    if kind == "wood":  # soft grain lines (render only; the game part keeps the flat colour)
        wv, tc = n.nodes.new("ShaderNodeTexWave"), n.nodes.new("ShaderNodeTexCoord")
        n.links.new(tc.outputs["Object"], wv.inputs["Vector"])
        wv.inputs["Scale"].default_value, wv.inputs["Distortion"].default_value = 22.0, 2.5
        ramp = n.nodes.new("ShaderNodeValToRGB")
        ramp.color_ramp.elements[0].color = HL.rgb(*[int(x * 0.88) for x in v])
        ramp.color_ramp.elements[1].color = HL.rgb(*v)
        ramp.color_ramp.elements[0].position = 0.25
        n.links.new(wv.outputs["Fac"], ramp.inputs["Fac"])
        n.links.new(ramp.outputs["Color"], b.inputs["Base Color"])
    if kind in ("irid", "pearl"):  # iridescent sheen
        b.inputs["Thin Film Thickness"].default_value = 360.0 if kind == "pearl" else 480.0
        b.inputs["Thin Film IOR"].default_value = 1.4
    if kind == "crystal":
        b.inputs["Transmission Weight"].default_value = 0.45
        glow = max(glow, 0.35)  # crystals glow faintly from inside so they keep their colour on a dark night
        b.inputs["IOR"].default_value = 1.55
    if kind == "satin":
        b.inputs["Sheen Weight"].default_value = 0.8
        b.inputs["Sheen Tint"].default_value = (1, 1, 1, 1)
    if kind == "glitter":  # tinted sparkle flecks
        vr = n.nodes.new("ShaderNodeTexVoronoi")
        tc = n.nodes.new("ShaderNodeTexCoord")
        n.links.new(tc.outputs["Object"], vr.inputs["Vector"])  # object space in studs: flecks about 0.03 studs apart
        vr.inputs["Scale"].default_value = 32.0
        ramp = n.nodes.new("ShaderNodeValToRGB")
        e0, e1 = ramp.color_ramp.elements
        e0.position, e1.position = 0.0, 0.12
        e0.color = HL.rgb(*[min(255, int(x * 0.5 + 130)) for x in v])
        e1.color = (0, 0, 0, 1)
        n.links.new(vr.outputs["Distance"], ramp.inputs["Fac"])
        n.links.new(ramp.outputs["Color"], b.inputs["Emission Color"])
        b.inputs["Emission Strength"].default_value = 1.5 + glow * 4  # glow on glitter = denser starfield sparkle
    elif glow > 0:
        b.inputs["Emission Color"].default_value = HL.rgb(*v)
        b.inputs["Emission Strength"].default_value = glow
    MATS[name] = {"kind": kind, "color": c, "glow": glow, "roblox": "Neon" if glow >= 1.5 else ROBLOX.get(kind, "SmoothPlastic")}
    return m


def M(d, kind="irid", color=None, glow=0.0):
    """material from a spec dict's mat/color/glow keys"""
    k = d.get("mat", kind)
    return material(k, d.get("color") or (None if k in METAL else color), d.get("glow", glow))  # metals keep their own tint


# ---------------------------------------------------------------- mesh helpers
OBJS = []


def mk(name, verts, faces, m, smooth=True):
    me = bpy.data.meshes.new(name)
    me.from_pydata([tuple(v) for v in verts], [], faces)
    me.validate()
    import bmesh
    bm = bmesh.new()
    bm.from_mesh(me)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new(name, me)
    scene.collection.objects.link(o)
    for p in me.polygons:
        p.use_smooth = smooth
    me.materials.append(m)
    OBJS.append(o)
    return o


def keep(o, m, smooth=True):
    """adopt an object made by a bpy.ops primitive"""
    o.data.materials.clear()
    o.data.materials.append(m)
    for p in o.data.polygons:
        p.use_smooth = smooth
    OBJS.append(o)
    return o


def V(p):
    return Vector(p)


def hp(x, z, y=0.0):
    """head point: [x, z] from the top of the handle"""
    return Vector((x, y, LEN + z))


def spline(ctrl, per=8):
    """Catmull-Rom points through the control points"""
    P = [V(c) for c in ctrl]
    if len(P) == 2:
        return [P[0].lerp(P[1], t / per) for t in range(per + 1)]
    P = [P[0] * 2 - P[1]] + P + [P[-1] * 2 - P[-2]]
    out = []
    for i in range(1, len(P) - 2):
        p0, p1, p2, p3 = P[i - 1], P[i], P[i + 1], P[i + 2]
        for s in range(per):
            t = s / per
            out.append(0.5 * ((2 * p1) + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t * t + (-p0 + 3 * p1 - 3 * p2 + p3) * t ** 3))
    out.append(P[-2])
    return out


def plane_normals(pts):
    """per-point normal in the xz plane, perpendicular to the path, on the same side along the whole path"""
    sgn = 1.0 if (pts[-1].x - pts[0].x) >= 0 else -1.0
    ns = []
    for i in range(len(pts)):
        T = (pts[min(len(pts) - 1, i + 1)] - pts[max(0, i - 1)]).normalized()
        n = T.cross(Vector((0, 1, 0))) * sgn
        ns.append(n.normalized() if n.length > 1e-6 else Vector((1, 0, 0)))
    return ns


def sweep(name, pts, sec, m, nfun=None, cap=True, smooth=True, closed=False):
    """sweep a cross-section along a path. sec(t) -> [(u, v)] with offset = N*u + B*v; N from nfun(i, p, T) or the xz-plane normal."""
    pts = [V(p) for p in pts]
    n = len(pts)
    pn = plane_normals(pts) if nfun is None else None
    verts, faces, k = [], [], 0
    for i, p in enumerate(pts):
        a, b = (pts[i - 1], pts[(i + 1) % n]) if closed else (pts[max(0, i - 1)], pts[min(n - 1, i + 1)])
        T = (b - a).normalized()
        N = pn[i] if nfun is None else nfun(i, p, T)
        B = T.cross(N).normalized()
        N = B.cross(T).normalized()
        ring = sec(i / n if closed else i / (n - 1))
        k = len(ring)
        verts += [p + N * u + B * w for u, w in ring]
    for i in range(n if closed else n - 1):
        i2 = (i + 1) % n
        for j in range(k):
            j2 = (j + 1) % k
            faces.append((i * k + j, i * k + j2, i2 * k + j2, i2 * k + j))
    if cap and not closed:
        faces += [tuple(range(k))[::-1], tuple(range((n - 1) * k, n * k))]
    return mk(name, verts, faces, m, smooth)


def tube_sec(r, k=6):
    return lambda t: [(r(t) * math.cos(j / k * 2 * math.pi), r(t) * math.sin(j / k * 2 * math.pi)) for j in range(k)]


def lens_sec(wt, wb, th):
    """blade section: sharp top and bottom edges, thickness th"""
    return lambda t: [(wt(t), 0), (wt(t) * 0.45, th(t)), (-wb(t) * 0.45, th(t)), (-wb(t), 0), (-wb(t) * 0.45, -th(t)), (wt(t) * 0.45, -th(t))]


def strip_sec(w, th, twist=lambda t: 0.0):
    def f(t):
        a = twist(t)
        ca, sa = math.cos(a), math.sin(a)
        return [(u * ca - v * sa, u * sa + v * ca) for u, v in ((w(t), th), (-w(t), th), (-w(t), -th), (w(t), -th))]
    return f


def sphere(at, r, m, seg=12, rings=6, scale=(1, 1, 1), smooth=True):
    bpy.ops.mesh.primitive_uv_sphere_add(radius=r, location=at, segments=seg, ring_count=rings)
    o = bpy.context.object
    o.scale = scale
    return keep(o, m, smooth)


def torus(at, R, r, m, rot=(0, 0, 0), seg=20, minor=6):
    bpy.ops.mesh.primitive_torus_add(major_radius=R, minor_radius=r, location=at, rotation=rot, major_segments=seg, minor_segments=minor)
    return keep(bpy.context.object, m)


def spike(base, d, ln, r, m, k=6, pos=0.28):
    """elongated crystal bipyramid from base along direction d"""
    d = V(d).normalized()
    a = d.orthogonal().normalized()
    b = d.cross(a)
    ring = [base + d * ln * pos + (a * math.cos(j / k * 2 * math.pi) + b * math.sin(j / k * 2 * math.pi)) * r for j in range(k)]
    verts = ring + [base + d * ln, base]
    faces = [(j, (j + 1) % k, k) for j in range(k)] + [((j + 1) % k, j, k + 1) for j in range(k)]
    return mk("Spike", verts, faces, m, smooth=False)


# ---------------------------------------------------------------- 2D outlines (x, z) and faceted gems facing the camera
def outline(shape, size, n=24, points=5, ratio=0.45):
    if shape == "heart":
        P = []
        for i in range(n):
            t = i / n * 2 * math.pi
            P.append((16 * math.sin(t) ** 3 * size / 17, (13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t)) * size / 17 + size * 0.1))
        return P
    if shape == "star":
        return [((size if k % 2 == 0 else size * ratio) * math.cos(math.pi / 2 + k * math.pi / points), (size if k % 2 == 0 else size * ratio) * math.sin(math.pi / 2 + k * math.pi / points)) for k in range(points * 2)]
    if shape == "diamond":
        return [(0, size * 1.3), (-size * 0.75, 0), (0, -size * 1.3), (size * 0.75, 0)]
    if shape == "drop":  # teardrop, point up
        return [(size * 0.75 * math.sin(t) * math.sin(t / 2) ** 1.2, size * math.cos(t)) for t in [i / n * 2 * math.pi for i in range(n)]]
    if shape == "flower":
        return [(size * (0.5 + 0.5 * abs(math.cos(points * t / 2))) * math.cos(t), size * (0.5 + 0.5 * abs(math.cos(points * t / 2))) * math.sin(t)) for t in [i / n * 2 * math.pi + math.pi / 2 for i in range(n)]]
    if shape == "crescent":  # opening to the right
        R, r, c = size, size * 0.82, size * 0.42
        outer = [(R * math.cos(t), R * math.sin(t)) for t in [i / 48 * 2 * math.pi for i in range(48)] if math.hypot(R * math.cos(t) - c, R * math.sin(t)) > r]
        inner = [(c + r * math.cos(t), r * math.sin(t)) for t in [i / 48 * 2 * math.pi for i in range(48)] if math.hypot(c + r * math.cos(t), r * math.sin(t)) < R]
        outer.sort(key=lambda p: math.atan2(p[1], p[0]) % (2 * math.pi))
        inner.sort(key=lambda p: -(math.atan2(p[1], p[0] - c) % (2 * math.pi)))
        return outer + inner
    if shape == "oval":
        return [(size * 0.8 * math.cos(i / n * 2 * math.pi), size * math.sin(i / n * 2 * math.pi)) for i in range(n)]
    if shape == "rect":  # buckle plate, wider than tall
        return [(size * 1.2, size * 0.8), (-size * 1.2, size * 0.8), (-size * 1.2, -size * 0.8), (size * 1.2, -size * 0.8)]
    return [(size * math.cos(i / n * 2 * math.pi), size * math.sin(i / n * 2 * math.pi)) for i in range(n)]  # circle


def gem2d(name, shape, size, at, m, depth=None, table=0.55, rot=0.0, back=0.35, facet=True, n=24, points=5, ratio=0.45, sx=1.0, sz=1.0):
    """faceted gem: outline rim, a flat table toward the camera (-y), sloped crown facets, flat back"""
    depth = depth if depth is not None else size * 0.45
    O = outline(shape, size, n, points, ratio)
    ca, sa = math.cos(math.radians(rot)), math.sin(math.radians(rot))
    O = [((x * ca - z * sa) * sx, (x * sa + z * ca) * sz) for x, z in O]
    cx = sum(p[0] for p in O) / len(O)
    cz = sum(p[1] for p in O) / len(O)
    if shape == "crescent":  # inset along the outline normal (the centroid lies outside the shape)
        T = []
        for i, (x, z) in enumerate(O):
            ax, az = O[i - 1]
            bx, bz = O[(i + 1) % len(O)]
            nx, nz = -(bz - az), (bx - ax)
            ln = math.hypot(nx, nz) or 1
            T.append((x + nx / ln * size * 0.08, z + nz / ln * size * 0.08))
        area = sum(O[i - 1][0] * O[i][1] - O[i][0] * O[i - 1][1] for i in range(len(O)))
        if area > 0:  # make the inset go inward for either winding
            T = [(2 * x - tx, 2 * z - tz) for (x, z), (tx, tz) in zip(O, T)]
    else:
        T = [(cx + (x - cx) * table, cz + (z - cz) * table) for x, z in O]
    k = len(O)
    at = V(at)
    verts = [at + Vector((x, -depth * 0.35, z)) for x, z in O] + [at + Vector((x, -depth, z)) for x, z in T] + [at + Vector((x, depth * back, z)) for x, z in O]
    faces = [tuple(range(k, 2 * k))[::-1], tuple(range(2 * k, 3 * k))]
    for j in range(k):
        j2 = (j + 1) % k
        faces.append((j, j2, k + j2, k + j))
        faces.append((2 * k + j, 2 * k + j2, j2, j))
    return mk(name, verts, faces, m, smooth=not facet)


# ---------------------------------------------------------------- parts
def arm(a):
    sd, L = a["side"], a["len"]
    n = a.get("n", 24)
    rise, droop, curl = a.get("rise", 0.15), a.get("droop", 0.5), a.get("curl", 0.0)
    if "pts" in a:
        pts = spline([hp(sd * x, z) for x, z in a["pts"]], 6)
    else:
        pts = []
        for i in range(n):
            t = i / (n - 1)
            z = rise * math.sin(t * math.pi * 0.9) - droop * t ** a.get("bend", 2.2) + curl * max(0.0, t - 0.75) ** 2 * 16
            pts.append(hp(sd * (a.get("root", 0.06) + L * t), z))
    W, th0 = a.get("width", 0.24), a.get("thick", 0.05)
    tp, belly, top = a.get("taper", 0.8), a.get("belly", 0.0), a.get("top", 0.5)
    w = lambda t: max(0.004, W * ((1 - t) ** tp) * (1 + belly * math.sin(math.pi * t)))
    th = lambda t: max(0.003, th0 * (1 - 0.75 * t))
    o = sweep(f"Arm{sd}", pts, lens_sec(lambda t: w(t) * top, lambda t: w(t) * (1 - top), th), M(a, "irid", "#d6b8ff"), smooth=not a.get("facet", False))
    ns = plane_normals([V(p) for p in pts])
    if "core" in a:  # a second colour band through the middle of the blade (both faces)
        cf = a["core"].get("frac", 0.45)
        sweep(f"Core{sd}", pts, lens_sec(lambda t: w(t) * cf * top, lambda t: w(t) * cf * (1 - top), lambda t: th(t) * 1.25), M(a["core"], "irid", "#ffffff"))
    if "edge" in a:  # bright rim along the top edge
        e_pts = [p + nn * w(i / (len(pts) - 1)) * top * 0.96 for i, (p, nn) in enumerate(zip(pts, ns))]
        er = a.get("edge_r", 0.022)
        sweep(f"Edge{sd}", e_pts, tube_sec(lambda t: max(0.004, er * (1 - t) ** 0.4), 5), material(a.get("edge_mat", "irid"), a["edge"], a.get("edge_glow", 0.8)))
    if "edge2" in a:  # rim along the bottom edge
        e_pts = [p - nn * w(i / (len(pts) - 1)) * (1 - top) * 0.96 for i, (p, nn) in enumerate(zip(pts, ns))]
        er = a.get("edge_r", 0.022) * 0.8
        sweep(f"EdgeB{sd}", e_pts, tube_sec(lambda t: max(0.004, er * (1 - t) ** 0.4), 5), material(a.get("edge2_mat", "gold"), a["edge2"], 0.0))
    if "thorns" in a:  # serrated crystal thorns along the top edge, leaning toward the tip
        th_ = a["thorns"]
        for k in range(th_.get("n", 5)):
            t = th_.get("t0", 0.08) + (th_.get("t1", 0.6) - th_.get("t0", 0.08)) * k / max(1, th_.get("n", 5) - 1)
            i = int(t * (len(pts) - 1))
            T = (pts[min(i + 1, len(pts) - 1)] - pts[max(i - 1, 0)]).normalized()
            base = pts[i] + ns[i] * w(t) * top * 0.8
            ln = th_.get("len", 0.18) * (1 - 0.5 * k / max(1, th_.get("n", 5) - 1))
            spike(base, ns[i] * 0.75 + T * 0.65, ln, th_.get("r", 0.035), material(th_.get("mat", a.get("mat", "crystal")), th_.get("color", a.get("color")), th_.get("glow", 0.35)), k=4)
    if "filigree" in a:  # small metal scrolls along the top ridge
        fg = a["filigree"]
        for k in range(fg.get("n", 4)):
            t = 0.1 + 0.6 * k / max(1, fg.get("n", 4) - 1)
            i = int(t * (len(pts) - 1))
            c0 = pts[i] + ns[i] * w(t) * top * 0.9 + Vector((0, -th(t) - 0.01, 0))
            rr, turns = fg.get("r", 0.06) * (1 - 0.4 * t), 1.15
            sp = [c0 + Vector((sd * rr * math.exp(-0.28 * a_) * math.cos(a_), 0, rr * math.exp(-0.28 * a_) * math.sin(a_))) for a_ in [j / 12 * 2 * math.pi for j in range(int(turns * 12) + 1)]]
            sweep("Filigree", sp, tube_sec(lambda t_: max(0.004, fg.get("w", 0.012) * (1 - 0.6 * t_)), 4), material(fg.get("mat", "gold")))
    for g in a.get("gems", []):  # gems set on the blade at fraction t
        i = int(g["t"] * (len(pts) - 1))
        gem2d("ArmGem", g.get("shape", "circle"), g.get("size", 0.04), pts[i] + Vector((0, -th(g["t"]) * 0.6, 0)), M(g, "crystal", "#ffffff", 0.8), n=12)
    return pts


def feathers(c, at):
    """a fan of feathers (wing): each one a pointed blade"""
    sd = c.get("side", 1)
    for k in range(c.get("n", 6)):
        ln = c.get("len", 0.5) * (1 - k * c.get("shrink", 0.1))
        ang = math.radians(c.get("angle", 25) - k * c.get("spread", 14))
        d = Vector((sd * math.cos(ang), 0, math.sin(ang)))
        bend = Vector((0, 0, -1)) * c.get("bend", 0.08)
        pts = [at + Vector((0, -0.01 * k, 0)) + d * ln * u + bend * u * u for u in (0, 0.2, 0.4, 0.6, 0.8, 1.0)]
        wd = c.get("w", 0.06)
        sweep("Feather", pts, lens_sec(lambda t: max(0.004, wd * math.sin(math.pi * min(1, t * 0.9 + 0.1)) ** 0.6), lambda t: max(0.004, wd * 0.7 * math.sin(math.pi * min(1, t * 0.9 + 0.1)) ** 0.6), lambda t: 0.012), M(c, "silver"))


def burst(c, at):
    """ring or fan of flat faceted crystal leaves"""
    n = c.get("n", 12)
    r0, r1, wd, dp = c.get("r0", 0.1), c.get("r1", 0.4), c.get("w", 0.06), c.get("depth", 0.025)
    a0, a1 = c.get("from", 0), c.get("to", 360)
    cols = c.get("colors", [c.get("color", "#e8dcff")])
    full = (a1 - a0) % 360 == 0
    for k in range(n):
        f = (k + 0.5) / n if full else k / max(1, n - 1)
        ang = math.radians(a0 + (a1 - a0) * f + RNG.uniform(-1, 1) * c.get("jitter", 6))
        ln = (r1 - r0) * (1 - c.get("vary", 0.3) * RNG.random()) * (c.get("long_mid", 0) * math.sin(math.pi * f) + 1)
        d = Vector((math.cos(ang), 0, math.sin(ang)))
        pp = Vector((-math.sin(ang), 0, math.cos(ang)))
        y = Vector((0, -0.012 * (k % 2) + c.get("y", 0.0), 0))
        base = at + d * r0 + y
        tip = at + d * (r0 + ln) + y + Vector((0, -c.get("cup", 0.0) * ln, 0))
        mid = base.lerp(tip, 0.42)
        left, right = mid + pp * wd, mid - pp * wd
        fa, ba = mid + Vector((0, -dp, 0)), mid + Vector((0, dp * 0.6, 0))
        verts = [base, left, tip, right, fa, ba]
        faces = [(0, 1, 4), (1, 2, 4), (2, 3, 4), (3, 0, 4), (1, 0, 5), (2, 1, 5), (3, 2, 5), (0, 3, 5)]
        mk("Leaf", verts, faces, material(c.get("mat", "crystal"), cols[k % len(cols)], c.get("glow", 0.25)), smooth=False)


def blossoms(c, at):
    n, r = c.get("n", 8), c.get("r", 0.25)
    py = c.get("py", -0.05)
    pos = [hp(*p, y=py) for p in c["pts"]] if "pts" in c else [at + Vector((math.cos(k / n * 2 * math.pi + 0.3) * r, py, math.sin(k / n * 2 * math.pi + 0.3) * r)) for k in range(n)]
    cols = c.get("colors", [c.get("color", "#f7c8ea")])
    for k, p in enumerate(pos):
        s = c.get("size", 0.06) * (0.85 + 0.3 * RNG.random())
        gem2d("Blossom", "flower", s, p + Vector((0, -0.01 * (k % 3), 0)), material(c.get("mat", "irid"), cols[k % len(cols)], c.get("glow", 0.1)), depth=s * 0.3, table=0.5, facet=False, n=20, rot=RNG.uniform(0, 72))
        sphere(p + Vector((0, -s * 0.45, 0)), s * 0.22, material(c.get("center", "gold")), seg=8, rings=4)


def scroll(c, at):
    """gold filigree spiral(s)"""
    for sd in ([-1, 1] if c.get("mirror", True) else [c.get("side", 1)]):
        r0, turns, b = c.get("r", 0.12), c.get("turns", 1.25), c.get("grow", 0.25)
        rot = math.radians(c.get("rot", 0))
        pts = []
        for i in range(int(turns * 16) + 1):
            th = i / 16 * 2 * math.pi
            rr = r0 * math.exp(-b * th)
            x, z = rr * math.cos(th + rot), rr * math.sin(th + rot)
            pts.append(at + Vector((sd * (x + c.get("dx", 0.0)), 0.0, z)))
        wr = c.get("w", 0.016)
        sweep("Scroll", pts, tube_sec(lambda t: max(0.004, wr * (1 - 0.6 * t)), 5), M(c, "gold"))


def chain(pts, c):
    """bead chain along a path: a thin wire with small beads"""
    path = spline(pts, 10)
    sweep("Wire", path, tube_sec(lambda t: c.get("wire", 0.005), 4), material(c.get("chain", "gold"), c.get("chain_color")))  # chain_color: a tinted cord
    acc, step, last = 0.0, c.get("step", 0.055), path[0]
    for p in path[1:]:
        acc += (p - last).length
        last = p
        if acc >= step:
            acc = 0.0
            sphere(p, c.get("bead", 0.013), material(c.get("bead_mat", c.get("chain", "gold")), c.get("bead_color")), seg=6, rings=3)


def charm(kind, end, c):
    m = material(c.get("mat", "crystal"), c.get("color", "#d8ecff"), c.get("glow", 0.9))
    s = c.get("size", 0.07)
    if kind in ("star", "heart", "diamond", "circle", "oval", "flower"):
        gem2d("Charm", kind, s, end + Vector((0, 0, -s)), m, n=16, depth=s * 0.5)
    elif kind == "moon":
        gem2d("Charm", "crescent", s, end + Vector((0, 0, -s)), material(c.get("mat", "silver"), c.get("color")), depth=s * 0.35, rot=c.get("rot", 30))
    elif kind == "drop":
        spike(end + Vector((0, 0, -s * 0.3)), (0, 0, -1), s * 2.2, s * 0.45, m)
    elif kind == "pearl":
        sphere(end + Vector((0, 0, -s * 0.6)), s * 0.6, material("pearl", c.get("color", "#fff4f8")), seg=10, rings=6)
    elif kind == "tassel":  # bead + flared fringe
        sphere(end + Vector((0, 0, -s * 0.3)), s * 0.35, material("gold"), seg=8, rings=4)
        bpy.ops.mesh.primitive_cone_add(vertices=10, radius1=s * 0.55, radius2=s * 0.18, depth=s * 2.4, location=end + Vector((0, 0, -s * 1.9)))
        keep(bpy.context.object, material("satin", c.get("color", "#f4a9c8")))
    elif kind in ("acorn", "pebble"):  # egg-shaped nut under a cap, or a river pebble with a white stripe
        c0 = end + Vector((0, 0, -s * 1.0))
        sphere(c0, s * 0.62, material(c.get("mat", "wood" if kind == "acorn" else "stone"), c.get("color", "#e8b468" if kind == "acorn" else "#b5aec6")), seg=12, rings=8, scale=(1, 1, 1.3))
        if kind == "acorn":
            sphere(end + Vector((0, 0, -s * 0.32)), s * 0.7, material("wood", c.get("cap", "#9a6a3e")), seg=12, rings=6, scale=(1, 1, 0.55))
            spike(end + Vector((0, 0, -s * 0.05)), (0, 0, 1), s * 0.35, s * 0.08, material("wood", c.get("cap", "#9a6a3e")), k=5)
        else:
            torus(c0, s * 0.6, s * 0.035, material("pearl", "#fbf8ff"), rot=(0.35, 0, 0), seg=16, minor=4)


def bow(bw):
    at = hp(*bw.get("at", [0, -0.3]), y=bw.get("y", -0.07))
    L, H = bw.get("size", 0.22), bw.get("size", 0.22) * bw.get("height", 0.7)
    m = material(bw.get("mat", "satin"), bw.get("color", "#f6c3e4"))
    import bmesh
    for sd in (-1, 1):
        bm = bmesh.new()
        bmesh.ops.create_uvsphere(bm, u_segments=14, v_segments=8, radius=1.0)
        for v in bm.verts:
            u = (v.co.x + 1) / 2  # 0 at the knot, 1 at the outer end
            z = v.co.z * H * (0.3 + 0.7 * u ** 0.6)
            dent = 0.25 * max(0.0, -v.co.y) * math.sin(math.pi * u)  # soft fold in the front face
            v.co = Vector((sd * u * L, v.co.y * H * 0.45 + dent * H, z + u * L * bw.get("lift", 0.25)))
        me = bpy.data.meshes.new("BowLoop")
        bm.to_mesh(me)
        bm.free()
        o = bpy.data.objects.new("BowLoop", me)
        scene.collection.objects.link(o)
        o.location = at
        keep(o, m)
    sphere(at + Vector((0, -0.02, 0)), L * 0.22, m, seg=10, rings=6, scale=(1, 0.8, 1.15))
    if bw.get("gem"):
        gem2d("BowGem", bw.get("gem_shape", "circle"), L * 0.2, at + Vector((0, -L * 0.18, 0)), material("crystal", bw["gem"], 1.0), n=14)
    for tail in bw.get("tails", []):
        ribbon({**tail, "color": tail.get("color", bw.get("color")), "mat": bw.get("mat", "satin")})


def ribbon(rb):
    y = rb.get("y", -0.06)
    pts = spline([hp(p[0], p[1], p[2] if len(p) > 2 else y) for p in rb["pts"]], rb.get("per", 6))  # optional per-point y wraps a strap round the head
    wd, tw = rb.get("width", 0.12) / 2, rb.get("twist", 0.9)
    sweep("Ribbon", pts, strip_sec(lambda t: wd * (1 - 0.25 * t), 0.006, lambda t: tw * math.sin(t * math.pi * rb.get("waves", 1.5))), material(rb.get("mat", "satin"), rb.get("color", "#f7c8e6"), rb.get("glow", 0.0)))


# ---------------------------------------------------------------- build
h = S.get("handle", {})
hb = h.get("r_bottom", HR)
sweep("Handle", [(0, 0, h.get("z0", 0.0)), (0, 0, LEN * 0.5), (0, 0, LEN)], tube_sec(lambda t: hb + (HR - hb) * t, 14), M(h, "irid", "#d9b8f0"), nfun=lambda i, p, T: Vector((1, 0, 0)))
if "wrap" in h:
    w = h["wrap"]
    turns, z0, z1 = w.get("turns", 7), w.get("z0", 0.25), w.get("z1", LEN - 0.35)
    pts = []
    for i in range(int(turns * 14) + 1):
        t = i / (turns * 14)
        a = t * turns * 2 * math.pi
        r = hb + (HR - hb) * ((z0 + (z1 - z0) * t) / LEN)
        pts.append((math.cos(a) * r, math.sin(a) * r, z0 + (z1 - z0) * t))
    bw_ = w.get("w", 0.035)
    sweep("Wrap", pts, lambda t: [(-0.004, bw_), (0.012, bw_), (0.012, -bw_), (-0.004, -bw_)], M(w, "satin", "#f7c8e6"), nfun=lambda i, p, T: Vector((p[0], p[1], 0)).normalized())
for b in h.get("bands", []):
    torus((0, 0, b["z"]), HR * b.get("scale", 1.12), b.get("r", 0.022), M(b, "gold"), minor=6)
for sl in h.get("sleeves", []):  # thicker ornate sections of the handle
    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=sl.get("r", HR * 1.3), depth=sl["z1"] - sl["z0"], location=(0, 0, (sl["z0"] + sl["z1"]) / 2))
    keep(bpy.context.object, M(sl, "rosegold"))
for b in h.get("gems", []):  # gems set along the handle, facing the camera
    gem2d("HandleGem", b.get("shape", "circle"), b.get("size", 0.05), (0, -HR * 0.75, b["z"]), M(b, "crystal", "#ffffff", 0.9), n=12)

p = S.get("pommel")
if p:
    pr, pl = p.get("r", 0.11), p.get("len", 0.32)
    if p.get("type", "gem") == "gem":  # faceted point
        spike(Vector((0, 0, 0.02)), (0, 0, -1), pl, pr, M(p, "crystal", "#c8b8ff", 0.6), k=p.get("facets", 8), pos=p.get("crown", 0.25))
    elif p["type"] == "orb":
        sphere((0, 0, -pr * 0.85), pr, M(p, "crystal", "#c8b8ff", 0.6), seg=16, rings=8)
    elif p["type"] == "moon":
        gem2d("PommelMoon", "crescent", pr, (0, 0, -pr * 0.9), M(p, "silver"), depth=pr * 0.4, rot=p.get("rot", -90))
    if p.get("collar", "gold"):
        torus((0, 0, 0.03), max(hb, pr * 0.7), 0.028, material(p.get("collar", "gold")), minor=6)
    if p.get("cap"):  # metal cap above the collar
        bpy.ops.mesh.primitive_cone_add(vertices=14, radius1=hb * 1.35, radius2=hb * 1.05, depth=p.get("cap", 0.12), location=(0, 0, 0.03 + p["cap"] / 2))
        keep(bpy.context.object, material(p.get("collar", "gold")))
    if "cage" in p:  # filigree cage: metal arcs from the collar around the pommel gem to its tip
        cg = p["cage"]
        ln = pl if p.get("type", "gem") == "gem" else pr * 2
        for k in range(cg.get("n", 4)):
            a = k / cg.get("n", 4) * 2 * math.pi + 0.4
            arc = [Vector((math.cos(a) * pr * f, math.sin(a) * pr * f, z)) for f, z in ((0.8, 0.02), (1.35, -ln * 0.3), (1.15, -ln * 0.6), (0.2, -ln * 0.95))]
            sweep("Cage", spline(arc, 6), tube_sec(lambda t: cg.get("w", 0.014), 5), material(cg.get("mat", "gold")), nfun=lambda i, q, T: T.orthogonal().normalized())
    for k in range(p.get("pearls", 0)):
        a = k / p["pearls"] * 2 * math.pi
        sphere((math.cos(a) * pr * 0.75, math.sin(a) * pr * 0.75, 0.0), 0.026, material("pearl", "#fff6fb"), seg=8, rings=4)

if "arm" in S:  # one arm spec, mirrored
    S["arms"] = [{**S["arm"], "side": -1}, {**S["arm"], "side": 1}]
for a in S.get("arms", []):
    arm(a)

for c in S.get("center", []):
    t = c["type"]
    at = hp(*c.get("at", [0, 0]), y=c.get("y", -0.06))
    if t in ("heart", "star", "gem", "circle", "oval", "diamond", "drop", "crescent", "flower"):
        shape = c.get("shape", t if t != "gem" else "circle")
        if "frame" in c:
            gem2d("Frame", shape, c["size"] * c.get("frame_scale", 1.22), at + Vector((0, 0.035, 0)), material(c.get("frame_mat", "gold"), c["frame"]), facet=False, table=0.85, depth=c["size"] * 0.25, rot=c.get("rot", 0), n=28, points=c.get("points", 5), ratio=c.get("ratio", 0.45))
        gem2d(t.title(), shape, c["size"], at, M(c, "crystal", "#f0b2ff", 1.0), depth=c.get("depth"), rot=c.get("rot", 0), n=28, points=c.get("points", 5), ratio=c.get("ratio", 0.45), sx=c.get("sx", 1.0), sz=c.get("sz", 1.0))
    elif t in ("orb", "pearl"):
        sphere(at, c.get("r", 0.12), material("pearl", c.get("color", "#fff4fa")) if t == "pearl" else M(c, "crystal", "#c8e0ff", 1.2), seg=18, rings=10, scale=tuple(c.get("scale", (1, 1, 1))))
    elif t == "ring":
        torus(at, c.get("r", 0.2), c.get("w", 0.02), M(c, "gold"), rot=(math.pi / 2, 0, 0), seg=28)
    elif t == "spike":
        d = c.get("dir", [0, 0, 1])
        spike(at, d, c.get("len", 0.35), c.get("r", 0.07), M(c, "crystal", "#e8d6ff", 0.8), k=c.get("facets", 6))
    elif t == "spikes":  # fan of crystal points
        n = c.get("n", 5)
        for k in range(n):
            ang = math.radians(c.get("from", 30) + (c.get("to", 150) - c.get("from", 30)) * k / max(1, n - 1))
            mid = 1 - abs(k / max(1, n - 1) - 0.5) * 2
            ln = c.get("len", 0.25) * (c.get("edge_len", 0.6) + (1 - c.get("edge_len", 0.6)) * mid)
            d = Vector((math.cos(ang), 0, math.sin(ang)))
            spike(at + d * c.get("r", 0.12), d, ln, c.get("w", 0.04), M(c, "crystal", "#e8f2ff", 0.6), k=c.get("facets", 5))
    elif t == "burst":
        burst(c, at)
    elif t == "blossoms":
        blossoms(c, at)
    elif t == "wing":
        feathers(c, at)
    elif t == "scroll":
        scroll(c, at)
    elif t == "pearls":  # a ring or arc of small pearls in the picture plane
        n = c.get("n", 10)
        a0, a1 = c.get("from", 0), c.get("to", 360)
        for k in range(n):
            a = math.radians(a0 + (a1 - a0) * (k / n if (a1 - a0) % 360 == 0 else k / max(1, n - 1)))
            sphere(at + Vector((math.cos(a) * c.get("r", 0.2), 0, math.sin(a) * c.get("r", 0.2))), c.get("size", 0.03), material("pearl", c.get("color", "#fff4fa")), seg=8, rings=5)
    elif t == "collar":  # the head's socket block around the handle top
        bpy.ops.mesh.primitive_cylinder_add(vertices=c.get("facets", 12), radius=c.get("r", 0.11), depth=c.get("h", 0.18), location=at + Vector((0, 0.06, 0)))
        keep(bpy.context.object, M(c, "gold"), smooth=c.get("facets", 12) > 8)

if "bow" in S:
    bow(S["bow"])
for rb in S.get("ribbons", []):
    ribbon(rb)
for ch in S.get("chains", []):  # swags between two head points, optional charm at the lowest point
    p0, p1 = hp(*ch["from"], y=ch.get("y", -0.07)), hp(*ch["to"], y=ch.get("y", -0.07))
    mid = (p0 + p1) / 2 + Vector((0, 0, -ch.get("sag", 0.15)))
    chain([p0, mid, p1], ch)
    if ch.get("charm"):
        charm(ch["charm"], mid + Vector((0, 0, -0.01)), ch)
for ch in S.get("charms", []):  # dangling chain + charm
    ax, az = ch["anchor"]
    ln = ch.get("len", 0.5)
    top = hp(ax, az, ch.get("y", -0.07))
    end = top + Vector((ch.get("swing", 0.0), 0, -ln))
    chain([top, top.lerp(end, 0.5) + Vector((ch.get("swing", 0.0) * 0.2, 0, 0)), end], ch)
    charm(ch.get("charm", "star"), end, ch)

# ---------------------------------------------------------------- budget
groups = {}
for o in OBJS:
    groups.setdefault(o.data.materials[0].name, []).append(o)
tri = lambda o: sum(len(q.vertices) - 2 for q in o.data.polygons)
total = sum(tri(o) for o in OBJS)
per = {g: sum(tri(o) for o in os_) for g, os_ in groups.items()}
print("PICKAXE", S["name"], "objects", len(OBJS), "parts", len(groups), "tris", total, flush=True)
assert total < TRI_LIMIT, f"{S['name']}: {total} tris (limit {TRI_LIMIT})"
json.dump({"name": S["name"], "objects": len(OBJS), "parts": len(groups), "tris": total, "per_part": per}, open(os.path.join(OUT, "stats.json"), "w"), indent=1)

# ---------------------------------------------------------------- render VFX (renders only, never exported): twinkle stars + gem light
VFX = []
fx = S.get("vfx", {})
if fx.get("sparkles", 14):
    xs0 = [(o.matrix_world @ v.co) for o in OBJS for v in o.data.vertices]
    span = max(abs(v.x) for v in xs0)
    for k in range(fx.get("sparkles", 14)):
        a = RNG.uniform(0, 2 * math.pi)
        rr = RNG.uniform(0.25, 1.0)
        pos = hp(math.cos(a) * span * rr * 1.05, math.sin(a) * 0.55 * rr - 0.15 - RNG.random() * 0.8 * (k % 3 == 0), -0.25 - RNG.random() * 0.2)
        s_ = RNG.uniform(0.025, 0.07)
        cols = fx.get("colors", ["#ffffff"])
        before = len(OBJS)
        gem2d("Twinkle", "star", s_, pos, material("fx", cols[k % len(cols)], 9.0), points=4, ratio=0.18, depth=0.004, n=8, rot=RNG.uniform(-12, 12))
        VFX.append(OBJS.pop())
if fx.get("light"):
    L = bpy.data.lights.new("GemLight", "POINT")
    L.energy, L.color, L.shadow_soft_size = fx.get("light_power", 60), tuple(c / 255 for c in hexrgb(fx["light"])), 0.3
    lo = bpy.data.objects.new("GemLight", L)
    scene.collection.objects.link(lo)
    lo.location = hp(0, 0, -0.45)
    VFX.append(lo)

# ---------------------------------------------------------------- render: night studio, hero (concept angle), front, side
xs = [(o.matrix_world @ v.co) for o in OBJS for v in o.data.vertices]
zmin, zmax = min(v.z for v in xs), max(v.z for v in xs)
xext = max(abs(v.x) for v in xs)
ctr = Vector((0, 0, (zmin + zmax) / 2))
piv = bpy.data.objects.new("Pivot", None)
scene.collection.objects.link(piv)
piv.location = ctr
bpy.context.view_layer.update()  # matrix_world must include the new location before it is inverted
for o in OBJS + VFX:
    o.parent = piv
    o.matrix_parent_inverse = piv.matrix_world.inverted()
w = bpy.data.worlds.new("W")
scene.world = w
w.use_nodes = True
wn = w.node_tree
bg = wn.nodes["Background"]
bg.inputs["Color"].default_value = HL.rgb(*hexrgb(fx.get("ambient", "#8a84a0")))  # what metals and gems reflect
tc, sep, ramp = wn.nodes.new("ShaderNodeTexCoord"), wn.nodes.new("ShaderNodeSeparateXYZ"), wn.nodes.new("ShaderNodeValToRGB")
wn.links.new(tc.outputs["Window"], sep.inputs[0])
wn.links.new(sep.outputs["Y"], ramp.inputs["Fac"])
ramp.color_ramp.elements[0].color = HL.rgb(*hexrgb(fx.get("bg_bottom", "#120d22")))
ramp.color_ramp.elements[1].color = HL.rgb(*hexrgb(fx.get("bg_top", "#2e2150")))
bg2 = wn.nodes.new("ShaderNodeBackground")
wn.links.new(ramp.outputs["Color"], bg2.inputs["Color"])
lp, mix = wn.nodes.new("ShaderNodeLightPath"), wn.nodes.new("ShaderNodeMixShader")
wn.links.new(lp.outputs["Is Camera Ray"], mix.inputs[0])
wn.links.new(bg.outputs[0], mix.inputs[1])
wn.links.new(bg2.outputs[0], mix.inputs[2])
wn.links.new(mix.outputs[0], wn.nodes["World Output"].inputs["Surface"])
HL.area_light(scene, "Key", ctr + Vector((-3.5, -5.0, 3.5)), 450, 5.0, (1.0, 0.9, 0.93), ctr)
HL.area_light(scene, "Rim", ctr + Vector((4.0, 3.5, 2.5)), 700, 4.0, (0.62, 0.78, 1.0), ctr)
HL.area_light(scene, "Fill", ctr + Vector((3.5, -5.0, -0.5)), 160, 6.0, (0.95, 0.85, 1.0), ctr)
HL.area_light(scene, "Top", ctr + Vector((0.0, -1.5, 5.0)), 160, 3.0, (1.0, 0.95, 1.0), ctr)
cam_d = bpy.data.cameras.new("Cam")
cam = bpy.data.objects.new("Cam", cam_d)
scene.collection.objects.link(cam)
scene.camera = cam
cam_d.lens = 50
cam_d.sensor_width = 36
HL.setup_cycles(scene, SAMPLES)
scene.view_settings.view_transform = "Standard"  # AgX greys out bright saturated pastels; the concepts are saturated
scene.view_settings.look = "None"
scene.view_settings.exposure = -0.6  # pastel blades clip to white at 0
scene.render.resolution_x, scene.render.resolution_y = 900, 1350
half = max((zmax - zmin) / 2, xext * 1.5) * 1.12
dist = half / math.tan(math.atan(18 / 50))
tilt = math.radians(S.get("tilt", -15))
shots = {"hero": (0, tilt, math.radians(S.get("yaw", 22))), "front": (0, 0, 0), "side": (0, 0, math.radians(90))}
if ICON:
    scene.render.film_transparent = True
    scene.render.resolution_x = scene.render.resolution_y = 512
    piv.rotation_euler = (0, math.radians(-38), math.radians(S.get("yaw", 22)))
    bpy.context.view_layer.update()
    pts = [(o.matrix_world @ v.co) for o in OBJS for v in o.data.vertices]
    half = max(max(abs(v.x - ctr.x) for v in pts), max(abs(v.z - ctr.z) for v in pts)) * 1.06
    dist = half / math.tan(math.atan(18 / 50))
    cam.location = ctr + Vector((0, -dist, 0))
    cam.rotation_euler = (ctr - cam.location).to_track_quat("-Z", "Y").to_euler()
    scene.render.filepath = os.path.join(OUT, f"{S['name']}_icon.png")
    bpy.ops.render.render(write_still=True)
    print("ICON", scene.render.filepath)
    sys.exit(0)
for label, rot in shots.items():
    piv.rotation_euler = rot
    cam.location = ctr + Vector((0, -dist, dist * 0.08))
    cam.rotation_euler = (ctr - cam.location).to_track_quat("-Z", "Y").to_euler()
    scene.render.filepath = os.path.join(OUT, f"{S['name']}_{label}.png")
    bpy.ops.render.render(write_still=True)

# ---------------------------------------------------------------- export: one MeshPart per material, handle bottom at the origin
if GAME:
    for o in VFX:
        bpy.data.objects.remove(o)
    piv.rotation_euler = (0, 0, 0)
    bpy.context.view_layer.update()
    for o in OBJS:
        mw = o.matrix_world.copy()
        o.parent = None
        o.matrix_world = mw
    # palette atlas: every material becomes one 8x8 cell of a small PNG, so a pickaxe is at most 4 MeshParts (one per Roblox material)
    names = list(groups)
    assert len(names) <= 64, "more than 64 materials"
    img = bpy.data.images.new(S["name"] + "_palette", 64, 64)
    px = [1.0] * (64 * 64 * 4)
    for i, nm in enumerate(names):
        r, g, b = hexrgb(MATS[nm]["color"])
        cx, cy = (i % 8) * 8, (i // 8) * 8
        for yy in range(cy, cy + 8):
            for xx in range(cx, cx + 8):
                px[(yy * 64 + xx) * 4:(yy * 64 + xx) * 4 + 4] = [r / 255, g / 255, b / 255, 1.0]
    img.pixels = px
    img.filepath_raw = os.path.join(OUT, S["name"] + "_palette.png")
    img.file_format = "PNG"
    img.save()
    cls_mat = {}
    for cls in ("SmoothPlastic", "Glass", "Metal", "Neon"):
        m = bpy.data.materials.new("PD_" + cls)
        n, b = HL.principled(m)
        tx = n.nodes.new("ShaderNodeTexImage")
        tx.image = img
        tx.interpolation = "Closest"
        n.links.new(tx.outputs["Color"], b.inputs["Base Color"])
        b.inputs["Metallic"].default_value = 1.0 if cls == "Metal" else 0.0
        b.inputs["Roughness"].default_value = {"Glass": 0.05, "Metal": 0.3}.get(cls, 0.35)
        if cls == "Neon":
            n.links.new(tx.outputs["Color"], b.inputs["Emission Color"])
            b.inputs["Emission Strength"].default_value = 2.0
        cls_mat[cls] = m
    byclass = {}
    for i, nm in enumerate(names):
        uv = (((i % 8) * 8 + 4) / 64, ((i // 8) * 8 + 4) / 64)  # image row 0 is the bottom in Blender
        cls = MATS[nm]["roblox"]
        for o in groups[nm]:
            me = o.data
            if not me.uv_layers:
                me.uv_layers.new()
            for d in me.uv_layers.active.data:
                d.uv = uv
            me.materials.clear()
            me.materials.append(cls_mat[cls])
            byclass.setdefault(cls, []).append(o)
    manifest = {"vfx": fx, "name": S["name"], "units": "studs (1 Blender unit = 1 stud); glTF is Y-up: handle along +Y, head at Y=length",
                "length": LEN, "grip": [0, round(LEN * 0.3, 3), 0], "tris": total, "palette": S["name"] + "_palette.png", "parts": {}}
    for cls, members in byclass.items():
        bpy.ops.object.select_all(action="DESELECT")
        for o in members:
            o.select_set(True)
        bpy.context.view_layer.objects.active = members[0]
        if len(members) > 1:
            bpy.ops.object.join()
        j = bpy.context.view_layer.objects.active
        j.name = f"{S['name']}_{cls}"
        manifest["parts"][j.name] = {"roblox_material": cls, "tris": tri(j), "transparency": 0.25 if cls == "Glass" else 0.0}
        assert tri(j) < TRI_LIMIT
    bpy.ops.object.select_all(action="DESELECT")
    for o in scene.objects:
        if o.type == "MESH":
            o.select_set(True)
    bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, S["name"] + ".glb"), export_format="GLB", use_selection=True, export_apply=True)
    json.dump(manifest, open(os.path.join(OUT, S["name"] + "_manifest.json"), "w"), indent=1)
    print("EXPORTED", S["name"], len(manifest["parts"]), "parts", {k: v["tris"] for k, v in manifest["parts"].items()}, flush=True)
print("DONE", flush=True)
