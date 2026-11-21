"""Hatch motion as a frame-by-frame video when the screen recorder cannot run (a sleeping display freezes the window
recorder): the hatch scene is replayed once per frame, held at moment t with its freeze hook, and captured by Studio itself.
    python spike/hatch_frames.py <name> [pet] [fps] [end]   (Play running)  -> captures/video/<name>.mp4 at the given fps
then: python ../../tools/video_judge.py captures/video/<name>.mp4 "<intent>" --name <label>
Works like spike/hatch_shots.py (the Lua call stays open for the scene: a returned call gives the view back to the plugin)."""
import subprocess, sys, threading, time
import night as N
name = sys.argv[1]
pet = sys.argv[2] if len(sys.argv) > 2 else "Fafnir"
fps = float(sys.argv[3]) if len(sys.argv) > 3 else 5.0
end = float(sys.argv[4]) if len(sys.argv) > 4 else 9.0
d = N.game / "captures" / "video" / (name + "_frames")
d.mkdir(parents=True, exist_ok=True)
n, f = 0, 0.1
while f <= end + 1e-6:
    th = threading.Thread(target=N.lua, args=(f'''local p=game.Players.LocalPlayer p:SetAttribute("DevHatchFreeze",{f:.2f}) p:SetAttribute("DevHatch","") p:SetAttribute("DevHatch","{pet}") task.wait({f:.2f} + 3.6) return "ok"''', "Client"))
    th.start()
    time.sleep(f + 1.4)
    N.shot(f"hf_{name}")
    (N.out / f"hf_{name}.png").replace(d / f"f{n:04d}.png")
    th.join()
    time.sleep(0.6)
    n += 1
    f += 1.0 / fps
subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-framerate", str(fps), "-i", str(d / "f%04d.png"), "-vf", "scale=1280:-2", "-pix_fmt", "yuv420p", str(d.parent / f"{name}.mp4")], check=True)
print("frames", n, "->", d.parent / f"{name}.mp4")
