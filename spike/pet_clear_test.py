"""v15: is the lead pet ever left inside a Clay column? python spike/pet_clear_test.py"""
import pathlib, sys, time
here = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(here))
import night as N
P = "local p=game.Players:GetPlayers()[1] "
N.play(False); N.play(True); time.sleep(6)
N.lua(P + "p:SetAttribute('DevPet','Shinemane') return 1", "Server"); time.sleep(2)
N.lua("local g=game.Players.LocalPlayer.PlayerGui:FindFirstChild('DailyChest') if g then g.Enabled=false end return 1", "Client")
N.key("Q"); time.sleep(26)  # DevClay works from the caves: ride down to Camp 1 first (clay_v14_shots.py)
N.lua(P + "p:SetAttribute('DevClay',2) return 1", "Server")
for _ in range(30):
    st = N.lua("local p=game.Players.LocalPlayer return tostring(p:GetAttribute('InCave'))..' '..tostring(p.CameraMode)..' '..tostring(workspace.CurrentCamera.CameraType)", "Client")
    if "true Enum.CameraMode.LockFirstPerson Enum.CameraType.Custom" in st: break
    time.sleep(2)
print("state", st); time.sleep(2)
r = N.lua((here / "pet_clear.luau").read_text(encoding="utf-8"), "Client")
print(r)
N.shot("pet_clear_last")
print("RESULT", "PASS" if "in rock 0" in r and "tried 0" not in r else "FAIL")
