"""Two checks left open on 2026-11-10 (starts Play itself):
1 Quest carry-over: with the ride quest finished but not claimed, an extraction counts toward the next quest, and claiming
  the ride quest keeps that progress.
2 Gloomling wind-up: when a Gloomling rears up (State = windup), stepping 14 studs away inside its 0.8 s makes it miss
  (HP unchanged)."""
import sys, time, pathlib, subprocess
here = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(here))
import prompt_test as T
Q = "local R=game.ReplicatedStorage.Remotes local q local con=R.Quest.OnClientEvent:Connect(function(x) q=x end) "
SHOW = "task.wait(0.8) con:Disconnect() return q and ('story '..tostring(q.story)..' sp '..tostring(q.sp)..' np '..tostring(q.np)) or 'no reply'"
T.night("play"); time.sleep(4); T.night("key", "Q"); time.sleep(30)
print("after the ride:", T.night("lua", "Client", Q + "R.Quest:FireServer('get') " + SHOW))
subprocess.run([sys.executable, str(here / "mg_night.py"), "vq", "strike"], capture_output=True, text=True, cwd=here); time.sleep(3)
print("after one extraction (ride not claimed):", T.night("lua", "Client", Q + "R.Quest:FireServer('get') " + SHOW))
print("after claiming 'ride':", T.night("lua", "Client", Q + "R.Quest:FireServer('claim','ride') " + SHOW))
# 2 the wind-up dodge
P = "local p=game.Players:GetPlayers()[1] local h=p.Character.HumanoidRootPart "
T.night("lua", "Server", T.SAFE + P + "local s=workspace.Caves:FindFirstChild('LostLanternSpot',true) h.CFrame=CFrame.new(safe(s.Position)) p:SetAttribute('DevBanked',true) p:SetAttribute('DevTorchAge',900) return 1")
r = T.night("lua", "Server", P + "local hp0=p:GetAttribute('HP') local t0=os.clock() local seen=false "
            "while os.clock()-t0<40 do local g=workspace:FindFirstChild('Gloom') for _,x in g and g:GetChildren() or {} do if x:GetAttribute('State')=='windup' and (x.Position-h.Position).Magnitude<12 then seen=true end end if seen then break end task.wait(0.05) end "
            "if not seen then return 'no wind-up seen in 40 s (HP '..tostring(p:GetAttribute('HP'))..')' end "
            "local hpAt=p:GetAttribute('HP') h.CFrame=h.CFrame+Vector3.new(14,0,0) task.wait(1.6) return 'wind-up seen; HP before '..tostring(hpAt)..' after stepping away '..tostring(p:GetAttribute('HP'))")
print("wind-up dodge:", r)
# 3 the way home (Shared.WayHome): embers on the floor toward camp while the torch is low, none inside the camp ring
EMB = "local n=0 for _,d in workspace.WayHome:GetChildren() do if d.Transparency<1 then n+=1 end end return n"
PC = P + "local C=require(game.ReplicatedStorage.Shared.Config) "
T.night("lua", "Server", PC + "h.CFrame=CFrame.new(C.CAVE_ORIGIN+Vector3.new(48,3,0)) task.wait(0.4) p:SetAttribute('DevTorchAge',C.TORCH.time*0.73) return 1"); time.sleep(5)
out = T.night("lua", "Client", EMB)
T.night("lua", "Server", PC + "h.CFrame=CFrame.new(C.CAVE_ORIGIN+Vector3.new(4,3,4)) return 1"); time.sleep(3.5)
print("way home embers: low torch outside camp", out, "(PASS over 0), at camp", T.night("lua", "Client", EMB), "(PASS 0)")
ERR = "local t={} for _,m in game:GetService('LogService'):GetLogHistory() do if m.messageType==Enum.MessageType.MessageError then t[string.sub(m.message,1,150)]=true end end local e={} for k in t do table.insert(e,k) end return #e..' '..table.concat(e,' ## ')"
for w in ("Client", "Server"): print(w, "errors:", T.night("lua", w, ERR))
T.night("stop")
