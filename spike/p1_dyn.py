"""Dynamic HUD check: town calm with the setting on (does the chrome slide away?), a key wakes it; touch layout in the caves.
    python spike/p1_dyn.py <prefix>"""
import sys, time
import night as N
pre = sys.argv[1] if len(sys.argv) > 1 else "p1"
S = lambda code: (N.lua(code, "Server").splitlines() or ["?"])[-1]
C = lambda code: (N.lua(code, "Client").splitlines() or ["?"])[-1]
P = "local p=game.Players:GetPlayers()[1] local h=p.Character.HumanoidRootPart "
N.play(True); time.sleep(12)
C("local g=game.Players.LocalPlayer.PlayerGui:FindFirstChild('DailyChest') if g then g.Enabled=false end return 1")
S(P + "local rp=RaycastParams.new() rp.FilterDescendantsInstances={p.Character} local best for _,o in {Vector3.new(34,0,30),Vector3.new(-34,0,30),Vector3.new(30,0,-34),Vector3.new(-30,0,-30)} do local r=workspace:Raycast(h.Position+o+Vector3.new(0,60,0),Vector3.new(0,-120,0),rp) if r and not best then best=r.Position end end if best then h.CFrame=CFrame.new(best+Vector3.new(0,3,0)) end return 1"); time.sleep(2)
C("game.Players.LocalPlayer:SetAttribute('HudDynamic',true) return 1"); time.sleep(11)
print("calm: left column x", C("return game.Players.LocalPlayer.PlayerGui.PixelHUD.LeftColumn.Position.X.Scale"))
N.shot(pre + "_town_dyn")
N.key("J"); time.sleep(0.8); N.key("J"); time.sleep(0.6)
print("after a key: x", C("return game.Players.LocalPlayer.PlayerGui.PixelHUD.LeftColumn.Position.X.Scale"))
C("game.Players.LocalPlayer:SetAttribute('HudDynamic',nil) return 1")
S(P + "game.ReplicatedStorage.Remotes.Surface:FireServer() return 1")
S(P + "p:SetAttribute('DevRidden',true) return 1")
print("down:", S(P + "local ok=pcall(function() game.ReplicatedStorage.Remotes.Fx.Parent:FindFirstChild('Surface') end) return tostring(ok)"))
C("game.ReplicatedStorage.Remotes.Surface:FireServer('down') return 1"); time.sleep(16)
C("game.Players.LocalPlayer:SetAttribute('DevTouch',true) return 1"); time.sleep(2)
print("in cave:", C("return tostring(game.Players.LocalPlayer:GetAttribute('InCave'))"))
N.shot(pre + "_touch_cave")
C("game.Players.LocalPlayer:SetAttribute('DevTouch',nil) return 1")
print("errors:", C("local t={} for _,m in game:GetService('LogService'):GetLogHistory() do if m.messageType==Enum.MessageType.MessageError and not m.message:find('not authorized') then t[m.message:sub(1,160)]=true end end local o={} for k in t do table.insert(o,k) end return #o..' '..table.concat(o,' ## ')"))
