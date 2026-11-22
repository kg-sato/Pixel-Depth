"""Cave light A/B (2026-11-22, Gemini full1122d: "mid-distance cavern paths turn into muddy voids"): rides down to Camp 1, then at
four layout spots looks down the longest sightline and takes one still per atmosphere variant, set on the client only.
    python spike/cave_light_ab.py <tag>      stills: captures/night/lab_<tag>_<spot>_<variant>.png (Play is started and stopped here)"""
import sys, time
import night as N
tag = sys.argv[1] if len(sys.argv) > 1 else "a"
C = lambda code: (N.lua(code, "Client").splitlines() or ["?"])[-1]
S = lambda code: (N.lua(code, "Server").splitlines() or ["?"])[-1]
VARIANTS = {  # Atmosphere on the client; A is whatever the game set
    "A": None,
    "B": "Density=0.32 a.Haze=0.4",
    "C": "Density=0.38 a.Haze=0.3 a.Color=Color3.fromRGB(30,20,52) a.Decay=Color3.fromRGB(14,8,26)",
    "D": None,
}
SPOTS = ["Canyon", "Cathedral", "OldTube", "B2"]
N.play(False); time.sleep(2); N.play(); time.sleep(10)
C("local g=game.Players.LocalPlayer.PlayerGui:FindFirstChild('DailyChest') if g then g.Enabled=false end return 1")
N.key("Q"); time.sleep(26)  # the ride down to Camp 1
print("in cave:", S("return tostring(game.Players:GetPlayers()[1]:GetAttribute('InCave'))"))
base = C("local a=game.Lighting:FindFirstChildOfClass('Atmosphere') a:SetAttribute('labD',a.Density) a:SetAttribute('labH',a.Haze) a:SetAttribute('labC',a.Color) a:SetAttribute('labY',a.Decay) "
         "return a.Density..' '..a.Haze..' '..tostring(a.Color)..' '..tostring(a.Decay)")
print("atmosphere A:", base)
for spot in SPOTS:
    ok = S("local a=workspace.Terrain:FindFirstChild('Spot_%s') if not a then return 'none' end local p=game.Players:GetPlayers()[1] "
           "p.Character:PivotTo(CFrame.new(a.WorldPosition+Vector3.new(0,3,0))) p.Character.HumanoidRootPart.Anchored=true return 'ok'" % spot)
    if ok != "ok":
        print(spot, "no spot"); continue
    time.sleep(2.5)
    C("local a=workspace.Terrain:FindFirstChild('Spot_%s') local rp=RaycastParams.new() rp.FilterType=Enum.RaycastFilterType.Include rp.FilterDescendantsInstances={workspace.Caves} "
      "local eye=a.WorldPosition+Vector3.new(0,4.5,0) local best,bd=Vector3.xAxis,-1 for i=0,15 do local an=i*math.pi/8 local d=Vector3.new(math.cos(an),0,math.sin(an)) "
      "local r=workspace:Raycast(eye,d*200,rp) local m=r and r.Distance or 200 if m>bd then best,bd=d,m end end "
      "local cf=CFrame.lookAt(eye,eye+(best+Vector3.new(0,-0.12,0)).Unit*20) local RS=game:GetService('RunService') RS:UnbindFromRenderStep('labcam') "
      "RS:BindToRenderStep('labcam',2001,function() workspace.CurrentCamera.CFrame=cf end) return bd" % spot)
    for v, setv in VARIANTS.items():
        if setv:
            C("local a=game.Lighting:FindFirstChildOfClass('Atmosphere') local RS=game:GetService('RunService') RS:UnbindFromRenderStep('labatmo') "
              "RS:BindToRenderStep('labatmo',2002,function() a.%s end) return 1" % setv)
        if v == "D":  # the walls in Rock (stronger relief), the floors stay Slate: a material contrast between walking and wall surfaces
            C("for _,d in workspace.Caves:GetDescendants() do if d:IsA('BasePart') and d.Name=='Rock' and d.Material==Enum.Material.Slate then d.Material=Enum.Material.Rock d:SetAttribute('labRock',true) end end return 1")
        time.sleep(1.5)
        N.shot(f"lab_{tag}_{spot}_{v}")
        if v == "D":
            C("for _,d in workspace.Caves:GetDescendants() do if d:GetAttribute('labRock') then d.Material=Enum.Material.Slate d:SetAttribute('labRock',nil) end end return 1")
        C("game:GetService('RunService'):UnbindFromRenderStep('labatmo') local a=game.Lighting:FindFirstChildOfClass('Atmosphere') "
          "a.Density=a:GetAttribute('labD') a.Haze=a:GetAttribute('labH') a.Color=a:GetAttribute('labC') a.Decay=a:GetAttribute('labY') return 1")
C("game:GetService('RunService'):UnbindFromRenderStep('labcam') return 1")
N.play(False)
print("done")
