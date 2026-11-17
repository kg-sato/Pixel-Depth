"""Hatch cutscene stills (Play running): python spike/hatch_shots.py <prefix> [pet] -> captures/night/<prefix>_<t>.png
Holds Shared.HatchScene at fixed moments with its freeze hook (Legendary: arrive 1.0, build 3.5, hang 4.2, burst 4.52, reveal 6.2)."""
import sys, time
import night as N
pre = sys.argv[1]; pet = sys.argv[2] if len(sys.argv) > 2 else "Fafnir"
for f in (1.0, 3.5, 4.2, 4.6, 6.2):
    N.lua(f'''local p=game.Players.LocalPlayer p:SetAttribute("DevHatchFreeze",{f}) p:SetAttribute("DevHatch","") p:SetAttribute("DevHatch","{pet}") return "ok"''', "Client")
    time.sleep(f + 1.4)
    N.shot(f"{pre}_{f}")
    time.sleep(4)
print("done")
