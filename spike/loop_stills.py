"""loop_rec5.py's whole-game tour, but captured as MCP screen_capture stills instead of a window video.
Use it when the display is asleep: record_window.py (PrintWindow) then gives one frozen frame for the whole run.
    python spike/loop_stills.py <name>     stills: captures/loop/<name>/, sheets: <workspace>/Overnight/judge/loop_<name>/
Every STEP seconds a background thread takes one still, labelled with the time and the tour step running."""
import pathlib, re, sys, threading, time
here = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(here))
import night as N

STEP = 4
name = sys.argv[1] if len(sys.argv) > 1 else "stills"
src = (here / "loop_rec5.py").read_text(encoding="utf-8")
src = "".join("rec = None  # no window video" + chr(10) if l.startswith("rec = subprocess.Popen(") else l for l in src.splitlines(keepends=True))
src = re.sub(r'left = SECS - \(time.time\(\) - t0\)\nmark\(f"\{left:.0f\} s of recording left"\)\ntime.sleep\(max\(left \+ 4, 4\)\)\nprint\(rec.communicate\(timeout=900\)\[0\]\[-300:\]\)\n', "STOP.set(); time.sleep(STEP + 2)\n", src)
src = src.replace('r = subprocess.run([VENV, "-I", str(ws / "tools" / "video_sheets.py"), str(video), str(sheets), "3"]', 'r = subprocess.run([VENV, "-I", str(here / "stills_sheets.py"), str(game / "captures" / "loop" / name), str(sheets)]')
assert "STOP.set()" in src and "stills_sheets" in src and "rec = None" in src, "loop_rec5.py changed: update the patterns"
src = src.replace('def mark(what): print(', 'def mark(what): STATE["step"] = what; print(')

STOP, STATE = threading.Event(), {"step": "start"}
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
        time.sleep(max(0, STEP - (time.time() - t0 - t)))


threading.Thread(target=snap, daemon=True).start()
sys.argv = [str(here / "loop_rec5.py"), name]
exec(compile(src, str(here / "loop_rec5.py"), "exec"), {"__name__": "__main__", "__file__": str(here / "loop_rec5.py"), "STOP": STOP, "STATE": STATE, "STEP": STEP})
labels.close()
