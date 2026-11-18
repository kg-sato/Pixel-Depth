"""Signature hatch stills (Play running): python spike/sig_shots.py <prefix> [Pet ...] -> captures/night/<prefix>_<pet>_<t>.png
Holds Shared.HatchScene with its freeze hook inside each pet's omen (Shared.HatchSignature), on the burst and in the reveal."""
import sys, time
import night as N
AB = {"Fafnir": (3.96, 1.8, 0.5), "Kirin": (3.96, 1.9, 0.5), "Ouro": (4.28, 2.0, 0.55), "Ninering": (4.6, 2.6, 0.6)}  # build end, omen, hang
pre = sys.argv[1]
for pet in sys.argv[2:] or list(AB):
    ab, om, hang = AB[pet]
    a3 = ab + om + hang
    for f in (round(ab + om * 0.45, 2), round(ab + om * 0.9, 2), round(a3 + 0.12, 2), round(a3 + 1.8, 2)):
        N.lua(f'''local p=game.Players.LocalPlayer p:SetAttribute("DevHatchFreeze",{f}) p:SetAttribute("DevHatch","") p:SetAttribute("DevHatch","{pet}") return "ok"''', "Client")
        time.sleep(f + 0.9)
        N.shot(f"{pre}_{pet}_{f}")
        time.sleep(4)
print("done")
