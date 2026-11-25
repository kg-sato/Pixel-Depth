-- SignFade (ReplicatedStorage.Shared.SignFade), started by PixelClient. Master Directive v16 4.1 (tour full1124c fix 2, the
-- Df0G1CTSQWj reference): the town's sign words (MINE, SELL, EGGS, QUESTS, CREW HEARTH, REFINERY ...) all shouted at once from
-- the high camera. Now only the signs near the player stay at full strength; the rest sink back to a quiet ghost of their words.
-- The Deep Chronicle is never faded. Display only: it changes text and image transparency on this player's screen.
local M = {}
local NEAR, FAR, GHOST = 14, 34, 0.6 -- full inside NEAR studs, GHOST transparency beyond FAR
local KEEP = { ChronicleSlab = true }

function M.start(E)
	local plr = E.plr
	local signs = {} -- SurfaceGui -> { part, { {gui object, property, base} } }
	local function track(sg)
		if signs[sg] or not sg:IsA("SurfaceGui") or not sg.Parent then return end
		local part = sg.Adornee or sg.Parent
		if not (part and part:IsA("BasePart")) or KEEP[part.Name] then return end
		if not part:FindFirstAncestor("Hub") and not part:FindFirstAncestor("Town") then return end
		local list = {}
		for _, o in sg:GetDescendants() do
			if o:IsA("TextLabel") or o:IsA("TextButton") then table.insert(list, { o, "TextTransparency", o.TextTransparency })
			elseif o:IsA("ImageLabel") then table.insert(list, { o, "ImageTransparency", o.ImageTransparency }) end
		end
		if #list > 0 then signs[sg] = { part = part, list = list } end
	end
	for _, d in workspace:GetDescendants() do if d:IsA("SurfaceGui") then track(d) end end
	workspace.DescendantAdded:Connect(function(d) if d:IsA("SurfaceGui") then task.delay(1, track, d) end end)
	local last = {}
	task.spawn(function()
		while true do
			task.wait(0.2)
			local ch = plr.Character
			local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
			local inCave = plr:GetAttribute("InCave") == true
			for sg, s in signs do
				if not sg.Parent then signs[sg] = nil last[sg] = nil continue end
				local a = 0
				if hrp and not inCave then
					local d = (s.part.Position - hrp.Position).Magnitude
					a = math.clamp((d - NEAR) / (FAR - NEAR), 0, 1) * GHOST
				end
				a = math.floor(a * 20 + 0.5) / 20
				if last[sg] ~= a then
					last[sg] = a
					for _, it in s.list do
						local o, prop, base = it[1], it[2], it[3]
						if o.Parent then o[prop] = base + (1 - base) * a end
					end
				end
			end
		end
	end)
end

return M
