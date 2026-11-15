-- ReplicatedStorage.Shared.ForgeWood (src/ForgeWood.luau): the Wood Pickaxe biography, played by ForgeStory.
-- BORN: a birch branch, dropped by a spring storm. MADE: whittled by a young raccoon (Bolt as a kit) in one long night; an acorn
-- falls on his head and becomes the charm. NAMED: sunrise, he holds it up. "His first."
-- Nothing here is shared with another scene: the grove, the storm, the whittling and the sunrise belong to this pickaxe.
-- Models: design3d/wood.mjs (WoodSet, BoltKit, BirchBranch, WoodBlank, Shaving, Acorn, Knife, Leaf). Space: front of a model is -Z,
-- the camera stands at -Z and looks toward the paper backdrop at +Z.
local M = { length = 11.2, named = 7.6 }

local function hex(h) return Color3.fromHex(h) end
local function v3(x, y, z) return Vector3.new(x, y, z) end

function M.setup(ctx)
	local S = ctx.S
	local R, smooth, lin, step, backOut = S.rot, S.smooth, S.lin, S.step, S.backOut
	local O, sfx = ctx.O, ctx.sfx
	local function W(x, y, z) return O * CFrame.new(x, y, z) end -- stage space to world

	local set = ctx.rig("WoodSet")
	local bolt = ctx.rig("BoltKit", CFrame.new(-2.5, 0.56, -2.3) * R(0, -18, 0))
	local branch = ctx.rig("BirchBranch", CFrame.new(5.2, 6.4, 3.4))
	local blank = ctx.rig("WoodBlank", CFrame.new(0, -50, 0), 0.42)
	local knife = ctx.rig("Knife", CFrame.new(0, -50, 0), 1.25)
	local acorn = ctx.rig("Acorn", CFrame.new(0, -50, 0), 0.85)
	local pick = ctx.pick()
	local pickScale0, pickH = 1, 5
	if pick then pickScale0, pickH = pick:GetScale(), math.max(pick:GetExtentsSize().Y, 0.1) pick:PivotTo(W(0, -60, 0)) end
	local function placePick(cf, height) -- stage-space frame, wanted height in studs
		if not pick then return end
		pick:ScaleTo(pickScale0 * height / pickH)
		pick:PivotTo(O * cf)
	end

	-- pooled extras: rain streaks, wind leaves, wood shavings
	local rain = {}
	for i = 1, 46 do
		local p = ctx.part(v3(0.07, 1.7, 0.07), CFrame.new(0, -80, 0), hex("#cfe0ff"), { Material = Enum.Material.Neon, Transparency = 0.45 })
		rain[i] = { p = p, x = (i * 7.31) % 34 - 17, z = (i * 3.77) % 22 - 9, ph = (i * 0.618) % 1 }
	end
	local leaves = {}
	for i = 1, 10 do leaves[i] = { r = ctx.rig("Leaf", CFrame.new(0, -70, 0), 0.9), ph = (i * 0.37) % 1, y = 2 + (i * 1.9) % 7, z = (i * 2.3) % 9 - 2 } end
	local curls = {}
	for i = 1, 12 do curls[i] = { r = ctx.rig("Shaving", CFrame.new(0, -70, 0), 0.7), t0 = -1, from = Vector3.zero, vel = Vector3.zero, spin = 0 } end
	local curlN = 0
	local function tossCurl(from, t)
		curlN = curlN % #curls + 1
		local c = curls[curlN]
		local a = curlN * 2.4
		c.t0, c.from, c.vel, c.spin = t, from, v3(2.2 + math.cos(a) * 1.6, 5.5 + (curlN % 3), -2.6 + math.sin(a) * 1.4), 300 + curlN * 40
	end

	-- lights and emitters
	local firePart = ctx.part(v3(0.4, 0.4, 0.4), CFrame.new(0.6, 1.0, -3.0), hex("#ffb14a"), { Transparency = 1 })
	local fireLight = Instance.new("PointLight")
	fireLight.Color, fireLight.Range, fireLight.Brightness, fireLight.Shadows, fireLight.Parent = hex("#ff9c50"), 26, 0, false, firePart
	local fireGlow = Instance.new("BillboardGui")
	fireGlow.Size, fireGlow.LightInfluence, fireGlow.Brightness, fireGlow.Parent = UDim2.fromScale(11, 11), 0, 1, firePart
	local fireGlowIm = Instance.new("ImageLabel")
	fireGlowIm.BackgroundTransparency, fireGlowIm.Image, fireGlowIm.ImageColor3, fireGlowIm.ImageTransparency, fireGlowIm.Size, fireGlowIm.Parent = 1, S.GLOW, hex("#ff9a4a"), 1, UDim2.fromScale(1, 1), fireGlow
	local embers = ctx.emitter(firePart, { Texture = S.SPARK, Color = ColorSequence.new(hex("#ffe58f"), hex("#ff7d4a")), Size = NumberSequence.new(0.22, 0), Transparency = NumberSequence.new(0, 1), Lifetime = NumberRange.new(1, 2.2), Speed = NumberRange.new(1.5, 3.5), SpreadAngle = Vector2.new(18, 18), Acceleration = v3(0.6, 1.5, 0), EmissionDirection = Enum.NormalId.Top })
	local fireFx = ctx.emitter(firePart, { Texture = S.FIRE, Color = ColorSequence.new(hex("#ffd070"), hex("#f2701c")), Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(1, 0.1) }), Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1) }), Lifetime = NumberRange.new(0.4, 0.7), Speed = NumberRange.new(1.5, 3), SpreadAngle = Vector2.new(12, 12), EmissionDirection = Enum.NormalId.Top, LightEmission = 0.7 })
	local workPart = ctx.part(v3(0.3, 0.3, 0.3), CFrame.new(-2.2, 2.0, -3.2), hex("#ffffff"), { Transparency = 1 })
	local dust = ctx.emitter(workPart, { Texture = S.SMOKE, Color = ColorSequence.new(hex("#f7e9c8")), Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1.5) }), Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 1) }), Lifetime = NumberRange.new(0.5, 0.9), Speed = NumberRange.new(2, 5), SpreadAngle = Vector2.new(35, 35), LightEmission = 0.2, EmissionDirection = Enum.NormalId.Front, Drag = 3 })
	local chips = ctx.emitter(workPart, { Texture = S.SPARK, Color = ColorSequence.new(hex("#fff3d0"), hex("#f0d7a8")), Size = NumberSequence.new(0.28, 0), Transparency = NumberSequence.new(0, 1), Lifetime = NumberRange.new(0.3, 0.6), Speed = NumberRange.new(5, 11), SpreadAngle = Vector2.new(60, 60), Acceleration = v3(0, -30, 0), LightEmission = 0.4 })
	local ribbon = ctx.emitter(workPart, { Texture = S.GLOW, Color = ColorSequence.new(hex("#9fe3c4"), hex("#d8f5e6")), Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(1, 0) }), Transparency = NumberSequence.new(0.1, 1), Lifetime = NumberRange.new(0.45, 0.7), Speed = NumberRange.new(0, 0.4), LightEmission = 0.6 })
	local sparkle = ctx.emitter(workPart, { Texture = S.SPARK, Color = ColorSequence.new(hex("#ffffff"), hex("#ffe6a8")), Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.3, 0.7), NumberSequenceKeypoint.new(1, 0) }), Transparency = NumberSequence.new(0, 1), Lifetime = NumberRange.new(0.6, 1.2), Speed = NumberRange.new(3, 9), SpreadAngle = Vector2.new(180, 180), Rotation = NumberRange.new(0, 360), Drag = 2 })
	local heroPart = ctx.part(v3(0.3, 0.3, 0.3), CFrame.new(-7.0, 5.6, -5.0), hex("#ffffff"), { Transparency = 1 })
	local rays = Instance.new("BillboardGui")
	rays.Size, rays.LightInfluence, rays.Brightness, rays.Parent = UDim2.fromScale(13, 13), 0, 1.4, heroPart
	local raysIm = Instance.new("ImageLabel")
	raysIm.BackgroundTransparency, raysIm.Image, raysIm.ImageColor3, raysIm.ImageTransparency, raysIm.Size, raysIm.Parent = 1, "rbxassetid://98789616938156", hex("#ffe6a8"), 1, UDim2.fromScale(1, 1), rays
	local heroSpark = ctx.emitter(heroPart, { Texture = S.SPARK, Color = ColorSequence.new(hex("#ffffff"), hex("#9fe3c4")), Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.3, 0.6), NumberSequenceKeypoint.new(1, 0) }), Transparency = NumberSequence.new(0, 1), Lifetime = NumberRange.new(0.8, 1.6), Speed = NumberRange.new(2, 7), SpreadAngle = Vector2.new(180, 180), Rotation = NumberRange.new(0, 360), Drag = 1.5 })

	-- the raccoon's acting. Seated base, then five whittling strokes that speed up; the knife arm is the right one.
	local SIT = { LegL = R(74, 0, 10), LegR = R(62, 0, -16), Tail1 = R(-25, 0, 0), Tail2 = R(-20, 0, 0) }
	local HOLD = { ArmL = R(24, 0, 24), ForeL = R(52, 0, 0), ArmR = R(22, 0, -20), ForeR = R(56, 0, 0) }
	local STROKES = { 3.75, 4.2, 4.62, 5.0, 5.34 }
	local keys = { { 3.0, { ArmR = HOLD.ArmR, ForeR = HOLD.ForeR, ArmL = HOLD.ArmL, ForeL = HOLD.ForeL, Head = R(20, 8, -7), Body = R(14, 10, 3) } } }
	for i, at in STROKES do
		table.insert(keys, { at - 0.17, { ArmR = R(-6, 0, -30), ForeR = R(100, 0, 0), Head = R(12, -8, 4), Body = R(8, 6, 0) }, "out" }) -- anticipation: knife drawn back
		table.insert(keys, { at, { ArmR = R(48, 0, -6), ForeR = R(18, 0, 0), Head = R(26, 8, -8), Body = R(20, 12, 4) }, "in" }) -- the cut
		table.insert(keys, { at + 0.12, { ArmR = R(40, 0, -10), ForeR = R(30, 0, 0), Head = R(20, 6, -6), Body = R(15, 10, 3) }, "back" }) -- settle
	end
	table.insert(keys, { 5.55, { ArmR = R(14, 0, -30), ForeR = R(60, 0, 0), Head = R(14, 0, 0), Body = R(8, 0, 0) }, "inout" }) -- lean in to blow the dust
	table.insert(keys, { 5.72, { Head = R(18, 0, 0), Body = R(11, 0, 0) }, "out" })
	table.insert(keys, { 5.95, { Head = R(8, 0, 0), Body = R(4, 0, 0), ArmL = R(30, 0, 30), ForeL = R(58, 0, 0) }, "back" })
	table.insert(keys, { 6.25, { ArmR = R(34, 0, -34), ForeR = R(66, 0, 0), ArmL = R(34, 0, 36), ForeL = R(66, 0, 0), Head = R(12, -10, 6) }, "inout" }) -- tying the ribbon: paws together
	table.insert(keys, { 6.62, { Head = R(12, -10, 6), Body = R(4, 0, 0) }, "hold" })
	table.insert(keys, { 6.66, { Head = R(30, 0, 0), Body = R(18, 0, 0), ArmL = R(150, 0, -36), ForeL = R(70, 0, 0), ArmR = R(150, 0, 36), ForeR = R(70, 0, 0) }, "out" }) -- bonk: he flinches, paws over his head
	table.insert(keys, { 6.9, { Head = R(-26, 14, 0), Body = R(-6, 0, 0), ArmL = R(120, 0, -20), ForeL = R(40, 0, 0), ArmR = R(30, 0, -26), ForeR = R(60, 0, 0) }, "back" }) -- looks up, catches the acorn in his left paw
	table.insert(keys, { 7.18, { Head = R(-8, 26, 8), ArmL = R(96, 0, -6), ForeL = R(60, 0, 0) }, "inout" }) -- holds it up and looks at it
	table.insert(keys, { 7.42, { Head = R(14, 6, -6), Body = R(8, 0, 0), ArmL = R(34, 0, 34), ForeL = R(62, 0, 0) }, "back" }) -- ties it on
	local act = S.track(keys)
	-- NAMED: he stands on the grass and lifts it over his head
	local named = S.track({
		{ 7.6, { LegL = R(0, 0, 0), LegR = R(0, 0, 0), ArmL = R(40, 0, 20), ForeL = R(40, 0, 0), ArmR = R(40, 0, -20), ForeR = R(40, 0, 0), Head = R(6, 0, 0), Body = R(8, 0, 0), Tail1 = R(0, 0, 0), Tail2 = R(0, 0, 0) } },
		{ 8.15, { ArmL = R(20, 0, 10), ForeL = R(70, 0, 0), ArmR = R(20, 0, -10), ForeR = R(70, 0, 0), Head = R(10, 0, 0), Body = R(12, 0, 0), LegL = R(-18, 0, 0), LegR = R(-18, 0, 0) }, "inout" }, -- crouch: anticipation
		{ 8.45, { ArmL = R(120, 0, -30), ForeL = R(30, 0, 0), ArmR = R(170, 0, 10), ForeR = R(6, 0, 0), Head = R(-22, -10, 8), Body = R(-16, -8, 5), LegL = R(-10, 0, 10), LegR = R(14, 0, -8) }, "back" }, -- up it goes, one paw
		{ 9.4, { ArmL = R(60, 0, -56), ForeL = R(70, 0, 0), ArmR = R(166, 0, 14), Head = R(-18, -12, 8), Body = R(-13, -8, 5) }, "inout" }, -- the free paw on his hip
		{ 10.2, { ArmR = R(160, 0, 20), Head = R(-22, -6, 6) }, "inout" },
	})

	-- lighting looks: storm, fire night, dawn
	local LOOK = {
		storm = { Ambient = Color3.fromRGB(100, 96, 136), OutdoorAmbient = Color3.fromRGB(100, 96, 136), Brightness = 1.6, ColorShift_Top = Color3.fromRGB(196, 204, 255), ExposureCompensation = 0 },
		night = { Ambient = Color3.fromRGB(118, 98, 140), OutdoorAmbient = Color3.fromRGB(118, 98, 140), Brightness = 2.4, ColorShift_Top = Color3.fromRGB(255, 160, 96), ExposureCompensation = 0 },
		dawn = { Ambient = Color3.fromRGB(150, 122, 130), OutdoorAmbient = Color3.fromRGB(150, 122, 130), Brightness = 2.4, ColorShift_Top = Color3.fromRGB(255, 214, 150), ExposureCompensation = 0 },
	}
	local function look(a, b, u)
		local out = {}
		for k, v in a do
			local w = b[k]
			if typeof(v) == "Color3" then out[k] = v:Lerp(w, u) else out[k] = v + (w - v) * u end
		end
		ctx.light(out)
	end
	-- the key light per chapter: cold from above in the storm, low and warm from the fire side at night, low from behind at dawn
	local KEYS = { Vector3.new(-0.4, 0.75, -0.5), Vector3.new(0.8, 0.45, 0.45), Vector3.new(0.5, 0.42, -0.7) } -- the night key comes from the fire side and a little behind, so it does not wash the paper sky
	local keyNow = 0
	local function key(i) if keyNow ~= i then keyNow = i ctx.key(KEYS[i]) end end
	set:show("Lightning", false)
	set:show("SunRays", false)
	bolt:show("EyesShut", false)
	branch.root = W(5.2, 6.4, 3.4) * R(0, 20, -12)

	local hitT = -1 -- time of the last stroke that landed
	local stage = 0 -- 0 branch, 1 blank, 2 pickaxe
	local function workCF() return bolt:joint("Body") * CFrame.new(0, 0.42, -1.1) end -- in front of his chest, over his lap

	return function(t, dt)
		local ts = step(t) -- the characters move on twos
		local storm = 1 - smooth(2.7, 3.0, t)
		local dawn = smooth(7.6, 9.2, t)

		-- ===== lighting and the paper sky =====
		if t < 3.0 then key(1) look(LOOK.storm, LOOK.night, 0) elseif t < 7.6 then key(2) look(LOOK.night, LOOK.night, 0) else key(3) look(LOOK.night, LOOK.dawn, dawn) end
		set:alpha("Dawn", 1 - smooth(7.7, 9.6, t))
		set:show("Dawn", t >= 7.6)
		ctx.cc.TintColor = Color3.fromRGB(226, 226, 250):Lerp(Color3.fromRGB(255, 240, 225), smooth(2.9, 3.1, t)):Lerp(Color3.fromRGB(255, 244, 232), dawn)
		ctx.cc.Saturation, ctx.cc.Contrast = 0.12 + 0.1 * dawn, 0.08
		set:set("Cloud1", CFrame.new(-18 * smooth(2.4, 3.0, t) + 4 * (1 - smooth(0, 1.2, t)) + math.sin(t * 0.9) * 0.3, 0, 0))
		set:set("Cloud2", CFrame.new(20 * smooth(2.4, 3.0, t) - 5 * (1 - smooth(0, 1.2, t)) + math.sin(t * 0.7 + 1) * 0.3, 0, 0))
		set:alpha("Cloud1", smooth(2.6, 3.0, t)) set:alpha("Cloud2", smooth(2.6, 3.0, t))
		set:alpha("Stars", t < 3.0 and 0.75 or math.max(0.05 + 0.25 * (0.5 + 0.5 * math.sin(ts * 9)), dawn))
		set:set("Stars", CFrame.new(0, 0, 0) * R(0, 0, math.sin(t * 0.2) * 0.6))
		set:set("Sun", CFrame.new(0, -9 + 12.5 * smooth(7.6, 10.2, t), 0))
		set:show("SunRays", t >= 7.9)
		set:alpha("SunRays", 1 - 0.75 * smooth(7.9, 9.4, t))
		set:set("SunRays", R(0, 0, t * 8))
		-- lightning: two flickers, the second one breaks the branch
		local bolt1 = (t >= 0.95 and t < 1.02) or (t >= 1.32 and t < 1.46)
		set:show("Lightning", bolt1)
		ctx.flashAlpha = math.max((t >= 0.95 and t < 1.0) and 0.35 or 0, 0.85 * (1 - lin(1.32, 1.62, t)) * (t >= 1.32 and 1 or 0), (1 - lin(3.0, 3.22, t)) * (t >= 2.94 and 1 or 0) * smooth(2.94, 3.0, t), 0.9 * (1 - lin(8.45, 8.8, t)) * (t >= 8.45 and 1 or 0))
		ctx.once("thunder1", 0.95, t, function() sfx("breakRock", 0.55) end)
		ctx.once("thunder2", 1.32, t, function() sfx("breakRock", 0.4) sfx("hit", 0.5) ctx.shake(1.1) ctx.hold(3 / 60) end)

		-- ===== storm: wind in the canopies, rain, leaves =====
		local gust = storm * (0.6 + 0.4 * math.sin(t * 2.3))
		for i = 1, 3 do
			set:set("Canopy" .. i, R(math.sin(t * 5 + i) * 3 * gust, 0, (6 + math.sin(t * 7.3 + i * 2) * 5) * gust + math.sin(t * 1.3 + i) * 0.8))
			set:set("Trunk" .. i, R(0, 0, 1.6 * gust))
		end
		for i, d in rain do
			local u = (t * 1.9 + d.ph) % 1
			d.p.CFrame = W(d.x + u * 5, 21 - u * 22, d.z) * R(0, 0, 13)
			d.p.Transparency = storm > 0.02 and 0.45 + 0.55 * (1 - storm) or 1
		end
		for _, l in leaves do
			local u = (t * 0.55 + l.ph) % 1
			l.r.root = W(-16 + u * 32, l.y + math.sin(u * 9 + l.ph * 6) * 1.2 - u * 1.5, l.z) * R(t * 300 + l.ph * 360, t * 170, 0)
			l.r:all(function(p) p.Transparency = storm > 0.02 and 0 or 1 end)
		end

		-- ===== the branch: hangs, snaps, falls, bounces, then lies in his lap =====
		if t < 1.36 then
			branch.root = W(5.2, 6.4, 3.4) * R(0, 20, -12 + math.sin(t * 6) * 4 * gust)
			branch.scale = 1.5
		elseif t < 3.0 then
			local u = t - 1.36
			local fall = math.min(u / 0.62, 1)
			local y = 6.4 - (6.4 - 0.3) * fall * fall
			local b = u > 0.62 and math.abs(math.sin((u - 0.62) * 9)) * 1.1 * math.exp(-(u - 0.62) * 4.5) or 0
			branch.root = W(5.2 - 4.4 * fall, y + b, 3.4 - 6.4 * fall) * R(fall * 150 * (1 - fall) , 20 + fall * 60, -12 + fall * 372)
			branch.scale = 1.5
			ctx.once("snap", 1.36, t, function() workPart.CFrame = W(5.2, 6.4, 3.4) chips:Emit(24) end)
			ctx.once("land", 1.36 + 0.62, t, function() sfx("land", 0.8) sfx("swing", 0.7) ctx.kick(3) ctx.hold(2 / 60) end)
		end

		-- ===== the fire =====
		local fire = smooth(3.0, 3.3, t) * (1 - 0.75 * smooth(8.2, 10, t))
		for i, n in { "Flame1", "Flame2", "Flame3", "FlameCore" } do
			local f = 0.82 + 0.3 * math.abs(math.sin(ts * 11 + i * 1.7))
			set:size(n, Vector3.new(0.9 + 0.1 * math.sin(ts * 13 + i), f, 0.9) * math.max(fire, 0.001))
			set:show(n, fire > 0.01)
			set:set(n, R(0, 0, math.sin(ts * 8 + i * 2) * 5))
		end
		fireLight.Brightness = 9 * fire * (0.85 + 0.15 * math.sin(ts * 12))
		fireGlowIm.ImageTransparency = 1 - 0.42 * fire
		embers.Rate = 9 * fire
		fireFx.Rate = 16 * fire

		-- ===== the raccoon =====
		local breathe = math.sin(ts * 2.6) * 0.012
		bolt:size("Body", Vector3.new(1 + breathe, 1 - breathe, 1 + breathe))
		local blink = (ts % 2.3) < 0.1
		local shut = blink or (t >= 6.62 and t < 6.95) or (t >= 8.45)
		bolt:show("Eyes", not shut) bolt:show("EyesShut", shut)
		bolt:set("EarL", R(0, 0, math.sin(ts * 3.1) * 4 + ((ts % 1.7) < 0.09 and 16 or 0)))
		bolt:set("EarR", R(0, 0, -math.sin(ts * 3.1 + 1) * 4 - ((ts % 2.1) < 0.09 and 16 or 0)))
		if t < 3.0 then
			bolt.root = W(0, -60, 0)
		elseif t < 7.6 then
			bolt.root = W(-2.5, 0.56, -2.3) * R(0, -18, 0)
			bolt:pose(SIT)
			bolt:pose(act(ts))
			bolt:set("Tail1", R(-25, 38 + math.sin(ts * 4) * 14, 0)) bolt:set("Tail2", R(-20, 30 + math.sin(ts * 4 - 0.8) * 18, 0))
			bolt:set("LegL", R(74 + math.sin(ts * 3) * 6, 0, 10)) bolt:set("LegR", R(60 - math.sin(ts * 3) * 8, 0, -16)) -- feet kick while he works
			local bonk = t >= 6.62 and math.max(0, 1 - (t - 6.62) / 0.3) or 0
			bolt:size("Head", Vector3.new(1 + 0.12 * bonk, 1 - 0.2 * bonk, 1 + 0.12 * bonk))
		else
			local hop = math.sin(math.clamp((t - 8.3) / 0.45, 0, 1) * math.pi) * 1.2 -- a little jump as he lifts it
			bolt.root = W(-7.0, hop, -5.0) * R(0, -16, 0) -- out from under the birches, the sunrise behind him
			bolt:pose(named(ts))
			bolt:set("Tail1", R(0, math.sin(ts * 9) * 26, 0)) bolt:set("Tail2", R(0, math.sin(ts * 9 - 0.8) * 30, 0))
			bolt:size("Head", Vector3.one)
		end
		bolt:update()

		-- ===== the work: strokes, shavings, the three states of the wood =====
		local work = workCF()
		if t >= 3.0 then workPart.CFrame = work end
		for i, at in STROKES do
			ctx.once("stroke" .. i, at, t, function()
				hitT = at
				sfx("swing", 1.0 + i * 0.12) sfx("hit", 1.5 + i * 0.1)
				ctx.hold(2 / 60) ctx.kick(1.6)
				chips:Emit(10)
				tossCurl(work.Position, at) tossCurl(work.Position + Vector3.new(0.3, 0, 0), at + 0.03)
				if i == 1 then branch:show("Leaves", false) end
				if i == 3 then stage = 1 dust:Emit(14) sfx("pop", 1.2) end
			end)
		end
		ctx.once("blow", 5.72, t, function() dust:Emit(26) sfx("swing", 1.6) end)
		ctx.once("tie", 6.25, t, function() stage = 2 sparkle:Emit(26) sfx("sparkle", 1.2) sfx("pop", 1.4) end)
		ribbon.Rate = (t >= 5.95 and t < 6.3) and 60 or 0
		if t >= 5.95 and t < 6.3 then -- the mint ribbon winds round it: the emitter circles the work
			local a = (t - 5.95) * 26
			workPart.CFrame = work * CFrame.new(math.cos(a) * 1.3, math.sin(a) * 0.5 + (t - 6.1) * 3, math.sin(a) * 0.7)
		end
		for _, c in curls do
			local u = t - c.t0
			if c.t0 > 0 and u >= 0 and u < 1.1 then
				c.r.root = CFrame.new(c.from + c.vel * u + Vector3.new(0, -16 * u * u, 0)) * R(u * c.spin, u * c.spin * 0.7, 0)
				c.r:all(function(p) p.Transparency = math.clamp((u - 0.8) / 0.3, 0, 1) end)
			else
				c.r.root = W(0, -70, 0)
			end
		end
		local jolt = hitT > 0 and math.max(0, 1 - (t - hitT) / 0.12) or 0
		if t >= 3.0 and t < 7.6 then
			local lap = work * CFrame.new(-0.25, -0.1 - 0.1 * jolt, 0.1) * R(0, 0, 18 - 6 * jolt)
			branch.root = stage == 0 and lap * R(0, 180, 0) * CFrame.new(-0.4, 0, 0) or W(0, -60, 0)
			branch.scale = 0.6
			blank.root = stage == 1 and lap * R(-70, 0, 72) * CFrame.new(0, 0.45, 0) or W(0, -60, 0)
			if stage == 2 then
				local pop = backOut(lin(6.25, 6.5, t))
				placePick(O:ToObjectSpace(lap) * CFrame.new(0.15, -0.2, -0.15) * R(0, 180, 78), 2.9 * (0.6 + 0.4 * pop))
			end
			knife.root = t < 5.9 and bolt:joint("ForeR") * CFrame.new(0.12, -0.62, -0.22) * R(-100, 0, 0) or W(0, -60, 0)
		elseif t >= 7.6 then
			branch.root, blank.root, knife.root = W(0, -60, 0), W(0, -60, 0), W(0, -60, 0)
		end

		-- ===== the acorn: falls, bonks him, hops onto the pickaxe =====
		if t >= 6.2 and t < 7.25 then
			local head = bolt:joint("Head").Position + Vector3.new(0, 1.75, 0)
			local cf
			if t < 6.62 then
				local u = (t - 6.2) / 0.42
				cf = CFrame.new(head + Vector3.new(0, 9 * (1 - u * u), 0)) * R(u * 300, 0, 20)
			elseif t < 6.9 then -- bounces off his head
				local u = (t - 6.62) / 0.28
				cf = CFrame.new(head + Vector3.new(0.5 * u, math.sin(u * math.pi * 0.8) * 2.2, -0.2 * u)) * R(u * 400, u * 200, 0)
			else -- caught: it sits in his left paw, then goes onto the pickaxe
				local paw = (bolt:joint("ForeL") * CFrame.new(-0.11, -0.62, -0.25)).Position
				local air = head + Vector3.new(0.5, math.sin(math.pi * 0.8) * 2.2, -0.2)
				local to = paw:Lerp(work.Position, smooth(7.18, 7.25, t))
				cf = CFrame.new(air:Lerp(to, smooth(6.9, 6.98, t))) * R(0, t * 90, 10)
			end
			acorn.root = cf
			ctx.once("bonk", 6.62, t, function() sfx("pop", 0.8) sfx("land", 1.4) ctx.hold(3 / 60) ctx.kick(2.2) ctx.shake(0.35) end)
		else
			acorn.root = W(0, -60, 0)
			ctx.once("charm", 7.25, t, function() sparkle:Emit(12) sfx("coin", 1.3) end)
		end

		-- ===== NAMED: the lift and the hero turn =====
		if t >= 7.6 then
			local hands = (bolt:joint("ForeR") * CFrame.new(0.11, -0.5, -0.2)).Position:Lerp((bolt:joint("ForeL").Position + bolt:joint("ForeR").Position) / 2, 1 - smooth(8.15, 8.45, t))
			local lift = smooth(8.45, 9.3, t)
			local at = O:PointToObjectSpace(hands) + Vector3.new(0.3 * lift, 0.9 + 0.5 * lift + math.sin(t * 2) * 0.12 * lift, -0.3 * lift)
			local spin = smooth(8.5, 10.0, t) * 360
			placePick(CFrame.new(at) * R(0, 180 + spin, 78 - 98 * smooth(8.2, 8.5, t)), 2.9 + 0.7 * lift)
			heroPart.CFrame = W(at.X, at.Y + 0.6, at.Z)
			raysIm.ImageTransparency = 1 - 0.75 * smooth(8.45, 8.8, t) * (1 - smooth(10.6, 11.1, t))
			raysIm.Rotation = t * 22
			ctx.once("reveal", 8.45, t, function() heroSpark:Emit(46) sfx("upgrade", 1) sfx("sparkle", 1.3) ctx.kick(5) ctx.hold(4 / 60) end)
			heroSpark.Rate = t >= 8.6 and 10 or 0
			ctx.name("His first.")
			ctx.cardAlpha = smooth(9.0, 9.35, t) * (1 - smooth(10.7, 11.0, t))
		end

		-- ===== chapters and camera =====
		if t >= 0.35 and t < 3.0 then ctx.chapter(1, "BORN", "A birch branch, dropped by a spring storm.")
		elseif t >= 3.2 and t < 7.6 then ctx.chapter(2, "MADE", "Whittled by a young raccoon in one long night.")
		elseif t >= 7.8 then ctx.chapter(3, "NAMED", "Morning. The first pickaxe he ever made.") end
		local cf, fov, focus
		local function shot(from, aim, f) cf, fov, focus = CFrame.lookAt(from, aim), f, (from - aim).Magnitude end
		local V = Vector3.new
		if t < 1.36 then -- close on the branch, high in the birch, while the storm pulls at it
			shot(V(2.6 - 0.5 * smooth(0, 1.36, t), 5.2, -3.4), V(5.0, 6.5, 3.2), 40)
		elseif t < 3.0 then -- it snaps: low and wide, the camera follows it down to the grass
			local bp = O:PointToObjectSpace(branch.root.Position)
			shot(V(-0.8, 0.9, -9.5 + 2.0 * smooth(1.6, 2.8, t)), V(4.6, 6.4, 3.4):Lerp(bp, smooth(1.36, 1.7, t)), 52 - 12 * smooth(1.6, 2.8, t))
		elseif t < 3.62 then -- the camp: fire on the left, the raccoon on his log
			shot(V(2.4, 2.4, -11.8 + 0.6 * smooth(3.0, 3.62, t)), V(-0.9, 2.0, -2.6), 44)
		elseif t < 5.5 then -- close on his paws for the knife work
			shot(V(-0.6 + 0.3 * smooth(3.62, 5.5, t), 2.7, -7.8), V(-2.75, 2.5, -3.2), 38)
		elseif t < 6.2 then -- front on: he blows the dust off and ties the ribbon
			shot(V(-1.9, 2.5, -8.6 + 0.5 * smooth(5.5, 6.2, t)), V(-2.7, 2.35, -3.0), 40)
		elseif t < 6.62 then -- room above his head: something is falling
			shot(V(-0.4, 1.9, -9.4), V(-2.6, 3.7, -2.6), 46)
		else -- his face, and the acorn in his paw
			shot(V(-1.3 - 0.2 * smooth(6.62, 7.6, t), 2.9, -7.2), V(-2.7, 2.85, -2.7), 38 - 3 * smooth(6.62, 7.6, t))
		end
		if t >= 7.6 then -- low at his feet, looking up: the pickaxe against the sunrise
			local up = smooth(8.3, 9.2, t)
			shot(V(-4.4 - 0.3 * smooth(8.4, 10.8, t), 0.7, -15.4 + 0.8 * smooth(8.4, 10.8, t)), V(-7.0, 2.3, -5.0):Lerp(V(-7.0, 3.3, -5.0), up), 47 - 2 * smooth(8.4, 10.8, t))
		end
		ctx.cam, ctx.fov = O * cf, fov
		ctx.dof.FocusDistance = focus
		ctx.dof.InFocusRadius = (t >= 1.36 and t < 3.0) and 60 or 7
		ctx.dof.FarIntensity = (t >= 1.36 and t < 3.0) and 0.1 or 0.35
	end
end

return M
