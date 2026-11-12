"""Record the first 26 s of a minecart escape (idle player) and measure, from the frames, when each warning plate shows
and when BONK lands. Run with the system python; the recording and the measuring use the Hunyuan3D venv (OpenCV).
    python spike/escape_warn_measure.py [name]"""
import subprocess, sys, time, pathlib
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import night
name = sys.argv[1] if len(sys.argv) > 1 else "escape_warn"
out = night.game / "captures" / "video"; out.mkdir(parents=True, exist_ok=True)
py = str(night.root / "Hunyuan3D" / ".venv" / "Scripts" / "python.exe")
night.play(True); time.sleep(6)
night.lua("game.ReplicatedStorage.Remotes.Surface:FireServer('down') return 1", "Client"); time.sleep(16)
night.lua("game.ReplicatedStorage.Remotes.Surface:FireServer('up') return 1", "Client")
subprocess.run([py, "-I", str(night.root / "tools" / "record_window.py"), str(out / f"{name}.mp4"), "26", "30"], capture_output=True, text=True)
night.play(False)
MEASURE = r'''
import cv2, sys
c = cv2.VideoCapture(sys.argv[1]); fps = c.get(cv2.CAP_PROP_FPS); i = 0
ok, f = c.read(); X0, X1, Y0, Y1 = 10, 1926, 190, 972   # the game view inside the Studio window
def reg(fx, fy, r=0.035):
    x, y = int(X0 + (X1 - X0) * fx), int(Y0 + (Y1 - Y0) * fy); d = int((Y1 - Y0) * r)
    return slice(y - d, y + d), slice(x - d, x + d)
spots = {"right": reg(0.76, 0.5), "left": reg(0.24, 0.5), "up": reg(0.5, 0.27), "down": reg(0.5, 0.68)}
last, start, bonk, leads = {}, {}, False, []
while ok:
    t = i / fps
    for k, s in spots.items():
        p = f[s].reshape(-1, 3).astype(int)   # the plate is ink (BGR about 90, 46, 66)
        if ((abs(p[:, 0] - 90) < 28) & (abs(p[:, 1] - 46) < 22) & (abs(p[:, 2] - 66) < 26)).mean() > 0.35:
            if k not in last or t - last[k] > 0.45: start[k] = t   # a new plate (the running chevrons do not matter)
            last[k] = t
    b = f[reg(0.5, 0.42, 0.06)].reshape(-1, 3).astype(int)
    pink = ((b[:, 2] > 235) & (abs(b[:, 1] - 157) < 25) & (abs(b[:, 0] - 176) < 30)).mean() > 0.03
    if pink and not bonk:
        near = [(t - start[k], k) for k in start if t - last.get(k, -9) < 0.5]
        if near: leads.append(max(near))
    bonk = pink
    ok, f = c.read(); i += 1
print("warning lead before each BONK (s, plate):", [(round(a, 2), k) for a, k in leads])
if leads: print("shortest %.2f  mean %.2f" % (min(a for a, _ in leads), sum(a for a, _ in leads) / len(leads)))
'''
print(subprocess.run([py, "-I", "-c", MEASURE, str(out / f"{name}.mp4")], capture_output=True, text=True).stdout.strip())
