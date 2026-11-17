"""Cave props before/after stills (Play running): rides down if needed, then stands the player on fixed floor spots of each
cave theme (the same spots every run: picked by a hash of the floor part's place) and takes a still looking along the cave.
    python spike/props_shots.py <prefix>        -> captures/night/<prefix>_<theme>_<n>.png"""
import sys, time
import night as N
pre = sys.argv[1]
if "InCave" not in N.lua("return game.Players:GetPlayers()[1]:GetAttribute('InCave') and 'InCave' or 'town'"):
    N.key("Q"); time.sleep(32)
PICK = ("local out={} local by={} for _,f in workspace.Caves.Floor:GetChildren() do local th=f:GetAttribute('Theme') or '?' by[th]=by[th] or {} table.insert(by[th],f) end "
        "for th,l in by do table.sort(l,function(a,b) return a.Position.X*7+a.Position.Z<b.Position.X*7+b.Position.Z end) "
        "for k=1,2 do local f=l[math.floor(#l*k/3)] if f then table.insert(out,th..'|'..math.floor(f.Position.X)..'|'..math.floor(f.Position.Y+f.Size.Y/2)..'|'..math.floor(f.Position.Z)) end end end return table.concat(out,';')")
spots = N.lua(PICK, "Server").splitlines()[-1].split(";")
print(spots)
for k, s in enumerate(spots):
    th, x, y, z = s.split("|")
    N.lua(f"local h=game.Players:GetPlayers()[1].Character.HumanoidRootPart h.AssemblyLinearVelocity=Vector3.zero h.CFrame=CFrame.new({x},{int(y)+3},{z}) return 1", "Server")
    time.sleep(1.5)
    # look along the most open direction (the longest free ray at eye height)
    N.lua(f"local c=workspace.CurrentCamera local o=Vector3.new({x},{int(y)+5},{z}) local rp=RaycastParams.new() rp.FilterDescendantsInstances={{game.Players.LocalPlayer.Character}} rp.FilterType=Enum.RaycastFilterType.Exclude "
          "local best,bd=Vector3.xAxis,0 for a=0,345,15 do local d=Vector3.new(math.cos(math.rad(a)),-0.12,math.sin(math.rad(a))) local r=workspace:Raycast(o,d*80,rp) local len=r and r.Distance or 80 if len>bd then best,bd=d,len end end "
          "c.CameraType=Enum.CameraType.Scriptable c.CFrame=CFrame.lookAt(o,o+best) task.wait(1.2) return bd", "Client")
    N.shot(f"{pre}_{th}_{k}")
N.lua("workspace.CurrentCamera.CameraType=Enum.CameraType.Custom return 1", "Client")
print("done")
