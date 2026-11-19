"""Contact sheets (4 x 3) from a folder of stills with labels.txt (name, seconds, step), for the Gemini judge.
    Hunyuan3D/.venv/Scripts/python.exe -I spike/stills_sheets.py <stills dir> <out dir>"""
import pathlib, sys
import cv2, numpy as np
src, out = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
out.mkdir(parents=True, exist_ok=True)
rows = [l.split("\t") for l in (src / "labels.txt").read_text(encoding="utf-8").splitlines() if l.strip()]
W, H, n = 480, 270, 12
for s in range(0, len(rows), n):
    sheet = np.zeros((H * 3, W * 4, 3), np.uint8)
    for i, (f, t, step) in enumerate(rows[s:s + n]):
        img = cv2.imread(str(src / f))
        if img is None: continue
        img = cv2.resize(img, (W, H))
        cv2.rectangle(img, (0, 0), (W, 20), (0, 0, 0), -1)
        cv2.putText(img, f"{t}s {step}"[:60], (4, 15), cv2.FONT_HERSHEY_SIMPLEX, 0.42, (80, 220, 255), 1, cv2.LINE_AA)
        sheet[(i // 4) * H:(i // 4 + 1) * H, (i % 4) * W:(i % 4 + 1) * W] = img
    p = out / f"{out.name.removeprefix('loop_')}_sheet_{s // n + 1:02d}.jpg"
    cv2.imwrite(str(p), sheet, [cv2.IMWRITE_JPEG_QUALITY, 85])
    print("wrote", p)
