-- HatchScene (ReplicatedStorage.Shared.HatchScene): the egg hatch as a cutscene in its own built place (2026-11-17, brief:
-- vault Projects/Pixel-_/Briefs/Egg Hatching v3 (2026-11-17).md; research: Research/Game Design/Craft Videos for Weak Grades).
-- Made the way Shared.ForgeCutscene is: a private stage far from the world, one clock for every part, camera and effect,
-- the HUD hidden and the lighting restored after. The place is a small glowing grotto (voxel rock, cyan crystals, magenta
-- glow mushrooms, a light shaft from a hole in the roof) with a mossy nest on a rock pedestal. Beats, after the hatch
-- videos (Pet Simulator X, BGSI, ten years of gacha pulls, Dragon Ball Legends summons):
--   1 ARRIVE   a fade into the grotto, the camera drifts down the light shaft to the nest
--   2 BUILD    the egg rocks harder and harder, cracks of light open one by one, two rings of light orbit it faster and faster;
--              the rarity CLIMBS in steps: the rings, the crystals and the shaft change colour up the rarity ladder, one
--              step and one rising chime per tier, so a rarer egg climbs further (the tell is in stages, not just longer)
--   3 HANG     it squashes down and holds still a beat, the light pulsing
--   4 BURST    a white cut, the shell flies apart in voxel chunks, a shockwave ring rolls over the floor, the whole grotto
--              floods with the rarity colour
--   5 REVEAL   the pet pops out toward the camera with overshoot and lands in the nest; its name slams in, then its rarity,
--              role and odds; confetti for Epic and up; tap to continue (or 6 s)
-- Display only: the server has already chosen the pet. Fast cutscenes (player attribute FastCine) shortens 1 and 2; Reduced
-- Motion drops the shake.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local M = {}
local WHITE, INK = Color3.new(1, 1, 1), Color3.fromRGB(28, 16, 40)
local SPARK = "rbxasset://textures/particles/sparkles_main.dds"
local ROCK = { Color3.fromRGB(58, 38, 72), Color3.fromRGB(70, 46, 86), Color3.fromRGB(48, 32, 62), Color3.fromRGB(82, 56, 98) }
local CYAN, MAGENTA = Color3.fromRGB(80, 230, 255), Color3.fromRGB(255, 80, 190)

local function smooth(a, b, x)
	local u = math.clamp((x - a) / (b - a), 0, 1)
	return u * u * (3 - 2 * u)
end
local function backOut(u) -- 0..1 with about 10% overshoot
	local c = 1.70158
	u -= 1
	return 1 + (c + 1) * u * u * u + c * u * u
end

local function part(parent, size, cf, color, props)
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	p.Size, p.CFrame, p.Color, p.Material = size, cf, color, Enum.Material.SmoothPlastic
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	for k, v in props or {} do p[k] = v end
	p.Parent = parent
	return p
end
local function light(parent, color, range, bright)
	local l = Instance.new("PointLight")
	l.Color, l.Range, l.Brightness, l.Shadows = color, range, bright, false
	l.Parent = parent
	return l
end

-- options: { name, rarity = "Legendary", role = "Cave-in armour", odds = "1 IN 250" or "", tier = 1..n, ladder = { Color3 per tier },
--   build = fn(name) -> Model (the pet), animate = fn(model, now, dt, moving) or nil, sfx = fn(name, pitch), fast = bool, calm = bool }
-- yields until the player has closed the scene
function M.play(opt)
	local plr = Players.LocalPlayer
	local cam = workspace.CurrentCamera
	local sfx = opt.sfx or function() end
	local tier, ladder = opt.tier or 1, opt.ladder or { WHITE }
	local rc = ladder[tier] or WHITE
	local k = (tier - 1) / math.max(#ladder - 1, 1) -- 0 Common .. 1 Secret
	local rnd = Random.new(7)
	local O = Vector3.new(-4000, 420, 0) -- the stage: far from the town, the mines and the caves
	local world = Instance.new("Folder")
	world.Name = "HatchStage"
	world.Parent = workspace

	-- THE GROTTO ------------------------------------------------------------------------------------------------------
	-- the baked meshes (design3d/hatch, loaded by PetVoxels.serverLoad into ReplicatedStorage.HatchArt); the part-built grotto and egg stay as the fallback
	local art = game:GetService("ReplicatedStorage"):FindFirstChild("HatchArt")
	local artG, artE = art and art:FindFirstChild("HatchGrotto"), art and art:FindFirstChild("HatchEgg")
	local B = 1.6 -- rock voxel size
	if not artG then
	for x = -9, 9 do
		for z = -9, 9 do
			local r = math.sqrt(x * x + z * z)
			if r <= 9.5 then -- the floor: a disc of rock blocks, a little uneven
				local h = (r > 7.5 and (r - 7.5) * 1.4 or 0) + rnd:NextNumber(0, 0.35)
				part(world, Vector3.new(B, B, B), CFrame.new(O + Vector3.new(x * B, -B / 2 + h, z * B)), ROCK[rnd:NextInteger(1, 4)])
			end
		end
	end
	for a = 0, 359, 9 do -- the walls: a ring of stacked blocks curling in overhead; the camera side (-Z) stays open low down
		local t = math.rad(a)
		local open = math.cos(t - math.pi * 1.5) > 0.55 -- facing the camera
		for y = 0, 9 do
			local inward = (y / 9) ^ 2 * 6.5
			local r = 15 - inward
			if not (open and y < 6) and not (y >= 8 and r < 9.5 and math.cos(t) > 0.2) then -- a gap in the roof on the far side lets the light shaft in
				local c = ROCK[(a // 9 + y) % 4 + 1]:Lerp(Color3.new(0, 0, 0), y * 0.04)
				part(world, Vector3.new(B * 1.6, B * 1.2, B * 1.6), CFrame.new(O + Vector3.new(math.cos(t) * r * B * 0.62, y * B * 1.1, math.sin(t) * r * B * 0.62)) * CFrame.Angles(0, -t, rnd:NextNumber(-0.08, 0.08)), c)
			end
		end
	end
	end
	local lit = artG and 0.5 or 1 -- the mesh grotto has more lights, nearer the walls (stills m3: the gold flood turned the rock orange)
	local glows = {} -- every light that floods with the rarity colour on the burst
	local crystals = {} -- the crystal parts, tinted as the rarity climbs
	local function crystal(at, n, h, col)
		for i = 1, n do
			local tilt = CFrame.Angles(rnd:NextNumber(-0.45, 0.45), rnd:NextNumber(0, 6.28), rnd:NextNumber(-0.45, 0.45))
			local hh = h * rnd:NextNumber(0.55, 1)
			local c = part(world, Vector3.new(0.5, hh, 0.5), CFrame.new(at) * tilt * CFrame.new(0, hh / 2, 0), col, { Material = Enum.Material.Neon, Transparency = 0.15 })
			c:SetAttribute("Base", col)
			table.insert(crystals, c)
			part(world, Vector3.new(0.36, 0.5, 0.36), c.CFrame * CFrame.new(0, hh / 2 + 0.2, 0) * CFrame.Angles(0, math.rad(45), 0), col:Lerp(WHITE, 0.4), { Material = Enum.Material.Neon })
		end
		local holder = part(world, Vector3.new(0.2, 0.2, 0.2), CFrame.new(at + Vector3.new(0, h * 0.6, 0)), col, { Transparency = 1 })
		table.insert(glows, { l = light(holder, col, 16, 1.6), base = col })
	end
	local function mushroom(at, s)
		part(world, Vector3.new(0.35, 1.0, 0.35) * s, CFrame.new(at + Vector3.new(0, 0.5 * s, 0)), Color3.fromRGB(230, 210, 240))
		local cap = part(world, Vector3.new(1.3, 0.6, 1.3) * s, CFrame.new(at + Vector3.new(0, 1.1 * s, 0)), MAGENTA, { Material = Enum.Material.Neon, Shape = Enum.PartType.Ball })
		table.insert(glows, { l = light(cap, MAGENTA, 10, 1.2), base = MAGENTA })
	end
	if not artG then
	crystal(O + Vector3.new(-9, 0.4, 6), 5, 4.5, CYAN)
	crystal(O + Vector3.new(9.5, 0.6, 4), 6, 5.5, CYAN)
	crystal(O + Vector3.new(4, 0.3, 11), 4, 3.6, CYAN:Lerp(MAGENTA, 0.35))
	crystal(O + Vector3.new(-5, 0.3, 11.5), 3, 3, CYAN)
	mushroom(O + Vector3.new(-7, 0.3, 2), 1.1)
	mushroom(O + Vector3.new(-6, 0.3, 3.4), 0.7)
	mushroom(O + Vector3.new(7.2, 0.3, 9), 1.0)
	mushroom(O + Vector3.new(6, 0.3, 0.5), 0.6)
	-- the pedestal and the nest
	for i, s in { 3.6, 3.0, 2.4 } do
		part(world, Vector3.new(s, 0.7, s), CFrame.new(O + Vector3.new(0, 0.1 + i * 0.6, 0)) * CFrame.Angles(0, i * 0.4, 0), ROCK[i + 1]:Lerp(WHITE, 0.08))
	end
	end
	local NEST = O + Vector3.new(0, 2.25, 0) -- the egg's foot
	if artG then -- the egg's foot sits on the floor of the woven bowl, 0.25 below the middle of the Nest part
		local g = artG:Clone()
		local nestP = g:FindFirstChild("Nest__Tex", true) -- each MeshPart sits in its own "<name>_Node" model
		if nestP then -- the nest at half height (stills m1: its 0.5-stud twigs hid the egg and the pet); the egg's foot on its woven floor
			local bottom = nestP.Position - Vector3.new(0, nestP.Size.Y / 2, 0)
			nestP.Size *= Vector3.new(1, 0.5, 1)
			nestP.Position = bottom + Vector3.new(0, nestP.Size.Y / 2, 0)
			g:PivotTo(g:GetPivot() + (NEST - bottom - Vector3.new(0, 0.25, 0)))
		end
		for _, p in g:GetDescendants() do
			if p:IsA("BasePart") then
				local role = p.Name:match("__(%w+)$")
				if role == "Crystal" then
					local c = CYAN:Lerp(INK, 0.5) -- the fat mesh crystals bloomed into white blobs at full cyan (stills m1)
					p.Material, p.Color, p.Transparency = Enum.Material.Neon, c, 0.2
					p:SetAttribute("Base", c)
					table.insert(crystals, p)
					table.insert(glows, { l = light(p, CYAN, 12, 0.9), base = CYAN })
				elseif role == "Glow" then
					p.Material, p.Color = Enum.Material.SmoothPlastic, Color3.fromRGB(112, 86, 160) -- set dressing that stays back (Gemini m5/m12: bright caps clashed and stole focus); lit plastic keeps the voxel steps
				end
			end
		end
		g.Parent = world
	end
	local runes = {} -- a ring of rune stones round the pedestal top that light up as the egg wakes (Gemini n17_hatch: the nest read as plain wood)
	for i = 0, 11 do
		local a = i / 12 * math.pi * 2
		local rr, ry = artG and 2.1 or 1.9, artG and NEST.Y - O.Y - 1.44 or 2.0 -- the meshes: on the lowest step of the pedestal, clear of the nest
		table.insert(runes, part(world, Vector3.new(0.5, 0.12, 0.22), CFrame.new(O + Vector3.new(math.cos(a) * rr, ry, math.sin(a) * rr)) * CFrame.Angles(0, -a, 0), Color3.fromRGB(70, 50, 96), { Material = Enum.Material.Neon }))
	end
	if not artG then
	for a = 0, 359, 20 do
		local t = math.rad(a)
		for y = 0, 1 do
			local r = 1.25 + y * 0.25
			local moss = (a // 20 + y) % 3 == 0
			part(world, Vector3.new(0.55, 0.42, 0.55), CFrame.new(NEST + Vector3.new(math.cos(t) * r, y * 0.36, math.sin(t) * r)) * CFrame.Angles(0, -t, 0.2),
				moss and Color3.fromRGB(110, 150, 96) or Color3.fromRGB(122, 86, 58):Lerp(Color3.fromRGB(150, 110, 70), (a % 40) / 40))
		end
	end
	end
	-- the light shaft from the gap in the roof, and the dust that drifts in it
	local shaftTop = O + Vector3.new(4, 13, 6)
	local shaftLen = (shaftTop - NEST).Magnitude
	local shaft = part(world, Vector3.new(shaftLen, 3.2, 3.2), CFrame.lookAt((shaftTop + NEST) / 2, NEST) * CFrame.Angles(0, math.pi / 2, 0), Color3.fromRGB(220, 230, 255),
		{ Material = Enum.Material.Neon, Transparency = 0.9, Shape = Enum.PartType.Cylinder })
	local motes = Instance.new("ParticleEmitter")
	motes.Texture, motes.Rate, motes.LightEmission, motes.LightInfluence = SPARK, 14, 1, 0
	motes.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0.18), NumberSequenceKeypoint.new(1, 0) })
	motes.Transparency, motes.Lifetime, motes.Speed = NumberSequence.new(0.2, 1), NumberRange.new(4, 7), NumberRange.new(0.2, 0.6)
	motes.SpreadAngle, motes.Color = Vector2.new(180, 180), ColorSequence.new(CYAN, MAGENTA)
	motes.Parent = shaft
	local nestLight = part(world, Vector3.new(0.2, 0.2, 0.2), CFrame.new(NEST + Vector3.new(0, 3, -1)), WHITE, { Transparency = 1 })
	local keyL = light(nestLight, Color3.fromRGB(255, 236, 214), 14, 1.2) -- a warm key on the nest

	-- THE EGG: a voxel egg of small cubes (the game's look), cream with darker speckles
	local egg = Instance.new("Model")
	egg.Name = "Egg"
	local cells = {}
	local E = 0.3
	local shell, shellSize = nil, nil -- the baked egg mesh, when it has loaded
	if artE then
		shell = artE:FindFirstChildWhichIsA("BasePart", true):Clone()
		shell.Anchored, shell.CanCollide, shell.CanQuery, shell.CanTouch, shell.CastShadow = true, false, false, false, false
		shellSize = shell.Size * 1.2 -- 3.5 tall, the size of the old cube egg
		shell.Size, shell.CFrame = shellSize, CFrame.new(NEST + Vector3.new(0, shellSize.Y / 2, 0))
		shell.Parent = egg
	end
	for x = -4, 4 do
		for y = 0, 11 do
			for z = -4, 4 do
				local yy = (y + 0.5) * E - 1.75
				local rx = (yy > 0) and 1.2 * (1 - (yy / 1.95) ^ 2) ^ 0.5 or 1.32 * (1 - (yy / 1.8) ^ 2) ^ 0.5 -- narrower at the top
				local d = math.sqrt((x * E) ^ 2 + (z * E) ^ 2)
				if not shell and d <= rx and d > rx - 0.62 then
					local speck = (x * 7 + y * 3 + z * 5) % 9 == 0
					local c = part(egg, Vector3.new(E, E, E), CFrame.new(NEST + Vector3.new(x * E, (y + 0.5) * E, z * E)), speck and Color3.fromRGB(176, 150, 196) or Color3.fromRGB(248, 236, 214):Lerp(Color3.fromRGB(230, 214, 240), y / 11))
					table.insert(cells, { p = c, rest = CFrame.new(x * E, (y + 0.5) * E, z * E) })
				end
			end
		end
	end
	local core = part(egg, Vector3.new(0.2, 0.2, 0.2), CFrame.new(NEST + Vector3.new(0, 1.8, 0)), rc, { Transparency = 1 })
	local coreL = light(core, rc, 0, 0)
	local cracks = {}
	local nCr = shell and 8 or 5 -- more seams on the mesh egg (Gemini m8: it read as a dull rock)
	for i = 1, nCr do -- cracks of light down the front of the shell, opening one by one
		local a = (i - (nCr + 1) / 2) * (shell and 0.3 or 0.42)
		local y = 1.2 + (i % 3) * 0.55
		local cr = 1.25
		if shell then -- on the mesh's surface at this height (Gemini m11: seams standing off the shell read as floating sticks)
			local yy = y / shellSize.Y * 2 - 0.92
			cr = 1.33 * math.sqrt(math.max(0, 1 - (yy / (yy > 0 and 1.08 or 0.92)) ^ 2)) * (yy > 0 and 0.92 or 1) - 0.02
		end
		local c = part(egg, shell and Vector3.new(0.13, 0.75, 0.13) or Vector3.new(0.09, 0.55, 0.09), CFrame.new(NEST + Vector3.new(math.sin(a) * cr, y, -math.cos(a) * cr)) * CFrame.Angles(0, -a, (i % 2 == 0 and 1 or -1) * (shell and 0.35 or 0.5)), rc:Lerp(WHITE, 0.35), { Material = Enum.Material.Neon, Transparency = 1 })
		cracks[i] = { p = c, rest = CFrame.new(NEST):ToObjectSpace(c.CFrame) }
	end
	egg.Parent = world
	-- two rings of light beads that orbit the egg
	local beads = {}
	for i = 1, 14 do
		beads[i] = part(world, Vector3.new(0.22, 0.22, 0.22), CFrame.new(NEST), ladder[1], { Material = Enum.Material.Neon, Transparency = 1 })
	end
	local hl = Instance.new("Highlight")
	hl.FillTransparency, hl.OutlineTransparency, hl.OutlineColor, hl.DepthMode = 1, 1, rc, Enum.HighlightDepthMode.Occluded
	hl.Parent = egg

	-- THE SCREEN LAYER: the fade, the letterbox, the flash, the name card
	local pg = plr:WaitForChild("PlayerGui")
	local gui = Instance.new("ScreenGui")
	gui.Name, gui.IgnoreGuiInset, gui.ResetOnSpawn, gui.DisplayOrder, gui.ZIndexBehavior = "HatchSceneGui", true, false, 31, Enum.ZIndexBehavior.Sibling
	local hidden = {}
	for _, g in pg:GetChildren() do
		if g:IsA("ScreenGui") and g.Enabled then g.Enabled = false table.insert(hidden, g) end
	end
	gui.Parent = pg
	local function frame(props)
		local f = Instance.new("Frame")
		f.BorderSizePixel = 0
		for kk, v in props do f[kk] = v end
		f.Parent = props.Parent or gui
		return f
	end
	local function label(txt, size, pos, color, z, stroke)
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency, l.Font, l.TextScaled, l.Text, l.TextColor3, l.ZIndex = 1, Enum.Font.FredokaOne, true, txt, color, z
		l.Size, l.Position, l.AnchorPoint = size, pos, Vector2.new(0.5, 0.5)
		local s = Instance.new("UIStroke")
		s.Color, s.Thickness = stroke or INK, 3
		s.Parent = l
		local sc = Instance.new("UIScale")
		sc.Parent = l
		l.Parent = gui
		return l, sc
	end
	local veil = frame({ Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(14, 8, 22), BackgroundTransparency = 0, ZIndex = 9 })
	local barT = frame({ Size = UDim2.fromScale(1, 0.1), BackgroundColor3 = Color3.fromRGB(8, 4, 14), ZIndex = 5 })
	local barB = frame({ Size = UDim2.fromScale(1, 0.1), Position = UDim2.fromScale(0, 0.9), BackgroundColor3 = Color3.fromRGB(8, 4, 14), ZIndex = 5 })
	local flash = frame({ Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BackgroundTransparency = 1, ZIndex = 8 })
	local caption = label("SOMETHING STIRS IN THE NEST...", UDim2.fromScale(0.6, 0.045), UDim2.fromScale(0.5, 0.95), Color3.fromRGB(236, 224, 255), 6)
	caption.TextTransparency, caption.UIStroke.Transparency = 1, 1
	local nameL, nameS = label(string.upper(opt.name), UDim2.fromScale(0.62, 0.11), UDim2.fromScale(0.5, 0.165), WHITE, 7, rc:Lerp(INK, 0.45))
	nameL.UIStroke.Thickness = 5
	local nameGrad = Instance.new("UIGradient")
	nameGrad.Color, nameGrad.Rotation = ColorSequence.new(WHITE, rc:Lerp(WHITE, 0.35)), 90
	nameGrad.Parent = nameL
	local subL, subS = label(string.upper(opt.rarity or "") .. "  -  " .. string.upper(opt.role or "") .. ((opt.odds or "") ~= "" and ("  -  " .. opt.odds) or ""),
		UDim2.fromScale(0.5, 0.05), UDim2.fromScale(0.5, 0.26), rc:Lerp(WHITE, 0.25), 7)
	local hint = label(game:GetService("UserInputService").TouchEnabled and "TAP TO CONTINUE" or "CLICK TO CONTINUE", UDim2.fromScale(0.3, 0.035), UDim2.fromScale(0.5, 0.95), Color3.fromRGB(236, 224, 255), 7)
	for _, l in { nameL, subL, hint } do l.TextTransparency, l.UIStroke.Transparency = 1, 1 end
	local tapBtn = Instance.new("TextButton")
	tapBtn.Size, tapBtn.BackgroundTransparency, tapBtn.Text, tapBtn.ZIndex, tapBtn.Visible = UDim2.fromScale(1, 1), 1, "", 10, false
	tapBtn.Parent = gui

	-- LIGHTING: a dark cave, restored after; blur and depth of field off; the first-person tool hidden
	local camSaved = { CameraType = cam.CameraType, CameraSubject = cam.CameraSubject, FieldOfView = cam.FieldOfView }
	local saved = { ClockTime = Lighting.ClockTime, Brightness = Lighting.Brightness, Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient, ExposureCompensation = Lighting.ExposureCompensation, FogEnd = Lighting.FogEnd, FogColor = Lighting.FogColor }
	local off = {}
	for _, root in { Lighting, cam } do
		for _, e in root:GetChildren() do
			if (e:IsA("BlurEffect") or e:IsA("DepthOfFieldEffect")) and e.Enabled then e.Enabled = false table.insert(off, e) end
		end
	end
	local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
	local atmoSaved = atmo and { Density = atmo.Density, Color = atmo.Color, Decay = atmo.Decay, Haze = atmo.Haze }
	local hiddenVm = {}
	for _, m in cam:GetChildren() do
		for _, d in m:GetDescendants() do
			if d:IsA("BasePart") and d.LocalTransparencyModifier < 1 then d.LocalTransparencyModifier = 1 table.insert(hiddenVm, d) end
		end
	end
	Lighting.ClockTime, Lighting.Brightness, Lighting.ExposureCompensation = 0, 0.5, 0
	local AMB, OAMB, DARK = Color3.fromRGB(46, 30, 62), Color3.fromRGB(56, 36, 76), Color3.fromRGB(10, 8, 30) -- dark stays cool violet
	Lighting.Ambient, Lighting.OutdoorAmbient = AMB, OAMB
	local dof = Instance.new("DepthOfFieldEffect") -- the cave falls out of focus behind the egg and the pet (Gemini m12: isolate the subject)
	dof.Name, dof.FarIntensity, dof.NearIntensity, dof.InFocusRadius, dof.FocusDistance = "HatchDOF", 0, 0, 4, 9
	dof.Parent = Lighting
	if atmo then atmo.Density, atmo.Color, atmo.Decay, atmo.Haze = 0.42, Color3.fromRGB(40, 24, 56), Color3.fromRGB(24, 12, 34), 1.2 end

	-- THE CLOCK --------------------------------------------------------------------------------------------------------
	local fast = opt.fast
	local A1 = fast and 0.5 or 1.4 -- arrive ends
	local BUILD = fast and 0.6 or (1.6 + k * 1.6) -- the build-up, longer for rarer eggs
	local A2 = A1 + BUILD
	local HANG = fast and 0.2 or (0.35 + k * 0.25)
	local A3 = A2 + HANG -- the burst
	local t, last, fired = 0, os.clock(), {}
	local done, closing, closeAt = false, false, nil
	local pet, petT = nil, nil
	local shards, shock, rays = {}, nil, nil
	local climbStep, climbCol = 1, ladder[1]
	local shake = 0
	local function once(key, at, fn)
		if t >= at and not fired[key] then
			fired[key] = true
			fn()
		end
	end
	tapBtn.Activated:Connect(function()
		if t > A3 + 0.8 and not closing then closing, closeAt = true, t end
	end)
	TweenService:Create(veil, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 }):Play()
	local frozeAt = nil

	RunService:BindToRenderStep("HatchScene", Enum.RenderPriority.Camera.Value + 21, function()
		local now = os.clock()
		local dt = math.min(now - last, 0.1)
		last = now
		t += dt
		if opt.freeze then t = math.min(t, opt.freeze) end -- test hook (stills): hold the scene at one moment
		if opt.freeze and t >= opt.freeze then
			frozeAt = frozeAt or now
			if opt.freezeFor and now - frozeAt > opt.freezeFor then done = true end
		end
		cam.CameraType = Enum.CameraType.Scriptable

		-- 1 ARRIVE: down the light shaft to the nest; the caption fades in
		once("cap", 0.3, function()
			TweenService:Create(caption, TweenInfo.new(0.4), { TextTransparency = 0 }):Play()
			TweenService:Create(caption.UIStroke, TweenInfo.new(0.4), { Transparency = 0.2 }):Play()
		end)
		local u1 = smooth(0, A1, t)
		local camPos = (O + Vector3.new(2.5, 9, -22)):Lerp(NEST + Vector3.new(0.8, 2.6, -9), u1)
		local look = NEST + Vector3.new(0, 1.7 + (1 - u1) * 1.5, 0)
		local fov = 52 - u1 * 6

		-- 2 BUILD: rock, crack, orbit, climb
		local ub = smooth(A1, A2, t)
		if t >= A1 and t < A3 then
			camPos = camPos:Lerp(NEST + Vector3.new(0.5, 2.7, -8.2), smooth(A1, A2, t)) -- the whole egg and its rings stay in frame (stills hs5: the egg was cut off at the top)
			fov = 46 - ub * 8
			if t >= A2 then fov = 38 - smooth(A2, A2 + 0.12, t) * 7 end
			dof.FarIntensity = 0.45 * ub
			local dim = smooth(A1, A2, t) * 0.85 + smooth(A2, A2 + 0.1, t) * 0.15 -- full black on the hang: the egg alone, a silhouette with its seams (Gemini m11) -- the cave sinks toward black as the egg wakes, so the egg carries the contrast (Gemini m8)
			Lighting.Ambient, Lighting.OutdoorAmbient = AMB:Lerp(DARK, dim), OAMB:Lerp(DARK, dim)
			for _, g in glows do g.l.Brightness = 1.6 * lit * (1 - dim) end -- the cave lights die down with it
			keyL.Range, keyL.Color = 14 - dim * 7, Color3.fromRGB(255, 236, 214):Lerp(Color3.fromRGB(225, 235, 255), dim) -- the key closes in on the egg and cools -- a snap in on the hang (Gemini m5: the camera stayed on one flat shot)
			-- the climb: one colour step per tier, spread over the build-up
			local step = math.clamp(math.floor(ub * tier) + 1, 1, tier)
			if step ~= climbStep then
				climbStep, climbCol = step, ladder[step]
				sfx("upgrade", 1.1 + step * 0.12)
				for _, g in glows do
					TweenService:Create(g.l, TweenInfo.new(0.25), { Color = g.base:Lerp(climbCol, 0.3) }):Play()
				end
				for _, c in crystals do TweenService:Create(c, TweenInfo.new(0.3), { Color = c:GetAttribute("Base"):Lerp(climbCol:Lerp(INK, 0.4), 0.85) }):Play() end -- the crystals take the climbing colour too
				shaft.Color = climbCol:Lerp(WHITE, 0.5)
				for i, r in runes do r.Color = i <= math.ceil(12 * step / tier) and climbCol or Color3.fromRGB(70, 50, 96) end
				hl.OutlineColor = climbCol
			end
			shake = opt.calm and 0 or ub ^ 3 * (0.08 + k * 0.08)
		end
		if t < A3 then -- the egg rocks harder and harder (and holds still in the hang)
			local hang = t >= A2
			local amp = hang and 0 or (0.02 + 0.3 * ub ^ 2.5) * (0.7 + k * 0.5)
			local wob = CFrame.new(NEST) * CFrame.Angles(math.sin(t * (14 + 30 * ub)) * amp * 0.5, 0, math.sin(t * (11 + 34 * ub)) * amp)
			local sq = hang and smooth(A2, A2 + 0.18, t) * 0.18 or 0 -- the squash before the snap
			for _, c in cells do
				local r = c.rest
				c.p.CFrame = wob * CFrame.new(r.X * (1 + sq), r.Y * (1 - sq), r.Z * (1 + sq))
			end
			if shell then
				shell.Size = shellSize * Vector3.new(1 + sq, 1 - sq, 1 + sq)
				shell.CFrame = wob * CFrame.new(0, shellSize.Y * (1 - sq) / 2, 0)
			end
			for i, c in cracks do
				c.p.CFrame = wob * c.rest
				c.p.Transparency = ub > (i - 0.5) / (#cracks + 1) and 0 or 1
				c.p.Color = climbCol:Lerp(WHITE, 0.35)
			end
			coreL.Range, coreL.Brightness, coreL.Color = 4 + ub * 4, ub * 3, climbCol -- local: a range of 14 lit the whole cave gold (stills m10)
			hl.OutlineTransparency = 1 - ub * 0.8
			if shell then hl.FillColor, hl.FillTransparency = climbCol:Lerp(WHITE, 0.3), 1 - ub * 0.3 end -- the shell itself takes the climbing colour (Gemini m5: the climb was only in the crystals)
			for i, b in beads do -- two rings, tilted, speeding up
				local ring = i <= 7 and 1 or -1
				local a = (i % 7) / 7 * math.pi * 2 + (t - A1) * (1.5 + 9 * ub ^ 2) * ring
				local rr = 2.1 - ub * 0.4
				local off = CFrame.Angles(0, 0, ring * 0.5) * Vector3.new(math.cos(a) * rr, 0, math.sin(a) * rr)
				b.CFrame = CFrame.new(NEST + Vector3.new(0, 1.8, 0) + off)
				b.Transparency = t < A1 and 1 or (1 - math.min(1, ub * 3))
				b.Color = climbCol
			end
			if hang then
				coreL.Brightness = 3 + math.sin(t * 40) * 1.5
				shake = opt.calm and 0 or 0.05 -- a fine tremble under the pressure (Gemini n17_hatch: the hang had no strain)
			end
		end
		once("tick", A1, function()
			task.spawn(function() -- ticks that climb in pitch and speed through the build-up
				local s = os.clock()
				while os.clock() - s < BUILD and not done do
					local u = (os.clock() - s) / BUILD
					sfx("hit", 0.8 + u * 0.9)
					task.wait(0.32 - u * 0.22)
				end
			end)
		end)
		once("hang", A2, function()
			sfx("swing", 1.3)
			TweenService:Create(caption, TweenInfo.new(0.2), { TextTransparency = 1 }):Play()
			TweenService:Create(caption.UIStroke, TweenInfo.new(0.2), { Transparency = 1 }):Play()
		end)

		-- 4 BURST
		once("burst", A3, function()
			sfx("claim", 1.0 + k * 0.2)
			sfx("sparkle", 1.2)
			flash.BackgroundTransparency = 0.3 -- not a full white-out (Gemini m5: the flat flash hid the shards); faded by the clock below, so a held still shows it
			for _, c in cells do -- the shell flies apart
				local out = (c.rest.Position * Vector3.new(1, 0.5, 1)).Unit
				if out ~= out then out = Vector3.yAxis end
				local toCam = Vector3.new(0, 0, -1) * rnd:NextNumber(0, 6) -- some shrapnel flies at the lens (Gemini n17_hatch: "voxel shrapnel bursting toward the camera")
				c.p.Size = c.p.Size * 1.6
				c.p.Color = c.p.Color:Lerp(rc, 0.25)
				table.insert(shards, { p = c.p, v = out * rnd:NextNumber(7, 15) + toCam + Vector3.new(0, rnd:NextNumber(4, 10), 0), spin = Vector3.new(rnd:NextNumber(-8, 8), rnd:NextNumber(-8, 8), rnd:NextNumber(-8, 8)) })
			end
			if shell then -- the mesh shell: hide it and throw cube shards in its colours
				shell.Transparency = 1
				local cols = { Color3.fromRGB(248, 236, 214), Color3.fromRGB(239, 228, 244), Color3.fromRGB(176, 150, 196), Color3.fromRGB(216, 192, 232) }
				for i = 1, 50 do
					local yy = rnd:NextNumber(0.1, 0.95) * shellSize.Y
					local a = rnd:NextNumber(0, math.pi * 2)
					local rest = Vector3.new(math.cos(a) * shellSize.X * 0.45, yy, math.sin(a) * shellSize.Z * 0.45)
					local sz = rnd:NextNumber(0.3, 0.55)
					local c = part(world, Vector3.new(sz, sz, sz), CFrame.new(NEST + rest) * CFrame.Angles(rnd:NextNumber(0, 3), rnd:NextNumber(0, 3), 0), cols[i % 4 + 1]:Lerp(rc, 0.25))
					local out = (rest * Vector3.new(1, 0.5, 1)).Unit
					table.insert(shards, { p = c, v = out * rnd:NextNumber(7, 15) + Vector3.new(0, 0, -1) * rnd:NextNumber(0, 6) + Vector3.new(0, rnd:NextNumber(4, 10), 0), spin = Vector3.new(rnd:NextNumber(-8, 8), rnd:NextNumber(-8, 8), rnd:NextNumber(-8, 8)) })
				end
			end
			for _, c in cracks do c.p.Transparency = 1 end
			for _, b in beads do b.Transparency = 1 end
			hl.Enabled = false
			shock = part(world, Vector3.new(0.12, 1, 1), CFrame.new(NEST + Vector3.new(0, 0.15, 0)) * CFrame.Angles(0, 0, math.pi / 2), rc:Lerp(WHITE, 0.3), { Shape = Enum.PartType.Cylinder, Material = Enum.Material.Neon, Transparency = 0.2 })
			for _, g in glows do -- the grotto floods with the rarity colour
				TweenService:Create(g.l, TweenInfo.new(0.3), { Color = g.base:Lerp(rc, 0.4), Brightness = (1.0 + k * 0.4) * lit, Range = 18 }):Play() -- was 2.6 + k * 1.4: a gold flood washed the pet out (stills hs5)
			end
			keyL.Color, keyL.Brightness = rc:Lerp(WHITE, 0.6), 2
			shaft.Color, shaft.Transparency = rc:Lerp(WHITE, 0.4), 0.88
			coreL.Brightness, coreL.Range = 4, 16
			TweenService:Create(coreL, TweenInfo.new(1.2), { Brightness = 0.5, Range = 10 }):Play()
			pet = opt.build(opt.name)
			if pet then
				pet:PivotTo(CFrame.new(NEST + Vector3.new(0, 0.92, 0))) -- pets look -Z: at the camera
				pet.Parent = world
				pet:ScaleTo(0.2)
			end
			petT = t
			light(part(world, Vector3.new(0.2, 0.2, 0.2), CFrame.new(NEST + Vector3.new(0, 2.4, 2.2)), WHITE, { Transparency = 1 }), CYAN:Lerp(WHITE, 0.3), 8, 3) -- a cool rim light behind the pet against the warm burst (Gemini m11)
			shake = opt.calm and 0 or 0.35
			rays = Instance.new("Model")
			rays.Parent = world
			for i = 1, 12 do -- a slow sunburst of light blades behind the pet (Gemini n17_hatch: "a rotating radial sunburst behind the pet")
				part(rays, Vector3.new(i % 2 == 0 and 0.3 or 0.16, 11, 0.05), CFrame.new(), i % 2 == 0 and rc or rc:Lerp(WHITE, 0.6), { Material = Enum.Material.Neon, Transparency = i % 2 == 0 and 0.8 or 0.86 }).Name = tostring(i) -- faint and far behind: brighter blades bloomed over the pet (stills hs8)
			end
		end)
		if t >= A3 then flash.BackgroundTransparency = 0.3 + 0.7 * smooth(A3, A3 + 0.3 + k * 0.15, t) end
		local sdt = opt.freeze and t >= opt.freeze and 0 or dt -- held stills freeze the shrapnel too
		if #shards > 0 then
			for i = #shards, 1, -1 do
				local s = shards[i]
				local dt = sdt
				s.v += Vector3.new(0, -30, 0) * dt
				s.p.CFrame = (s.p.CFrame + s.v * dt) * CFrame.Angles(s.spin.X * dt, s.spin.Y * dt, s.spin.Z * dt)
				s.p.Size = s.p.Size * (1 - dt * 0.6)
				if s.p.Position.Y < O.Y - 2 or t - A3 > 1.6 then s.p:Destroy() table.remove(shards, i) end
			end
		end
		if shock then
			local u = smooth(A3, A3 + 0.55, t)
			shock.Size = Vector3.new(0.12, 1 + u * 26, 1 + u * 26)
			shock.Transparency = 0.2 + u * 0.8
			if u >= 1 then shock:Destroy() shock = nil end
		end

		-- 5 REVEAL: the pet pops toward the camera and lands, then turns to look about; the name slams in
		if pet and petT then
			local u = math.clamp((t - petT) / 0.55, 0, 1)
			local s = 0.2 + 0.8 * backOut(u)
			local hop = math.sin(math.min(u, 1) * math.pi) * 1.6
			local turn = math.sin((t - petT) * 0.9) * 0.35 * smooth(petT + 0.8, petT + 1.6, t) -- it looks about a little after it lands
			pet:ScaleTo(math.max(0.05, s) * 1.15)
			pet:PivotTo(CFrame.new(NEST + Vector3.new(0, 0.92 * s * 1.15 + hop + 0.6 * u + math.sin((t - petT) * 2.2) * 0.12 * u, -0.4 * (1 - u))) * CFrame.Angles(0, turn, 0)) -- it floats clear of the nest rim (Gemini m5: the limbs blended into the nest)
			if opt.animate then opt.animate(pet, now, dt, false) end
			local ru = smooth(A3, A3 + 0.9, t)
			camPos = (NEST + Vector3.new(0.5, 2.7, -8.2)):Lerp(NEST + Vector3.new(-0.6, 2.9, -10.8) + Vector3.new(math.sin((t - A3) * 0.35) * 1.2, 0, 0), ru)
			look = NEST + Vector3.new(0, 2.75, 0) -- the pet sits low in frame, under its name (stills m6: the floating pet's head was behind the card)
			fov = 54 - ru * 14
			dof.FarIntensity, dof.FocusDistance = 0.5, 10.8
			Lighting.Ambient, Lighting.OutdoorAmbient = DARK:Lerp(AMB, 0.15 + ru * 0.35), DARK:Lerp(OAMB, 0.15 + ru * 0.35) -- the cave comes back only half way -- a wide pop on the burst that settles in
		end
		if rays then -- the blades turn slowly in a plane behind the pet, facing the camera
			local spinA = (t - A3) * 0.35
			for _, b in rays:GetChildren() do
				local i = tonumber(b.Name)
				b.CFrame = CFrame.new(NEST + Vector3.new(0, 2.6, 7)) * CFrame.Angles(0, 0, spinA + i / 12 * math.pi * 2) * CFrame.new(0, 6.2, 0)
			end
		end
		once("name", A3 + 0.35, function()
			-- the plate: a dot of light that opens into a jelly-glass pill behind the name (Oly's circle-to-pill morph)
			local plate = frame({ Size = UDim2.fromScale(0.05, 0.08), Position = UDim2.fromScale(0.5, 0.2), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.fromRGB(22, 10, 34), BackgroundTransparency = 0.18, ZIndex = 6 })
			local pc = Instance.new("UICorner")
			pc.CornerRadius = UDim.new(0.5, 0)
			pc.Parent = plate
			local ps = Instance.new("UIStroke")
			ps.Color, ps.Thickness, ps.Transparency = rc, 3, 0
			ps.Parent = plate
			local pg2 = Instance.new("UIGradient")
			pg2.Rotation, pg2.Transparency = 90, NumberSequence.new(0, 0.35)
			pg2.Parent = plate
			TweenService:Create(plate, TweenInfo.new(0.42, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.fromScale(0.64, 0.2) }):Play()
			nameL.TextTransparency, nameL.UIStroke.Transparency = 0, 0
			nameS.Scale = 2.4
			TweenService:Create(nameS, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
			for i = 1, 2 do -- rack focus (after @creatoroly's clean motion): two soft, larger ghosts of the name shrink into it and fade, so it lands out of focus and sharpens
				local gh = nameL:Clone()
				gh.ZIndex = 6
				gh.TextTransparency, gh.UIStroke.Transparency = 0.55, 1
				gh.Parent = gui
				gh.UIScale.Scale = 2.4 + i * 0.25
				TweenService:Create(gh.UIScale, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1.04 + i * 0.03 }):Play()
				TweenService:Create(gh, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { TextTransparency = 1 }):Play()
				task.delay(0.55, function() gh:Destroy() end)
			end
			sfx("hit", 0.6)
		end)
		once("sub", A3 + 0.75, function()
			-- word by word, the rarity word in its colour (Oly's reveals: one keyword lit, the rest calm)
			local row = frame({ Size = UDim2.fromScale(0.8, 0.05), Position = UDim2.fromScale(0.5, 0.26), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, ZIndex = 7 })
			local lay = Instance.new("UIListLayout")
			lay.FillDirection, lay.HorizontalAlignment, lay.VerticalAlignment, lay.Padding = Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center, UDim.new(0, 10)
			lay.Parent = row
			local px = math.max(14, math.floor(gui.AbsoluteSize.Y * 0.032))
			local words = { string.upper(opt.rarity or "") }
			for w in string.gmatch(string.upper(opt.role or ""), "%S+") do table.insert(words, w) end
			if (opt.odds or "") ~= "" then table.insert(words, "·") for w in string.gmatch(opt.odds, "%S+") do table.insert(words, w) end end
			for i, w in words do
				local l = Instance.new("TextLabel")
				l.BackgroundTransparency, l.Font, l.TextSize, l.Text, l.AutomaticSize, l.Size = 1, Enum.Font.FredokaOne, px, w, Enum.AutomaticSize.XY, UDim2.new()
				l.TextColor3, l.TextTransparency, l.LayoutOrder, l.ZIndex = i == 1 and rc:Lerp(WHITE, 0.15) or Color3.fromRGB(232, 222, 250), 1, i, 7
				local st = Instance.new("UIStroke")
				st.Color, st.Thickness, st.Transparency = INK, 2.5, 1
				st.Parent = l
				l.Parent = row
				task.delay(0.07 * i, function()
					TweenService:Create(l, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextTransparency = 0 }):Play()
					TweenService:Create(st, TweenInfo.new(0.25), { Transparency = 0.1 }):Play()
				end)
			end
			sfx("sparkle", 1.5)
			if tier >= 3 then -- confetti cubes in the rarity colours, falling through the light
				for i = 1, 12 + tier * 6 do
					local c = part(world, Vector3.new(0.18, 0.18, 0.06), CFrame.new(NEST + Vector3.new(rnd:NextNumber(-5, 5), rnd:NextNumber(6, 9), rnd:NextNumber(-3, 4))), ({ rc, CYAN, MAGENTA, WHITE })[i % 4 + 1], { Material = Enum.Material.Neon })
					table.insert(shards, { p = c, v = Vector3.new(rnd:NextNumber(-1, 1), rnd:NextNumber(-3, -1), 0), spin = Vector3.new(rnd:NextNumber(-6, 6), rnd:NextNumber(-6, 6), 0) })
				end
			end
		end)
		once("hint", A3 + 1.1, function()
			hint.TextTransparency, hint.UIStroke.Transparency = 0, 0.3
			tapBtn.Visible = true
		end)
		if t > A3 + 6 and not closing then closing, closeAt = true, t end
		if closing and t - closeAt > 0.3 then done = true end
		veil.BackgroundTransparency = closing and 1 - smooth(closeAt, closeAt + 0.28, t) or veil.BackgroundTransparency

		shake = math.max(0, shake - dt * 0.9)
		local sx, sy = math.noise(t * 22, 1) * shake, math.noise(t * 22, 2) * shake
		cam.CFrame = CFrame.lookAt(camPos, look) * CFrame.Angles(sy * 0.12, sx * 0.12, sx * 0.05)
		cam.FieldOfView = fov
	end)
	local started = os.clock()
	while not done and os.clock() - started < 25 do task.wait() end -- never hang the player in the scene
	RunService:UnbindFromRenderStep("HatchScene")
	for kk, v in saved do Lighting[kk] = v end
	if atmo and atmoSaved then for kk, v in atmoSaved do atmo[kk] = v end end
	for _, e in off do e.Enabled = true end
	for _, d in hiddenVm do if d.Parent then d.LocalTransparencyModifier = 0 end end
	for _, g in hidden do if g.Parent then g.Enabled = true end end
	for kk, v in camSaved do pcall(function() cam[kk] = v end) end
	world:Destroy()
	if dof then dof:Destroy() end
	TweenService:Create(veil, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 }):Play()
	task.delay(0.4, function() gui:Destroy() end)
end

return M
