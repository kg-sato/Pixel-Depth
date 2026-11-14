"""Run the 2026-11-11 night's Play tests one after another and print PASS / FAIL per check (about 8 minutes; Studio open, Edit mode).
    python spike/night_all.py
Checks the output text of each test script for the lines that prove it; a FAIL prints the script's tail. The Soul Tree tests
(soul_test.py, soul_hit_test.py, review_fix_test.py) are left out: they need C.SOUL_TREE.on = true pushed first."""
import subprocess, sys, pathlib
here = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(here))
import night
TESTS = [  # script, [(what, text that must be in the output)]
    ("wheel_test.py", [("sonar through the wheel", "sonar: true"), ("flare through the wheel", "flare: 2 -> 1"), ("no wardrobe in the caves", "must stay shut): 0 open"), ("no HUD overlap", "0 overlaps, 0 prompt overlaps")]),
    ("wheel_touch_test.py", [("TOOLS button opens the wheel", "wheel open: true"), ("slot tap opens the wardrobe", "wardrobe panels open 1")]),
    ("load_test.py", [("loading logo letters land one at a time", "one by one: yes")]),
    ("spatial_click_test.py", [("a click reaches a button on a world-panel menu", "bag still open: false")]),
    ("ar_click_test.py", [("a click flips a toggle in the look-around settings", "NoShake after click: true")]),
    ("touch_test.py", [("thumb buttons show in the caves", "cave: flare true sonar true ping true"), ("no script errors in touch mode", "errors: 0")]),
    ("opts_test.py", [("settings reach the server", 'kept after a good send: {"shake":false,"vol":3,"hints":true,"dark":true}'), ("bad settings are dropped", "kept after a number: []"), ("fast cutscenes kept", '"fast":true'), ("fast cutscenes skip the lift", "picture false anchored false at Camp 2 true"), ("saved settings load on join", "loaded on join: NoShake true DevLowLight true volume 3"), ("test hook cleared", "hook cleared: nil")]),
    ("pet_test.py", [("three pets have faces", "town faces: 3 "), ("three crew pets in the cave view", "in view: 3 pets"), ("whistle marks a deposit", "whistle: mark true glow true"), ("whistle has a cooldown", "most marks at once: 1,"), ("pets react to a hit", "hurt face seen: true"), ("no script errors with pets", "errors: 0")]),
    ("boon_test.py", [("offer arrives", "boonOffer:"), ("bad picks refused", "-> flares 2 hp 100 shield 0 fx\n"), ("a pick lands", "boonTaken:"), ("second prayer is spent", "boonSpent")]),
    ("ping_test.py", [("marker and beam", "marks on screen: 1 beam true"), ("bad pings refused", "(0 expected): 0"), ("rate limit", "(1 expected): 1"), ("no HUD overlap", "0 overlaps, 0 prompt overlaps")]),
    ("travel_test.py", [("hearth refused in town", "hearth in town: 1 no:Caves only"), ("hearth refused while grabbed", "hearth while grabbed: 1 no:Grabbed!"), ("hearth cannot end early", "hearth ended early: 2 go:3 no:Stand still | studs from camp: far"),
        ("hearth cannot end after walking away", "1 no:Stand still | studs from camp: far"), ("hearth brings you home", "done:300 | studs from camp: near"), ("hearth cooldown", "cooldown on: True"),
        ("zip refused far from the grip", "grip moved on the client: prompt fired 1, 0 rides"), ("zip refused while grabbed", "zip while grabbed: prompt fired 1, 0 rides"), ("zip rides from the grip", "at the handle: prompt fired 1, 1 rides | studs from the far post: near"),
        ("grotto zip rides back", "(handle 4): prompt fired 1, 1 rides | studs from the near post: near"), ("camp 2 refused before the gate", "gate shut: in cave true studs from Camp 1 near"), ("lift holds the rider, once", "lift asked twice: 1 ride of 12 s"),
        ("no hearth on the lift", "picture up: true | hearth: no:Not now"), ("lift lets go at Camp 2", "lift, 16 s in: anchored false studs from Camp 2 near"), ("Q offers both camps", "panel true in cave false"),
        ("the pick rides to Camp 2", "picked Camp 2: anchored false studs from Camp 2 near"), ("no client errors", "client errors: 0")]),
    ("boss_atk_test.py", [("slam hits near", "Warden slam, standing 10 studs away: bossSlam bossHit:slam"), ("slam misses far", "Warden slam, 24 studs away: bossSlam bossDodge"),
        ("sweep hits in the lane", "Warden sweep, standing in the lane: bossSweep bossHit:sweep"), ("sweep misses beside the lane", "Warden sweep, stepped 7 studs aside: bossSweep bossDodge"),
        ("ring hits on a band", "Warden rings, standing on the second band (14): bossRings bossHit:rings"), ("ring misses in a gap", "Warden rings, standing in the first gap (10.5): bossRings bossDodge"),
        ("golem sweep hits and misses", "KilnGolem sweep, stepped 7 studs aside: bossSweep bossDodge"), ("golem rings hit on a band", "KilnGolem rings, standing on the second band (14): bossRings bossHit:rings"),
        ("golem rings miss in a gap", "KilnGolem rings, standing in the second gap (17.5): bossRings bossDodge"), ("no client errors", "client errors 2: 0")]),
    ("boss_fight_test.py", [("boss frame shows", "bar true banner ROOT WARDEN"), ("a whole fight without a hit", "fight summary: won True, hits 0, slam True, sweep True, rings True"),
        ("reward chest", "chest layer true title ROOT WARDEN CHEST bar false"), ("no client errors", "client errors: 0")]),
    ("camp2_test.py", [("openings clear, rooms reachable", "door blocked by 0"), ("every set point reached", "walk test: 0 unreachable"), ("no z-fighting", "z-fight pairs 0"), ("jars and fossils moved", "4 jars in the gallery, 3 fossils in the dig, hammer true"),
        ("jar cooldown holds", "jar 5, again at once: prompt on false, paid 0"), ("surge refills jars", "jar 5, after the surge began: prompt on false, paid 1"), ("surge ends on the server clock", "surge over: true"),
        ("vents never rest in a surge", "never rests in a surge: True"), ("no client errors", "client errors: 0")]),
    ("retention_test.py", [("gift pill counts down", "pills at the start: NEXT GIFT"), ("no gift before its time", "claim with nothing due: ?"), ("a due gift is paid once", "claim again at once: coins:150"),
        ("gifts are paid in order", "two claims at 21 minutes: coins:150 flares:2 gems:10"), ("bad messages pay nothing", "bad messages: coins:150 flares:2 gems:10"), ("golden surge doubles the zone", "zone doubled: True"),
        ("event pill shows the surge", "GOLD SURGE ON"), ("friends are counted", "board: 2/5 FRIENDS HERE / +15% ORE VALUE IS ON"), ("rift is off by default", "rift off: 1 in the Clay Caves, 1 in Camp 1"), ("rift triples Clay Caves ore only", "rift on: 3 in the Clay Caves, 1 in Camp 1"), ("rift crystal shows", "crystal: true"), ("refinery refuses without a geode", "refinery, no geode:  none"), ("refinery starts once", "refinery, a geode in, pressed again:  none start |  none start wait"), ("refinery pays once", "refinery, done:  none start wait paid"), ("refinery is empty after", "refinery, empty again:  none start wait paid none"), ("refinery refuses from far away", "refinery, pressed from far away:  none start wait paid none
"), ("no client errors", "client errors: 0"), ("no server errors", "server errors: 0")]),
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
