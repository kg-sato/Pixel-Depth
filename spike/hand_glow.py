"""Which light blows out the first-person hand? Run in Play, in the cave. Prints the mean colour of the hand crop for each case."""
import subprocess, sys, pathlib
from PIL import Image
here = pathlib.Path(__file__).resolve().parent
def night(*a): return subprocess.run([sys.executable, str(here / "night.py"), *a], capture_output=True, text=True).stdout
def mean(name):
    night("shot", name)
    im = Image.open(here.parent / "captures" / "night" / f"{name}.png").convert("RGB"); w, h = im.size
    px = list(im.crop((int(w * 0.58), int(h * 0.82), int(w * 0.74), int(h * 0.99))).getdata())
    return tuple(sum(c[i] for c in px) // len(px) for i in range(3))
CASES = {
    "base": "return 1",
    "lantern0": "local l=game.Players.LocalPlayer.Character:FindFirstChild('Lantern',true) l.Enabled=false return 1",
    "platform0": "for _,d in workspace.Caves.Camp:GetDescendants() do if d:IsA('Light') then d.Enabled=false end end return 1",
    "alllights0": "for _,d in workspace:GetDescendants() do if d:IsA('Light') then d.Enabled=false end end return 1",
    "exposure0": "game.Lighting.ExposureCompensation=0 return 1",
    "ambient0": "game.Lighting.Ambient=Color3.new() game.Lighting.OutdoorAmbient=Color3.new() game.Lighting.EnvironmentDiffuseScale=0 game.Lighting.EnvironmentSpecularScale=0 return 1",
    "noneon": "for _,d in workspace.CurrentCamera:GetDescendants() do if d:IsA('BasePart') and d.Material==Enum.Material.Neon then d.Transparency=1 end end return 1",
}
for name, code in CASES.items():
    night("lua", "Client", code)
    print(name, mean("glow_" + name), flush=True)
