"""Signature hatch stills (Play running): python spike/sig_shots.py <prefix> [Pet ...] -> captures/night/<prefix>_<pet>_<t>.png
Holds Shared.HatchScene with its freeze hook inside each pet's omen (Shared.HatchSignature), on the burst and in the reveal."""
import sys, time
import night as N
AB = {"Fafnir": (3.96, 1.8, 1.13), "Kirin": (3.96, 1.9, 1.13), "Ouro": (4.28, 2.0, 1.19), "Ninering": (4.6, 2.6, 1.25)}  # build end, omen, hang (hang 0.95 + k * 0.3 since directive v13)
pre = sys.argv[1]
for pet in sys.argv[2:] or list(AB):
    ab, om, hang = AB[pet]
    a3 = ab + om + hang
    for f in (round(ab + om * 0.45, 2), round(ab + om * 0.9, 2), round(a3 + 0.12, 2), round(a3 + 1.8, 2)):
        N.lua(f'''local p=game.Players.LocalPlayer p:SetAttribute("DevHatchFreeze",{f}) return "ok"''', "Client")
        N.lua(f'''game.ReplicatedStorage.Remotes.Fx:FireClient(game.Players:GetPlayers()[1], 'hatch', '{pet}') return 1''', "Server")  # 2026-11-20: the client DevHatch hook went with the old 2D show
        time.sleep(f + 0.9)
        N.shot(f"{pre}_{pet}_{f}")
        time.sleep(14)  # let this hatch finish: a hatch fired while one plays is dropped (2026-11-20, Kirin stills showed the town)
print("done")
