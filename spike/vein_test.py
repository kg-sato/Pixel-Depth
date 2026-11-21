"""Vein Chains end to end (2026-11-20): a flawless Vein Rush on a rare deposit with a same-ore neighbour within C.VEIN.radius
pays the chain (Fx veinChain) and claims the neighbours.     python spike/vein_test.py
The script answers the server's crack sequence itself (the client holds it, see PixelServer's shortcut note)."""
import time
import night as N
S1 = lambda code: (N.lua(code, "Server").splitlines() or ["?"])[-1]
C1 = lambda code: (N.lua(code, "Client").splitlines() or ["?"])[-1]
N.play(True); time.sleep(6)
N.key("Q"); time.sleep(30)
pick = S1("""local deps=workspace.Caves.Deposits:GetChildren() local best
for _,a in deps do if a:GetAttribute('Ore')>=3 and a:GetAttribute('OreName')~='Root Knot' and a:GetAttribute('OreName')~='Kiln Vent' and a.PrimaryPart and a.PrimaryPart.Transparency<1 then for _,b in deps do
 if b~=a and b:GetAttribute('Layer')==a:GetAttribute('Layer') and b:GetAttribute('Ore')==a:GetAttribute('Ore') and (a:GetPivot().Position-b:GetPivot().Position).Magnitude<=16 then best=a break end end end if best then break end end
if not best then return 'none' end
local p=game.Players:GetPlayers()[1] local c=best.PrimaryPart local rp=RaycastParams.new() rp.FilterDescendantsInstances={p.Character,best}
local at=c.Position+Vector3.new(0,3,0) for i=0,15 do local a=i*math.pi/8 local q=c.Position+Vector3.new(math.cos(a)*5,3,math.sin(a)*5) local fl=workspace:Raycast(q,Vector3.new(0,-8,0),rp) if fl and not workspace:Raycast(q,c.Position-q,rp) then at=fl.Position+Vector3.new(0,3,0) break end end
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
time.sleep(1)
print("client errors:", C1("local t={} for _,m in game:GetService('LogService'):GetLogHistory() do if m.messageType==Enum.MessageType.MessageError and not string.find(m.message,'Requester') and not string.find(m.message,'not authorized') then t[#t+1]=string.sub(m.message,1,140) end end return #t..' '..table.concat(t,' | ')"))
N.play(False)
