"""Directive v14 phase 2 stills of a Cave v2 preview layer (Play running). Each view stands at a layout spot at head height and
looks down the longest open sightline from there (16 headings, raycast against the rock), so the camera is never inside rock.
    python spike/cv2_v14_shots.py <tag> <layer> [seed]      stills: captures/night/c14_<tag>_L<layer>_<view>.png and a sheet"""
import sys, time
import night as N
tag, LAYER = sys.argv[1], int(sys.argv[2])
seed = sys.argv[3] if len(sys.argv) > 3 else "7"
print(N.lua("local C=require(game.ReplicatedStorage.Shared.Config) local o=workspace:FindFirstChild('CavesV2') if o then o:Destroy() end for _,a in workspace.Terrain:GetChildren() do if a:GetAttribute('CaveV2') then a:Destroy() end end "
            f"local m=require(game.ServerScriptService.CaveV2).build(workspace, C.CAVE_V2_ORIGIN, {seed}, {{ layer = {LAYER} }}) local pr=require(game.ServerScriptService.CaveProps).build(m) require(game.ServerScriptService.CaveV2).tintProps(m, {LAYER}) "
            "local p=game.Players:GetPlayers()[1] p.Character:PivotTo(workspace.Terrain.Spot_Camp.WorldCFrame) p.Character.HumanoidRootPart.Anchored=true return m:GetAttribute('Parts')", "Server"))
time.sleep(3)
# (name, spot, pitch, mode): mode "far" = the longest sightline; "rim" = from the spot toward the nearest rimstone pool
VIEWS = [("keyhole", "OldTube", 0.0, "far"), ("canyon", "Canyon", 0.08, "far"), ("dome", "Cathedral", 0.6, "far"), ("hall", "Cathedral", 0.12, "far"),
         ("b1", "B1", 0.05, "far"), ("b2", "B2", 0.05, "far"), ("sump", "SumpGate", 0.05, "far"), ("b5", "B5", 0.05, "far")]
if LAYER in (2, 3):
    VIEWS += [("rimstone", "B2", -0.25, "rim"), ("rimstone2", "Cathedral" if LAYER == 2 else "B3", -0.25, "rim")]
HEAD = ("local cv=workspace:FindFirstChild('CavesV2') local rp=RaycastParams.new() rp.FilterType=Enum.RaycastFilterType.Include "
        "rp.FilterDescendantsInstances={cv:FindFirstChild('Walls'), cv:FindFirstChild('Floor'), cv:FindFirstChild('Ramps')} "
        "local function S(n) local a=workspace.Terrain:FindFirstChild('Spot_'..n) return a and a.WorldPosition or Vector3.zero end "
        "local function dist(o, d) local r=workspace:Raycast(o, d*220, rp) return r and r.Distance or 220 end "
        "local function far(o) local best, bd = Vector3.xAxis, -1 for i=0,15 do local a=i*math.pi/8 local d=Vector3.new(math.cos(a),0,math.sin(a)) local m=dist(o,d) if m>bd then best,bd=d,m end end return best end "
        "local function pool(at) local best,bd for _,d in cv:GetDescendants() do if d:IsA('BasePart') and d.Name=='RimPool' then local m=(d.Position-at).Magnitude if not bd or m<bd then best,bd=d,m end end end return best end ")
for name, spot, pitch, mode in VIEWS:
    N.lua(HEAD + f"local p=game.Players:GetPlayers()[1] p.Character:PivotTo(CFrame.new(S('{spot}'))) p:RequestStreamAroundAsync(S('{spot}'), 8) return 1", "Server")
    time.sleep(2.5)
    if mode == "far":
        aim = (f"local eye=S('{spot}')+Vector3.new(0,1.5,0) local d=far(eye) local back=math.min(6, dist(eye,-d)-1.5) eye=eye-d*math.max(0,back) "
               f"local at=eye+(d+Vector3.new(0,{pitch},0)).Unit*20 ")
    else:
        aim = (f"local pl=pool(S('{spot}')) local tgt=pl and pl.Position or S('{spot}') local dh=pl and pl.CFrame.LookVector or Vector3.xAxis "
               "local eye=tgt+Vector3.new(0,5,0) local back=math.min(12, dist(eye, dh)-2) eye=eye+dh*math.max(0,back) "
               "local at=tgt-dh*3 ")
    code = (HEAD + aim + "local RS=game:GetService('RunService') pcall(function() RS:UnbindFromRenderStep('CV2Cam') end) "
            "for _,g in game.Players.LocalPlayer.PlayerGui:GetChildren() do if g:IsA('ScreenGui') then g.Enabled=false end end "
            "local ch=game.Players.LocalPlayer.Character "
            "for _,d in workspace:GetDescendants() do if d:IsA('Model') and d:GetAttribute('Pet') ~= nil then d:PivotTo(d:GetPivot()+Vector3.new(0,-500,0)) end end "
            "local torch=workspace:FindFirstChild('CV2Torch') or Instance.new('Part') torch.Name='CV2Torch' torch.Anchored=true torch.CanCollide=false torch.Transparency=1 torch.Size=Vector3.one torch.Parent=workspace "
            "local tl=torch:FindFirstChildOfClass('PointLight') or Instance.new('PointLight', torch) tl.Color=Color3.fromRGB(255,190,120) tl.Range=40 tl.Brightness=1.2 tl.Shadows=true "
            "RS:BindToRenderStep('CV2Cam', Enum.RenderPriority.Camera.Value+40, function() local cam=workspace.CurrentCamera cam.CameraType=Enum.CameraType.Scriptable cam.FieldOfView=78 cam.CFrame=CFrame.lookAt(eye, at) torch.CFrame=CFrame.new(eye+Vector3.new(0.6,-0.8,0)) for _,d in ch:GetDescendants() do if d:IsA('BasePart') then d.LocalTransparencyModifier=1 end end end) "
            "task.delay(9, function() pcall(function() RS:UnbindFromRenderStep('CV2Cam') end) end) return 1")
    N.lua(code, "Client")
    time.sleep(1.2)
    N.shot(f"c14_{tag}_L{LAYER}_{name}")
N.lua("for _,g in game.Players.LocalPlayer.PlayerGui:GetChildren() do if g:IsA('ScreenGui') then g.Enabled=true end end workspace.CurrentCamera.CameraType=Enum.CameraType.Custom return 1", "Client")
from PIL import Image
ims = [Image.open(N.out / f"c14_{tag}_L{LAYER}_{v[0]}.png").convert("RGB").resize((640, 260)) for v in VIEWS]
sheet = Image.new("RGB", (1280, 260 * ((len(ims) + 1) // 2)))
for i, im in enumerate(ims): sheet.paste(im, ((i % 2) * 640, (i // 2) * 260))
sheet.save(N.out / f"c14_{tag}_L{LAYER}_sheet.jpg", quality=88)
print("sheet", N.out / f"c14_{tag}_L{LAYER}_sheet.jpg")
