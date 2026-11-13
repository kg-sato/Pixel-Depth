"""Record the whole game as one video in the player's real view, with every feature of the glass and jelly pass (2026-11-13):
the loading logo, the town HUD, the daily chest, the bag, the Tab wheel, the look-around settings (left, middle, right),
the forge, then the core loop of loop_rec.py (ride down with the arrival banner, Perfect Strike, Vein Rush, a combo, the pet
mood mark, a shrine, Gloomlings, the escape ride with its result). Studio open in Edit mode and in front.
    python spike/loop_rec2.py <name>     video: captures/loop/<name>.mp4, sheets: <workspace>/Overnight/judge/loop_<name>/
Shortcuts (say so to a grader): keys pressed by the script, teleports to the deposits and the shrine, strikes sent through the
remote when the needle crosses the gold, Dev attributes (DevCombo, DevBanked, DevTorchAge, DevPet), the chest fired by hand."""
import pathlib, subprocess, sys, time
here = pathlib.Path(__file__).resolve().parent
game, ws = here.parent, here.parent.parent.parent
name = sys.argv[1] if len(sys.argv) > 1 else "loop2"
VENV = r"C:\Users\kgsat\Documents\Roblox\Hunyuan3D\.venv\Scripts\python.exe"
video = game / "captures" / "loop" / f"{name}.mp4"; video.parent.mkdir(parents=True, exist_ok=True)
sheets = ws / "Overnight" / "judge" / f"loop_{name}"; sheets.mkdir(parents=True, exist_ok=True)
SECS = 300


def night(*a): return (subprocess.run([sys.executable, str(here / "night.py"), *a], capture_output=True, text=True).stdout.strip().splitlines() or ["?"])[-1]


def key(k, wait): night("key", k); time.sleep(wait)


P = "local p=game.Players:GetPlayers()[1] local h=p.Character.HumanoidRootPart "
if video.exists(): video.unlink()
rec = subprocess.Popen([VENV, "-I", str(ws / "tools" / "record_window.py"), str(video), str(SECS), "20"], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
t0 = time.time()
def mark(what): print(f"{time.time() - t0:5.0f} s  {what}", flush=True)
time.sleep(1.5)
mark("Play starts: the loading logo")
night("play"); time.sleep(9)
night("lua", "Server", "game.Players:GetPlayers()[1]:SetAttribute('DevPet','Shinemane') return 1")
mark("town HUD"); time.sleep(3)
night("lua", "Server", "game.ReplicatedStorage.Remotes.Fx:FireClient(game.Players:GetPlayers()[1],'dailyChest',120,3,4) return 1"); mark("daily chest"); time.sleep(5.5)
night("lua", "Client", "game.Players.LocalPlayer.PlayerGui.DailyChest.Enabled=false return 1"); time.sleep(0.6)  # the script cannot press COLLECT: the chest layer is switched off
mark("bag"); key("B", 3); key("B", 1)
mark("quests"); key("J", 3); key("J", 1)
mark("Tab wheel"); key("Tab", 3); key("Tab", 1)
mark("settings: middle, left, right"); key("N", 3.5); key("A", 2.5); key("D", 1.2); key("D", 2.5); key("N", 1.5)
mark("forge"); key("G", 5); key("G", 2)
mark("Q: ride down"); key("Q", 30)
mark("arrival at Camp 1; H inspects the pickaxe"); time.sleep(3); key("H", 2.5)
night("lua", "Client", "game.Players.LocalPlayer:SetAttribute('DevCombo',9) return 1"); mark("combo counter"); time.sleep(2.5)
mark("minigames (mg_night.py: strike, then rush)")
subprocess.run([sys.executable, str(here / "mg_night.py"), "loop_" + name], capture_output=True, text=True, cwd=here)
time.sleep(3)
night("lua", "Server", P + "local s=workspace.Caves:FindFirstChild('LostLanternSpot',true) h.CFrame=CFrame.new(s.Position+Vector3.new(5,3,5), s.Position) return 1"); mark("teleport: shrine"); time.sleep(6)
night("lua", "Server", P + "p:SetAttribute('DevBanked',true) p:SetAttribute('DevTorchAge',900) return 1"); mark("torch aged: Gloomlings come"); time.sleep(24)
night("lua", "Server", P + "local l=workspace.Caves:FindFirstChild('LiftLanding',true) h.CFrame=l.CFrame+Vector3.new(0,3,0) return 1"); mark("teleport: camp"); time.sleep(5)
key("Q", 0); mark("Q: escape ride")
left = SECS - (time.time() - t0)
mark(f"{left:.0f} s of recording left")
time.sleep(max(left + 4, 4))
print(rec.communicate(timeout=180)[0][-300:])
print("client errors:", night("lua", "Client", "local t={} for _,m in game:GetService('LogService'):GetLogHistory() do if m.messageType==Enum.MessageType.MessageError and not string.find(m.message,'Requester') then t[string.sub(m.message,1,140)]=true end end local e={} for k in t do table.insert(e,k) end return #e..' '..table.concat(e,' | ')"))
night("stop")
r = subprocess.run([VENV, "-I", str(ws / "tools" / "video_sheets.py"), str(video), str(sheets), "3"], capture_output=True, text=True)
print([l for l in r.stdout.splitlines() if l.startswith("wrote")][-3:])
