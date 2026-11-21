-- Crests (ReplicatedStorage.Shared.Crests): the chunky voxel crest objects of the blessings and the Soul Tree nodes (a flare
-- stick, a gold shield, a pink heart), shown live by Shared.ModelCard. Moved out of BoonUI (directive v13) so the Soul Tree
-- uses the same crests instead of flat emoji icons (Gemini v13: "generic emoji-style clipart"). Each crest is two layers deep
-- (a dark back layer a step behind the bright face) with a lit highlight, so it reads as a carved object, not a flat sprite.
local M = {}

function M.model(id) -- "flare", "shield" or anything else (a heart: Second Wind, Thick Hide)
	local m = Instance.new("Model")
	local function blk(size, cf, color, mat, shape)
		local p = Instance.new("Part")
		p.Size, p.CFrame, p.Color, p.Material, p.Anchored = size, cf, color, mat or Enum.Material.SmoothPlastic, true
		if shape then p.Shape = shape end
		p.Parent = m
		if not m.PrimaryPart then m.PrimaryPart = p end
		return p
	end
	local V = 0.6 -- one voxel
	local function grid(rows, colors, depth, z, mat) -- rows: strings top to bottom, a letter = a colour key, "." = empty
		local h = #rows
		for r, row in rows do
			local w = #row
			for c = 1, w do
				local k = string.sub(row, c, c)
				if colors[k] then
					blk(Vector3.new(V, V, depth), CFrame.new((c - (w + 1) / 2) * V, ((h + 1) / 2 - r) * V, z), colors[k], mat)
				end
			end
		end
	end
	if id == "flare" then -- a red flare stick with white bands and a brass cap, a stepped voxel flame on top
		local tilt = CFrame.Angles(0, 0, math.rad(-16))
		blk(Vector3.new(0.75, 2.8, 0.75), tilt * CFrame.new(0, -0.9, 0), Color3.fromRGB(206, 44, 64))
		for _, y in { -1.7, -0.5 } do blk(Vector3.new(0.8, 0.2, 0.8), tilt * CFrame.new(0, y, 0), Color3.fromRGB(250, 236, 226)) end
		blk(Vector3.new(0.95, 0.4, 0.95), tilt * CFrame.new(0, 0.62, 0), Color3.fromRGB(226, 176, 84), Enum.Material.Metal)
		local top = tilt * CFrame.new(0, 0.85, 0)
		grid({ "..y..", ".yoy.", "yoroy", "orrro", ".rrr." }, { y = Color3.fromRGB(255, 236, 150), o = Color3.fromRGB(255, 160, 60), r = Color3.fromRGB(255, 90, 70) }, 0.5, 0, Enum.Material.Neon)
		for _, p in m:GetChildren() do -- the flame grid was built round the origin: lift it onto the cap
			if p.Material == Enum.Material.Neon then p.CFrame = top * CFrame.new(0, 1.55, 0) * (CFrame.new(0, 0, 0):ToObjectSpace(p.CFrame)) end
		end
	elseif id == "shield" then -- a heater shield: a dark bronze back, a bright gold face with a rim, a glowing gem boss
		local rows = { "rrrrrrr", "rgggggr", "rgggggr", "rgggggr", ".rgggr.", "..rgr..", "...r..." }
		grid(rows, { r = Color3.fromRGB(176, 118, 40), g = Color3.fromRGB(255, 204, 88) }, 0.42, 0, Enum.Material.Metal)
		grid(rows, { r = Color3.fromRGB(96, 62, 28), g = Color3.fromRGB(120, 80, 34) }, 0.42, 0.38, Enum.Material.Metal)
		blk(Vector3.new(1.05, 1.05, 0.4), CFrame.new(0, 0.5, -0.34) * CFrame.Angles(0, 0, math.rad(45)), Color3.fromRGB(110, 230, 255), Enum.Material.Neon)
		blk(Vector3.new(0.35, 0.35, 0.2), CFrame.new(-0.3, 0.8, -0.56), Color3.fromRGB(240, 255, 255), Enum.Material.Neon)
	else -- a pink voxel heart, a darker berry layer behind, a white highlight on its upper left
		local rows = { ".hh.hh.", "hhhhhhh", "hhhhhhh", ".hhhhh.", "..hhh..", "...h..." }
		grid(rows, { h = Color3.fromRGB(255, 104, 156) }, 0.45, 0)
		grid(rows, { h = Color3.fromRGB(170, 40, 92) }, 0.45, 0.42)
		blk(Vector3.new(0.6, 0.6, 0.25), CFrame.new(-1.2, 1.2, -0.3), Color3.fromRGB(255, 230, 240), Enum.Material.Neon)
		blk(Vector3.new(0.3, 0.3, 0.2), CFrame.new(-0.6, 1.5, -0.32), Color3.fromRGB(255, 230, 240), Enum.Material.Neon)
	end
	return m
end

return M
