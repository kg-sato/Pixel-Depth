"""Low-tier cave lighting A/B (Play running, in Camp 1): the same camp view with the light factor as built and forced low
(DevLowLight), mean brightness and the share of near-black pixels of each.   python spike/p5_low.py <prefix>"""
import sys, time, pathlib
import night as N
from PIL import Image, ImageStat
pre = sys.argv[1] if len(sys.argv) > 1 else "p5"
C = lambda code: (N.lua(code, "Client").splitlines() or ["?"])[-1]
C("game.ReplicatedStorage.Remotes.Surface:FireServer('down') return 1"); time.sleep(16)
res = {}
for tag, low in (("hi", False), ("low", True)):
    C(f"game.Players.LocalPlayer:SetAttribute('DevLowLight', {'true' if low else 'nil'}) return 1"); time.sleep(3)
    C("local RS=game:GetService('RunService') pcall(function() RS:UnbindFromRenderStep('P5Cam') end) local O=require(game.ReplicatedStorage.Shared.Config).CAVE_ORIGIN "
      "for _,g in game.Players.LocalPlayer.PlayerGui:GetChildren() do if g:IsA('ScreenGui') then g.Enabled=false end end "
      "RS:BindToRenderStep('P5Cam', Enum.RenderPriority.Camera.Value+40, function() local cam=workspace.CurrentCamera cam.CameraType=Enum.CameraType.Scriptable cam.FieldOfView=75 cam.CFrame=CFrame.lookAt(O+Vector3.new(-18,6,14), O+Vector3.new(10,3,-6)) end) "
      "task.delay(8, function() pcall(function() RS:UnbindFromRenderStep('P5Cam') end) end) return 1")
    time.sleep(1.5)
    N.shot(f"{pre}_{tag}")
    im = Image.open(N.out / f"{pre}_{tag}.png").convert("L")
    st = ImageStat.Stat(im)
    dark = sum(1 for v in im.getdata() if v < 12) / (im.width * im.height)
    res[tag] = (round(st.mean[0], 1), round(dark * 100, 1))
C("game.Players.LocalPlayer:SetAttribute('DevLowLight', nil) for _,g in game.Players.LocalPlayer.PlayerGui:GetChildren() do if g:IsA('ScreenGui') then g.Enabled=true end end return 1")
print("mean brightness / % near-black:", res)
