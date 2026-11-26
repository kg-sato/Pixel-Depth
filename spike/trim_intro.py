"""v16.1 (audit 2:35): cut what Studio shows before the game's first frame from a Play recording. A Studio client draws the bare
default day sky for about 5 s while the place replicates, before any script runs (a real client shows Roblox's own loading
screen there; game code cannot reach those frames). This cuts the recording to start at the Splash cover's first dark frame
that follows the sky. A recording without the sky is left as it is.
    python spike/trim_intro.py <in.mp4> [out.mp4]   (out defaults to replacing in)"""
import pathlib, subprocess, sys
src = pathlib.Path(sys.argv[1])
dst = pathlib.Path(sys.argv[2]) if len(sys.argv) > 2 else src
FPS, W, H = 10, 32, 18
raw = subprocess.run(["ffmpeg", "-loglevel", "error", "-t", "40", "-i", str(src), "-vf", f"fps={FPS},scale={W}:{H}", "-f", "rawvideo", "-pix_fmt", "rgb24", "-"], capture_output=True).stdout
n = len(raw) // (W * H * 3)
def mean(i):
    f = raw[i * W * H * 3:(i + 1) * W * H * 3]
    return [sum(f[c::3]) / (W * H) for c in range(3)]
sky_seen, cut = False, None
for i in range(n):
    r, g, b = mean(i)
    if b > 140 and b > r + 40: sky_seen = True  # the default day sky: bright and blue
    elif sky_seen and (r + g + b) / 3 < 40: cut = i / FPS; break  # the first dark cover frame after it
if cut is None:
    print("no default-sky intro found: left as it is"); sys.exit(0)
tmp = dst.with_name(dst.stem + "_trim_tmp.mp4")
subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-ss", f"{cut:.2f}", "-i", str(src), "-c:v", "libx264", "-crf", "18", "-preset", "fast", "-an", str(tmp)], check=True)
tmp.replace(dst)
print(f"cut {cut:.1f} s of Studio start-up (default sky) from {src.name}")
