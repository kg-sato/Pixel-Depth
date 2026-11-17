"""Close stills of each cave prop kind (Play running, in the caves): the player stands in front of the first prop of each
kind and faces it.   python spike/props_close.py <prefix>   -> captures/night/<prefix>_<kind>.png"""
import sys, time
import night as N
pre = sys.argv[1]
if "InCave" not in N.lua("return game.Players:GetPlayers()[1]:GetAttribute('InCave') and 'InCave' or 'town'"):
    N.key("Q"); time.sleep(32)
kinds = N.lua("local t,s={},{} for _,m in workspace.Caves.Props:GetChildren() do if not s[m.Name] then s[m.Name]=1 table.insert(t,m.Name) end end return table.concat(t,',')", "Server").splitlines()[-1].split(",")
for k in kinds:
    r = N.lua(f"local m=workspace.Caves.Props:FindFirstChild('{k}') local cf,sz=m:GetBoundingBox() local p=game.Players:GetPlayers()[1] local h=p.Character.HumanoidRootPart "
              "local rp=RaycastParams.new() rp.FilterDescendantsInstances={workspace.Caves.Walls,workspace.Caves.Floor,workspace.Caves.Ceiling} rp.FilterType=Enum.RaycastFilterType.Include "
              "local best for a=0,345,15 do local d=Vector3.new(math.cos(math.rad(a)),0,math.sin(math.rad(a))) local o=cf.Position+Vector3.new(0,2,0) if not workspace:Raycast(o,d*10,rp) then local f=workspace:Raycast(o+d*9+Vector3.new(0,4,0),Vector3.new(0,-20,0),rp) if f then best=f.Position break end end end "
              "if not best then return 'nospot' end h.AssemblyLinearVelocity=Vector3.zero h.CFrame=CFrame.lookAt(best+Vector3.new(0,3,0),Vector3.new(cf.Position.X,best.Y+3,cf.Position.Z)) return 'ok'", "Server").splitlines()[-1]
    time.sleep(1.2)
    N.lua(f"if _G.PropLook then _G.PropLook:Disconnect() end local m=workspace.Caves.Props:GetChildren() local pick for _,x in m do if x.Name=='{k}' then pick=x break end end "
          "local cf,sz=pick:GetBoundingBox() local c=workspace.CurrentCamera local rp=RaycastParams.new() rp.FilterDescendantsInstances={{workspace.Caves.Walls,workspace.Caves.Floor,workspace.Caves.Ceiling}} rp.FilterType=Enum.RaycastFilterType.Include "
          "local best,bl=Vector3.xAxis,0 for a=0,345,15 do local d=Vector3.new(math.cos(math.rad(a)),0.35,math.sin(math.rad(a))).Unit local r=workspace:Raycast(cf.Position,d*22,rp) local l=r and r.Distance or 22 if l>bl then best,bl=d,l end end "
          "local eye=cf.Position+best*math.min(bl-1,math.max(sz.Magnitude*1.3,9)) c.CameraType=Enum.CameraType.Scriptable "
          "_G.PropLook=game:GetService('RunService').RenderStepped:Connect(function() c.CFrame=CFrame.lookAt(eye,cf.Position) end) return bl", "Client")
    time.sleep(0.8)
    N.shot(f"{pre}_{k}")
    N.lua("if _G.PropLook then _G.PropLook:Disconnect() _G.PropLook=nil end workspace.CurrentCamera.CameraType=Enum.CameraType.Custom return 1", "Client")
    print(k, r)
