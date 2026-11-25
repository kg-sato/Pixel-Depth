-- Stack4FX (ReplicatedStorage.Shared.Stack4FX). Master Directive v16 3.2 (the DgAQV4PuLkS "4-layer" voxel VFX formula): one
-- call plays, at a point on the floor, (1) a ground rune ring of pixel cubes that turns and fades, (2) two halo rings rising up,
-- (3) vertical voxel sparks shooting up, (4) an expanding floor shockwave. Used by the Boon Shrines (BoonUI), the Crystal Chime
-- wakes (CrystalChimes) and the hearthstone teleport (Hearth). Display only; Reduced Motion plays only the shockwave.
local RunService = game:GetService("RunService")
local M = {}
local folder

local function cube(col, sz)
	if not folder or not folder.Parent then
		folder = Instance.new("Folder")
		folder.Name = "Stack4FX"
		folder.Parent = workspace
	end
	local q = Instance.new("Part")
	q.Size, q.Material, q.Color = Vector3.one * sz, Enum.Material.Neon, col
	q.Anchored, q.CanCollide, q.CanQuery, q.CanTouch, q.CastShadow = true, false, false, false, false
	q.Parent = folder
	return q
end

function M.play(pos, col, scale)
	if typeof(pos) ~= "Vector3" then return end
	col = col or Color3.fromRGB(120, 240, 255)
	scale = scale or 1
	local calm = false
	pcall(function() calm = game:GetService("GuiService").ReducedMotionEnabled end)
	local ground = pos + Vector3.new(0, 0.08, 0)
	local parts = {}
	local rune, halo, sparks, wave = {}, {}, {}, {}
	if not calm then
		for i = 1, 16 do local q = cube(col, 0.22 * scale) table.insert(rune, q) table.insert(parts, q) end
		for r = 1, 2 do for i = 1, 14 do local q = cube(col, 0.16 * scale) table.insert(halo, { q = q, r = r, i = i }) table.insert(parts, q) end end
		for i = 1, 10 do local q = cube(col:Lerp(Color3.new(1, 1, 1), 0.3), 0.18 * scale) table.insert(sparks, { q = q, a = math.random() * math.pi * 2, d = math.random() * 1.4 * scale, v = (5 + math.random() * 4) * scale, w = math.random() * 0.3 }) table.insert(parts, q) end
	end
	for i = 1, 24 do local q = cube(col, 0.26 * scale) table.insert(wave, q) table.insert(parts, q) end
	local t0 = os.clock()
	local c
	c = RunService.Heartbeat:Connect(function()
		local u = os.clock() - t0
		if u > 1.4 then
			c:Disconnect()
			for _, q in parts do q:Destroy() end
			return
		end
		local R = 2.2 * scale
		for i, q in rune do -- 1: the rune ring, turning, fading out after a second
			local a = u * 1.6 + i / #rune * math.pi * 2
			q.CFrame = CFrame.new(ground + Vector3.new(math.cos(a) * R, 0, math.sin(a) * R)) * CFrame.Angles(0, -a, 0)
			q.Transparency = math.clamp((u - 0.9) / 0.5, 0, 1)
		end
		for _, h in halo do -- 2: two halo rings rising, the second a beat later
			local k = math.clamp((u - 0.12 * h.r) / 0.9, 0, 1)
			local a = -u * 2 + h.i / 14 * math.pi * 2
			local rr = R * (0.85 - 0.35 * k)
			h.q.CFrame = CFrame.new(ground + Vector3.new(math.cos(a) * rr, k * 4.2 * scale, math.sin(a) * rr))
			h.q.Transparency = (k <= 0 or k >= 1) and 1 or k
		end
		for _, s in sparks do -- 3: voxel sparks shooting up
			local k = math.clamp((u - s.w) / 0.8, 0, 1)
			s.q.CFrame = CFrame.new(ground + Vector3.new(math.cos(s.a) * s.d, s.v * k - 3 * k * k, math.sin(s.a) * s.d)) * CFrame.Angles(k * 5, k * 3, 0)
			s.q.Transparency = (k <= 0 or k >= 1) and 1 or k
		end
		local k = math.clamp(u / 0.7, 0, 1) -- 4: the floor shockwave
		for i, q in wave do
			local a = i / #wave * math.pi * 2
			local rr = R * (0.3 + 2.4 * k)
			q.CFrame = CFrame.new(ground + Vector3.new(math.cos(a) * rr, 0, math.sin(a) * rr)) * CFrame.Angles(0, -a, 0)
			q.Transparency = k >= 1 and 1 or k
		end
	end)
end

return M
