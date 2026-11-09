-- ServerScriptService.HubBuilder: the shared Surface Camp hub (v4, 2026-11-08), built from voxel parts (Miro "3D Design" board,
-- Pixel Depths v1.5: "Hollow Mountain inside the World Tree roots"; hub concepts art/hub/pd_hub_vox_s41.png and pd_hub_s21.png).
-- v4: the camp is four times the area of v3 (twice as wide each way) so every store has room, and the backdrop (roots, trunk,
-- rock hollow) is twice the size. Stores wear tiling 32 px pixel textures (art/pd_hub_tex.py, ids art/roblox_tex/hub/asset_ids.json)
-- built toward per-store references (art/hub/refs/README.md: found images + local FLUX references art/hub/pdv4_*.jpg).
-- Seen from the bird's-eye camera south of the player looking north.
-- Hub.build(parent, origin) returns the Model; station parts carry attributes the server hooks up:
-- Station = "sell" | "forge" | "hatch" | "map" | "chest" | "enter" (each has a ProximityPrompt), and "SpawnPoint" / "SellPoint".
local Hub = {}

-- three shades per material: dark (cool), mid, light (warm)
local PAL = {
	wood = { Color3.fromRGB(92, 58, 62), Color3.fromRGB(138, 92, 74), Color3.fromRGB(178, 128, 92) },
	plank = { Color3.fromRGB(110, 72, 64), Color3.fromRGB(156, 108, 82), Color3.fromRGB(196, 148, 106) },
	stone = { Color3.fromRGB(78, 74, 104), Color3.fromRGB(108, 104, 138), Color3.fromRGB(140, 136, 170) },
	grass = { Color3.fromRGB(76, 132, 128), Color3.fromRGB(92, 150, 138), Color3.fromRGB(112, 168, 150) },
	rock = { Color3.fromRGB(54, 40, 76), Color3.fromRGB(70, 54, 96), Color3.fromRGB(90, 72, 120) },
	bark = { Color3.fromRGB(50, 30, 74), Color3.fromRGB(74, 44, 104), Color3.fromRGB(100, 62, 134) },
	leaf = { Color3.fromRGB(30, 88, 86), Color3.fromRGB(48, 124, 112), Color3.fromRGB(86, 170, 140) },
	moss = { Color3.fromRGB(46, 104, 88), Color3.fromRGB(66, 136, 106), Color3.fromRGB(96, 168, 126) },
	pink = { Color3.fromRGB(196, 84, 116), Color3.fromRGB(232, 122, 150), Color3.fromRGB(250, 186, 200) },
	cream = { Color3.fromRGB(200, 184, 180), Color3.fromRGB(232, 220, 206), Color3.fromRGB(246, 238, 226) },
	lilac = { Color3.fromRGB(108, 90, 168), Color3.fromRGB(154, 134, 214), Color3.fromRGB(201, 184, 242) },
	straw = { Color3.fromRGB(196, 150, 86), Color3.fromRGB(226, 186, 110), Color3.fromRGB(246, 214, 140) },
}
local WHITE_ = Color3.fromRGB(255, 255, 255)
local LAMP, CYAN, GOLD, EMBER = Color3.fromRGB(232, 168, 96), Color3.fromRGB(96, 206, 226), Color3.fromRGB(255, 214, 92), Color3.fromRGB(240, 130, 64)
local INK = Color3.fromRGB(42, 28, 58)
local ORE = { EMBER, Color3.fromRGB(201, 184, 242), GOLD, Color3.fromRGB(140, 227, 192) }

-- pixel textures (one 32 px tile = 4 studs unless a call says otherwise) and the average colour of each, used as the part colour
local TEX = {
	planks = 136733596332196, planks_light = 72771835460014, logs = 95402050034854, stonebrick = 98964967285250,
	cobble = 115790715717963, shingle_teal = 123617774947178, shingle_plum = 97900496468174, moss_roof = 105534931797006,
	awning = 114815078373584, plaster = 90929537651821, beam = 113295401166112, bark = 95671523543687,
	rockface = 76858268703683, leaves = 87594727710313, path = 114352826559819, iron = 134383025955872,
	glass = 127998839149211, grass = 133229924509191, wood_frame = 98417694570042, flagstone = 113808643905036, cobble_soft = 124222168049970, cobble_lane = 138112363793278,
}
local AVG = {
	planks = Color3.fromRGB(167, 123, 103), planks_light = Color3.fromRGB(174, 130, 108), logs = Color3.fromRGB(131, 93, 83),
	stonebrick = Color3.fromRGB(137, 129, 174), cobble = Color3.fromRGB(117, 107, 146), shingle_teal = Color3.fromRGB(77, 143, 150),
	shingle_plum = Color3.fromRGB(102, 79, 144), moss_roof = Color3.fromRGB(93, 177, 146), awning = Color3.fromRGB(236, 178, 186),
	plaster = Color3.fromRGB(238, 227, 217), beam = Color3.fromRGB(93, 61, 71), bark = Color3.fromRGB(73, 47, 106),
	rockface = Color3.fromRGB(81, 63, 106), leaves = Color3.fromRGB(43, 108, 99), path = Color3.fromRGB(166, 140, 137),
	iron = Color3.fromRGB(85, 77, 120), glass = Color3.fromRGB(196, 220, 237), grass = Color3.fromRGB(118, 196, 162),
	wood_frame = Color3.fromRGB(201, 155, 126), flagstone = Color3.fromRGB(163, 140, 139), cobble_soft = Color3.fromRGB(140, 131, 173), cobble_lane = Color3.fromRGB(122, 116, 153),
}
local N = Enum.NormalId
local SIDES = { N.Top, N.Front, N.Back, N.Left, N.Right }

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
-- put a tiling pixel texture on the given faces (default: every face but the bottom)
local function skin(p, tex, studs, faces, tint)
	p.Color = AVG[tex]
	for _, f in faces or SIDES do
		local t = Instance.new("Texture")
		t.Name = tex
		t.Texture = "rbxassetid://" .. TEX[tex]
		t.Face, t.StudsPerTileU, t.StudsPerTileV = f, studs or 4, studs or 4
		if tint then t.Color3 = tint end
		t.Parent = p
	end
	return p
end
local function tvox(parent, name, size, cf, tex, studs, props, faces)
	return skin(vox(parent, name, size, cf, AVG[tex], props), tex, studs, faces)
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

-- Stepped voxel roof over a w x d footprint (overhang included), ridge along x, rising from y0: each step is `step` high and `run` in
local function stepRoof(g, at, w, d, y0, tex, step, run)
	step = step or 1
	run = run or step
	local n = math.floor(d / 2 / run)
	for i = 0, n - 1 do
		tvox(g, "Roof", Vector3.new(w, step, d - i * 2 * run), at(0, y0 + (i + 0.5) * step, 0), tex, 4)
	end
	tvox(g, "Ridge", Vector3.new(w + 0.6, 0.8, 1.4), at(0, y0 + n * step + 0.3, 0), "beam", 4)
	return y0 + n * step
end
-- Stepped gable ends under a stepRoof: bars on the two side walls (x = +-x), each shorter than the one below
local function gables(g, at, x, d, y0, tex, step)
	step = step or 1
	for _, s in { -1, 1 } do
		for i = 0, math.floor(d / 2 / step) - 1 do
			tvox(g, "Gable", Vector3.new(0.9, step - 0.04, d - i * 2 * step - 0.04), at(s * x, y0 + (i + 0.5) * step, 0), tex, 4) -- 0.02 inside the roof step faces (playtest 2 z-fighting)
		end
	end
end

local function sign(g, text, cf, w, h, fg, plain)
	-- playtest 2 (board 6): readable from the bird's-eye camera: 1.4x bigger, a cream plate (or the given colour), ink Fredoka
	-- letters, a thick plum rim, a trim strip in the sign's colour, the camera-side face tilted up 45 degrees toward the steep camera (vertical
	-- signs read as slivers from above); the face is lit by its own SurfaceGui background, so it stays cream at night
	w, h = w * 1.4, h * 1.4
	cf = cf * CFrame.Angles(math.rad(cf.LookVector.Z > 0 and 45 or -45), 0, 0) -- the face the camera sees (it sits south: C.CAM_YAW 0, pitch 52) tilts up toward it
	local board = vox(g, "Sign", Vector3.new(w, h, 0.4), cf, plain or PAL.cream[2], { CanCollide = false })
	vox(g, "SignFrame", Vector3.new(w + 0.8, h + 0.8, 0.3), cf, INK, { CanCollide = false })
	if fg then vox(g, "SignTrim", Vector3.new(w, 0.3, 0.46), cf * CFrame.new(0, -h / 2 + 0.25, 0), fg, { CanCollide = false }) end
	for _, face in { N.Back, N.Front } do
		local sg = Instance.new("SurfaceGui")
		sg.Face, sg.SizingMode, sg.PixelsPerStud, sg.LightInfluence = face, Enum.SurfaceGuiSizingMode.PixelsPerStud, 40, 0
		local t = Instance.new("TextLabel")
		t.Name = "Label"
		t.Size, t.BackgroundTransparency, t.Text, t.TextScaled = UDim2.fromScale(1, 1), 1, text, true
		t.Font, t.TextColor3, t.TextStrokeTransparency = Enum.Font.FredokaOne, INK, 1
		t.BackgroundTransparency, t.BackgroundColor3 = 0, plain or Color3.fromRGB(255, 247, 236)
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
	pr.Style = Enum.ProximityPromptStyle.Custom -- drawn by PixelClient (keycap + tooltip bubble)
	pr.Parent = p
	p:SetAttribute("Station", station)
	return pr
end

local function cubeLantern(g, pos, hang, s)
	s = s or 1
	if hang then vox(g, "Chain", Vector3.new(0.2, hang, 0.2), pos + Vector3.new(0, 1.1 * s + hang / 2, 0), PAL.stone[1], { CanCollide = false }) end
	tvox(g, "LanternCap", Vector3.new(1.6, 0.4, 1.6) * s, pos + Vector3.new(0, 0.95 * s, 0), "iron", 2, { CanCollide = false })
	tvox(g, "LanternBase", Vector3.new(1.6, 0.4, 1.6) * s, pos - Vector3.new(0, 0.95 * s, 0), "iron", 2, { CanCollide = false })
	for _, o in { { -1, -1 }, { -1, 1 }, { 1, -1 }, { 1, 1 } } do
		vox(g, "LanternBar", Vector3.new(0.2, 1.5, 0.2) * s, pos + Vector3.new(o[1] * 0.62, 0, o[2] * 0.62) * s, INK, { CanCollide = false })
	end
	local core = vox(g, "Lantern", Vector3.new(1.1, 1.5, 1.1) * s, pos, LAMP, { CanCollide = false })
	glow(core, LAMP, 16 * s, 0.7)
	core:SetAttribute("Sway", 0.08)
	return core
end

-- Sweeping roots: chunky blocks laid along each curve (rotated, octagonal), wearing the bark texture
local function rootSweep(g, tubes, step)
	for ti, t in tubes do
		local p0, p1, p2, p3, r0, r1 = t[1], t[2], t[3], t[4], t[5], t[6]
		local n = math.max(6, math.ceil((p0 - p3).Magnitude / step))
		local prev = p0
		for i = 1, n do
			local u = i / n
			local a = 1 - u
			local c = p0 * a ^ 3 + p1 * 3 * a ^ 2 * u + p2 * 3 * a * u ^ 2 + p3 * u ^ 3
			local r = r0 + (r1 - r0) * u
			local len = (c - prev).Magnitude
			if len > 0.05 then
				local cf = CFrame.lookAt((c + prev) / 2, c) * CFrame.Angles(0, 0, (ti * 0.7 + i * 0.13) % 0.8)
				local tint = PAL.bark[(i + ti) % 3 + 1]:Lerp(Color3.new(1, 1, 1), 0.55)
				skin(vox(g, "Root", Vector3.new(r * 2, r * 2, len + r * 0.5), cf, AVG.bark), "bark", 8, { N.Top, N.Bottom, N.Left, N.Right }, tint)
				vox(g, "RootEdge", Vector3.new(r * 1.7, r * 1.7, len + r * 0.4), cf * CFrame.Angles(0, 0, math.pi / 4), PAL.bark[2], { CanCollide = false })
			end
			prev = c
		end
		if p3.Y < p0.Y - 4 then -- the root meets the ground: three short splays
			local dir = (p3 - p2) * Vector3.new(1, 0, 1)
			dir = dir.Magnitude > 0.1 and dir.Unit or Vector3.xAxis
			for k = -1, 1 do
				local d = (CFrame.Angles(0, k * 0.7, 0) * CFrame.new(dir * 1)).Position.Unit
				local a, b = p3 + Vector3.new(0, 0.6, 0), p3 + d * (r1 * 2.6) + Vector3.new(0, -0.4, 0)
				skin(vox(g, "RootSplay", Vector3.new(r1 * 1.2, r1 * 0.9, (b - a).Magnitude), CFrame.lookAt((a + b) / 2, b), AVG.bark), "bark", 8, { N.Top, N.Left, N.Right })
			end
		end
	end
end

-- Warm string lights hung between two points (a sagging rope of small cube bulbs)
local function stringLights(g, a, b, sag, n)
	for i = 0, n do
		local u = i / n
		local p = a:Lerp(b, u) - Vector3.new(0, math.sin(u * math.pi) * sag, 0)
		local bulb = vox(g, "Bulb", Vector3.new(0.8, 0.8, 0.8), CFrame.new(p), i % 3 == 0 and Color3.fromRGB(255, 157, 176) or LAMP, { CanCollide = false, Material = Enum.Material.Neon })
		if i % 4 == 2 then glow(bulb, LAMP, 14, 0.5) end
		if i < n then
			local q = a:Lerp(b, (i + 1) / n) - Vector3.new(0, math.sin((i + 1) / n * math.pi) * sag, 0)
			vox(g, "Wire", Vector3.new(0.15, 0.15, (q - p).Magnitude), CFrame.lookAt((p + q) / 2, q), PAL.wood[1], { CanCollide = false })
		end
	end
end

-- A chibi voxel villager (head about 45% of the height) facing +Z of cf, with a bobbing "!" over the head
local function villager(name, cf, body, hat, skin_)
	local m = Instance.new("Model")
	m.Name = name
	skin_ = skin_ or Color3.fromRGB(255, 214, 186)
	local function at(x, y, z) return cf * CFrame.new(x, y, z) end
	for _, x in { -0.45, 0.45 } do vox(m, "Leg", Vector3.new(0.7, 1, 0.8), at(x, 0.5, 0), PAL.wood[1]) end
	vox(m, "Body", Vector3.new(2, 1.8, 1.3), at(0, 1.9, 0), body)
	vox(m, "Apron", Vector3.new(1.4, 1.3, 0.1), at(0, 1.7, 0.7), body:Lerp(Color3.new(1, 1, 1), 0.45))
	for _, x in { -1.25, 1.25 } do vox(m, "Arm", Vector3.new(0.55, 1.4, 0.6), at(x, 2, 0), body) end
	vox(m, "Head", Vector3.new(2.4, 2.3, 2.2), at(0, 4, 0), skin_)
	for _, x in { -0.5, 0.5 } do
		vox(m, "Eye", Vector3.new(0.4, 0.45, 0.1), at(x, 4.05, 1.12), INK, { CanCollide = false })
		vox(m, "Shine", Vector3.new(0.15, 0.15, 0.06), at(x + 0.08, 4.18, 1.17), Color3.new(1, 1, 1), { CanCollide = false })
		vox(m, "Blush", Vector3.new(0.4, 0.2, 0.06), at(x * 1.7, 3.6, 1.12), PAL.pink[3], { CanCollide = false })
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

-- Bolt the raccoon, the town smith (the user's pick, 2026-11-08): grey fur, a dark mask with bright eyes, a white muzzle, round
-- ears, a ringed tail, a butter apron and a pink headband; faces +Z like the villagers
local function raccoon(name, cf)
	local m = Instance.new("Model")
	m.Name = name
	local FUR, FUR_D, FUR_L, MASK = Color3.fromRGB(150, 146, 168), Color3.fromRGB(96, 90, 116), Color3.fromRGB(196, 192, 210), Color3.fromRGB(64, 56, 82)
	local function at(x, y, z) return cf * CFrame.new(x, y, z) end
	for _, x in { -0.45, 0.45 } do vox(m, "Leg", Vector3.new(0.7, 1, 0.8), at(x, 0.5, 0), FUR_D) end
	vox(m, "Body", Vector3.new(2, 1.8, 1.3), at(0, 1.9, 0), FUR)
	vox(m, "Apron", Vector3.new(1.4, 1.4, 0.1), at(0, 1.75, 0.7), Color3.fromRGB(255, 217, 112))
	for _, x in { -1.25, 1.25 } do vox(m, "Arm", Vector3.new(0.55, 1.4, 0.6), at(x, 2, 0), FUR) end
	vox(m, "Head", Vector3.new(2.4, 2.1, 2.2), at(0, 3.95, 0), FUR_L)
	vox(m, "Mask", Vector3.new(2.42, 0.62, 0.1), at(0, 4.1, 1.12), MASK, { CanCollide = false })
	for _, x in { -0.5, 0.5 } do
		vox(m, "Eye", Vector3.new(0.36, 0.4, 0.08), at(x, 4.1, 1.18), Color3.new(1, 1, 1), { CanCollide = false })
		vox(m, "Pupil", Vector3.new(0.2, 0.26, 0.06), at(x, 4.08, 1.23), INK, { CanCollide = false })
		vox(m, "Ear", Vector3.new(0.7, 0.7, 0.5), at(x * 1.7, 5.25, 0), FUR_D)
		vox(m, "EarIn", Vector3.new(0.4, 0.4, 0.06), at(x * 1.7, 5.2, 0.27), PAL.pink[3], { CanCollide = false })
	end
	vox(m, "Muzzle", Vector3.new(1.1, 0.6, 0.4), at(0, 3.45, 1.25), Color3.fromRGB(250, 246, 240))
	vox(m, "Nose", Vector3.new(0.46, 0.26, 0.24), at(0, 3.78, 1.42), INK, { CanCollide = false }) -- on the muzzle's top edge (lower read as a mouth)
	vox(m, "Band", Vector3.new(2.46, 0.4, 2.26), at(0, 4.73, 0), PAL.pink[2])
	for k = 1, 4 do -- the ringed tail curls up behind
		vox(m, "Tail", Vector3.new(0.8, 0.8, 0.8), at(0, 0.9 + k * 0.45, -0.85 - k * 0.42) * CFrame.Angles(-0.3 * k, 0, 0), k % 2 == 0 and MASK or FUR_L, { CanCollide = false })
	end
	local bang = Instance.new("Model")
	bang.Name = "Quest"
	vox(bang, "Bar", Vector3.new(0.5, 1.2, 0.5), at(0, 7.6, 0), GOLD, { CanCollide = false, Material = Enum.Material.Neon })
	vox(bang, "Dot", Vector3.new(0.5, 0.5, 0.5), at(0, 6.6, 0), GOLD, { CanCollide = false, Material = Enum.Material.Neon })
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

-- crates of glowing ore (the stall's goods and the props round the camp)
local function oreCrate(g, cf, ore, w)
	w = w or 2.6
	tvox(g, "Crate", Vector3.new(w, 1.6, w * 0.8), cf * CFrame.new(0, 0.8, 0), "wood_frame", 2)
	vox(g, "CrateRim", Vector3.new(w + 0.2, 0.3, w * 0.8 + 0.2), cf * CFrame.new(0, 1.65, 0), PAL.wood[1])
	for k = 0, 4 do
		local o = Vector3.new((hash(k, 1, w) - 0.5) * (w - 0.9), 1.8 + (k % 2) * 0.35, (hash(k, 2, w) - 0.5) * (w * 0.8 - 0.9))
		vox(g, "Ore", Vector3.new(0.8, 0.8, 0.8), cf * CFrame.new(o) * CFrame.Angles(hash(k, 3, w), hash(k, 4, w) * 3, 0), ore,
			{ CanCollide = false, Material = k == 2 and Enum.Material.Neon or Enum.Material.SmoothPlastic })
	end
end

local function barrel(g, p, s)
	s = s or 1
	for y = 0, 2 do tvox(g, "Barrel", Vector3.new(1.8, 0.9, 1.8) * s, CFrame.new(p + Vector3.new(0, (0.45 + y * 0.9) * s, 0)), "planks", 2) end
	for _, y in { 0.5, 2.2 } do vox(g, "BarrelBand", Vector3.new(1.95, 0.22, 1.95) * s, CFrame.new(p + Vector3.new(0, y * s, 0)), PAL.stone[1]) end
end

local function bush(g, p, seed)
	for i = -1, 1 do for k = -1, 1 do
		if hash(seed + i, 3, k) > 0.2 then
			vox(g, "Bush", Vector3.new(2, 2, 2) + Vector3.one * ((i + k) % 2) * 0.08, CFrame.new(p + Vector3.new(i * 1.9, 1 + (i == 0 and k == 0 and 1.5 or 0) + ((i + k) % 2) * 0.05, k * 1.9)), shadeOf("leaf", seed + i, 1, k), { CanCollide = false })
		end
	end end
	if hash(seed, 9, 9) > 0.5 then vox(g, "Berry", Vector3.new(0.6, 0.6, 0.6), CFrame.new(p + Vector3.new(0.8, 2.3, 1.2)), PAL.pink[2], { CanCollide = false }) end
end

function Hub.build(parent, origin)
	origin = origin or Vector3.zero
	model = Instance.new("Model")
	model.Name = "Hub"
	local O = origin
	local function W(x, y, z) return O + Vector3.new(x, y, z) end

	-- v5 town layout (the user, 2026-11-08: "more varied instead of just a linear line to each location"; refs: the user's
	-- Pinterest pixel towns and art/hub/pdv5_town_s71.jpg / s73.jpg): a north terrace (top y 4) behind a retaining wall with
	-- wide stairs, an east rise (top y 2) for the cabins, a stream with two arched footbridges, winding lanes that open into a
	-- small square round the shaft, tree clusters, a vegetable garden, a well, and lamps along the lanes.
	local TERRACE = { x0 = -20, x1 = 64, z0 = -120, z1 = -28, top = 4 }
	local RISE = { x0 = 28, x1 = 66, z0 = -12, z1 = 40, top = 2 }
	local function groundTop(x, z)
		if x >= TERRACE.x0 and x <= TERRACE.x1 and z >= TERRACE.z0 and z <= TERRACE.z1 then return TERRACE.top end
		if x >= RISE.x0 and x <= RISE.x1 and z >= RISE.z0 and z <= RISE.z1 then return RISE.top end
		return 0.6
	end
	local function bez(pts, u)
		local a = 1 - u
		return pts[1] * a ^ 3 + pts[2] * 3 * a ^ 2 * u + pts[3] * 3 * a * u ^ 2 + pts[4] * u ^ 3
	end
	local function P(x, z) return W(x, 0, z) end

	-- 1. Ground: a grass meadow round a big lilac cobblestone plaza (textured slabs, open over the shaft), tufts and flowers
	local ground = group("Ground")
	for _, b in { { -95, 0, 178, 360 }, { 95, 0, 178, 360 }, { 0, -93, 12, 174 }, { 0, 93, 12, 174 } } do -- grass meadow with a 12 x 12 hole for the shaft
		skin(vox(ground, "Meadow", Vector3.new(b[3], 6, b[4]), CFrame.new(W(b[1], -2.4, b[2])), AVG.grass), "grass", 6, { N.Top })
	end
	-- the small square round the shaft: cobbles with a ragged edge (top y 1.1)
	for z = -20, 18, 3 do
		local zc = z + 1.5
		local half = 17 * math.sqrt(math.max(0, 1 - (zc / 20.5) ^ 2)) + (hash(z, 2, 2) - 0.5) * 4
		if half > 3 then
			local spans = math.abs(zc) < 8 and { { -half, -7.5 }, { 7.5, half } } or { { -half, half } }
			for _, sp in spans do
				if sp[2] - sp[1] > 1 then
					skin(vox(ground, "Square", Vector3.new(sp[2] - sp[1], 0.5, 3), CFrame.new(W((sp[1] + sp[2]) / 2, 0.85, zc)), AVG.cobble_soft), "cobble_soft", 6, SIDES)
				end
			end
		end
	end

	-- the raised ground: grass on top, a lilac stone retaining wall round the sides, a mossy lip and hanging moss on the open edges
	local terr = group("Terraces")
	local wallTint = Color3.fromRGB(205, 200, 235)
	local function raised(r, name, edges)
		local blk = vox(terr, name, Vector3.new(r.x1 - r.x0, r.top + 2, r.z1 - r.z0), CFrame.new(W((r.x0 + r.x1) / 2, r.top / 2 - 1, (r.z0 + r.z1) / 2)), AVG.grass)
		skin(blk, "grass", 6, { N.Top })
		skin(blk, "stonebrick", 5, { N.Front, N.Back, N.Left, N.Right }, wallTint)
		blk.Color = AVG.stonebrick
		for _, e in edges do -- e = { "x" or "z", fixed coordinate, from, to, outward sign, skip from, skip to }
			for t = e[3], e[4] - 2, 2.6 do
				if not (e[6] and t > e[6] - 1 and t < e[7] + 1) then
					local h = hash(t, e[2], 4)
					local pos = e[1] == "z" and W(t + 1.3, r.top + 0.25, e[2] + e[5] * 0.4) or W(e[2] + e[5] * 0.4, r.top + 0.25, t + 1.3)
					vox(terr, "Lip", e[1] == "z" and Vector3.new(2.8, 0.7, 1.4) or Vector3.new(1.4, 0.7, 2.8), CFrame.new(pos), shadeOf("grass", t, 1, e[2]), { CanCollide = false })
					if h > 0.62 then -- hanging moss with a flower
						local hang = 1.2 + h * 2.2
						local hp = pos + (e[1] == "z" and Vector3.new(0, -0.35 - hang / 2, e[5] * 0.5) or Vector3.new(e[5] * 0.5, -0.35 - hang / 2, 0))
						vox(terr, "Moss", Vector3.new(0.8, hang, 0.8), CFrame.new(hp), PAL.moss[2], { CanCollide = false })
						vox(terr, "MossFlower", Vector3.new(0.6, 0.6, 0.6), CFrame.new(hp - Vector3.new(0, hang / 2 + 0.2, 0)), h > 0.8 and PAL.pink[2] or PAL.lilac[3], { CanCollide = false })
					end
				end
			end
		end
	end
	raised(TERRACE, "NorthTerrace", { { "z", TERRACE.z1, TERRACE.x0, TERRACE.x1, 1, 1.5, 10.5 }, { "x", TERRACE.x0, TERRACE.z0 + 40, TERRACE.z1, -1 } })
	raised(RISE, "EastRise", { { "x", RISE.x0, RISE.z0, RISE.z1, -1, 2, 12 }, { "z", RISE.z1, RISE.x0, RISE.x1, 1 }, { "z", RISE.z0, RISE.x0, RISE.x1, -1 } })
	for k = 0, 3 do -- the wide terrace stairs, with stepped cheek walls
		local top = k + 1
		skin(vox(terr, "Stair", Vector3.new(8, top, 2), CFrame.new(W(6, top / 2, -21 - k * 2)), PAL.stone[2]), "stonebrick", 3, SIDES, wallTint)
		for _, x in { 1.5, 10.5 } do skin(vox(terr, "Cheek", Vector3.new(1, top + 0.6, 2), CFrame.new(W(x, (top + 0.6) / 2, -21 - k * 2)), PAL.stone[2]), "stonebrick", 3, SIDES, wallTint) end
		-- a pale tread slab on each step that overhangs the riser (nosing), so every step casts a line of shadow
		skin(vox(terr, "Tread", Vector3.new(8, 0.3, 2.35), CFrame.new(W(6, top + 0.15, -20.85 - k * 2)), Color3.fromRGB(226, 216, 232)), "flagstone", 3, { N.Top }, Color3.fromRGB(255, 250, 255))
		if k % 2 == 0 then vox(terr, "RiserMoss", Vector3.new(1.4, 0.35, 0.3), CFrame.new(W(3 + k * 1.3, top - 0.2, -19.85 - k * 2)), PAL.moss[2], { CanCollide = false }) end
	end
	for k = 0, 1 do -- two steps up onto the east rise
		local top = 1 + k
		skin(vox(terr, "Stair", Vector3.new(2, top, 8), CFrame.new(W(25 + k * 2, top / 2, 7)), PAL.stone[2]), "stonebrick", 3, SIDES, wallTint)
		skin(vox(terr, "Tread", Vector3.new(2.35, 0.3, 8), CFrame.new(W(24.85 + k * 2, top + 0.15, 7)), Color3.fromRGB(226, 216, 232)), "flagstone", 3, { N.Top }, Color3.fromRGB(255, 250, 255))
	end

	-- the stream: water over the meadow with stone banks, reeds and lily pads; it walks the town from the west roots to the south
	local water = group("Stream")
	local function stream(pts, width)
		local n = math.ceil((pts[1] - pts[4]).Magnitude / 2)
		local prev = bez(pts, 0)
		for i = 1, n do
			local c = bez(pts, i / n)
			local mid = (prev + c) / 2
			local y = O.Y + 0.68 + (i % 2) * 0.04 -- playtest 2: neighbouring water and bank pieces 0.04 apart (0.01 flickered by the egg garden)
			local cf = CFrame.lookAt(Vector3.new(mid.X, y, mid.Z), Vector3.new(c.X, y, c.Z))
			local w = vox(water, "Water", Vector3.new(width, 0.2, (c - prev).Magnitude + 0.8), cf, Color3.fromRGB(120, 206, 226), { CanCollide = false, Transparency = 0.12, Material = Enum.Material.Glass })
			local t = Instance.new("Texture")
			t.Texture, t.Face, t.StudsPerTileU, t.StudsPerTileV, t.Transparency = "rbxassetid://102263231288805", N.Top, 6, 6, 0.4
			t.Parent = w
			local seg = (c - prev).Magnitude
			for _, sd in { -1, 1 } do
				local h = hash(i, sd, c.X)
				vox(water, "BankBed", Vector3.new(1.5 - (i % 3) * 0.04, 0.34, seg + 1.4), cf * CFrame.new(sd * (width / 2 + 0.55), 0.02 + (i % 3) * 0.035, 0), Color3.fromRGB(74, 70, 92), { CanCollide = false })
				tvox(water, "Bank", Vector3.new(1.3 + h * 0.6, 0.6 + h * 0.6 + (i % 3) * 0.05, 2.6), cf * CFrame.new(sd * (width / 2 + 0.5), 0.2, 0) * CFrame.Angles(0, (h - 0.5) * 0.5, 0), "cobble", 2)
				if i < n then -- the joint: a stone at the bend so the outside edge stays closed
					local nxt = bez(pts, (i + 1) / n)
					local jcf = CFrame.lookAt(Vector3.new(c.X, y, c.Z), Vector3.new(c.X, y, c.Z) + Vector3.new(nxt.X - prev.X, 0, nxt.Z - prev.Z))
					tvox(water, "BankJoint", Vector3.new(1.44, 0.5 + h * 0.4 + 0.07, 1.8), jcf * CFrame.new(sd * (width / 2 + 0.55), 0.18, 0), "cobble", 2)
				end
				if h > 0.78 then
					for k = 0, 2 do vox(water, "Reed", Vector3.new(0.25, 1.6 + k * 0.4, 0.25), cf * CFrame.new(sd * (width / 2 + 1.4), 0.9, k * 0.5 - 0.5), PAL.moss[(k % 3) + 1], { CanCollide = false }) end
				end
			end
			if hash(i, 7, c.Z) > 0.72 then
				vox(water, "LilyPad", Vector3.new(1.4, 0.12, 1.4), cf * CFrame.new((hash(i, 8, 1) - 0.5) * width * 0.5, 0.13, 0), PAL.moss[3], { CanCollide = false })
				if hash(i, 9, 1) > 0.5 then vox(water, "LilyFlower", Vector3.new(0.5, 0.4, 0.5), cf * CFrame.new((hash(i, 8, 1) - 0.5) * width * 0.5, 0.35, 0), PAL.pink[3], { CanCollide = false }) end
			end
			prev = c
		end
	end
	stream({ P(-92, -14), P(-66, -6), P(-46, 24), P(-19, 22) }, 5)
	stream({ P(-19, 22), P(-6, 21), P(-12, 40), P(-9, 46) }, 5)
	stream({ P(-9, 46), P(-6, 58), P(8, 70), P(16, 94) }, 5.5)

	-- arched plank footbridges with railings
	local function bridge(x, z, dx, dz, len)
		local g = group("Bridge")
		local p = W(x, 0.6, z)
		local cf = CFrame.lookAt(p, p + Vector3.new(dx, 0, dz))
		local n = 7
		for i = 0, n - 1 do
			local y = math.sin((i + 0.5) / n * math.pi) * 1.2
			tvox(g, "Deck", Vector3.new(4.4, 0.5, len / n + 0.1), cf * CFrame.new(0, 0.45 + y, -len / 2 + (i + 0.5) * len / n), "planks", 2)
		end
		for _, sd in { -1, 1 } do
			for i = 0, 4 do
				local u = i / 4
				tvox(g, "RailPost", Vector3.new(0.4, 1.8, 0.4), cf * CFrame.new(sd * 2.1, 1.4 + math.sin(u * math.pi) * 1.2, -len / 2 + u * len), "beam", 1)
			end
			for i = 0, 3 do
				local a = (cf * CFrame.new(sd * 2.1, 2.2 + math.sin(i / 4 * math.pi) * 1.2, -len / 2 + i / 4 * len)).Position
				local b = (cf * CFrame.new(sd * 2.1, 2.2 + math.sin((i + 1) / 4 * math.pi) * 1.2, -len / 2 + (i + 1) / 4 * len)).Position
				tvox(g, "Rail", Vector3.new(0.35, 0.35, (b - a).Magnitude + 0.2), CFrame.lookAt((a + b) / 2, b), "beam", 1)
			end
		end
	end
	bridge(-19, 22, 0, 1, 10)
	bridge(-9, 46, -0.9, 0.45, 10)

	-- winding lanes v2 (refs: art/hub/refs/README.md, Paths): big rounded cobbles; the width swells along the lane and flares where
	-- it meets a square or a door; the edges break up into the grass with loose stones and creeping tufts, and flowers grow in clumps
	local function lane(pts, width, tex, y)
		local n = math.max(3, math.ceil((pts[1] - pts[4]).Magnitude / 2.4))
		local prev = bez(pts, 0)
		for i = 1, n do
			local u = i / n
			local c = bez(pts, u)
			local mid = (prev + c) / 2
			local yy = O.Y + (y or groundTop(mid.X - O.X, mid.Z - O.Z)) + 0.15 + (i % 2) * 0.04 -- playtest 2: layers 0.04+ apart (0.01-0.02 flickered on the egg garden paths)
			local cf = CFrame.lookAt(Vector3.new(mid.X, yy, mid.Z), Vector3.new(c.X, yy, c.Z))
			local w = width * (1 + 0.45 * (1 - u) ^ 6 + 0.3 * u ^ 8 + 0.12 * math.sin(u * 6 + width))
			local laneTint = Color3.fromRGB(214, 220, 240) -- cools the lilac cobbles toward slate (Gemini paths r1)
			skin(vox(ground, "Lane", Vector3.new(w, 0.3, (c - prev).Magnitude + 1.2), cf, AVG[tex]), tex, 5, { N.Top }, laneTint)
			vox(ground, "LaneBed", Vector3.new(w + 0.9, 0.2, (c - prev).Magnitude + 1.4), cf * CFrame.new(0, -0.1, 0), Color3.fromRGB(58, 66, 62), { CanCollide = false })
			if i < n then -- joint slab on the bend, turned halfway between the two segments: closes the wedge on the outside of curves
				local nxt = bez(pts, (i + 1) / n)
				local jy = yy - 0.08 -- the joint sits clearly under both lane tops and above both beds
				local jcf = CFrame.lookAt(Vector3.new(c.X, jy, c.Z), Vector3.new(c.X, jy, c.Z) + Vector3.new(nxt.X - prev.X, 0, nxt.Z - prev.Z))
				skin(vox(ground, "LaneJoint", Vector3.new(w - 0.06, 0.3, math.min(w, 2.4)), jcf, AVG[tex]), tex, 5, { N.Top }, laneTint) -- 0.03 inside the lane edge: on straight runs its sides matched the lane's
				vox(ground, "LaneBed", Vector3.new(w + 0.84, 0.2, math.min(w, 2.4) + 0.4), jcf * CFrame.new(0, -0.1, 0), Color3.fromRGB(58, 66, 62), { CanCollide = false })
			end
			for _, side in { -1, 1 } do -- ragged edges: loose stones half in the grass, and tufts creeping over the edge
				local h = hash(i, side, c.X + c.Z)
				local e = cf * CFrame.new(side * (w / 2 + 0.2 + h * 0.5), -0.05, (h - 0.5) * 1.6)
				if h < 0.45 then
					tvox(ground, "EdgeStone", Vector3.new(1 + h * 0.9, 0.32, 0.9 + h * 0.8), e * CFrame.Angles(0, h * 2.5, 0), tex, 3)
				end
				if h > 0.3 then
					vox(ground, "EdgeTuft", Vector3.new(1.2 + h * 0.6, 0.45, 0.8 + h * 0.5), cf * CFrame.new(side * (w / 2 - 0.15), 0.12, (0.5 - h) * 1.4), shadeOf("grass", i, side, 5), { CanCollide = false })
				end
			end
			if i == 1 or i == n then -- a dirt patch with a pebble cluster where the lane runs out into the grass
				local e = cf * CFrame.new(0, -0.13, i == 1 and -1.5 or 1.5)
				vox(ground, "Dirt", Vector3.new(w + 1.2, 0.2, 2.2), e, Color3.fromRGB(104, 78, 84), { CanCollide = false })
				for k = 0, 4 do
					local hh = hash(k, i, c.X)
					vox(ground, "Pebble", Vector3.new(0.4 + hh * 0.35, 0.3, 0.4 + hh * 0.3), e * CFrame.new((hh - 0.5) * w, 0.2 + k * 0.03, (hash(k, c.Z, 2) - 0.5) * 1.6) * CFrame.Angles(0, hh * 3, 0), Color3.fromRGB(196, 190, 212), { CanCollide = false })
				end
			end
			if i % 4 == 2 and hash(i, 3, c.X) > 0.35 then -- a flower clump beside the lane
				local side = hash(i, 4, c.Z) > 0.5 and 1 or -1
				local e = cf * CFrame.new(side * (w / 2 + 1.6), 0, 0)
				local tint = ({ PAL.pink, PAL.lilac, { GOLD, GOLD, Color3.fromRGB(255, 240, 180) }, { PAL.cream[2], PAL.cream[3], WHITE_ } })[(i % 4) + 1]
				vox(ground, "Leaves", Vector3.new(1.8, 0.5, 1.6), e * CFrame.new(0, 0.1, 0), PAL.moss[2], { CanCollide = false })
				for k = 0, 3 do vox(ground, "Bloom", Vector3.new(0.6, 0.6, 0.6), e * CFrame.new((k % 2 - 0.5) * 0.9, 0.55 + (k == 3 and 0.35 or 0), (math.floor(k / 2) - 0.5) * 0.8), tint[(k % 3) + 1], { CanCollide = false }) end
			end
			prev = c
		end
	end
	-- stepping stones: flat cream slabs, each turned a little, with grass between them
	local function steps(pts, y)
		local n = math.max(2, math.floor((pts[1] - pts[4]).Magnitude / 2.6))
		for i = 0, n do
			local c = bez(pts, i / n)
			local h = hash(i, c.X, c.Z)
			local yy = O.Y + (y or groundTop(c.X - O.X, c.Z - O.Z)) + 0.12
			local scf = CFrame.new(c.X + (h - 0.5) * 0.8, yy + 0.12, c.Z) * CFrame.Angles(0, (h - 0.5) * 0.25, 0)
			vox(ground, "SteppingStone", Vector3.new(2 + h * 0.4, 0.5, 1.8 + h * 0.4), scf, Color3.fromRGB(220, 212, 192))
			vox(ground, "StoneTop", Vector3.new(1.6 + h * 0.4, 0.06, 1.3 + h * 0.4), scf * CFrame.new(-0.1, 0.27, -0.1), Color3.fromRGB(240, 234, 216), { CanCollide = false })
			vox(ground, "StoneBed", Vector3.new(2.8 + h * 0.4, 0.06, 2.6 + h * 0.4), scf * CFrame.new(0, -0.22, 0), Color3.fromRGB(104, 78, 84), { CanCollide = false })
		end
	end
	lane({ P(-13, 3), P(-18, 1), P(-23, 4), P(-28, 3) }, 5, "cobble_lane") -- to the sell stall (the ore cart rails run along it)
	lane({ P(-11, -11), P(-17, -19), P(-26, -14), P(-32, -22) }, 5, "cobble_lane") -- to the forge
	lane({ P(6, -28), P(6, -31), P(6, -33), P(6, -36) }, 6, "flagstone", 4) -- up the stairs to the quest kiosk
	lane({ P(9, -30), P(16, -28), P(24, -37), P(31, -36) }, 5, "flagstone", 4) -- along the terrace to the trophy hall
	lane({ P(15, 2), P(19, 6), P(22, 6), P(24, 7) }, 5, "cobble_lane") -- east to the rise steps
	lane({ P(28, 6), P(34, 4), P(40, -2), P(44, -1) }, 4.5, "cobble_lane", 2) -- the cabins on the rise
	lane({ P(28, 8), P(31, 14), P(33, 22), P(36, 24) }, 4.5, "cobble_lane", 2)
	lane({ P(-11, 11), P(-14, 13), P(-18, 14), P(-19, 17) }, 5, "cobble_lane") -- over the first bridge to the incubator
	steps({ P(-19, 27), P(-21, 30), P(-26, 30.5), P(-30, 30) })
	lane({ P(3, 19), P(5, 24), P(7, 28), P(9, 31) }, 5, "cobble_lane") -- south to the campfire glade
	steps({ P(2, 42), P(0, 43), P(-3, 43.5), P(-4.5, 43.8) }) -- the glade loop over the second bridge to the garden
	steps({ P(-13.5, 48.3), P(-14.5, 49.5), P(-15.5, 50.5), P(-16.5, 51) })

	-- voxel trees v2 (refs: art/hub/refs/README.md, Trees): a trunk in two bent segments with a root flare, branches for the
	-- blossom and wisteria kinds, and a canopy of shaded clumps (dark underside, light top, loose leaf cubes breaking the outline).
	-- Kinds: round (mint), blossom (pink, petals on the ground), wisteria (lilac, hanging strands), bonsai (flat layered pads).
	local trees = group("Trees")
	local TREE_COLS = {
		round = { Color3.fromRGB(40, 90, 85), Color3.fromRGB(115, 215, 170), Color3.fromRGB(180, 245, 210), Color3.fromRGB(245, 255, 200) },
		blossom = { Color3.fromRGB(155, 75, 120), Color3.fromRGB(255, 170, 205), Color3.fromRGB(255, 225, 235), Color3.fromRGB(255, 245, 210) },
		wisteria = { Color3.fromRGB(56, 112, 96), Color3.fromRGB(96, 160, 128), Color3.fromRGB(135, 200, 156), Color3.fromRGB(190, 236, 196) }, -- a green crown; the flowers hang below
		wisteriaFlower = { Color3.fromRGB(135, 95, 180), Color3.fromRGB(185, 145, 225), Color3.fromRGB(225, 195, 250) },
		bonsai = { Color3.fromRGB(40, 104, 96), Color3.fromRGB(66, 146, 120), Color3.fromRGB(112, 190, 146), Color3.fromRGB(170, 228, 180) },
	}
	local LEAF = { CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false }
	local function clump(c, r, cols, seed, flat)
		-- a shell of small leaf cubes (about 1 stud) on a golden spiral round a dark core, shaded in bands by height
		-- (refs pdv5_trees_s81/82; Gemini trees r1: many small cubes, dark under, light top, cubes poking out of the outline)
		local fy = flat or 0.8
		vox(trees, "LeafCore", Vector3.new(r * 1.45, r * 1.45 * fy, r * 1.45), CFrame.new(c) * CFrame.Angles(0, seed, 0), cols[1], LEAF)
		local n = math.clamp(math.floor(r * r * 2.8), 10, 24)
		for k = 1, n do
			local y = 1 - 2 * (k - 0.5) / n
			local rr = math.sqrt(1 - y * y)
			local a = k * 2.39996 + seed
			local d = Vector3.new(math.cos(a) * rr, y * fy, math.sin(a) * rr)
			local h = hash(k, seed * 10, r)
			local band = d.Y < -0.3 * fy and 1 or (d.Y < 0.15 * fy and 2 or (d.Y < 0.55 * fy and 3 or 4))
			if h > 0.8 and band < 4 then band += 1 end
			local sz = 0.8 + h * 0.5
			vox(trees, "Leaf", Vector3.one * sz, CFrame.new(c + d * r * (0.78 + h * 0.2)) * CFrame.Angles(0, (h - 0.5) * 0.5, 0), cols[band], LEAF)
		end
	end
	local function tree(x, z, sc, kind)
		kind = kind == true and "blossom" or (kind or "round")
		if kind == "round" then sc *= 1.35 end
		local cols = TREE_COLS[kind]
		local base = W(x, groundTop(x, z), z)
		local seed = hash(x, z, 9) * 6
		local lean = Vector3.new(math.cos(seed), 0, math.sin(seed)) * 0.6 * sc
		local h = (kind == "bonsai" and 4.5 or 6.5) * sc
		local tw = (kind == "bonsai" and 2.2 or 1.7) * sc
		local barkTint = Color3.fromRGB(196, 172, 190)
		local top = base + Vector3.new(0, h, 0) + lean * 0.3
		local side = Vector3.new(-lean.Z, 0, lean.X)
		local p1 = base + Vector3.new(0, h * 0.34, 0) + lean * 0.7
		local p2 = base + Vector3.new(0, h * 0.68, 0) + lean * 0.9 + side * 0.5
		for _, seg in { { base, p1, tw }, { p1, p2, tw * 0.8 }, { p2, top, tw * 0.62 } } do -- three tapered trunk segments in an S-curve
			local a, b = seg[1], seg[2]
			skin(vox(trees, "Trunk", Vector3.new(seg[3], seg[3], (b - a).Magnitude + seg[3] * 0.5), CFrame.lookAt((a + b) / 2, b), AVG.bark), "bark", 4, SIDES, barkTint)
		end
		for k = 0, 3 do -- four uneven roots that slope down into the grass
			local a = seed + k * 1.57 + (hash(k, x, z) - 0.5) * 0.8
			local d = Vector3.new(math.cos(a), 0, math.sin(a))
			local len = tw * (0.8 + hash(k, z, x) * 0.7)
			skin(vox(trees, "Root", Vector3.new(tw * 0.45, tw * 0.38, len), CFrame.lookAt(base + d * (tw * 0.35 + len * 0.4) + Vector3.new(0, tw * 0.22, 0), base + d * (tw + len) - Vector3.new(0, tw * 0.5, 0)), AVG.bark), "bark", 4, { N.Top, N.Left, N.Right }, barkTint)
		end
		local crown = {}
		if kind == "round" then
			crown = { { top + Vector3.new(0, 1.4 * sc, 0), 2.7 }, { top + Vector3.new(2.1, 0.2, 0.8) * sc, 1.9 }, { top + Vector3.new(-1.9, 0.4, -1.1) * sc, 2 }, { top + Vector3.new(0.4, 0.9, -2.2) * sc, 1.7 }, { top + Vector3.new(-0.6, 3, 0.6) * sc, 1.6 } }
		elseif kind == "bonsai" then -- a mossy rock under the roots, short branches with flattened leaf clumps
			for q, b in { { 2.6, 1.2, 2.2, 0, 0 }, { 1.7, 1.5, 1.6, 0.5, 0.3 }, { 1.4, 0.9, 1.3, -0.7, -0.4 } } do -- a weathered slate boulder
				vox(trees, "BonsaiRock", Vector3.new(b[1], b[2], b[3]) * tw, CFrame.new(base + Vector3.new(b[4] * tw, b[2] * tw * 0.45, b[5] * tw)) * CFrame.Angles(0, seed + q * 0.7, 0), ({ Color3.fromRGB(110, 118, 130), Color3.fromRGB(136, 144, 158), Color3.fromRGB(92, 98, 112) })[q])
			end
			vox(trees, "Moss", Vector3.new(tw * 1.8, 0.3, tw * 1.5), CFrame.new(base + Vector3.new(0, tw * 1.1, 0)) * CFrame.Angles(0, seed + 0.4, 0), cols[3], { CanCollide = false })
			for k, o in { { 0, 0.6, 0, 2.2 }, { 2.8, -1.2, 1, 1.5 }, { -2.6, -0.4, -1.3, 1.6 } } do
				local pc = top + Vector3.new(o[1], o[2], o[3]) * sc
				if k > 1 then skin(vox(trees, "Branch", Vector3.new(0.6 * sc, 0.6 * sc, (pc - top).Magnitude + 0.3), CFrame.lookAt((pc + top) / 2, pc), AVG.bark), "bark", 4, SIDES, barkTint) end
				table.insert(crown, { pc, o[4] })
			end
		else -- blossom and wisteria: three branches spread sideways, a clump on each and one on top
			crown = { { top + Vector3.new(0, 1.6 * sc, 0), 2.2 } }
			for k = 0, 2 do
				local a = seed + k * 2.1
				local reach = kind == "blossom" and 4.3 or 3.4
				local tip = top + Vector3.new(math.cos(a) * reach, 0.4 + (k % 2) * 1.1, math.sin(a) * reach) * sc
				skin(vox(trees, "Branch", Vector3.new(0.7 * sc, 0.7 * sc, (tip - top).Magnitude + 0.4), CFrame.lookAt((tip + top) / 2, tip), AVG.bark), "bark", 4, SIDES, barkTint)
				table.insert(crown, { tip + Vector3.new(0, 0.6 * sc, 0), kind == "blossom" and 1.5 or 1.8 })
			end
		end
		for k, cl in crown do clump(cl[1], cl[2] * sc, cols, seed + k, kind == "bonsai" and 0.42 or nil) end
		if kind == "wisteria" then -- tapered racemes hanging from each clump: deep lilac, lavender, pale tip, a few loose petals below
			local fl = TREE_COLS.wisteriaFlower
			for k = 1, #crown do
				for j = 0, 5 do
					local a = seed + k * 1.7 + j * 1.05
					local rr = crown[k][2] * sc * (j % 2 == 0 and 0.85 or 0.5)
					local sp = crown[k][1] + Vector3.new(math.cos(a) * rr, -crown[k][2] * sc * 0.45, math.sin(a) * rr)
					local L = 0.8 + hash(j, k, x) * 0.8
					vox(trees, "Raceme", Vector3.new(0.8, 1.5 * L, 0.8), CFrame.new(sp - Vector3.new(0, 0.75 * L, 0)), fl[1], LEAF)
					vox(trees, "Raceme", Vector3.new(0.6, 1.5 * L, 0.6), CFrame.new(sp - Vector3.new(0, 2.25 * L, 0)), fl[2], LEAF)
					vox(trees, "Raceme", Vector3.new(0.4, 1 * L, 0.4), CFrame.new(sp - Vector3.new(0, 3.25 * L, 0)), fl[3], LEAF)
				end
			end
			for q = 0, 4 do vox(trees, "Petal", Vector3.new(0.5, 0.12, 0.5), CFrame.new(base + Vector3.new((hash(q, x, 3) - 0.5) * 7 * sc, 0.08, (hash(q, z, 4) - 0.5) * 7 * sc)), fl[3], LEAF) end
		end
		if kind == "blossom" then
			for k = 0, 5 do vox(trees, "Petal", Vector3.new(0.6, 0.12, 0.6), CFrame.new(base + Vector3.new((hash(k, x, 1) - 0.5) * 8 * sc, 0.08, (hash(k, z, 2) - 0.5) * 8 * sc)), cols[3], { CanCollide = false }) end
		end
		for k = 0, 2 do -- a ring of grass tufts round the foot
			local a = seed * 2 + k * 2.1
			vox(trees, "Tuft", Vector3.new(0.9, 0.6, 0.9), CFrame.new(base + Vector3.new(math.cos(a) * tw * 1.4, 0.3, math.sin(a) * tw * 1.4)), shadeOf("grass", k, x, z), { CanCollide = false })
		end
	end
	for _, t in { { -24, -44, 1.1 }, { -54, -44, 1.3, "wisteria" }, { -58, -16, 1, "blossom" }, { -60, 36, 1.2 }, { -48, 54, 1, "blossom" }, { -14, 66, 1.1, "bonsai" }, { 22, 66, 1.2 },
		{ 44, 56, 1, "wisteria" }, { 60, 48, 1.3 }, { 58, -20, 1, "bonsai" }, { 54, -42, 1.2, "blossom" }, { -8, -58, 1.3 }, { 22, -62, 1.1, "wisteria" }, { 20, -18, 0.9, "blossom" },
		{ 18, 24, 0.8, "bonsai" }, { -48, -18, 0.8, "blossom" }, { 62, 12, 1.1 }, { -66, 6, 1.1, "wisteria" },
		{ -38, 54, 0.9, "blossom" }, { 14, 56, 0.8 }, { 44, 12, 0.85, "wisteria" } } do
		tree(t[1], t[2], t[3], t[4])
	end

	-- the vegetable garden by the second bridge: soil rows, sprouts, pumpkins, a picket fence with a gate on the east side
	do
		local g = group("Garden")
		local x0, x1, z0, z1 = -30, -16, 44, 58
		for k = 0, 3 do
			local z = z0 + 2.5 + k * 3.2
			vox(g, "Soil", Vector3.new(x1 - x0 - 2, 0.5, 1.8), CFrame.new(W((x0 + x1) / 2, 0.75, z)), Color3.fromRGB(110, 76, 84))
			for j = 0, 5 do
				local x = x0 + 2 + j * 2.1
				if k == 2 and j % 2 == 0 then
					vox(g, "Pumpkin", Vector3.new(1.3, 1, 1.3), CFrame.new(W(x, 1.4, z)), Color3.fromRGB(240, 150, 80))
					vox(g, "Stalk", Vector3.new(0.25, 0.4, 0.25), CFrame.new(W(x, 2.1, z)), PAL.moss[1], { CanCollide = false })
				else
					vox(g, "Sprout", Vector3.new(0.6, 0.7 + (j % 2) * 0.3, 0.6), CFrame.new(W(x, 1.35, z)), shadeOf("moss", j, k, 2), { CanCollide = false })
					if k == 1 then vox(g, "Carrot", Vector3.new(0.4, 0.3, 0.4), CFrame.new(W(x + 0.4, 1.1, z + 0.3)), Color3.fromRGB(240, 140, 70), { CanCollide = false }) end
				end
			end
		end
		local picket = PAL.cream[3]
		for x = x0, x1, 1.6 do for _, z in { z0, z1 } do vox(g, "Picket", Vector3.new(0.4, 1.6, 0.4), CFrame.new(W(x, 1.4, z)), picket) end end
		for z = z0, z1, 1.6 do
			vox(g, "Picket", Vector3.new(0.4, 1.6, 0.4), CFrame.new(W(x0, 1.4, z)), picket)
			if z < 49 or z > 53 then vox(g, "Picket", Vector3.new(0.4, 1.6, 0.4), CFrame.new(W(x1, 1.4, z)), picket) end -- the gate gap
		end
		for _, z in { z0, z1 } do vox(g, "FenceRail", Vector3.new(x1 - x0, 0.3, 0.25), CFrame.new(W((x0 + x1) / 2, 1.7, z)), picket) end
		vox(g, "FenceRail", Vector3.new(0.25, 0.3, z1 - z0), CFrame.new(W(x0, 1.7, (z0 + z1) / 2)), picket)
	end

	-- a stone well on the square's west corner, and a signpost at the north-east corner pointing up the stairs
	do
		local g = group("Well")
		local c = W(-16, 1.1, -6)
		for i = 0, 9 do
			local a = i / 10 * math.pi * 2
			tvox(g, "WellStone", Vector3.new(1.2, 1.6, 1.2), CFrame.new(c + Vector3.new(math.cos(a) * 1.9, 0.8, math.sin(a) * 1.9)) * CFrame.Angles(0, -a, 0), "stonebrick", 2)
		end
		vox(g, "WellWater", Vector3.new(2.8, 0.2, 2.8), CFrame.new(c + Vector3.new(0, 1.2, 0)), Color3.fromRGB(110, 200, 226), { CanCollide = false, Material = Enum.Material.Glass })
		for _, sd in { -1, 1 } do tvox(g, "WellPost", Vector3.new(0.5, 4.4, 0.5), CFrame.new(c + Vector3.new(sd * 2.1, 2.2, 0)), "beam", 2) end
		tvox(g, "Crank", Vector3.new(4.6, 0.35, 0.35), CFrame.new(c + Vector3.new(0, 3.6, 0)), "beam", 1)
		stepRoof(g, function(x, y, z) return CFrame.new(c) * CFrame.new(x, y, z) end, 5.6, 4, 4.4, "shingle_teal", 0.5)
		tvox(g, "Bucket", Vector3.new(0.9, 0.8, 0.9), CFrame.new(c + Vector3.new(0.4, 2.4, 0.3)), "planks", 1)
		vox(g, "Rope", Vector3.new(0.12, 0.9, 0.12), CFrame.new(c + Vector3.new(0.4, 3.1, 0.3)), PAL.cream[1], { CanCollide = false })
		local sp = group("Signpost")
		local q = W(11, 1.1, -14)
		tvox(sp, "Post", Vector3.new(0.6, 5.4, 0.6), CFrame.new(q + Vector3.new(0, 2.7, 0)), "beam", 2)
		for k, d in { { "QUESTS", -100, 4.6 }, { "TROPHIES", -40, 3.8 }, { "CABINS", 20, 3 } } do
			sign(sp, d[1], CFrame.new(q + Vector3.new(0, d[3], 0)) * CFrame.Angles(0, math.rad(d[2]), 0) * CFrame.new(1.6, 0, 0), 3.4, 0.8, PAL.cream[2])
		end
	end

	for i = 0, 219 do -- grass tufts and flowers in the grass between the lanes
		local a, rr = hash(i, 11, 3) * math.pi * 2, 22 + hash(i, 12, 3) * 62
		local tx, tz = math.cos(a) * rr, math.sin(a) * rr * 1.1
		local p = W(tx, groundTop(tx, tz), tz)
		local h = hash(i, 13, 3)
		if h > 0.55 then
			local fc = ({ PAL.pink[2], GOLD, PAL.cream[2], PAL.lilac[3], PAL.moss[3] })[math.floor(h * 1000) % 5 + 1]
			vox(ground, "Flower", Vector3.new(0.7, 0.7, 0.7), CFrame.new(p + Vector3.new(0, 0.9, 0)), fc, { CanCollide = false })
			vox(ground, "Stem", Vector3.new(0.25, 0.9, 0.25), CFrame.new(p + Vector3.new(0, 0.45, 0)), PAL.moss[1], { CanCollide = false })
		else
			vox(ground, "Tuft", Vector3.new(1.2, 0.7 + h, 1.2), CFrame.new(p + Vector3.new(0, 0.35 + h / 2, 0)), shadeOf("grass", i, 2, 3), { CanCollide = false })
		end
	end
	for i = 0, 40 do -- low brambles and stones along the south edge of the view
		local x = -86 + i * 4.3 + hash(i, 1, 9) * 2
		local z = 66 + hash(i, 2, 9) * 10
		local h = 1.6 + hash(i, 3, 9) * 2.2
		vox(ground, "Bramble", Vector3.new(4, h, 3.8), CFrame.new(W(x, h / 2 + 0.6, z)) * CFrame.Angles(0, hash(i, 4, 9), 0), PAL.leaf[(i % 3) + 1], { CanCollide = false })
		if i % 3 == 0 then vox(ground, "BrambleTop", Vector3.new(2.6, 1.4, 2.6), CFrame.new(W(x + 0.6, h + 1.2, z - 0.4)), PAL.leaf[3], { CanCollide = false }) end
		if i % 4 == 1 then vox(ground, "Berry", Vector3.new(0.6, 0.6, 0.6), CFrame.new(W(x - 0.8, h + 0.8, z - 1.4)), PAL.pink[2], { CanCollide = false }) end
	end

	-- 2. The mine shaft in the centre: stone-block rim, a pit with stone walls and a cyan crystal glow; falling in enters your mine
	local shaft = group("MineShaft")
	for _, o in { { 0, -1 }, { 0, 1 }, { -1, 0 }, { 1, 0 } } do
		for t = -6, 6, 2 do
			local x, z = o[1] ~= 0 and o[1] * 7 or t, o[2] ~= 0 and o[2] * 7 or t
			skin(vox(shaft, "Rim", Vector3.new(2, 1.6, 2), CFrame.new(W(x, 0.8, z)), PAL.stone[2]), "stonebrick", 2)
			if (t + 6) % 4 == 0 then vox(shaft, "RimCap", Vector3.new(2.2, 0.5, 2.2), CFrame.new(W(x, 1.85, z)), PAL.stone[3]) end
		end
	end
	for _, o in { { 0, -1 }, { 0, 1 }, { -1, 0 }, { 1, 0 } } do -- the pit walls as four textured slabs, darker the deeper they go
		local cf = CFrame.new(W(o[1] * 6.5, -5, o[2] * 6.5))
		skin(vox(shaft, "PitWall", o[1] ~= 0 and Vector3.new(2, 10, 13) or Vector3.new(13, 10, 2), cf, PAL.stone[1]), "stonebrick", 4, SIDES, Color3.fromRGB(150, 140, 190))
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
	sparks.Color, sparks.LightEmission, sparks.EmissionDirection = ColorSequence.new(CYAN), 1, N.Top
	sparks.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0) })
	sparks.Parent = pitFloor
	local mist = Instance.new("ParticleEmitter")
	mist.Rate, mist.Lifetime, mist.Speed, mist.SpreadAngle = 3, NumberRange.new(3, 5), NumberRange.new(2, 3.5), Vector2.new(25, 25)
	mist.Color, mist.LightEmission, mist.EmissionDirection = ColorSequence.new(Color3.fromRGB(170, 160, 240), CYAN), 0.4, N.Top
	mist.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 6) })
	mist.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.75), NumberSequenceKeypoint.new(1, 1) })
	mist.Parent = pitFloor
	-- headframe: two A-legs of timber beams, a crossbeam, a cube-built pulley wheel, rope and a hanging crystal
	for _, s in { -1, 1 } do
		for _, z in { -6, 6 } do tvox(shaft, "Leg", Vector3.new(2, 20, 2), CFrame.new(W(s * 7.5, 10, z)) * CFrame.Angles(z > 0 and 0.12 or -0.12, 0, 0), "beam", 4) end
		tvox(shaft, "Brace", Vector3.new(1.4, 1.4, 12), CFrame.new(W(s * 7.5, 7, 0)), "beam", 4)
		tvox(shaft, "Brace", Vector3.new(1.2, 1.2, 12.5), CFrame.new(W(s * 7.5, 12, 0)) * CFrame.Angles(0.5, 0, 0), "beam", 4)
	end
	tvox(shaft, "CrossBeam", Vector3.new(18, 2.2, 2.2), CFrame.new(W(0, 19.5, 0)), "beam", 4)
	vox(shaft, "Rope", Vector3.new(0.25, 14, 0.25), CFrame.new(W(0, 13, 2.6)), PAL.cream[1], { CanCollide = false })
	for k, o in { { 0.7, 0.2, 1.1 }, { -0.6, -0.4, 0.9 }, { 0.1, -0.9, 0.8 } } do
		vox(shaft, "HangingShard", Vector3.new(0.7, o[3] * 1.6, 0.7), CFrame.new(W(o[1], 5.4 + o[2], 2.6)) * CFrame.Angles(0.3 * k, 0.5, 0.2), k == 2 and Color3.fromRGB(170, 150, 240) or CYAN, { CanCollide = false, Material = Enum.Material.Neon })
	end
	local hang = vox(shaft, "HangingCrystal", Vector3.new(1.6, 1.6, 1.6), CFrame.new(W(0, 5.4, 2.6)) * CFrame.Angles(0.6, 0.6, 0), CYAN, { CanCollide = false })
	glow(hang, CYAN, 18, 1.2)
	hang:SetAttribute("Bob", 0.3)
	sign(shaft, "MINE", CFrame.new(W(0, 17.2, 6.9)), 5, 1.8, GOLD)
	-- the minecart dock (feedback batch phase 4, storyboard https://claude.ai/artifact/RbfNa2PVyTuRTwyVzdbWTs): a plank deck over the
	-- south rim, rails that run to the lip of the shaft and dip over it, buffers, and the parked cart whose prompt starts the ride
	local dock = group("MineDock")
	local RAILC = Color3.fromRGB(150, 140, 170)
	vox(dock, "Deck", Vector3.new(5, 1.2, 8.4), CFrame.new(W(0, 1.7, 9.8)), PAL.wood[2])
	for k = 0, 4 do vox(dock, "Sleeper", Vector3.new(3.4, 0.2, 0.7), CFrame.new(W(0, 2.4, 6.2 + k * 1.8)), PAL.wood[1], { CanCollide = false }) end
	for _, x in { -1.25, 1.25 } do
		vox(dock, "Rail", Vector3.new(0.3, 0.3, 8.4), CFrame.new(W(x, 2.45, 9.8)), RAILC, { Material = Enum.Material.Metal, CanCollide = false })
		local c = W(x, 1.88, 4.8)
		vox(dock, "RailLip", Vector3.new(0.3, 0.3, 2), CFrame.lookAt(c, c + Vector3.new(0, -0.57, -0.82)), RAILC, { Material = Enum.Material.Metal, CanCollide = false })
		vox(dock, "BufferPost", Vector3.new(0.6, 1.4, 0.6), CFrame.new(W(x * 1.2, 3, 13.7)), PAL.wood[1])
		vox(dock, "BufferPad", Vector3.new(0.8, 0.6, 0.3), CFrame.new(W(x * 1.2, 3.2, 13.3)), PAL.pink[2])
	end
	-- the cart: a hollow lilac tub (the rider sees its inside in first person) with butter rims on four wheels, facing the shaft
	local cart = group("HubCart")
	local base = CFrame.lookAt(W(0, 2.3, 9.8), W(0, 2.3, 0))
	local LIL, BUT = Color3.fromRGB(150, 128, 200), Color3.fromRGB(255, 214, 140)
	local root = vox(cart, "Base", Vector3.new(0.2, 0.2, 0.2), base, LIL, { Transparency = 1, CanCollide = false, CanQuery = false })
	cart.PrimaryPart = root
	local floor = vox(cart, "Floor", Vector3.new(2.4, 0.3, 3), base * CFrame.new(0, 0.9, 0), LIL:Lerp(Color3.new(0, 0, 0), 0.25))
	for _, z in { -1.65, 1.65 } do vox(cart, "WallEnd", Vector3.new(3, 1.6, 0.3), base * CFrame.new(0, 1.75, z), LIL) end
	for _, x in { -1.35, 1.35 } do vox(cart, "WallSide", Vector3.new(0.3, 1.6, 3), base * CFrame.new(x, 1.75, 0), LIL) end
	for _, z in { -1.65, 1.65 } do vox(cart, "RimEnd", Vector3.new(3.2, 0.35, 0.35), base * CFrame.new(0, 2.62, z), BUT, { Material = Enum.Material.Metal }) end
	for _, x in { -1.4, 1.4 } do vox(cart, "RimSide", Vector3.new(0.3, 0.3, 2.95), base * CFrame.new(x, 2.6, 0), BUT, { Material = Enum.Material.Metal }) end
	for _, w in { { -1.55, -1.1 }, { 1.55, -1.1 }, { -1.55, 1.1 }, { 1.55, 1.1 } } do
		vox(cart, "Wheel", Vector3.new(0.4, 1, 1), base * CFrame.new(w[1], 0.65, w[2]) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(60, 46, 76), { Shape = Enum.PartType.Cylinder })
	end
	prompt(floor, "Ride the minecart", "Minecart", "enter")

	-- a store frame at (x, z) with its front (+Z) turned toward the point (fx, fz); store parts are laid out for a ground top of
	-- 1.1, so the frame sits at the real ground top (meadow 0.6, rise 2, terrace 4) minus 1.1
	local function stationAt(x, z, fx, fz, top)
		local p = W(x, (top or 0.6) - 1.1, z)
		local away = Vector3.new(x - fx, 0, z - fz).Unit
		local cf = CFrame.lookAt(p, p + away)
		return function(xx, yy, zz) return cf * CFrame.new(xx, yy, zz) end, cf
	end

	-- 3. Sell stall (west; ref art/hub/pdv4_sell_s61.jpg): a raised plank deck, a counter with drawers and brass knobs, thick posts,
	-- a scalloped pink and cream awning, crates heaped with glowing ore, brass scales, lanterns and a SELL sign hung from the post
	do
		local g, at = group("SellStall"), stationAt(-36, 2, -12, 4)
		tvox(g, "Deck", Vector3.new(18, 1.4, 12), at(0, 1.3, -2), "planks_light", 4)
		for _, x in { -8.6, 8.6 } do for _, z in { 3.6, -7.6 } do tvox(g, "DeckPost", Vector3.new(0.9, 1.5, 0.9), at(x, 1.2, z), "beam", 2) end end
		tvox(g, "Counter", Vector3.new(14, 3, 2.6), at(0, 3.5, 1.6), "planks", 4)
		for i = 0, 3 do -- drawer faces with brass knobs on the counter front
			local x = -5.25 + i * 3.5
			tvox(g, "Drawer", Vector3.new(2.8, 1.2, 0.25), at(x, 3.3, 2.95), "planks_light", 2)
			vox(g, "Knob", Vector3.new(0.35, 0.35, 0.2), at(x, 3.3, 3.15), GOLD, { Material = Enum.Material.Metal })
		end
		tvox(g, "CounterTop", Vector3.new(14.8, 0.5, 3.4), at(0, 5.25, 1.6), "planks_light", 4)
		local slope, top = math.rad(16), 15
		for _, x in { -7.6, 7.6 } do
			for _, z in { 3, -7 } do -- thick posts, each cut to meet the sloping awning
				local h = top - (z + 2) * math.tan(slope) - 0.3 - 2
				tvox(g, "Post", Vector3.new(1.5, h, 1.5), at(x, 2 + h / 2, z), "beam", 4)
			end
		end
		local aw = tvox(g, "Awning", Vector3.new(17.4, 0.6, 12), at(0, top, -2) * CFrame.Angles(slope, 0, 0), "awning", 4)
		for i = 0, 16 do -- the scalloped front valance: rounded tabs in alternating pink and cream
			local lip = aw.CFrame * CFrame.new(-8 + i, -0.3, 6.1) * CFrame.Angles(-slope, 0, 0)
			local c = (math.floor(i / 2) % 2 == 0) and PAL.pink[2] or PAL.cream[3]
			vox(g, "Scallop", Vector3.new(1, 1.2, 0.5), lip * CFrame.new(0, -0.6, 0), c, { CanCollide = false })
			vox(g, "ScallopTip", Vector3.new(0.6, 0.45, 0.5), lip * CFrame.new(0, -1.42, 0), c, { CanCollide = false })
		end
		for i, ore in { ORE[1], ORE[2], ORE[3] } do oreCrate(g, at(-4.6 + (i - 1) * 4.6, 5.5, 1.6), ore, 3) end
		for i, ore in { ORE[4], ORE[1], ORE[3] } do oreCrate(g, at(-6.4 + (i - 1) * 3.4, 1.1, 5.8) * CFrame.Angles(0, (i - 2) * 0.15, 0), ore, 2.6) end
		oreCrate(g, at(-4.5, 2, -5.4), ORE[2], 2.4)
		oreCrate(g, at(4.2, 2, -5.6) * CFrame.Angles(0, 0.2, 0), ORE[4], 2.4)
		barrel(g, at(-0.6, 2, -6).Position, 0.8)
		tvox(g, "Scale", Vector3.new(0.4, 2.2, 0.4), at(5.6, 6.6, 2.2), "iron", 2)
		vox(g, "ScaleBeam", Vector3.new(3, 0.25, 0.25), at(5.6, 7.7, 2.2), GOLD, { Material = Enum.Material.Metal })
		for _, x in { 4.3, 6.9 } do vox(g, "ScalePan", Vector3.new(1.2, 0.2, 1.2), at(x, 6.7, 2.2), GOLD, { Material = Enum.Material.Metal }) end
		tvox(g, "CrossBeam", Vector3.new(16.6, 0.8, 0.8), at(0, 12.9, 3), "beam", 4)
		cubeLantern(g, at(0, 10.4, 3).Position, 1.2, 1.1) -- the big lantern hung from the front crossbeam
		for i = 0, 3 do -- drawer faces on the deck skirt
			local x = -6 + i * 4
			tvox(g, "DeckDrawer", Vector3.new(3, 0.9, 0.2), at(x, 1.3, 4.05), "planks", 2)
			vox(g, "Knob", Vector3.new(0.35, 0.35, 0.2), at(x, 1.3, 4.2), GOLD, { Material = Enum.Material.Metal })
		end
		for _, sd in { -1, 1 } do -- scallops down both flanks of the awning
			for k = 0, 11 do
				local lip = aw.CFrame * CFrame.new(sd * 8.75, -0.3, -5.5 + k) * CFrame.Angles(-slope, 0, 0)
				vox(g, "Scallop", Vector3.new(0.5, k % 2 == 0 and 1.2 or 0.9, 1), lip * CFrame.new(0, k % 2 == 0 and -0.6 or -0.45, 0), (math.floor(k / 2) % 2 == 0) and PAL.pink[2] or PAL.cream[3], { CanCollide = false })
			end
		end
		do -- a price ledger and a quill on the counter
			local led = vox(g, "Ledger", Vector3.new(1.8, 0.12, 1.3), at(-1.4, 5.56, 2.3) * CFrame.Angles(0, 0.3, 0), PAL.cream[3], { CanCollide = false })
			for l = 0, 2 do vox(g, "LedgerLine", Vector3.new(1.2, 0.04, 0.1), led.CFrame * CFrame.new(0, 0.07, -0.35 + l * 0.35), INK:Lerp(PAL.cream[1], 0.4), { CanCollide = false }) end
			vox(g, "Quill", Vector3.new(0.15, 0.15, 1.4), led.CFrame * CFrame.new(0.6, 0.2, 0.1) * CFrame.Angles(0.5, 0.4, 0), PAL.pink[3], { CanCollide = false })
		end
		-- the SELL sign hangs from an arm on the front post, turned to face the camera (south)
		tvox(g, "SignArm", Vector3.new(4.4, 0.5, 0.5), at(9.8, 11.8, 3), "beam", 2)
		do -- the SELL sign hangs off the front post on an arm, turned to face the camera (pairwise round 3 vs 5)
			local sp = at(10.6, 9.6, 3).Position
			sign(g, "SELL", CFrame.new(sp), 5, 2, GOLD)
			for _, dx in { -1.6, 1.6 } do vox(g, "SignChain", Vector3.new(0.15, 1.3, 0.15), CFrame.new(sp + Vector3.new(dx, 1.65, 0)), PAL.stone[1], { CanCollide = false }) end
		end
		barrel(g, at(-10.6, 1.1, 3).Position)
		barrel(g, at(-10.4, 1.1, 0.2).Position, 0.85)
		local counter = g:FindFirstChild("CounterTop")
		prompt(counter, "Sell ore", "Sell stall", "sell")
		vox(g, "SellPoint", Vector3.new(1, 1, 1), at(0, 3, 7.4), PAL.wood[1], { Transparency = 1, CanCollide = false, CanQuery = false })
		villager("Pip", at(1.6, 2, -2.2), PAL.pink[2], PAL.cream[2])
	end

	-- 4. Forge (north-west; ref art/hub/pdv4_forge_s61.jpg): a stone brick ground floor with an open workshop alcove under a
	-- timber-framed plaster upper floor, a steep teal shingle gable facing front, a brick chimney with a fireplace on the right,
	-- an anvil on a stump, a stone quench trough, a tool barrel and a lamp post
	do
		local g, at = group("Forge"), stationAt(-38, -26, -14, -10)
		local cool = Color3.fromRGB(200, 196, 230) -- keeps the brick lilac next to the fire glow
		skin(vox(g, "Apron", Vector3.new(28, 0.6, 18), at(2.5, 1.1, -3), PAL.stone[2]), "flagstone", 5, { N.Top, N.Front, N.Left, N.Right }, Color3.fromRGB(205, 200, 240))
		skin(vox(g, "Base", Vector3.new(16, 5, 7), at(0, 3.9, -8.5), PAL.stone[2]), "stonebrick", 5, SIDES, cool)
		for _, x in { -7.5, 7.5 } do skin(vox(g, "AlcoveWall", Vector3.new(1, 5, 5), at(x, 3.9, -2.5), PAL.stone[2]), "stonebrick", 5, SIDES, cool) end
		-- the upper floor sits over the back half only; the front is an open workshop under the roof, lit warm inside
		tvox(g, "Upper", Vector3.new(16, 5, 7), at(0, 8.9, -8.5), "plaster", 4)
		for _, x in { -8, -2.7, 2.7, 8 } do tvox(g, "Stud", Vector3.new(0.9, 5, 0.4), at(x, 8.9, -4.85), "beam", 4) end
		for _, y in { 6.7, 11.1 } do tvox(g, "Rail", Vector3.new(16.6, 0.7, 0.5), at(0, y, -4.8), "beam", 4) end
		for _, x in { -5.35, 0, 5.35 } do -- X-braces in each plaster panel
			for _, d in { -1, 1 } do tvox(g, "XBrace", Vector3.new(0.5, 5.2, 0.35), at(x, 8.9, -4.72) * CFrame.Angles(0, 0, d * 0.75), "beam", 2) end
		end
		for _, x in { -7.6, 7.6 } do tvox(g, "FrontPost", Vector3.new(1, 10, 1), at(x, 6.4, 1.4), "beam", 4) end
		tvox(g, "TieBeam", Vector3.new(16.8, 1, 1.2), at(0, 10.9, 1.4), "beam", 4)
		local wl = Instance.new("PointLight") -- warm light filling the workshop
		wl.Color, wl.Range, wl.Brightness = LAMP, 16, 1
		wl.Parent = g:FindFirstChild("TieBeam")
		-- the ridge runs along the facade like the reference; timber-framed gable ends left and right
		local function atG(x, y, z) return at(x, y, z - 5.7) end
		gables(g, atG, 7.6, 12.6, 11.4, "plaster")
		local peak = stepRoof(g, atG, 19, 15.4, 11.4, "shingle_teal")
		for _, s in { -1, 1 } do
			tvox(g, "GableTie", Vector3.new(0.5, 0.8, 13), at(s * 8.3, 11.8, -5.7), "beam", 4)
			tvox(g, "GablePost", Vector3.new(0.5, peak - 12.6, 0.7), at(s * 8.3, (peak + 11.4) / 2 - 0.6, -5.7), "beam", 4)
			for _, d in { -1, 1 } do tvox(g, "GableBrace", Vector3.new(0.5, 4.6, 0.5), at(s * 8.3, 14.2, -5.7 + d * 2.4) * CFrame.Angles(d * 0.8, 0, 0), "beam", 4) end
		end
		-- inside the alcove: a lit workbench and a tool rack on the back wall
		tvox(g, "Bench", Vector3.new(5, 0.6, 2), at(3.4, 3.8, -4), "planks", 2)
		for _, x in { 1.4, 5.4 } do tvox(g, "BenchLeg", Vector3.new(0.5, 2.4, 1.6), at(x, 2.6, -4), "beam", 2) end
		local bulb = vox(g, "AlcoveLamp", Vector3.new(0.8, 0.8, 0.8), at(3.4, 4.5, -4.4), LAMP, { CanCollide = false })
		glow(bulb, LAMP, 12, 0.9)
		tvox(g, "ToolRack", Vector3.new(6, 0.5, 0.5), at(-3, 5.4, -4.8), "beam", 2)
		for _, o in { { 2.4, -4 }, { 3.7, -3.7 } } do vox(g, "Ingot", Vector3.new(1.2, 0.45, 0.6), at(o[1], 4.33, o[2]), EMBER, { Material = Enum.Material.Neon, CanCollide = false }) end
		skin(vox(g, "YardWall", Vector3.new(1, 4.5, 7), at(-11, 3.65, 2), PAL.stone[2]), "stonebrick", 4, SIDES, cool) -- the yard's side wall behind the trough
		for k = 0, 3 do tvox(g, "HungTool", Vector3.new(0.3, 2, 0.3), at(-5.2 + k * 1.4, 4.2, -4.7), k % 2 == 0 and "iron" or "beam", 1) end
		-- a wide brick chimney on the right with a real firebox opening (4 wide, 3 tall, 2 deep) and a corbelled mantel
		local function brick(name, size, cf) return skin(vox(g, name, size, cf, PAL.stone[2]), "stonebrick", 5, SIDES, cool) end
		brick("ChimneyBack", Vector3.new(6, 7.6, 4), at(11.6, 5.2, -2))
		for _, x in { 9.1, 14.1 } do brick("Jamb", Vector3.new(1, 3, 2), at(x, 2.9, 1)) end
		brick("ChimneyTop", Vector3.new(6, 4.6, 2), at(11.6, 6.7, 1))
		tvox(g, "Mantel", Vector3.new(7, 0.8, 2.6), at(11.6, 4.8, 1.3), "beam", 2)
		brick("Corbel", Vector3.new(6.6, 0.8, 4.6), at(11.6, 9.4, -1))
		brick("Flue", Vector3.new(5, 8, 4.4), at(11.6, 13.8, -1.2))
		brick("Flue2", Vector3.new(3.8, 8, 3.8), at(11.6, 21.8, -1.4))
		brick("ChimneyCap", Vector3.new(4.6, 0.9, 4.6), at(11.6, 26.2, -1.4))
		vox(g, "Firebox", Vector3.new(4, 3, 0.3), at(11.6, 2.9, 0.15), Color3.fromRGB(40, 20, 34))
		vox(g, "Ash", Vector3.new(4, 0.3, 2), at(11.6, 1.55, 1), Color3.fromRGB(46, 36, 52))
		for k = 0, 2 do tvox(g, "FireLog", Vector3.new(3, 0.5, 0.5), at(11.6, 1.95, 0.6 + k * 0.5) * CFrame.Angles(0, (k - 1) * 0.3, 0), "logs", 1) end
		local mouth = vox(g, "Furnace", Vector3.new(2.4, 1.6, 0.6), at(11.6, 2.9, 0.8), EMBER, { CanCollide = false })
		glow(mouth, EMBER, 18, 1.6, true):SetAttribute("Flicker", 1)
		vox(g, "FurnaceCore", Vector3.new(1.2, 1, 0.4), at(11.6, 2.7, 1.2), GOLD, { CanCollide = false, Material = Enum.Material.Neon })
		local smoke = Instance.new("ParticleEmitter")
		smoke.Rate, smoke.Lifetime, smoke.Speed = 3, NumberRange.new(4, 6), NumberRange.new(2, 3)
		smoke.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.4), NumberSequenceKeypoint.new(1, 5) })
		smoke.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1) })
		smoke.Color, smoke.EmissionDirection = ColorSequence.new(Color3.fromRGB(180, 168, 210)), N.Top
		smoke.Parent = g:FindFirstChild("ChimneyCap")
		local sparkle = Instance.new("ParticleEmitter") -- sparks jumping out of the fire
		sparkle.Rate, sparkle.Lifetime, sparkle.Speed, sparkle.SpreadAngle = 5, NumberRange.new(0.6, 1.2), NumberRange.new(3, 6), Vector2.new(30, 30)
		sparkle.Color, sparkle.LightEmission, sparkle.EmissionDirection = ColorSequence.new(GOLD, EMBER), 1, N.Front
		sparkle.Acceleration = Vector3.new(0, -12, 0)
		sparkle.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(1, 0) })
		sparkle.Parent = mouth
		-- out front: anvil on a stump, stone quench trough, tool barrel, lamp post
		tvox(g, "Stump", Vector3.new(3, 2, 3), at(-1.5, 2.4, 3.6), "logs", 2)
		local anvil = tvox(g, "Anvil", Vector3.new(3.8, 1.3, 1.8), at(-1.5, 4.35, 3.6), "iron", 2)
		tvox(g, "AnvilHorn", Vector3.new(1.4, 0.8, 1), at(-4, 4.5, 3.6), "iron", 2)
		tvox(g, "AnvilWaist", Vector3.new(1.6, 0.6, 1.2), at(-1.5, 3.5, 3.6), "iron", 2)
		vox(g, "HotBar", Vector3.new(1.6, 0.25, 0.35), at(-0.9, 4.9, 3.6), EMBER, { Material = Enum.Material.Neon, CanCollide = false })
		tvox(g, "Hammer", Vector3.new(0.3, 0.3, 2), at(0.4, 4.95, 4) * CFrame.Angles(0, 0.6, 0), "beam", 2)
		barrel(g, at(-6.4, 1.4, 4.4).Position, 1.25) -- a tall banded quench barrel
		vox(g, "QuenchWater", Vector3.new(2, 0.2, 2), at(-6.4, 4.75, 4.4), Color3.fromRGB(110, 210, 230), { Material = Enum.Material.Glass, Transparency = 0.3 })
		barrel(g, at(5, 1.4, 4.2).Position, 0.9)
		for k = 0, 2 do tvox(g, "Tool", Vector3.new(0.3, 2.6, 0.3), at(4.7 + k * 0.4, 4.6, 4.2) * CFrame.Angles(0, 0, (k - 1) * 0.2), "beam", 2) end
		tvox(g, "LampPost", Vector3.new(0.8, 4, 0.8), at(-11, 7.9, 5), "beam", 2)
		cubeLantern(g, at(-11, 10.9, 5).Position)
		do -- the FORGE sign hangs under the eave between the windows
			local sp = at(0, 8.9, 1.5).Position
			sign(g, "FORGE", CFrame.new(sp), 4.6, 1.5, Color3.fromRGB(255, 190, 140))
			for _, dx in { -1.6, 1.6 } do vox(g, "SignChain", Vector3.new(0.15, 1.2, 0.15), CFrame.new(sp + Vector3.new(dx, 1.35, 0)), PAL.stone[1], { CanCollide = false }) end
		end
		prompt(anvil, "Upgrade", "Forge", "forge")
		local bolt = raccoon("Bolt", at(1.8, 1.4, 4.6))
		prompt(bolt:FindFirstChild("Body"), "Sell ore", "Bolt", "sell") -- playtest 2: sell at Bolt (pick stacks or SELECT ALL)
	end

	-- 5. Trophy hall (north-east; ref art/hub/pdv4_trophy_s61.jpg): a wide stone hall, stepped plum shingle roof, three horned
	-- skulls along the eave, an arched double door in a stone arch, pennant bunting, fire braziers and glowing gem pedestals
	do
		local g, at = group("TrophyHouse"), stationAt(36, -42, 18, -18, 4)
		tvox(g, "Apron", Vector3.new(26, 0.6, 19), at(0, 1.1, -3.5), "cobble", 4, nil, { N.Top, N.Front, N.Left, N.Right })
		tvox(g, "Hall", Vector3.new(22, 11, 13), at(0, 6.9, -6.5), "stonebrick", 5)
		gables(g, function(x, y, z) return at(x, y, z - 6.5) end, 10.6, 13, 12.4, "stonebrick")
		local peak = stepRoof(g, function(x, y, z) return at(x, y, z - 6.5) end, 24, 15.4, 12.4, "shingle_plum")
		for _, s in { -1, 1 } do -- buttress pillars at the corners
			tvox(g, "Buttress", Vector3.new(1.6, 11.6, 1.6), at(s * 11.2, 7.2, 0.2), "stonebrick", 3)
		end
		-- arched double door
		for _, s in { -1, 1 } do
			tvox(g, "Door", Vector3.new(2.5, 7, 0.4), at(s * 1.3, 4.9, 0.15), "planks", 2)
			vox(g, "DoorRing", Vector3.new(0.5, 0.5, 0.2), at(s * 0.6, 5, 0.45), GOLD, { Material = Enum.Material.Metal })
			tvox(g, "Jamb", Vector3.new(1.2, 7.2, 1.2), at(s * 3.2, 5, 0.3), "stonebrick", 2)
		end
		for k, w in { 4.8, 3.8, 2.2 } do tvox(g, "DoorArch", Vector3.new(w, 1, 0.4), at(0, 8.9 + (k - 1), 0.15), "planks", 2) end
		for k = 0, 6 do -- voussoir blocks round the arch
			local a = math.pi * k / 6
			tvox(g, "Voussoir", Vector3.new(1.3, 1.3, 1.3), at(math.cos(a) * 3.2, 8.4 + math.sin(a) * 3.2, 0.35) * CFrame.Angles(0, 0, a), "stonebrick", 2)
		end
		-- horned skulls: a big one on the portico gable, two smaller ones on the main eave turned outward
		local function skull(cf, s)
			local function P(name, size, x, y, z, c) vox(g, name, size * s, cf * CFrame.new(x * s, y * s, z * s), c, { CanCollide = false }) end
			P("Skull", Vector3.new(3.2, 1.8, 2.2), 0, 0.9, 0, PAL.cream[2])
			P("SkullFace", Vector3.new(2.6, 1.4, 1.8), 0, -0.6, 0.3, PAL.cream[2])
			P("SkullCheek", Vector3.new(2.1, 1, 1.6), 0, -1.7, 0.45, PAL.cream[2])
			P("Snout", Vector3.new(1.6, 1, 1.4), 0, -2.6, 0.6, PAL.cream[3])
			P("SnoutTip", Vector3.new(1.1, 0.6, 1.1), 0, -3.3, 0.7, PAL.cream[3])
			P("Brow", Vector3.new(3.4, 0.5, 0.4), 0, 0.3, 1.15, PAL.cream[3])
			for _, e in { -0.7, 0.7 } do P("Eye", Vector3.new(0.8, 0.85, 0.2), e, -0.35, 1.2, INK) end
			for _, e in { -0.28, 0.28 } do P("Nose", Vector3.new(0.3, 0.5, 0.2), e, -2.8, 1.3, INK) end
			for _, sd in { -1, 1 } do -- each horn sweeps out, curls up and hooks back in six blocks, thinning to a tip
				for k, h in { { 2.0, 1.3, 0, 1.2, 0.9 }, { 2.9, 1.6, -0.1, 1.0, 0.85 }, { 3.7, 2.2, -0.2, 0.85, 0.8 }, { 4.2, 3.0, -0.35, 0.7, 0.75 }, { 4.2, 3.9, -0.5, 0.55, 0.65 }, { 3.8, 4.6, -0.6, 0.45, 0.5 } } do
					P(k == 6 and "HornTip" or "Horn", Vector3.new(h[4] + 0.4, h[5], h[4] + 0.1), sd * h[1], h[2], h[3], k > 4 and PAL.cream[3] or (k > 2 and PAL.cream[2] or PAL.cream[1]))
				end
			end
		end
		-- the portico: two stone pillars and a small gabled roof projecting over the door
		for _, s in { -1, 1 } do tvox(g, "PorticoPillar", Vector3.new(1.3, 10.4, 1.3), at(s * 4.2, 6.6, 3.2), "stonebrick", 2) end
		local function atP(x, y, z) return at(0, 0, 1.1) * CFrame.Angles(0, math.pi / 2, 0) * CFrame.new(x, y, z) end
		stepRoof(g, atP, 5.6, 10, 11.8, "shingle_plum", 0.6)
		for i = 0, 6 do tvox(g, "PorticoGable", Vector3.new(9 - i * 1.2, 0.6, 0.6), at(0, 12.1 + i * 0.6, 3.6), "stonebrick", 2) end
		skull(at(0, 16.6, 3.8), 1.15)
		skull(at(-7.4, 13.8, 1.2) * CFrame.Angles(0, 0.35, 0), 0.95)
		skull(at(7.4, 13.8, 1.2) * CFrame.Angles(0, -0.35, 0), 0.95)
		-- long swallowtail banners with a pixel heart, hung from a rail across the facade
		tvox(g, "BannerRail", Vector3.new(20, 0.5, 0.5), at(0, 12, 0.5), "beam", 4)
		for i = 0, 22 do -- a swag of little rose and mint pennants under the eave
			local u = i / 22
			local x = -10.8 + u * 21.6
			if math.abs(x) > 4.8 then
				local y = 12.9 - math.sin(u * math.pi * 2 % math.pi) * 1.1
				vox(g, "Swag", Vector3.new(0.7, 0.8, 0.12), at(x, y - 0.4, 1.1), i % 2 == 0 and PAL.pink[2] or Color3.fromRGB(140, 216, 180), { CanCollide = false })
				vox(g, "SwagTip", Vector3.new(0.3, 0.3, 0.12), at(x, y - 0.95, 1.1), i % 2 == 0 and PAL.pink[2] or Color3.fromRGB(140, 216, 180), { CanCollide = false })
			end
		end
		for k, x in { -9.6, -5.4, 5.4, 9.6 } do
			local col = k % 2 == 1 and PAL.pink or PAL.lilac
			vox(g, "Banner", Vector3.new(1.8, 3.6, 0.15), at(x, 9.9, 0.6), col[2], { CanCollide = false })
			for _, d in { -0.55, 0.55 } do vox(g, "BannerTail", Vector3.new(0.7, 0.8, 0.15), at(x + d, 7.7, 0.6), col[2], { CanCollide = false }) end
			vox(g, "BannerHem", Vector3.new(1.86, 0.3, 0.17), at(x, 11.55, 0.62), col[1], { CanCollide = false })
			for _, px in { { -0.3, 0.3 }, { 0.3, 0.3 }, { -0.55, 0.05 }, { 0, 0.05 }, { 0.55, 0.05 }, { -0.3, -0.2 }, { 0.3, -0.2 }, { 0, -0.45 } } do
				vox(g, "Heart", Vector3.new(0.27, 0.27, 0.1), at(x + px[1] * 0.85, 10.2 + px[2] * 0.85, 0.71), PAL.cream[3], { CanCollide = false })
			end
		end
		for i, s in { -1, 1 } do
			-- fire braziers either side of the door
			tvox(g, "Brazier", Vector3.new(2, 3, 2), at(s * 5.2, 2.9, 2.2), "stonebrick", 2)
			tvox(g, "BrazierBowl", Vector3.new(2.6, 0.8, 2.6), at(s * 5.2, 4.8, 2.2), "iron", 2)
			local fl = vox(g, "BrazierFire", Vector3.new(1.4, 1.2, 1.4), at(s * 5.2, 5.7, 2.2), EMBER, { CanCollide = false })
			glow(fl, EMBER, 16, 1.2):SetAttribute("Flicker", 1)
			vox(g, "BrazierFlame", Vector3.new(0.8, 0.8, 0.8), at(s * 5.2, 6.6, 2.2), GOLD, { CanCollide = false, Material = Enum.Material.Neon })
			-- glowing gem pedestals further out
			tvox(g, "Pedestal", Vector3.new(1.8, 2.4, 1.8), at(s * 9, 2.6, 4), "stonebrick", 2)
			tvox(g, "PedestalTop", Vector3.new(2.2, 0.4, 2.2), at(s * 9, 4, 4), "stonebrick", 2)
			local gem = vox(g, "Gem", Vector3.new(1, 1.4, 1), at(s * 9, 5, 4) * CFrame.Angles(0, math.pi / 4, 0), i == 1 and PAL.pink[2] or Color3.fromRGB(140, 227, 192), { CanCollide = false, Material = Enum.Material.Neon })
			glow(gem, gem.Color, 10, 0.6)
			gem:SetAttribute("Bob", 0.2)
		end
		vox(g, "Rug", Vector3.new(3.4, 0.1, 2.2), at(0, 1.45, 1.6), PAL.pink[2])
		sign(g, "TROPHIES", CFrame.new(at(0, peak + 1.4, -6.5).Position), 7, 1.6, GOLD)
	end

	-- 6. Two log guest cabins (east and south-east; ref art/hub/pdv4_cabin_s62.jpg): round-log walls with notched log ends, a front
	-- gable with an attic window under a lower overhanging roof, a gabled porch roof, an outside fieldstone chimney, a barred
	-- window with a flower box. The first cabin has a moss roof and pink flowers, the second teal shingles and butter flowers.
	for n, spot in { { 48, -2, 20, 4 }, { 40, 26, 18, 14 } } do
		local g, at = group("GuestCabin" .. n), stationAt(spot[1], spot[2], spot[3], spot[4], 2)
		local roofTex = n == 1 and "moss_roof" or "shingle_teal"
		local logTint = Color3.fromRGB(214, 198, 204)
		tvox(g, "Porch", Vector3.new(14, 0.6, 4), at(0, 1.4, 1.6), "planks_light", 4)
		skin(vox(g, "Walls", Vector3.new(12, 7.2, 10), at(0, 4.7, -5), AVG.logs), "logs", 4.8, SIDES, logTint)
		for _, cx in { -6, 6 } do -- notched log ends: alternate rows poke out along x and along z
			for _, cz in { 0, -10 } do
				for k = 0, 5 do
					local alongX = k % 2 == 0
					local o = Vector3.new(alongX and cx + math.sign(cx) * 0.5 or cx, 1.7 + k * 1.2, alongX and cz or cz + (cz == 0 and 0.5 or -0.5))
					vox(g, "LogEnd", Vector3.new(alongX and 1.6 or 1.15, 1.05, alongX and 1.15 or 1.6), at(o.X, o.Y, o.Z), alongX and Color3.fromRGB(184, 142, 116) or Color3.fromRGB(160, 120, 100))
				end
			end
		end
		local function atR(x, y, z) return at(0, 0, -5.1) * CFrame.Angles(0, math.pi / 2, 0) * CFrame.new(x, y, z) end
		stepRoof(g, atR, 13.8, 15.6, 8.3, roofTex, 0.8, 1)
		for i = 0, 5 do skin(vox(g, "Gable", Vector3.new(12 - 2 * i, 0.8, 0.9), at(0, 8.7 + i * 0.8, 1.65), AVG.logs), "logs", 4.8, SIDES, logTint) end
		local attic = vox(g, "AtticWindow", Vector3.new(1.8, 1.8, 0.3), at(0, 11.2, 2.15), LAMP, { CanCollide = false })
		glow(attic, LAMP, 10, 0.6)
		vox(g, "AtticBar", Vector3.new(0.22, 1.8, 0.2), at(0, 11.2, 2.33), INK, { CanCollide = false })
		vox(g, "AtticBar", Vector3.new(1.8, 0.22, 0.2), at(0, 11.2, 2.33), INK, { CanCollide = false })
		for _, sd in { -1, 1 } do tvox(g, "Shutter", Vector3.new(0.7, 1.9, 0.25), at(sd * 1.35, 11.2, 2.3), "planks", 1) end
		local win = vox(g, "Window", Vector3.new(2.6, 2.2, 0.3), at(-3, 5.2, 0.05), LAMP, { CanCollide = false })
		glow(win, LAMP, 14, 0.9)
		vox(g, "WinBar", Vector3.new(0.25, 2.2, 0.2), at(-3, 5.2, 0.25), INK, { CanCollide = false })
		vox(g, "WinBar", Vector3.new(2.6, 0.25, 0.2), at(-3, 5.2, 0.25), INK, { CanCollide = false })
		tvox(g, "WinFrame", Vector3.new(3.2, 0.4, 0.5), at(-3, 6.45, 0.1), "beam", 2)
		tvox(g, "FlowerBox", Vector3.new(3.4, 0.8, 0.9), at(-3, 3.7, 0.5), "planks", 2)
		local flowers = n == 1 and { PAL.pink[2], PAL.pink[3], PAL.cream[3], PAL.pink[1] } or { GOLD, PAL.lilac[3], GOLD, PAL.lilac[2] }
		for k = 0, 3 do vox(g, "Flower", Vector3.new(0.6, 0.6, 0.6), at(-4.2 + k * 0.8, 4.4, 0.5), flowers[k + 1], { CanCollide = false }) end
		tvox(g, "Door", Vector3.new(2.4, 4.8, 0.3), at(2.6, 4.1, 0.05), "planks", 2)
		vox(g, "DoorKnob", Vector3.new(0.3, 0.3, 0.3), at(1.8, 4, 0.3), GOLD, { Material = Enum.Material.Metal })
		-- gabled porch roof over the door on two posts with knee braces, a lantern hanging under it
		local function atP(x, y, z) return at(2.6, 0, 2) * CFrame.Angles(0, math.pi / 2, 0) * CFrame.new(x, y, z) end
		stepRoof(g, atP, 4, 5.6, 7.2, roofTex, 0.5)
		for _, x in { 0.8, 4.4 } do -- knee braces from the wall carry the porch roof
			local a0, a1 = at(x, 5.2, 0.3).Position, at(x, 7.1, 2.6).Position
			tvox(g, "KneeBrace", Vector3.new(0.45, 0.45, (a1 - a0).Magnitude), CFrame.lookAt((a0 + a1) / 2, a1), "beam", 1)
		end
		vox(g, "Blanket", Vector3.new(1.3, 0.25, 1.1), at(-3.7, 2.97, 2.4), PAL.pink[2])
		tvox(g, "Stool", Vector3.new(1, 1, 1), at(-0.7, 2.2, 2.8), "logs", 1)
		cubeLantern(g, at(2.6, 5.9, 2.6).Position, 0.4, 0.7)
		-- outside fieldstone chimney on the far wall: a stepped base and a thick stack
		tvox(g, "ChimneyBase", Vector3.new(3.8, 6, 4.6), at(7.6, 4.1, -5), "stonebrick", 3)
		tvox(g, "ChimneyStep", Vector3.new(3.4, 0.8, 4), at(7.5, 7.5, -5), "stonebrick", 2)
		tvox(g, "Chimney", Vector3.new(3.2, 9, 3.2), at(7.4, 12.4, -5), "stonebrick", 3)
		local smoke = Instance.new("ParticleEmitter")
		smoke.Rate, smoke.Lifetime, smoke.Speed = 2, NumberRange.new(4, 6), NumberRange.new(1.5, 2.5)
		smoke.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 4) })
		smoke.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 1) })
		smoke.Color, smoke.EmissionDirection = ColorSequence.new(Color3.fromRGB(180, 168, 210)), N.Top
		smoke.Parent = g:FindFirstChild("Chimney")
		tvox(g, "Bench", Vector3.new(3.4, 0.5, 1.2), at(-3, 2.6, 2.4), "planks", 2)
		for _, x in { -4.4, -1.6 } do tvox(g, "BenchLeg", Vector3.new(0.4, 0.9, 1), at(x, 2, 2.4), "beam", 1) end
		for _, x in { -6.6, 6.6 } do tvox(g, "Rail", Vector3.new(0.4, 1.4, 3.6), at(x, 2.4, 1.6), "beam", 2) end
		if n == 1 then barrel(g, at(-7.8, 1.1, 2.4).Position, 0.8) else
			for k = 0, 3 do tvox(g, "Firewood", Vector3.new(0.8, 0.8, 3), at(-8 + (k % 2) * 0.85, 1.5 + math.floor(k / 2) * 0.8, -2), "logs", 2) end
		end
	end
	sign(model, "GUESTS SOON", CFrame.new(W(21, 3.2, 12)), 6, 1.6)
	tvox(model, "GuestSignPost", Vector3.new(0.6, 2.2, 0.6), CFrame.new(W(21, 1.5, 12)), "beam", 2)

	-- 7. Egg incubator (south-west; ref art/hub/pdv4_incubator_s61.jpg): a stone base, a warm timber frame with clear glass and a
	-- pitched glass roof, three big speckled eggs on twig nests, terracotta pots with succulents, two hanging lanterns
	do
		local g, at = group("Incubator"), stationAt(-34, 32, -10, 14)
		tvox(g, "Base", Vector3.new(15, 1.4, 13), at(0, 1.3, -5), "stonebrick", 4)
		skin(vox(g, "Plinth", Vector3.new(17, 0.8, 15), at(0, 1.0, -5), PAL.stone[3]), "stonebrick", 4, SIDES, Color3.fromRGB(235, 232, 250))
		for _, c in { { -7, 1 }, { 7, 1 }, { -7, -11 }, { 7, -11 }, { -2.3, 1 }, { 2.3, 1 }, { 0, -11 }, { -7, -5 }, { 7, -5 } } do
			tvox(g, "Frame", Vector3.new(0.8, 7.4, 0.8), at(c[1], 5.7, c[2]), "wood_frame", 4)
		end
		for _, z in { 1, -11 } do tvox(g, "Beam", Vector3.new(14.8, 0.7, 0.7), at(0, 9.6, z), "wood_frame", 4) end
		for _, x in { -7, 7 } do tvox(g, "Beam", Vector3.new(0.7, 0.7, 12.8), at(x, 9.6, -5), "wood_frame", 4) end
		tvox(g, "Ridge", Vector3.new(15.4, 0.8, 0.8), at(0, 13.2, -5), "wood_frame", 4)
		local glassProps = { Transparency = 1, CanCollide = false, CastShadow = false }
		for _, s in { -1, 1 } do -- pitched glass roof with rafters
			local cf = at(0, 11.4, -5 + s * 3.15) * CFrame.Angles(s * 0.62, 0, 0)
			skin(vox(g, "RoofGlass", Vector3.new(14.6, 0.2, 7.6), cf, AVG.glass, glassProps), "glass", 7, { N.Top, N.Bottom })
			for x = -7, 7, 3.5 do tvox(g, "Rafter", Vector3.new(0.5, 0.5, 7.8), cf * CFrame.new(x, 0.25, 0), "wood_frame", 2, { CanCollide = false }) end
		end
		for _, z in { 1, -11 } do skin(vox(g, "Glass", Vector3.new(13.8, 7.4, 0.2), at(0, 5.7, z), AVG.glass, glassProps), "glass", 7, { N.Front, N.Back }) end
		for _, x in { -7, 7 } do skin(vox(g, "Glass", Vector3.new(0.2, 7.4, 11.8), at(x, 5.7, -5), AVG.glass, glassProps), "glass", 7, { N.Left, N.Right }) end
		for _, s in { -1, 1 } do -- glass gables
			for i = 0, 5 do skin(vox(g, "GableGlass", Vector3.new(0.2, 0.6, 11.4 - i * 1.9), at(s * 7, 10.2 + i * 0.6, -5), AVG.glass, glassProps), "glass", 7, { N.Left, N.Right }) end
		end
		for _, x in { -4, 4 } do -- two lanterns hanging from the ridge on iron rods
			vox(g, "LampRod", Vector3.new(0.15, 2.6, 0.15), at(x, 11.7, -5), INK, { CanCollide = false })
			local l = cubeLantern(g, at(x, 9.6, -5).Position, nil, 0.8):FindFirstChildOfClass("PointLight")
			l.Brightness, l.Range = 1, 12
		end
		for i, ec in { Color3.fromRGB(247, 192, 204), Color3.fromRGB(255, 243, 186), Color3.fromRGB(196, 232, 204) } do
			local e = group("Egg" .. i)
			e.Parent = g
			local x, z = -4.2 + (i - 1) * 4.2, -5 + (i == 2 and -1.8 or 0.8)
			local nest = vox(g, "Nest", Vector3.new(3.6, 0.8, 3.6), at(x, 2.4, z), PAL.straw[2])
			local warm = Instance.new("PointLight")
			warm.Color, warm.Range, warm.Brightness = Color3.fromRGB(255, 224, 130), 6, 0.8
			warm.Parent = nest
			for k = 0, 9 do -- the flared outer rim of the nest
				local a = k / 10 * math.pi * 2 + 0.3
				tvox(g, "Twig", Vector3.new(1.8, 0.4, 0.4), at(x + math.cos(a) * 2.1, 3.4, z + math.sin(a) * 2.1) * CFrame.Angles(0, -a + math.pi / 2, 0.35), "logs", 1, { CanCollide = false })
			end
			for k = 0, 7 do -- a ring of twigs
				local a = k / 8 * math.pi * 2
				tvox(g, "Twig", Vector3.new(1.7, 0.45, 0.45), at(x + math.cos(a) * 1.7, 2.95 + (k % 2) * 0.2, z + math.sin(a) * 1.7) * CFrame.Angles(0, -a + math.pi / 2, (k % 2) * 0.25), "logs", 1, { CanCollide = false })
			end
			for k = 0, 3 do vox(g, "Straw", Vector3.new(1.2, 0.25, 0.25), at(x + (k - 1.5) * 0.6, 3.05, z + 1.4) * CFrame.Angles(0, k * 0.6, 0.3), PAL.straw[3], { CanCollide = false }) end
			for k, l in { { 2, 1.1 }, { 2.5, 1.0 }, { 2.7, 1.0 }, { 2.4, 1.0 }, { 1.8, 0.8 }, { 1, 0.6 } } do -- a round egg in six layers
				local y = 3.2 + (k - 1) * 0.92
				vox(e, k == 3 and "Mid" or "Layer", Vector3.new(l[1], l[2], l[1]), at(x, y, z), ec)
			end
			for k = 0, 4 do -- speckles
				vox(e, "Speck", Vector3.new(0.35, 0.35, 0.1), at(x + ((k % 3) - 1) * 0.6, 3.9 + k * 0.6, z + 1.36), ec:Lerp(INK, 0.3), { CanCollide = false })
			end
			local sp = Instance.new("ParticleEmitter") -- sparkles round each egg
			sp.Rate, sp.Lifetime, sp.Speed, sp.SpreadAngle = 2, NumberRange.new(0.8, 1.4), NumberRange.new(0.5, 1.2), Vector2.new(180, 180)
			sp.Color, sp.LightEmission = ColorSequence.new(ec:Lerp(Color3.new(1, 1, 1), 0.4)), 1
			sp.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0.4), NumberSequenceKeypoint.new(1, 0) })
			sp.Parent = e:FindFirstChild("Mid")
			e:SetAttribute("Bob", 0.25 + i * 0.05)
			if i == 2 then glow(e:FindFirstChild("Mid"), Color3.fromRGB(255, 200, 170), 14, 0.8) e:FindFirstChild("Mid").Material = Enum.Material.SmoothPlastic end
		end
		local clay = Color3.fromRGB(198, 107, 75)
		for k, p in { { -5.6, -9.6 }, { 5.6, -9.6 }, { -6, -0.2 }, { 5.8, -0.2 }, { 0, -10 } } do -- terracotta pots with succulents
			vox(g, "Pot", Vector3.new(1.4, 1.1, 1.4), at(p[1], 2.55, p[2]), clay)
			vox(g, "PotRim", Vector3.new(1.6, 0.3, 1.6), at(p[1], 3.2, p[2]), clay:Lerp(Color3.new(1, 1, 1), 0.15))
			for j = 0, 2 do vox(g, "Succulent", Vector3.new(0.6, 0.9, 0.6), at(p[1] + (j - 1) * 0.45, 3.7 + (j == 1 and 0.4 or 0), p[2]) * CFrame.Angles(0, 0, (j - 1) * 0.4), shadeOf("moss", j, k, 1), { CanCollide = false }) end
		end
		tvox(g, "DoorStep", Vector3.new(3.4, 0.6, 1.6), at(0, 0.9, 2.2), "stonebrick", 2)
		for k, x in { -6, -3.6, 3.6, 6 } do -- succulent pots along the front curb, outside the glass
			vox(g, "Pot", Vector3.new(1.1, 0.9, 1.1), at(x, 1.85, 2), clay)
			for j = 0, 2 do vox(g, "Succulent", Vector3.new(0.5, 0.8, 0.5), at(x + (j - 1) * 0.35, 2.6 + (j == 1 and 0.3 or 0), 2) * CFrame.Angles(0, 0, (j - 1) * 0.45), shadeOf("moss", j, k, 2), { CanCollide = false }) end
		end
		tvox(g, "SignPost", Vector3.new(0.5, 3.2, 0.5), at(3.8, 2.7, 3.4), "beam", 2)
		sign(g, "EGGS", CFrame.new(at(3.8, 4.8, 3.4).Position), 3.4, 1.3, PAL.pink[3])
		prompt(g:FindFirstChild("SignPost"), "Egg odds", "Incubator", "odds") -- the odds moved off the HUD rail (the user, 2026-11-08)
		prompt(g:FindFirstChild("Base"), "Hatch an egg", "Incubator", "hatch")
		villager("Maribel", at(-4.8, 1.1, 4.6), Color3.fromRGB(140, 227, 192), Color3.fromRGB(201, 184, 242))
	end

	-- 8. Quest notice board, treasure map and the daily relic chest (north, behind the shaft; ref art/hub/pdv4_notice_s61.jpg)
	do
		local g, at = group("NoticeBoard"), stationAt(6, -42, 6, 0, 4)
		tvox(g, "Apron", Vector3.new(24, 0.6, 12), at(0, 1.1, 0), "flagstone", 5, nil, { N.Top, N.Front, N.Left, N.Right })
		for _, s in { -1, 1 } do
			tvox(g, "Post", Vector3.new(1, 10, 1), at(s * 4.6, 5.4, 0), "beam", 4)
			tvox(g, "WingPost", Vector3.new(0.8, 9, 0.8), at(s * 8.7, 4.9, 2), "beam", 4)
		end
		tvox(g, "Board", Vector3.new(9, 5.6, 0.6), at(0, 6.4, 0.1), "planks", 4)
		local wingL = tvox(g, "Wing", Vector3.new(4.4, 5, 0.5), at(-6.7, 6, 1) * CFrame.Angles(0, 0.46, 0), "planks", 4)
		local wingR = tvox(g, "Wing", Vector3.new(4.4, 5, 0.5), at(6.7, 6, 1) * CFrame.Angles(0, -0.46, 0), "planks", 4)
		local function atN(x, y, z) return at(0, 0, 0.4) * CFrame.Angles(0, math.pi / 2, 0) * CFrame.new(x, y, z) end
		stepRoof(g, atN, 6.4, 19.6, 10.2, "shingle_plum", 0.8, 1) -- a steep storybook gable facing front
		sign(g, "QUESTS", CFrame.new(at(0, 14.2, 3.9).Position), 5, 1.3, PAL.cream[3], Color3.fromRGB(108, 191, 156))
		for k, pp in { { -0.8, 0.8, 1.4, 1.8 }, { 0.9, 0.4, 1.6, 1.6 }, { -0.2, -1.2, 1.8, 1.4 } } do -- notices on the right wing
			local cf = wingR.CFrame * CFrame.new(pp[1], pp[2], 0.3 + k * 0.01) * CFrame.Angles(0, 0, (hash(k, 4, 4) - 0.5) * 0.3)
			vox(g, "Paper", Vector3.new(pp[3], pp[4], 0.08), cf, PAL.cream[2]:Lerp(PAL.straw[3], 0.25), { CanCollide = false })
			vox(g, "Seal", Vector3.new(0.4, 0.4, 0.1), cf * CFrame.new(0, pp[4] / 2 - 0.3, 0.06), Color3.fromRGB(163, 40, 40), { CanCollide = false })
		end
		for i, pp in { { -3, 7.7, 1.8, 2 }, { -0.9, 7.3, 1.6, 2.2 }, { 1.4, 7.9, 1.6, 1.6 }, { 3.2, 6.8, 1.4, 2 }, { -2.6, 5.1, 2, 1.6 }, { 0.5, 5.3, 1.8, 1.8 }, { 2.7, 4.9, 1.6, 1.4 }, { -1.4, 6.2, 1.2, 1.4 } } do
			local cf = at(pp[1], pp[2], 0.42 + i * 0.012) * CFrame.Angles(0, 0, (hash(i, 1, 1) - 0.5) * 0.28)
			vox(g, "Paper", Vector3.new(pp[3], pp[4], 0.08), cf, PAL.cream[(i % 2) + 2]:Lerp(PAL.straw[3], 0.25), { CanCollide = false })
			vox(g, "Seal", Vector3.new(0.4, 0.4, 0.1), cf * CFrame.new(0, pp[4] / 2 - 0.3, 0.06), Color3.fromRGB(163, 40, 40), { CanCollide = false })
			if i % 2 == 1 then vox(g, "DogEar", Vector3.new(0.45, 0.45, 0.1), cf * CFrame.new(pp[3] / 2 - 0.22, -pp[4] / 2 + 0.22, 0.05), PAL.straw[2], { CanCollide = false }) end
			if i % 3 == 0 then -- a little ink sketch (a pick or a skull) on some notices
				vox(g, "Sketch", Vector3.new(0.7, 0.18, 0.05), cf * CFrame.new(0, 0.1, 0.06) * CFrame.Angles(0, 0, 0.6), INK, { CanCollide = false })
				vox(g, "Sketch", Vector3.new(0.18, 0.9, 0.05), cf * CFrame.new(0.1, -0.15, 0.06) * CFrame.Angles(0, 0, -0.6), INK, { CanCollide = false })
			else
				for l = 1, 2 do vox(g, "Line", Vector3.new(pp[3] * 0.6, 0.12, 0.05), cf * CFrame.new(0, 0.2 - l * 0.4, 0.06), INK:Lerp(PAL.cream[1], 0.4), { CanCollide = false }) end
			end
		end
		cubeLantern(g, at(8.7, 8.1, 2.6).Position, 0.4, 0.8)
		-- the relic chest: a domed gold-banded lid with light leaking from the seam
		local gold, deep = Color3.fromRGB(229, 178, 56), Color3.fromRGB(156, 109, 31)
		-- the relic chest stands about 7 studs right of the spawn (crates stand at 9 to 11), facing it, so it no longer blocks the QUESTS board (playtest 2)
		local gC = group("DailyChest")
		local atC = stationAt(7, 14.5, 0, 16, groundTop(7, 14.5))
		local chest = tvox(gC, "Chest", Vector3.new(3.8, 2.2, 2.6), atC(0, 2.5 - 0.3, 3.8 - 3.8), "planks_light", 2)
		tvox(gC, "ChestLid", Vector3.new(3.9, 0.6, 2.7), atC(0, 3.9 - 0.3, 3.8 - 3.8), "planks_light", 2)
		tvox(gC, "ChestLid2", Vector3.new(3.9, 0.5, 2.1), atC(0, 4.45 - 0.3, 3.8 - 3.8), "planks_light", 2)
		tvox(gC, "ChestLid3", Vector3.new(3.9, 0.4, 1.3), atC(0, 4.9 - 0.3, 3.8 - 3.8), "planks_light", 2)
		for _, cx in { -1.75, 1.75 } do for _, cz in { -1.15, 1.15 } do vox(gC, "ChestCorner", Vector3.new(0.5, 2.3, 0.5), atC(cx, 2.5 - 0.3, 3.8 + cz - 3.8), deep, { Material = Enum.Material.Metal }) end end
		vox(gC, "ChestTrim", Vector3.new(4, 0.3, 2.8), atC(0, 3.62 - 0.3, 3.8 - 3.8), gold, { Material = Enum.Material.Metal })
		for _, x in { -1.6, 0, 1.6 } do
			vox(gC, "ChestBand", Vector3.new(0.45, 3.7, 2.8), atC(x, 3.25 - 0.3, 3.8 - 3.8), gold, { Material = Enum.Material.Metal })
		end
		local seam = vox(gC, "ChestSeam", Vector3.new(3.85, 0.12, 2.65), atC(0, 3.82 - 0.3, 3.8 - 3.8), Color3.fromRGB(255, 230, 130), { CanCollide = false })
		glow(seam, Color3.fromRGB(255, 230, 130), 10, 1.6)
		vox(gC, "ChestLock", Vector3.new(0.9, 1, 0.2), atC(0, 3.3 - 0.3, 5.15 - 3.8), gold, { Material = Enum.Material.Metal })
		vox(gC, "Keyhole", Vector3.new(0.22, 0.45, 0.1), atC(0, 3.25 - 0.3, 5.27 - 3.8), INK, { CanCollide = false })
		local shine = Instance.new("ParticleEmitter")
		shine.Rate, shine.Lifetime, shine.Speed, shine.SpreadAngle = 5, NumberRange.new(0.8, 1.6), NumberRange.new(0.6, 1.4), Vector2.new(70, 70)
		shine.Color, shine.LightEmission, shine.EmissionDirection = ColorSequence.new(GOLD), 1, N.Top
		shine.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0.4), NumberSequenceKeypoint.new(1, 0) })
		shine.Parent = seam
		prompt(chest, "Open", "Daily relic chest", "chest")
		-- a parchment treasure map on the left wing: a dotted trail down the seven layers to an X
		local map = wingL
		local paper = vox(g, "MapPaper", Vector3.new(3.8, 4, 0.1), wingL.CFrame * CFrame.new(0, 0, 0.3), Color3.fromRGB(240, 222, 186), { CanCollide = false })
		for k = 0, 9 do
			local u = k / 9
			vox(g, "Trail", Vector3.new(0.28, 0.28, 0.06), paper.CFrame * CFrame.new(math.sin(u * 7) * 1.2, 1.6 - u * 3.2, 0.07), Color3.fromRGB(150, 70, 60), { CanCollide = false })
		end
		for _, a in { math.pi / 4, -math.pi / 4 } do vox(g, "MapX", Vector3.new(0.9, 0.22, 0.06), paper.CFrame * CFrame.new(math.sin(7) * 1.2, -1.7, 0.08) * CFrame.Angles(0, 0, a), Color3.fromRGB(200, 40, 50), { CanCollide = false }) end
		prompt(map, "Look at the map", "Map", "map")
	end

	-- 9. Campfire (south, near the spawn; ref art/hub/pdv4_campfire_s62.jpg): a flagstone patio with a stone kerb, a fire ring,
	-- criss-crossed logs and a teepee, a three-pole tripod with a kettle, log benches with a blanket, a kindling stack
	local fire = W(12, 0, 40)
	do
		local g = group("Campfire")
		for z = -9, 7, 2 do -- the round flagstone patio in strips
			local half = math.sqrt(math.max(0, 81 - (z + 1) ^ 2))
			if half > 1 then skin(vox(g, "Patio", Vector3.new(half * 2, 0.4, 2), CFrame.new(fire + Vector3.new(0, 1.05, z + 1)), AVG.path), "flagstone", 5, { N.Top, N.Front, N.Back, N.Left, N.Right }) end
		end
		for i = 0, 23 do
			local a = i / 24 * math.pi * 2
			tvox(g, "Kerb", Vector3.new(2.3, 1, 1.1), CFrame.new(fire + Vector3.new(math.cos(a) * 9.2, 1.3, math.sin(a) * 9.2)) * CFrame.Angles(0, -a + math.pi / 2, 0), "stonebrick", 2)
		end
		for i = 0, 11 do
			local a = i / 12 * math.pi * 2
			tvox(g, "Stone", Vector3.new(1.5, 1, 1.5), CFrame.new(fire + Vector3.new(math.cos(a) * 2.8, 1.6, math.sin(a) * 2.8)) * CFrame.Angles(0, a, 0), "stonebrick", 2)
		end
		vox(g, "AshBed", Vector3.new(4.4, 0.2, 4.4), CFrame.new(fire + Vector3.new(0, 1.32, 0)), Color3.fromRGB(46, 36, 52))
		for k = 0, 7 do -- split logs laid round the fire, end grain showing, and glowing coals between them
			local a = k / 8 * math.pi * 2 + 0.2
			local cf = CFrame.lookAt(fire + Vector3.new(math.cos(a) * 1.7, 1.55, math.sin(a) * 1.7), fire + Vector3.new(math.cos(a) * 3, 1.55, math.sin(a) * 3))
			tvox(g, "SplitLog", Vector3.new(0.7, 0.6, 2.4), cf, "logs", 1)
			vox(g, "EndGrain", Vector3.new(0.6, 0.5, 0.1), cf * CFrame.new(0, 0, -1.22), Color3.fromRGB(238, 214, 176), { CanCollide = false })
			vox(g, "Coal", Vector3.new(0.45, 0.3, 0.45), CFrame.new(fire + Vector3.new(math.cos(a + 0.4) * 1.1, 1.5, math.sin(a + 0.4) * 1.1)), k % 2 == 0 and EMBER or Color3.fromRGB(255, 122, 0), { CanCollide = false, Material = Enum.Material.Neon })
		end
		for i = 0, 5 do -- criss-crossed charred logs
			local a = i / 6 * math.pi
			tvox(g, "BaseLog", Vector3.new(0.7, 0.7, 3.8), CFrame.new(fire + Vector3.new(0, 1.6 + (i % 2) * 0.4, 0)) * CFrame.Angles(0, a, 0), "logs", 2)
		end
		for i = 0, 4 do
			local a = i / 5 * math.pi * 2 + 0.4
			tvox(g, "Log", Vector3.new(0.7, 3.6, 0.7), CFrame.new(fire + Vector3.new(math.cos(a) * 0.8, 2.6, math.sin(a) * 0.8)) * CFrame.Angles(math.sin(a) * 0.45, 0, -math.cos(a) * 0.45), "logs", 2)
		end
		for i = 0, 5 do
			local a = i / 6 * math.pi * 2
			vox(g, "Ember", Vector3.new(0.4, 0.25, 0.4), CFrame.new(fire + Vector3.new(math.cos(a) * 1.6, 1.4, math.sin(a) * 1.6)), EMBER, { CanCollide = false, Material = Enum.Material.Neon })
		end
		local flames = group("Flames")
		flames.Parent = g
		for i, f in { { 0, 2.8, 0, 2.2, EMBER }, { 0.35, 4.1, 0.2, 1.5, GOLD }, { -0.25, 5.2, -0.1, 0.9, Color3.fromRGB(255, 240, 190) }, { 0.9, 2.5, 0.6, 1, Color3.fromRGB(255, 122, 0) }, { -0.9, 2.6, -0.6, 1, GOLD } } do
			local p = vox(flames, "Flame", Vector3.new(f[4], f[4], f[4]), CFrame.new(fire + Vector3.new(f[1], f[2], f[3])) * CFrame.Angles(0, i * 0.4, 0), f[5], { CanCollide = false, Material = Enum.Material.Neon })
			if i == 1 then glow(p, Color3.fromRGB(255, 160, 60), 22, 2.5, true):SetAttribute("Flicker", 1) end
		end
		flames:SetAttribute("Flames", true)
		local em = Instance.new("ParticleEmitter")
		em.Rate, em.Lifetime, em.Speed, em.SpreadAngle = 6, NumberRange.new(1, 2), NumberRange.new(2, 4), Vector2.new(20, 20)
		em.Color, em.LightEmission, em.EmissionDirection = ColorSequence.new(GOLD, EMBER), 1, N.Top
		em.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(1, 0) })
		em.Parent = flames:FindFirstChild("Flame")
		local plume = Instance.new("ParticleEmitter") -- a lazy lilac smoke plume
		plume.Rate, plume.Lifetime, plume.Speed, plume.SpreadAngle = 2, NumberRange.new(4, 6), NumberRange.new(1.5, 2.5), Vector2.new(8, 8)
		plume.Color, plume.EmissionDirection = ColorSequence.new(Color3.fromRGB(176, 168, 185)), N.Top
		plume.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 4) })
		plume.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 1) })
		plume.Parent = flames:FindFirstChild("Flame")
		local apex = fire + Vector3.new(0, 9.4, 0)
		for k = 0, 2 do -- the tripod: three poles lashed together over the fire, a kettle on a chain
			local a = k / 3 * math.pi * 2 + 0.5
			local foot = fire + Vector3.new(math.cos(a) * 4.2, 1.2, math.sin(a) * 4.2)
			tvox(g, "Pole", Vector3.new(0.5, 0.5, (apex - foot).Magnitude + 0.6), CFrame.lookAt((foot + apex) / 2, apex), "beam", 2)
		end
		vox(g, "Lashing", Vector3.new(0.9, 0.7, 0.9), CFrame.new(apex), PAL.cream[1])
		for k = 0, 2 do vox(g, "ChainLink", Vector3.new(0.3, 0.5, 0.3), CFrame.new(apex - Vector3.new(0, 0.6 + k * 0.5, 0)) * CFrame.Angles(0, k * math.pi / 2, 0), INK, { CanCollide = false }) end
		for _, l in { { 1.6, 0.4, 6.4 }, { 2.4, 0.9, 7 }, { 2.1, 0.4, 7.6 } } do -- a rounded cauldron in three layers
			vox(g, "Cauldron", Vector3.new(l[1], l[2], l[1]), CFrame.new(fire + Vector3.new(0, l[3], 0)), Color3.fromRGB(43, 43, 46), { Material = Enum.Material.Metal })
		end
		vox(g, "CauldronRim", Vector3.new(2.5, 0.3, 2.5), CFrame.new(fire + Vector3.new(0, 7.85, 0)), Color3.fromRGB(70, 66, 80), { Material = Enum.Material.Metal })
		vox(g, "Stew", Vector3.new(1.9, 0.1, 1.9), CFrame.new(fire + Vector3.new(0, 7.9, 0)), Color3.fromRGB(196, 120, 80), { CanCollide = false })
		for _, b in { { -7.6, 0, 0, 90 }, { 7.6, 0, 0, 90 }, { 0, 0, -7.6, 0 } } do
			tvox(g, "Bench", Vector3.new(4.6, 1.2, 1.3), CFrame.new(fire + Vector3.new(b[1], 1.85, b[3])) * CFrame.Angles(0, math.rad(b[4]), 0), "logs", 2)
		end
		vox(g, "Blanket", Vector3.new(2, 0.3, 1.5), CFrame.new(fire + Vector3.new(0.6, 2.6, -7.6)), PAL.pink[2])
		tvox(g, "Mug", Vector3.new(0.5, 0.6, 0.5), CFrame.new(fire + Vector3.new(-7.6, 2.75, 1.2)), "iron", 1)
		vox(g, "BlanketStripe", Vector3.new(2.02, 0.32, 0.3), CFrame.new(fire + Vector3.new(0.6, 2.6, -7.2)), PAL.cream[3])
		for k = 0, 5 do tvox(g, "Kindling", Vector3.new(3, 0.8, 0.8), CFrame.new(fire + Vector3.new(5.4, 1.65 + math.floor(k / 3) * 0.8, 4.4 + (k % 3) * 0.85 - math.floor(k / 3) * 0.4)), "logs", 2) end
	end

	-- 10. Friends bench (south-west)
	do
		local g = group("FriendsBench")
		local p = W(30, 0, 52)
		tvox(g, "Seat", Vector3.new(6, 0.6, 1.8), CFrame.new(p + Vector3.new(0, 2.1, 0)), "planks_light", 2)
		tvox(g, "Back", Vector3.new(6, 1.8, 0.5), CFrame.new(p + Vector3.new(0, 3.1, 0.9)), "planks", 2)
		for _, s in { -1, 1 } do tvox(g, "Leg", Vector3.new(0.5, 1.4, 1.6), CFrame.new(p + Vector3.new(s * 2.5, 1.3, 0)), "beam", 1) end
		sign(g, "FRIENDS", CFrame.new(p + Vector3.new(0, 5, 1.2)), 4.6, 1.2, PAL.pink[3])
	end

	-- 11. Lamp posts along the lanes, at the stair top and by the bridges
	local posts = group("LanternPosts")
	for _, l in { { -20, -2 }, { -22, -21 }, { 1.5, -30 }, { 10.5, -30 }, { 20, -33 }, { 19, 10 }, { 32, 10 }, { -15, 9 }, { -23, 17 }, { 11, 27 }, { -5, 39 }, { -20, 30 }, { 40, 6 } } do
		local y = groundTop(l[1], l[2])
		local p = W(l[1], y, l[2])
		tvox(posts, "Post", Vector3.new(0.9, 8, 0.9), CFrame.new(p + Vector3.new(0, 4, 0)), "beam", 4)
		tvox(posts, "Arm", Vector3.new(2.4, 0.5, 0.5), CFrame.new(p + Vector3.new(1, 8, 0)), "beam", 2)
		cubeLantern(posts, p + Vector3.new(2, 6.4, 0), 0.6)
	end

	-- 12. The World Tree: a huge trunk behind the camp (north) and roots that wall the plaza and arch overhead (twice the v3 size)
	local tree = group("WorldTree")
	local tubes = {}
	local K, KR = 1.72, 1.8 -- position and radius scale against v3
	for _, s in { -1, 1 } do
		local function T(p0, p1, p2, p3, r0, r1)
			table.insert(tubes, { W(p0[1] * s * K, p0[2] * K, p0[3] * K), W(p1[1] * s * K, p1[2] * K, p1[3] * K), W(p2[1] * s * K, p2[2] * K, p2[3] * K), W(p3[1] * s * K, p3[2] * K, p3[3] * K), r0 * KR, r1 * KR })
		end
		T({ 8, 24, -62 }, { 34, 30, -50 }, { 46, 14, -16 }, { 38, -1, 18 }, 7, 3.6) -- the big wall roots, west and east
		T({ 6, 12, -60 }, { 26, 12, -44 }, { 36, 6, -30 }, { 30, -1, -20 }, 5.6, 3)
		T({ 46, 10, -18 }, { 54, 8, 4 }, { 48, 5, 24 }, { 32, -1, 34 }, 3.4, 1.8) -- curling round the south-west and south-east corners
		T({ 10, 40, -60 }, { 22, 46, -34 }, { 30, 38, -16 }, { 40, 12, -4 }, 3.6, 2) -- arches over the back half of the plaza
		T({ 0, 44, -58 }, { 8, 50, -30 }, { 20, 40, -8 }, { 34, 20, 6 }, 2.8, 1.6)
	end
	-- v4 canopy: a great arch over the plaza, two crossing arches toward the trunk and low roots that close the bowl
	table.insert(tubes, { W(-96, -2, -10), W(-70, 120, -30), W(70, 120, -30), W(96, -2, -10), 8, 8 })
	table.insert(tubes, { W(-90, -2, 40), W(-60, 100, 10), W(40, 110, -70), W(30, 60, -120), 6, 5 })
	table.insert(tubes, { W(90, -2, 40), W(60, 100, 10), W(-40, 110, -70), W(-30, 60, -120), 6, 5 })
	for _, s in { -1, 1 } do
		table.insert(tubes, { W(s * 30, 30, -110), W(s * 70, 20, -90), W(s * 92, 10, -40), W(s * 84, -1, 10), 7, 4 })
		table.insert(tubes, { W(s * 92, 26, -6), W(s * 98, 18, 30), W(s * 80, 8, 56), W(s * 50, -1, 72), 5, 3 })
	end
	table.insert(tubes, { W(-52, 66, -34), W(-21, 90, -45), W(21, 90, -45), W(52, 66, -34), 5, 5 }) -- the crown arch across the north
	table.insert(tubes, { W(0, -2, -128), W(0, 60, -128), W(0, 140, -128), W(0, 220, -132), 24, 16 }) -- the trunk
	for _, b in { -110, -80, -50, -20, 20, 50, 80, 110 } do -- great roots buttressing the hollow wall, from its top down to the ground
		local a = math.rad(b)
		local function P(r, y) return W(math.sin(a) * r, y, -math.cos(a) * r) end
		table.insert(tubes, { P(100, 84), P(94, 60), P(86, 24), P(74, -1), 6.5, 3.6 })
	end
	rootSweep(tree, tubes, 6)
	for ti, t in tubes do -- flowering vines hanging from the lower roots
		for k = 1, 9 do
			local u = k / 10
			local a = 1 - u
			local c = t[1] * a ^ 3 + t[2] * 3 * a ^ 2 * u + t[3] * 3 * a * u ^ 2 + t[4] * u ^ 3
			local yy = c.Y - O.Y
			if yy > 14 and yy < 50 and hash(ti, k, 5) > 0.55 then
				local r = t[5] + (t[6] - t[5]) * u
				local len = 3 + math.floor(hash(ti, k, 6) * 4)
				for j = 0, len - 1 do
					vox(tree, "Vine", Vector3.new(0.9, 1, 0.9), CFrame.new(c - Vector3.new(0, r * 0.8 + 0.5 + j, 0)) * CFrame.Angles(0, j * 0.5, 0), shadeOf("moss", ti, j, k), { CanCollide = false })
				end
				vox(tree, "VineFlower", Vector3.new(1, 1, 1), CFrame.new(c - Vector3.new(0, r * 0.8 + len + 0.3, 0)), hash(ti, k, 7) > 0.5 and PAL.pink[2] or PAL.lilac[3], { CanCollide = false })
			end
		end
	end
	for _, c in { W(-38, 92, -62), W(38, 92, -62), W(0, 214, -132), W(-30, 206, -124), W(30, 198, -136), W(-66, 70, -24), W(66, 70, -24), W(0, 98, -50), W(-20, 180, -110), W(22, 170, -116) } do
		leafClump(tree, c, 3, 4.8)
	end
	stringLights(tree, W(-62, 46, -18), W(62, 46, -18), 10, 34)
	stringLights(tree, W(-52, 34, 18), W(-14, 60, -36), 7, 14)
	stringLights(tree, W(52, 34, 18), W(14, 60, -36), 7, 14)
	for i, p in { W(-58, 24, -4), W(58, 24, -4), W(-34, 52, -48), W(34, 52, -48), W(-68, 14, 34), W(68, 14, 34), W(-20, 44, -20), W(20, 44, -20) } do -- lanterns hanging from the roots
		cubeLantern(tree, p, 2 + (i % 3) * 3, 1.3)
	end
	local flies = Instance.new("ParticleEmitter") -- fireflies drifting round the canopy and the plaza
	flies.Rate, flies.Lifetime, flies.Speed, flies.SpreadAngle = 14, NumberRange.new(4, 7), NumberRange.new(0.5, 1.5), Vector2.new(180, 180)
	flies.Color, flies.LightEmission = ColorSequence.new(Color3.fromRGB(198, 247, 226), GOLD), 1
	flies.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.2, 0.45), NumberSequenceKeypoint.new(1, 0) })
	local flyBox = vox(tree, "Fireflies", Vector3.new(170, 50, 130), CFrame.new(W(0, 30, -20)), Color3.new(), { Transparency = 1, CanCollide = false, CanQuery = false })
	flies.Shape, flies.Parent = Enum.ParticleEmitterShape.Box, flyBox

	-- 12b. The Hollow Mountain: a stepped rock wall round the camp, lower toward the south where the camera looks in
	local hollow = group("HollowWall")
	for i = 0, 95 do
		local a = i / 96 * math.pi * 2
		local south = math.cos(a - math.pi / 2) -- 1 = due south (+z), the camera side
		if south < 0.55 then
			local rr = 92 + hash(i, 1, 2) * 10
			local p = W(math.cos(a) * rr, 0, math.sin(a) * rr)
			local h = (84 + hash(i, 3, 4) * 30) * (1 - math.max(south, 0) * 1.1)
			local look = CFrame.lookAt(p, W(0, 0, 0))
			local y = 0
			for band = 1, 3 do
				local bh = h / 3 + (band == 3 and hash(i, band, 9) * 8 or 0)
				skin(vox(hollow, "Rock", Vector3.new(7.4, bh, 9 + band * 2.4), look * CFrame.new(0, y + bh / 2, -band * 1.1 + 2), PAL.rock[((i + band) % 3) + 1]), "rockface", 8, { N.Front, N.Top }, PAL.rock[((i + band) % 3) + 1]:Lerp(Color3.new(1, 1, 1), 0.6))
				y += bh
			end
			if hash(i, 7, 7) > 0.55 then -- a mossy ledge or a glowing crystal on the wall face
				local ledge = vox(hollow, "Ledge", Vector3.new(6, 1.4, 3), look * CFrame.new(0, h * (0.25 + hash(i, 8, 8) * 0.45), -5.6), PAL.grass[2])
				if hash(i, 9, 9) > 0.55 then
					local tint = hash(i, 5, 5) > 0.5 and Color3.fromRGB(120, 210, 220) or Color3.fromRGB(190, 160, 240)
					local cr = vox(hollow, "WallCrystal", Vector3.new(1.2, 4, 1.2), ledge.CFrame * CFrame.new(0, 2.4, 0) * CFrame.Angles(0.2, 0, 0.3), tint, { CanCollide = false, Material = Enum.Material.Neon })
					if i % 3 == 0 then glow(cr, tint, 18, 0.6) end
				end
			end
		end
	end
	do -- the rear cliff behind the notice board: a stepped rock pillar with a zigzag stairway up to a glowing gate
		local c = group("RearCliff")
		local function rock(size, pos, band) skin(vox(c, "Cliff", size, CFrame.new(W(pos.X, pos.Y, pos.Z)), PAL.rock[band]), "rockface", 8, SIDES, PAL.rock[band]:Lerp(Color3.new(1, 1, 1), 0.6)) end
		rock(Vector3.new(34, 22, 16), Vector3.new(0, 11, -92), 2)
		rock(Vector3.new(30, 22, 12), Vector3.new(0, 33, -96), 3)
		rock(Vector3.new(22, 12, 10), Vector3.new(-2, 50, -98), 1)
		for k = 0, 11 do -- first flight along the front face, then the second flight on the ledge above
			local h1 = (k + 1) * 1.8
			skin(vox(c, "Step", Vector3.new(2.2, h1, 4), CFrame.new(W(-12 + k * 2.2, h1 / 2, -82)), PAL.stone[2]), "stonebrick", 3)
			local h2 = (k + 1) * 1.8
			skin(vox(c, "Step", Vector3.new(2.2, h2, 4), CFrame.new(W(12 - k * 2.2, 22 + h2 / 2, -88)), PAL.stone[2]), "stonebrick", 3)
		end
		local gate = vox(c, "Gate", Vector3.new(5, 7, 0.6), CFrame.new(W(-13, 47.5, -90.4)), CYAN, { CanCollide = false })
		glow(gate, CYAN, 26, 1.4)
		for _, x in { -16, -10 } do skin(vox(c, "GatePillar", Vector3.new(1.4, 9, 1.4), CFrame.new(W(x, 48.5, -90)), PAL.stone[2]), "stonebrick", 3) end
		skin(vox(c, "GateLintel", Vector3.new(7.6, 1.4, 1.6), CFrame.new(W(-13, 53.6, -90)), PAL.stone[2]), "stonebrick", 3)
		for _, p in { W(-12, 6, -79.6), W(13, 24, -79.6), W(13, 28, -85.6), W(-12, 46, -85.6) } do cubeLantern(c, p, nil, 1.2) end
	end
	vox(hollow, "FarGround", Vector3.new(640, 6, 640), CFrame.new(W(0, -14, 0)), PAL.rock[1], { CanCollide = false }) -- under the pit floor, so the shaft stays open

	-- 13. Props that make the camp feel lived in: an ore cart on rails, barrels, crate stacks, bushes, glowing mushrooms
	local props = group("Props")
	for i = 0, 11 do -- rails from the shaft rim toward the sell stall
		tvox(props, "Sleeper", Vector3.new(0.7, 0.3, 3), CFrame.new(W(-9 - i * 1.6, 1.2, 2)), "beam", 2)
	end
	for _, z in { 1, 3 } do tvox(props, "Rail", Vector3.new(19, 0.3, 0.35), CFrame.new(W(-17.8, 1.45, z)), "iron", 2) end
	tvox(props, "Cart", Vector3.new(3.4, 2, 2.6), CFrame.new(W(-15, 2.7, 2)), "planks", 2)
	for _, w in { { -16.2, 0.6 }, { -13.8, 0.6 }, { -16.2, 3.4 }, { -13.8, 3.4 } } do tvox(props, "Wheel", Vector3.new(1, 1, 0.3), CFrame.new(W(w[1], 1.9, w[2])), "iron", 1) end
	for k = 0, 4 do vox(props, "CartOre", Vector3.new(0.8, 0.8, 0.8), CFrame.new(W(-16 + k * 0.5, 3.9 + (k % 2) * 0.3, 1.6 + (k % 3) * 0.4)), ORE[k % 3 + 1], { Material = k == 2 and Enum.Material.Neon or Enum.Material.SmoothPlastic }) end
	for _, p in { W(-12, 0.6, -14), W(-13.6, 0.6, -12), W(14, 0.6, -10), W(-26, 0.6, 10), W(26, 0.6, -6) } do barrel(props, p) end
	for _, c in { { 13, 15 }, { -15, -15 }, { 24, -20 }, { -30, -6 } } do
		for k = 0, 2 do tvox(props, "Crate", Vector3.new(2.2, 2.2, 2.2), CFrame.new(W(c[1] + (k % 2) * 2.3, 1.7 + math.floor(k / 2) * 2.2, c[2])) * CFrame.Angles(0, k * 0.2, 0), "wood_frame", 2) end
	end
	-- mining clutter clusters in the grass gaps between the lanes (Gemini town v5 r1: "fill the dead grass voids"): ore sacks,
	-- crate and barrel piles, a tool rack, a pickaxe in a stump, a wheelbarrow of ore. Spots found free with an overlap scan.
	local SACK = Color3.fromRGB(214, 190, 160)
	local function cluster(x, z, kind, seed)
		local y = groundTop(x, z)
		local base = CFrame.new(W(x, y, z)) * CFrame.Angles(0, seed, 0)
		local function at(dx, dy, dz) return base * CFrame.new(dx, dy, dz) end
		if kind == "sacks" then
			for k, o in { { 0, 0 }, { 1.3, 0.3 }, { 0.6, 1.2 }, { 0.65, 0.5, 1 } } do
				vox(props, "OreSack", Vector3.new(1.2, 1.1, 1.1), at(o[1], 0.55 + (o[3] or 0) * 1, o[2]) * CFrame.Angles(0, k * 0.5, 0.08), SACK)
				vox(props, "SackTie", Vector3.new(0.5, 0.3, 0.5), at(o[1], 1.2 + (o[3] or 0) * 1, o[2]), Color3.fromRGB(150, 110, 96), { CanCollide = false })
			end
			vox(props, "LooseOre", Vector3.new(0.6, 0.6, 0.6), at(-1, 0.3, 0.8), ORE[(seed * 10) % 3 // 1 + 1], { Material = Enum.Material.Neon })
		elseif kind == "crates" then
			for k = 0, 2 do tvox(props, "Crate", Vector3.new(2, 2, 2), at((k % 2) * 2.1, 1 + math.floor(k / 2) * 2, 0) * CFrame.Angles(0, k * 0.25, 0), "wood_frame", 2) end
			barrel(props, W(x, y, z) + (base.RightVector * -1.9) + Vector3.new(0, 0, 0))
		elseif kind == "tools" then -- a rack of picks and shovels leaning on a rail
			for _, dx in { -1.2, 1.2 } do tvox(props, "RackPost", Vector3.new(0.35, 2.4, 0.35), at(dx, 1.2, 0), "beam", 1) end
			tvox(props, "RackRail", Vector3.new(3, 0.3, 0.3), at(0, 2.1, 0), "beam", 1)
			for k = 0, 2 do
				tvox(props, "ToolHandle", Vector3.new(0.22, 2.6, 0.22), at(-0.8 + k * 0.8, 1.3, 0.35) * CFrame.Angles(-0.3, 0, 0), "beam", 1)
				vox(props, "ToolHead", k == 1 and Vector3.new(0.5, 0.7, 0.12) or Vector3.new(1.3, 0.25, 0.25), at(-0.8 + k * 0.8, 2.55, 0.0), Color3.fromRGB(170, 176, 196))
			end
		elseif kind == "stump" then -- a stump with a pickaxe stuck in it and a lantern
			skin(vox(props, "Stump", Vector3.new(1.8, 1.1, 1.8), at(0, 0.55, 0), AVG.bark), "bark", 3, SIDES)
			vox(props, "StumpTop", Vector3.new(1.6, 0.1, 1.6), at(0, 1.12, 0), Color3.fromRGB(226, 196, 160))
			tvox(props, "ToolHandle", Vector3.new(0.22, 1.8, 0.22), at(0.2, 1.8, 0) * CFrame.Angles(0, 0, 0.4), "beam", 1)
			vox(props, "ToolHead", Vector3.new(1.4, 0.25, 0.25), at(-0.15, 2.55, 0) * CFrame.Angles(0, 0, 0.4), Color3.fromRGB(170, 176, 196))
			cubeLantern(props, W(x, y, z) + base.RightVector * 1.6 + Vector3.new(0, 0.5, 0), nil, 0.8)
		elseif kind == "barrow" then -- a wheelbarrow full of glowing ore
			tvox(props, "Barrow", Vector3.new(1.8, 0.9, 2.4), at(0, 1.1, 0) * CFrame.Angles(0.12, 0, 0), "planks", 2)
			tvox(props, "BarrowWheel", Vector3.new(0.3, 1, 1), at(0, 0.5, -1.4), "iron", 1)
			for _, dx in { -0.7, 0.7 } do tvox(props, "BarrowArm", Vector3.new(0.2, 0.2, 1.6), at(dx, 1, 1.8) * CFrame.Angles(0.25, 0, 0), "beam", 1) end
			for k = 0, 3 do vox(props, "CartOre", Vector3.new(0.7, 0.7, 0.7), at((k % 2 - 0.5) * 0.7, 1.75, (k // 2 - 0.5) * 0.9), ORE[k % 3 + 1], { Material = k == 1 and Enum.Material.Neon or Enum.Material.SmoothPlastic }) end
		end
	end
	for i, c in { { -22, -9, "barrow" }, { -22, 38, "sacks" }, { -1, 30, "stump" }, { 23, -11, "tools" }, { 32, 46, "crates" }, { 42, 48, "sacks" }, { 37, 12, "barrow" }, { -43, 48, "crates" }, { -40, 50, "stump" } } do
		cluster(c[1], c[2], c[3], i * 1.3)
	end
	for _, b in { { -18, -26 }, { 16, -24 }, { 22, 18 }, { -50, -12 }, { 26, 36 }, { 2, 56 }, { 36, -22 }, { -30, -40 } } do -- bush clumps round the lanes
		bush(props, W(b[1], groundTop(b[1], b[2]), b[2]), b[1] * 3 + b[2])
	end
	for i = 0, 9 do -- glowing mushrooms at the root walls
		local a = i / 10 * math.pi * 2 + 0.4
		if math.cos(a - math.pi / 2) < 0.6 then
			local tint = ({ Color3.fromRGB(196, 96, 128), Color3.fromRGB(80, 168, 136), Color3.fromRGB(140, 120, 200) })[i % 3 + 1]
			for k = 0, 2 do
				local h = 1.6 + k * 0.9
				local mx, mz = math.cos(a) * 62 + k * 1.8, math.sin(a) * 66 + (k % 2) * 1.5
				local p = W(mx, groundTop(mx, mz), mz)
				vox(props, "MushStem", Vector3.new(0.7, h, 0.7), CFrame.new(p + Vector3.new(0, h / 2, 0)), PAL.cream[2], { CanCollide = false })
				local cap = vox(props, "MushCap", Vector3.new(h * 1.2, 0.8, h * 1.2), CFrame.new(p + Vector3.new(0, h + 0.3, 0)), tint, { CanCollide = false })
				if k == 2 then glow(cap, tint, 14, 0.8) end
			end
		end
	end

	-- 14. Two villagers toasting marshmallows at the campfire (they face the fire)
	for i, v in { { "Juniper", Vector3.new(-6, 0, 0), PAL.pink[2], Color3.fromRGB(96, 150, 132) }, { "Tock", Vector3.new(6, 0, 0), Color3.fromRGB(142, 200, 255), Color3.fromRGB(84, 76, 112) } } do
		local pos = fire + v[2] * 0.77 + Vector3.new(0, 1.25, 0)
		local cf = CFrame.lookAt(pos, pos + (pos - Vector3.new(fire.X, pos.Y, fire.Z))) -- +Z (the face) toward the fire
		local m = villager(v[1], cf, v[3], v[4])
		local q = m:FindFirstChild("Quest")
		if q then q:Destroy() end
		local hand = cf * CFrame.new(0.9, 2.2, 1.2)
		vox(m, "Stick", Vector3.new(0.18, 0.18, 3), hand * CFrame.Angles(0.35, 0, 0) * CFrame.new(0, 0, 1.2), PAL.wood[3], { CanCollide = false })
		local mm = vox(m, "Marshmallow", Vector3.new(0.6, 0.6, 0.6), hand * CFrame.Angles(0.35, 0, 0) * CFrame.new(0, 0, 2.8), PAL.cream[3], { CanCollide = false })
		local puff = Instance.new("ParticleEmitter") -- a toasty puff now and then
		puff.Rate, puff.Lifetime, puff.Speed, puff.EmissionDirection = 1.2, NumberRange.new(1, 1.6), NumberRange.new(1, 2), N.Top
		puff.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1.1) })
		puff.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 1) })
		puff.Color = ColorSequence.new(Color3.fromRGB(230, 220, 240))
		puff.Parent = mm
		m:SetAttribute("Bob", 0.06 + i * 0.02)
	end

	-- 15. Spawn point south of the shaft, facing it
	vox(model, "SpawnPoint", Vector3.new(1, 1, 1), CFrame.lookAt(W(0, 3.6, 16), W(0, 3.6, 0)), PAL.wood[1], { Transparency = 1, CanCollide = false, CanQuery = false })

	model:SetAttribute("ZFixed", require(game:GetService("ServerScriptService"):WaitForChild("ZFix")).fix(model)) -- no z-fighting (the user, 2026-11-08)
	model.Parent = parent
	return model
end

return Hub
