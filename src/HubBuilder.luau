-- ServerScriptService.HubBuilder: the shared Surface Camp hub, built from voxel parts (Miro "3D Design" board, Pixel Depths v1.5:
-- "Hollow Mountain inside the World Tree roots"; hub concepts art/hub/pd_hub_vox_s41.png and pd_hub_s21.png).
-- Art rules from the board: chunky voxels, flat-colour faces, three hue-shifted shades per material (cool violet shadows,
-- warm yellow highlights), no textures, no outlines. Seen from the bird's-eye camera south of the player looking north.
-- Hub.build(parent, origin) returns the Model; station parts carry attributes the server hooks up:
-- Station = "sell" | "forge" | "hatch" | "map" | "chest" | "enter" (each has a ProximityPrompt), and "SpawnPoint" / "SellPoint".
local Hub = {}

-- three shades per material: dark (cool), mid, light (warm)
local PAL = {
	wood = { Color3.fromRGB(92, 58, 62), Color3.fromRGB(138, 92, 74), Color3.fromRGB(178, 128, 92) },
	plank = { Color3.fromRGB(110, 72, 64), Color3.fromRGB(156, 108, 82), Color3.fromRGB(196, 148, 106) },
	stone = { Color3.fromRGB(78, 74, 104), Color3.fromRGB(108, 104, 138), Color3.fromRGB(140, 136, 170) },
	plaza = { Color3.fromRGB(96, 84, 116), Color3.fromRGB(122, 108, 142), Color3.fromRGB(150, 134, 166) },
	grass = { Color3.fromRGB(40, 92, 90), Color3.fromRGB(54, 114, 104), Color3.fromRGB(74, 140, 118) },
	dirt = { Color3.fromRGB(46, 34, 54), Color3.fromRGB(70, 50, 68), Color3.fromRGB(96, 70, 82) },
	bark = { Color3.fromRGB(50, 30, 74), Color3.fromRGB(74, 44, 104), Color3.fromRGB(100, 62, 134) },
	leaf = { Color3.fromRGB(30, 88, 86), Color3.fromRGB(48, 124, 112), Color3.fromRGB(86, 170, 140) },
	roof = { Color3.fromRGB(58, 52, 82), Color3.fromRGB(84, 76, 112), Color3.fromRGB(112, 102, 142) },
	moss = { Color3.fromRGB(46, 104, 88), Color3.fromRGB(66, 136, 106), Color3.fromRGB(96, 168, 126) },
	pink = { Color3.fromRGB(196, 84, 116), Color3.fromRGB(232, 122, 150), Color3.fromRGB(250, 186, 200) },
	cream = { Color3.fromRGB(200, 184, 180), Color3.fromRGB(232, 220, 206), Color3.fromRGB(246, 238, 226) },
}
local LAMP, CYAN, GOLD, EMBER = Color3.fromRGB(255, 206, 120), Color3.fromRGB(110, 236, 255), Color3.fromRGB(255, 214, 92), Color3.fromRGB(255, 150, 70)

local model -- the hub Model being built
local function hash(x, y, z)
	local h = math.sin(x * 12.9898 + y * 78.233 + z * 37.719) * 43758.5453
	return h - math.floor(h)
end
local function shadeOf(mat, x, y, z)
	local p = PAL[mat]
	local h = hash(math.floor(x), math.floor(y), math.floor(z))
	return p[h < 0.25 and 1 or (h < 0.75 and 2 or 3)]
end

local function vox(parent, name, size, cf, color, props)
	local p = Instance.new("Part")
	p.Name, p.Size, p.CFrame, p.Color = name, size, typeof(cf) == "Vector3" and CFrame.new(cf) or cf, color
	p.Material = Enum.Material.SmoothPlastic
	p.Anchored, p.TopSurface, p.BottomSurface = true, Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	for k, v in props or {} do p[k] = v end
	p.Parent = parent or model
	return p
end
local function glow(p, color, range, brightness, shadows)
	p.Material = Enum.Material.Neon
	local l = Instance.new("PointLight")
	l.Color, l.Range, l.Brightness, l.Shadows = color, range, brightness, shadows or false
	l.Parent = p
	return l
end
local function group(name)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = model
	return m
end

-- A wall of voxel bricks in a frame `at` (local x along the wall, y up), size w x h, brick size b, material mat
local function brickWall(g, at, w, h, b, mat, depth, holes)
	for y = 0, math.floor(h / b) - 1 do
		local off = (y % 2) * b / 2
		local x = -w / 2 - off
		while x < w / 2 do
			local x0, x1 = math.max(x, -w / 2), math.min(x + b, w / 2)
			if x1 - x0 > 0.05 then
				local cx, cy = (x0 + x1) / 2, (y + 0.5) * b
				local skip = false
				for _, hole in holes or {} do
					if cx > hole[1] and cx < hole[2] and cy > hole[3] and cy < hole[4] then skip = true end
				end
				if not skip then
					vox(g, "Brick", Vector3.new(x1 - x0 - 0.06, b - 0.06, depth), at(cx, cy, 0), shadeOf(mat, cx * 3, cy * 3, 7))
				end
			end
			x += b
		end
	end
end

-- Stepped voxel roof over a w x d footprint, ridge along x, rising from height y0
local function stepRoof(g, at, w, d, y0, steps, mat)
	for i = 0, steps - 1 do
		local dd = d + 1.2 - i * (d + 1.2) / steps
		vox(g, "Roof", Vector3.new(w + 1.2, 0.9, dd), at(0, y0 + i * 0.9 + 0.45, 0), PAL[mat][i == 0 and 1 or 2])
	end
	vox(g, "Ridge", Vector3.new(w + 1.6, 0.7, 0.9), at(0, y0 + steps * 0.9 + 0.35, 0), PAL[mat][3])
end

local function sign(g, text, cf, w, h, fg)
	local board = vox(g, "Sign", Vector3.new(w, h, 0.4), cf, PAL.wood[1], { CanCollide = false })
	for _, face in { Enum.NormalId.Back, Enum.NormalId.Front } do
		local sg = Instance.new("SurfaceGui")
		sg.Face, sg.SizingMode, sg.PixelsPerStud, sg.LightInfluence = face, Enum.SurfaceGuiSizingMode.PixelsPerStud, 40, 0
		local t = Instance.new("TextLabel")
		t.Name = "Label"
		t.Size, t.BackgroundTransparency, t.Text, t.TextScaled = UDim2.fromScale(1, 1), 1, text, true
		t.Font, t.TextColor3, t.TextStrokeTransparency, t.TextStrokeColor3 = Enum.Font.Arcade, fg or PAL.cream[2], 0, Color3.fromRGB(42, 28, 58)
		local pad = Instance.new("UIPadding")
		pad.PaddingLeft, pad.PaddingRight, pad.PaddingTop, pad.PaddingBottom = UDim.new(0.08, 0), UDim.new(0.08, 0), UDim.new(0.15, 0), UDim.new(0.15, 0)
		pad.Parent = t
		t.Parent = sg
		sg.Parent = board
	end
	return board
end

local function prompt(p, action, object, station)
	local pr = Instance.new("ProximityPrompt")
	pr.ActionText, pr.ObjectText, pr.KeyboardKeyCode = action, object, Enum.KeyCode.F
	pr.MaxActivationDistance, pr.RequiresLineOfSight, pr.HoldDuration = 14, false, 0
	pr.Parent = p
	p:SetAttribute("Station", station)
	return pr
end

local function cubeLantern(g, pos, hang)
	if hang then vox(g, "Chain", Vector3.new(0.2, hang, 0.2), pos + Vector3.new(0, 1.1 + hang / 2, 0), PAL.stone[1], { CanCollide = false }) end
	vox(g, "LanternCap", Vector3.new(1.5, 0.35, 1.5), pos + Vector3.new(0, 0.95, 0), PAL.wood[1], { CanCollide = false })
	vox(g, "LanternBase", Vector3.new(1.5, 0.35, 1.5), pos - Vector3.new(0, 0.95, 0), PAL.wood[1], { CanCollide = false })
	local core = vox(g, "Lantern", Vector3.new(1.1, 1.5, 1.1), pos, LAMP, { CanCollide = false })
	glow(core, LAMP, 16, 0.7)
	core:SetAttribute("Sway", 0.08)
	return core
end

-- Voxelize a set of tubes (cubic bezier roots) on a grid of size V: only shell voxels, merged along x per shade
local function voxTubes(g, tubes, V, mat, collide)
	local cells = {}
	local function key(i, j, k) return i .. "," .. j .. "," .. k end
	for _, t in tubes do
		local p0, p1, p2, p3, r0, r1 = t[1], t[2], t[3], t[4], t[5], t[6]
		local n = math.ceil((p0 - p3).Magnitude / (V * 0.5)) + 4
		for s = 0, n do
			local u = s / n
			local a = (1 - u)
			local c = p0 * a ^ 3 + p1 * 3 * a ^ 2 * u + p2 * 3 * a * u ^ 2 + p3 * u ^ 3
			local r = r0 + (r1 - r0) * u
			for i = math.floor((c.X - r) / V), math.ceil((c.X + r) / V) do
				for j = math.floor((c.Y - r) / V), math.ceil((c.Y + r) / V) do
					for k = math.floor((c.Z - r) / V), math.ceil((c.Z + r) / V) do
						local q = Vector3.new((i + 0.5) * V, (j + 0.5) * V, (k + 0.5) * V)
						if (q - c).Magnitude <= r and q.Y > -V then cells[key(i, j, k)] = { i, j, k } end
					end
				end
			end
		end
	end
	local rows = {} -- shell cells grouped by (j, k) row, then merged along i
	for _, c in cells do
		local i, j, k = c[1], c[2], c[3]
		if not (cells[key(i + 1, j, k)] and cells[key(i - 1, j, k)] and cells[key(i, j + 1, k)] and cells[key(i, j - 1, k)] and cells[key(i, j, k + 1)] and cells[key(i, j, k - 1)]) then
			local rk = j .. "," .. k
			rows[rk] = rows[rk] or {}
			table.insert(rows[rk], i)
		end
	end
	local count = 0
	for rk, list in rows do
		table.sort(list)
		local j, k = string.match(rk, "(-?%d+),(-?%d+)")
		j, k = tonumber(j), tonumber(k)
		local start, prev, prevShade = nil, nil, nil
		local function flush()
			if start then
				local len = prev - start + 1
				vox(g, "Root", Vector3.new(len * V, V, V), Vector3.new((start + len / 2) * V, (j + 0.5) * V, (k + 0.5) * V), prevShade, { CanCollide = collide })
				count += 1
			end
		end
		for _, i in list do
			local sh = shadeOf(mat, math.floor(i / 2), j, k)
			if start and i == prev + 1 and sh == prevShade then
				prev = i
			else
				flush()
				start, prev, prevShade = i, i, sh
			end
		end
		flush()
	end
	return count
end

local function leafClump(g, c, r, V)
	for i = -r, r do for j = -r, r do for k = -r, r do
		local d = math.sqrt(i * i + j * j * 1.6 + k * k)
		if d <= r and d > r - 1.2 and hash(i + c.X, j + c.Y, k + c.Z) > 0.18 then
			vox(g, "Leaf", Vector3.new(V, V, V), c + Vector3.new(i, j, k) * V, shadeOf("leaf", i + c.X, j + c.Y, k), { CanCollide = false })
		end
	end end end
end

function Hub.build(parent, origin)
	origin = origin or Vector3.zero
	model = Instance.new("Model")
	model.Name = "Hub"
	local O = origin
	local function W(x, y, z) return O + Vector3.new(x, y, z) end

	-- 1. Ground: lilac cobblestone plaza (tiles with gaps), grass voxels around it, a dark dirt rim under everything
	local ground = group("Ground")
	for _, b in { { -47, 0, 82, 160 }, { 47, 0, 82, 160 }, { 0, -43, 12, 74 }, { 0, 43, 12, 74 } } do -- dark grout/dirt under everything, open over the shaft
		vox(ground, "Base", Vector3.new(b[3], 6, b[4]), CFrame.new(W(b[1], -3, b[2])), PAL.dirt[1])
	end
	local PR, T, S = 34, 4, 3.2
	for x = -72, 68, T do -- grass outside the plaza
		for z = -72, 68, T do
			local cx, cz = x + T / 2, z + T / 2
			local d = math.sqrt(cx * cx + (cz * 1.15) ^ 2)
			if d < 74 and d >= PR + hash(cx, 0, cz) * 4 then
				local h = hash(cx, 2, cz)
				vox(ground, "Grass", Vector3.new(T, 0.6 + (h > 0.85 and 0.4 or 0), T), CFrame.new(W(cx, 0.3 + (h > 0.85 and 0.2 or 0), cz)), shadeOf("grass", cx, 0, cz))
				if h > 0.9 then -- a flower or a tuft voxel
					local fc = ({ PAL.pink[2], GOLD, PAL.cream[2], Color3.fromRGB(201, 184, 242), PAL.moss[3] })[math.floor(h * 1000) % 5 + 1]
					vox(ground, "Flower", Vector3.new(0.6, 0.6, 0.6), CFrame.new(W(cx + 0.6, 1.1, cz - 0.5)), fc, { CanCollide = false })
				end
			end
		end
	end
	for x = -PR, PR, S do -- cobblestones of mixed sizes with dark grout between them
		for z = -PR * 1.2, PR * 1.2, S do
			local row = math.floor((z + 100) / S)
			local jx, jz = (hash(x, 5, z) - 0.5) * 0.7 + (row % 2) * S / 2, (hash(x, 6, z) - 0.5) * 0.5
			local cx, cz = x + jx, z + jz
			local d = math.sqrt(cx * cx + (cz / 1.15) ^ 2)
			if d < PR + hash(x, 0, z) * 3 and not (math.abs(cx) < 7.5 and math.abs(cz) < 7.5) then
				local w, l = S - 0.5 - hash(x, 7, z) * 0.6, S - 0.5 - hash(x, 8, z) * 0.6
				vox(ground, "Cobble", Vector3.new(w, 0.45, l), CFrame.new(W(cx, 0.22 + hash(x, 9, z) * 0.08, cz)), shadeOf("plaza", x, 0, z))
			end
		end
	end

	-- 2. The mine shaft in the centre: stone-block rim, a pit with stone walls and a cyan crystal glow; falling in enters your mine
	local shaft = group("MineShaft")
	for _, o in { { 0, -1 }, { 0, 1 }, { -1, 0 }, { 1, 0 } } do
		for t = -6, 6, 2 do
			local x, z = o[1] ~= 0 and o[1] * 7 or t, o[2] ~= 0 and o[2] * 7 or t
			vox(shaft, "Rim", Vector3.new(2, 1.4, 2), CFrame.new(W(x, 0.7, z)), shadeOf("stone", x, 1, z))
			if (t + 6) % 4 == 0 then vox(shaft, "RimCap", Vector3.new(2.2, 0.5, 2.2), CFrame.new(W(x, 1.65, z)), PAL.stone[3]) end
		end
	end
	for y = 0, 4 do
		for _, o in { { 0, -1 }, { 0, 1 }, { -1, 0 }, { 1, 0 } } do
			for t = -5, 5, 2 do
				local x, z = o[1] ~= 0 and o[1] * 6.5 or t, o[2] ~= 0 and o[2] * 6.5 or t
				vox(shaft, "PitWall", Vector3.new(2, 2, 2), CFrame.new(W(x, -1 - y * 2, z)), shadeOf("stone", x, y, z):Lerp(Color3.new(), y * 0.1))
			end
		end
	end
	local pitFloor = vox(shaft, "PitFloor", Vector3.new(12, 1, 12), CFrame.new(W(0, -10.5, 0)), Color3.fromRGB(40, 120, 150))
	pitFloor:SetAttribute("Station", "enter")
	for i = 1, 7 do -- crystal shards glowing up out of the pit
		local a = i / 7 * math.pi * 2
		local c = vox(shaft, "PitCrystal", Vector3.new(0.9, 2 + (i % 3), 0.9), CFrame.new(W(math.cos(a) * 3.6, -8.5, math.sin(a) * 3.6)) * CFrame.Angles(math.sin(a) * 0.3, a, math.cos(a) * 0.3), CYAN, { CanCollide = false })
		if i % 3 == 0 then glow(c, CYAN, 26, 1.6) else c.Material = Enum.Material.Neon end
	end
	local sparks = Instance.new("ParticleEmitter")
	sparks.Rate, sparks.Lifetime, sparks.Speed = 8, NumberRange.new(2, 3.5), NumberRange.new(3, 6)
	sparks.Color, sparks.LightEmission, sparks.EmissionDirection = ColorSequence.new(CYAN), 1, Enum.NormalId.Top
	sparks.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0) })
	sparks.Parent = pitFloor
	-- headframe: two A-legs of voxel beams, a crossbeam, a cube-built pulley wheel, rope and a hanging crystal
	for _, s in { -1, 1 } do
		for _, z in { -6, 6 } do vox(shaft, "Leg", Vector3.new(1.4, 20, 1.4), CFrame.new(W(s * 7.5, 10, z)) * CFrame.Angles(z > 0 and 0.12 or -0.12, 0, 0), PAL.wood[2]) end
		vox(shaft, "Brace", Vector3.new(1, 1, 12), CFrame.new(W(s * 7.5, 7, 0)), PAL.wood[1])
	end
	vox(shaft, "CrossBeam", Vector3.new(17, 1.6, 1.6), CFrame.new(W(0, 19.5, 0)), PAL.wood[3])
	local wheel = group("LiftWheel")
	for i = 0, 11 do
		local a = i / 12 * math.pi * 2
		vox(wheel, "Rim", Vector3.new(1, 1, 1), CFrame.new(W(0, 22 + math.sin(a) * 2.6, math.cos(a) * 2.6)), i % 2 == 0 and PAL.wood[2] or PAL.wood[3])
	end
	vox(wheel, "Hub", Vector3.new(1.4, 1.4, 1.4), CFrame.new(W(0, 22, 0)), PAL.stone[2])
	for i = 0, 3 do vox(wheel, "Spoke", Vector3.new(0.5, 5, 0.5), CFrame.new(W(0, 22, 0)) * CFrame.Angles(i * math.pi / 4, 0, 0), PAL.wood[1]) end
	wheel:SetAttribute("SpinX", 1.4)
	vox(shaft, "Rope", Vector3.new(0.25, 14, 0.25), CFrame.new(W(0, 13, 2.6)), PAL.cream[1], { CanCollide = false })
	local hang = vox(shaft, "HangingCrystal", Vector3.new(1.6, 1.6, 1.6), CFrame.new(W(0, 5.4, 2.6)) * CFrame.Angles(0.6, 0.6, 0), CYAN, { CanCollide = false })
	glow(hang, CYAN, 18, 1.2)
	hang:SetAttribute("Bob", 0.3)
	sign(shaft, "MINE", CFrame.new(W(0, 17.2, 6.9)), 5, 1.8, GOLD)
	prompt(vox(shaft, "EnterPlate", Vector3.new(4, 0.3, 2), CFrame.new(W(0, 1.55, 7)), PAL.wood[3], { CanCollide = false }), "Enter the mine", "Lift", "enter")

	-- a station frame at (dx, dz), turned so its front (+Z) faces the shaft
	local function station(dx, dz)
		local p = W(dx, 0, dz)
		local away = Vector3.new(dx, 0, dz).Unit
		local cf = CFrame.lookAt(p, p + away)
		return function(x, y, z) return cf * CFrame.new(x, y, z) end
	end

	-- 3. Sell stall (west): plank counter, posts, pink and cream striped awning, ore crates, SELL sign
	do
		local g, at = group("SellStall"), station(-22, 4)
		for x = -4.5, 4.5, 1.5 do vox(g, "Counter", Vector3.new(1.5, 3, 3), at(x, 1.5, 0), shadeOf("plank", x * 2, 1, 0)) end
		vox(g, "CounterTop", Vector3.new(10, 0.5, 3.6), at(0, 3.25, 0.2), PAL.plank[3])
		for _, s in { -1, 1 } do for _, z in { 1.4, -2.6 } do vox(g, "Post", Vector3.new(0.9, 8.4, 0.9), at(s * 4.6, 4.2, z), PAL.wood[1]) end end
		for i = 0, 9 do
			for row = 0, 2 do
				vox(g, "Awning", Vector3.new(1.05, 0.5, 1.8), at(-4.75 + i * 1.05, 8.6 - row * 0.45, 1.2 - row * 1.7) * CFrame.Angles(math.rad(14), 0, 0), i % 2 == 0 and PAL.pink[2] or PAL.cream[2])
			end
		end
		for i, oc in { EMBER, Color3.fromRGB(201, 184, 242), GOLD } do
			local x = -3.2 + (i - 1) * 3.2
			vox(g, "Crate", Vector3.new(2.2, 1.4, 1.8), at(x, 4.2, -0.6), PAL.wood[1])
			for k = 0, 2 do vox(g, "Ore", Vector3.new(0.8, 0.8, 0.8), at(x - 0.6 + k * 0.6, 5.2 + (k == 1 and 0.4 or 0), -0.6), oc, { Material = i == 3 and Enum.Material.Neon or Enum.Material.SmoothPlastic }) end
		end
		cubeLantern(g, at(4.6, 7.2, 1.9).Position)
		sign(g, "SELL", at(0, 10.6, 1.4), 5, 1.8, GOLD)
		local counter = g:FindFirstChild("CounterTop")
		prompt(counter, "Sell ore", "Sell stall", "sell")
		vox(g, "SellPoint", Vector3.new(1, 1, 1), at(0, 3, 5), PAL.wood[1], { Transparency = 1, CanCollide = false, CanQuery = false })
	end

	-- 4. Forge (north-west): voxel stone hut, stepped roof, glowing furnace mouth, chimney smoke, anvil out front
	do
		local g, at = group("Forge"), station(-20, -20)
		for _, side in { { 0, 0, 0 }, { 0, 0, -9 } } do
			brickWall(g, function(x, y, z) return at(x, y, side[3] + z) end, 12, 8, 2, "stone", 1.6, side[3] == 0 and { { -4.2, 0, 0, 3.8 }, { 2, 4.6, 0, 6 } } or nil)
		end
		for _, s in { -1, 1 } do
			brickWall(g, function(x, y, z) return at(s * 5.2, y, -4.5 + x) * CFrame.Angles(0, math.pi / 2, 0) end, 8, 8, 2, "stone", 1.6)
		end
		stepRoof(g, at, 12, 10, 8, 5, "roof")
		local mouth = vox(g, "Furnace", Vector3.new(4, 3.6, 0.6), at(-2.1, 1.8, -0.6), EMBER, { CanCollide = false })
		glow(mouth, EMBER, 26, 2.2, true):SetAttribute("Flicker", 1)
		vox(g, "Door", Vector3.new(2.6, 6, 0.6), at(3.3, 3, -0.4), PAL.wood[1])
		local chimney = vox(g, "Chimney", Vector3.new(2.4, 7, 2.4), at(3.6, 12, -6.5), PAL.stone[1])
		local smoke = Instance.new("ParticleEmitter")
		smoke.Rate, smoke.Lifetime, smoke.Speed = 3, NumberRange.new(3, 5), NumberRange.new(2, 3)
		smoke.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 4) })
		smoke.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1) })
		smoke.Color, smoke.EmissionDirection = ColorSequence.new(Color3.fromRGB(180, 168, 210)), Enum.NormalId.Top
		smoke.Parent = chimney
		local anvil = vox(g, "Anvil", Vector3.new(2.8, 1.2, 1.4), at(-1, 2.3, 4.2), PAL.stone[1])
		vox(g, "AnvilHorn", Vector3.new(1, 0.7, 0.8), at(-2.8, 2.4, 4.2), PAL.stone[1])
		vox(g, "AnvilBase", Vector3.new(1.4, 1.7, 1.2), at(-1, 0.85, 4.2), PAL.wood[1])
		sign(g, "FORGE", at(0, 7.2, 0.9), 5.2, 1.6, Color3.fromRGB(255, 190, 140))
		prompt(anvil, "Upgrade", "Forge", "forge")
	end

	-- 5. Trophy house (north-east): stone house with a stepped purple roof and horned voxel skulls on the wall
	do
		local g, at = group("TrophyHouse"), station(20, -21)
		for _, side in { { 0 }, { -8 } } do
			brickWall(g, function(x, y, z) return at(x, y, side[1] + z) end, 11, 8, 2, "stone", 1.6, side[1] == 0 and { { -1.4, 1.4, 0, 5.4 } } or nil)
		end
		for _, s in { -1, 1 } do
			brickWall(g, function(x, y, z) return at(s * 4.7, y, -4 + x) * CFrame.Angles(0, math.pi / 2, 0) end, 7, 8, 2, "stone", 1.6)
		end
		stepRoof(g, at, 11, 9, 8, 5, "roof")
		vox(g, "Door", Vector3.new(2.6, 5.2, 0.5), at(0, 2.6, -0.3), PAL.wood[1])
		for i, x in { -3.4, 3.4 } do -- voxel skulls with horns either side of the door
			local y = 5.6
			vox(g, "Skull", Vector3.new(1.8, 1.6, 0.8), at(x, y, 1.1), PAL.cream[2])
			vox(g, "Jaw", Vector3.new(1.2, 0.6, 0.8), at(x, y - 1, 1.1), PAL.cream[1])
			for _, e in { -0.45, 0.45 } do vox(g, "Eye", Vector3.new(0.45, 0.45, 0.2), at(x + e, y + 0.1, 1.55), Color3.fromRGB(42, 28, 58)) end
			for _, s in { -1, 1 } do
				vox(g, "Horn", Vector3.new(1.2, 0.5, 0.5), at(x + s * 1.4, y + 0.6, 1.1), PAL.cream[1])
				vox(g, "HornTip", Vector3.new(0.5, 0.9, 0.5), at(x + s * 2.1, y + 1.2, 1.1), PAL.cream[3])
			end
			local gem = vox(g, "Gem", Vector3.new(0.7, 0.7, 0.7), at(x, y - 2.2, 1.1) * CFrame.Angles(0, 0, math.pi / 4), i == 1 and PAL.pink[2] or Color3.fromRGB(140, 227, 192), { CanCollide = false })
			gem.Material = Enum.Material.Neon
		end
		sign(g, "TROPHIES", at(0, 7.4, 0.9), 5.4, 1.2, GOLD)
	end

	-- 6. Two log guest cabins (east and south-east) with warm windows and stepped roofs
	for n, pos in { { 30, -2 }, { 27, 15 } } do
		local g, at = group("GuestCabin" .. n), station(pos[1], pos[2])
		for y = 0, 6 do -- stacked log rows with alternating shades
			local c = PAL.plank[(y % 2) + 1]
			vox(g, "Log", Vector3.new(9, 0.9, 0.9), at(0, 0.45 + y * 0.92, 0), c)
			vox(g, "Log", Vector3.new(9, 0.9, 0.9), at(0, 0.45 + y * 0.92, -7), c)
			for _, s in { -1, 1 } do vox(g, "Log", Vector3.new(0.9, 0.9, 7.9), at(s * 4.1, 0.45 + y * 0.92, -3.5), c) end
		end
		stepRoof(g, function(x, y, z) return at(x, y, z - 3.5) end, 9, 8, 6.4, 4, n == 1 and "roof" or "grass")
		local win = vox(g, "Window", Vector3.new(2.2, 1.8, 0.3), at(-2, 3.6, 0.55), LAMP, { CanCollide = false })
		glow(win, LAMP, 14, 0.9)
		vox(g, "Door", Vector3.new(2, 4.4, 0.3), at(2, 2.2, 0.55), PAL.wood[1], { CanCollide = false })
		vox(g, "Step", Vector3.new(3, 0.5, 1.6), at(2, 0.25, 1.4), PAL.stone[2])
	end
	sign(model, "GUESTS SOON", CFrame.new(W(22, 2.4, 8)) * CFrame.Angles(0, -0.7, 0), 4.6, 1.2)

	-- 7. Egg incubator (south-west): small shed, glass dome, three glowing pastel voxel eggs
	do
		local g, at = group("Incubator"), station(-25, 17)
		vox(g, "Base", Vector3.new(10, 1.2, 10), at(0, 0.6, -2), PAL.wood[1])
		for _, c in { { -4, -6 }, { 4, -6 }, { -4, 2 }, { 4, 2 } } do vox(g, "Frame", Vector3.new(0.7, 6.4, 0.7), at(c[1], 4.4, c[2]), PAL.wood[1]) end
		vox(g, "FrameTop", Vector3.new(8.7, 0.7, 8.7), at(0, 7.6, -2), PAL.wood[2])
		for _, z in { 2, -6 } do vox(g, "Glass", Vector3.new(7.3, 6, 0.2), at(0, 4.4, z), Color3.fromRGB(190, 230, 250), { Transparency = 0.75, CanCollide = false }) end
		for _, x in { -4, 4 } do vox(g, "Glass", Vector3.new(0.2, 6, 7.3), at(x, 4.4, -2), Color3.fromRGB(190, 230, 250), { Transparency = 0.75, CanCollide = false }) end
		for i, ec in { PAL.pink[2], PAL.cream[2], Color3.fromRGB(140, 227, 192) } do
			local e = group("Egg" .. i)
			local x, z = -2.6 + (i - 1) * 2.6, -2 + (i == 2 and -0.9 or 0.6)
			vox(e, "Low", Vector3.new(1.6, 1, 1.6), at(x, 1.8, z), ec)
			vox(e, "Mid", Vector3.new(1.8, 1.1, 1.8), at(x, 2.8, z), ec)
			vox(e, "Top", Vector3.new(1.2, 0.8, 1.2), at(x, 3.7, z), ec)
			for _, p in e:GetChildren() do p.Material = Enum.Material.Neon end
			e:SetAttribute("Bob", 0.25 + i * 0.05)
			if i == 2 then glow(e:FindFirstChild("Mid"), Color3.fromRGB(255, 220, 200), 18, 1.4) end
		end
		sign(g, "EGGS", at(0, 7.6, 2.9), 4, 1.5, PAL.pink[3])
		prompt(g:FindFirstChild("Base"), "Hatch an egg", "Incubator", "hatch")
	end

	-- 8. Notice board and the daily relic chest (north)
	do
		local g, at = group("NoticeBoard"), station(-4, -24)
		for _, s in { -1, 1 } do vox(g, "Post", Vector3.new(0.8, 6.4, 0.8), at(s * 2.8, 3.2, 0), PAL.wood[1]) end
		vox(g, "Board", Vector3.new(6, 3.6, 0.5), at(0, 4.4, 0.1), PAL.plank[2])
		for i = 0, 4 do vox(g, "Paper", Vector3.new(1.2, 1.4, 0.1), at(-2.2 + i * 1.1, 4.4 + (i % 2) * 0.5, 0.4), PAL.cream[(i % 2) + 2], { CanCollide = false }) end
		sign(g, "NOTICES", at(0, 7, 0.1), 4.4, 1, PAL.cream[2])
		local chest = vox(g, "Chest", Vector3.new(3, 1.8, 2), at(4.6, 0.9, 1.6), PAL.wood[2])
		vox(g, "ChestLid", Vector3.new(3.2, 0.7, 2.2), at(4.6, 2.1, 1.6), GOLD)
		prompt(chest, "Open", "Daily relic chest", "chest")
		local map = vox(g, "MapBoard", Vector3.new(4.6, 3, 0.4), at(-6.5, 3.6, 0.6), PAL.cream[2])
		for i, lc in { Color3.fromRGB(128, 86, 54), Color3.fromRGB(188, 94, 62), Color3.fromRGB(62, 82, 142), Color3.fromRGB(124, 32, 26), Color3.fromRGB(42, 124, 134), Color3.fromRGB(84, 52, 114), Color3.fromRGB(34, 22, 44) } do
			vox(g, "MapLayer", Vector3.new(4, 0.32, 0.1), at(-6.5, 4.9 - i * 0.38, 0.85), lc, { CanCollide = false })
		end
		vox(g, "MapPost", Vector3.new(0.5, 3, 0.5), at(-6.5, 1.5, 0.6), PAL.wood[1])
		prompt(map, "Look at the map", "Map", "map")
	end

	-- 9. Campfire with stone ring, log benches and voxel flames (south of the shaft)
	do
		local g = group("Campfire")
		local c = W(9, 0, 20)
		for i = 0, 9 do
			local a = i / 10 * math.pi * 2
			vox(g, "Stone", Vector3.new(1.3, 0.9, 1.3), CFrame.new(c + Vector3.new(math.cos(a) * 2.3, 0.45, math.sin(a) * 2.3)), shadeOf("stone", i, 0, 3))
		end
		for _, a in { 0.3, 1.9 } do vox(g, "Log", Vector3.new(3.2, 0.7, 0.7), CFrame.new(c + Vector3.new(0, 0.5, 0)) * CFrame.Angles(0, a, 0), PAL.wood[1]) end
		local flames = group("Flames")
		flames.Parent = g
		for i, f in { { 0, 1.3, 0, 1.4, EMBER }, { 0.3, 2.3, 0.2, 1, GOLD }, { -0.3, 1.9, -0.2, 0.9, Color3.fromRGB(255, 110, 150) }, { 0, 3.1, 0, 0.6, Color3.fromRGB(255, 240, 180) } } do
			local p = vox(flames, "Flame", Vector3.new(f[4], f[4], f[4]), CFrame.new(c + Vector3.new(f[1], f[2], f[3])), f[5], { CanCollide = false, Material = Enum.Material.Neon })
			if i == 1 then glow(p, EMBER, 30, 2.2, true):SetAttribute("Flicker", 1) end
		end
		flames:SetAttribute("Flames", true)
		for _, s in { -1, 1 } do vox(g, "Bench", Vector3.new(1.2, 1, 4.2), CFrame.new(c + Vector3.new(s * 5, 0.5, 0)), PAL.wood[2]) end
		vox(g, "Bench", Vector3.new(4.2, 1, 1.2), CFrame.new(c + Vector3.new(0, 0.5, 5)), PAL.wood[3])
	end

	-- 10. Friends bench (south-east)
	vox(model, "FriendsBench", Vector3.new(5, 0.6, 1.6), CFrame.new(W(18, 1.4, 26)), PAL.plank[3])
	vox(model, "FriendsBenchBack", Vector3.new(5, 1.6, 0.5), CFrame.new(W(18, 2.4, 26.8)), PAL.plank[2])
	for _, s in { -1, 1 } do vox(model, "FriendsBenchLeg", Vector3.new(0.5, 1.1, 1.4), CFrame.new(W(18 + s * 2.1, 0.55, 26)), PAL.wood[1]) end
	sign(model, "FRIENDS", CFrame.new(W(18, 4.2, 27.1)), 3.8, 1, PAL.pink[3])

	-- 11. Lantern posts round the plaza
	local posts = group("LanternPosts")
	for i = 0, 9 do
		local a = i / 10 * math.pi * 2 + 0.3
		local p = W(math.cos(a) * 30, 0, math.sin(a) * 30 * 0.87)
		if not (math.abs(p.X - O.X) < 8 and p.Z - O.Z > 20) then -- keep the front open for the camera
			vox(posts, "Post", Vector3.new(0.8, 7, 0.8), CFrame.new(p + Vector3.new(0, 3.5, 0)), PAL.wood[1])
			vox(posts, "Arm", Vector3.new(2.2, 0.5, 0.5), CFrame.new(p + Vector3.new(0.9, 7, 0)), PAL.wood[1])
			cubeLantern(posts, p + Vector3.new(1.8, 5.6, 0), 0.6)
		end
	end

	-- 12. The World Tree: a huge trunk behind the camp (north) and voxel roots that wall the plaza and arch overhead
	local tree = group("WorldTree")
	local trunk = W(0, 0, -74)
	local tubes = {
		{ trunk + Vector3.new(0, -2, 0), trunk + Vector3.new(0, 40, 0), trunk + Vector3.new(0, 80, 0), trunk + Vector3.new(0, 124, 0), 16, 11 }, -- trunk
	}
	for _, s in { -1, 1 } do -- roots wall the plaza on the west, north and east; the south stays open for the camera
		local function T(p0, p1, p2, p3, r0, r1)
			table.insert(tubes, { p0, W(p1[1] * s, p1[2], p1[3]), W(p2[1] * s, p2[2], p2[3]), W(p3[1] * s, p3[2], p3[3]), r0, r1 })
		end
		T(trunk + Vector3.new(s * 10, 14, 8), { 40, 26, -50 }, { 58, 16, -10 }, { 52, -1, 24 }, 5, 2.8)
		T(trunk + Vector3.new(s * 8, 6, 10), { 30, 12, -46 }, { 44, 8, -26 }, { 40, -1, -12 }, 4, 2.5)
		T(W(s * 56, 6, 0), { 62, 10, 20 }, { 52, 6, 40 }, { 34, -1, 54 }, 3.4, 2.2)
		T(trunk + Vector3.new(s * 14, 4, 12), { 20, 6, -50 }, { 26, 4, -42 }, { 30, -1, -34 }, 3.4, 2)
		T(trunk + Vector3.new(s * 12, 60, 0), { 30, 72, -52 }, { 50, 62, -36 }, { 60, 28, -22 }, 4, 2.6) -- high arch behind the camp
	end
	voxTubes(tree, tubes, 3, "bark", true)
	for _, c in { W(-30, 72, -50), W(30, 72, -50), W(0, 124, -74), W(-18, 120, -70), W(18, 118, -78), W(-50, 60, -36), W(50, 60, -36), W(-56, 22, -6), W(56, 22, -6) } do
		leafClump(tree, c, 3, 2.8)
	end
	for i, p in { W(-46, 12, -14), W(46, 12, -14), W(-44, 12, 12), W(44, 12, 12), W(-26, 22, -44), W(26, 22, -44), W(-52, 8, 30), W(52, 8, 30) } do -- lanterns hanging from the roots
		cubeLantern(tree, p, 2 + (i % 3) * 2)
	end
	local flies = Instance.new("ParticleEmitter") -- fireflies drifting round the canopy
	flies.Rate, flies.Lifetime, flies.Speed, flies.SpreadAngle = 6, NumberRange.new(4, 7), NumberRange.new(0.5, 1.5), Vector2.new(180, 180)
	flies.Color, flies.LightEmission = ColorSequence.new(Color3.fromRGB(198, 247, 226), GOLD), 1
	flies.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.2, 0.35), NumberSequenceKeypoint.new(1, 0) })
	local flyBox = vox(tree, "Fireflies", Vector3.new(90, 30, 70), CFrame.new(W(0, 26, -16)), Color3.new(), { Transparency = 1, CanCollide = false, CanQuery = false })
	flies.Shape, flies.Parent = Enum.ParticleEmitterShape.Box, flyBox

	-- 13. Props that make the camp feel lived in: an ore cart on rails, barrels, crate stacks, bushes, glowing mushrooms, a log pile
	local props = group("Props")
	for i = 0, 7 do -- rails from the shaft rim toward the sell stall
		local x = -9 - i * 1.6
		vox(props, "Sleeper", Vector3.new(0.6, 0.25, 2.6), CFrame.new(W(x, 0.55, 2)), PAL.wood[1])
	end
	for _, z in { 1.1, 2.9 } do vox(props, "Rail", Vector3.new(13, 0.25, 0.3), CFrame.new(W(-14.6, 0.8, z)), PAL.stone[1]) end
	vox(props, "Cart", Vector3.new(3, 1.8, 2.4), CFrame.new(W(-12, 1.9, 2)), PAL.wood[2])
	for _, w in { { -13, 1 }, { -11, 1 }, { -13, 3 }, { -11, 3 } } do vox(props, "Wheel", Vector3.new(0.9, 0.9, 0.3), CFrame.new(W(w[1], 1.1, w[2] + (w[2] > 2 and 0.3 or -0.3))), PAL.stone[1]) end
	for k = 0, 4 do vox(props, "CartOre", Vector3.new(0.8, 0.8, 0.8), CFrame.new(W(-12.9 + k * 0.45, 3 + (k % 2) * 0.3, 1.6 + (k % 3) * 0.4)), ({ EMBER, GOLD, Color3.fromRGB(201, 184, 242) })[k % 3 + 1], { Material = k == 2 and Enum.Material.Neon or Enum.Material.SmoothPlastic }) end
	local function barrel(p)
		for y = 0, 2 do vox(props, "Barrel", Vector3.new(1.8, 0.9, 1.8), CFrame.new(p + Vector3.new(0, 0.45 + y * 0.9, 0)), y == 1 and PAL.wood[3] or PAL.wood[2]) end
		vox(props, "BarrelBand", Vector3.new(1.9, 0.2, 1.9), CFrame.new(p + Vector3.new(0, 1.35, 0)), PAL.stone[1])
	end
	for _, p in { W(-27, 0, -8), W(-29, 0, -6), W(-14, 0, -27), W(24, 0, -10), W(33, 0, 6) } do barrel(p) end
	for _, c in { { -30, 10 }, { 34, -10 }, { 13, -28 }, { -8, 27 } } do
		for k = 0, 2 do vox(props, "Crate", Vector3.new(2, 2, 2), CFrame.new(W(c[1] + (k % 2) * 2.1, 1 + math.floor(k / 2) * 2, c[2])) * CFrame.Angles(0, k * 0.2, 0), PAL.plank[2 + k % 2]) end
	end
	for _, c in { { -33, -2 }, { 35, 0 }, { -12, 32 }, { 26, 26 }, { -30, -20 }, { 32, -20 }, { -20, 30 } } do -- voxel bushes at the plaza edge
		for i = -1, 1 do for k = -1, 1 do
			if hash(c[1] + i, 3, c[2] + k) > 0.2 then
				vox(props, "Bush", Vector3.new(1.6, 1.6, 1.6), CFrame.new(W(c[1] + i * 1.5, 0.8 + (i == 0 and k == 0 and 1.2 or 0), c[2] + k * 1.5)), shadeOf("leaf", c[1] + i, 1, c[2] + k), { CanCollide = false })
			end
		end end
	end
	for i, c in { { -40, -26 }, { -44, 4 }, { 42, -24 }, { 44, 2 }, { -36, 22 }, { 38, 20 } } do -- glowing mushrooms at the root walls
		local tint = ({ PAL.pink[2], Color3.fromRGB(140, 227, 192), Color3.fromRGB(201, 184, 242) })[i % 3 + 1]
		for k = 0, 2 do
			local h = 1.2 + k * 0.6
			local p = W(c[1] + k * 1.3, 0, c[2] + (k % 2) * 1.1)
			vox(props, "MushStem", Vector3.new(0.5, h, 0.5), CFrame.new(p + Vector3.new(0, h / 2, 0)), PAL.cream[2], { CanCollide = false })
			local cap = vox(props, "MushCap", Vector3.new(h * 1.1, 0.6, h * 1.1), CFrame.new(p + Vector3.new(0, h + 0.2, 0)), tint, { CanCollide = false, Material = Enum.Material.Neon })
			if k == 2 then glow(cap, tint, 12, 0.8) end
		end
	end
	for k = 0, 3 do vox(props, "LogPile", Vector3.new(3.6, 0.8, 0.8), CFrame.new(W(16, 0.4 + math.floor(k / 2) * 0.8, 16 + (k % 2) * 0.85)), PAL.wood[(k % 2) + 1]) end
	for i = 0, 4 do -- stepping stones from the spawn to the plaza
		vox(props, "Step", Vector3.new(2.6, 0.4, 1.8), CFrame.new(W((i % 2) * 0.8 - 0.4, 0.5, 36 + i * 3.2)), PAL.plaza[2])
	end

	-- 14. Spawn point south of the shaft, facing it
	vox(model, "SpawnPoint", Vector3.new(1, 1, 1), CFrame.lookAt(W(0, 3.5, 18), W(0, 3.5, 0)), PAL.wood[1], { Transparency = 1, CanCollide = false, CanQuery = false })

	model.Parent = parent
	return model
end

return Hub
