"""Trigger prompts the way a player does, to test the server's handlers (Play running or not: it starts Play itself).
A prompt only works while it is on screen, so each step teleports next to it, aims a Scriptable camera at it and holds the
prompt, all inside one execute_luau call (Studio resets the camera when the call ends). Prints the Fx events that came back.
    python spike/prompt_test.py        runs the reward prompts: town station, shrine chest (twice), nest (twice), jar (twice)"""
import subprocess, sys, time, pathlib
here = pathlib.Path(__file__).resolve().parent
def night(*a): return (subprocess.run([sys.executable, str(here / "night.py"), *a], capture_output=True, text=True).stdout.strip().splitlines() or ["?"])[-1]
FIND = "local function find(attr, val) local best for _,d in workspace:GetDescendants() do if d:IsA('ProximityPrompt') and d.Enabled and (d:GetAttribute(attr)==val or (val==nil and d:GetAttribute(attr)~=nil) or (d.Parent:GetAttribute(attr)==val and val~=nil)) then best=d break end end return best end "
# a standing point near `at`: floor within 8 studs below and free space for the body (a fixed offset sometimes landed inside
# rock: the character fell out of the map and woke in town, and the test then reported a failure that was not one)
SAFE = ("local function safe(at) local prm=OverlapParams.new() for r=4,7 do for k=0,7 do local a=k*math.pi/4 local o=at+Vector3.new(math.cos(a)*r,0,math.sin(a)*r) "
        "for dy=3,-3,-1 do local q=o+Vector3.new(0,dy,0) local hit=workspace:Raycast(q,Vector3.new(0,-8,0)) "
        "if hit and #workspace:GetPartBoundsInBox(CFrame.new(hit.Position+Vector3.new(0,3.2,0)),Vector3.new(2.4,5,2.4),prm)==0 then return hit.Position+Vector3.new(0,3.2,0) end end end end return at+Vector3.new(4,3,0) end ")
def trigger(attr, val="nil", times=1, off=None):
    night("lua", "Server", FIND + SAFE + f"local pr=find('{attr}',{val}) local par=pr.Parent local at=par:IsA('Attachment') and par.WorldPosition or par.Position "
          f"game.Players:GetPlayers()[1].Character.HumanoidRootPart.CFrame=CFrame.new({'at+' + off if off else 'safe(at)'}) return 1")
    time.sleep(2.2)
    NEAR = "local function near(attr) local h=game.Players.LocalPlayer.Character.HumanoidRootPart local best,bd for _,d in workspace:GetDescendants() do if d:IsA('ProximityPrompt') and (d:GetAttribute(attr)~=nil or d.Parent:GetAttribute(attr)~=nil) then local par=d.Parent local at=par:IsA('Attachment') and par.WorldPosition or par.Position local m=(at-h.Position).Magnitude if not bd or m<bd then best,bd=d,m end end end return best end "  # the server and the client list instances in different orders: the client takes the prompt nearest the player
    return night("lua", "Client", NEAR + f"local pr=near('{attr}') local par=pr.Parent local at=par:IsA('Attachment') and par.WorldPosition or par.Position "
                 "local h=game.Players.LocalPlayer.Character.HumanoidRootPart local kinds={} local con=game.ReplicatedStorage.Remotes.Fx.OnClientEvent:Connect(function(k,a,b) table.insert(kinds,tostring(k)..':'..tostring(typeof(a)=='Instance' and a.Name or a)) end) "
                 "local c=workspace.CurrentCamera c.CameraType=Enum.CameraType.Scriptable c.CFrame=CFrame.lookAt(h.Position+Vector3.new(0,1.5,0), at) task.wait(0.6) "
                 f"for n=1,{times} do pr.Enabled=true pr:InputHoldBegin() task.wait(pr.HoldDuration+0.3) pr:InputHoldEnd() task.wait(1.3) end con:Disconnect() "
                 "return 'dist '..math.floor((h.Position-at).Magnitude)..' fx '..table.concat(kinds,',')")
if __name__ == "__main__":
    night("play"); time.sleep(5)
    print("town daily chest:", trigger("Station", "'chest'"))
    night("key", "Q"); time.sleep(30)
    print("shrine chest x2:", trigger("CaveShrine", "true", 2))
    print("nest x2:", trigger("CaveNest", "true", 2))
    night("lua", "Server", "game.Players:GetPlayers()[1]:SetAttribute('DevClay',2) return 1"); time.sleep(4)
    print("jar x2:", trigger("ClayJar", "1", 2))
    print("far jar (should pay nothing):", night("lua", "Client", FIND + "local pr=find('ClayJar',5) local kinds={} local con=game.ReplicatedStorage.Remotes.Fx.OnClientEvent:Connect(function(k) table.insert(kinds,k) end) pr:InputHoldBegin() task.wait(0.3) pr:InputHoldEnd() task.wait(1) con:Disconnect() return 'fx '..table.concat(kinds,',')"))
    ERR = "local t={} for _,m in game:GetService('LogService'):GetLogHistory() do if m.messageType==Enum.MessageType.MessageError then t[string.sub(m.message,1,150)]=true end end local e={} for k in t do table.insert(e,k) end return #e..' '..table.concat(e,' ## ')"
    for w in ("Client", "Server"): print(w, "errors:", night("lua", w, ERR))
    night("stop")
