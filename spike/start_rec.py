"""v16.1 fix 3: record the first seconds of Play to see what shows before the game's own cover (the 2:35 blue-sky flash).
    python spike/start_rec.py <tag> [secs]  -> captures/video/start_<tag>.mp4 and Overnight-free tile captures/video/start_<tag>.jpg"""
import ctypes, pathlib, subprocess, sys, time
here = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(here))
import night as N
tag = sys.argv[1] if len(sys.argv) > 1 else "a"
secs = float(sys.argv[2]) if len(sys.argv) > 2 else 14
out = here.parent / "captures" / "video" / f"start_{tag}.mp4"
out.parent.mkdir(parents=True, exist_ok=True)
VENV = str(N.root / "Hunyuan3D" / ".venv" / "Scripts" / "python.exe")
u = ctypes.windll.user32
u.mouse_event(0x0001, 1, 0, 0, 0); time.sleep(0.05); u.mouse_event(0x0001, -1, 0, 0, 0)
ctypes.windll.kernel32.SetThreadExecutionState(0x80000000 | 0x00000002 | 0x00000001)
N.play(False); N.restore(); time.sleep(1)
rec = subprocess.Popen([VENV, "-I", str(N.root / "tools" / "record_window.py"), str(out), str(secs), "10"], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
time.sleep(1.0)
t0 = time.time()
N.run("start_stop_play", {"is_start": True})
print("play started after %.1f s" % (time.time() - t0), flush=True)
print((rec.communicate(timeout=120)[0] or "").strip().splitlines()[-1:])
tile = out.with_suffix(".jpg")
subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", str(out), "-vf", "fps=2,scale=320:-1,tile=7x4", "-frames:v", "1", str(tile)])
print(tile)
