"""Pets, plan phase A: faces, three crew pets in the cave view, the whistle. Starts Play itself.
    python spike/pet_test.py"""
import time
import night as N
C1 = lambda code: N.lua(code, "Client").splitlines()[-1]
S1 = lambda code: N.lua(code, "Server").splitlines()[-1]
FACES = ("local C=require(game.ReplicatedStorage.Shared.Config) local names={} for k,v in C.PET_FACE do names[v]=k end local out={} "
         "for _,m in workspace:GetDescendants() do local h=m:IsA('Model') and m:FindFirstChild('Head') local g=h and h:FindFirstChild('Face') if g then out[#out+1]=m.Name..':'..tostring(names[g:FindFirstChildOfClass('ImageLabel').Image]) end end return #out..' '..table.concat(out,' ')")
N.play(True); time.sleep(8)
for pet in ("Shinemane", "Tosk", "Kobold"):
    S1(f"game.Players:GetPlayers()[1]:SetAttribute('DevPet','{pet}') return 1"); time.sleep(1.5)
time.sleep(1)
print("town faces:", C1(FACES))
N.shot("pet_town")
N.key("Q"); time.sleep(36)
print("in view:", C1("local cam=workspace.CurrentCamera local n=0 for _,m in workspace:GetDescendants() do if m:IsA('Model') and m:FindFirstChild('Head') and m:FindFirstChild('Collar') then local v,on=cam:WorldToViewportPoint(m.PrimaryPart.Position) if on and v.Z>0 then n+=1 end end end return n..' pets on screen with a collar'"))
N.shot("pet_cave")
N.key("X"); time.sleep(1.2)
print("whistle with no ore near:", C1("return 'marks '..tostring(game.Players.LocalPlayer.PlayerGui:FindFirstChild('WhistleMark')~=nil)"))
time.sleep(5)  # the short cooldown after an empty whistle
S1("local p=game.Players:GetPlayers()[1] local h=p.Character.HumanoidRootPart local best,bd for _,d in workspace.Caves.Deposits:GetChildren() do local c=d.PrimaryPart if c and c.Transparency<1 then local m=(c.Position-h.Position).Magnitude if not bd or m<bd then best,bd=c,m end end end h.CFrame=CFrame.lookAt(best.Position+Vector3.new(14,4,0),best.Position) return 1"); time.sleep(1.5)
N.key("X"); time.sleep(2.5)
print("whistle:", C1("local pg=game.Players.LocalPlayer.PlayerGui local m=pg:FindFirstChild('WhistleMark') local glow=false for _,d in workspace.Caves.Deposits:GetDescendants() do if d.Name=='WhistleGlow' then glow=true end end return 'mark '..tostring(m~=nil)..' glow '..tostring(glow)"))
print("whistle faces:", C1(FACES))
N.shot("pet_whistle")
N.key("X"); time.sleep(0.6)
print("second whistle at once:", C1("local n=0 for _,g in game.Players.LocalPlayer.PlayerGui:GetChildren() do if g.Name=='WhistleMark' then n+=1 end end return n..' marks (1 expected)'"))
S1("game.ReplicatedStorage.Remotes.Fx:FireClient(game.Players:GetPlayers()[1],'grabbed',2) return 1"); time.sleep(0.8)
print("hurt faces:", C1(FACES))
time.sleep(9)
print("mark gone:", C1("return tostring(game.Players.LocalPlayer.PlayerGui:FindFirstChild('WhistleMark')==nil)"))
print("errors:", C1("local n,t=0,{} for _,m in game:GetService('LogService'):GetLogHistory() do if m.messageType==Enum.MessageType.MessageError and not string.find(m.message,'Requester') then n+=1 t[#t+1]=string.sub(m.message,1,300) end end return n..' '..table.concat(t,' || ')"))
N.play(False)
