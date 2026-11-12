"""Record the Secret hatch cutscene to captures/video/<name>.mp4 (the window recorder needs the Hunyuan3D venv python).
    python spike/hatch_video.py [name] [pet]     then: python ../../tools/video_judge.py <mp4> "<intent>" --name <label>"""
import subprocess, sys, time, pathlib
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import night
name = sys.argv[1] if len(sys.argv) > 1 else "hatch_cine"
pet = sys.argv[2] if len(sys.argv) > 2 else "Ninering"
out = night.game / "captures" / "video"; out.mkdir(parents=True, exist_ok=True)
night.play(True); time.sleep(5)
rec = subprocess.Popen([str(night.root / "Hunyuan3D" / ".venv" / "Scripts" / "python.exe"), "-I", str(night.root / "tools" / "record_window.py"), str(out / f"{name}.mp4"), "12", "30"], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
time.sleep(0.5)
night.lua(f"game.ReplicatedStorage.Remotes.Fx:FireClient(game.Players:GetPlayers()[1], 'hatch', '{pet}') return 1", "Server")
print((rec.communicate()[0] or "").strip().splitlines()[-1:])
night.play(False)
