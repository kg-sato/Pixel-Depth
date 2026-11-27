"""Style calibration for plate_kit against the owner's Loomweaver reference (not a game pet).
    blender -b -P design3d/pets/plate_test.py -- <out_dir>"""
import json, math, os, sys
here = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, here)
import plate_kit as K
from plate_kit import V

out = os.path.abspath(sys.argv[sys.argv.index("--") + 1])
os.makedirs(out, exist_ok=True)
pal = {"Main": "#2a2533", "MainTop": "#3a3348", "Dark": "#17131f", "Bone": "#d8d4e0", "BoneTop": "#f4f2f8", "Glow": "#a040ff", "Edge": "#8a84a0"}
c = K.Creature("PlateTest", pal)
c.joint("Body", (0, 0, 2.2))
c.tiers("Body", (0, -0.2, 2.6), (3.0, 3.6, 1.6), n=4, shrink=0.14)
c.block("Body", (0, 1.6, 2.2), (2.0, 1.2, 1.4), bevel=0.06)
for x in (-0.6, -0.2, 0.2, 0.6):
    c.slit("Body", (x, 2.21, 2.3), (0.22, 0.32, 0.08), (0, 1, 0))
for s in (-1, 1):
    for i, (y, spread) in enumerate(((1.2, 0.5), (0.4, 0.9), (-0.4, 1.1), (-1.2, 1.0))):
        hip = V(s * 1.3, y, 2.2)
        knee = hip + V(s * 1.6, y * 0.3 + (0.6 - i * 0.35), 1.3)
        foot = V(s * (3.6 + 0.2 * i), y * 1.3, 0.0)
        c.chain(f"Leg{'L' if s < 0 else 'R'}{i + 1}_", [hip, knee, knee.lerp(foot, 0.5) + V(0, 0, 0.3), foot + V(0, 0, 0.5)], [0.42, 0.36, 0.28, 0.2], parent="Body", claw=(0.6, 0.18), group="leg", spikes=1)
cells = set()
for i in range(-6, 7):
    for k in range(0, 8):
        r = math.hypot(i, k - 0.5)
        if 5 <= r <= 7.2 and not (k < 3 and abs(i) < 3): cells.add((i, 0, k)); cells.add((i, 1, k))
c.voxels("Body", cells, 0.12, (-0.06, -0.6, 3.4))
for k in range(5):
    c.claw("Body", (-0.8 + k * 0.4, -0.2, 3.35), (-0.8 + k * 0.4, -0.3, 3.75 + 0.15 * (k % 2)), 0.12)
d = K.export(c, out)
print("TEST", json.dumps({k: d[k] for k in ("tris", "parts", "size")}))
