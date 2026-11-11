"""One picture per item of the 2026-11-10 overnight directive, for the Gemini grade. Studio open in Edit mode.
Writes captures/night/d_*.png and copies them to <workspace>/Overnight/judge/dir35/ (argument: a round name, default r1)."""
import shutil, subprocess, sys, time, pathlib
here = pathlib.Path(__file__).resolve().parent
rnd = sys.argv[1] if len(sys.argv) > 1 else "r1"
dest = here.parent.parent.parent / "Overnight" / "judge" / "dir35" / rnd; dest.mkdir(parents=True, exist_ok=True)
def night(*a): return (subprocess.run([sys.executable, str(here / "night.py"), *a], capture_output=True, text=True).stdout.strip().splitlines() or ["?"])[-1]
def S(code): return night("lua", "Server", "local p=game.Players:GetPlayers()[1] local h=p.Character.HumanoidRootPart local C=require(game.ReplicatedStorage.Shared.Config) local O=C.CAVE2_ORIGIN " + code)
def Cl(code): return night("lua", "Client", code)
def shot(name): night("shot", "d_" + name); shutil.copy(here.parent / "captures" / "night" / f"d_{name}.png", dest / f"{name}.png")
def cam(expr): Cl("local C=require(game.ReplicatedStorage.Shared.Config) local O=C.CAVE2_ORIGIN local h=game.Players.LocalPlayer.Character.HumanoidRootPart local c=workspace.CurrentCamera c.CameraType=Enum.CameraType.Scriptable c.CFrame=" + expr + " return 1")
def free(): Cl("workspace.CurrentCamera.CameraType=Enum.CameraType.Custom return 1")
FX = "local F=game.ReplicatedStorage.Remotes.Fx "
night("play"); time.sleep(5); shot("01_hub_hud")
S("p:SetAttribute('DevPet','Glimwisp') return 1"); time.sleep(1.5); night("key", "Q"); time.sleep(25)
S("local s=workspace.Caves:FindFirstChild('LostLanternSpot',true) h.CFrame=CFrame.new(s.Position+Vector3.new(5,3,5), s.Position) return 1"); time.sleep(2.5)
shot("05_pet_companion")
cam("CFrame.lookAt(h.Position+Vector3.new(0,1.5,0), workspace.Caves:FindFirstChild('LostLanternSpot',true).Position+Vector3.new(0,2,0))"); time.sleep(0.5); shot("02_first_person_hands"); free()
S(FX + "for i=1,3 do F:FireClient(p,'lanternHave') end F:FireClient(p,'lantern',1,1,5) return 1"); time.sleep(1.2); shot("03_toast_queue")
time.sleep(7)
S("workspace:SetAttribute('DevSpore',60) return 1"); time.sleep(13); shot("06_spore_storm")
S("workspace:SetAttribute('DevRoots',900) return 1"); time.sleep(4); shot("07_roots_warning")
S(FX + "F:FireClient(p,'drowned',7,'fell') return 1"); time.sleep(1.5); shot("04_death_screen"); time.sleep(4)
S(FX + "F:FireClient(p,'grabbed',3) return 1"); time.sleep(0.9); shot("04b_grabbed"); time.sleep(3)
S(FX + "F:FireClient(p,'caught',6) return 1"); time.sleep(1.0); shot("04c_caught"); time.sleep(3)
S("workspace:SetAttribute('RootsStirAt',nil) p:SetAttribute('DevClay',2) return 1"); time.sleep(4)
cam("CFrame.lookAt(O+Vector3.new(-60,9,0),O+Vector3.new(20,8,0))"); time.sleep(0.6); shot("08_clay_hall")
S("h.CFrame=CFrame.new(O+Vector3.new(-14,3,8)) return 1"); time.sleep(1)
cam("CFrame.lookAt(O+Vector3.new(-16,7,10),O+Vector3.new(0,5,-12))"); time.sleep(0.6); shot("09_clay_kiln_camp")
S("h.CFrame=CFrame.new(O+Vector3.new(38,3,-26)) return 1"); cam("CFrame.lookAt(O+Vector3.new(14,10,-6),O+Vector3.new(46,28,-26))")
for _ in range(60):
    if "up" in Cl("local h=game.Players.LocalPlayer.Character.HumanoidRootPart return h.Position.Y>12 and 'up' or 'no'"): break
time.sleep(0.9); shot("10_steam_glide"); free()
S("h.CFrame=CFrame.new(O+Vector3.new(66,3,-30), O+Vector3.new(73,5,-30)) return 1"); time.sleep(1.5)
Cl("local h=game.Players.LocalPlayer.Character.HumanoidRootPart for _,d in workspace.Caves.Clay:GetDescendants() do if d:IsA('ProximityPrompt') and d:GetAttribute('Fossil')==3 then d:InputHoldBegin() task.wait(0.1) d:InputHoldEnd() end end return 1")
time.sleep(1.3); shot("11_fossil_brushing")
print("captures in", dest)
