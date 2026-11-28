"""v17 showcase clip (2026-11-28 owner brief, Phase 3): the uploaded voxel characters in the live game and the systems the full tour
skips. Close-ups of Bolt, Maribel, Tock and Pip in town; the town signpost's Guide me picker, a gold trail and the Journey
roadmap; the ride down; Wick and Smudge at Camp 1; a hardness-gated vein refusing a weak pick (sparks, "Needs T"); a swim in a
terrain-water pool (Swimming state, splashes, air bar); a Gloomling stalking once the torch is out; the Root Warden waking
(roar, slam act); the glass lift to the Clay Caves; the Kiln Keeper, the Kiln Golem and a Clayling.
Shortcuts (say so to a grader): server teleports, scripted cameras, Dev attributes (DevGuide, DevJourney, DevTorchAge, DevBanked,
DevClay), the rig acts fired by script (Shared.CharRigs.act). Studio open in Edit mode and in front.
    python spike/showcase_v17.py <name>     video: captures/loop/<name>.mp4, sheets: <workspace>/Overnight/judge/loop_<name>/"""
import pathlib, subprocess, sys, time
here = pathlib.Path(__file__).resolve().parent
game, ws = here.parent, here.parent.parent.parent
sys.path.insert(0, str(here))
import night as N
from prompt_test import trigger
name = sys.argv[1] if len(sys.argv) > 1 else "show17"
VENV = r"C:\Users\kgsat\Documents\Roblox\Hunyuan3D\.venv\Scripts\python.exe"
video = game / "captures" / "loop" / f"{name}.mp4"; video.parent.mkdir(parents=True, exist_ok=True)
sheets = ws / "Overnight" / "judge" / f"loop_{name}"; sheets.mkdir(parents=True, exist_ok=True)
SECS = 270
def S(code): return (N.lua(code, "Server").splitlines() or ["?"])[-1]
def C(code): return (N.lua(code, "Client").splitlines() or ["?"])[-1]
def key(k, wait): N.key(k); time.sleep(wait)
P = "local p=game.Players:GetPlayers()[1] local h=p.Character.HumanoidRootPart local cv=workspace:FindFirstChild('Caves') local C=require(game.ReplicatedStorage.Shared.Config) "
ERRS = ("local t={} for _,m in game:GetService('LogService'):GetLogHistory() do if m.messageType==Enum.MessageType.MessageError and not string.find(m.message,'Requester') "
        "and not string.find(m.message,'not authorized') then t[string.sub(m.message,1,140)]=true end end local e={} for k in t do table.insert(e,k) end return #e..' '..table.concat(e,' ## ')")


def rig_cam(n, secs=5, dist=1.2, side=0.35):  # a scripted camera in front of a mounted rig (town: bound after the game's camera)
    return C("local m=workspace:FindFirstChild('CharRigsVis') and workspace.CharRigsVis:FindFirstChild('" + n + "') if not m then return 'none' end "
             "local cf=m:GetPivot() local hh=m:GetExtentsSize().Y local d=math.max(hh*" + str(dist) + ",5) local at=cf.Position+Vector3.new(0,hh*0.3,0) "
             "local eye=at+cf.LookVector*d+cf.RightVector*d*" + str(side) + "+Vector3.new(0,hh*0.25,0) local p=game.Players.LocalPlayer p:SetAttribute('HidePetsUntil',os.clock()+" + str(secs) + ") "
             "local RS=game:GetService('RunService') _G.ShowN=(_G.ShowN or 0)+1 local nm='ShowCam'.._G.ShowN "
             "RS:BindToRenderStep(nm,2000,function() local c=workspace.CurrentCamera c.CameraType=Enum.CameraType.Scriptable c.CFrame=CFrame.lookAt(eye,at) end) "
             "task.delay(" + str(secs) + ",function() pcall(function() RS:UnbindFromRenderStep(nm) end) if _G.ShowN==tonumber(string.sub(nm,8)) then workspace.CurrentCamera.CameraType=Enum.CameraType.Custom end end) return 'ok'")


def face(target_expr, back=7, up=0):  # caves (first person): stand the player in front of something and look at it
    S(P + "local at=" + target_expr + " local dir=(h.Position-at)*Vector3.new(1,0,1) if dir.Magnitude<0.1 then dir=Vector3.new(1,0,0) end "
          "local pos=at+dir.Unit*" + str(back) + " h.AssemblyLinearVelocity=Vector3.zero h.CFrame=CFrame.lookAt(pos+Vector3.new(0,3,0),Vector3.new(at.X,pos.Y+3,at.Z)) return 1")
    time.sleep(0.6)
    C("local at=" + target_expr + " local cam=workspace.CurrentCamera cam.CFrame=CFrame.lookAt(cam.CFrame.Position,at+Vector3.new(0," + str(up) + ",0)) return 1")


def rig_front(n, back=7, up=1.5):  # in front of a rig, not merely near it: the side its face looks to
    S(P + "local m=workspace:FindFirstChild('CharRigsVis') and workspace.CharRigsVis:FindFirstChild('" + n + "') if not m then return 1 end local cf=m:GetPivot() "
          "local pos=cf.Position+cf.LookVector*" + str(back) + " h.AssemblyLinearVelocity=Vector3.zero h.CFrame=CFrame.lookAt(pos+Vector3.new(0,3,0),Vector3.new(cf.X,pos.Y+3,cf.Z)) return 1")
    time.sleep(0.6)
    C("local m=workspace.CharRigsVis:FindFirstChild('" + n + "') local cam=workspace.CurrentCamera if m then cam.CFrame=CFrame.lookAt(cam.CFrame.Position,m:GetPivot().Position+Vector3.new(0," + str(up) + ",0)) end return 1")


def look_gloom():
    C("local g=workspace:FindFirstChild('GloomVis') local cam=workspace.CurrentCamera local best,bd for _,m in (g and g:GetChildren() or {}) do if m:IsA('Model') and m.PrimaryPart then local d=(m.PrimaryPart.Position-cam.CFrame.Position).Magnitude if not bd or d<bd then best,bd=m,d end end end "
      "if best then cam.CFrame=CFrame.lookAt(cam.CFrame.Position,best.PrimaryPart.Position) end return 1")


N.play(False); N.restore()
if video.exists(): video.unlink()
rec = subprocess.Popen([VENV, "-I", str(ws / "tools" / "record_window.py"), str(video), str(SECS), "15"], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
t0 = time.time()
def mark(what): print(f"{time.time() - t0:5.0f} s  {what}", flush=True)
STILLS = []
def snap():  # a Studio still of this beat: the window recorder sees one frozen frame while the display sleeps (vault: Tool Connections, night recordings)
    p = N.shot(f"{name}_{len(STILLS):02d}"); STILLS.append(p)
time.sleep(1.5)
mark("Play starts")
N.run("start_stop_play", {"is_start": True})
time.sleep(16)
mark("town: Bolt the smith (v17 voxel rig)"); print(rig_cam("Bolt", 5)); time.sleep(2); snap(); time.sleep(1)
mark("town: Maribel at the hatchery"); print(rig_cam("Maribel", 5)); time.sleep(2); snap(); time.sleep(1)
mark("town: Juniper and Tock roasting at the campfire"); print(rig_cam("Tock", 5, 1.6, -0.6)); time.sleep(2); snap(); time.sleep(1)
mark("town: Pip the scout"); print(rig_cam("Pip", 4)); time.sleep(2); snap(); time.sleep(1)
mark("the signpost: Guide me opens the station picker")
trigger("Station", "'guide'"); time.sleep(2); snap()
C("local p=game.Players.LocalPlayer p:SetAttribute('DevGuide',nil) p:SetAttribute('DevGuide','forge') return 1"); time.sleep(0.5)
mark("the gold trail to the forge"); time.sleep(2); snap(); time.sleep(1)
mark("the Journey roadmap (Shared.JourneyUI)")
C("local p=game.Players.LocalPlayer p:SetAttribute('DevJourney',nil) p:SetAttribute('DevJourney',true) return 1"); time.sleep(2.5); snap(); time.sleep(1); key("M", 1)
C("game.Players.LocalPlayer:SetAttribute('DevJourney',nil) return 1")
mark("Q: ride down"); key("Q", 30)
mark("Camp 1: Wick the elder glowworm"); rig_front("Wick", 7, 1.5); time.sleep(2); snap(); time.sleep(1)
mark("Camp 1: Smudge the soot sprite"); rig_front("Smudge", 4, 0.3); time.sleep(2); snap()
mark("a hardness gate: a vein too hard for the Stone Pickaxe")
r = S(P + "local eq=1 local best,bd for _,d in cv:GetDescendants() do if (d:IsA('BasePart') or d:IsA('Model')) and d:GetAttribute('Ore') and d:GetAttribute('Layer') then local need=C.minTier(d:GetAttribute('Layer'),d:GetAttribute('Ore')) "
          "if need and need>eq then local m=(d:GetPivot().Position-h.Position).Magnitude if not bd or m<bd then best,bd=d,m end end end end if not best then return 'none' end "
          "p:SetAttribute('ShowVein',best:GetFullName()) local bp=best:GetPivot().Position local dir=(h.Position-bp)*Vector3.new(1,0,1) dir=dir.Magnitude>0.1 and dir.Unit or Vector3.new(1,0,0) "
          "h.AssemblyLinearVelocity=Vector3.zero h.CFrame=CFrame.lookAt(bp+dir*5+Vector3.new(0,1,0),bp) return best.Name..' needs T'..C.minTier(best:GetAttribute('Layer'),best:GetAttribute('Ore'))")
print("vein:", r); time.sleep(0.8)
C("local p=game.Players.LocalPlayer local n=p:GetAttribute('ShowVein') local d=game for s in string.gmatch(n or '','[^%.]+') do d=d and d:FindFirstChild(s) end if d and d ~= game then local cam=workspace.CurrentCamera cam.CFrame=CFrame.lookAt(cam.CFrame.Position,d:GetPivot().Position) end return 1")
time.sleep(1.5); key("E", 0.6); snap(); key("E", 1.2); key("E", 1)
mark("swimming in a cave pool (terrain water)")
FIND = ("local C=require(game.ReplicatedStorage.Shared.Config) local o=C.CAVE_ORIGIN local r=Region3.new(o-Vector3.new(256,96,256), o+Vector3.new(256,64,256)):ExpandToGrid(4) "
        "local mats,occ=workspace.Terrain:ReadVoxels(r,4) local sz=mats.Size local best,bd for x=1,sz.X do for z=1,sz.Z do local d=0 local top for y=1,sz.Y do if mats[x][y][z]==Enum.Material.Water then d+=1 top=y end end "
        "if d>0 and (not bd or d>bd) then bd=d best=r.CFrame.Position-r.Size/2+Vector3.new((x-0.5)*4,(top-0.5)*4,(z-0.5)*4) end end end "
        "if not best then return 'none' end local p=game.Players:GetPlayers()[1] p.Character.HumanoidRootPart.CFrame=CFrame.new(best+Vector3.new(0,4,0)) return 'ok'")
print("pool:", S(FIND)); time.sleep(1.5)
C("local cam=workspace.CurrentCamera cam.CFrame=CFrame.lookAt(cam.CFrame.Position,cam.CFrame.Position+Vector3.new(0.6,-0.8,0.2)) return 1"); time.sleep(2.5)
print("swim state:", C("return tostring(game.Players.LocalPlayer.Character.Humanoid:GetState())")); snap()
key("Space", 1.5); key("Space", 1.5)
mark("the dark: the torch dies and a Gloomling stalks (v17 voxel rig)")
S(P + "p:SetAttribute('DevBanked',true) h.CFrame=cv:FindFirstChild('LiftLanding',true).CFrame+Vector3.new(0,3,0) task.wait(0.5) p:SetAttribute('DevTorchAge',900) return 1"); time.sleep(6)
look_gloom(); time.sleep(2.5); look_gloom(); snap(); time.sleep(1)
S(P + "p:SetAttribute('DevTorchAge',nil) return 1")
mark("Root Warden: asleep, then the wake roar and a slam hoist")
subprocess.run([sys.executable, str(here / "boss_stance.py"), "Warden", f"{name}_warden"], capture_output=True, text=True, cwd=here)
time.sleep(1.5)
C("local CR=require(game.ReplicatedStorage.Shared.CharRigs) CR.act('RootWarden','roar') return 1"); time.sleep(0.9); snap(); time.sleep(1)
C("local CR=require(game.ReplicatedStorage.Shared.CharRigs) CR.act('RootWarden','rear') return 1"); time.sleep(0.8); snap(); time.sleep(1.2)
mark("glass lift down to the Clay Caves")
S(P + "h.CFrame=cv:FindFirstChild('LiftLanding',true).CFrame+Vector3.new(0,3,0) task.wait(1) p:SetAttribute('DevClay',2) return 1"); time.sleep(17)
mark("Camp 2: the Kiln Keeper at his stall"); rig_front("KilnKeeper", 8, 1.5); time.sleep(2); snap(); time.sleep(1)
mark("the Kiln Golem: a wake roar and a cleave")
subprocess.run([sys.executable, str(here / "boss_stance.py"), "KilnGolem", f"{name}_golem"], capture_output=True, text=True, cwd=here)
time.sleep(1.5)
C("local CR=require(game.ReplicatedStorage.Shared.CharRigs) CR.act('KilnGolem','roar') return 1"); time.sleep(0.9); snap(); time.sleep(1)
C("local CR=require(game.ReplicatedStorage.Shared.CharRigs) CR.act('KilnGolem','armflex') return 1"); time.sleep(0.8); snap(); time.sleep(1.2)
mark("a Clayling: it moves only while you look away")
S(P + "local O=CFrame.new(C.CAVE2_ORIGIN) h.CFrame=O*CFrame.new(11,3,-64) task.wait(0.3) p:SetAttribute('DevBanked',true) p:SetAttribute('DevTorchAge',900) return 1"); time.sleep(7)
look_gloom(); time.sleep(2.5); look_gloom(); snap(); time.sleep(1)
S(P + "p:SetAttribute('DevTorchAge',nil) return 1")
left = SECS - (time.time() - t0)
mark(f"{left:.0f} s of recording left")
time.sleep(max(left + 4, 4))
print(rec.communicate(timeout=600)[0][-300:])
print("client errors:", C(ERRS))
print("server errors:", S(ERRS))
N.play(False)
if STILLS:  # the stills as a slideshow, 2 s a beat: <name>_stills.mp4 beside the recording
    NL = chr(10)
    lst = game / "captures" / "loop" / f"{name}_stills.txt"
    lst.write_text("".join(f"file '{pathlib.Path(p).as_posix()}'" + NL + "duration 2" + NL for p in STILLS) + f"file '{pathlib.Path(STILLS[-1]).as_posix()}'" + NL, encoding="utf-8")
    out = game / "captures" / "loop" / f"{name}_stills.mp4"
    subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-f", "concat", "-safe", "0", "-i", str(lst), "-vf", "scale=1920:-2,fps=15", "-pix_fmt", "yuv420p", str(out)])
    print("stills video:", out, len(STILLS), "beats")
r = subprocess.run([VENV, "-I", str(ws / "tools" / "video_sheets.py"), str(video), str(sheets), "3"], capture_output=True, text=True)
print([l for l in r.stdout.splitlines() if l.startswith("wrote")][-3:])
