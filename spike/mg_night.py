"""Minigame captures for the night pass (Play running, player in town or in the caves): Perfect Strike (the brass gauge),
Vein Rush (the crystal spire, played through the real keys) and the result card.
    python spike/mg_night.py <prefix> [strike] [rush]      captures go to captures/night/<prefix>_*.png"""
import sys, time
import night as N

pre = sys.argv[1]
want = sys.argv[2:] or ["strike", "rush"]
P = 'local p=game.Players:GetPlayers()[1] local h=p.Character.HumanoidRootPart '


def go_to(which):
    return N.lua(P + "local best,bd for _,d in workspace.Caves.Deposits:GetChildren() do if (" + which + ") and d.PrimaryPart.Transparency<1 then "
                 "local m=(d.PrimaryPart.Position-Vector3.new(-3000,0,0)).Magnitude if not bd or m<bd then best,bd=d,m end end end "
                 "if not best then return 'none' end local c=best.PrimaryPart local at=c.Position-c.CFrame.LookVector*Vector3.new(1,0,1)*6+Vector3.new(0,3,0) "
                 "h.CFrame=CFrame.lookAt(at,Vector3.new(c.Position.X,at.Y,c.Position.Z)) return best:GetAttribute('OreName')").splitlines()[-1]


def face():
    N.lua("local c=workspace.CurrentCamera local best,bd for _,d in workspace.Caves.Deposits:GetChildren() do local m=(d.PrimaryPart.Position-c.CFrame.Position).Magnitude "
          "if not bd or m<bd then best,bd=d,m end end c.CFrame=CFrame.lookAt(c.CFrame.Position,best.PrimaryPart.Position) return bd", "Client")
    time.sleep(0.5)


if "InCave" not in N.lua("return game.Players:GetPlayers()[1]:GetAttribute('InCave') and 'InCave' or 'town'"):
    N.key("Q"); time.sleep(15)

if "strike" in want:
    print("common:", go_to("d:GetAttribute('Ore')<3")); time.sleep(1.2); face()
    N.key("E"); time.sleep(0.8); N.shot(pre + "_strike")
    print(N.lua("local hud=game.Players.LocalPlayer.PlayerGui.PixelHUD.CaveHud.PerfectStrike local nd,ar=hud:FindFirstChild('Needle',true),hud:FindFirstChild('Arc',true) "
                "local R=game.ReplicatedStorage.Remotes.Extract local t0=os.clock() while os.clock()-t0<3 do if math.abs((nd.Rotation-ar.Rotation+180)%360-180)<5 then break end task.wait() end "
                "R:FireServer('strike',workspace:GetServerTimeNow()) return 'struck'", "Client").splitlines()[-1])
    time.sleep(0.12); N.shot(pre + "_strike_hit")
    for _ in range(2):
        time.sleep(0.6)
        N.lua("local hud=game.Players.LocalPlayer.PlayerGui.PixelHUD.CaveHud.PerfectStrike local nd,ar=hud:FindFirstChild('Needle',true),hud:FindFirstChild('Arc',true) "
              "local t0=os.clock() while os.clock()-t0<3 do if math.abs((nd.Rotation-ar.Rotation+180)%360-180)<5 then break end task.wait() end "
              "game.ReplicatedStorage.Remotes.Extract:FireServer('strike',workspace:GetServerTimeNow()) return 1", "Client")
    time.sleep(1.3); N.shot(pre + "_result"); time.sleep(2.5)

if "rush" in want:
    print("rare:", go_to("d:GetAttribute('Ore')==3")); time.sleep(1.2); face()
    N.key("E"); time.sleep(0.9); N.shot(pre + "_rush_start")
    seq = N.lua("return game.Players.LocalPlayer.PlayerGui.PixelHUD.CaveHud.VeinRush:GetAttribute('Seq') or ''", "Client").splitlines()[-1].strip()
    print("seq", seq)
    for i, c in enumerate(seq):
        N.key("D" if c == "1" else "A")  # chisel the side without the fissure
        if i == 1: N.shot(pre + "_rush_mid")
    time.sleep(1.2); N.shot(pre + "_rush_result")
print(N.lua("local t={} for _,l in game.LogService:GetLogHistory() do if l.messageType==Enum.MessageType.MessageError then table.insert(t,l.message:sub(1,220)) end end return table.concat(t,'\\n')", "Client")[-600:])
