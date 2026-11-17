"""Perfect Strike juice check (Play running, in the caves): one run struck early, then one struck on the gold three times
(the flawless path); stills a moment after each swing.  python spike/sj_test.py <prefix>  -> captures/night/<prefix>_*.png"""
import sys, time
import night as N
pre = sys.argv[1]
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
SW = ("local hud=game.Players.LocalPlayer.PlayerGui.PixelHUD.CaveHud.PerfectStrike local nd,ar=hud:FindFirstChild('Needle',true),hud:FindFirstChild('Arc',true) "
      "local function d() return (nd.Rotation-ar.Rotation+180)%360-180 end local RS=game:GetService('RunService') local t0,pv=os.clock(),d() while os.clock()-t0<3 do RS.RenderStepped:Wait() local v=d() if pv<({off}) and v>=({off}) and v-pv<60 then break end pv=v end "
      "local v=d() game.Players.LocalPlayer:SetAttribute('DevJuiceHold',true) game.Players.LocalPlayer:SetAttribute('DevStrike',os.clock()) return v")
def run(tag, offs):
    print(tag, go_to("d:GetAttribute('Ore')<3")); time.sleep(1.2); face()
    N.key("E"); time.sleep(1.0)
    for i, off in enumerate(offs):
        print(" swing", i + 1, N.lua(SW.replace("{off}", str(off)), "Client").splitlines()[-1])
        time.sleep(0.05); N.shot(f"{pre}_{tag}_{i + 1}")
        time.sleep(0.5)
    time.sleep(2.5)
run(sys.argv[2], [float(x) for x in sys.argv[3].split(",")])
