"""loop_rec5.py's whole-game tour, but captured as MCP screen_capture stills instead of a window video.
Use it when the display is asleep: record_window.py (PrintWindow) then gives one frozen frame for the whole run.
    python spike/loop_stills.py <name> [script.py]   stills: captures/loop/<name>/, sheets: <workspace>/Overnight/judge/loop_<name>/
script: loop_rec5.py (default) or cutscene_rec.py. STILL_STEP=<seconds> sets the gap (one still takes about 1.3 s).
Then python spike/stills_mp4.py captures/loop/<name> makes a slideshow video at the real timing.
Every STEP seconds a background thread takes one still, labelled with the time and the tour step running."""
import pathlib, re, sys, threading, time
here = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(here))
import night as N

import os
STEP = float(os.environ.get("STILL_STEP", 4))
name = sys.argv[1] if len(sys.argv) > 1 else "stills"
SCRIPT = sys.argv[2] if len(sys.argv) > 2 else "loop_rec5.py"
src = (here / SCRIPT).read_text(encoding="utf-8")
src = "".join("rec = None  # no window video" + chr(10) if l.startswith("rec = subprocess.Popen(")
              else "STOP.set(); time.sleep(STEP + 2)" + chr(10) if l.startswith("print(rec.communicate(")
              else "pass  # no recording to wait for" + chr(10) if l.startswith("time.sleep(max(left + 4, 4))") else l for l in src.splitlines(keepends=True))
src = re.sub(r'left = SECS - \(time.time\(\) - t0\)\nmark\(f"\{left:.0f\} s of recording left"\)\ntime.sleep\(max\(left \+ 4, 4\)\)\nprint\(rec.communicate\(timeout=900\)\[0\]\[-300:\]\)\n', "STOP.set(); time.sleep(STEP + 2)\n", src)
src = src.replace('subprocess.run([VENV, "-I", str(ws / "tools" / "video_sheets.py"), str(video), str(sheets), "3"]', 'subprocess.run([VENV, "-I", str(here / "stills_sheets.py"), str(game / "captures" / "loop" / name), str(sheets)]')
assert "STOP.set()" in src and "stills_sheets" in src and "rec = None" in src, SCRIPT + " changed: update the patterns"
src = src.replace('def mark(what): print(', 'def mark(what): STATE["step"] = what; print(')

STOP, STATE, FORCE = threading.Event(), {"step": "start"}, threading.Event()
outdir = here.parent / "captures" / "loop" / name
outdir.mkdir(parents=True, exist_ok=True)
labels = open(outdir / "labels.txt", "w", encoding="utf-8")


def snap():
    t0 = time.time()
    while not STOP.is_set():
        t = time.time() - t0
        try:
            p = N.shot("_still")
            dst = outdir / f"{int(t):04d}.png"
            pathlib.Path(p).replace(dst)
            labels.write(f"{dst.name}\t{t:.0f}\t{STATE['step']}\n"); labels.flush()
        except Exception as e:
            print("still failed:", e, flush=True)
        FORCE.wait(max(0, STEP - (time.time() - t0 - t)))  # the tour can ask for a still now (FORCE.set()) for a moment shorter than STEP
        FORCE.clear()


threading.Thread(target=snap, daemon=True).start()
sys.argv = [str(here / SCRIPT), name]
exec(compile(src, str(here / SCRIPT), "exec"), {"__name__": "__main__", "__file__": str(here / SCRIPT), "STOP": STOP, "STATE": STATE, "STEP": STEP, "FORCE": FORCE})
labels.close()
