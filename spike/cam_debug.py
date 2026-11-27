"""Debug (2026-11-27 night): does a server teleport just after the ride down ends leave the cave view on the Scriptable town camera?
python spike/cam_debug.py [delay]   teleports the player to zip grip 1 <delay> s (default 0.4) after the ride's gui goes."""
import sys, time
import night as N
S1 = lambda code: (N.lua(code, "Server").splitlines() or ["?"])[-1]
C1 = lambda code: (N.lua(code, "Client").splitlines() or ["?"])[-1]
D = float(sys.argv[1]) if len(sys.argv) > 1 else 0.4
N.play(True); time.sleep(8)
C1("local p=game.Players.LocalPlayer local cam=workspace.CurrentCamera p:SetAttribute('DevCamLog','') local t0=os.clock() task.spawn(function() local last while os.clock()-t0<60 do "
   "local s=tostring(cam.CameraType.Name)..'/'..tostring(p:GetAttribute('InCave'))..'/'..tostring(p.PlayerGui:FindFirstChild('MinecartRideGui')~=nil) "
   "if s~=last then last=s p:SetAttribute('DevCamLog',p:GetAttribute('DevCamLog')..string.format(' %.2f ',os.clock()-t0)..s) end task.wait() end end) "
   # the client moves itself D s after the ride's gui goes (as a teleport would; it owns its character)
   "task.spawn(function() repeat task.wait() until p.PlayerGui:FindFirstChild('MinecartRideGui') repeat task.wait() until not p.PlayerGui:FindFirstChild('MinecartRideGui') "
   f"task.wait({D}) local pr for _,d in workspace.Caves.Ziplines:GetDescendants() do if d:GetAttribute('Zip')==1 then pr=d end end local h=p.Character.HumanoidRootPart h.AssemblyLinearVelocity=Vector3.zero h.CFrame=CFrame.new(pr.Parent.Position+Vector3.new(3,0,0)) end) return 1")
C1("game.ReplicatedStorage.Remotes.Surface:FireServer('down',2) return 1"); time.sleep(24)
print("log (s, CameraType/InCave/ride gui):", C1("return game.Players.LocalPlayer:GetAttribute('DevCamLog')"))
N.play(False)
