"""Perfect Strike juice, recorded (Play running, in the caves): records the Studio window while one run is struck at the given
offsets, then cuts stills 0.1, 0.25 and 0.45 s after each swing (stills taken by screen_capture land about a second late and
miss the burst).   python spike/sj_rec.py <prefix> <off1,off2,off3>   -> captures/night/<prefix>_s<k>_<t>.png"""
import subprocess, sys, time, pathlib
import night as N
pre, offs = sys.argv[1], [float(x) for x in sys.argv[2].split(",")]
game = pathlib.Path(__file__).resolve().parent.parent
VENV = r"C:\Users\kgsat\Documents\Roblox\Hunyuan3D\.venv\Scripts\python.exe"
src = open(pathlib.Path(__file__).parent / "sj_test.py", encoding="utf-8").read()
exec(src.split("SW = (")[0].split('pre = sys.argv[1]\n')[1])  # go_to, face, P and the ride down
exec("SW = (" + src.split("SW = (")[1].split("def run(")[0])
print(go_to("d:GetAttribute('Ore')<3")); time.sleep(1.2); face()
video = game / "captures" / "loop" / f"{pre}.mp4"
rec = subprocess.Popen([VENV, "-I", str(game.parent.parent / "tools" / "record_window.py"), str(video), "9", "30"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
time.sleep(1.0); t0 = time.time()
N.key("E"); time.sleep(1.0)
marks = []
for off in offs:
    N.lua(SW.replace("{off}", str(off)), "Client")
    marks.append(time.time() - t0); time.sleep(0.7)
rec.wait(timeout=30)
for k, m in enumerate(marks):
    for dt in (0.1, 0.25, 0.45):
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-ss", f"{m + 1.0 - 0.15 + dt:.2f}", "-i", str(video), "-frames:v", "1", str(game / "captures" / "night" / f"{pre}_s{k + 1}_{dt}.png")])
print("marks", marks)
