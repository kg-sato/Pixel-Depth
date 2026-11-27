"""Debug (2026-11-23): ride the Camp 1 root zipline as the tour does and list bright parts near the lower-left of the view."""
import time
import night as N
C = lambda code: (N.lua(code, "Client").splitlines() or ["?"])[-1]
S = lambda code: (N.lua(code, "Server").splitlines() or ["?"])[-1]
P = "local p=game.Players:GetPlayers()[1] local h=p.Character.HumanoidRootPart "
ZIP = "local pr for _,d in workspace.Caves.Ziplines:GetDescendants() do if d:GetAttribute('Zip')==1 then pr=d end end "
N.play(False); time.sleep(2); N.play(True); time.sleep(8)
S("game.Players:GetPlayers()[1]:SetAttribute('DevPet','Shinemane') return 1"); time.sleep(1)
N.key("Q"); time.sleep(33)
S(P + ZIP + "h.CFrame=CFrame.new(pr.Parent.Position+Vector3.new(-3,0,0)) return 1"); time.sleep(0.8)
C(ZIP + "local cam=workspace.CurrentCamera cam.CFrame=CFrame.lookAt(cam.CFrame.Position,pr.Parent.Position) task.wait(0.4) pr:InputHoldBegin() task.wait(0.1) pr:InputHoldEnd() return 1")
time.sleep(1.5)
N.shot("zip_orb")
print(C("local cam=workspace.CurrentCamera local vs=cam.ViewportSize local out={} for _,d in workspace:GetDescendants() do if d:IsA('BasePart') and d.Transparency+d.LocalTransparencyModifier<1.5 and (d.Material==Enum.Material.Neon or d.Color.R+d.Color.G+d.Color.B>2.3) then local v,on=cam:WorldToViewportPoint(d.Position) if on and v.X<vs.X*0.3 and v.Y>vs.Y*0.55 and v.Z<30 then table.insert(out,d:GetFullName():sub(-55)..' '..d.Material.Name..' z'..math.floor(v.Z)..' ltm'..string.format('%.2f',d.LocalTransparencyModifier)) end end end return #out..' | '..table.concat(out,' ; ')"))
N.play(False)
