"""Directive v14 phase 3 stills (Play running in town or caves): the Glass Lift ride down (three frames) and the Clay Caves hall:
overview from the arrival ledge, the vault overhead, the north wall alcoves, the kiln arena, the west portal throat.
    python spike/clay_v14_shots.py <tag>      stills: captures/night/cl14_<tag>_<view>.png and a sheet"""
import sys, time
import night as N
tag = sys.argv[1] if len(sys.argv) > 1 else "a"
P = "local p=game.Players:GetPlayers()[1] local h=p.Character.HumanoidRootPart local O=require(game.ReplicatedStorage.Shared.Config).CAVE2_ORIGIN "
# the ride: down to Camp 1 first (Q), then ask for the Clay Caves trip and catch the lift on the way down
N.key("Q"); time.sleep(26)
N.lua(P + "p:SetAttribute('DevClay',2) return 1", "Server")
for t in (2.5, 5.0, 7.5):
    time.sleep(2.5)
    N.shot(f"cl14_{tag}_lift{int(t)}")
time.sleep(10)
VIEWS = [("hall", "-58,8,4", "30,14,-6"), ("vault", "-10,6,10", "6,80,-4"), ("north", "-20,10,30", "-10,40,-56"),
         ("kiln", "-30,9,-24", "20,6,10"), ("east", "50,9,20", "-20,18,-30"), ("portal", "-40,7,6", "-72,7,0")]
for name, eye, at in VIEWS:
    N.lua(P + f"h.CFrame=CFrame.new(O+Vector3.new({eye})) return 1", "Server")
    time.sleep(1.5)
    N.lua("local O=require(game.ReplicatedStorage.Shared.Config).CAVE2_ORIGIN local RS=game:GetService('RunService') pcall(function() RS:UnbindFromRenderStep('ClCam') end) "
          "for _,g in game.Players.LocalPlayer.PlayerGui:GetChildren() do if g:IsA('ScreenGui') then g.Enabled=false end end "
          f"local eye, at = O+Vector3.new({eye}), O+Vector3.new({at}) local ch=game.Players.LocalPlayer.Character "
          "RS:BindToRenderStep('ClCam', Enum.RenderPriority.Camera.Value+40, function() local cam=workspace.CurrentCamera cam.CameraType=Enum.CameraType.Scriptable cam.FieldOfView=78 cam.CFrame=CFrame.lookAt(eye, at) "
          "for _,d in ch:GetDescendants() do if d:IsA('BasePart') then d.LocalTransparencyModifier=1 end end for _,d in cam:GetDescendants() do if d:IsA('BasePart') then d.LocalTransparencyModifier=1 end end end) "
          "task.delay(8, function() pcall(function() RS:UnbindFromRenderStep('ClCam') end) end) return 1", "Client")
    time.sleep(1.2)
    N.shot(f"cl14_{tag}_{name}")
N.lua("for _,g in game.Players.LocalPlayer.PlayerGui:GetChildren() do if g:IsA('ScreenGui') then g.Enabled=true end end workspace.CurrentCamera.CameraType=Enum.CameraType.Custom return 1", "Client")
from PIL import Image
names = [f"lift{t}" for t in (2, 5, 7)] + [v[0] for v in VIEWS]
ims = [Image.open(N.out / f"cl14_{tag}_{n}.png").convert("RGB").resize((640, 260)) for n in names]
sheet = Image.new("RGB", (1280, 260 * ((len(ims) + 1) // 2)))
for i, im in enumerate(ims): sheet.paste(im, ((i % 2) * 640, (i // 2) * 260))
sheet.save(N.out / f"cl14_{tag}_sheet.jpg", quality=88)
print("sheet", N.out / f"cl14_{tag}_sheet.jpg")
