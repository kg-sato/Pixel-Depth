-- ReplicatedStorage.Shared.ForgeGeode (src/ForgeGeode.luau): the Geode Pickaxe biography, played by ForgeStory.
-- BORN: at a stone stall on the quarry road a plain grey rock is weighed and tossed in the reject barrel, again and again.
-- MADE: a hedgehog child takes the one nobody wanted, sits down in the dust and taps it with her toy hammer until a crack
-- glows and it opens on a cave of violet crystal; the stallkeeper stops and stares. NAMED: she holds the two halves up to
-- the sun. "Nobody wanted it."
-- The setting is a place of its own (references refs/forge/sheets/geode_setting_s11.png and hedgehog_views_s11.png).
-- Built from design3d/geode.mjs. The sky is the Stone scene's summer picture (a pale noon sky).
-- Space: front of a model is -Z, the camera stands at -Z and looks up the road toward +Z. +X is screen left: the stall is
-- on the left at x = +4, the cart on the right, the quarry terraces and windmills far off on the right.
-- Every time in this file is a story second; the clock runs at 0.58 of real time (see ForgeWood).
local M = { length = 11.2, named = 7.6, open = true, pace = 0.58, fastPace = 0.75 }
local IMG = { noon = { side = "123739504725049", up = "81181571686796", dn = "95878689619602", sun = 7 } }
local SND = { tap = 90326072989009, bonk = 101020483687867, dawn = 85010698086137 }

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

	-- ===== the place =====
	local land = ctx.prop("GeodeLand")
	matte(land)
	land:all(function(p, b) if b.name == "Terraces" then p.CastShadow = false end end)
	local STALL = V(4, 0, 2)
	local stall = ctx.rig("GeodeStall", CFrame.new(STALL))
	matte(stall)
	stall:all(function(p, b) if b.name == "Trays" then p.Material = Enum.Material.SmoothPlastic end end)
	matte(ctx.prop("MarketBits"))
	local BARREL = V(2.2, 0, 0.7)
	matte(ctx.prop("RejectBarrel", CFrame.new(BARREL)))
	local cart = ctx.rig("HandCart", CFrame.new(-4.6, 0, 1.2) * R(0, 12, 0))
	matte(cart)
	local mills = {}
	for i, at in { { V(-36, 23.4, 60), 0, 1 }, { V(-6, 10, 110), -10, 0.8 }, { V(-60, 30, 30), 30, 1.1 } } do
		local w = ctx.rig("Windmill", CFrame.new(at[1]) * R(0, at[2], 0), at[3])
		matte(w)
		mills[i] = w
	end
	ctx.sky(IMG.noon)
	ctx.atmo({ Density = 0.3, Haze = 2.2, Color = rgb(240, 216, 186), Decay = rgb(200, 170, 150), Glare = 0.1, Offset = 0.2 })
	ctx.light({ Brightness = 2.1, Ambient = rgb(150, 128, 116), OutdoorAmbient = rgb(168, 146, 130), ColorShift_Top = rgb(255, 236, 206), ExposureCompensation = -0.25, EnvironmentDiffuseScale = 0.4, EnvironmentSpecularScale = 0 })
	ctx.key(V(0.5, 1.6, -0.6))
	ctx.cc.TintColor = rgb(255, 246, 232)
	ctx.cc.Saturation, ctx.cc.Contrast = 0.04, 0.08

	-- dust in the air, and on the road
	local air = ctx.part(v3(16, 5, 16), CFrame.new(0, 2.5, 2), hex("#ffffff"), { Transparency = 1 })
	local motes = ctx.emitter(air, { Texture = S.GLOW, Color = ColorSequence.new(hex("#fff0d8")), Size = NumberSequence.new({ K(0, 0), K(0.2, 0.06), K(0.8, 0.06), K(1, 0) }), Transparency = NumberSequence.new(0.35), Lifetime = NumberRange.new(4, 7), Speed = NumberRange.new(0.1, 0.5), SpreadAngle = Vector2.new(180, 180), LightEmission = 0.3, LightInfluence = 0.8, Rate = 14 })
	motes:Emit(50)
	local roadPart = ctx.part(v3(4, 0.2, 30), CFrame.new(-0.6, 0.1, 10), hex("#ffffff"), { Transparency = 1 })
	local roadDust = ctx.emitter(roadPart, { Texture = S.SMOKE, Color = ColorSequence.new(hex("#e8c49a")), Size = NumberSequence.new({ K(0, 0.6), K(1, 2.4) }), Transparency = NumberSequence.new({ K(0, 0.75), K(1, 1) }), Lifetime = NumberRange.new(2, 3.5), Speed = NumberRange.new(0.5, 1.5), SpreadAngle = Vector2.new(60, 60), EmissionDirection = Enum.NormalId.Top, Acceleration = v3(-0.6, 0, 0), LightEmission = 0, LightInfluence = 1, Rate = 3 })

	-- ===== the people and the rock =====
	local keeper = ctx.rig("Stallkeeper", CFrame.new(STALL + V(0.3, 0, 0.9)) * R(0, 0, 0))
	matte(keeper)
	local kid = ctx.rig("HedgehogKit", CFrame.new(0, -60, 0))
	matte(kid)
	kid:show("EyesShut", false)
	kid:all(function(p, b) if b.name == "Eyes" then p.Material = Enum.Material.SmoothPlastic end end)
	local hammer = ctx.rig("ToyHammer", CFrame.new(0, -60, 0))
	matte(hammer)
	local rock = ctx.rig("GeodeRock", CFrame.new(0, -60, 0))
	rock:all(function(p, b) if b.name == "HalfA" or b.name == "HalfB" then p.Material = Enum.Material.Rubber end if b.name == "Crack" or string.find(b.name, "Crystal") then p.CastShadow = false end end)
	rock:show("Crack", false)
	local pick = ctx.pick() -- ForgeModels.GeodePickaxe (design3d/picks.mjs): the two halves on her toy hammer's head, her hat ribbon round the haft
	local pickScale0, pickH = 1, 5
	if pick then pickScale0, pickH = pick:GetScale(), math.max(pick:GetExtentsSize().Y, 0.1) pick:PivotTo(FAR) end

	-- the violet light from inside the rock, and what it throws
	local glowPart = ctx.part(v3(0.2, 0.2, 0.2), CFrame.new(0, -60, 0), hex("#9b6fd6"), { Transparency = 1 })
	local violet = Instance.new("PointLight")
	violet.Color, violet.Range, violet.Brightness, violet.Shadows, violet.Parent = hex("#b48cff"), 9, 0, false, glowPart
	local crystalDust = ctx.emitter(glowPart, { Texture = S.SPARK, Color = ColorSequence.new(hex("#ffffff"), hex("#b48cff")), Size = NumberSequence.new({ K(0, 0), K(0.3, 0.3), K(1, 0) }), Transparency = NumberSequence.new(0, 1), Lifetime = NumberRange.new(0.6, 1.4), Speed = NumberRange.new(0.6, 2.4), SpreadAngle = Vector2.new(180, 180), Rotation = NumberRange.new(0, 360), Drag = 2 })
	local spots = ctx.emitter(glowPart, { Texture = S.GLOW, Color = ColorSequence.new(hex("#c8a8ff")), Size = NumberSequence.new({ K(0, 0), K(0.3, 0.22), K(1, 0) }), Transparency = NumberSequence.new(0.2), Lifetime = NumberRange.new(1.2, 2.2), Speed = NumberRange.new(1.5, 4), SpreadAngle = Vector2.new(70, 70), EmissionDirection = Enum.NormalId.Top, Drag = 1.2, LightEmission = 0.8 })
	local tapDust = ctx.emitter(glowPart, { Texture = S.SMOKE, Color = ColorSequence.new(hex("#e0c8a8")), Size = NumberSequence.new({ K(0, 0.15), K(1, 0.6) }), Transparency = NumberSequence.new({ K(0, 0.5), K(1, 1) }), Lifetime = NumberRange.new(0.4, 0.7), Speed = NumberRange.new(0.5, 1.5), SpreadAngle = Vector2.new(80, 80), EmissionDirection = Enum.NormalId.Top, LightEmission = 0, LightInfluence = 1 })
	local heroPart = ctx.part(v3(0.3, 0.3, 0.3), CFrame.new(0, -60, 0), hex("#ffffff"), { Transparency = 1 })
	local rays = Instance.new("BillboardGui")
	rays.Size, rays.LightInfluence, rays.Brightness, rays.Parent = UDim2.fromScale(9, 9), 0, 1.1, heroPart
	local raysIm = Instance.new("ImageLabel")
	raysIm.BackgroundTransparency, raysIm.Image, raysIm.ImageColor3, raysIm.ImageTransparency, raysIm.Size, raysIm.Parent = 1, "rbxassetid://98789616938156", hex("#c8a8ff"), 1, UDim2.fromScale(1, 1), rays
	local heroSpark = ctx.emitter(heroPart, { Texture = S.SPARK, Color = ColorSequence.new(hex("#ffffff"), hex("#9b6fd6")), Size = NumberSequence.new({ K(0, 0), K(0.3, 0.5), K(1, 0) }), Transparency = NumberSequence.new(0, 1), Lifetime = NumberRange.new(0.8, 1.6), Speed = NumberRange.new(2, 6), SpreadAngle = Vector2.new(180, 180), Rotation = NumberRange.new(0, 360), Drag = 1.5 })

	-- ===== the timetable =====
	local SCALES = STALL + V(-1.4, 2.62, -0.5) -- the left pan of the scales (stage space)
	local INBAR = BARREL + V(0, 1.35, 0)
	local TOSSES = { 0.7, 1.6, 2.5 } -- each toss: weighed at -0.45, thrown at the time, lands 0.35 later
	local SIT = V(1.0, 0, -0.9) -- where she sits in the dust, between the barrel and the cameras
	local TAPS = { 5.0, 5.35, 5.7, 6.05, 6.4 }
	local OPEN = 6.85
	local function lean(p)
		for _, b in { "Head", "Body" } do
			local cf = p[b]
			if cf then local x, y, z = cf:ToEulerAnglesXYZ() p[b] = CFrame.Angles(-x, y, z) end
		end
		return p
	end
	local function once(key, at, t, fn) if t - at < 0.25 then ctx.once(key, at, t, fn) end end
	local PAW = V(0, -0.42, -0.16)
	local lastPhase = -1

	return function(t, dt)
		-- ===== the stall: bunting stirs, the cart creaks past, the windmills turn =====
		stall:set("Flags", R(math.sin(t * 3.1) * 3, 0, 0))
		for i, w in mills do w:set("Sails", R(0, 0, t * (24 + i * 6))) end
		local cz = -4 + 30 * lin(0, 11.2, t)
		cart.root = W(-4.6 + 0.3 * math.sin(t), 0, 1.2 + (t < 3.2 and 0 or 0)) * R(0, 12, 0)
		cart:set("WheelL", R(0, 0, 0)) cart:set("WheelR", R(0, 0, 0))
		roadDust.Rate = 3

		-- ===== the keeper: weighs it, frowns, tosses it; then stops and stares =====
		local kpose = { Head = R(10, 0, 0), Body = R(4, 0, 0), ArmL = R(40, 0, 10), ForeL = R(40, 0, 0), ArmR = R(40, 0, -10), ForeR = R(40, 0, 0) }
		local rockHeld = nil
		if t < 3.2 then
			for i, ts in TOSSES do
				local u = t - (ts - 0.45)
				if u >= 0 and u < 0.45 then -- weighs it on the scales, then lifts it
					kpose = { Head = R(22, -20, 0), Body = R(10, -10, 0), ArmR = R(70 + 40 * smooth(0.25, 0.45, u), 0, -24), ForeR = R(50, 0, 0), ArmL = R(30, 0, 12), ForeL = R(40, 0, 0) }
					rockHeld = u < 0.28 and CFrame.new(SCALES) or nil
				elseif u >= 0.45 and u < 0.8 then -- the toss
					kpose = { Head = R(0, -30, 0), Body = R(-6, -24, 0), ArmR = R(20, 0, -50), ForeR = R(10, 0, 0), ArmL = R(30, 0, 12), ForeL = R(40, 0, 0) }
				end
				once("toss" .. i, ts, t, function() sfx("swing", 1.4) end)
				once("land" .. i, ts + 0.35, t, function() ctx.sound(SND.tap, 0.4, 0.8) sfx("land", 0.9) ctx.kick(0.8) end)
			end
		elseif t >= OPEN then -- he stops and stares
			local s = smooth(OPEN, OPEN + 0.4, t)
			kpose = { Head = R(26 * s, 50 * s, 0), Body = R(16 * s, 30 * s, 0), ArmL = R(30 + 40 * s, 0, 12), ForeL = R(40 + 30 * s, 0, 0), ArmR = R(30, 0, -12), ForeR = R(40, 0, 0) }
		end
		keeper:pose(lean(kpose))
		keeper:smooth(dt, 16)

		-- the rock in BORN: on the scales, in his paw, flying, in the barrel
		if t < 3.2 then
			local placed = false
			for i, ts in TOSSES do
				local u = t - (ts - 0.45)
				if u >= 0 and u < 0.8 then
					placed = true
					if u < 0.28 then rock.root = W(SCALES.X, SCALES.Y + 0.4, SCALES.Z)
					elseif u < 0.45 then rock.root = keeper:joint("ForeR") * CFrame.new(V(0.04, -0.42, -0.2))
					else
						local f = smooth(0.45, 0.8, u)
						local a, b = keeper:joint("ForeR").Position, O * INBAR
						rock.root = CFrame.new(a:Lerp(b, f) + V(0, math.sin(f * math.pi) * 1.4, 0)) * R(f * 400, f * 200, 0)
					end
				end
			end
			if not placed then rock.root = W(INBAR.X + 0.1, INBAR.Y - 0.05, INBAR.Z) * R(20, 40, 0) end
		end

		-- ===== the child =====
		local phase = t < 3.2 and 0 or (t < 4.8 and 1 or (t < 7.6 and 2 or 3))
		if phase ~= lastPhase then lastPhase = phase kid:snap() end
		local pose, root
		local open = smooth(OPEN, OPEN + 0.35, t)
		if phase == 0 then
			root = FAR
		elseif phase == 1 then
			-- she comes along the road from the right, stops at the barrel, looks in, takes the grey one out
			local walk = smooth(3.2, 4.0, t)
			local step = math.sin(t * 16) * (1 - smooth(3.9, 4.0, t))
			local p = V(-3.0, 0, -0.6):Lerp(BARREL + V(-0.9, 0, -0.5), walk)
			local reach = smooth(4.05, 4.4, t) * (1 - smooth(4.5, 4.8, t))
			pose = { Body = R(8 + 30 * reach, 0, 0), Head = R(16 + 20 * reach, 0, 0), LegL = R(step * 24, 0, 0), LegR = R(-step * 24, 0, 0), ArmL = R(20 + 90 * reach, 0, 10), ForeL = R(20, 0, 0), ArmR = R(-step * 20 + 30, 0, -10), ForeR = R(30, 0, 0) }
			root = W(p.X, p.Y + math.abs(step) * 0.05, p.Z) * R(0, -60 + 30 * walk, 0)
			hammer.root = kid:joint("ForeR") * CFrame.new(PAW) * R(-90, 0, 0)
			if t >= 4.4 then rock.root = kid:joint("ForeL") * CFrame.new(V(-0.06, -0.48, -0.2)) end
			if t < 4.4 then rock.root = W(INBAR.X + 0.1, INBAR.Y - 0.05, INBAR.Z) * R(20, 40, 0) end
		elseif phase == 2 then
			-- she sits in the dust, the rock between her feet, and taps; then she is still, round-eyed
			local s = t - TAPS[1]
			local since = 9
			for _, tp in TAPS do if t >= tp then since = t - tp end end
			local hit = since < 0.08
			local up = (not hit) and since < 0.3
			local wonder = smooth(OPEN, OPEN + 0.3, t)
			pose = { Hips = R(0, 0, 0), Body = R(10 - 18 * wonder, 0, 0), Head = R(16 - 26 * wonder, 0, 0), LegL = R(80, 0, 14), LegR = R(80, 0, -14),
				ArmR = (t < OPEN) and (hit and R(70, 0, -10) or (up and R(130, 0, -14) or R(90, 0, -12))) or R(30, 0, -20), ForeR = R(hit and 10 or 40, 0, 0),
				ArmL = R(60 - 30 * wonder, 0, 16), ForeL = R(30, 0, 0) }
			root = W(SIT.X, -0.42, SIT.Z) * R(0, 18, 0)
			hammer.root = kid:joint("ForeR") * CFrame.new(PAW) * R(-90, 0, 0)
			local ROCK = V(SIT.X - 0.25, 0.36, SIT.Z - 1.35) -- in the dust in front of her feet
			glowPart.CFrame = W(ROCK.X, ROCK.Y + 0.1, ROCK.Z)
			local apart = backOut(open)
			rock.root = W(ROCK.X, ROCK.Y, ROCK.Z) * R(0, 70, 0)
			rock:set("HalfA", CFrame.new(0.28 * apart, 0, 0) * R(0, 0, -40 * apart))
			rock:set("HalfB", CFrame.new(-0.28 * apart, 0, 0) * R(0, 0, 40 * apart))
			for i, tp in TAPS do once("tap" .. i, tp, t, function() ctx.sound(SND.tap, 0.45, 1.5 + i * 0.05) tapDust:Emit(5) ctx.kick(0.6) end) end
			kid:size("Eyes", 1 + 0.25 * wonder)
			kid:size("Mouth", V(1, 1 + 0.8 * wonder, 1))
		else
			-- NAMED: she stands and holds the two halves up to the sun, one in each paw; the pickaxe comes out of the light
			local lift = smooth(7.7, 8.5, t) * (1 - smooth(8.4, 9.0, t)) + smooth(9.1, 9.7, t)
			pose = { Body = R(-8 * lift, 0, 0), Head = R(-24 * lift, 0, 0), ArmL = R(60 + 20 * lift, 0, 20 + 40 * lift), ArmR = R(60 + 20 * lift, 0, -20 - 40 * lift), ForeL = R(30 - 10 * lift, 0, 0), ForeR = R(30 - 10 * lift, 0, 0), LegL = R(0, 0, 4), LegR = R(0, 0, -4) }
			root = W(SIT.X, 0, SIT.Z) * R(0, 10, 0)
			kid:size("Eyes", 1.15)
			if t < 7.7 then hammer.root = W(SIT.X - 0.7, 0.06, SIT.Z - 0.4) * R(0, 30, 90) end
			kid:size("Mouth", V(1, 1.4, 1))
		end
		if pose then kid:pose(lean(pose)) end
		kid:smooth(dt, phase == 2 and 30 or 14)
		kid.root = root
		if phase == 3 then -- the two halves ride in her raised paws, cut faces to the camera
			local a = kid:joint("ForeL") * CFrame.new(V(-0.04, -0.5, -0.2))
			local b = kid:joint("ForeR") * CFrame.new(V(0.04, -0.5, -0.2))
			local join = smooth(8.4, 9.0, t)
			local mid = a.Position:Lerp(b.Position, 0.5)
			hammer.root = CFrame.new(mid + O:VectorToWorldSpace(V(-1.1 * smooth(8.4, 9.2, t), -0.55 - 0.8 * smooth(8.4, 9.2, t), -0.2 - 0.3 * smooth(8.4, 9.2, t)))) * (O - O.Position) * R(0, 0, 12 * smooth(8.4, 9.2, t)) -- upright in her paws, then held out to screen right (the name card sits top left) and a little lower and nearer, so her face and the whole pick show (2026-11-19)
			local head = hammer.root * CFrame.new(0, 0.74, 0)
			rock.root = CFrame.new(mid:Lerp(head.Position, join)) * (O - O.Position) * R(0, 180, 0)
			rock:set("HalfA", (CFrame.new(-0.75, 0, 0) * R(0, 90, 0)):Lerp(CFrame.new(-0.42, -0.08, 0) * R(0, 90, 0) * R(-22, 0, 0), join)) -- the halves go either side of the hammer head, crystal to the front, drooping like the two points of a pick
			rock:set("HalfB", (CFrame.new(0.75, 0, 0) * R(0, -90, 0)):Lerp(CFrame.new(0.42, -0.08, 0) * R(0, -90, 0) * R(-22, 0, 0), join))
			glowPart.CFrame = rock.root * CFrame.new(0, 0, -0.3)
			once("join", 9.0, t, function() ctx.sound(SND.bonk, 0.45, 2.24) crystalDust:Emit(30) ctx.kick(2) end)
			if t >= 9.0 and pick then -- the halves and the hammer are now one thing: the pickaxe
				pick:ScaleTo(pickScale0 * 2.1 / pickH) -- 2.1 high (was 2.6): the low camera cut its head off the top of the frame
				pick:PivotTo(hammer.root * CFrame.new(0, -0.2, -0.1))
				hammer.root, rock.root = FAR, FAR
			end
		end

		-- ===== the crack, the light, the reveal =====
		local crackOn = t >= TAPS[3] and t < OPEN + 0.1
		rock:show("Crack", crackOn)
		if crackOn then rock:alpha("Crack", 1 - smooth(TAPS[3], TAPS[5] + 0.2, t)) end
		rock:show("CrystalA", t >= OPEN) rock:show("CrystalB", t >= OPEN)
		violet.Brightness = (t >= OPEN and 1.4 * (1 - 0.4 * smooth(OPEN + 0.6, 7.6, t)) or 0) + (crackOn and 0.8 * smooth(TAPS[3], TAPS[5], t) or 0) + (t >= 7.6 and 0.6 or 0)
		spots.Rate = t >= OPEN and t < 7.6 and 10 or 0
		once("crackGlow", TAPS[3], t, function() sfx("sparkle", 2.2) end)
		once("open", OPEN, t, function()
			ctx.sound(SND.bonk, 0.5, 2.0) ctx.sound(SND.bonk, 0.35, 2.52) crystalDust:Emit(40) spots:Emit(20) sfx("sparkle", 1.2)
			ctx.hold(5 / 60) ctx.kick(3) ctx.flashAlpha = 0
		end)
		ctx.flashAlpha = 0.15 * (1 - lin(OPEN, OPEN + 0.2, t)) * (t >= OPEN and 1 or 0)
		if t >= 7.6 then
			heroPart.CFrame = (t >= 9.0 and pick) and pick:GetPivot() * CFrame.new(0, 0.8, 0) or rock.root * CFrame.new(0, 0.3, 0.3)
			raysIm.ImageTransparency = 1 - 0.6 * smooth(8.6, 9.1, t) * (1 - smooth(10.6, 11.1, t))
			raysIm.Rotation = t * 20
			heroSpark.Rate = t >= 9.0 and 6 or 0
			once("reveal", 9.0, t, function() heroSpark:Emit(40) ctx.sound(SND.dawn, 0.5, 1.05) sfx("sparkle", 1.3) ctx.kick(4) ctx.hold(3 / 60) end)
			ctx.name("Nobody wanted it.")
			ctx.cardAlpha = smooth(9.2, 9.55, t) * (1 - smooth(10.7, 11.0, t))
		end

		-- ===== chapters and camera =====
		if t >= 0.35 and t < 3.0 then ctx.chapter(1, "BORN", "A plain grey rock, thrown in the reject barrel. Again.")
		elseif t >= 3.2 and t < 7.6 then ctx.chapter(2, "MADE", "A child took the one nobody wanted, and tapped.")
		elseif t >= 7.8 then ctx.chapter(3, "NAMED", "She held the two halves up to the sun.") end
		local cf, fov, focus
		local function shot(from, aim, f) cf, fov, focus = CFrame.lookAt(from, aim), f, (from - aim).Magnitude end
		if t < 1.2 then -- the quarry road at noon: the stall, the cart, the terraces and windmills
			local u = smooth(0, 1.2, t)
			shot(V(-1.4 + 0.6 * u, 3.2 - 0.5 * u, -11 + 2.5 * u), V(1.6, 2.4, 6), 54 - 4 * u)
		elseif t < 2.2 then -- the keeper at the scales: weighed, and thrown
			shot(V(0.6, 2.8, -3.4), V(3.0, 2.2, 1.2), 46)
		elseif t < 3.2 then -- the barrel, as it lands among the rejects again
			shot(V(0.6, 2.4, -2.0 + 0.3 * smooth(2.2, 3.2, t)), V(2.2, 1.3, 0.7), 44)
		elseif t < 4.8 then -- low on the road: she comes, stops, looks in
			shot(V(-1.6, 1.4, -5.4 + 0.6 * smooth(3.2, 4.8, t)), V(1.2, 1.3, 0.4), 46)
		elseif t < 6.0 then -- low beside her in the dust: tap, tap
			shot(V(-2.8, 0.9, -3.4), V(0.8, 0.7, -1.6), 46) -- from her side: her big head is not between us and the rock
		elseif t < 6.8 then -- close on the rock: the crack glows
			shot(V(-1.2, 0.7, -3.2), V(0.75, 0.4, -2.25), 38)
		elseif t < 7.6 then -- her face in the violet light, the keeper staring behind her
			shot(V(0.3, 1.5, -4.6), V(1.0, 1.4, -0.9), 42)
		else -- low in front: the halves held up to the sun
			local s = smooth(8.0, 10.8, t)
			shot(V(0.2 + 0.2 * s, 0.6, -4.6 + 0.5 * s), V(1.0, 1.8, -0.8):Lerp(V(1.4, 2.5, -0.8), smooth(8.2, 9.2, t)), 56 - 2 * s)
		end
		ctx.cam, ctx.fov = O * cf, fov
		ctx.dof.FocusDistance = focus
		ctx.dof.InFocusRadius, ctx.dof.FarIntensity, ctx.dof.NearIntensity = 400, 0, 0
	end
end

return M
