"""Run the Play tests one after another and print PASS / FAIL per check (Studio open, Edit mode).
    python spike/night_all.py                  every test (about 25 minutes); run it before a recording and at the end of a night
    python spike/night_all.py quick [name...]  only what a change can have broken (the owner, 2026-11-14: "regressions take 30 min
                                               for one simple feature"): a smoke set, every test that covers a file changed since
                                               the last full pass or the last quick pass on a clean tree (COVER below; uncommitted changes
                                               count), and the tests named
                                               (crew, trophy, ...). A change to PixelClient, PixelServer or Config touches
                                               everything, so name the tests of the feature you changed.
A failed test is run once more by itself before it counts (two checks are known to fail now and then: a simulated click,
the pet whistle). A full pass writes spike/.last_full (the commit it ran at) and every run writes spike/.test_times.json.
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
    ("pet_test.py", [("three pets have faces", "town faces: 3 "), ("three crew pets in the cave view", "in view: 3 pets"), ("whistle marks a deposit", "whistle: mark true glow true"), ("whistle has a cooldown", "most marks at once: 1,"), ("no script errors with pets", "errors: 0")]),
    ("boon_test.py", [("offer arrives", "boonOffer:"), ("bad picks refused", "-> flares 2 hp 100 shield 0 fx\n"), ("a pick lands", "boonTaken:"), ("second prayer is spent", "boonSpent")]),
    ("ping_test.py", [("marker and beam", "marks on screen: 1 beam true"), ("bad pings refused", "(0 expected): 0"), ("rate limit", "(1 expected): 1"), ("no HUD overlap", "0 overlaps, 0 prompt overlaps")]),
    ("travel_test.py", [("hearth refused in town", "hearth in town: 1 no:Caves only"), ("hearth refused while grabbed", "hearth while grabbed: 1 no:Grabbed!"), ("hearth cannot end early", "hearth ended early: 2 go:3 no:Stand still | studs from camp: far"),
        ("hearth cannot end after walking away", "1 no:Stand still | studs from camp: far"), ("hearth brings you home", "done:300 | studs from camp: near"), ("hearth cooldown", "cooldown on: True"),
        ("zip refused far from the grip", "grip moved on the client: prompt fired 1, 0 rides"), ("zip refused while grabbed", "zip while grabbed: prompt fired 1, 0 rides"), ("zip rides once however often it is pressed", ", 1 rides | studs from the far post: near"),
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
    ("crew_test.py", [("crew sign stands over the cart", "sign before: CREW RIDE:  PRESS V TO BOARD"), ("boarding seats the driver and starts the clock", "board: seat 1 | CREW RIDE  0:1"), ("no solo ride while aboard", "solo ride while aboard: seat 1 | CREW RIDE"), ("the driver can go now", "driver presses again: seat nil | CREW RIDE:  PRESS V TO BOARD | seated true | ride true"), ("a passenger follows the driver", "passenger: replica true seat x -0.75 moved true near the driver true things on the rail true"), ("a crew of two with one crew moment is paid 31", "home: paid 31 in cave false"), ("one flare is counted, a second at once is not", "flares: thrown 1 left 7 | on screen 7 | button true"), ("a crew moment answered in time is won, an unanswered one is lost", "moments: call:left verdict:true call:duck verdict:false"), ("only the driver feeds the relay", "echoes 0"), ("the first crew ride of the day pays a gem", "crew numbers: gem 1 riders 2 x1.25 hits 1 flares 1 moves 1/2"), ("the result card shows the crew", "result card: +31 COINS  +1 GEM | 1 OF 2 | 2 RIDERS  x1.25"), ("a second crew ride the same day pays no gem", "second crew ride the same day: paid 27 | gem 0"), ("the next rider drives when the driver leaves", "the driver left: replica false job driver still moving true in the cave true"), ("a stoke in the gold is a hit", "in the gold: true 0.2 1"), ("a stoke outside is a miss", "outside: false"), ("fast presses are judged once", "three at once judged: 1"), ("the stoker has its bar", "job stoker"), ("a lookout's jump moves the cart", "job lookout | jumps the cart made: 1 | stoke replies: 0 | flares thrown: 0 | bar false"), ("no lookout errors", "client errors C: 0"), ("no crew errors on the client", "client errors B: 0"), ("no crew errors on the server", "server errors: 0")]),
    ("trophy_test.py", [("empty cases say how to earn them", "cases at the start: <> gate1=??? / BEAT THE ROOT WARDEN ; gate2=??? / BEAT THE KILN GOLEM ; Ouro=??? / HATCH A MYTHIC PET ; Ninering=??? / HATCH A SECRET PET"), ("a Common hatch fills nothing", "after a Common hatch: <>"), ("a Secret hatch fills its case", "after a Secret hatch: <Ninering>"), ("a beaten boss fills its case", "gate1=ROOT WARDEN [figure]"), ("the server ignores a client that fills its own cases", "| <gate1,Ninering>"), ("no trophy errors", "client errors: 0")]),
    ("townfill_test.py", [("the town is lit right after a join", "just after the join: fill 100 ambient 210,158,110 | lit: True"), ("the town's own ambient comes back", "25 s later: fill 0 ambient 26,22,48"), ("the caves are filled on arrival", "in the caves: fill 100 ambient 175,180,150"), ("the caves' own ambient comes back", "in the caves, 15 s later: fill 0 ambient 40,32,60"), ("the town is filled on a return", "back in town: fill 100 ambient 210,158,110"), ("the fill ends after a return", "15 s later: fill 0 ambient 26,22,48")]),
    ("menu_test.py", [("the buttons are folded behind MENU and one timer pill shows", "at the start: buttons false attr false | timer boxes showing 1 | list false"), ("MENU opens the buttons", "MENU clicked: buttons true"), ("no overlap with the menu open", "overlaps with the menu open: 0 overlaps, 0 prompt overlaps"), ("using a button folds the menu", "BAG used: buttons false"), ("the timers pill opens its list", "timers pill clicked: buttons false attr false | timer boxes showing 2 | list true"), ("no overlap with the list open", "overlaps at rest: 0 overlaps, 0 prompt overlaps")]),
    ("chime_test.py", [("the chimes wake with an order of three", "woken: True | three crystals in the order: True"), ("a wrong crystal ends the try", "the second crystal first: miss:"), ("three in order pay 90 coins", "in order: hit hit done:90"), ("the chimes rest after a win", "again at once: cool:10"), ("no chime errors", "server errors: 0")]),
    ("codex_test.py", [("codex luck steps at a quarter, half and all", "luck at 0, a quarter less one, a quarter, half, all: 0 0 0.05 0.1 0.2 | odds with 20% add up to 100.00 epic 12.0"), ("an empty codex at the start", "at the start: luck 0 | lit 0 | FOUND 0 OF"), ("a hatched pet is kept", "a pet hatched: luck 0 | lit 1 | FOUND 1 OF"), ("a quarter found gives 5% luck on the odds panel", "a quarter found: luck 5 | lit Q | FOUND Q OF"), ("the odds panel names the codex luck", "CODEX +5%"), ("K opens the codex", "K opens the gallery: true")]),
    ("marquee_test.py", [("no banner for a Common hatch", "a Common hatch: false"), ("everyone is told of a Secret hatch", "a Secret hatch: true"), ("the banner names the pet", "HATCHED A SECRET  NINERING!"), ("the banner leaves", "gone after its time: visible false"), ("the banner overlaps nothing", "marquee up: 0 overlaps, 0 prompt overlaps")]),
    ("retention_test.py", [("gift pill counts down", "pills at the start: NEXT GIFT"), ("no gift before its time", "claim with nothing due: ?"), ("a due gift is paid once", "claim again at once: coins:150"),
        ("gifts are paid in order", "two claims at 21 minutes: coins:150 flares:2 gems:10"), ("bad messages pay nothing", "bad messages: coins:150 flares:2 gems:10"), ("golden surge doubles the zone", "zone doubled: True"),
        ("event pill shows the surge", "GOLD SURGE ON"), ("friends are counted", "board: 2/5 FRIENDS HERE / +15% ORE VALUE  +20% EGG LUCK"), ("friends luck keeps the odds at 100", "egg odds, 2 friends: 57.00 25.00 12.00 4.80 1.08 0.12 sum 100.00 | none: 60.00 25.00 10.00 4.00 0.90 0.10 | 99 friends: 0.15 0.10 60.00"), ("the odds panel shows the friends luck", "odds panel, 2 friends: 57% 12% 4.8% 1.08% 0.12% / FRIENDS LUCK ON:  EPIC AND BETTER +20%"), ("rift is off by default", "rift off: 1 in the Clay Caves, 1 in Camp 1"), ("rift triples Clay Caves ore only", "rift on: 3 in the Clay Caves, 1 in Camp 1"), ("rift crystal shows", "crystal: true"), ("refinery refuses without a geode", "refinery, no geode: none"), ("refinery starts once", "refinery, a geode in, pressed again: none start | none start wait"), ("refinery pays once", "refinery, done: none start wait paid"), ("a geode cracked on the seam is perfect", "geode crack, on the seam: done perfect 5 30"), ("a geode cracked at once is bad", "geode crack, pressed at once: done bad 1 15"), ("no geode, no crack", "geode crack, no geode: none nil nil nil"), ("refinery is empty after", "refinery, empty again: none start wait paid none"), ("refinery refuses from far away", "refinery, pressed from far away: none start wait paid none" + chr(10)), ("no client errors", "client errors: 0"), ("no server errors", "server errors: 0")]),
    ("verify_night.py", [("wind-up dodge", "after stepping away 100"), ("way home embers", "(PASS over 0), at camp 0 (PASS 0)")]),
]
# which source files each test exercises (src names without .luau); the quick mode picks tests by these
COVER = {
    "wheel_test.py": ["UtilityWheel", "Sonar", "WardrobeUI", "DiegeticHUD"], "wheel_touch_test.py": ["UtilityWheel", "WardrobeUI"],
    "load_test.py": ["LoadingScreen", "JellyText"], "spatial_click_test.py": ["SpatialWorldUI", "ForgeUI"], "ar_click_test.py": ["ARSettings"],
    "touch_test.py": ["TouchControls", "DiegeticHUD", "UtilityWheel"], "opts_test.py": ["ARSettings", "GlassLift"], "pet_test.py": ["PetJobs", "PetCompanion"],
    "boon_test.py": ["BoonShrine", "BoonUI"], "ping_test.py": ["Ping", "PingRelay"], "travel_test.py": ["Travel", "Hearth", "GlassLift", "CampChoice", "ClayCaves", "ClayClient"],
    "boss_atk_test.py": ["Boss", "BossClient"], "boss_fight_test.py": ["Boss", "BossClient", "CaveBuilder", "DailyChestUI", "MiningReticle"],
    "camp2_test.py": ["ClayCaves", "ClayClient"], "crew_test.py": ["MinecartEscape", "EscapeHUD"], "trophy_test.py": ["Trophies", "HubBuilder"],
    "townfill_test.py": ["TownFill"], "menu_test.py": ["HudCompact", "RetentionTimers", "UpgradeTracker"], "chime_test.py": ["CrystalChimes", "ClayCaves"], "codex_test.py": ["CodexUI"], "marquee_test.py": ["Marquee"], "retention_test.py": ["Retention", "RetentionTimers", "LanternTether", "CaveEvents", "ClayCaves", "GeodeCrack"],
    "verify_night.py": ["MiningReticle", "Juice", "VoxelFractureFX", "CaveBuilder"],
}
SMOKE = ["load_test.py", "opts_test.py", "marquee_test.py"]  # short, and between them they load every script on both sides
CORE = {"PixelClient.client", "PixelServer.server", "Config"}  # touch everything: in quick mode they only add the smoke set
import json, time
args = sys.argv[1:]
quick = bool(args) and args[0] == "quick"
last_file, times_file = here / ".last_full", here / ".test_times.json"
todo = TESTS
if quick:
    def git(*a): return subprocess.run(["git", *a], capture_output=True, text=True, cwd=here.parent).stdout
    since = last_file.read_text().strip() if last_file.exists() else "HEAD"
    quick_file = here / ".last_quick"  # the commit of the last quick run that passed: nothing older needs testing again
    if quick_file.exists():
        q = quick_file.read_text().strip()
        if q and subprocess.run(["git", "merge-base", "--is-ancestor", since, q], cwd=here.parent).returncode == 0: since = q
    changed = set()
    for line in (git("diff", "--name-only", since) + git("status", "--porcelain")).splitlines():
        name = line.strip().split()[-1] if line.strip() else ""
        if name.startswith("src/") and name.endswith(".luau"): changed.add(pathlib.Path(name).stem)
    pick = set(SMOKE)
    for script, files in COVER.items():
        if changed & set(files): pick.add(script)
    for word in args[1:]:
        pick |= {script for script, _ in TESTS if word in script}
    uncovered = sorted(c for c in changed - CORE if not any(c in f for f in COVER.values()))
    todo = [t for t in TESTS if t[0] in pick]
    print("quick run since", since[:8], "| changed:", " ".join(sorted(changed)) or "nothing", flush=True)
    if uncovered: print("no test covers:", " ".join(uncovered), "(write one, or name a test)", flush=True)
    if changed & CORE and len(args) == 1: print("PixelClient, PixelServer or Config changed and no test was named: only the smoke set covers them", flush=True)
    print("tests:", " ".join(t[0] for t in todo), flush=True)
times = json.loads(times_file.read_text()) if times_file.exists() else {}
def run_test(script):
    night.play(False)
    t = time.time()
    r = subprocess.run([sys.executable, str(here / script)], capture_output=True, text=True, encoding="utf-8", errors="replace")
    times[script] = round(time.time() - t)
    return (r.stdout or "") + (r.stderr or "")
bad = 0
for script, checks in todo:
    out = run_test(script)
    if any(n not in out for _, n in checks):  # once more by itself before it counts
        print("   retry " + script + " (first tail: " + " | ".join(out.strip().splitlines()[-3:])[:300] + ")", flush=True)
        out = run_test(script)
    for what, needle in checks:
        ok = needle in out
        bad += 0 if ok else 1
        print(("PASS  " if ok else "FAIL  ") + script + ": " + what, flush=True)
    if any(n not in out for _, n in checks): print("   tail: " + " | ".join(out.strip().splitlines()[-6:])[:900])
times_file.write_text(json.dumps(times, indent=1))
night.play(True)
time.sleep(4)
ERR = "local t={} for _,m in game:GetService('LogService'):GetLogHistory() do if m.messageType==Enum.MessageType.MessageError then t[string.sub(m.message,1,160)]=true end end local e={} for k in t do if not string.find(k,'Requester does not have permission') then table.insert(e,k) end end return #e..' '..table.concat(e,' ## ')"
for w in ("Client", "Server"):
    line = night.lua(ERR, w).splitlines()[-1]
    ok = line.startswith("0")
    bad += 0 if ok else 1
    print(("PASS  " if ok else "FAIL  ") + f"{w} log has no game errors" + ("" if ok else ": " + line))
night.play(False)
if bad == 0 and quick and not subprocess.run(["git", "status", "--porcelain", "src"], capture_output=True, text=True, cwd=here.parent).stdout.strip():
    (here / ".last_quick").write_text(subprocess.run(["git", "rev-parse", "HEAD"], capture_output=True, text=True, cwd=here.parent).stdout.strip())  # only a clean tree: uncommitted work was tested, but HEAD does not hold it
if bad == 0 and not quick:
    last_file.write_text(subprocess.run(["git", "rev-parse", "HEAD"], capture_output=True, text=True, cwd=here.parent).stdout.strip())
print(("ALL PASS" if bad == 0 else f"{bad} FAILED") + (" (quick: %d of %d tests)" % (len(todo), len(TESTS)) if quick else ""))
