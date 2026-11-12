"""Record the loading screen (Play running) at 30 fps and cut it into one sheet of frames, 33 ms apart.
    python spike/load_rec.py <name>      video: captures/loop/<name>.mp4, sheet: captures/loop/<name>_sheet.jpg"""
import glob, pathlib, shutil, subprocess, sys, time
import numpy as np
from PIL import Image, ImageDraw
import night as N
name = sys.argv[1]
game = pathlib.Path(__file__).resolve().parent.parent
VENV = r"C:\Users\kgsat\Documents\Roblox\Hunyuan3D\.venv\Scripts\python.exe"
video = game / "captures" / "loop" / f"{name}.mp4"
if video.exists(): video.unlink()
rec = subprocess.Popen([VENV, "-I", str(game.parent.parent / "tools" / "record_window.py"), str(video), "5", "30"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
time.sleep(1.2)
N.lua('local C=require(game.ReplicatedStorage.Shared.Config) task.spawn(function() require(game.ReplicatedStorage.Shared.LoadingScreen).start({ C = { LOADING = { on = true, min = 6, letters = C.LOADING.letters, hot = C.LOADING.hot } }, plr = game.Players.LocalPlayer }) end) return 1', "Client")
rec.wait(timeout=30)
tmp = game / "captures" / "loop" / f"_{name}"
shutil.rmtree(tmp, ignore_errors=True); tmp.mkdir()
subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", str(video), "-vf", "crop=iw:ih*0.5:0:ih*0.2,scale=480:-1", str(tmp / "f_%03d.jpg")])
fs = sorted(glob.glob(str(tmp / "f_*.jpg")))
start = next((i for i, f in enumerate(fs) if np.asarray(Image.open(f).convert("L")).mean() < 28), 0)
sel = fs[start:start + 48]
w, h = Image.open(sel[0]).size
sh = Image.new("RGB", (4 * w, 12 * h)); d = ImageDraw.Draw(sh)
for k, f in enumerate(sel):
    x, y = (k % 4) * w, (k // 4) * h
    sh.paste(Image.open(f), (x, y)); d.text((x + 3, y + 2), f"{k} +{k * 33}ms", fill=(255, 255, 0))
out = game / "captures" / "loop" / f"{name}_sheet.jpg"
sh.save(out, quality=85); shutil.rmtree(tmp, ignore_errors=True)
print(out, len(fs), "frames, loading starts at", start)
