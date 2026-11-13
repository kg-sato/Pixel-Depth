"""Do the loading logo's letters land one at a time? Starts Play and reads the player attribute DevLoadTimes (the wall-clock
second each of the ten letters appeared, written by Shared.LoadingScreen when the word shakes). Passes when there are ten
times, no two letters are closer than 50 ms, and the whole landing takes at least 0.8 s.   python spike/load_test.py"""
import time
import night as N
N.play(True); time.sleep(6)
raw = ""
for _ in range(6):
    raw = N.lua("return tostring(game.Players.LocalPlayer:GetAttribute('DevLoadTimes'))", "Client").splitlines()[-1]
    if raw != "nil": break
    time.sleep(2)
ts = [float(x) for x in raw.split()] if raw != "nil" else []
gaps = [round(b - a, 2) for a, b in zip(ts, ts[1:])]
ok = len(ts) == 10 and min(gaps) >= 0.05 and ts[-1] - ts[0] >= 0.8
print("letters", len(ts), "| smallest gap", min(gaps) if gaps else None, "| whole landing", round(ts[-1] - ts[0], 2) if ts else None, "| one by one:", "yes" if ok else "NO")
