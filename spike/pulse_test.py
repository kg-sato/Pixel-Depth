"""Root Pulse end to end (2026-11-20): after the calm first 90 s of a dive, the server warns (pulseWarn) and breathes (pulse);
a player away from camp with unbanked ore loses C.PULSE.loss of it.     python spike/pulse_test.py   (about 6 minutes)"""
import time
import night as N
S1 = lambda code: (N.lua(code, "Server").splitlines() or ["?"])[-1]
C1 = lambda code: (N.lua(code, "Client").splitlines() or ["?"])[-1]
N.play(True); time.sleep(6)
N.key("Q"); time.sleep(30)
C1("""local p=game.Players.LocalPlayer p:SetAttribute('DevPulse','') game.ReplicatedStorage.Remotes.Fx.OnClientEvent:Connect(function(k,a,b)
 if k=='pulseWarn' or k=='pulse' then p:SetAttribute('DevPulse',(p:GetAttribute('DevPulse') or '')..' '..k..':'..tostring(a)..'@'..math.floor(workspace:GetServerTimeNow()%180)) end end) return 1""")
# some unbanked ore: a flawless Vein Rush on a rare deposit (the steps of spike/vein_test.py), then stand far from camp
pick = S1("""local deps=workspace.Caves.Deposits:GetChildren() local best
for _,a in deps do if a:GetAttribute('Ore')>=3 and a:GetAttribute('OreName')~='Root Knot' and a:GetAttribute('OreName')~='Kiln Vent' and a.PrimaryPart and a.PrimaryPart.Transparency<1 then best=a end if best then break end end
if not best then return 'none' end
local p=game.Players:GetPlayers()[1] local c=best.PrimaryPart local rp=RaycastParams.new() rp.FilterDescendantsInstances={p.Character,best}
local at=c.Position+Vector3.new(0,3,0) local op=OverlapParams.new() op.FilterType=Enum.RaycastFilterType.Exclude op.FilterDescendantsInstances={p.Character,best} op.RespectCanCollide=true for i=0,31 do local a=i*math.pi/8 local r=i<16 and 5 or 7 local q=c.Position+Vector3.new(math.cos(a)*r,3,math.sin(a)*r) local fl=workspace:Raycast(q,Vector3.new(0,-8,0),rp) if fl and not workspace:Raycast(q,c.Position-q,rp) and #workspace:GetPartBoundsInBox(CFrame.new(fl.Position+Vector3.new(0,3.2,0)),Vector3.new(2,5,2),op)==0 then at=fl.Position+Vector3.new(0,3,0) break end end
p:SetAttribute('FastCine',true) p:SetAttribute('DevEquip',require(game.ReplicatedStorage.Shared.Config).minTier(best:GetAttribute('Layer'),best:GetAttribute('Ore'))) -- 2026-11-27: deposits now need the pickaxe tier their hardness asks for (FastCine: no forge scene, which put the player back where it began)
p.Character.HumanoidRootPart.CFrame=CFrame.lookAt(at,Vector3.new(c.Position.X,at.Y,c.Position.Z)) best:SetAttribute('VeinTest',true) return best:GetFullName()""")
print("deposit:", pick)
print(C1("""local p=game.Players.LocalPlayer local R=game.ReplicatedStorage.Remotes local got={} local seq
R.Fx.OnClientEvent:Connect(function(k,a,b,c,d) if k=='mgStart' and b=='rush' then seq=d end if k=='veinChain' then got.n=#a got.ore=b end end)
local dep for _,d in workspace.Caves.Deposits:GetChildren() do if d:GetAttribute('VeinTest') then dep=d end end
local pr=dep.PrimaryPart:FindFirstChildOfClass('ProximityPrompt') workspace.CurrentCamera.CFrame=CFrame.lookAt(workspace.CurrentCamera.CFrame.Position,dep.PrimaryPart.Position)
task.wait(0.4) pr:InputHoldBegin() task.wait(0.1) pr:InputHoldEnd()
local t=os.clock() while not seq and os.clock()-t<4 do task.wait(0.05) end
if not seq then return 'no rush started' end
task.wait(#seq*0.2) local ans={} for i,c in seq do ans[i]= c==1 and 2 or 1 end R.Extract:FireServer('rush',ans)
t=os.clock() while not got.n and os.clock()-t<4 do task.wait(0.05) end
return 'chain fired: '..tostring(got.n ~= nil)..' | seq '..#seq..' | vein chain: '..tostring(got.n)..' deposits, +'..tostring(got.ore)..' ore'"""))
time.sleep(2)
# the rush above does not always leave ore in the bag (full suite 2026-11-22: "chain fired: false", bag empty, the breath cost 0): top it up
print("moved:", S1("local p=game.Players:GetPlayers()[1] local c=workspace.Caves.Spot_Cathedral.Value.WorldPosition p.Character.HumanoidRootPart.CFrame=CFrame.new(c+Vector3.new(0,3,0)) return math.floor((c-workspace.Caves:FindFirstChild('LiftLanding',true).Position).Magnitude)"))
S1("game.Players:GetPlayers()[1]:SetAttribute('DevBag', 20) return 1"); time.sleep(1.5)  # 20: the breath takes floor(20 * C.PULSE.loss 0.15) = 3 (6 rounded down to 0)  # after the move (2026-11-27): at camp the bag is banked at once (Fx sold), so a top-up there was gone before the breath
time.sleep(1)
print("bag before:", S1("local p=game.Players:GetPlayers()[1] return tostring(p:GetAttribute('InCave'))"))
t0 = time.time()
while time.time() - t0 < 300:
    log = C1("return tostring(game.Players.LocalPlayer:GetAttribute('DevPulse'))")
    if " pulse:" in log: break
    time.sleep(15)
print("pulse log:", log)
print("warned before the breath:", "pulseWarn:" in log and log.index("pulseWarn:") < log.index(" pulse:") if " pulse:" in log else False)
lost = log.split(" pulse:")[-1].split("@")[0] if " pulse:" in log else "?"
print("ore lost away from camp:", lost, "| lost > 0:", lost.isdigit() and int(lost) > 0)
# then at camp: the next breath costs nothing
S1("local p=game.Players:GetPlayers()[1] p.Character.HumanoidRootPart.CFrame=workspace.Caves:FindFirstChild('LiftLanding',true).CFrame+Vector3.new(0,3,0) return 1")
C1("game.Players.LocalPlayer:SetAttribute('DevPulse','') return 1")
t0 = time.time()
while time.time() - t0 < 200:
    log2 = C1("return tostring(game.Players.LocalPlayer:GetAttribute('DevPulse'))")
    if " pulse:" in log2: break
    time.sleep(15)
print("at camp:", log2, "| kept:", " pulse:0@" in log2)
print("client errors:", C1("local t={} for _,m in game:GetService('LogService'):GetLogHistory() do if m.messageType==Enum.MessageType.MessageError and not string.find(m.message,'Requester') and not string.find(m.message,'not authorized') then t[#t+1]=string.sub(m.message,1,140) end end return #t..' '..table.concat(t,' | ')"))
N.play(False)
