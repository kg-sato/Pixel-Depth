"""Record the hatch cutscene through the DevHatch hook (Play started and settled first; the Fx remote fired too early in hatch_video.py).
    python spike/hatch_video2.py <name> [pet]  -> captures/video/<name>.mp4"""
import subprocess, sys, time, pathlib
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import night
name = sys.argv[1]; pet = sys.argv[2] if len(sys.argv) > 2 else "Fafnir"
out = night.game / "captures" / "video"; out.mkdir(parents=True, exist_ok=True)
night.play(True); time.sleep(15)
rec = subprocess.Popen([str(night.root / "Hunyuan3D" / ".venv" / "Scripts" / "python.exe"), "-I", str(night.root / "tools" / "record_window.py"), str(out / f"{name}.mp4"), "11", "30"], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
time.sleep(0.6)
night.lua(f'local p=game.Players.LocalPlayer p:SetAttribute("DevHatchFreeze",nil) p:SetAttribute("DevHatch","") p:SetAttribute("DevHatch","{pet}") return 1', "Client")
print((rec.communicate()[0] or "").strip().splitlines()[-1:])
night.play(False)
