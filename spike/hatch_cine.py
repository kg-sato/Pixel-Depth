"""Capture the Secret hatch cutscene: fire Fx "hatch" for the Secret pet and take shots at several moments.
    python spike/hatch_cine.py [pet]     shots captures/night/cine_<n>.png (Play must be stopped: it starts Play itself)"""
import sys, threading, time, pathlib
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import night
pet = sys.argv[1] if len(sys.argv) > 1 else "Ninering"
night.play(True); time.sleep(5)
night.lua(f"game.ReplicatedStorage.Remotes.Fx:FireClient(game.Players:GetPlayers()[1], 'hatch', '{pet}') return 1", "Server")
t0 = time.time(); ths = []
for i, d in enumerate((0.0, 1.0, 3.0, 4.6, 6.0, 9.0)):
    def go(i=i, d=d):
        time.sleep(max(0, d - (time.time() - t0)))
        p = night.shot(f"cine_{i}"); print(i, d, "done at %.1f" % (time.time() - t0))
    th = threading.Thread(target=go); th.start(); ths.append(th)
for th in ths: th.join()
