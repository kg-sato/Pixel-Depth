"""Pixel Depth gel skins v2 (2026-11-18, the owner: "the overall round highlights / shine effects for the boxes ... don't look the
most engaging"; Gemini's audit: the white dome is a "2010 Web 2.0 ellipse", a sticker, with no edge refraction and no grounding).
Same sizes and 9-slice centres as art/ui_jelly (pd_ui_jelly.py), so the game only swaps image ids (Config.UI_GLASS.jelly).
Each piece is lit like a real slab of jelly instead of painted: a signed-distance rounded shape gets a rounded bevel as a height
field, its normals take a key light from the upper left, and the result is
  * an amethyst-to-obsidian body (Gemini palette: #4C2D82 top, #130D22 bottom), slightly see-through
  * a Fresnel rim: the bevel glows in the piece's rim colour, bright on top, dim at the bottom
  * a thin specular crescent where the top bevel faces the light, and a small hot glint at the upper left
  * light gathered low inside the jelly (subsurface glow) in the rim colour
  * a darker extruded lip under it (the slab's side) and a soft shadow baked under the lip
    python art/pd_ui_gel.py        -> art/ui_gel/*.png and _sheet.png
    python art/pd_ui_gel.py --matte -> art/ui_matte/*.png (2026-11-24, the owner chose "matte skins" for a more generic HUD after the
                                      flat-text A/B, where Gemini kept marking down the baked gloss): the same shapes, sizes, lip and
                                      shadow, a soft body gradient and a flat rim stroke in the rim colour; no bevel light, Fresnel,
                                      sheen, inner glow, specular or glint"""
import math, pathlib, sys
import numpy as np
from PIL import Image, ImageFilter

here = pathlib.Path(__file__).resolve().parent
MATTE = "--matte" in sys.argv
out = here / ("ui_matte" if MATTE else "ui_gel")
out.mkdir(exist_ok=True)
SS = 4


def H(h): return np.array([int(h[i:i + 2], 16) for i in (1, 3, 5)], np.float32) / 255


def sd_round_box(x, y, cx, cy, hw, hh, r):
    qx, qy = np.abs(x - cx) - (hw - r), np.abs(y - cy) - (hh - r)
    return np.hypot(np.maximum(qx, 0), np.maximum(qy, 0)) + np.minimum(np.maximum(qx, qy), 0) - r


def sd_hex(x, y, cx, cy, r):
    # a flat-topped hexagon of circumradius r (vertices at 0, 60, ... degrees), squashed 0.98 in y like pd_ui_jelly
    px, py = np.abs(x - cx), np.abs((y - cy) / 0.98)
    k = (-0.8660254, 0.5)
    # rotate the problem: distance to a hexagon with vertices on the x axis = pointy-side left/right
    d1 = py - r * 0.8660254
    d2 = (px * 0.8660254 + py * 0.5) - r * 0.8660254
    return np.maximum(d1, d2)


def smooth(e0, e1, v):
    t = np.clip((v - e0) / (e1 - e0), 0, 1)
    return t * t * (3 - 2 * t)


def gel(size, rim, top="#4c2d82", bot="#130d22", radius=16, lip=6, hexa=False, lit=False, body_alpha=0.92, rim_gain=1.15):
    w, h = size
    W, Hh = w * SS, h * SS
    y, x = np.mgrid[0:Hh, 0:W].astype(np.float32) + 0.5
    pad, L, R = 4 * SS, lip * SS, radius * SS
    x0, y0, x1, y1 = pad, pad, W - pad, Hh - pad - L  # the face of the slab (as pd_ui_jelly's box)
    cx, cy, hw, hh = (x0 + x1) / 2, (y0 + y1) / 2, (x1 - x0) / 2, (y1 - y0) / 2
    if hexa:
        rr = (w / 2 - 9) * SS
        def sdf(dy=0, grow=0): return sd_hex(x, y - dy, cx, cy, rr + grow)
    else:
        def sdf(dy=0, grow=0): return sd_round_box(x, y - dy, cx, cy, hw + grow, hh + grow, R + grow)
    d = sdf()
    face = np.clip(0.5 - d, 0, 1)  # anti-aliased coverage (supersampled anyway)
    side = np.clip(0.5 - sdf(L), 0, 1)  # the slab's side, seen under the face
    shadow = np.asarray(Image.fromarray((np.clip(0.5 - sdf(L + 2 * SS, 1 * SS), 0, 1) * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(3 * SS)), np.float32) / 255
    if MATTE:
        yy = np.clip((y - y0) / max(y1 - y0, 1), 0, 1)
        rimc = H(rim)
        col = H(top)[None, None, :] * (1 - 0.35 * yy[..., None]) + H(bot)[None, None, :] * (0.35 * yy[..., None])  # a soft fall, no light
        ring = smooth(-3.2 * SS, -1.8 * SS, d)  # a flat stroke just inside the edge
        col = col * (1 - ring[..., None] * 0.85) + rimc[None, None, :] * ring[..., None] * 0.85
        a_face = face * body_alpha
        sidecol = np.broadcast_to(H(bot) * 0.55, col.shape).copy()
    else:
        col, a_face, sidecol = lit_face(x, y, d, sdf, x0, y0, x1, y1, W, Hh, B_of(hh, hexa), R, L, rim, top, bot, hexa, lit, body_alpha, rim_gain, face, side)
    return finish(col, a_face, sidecol, shadow, side, w, h)


def B_of(hh, hexa): return min(hh, 9 * SS) if not hexa else 9 * SS


def lit_face(x, y, d, sdf, x0, y0, x1, y1, W, Hh, B, R, L, rim, top, bot, hexa, lit, body_alpha, rim_gain, face, side):

    # the bevel as a height field: a quarter circle over the outer B pixels, flat inside
    t = np.clip(-d / B, 0, 1)
    hgt = np.sqrt(1 - (1 - t) ** 2) * B * 0.9
    gy, gx = np.gradient(hgt)
    n = np.dstack([-gx, -gy, np.ones_like(hgt)])
    n /= np.linalg.norm(n, axis=2, keepdims=True)
    Ld = np.array([-0.45, -0.75, 0.55], np.float32); Ld /= np.linalg.norm(Ld)
    V = np.array([0, 0, 1], np.float32)
    Hv = (Ld + V) / np.linalg.norm(Ld + V)
    ndl = np.clip((n * Ld).sum(2), 0, 1)
    spec = np.clip((n * Hv).sum(2), 0, 1) ** 60
    fres = (1 - n[..., 2]) ** 1.6  # the bevel, strongest where it turns away

    yy = np.clip((y - y0) / max(y1 - y0, 1), 0, 1)
    rimc = H(rim)
    body = H(top)[None, None, :] * (1 - yy[..., None]) + H(bot)[None, None, :] * yy[..., None]
    body = body * (0.82 + 0.3 * ndl[..., None])
    # light gathered low in the jelly: a soft pool of the rim colour above the bottom edge, inside
    pool = smooth(0.35, 1.0, yy) * smooth(0, 2.5 * B, -d) * (0.55 if lit else 0.35)
    col = body + rimc[None, None, :] * pool[..., None] * 0.9
    # Fresnel rim: rim colour on the bevel, bright at the top edge and dim at the bottom
    rim_k = fres * (0.95 - 0.55 * yy) * rim_gain
    col = col * (1 - rim_k[..., None] * 0.6) + rimc[None, None, :] * rim_k[..., None]
    # a faint broad reflection over the upper part of the flat face (not a sticker: under 10 %)
    sheen = smooth(0.55, 0.0, yy) * smooth(0, B * 0.8, -d) * 0.08
    col = col + sheen[..., None]
    # the specular crescent on the lit bevel and a hot glint at the upper left
    gl_x, gl_y = x0 + (R if not hexa else W * 0.3) * 0.75 + 2 * SS, y0 + (R if not hexa else Hh * 0.08) * 0.45 + 2 * SS
    glint = np.exp(-(((x - gl_x) / (3.2 * SS)) ** 2 + ((y - gl_y) / (2.0 * SS)) ** 2))
    col = col + (spec * 1.25 + glint * 0.8)[..., None]
    a_face = face * np.clip(body_alpha + 0.08 * rim_k + spec, 0, 1)

    sidec = H(bot) * 0.45 + rimc * 0.05
    sidecol = np.broadcast_to(sidec, col.shape).copy()
    # the side catches a thin line of rim light at its bottom edge
    sd_edge = smooth(-2.0 * SS, 0, sdf(L)) * side
    sidecol += rimc * 0.12 * sd_edge[..., None]  # only a hint: a bright line there read as a second outline
    return col, a_face, sidecol


def finish(col, a_face, sidecol, shadow, side, w, h):
    # composite: shadow, then side, then face
    rgb = np.zeros(col.shape, np.float32); A = np.zeros(a_face.shape, np.float32)
    def over(c, a):
        nonlocal rgb, A
        na = a + A * (1 - a)
        rgb = (c * a[..., None] + rgb * A[..., None] * (1 - a[..., None])) / np.maximum(na[..., None], 1e-5)
        A = na
    over(np.broadcast_to(np.array([0.03, 0.01, 0.06], np.float32), col.shape), shadow * 0.55)
    over(sidecol, side * 0.97)
    over(np.clip(col, 0, 1), a_face)
    im = Image.fromarray((np.dstack([np.clip(rgb, 0, 1), np.clip(A, 0, 1)]) * 255).astype(np.uint8), "RGBA")
    return im.resize((w, h), Image.LANCZOS)


PIECES = {}
# buttons, 160 x 100 (9-slice 42, 40, 118, 52): a jewel-toned body each, as in v1
for n, (t, b, r) in {"mint": ("#2fc79c", "#0b5a4a", "#b8ffe8"), "pink": ("#ff4f9e", "#7a0c46", "#ffc0de"), "lilac": ("#8a5cf0", "#36145a", "#e6c4ff"),
                     "butter": ("#ffb830", "#94480a", "#fff2c0"), "sky": ("#34b8f6", "#0e4aa0", "#c0f6ff"), "off": ("#6e6290", "#2c2440", "#c8bce2")}.items():
    PIECES[n] = gel((160, 100), r, t, b, radius=18, lip=7)
# pills, 176 x 80 (and 176 x 76): obsidian-amethyst gel, the rim colour says which
for n, (r, hgt) in {"pill": ("#c49bff", 76), "pillButter": ("#ffc94a", 80), "pillLilac": ("#c49bff", 80), "pillMint": ("#4eeda8", 80), "pillPink": ("#ff6b97", 80)}.items():
    PIECES[n] = gel((176, hgt), r, radius=22, lip=5, body_alpha=0.9, rim_gain=1.7)  # the dark pills need a stronger rim to say their colour
PIECES["hex"] = gel((128, 128), "#c49bff", "#563290", "#160e28", lip=7, hexa=True)
PIECES["hexOn"] = gel((128, 128), "#5fe8ff", "#2a8ad8", "#0f2c70", lip=7, hexa=True, lit=True)

if __name__ == "__main__":
    for n, im in PIECES.items():
        im.save(out / (n + ".png"))
    # a contact sheet on the town's colours and the cave's, at 2x
    sheet = Image.new("RGBA", (1100, 1000), (40, 70, 40, 255))
    sheet.paste((26, 18, 38, 255), (0, 480, 1100, 1000))
    x, yy = 20, 20
    for n, im in PIECES.items():
        big = im.resize((im.width * 2 // 1, im.height * 2 // 1), Image.LANCZOS)
        if x + big.width > 1090: x, yy = 20, yy + 230
        sheet.alpha_composite(big, (x, yy)); x += big.width + 16
    sheet.save(out / "_sheet.png")
    print("ok", list(PIECES))
