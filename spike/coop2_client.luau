-- Directive v14 phase 4: the client side of spike/coop2_server.luau (installed as StarterPlayerScripts.Coop2Client by
-- spike/coop2_test.py; idle unless the test's ReplicatedStorage.CoopTestR exists). It fires the game's own remotes on the
-- server's cue and reports back the Fx messages this player receives.
local RS = game:GetService("ReplicatedStorage")
local R = RS:WaitForChild("CoopTestR", 30)
if not R then return end
local plr = game:GetService("Players").LocalPlayer
local rem = RS:WaitForChild("Remotes")
local WATCH = { clink = true, clinkPair = true, ping = true, saviorBonus = true, rescued = true, rescuedFriend = true, grabbed = true }
rem:WaitForChild("Fx").OnClientEvent:Connect(function(kind, a, b, c)
	if WATCH[kind] then R:FireServer("fx_" .. kind, kind == "ping" and (tostring(b) .. " by " .. tostring(c)) or nil) end
end)
local lastG = "none"
rem:WaitForChild("Crew").OnClientEvent:Connect(function(kind, a) if kind == "G" then lastG = string.format("%.3f", a) end end) -- v15: the server's crew Gloom gap
R.OnClientEvent:Connect(function(cmd, arg)
	local h = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
	if cmd == "clink" then rem:WaitForChild("Clink"):FireServer()
	elseif cmd == "down" then rem:WaitForChild("Surface"):FireServer("down")
	elseif cmd == "ping" and h then rem:WaitForChild("Ping"):FireServer(h.Position, "help")
	elseif cmd == "strike" then rem:WaitForChild("GloomStrike"):FireServer(arg)
	elseif cmd == "crewdbg" then plr:SetAttribute("DevCrew", true)
	elseif cmd == "flare" then rem:WaitForChild("Crew"):FireServer("f")
	elseif cmd == "gap" then R:FireServer("gap", lastG)
	elseif cmd == "state" then R:FireServer("state", tostring(plr:GetAttribute("DevCrewState")))
	elseif cmd == "card" then -- the escape's result card: is everything above CONTINUE clear of it?
		local found = "none"
		for _, d in plr.PlayerGui:GetDescendants() do
			if d:IsA("TextButton") and d.Text == "CONTINUE" and d.Visible and d.AbsoluteSize.Y > 4 then
				local top, low, labels = d.AbsolutePosition.Y, 0, 0
				for _, x in d.Parent:GetDescendants() do
					if x:IsA("GuiObject") and x ~= d and x.Visible and not x:IsDescendantOf(d) and x.AbsolutePosition.Y < top then
						low = math.max(low, x.AbsolutePosition.Y + x.AbsoluteSize.Y)
						if x:IsA("TextLabel") then labels += 1 end
					end
				end
				found = string.format("labels=%d continueTop=%d lowestAbove=%d gap=%d", labels, top, low, top - low)
			end
		end
		R:FireServer("card", found)
	end
end)
