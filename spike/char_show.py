"""Close-up stills of the mounted v17 voxel characters (Shared.CharRigs) in Play: a scripted camera in front of each rig.
python spike/char_show.py <tag> [Name ...]   -> captures/chars/show/<tag>_<Name>.png   (Play running, NIGHT_SERIAL=1)"""
import pathlib, shutil, sys, time
here = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(here))
import night as N
tag = sys.argv[1]
names = sys.argv[2:] or ["Bolt", "Maribel", "Pip", "Juniper", "Tock"]
out = here.parent / "captures" / "chars" / "show"; out.mkdir(parents=True, exist_ok=True)
for n in names:
    r = N.lua("local m=workspace:FindFirstChild('CharRigsVis') and workspace.CharRigsVis:FindFirstChild('" + n + "') if not m then return 'none' end "
              "local cf=m:GetPivot() local h=m:GetExtentsSize().Y local d=math.max(h*1.15,5) local at=cf.Position+Vector3.new(0,h*0.2,0) "
              "local eye=at+cf.LookVector*d+cf.RightVector*d*0.35+Vector3.new(0,h*0.3,0) "
              "local p=game.Players.LocalPlayer local hrp=p.Character and p.Character:FindFirstChild('HumanoidRootPart') "
              "if hrp then hrp.CFrame=CFrame.new(eye+(eye-at).Unit*4*Vector3.new(1,0,1)) end "
              "p:SetAttribute('HidePetsUntil',os.clock()+6) local RS=game:GetService('RunService') pcall(function() RS:UnbindFromRenderStep('CharShow') end) "
              "RS:BindToRenderStep('CharShow',5000,function() local c=workspace.CurrentCamera c.CameraType=Enum.CameraType.Scriptable c.CFrame=CFrame.lookAt(eye,at) end) "
              "task.delay(5,function() pcall(function() RS:UnbindFromRenderStep('CharShow') end) workspace.CurrentCamera.CameraType=Enum.CameraType.Custom end) return 'ok'", "Client").splitlines()[-1]
    if r != "ok":
        print(n, r); continue
    time.sleep(2.2)
    p = N.shot(f"{tag}_{n}")
    shutil.copy(p, out / f"{tag}_{n}.png")
    print(n, out / f"{tag}_{n}.png", flush=True)
    time.sleep(3)
