"""Stills of the Cave v2 preview from inside (Play must be running with CaveV2 built). python spike/cavev2_shots.py <tag> [seed]"""
import sys, time
import night as N
tag = sys.argv[1] if len(sys.argv) > 1 else "a"
OLD = len(sys.argv) > 3 and sys.argv[3] == "old"  # the same camera and torch in the live caves (CaveBuilder), for a fair comparison
seed = sys.argv[2] if len(sys.argv) > 2 else "7"
if not OLD: print(N.lua("local C=require(game.ReplicatedStorage.Shared.Config) local o=workspace:FindFirstChild('CavesV2') if o then o:Destroy() end for _,a in workspace.Terrain:GetChildren() do if a:GetAttribute('CaveV2') then a:Destroy() end end "
            f"local m=require(game.ServerScriptService.CaveV2).build(workspace, C.CAVE_V2_ORIGIN, {seed}) local pr=require(game.ServerScriptService.CaveProps).build(m) "
            "local p=game.Players:GetPlayers()[1] p.Character:PivotTo(workspace.Terrain.Spot_Camp.WorldCFrame) p.Character.HumanoidRootPart.Anchored=true return m:GetAttribute('Parts')..' props '..tostring(pr:GetAttribute('Count'))", "Server"))
time.sleep(3)
if OLD:  # markers in the old caves: the camp and three points along its floors
    N.lua("local C=require(game.ReplicatedStorage.Shared.Config) local o=C.CAVE_ORIGIN local fl={} for _,p in workspace.Caves:GetDescendants() do if p:IsA('BasePart') and p.Name=='Floor' then table.insert(fl,p) end end "
          "for i,n in {'Camp','Canyon','Cathedral','OldTube','SumpGate','SwallowHole','B1','B2','B5'} do local a=workspace.Terrain:FindFirstChild('Spot_'..n) or Instance.new('Attachment') a.Name='Spot_'..n a.Parent=workspace.Terrain "
          "local p = i==1 and (o+Vector3.new(0,3,0)) or (fl[(i*977)%#fl+1].Position+Vector3.new(0,fl[(i*977)%#fl+1].Size.Y/2+3,0)) a.WorldPosition=p end return 1", "Server")
VIEWS = [("camp", "Camp", (1, 0.05, 0.1)), ("camp_w", "Camp", (-1, 0.1, 0)), ("canyon", "Canyon", (1, 0.05, 0.2)), ("cathedral", "Cathedral", (1, 0.25, 0)),
         ("oldtube", "OldTube", (1, 0, 0)), ("sump", "SumpGate", (-1, 0.1, 0)), ("swallow", "SwallowHole", (-0.3, -0.8, 0.5)), ("b1", "B1", (1, 0.1, 0.3)), ("b2", "B2", (1, 0, 0.2)), ("b5", "B5", (-1, 0.1, -0.4))]
for name, spot, d in VIEWS:
    N.lua("local p=game.Players:GetPlayers()[1] p.Character:PivotTo(workspace.Terrain.Spot_" + spot + ".WorldCFrame) p:RequestStreamAroundAsync(workspace.Terrain.Spot_" + spot + ".WorldPosition, 8) return 1", "Server")
    time.sleep(3)
    code = ("local RS=game:GetService('RunService') pcall(function() RS:UnbindFromRenderStep('CV2Cam') end) local a=workspace.Terrain:WaitForChild('Spot_" + spot + "') "
            "for _,g in game.Players.LocalPlayer.PlayerGui:GetChildren() do if g:IsA('ScreenGui') then g.Enabled=false end end "
            f"local p=a.WorldPosition+Vector3.new(0,4,0) for _,b in workspace:GetDescendants() do if b:IsA('Beam') or b:IsA('Trail') then b.Enabled=false end end local dir=Vector3.new({d[0]},{d[1]},{d[2]}).Unit "
            "local ch=game.Players.LocalPlayer.Character for _,d in ch:GetDescendants() do if d:IsA('BasePart') then d.LocalTransparencyModifier=1 end end "
            "for _,d in workspace:GetDescendants() do if d:IsA('Model') and d:GetAttribute('Pet') ~= nil then d:PivotTo(d:GetPivot()+Vector3.new(0,-500,0)) end end "
            "local torch=workspace:FindFirstChild('CV2Torch') or Instance.new('Part') torch.Name='CV2Torch' torch.Anchored=true torch.CanCollide=false torch.Transparency=1 torch.Size=Vector3.one torch.Parent=workspace "
            "local tl=torch:FindFirstChildOfClass('PointLight') or Instance.new('PointLight', torch) tl.Color=Color3.fromRGB(255,190,120) tl.Range=36 tl.Brightness=1.1 tl.Shadows=true "
            "RS:BindToRenderStep('CV2Cam', Enum.RenderPriority.Camera.Value+40, function() local cam=workspace.CurrentCamera cam.CameraType=Enum.CameraType.Scriptable cam.FieldOfView=80 cam.CFrame=CFrame.lookAt(p-dir*2, p+dir*10) torch.CFrame=CFrame.new(p+Vector3.new(0.6,-0.6,0)) for _,d in ch:GetDescendants() do if d:IsA('BasePart') then d.LocalTransparencyModifier=1 end end for _,d in cam:GetDescendants() do if d:IsA('BasePart') then d.LocalTransparencyModifier=1 end end end) "
            "task.delay(9, function() pcall(function() RS:UnbindFromRenderStep('CV2Cam') end) end) return 1")
    N.lua(code, "Client")
    time.sleep(1.2)
    N.shot(f"cv2_{tag}_{name}")
N.lua("for _,g in game.Players.LocalPlayer.PlayerGui:GetChildren() do if g:IsA('ScreenGui') then g.Enabled=true end end workspace.CurrentCamera.CameraType=Enum.CameraType.Custom return 1", "Client")
from PIL import Image
ims = [Image.open(N.out / f"cv2_{tag}_{v[0]}.png").resize((640, 248)) for v in VIEWS]
sheet = Image.new("RGB", (1280, 248 * 5))
for i, im in enumerate(ims): sheet.paste(im, ((i % 2) * 640, (i // 2) * 248))
sheet.save(N.out / f"cv2_{tag}_sheet.jpg", quality=88)
print("sheet", N.out / f"cv2_{tag}_sheet.jpg")
