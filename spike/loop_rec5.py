"""Record the whole game as one video in the player's real view. loop_rec4.py plus directive v10 (2026-11-14 night): the MENU
fold and the one timers pill, the Geode Timing Crack, the Codex, the Crystal Resonance Chimes, the reworked Root Warden seen
from the side away from the camp tent. loop_rec4.py was loop_rec3.py plus the systems of 2026-11-14: the mining
loading screen, the kiln by the Forge, the egg odds with friends luck, the trophy cases and the hatch banner, and a crew ride
seen from the stoker's seat (steam, flares, crew moments, the crew card). From loop_rec3.py:
the loading logo, the town HUD, bag, Tab wheel, look-around settings, forge; the ride down; the
hearthstone (HOME); a root zipline; Perfect Strike and Vein Rush; a whole Root Warden fight (banner, glass bar, slam, sweep,
rings, reward chest); the glass lift to the Clay Caves; the Jar Gallery, the Fossil Dig with the hammer, a Kiln Surge; the
choice of camp in town; the ride to Camp 2 and the minecart escape. Studio open in Edit mode and in front.
    python spike/loop_rec5.py <name>     video: captures/loop/<name>.mp4, sheets: <workspace>/Overnight/judge/loop_<name>/
Shortcuts (say so to a grader): keys pressed by the script, teleports by the server between places, the camera turned by
script, strikes sent through the remote when the needle crosses the gold, an autopilot that fights the boss (it jumps, steps
aside and stands in the gaps by moving its own character), Dev attributes (DevPet, DevWheel, DevEquip, DevBoss, DevClay,
DevSurge, DevRift, DevGold, DevGiftSecs, DevGeodes, DevFriends, DevMarquee, DevCrewBot, DevCodex), the MENU and timers pill clicked by
script, the geode press and the chime strikes timed by script, the sale shown by firing its effect by
hand, the reward chest closed by script. The crew ride has ONE real player: the server plays the driver, and a script presses
the stoker's key when the needle is in the gold, throws two flares and answers the crew moments."""
import os, pathlib, re, subprocess, sys, time
here = pathlib.Path(__file__).resolve().parent
game, ws = here.parent, here.parent.parent.parent
sys.path.insert(0, str(here))
import night as N
from prompt_test import trigger
name = sys.argv[1] if len(sys.argv) > 1 else "loop3"
VENV = r"C:\Users\kgsat\Documents\Roblox\Hunyuan3D\.venv\Scripts\python.exe"
video = game / "captures" / "loop" / f"{name}.mp4"; video.parent.mkdir(parents=True, exist_ok=True)
sheets = ws / "Overnight" / "judge" / f"loop_{name}"; sheets.mkdir(parents=True, exist_ok=True)
SECS = 900  # the tour grew to about 880 s (2026-11-16)
PILOT = re.search(r"PILOT = r'''(.*?)'''", (here / "boss_fight_test.py").read_text(encoding="utf-8"), re.S).group(1)


def S(code): return (N.lua(code, "Server").splitlines() or ["?"])[-1]
def C(code): return (N.lua(code, "Client").splitlines() or ["?"])[-1]
def key(k, wait): N.key(k); time.sleep(wait)
def hold_cam(eye, at, secs=7):  # v15: a camera bound after the game's own (the town camera), with the crew pets out of shot (the game's cutscenes hide them the same way)
    C("local RS=game:GetService('RunService') _G.TourN=(_G.TourN or 0)+1 local nm='TourCam'.._G.TourN game.Players.LocalPlayer:SetAttribute('HidePetsUntil',os.clock()+" + str(secs) + ") "
      "local C=require(game.ReplicatedStorage.Shared.Config) local O=C.CAVE2_ORIGIN local cv=workspace:FindFirstChild('Caves') "
      "local eye,at=" + eye + "," + at + " RS:BindToRenderStep(nm,2000,function() local c=workspace.CurrentCamera c.CameraType=Enum.CameraType.Scriptable c.CFrame=CFrame.lookAt(eye,at) end) "
      "task.delay(" + str(secs) + ",function() pcall(function() RS:UnbindFromRenderStep(nm) end) workspace.CurrentCamera.CameraType=Enum.CameraType.Custom end) return 1")
def look(expr): C("local C=require(game.ReplicatedStorage.Shared.Config) local O=C.CAVE2_ORIGIN local cv=workspace.Caves local cam=workspace.CurrentCamera cam.CFrame=CFrame.lookAt(cam.CFrame.Position," + expr + ") return 1")


P = "local p=game.Players:GetPlayers()[1] local h=p.Character.HumanoidRootPart local cv=workspace.Caves local C=require(game.ReplicatedStorage.Shared.Config) local O=CFrame.new(C.CAVE2_ORIGIN) "
ZIP = "local pr for _,d in workspace.Caves.Ziplines:GetDescendants() do if d:GetAttribute('Zip')==1 then pr=d end end "
N.play(False); N.restore()
if video.exists(): video.unlink()
rec = subprocess.Popen([VENV, "-I", str(ws / "tools" / "record_window.py"), str(video), str(SECS), "15"], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
t0 = time.time()
def mark(what): print(f"{time.time() - t0:5.0f} s  {what}", flush=True)
time.sleep(1.5)
mark("Play starts: the loading logo")
N.run("start_stop_play", {"is_start": True})
for _ in range(2):  # stills inside the logo (full1123c: the step's stills fell before Play drew or after the logo)
    if globals().get("FORCE"): FORCE.set()
    time.sleep(2.5)
time.sleep(5)
S("game.Players:GetPlayers()[1]:SetAttribute('DevPet','Shinemane') return 1")
mark("town HUD"); time.sleep(2.5)
# no daily chest here: a chest closed by script stays "busy" and the boss's reward chest (the same 3D chest) would not open
S("game.Players:GetPlayers()[1]:SetAttribute('DevGiftSecs',301) return 1"); mark("playtime gift ready: Y claims it"); time.sleep(3); key("Y", 3)
S(P + "local st for _,d in workspace.Hub:GetDescendants() do if d:IsA('BasePart') and d:GetAttribute('Station')=='sell' then st=d end end h.CFrame=CFrame.new(st.Position+Vector3.new(6,3,6)) task.wait(2) game.ReplicatedStorage.Remotes.Fx:FireClient(p,'sold',120,0,{['1.1']=5,['1.2']=3}) return 1")
mark("sell fountain"); time.sleep(3.5)
NAME = C("return game.Players.LocalPlayer.Name")
def click(path): N.run("user_mouse_input", {"actions": [{"action": "mouseButtonClick", "mouse_button": "left", "instance_path": "Players." + NAME + ".PlayerGui.PixelHUD." + path}], "datamodel_type": "Client"})
mark("MENU folds the buttons away; the one timers pill drops its list")
click("LeftColumn.Currency.MenuButton.Hit"); time.sleep(2.2); click("LeftColumn.Currency.MenuButton.Hit"); time.sleep(0.6)
click("Timers.Main.Open"); time.sleep(2.4); click("Timers.Main.Open"); time.sleep(0.4)
N.run("user_mouse_input", {"actions": [{"action": "moveTo", "x": 300, "y": 500}], "datamodel_type": "Client"}); time.sleep(0.5)
S(P + "p:SetAttribute('DevGeodes',2) local m=workspace.Hub:FindFirstChild('RefineryMouth') h.CFrame=CFrame.lookAt(m.Position+m.CFrame.LookVector*3.5+Vector3.new(0,2,0),m.Position) return 1"); mark("the refinery: a geode goes in"); time.sleep(2.5)
C("local pr=workspace.Hub.RefineryMouth:FindFirstChildOfClass('ProximityPrompt') local cam=workspace.CurrentCamera cam.CFrame=CFrame.lookAt(cam.CFrame.Position,pr.Parent.Position) task.wait(0.5) pr:InputHoldBegin() task.wait(0.15) pr:InputHoldEnd() return 1"); time.sleep(4)
mark("the crucible: the geode melts in the open pot; one stir takes 5 s off")  # v15 (Master Directive phase 3)
CRU = "workspace.Hub:FindFirstChild('CrucibleMelt',true)"
hold_cam(f"({CRU}.CFrame*CFrame.new(1.5,6,-8)).Position", f"{CRU}.Position", 8); time.sleep(2.5)
if globals().get("FORCE"): FORCE.set()
C("local pt=workspace.Hub:FindFirstChild('CrucibleStirPoint',true) local pr=pt:FindFirstChildOfClass('ProximityPrompt') task.wait(0.2) pr:InputHoldBegin() task.wait(0.15) pr:InputHoldEnd() return 1"); time.sleep(0.6)
if globals().get("FORCE"): FORCE.set()  # the stir's spark burst
time.sleep(4)
mark("Geode Timing Crack on the workbench: one press on the gold ring")
S(P + "local an=workspace.Hub.Forge:FindFirstChild('Bench',true) local away=((an.Position-workspace.Hub.Forge:FindFirstChild('Anvil',true).Position)*Vector3.new(1,0,1)).Unit h.CFrame=CFrame.lookAt(an.Position+away*3+Vector3.new(0,3,0),an.Position) return 1"); time.sleep(2)
C("task.spawn(function() local RS=game.ReplicatedStorage local Cf=require(RS.Shared.Config) local t0 local c=RS.Remotes.Fx.OnClientEvent:Connect(function(k,w,a) if k=='crack' and w=='start' then t0=a end end) "
  "local pr for _,d in workspace.Hub.Forge:GetDescendants() do if d:IsA('ProximityPrompt') and d:GetAttribute('GeodeCrack') then pr=d end end local cam=workspace.CurrentCamera cam.CFrame=CFrame.lookAt(cam.CFrame.Position,pr.Parent.Position) "
  "task.wait(0.6) pr:InputHoldBegin() task.wait(0.1) pr:InputHoldEnd() local t=os.clock() while os.clock()-t<2 and not t0 do task.wait() end if t0 then while workspace:GetServerTimeNow()<Cf.crackAt(t0) do task.wait() end RS.Remotes.Crack:FireServer() end c:Disconnect() end) return 1"); time.sleep(1.2)
if globals().get("FORCE"): FORCE.set()  # the crack ring shows for about 1.5 s: take a still inside it (full1123a missed it)
time.sleep(4.3)
S(P + "p:SetAttribute('DevFriends',2) local sp=workspace.Hub.Incubator:FindFirstChild('SignPost',true) h.CFrame=CFrame.new(sp.Position+Vector3.new(4,3,4)) return 1"); mark("egg odds with two friends in the server"); time.sleep(2.5)
# the odds panel is opened by script (its prompt shares the spot with the egg stall's card)
C("local o=game.Players.LocalPlayer.PlayerGui:FindFirstChild('Odds',true) o.Visible=true local sc=o:FindFirstChildOfClass('UIScale') if sc then sc.Scale=1 end return 1"); time.sleep(5.5)
C("game.Players.LocalPlayer.PlayerGui:FindFirstChild('Odds',true).Visible=false return 1"); time.sleep(1)
S(P + "p:SetAttribute('DevFriends',nil) return 1")
mark("the trophy cases, all empty; a Secret hatch fills one and everyone in the server is told")
S(P + "local g for _,d in workspace.Hub.TrophyHouse:GetChildren() do if d.Name=='TrophyGlass' and d:GetAttribute('Trophy')=='gate1' then g=d end end h.CFrame=g.CFrame*CFrame.new(14,0,9) return 1"); time.sleep(1.5)  # full1122h: standing at (6.9, 0, 12) the miner's back filled the trophy shot
C("local g for _,d in workspace.Hub.TrophyHouse:GetChildren() do if d.Name=='TrophyGlass' and d:GetAttribute('Trophy')=='gate1' then g=d end end local cam=workspace.CurrentCamera local t=os.clock() local cur local RS=game:GetService('RunService') game.Players.LocalPlayer:SetAttribute('HidePetsUntil',os.clock()+12) "  # v15: this camera is bound after PixelClient's, whose town pet ghosting measures its own high camera, so the crew stood opaque 9 studs from this lens (full1123e 267s); the game's cutscenes hide the crew the same way
  "RS:BindToRenderStep('tourcam',2000,function() local u=os.clock()-t if u>11 then RS:UnbindFromRenderStep('tourcam') return end "
  "local far=true cur=(cur or cam.CFrame):Lerp(CFrame.lookAt((g.CFrame*CFrame.new(far and 6.9 or 18.1,far and 5 or 1.6,far and 20 or 6.5)).Position,(g.CFrame*CFrame.new(far and 6.9 or 18.1,far and -0.6 or 0.1,0)).Position),0.1) cam.CFrame=cur end) return 1"); time.sleep(4)
S(P + "p:SetAttribute('DevMarquee','Ninering') return 1"); time.sleep(8)
mark("the Deep Chronicle: the miners of this server on a stone in town")  # v15 (Master Directive phase 3)
S(P + "local s=workspace.Hub.Chronicle.ChronicleSlab h.CFrame=CFrame.lookAt((s.CFrame*CFrame.new(1.5,-5.4,8)).Position,(s.CFrame*CFrame.new(0,-5.4,0)).Position) return 1"); time.sleep(1.5)
hold_cam("(workspace.Hub.Chronicle.ChronicleSlab.CFrame*CFrame.new(-4,1.5,15)).Position", "workspace.Hub.Chronicle.ChronicleSlab.Position+Vector3.new(0,0.5,0)", 7); time.sleep(2.5)
if globals().get("FORCE"): FORCE.set()
time.sleep(4.5)
S(P + "p:SetAttribute('DevCodex',12) return 1"); time.sleep(1.5)
mark("the Codex: found ores and pets, and the luck they give"); key("K", 4); key("K", 0.8)
mark("bag"); key("B", 2.5); key("B", 0.8)
S(P + "p:SetAttribute('DevEquip',2) return 1"); time.sleep(1.5)  # full1122f: the wheel waits for the Stone Pickaxe (FtueGate), so the tour pressed Tab on nothing
mark("Tab wheel"); key("Tab", 2.5); key("Tab", 0.8)
mark("settings: middle, left, right"); key("N", 3); key("A", 2); key("D", 1); key("D", 2); key("N", 1.2)
# directive v13: G is the pickaxe clink away from Bolt's anvil, and the forge beside it: walk to the anvil first
S(P + "local a=workspace.Hub:FindFirstChild('Anvil',true) h.CFrame=CFrame.lookAt(a.Position+Vector3.new(3,2,4),Vector3.new(a.Position.X,a.Position.Y+2,a.Position.Z)) return 1"); time.sleep(1.5)
mark("forge"); key("G", 5); key("G", 1.5)
mark("HEAT & BLOW: a new pickaxe, its forging scene and a strike in the gold")  # v15 (Master Directive phase 4); the press is sent by script when the needle is in the gold
S(P + "p:SetAttribute('DevGold',5000) p:SetAttribute('DevOres',60) return 1"); time.sleep(1.2)
C("_G.HT={} local R=game.ReplicatedStorage.Remotes R.Heat.OnClientEvent:Connect(function(k,id,a) if k=='start' then _G.HT.start=a _G.HT.id=id end end) R.Buy:FireServer('pick') "
  "task.spawn(function() local Cf=require(game.ReplicatedStorage.Shared.Config) local t0=os.clock() while not _G.HT.start and os.clock()-t0<30 do task.wait() end if not _G.HT.start then return end "
  "task.wait(1.1) while true do local el=workspace:GetServerTimeNow()-_G.HT.start if math.abs(Cf.heatAt(el+0.05)-0.5)<0.03 or el>2.3 then break end task.wait() end R.Heat:FireServer('press',_G.HT.id) end) return 1")
for _ in range(100):
    if C("return tostring(_G.HT and _G.HT.start~=nil)") == "true": break
    time.sleep(0.2)
time.sleep(0.5)
if globals().get("FORCE"): FORCE.set()  # the HEARTH HEAT gauge
time.sleep(1.0)
if globals().get("FORCE"): FORCE.set()  # PERFECT FORGE!
time.sleep(9)
mark("a Legendary hatch: Fafnir")
C("_G.V15H=nil local PV=require(game.ReplicatedStorage.Shared.PetVoxels) if not _G.V15HP then _G.V15HP=PV.hero PV.hero=function(m) _G.V15H=os.clock() return _G.V15HP(m) end end return 1")  # v15: note when the pet lands (its showcase starts)
S("workspace:SetAttribute('DevHeroSlow',2) game.ReplicatedStorage.Remotes.Fx:FireClient(game.Players:GetPlayers()[1], 'hatch', 'Fafnir') return 1")  # the showcase at half speed so a still lands in each beat
t_h = time.time()
for _ in range(80):
    if C("return tostring(_G.V15H~=nil)") == "true": break
    time.sleep(0.15)
mark("the hatch showcase: gather, then the rear-up roar")
if globals().get("FORCE"): FORCE.set()  # beat 1, the gather
time.sleep(1.3)
if globals().get("FORCE"): FORCE.set()  # beat 2, the rear-up roar
S("workspace:SetAttribute('DevHeroSlow',nil) return 1")
time.sleep(max(1, 16.5 - (time.time() - t_h)))  # it closes itself 6 s after the burst
mark("Q: ride down"); key("Q", 30)
mark("arrival at Camp 1")
time.sleep(3)
mark("the Soul Tree at the campfire: three constellations round the shard star")  # v15 (Master Directive phase 2)
S(P + "p:SetAttribute('DevSoul',14) return 1"); time.sleep(1)
trigger("SoulTree", "true"); time.sleep(0.8)
C("local R=game.ReplicatedStorage.Remotes R.Soul:FireServer('buy','hide') task.wait(0.6) R.Soul:FireServer('buy','flare') task.wait(0.6) R.Soul:FireServer('buy','hide') task.wait(0.8) return 1"); time.sleep(1.2)
if globals().get("FORCE"): FORCE.set()
time.sleep(3)
C("local w=game.Players.LocalPlayer.PlayerGui:FindFirstChild('SoulTree',true) if w then w.Visible=false end return 1"); time.sleep(1)
S(P + "local c=cv.Spot_Camp.Value.WorldPosition h.CFrame=CFrame.lookAt(c+Vector3.new(0,3,14),c+Vector3.new(0,3,0)) return 1"); time.sleep(2)  # Cave v2: the camp spot (zip 1 is in the cathedral now)
mark("HOME on the wheel: the hearthstone hold")
C("local p=game.Players.LocalPlayer p:SetAttribute('DevWheel',nil) p:SetAttribute('DevWheel',4) return 1"); time.sleep(6)
mark("root zipline")
S(P + ZIP + "h.CFrame=CFrame.new(pr.Parent.Position+Vector3.new(-5,0,-6)) return 1"); time.sleep(1.2)
C(ZIP + "local cam=workspace.CurrentCamera cam.CFrame=CFrame.lookAt(cam.CFrame.Position,pr.Parent.Position+Vector3.new(0,2,5)) return 1"); time.sleep(2)
S(P + ZIP + "h.CFrame=CFrame.new(pr.Parent.Position+Vector3.new(-3,0,0)) return 1"); time.sleep(0.8)
C(ZIP + "local cam=workspace.CurrentCamera cam.CFrame=CFrame.lookAt(cam.CFrame.Position,pr.Parent.Position) task.wait(0.4) pr:InputHoldBegin() task.wait(0.1) pr:InputHoldEnd() task.wait(0.3) "
        "local r=pr.Parent.Parent:FindFirstChild('ZipRope') cam.CFrame=CFrame.lookAt(cam.CFrame.Position,r:GetAttribute('ZipB')) return 1"); time.sleep(5)
S("workspace:SetAttribute('DevGold',70) return 1"); mark("Golden Vein Surge: the gold zone is twice as wide")
mark("minigames (mg_night.py: strike, then rush)")
S(P + "h.CFrame=cv:FindFirstChild('LiftLanding',true).CFrame+Vector3.new(0,3,0) return 1"); time.sleep(1.5)
r = subprocess.run([sys.executable, str(here / "mg_night.py"), "loop_" + name], capture_output=True, text=True, cwd=here, env={**os.environ, "MG_DWELL": "3.5"})
print("mg_night:", " | ".join(r.stdout.splitlines()[-6:]), r.stderr[-300:])  # full1122e: the strike never showed and nothing said why
time.sleep(2)
mark("Root Warden: the whole fight by autopilot")
S(P + "p:SetAttribute('DevEquip',6) local w=cv:FindFirstChild('Warden',true) local o=w.PrimaryPart.Position local away=(w:GetPivot().LookVector*Vector3.new(1,0,1)).Unit "
      "local rp=RaycastParams.new() rp.FilterDescendantsInstances={w,p.Character} rp.FilterType=Enum.RaycastFilterType.Exclude local best "
      "for _,deg in {0,15,-15,30,-30,45,-45,60,-60,90,-90,180} do local d=CFrame.Angles(0,math.rad(deg),0):VectorToWorldSpace(away) local hit=workspace:Raycast(o+d*13+Vector3.new(0,6,0),Vector3.new(0,-14,0),rp) "
      "if hit and math.abs(hit.Position.Y-(o.Y-4))<4 then local eye=hit.Position+Vector3.new(0,4.5,0) local see=workspace:Raycast(eye,(o-eye),rp) local roof=workspace:Raycast(eye,Vector3.new(0,5,0),rp) "
      "local back=workspace:Raycast(eye,d*5,rp) local box=#workspace:GetPartBoundsInBox(CFrame.new(hit.Position+Vector3.new(0,3.2,0)),Vector3.new(3,5,3)) "
      "if not see and not roof and not back and box==0 then best=hit.Position break end end end "  # open floor, a clear line to the boss, head room and nothing behind: the first try stood inside the rock
      "if not best then local d=Vector3.new(math.cos(math.rad(315)),0,math.sin(math.rad(315))) best=workspace:Raycast(o+d*13+Vector3.new(0,6,0),Vector3.new(0,-14,0),rp).Position end "
      "h.AssemblyLinearVelocity=Vector3.zero h.CFrame=CFrame.lookAt(best+Vector3.new(0,3,0),Vector3.new(o.X,best.Y+3,o.Z)) return 1"); time.sleep(1.5)  # on the side away from the camp tent (it filled a third of the picture)
look("cv:FindFirstChild('Warden',true).PrimaryPart.Position")
C(PILOT)
# the camera keeps looking at the boss and the floor before it through the fight
C("local RS=game:GetService('RunService') local w=workspace.Caves:FindFirstChild('Warden',true) local cam=workspace.CurrentCamera _G.BossLook=RS.RenderStepped:Connect(function() "
  "local to=w.PrimaryPart.Position+Vector3.new(0,0.5,0) local cf=CFrame.lookAt(cam.CFrame.Position,to) cam.CFrame=cam.CFrame:Lerp(cf,0.08) end) return 1")
S(P + "p:SetAttribute('DevBoss',1) return 1")
reticle_seen = False
C("game.Players.LocalPlayer:SetAttribute('DevPilotWait',1.8) return 1")  # v15: the pilot waits 1.8 s on an open knot dial so the still lands before KNOT CRACKED
for _ in range(45):
    for _q in range(1 if reticle_seen else 5):
        time.sleep(2 if reticle_seen else 0.4)
        if not reticle_seen and C("local pg=game.Players.LocalPlayer.PlayerGui local g=pg:FindFirstChild('StrikeReticle') local ps=pg:FindFirstChild('PerfectStrike',true) return tostring((g~=nil and g.Enabled and g.Adornee~=nil) or (ps~=nil and ps.Visible))") == "true": break
    if not reticle_seen and C("local pg=game.Players.LocalPlayer.PlayerGui local g=pg:FindFirstChild('StrikeReticle') local ps=pg:FindFirstChild('PerfectStrike',true) return tostring((g~=nil and g.Enabled and g.Adornee~=nil) or (ps~=nil and ps.Visible))") == "true":
        reticle_seen = True  # a still while the dial sits on a knot (Orchestrator round 3: view 07 never showed the live reticle)
        mark("Root Warden: strike reticle on a knot")
        if globals().get("FORCE"): FORCE.set()
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
mark("Crystal Resonance Chimes: wake them, then strike 1, 2, 3 in order")
C("local p=game.Players.LocalPlayer p:SetAttribute('DevChime','') game.ReplicatedStorage.Remotes.Fx.OnClientEvent:Connect(function(k,w,a) if k=='chime' and w=='start' then p:SetAttribute('DevChime',table.concat(a,'')) end end) return 1")
def strike(k):
    S(P + "local c for _,d in cv:GetDescendants() do if d:IsA('BasePart') and d:GetAttribute('ChimeCrystal')==%d then c=d end end h.CFrame=CFrame.lookAt(c.Position+Vector3.new(0,1.5,4),c.Position) return 1" % k); time.sleep(0.5)
    C("local c for _,d in workspace.Caves:GetDescendants() do if d:IsA('BasePart') and d:GetAttribute('ChimeCrystal')==%d then c=d end end local pr=c:FindFirstChildOfClass('ProximityPrompt') local cam=workspace.CurrentCamera "
      "cam.CFrame=CFrame.lookAt(cam.CFrame.Position,c.Position) task.wait(0.35) pr:InputHoldBegin() task.wait(0.1) pr:InputHoldEnd() return 1" % k); time.sleep(0.9)
S("workspace:SetAttribute('DevChimeSlow', 4) return 1")  # as chime_test: a slow Studio needs ~4 s a scripted strike, or the window shut before the badges were seen (full1123c)
strike(2); time.sleep(0.4)
S(P + "h.CFrame=CFrame.lookAt((O*CFrame.new(17,3,23)).Position,(O*CFrame.new(17,3,12)).Position) return 1"); time.sleep(0.4); look("O+Vector3.new(17,2.5,12)"); time.sleep(0.5)  # v15: step back so all three numbered crystals are in the still
if globals().get("FORCE"): FORCE.set()  # a still of the woken chimes with their numbers
order = C("return tostring(game.Players.LocalPlayer:GetAttribute('DevChime'))")
print("chime order:", order, "| refused:", S("return tostring(game.Players:GetPlayers()[1]:GetAttribute('DevChimeWhy'))"), flush=True)
for ch in order if order.isdigit() else "": strike(int(ch))
time.sleep(2.5)
S("workspace:SetAttribute('DevChimeSlow', nil) return 1")
mark("Kiln Surge")
S("workspace:SetAttribute('DevSurge',20) workspace:SetAttribute('DevRift',25) return 1"); time.sleep(1)
S(P + "h.CFrame=O*CFrame.new(30,3,-12) return 1"); time.sleep(0.8); look("O+Vector3.new(38,6,-26)"); time.sleep(3); look("O+Vector3.new(6,28,-12)"); time.sleep(4)
mark("back in town: choose your camp")
S(P + "p:SetAttribute('InCave',false) h.CFrame=workspace.Hub:FindFirstChild('HubCart',true):GetPivot()+Vector3.new(6,5,0) game.ReplicatedStorage.Remotes.Fx:FireClient(p,'lift',false) return 1"); time.sleep(4)  # 'lift' makes the client switch back to the town's light and camera (without it the town stayed dark)
S(P + "h.CFrame=workspace.Hub:FindFirstChild('HubCart',true):GetPivot()+Vector3.new(6,5,0) return 1"); time.sleep(2.5)
key("Q", 4)
mark("picked Camp 2: the ride")
C("local g=game.Players.LocalPlayer.PlayerGui local w=g:FindFirstChild('CampChoice',true) if w then w.Visible=false end game.ReplicatedStorage.Remotes.Surface:FireServer('down',2) return 1"); time.sleep(12)
key("Q", 0); mark("Q: escape ride (alone)")
time.sleep(25)
for _ in range(40):
    time.sleep(2)
    if "home" in C("local p=game.Players.LocalPlayer return (not workspace:FindFirstChild('MinecartEscape') and p:GetAttribute('InCave')~=true and p:GetAttribute('Seated')==nil) and 'home' or 'riding'"): break
mark("back in town; Q and Camp 1: down again for the crew ride"); time.sleep(2); key("Q", 3)
C("local g=game.Players.LocalPlayer.PlayerGui local w=g:FindFirstChild('CampChoice',true) if w then w.Visible=false end game.ReplicatedStorage.Remotes.Surface:FireServer('down',1) return 1"); time.sleep(30)
print("in the cave for the crew ride:", S(P + "return tostring(p:GetAttribute('InCave'))"), flush=True)
S(P + "local body=cv:FindFirstChild('CartBody',true) h.CFrame=body.CFrame*CFrame.new(0,3,8) return 1"); time.sleep(1)
C("local a=workspace.Caves:FindFirstChild('CrewAnchor',true) local cam=workspace.CurrentCamera cam.CFrame=CFrame.lookAt(cam.CFrame.Position,a.Position) return 1")
mark("the crew sign over the cart"); time.sleep(3.5)
C("game.Players.LocalPlayer:SetAttribute('DevCrew',true) return 1")
S(P + "p:SetAttribute('DevCrewBot',true) return 1")
mark("crew ride from the stoker's seat: steam, two flares, two crew moments")
# the stoker's hands: press in the gold, throw two flares, answer the crew moments (a script, in place of a second person)
C("task.spawn(function() local p=game.Players.LocalPlayer local RS=game.ReplicatedStorage local C=require(RS.Shared.Config) local S=C.CREW.stoke local R=RS.Remotes.Crew "
  "R.OnClientEvent:Connect(function(k) if k=='m' then task.wait(0.6) R:FireServer('a') end end) "
  "local t=os.clock() while os.clock()-t<12 and not p:GetAttribute('DevCrewT0') do task.wait(0.1) end task.wait(5) local t0=p:GetAttribute('DevCrewT0') local start=os.clock() local flares=0 "
  "while os.clock()-start<34 and t0 do local w={} for x in string.gmatch(p:GetAttribute('DevCrewState') or '', '%S+') do w[#w+1]=x end local hits=tonumber(w[9]) or 0 "
  "local z=C.stokeZone(4242,hits) local x=C.stokeAt(t0,workspace:GetServerTimeNow()) if x>z+0.07 and x<z+S.zone-0.07 then R:FireServer('k') task.wait(0.9) end "
  "if (flares==0 and os.clock()-start>9) or (flares==1 and os.clock()-start>22) then flares+=1 R:FireServer('f') end task.wait() end end) return 1")
time.sleep(25)  # the ride is not there in the first seconds: asking at once took "no ride yet" for "home"
for _ in range(35):
    time.sleep(2)
    if "home" in C("local p=game.Players.LocalPlayer return (not workspace:FindFirstChild('MinecartEscape') and p:GetAttribute('InCave')~=true) and 'home' or 'riding'"): break
mark("crew ride over")
time.sleep(2.5)
mark("back in town after the escape card")  # v15: view 13 is this still (it duplicated the result card while it was the crew step's last)
if globals().get("FORCE"): FORCE.set()
time.sleep(3)
left = SECS - (time.time() - t0)
mark(f"{left:.0f} s of recording left")
time.sleep(max(left + 4, 4))
print(rec.communicate(timeout=900)[0][-300:])
print("client errors:", C("local t={} for _,m in game:GetService('LogService'):GetLogHistory() do if m.messageType==Enum.MessageType.MessageError and not string.find(m.message,'Requester') and not string.find(m.message,'not authorized') then t[string.sub(m.message,1,140)]=true end end local e={} for k in t do table.insert(e,k) end return #e..' '..table.concat(e,' | ')"))
N.play(False)
r = subprocess.run([VENV, "-I", str(ws / "tools" / "video_sheets.py"), str(video), str(sheets), "3"], capture_output=True, text=True)
print([l for l in r.stdout.splitlines() if l.startswith("wrote")][-3:])
