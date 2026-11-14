"""Record the whole game as one video in the player's real view, with the systems of 2026-11-13 added to loop_rec2.py:
the loading logo, the town HUD, bag, Tab wheel, look-around settings, forge; the ride down; the
hearthstone (HOME); a root zipline; Perfect Strike and Vein Rush; a whole Root Warden fight (banner, glass bar, slam, sweep,
rings, reward chest); the glass lift to the Clay Caves; the Jar Gallery, the Fossil Dig with the hammer, a Kiln Surge; the
choice of camp in town; the ride to Camp 2 and the minecart escape. Studio open in Edit mode and in front.
    python spike/loop_rec3.py <name>     video: captures/loop/<name>.mp4, sheets: <workspace>/Overnight/judge/loop_<name>/
Shortcuts (say so to a grader): keys pressed by the script, teleports by the server between places, the camera turned by
script, strikes sent through the remote when the needle crosses the gold, an autopilot that fights the boss (it jumps, steps
aside and stands in the gaps by moving its own character), Dev attributes (DevPet, DevWheel, DevEquip, DevBoss, DevClay,
DevSurge), the reward chest closed by script."""
import pathlib, re, subprocess, sys, time
here = pathlib.Path(__file__).resolve().parent
game, ws = here.parent, here.parent.parent.parent
sys.path.insert(0, str(here))
import night as N
name = sys.argv[1] if len(sys.argv) > 1 else "loop3"
VENV = r"C:\Users\kgsat\Documents\Roblox\Hunyuan3D\.venv\Scripts\python.exe"
video = game / "captures" / "loop" / f"{name}.mp4"; video.parent.mkdir(parents=True, exist_ok=True)
sheets = ws / "Overnight" / "judge" / f"loop_{name}"; sheets.mkdir(parents=True, exist_ok=True)
SECS = 380
PILOT = re.search(r"PILOT = r'''(.*?)'''", (here / "boss_fight_test.py").read_text(encoding="utf-8"), re.S).group(1)


def S(code): return (N.lua(code, "Server").splitlines() or ["?"])[-1]
def C(code): return (N.lua(code, "Client").splitlines() or ["?"])[-1]
def key(k, wait): N.key(k); time.sleep(wait)
def look(expr): C("local C=require(game.ReplicatedStorage.Shared.Config) local O=C.CAVE2_ORIGIN local cv=workspace.Caves local cam=workspace.CurrentCamera cam.CFrame=CFrame.lookAt(cam.CFrame.Position," + expr + ") return 1")


P = "local p=game.Players:GetPlayers()[1] local h=p.Character.HumanoidRootPart local cv=workspace.Caves local C=require(game.ReplicatedStorage.Shared.Config) local O=CFrame.new(C.CAVE2_ORIGIN) "
ZIP = "local pr for _,d in workspace.Caves.Ziplines:GetDescendants() do if d:GetAttribute('Zip')==1 then pr=d end end "
N.play(False); N.restore()
if video.exists(): video.unlink()
rec = subprocess.Popen([VENV, "-I", str(ws / "tools" / "record_window.py"), str(video), str(SECS), "20"], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
t0 = time.time()
def mark(what): print(f"{time.time() - t0:5.0f} s  {what}", flush=True)
time.sleep(1.5)
mark("Play starts: the loading logo")
N.run("start_stop_play", {"is_start": True}); time.sleep(10)
S("game.Players:GetPlayers()[1]:SetAttribute('DevPet','Shinemane') return 1")
mark("town HUD"); time.sleep(2.5)
# no daily chest here: a chest closed by script stays "busy" and the boss's reward chest (the same 3D chest) would not open
mark("bag"); key("B", 2.5); key("B", 0.8)
mark("Tab wheel"); key("Tab", 2.5); key("Tab", 0.8)
mark("settings: middle, left, right"); key("N", 3); key("A", 2); key("D", 1); key("D", 2); key("N", 1.2)
mark("forge"); key("G", 4); key("G", 1.5)
mark("Q: ride down"); key("Q", 30)
mark("arrival at Camp 1")
S(P + ZIP + "h.CFrame=CFrame.new(pr.Parent.Position+Vector3.new(-6,0,-9)) return 1"); time.sleep(2)
mark("HOME on the wheel: the hearthstone hold")
C("local p=game.Players.LocalPlayer p:SetAttribute('DevWheel',nil) p:SetAttribute('DevWheel',4) return 1"); time.sleep(6)
mark("root zipline")
S(P + ZIP + "h.CFrame=CFrame.new(pr.Parent.Position+Vector3.new(-5,0,-6)) return 1"); time.sleep(1.2)
C(ZIP + "local cam=workspace.CurrentCamera cam.CFrame=CFrame.lookAt(cam.CFrame.Position,pr.Parent.Position+Vector3.new(0,2,5)) return 1"); time.sleep(2)
S(P + ZIP + "h.CFrame=CFrame.new(pr.Parent.Position+Vector3.new(-3,0,0)) return 1"); time.sleep(0.8)
C(ZIP + "local cam=workspace.CurrentCamera cam.CFrame=CFrame.lookAt(cam.CFrame.Position,pr.Parent.Position) task.wait(0.4) pr:InputHoldBegin() task.wait(0.1) pr:InputHoldEnd() task.wait(0.3) "
        "local r=pr.Parent.Parent:FindFirstChild('ZipRope') cam.CFrame=CFrame.lookAt(cam.CFrame.Position,r:GetAttribute('ZipB')) return 1"); time.sleep(5)
mark("minigames (mg_night.py: strike, then rush)")
S(P + "h.CFrame=cv:FindFirstChild('LiftLanding',true).CFrame+Vector3.new(0,3,0) return 1"); time.sleep(1.5)
subprocess.run([sys.executable, str(here / "mg_night.py"), "loop_" + name], capture_output=True, text=True, cwd=here)
time.sleep(2)
mark("Root Warden: the whole fight by autopilot")
S(P + "p:SetAttribute('DevEquip',6) local w=cv:FindFirstChild('Warden',true) local o=w.PrimaryPart.Position local d=Vector3.new(math.cos(math.rad(315)),0,math.sin(math.rad(315))) "
      "local rp=RaycastParams.new() rp.FilterDescendantsInstances={w,p.Character} rp.FilterType=Enum.RaycastFilterType.Exclude local hit=workspace:Raycast(o+d*10+Vector3.new(0,6,0),Vector3.new(0,-14,0),rp) "
      "h.AssemblyLinearVelocity=Vector3.zero h.CFrame=CFrame.lookAt(hit.Position+Vector3.new(0,3,0),Vector3.new(o.X,hit.Position.Y+3,o.Z)) return 1"); time.sleep(1.5)
look("cv:FindFirstChild('Warden',true).PrimaryPart.Position")
C(PILOT)
# the camera keeps looking at the boss and the floor before it through the fight
C("local RS=game:GetService('RunService') local w=workspace.Caves:FindFirstChild('Warden',true) local cam=workspace.CurrentCamera _G.BossLook=RS.RenderStepped:Connect(function() "
  "local to=w.PrimaryPart.Position-Vector3.new(0,2.5,0) local cf=CFrame.lookAt(cam.CFrame.Position,to) cam.CFrame=cam.CFrame:Lerp(cf,0.08) end) return 1")
S(P + "p:SetAttribute('DevBoss',1) return 1")
for _ in range(45):
    time.sleep(2)
    log = C("return tostring(game.Players.LocalPlayer:GetAttribute('DevBossLog'))")
    if "bossWin" in log or "bossLose" in log: break
mark("fight over: " + log.strip()[-60:])
C("if _G.BossLook then _G.BossLook:Disconnect() end return 1")
time.sleep(9)  # the reward chest opens 2.2 s after the win
C("game.Players.LocalPlayer.PlayerGui.DailyChest.Enabled=false return 1"); time.sleep(0.6)
mark("glass lift down to the Clay Caves")
S(P + "h.CFrame=cv:FindFirstChild('LiftLanding',true).CFrame+Vector3.new(0,3,0) task.wait(1) p:SetAttribute('DevClay',2) return 1"); time.sleep(17)
mark("Camp 2: the hall, the Jar Gallery, the Fossil Dig")
look("O+Vector3.new(30,10,-40)"); time.sleep(3)
S(P + "h.CFrame=O*CFrame.new(11,3,-46) return 1"); time.sleep(0.8); look("O+Vector3.new(11,8,-90)"); time.sleep(3)
S(P + "h.CFrame=O*CFrame.new(11,3,-64) return 1"); time.sleep(0.8); look("O+Vector3.new(14,7,-100)"); time.sleep(4)
S(P + "h.CFrame=O*CFrame.new(52,3,-44) return 1"); time.sleep(0.8); look("O+Vector3.new(55,14,-100)"); time.sleep(3.5)
S(P + "h.CFrame=O*CFrame.new(50,3,-66) return 1"); time.sleep(0.8); look("O+Vector3.new(56,12,-100)"); time.sleep(4.5)
mark("Kiln Surge")
S("workspace:SetAttribute('DevSurge',20) return 1"); time.sleep(1)
S(P + "h.CFrame=O*CFrame.new(30,3,-12) return 1"); time.sleep(0.8); look("O+Vector3.new(38,6,-26)"); time.sleep(5)
mark("back in town: choose your camp")
S(P + "p:SetAttribute('InCave',false) h.CFrame=workspace.Hub:FindFirstChild('HubCart',true):GetPivot()+Vector3.new(6,5,0) return 1"); time.sleep(3)
key("Q", 4)
mark("picked Camp 2: the ride")
C("local g=game.Players.LocalPlayer.PlayerGui local w=g:FindFirstChild('CampChoice',true) if w then w.Visible=false end game.ReplicatedStorage.Remotes.Surface:FireServer('down',2) return 1"); time.sleep(12)
key("Q", 0); mark("Q: escape ride")
left = SECS - (time.time() - t0)
mark(f"{left:.0f} s of recording left")
time.sleep(max(left + 4, 4))
print(rec.communicate(timeout=240)[0][-300:])
print("client errors:", C("local t={} for _,m in game:GetService('LogService'):GetLogHistory() do if m.messageType==Enum.MessageType.MessageError and not string.find(m.message,'Requester') then t[string.sub(m.message,1,140)]=true end end local e={} for k in t do table.insert(e,k) end return #e..' '..table.concat(e,' | ')"))
N.play(False)
r = subprocess.run([VENV, "-I", str(ws / "tools" / "video_sheets.py"), str(video), str(sheets), "3"], capture_output=True, text=True)
print([l for l in r.stdout.splitlines() if l.startswith("wrote")][-3:])
