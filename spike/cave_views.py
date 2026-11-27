"""Stills of the live caves for the 2026-11-27 mine overhaul (Play running, player in town):
   python spike/cave_views.py <tag> [view ...]   rides down to Camp 1 first unless already in the caves
   Each view puts a scripted camera at an eye point looking at a target (cave spots, the zip line, the Clay hall), with the HUD off."""
import sys, time, pathlib
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import night
tag = sys.argv[1] if len(sys.argv) > 1 else "t"
only = sys.argv[2:] or None
inCave = night.lua("return tostring(game.Players:GetPlayers()[1]:GetAttribute('InCave'))", "Server").splitlines()[-1]
if inCave != "true":
    night.lua("game.ReplicatedStorage.Remotes.Surface:FireServer('down') return 'ok'", "Client")
    for _ in range(40):
        time.sleep(2)
        if night.lua("return tostring(game.Players:GetPlayers()[1]:GetAttribute('InCave'))", "Server").splitlines()[-1] == "true": break
    time.sleep(8)
# eye and target as Luau expressions; S(n) = a cave spot, Z = the first zip rope's two ends, K = the Clay hall origin
VIEWS = {
    "camp": ("S('Camp')+Vector3.new(26,14,22)", "S('Camp')+Vector3.new(0,1,0)"),
    "campedge": ("S('Camp')+Vector3.new(-6,9,-4)", "S('Camp')+Vector3.new(-30,0,10)"),
    "zip": ("ZA+(ZB-ZA).Unit*-6+Vector3.new(0,-2,0)", "ZB+Vector3.new(0,-3,0)"),
    "zipside": ("(ZA+ZB)/2+Vector3.new(0,6,0)+((ZB-ZA):Cross(Vector3.yAxis)).Unit*22", "(ZA+ZB)/2"),
    "sump": ("S('SumpGate')+Vector3.new(14,10,14)", "S('SumpGate')"),
    "canyon": ("S('Canyon')+Vector3.new(10,9,10)", "S('Canyon')+Vector3.new(0,-3,0)"),
    "kiln": ("K+Vector3.new(40,26,40)", "K+Vector3.new(0,2,0)"),
    "kilnwall": ("K+Vector3.new(0,16,10)", "K+Vector3.new(-50,10,-40)"),
    "kilnwall2": ("K+Vector3.new(0,16,10)", "K+Vector3.new(55,10,-30)"),
}
HEAD = ("local C=require(game.ReplicatedStorage.Shared.Config) local cv=workspace.Caves "
        "local function S(n) local o=cv:FindFirstChild('Spot_'..n) local a=o and o.Value return a and (a:IsA('Attachment') and a.WorldPosition or a.Position) or C.CAVE_ORIGIN end "
        "local zr for _,r in cv.Ziplines:GetChildren() do if r:GetAttribute('ZipA') then zr=r break end end local ZA=zr and zr:GetAttribute('ZipA') or C.CAVE_ORIGIN local ZB=zr and zr:GetAttribute('ZipB') or C.CAVE_ORIGIN "
        "local K=C.CAVE2_ORIGIN ")
for name, (eye, at) in VIEWS.items():
    if only and name not in only: continue
    night.lua(HEAD + f"local p=game.Players:GetPlayers()[1] if workspace.StreamingEnabled then pcall(function() p:RequestStreamAroundAsync({eye}, 10) end) end return 'ok'", "Server")
    code = (HEAD + f"local eye={eye} local at={at} local RS=game:GetService('RunService') pcall(function() RS:UnbindFromRenderStep('CaveViewCam') end) "
            "local off={} for _,g in game.Players.LocalPlayer.PlayerGui:GetChildren() do if g:IsA('ScreenGui') and g.Enabled then g.Enabled=false table.insert(off,g) end end "
            "local torch=workspace:FindFirstChild('CaveViewTorch') or Instance.new('Part') torch.Name='CaveViewTorch' torch.Anchored=true torch.CanCollide=false torch.Transparency=1 torch.Size=Vector3.one torch.Parent=workspace "
            "local tl=torch:FindFirstChildOfClass('PointLight') or Instance.new('PointLight', torch) tl.Color=Color3.fromRGB(255,190,120) tl.Range=50 tl.Brightness=1.1 tl.Shadows=true "
            "RS:BindToRenderStep('CaveViewCam', Enum.RenderPriority.Camera.Value+40, function() local cam=workspace.CurrentCamera cam.CameraType=Enum.CameraType.Scriptable cam.FieldOfView=74 cam.CFrame=CFrame.lookAt(eye, at) torch.CFrame=CFrame.new(eye) end) "
            "task.delay(6, function() pcall(function() RS:UnbindFromRenderStep('CaveViewCam') end) for _,g in off do g.Enabled=true end end) return 1")
    night.lua(code, "Client")
    time.sleep(2.5)
    print(name, night.shot(f"cave_{tag}_{name}"))
    time.sleep(3.8)
