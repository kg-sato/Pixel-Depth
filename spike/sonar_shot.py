"""Catch the sonar shell mid-flight: press T and capture at several delays (the pulse lasts 1.4 s, cooldown 12 s).
    python spike/sonar_shot.py [nocave]     shots in captures/night/sonar_<delay>.png; prints what the client saw of the shell"""
import sys, threading, time, pathlib
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import night

WATCH = ("local seen, big = 0, 0 local t0 = os.clock() while os.clock() - t0 < 4 do local f = workspace:FindFirstChild('Sonar') local s = f and f:FindFirstChild('Shell') "
         "if s then seen += 1 big = math.max(big, s.Size.Z) end task.wait() end "
         "return 'frames with shell ' .. seen .. ', largest scale ' .. math.floor(big)")

if __name__ == "__main__":
    if "nocave" not in sys.argv:
        night.play(True); time.sleep(8); night.key("Q"); time.sleep(33)
    for d in (0.0, 0.25, 0.5, 0.8):
        res = {}
        w = threading.Thread(target=lambda: res.setdefault("w", night.lua(WATCH, "Client")))
        w.start(); time.sleep(0.8)
        k = threading.Thread(target=night.key, args=("T",)); k.start()
        time.sleep(d)
        t = time.time(); p = night.shot(f"sonar_{int(d * 100):03d}")
        k.join(); w.join()
        print(d, p.name, "shot took %.2f s" % (time.time() - t), (res.get("w") or "").splitlines()[-1:])
        time.sleep(12.5)
