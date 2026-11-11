"""Thumbnail candidates: clean captures with every HUD layer off, cropped to 16:9, into captures/thumbs/ (starts Play itself).
Each view holds a Scriptable camera and hidden HUD for a few seconds in a background call while the capture runs."""
import pathlib, subprocess, sys, time
from PIL import Image
here = pathlib.Path(__file__).resolve().parent
out = here.parent / "captures" / "thumbs"; out.mkdir(parents=True, exist_ok=True)
def night(*a): return (subprocess.run([sys.executable, str(here / "night.py"), *a], capture_output=True, text=True).stdout.strip().splitlines() or ["?"])[-1]
HOLD = ("local pg=game.Players.LocalPlayer.PlayerGui local off={} for _,g in pg:GetChildren() do if g:IsA('ScreenGui') and g.Enabled then g.Enabled=false table.insert(off,g) end end "
        "local c=workspace.CurrentCamera local C=require(game.ReplicatedStorage.Shared.Config) local O1,O2=C.CAVE_ORIGIN,C.CAVE2_ORIGIN %s "
        "local t0=os.clock() while os.clock()-t0<4.5 do %s for _,m in c:GetChildren() do for _,q in m:GetDescendants() do if q:IsA('BasePart') then q.LocalTransparencyModifier=1 end end end task.wait() end "
        "for _,m in c:GetChildren() do for _,q in m:GetDescendants() do if q:IsA('BasePart') then q.LocalTransparencyModifier=0 end end end for _,g in off do g.Enabled=true end return 1")  # the first-person hands and pickaxe are hidden too
def snap(name, setup, each=""):
    p = subprocess.Popen([sys.executable, str(here / "night.py"), "lua", "Client", HOLD % (setup, each)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    time.sleep(2.6); night("shot", "thumb_" + name); p.wait()
    im = Image.open(here.parent / "captures" / "night" / f"thumb_{name}.png").convert("RGB"); w, h = im.size
    cw = min(w, int(h * 16 / 9)); im.crop(((w - cw) // 2, 0, (w + cw) // 2, h)).save(out / f"{name}.png")
    print("saved", name, flush=True)
P = "local p=game.Players:GetPlayers()[1] local h=p.Character.HumanoidRootPart local C=require(game.ReplicatedStorage.Shared.Config) "
night("play"); time.sleep(5)
snap("1_town", "")  # the game's own bird's-eye camera
night("key", "Q"); time.sleep(31)
snap("3_camp1", "c.CameraType=Enum.CameraType.Scriptable", "c.CFrame=CFrame.lookAt(O1+Vector3.new(26,13,26),O1+Vector3.new(-4,3,-2))")
night("lua", "Server", P + "local pl for _,x in workspace.Caves.Chasm:GetChildren() do if x.Name=='Plank' then pl=pl or x end end h.CFrame=CFrame.new(pl.Position+Vector3.new(0,4,0)) return 1"); time.sleep(2)
snap("4_chasm", "c.CameraType=Enum.CameraType.Scriptable local hr=game.Players.LocalPlayer.Character.HumanoidRootPart", "c.CFrame=CFrame.lookAt(hr.Position+Vector3.new(-6,7,-14),hr.Position+Vector3.new(30,-6,10))")
night("lua", "Server", P + "p:SetAttribute('DevClay',2) return 1"); time.sleep(7)
night("lua", "Server", P + "h.CFrame=CFrame.new(C.CAVE2_ORIGIN+Vector3.new(-40,3,10)) return 1"); time.sleep(1.5)
snap("5_clay_hall", "c.CameraType=Enum.CameraType.Scriptable", "c.CFrame=CFrame.lookAt(O2+Vector3.new(-58,16,22),O2+Vector3.new(24,6,-18))")
snap("6_titan_hand", "c.CameraType=Enum.CameraType.Scriptable", "c.CFrame=CFrame.lookAt(O2+Vector3.new(2,15,-14),O2+Vector3.new(34,2,-38))")
night("stop")
