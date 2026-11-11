"""Level pictures of the Clay Caves hall for grading. Studio open in Edit mode. Writes captures/night/clayv_*.png.
The first-person camera cannot be aimed from a script, so each picture sets the camera Scriptable at a fixed place."""
import subprocess, sys, time, pathlib
here = pathlib.Path(__file__).resolve().parent
def night(*a): return (subprocess.run([sys.executable, str(here / "night.py"), *a], capture_output=True, text=True).stdout.strip().splitlines() or ["?"])[-1]
P = "local p=game.Players:GetPlayers()[1] local h=p.Character.HumanoidRootPart local O=require(game.ReplicatedStorage.Shared.Config).CAVE2_ORIGIN "
def cam(a, b): night("lua", "Client", f"local O=require(game.ReplicatedStorage.Shared.Config).CAVE2_ORIGIN local c=workspace.CurrentCamera c.CameraType=Enum.CameraType.Scriptable c.CFrame=CFrame.lookAt(O+Vector3.new({a}),O+Vector3.new({b})) return 1")
night("play"); time.sleep(2); night("key", "Q"); time.sleep(25)
night("lua", "Server", P + "p:SetAttribute('DevClay',2) return 1"); time.sleep(4)
cam("-60,9,0", "20,8,0"); time.sleep(0.6); night("shot", "clayv_hall")
night("lua", "Server", P + "h.CFrame=CFrame.new(O+Vector3.new(-14,3,8)) return 1"); time.sleep(1)
cam("-16,7,10", "0,5,-12"); time.sleep(0.6); night("shot", "clayv_camp")
night("lua", "Server", P + "h.CFrame=CFrame.new(O+Vector3.new(38,3,-26)) return 1")
cam("20,14,-2", "50,26,-26")
for _ in range(60):
    if "up" in night("lua", "Client", "local h=game.Players.LocalPlayer.Character.HumanoidRootPart return h.Position.Y>30 and 'up' or 'no'"): break
time.sleep(0.8); night("shot", "clayv_glide")
night("lua", "Server", P + "h.CFrame=CFrame.new(O+Vector3.new(-30,3,40)) return 1"); time.sleep(1)
cam("-22,6,38", "-30,4.5,53"); time.sleep(0.6); night("shot", "clayv_fossil")
night("lua", "Client", "workspace.CurrentCamera.CameraType=Enum.CameraType.Custom return 1")
from PIL import Image
ims = [Image.open(here.parent / "captures" / "night" / f"clayv_{n}.png").convert("RGB") for n in ("hall", "camp", "glide", "fossil")]
w = 960; ims = [i.resize((w, int(i.height * w / i.width))) for i in ims]
out = Image.new("RGB", (w * 2, ims[0].height * 2))
for k, i in enumerate(ims): out.paste(i, ((k % 2) * w, (k // 2) * ims[0].height))
out.save(here.parent / "captures" / "night" / "clayv_all.jpg", quality=84)
print("done")
