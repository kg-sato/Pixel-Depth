"""Stills from loop_stills.py to a slideshow mp4 at the real timing (each still held until the next one), with its time and step.
    python spike/stills_mp4.py <stills dir> [out.mp4]      (Hunyuan3D venv python: needs cv2)"""
import pathlib, sys
import cv2
d = pathlib.Path(sys.argv[1])
out = sys.argv[2] if len(sys.argv) > 2 else str(d) + ".mp4"
rows = [l.split("	") for l in (d / "labels.txt").read_text(encoding="utf-8").splitlines() if l.strip()]
FPS, W = 2, 1280  # agy decodes video at 1 fps anyway; 2 keeps the file small (20 MB sandbox cap)
w = None
for i, (f, t, step) in enumerate(rows):
    img = cv2.imread(str(d / f))
    if img is None: continue
    img = cv2.resize(img, (W, int(W * img.shape[0] / img.shape[1])))
    cv2.putText(img, f"{t}s  {step.strip()}"[:90], (12, img.shape[0] - 14), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 255, 255), 2)
    if w is None: w = cv2.VideoWriter(out, cv2.VideoWriter_fourcc(*"mp4v"), FPS, (img.shape[1], img.shape[0]))
    hold = (float(rows[i + 1][1]) - float(t)) if i + 1 < len(rows) else 2
    for _ in range(max(1, round(hold * FPS))): w.write(img)
w.release()
print("wrote", out, len(rows), "stills")
