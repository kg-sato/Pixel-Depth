"""Run the 2026-11-11 night's Play tests one after another and print PASS / FAIL per check (about 8 minutes; Studio open, Edit mode).
    python spike/night_all.py
Checks the output text of each test script for the lines that prove it; a FAIL prints the script's tail. The Soul Tree tests
(soul_test.py, soul_hit_test.py, review_fix_test.py) are left out: they need C.SOUL_TREE.on = true pushed first."""
import subprocess, sys, pathlib
here = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(here))
import night
TESTS = [  # script, [(what, text that must be in the output)]
    ("wheel_test.py", [("sonar through the wheel", "sonar: true"), ("flare through the wheel", "flare: 2 -> 1"), ("wardrobe refused in the caves", "0 open, wheel stayed true"), ("no HUD overlap", "0 overlaps, 0 prompt overlaps")]),
    ("wheel_touch_test.py", [("TOOLS button opens the wheel", "wheel open: true"), ("slot tap opens the wardrobe", "wardrobe panels open 1")]),
    ("spatial_click_test.py", [("a click reaches a button on a world-panel menu", "bag still open: false")]),
    ("boon_test.py", [("offer arrives", "boonOffer:"), ("bad picks refused", "-> flares 2 hp 100 shield 0 fx\n"), ("a pick lands", "boonTaken:"), ("second prayer is spent", "boonSpent")]),
    ("ping_test.py", [("marker and beam", "marks on screen: 1 beam true"), ("bad pings refused", "(0 expected): 0"), ("rate limit", "(1 expected): 1"), ("no HUD overlap", "0 overlaps, 0 prompt overlaps")]),
    ("verify_night.py", [("wind-up dodge", "after stepping away 100"), ("way home embers", "(PASS over 0), at camp 0 (PASS 0)")]),
]
bad = 0
for script, checks in TESTS:
    night.play(False)
    r = subprocess.run([sys.executable, str(here / script)], capture_output=True, text=True, encoding="utf-8", errors="replace")
    out = (r.stdout or "") + (r.stderr or "")
    for what, needle in checks:
        ok = needle in out
        bad += 0 if ok else 1
        print(("PASS  " if ok else "FAIL  ") + script + ": " + what)
    if any(n not in out for _, n in checks): print("   tail: " + " | ".join(out.strip().splitlines()[-6:])[:900])
night.play(True)
import time; time.sleep(4)
ERR = "local t={} for _,m in game:GetService('LogService'):GetLogHistory() do if m.messageType==Enum.MessageType.MessageError then t[string.sub(m.message,1,160)]=true end end local e={} for k in t do if not string.find(k,'Requester does not have permission') then table.insert(e,k) end end return #e..' '..table.concat(e,' ## ')"
for w in ("Client", "Server"):
    line = night.lua(ERR, w).splitlines()[-1]
    ok = line.startswith("0")
    bad += 0 if ok else 1
    print(("PASS  " if ok else "FAIL  ") + f"{w} log has no game errors" + ("" if ok else ": " + line))
night.play(False)
print("ALL PASS" if bad == 0 else f"{bad} FAILED")
