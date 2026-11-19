"""Hatch cutscene stills (Play running): python spike/hatch_shots.py <prefix> [pet] -> captures/night/<prefix>_<t>.png
Holds Shared.HatchScene at fixed moments with its freeze hook (Legendary: arrive 1.0, build 3.5, hang 4.2, burst 4.52, reveal 6.2)."""
import sys, time
import night as N
pre = sys.argv[1]; pet = sys.argv[2] if len(sys.argv) > 2 else "Fafnir"
for f in (1.0, 3.5, 4.2, 4.6, 6.2):
    # the call stays open for the whole scene: when an execute_luau call returns, the MCP plugin takes the view back to its own
    # camera and the captures showed the town under the hatch's letterbox (2026-11-19). cutscene_rec.py works the same way.
    import threading
    th = threading.Thread(target=N.lua, args=(f'''local p=game.Players.LocalPlayer p:SetAttribute("DevHatchFreeze",{f}) p:SetAttribute("DevHatch","") p:SetAttribute("DevHatch","{pet}") task.wait({f} + 4) return "ok"''', "Client"))
    th.start()
    time.sleep(f + 1.6)
    N.shot(f"{pre}_{f}")
    th.join()
    time.sleep(1)
print("done")
