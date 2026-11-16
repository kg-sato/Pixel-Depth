-- ReplicatedStorage.Shared.ForgeFossil (src/ForgeFossil.luau): the Fossil Pickaxe biography, played by ForgeStory.
-- BORN: a spiral shell sinks through an ancient sea onto the mud, and the mud settles over it. MADE: in a dig trench at
-- sunset a field mouse brushes it out of the clay; she blows the dust off, and for one moment the trench fills with the old
-- sea: fish, bubbles, rippling light, and the shell creature swims round her head; the water drains into her notebook.
-- NAMED: it settles back into stone in her paws, and becomes the pickaxe. "It swam once."
-- The setting is a place of its own (references refs/forge/sheets/fossil_setting_s11.png and mouse_views_s11.png).
-- Built from design3d/fossil.mjs. The sky is the Kiln scene's dusk picture, with a sun of its own low at the trench's end.
-- Space: front of a model is -Z, the camera stands at -Z and looks along the trench toward the sun at +Z. +X is screen left:
-- the string grid on the left lip, the camp table on the right. Trench inside |x| < 1.6, floor y = 0, ground y = 2.6.
-- Every time in this file is a story second; the clock runs at 0.58 of real time (see ForgeWood).
local M = { length = 11.2, named = 7.6, open = true, pace = 0.58, fastPace = 0.75 }
local IMG = { dusk = { side = "80928397749976", up = "136438363041912", dn = "72680942305539", stars = 200 } }
local SND = { tap = 90326072989009, bonk = 101020483687867, dawn = 85010698086137, river = 117253485620174 }

local function hex(h) return Color3.fromHex(h) end
local function v3(x, y, z) return Vector3.new(x, y, z) end

function M.setup(ctx)
	local S = ctx.S
	local R, smooth, lin, backOut = S.rot, S.smooth, S.lin, S.backOut
	local O, sfx = ctx.O, ctx.sfx
	local function W(x, y, z) return O * CFrame.new(x, y, z) end -- stage space to world
	local K = NumberSequenceKeypoint.new
	local rgb = Color3.fromRGB
	local V = Vector3.new
	local FAR = W(0, -60, 0)
	local function matte(r) r:all(function(p) if p.Material ~= Enum.Material.Neon then p.Material = Enum.Material.Rubber end end) end
	local function mix(a, b, u) local o = {} for k, v in a do local w = b[k] o[k] = typeof(v) == "number" and v + (w - v) * u or v:Lerp(w, u) end return o end

	-- ===== the place =====
	matte(ctx.prop("FossilTrench"))
	local camp = ctx.prop("DigCamp")
	matte(camp)
	local far = ctx.prop("Badlands")
	far:all(function(p) p.Material, p.CastShadow = Enum.Material.Rubber, false end)
	ctx.sky(IMG.dusk)
	local sun = ctx.part(v3(34, 34, 34), CFrame.new(0, 7, 230), hex("#ffd59a"), { Shape = Enum.PartType.Ball, Material = Enum.Material.Neon })
	local sunGlow = Instance.new("BillboardGui")
	sunGlow.Size, sunGlow.LightInfluence, sunGlow.Brightness, sunGlow.Parent = UDim2.fromScale(110, 110), 0, 1, sun
	local sunIm = Instance.new("ImageLabel")
	sunIm.BackgroundTransparency, sunIm.Image, sunIm.ImageColor3, sunIm.ImageTransparency, sunIm.Size, sunIm.Parent = 1, S.GLOW, hex("#ffb070"), 0.35, UDim2.fromScale(1, 1), sunGlow
	ctx.key(V(0.15, 0.32, 1))
	local LOOK = {
		sunset = { Brightness = 2.0, Ambient = rgb(140, 116, 132), OutdoorAmbient = rgb(160, 130, 146), ColorShift_Top = rgb(255, 186, 120), ExposureCompensation = 0.05, EnvironmentDiffuseScale = 0.3, EnvironmentSpecularScale = 0 },
		sea = { Brightness = 0.6, Ambient = rgb(40, 96, 112), OutdoorAmbient = rgb(50, 112, 128), ColorShift_Top = rgb(120, 220, 230), ExposureCompensation = 0.1, EnvironmentDiffuseScale = 0.3, EnvironmentSpecularScale = 0 },
	}
	local ATMO = {
		sunset = { Density = 0.32, Haze = 2.0, Color = rgb(236, 170, 150), Decay = rgb(150, 100, 140), Glare = 0.2, Offset = 0.2 },
		sea = { Density = 0.62, Haze = 3.0, Color = rgb(40, 130, 150), Decay = rgb(20, 70, 96), Glare = 0, Offset = 0 },
	}
	local TINT = { sunset = rgb(255, 238, 222), sea = rgb(180, 236, 240) }

	-- the old sea: water that rises in the trench, light that ripples, specks, bubbles, a shoal
	local water = ctx.part(v3(3.18, 0.1, 22), CFrame.new(0, -1, 5), hex("#3f8f9c"), { Transparency = 0.72, Material = Enum.Material.SmoothPlastic, CastShadow = false })
	local seaLightPart = ctx.part(v3(0.2, 0.2, 0.2), CFrame.new(0, 5, 3), hex("#7fd0d8"), { Transparency = 1 })
	local seaLight = Instance.new("PointLight")
	seaLight.Color, seaLight.Range, seaLight.Brightness, seaLight.Shadows, seaLight.Parent = hex("#8fe0e8"), 16, 0, false, seaLightPart
	local seaAir = ctx.part(v3(4, 4, 14), CFrame.new(0, 2.2, 4), hex("#ffffff"), { Transparency = 1 })
	local specks = ctx.emitter(seaAir, { Texture = S.GLOW, Color = ColorSequence.new(hex("#d8fff8")), Size = NumberSequence.new({ K(0, 0), K(0.3, 0.06), K(1, 0) }), Transparency = NumberSequence.new(0.3), Lifetime = NumberRange.new(3, 5), Speed = NumberRange.new(0.1, 0.4), SpreadAngle = Vector2.new(180, 180), Acceleration = v3(0, -0.15, 0), LightEmission = 0.6 })
	local bubbles = ctx.emitter(seaAir, { Texture = S.GLOW, Color = ColorSequence.new(hex("#ffffff")), Size = NumberSequence.new({ K(0, 0.04), K(1, 0.1) }), Transparency = NumberSequence.new({ K(0, 0.2), K(1, 0.8) }), Lifetime = NumberRange.new(1.5, 2.5), Speed = NumberRange.new(1, 2), SpreadAngle = Vector2.new(15, 15), EmissionDirection = Enum.NormalId.Top, LightEmission = 0.5 })
	local mudPart = ctx.part(v3(2.4, 0.2, 2.4), CFrame.new(0.3, 0.2, 6), hex("#ffffff"), { Transparency = 1 })
	local mud = ctx.emitter(mudPart, { Texture = S.SMOKE, Color = ColorSequence.new(hex("#8a9a94")), Size = NumberSequence.new({ K(0, 0.6), K(1, 2.2) }), Transparency = NumberSequence.new({ K(0, 0.5), K(1, 1) }), Lifetime = NumberRange.new(1.2, 2), Speed = NumberRange.new(0.3, 1.2), SpreadAngle = Vector2.new(80, 80), EmissionDirection = Enum.NormalId.Top, LightEmission = 0, LightInfluence = 1 })
	local fish = {}
	for i = 1, 9 do
		local f = ctx.rig("Fish", CFrame.new(0, -60, 0), 1.2 + (i % 3) * 0.2)
		f:all(function(p) p.Material, p.CastShadow = Enum.Material.SmoothPlastic, false end)
		fish[i] = { r = f, ph = i * 0.7, rad = 1.6 + (i % 3) * 0.4, y = 1.6 + (i % 4) * 0.4 }
	end

	-- ===== the mouse, the shell, the tools =====
	local mouse = ctx.rig("MouseKit", CFrame.new(0, -60, 0))
	matte(mouse)
	mouse:all(function(p, b) if b.name == "Eyes" then p.Material = Enum.Material.SmoothPlastic end end)
	mouse:show("EyesShut", false)
	local brush = ctx.rig("DigBrush", CFrame.new(0, -60, 0))
	matte(brush)
	local book = ctx.rig("FieldBook", CFrame.new(0, -60, 0))
	matte(book)
	local shell = ctx.rig("Ammonite", CFrame.new(0, -60, 0))
	shell:all(function(p, b) if b.name ~= "Pearl" then p.Material = Enum.Material.Rubber end end)
	shell:show("Body", false)
	local ghost = ctx.rig("Ammonite", CFrame.new(0, -60, 0)) -- the living one of the vision: the same shell, swimming
	ghost:all(function(p, b) p.CastShadow = false if b.name ~= "Pearl" then p.Material = Enum.Material.SmoothPlastic end end)
	local IN_WALL = V(1.42, 0.95, 3.2) -- where it lies in the trench wall (stage space), its coil facing into the trench
	local KNEEL = V(0.45, 0, 2.5)
	local pick = ctx.pick() -- ForgeModels.FossilPickaxe (design3d/fossil.mjs): the ammonite set in a stone head
	local pickScale0, pickH = 1, 5
	if pick then pickScale0, pickH = pick:GetScale(), math.max(pick:GetExtentsSize().Y, 0.1) pick:PivotTo(FAR) end
	local dustPart = ctx.part(v3(0.4, 0.4, 0.4), CFrame.new(IN_WALL), hex("#ffffff"), { Transparency = 1 })
	local dust = ctx.emitter(dustPart, { Texture = S.SMOKE, Color = ColorSequence.new(hex("#c8bca4")), Size = NumberSequence.new({ K(0, 0.2), K(1, 0.9) }), Transparency = NumberSequence.new({ K(0, 0.45), K(1, 1) }), Lifetime = NumberRange.new(0.6, 1.2), Speed = NumberRange.new(0.6, 2), SpreadAngle = Vector2.new(50, 50), EmissionDirection = Enum.NormalId.Left, LightEmission = 0, LightInfluence = 1 })
	local glint = ctx.emitter(dustPart, { Texture = S.SPARK, Color = ColorSequence.new(hex("#ffffff"), hex("#bfe8ee")), Size = NumberSequence.new({ K(0, 0), K(0.3, 0.4), K(1, 0) }), Transparency = NumberSequence.new(0, 1), Lifetime = NumberRange.new(0.5, 1.0), Speed = NumberRange.new(0.5, 2), SpreadAngle = Vector2.new(180, 180), Rotation = NumberRange.new(0, 360), Drag = 2 })
	local heroPart = ctx.part(v3(0.3, 0.3, 0.3), CFrame.new(0, -60, 0), hex("#ffffff"), { Transparency = 1 })
	local rays = Instance.new("BillboardGui")
	rays.Size, rays.LightInfluence, rays.Brightness, rays.Parent = UDim2.fromScale(11, 11), 0, 1.1, heroPart
	local raysIm = Instance.new("ImageLabel")
	raysIm.BackgroundTransparency, raysIm.Image, raysIm.ImageColor3, raysIm.ImageTransparency, raysIm.Size, raysIm.Parent = 1, "rbxassetid://98789616938156", hex("#ffd59a"), 1, UDim2.fromScale(1, 1), rays
	local heroSpark = ctx.emitter(heroPart, { Texture = S.SPARK, Color = ColorSequence.new(hex("#ffffff"), hex("#e8c27a")), Size = NumberSequence.new({ K(0, 0), K(0.3, 0.5), K(1, 0) }), Transparency = NumberSequence.new(0, 1), Lifetime = NumberRange.new(0.8, 1.6), Speed = NumberRange.new(2, 6), SpreadAngle = Vector2.new(180, 180), Rotation = NumberRange.new(0, 360), Drag = 1.5 })
	local hush = ctx.sound(SND.river, 0, 0.35, true) -- the deep underwater hush: the Stone scene's river slowed right down

	-- ===== the timetable =====
	local SEA_END, VISION, DRAIN, BACK = 2.85, 4.95, 6.55, 7.3
	local STROKES = { 3.85, 4.1, 4.35 }
	local function lean(p)
		for _, b in { "Head", "Body" } do
			local cf = p[b]
			if cf then local x, y, z = cf:ToEulerAnglesXYZ() p[b] = CFrame.Angles(-x, y, z) end
		end
		return p
	end
	local function once(key, at, t, fn) if t - at < 0.25 then ctx.once(key, at, t, fn) end end
	local lastPhase = -1

	return function(t, dt)
		-- ===== sea or sunset =====
		local sea = (t < SEA_END and 1 or 0) * (1 - smooth(SEA_END - 0.25, SEA_END, t))
		local vision = smooth(VISION, VISION + 0.45, t) * (1 - smooth(DRAIN, BACK, t))
		local wet = math.max(sea, vision)
		ctx.light(mix(LOOK.sunset, LOOK.sea, wet))
		ctx.atmo(mix(ATMO.sunset, ATMO.sea, wet))
		ctx.cc.TintColor = TINT.sunset:Lerp(TINT.sea, wet)
		ctx.cc.Saturation, ctx.cc.Contrast = 0.06, 0.08
		sun.Transparency = sea > 0.5 and 1 or 0
		seaLight.Brightness = wet * (1.3 + 0.5 * math.sin(t * 6.1) * math.sin(t * 3.7))
		seaLightPart.CFrame = W(math.sin(t * 2.3) * 0.8, 5, 3 + math.cos(t * 1.7) * 1.5)
		specks.Rate = 20 * wet
		bubbles.Rate = 8 * wet
		hush.Volume = 0.35 * wet
		-- the water stands to the sky in the old sea; in the vision it rises from the floor and drains back down
		local level = t < SEA_END and 9 or (2.0 + 2.2) * smooth(VISION, VISION + 0.5, t) * (1 - smooth(DRAIN, BACK, t))
		water.Size = v3(3.18, math.max(level, 0.05), 22)
		water.CFrame = W(0, level / 2, 5)
		water.Transparency = (level < 0.1) and 1 or (t < SEA_END and 0.88 or 0.72)
		for i, f in fish do
			if wet > 0.05 then
				local a = t * (1.1 + (i % 3) * 0.15) + f.ph
				local c = t < SEA_END and V(0.3, 3.2, 6) or V(KNEEL.X, 2.6, KNEEL.Z)
				local p = c + V(math.cos(a) * f.rad, f.y - 2.4 + math.sin(a * 2) * 0.2, math.sin(a) * f.rad)
				f.r.root = W(p.X, p.Y, p.Z) * R(0, -math.deg(a), 0)
			else
				f.r.root = FAR
			end
		end

		-- ===== BORN: the shell sinks and the mud settles =====
		if t < SEA_END then
			local u = smooth(0.2, 1.8, t)
			shell.root = W(0.3 + math.sin(t * 2) * 0.2 * (1 - u), 6.0 - 5.75 * u, 6) * R(math.sin(t * 1.6) * 20 * (1 - u), 90, 30 * (1 - u))
			shell:show("Body", t < 1.4)
			once("settle", 1.8, t, function() mud:Emit(14) ctx.kick(0.8) end)
			once("ages", 2.3, t, function() mud:Emit(30) end)
		end
		ctx.flashAlpha = 0.2 * (1 - lin(SEA_END, SEA_END + 0.3, t)) * (t >= SEA_END - 0.2 and 1 or 0)

		-- ===== the mouse =====
		local phase = t < 3.0 and 0 or (t < 7.6 and 1 or 2)
		if phase ~= lastPhase then lastPhase = phase mouse:snap() end
		local pose, root
		if phase == 0 then
			root = FAR
		elseif phase == 1 then
			-- kneeling at the wall: brushing, a puff of breath, then still as stone while the sea is round her
			local still = smooth(VISION, VISION + 0.3, t) * (1 - smooth(DRAIN, DRAIN + 0.4, t))
			local since = 9
			for _, s in STROKES do if t >= s then since = t - s end end
			local sweep = since < 0.22 and math.sin(since / 0.22 * math.pi) or 0
			local blow = smooth(4.6, 4.75, t) * (1 - smooth(4.85, 5.0, t))
			local write = smooth(DRAIN, DRAIN + 0.3, t)
			pose = { Hips = R(0, 0, 0), LegL = R(70, 0, 8), LegR = R(70, 0, -8),
				Body = R(16 + 10 * blow - 22 * still - 10 * write, 0, 0), Head = R(12 + 14 * blow - 30 * still + 14 * write, -20 * still, 0),
				ArmR = R(70 + 14 * sweep - 30 * still, 0, -10 - 30 * sweep), ForeR = R(40, 0, 0),
				ArmL = R(40 + 30 * write, 0, 14), ForeL = R(40 + 20 * write, 0, 0) }
			root = W(KNEEL.X, -0.45, KNEEL.Z) * R(0, 128 - 60 * write, 0) -- half turned to the cameras along the trench, the wall at her side
			brush.root = mouse:joint("ForeR") * CFrame.new(V(0, -0.44, -0.16)) * R(-90, 0, 0)
			book.root = t >= DRAIN and mouse:joint("ForeL") * CFrame.new(V(0, -0.5, -0.2)) * R(-30, 0, 0) or W(-2.5, 2.6 + 0.86, -0.5)
			mouse:size("Eyes", 1 + 0.2 * still)
			for i, s in STROKES do once("stroke" .. i, s, t, function() ctx.sound(SND.tap, 0.12, 3.2) dust:Emit(6) end) end
			once("blow", 4.7, t, function() dust:Emit(22) sfx("swing", 1.6) glint:Emit(10) end)
			once("vision", VISION, t, function() ctx.sound(SND.bonk, 0.35, 0.5) bubbles:Emit(30) sfx("sparkle", 0.8) end)
			once("call", VISION + 0.6, t, function() ctx.sound(SND.dawn, 0.4, 0.6) end) -- one long low call
			once("drain", DRAIN, t, function() sfx("pop", 0.8) end)
			-- the shell: in the wall, cleaner with each stroke; in the vision its living self swims round her head
			shell.root = W(IN_WALL.X, IN_WALL.Y, IN_WALL.Z) * R(0, 0, 0)
			if vision > 0.02 then
				local a = (t - VISION) * 3.2
				local head = O:PointToObjectSpace(mouse:joint("Head").Position)
				local p = head + V(math.cos(a) * 1.5, 1.0 + math.sin(a * 2) * 0.25, math.sin(a) * 1.5)
				ghost.root = W(p.X, p.Y, p.Z) * R(0, -math.deg(a) - 90, 0)
				ghost:set("Body", R(0, math.sin(t * 9) * 12, 0))
				ghost:alpha("Shell", 1 - vision) ghost:alpha("Body", 1 - vision)
			else
				ghost.root = FAR
			end
		else
			-- NAMED: she stands in the trench with it in both paws, holds it up against the sun; it becomes the pickaxe
			local lift = smooth(8.0, 8.8, t)
			pose = { Body = R(-6 * lift, 0, 0), Head = R(10 - 26 * lift, 0, 0), ArmL = R(60 + 40 * lift, 0, 18), ArmR = R(60 + 40 * lift, 0, -18), ForeL = R(30, 0, 0), ForeR = R(30, 0, 0) }
			root = W(0, 0, 2.4)
			brush.root, book.root, ghost.root = FAR, W(-0.9, 0.04, 1.2) * R(0, 30, 0), FAR
		end
		if pose then mouse:pose(lean(pose)) end
		mouse:smooth(dt, 16)
		mouse.root = root
		if phase == 2 then
			local a = mouse:joint("ForeL") * CFrame.new(V(-0.04, -0.46, -0.2))
			local b = mouse:joint("ForeR") * CFrame.new(V(0.04, -0.46, -0.2))
			local mid = a.Position:Lerp(b.Position, 0.5)
			if t < 9.0 or not pick then
				shell.root = CFrame.new(mid + O:VectorToWorldSpace(V(0, -0.25, -0.15))) * (O - O.Position) * R(0, 90, 0)
			else
				shell.root = FAR
				pick:ScaleTo(pickScale0 * 2.8 / pickH)
				pick:PivotTo(CFrame.new(mid + O:VectorToWorldSpace(V(-0.9, 0.1, -0.3))) * (O - O.Position) * R(0, 0, 10)) -- beside her face on the right, clear of the name card -- beside her face, not over it
			end
			heroPart.CFrame = CFrame.new(mid) * CFrame.new(0, 1.2, 0)
			raysIm.ImageTransparency = 1 - 0.6 * smooth(8.8, 9.2, t) * (1 - smooth(10.6, 11.1, t))
			raysIm.Rotation = t * 18
			heroSpark.Rate = t >= 9.0 and 6 or 0
			once("glint", 8.4, t, function() glint.Parent = heroPart glint:Emit(14) sfx("sparkle", 1.6) end)
			once("reveal", 9.0, t, function() heroSpark:Emit(40) ctx.sound(SND.dawn, 0.5, 1.0) sfx("sparkle", 1.3) ctx.kick(4) ctx.hold(3 / 60) end)
			ctx.name("It swam once.")
			ctx.cardAlpha = smooth(9.2, 9.55, t) * (1 - smooth(10.7, 11.0, t))
		end
		shell:alpha("Pearl", 1 - math.max(sea * 0.6, vision, (phase == 2 and t < 9.0) and 0.5 * smooth(8.2, 8.6, t) or 0))

		-- ===== chapters and camera =====
		if t >= 0.35 and t < 2.85 then ctx.chapter(1, "BORN", "A spiral shell sinks into the mud of an old sea.")
		elseif t >= 3.2 and t < 7.6 then ctx.chapter(2, "MADE", "Brushed out grain by grain. For a moment, it swam.")
		elseif t >= 7.8 then ctx.chapter(3, "NAMED", "Then it settled back into stone in her paws.") end
		local cf, fov, focus
		local function shot(from, aim, f) cf, fov, focus = CFrame.lookAt(from, aim), f, (from - aim).Magnitude end
		if t < 1.5 then -- the old sea: the shell coming down through the blue
			local u = smooth(0, 1.5, t)
			shot(V(-1.6, 3.0 - 0.8 * u, -1.6 + 1.2 * u), V(0.3, 4.2 - 3.2 * u, 6), 50)
		elseif t < 3.0 then -- on the sea floor: the mud settles over it, and settles, and settles
			shot(V(-0.8, 0.9, 3.4 + 0.3 * smooth(1.5, 3.0, t)), V(0.3, 0.3, 6), 40)
		elseif t < 4.0 then -- the dig at sunset: the trench, the shade, the badlands, the sun
			local u = smooth(3.0, 4.0, t)
			shot(V(0.2, 4.4 - 0.6 * u, -7.0 + 1.5 * u), V(0, 2.4, 14), 56)
		elseif t < VISION then -- over her shoulder: the brush at the wall, the shell coming clear
			shot(V(-1.2, 2.0, 7.0), V(0.9, 1.3, 3.0), 50) -- from along the trench: her face, the brush, the shell in the wall
		elseif t < DRAIN then -- low in the sea with her: the shell creature swims round her head
			shot(V(-1.1, 2.3, 6.2), V(0.5, 2.3, 2.6), 56)
		elseif t < 7.6 then -- the water drains into her notebook
			shot(V(-1.0, 1.9, 5.2), V(0.2, 1.0, 2.6), 48)
		elseif t < 8.6 then -- she stands with it in her paws
			shot(V(-0.4, 1.8, -1.6), V(0, 2.0, 2.4), 46)
		else -- low in the trench: it held up against the sun
			local s = smooth(8.6, 10.8, t)
			shot(V(-0.3 + 0.2 * s, 0.8, -2.2 + 0.4 * s), V(0, 2.9, 2.6), 56 - 2 * s)
		end
		ctx.cam, ctx.fov = O * cf, fov
		ctx.dof.FocusDistance = focus
		ctx.dof.InFocusRadius, ctx.dof.FarIntensity, ctx.dof.NearIntensity = 400, 0, 0
	end
end

return M
