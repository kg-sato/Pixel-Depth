-- LanternTether (ReplicatedStorage.Shared.LanternTether), started by PixelClient. The friends boost of directive v9
-- (2026-11-13), the part you see. The server (ServerScriptService.Retention) counts your friends in this server (player
-- attribute Friends) and says which friend stands beside you in the caves (TetherTo); here:
--   * a warm gold and cyan beam of light joins you to that friend (the torch burns slower for both while it shows)
--   * the party board by the MINE shaft shows how many friends are here and what that gives; its prompt opens Roblox's invite window
--   * one toast when the boost starts
-- Display only: the boost itself is decided on the server.
local Players = game:GetService("Players")
local M = {}

function M.start(E)
	local plr, C = E.plr, E.C
	if not C.TETHER then return end
	local GOLD, CYAN = Color3.fromRGB(255, 214, 107), Color3.fromRGB(0, 240, 255)
	local beam = Instance.new("Beam")
	beam.Name, beam.FaceCamera, beam.LightEmission, beam.LightInfluence, beam.Segments = "LanternTether", true, 1, 0, 12
	beam.Width0, beam.Width1, beam.CurveSize0, beam.CurveSize1 = 0.45, 0.45, 1.5, -1.5
	beam.Color = ColorSequence.new(GOLD, CYAN)
	beam.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(0.5, 0.1), NumberSequenceKeypoint.new(1, 0.35) })
	beam.Enabled = false
	beam.Parent = workspace
	local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
	local function tie()
		local to = plr:GetAttribute("TetherTo")
		local other = to and Players:FindFirstChild(to)
		local h0 = E.hrp()
		local h1 = other and other.Character and other.Character:FindFirstChild("HumanoidRootPart")
		if h0 and h1 then
			a0.Parent, a1.Parent = h0, h1
			beam.Attachment0, beam.Attachment1, beam.Enabled = a0, a1, true
		else
			beam.Enabled = false
		end
	end
	plr:GetAttributeChangedSignal("TetherTo"):Connect(tie)
	plr.CharacterAdded:Connect(function() task.wait(1) tie() end)

	local told = false
	local function board()
		local n = plr:GetAttribute("Friends") or 0
		local hub = workspace:FindFirstChild("Hub")
		local b = hub and hub:FindFirstChild("PartyBoard")
		local sg = b and b:FindFirstChild("PartyGui")
		if sg then
			sg.Line2.Text = n .. "/" .. C.TETHER.max .. " FRIENDS HERE"
			sg.Line3.Text = n > 0 and ("+" .. math.floor(C.TETHER.value * 100 + 0.5) .. "% ORE VALUE IS ON") or ("+" .. math.floor(C.TETHER.value * 100 + 0.5) .. "% ORE VALUE WITH A FRIEND")
		end
		if n > 0 and not told then
			told = true
			E.toast("LANTERN TETHER:  +" .. math.floor(C.TETHER.value * 100 + 0.5) .. "% ORE VALUE WITH A FRIEND HERE", GOLD, true)
		elseif n == 0 then
			told = false
		end
	end
	plr:GetAttributeChangedSignal("Friends"):Connect(board)
	task.delay(3, board)
	game:GetService("ProximityPromptService").PromptTriggered:Connect(function(prompt, who)
		if who == plr and prompt:GetAttribute("PartyInvite") then
			pcall(function() game:GetService("SocialService"):PromptGameInvite(plr) end)
		end
	end)
end

return M
