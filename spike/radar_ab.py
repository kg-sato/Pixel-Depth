"""A/B captures for the heading-up radar: the same cave spot with the north-up radar (A) and the heading-up radar (B).
    python spike/radar_ab.py      shots captures/night/radar_a.png and radar_b.png"""
import sys, time, pathlib
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import night
from prompt_test import SAFE
night.play(True); time.sleep(8); night.key("Q"); time.sleep(33)
print(night.lua(SAFE + "local C=require(game.ReplicatedStorage.Shared.Config) local best for _,d in workspace.Caves.Deposits:GetChildren() do if d:IsA('Model') and d.PrimaryPart then local m=(d.PrimaryPart.Position-C.CAVE_ORIGIN).Magnitude if m>45 and m<95 then best=d break end end end "
                "local h=game.Players:GetPlayers()[1].Character.HumanoidRootPart local at=safe(best.PrimaryPart.Position) h.CFrame=CFrame.lookAt(at, at+Vector3.new(1,0,0.4)) return 'dist '..math.floor((at-C.CAVE_ORIGIN).Magnitude)", "Server").splitlines()[-1])
time.sleep(3)
night.shot("radar_a")
night.lua("game.Players.LocalPlayer:SetAttribute('DevHeadingUp',1) return 1", "Client"); time.sleep(1)
night.shot("radar_b")
print(night.lua(open(pathlib.Path(__file__).resolve().parent / "hud_overlap.luau", encoding="utf-8").read(), "Client").splitlines()[-1])
