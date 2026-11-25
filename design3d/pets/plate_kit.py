"""Armoured-plate creature kit for the v16 pets (2026-11-24). Target: the owner's "Lure a Pet Showcase" reference
(Overnight/refs/pets_v16/user_*.jpg: Abyss Spear Kraken, Eclipse Loomweaver): big creatures built from bevelled block
segments stacked in stepped tiers, limbs as chains of tapering blocks ending in ivory claws, small glowing inset slits,
fine voxel crests, a 2048 px baked atlas with panel seams, occlusion and an edge light.
Blender coordinates: x right, y forward (where the pet looks), z up, studs. Every chain segment is its own Part (a bone the
game animates: Shared.PetRig). Roles: Tex (baked into the pet's one atlas), Glow (inset emissive, Neon in game), Gem.
    import plate_kit as K; c = K.Creature(name, palette); ...; K.export(c, out_dir)"""
import bpy, bmesh, math, os
from mathutils import Vector, Matrix, Quaternion, Euler

V = lambda *a: Vector(a[0]) if len(a) == 1 else Vector(a)


def hexlin(h):
    h = h.lstrip("#")
    return tuple(((int(h[i:i + 2], 16) / 255) ** 2.2) for i in (0, 2, 4)) + (1.0,)


def look(d, up=V(0, 0, 1)):
    """a rotation whose local +y points along d (local +z as close to up as possible)"""
    d = V(d).normalized()
    if abs(d.dot(up)) > 0.98: up = V(0, 1, 0) if abs(d.y) < 0.9 else V(1, 0, 0)
    x = d.cross(up).normalized(); z = x.cross(d).normalized()
    return Matrix((x, d, z)).transposed()


class Creature:
    def __init__(self, name, palette):
        self.name, self.pal = name, palette
        self.pieces = {}   # (part, role) -> [bmesh pieces with colour tag]
        self.colours = {}  # (part, role) -> list of (bmesh, colour key)
        self.parent, self.pivots, self.anchors, self.groups, self.axes = {}, {}, {}, {}, {}

    def add(self, part, role, b, colour):
        self.colours.setdefault((part, role), []).append((b, colour))

    def joint(self, part, pivot, parent=None, group=None):
        self.pivots[part] = V(pivot); self.parent[part] = parent
        if group: self.groups[part] = group

    # -------- primitives (each makes a bmesh in place)
    def block(self, part, c, size, rot=None, bevel=0.07, colour="Main", role="Tex", taper=1.0, panel=0.0):
        """a bevelled brick; size (x, y, z); taper < 1 narrows the +y end (limb segments, claws)"""
        b = bmesh.new()
        bmesh.ops.create_cube(b, size=1.0)
        for v in b.verts:
            if v.co.y > 0: v.co.x *= taper; v.co.z *= taper
        bmesh.ops.scale(b, vec=V(size), verts=b.verts)
        if bevel > 0:
            bmesh.ops.bevel(b, geom=list(b.edges), offset=bevel * min(size), segments=1, affect="EDGES", clamp_overlap=True)
        if panel > 0:  # raise each big face as a plate with a groove round it
            big = [f for f in b.faces if f.calc_area() > (panel * 4) ** 2]
            if big: bmesh.ops.inset_individual(b, faces=big, thickness=panel, depth=panel * 0.6, use_even_offset=True)
        if rot is not None: bmesh.ops.rotate(b, verts=b.verts, cent=V(0, 0, 0), matrix=rot if isinstance(rot, Matrix) else Euler(rot).to_matrix())
        bmesh.ops.translate(b, vec=V(c), verts=b.verts)
        self.add(part, role, b, colour)

    def tiers(self, part, c, size, n=4, shrink=0.16, rise=None, colour="Main", top_colour=None, rot=None):
        """a stepped ziggurat: n bevelled tiers, each smaller than the one under it"""
        c, size = V(c), V(size)
        h = size.z / n
        for i in range(n):
            k = 1 - shrink * i
            cc = c + V(0, 0, -size.z / 2 + h * (i + 0.5))
            if rot is not None: cc = c + (rot @ (cc - c))
            self.block(part, cc, (size.x * k, size.y * k, h * 1.02), rot=rot, bevel=0.05, colour=top_colour if (top_colour and i == n - 1) else colour)

    def segment(self, part, a, b, w0, w1, colour="Main", bevel=0.08, up=V(0, 0, 1), depth=1.0, role="Tex"):
        """a block spanning a -> b, tapering from width w0 to w1 (depth scales the height)"""
        a, b = V(a), V(b)
        L = (b - a).length
        self.block(part, (a + b) / 2, (w0, L, w0 * depth), rot=look(b - a, up), bevel=bevel, colour=colour, role=role, taper=w1 / w0)

    def claw(self, part, base, tip, w, colour="Bone", curl=0.0, up=V(0, 0, 1)):
        """an ivory claw/spike: three shrinking bevelled blocks bending toward 'curl' (a vector) at the tip"""
        base, tip = V(base), V(tip)
        mid = (base + tip) / 2 + V(curl) * 0.5 if not isinstance(curl, float) else (base + tip) / 2
        pts = [base, base.lerp(mid, 0.9), mid.lerp(tip, 0.55), tip]
        for i in range(3):
            self.segment(part, pts[i], pts[i + 1], w * (1 - 0.3 * i), w * (0.7 - 0.25 * i) + 0.01, colour=colour, bevel=0.1, up=up)

    def chain(self, prefix, pts, widths, colour="Main", parent=None, claw=None, group=None, up=V(0, 0, 1), depth=1.0, spikes=0):
        """a limb or tentacle: one Part per segment (prefix1, prefix2, ...), each parented to the one before; claw = (length, width)"""
        names = []
        prev = parent
        for i in range(len(pts) - 1):
            nm = f"{prefix}{i + 1}"
            self.joint(nm, pts[i], prev, group)
            self.plated(nm, pts[i], pts[i + 1], widths[i], widths[i + 1] * 1.08, colour=colour, plate=colour + "Top", up=up, depth=depth, ribs=1 if (V(pts[i + 1]) - V(pts[i])).length < 1.2 else 2, spikes=spikes if i < len(pts) - 2 else 0)
            names.append(nm); prev = nm
        if claw:
            L, w = claw
            a, b = V(pts[-2]), V(pts[-1])
            d = (b - a).normalized()
            self.claw(names[-1], b - d * w * 0.3, b + d * L, w, curl=V(0, 0, -L * 0.35) if d.z > -0.5 else d * 0.0)
        return names

    def plated(self, part, a, b, w0, w1, colour="Main", plate="MainTop", up=V(0, 0, 1), depth=1.0, ribs=2, spikes=0, spike_colour="Bone"):
        """a richer limb/body segment like the reference: a core block, a raised armour plate on its top face, a darker joint
        collar at its root, ribs across it and optional spikes along the plate"""
        a, b = V(a), V(b)
        d = b - a; L = d.length; dn = d.normalized()
        R = look(d, up)
        side, upv = R.col[0], R.col[2]
        self.segment(part, a, b, w0, w1, colour=colour, up=up, depth=depth)
        wm = (w0 + w1) / 2
        self.block(part, (a + b) / 2 + upv * wm * depth * 0.5, (wm * 0.72, L * 0.86, wm * 0.22), rot=R, bevel=0.12, colour=plate)
        self.block(part, a + dn * L * 0.06, (w0 * 1.12, L * 0.14, w0 * depth * 1.12), rot=R, bevel=0.1, colour="Dark")
        for k in range(ribs):
            u = (k + 1) / (ribs + 1)
            w = w0 + (w1 - w0) * u
            self.block(part, a + dn * L * u, (w * 1.06, L * 0.06, w * depth * 1.06), rot=R, bevel=0.1, colour="Dark")
        for k in range(spikes):
            u = (k + 0.5) / spikes
            w = w0 + (w1 - w0) * u
            base = a + dn * L * u + upv * w * depth * 0.62
            self.claw(part, base, base + upv * w * 0.9 - dn * w * 0.35, w * 0.28, colour=spike_colour)

    def studs(self, part, pts, r=0.07, colour="Bone"):
        """rivet studs: small bevelled blocks at each point (the reference's stud rows)"""
        for q in pts:
            self.block(part, q, (r * 2, r * 2, r * 1.4), bevel=0.25, colour=colour)

    def window(self, part, c, w, h, normal, depth=0.12, frame="Dark", colour="Glow"):
        """a framed glowing window cut into a plate facing 'normal': a dark frame block and a recessed glow pane"""
        n = V(normal).normalized()
        R = look(n, V(0, 0, 1) if abs(n.z) < 0.9 else V(0, 1, 0))
        # local axes of look(): x = side, y = n, z = up
        self.block(part, V(c), (w * 1.35, depth * 1.6, h * 1.35), rot=R, bevel=0.12, colour=frame)
        self.block(part, V(c) + n * depth * 0.55, (w, depth, h), rot=R, bevel=0.0, colour=colour, role="Glow")

    def foot(self, part, c, w, fwd=V(0, 1, 0), claws=3, L=0.5, colour="Main"):
        """a broad armoured foot with ivory claws fanned forward"""
        c = V(c)
        self.block(part, c, (w * 1.25, w * 1.2, w * 0.55), rot=look(fwd), bevel=0.12, colour=colour)
        f = V(fwd).normalized(); side = f.cross(V(0, 0, 1)).normalized()
        for i in range(claws):
            o = (i - (claws - 1) / 2) * w * 0.42
            base = c + f * w * 0.5 + side * o + V(0, 0, -w * 0.05)
            self.claw(part, base, base + f * L + V(0, 0, -w * 0.25), w * 0.26, curl=V(0, 0, -L * 0.4))

    def vmass(self, part, elems, cell=0.1, colour="Main", band=None, top=None, seams=None, studs=None, keep=None, edge=None, shell=0):
        """an organic mass voxelised into stepped blocks (the reference's stepped armour). elems: ('e', centre, radii[, rot Matrix])
        ellipsoids and ('c', a, b, r0, r1) tapered capsules; their union fills 'cell'-stud cubes.
          band  = (colour, axis, every): alternate armour bands along an axis (0 x, 1 y, 2 z)
          top   = colour for cells with open sky above (the lit carapace)
          seams = (axis, every): carve a one-cell groove between plates along that axis (real panel seams)
          studs = (colour, every): 2x2-cell studs raised on upward faces on a grid (the reference's stud plates)
          keep  = f(x, y, z) -> bool on cell centres in studs: keep only part of the mass (plates, shells, half domes)
          edge  = colour for the lit outer edge cells of top surfaces
          shell = n: keep only the outer n cells (hollow plates laid over another mass)"""
        import math as _m
        lo, hi = V(1e9, 1e9, 1e9), V(-1e9, -1e9, -1e9)
        prep = []
        for e in elems:
            if e[0] == "e":
                c, r = V(e[1]), V(e[2]); R = e[3] if len(e) > 3 else None
                prep.append(("e", c, r, R.inverted() if R is not None else None)); m = max(r)
                lo = V(min(lo.x, c.x - m), min(lo.y, c.y - m), min(lo.z, c.z - m)); hi = V(max(hi.x, c.x + m), max(hi.y, c.y + m), max(hi.z, c.z + m))
            else:
                a2, b2, r0, r1 = V(e[1]), V(e[2]), e[3], e[4]
                prep.append(("c", a2, b2, r0, r1)); m = max(r0, r1)
                for q in (a2, b2):
                    lo = V(min(lo.x, q.x - m), min(lo.y, q.y - m), min(lo.z, q.z - m)); hi = V(max(hi.x, q.x + m), max(hi.y, q.y + m), max(hi.z, q.z + m))
        def inside(p):
            for e in prep:
                if e[0] == "e":
                    d = p - e[1]
                    if e[3] is not None: d = e[3] @ d
                    if (d.x / e[2][0]) ** 2 + (d.y / e[2][1]) ** 2 + (d.z / e[2][2]) ** 2 <= 1: return True
                else:
                    ab = e[2] - e[1]; L2 = ab.length_squared or 1e-9
                    t = max(0.0, min(1.0, (p - e[1]).dot(ab) / L2))
                    if (p - (e[1] + ab * t)).length <= e[3] + (e[4] - e[3]) * t: return True
            return False
        i0 = [int(_m.floor(lo[k] / cell)) - 1 for k in range(3)]; i1 = [int(_m.ceil(hi[k] / cell)) + 1 for k in range(3)]
        cells = set()
        for i in range(i0[0], i1[0] + 1):
            for j in range(i0[1], i1[1] + 1):
                for k in range(i0[2], i1[2] + 1):
                    pc = V((i + 0.5) * cell, (j + 0.5) * cell, (k + 0.5) * cell)
                    if inside(pc) and (keep is None or keep(pc.x, pc.y, pc.z)): cells.add((i, j, k))
        N6 = ((1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1))
        def exposed(q, cs): return any((q[0] + d[0], q[1] + d[1], q[2] + d[2]) not in cs for d in N6)
        if shell:
            outer = set(q for q in cells if exposed(q, cells))
            layer = set(outer)
            for _ in range(shell - 1):
                layer |= set(q for q in cells if q not in layer and any((q[0] + d[0], q[1] + d[1], q[2] + d[2]) in layer for d in N6))
            cells = layer
        if seams:
            ax, ev = seams
            surf = [q for q in cells if exposed(q, cells)]
            for q in surf:
                if q[ax] % ev == 0:
                    inner = sum((q[0] + d[0], q[1] + d[1], q[2] + d[2]) in cells for d in N6)
                    if inner >= 4: cells.discard(q)
        groups = {}
        for q in cells:
            i, j, k = q
            col = colour
            if band and ((q[band[1]]) // band[2]) % 2 == 1: col = band[0]
            if top and (i, j, k + 1) not in cells and (i, j, k + 2) not in cells: col = top
            if edge and (i, j, k + 1) not in cells and any((i + dx, j + dy, k) not in cells for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))): col = edge
            groups.setdefault(col, set()).add(q)
        allc = set(cells)
        if studs:
            scol, ev = studs
            add = set()
            for (i, j, k) in cells:
                if (i, j, k + 1) not in cells and i % ev in (0, 1) and j % ev in (0, 1) and all((i - (i % ev) + a3, j - (j % ev) + b3, k) in cells and (i - (i % ev) + a3, j - (j % ev) + b3, k + 1) not in cells for a3 in (0, 1) for b3 in (0, 1)):
                    add.add((i, j, k + 1))
            if add:
                groups.setdefault(scol, set()).update(add); allc |= add
        for col, cs in groups.items():
            self.voxels(part, cs, cell, (0, 0, 0), colour=col, occ=allc)
        return cells

    def armor(self, part, c, r, seg=8, rings=6, rot=None, colour="Plate", zmin=-1.0, zmax=1.0, inset=0.05, lift=0.035, rivets=None, role="Tex"):
        """a faceted armour shell (the concepts' hard-surface plates): a low-poly ellipsoid, optionally cut to a band of its
        height (local -1..1), every facet raised as its own plate with a groove round it; rivets = colour for studs on the plates"""
        b = bmesh.new()
        bmesh.ops.create_uvsphere(b, u_segments=seg, v_segments=rings, radius=1.0)
        cut = [v for v in b.verts if v.co.z < zmin - 1e-4 or v.co.z > zmax + 1e-4]
        if cut: bmesh.ops.delete(b, geom=cut, context="VERTS")
        bmesh.ops.scale(b, vec=V(r), verts=b.verts)
        faces = [f for f in b.faces if f.calc_area() > 1e-5]
        cents = [(f.calc_center_median().copy(), f.normal.copy(), f.calc_area()) for f in faces]
        if inset > 0 and faces:
            bmesh.ops.inset_individual(b, faces=faces, thickness=inset, depth=lift, use_even_offset=True)
        if rot is not None: bmesh.ops.rotate(b, verts=b.verts, cent=V(0, 0, 0), matrix=rot if isinstance(rot, Matrix) else Euler(rot).to_matrix())
        bmesh.ops.translate(b, vec=V(c), verts=b.verts)
        bmesh.ops.recalc_face_normals(b, faces=b.faces)
        self.add(part, role, b, colour)
        if rivets:
            R = (rot if isinstance(rot, Matrix) else Euler(rot).to_matrix()) if rot is not None else Matrix.Identity(3)
            for cc, n, area in cents:
                if area < 0.35 or n.z < -0.2: continue
                p = V(c) + R @ (cc + n * (lift + 0.02))
                self.block(part, p, (0.17, 0.17, 0.12), rot=look(R @ n), bevel=0.35, colour=rivets)

    def limb(self, part, a, b, r0, r1, seg=6, colour="Main", bands=2, band_colour="Iron", plate=None, up=V(0, 0, 1), facets=True):
        """a faceted limb segment: a tapered prism with raised armour bands"""
        a, b = V(a), V(b)
        d = b - a; L = d.length
        R = look(d, up)
        bm = bmesh.new()
        bmesh.ops.create_cone(bm, cap_ends=True, segments=seg, radius1=r0, radius2=r1, depth=L)
        bmesh.ops.rotate(bm, verts=bm.verts, cent=V(0, 0, 0), matrix=Matrix.Rotation(-math.pi / 2, 3, "X"))  # cone axis z -> y
        side = [f for f in bm.faces if abs(f.normal.y) < 0.7]
        if facets: bmesh.ops.inset_individual(bm, faces=side, thickness=min(r0, r1) * 0.12, depth=min(r0, r1) * 0.06, use_even_offset=True)
        bmesh.ops.rotate(bm, verts=bm.verts, cent=V(0, 0, 0), matrix=R)
        bmesh.ops.translate(bm, vec=(a + b) / 2, verts=bm.verts)
        self.add(part, "Tex", bm, colour)
        for k in range(bands):
            u = (k + 0.5) / bands
            rr = r0 + (r1 - r0) * u
            bb = bmesh.new()
            bmesh.ops.create_cone(bb, cap_ends=True, segments=seg, radius1=rr * 1.12, radius2=rr * 1.12, depth=L * 0.12)
            bmesh.ops.rotate(bb, verts=bb.verts, cent=V(0, 0, 0), matrix=Matrix.Rotation(-math.pi / 2, 3, "X"))
            bmesh.ops.rotate(bb, verts=bb.verts, cent=V(0, 0, 0), matrix=R)
            bmesh.ops.translate(bb, vec=a + d * u, verts=bb.verts)
            self.add(part, "Tex", bb, band_colour)

    def gem(self, part, c, r, stretch=(1, 1, 1.4), colour="Glow", role="Glow", rot=None):
        """a cut crystal (an octahedron with a girdle), glowing by default"""
        b = bmesh.new()
        n = 8
        top = b.verts.new(V(0, 0, 1)); bot = b.verts.new(V(0, 0, -1))
        gird = [b.verts.new(V(math.cos(i / n * math.tau) * 0.75, math.sin(i / n * math.tau) * 0.75, 0.15)) for i in range(n)]
        for i in range(n):
            b.faces.new([gird[i], gird[(i + 1) % n], top]); b.faces.new([gird[(i + 1) % n], gird[i], bot])
        bmesh.ops.recalc_face_normals(b, faces=b.faces)
        bmesh.ops.scale(b, vec=V(stretch) * r, verts=b.verts)
        if rot is not None: bmesh.ops.rotate(b, verts=b.verts, cent=V(0, 0, 0), matrix=rot if isinstance(rot, Matrix) else Euler(rot).to_matrix())
        bmesh.ops.translate(b, vec=V(c), verts=b.verts)
        self.add(part, role, b, colour)

    # ---------------- magical fantasy details (the owner, 2026-11-24: "magical and fantasy instead of the metallic version")
    def tube(self, part, pts, radii, colour="Gold", seg=6, role="Tex"):
        """a swept tube through points (filigree curls, vines, roots, ribbons, whiskers); radii per point"""
        pts = [V(q) for q in pts]
        b = bmesh.new()
        rings = []
        n = len(pts)
        for i, q in enumerate(pts):
            t = (pts[min(i + 1, n - 1)] - pts[max(i - 1, 0)]).normalized()
            up = V(0, 0, 1) if abs(t.z) < 0.95 else V(0, 1, 0)
            side = t.cross(up).normalized(); up = side.cross(t).normalized()
            r = radii[i] if isinstance(radii, (list, tuple)) else radii
            rings.append([b.verts.new(q + (side * math.cos(a) + up * math.sin(a)) * r) for a in [k / seg * math.tau for k in range(seg)]])
        for r0, r1 in zip(rings, rings[1:]):
            for k in range(seg):
                b.faces.new([r0[k], r0[(k + 1) % seg], r1[(k + 1) % seg], r1[k]])
        b.faces.new(list(reversed(rings[0]))); b.faces.new(rings[-1])
        bmesh.ops.recalc_face_normals(b, faces=b.faces)
        self.add(part, role, b, colour)

    def crystal(self, part, base, direction, length, width, colour="Crystal", role="Crystal", sides=6):
        """one faceted crystal: a hexagonal prism with a pointed tip, standing on 'base' along 'direction'"""
        d = V(direction).normalized()
        R = look(d, V(0, 0, 1) if abs(d.z) < 0.9 else V(1, 0, 0))
        b = bmesh.new()
        ring0 = [b.verts.new(V(math.cos(a) * width, 0, math.sin(a) * width)) for a in [k / sides * math.tau for k in range(sides)]]
        ring1 = [b.verts.new(V(math.cos(a) * width * 0.92, length * 0.72, math.sin(a) * width * 0.92)) for a in [k / sides * math.tau for k in range(sides)]]
        tip = b.verts.new(V(0, length, 0))
        for k in range(sides):
            b.faces.new([ring0[k], ring0[(k + 1) % sides], ring1[(k + 1) % sides], ring1[k]])
            b.faces.new([ring1[k], ring1[(k + 1) % sides], tip])
        b.faces.new(list(reversed(ring0)))
        bmesh.ops.recalc_face_normals(b, faces=b.faces)
        bmesh.ops.rotate(b, verts=b.verts, cent=V(0, 0, 0), matrix=R)
        bmesh.ops.translate(b, vec=V(base), verts=b.verts)
        self.add(part, role, b, colour)

    def cluster(self, part, base, direction, size, n=5, colour="Crystal", role="Crystal", spread=0.55, seed=1):
        """a crystal cluster: a tall centre crystal and smaller ones leaning out round it"""
        import random as _r
        rnd = _r.Random(seed)
        d = V(direction).normalized()
        side = d.orthogonal().normalized(); other = d.cross(side).normalized()
        self.crystal(part, base, d, size, size * 0.2, colour, role)
        for i in range(n - 1):
            a = i / (n - 1) * math.tau + rnd.random() * 0.6
            lean = (d + (side * math.cos(a) + other * math.sin(a)) * spread).normalized()
            self.crystal(part, V(base) + (side * math.cos(a) + other * math.sin(a)) * size * 0.16, lean, size * (0.45 + 0.35 * rnd.random()), size * 0.13, colour, role)

    def rune(self, part, c, normal, size, glyph=0, colour="Glow", depth=0.03):
        """a glowing sigil inlaid on a surface facing 'normal': strokes of thin glowing bars in one of a few glyph shapes"""
        n = V(normal).normalized()
        R = look(n, V(0, 0, 1) if abs(n.z) < 0.9 else V(0, 1, 0))
        sx, sz = R.col[0], R.col[2]
        c0 = V(c) + n * depth
        g = glyph % 5
        strokes = {0: [((-0.5, -0.5), (0.5, 0.5)), ((-0.5, 0.5), (0.5, -0.5)), ((0, -0.6), (0, 0.6))],
                   1: [((-0.5, -0.4), (0, 0.6)), ((0, 0.6), (0.5, -0.4)), ((-0.35, 0), (0.35, 0))],
                   2: [((0, -0.6), (0, 0.6)), ((0, 0.2), (0.45, 0.55)), ((0, -0.1), (-0.45, 0.25))],
                   3: [((-0.5, 0.5), (0.5, 0.5)), ((0.5, 0.5), (-0.5, -0.5)), ((-0.5, -0.5), (0.5, -0.5))],
                   4: [((-0.45, -0.6), (-0.45, 0.6)), ((0.45, -0.6), (0.45, 0.6)), ((-0.45, 0), (0.45, 0))]}[g]
        for (a1, b1), (a2, b2) in strokes:
            pa = c0 + (sx * a1 + sz * b1) * size; pb = c0 + (sx * a2 + sz * b2) * size
            L = (pb - pa).length
            self.block(part, (pa + pb) / 2, (size * 0.12, L + size * 0.1, size * 0.06), rot=look(pb - pa, n), bevel=0.0, colour=colour, role="Glow")

    def moss(self, part, c, r, n=6, colour="Moss", seed=2):
        """a clump of mossy tufts (faceted little domes) sitting on a top surface"""
        import random as _r
        rnd = _r.Random(seed)
        for i in range(n):
            a = rnd.random() * math.tau; d = rnd.random() * r
            q = V(c) + V(math.cos(a) * d, math.sin(a) * d, 0)
            rr = r * (0.25 + 0.25 * rnd.random())
            b = bmesh.new()
            bmesh.ops.create_icosphere(b, subdivisions=1, radius=1.0)
            bmesh.ops.scale(b, vec=V(rr, rr, rr * 0.6), verts=b.verts)
            bmesh.ops.translate(b, vec=q, verts=b.verts)
            self.add(part, "Tex", b, colour)

    def feather(self, part, base, tip, width, colour="Feather", thick=0.05, bend=V(0, 0, 0), role="Tex"):
        """a flat tapered blade (feather, leaf, fin, mane lock) from base to tip, lying across the up axis"""
        base, tip = V(base), V(tip)
        mid = (base + tip) / 2 + V(bend)
        pts = [base, base.lerp(mid, 0.6), mid, mid.lerp(tip, 0.5), tip]
        wid = [width * 0.5, width * 0.9, width, width * 0.7, width * 0.08]
        b = bmesh.new()
        rows = []
        for i, q in enumerate(pts):
            t = (pts[min(i + 1, 4)] - pts[max(i - 1, 0)]).normalized()
            side = t.cross(V(0, 0, 1)) if abs(t.z) < 0.95 else t.cross(V(0, 1, 0))
            side.normalize(); up = side.cross(t).normalized()
            w = wid[i]
            rows.append([b.verts.new(q + side * w + up * thick), b.verts.new(q - side * w + up * thick), b.verts.new(q - side * w - up * thick), b.verts.new(q + side * w - up * thick)])
        for r0, r1 in zip(rows, rows[1:]):
            for k in range(4):
                b.faces.new([r0[k], r0[(k + 1) % 4], r1[(k + 1) % 4], r1[k]])
        b.faces.new(list(reversed(rows[0]))); b.faces.new(rows[-1])
        bmesh.ops.recalc_face_normals(b, faces=b.faces)
        self.add(part, role, b, colour)

    def orb(self, part, c, r, colour="Glow", role="Glow"):
        """a floating glowing orb (wisps, spirit lights, eyes)"""
        b = bmesh.new()
        bmesh.ops.create_icosphere(b, subdivisions=2, radius=r)
        bmesh.ops.translate(b, vec=V(c), verts=b.verts)
        self.add(part, role, b, colour)

    def tiles(self, part, c, r, rows=6, cols=8, colour="Main", alt=None, size=1.0, zmin=-0.2, tilt=16, thick=0.12, span=(-0.9, 0.9), taper=0.8, seed=0):
        """overlapping scale plates over an ellipsoid (pangolin tiles, dragon scales, jade armour): rows front to back along y,
        cols over the top from right to left; each plate faces out and lifts its back edge so the rows overlap like shingles.
        alt = (colour, every) paints every n-th row in a second colour (banding)"""
        c, r = V(c), V(r)
        for i in range(rows):
            v = span[1] - (span[1] - span[0]) * (i + 0.5) / rows
            rr = math.sqrt(max(0.0, 1 - v * v))
            for j in range(cols):
                a = math.pi * (j + 0.5 + 0.5 * (i % 2)) / cols
                if a > math.pi: continue
                nx, nz = math.cos(a) * rr, math.sin(a) * rr
                if nz < zmin: continue
                q = c + V(nx * r.x, v * r.y, nz * r.z)
                n = V(nx / r.x, v / r.y, nz / r.z).normalized()
                back = V(0, -1, 0) - n * n.dot(V(0, -1, 0))
                back = back.normalized() if back.length > 1e-4 else V(0, 0, -1)
                t = math.radians(tilt)
                d = (back * math.cos(t) + n * math.sin(t)).normalized()
                w = math.pi * max(rr, 0.25) * (r.x + r.z) / 2 / cols * 1.3 * size
                L = 2 * r.y * (span[1] - span[0]) / 2 / rows * 1.45 * size
                col = alt[0] if (alt and i % alt[1] == alt[1] - 1) else colour
                self.block(part, q + n * thick * 0.35 + back * L * 0.18, (w, L, thick), rot=look(d, n), bevel=0.18, colour=col, taper=taper)

    def tufts(self, part, c, r, n=20, length=0.6, width=0.18, colour="Fur", seed=3, where=None, back=0.6, droop=0.15, spread=0.25, solid=False):
        """fur, manes, leaf crowns and feather coats: n flat blades rooted on an ellipsoid surface, sweeping back and drooping;
        where(normal) -> bool picks the region (lambda n: n.z > 0.3 for a crest)"""
        import random as _r
        rnd = _r.Random(seed)
        c, r = V(c), V(r)
        made = tries = 0
        while made < n and tries < n * 60:
            tries += 1
            u = rnd.uniform(-1, 1); th = rnd.uniform(0, math.tau); sq = math.sqrt(1 - u * u)
            dv = V(sq * math.cos(th), sq * math.sin(th), u)
            nrm = V(dv.x / r.x, dv.y / r.y, dv.z / r.z).normalized()
            if where is not None and not where(nrm): continue
            q = c + V(dv.x * r.x, dv.y * r.y, dv.z * r.z)
            out = (nrm + V(rnd.uniform(-spread, spread), -back, -droop)).normalized()
            L = length * rnd.uniform(0.75, 1.2)
            if solid:  # a fur clump: a tapered bevelled spike lying back along the body
                self.segment(part, q - nrm * width * 0.5, q + out * L, width * rnd.uniform(0.85, 1.15), width * 0.12, colour=colour, bevel=0.25, up=nrm, depth=0.7)
            else:
                self.feather(part, q - nrm * width * 0.4, q + out * L, width * rnd.uniform(0.8, 1.2), colour=colour, thick=width * 0.16, bend=nrm * L * 0.18)
            made += 1

    def ring(self, part, c, R, w, h, n, normal=(0, 1, 0), colour="Gold", gems=None, gem_every=0, teeth=0, tooth_len=0.4, tooth_colour="Gold", gap=1.04):
        """a segmented ring (astrolabe band, halo, collar): n bevelled blocks round a circle of radius R in the plane facing
        'normal'; w = radial width, h = depth along the normal; a cabochon gem on every gem_every-th block; teeth = a spike on every
        teeth-th block pointing outward"""
        c = V(c); nrm = V(normal).normalized(); u = nrm.orthogonal().normalized(); v = nrm.cross(u).normalized()
        L = 2 * math.pi * R / n * gap
        for k in range(n):
            a = math.tau * k / n
            rad = u * math.cos(a) + v * math.sin(a); tang = nrm.cross(rad)
            M = Matrix((rad, tang, nrm)).transposed()
            q = c + rad * R
            self.block(part, q, (w, L, h), rot=M, bevel=0.14, colour=colour)
            if gems and gem_every and k % gem_every == 0:
                self.gem(part, q + nrm * h * 0.5, min(w, h) * 0.42, stretch=(1, 1, 0.7), colour=gems, rot=M)
            if teeth and k % teeth == 0:
                self.claw(part, q + rad * w * 0.4, q + rad * (w * 0.4 + tooth_len), min(w, h) * 0.5, colour=tooth_colour)

    def lotus(self, part, c, normal, r, n=8, colour="Petal", colour2=None, layers=2, centre="Glow"):
        """a lotus / blossom: layers of petal blades round 'normal', the inner layer taller, a glowing heart"""
        c = V(c); nrm = V(normal).normalized(); u = nrm.orthogonal().normalized(); v = nrm.cross(u).normalized()
        for L in range(layers):
            for k in range(n):
                a = math.tau * (k + 0.5 * L) / n
                rad = u * math.cos(a) + v * math.sin(a)
                base = c + rad * r * 0.15
                tip = c + rad * r * (1.0 - 0.3 * L) + nrm * r * (0.45 + 0.35 * L)
                self.feather(part, base, tip, r * 0.3 * (1 - 0.15 * L), colour=(colour2 or colour) if L else colour, thick=r * 0.04, bend=nrm * r * 0.12 - rad * r * 0.05)
        self.orb(part, c + nrm * r * 0.18, r * 0.2, colour=centre)

    def spiral(self, part, c, axis, r0, r1, turns=1.5, w0=0.08, w1=0.5, colour="Pearl", seg=10, n=44, start=0.0, drift=0.0, role="Tex"):
        """a logarithmic spiral swept round 'axis' (nautilus shells, ram horns, curled tails); radius r0 -> r1, tube width
        w0 -> w1 from the inner end outward; drift moves the outer end along the axis (horns that grow outward)"""
        c = V(c); ax = V(axis).normalized(); u = ax.orthogonal().normalized(); v = ax.cross(u).normalized()
        pts, rad = [], []
        for i in range(n + 1):
            t = i / n
            a = start + t * turns * math.tau
            R = r0 * (r1 / r0) ** t
            pts.append(c + (u * math.cos(a) + v * math.sin(a)) * R + ax * drift * t)
            rad.append(w0 + (w1 - w0) * t)
        self.tube(part, pts, rad, colour=colour, seg=seg, role=role)

    def slit(self, part, c, size, normal, colour="Glow"):
        """an inset glowing window: a thin glowing panel sunk just under a face (normal = the face's outward direction)"""
        n = V(normal).normalized()
        self.block(part, V(c) - n * size[2] * 0.3, size, rot=look(n.cross(V(0, 0, 1)) if abs(n.z) < 0.9 else V(1, 0, 0)), bevel=0.0, colour=colour, role="Glow")

    def voxels(self, part, cells, s, origin, colour="Bone", role="Tex", occ=None):
        """fine voxel detail (crests, crescents, spikes): cells = set of (i, j, k), cube size s, at origin (bevelled cubes,
        hidden faces culled by merging)"""
        o = V(origin)
        b = bmesh.new()
        cache = {}
        F = (((1, 0, 0), [(1, 0, 0), (1, 1, 0), (1, 1, 1), (1, 0, 1)]), ((-1, 0, 0), [(0, 0, 0), (0, 0, 1), (0, 1, 1), (0, 1, 0)]),
             ((0, 1, 0), [(0, 1, 0), (0, 1, 1), (1, 1, 1), (1, 1, 0)]), ((0, -1, 0), [(0, 0, 0), (1, 0, 0), (1, 0, 1), (0, 0, 1)]),
             ((0, 0, 1), [(0, 0, 1), (1, 0, 1), (1, 1, 1), (0, 1, 1)]), ((0, 0, -1), [(0, 0, 0), (0, 1, 0), (1, 1, 0), (1, 0, 0)]))
        for (i, j, k) in cells:
            for nrm, q in F:
                if (i + nrm[0], j + nrm[1], k + nrm[2]) in (occ if occ is not None else cells): continue
                vs = []
                for (a, bb, c) in q:
                    key = (i + a, j + bb, k + c)
                    if key not in cache: cache[key] = b.verts.new(o + V(key) * s)
                    vs.append(cache[key])
                try: b.faces.new(vs)
                except ValueError: pass
        bmesh.ops.recalc_face_normals(b, faces=b.faces)
        self.add(part, role, b, colour)


# -------- export: one atlas per creature
def _material(colour, img, pal, seam):
    m = bpy.data.materials.new("m_" + colour); m.use_nodes = True
    nt = m.node_tree
    for n in list(nt.nodes): nt.nodes.remove(n)
    N, L = nt.nodes.new, nt.links.new
    out = N("ShaderNodeOutputMaterial"); em = N("ShaderNodeEmission")
    base = hexlin(pal.get(colour, "#808080"))
    top = hexlin(pal.get(colour + "Top", pal.get(colour, "#808080")))
    geo = N("ShaderNodeNewGeometry")
    sz = N("ShaderNodeSeparateXYZ"); L(geo.outputs["Normal"], sz.inputs[0])
    tm = N("ShaderNodeMapRange"); tm.inputs["From Min"].default_value, tm.inputs["From Max"].default_value = 0.2, 0.9
    L(sz.outputs["Z"], tm.inputs["Value"])
    c0 = N("ShaderNodeRGB"); c0.outputs[0].default_value = base
    c1 = N("ShaderNodeRGB"); c1.outputs[0].default_value = top
    mx = N("ShaderNodeMix"); mx.data_type = "RGBA"; L(tm.outputs[0], mx.inputs["Factor"]); L(c0.outputs[0], mx.inputs[6]); L(c1.outputs[0], mx.inputs[7])
    # panel seams: thin dark lines on a block grid in object space (the stacked-brick surface of the reference)
    br = N("ShaderNodeTexBrick"); br.inputs["Scale"].default_value = seam; br.inputs["Mortar Size"].default_value = 0.0 if (pal.get("_noseams") or colour in pal.get("_plain", ())) else 0.035
    br.inputs["Color1"].default_value = (1, 1, 1, 1); br.inputs["Color2"].default_value = (0.93, 0.93, 0.95, 1); br.inputs["Mortar"].default_value = (0.42, 0.4, 0.5, 1)
    br.offset = 0.5; br.squash = 1.0
    L(geo.outputs["Position"], br.inputs["Vector"])
    ms = N("ShaderNodeMix"); ms.data_type = "RGBA"; ms.blend_type = "MULTIPLY"; ms.inputs["Factor"].default_value = 1.0
    L(mx.outputs[2], ms.inputs[6]); L(br.outputs["Color"], ms.inputs[7])
    ao = N("ShaderNodeAmbientOcclusion"); ao.inputs["Distance"].default_value = 0.6; ao.samples = 24
    am = N("ShaderNodeMapRange"); am.inputs["To Min"].default_value, am.inputs["To Max"].default_value = 0.35, 1.0
    L(ao.outputs["AO"], am.inputs["Value"])
    sh = N("ShaderNodeMix"); sh.data_type = "RGBA"; L(am.outputs[0], sh.inputs["Factor"])
    sh.inputs[6].default_value = (0.03, 0.02, 0.06, 1); L(ms.outputs[2], sh.inputs[7])
    kl = N("ShaderNodeVectorMath"); kl.operation = "DOT_PRODUCT"; kl.inputs[1].default_value = V(-0.35, 0.4, 0.85).normalized()
    L(geo.outputs["Normal"], kl.inputs[0])
    km = N("ShaderNodeMapRange"); km.inputs["From Min"].default_value, km.inputs["From Max"].default_value = -1, 1
    km.inputs["To Min"].default_value, km.inputs["To Max"].default_value = 0.62, 1.08
    L(kl.outputs["Value"], km.inputs["Value"])
    lit = N("ShaderNodeMix"); lit.data_type = "RGBA"; lit.blend_type = "MULTIPLY"; lit.inputs["Factor"].default_value = 1.0
    L(sh.outputs[2], lit.inputs[6])
    kc = N("ShaderNodeCombineColor"); L(km.outputs[0], kc.inputs[0]); L(km.outputs[0], kc.inputs[1]); L(km.outputs[0], kc.inputs[2])
    L(kc.outputs[0], lit.inputs[7])
    bv = N("ShaderNodeBevel"); bv.inputs["Radius"].default_value = 0.02; bv.samples = 8
    dt = N("ShaderNodeVectorMath"); dt.operation = "DOT_PRODUCT"; L(bv.outputs[0], dt.inputs[0]); L(geo.outputs["Normal"], dt.inputs[1])
    ed = N("ShaderNodeMapRange"); ed.inputs["From Min"].default_value, ed.inputs["From Max"].default_value = 0.99, 0.85
    ed.inputs["To Max"].default_value = 0.3 if img is not None else 0.0  # a vertex bake samples on the corners, which are all edges: no edge light there
    L(dt.outputs["Value"], ed.inputs["Value"])
    hi = N("ShaderNodeMix"); hi.data_type = "RGBA"; hi.blend_type = "SCREEN"; L(ed.outputs[0], hi.inputs["Factor"])
    L(lit.outputs[2], hi.inputs[6]); hi.inputs[7].default_value = hexlin(pal.get("Edge", "#9aa0b8"))
    L(hi.outputs[2], em.inputs["Color"]); L(em.outputs[0], out.inputs[0])
    if img is not None:
        tex = N("ShaderNodeTexImage"); tex.image = img; nt.nodes.active = tex
    return m


def export(c, out_dir, split=19000, bake=True, samples=32):
    """objects Part__Tex (vertex-coloured: colour x occlusion x key light + edge light baked by Cycles into a face-corner colour
    attribute) and Part__Glow; origins at the joints; no triangle cap while designing: any object over 'split' triangles is cut
    into pieces Part__Tex, Part__Tex2, ... (Roblox MeshParts must stay under 20,000). Writes <Name>.glb; returns the rig data
    (parents, pivots in game axes x / y up / z forward, feet at 0)."""
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    allv = [v.co for lst in c.colours.values() for b, _ in lst for v in b.verts]
    mn = V(min(p.x for p in allv), min(p.y for p in allv), min(p.z for p in allv))
    mx = V(max(p.x for p in allv), max(p.y for p in allv), max(p.z for p in allv))
    shift = V(-(mn.x + mx.x) / 2, -(mn.y + mx.y) / 2, -mn.z)
    mats, objs, tris = {}, [], 0
    for (part, role), lst in c.colours.items():
        me = bpy.data.meshes.new(f"{part}__{role}")
        b = bmesh.new()
        keys = []
        for piece, colour in lst:
            if colour not in keys: keys.append(colour)
            tmpme = bpy.data.meshes.new("t"); piece.to_mesh(tmpme); piece.free()
            n0 = len(b.faces)
            b.from_mesh(tmpme); bpy.data.meshes.remove(tmpme)
            b.faces.ensure_lookup_table()
            for f in b.faces[n0:]: f.material_index = keys.index(colour)
        bmesh.ops.translate(b, vec=shift, verts=b.verts)
        bmesh.ops.remove_doubles(b, verts=b.verts, dist=1e-5)
        bmesh.ops.triangulate(b, faces=b.faces)
        b.to_mesh(me); b.free()
        tris += len(me.polygons)
        o = bpy.data.objects.new(f"{part}__{role}", me); sc.collection.objects.link(o)
        for k in keys:
            if role == "Tex":
                if k not in mats: mats[k] = _material(k, None, c.pal, 3.2)
                me.materials.append(mats[k])
            else:
                m = bpy.data.materials.new(role); m.use_nodes = True
                m.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = hexlin(c.pal.get(k, c.pal.get(role, "#ffffff")))
                me.materials.append(m)
        sm = set(c.pal.get("_smooth", ()))
        for pg in me.polygons: pg.use_smooth = keys[pg.material_index] in sm if pg.material_index < len(keys) else False
        if role == "Tex":
            ca = me.color_attributes.new(name="Col", type="FLOAT_COLOR", domain="CORNER")  # linear, as glTF COLOR_0 is
            me.color_attributes.active_color = ca
        objs.append(o)
    texo = [o for o in objs if o.name.endswith("__Tex")]
    if bake and texo:
        sc.render.engine = "CYCLES"; sc.cycles.samples = samples
        try:
            pr = bpy.context.preferences.addons["cycles"].preferences
            pr.compute_device_type = "OPTIX"; pr.get_devices()
            for d in pr.devices: d.use = True
            sc.cycles.device = "GPU"
        except Exception:
            sc.cycles.device = "CPU"
        sc.render.bake.target = "VERTEX_COLORS"
        for o in objs:
            if not o.name.endswith("__Tex"): o.hide_render = True
        bpy.ops.object.select_all(action="DESELECT")
        for o in texo: o.select_set(True)
        bpy.context.view_layer.objects.active = texo[0]
        bpy.ops.object.bake(type="EMIT")
        for o in objs: o.hide_render = False
    vm = bpy.data.materials.new("vc"); vm.use_nodes = True
    vn = vm.node_tree.nodes.new("ShaderNodeVertexColor"); vn.layer_name = "Col"
    vm.node_tree.links.new(vn.outputs["Color"], vm.node_tree.nodes["Principled BSDF"].inputs["Base Color"])
    vm.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.75
    for o in texo:
        o.data.materials.clear(); o.data.materials.append(vm)
    # split big objects into spatial chunks under the MeshPart limit (a face attribute marks each face's chunk first)
    for o in list(objs):
        n = len(o.data.polygons)
        if n <= split: continue
        k = n // split + 1
        dims = o.dimensions; ax = max(range(3), key=lambda i: dims[i])
        order = sorted(range(n), key=lambda i: o.data.polygons[i].center[ax])
        rank = [0] * n
        for r, i in enumerate(order): rank[i] = r * k // n
        att = o.data.attributes.new("chunk", "INT", "FACE")
        for i in range(n): att.data[i].value = rank[i]
        bpy.ops.object.select_all(action="DESELECT"); o.select_set(True); bpy.context.view_layer.objects.active = o
        for chunk in range(1, k):
            bpy.ops.object.mode_set(mode="OBJECT")
            ch = o.data.attributes["chunk"]
            for pg in o.data.polygons: pg.select = ch.data[pg.index].value == chunk
            for e in o.data.edges: e.select = False
            for v in o.data.vertices: v.select = False
            bpy.ops.object.mode_set(mode="EDIT"); bpy.ops.mesh.select_mode(type="FACE")
            bpy.ops.object.mode_set(mode="OBJECT")
            for pg in o.data.polygons: pg.select = o.data.attributes["chunk"].data[pg.index].value == chunk
            bpy.ops.object.mode_set(mode="EDIT"); bpy.ops.mesh.separate(type="SELECTED"); bpy.ops.object.mode_set(mode="OBJECT")
            new = [x for x in bpy.context.selected_objects if x != o]
            if new:
                new[0].name = o.name + str(chunk + 1); objs.append(new[0]); new[0].select_set(False)
            bpy.context.view_layer.objects.active = o; o.select_set(True)
    for o in objs:
        part = o.name.split("__")[0]
        p = c.pivots.get(part)
        if p is not None:
            pv = p + shift
            o.data.transform(Matrix.Translation(-pv)); o.location = pv
    path = os.path.join(out_dir, c.name.replace(" ", "") + ".glb")
    try:
        bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", export_yup=True, export_apply=True, export_vertex_color="ACTIVE")
    except TypeError:
        bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", export_yup=True, export_apply=True)
    g = lambda v: [round(v.x, 3), round(v.z, 3), round(v.y, 3)]
    big = max(len(o.data.polygons) for o in objs)
    return {"name": c.name, "tris": tris, "maxPart": big, "objects": len(objs), "parts": len({o.name.split("__")[0] for o in objs}),
            "height": round(mx.z - mn.z, 3), "size": [round(mx.x - mn.x, 2), round(mx.y - mn.y, 2), round(mx.z - mn.z, 2)],
            "parent": c.parent, "groups": c.groups, "axes": {k2: g(V(v)) for k2, v in c.axes.items()}, "pivots": {k2: g(v + shift) for k2, v in c.pivots.items()},
            "anchors": {k2: [pp, g(v + shift)] for k2, (pp, v) in c.anchors.items()}, "palette": c.pal}
