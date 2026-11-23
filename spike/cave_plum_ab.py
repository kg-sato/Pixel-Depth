"""Cave light A/B for the Orchestrator's task 10 (2026-11-23): rides to Camp 1, then from three spots just outside the camp ring
looks out along the longest open line and takes one still per variant (client only, held each frame over the game's own setting).
    python spike/cave_plum_ab.py <tag>      stills: captures/night/plum_<tag>_<view>_<variant>.png and a sheet"""
import sys, time
import night as N
from PIL import Image
tag = sys.argv[1] if len(sys.argv) > 1 else "a"
C = lambda code: (N.lua(code, "Client").splitlines() or ["?"])[-1]
S = lambda code: (N.lua(code, "Server").splitlines() or ["?"])[-1]
# variant: Lighting props, ColorCorrection props, torch brightness factor
VARIANTS = {  # target: the reference board's REWORK-LGT-01 (a golden torch pool, plum-mauve rock outside it, not black, not brown)
    "A": None,
    "B": ("Ambient=Color3.fromRGB(64,38,96) L.OutdoorAmbient=Color3.fromRGB(52,30,82) L.EnvironmentDiffuseScale=0.05", "Contrast=0.24 cc.Saturation=0.16", 1.35),
    "C": ("Ambient=Color3.fromRGB(52,30,84) L.OutdoorAmbient=Color3.fromRGB(44,26,72) L.EnvironmentDiffuseScale=0.04", "Contrast=0.3 cc.Saturation=0.22", 1.6),
}
N.play(False); time.sleep(2); N.play(); time.sleep(10)
C("local g=game.Players.LocalPlayer.PlayerGui:FindFirstChild('DailyChest') if g then g.Enabled=false end return 1")
N.key("Q"); time.sleep(30)
print("in cave:", S("return tostring(game.Players:GetPlayers()[1]:GetAttribute('InCave'))"))
names = []
for v_i, deg in enumerate((20, 140, 260)):
    view = f"v{v_i + 1}"
    # stand 30 studs out from camp at this bearing on open floor, face away from camp
    S("local C=require(game.ReplicatedStorage.Shared.Config) local o=C.CAVE_ORIGIN local p=game.Players:GetPlayers()[1] local h=p.Character.HumanoidRootPart "
      "local rp=RaycastParams.new() rp.FilterDescendantsInstances={p.Character} rp.FilterType=Enum.RaycastFilterType.Exclude "
      f"for r=34,14,-4 do local a=math.rad({deg}) local q=o+Vector3.new(math.cos(a)*r,30,math.sin(a)*r) local hit=workspace:Raycast(q,Vector3.new(0,-60,0),rp) "
      "if hit and hit.Position.Y<o.Y+12 and hit.Position.Y>o.Y-12 then h.CFrame=CFrame.lookAt(hit.Position+Vector3.new(0,3,0),hit.Position+Vector3.new(0,3,0)+Vector3.new(math.cos(a),0,math.sin(a))) return r end end return 'none'")
    time.sleep(2.5)
    C("local cam=workspace.CurrentCamera local h=game.Players.LocalPlayer.Character.HumanoidRootPart local look=h.CFrame.LookVector "
      "local RS=game:GetService('RunService') pcall(function() RS:UnbindFromRenderStep('plumcam') end) "
      "RS:BindToRenderStep('plumcam',2001,function() cam.CFrame=CFrame.lookAt(h.Position+Vector3.new(0,1.6,0), h.Position+Vector3.new(0,1.0,0)+look*20) end) return 1")
    for v, cfg in VARIANTS.items():
        C("game:GetService('RunService'):UnbindFromRenderStep('plumlight') return 1")
        if cfg:
            C("local L=game.Lighting local cc=L:FindFirstChildOfClass('ColorCorrectionEffect') local RS=game:GetService('RunService') "
              "RS:BindToRenderStep('plumlight',2002,function() L.%s if cc then cc.%s end local t=game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild('Lantern',true) "
              "if t then t.Brightness=t.Brightness*%s end end) return 1" % (cfg[0], cfg[1], cfg[2]))
        time.sleep(1.6)
        N.shot(f"plum_{tag}_{view}_{v}")
        names.append((view, v))
    C("local RS=game:GetService('RunService') pcall(function() RS:UnbindFromRenderStep('plumlight') end) pcall(function() RS:UnbindFromRenderStep('plumcam') end) return 1")
N.play(False)
W, H = 640, 248
sheet = Image.new("RGB", (W * 3, H * 3), "black")
for i, (view, v) in enumerate(names):
    im = Image.open(N.CAP / f"plum_{tag}_{view}_{v}.png" if hasattr(N, "CAP") else f"../captures/night/plum_{tag}_{view}_{v}.png").convert("RGB").resize((W, H))
    sheet.paste(im, ("ABC".index(v) * W, (int(view[1]) - 1) * H))
sheet.save(f"../captures/night/plum_{tag}_sheet.png")
print("done")
