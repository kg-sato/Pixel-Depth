"""Directive v9 retention and friends boost: does the server decide the playtime gifts, the Golden Vein Surge and the
Lantern Tether?   python spike/retention_test.py
Shortcuts: DevGiftSecs sets the seconds played today, DevGold starts a short surge, DevFriends counts as friends in the server;
the player is put in the caves by the ride (key Q)."""
import time
import night as N
C1 = lambda code: (N.lua(code, "Client").splitlines() or ["?"])[-1]
S1 = lambda code: (N.lua(code, "Server").splitlines() or ["?"])[-1]
P = "local p=game.Players:GetPlayers()[1] local h=p.Character.HumanoidRootPart "
N.play(True); time.sleep(8)
C1("local p=game.Players.LocalPlayer p:SetAttribute('DevPaid','') game.ReplicatedStorage.Remotes.Fx.OnClientEvent:Connect(function(k,a,b,c) if k=='giftPaid' then p:SetAttribute('DevPaid',(p:GetAttribute('DevPaid') or '')..' '..tostring(a)..':'..tostring(b)) end end) return 1")
PILL = "local g=game.Players.LocalPlayer.PlayerGui:FindFirstChild('Timers',true) return g and (g.Gift.Line.Text..' | '..tostring(g.Event.Visible and g.Event.Line.Text)) or 'no pills'"
print("pills at the start:", C1(PILL))
CLAIM = "game.ReplicatedStorage.Remotes.Gift:FireServer('claim') task.wait(0.9) return tostring(game.Players.LocalPlayer:GetAttribute('DevPaid'))"
print("claim with nothing due:", C1(CLAIM))
S1(P + "p:SetAttribute('DevGiftSecs',301) return 1"); time.sleep(2.5)
print("pill at 5 minutes:", C1(PILL))
print("claim at 5 minutes:", C1(CLAIM))
print("claim again at once:", C1(CLAIM))
S1(P + "p:SetAttribute('DevGiftSecs',1300) return 1"); time.sleep(2.5)
print("two claims at 21 minutes:", C1("local R=game.ReplicatedStorage.Remotes.Gift R:FireServer('claim') task.wait(0.6) R:FireServer('claim') task.wait(0.9) R:FireServer('claim') task.wait(0.9) return tostring(game.Players.LocalPlayer:GetAttribute('DevPaid'))"))
print("bad messages:", C1("local R=game.ReplicatedStorage.Remotes.Gift R:FireServer(7) R:FireServer({}) R:FireServer('claim', 99) task.wait(0.9) return tostring(game.Players.LocalPlayer:GetAttribute('DevPaid'))"))
# the Golden Vein Surge: the strike zone the server sends is twice as wide
N.key("Q"); time.sleep(32)
ZONE = ("local z local con=game.ReplicatedStorage.Remotes.Fx.OnClientEvent:Connect(function(k,dep,kind,t0,arc,zone) if k=='mgStart' and kind=='strike' then z=zone end end) "
        "local h=game.Players.LocalPlayer.Character.HumanoidRootPart local best,bd for _,d in workspace.Caves.Deposits:GetChildren() do local pp=d.PrimaryPart if pp and d:GetAttribute('Game')~='rush' then local m=(pp.Position-h.Position).Magnitude if not bd or m<bd then best,bd=d,m end end end "
        "return 1")
def zone(tries=4):  # walk to deposits further and further away until one starts a Perfect Strike; return the zone the server sent
    for k in range(tries):
        S1(P + "local list={} for _,d in workspace.Caves.Deposits:GetChildren() do local pp=d.PrimaryPart local pr=pp and d:FindFirstChildWhichIsA('ProximityPrompt',true) if pr and pr.Enabled and not d:GetAttribute('DevUsed') then list[#list+1]={d,(pp.Position-h.Position).Magnitude} end end "
               "table.sort(list,function(a,b) return a[2]<b[2] end) local d=list[1][1] d:SetAttribute('DevUsed',true) h.AssemblyLinearVelocity=Vector3.zero h.CFrame=CFrame.new(d.PrimaryPart.Position+Vector3.new(0,3,4)) return 1")
        time.sleep(1.5)
        r = C1("local z,kd local con=game.ReplicatedStorage.Remotes.Fx.OnClientEvent:Connect(function(k,dep,kind,t0,arc,zn) if k=='mgStart' then z,kd=zn,kind end end) "
               "local h=game.Players.LocalPlayer.Character.HumanoidRootPart local best,bd for _,d in workspace.Caves.Deposits:GetDescendants() do if d:IsA('ProximityPrompt') and d.Enabled then local m=(d.Parent.Position-h.Position).Magnitude if not bd or m<bd then best,bd=d,m end end end "
               "local cam=workspace.CurrentCamera cam.CFrame=CFrame.lookAt(cam.CFrame.Position,best.Parent.Position) task.wait(0.4) best:InputHoldBegin() task.wait(0.15) best:InputHoldEnd() task.wait(1) con:Disconnect() return tostring(kd)..' '..tostring(z)")
        time.sleep(10)  # let the minigame run out
        if r.startswith("strike"): return r
    return r
z1 = zone()
S1("workspace:SetAttribute('DevGold',60) return 1"); time.sleep(2)
print("event pill in a surge:", C1(PILL))
z2 = zone()
print("strike zone: %s without, %s in a Golden Vein Surge" % (z1, z2))
try: print("zone doubled:", abs(float(z2.split()[1]) - 2 * float(z1.split()[1])) < 0.01)
except Exception: print("zone doubled: unknown")
# the Lantern Tether: ore is worth more with a friend here
print("friends 0:", S1(P + "return tostring(p:GetAttribute('Friends'))"))
S1(P + "p:SetAttribute('DevFriends',2) return 1"); time.sleep(2.5)
print("friends with the hook:", S1(P + "return tostring(p:GetAttribute('Friends'))"), "| board:", C1("local b=workspace.Hub:FindFirstChild('PartyBoard') return b and (b.PartyGui.Line2.Text..' / '..b.PartyGui.Line3.Text) or 'no board'"))
print("client errors:", C1("local t={} for _,m in game:GetService('LogService'):GetLogHistory() do if m.messageType==Enum.MessageType.MessageError and not string.find(m.message,'Requester') then t[#t+1]=string.sub(m.message,1,140) end end return #t..' '..table.concat(t,' | ')"))
print("server errors:", S1("local t={} for _,m in game:GetService('LogService'):GetLogHistory() do if m.messageType==Enum.MessageType.MessageError and not string.find(m.message,'Requester') and not string.find(m.message,'AssistantCommand') then t[#t+1]=string.sub(m.message,1,140) end end return #t..' '..table.concat(t,' | ')"))
N.play(False)
