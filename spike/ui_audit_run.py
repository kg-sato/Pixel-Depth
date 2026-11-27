"""Open each menu in turn and run spike/ui_align_audit.luau on it (Play running, player in town).
   python spike/ui_audit_run.py [tag]  -> prints the counts per screen, captures captures/night/uia_<tag>_<screen>.png"""
import sys, time, pathlib
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import night
tag = sys.argv[1] if len(sys.argv) > 1 else "t"
AUDIT = (pathlib.Path(__file__).resolve().parent / "ui_align_audit.luau").read_text(encoding="utf-8")
FX = "game.ReplicatedStorage.Remotes.Fx:FireClient(game.Players:GetPlayers()[1], '%s') return 'ok'"
SCREENS = [
    ("hud", None, None),
    ("bag", ("key", "B"), ("key", "B")),
    ("quests", ("key", "J"), ("key", "J")),
    ("settings", ("key", "N"), ("key", "N")),
    ("wheel", ("key", "Tab"), ("key", "Tab")),
    ("forge", ("fx", "openForge"), ("key", "Escape")),
    ("hatchery", ("fx", "openHatchery"), ("key", "Escape")),
]
only = sys.argv[2:] or None
total = [0, 0, 0]
for name, op, close in SCREENS:
    if only and name not in only: continue
    if op and op[0] == "key": night.key(op[1])
    elif op: night.lua(FX % op[1], "Server")
    time.sleep(1.6)
    r = night.lua(AUDIT, "Client")
    head = r.splitlines()
    i = next((k for k, l in enumerate(head) if l.startswith("small ")), None)
    print(f"== {name}: " + ("\n".join(head[i:]) if i is not None else r[-400:]))
    if i is not None:
        n = [int(x) for x in head[i].replace("small", "").replace("overlap", "").replace("out", "").split()]
        total = [a + b for a, b in zip(total, n)]
    night.shot(f"uia_{tag}_{name}")
    if close and close[0] == "key": night.key(close[1])
    time.sleep(0.8)
print("TOTAL small %d overlap %d out %d" % tuple(total))
