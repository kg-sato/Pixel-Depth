"""Grayscale chunky pixel-fire flipbook, 4x4 frames of 128 px (16x16 fat pixels each), white core to dark edge, alpha cut.
Tinted in game by the ParticleEmitter Color (orange camp fire, cyan crystal vent, green spore vent). Ref: Instagram Df2oc8rElqf.
    Hunyuan3D venv python spike/pixel_fire.py  ->  art/fx/pixel_fire_4x4.png"""
import numpy as np, cv2, pathlib
N, C, F = 16, 8, 16  # cells per side, px per cell, frames
rng = np.random.default_rng(7)
noise = rng.random((64, N))
out = np.zeros((4 * N * C, 4 * N * C, 4), np.uint8)
for f in range(F):
    img = np.zeros((N, N), float)
    for y in range(N):
        h = 1 - y / (N - 1)                      # 0 at the base row (bottom), 1 at the top
        width = 4.4 * (1 - h) ** 0.6 * min(1.0, (N - y) / 4.5) + 0.5  # a teardrop: round at the base, a point at the top
        sway = 1.2 * np.sin(f / F * 2 * np.pi + h * 3.2) * h
        for x in range(N):
            d = abs(x - (N - 1) / 2 - sway) / max(width, 0.1)
            flick = noise[(f * 3 + y) % 64, x] * 0.35
            v = (1 - d) * (1 - 0.55 * h) + 0.25 - flick * h
            img[y, x] = v
    img = np.clip(img, 0, 1)
    lvl = np.where(img > 0.72, 255, np.where(img > 0.5, 200, np.where(img > 0.3, 140, np.where(img > 0.14, 90, 0))))  # 4 hard steps
    a = (lvl > 0).astype(np.uint8) * 255
    big = np.kron(lvl, np.ones((C, C))).astype(np.uint8)
    ba = np.kron(a, np.ones((C, C))).astype(np.uint8)
    r, c = divmod(f, 4)
    tile = np.dstack([big, big, big, ba])
    out[r * N * C:(r + 1) * N * C, c * N * C:(c + 1) * N * C] = tile
p = pathlib.Path(__file__).resolve().parent.parent / "art" / "fx" / "pixel_fire_4x4.png"
cv2.imwrite(str(p), cv2.cvtColor(out, cv2.COLOR_RGBA2BGRA))
print("wrote", p)
