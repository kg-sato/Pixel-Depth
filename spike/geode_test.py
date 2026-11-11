"""Play test for Echo Tap and the Geode Lock in the Clay Caves (starts Play itself). Wins a geode at an echo wall through the
real remote, then cracks it at the anvil by answering every round the server sends, then tries a wrong facet on a second
geode. Prints the Fx events. Captures captures/night/geode_panel.png."""
import sys, time, pathlib
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import prompt_test as T
T.night("play"); time.sleep(4); T.night("key", "Q"); time.sleep(30)
T.night("lua", "Server", "game.Players:GetPlayers()[1]:SetAttribute('DevClay',2) return 1"); time.sleep(6)
LISTEN = "local R=game.ReplicatedStorage.Remotes local log={} local con=R.Fx.OnClientEvent:Connect(function(k,a,b,c,d) if string.sub(k,1,4)=='echo' or string.sub(k,1,5)=='geode' then table.insert(log,k..':'..tostring(type(a)=='table' and table.concat(a,'') or a)..':'..tostring(b)..':'..tostring(c)) end end) "
won = 0
for wall in (1, 2, 3):
    print("echo wall", wall, T.trigger("Echo", str(wall), 1, "Vector3.new(0,-2,-7)" if wall != 2 else "Vector3.new(7,-2,0)"))
    r = T.night("lua", "Client", LISTEN + f"local found=false local c2=R.Fx.OnClientEvent:Connect(function(k,a,b) if k=='echoTap' and b==0 then found=true end end) for k=1,4 do if not found then R.Clay:FireServer('echo',{wall},k) task.wait(0.7) end end return tostring(found)..' '..table.concat(log,' | ')")
    print("  taps:", r)
    if r.startswith("true"): won += 1
print("geodes won:", won)
print("anvil:", T.trigger("GeodeAnvil", "true", 0, "Vector3.new(4,2,3)"))
r = T.night("lua", "Client", "local function near() for _,d in workspace.Caves.Clay:GetDescendants() do if d:IsA('ProximityPrompt') and d:GetAttribute('GeodeAnvil') then return d end end end local pr=near() "
            + LISTEN + "local done=false local c2=R.Fx.OnClientEvent:Connect(function(k,a,b) if k=='geodeStart' or k=='geodeRound' then task.wait(0.3) for _,f in a do R.Clay:FireServer('geode',f) task.wait(0.15) end elseif k=='geodeWin' or k=='geodeNone' or k=='geodeMiss' then done=true end end) "
            "local h=game.Players.LocalPlayer.Character.HumanoidRootPart local c=workspace.CurrentCamera c.CameraType=Enum.CameraType.Scriptable c.CFrame=CFrame.lookAt(h.Position+Vector3.new(0,1.5,0), pr.Parent.WorldPosition) task.wait(0.6) "
            "pr:InputHoldBegin() task.wait(0.3) pr:InputHoldEnd() local t0=os.clock() while not done and os.clock()-t0<12 do task.wait(0.1) end return table.concat(log,' | ')")
print("crack:", r)
T.night("shot", "geode_panel")
if won > 1:
    r = T.night("lua", "Client", "local pr for _,d in workspace.Caves.Clay:GetDescendants() do if d:IsA('ProximityPrompt') and d:GetAttribute('GeodeAnvil') then pr=d end end "
                + LISTEN + "local h=game.Players.LocalPlayer.Character.HumanoidRootPart local c=workspace.CurrentCamera c.CameraType=Enum.CameraType.Scriptable c.CFrame=CFrame.lookAt(h.Position+Vector3.new(0,1.5,0), pr.Parent.WorldPosition) task.wait(0.6) "
                "local first local c2=R.Fx.OnClientEvent:Connect(function(k,a) if k=='geodeStart' then first=a[1] end end) pr:InputHoldBegin() task.wait(0.3) pr:InputHoldEnd() task.wait(1.2) R.Clay:FireServer('geode', first%6+1) task.wait(1) return table.concat(log,' | ')")
    print("wrong facet:", r)
ERR = "local t={} for _,m in game:GetService('LogService'):GetLogHistory() do if m.messageType==Enum.MessageType.MessageError then t[string.sub(m.message,1,150)]=true end end local e={} for k in t do table.insert(e,k) end return #e..' '..table.concat(e,' ## ')"
for w in ("Client", "Server"): print(w, "errors:", T.night("lua", w, ERR))
print("zfight:", T.night("lua", "Server", "@" + str(pathlib.Path(__file__).resolve().parent / "zfight_scan.luau")))
T.night("stop")
