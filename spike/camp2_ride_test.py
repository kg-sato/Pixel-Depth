"""Task 1 check (2026-11-19): ride down to the Kiln Camp and take stills every 0.4 s; no frame may show the open sky.
    python spike/camp2_ride_test.py     stills: captures/camp2ride/NN.png, verdict printed (sky-blue share per frame)"""
import pathlib, sys, time, threading
here = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(here))
import night as N
out = here.parent / "captures" / "camp2ride"; out.mkdir(parents=True, exist_ok=True)
if '--check' not in sys.argv:
  for f in out.glob('*.png'): f.unlink()
  N.push(); N.play(True); time.sleep(4)
  N.lua("""local p=game.Players:GetPlayers()[1] local R=game.ReplicatedStorage.Remotes
p.Character.HumanoidRootPart.Anchored=true
R.Fx:FireClient(p,"ride",false,true)
task.delay(1.25,function() local l=workspace.Caves:FindFirstChild("ClayLanding",true) p.Character.HumanoidRootPart.CFrame=l.CFrame+Vector3.new(0,3,0) p:SetAttribute("InCave",true) end)
task.delay(8,function() p.Character.HumanoidRootPart.Anchored=false end) return 1""", "Server")
  t0 = time.time(); i = 0
  while time.time() - t0 < 11:
    p = N.shot("_c2"); pathlib.Path(p).replace(out / f"{i:02d}.png"); i += 1
  N.play(False)
try:
    import cv2, numpy as np
except ImportError:
    sys.exit('stills taken; rerun the check with the Hunyuan3D venv python: python spike/camp2_ride_test.py --check')
for f in sorted(out.glob("*.png")):
    im = cv2.imread(str(f)); hsv = cv2.cvtColor(im, cv2.COLOR_BGR2HSV)
    sky = ((hsv[..., 0] > 95) & (hsv[..., 0] < 115) & (hsv[..., 1] > 120) & (hsv[..., 2] > 90)).mean()
    print(f.name, f"sky {sky:.2f}", "VOID" if sky > 0.5 else "")
