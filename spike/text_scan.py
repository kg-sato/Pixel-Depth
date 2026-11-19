"""Text overlap route (2026-11-18): plays the game, opens each screen the real way and runs spike/text_overlap.luau on it.
    python spike/text_scan.py [name]      screenshots captures/night/ts_<name>_<state>.png, report printed"""
import sys, time, subprocess, pathlib
here = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(here))
import night as N
from prompt_test import trigger
name = sys.argv[1] if len(sys.argv) > 1 else "a"
SCAN = str(here / "text_overlap.luau")
report = []
def scan(state):
    time.sleep(1.2)
    r = N.lua("_G.TEXT_SCAN_FORCE=false return 1", "Client")
    out = N.run("execute_luau", {"datamodel_type": "Client"}, file=SCAN)
    N.shot(f"ts_{name}_{state}")
    lines = [l for l in out.splitlines() if l.strip()]
    report.append(f"== {state}: " + "\n".join(lines[-40:]))
def fresh():  # a real restart: play() on a running session keeps it, with whatever an earlier test left open
    N.play(False); time.sleep(3); N.play(); time.sleep(9)
fresh(); scan("town")
for st in ("forge", "hatch", "sell", "map", "chest"):
    trigger("Station", f"'{st}'"); scan(st); fresh()
for k, st in (("J", "quests"), ("Tab", "wheel"), ("N", "notes")):
    N.key(k); scan(st); N.key(k if k != "Tab" else "Tab")
fresh(); N.key("Q"); time.sleep(26); scan("cave")
N.key("J"); scan("cave_quests"); N.key("J")
N.key("Q"); time.sleep(10); scan("escape")
time.sleep(40); scan("escape_end")
fresh(); N.lua("_G.TEXT_SCAN_FORCE=true return 1", "Client")
out = N.run("execute_luau", {"datamodel_type": "Client"}, file=SCAN)
report.append("== forced (closed panels opened raw; dynamic parts unset):\n" + "\n".join(out.splitlines()[-60:]))
N.play(False)  # the forced pass leaves panels in odd states: never reuse that session
print("\n".join(report))
