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
	plaza = { Color3.fromRGB(108, 96, 128), Color3.fromRGB(120, 107, 140), Color3.fromRGB(134, 120, 152) },
	grass = { Color3.fromRGB(76, 132, 128), Color3.fromRGB(92, 150, 138), Color3.fromRGB(112, 168, 150) },
	rock = { Color3.fromRGB(54, 40, 76), Color3.fromRGB(70, 54, 96), Color3.fromRGB(90, 72, 120) },
	dirt = { Color3.fromRGB(46, 34, 54), Color3.fromRGB(70, 50, 68), Color3.fromRGB(96, 70, 82) },
	bark = { Color3.fromRGB(50, 30, 74), Color3.fromRGB(74, 44, 104), Color3.fromRGB(100, 62, 134) },
	leaf = { Color3.fromRGB(30, 88, 86), Color3.fromRGB(48, 124, 112), Color3.fromRGB(86, 170, 140) },
	roof = { Color3.fromRGB(58, 52, 82), Color3.fromRGB(84, 76, 112), Color3.fromRGB(112, 102, 142) },
	moss = { Color3.fromRGB(46, 104, 88), Color3.fromRGB(66, 136, 106), Color3.fromRGB(96, 168, 126) },
	pink = { Color3.fromRGB(196, 84, 116), Color3.fromRGB(232, 122, 150), Color3.fromRGB(250, 186, 200) },
	cream = { Color3.fromRGB(200, 184, 180), Color3.fromRGB(232, 220, 206), Color3.fromRGB(246, 238, 226) },
}
local LAMP, CYAN, GOLD, EMBER = Color3.fromRGB(232, 168, 96), Color3.fromRGB(96, 206, 226), Color3.fromRGB(255, 214, 92), Color3.fromRGB(240, 130, 64)

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

-- Sweeping roots: chunky blocks laid along each curve (rotated, octagonal), banded in three bark shades
local function rootSweep(g, tubes, mat)
	for ti, t in tubes do
		local p0, p1, p2, p3, r0, r1 = t[1], t[2], t[3], t[4], t[5], t[6]
		local n = math.max(6, math.ceil((p0 - p3).Magnitude / 3.2))
		local prev = p0
		for i = 1, n do
			local u = i / n
			local a = 1 - u
			local c = p0 * a ^ 3 + p1 * 3 * a ^ 2 * u + p2 * 3 * a * u ^ 2 + p3 * u ^ 3
			local r = r0 + (r1 - r0) * u
			local len = (c - prev).Magnitude
			if len > 0.05 then
				local cf = CFrame.lookAt((c + prev) / 2, c) * CFrame.Angles(0, 0, (ti * 0.7 + i * 0.13) % 0.8)
				local shade = PAL[mat][(i + ti) % 3 == 0 and 1 or ((i + ti) % 3 == 1 and 2 or 3)]
				vox(g, "Root", Vector3.new(r * 2, r * 2, len + r * 0.5), cf, shade)
				vox(g, "RootEdge", Vector3.new(r * 1.7, r * 1.7, len + r * 0.4), cf * CFrame.Angles(0, 0, math.pi / 4), PAL[mat][2], { CanCollide = false })
			end
			prev = c
		end
		if p3.Y < p0.Y - 4 then -- the root meets the ground: three short splays
			local dir = (p3 - p2) * Vector3.new(1, 0, 1)
			dir = dir.Magnitude > 0.1 and dir.Unit or Vector3.xAxis
			for k = -1, 1 do
				local d = (CFrame.Angles(0, k * 0.7, 0) * CFrame.new(dir * 1)).Position.Unit
				local a, b = p3 + Vector3.new(0, 0.6, 0), p3 + d * (r1 * 2.6) + Vector3.new(0, -0.4, 0)
				vox(g, "RootSplay", Vector3.new(r1 * 1.2, r1 * 0.9, (b - a).Magnitude), CFrame.lookAt((a + b) / 2, b), PAL[mat][1])
			end
		end
	end
end

-- Warm string lights hung between two points (a sagging rope of small cube bulbs)
local function stringLights(g, a, b, sag, n)
	for i = 0, n do
		local u = i / n
		local p = a:Lerp(b, u) - Vector3.new(0, math.sin(u * math.pi) * sag, 0)
		local bulb = vox(g, "Bulb", Vector3.new(0.6, 0.6, 0.6), CFrame.new(p), i % 3 == 0 and Color3.fromRGB(255, 157, 176) or LAMP, { CanCollide = false, Material = Enum.Material.Neon })
		if i % 4 == 2 then glow(bulb, LAMP, 12, 0.5) end
		if i < n then
			local q = a:Lerp(b, (i + 1) / n) - Vector3.new(0, math.sin((i + 1) / n * math.pi) * sag, 0)
			vox(g, "Wire", Vector3.new(0.12, 0.12, (q - p).Magnitude), CFrame.lookAt((p + q) / 2, q), PAL.wood[1], { CanCollide = false })
		end
	end
end

-- A chibi voxel villager (head about 45% of the height) with a bobbing "!" over the head
local function villager(name, cf, body, hat, skin)
	local m = Instance.new("Model")
	m.Name = name
	skin = skin or Color3.fromRGB(255, 214, 186)
	local function at(x, y, z) return cf * CFrame.new(x, y, z) end
	for _, x in { -0.45, 0.45 } do vox(m, "Leg", Vector3.new(0.7, 1, 0.8), at(x, 0.5, 0), PAL.wood[1]) end
	vox(m, "Body", Vector3.new(2, 1.8, 1.3), at(0, 1.9, 0), body)
	for _, x in { -1.25, 1.25 } do vox(m, "Arm", Vector3.new(0.55, 1.4, 0.6), at(x, 2, 0), body) end
	vox(m, "Head", Vector3.new(2.4, 2.3, 2.2), at(0, 4, 0), skin)
	for _, x in { -0.5, 0.5 } do
		vox(m, "Eye", Vector3.new(0.4, 0.45, 0.1), at(x, 4.05, 1.12), Color3.fromRGB(42, 28, 58), { CanCollide = false })
		vox(m, "Shine", Vector3.new(0.15, 0.15, 0.06), at(x + 0.08, 4.18, 1.17), Color3.new(1, 1, 1), { CanCollide = false })
	end
	vox(m, "Hat", Vector3.new(2.6, 0.6, 2.4), at(0, 5.4, 0), hat)
	vox(m, "HatTop", Vector3.new(1.6, 0.7, 1.5), at(0, 6, 0), hat)
	local bang = Instance.new("Model")
	bang.Name = "Quest"
	vox(bang, "Bar", Vector3.new(0.5, 1.2, 0.5), at(0, 8.1, 0), GOLD, { CanCollide = false, Material = Enum.Material.Neon })
	vox(bang, "Dot", Vector3.new(0.5, 0.5, 0.5), at(0, 7.1, 0), GOLD, { CanCollide = false, Material = Enum.Material.Neon })
	bang:SetAttribute("Bob", 0.3)
	bang.Parent = m
	m.Parent = model
	return m
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
		vox(ground, "Base", Vector3.new(b[3], 6, b[4]), CFrame.new(W(b[1], -3, b[2])), Color3.fromRGB(70, 58, 84))
	end
	local PR, T, S = 22, 4, 3.2
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

	for i = 0, 47 do
		local a = i / 48 * math.pi * 2
		local rr = PR + 1.5 + hash(i, 4, 4) * 3
		if hash(i, 6, 6) > 0.35 then
			vox(ground, "Stray", Vector3.new(1.6 + hash(i, 1, 1), 0.4, 1.4 + hash(i, 2, 2)), CFrame.new(W(math.cos(a) * rr, 0.62, math.sin(a) * rr * 1.15)) * CFrame.Angles(0, hash(i, 3, 3) * 3, 0), PAL.plaza[(i % 3) + 1])
		end
	end
	for i = 0, 22 do -- low brambles and stones along the south edge of the view
		local x = -44 + i * 4 + hash(i, 1, 9) * 2
		local z = 34 + hash(i, 2, 9) * 6
		local h = 1.2 + hash(i, 3, 9) * 1.6
		vox(ground, "Bramble", Vector3.new(3.2, h, 3), CFrame.new(W(x, h / 2 + 0.4, z)) * CFrame.Angles(0, hash(i, 4, 9), 0), PAL.leaf[(i % 3) + 1], { CanCollide = false })
		if i % 3 == 0 then
			vox(ground, "BrambleTop", Vector3.new(2, 1.2, 2), CFrame.new(W(x + 0.6, h + 0.9, z - 0.4)), PAL.leaf[3], { CanCollide = false })
		end
		if i % 4 == 1 then
			vox(ground, "Berry", Vector3.new(0.5, 0.5, 0.5), CFrame.new(W(x - 0.8, h + 0.6, z - 1.2)), Color3.fromRGB(232, 122, 150), { CanCollide = false })
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
	local pitFloor = vox(shaft, "PitFloor", Vector3.new(12, 1, 12), CFrame.new(W(0, -10.5, 0)), Color3.fromRGB(34, 70, 110))
	pitFloor:SetAttribute("Station", "enter")
	for i = 1, 7 do -- crystal shards glowing up out of the pit
		local a = i / 7 * math.pi * 2
		local c = vox(shaft, "PitCrystal", Vector3.new(0.9, 2 + (i % 3), 0.9), CFrame.new(W(math.cos(a) * 3.6, -8.5, math.sin(a) * 3.6)) * CFrame.Angles(math.sin(a) * 0.3, a, math.cos(a) * 0.3), i % 2 == 0 and CYAN or Color3.fromRGB(150, 140, 230), { CanCollide = false })
		if i == 3 then glow(c, CYAN, 18, 0.9) elseif i % 3 == 0 then c.Material = Enum.Material.Neon end
	end
	local sparks = Instance.new("ParticleEmitter")
	sparks.Rate, sparks.Lifetime, sparks.Speed = 4, NumberRange.new(2, 3.5), NumberRange.new(3, 6)
	sparks.Color, sparks.LightEmission, sparks.EmissionDirection = ColorSequence.new(CYAN), 1, Enum.NormalId.Top
	sparks.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0) })
	sparks.Parent = pitFloor
	local mist = Instance.new("ParticleEmitter")
	mist.Rate, mist.Lifetime, mist.Speed, mist.SpreadAngle = 3, NumberRange.new(3, 5), NumberRange.new(2, 3.5), Vector2.new(25, 25)
	mist.Color, mist.LightEmission, mist.EmissionDirection = ColorSequence.new(Color3.fromRGB(170, 160, 240), CYAN), 0.4, Enum.NormalId.Top
	mist.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 6) })
	mist.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.75), NumberSequenceKeypoint.new(1, 1) })
	mist.Parent = pitFloor
	-- headframe: two A-legs of voxel beams, a crossbeam, a cube-built pulley wheel, rope and a hanging crystal
	for _, s in { -1, 1 } do
		for _, z in { -6, 6 } do vox(shaft, "Leg", Vector3.new(2, 20, 2), CFrame.new(W(s * 7.5, 10, z)) * CFrame.Angles(z > 0 and 0.12 or -0.12, 0, 0), PAL.wood[2]) end
		vox(shaft, "Brace", Vector3.new(1.4, 1.4, 12), CFrame.new(W(s * 7.5, 7, 0)), PAL.wood[1])
		vox(shaft, "Brace", Vector3.new(1.2, 1.2, 12.5), CFrame.new(W(s * 7.5, 12, 0)) * CFrame.Angles(0.5, 0, 0), PAL.wood[1])
	end
	vox(shaft, "CrossBeam", Vector3.new(18, 2.2, 2.2), CFrame.new(W(0, 19.5, 0)), PAL.wood[3])
	local wheel = group("LiftWheel")
	for i = 0, 15 do
		local a = i / 16 * math.pi * 2
		vox(wheel, "Rim", Vector3.new(1.2, 1.2, 1.2), CFrame.new(W(0, 23 + math.sin(a) * 3.6, math.cos(a) * 3.6)), i % 2 == 0 and PAL.wood[2] or PAL.wood[3])
	end
	vox(wheel, "Hub", Vector3.new(1.8, 1.8, 1.8), CFrame.new(W(0, 23, 0)), PAL.stone[2])
	for i = 0, 3 do vox(wheel, "Spoke", Vector3.new(0.6, 7, 0.6), CFrame.new(W(0, 23, 0)) * CFrame.Angles(i * math.pi / 4, 0, 0), PAL.wood[1]) end
	wheel:SetAttribute("SpinX", 1.4)
	vox(shaft, "Rope", Vector3.new(0.25, 14, 0.25), CFrame.new(W(0, 13, 2.6)), PAL.cream[1], { CanCollide = false })
	for k, o in { { 0.7, 0.2, 1.1 }, { -0.6, -0.4, 0.9 }, { 0.1, -0.9, 0.8 } } do -- a cluster of smaller crystals round the big one
		vox(shaft, "HangingShard", Vector3.new(0.7, o[3] * 1.6, 0.7), CFrame.new(W(o[1], 5.4 + o[2], 2.6)) * CFrame.Angles(0.3 * k, 0.5, 0.2), k == 2 and Color3.fromRGB(170, 150, 240) or CYAN, { CanCollide = false, Material = Enum.Material.Neon })
	end
	local hang = vox(shaft, "HangingCrystal", Vector3.new(1.6, 1.6, 1.6), CFrame.new(W(0, 5.4, 2.6)) * CFrame.Angles(0.6, 0.6, 0), CYAN, { CanCollide = false })
	glow(hang, CYAN, 18, 1.2)
	hang:SetAttribute("Bob", 0.3)
	sign(shaft, "MINE", CFrame.new(W(0, 17.2, 6.9)), 5, 1.8, GOLD)
	prompt(vox(shaft, "EnterPlate", Vector3.new(4, 0.3, 2), CFrame.new(W(0, 1.55, 7)), PAL.wood[3], { CanCollide = false }), "Enter the mine", "Lift", "enter")

	-- a station frame at (dx, dz), turned so its front (+Z) faces the shaft
	local function station(dx, dz)
		dx, dz = dx * 0.72, dz * 0.72 -- graded rounds 2-4: cluster the stalls tight round the pit (the concept is an intimate alcove)
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
		vox(g, "Base", Vector3.new(10, 1.2, 10), at(0, 0.6, -2), PAL.stone[2])
		vox(g, "BaseTrim", Vector3.new(10.4, 0.4, 10.4), at(0, 1.3, -2), PAL.stone[3])
		for _, c in { { -4, -6 }, { 4, -6 }, { -4, 2 }, { 4, 2 } } do vox(g, "Frame", Vector3.new(0.7, 6.4, 0.7), at(c[1], 4.4, c[2]), PAL.wood[2]) end
		for _, z in { -6, 2 } do vox(g, "Beam", Vector3.new(8.7, 0.6, 0.6), at(0, 7.6, z), PAL.wood[2]) end
		vox(g, "Ridge", Vector3.new(9.4, 0.7, 0.7), at(0, 10, -2), PAL.wood[3])
		for _, s in { -1, 1 } do -- pitched glass roof with rafters, so the eggs show from above
			local cf = at(0, 8.8, -2 + s * 2.2) * CFrame.Angles(s * 0.5, 0, 0)
			vox(g, "RoofGlass", Vector3.new(8.8, 0.2, 5), cf, Color3.fromRGB(190, 200, 240), { Transparency = 0.72, CanCollide = false })
			for x = -4.2, 4.2, 2.8 do vox(g, "Rafter", Vector3.new(0.45, 0.45, 5.2), cf * CFrame.new(x, 0.2, 0), PAL.wood[1], { CanCollide = false }) end
		end
		vox(g, "HeatLamp", Vector3.new(1, 0.6, 1), at(0, 9.2, -2), Color3.fromRGB(220, 150, 130), { CanCollide = false })
		for _, z in { 2, -6 } do vox(g, "Glass", Vector3.new(7.3, 6, 0.2), at(0, 4.4, z), Color3.fromRGB(190, 230, 250), { Transparency = 0.75, CanCollide = false }) end
		for _, x in { -4, 4 } do vox(g, "Glass", Vector3.new(0.2, 6, 7.3), at(x, 4.4, -2), Color3.fromRGB(190, 230, 250), { Transparency = 0.75, CanCollide = false }) end
		for i, ec in { PAL.pink[2], PAL.cream[2], Color3.fromRGB(140, 227, 192) } do
			local e = group("Egg" .. i)
			local x, z = -2.6 + (i - 1) * 2.6, -2 + (i == 2 and -0.9 or 0.6)
			vox(e, "Low", Vector3.new(1.6, 1, 1.6), at(x, 1.8, z), ec)
			vox(e, "Mid", Vector3.new(1.8, 1.1, 1.8), at(x, 2.8, z), ec)
			vox(e, "Top", Vector3.new(1.2, 0.8, 1.2), at(x, 3.7, z), ec)
			for _, p in e:GetChildren() do p.Material = Enum.Material.SmoothPlastic end
			local sp = Instance.new("ParticleEmitter") -- sparkles round each egg
			sp.Rate, sp.Lifetime, sp.Speed, sp.SpreadAngle = 2, NumberRange.new(0.8, 1.4), NumberRange.new(0.5, 1.2), Vector2.new(180, 180)
			sp.Color, sp.LightEmission = ColorSequence.new(ec:Lerp(Color3.new(1, 1, 1), 0.4)), 1
			sp.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0.35), NumberSequenceKeypoint.new(1, 0) })
			sp.Parent = e:FindFirstChild("Mid")
			e:SetAttribute("Bob", 0.25 + i * 0.05)
			if i == 2 then glow(e:FindFirstChild("Mid"), Color3.fromRGB(255, 170, 200), 14, 0.8) e:FindFirstChild("Mid").Material = Enum.Material.SmoothPlastic end
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

	-- 9. Campfire: stone ring, a teepee of voxel logs, embers and dancing flame cubes; log benches round it
	do
		local g = group("Campfire")
		local c = W(6, 0, 12.5)
		for i = 0, 9 do
			local a = i / 10 * math.pi * 2
			vox(g, "Stone", Vector3.new(1.3, 0.9, 1.3), CFrame.new(c + Vector3.new(math.cos(a) * 2.3, 0.45, math.sin(a) * 2.3)), shadeOf("stone", i, 0, 3))
		end
		for i = 0, 3 do
			local a = i / 4 * math.pi * 2 + 0.4
			vox(g, "Log", Vector3.new(0.6, 3, 0.6), CFrame.new(c + Vector3.new(math.cos(a) * 0.7, 1.3, math.sin(a) * 0.7)) * CFrame.Angles(math.sin(a) * 0.45, 0, -math.cos(a) * 0.45), PAL.wood[(i % 2) + 1])
		end
		for i = 0, 5 do
			local a = i / 6 * math.pi * 2
			vox(g, "Ember", Vector3.new(0.35, 0.25, 0.35), CFrame.new(c + Vector3.new(math.cos(a) * 1.2, 0.3, math.sin(a) * 1.2)), EMBER, { CanCollide = false, Material = Enum.Material.Neon })
		end
		local flames = group("Flames")
		flames.Parent = g
		for i, f in { { 0, 1, 0, 1.1, EMBER }, { 0.25, 1.8, 0.15, 0.75, GOLD }, { -0.2, 2.4, -0.1, 0.45, Color3.fromRGB(255, 240, 190) } } do
			local p = vox(flames, "Flame", Vector3.new(f[4], f[4], f[4]), CFrame.new(c + Vector3.new(f[1], f[2], f[3])), f[5], { CanCollide = false, Material = Enum.Material.Neon })
			if i == 1 then glow(p, EMBER, 24, 1.6, true):SetAttribute("Flicker", 1) end
		end
		flames:SetAttribute("Flames", true)
		for _, s in { -1, 1 } do vox(g, "Bench", Vector3.new(1.2, 1, 4.2), CFrame.new(c + Vector3.new(s * 4.6, 0.5, 0)), PAL.wood[2]) end
		vox(g, "Bench", Vector3.new(4.2, 1, 1.2), CFrame.new(c + Vector3.new(0, 0.5, 4.4)), PAL.wood[3])
	end

	-- 10. Friends bench (south-east)
	vox(model, "FriendsBench", Vector3.new(5, 0.6, 1.6), CFrame.new(W(13, 1.4, 18)), PAL.plank[3])
	vox(model, "FriendsBenchBack", Vector3.new(5, 1.6, 0.5), CFrame.new(W(13, 2.4, 18.8)), PAL.plank[2])
	for _, s in { -1, 1 } do vox(model, "FriendsBenchLeg", Vector3.new(0.5, 1.1, 1.4), CFrame.new(W(13 + s * 2.1, 0.55, 18)), PAL.wood[1]) end
	sign(model, "FRIENDS", CFrame.new(W(13, 4.2, 19.1)), 3.8, 1, PAL.pink[3])

	-- 11. Lantern posts round the plaza
	local posts = group("LanternPosts")
	for i = 0, 9 do
		local a = i / 10 * math.pi * 2 + 0.3
		local p = W(math.cos(a) * 20, 0, math.sin(a) * 20 * 0.87)
		if not (math.abs(p.X - O.X) < 8 and p.Z - O.Z > 20) then -- keep the front open for the camera
			vox(posts, "Post", Vector3.new(0.8, 7, 0.8), CFrame.new(p + Vector3.new(0, 3.5, 0)), PAL.wood[1])
			vox(posts, "Arm", Vector3.new(2.2, 0.5, 0.5), CFrame.new(p + Vector3.new(0.9, 7, 0)), PAL.wood[1])
			cubeLantern(posts, p + Vector3.new(1.8, 5.6, 0), 0.6)
		end
	end

	-- 12. The World Tree: a huge trunk behind the camp (north) and voxel roots that wall the plaza and arch overhead
	local tree = group("WorldTree")
	local trunk = W(0, 0, -74)
	local tubes = {}
	for _, s in { -1, 1 } do
		local function T(p0, p1, p2, p3, r0, r1)
			local k = 0.86 -- pull the root walls in round the smaller plaza
			table.insert(tubes, { W(p0[1] * s * k, p0[2], p0[3] * k), W(p1[1] * s * k, p1[2], p1[3] * k), W(p2[1] * s * k, p2[2], p2[3] * k), W(p3[1] * s * k, p3[2], p3[3] * k), r0, r1 })
		end
		T({ 8, 24, -62 }, { 34, 30, -50 }, { 46, 14, -16 }, { 38, -1, 18 }, 7, 3.6) -- the big wall roots, west and east
		T({ 6, 12, -60 }, { 26, 12, -44 }, { 36, 6, -30 }, { 30, -1, -20 }, 5.6, 3)
		T({ 46, 10, -18 }, { 54, 8, 4 }, { 48, 5, 24 }, { 32, -1, 34 }, 3.4, 1.8) -- curling round the south-west and south-east corners
		T({ 10, 40, -60 }, { 22, 46, -34 }, { 30, 38, -16 }, { 40, 12, -4 }, 3.6, 2) -- arches over the back half of the plaza
		T({ 0, 44, -58 }, { 8, 50, -30 }, { 20, 40, -8 }, { 34, 20, 6 }, 2.8, 1.6)
	end
	table.insert(tubes, { W(-30, 38, -20), W(-12, 52, -26), W(12, 52, -26), W(30, 38, -20), 2.8, 2.8 }) -- the crown arch across the north
	table.insert(tubes, { W(0, -2, -64), W(0, 30, -64), W(0, 70, -64), W(0, 110, -66), 13, 9 }) -- the trunk
	rootSweep(tree, tubes, "bark")
	for _, c in { W(-22, 52, -36), W(22, 52, -36), W(0, 108, -66), W(-16, 104, -62), W(16, 100, -68), W(-38, 40, -14), W(38, 40, -14), W(0, 56, -28) } do
		leafClump(tree, c, 3, 2.8)
	end
	stringLights(tree, W(-36, 26, -10), W(36, 26, -10), 6, 20)
	stringLights(tree, W(-30, 20, 10), W(-8, 34, -20), 4, 9)
	stringLights(tree, W(30, 20, 10), W(8, 34, -20), 4, 9)
	for i, p in { W(-34, 14, -2), W(34, 14, -2), W(-20, 30, -28), W(20, 30, -28), W(-40, 8, 20), W(40, 8, 20) } do -- lanterns hanging from the roots
		cubeLantern(tree, p, 2 + (i % 3) * 2)
	end
	local flies = Instance.new("ParticleEmitter") -- fireflies drifting round the canopy
	flies.Rate, flies.Lifetime, flies.Speed, flies.SpreadAngle = 6, NumberRange.new(4, 7), NumberRange.new(0.5, 1.5), Vector2.new(180, 180)
	flies.Color, flies.LightEmission = ColorSequence.new(Color3.fromRGB(198, 247, 226), GOLD), 1
	flies.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.2, 0.35), NumberSequenceKeypoint.new(1, 0) })
	local flyBox = vox(tree, "Fireflies", Vector3.new(90, 30, 70), CFrame.new(W(0, 26, -16)), Color3.new(), { Transparency = 1, CanCollide = false, CanQuery = false })
	flies.Shape, flies.Parent = Enum.ParticleEmitterShape.Box, flyBox

	-- 12b. The Hollow Mountain: a stepped voxel rock wall round the camp, lower toward the south where the camera looks in
	local hollow = group("HollowWall")
	for i = 0, 63 do
		local a = i / 64 * math.pi * 2
		local south = math.cos(a - math.pi / 2) -- 1 = due south (+z), the camera side
		if south < 0.55 then
			local rr = 44 + hash(i, 1, 2) * 5
			local p = W(math.cos(a) * rr, 0, math.sin(a) * rr)
			local h = (34 + hash(i, 3, 4) * 14) * (1 - math.max(south, 0) * 1.1)
			local look = CFrame.lookAt(p, W(0, 0, 0))
			local y = 0
			for band = 1, 3 do
				local bh = h / 3 + (band == 3 and hash(i, band, 9) * 4 or 0)
				vox(hollow, "Rock", Vector3.new(5.6, bh, 6 + band * 1.5), look * CFrame.new(0, y + bh / 2, -band * 0.6 + 1), PAL.rock[((i + band) % 3) + 1])
				y += bh
			end
			if hash(i, 7, 7) > 0.6 then -- a mossy ledge or a glowing crystal on the wall face
				local ledge = vox(hollow, "Ledge", Vector3.new(4, 1, 2), look * CFrame.new(0, h * (0.3 + hash(i, 8, 8) * 0.4), -3.6), PAL.grass[2])
				if hash(i, 9, 9) > 0.6 then
					local tint = hash(i, 5, 5) > 0.5 and Color3.fromRGB(120, 210, 220) or Color3.fromRGB(190, 160, 240)
					local cr = vox(hollow, "WallCrystal", Vector3.new(0.8, 2.6, 0.8), ledge.CFrame * CFrame.new(0, 1.6, 0) * CFrame.Angles(0.2, 0, 0.3), tint, { CanCollide = false, Material = Enum.Material.Neon })
					if i % 3 == 0 then glow(cr, tint, 14, 0.6) end
				end
			end
		end
	end
	vox(hollow, "FarGround", Vector3.new(320, 6, 320), CFrame.new(W(0, -14, 0)), PAL.rock[1], { CanCollide = false }) -- under the pit floor, so the shaft stays open

	-- 13. Props that make the camp feel lived in: an ore cart on rails, barrels, crate stacks, bushes, glowing mushrooms, a log pile
	local props = group("Props")
	for i = 0, 3 do -- rails from the shaft rim toward the sell stall
		local x = -9 - i * 1.6
		vox(props, "Sleeper", Vector3.new(0.6, 0.25, 2.6), CFrame.new(W(x, 0.55, 2)), PAL.wood[1])
	end
	for _, z in { 1.1, 2.9 } do vox(props, "Rail", Vector3.new(7, 0.25, 0.3), CFrame.new(W(-11.4, 0.8, z)), PAL.stone[1]) end
	vox(props, "Cart", Vector3.new(3, 1.8, 2.4), CFrame.new(W(-12, 1.9, 2)), PAL.wood[2])
	for _, w in { { -13, 1 }, { -11, 1 }, { -13, 3 }, { -11, 3 } } do vox(props, "Wheel", Vector3.new(0.9, 0.9, 0.3), CFrame.new(W(w[1], 1.1, w[2] + (w[2] > 2 and 0.3 or -0.3))), PAL.stone[1]) end
	for k = 0, 4 do vox(props, "CartOre", Vector3.new(0.8, 0.8, 0.8), CFrame.new(W(-12.9 + k * 0.45, 3 + (k % 2) * 0.3, 1.6 + (k % 3) * 0.4)), ({ EMBER, GOLD, Color3.fromRGB(201, 184, 242) })[k % 3 + 1], { Material = k == 2 and Enum.Material.Neon or Enum.Material.SmoothPlastic }) end
	local function barrel(p)
		for y = 0, 2 do vox(props, "Barrel", Vector3.new(1.8, 0.9, 1.8), CFrame.new(p + Vector3.new(0, 0.45 + y * 0.9, 0)), y == 1 and PAL.wood[3] or PAL.wood[2]) end
		vox(props, "BarrelBand", Vector3.new(1.9, 0.2, 1.9), CFrame.new(p + Vector3.new(0, 1.35, 0)), PAL.stone[1])
	end
	for _, p in { W(-20, 0, -6), W(-21.6, 0, -4.6), W(-10, 0, -20), W(17, 0, -7), W(24, 0, 4) } do barrel(p) end
	for _, c in { { -21, 8 }, { 24, -7 }, { 9, -21 }, { -6, 20 } } do
		for k = 0, 2 do vox(props, "Crate", Vector3.new(2, 2, 2), CFrame.new(W(c[1] + (k % 2) * 2.1, 1 + math.floor(k / 2) * 2, c[2])) * CFrame.Angles(0, k * 0.2, 0), PAL.plank[2 + k % 2]) end
	end
	for _, c in { { -24, -2 }, { 25, 0 }, { -9, 23 }, { 19, 19 }, { -22, -16 }, { 23, -16 }, { -16, 21 } } do -- voxel bushes at the plaza edge
		for i = -1, 1 do for k = -1, 1 do
			if hash(c[1] + i, 3, c[2] + k) > 0.2 then
				vox(props, "Bush", Vector3.new(1.6, 1.6, 1.6), CFrame.new(W(c[1] + i * 1.5, 0.8 + (i == 0 and k == 0 and 1.2 or 0), c[2] + k * 1.5)), shadeOf("leaf", c[1] + i, 1, c[2] + k), { CanCollide = false })
			end
		end end
	end
	for i, c in { { -28, -19 }, { -33, 4 }, { 29, -17 }, { 33, 2 }, { -28, 17 }, { 28, 16 } } do -- glowing mushrooms at the root walls
		local tint = ({ Color3.fromRGB(196, 96, 128), Color3.fromRGB(80, 168, 136), Color3.fromRGB(140, 120, 200) })[i % 3 + 1] -- darker tints: neon blooms them
		for k = 0, 2 do
			local h = 1.2 + k * 0.6
			local p = W(c[1] + k * 1.3, 0, c[2] + (k % 2) * 1.1)
			vox(props, "MushStem", Vector3.new(0.5, h, 0.5), CFrame.new(p + Vector3.new(0, h / 2, 0)), PAL.cream[2], { CanCollide = false })
			local cap = vox(props, "MushCap", Vector3.new(h * 1.1, 0.6, h * 1.1), CFrame.new(p + Vector3.new(0, h + 0.2, 0)), tint, { CanCollide = false })
			if k == 2 then glow(cap, tint, 12, 0.8) end
		end
	end
	for k = 0, 3 do vox(props, "LogPile", Vector3.new(3.6, 0.8, 0.8), CFrame.new(W(12, 0.4 + math.floor(k / 2) * 0.8, 8 + (k % 2) * 0.85)), PAL.wood[(k % 2) + 1]) end
	for i = 0, 4 do -- stepping stones from the spawn to the plaza
		vox(props, "Step", Vector3.new(2.6, 0.4, 1.8), CFrame.new(W((i % 2) * 0.8 - 0.4, 0.5, 28 + i * 3.2)), PAL.plaza[2])
	end

	-- 14. Villagers who run the stations, each with a bobbing "!"
	for _, v in { { "Bolt", "Forge", Vector3.new(-2.2, 0, 6.6), Color3.fromRGB(110, 120, 170), Color3.fromRGB(96, 70, 60) },
		{ "Pip", "SellStall", Vector3.new(2.6, 0, -1.6), PAL.pink[2], PAL.cream[2] },
		{ "Maribel", "Incubator", Vector3.new(5.6, 0, 2.4), Color3.fromRGB(140, 227, 192), Color3.fromRGB(201, 184, 242) } } do
		local st = model:FindFirstChild(v[2])
		local anchorPart = st and st:FindFirstChildWhichIsA("BasePart")
		if anchorPart then
			local base = st:GetBoundingBox()
			local look = (Vector3.new(O.X, 0, O.Z) - Vector3.new(base.Position.X, 0, base.Position.Z)).Unit
			local pos = Vector3.new(base.Position.X, O.Y, base.Position.Z) + look * v[3].Z + look:Cross(Vector3.yAxis) * v[3].X
			villager(v[1], CFrame.lookAt(pos, pos + look), v[4], v[5])
		end
	end

	for i, v in { { "Juniper", Vector3.new(6 - 6.2, 0, 12.5), PAL.pink[2], Color3.fromRGB(96, 150, 132) }, { "Tock", Vector3.new(6 + 6.2, 0, 12.5), Color3.fromRGB(142, 200, 255), PAL.roof[2] } } do
		local pos = W(v[2].X, 0.5, v[2].Z)
		local fire = W(6, 0.5, 12.5)
		local m = villager(v[1], CFrame.lookAt(pos, Vector3.new(fire.X, pos.Y, fire.Z)), v[3], v[4])
		local q = m:FindFirstChild("Quest")
		if q then q:Destroy() end
		local hand = CFrame.lookAt(pos, Vector3.new(fire.X, pos.Y, fire.Z)) * CFrame.new(0.9, 2.4, -1.4)
		vox(m, "Stick", Vector3.new(0.18, 0.18, 2.6), hand * CFrame.Angles(-0.35, 0, 0), PAL.wood[3], { CanCollide = false })
		local mm = vox(m, "Marshmallow", Vector3.new(0.55, 0.55, 0.55), hand * CFrame.Angles(-0.35, 0, 0) * CFrame.new(0, 0, -1.4), PAL.cream[3], { CanCollide = false })
		local puff = Instance.new("ParticleEmitter") -- a toasty puff now and then
		puff.Rate, puff.Lifetime, puff.Speed, puff.EmissionDirection = 1.2, NumberRange.new(1, 1.6), NumberRange.new(1, 2), Enum.NormalId.Top
		puff.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1.1) })
		puff.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 1) })
		puff.Color = ColorSequence.new(Color3.fromRGB(230, 220, 240))
		puff.Parent = mm
		m:SetAttribute("Bob", 0.06 + i * 0.02)
	end

	-- 15. Spawn point south of the shaft, facing it
	vox(model, "SpawnPoint", Vector3.new(1, 1, 1), CFrame.lookAt(W(0, 3.5, 14), W(0, 3.5, 0)), PAL.wood[1], { Transparency = 1, CanCollide = false, CanQuery = false })

	model.Parent = parent
	return model
end

return Hub
