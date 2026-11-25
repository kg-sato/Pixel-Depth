"""Vertex-colour voxel meshing for the v5 pets (2026-11-24), the way the vault says voxel art is shaded
(Library/LihFolk/53 Voxel Modelling Deep Dive: "Voxel Shading - Baked AO Edges and Lighting" and "Voxel Palettes - Ramps Hue
Shifting and Limits"; the Roblox 3D importer keeps glTF vertex colours and multiplies them with MeshPart.Color, so the game sets
Color white on these parts):
  * one quad per visible cell face, per-corner ambient occlusion from the three cells in front of each corner (both sides filled
    = fully dark), split along the diagonal that joins the darker pair (no diamond artefacts)
  * every role colour becomes a 3-step hue-shifted ramp: the shadow step turns toward violet, the light step toward warm yellow
    (never toward black or white); top faces take a half step up, undersides the shadow step, and the lit outer edge cells of a
    top surface the full light step
  * no noise. Occlusion and gradients come only from the shape.
mesh_part(cells, fcells, occ, palette, ...) returns (verts, faces, corner colours) for one moving part."""
import colorsys

AO = (0.58, 0.72, 0.86, 1.0)
DIRS = ((1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1))


def hexrgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))


def shift(rgb, dl, dh_to, k):
    """move lightness by dl and rotate the hue a fraction k of the way toward hue dh_to (0..1)"""
    h, l, s = colorsys.rgb_to_hls(*rgb)
    d = ((dh_to - h + 0.5) % 1.0) - 0.5
    h = (h + d * k) % 1.0
    l = min(max(l + dl, 0.0), 1.0)
    s = min(s * (1.08 if dl < 0 else 0.95), 1.0)
    return colorsys.hls_to_rgb(h, l, s)


def ramp(hexc):
    base = hexrgb(hexc)
    _, l, s = colorsys.rgb_to_hls(*base)
    k = 0.18 if s > 0.12 else 0.06  # greys and whites barely shift
    shadow = shift(base, -0.13, 0.74, k)   # toward violet
    light = shift(base, 0.08 if l < 0.85 else 0.03, 0.14, k * 0.8)  # toward warm yellow
    return shadow, base, light


def lerp(a, b, t):
    return tuple(x + (y - x) * t for x, y in zip(a, b))


def to_lin(c):
    return tuple(x ** 2.2 for x in c)


def mesh_part(cells, occ, palette, size, origin, ymax):
    """cells: {(x, y, z): role} of this part (coarse voxels) plus fine cells as {(fx, fy, fz, 'f'): role} (half size);
    occ(x, y, z) -> bool for the whole pet in coarse cells (fine cells count as their coarse cell for occlusion).
    Returns verts (in voxel units, x, y up, z), faces (index triples, x/y/z winding) and per-face corner colours (sRGB)."""
    ramps = {r: ramp(palette[r]) for r in set(cells.values()) if r in palette}
    verts, faces, cols = [], [], []
    vid = {}

    def V(p):
        if p not in vid:
            vid[p] = len(verts); verts.append(p)
        return vid[p]

    for key, role in cells.items():
        fine = len(key) == 4
        x, y, z = key[:3]
        k = 0.5 if fine else 1.0
        sh, base, li = ramps[role]
        for d in range(3):
            u, v = (d + 1) % 3, (d + 2) % 3
            for side in (1, -1):
                n = [x, y, z]; n[d] += side
                if fine:
                    if (n[0], n[1], n[2], "f") in cells or occ(n[0] // 2, n[1] // 2, n[2] // 2, own=True): continue
                elif occ(*n, own=True):
                    continue
                plane = [x, y, z]
                if side > 0: plane[d] += 1
                # colour of the face: undersides take the shadow step, tops a half step up, lit outer edges the full light step
                if d == 1 and side < 0: c = lerp(base, sh, 0.7)
                elif d == 1 and side > 0:
                    edge = not fine and any(not occ(x + dx, y, z + dz) for dx, dz in ((1, 0), (-1, 0), (0, 1), (0, -1)))
                    c = li if edge else lerp(base, li, 0.45)
                else: c = base
                hy = (y * k) / max(ymax, 1)
                c = lerp(lerp(c, sh, 0.18), c, min(1.0, 0.55 + hy))  # a gentle gradient: deeper toward the feet
                corners, ao = [], []
                for du, dv in ((0, 0), (1, 0), (1, 1), (0, 1)):
                    cc = list(plane); cc[u] += du; cc[v] += dv
                    corners.append(tuple(q * k for q in cc))
                    if fine:
                        ao.append(3); continue
                    su, sv = (1 if du else -1), (1 if dv else -1)
                    s1 = list(n); s1[u] += su
                    s2 = list(n); s2[v] += sv
                    s3 = list(n); s3[u] += su; s3[v] += sv
                    a, b2, c3 = occ(*s1), occ(*s2), occ(*s3)
                    ao.append(0 if (a and b2) else 3 - (a + b2 + c3))
                if side < 0:
                    corners.reverse(); ao.reverse()
                ids = [V(p) for p in corners]
                if ao[0] + ao[2] > ao[1] + ao[3]: tris = ((1, 2, 3), (1, 3, 0))
                else: tris = ((0, 1, 2), (0, 2, 3))
                for t in tris:
                    faces.append(tuple(ids[i] for i in t))
                    cols.append([lerp(lerp(sh, (0.16, 0.1, 0.24), 0.35), c, AO[ao[i]]) if ao[i] < 3 else c for i in t])
    return verts, faces, cols
