-- Trophies (ReplicatedStorage.Shared.Trophies), started by PixelClient. Next Systems Plan, phase E: "trophy cases in town for
-- beaten bosses and Secret pets" (vault Briefs/Trophy Cases (2026-11-14)). Four glass cases stand against the Trophy House's
-- front wall (HubBuilder builds them, each with the attribute Trophy = a key of Config.TROPHIES). What is IN a case is each
-- player's own: the server says which trophies this player has (player attribute Trophies, keys joined by commas) and this
-- module fills the cases on this player's screen: a small voxel figure that turns slowly and the name on the plaque, or a
-- dark block and how to earn it. Display only.
local RunService = game:GetService("RunService")
local M = {}

function M.start(E)
	local plr, C = E.plr, E.C
	local folder = Instance.new("Folder")
	folder.Name = "TrophyFX"
	folder.Parent = workspace
	local spin = {}
	local function bit(m, size, cf, color, mat, tr)
		local p = Instance.new("Part")
		p.Size, p.CFrame, p.Color, p.Material, p.Transparency, p.Anchored = size, cf, color, mat or Enum.Material.SmoothPlastic, tr or 0, true
		p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = false, false, false, false
		p.Parent = m
		return p
	end
	-- the figures, about one stud tall, built round `o` (the middle of the case, facing out)
	local FIG = {}
	function FIG.gate1(m, o) -- the Root Warden: basalt with turquoise crystal spikes
		local body = bit(m, Vector3.new(0.7, 0.8, 0.6), o * CFrame.new(0, -0.15, 0), Color3.fromRGB(46, 40, 60), Enum.Material.Slate)
		bit(m, Vector3.new(0.5, 0.16, 0.1), o * CFrame.new(0, 0.05, -0.33), Color3.fromRGB(28, 24, 38))
		for _, x in { -0.15, 0.15 } do bit(m, Vector3.new(0.1, 0.1, 0.06), o * CFrame.new(x, 0.05, -0.37), Color3.fromRGB(64, 224, 208), Enum.Material.Neon) end
		for _, s in { { -0.25, 0.42, 0.5, 14 }, { 0.05, 0.5, 0.66, -6 }, { 0.28, 0.4, 0.44, -18 } } do
			bit(m, Vector3.new(0.16, s[3], 0.16), o * CFrame.new(s[1], s[2], 0.05) * CFrame.Angles(0, 0.6, math.rad(s[4])), Color3.fromRGB(64, 224, 208), Enum.Material.Glass, 0.2)
		end
		return body
	end
	function FIG.gate2(m, o) -- the Kiln Golem: fired clay with a glowing kiln mouth
		local body = bit(m, Vector3.new(0.8, 0.6, 0.6), o * CFrame.new(0, -0.25, 0), Color3.fromRGB(196, 108, 70))
		bit(m, Vector3.new(0.46, 0.4, 0.46), o * CFrame.new(0, 0.26, 0), Color3.fromRGB(214, 128, 84))
		bit(m, Vector3.new(0.36, 0.2, 0.06), o * CFrame.new(0, -0.25, -0.32), Color3.fromRGB(255, 150, 50), Enum.Material.Neon)
		for _, x in { -0.1, 0.1 } do bit(m, Vector3.new(0.08, 0.08, 0.06), o * CFrame.new(x, 0.3, -0.25), Color3.fromRGB(255, 200, 90), Enum.Material.Neon) end
		for _, x in { -0.52, 0.52 } do bit(m, Vector3.new(0.24, 0.5, 0.3), o * CFrame.new(x, -0.2, 0), Color3.fromRGB(170, 90, 60)) end
		return body
	end
	local function pet(name)
		return function(m, o) -- a pet in its own two colours (Config.PETS)
			local p = C.PETS[name]
			local c1, c2 = p and p[5] or Color3.new(1, 1, 1), p and p[6] or Color3.new(1, 1, 0.6)
			local body = bit(m, Vector3.new(0.6, 0.45, 0.8), o * CFrame.new(0, -0.3, 0.05), c1)
			bit(m, Vector3.new(0.46, 0.42, 0.42), o * CFrame.new(0, 0.1, -0.3), c1)
			for _, x in { -0.16, 0.16 } do
				bit(m, Vector3.new(0.12, 0.2, 0.1), o * CFrame.new(x, 0.4, -0.25), c2)
				bit(m, Vector3.new(0.08, 0.1, 0.05), o * CFrame.new(x * 0.8, 0.14, -0.53), Color3.fromRGB(30, 22, 44))
			end
			bit(m, Vector3.new(0.14, 0.14, 0.5), o * CFrame.new(0, -0.1, 0.6) * CFrame.Angles(0.6, 0, 0), c2, Enum.Material.Neon)
			return body
		end
	end
	FIG.Ouro, FIG.Ninering = pet("Ouro"), pet("Ninering")

	local function cases()
		local out = {}
		local house = workspace:FindFirstChild("Hub") and workspace.Hub:FindFirstChild("TrophyHouse")
		for _, d in house and house:GetChildren() or {} do
			if d.Name == "TrophyGlass" and d:GetAttribute("Trophy") then out[d:GetAttribute("Trophy")] = d end
		end
		return out, house
	end
	local function fill()
		folder:ClearAllChildren()
		table.clear(spin)
		local have = {}
		for key in string.gmatch(plr:GetAttribute("Trophies") or "", "[^,]+") do have[key] = true end
		local glass, house = cases()
		for _, t in C.TROPHIES do
			local g = glass[t[1]]
			if g then
				local m = Instance.new("Model")
				m.Name = t[1]
				local o = g.CFrame * CFrame.Angles(0, math.pi, 0) -- the case's front is its +z face, a figure's front is -z
				if have[t[1]] and FIG[t[1]] then
					m.PrimaryPart = FIG[t[1]](m, o)
					m:SetAttribute("Earned", true)
					table.insert(spin, { m, g.CFrame, #spin * 1.7 })
				else
					m.PrimaryPart = bit(m, Vector3.new(0.5, 0.5, 0.5), o * CFrame.new(0, -0.35, 0) * CFrame.Angles(0.3, 0.7, 0.2), Color3.fromRGB(44, 36, 62), Enum.Material.Slate)
				end
				m.Parent = folder
				local plaque
				for _, d in house:GetChildren() do
					if d.Name == "TrophyPlaque" and d:GetAttribute("Trophy") == t[1] then plaque = d end
				end
				local line = plaque and plaque:FindFirstChild("Line", true)
				if line then
					line.Text = have[t[1]] and t[2] or ("???\n" .. t[3])
					line.TextColor3 = have[t[1]] and Color3.fromRGB(255, 214, 107) or Color3.fromRGB(200, 190, 225)
				end
			end
		end
	end
	plr:GetAttributeChangedSignal("Trophies"):Connect(fill)
	task.spawn(function() -- the town may still be building when this starts
		for _ = 1, 60 do
			local c = cases()
			if next(c) then break end
			task.wait(1)
		end
		fill()
	end)
	RunService.Heartbeat:Connect(function() -- earned figures turn slowly and bob a little
		local now = os.clock()
		for _, s in spin do
			if s[1].PrimaryPart then
				s[1]:PivotTo(s[2] * CFrame.new(0, math.sin(now * 1.4 + s[3]) * 0.05, 0) * CFrame.Angles(0, now * 0.5 + s[3], 0) * CFrame.new(0, -0.15, 0))
			end
		end
	end)
end

return M
