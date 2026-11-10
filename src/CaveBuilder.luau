-- CaveBuilder: the shared cave world of the cave exploration rework (vault: Projects/Pixel-_/Briefs/Cave Exploration Rework.md,
-- numbers in Briefs/Cave Rework Reference Board (2026-11-08).md, refs in art/caves/refs).
-- Cave.build(parent, origin, seed) builds Camp 1 (fixed) and three hand-made pieces that the seed places, turns, mirrors and joins
-- with winding tunnels: a chasm with a rope bridge (ENV-01), a flooded crystal grotto (ENV-02), and a root squeeze opening into a
-- giant mushroom hall (ENV-03).
-- How it is built: a 2.5D raster of 4-stud cells. Each open cell has a floor height and a ceiling height; pieces and tunnels
-- stamp into the raster, then floors, ceilings and walls are built from it as voxel columns. Floors move in 1-stud steps so the
-- player can walk them; neighbouring cells with the same height merge (up to 3x3) to keep the part count down.
-- Ore deposits (stage 4) sit against walls the player can walk to from camp; each carries Layer, Ore and OreName attributes.
local Cave = {}
local C = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))

local CELL = 4
local PAL = {
	rock = { Color3.fromRGB(46, 32, 66), Color3.fromRGB(70, 50, 98), Color3.fromRGB(98, 72, 132), Color3.fromRGB(134, 104, 170) },
	moss = { Color3.fromRGB(64, 130, 112), Color3.fromRGB(96, 176, 140), Color3.fromRGB(140, 214, 170) },
	teal = Color3.fromRGB(40, 176, 168), violet = Color3.fromRGB(150, 84, 220), mint = Color3.fromRGB(80, 196, 140),
	lightTeal = Color3.fromRGB(120, 255, 236), lightViolet = Color3.fromRGB(206, 150, 255), lightMint = Color3.fromRGB(160, 255, 200),
	warm = Color3.fromRGB(255, 196, 120), bark = Color3.fromRGB(104, 70, 66), barkLt = Color3.fromRGB(150, 104, 90),
	cream = Color3.fromRGB(236, 222, 200), plank = Color3.fromRGB(170, 122, 92), rope = Color3.fromRGB(214, 182, 132),
	water = Color3.fromRGB(56, 170, 190), pink = Color3.fromRGB(255, 157, 176), lilac = Color3.fromRGB(185, 164, 238),
	capMint = Color3.fromRGB(70, 180, 130), capTeal = Color3.fromRGB(40, 160, 170), capLilac = Color3.fromRGB(130, 96, 200), capPink = Color3.fromRGB(200, 90, 130),
}
-- floor tint per theme (dark, mid) and whether moss grows there
local THEME = {
	camp = { Color3.fromRGB(118, 92, 104), Color3.fromRGB(150, 118, 124), moss = 0.12 },
	tunnel = { Color3.fromRGB(62, 46, 84), Color3.fromRGB(84, 62, 110), moss = 0.3 },
	chasm = { Color3.fromRGB(58, 44, 88), Color3.fromRGB(80, 62, 116), moss = 0.45 },
	grotto = { Color3.fromRGB(48, 52, 96), Color3.fromRGB(66, 76, 126), moss = 0.2 },
	squeeze = { Color3.fromRGB(70, 48, 64), Color3.fromRGB(96, 66, 82), moss = 0.1 },
	mush = { Color3.fromRGB(56, 44, 82), Color3.fromRGB(76, 60, 108), moss = 0.55 },
}

local ROCK_VARIANT = "PixelCaveRock"
local function ensureVariant() -- 32 px rock tile from art/pd_hub_tex.py (rockface), tinted by each part's colour
	local ms = game:GetService("MaterialService")
	if ms:FindFirstChild(ROCK_VARIANT) then return true end
	return pcall(function()
		local v = Instance.new("MaterialVariant")
		v.Name, v.BaseMaterial, v.StudsPerTile = ROCK_VARIANT, Enum.Material.Slate, 8
		v.ColorMap = "rbxassetid://76858268703683"
		v.Parent = ms
	end)
end

local function hash(a, b, c)
	local n = math.sin(a * 12.9898 + b * 78.233 + (c or 0) * 37.719) * 43758.5453
	return n - math.floor(n)
end
local function lerpC(a, b, t) return a:Lerp(b, math.clamp(t, 0, 1)) end

function Cave.build(parent, origin, seed)
	origin = origin or Vector3.zero
	seed = seed or 1
	local rng = Random.new(seed)
	local rocky = ensureVariant()
	local ROCK = rocky and { Material = Enum.Material.Slate, MaterialVariant = ROCK_VARIANT } or {}
	local model = Instance.new("Model")
	model.Name = "Caves"
	model:SetAttribute("Seed", seed)
	local groups = {}
	local function group(name)
		if not groups[name] then
			local f = Instance.new("Folder")
			f.Name = name
			f.Parent = model
			groups[name] = f
		end
		return groups[name]
	end
	local function part(g, name, size, cf, color, props)
		local p = Instance.new("Part")
		p.Name, p.Size, p.CFrame, p.Color = name, size, typeof(cf) == "Vector3" and CFrame.new(cf) or cf, color
		p.Material, p.Anchored, p.TopSurface, p.BottomSurface = Enum.Material.SmoothPlastic, true, Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		for k, v in props or {} do p[k] = v end
		p.Parent = group(g)
		return p
	end
	local DECO = { CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false }
	local function glow(p, color, range, brightness, shadows)
		local l = Instance.new("PointLight")
		l.Color, l.Range, l.Brightness, l.Shadows = color, range, brightness or 1, shadows or false
		l.Parent = p
		return l
	end
	-- a miner's lantern (demo audit 09: bare neon cubes blew out under bloom): a small neon wick inside amber glass panes, a brass
	-- cap, base and corner struts. The light sits on the wick; the fixture keeps its glow through the playtest 2 dimming pass.
	local BRASS, BRASS_DARK = Color3.fromRGB(60, 54, 62), Color3.fromRGB(43, 42, 45) -- dark iron: brass lit by its own flame read as mustard plastic (Gemini r3)
	local function lantern(g, name, cf, color, range, s)
		s = s or 1
		cf = typeof(cf) == "Vector3" and CFrame.new(cf) or cf
		local core = part(g, name, Vector3.new(0.2, 0.3, 0.2) * s, cf * CFrame.new(0, -0.04 * s, 0), color, { Material = Enum.Material.Neon, CanCollide = false, CastShadow = false }) -- a small flame
		part(g, "LanternFlameTip", Vector3.new(0.11, 0.2, 0.11) * s, cf * CFrame.new(0, 0.2 * s, 0), color:Lerp(Color3.new(1, 1, 1), 0.3), { Material = Enum.Material.Neon, CanCollide = false, CastShadow = false })
		part(g, "LanternWick", Vector3.new(0.3, 0.26, 0.3) * s, cf * CFrame.new(0, -0.4 * s, 0), BRASS_DARK, DECO) -- the oil cup under it
		part(g, "LanternGlass", Vector3.new(0.9, 1.08, 0.9) * s, cf, Color3.fromRGB(255, 170, 84), { Material = Enum.Material.Glass, Transparency = 0.6, Reflectance = 0.2, CanCollide = false, CastShadow = false }) -- warm amber panes you can see (at 0.8 the cage read as empty)
		part(g, "LanternCap", Vector3.new(1.06, 0.2, 1.06) * s, cf * CFrame.new(0, 0.62 * s, 0), BRASS, DECO)
		part(g, "LanternCap", Vector3.new(0.6, 0.18, 0.6) * s, cf * CFrame.new(0, 0.8 * s, 0), BRASS_DARK, DECO)
		part(g, "LanternBase", Vector3.new(1.06, 0.2, 1.06) * s, cf * CFrame.new(0, -0.62 * s, 0), BRASS, DECO)
		for _, o in { { -1, -1 }, { -1, 1 }, { 1, -1 }, { 1, 1 } } do
			for _, y in { -0.62, 0.62 } do part(g, "LanternBracket", Vector3.new(0.2, 0.26, 0.2) * s, cf * CFrame.new(o[1] * 0.46 * s, y * s, o[2] * 0.46 * s), Color3.fromRGB(112, 84, 48), { CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false }) end -- brass corner brackets on the hammered iron
			part(g, "LanternStrut", Vector3.new(0.12, 1.06, 0.12) * s, cf * CFrame.new(o[1] * 0.44 * s, 0, o[2] * 0.44 * s), BRASS_DARK, DECO)
		end
		local l = glow(core, color, range, 0.6) -- soft and wide. The audit asked for 1.2 to 1.8: tried 1.2, the whole camp floor went white (captures/night/p1_camp.png)
		l:SetAttribute("Fixture", true)
		return core
	end

	-- the raster: cells[key] = { f = floor y, c = ceiling y, theme, prio, water }
	local cells = {}
	local function key(i, j) return (i + 2048) * 4096 + (j + 2048) end
	local function stamp(i, j, f, c, theme, prio, extra)
		local k = key(i, j)
		local old = cells[k]
		if old and old.prio > prio then return end
		local cell = { i = i, j = j, f = f, c = math.max(c, f + 8), theme = theme, prio = prio }
		for kk, v in extra or {} do cell[kk] = v end
		cells[k] = cell
	end
	local function W(i, j, y) return origin + Vector3.new(i * CELL, y, j * CELL) end

	-- a piece in local cells (u along its length, v across); turned by rot (0..3 quarter turns) and mirrored, at cell (oi, oj)
	local function placer(oi, oj, rot, mirror, y0)
		local function toIJ(u, v)
			v = mirror and -v or v
			if rot == 0 then return oi + u, oj + v elseif rot == 1 then return oi - v, oj + u elseif rot == 2 then return oi - u, oj - v end
			return oi + v, oj - u
		end
		local yaw = -rot * math.pi / 2
		local function cf(u, v, y, turn) -- world CFrame at local cell (u, v), height y above the piece base, facing local +u turned by `turn`
			local i, j = toIJ(u, v)
			return CFrame.new(W(i, j, y0 + y)) * CFrame.Angles(0, yaw + (turn or 0) * (mirror and -1 or 1), 0)
		end
		return toIJ, cf
	end

	local pieces = {}
	-- CAMP 1 (CMP-01): fixed at the origin, a dome over a flat floor; exits east, north and west; the lift on the south side
	local function buildCamp()
		local R = 11
		for i = -R - 1, R + 1 do
			for j = -R - 1, R + 1 do
				local a = math.atan2(j, i)
				local edge = R + (math.noise(a * 1.7, seed * 0.01, 3.1) * 2.2)
				local r = math.sqrt(i * i + j * j)
				if r <= edge then
					local rim = math.clamp((r - 8.5) / 2.5, 0, 1)
					local f = math.floor(rim * (2 + hash(i, j, 1) * 2))
					local c = 22 + math.floor(14 * (1 - (r / R) ^ 2) + hash(i, j, 2) * 3)
					stamp(i, j, f, c, "camp", 3)
				end
			end
		end
		local exits = { { 11, 0, 0 }, { 0, 11, 1 }, { -11, 0, 2 } } -- (i, j, rot): rot turns a piece's +u to point out of that exit
		-- campfire: a stone ring, split logs, a neon flame, the warm main light
		local fire = W(0, 3, 0)
		for k = 0, 7 do
			local a = k / 8 * math.pi * 2
			part("Camp", "FireStone", Vector3.new(1.6, 1, 1.6), CFrame.new(fire + Vector3.new(math.cos(a) * 3, 0.5, math.sin(a) * 3)) * CFrame.Angles(0, a, 0), PAL.rock[3])
		end
		for k = 0, 2 do part("Camp", "Log", Vector3.new(0.9, 0.9, 4), CFrame.new(fire + Vector3.new(0, 0.6, 0)) * CFrame.Angles(0, k * 2.1, 0.25), PAL.bark) end
		local flame = part("Camp", "Flame", Vector3.new(1.8, 2.6, 1.8), CFrame.new(fire + Vector3.new(0, 2, 0)) * CFrame.Angles(0, 0.6, 0), PAL.warm, { Material = Enum.Material.Neon, CanCollide = false, CastShadow = false })
		part("Camp", "FlameCore", Vector3.new(0.9, 1.6, 0.9), CFrame.new(fire + Vector3.new(0, 2.6, 0)), Color3.fromRGB(255, 240, 190), { Material = Enum.Material.Neon, CanCollide = false, CastShadow = false })
		glow(flame, Color3.fromRGB(255, 185, 95), 32, 1.15, true) -- was 3.4 then 1.7: the camp blew out to white (i65, Gemini r2 2026-11-09)
		local sparks = Instance.new("ParticleEmitter")
		sparks.Color, sparks.LightEmission, sparks.Rate = ColorSequence.new(PAL.warm), 1, 6
		sparks.Size, sparks.Lifetime, sparks.Speed = NumberSequence.new(0.25, 0), NumberRange.new(1.5, 2.5), NumberRange.new(3, 6)
		sparks.SpreadAngle, sparks.Acceleration = Vector2.new(15, 15), Vector3.new(0, 1, 0)
		sparks.Parent = flame
		-- Wick the glowworm (Camp 1's keeper): pale mint segments, a glowing tail tip, big eyes and antennae, facing the rail station
		do
			local wick = CFrame.lookAt(fire + Vector3.new(9, 0, -4), W(-1, -7, 0)) -- out of the fire's glare (it washed him white)
			local BODY, STRIPE = Color3.fromRGB(120, 196, 140), Color3.fromRGB(90, 168, 118)
			local tip = part("Camp", "WickTail", Vector3.new(0.9, 0.9, 0.9), wick * CFrame.new(0, 0.45, 2.6), PAL.warm, { Material = Enum.Material.Neon, CanCollide = false, CastShadow = false })
			glow(tip, PAL.warm, 10, 0.8)
			part("Camp", "WickSeg", Vector3.new(1.1, 1.1, 1.1), wick * CFrame.new(0, 0.55, 1.8), STRIPE)
			part("Camp", "WickSeg", Vector3.new(1.3, 1.3, 1.3), wick * CFrame.new(0, 0.75, 0.9), BODY)
			part("Camp", "WickSeg", Vector3.new(1.5, 1.5, 1.5), wick * CFrame.new(0, 1.1, 0), STRIPE)
			part("Camp", "WickHead", Vector3.new(1.9, 1.7, 1.7), wick * CFrame.new(0, 2.1, -0.6), BODY)
			for _, x in { -0.42, 0.42 } do
				part("Camp", "WickEye", Vector3.new(0.4, 0.52, 0.08), wick * CFrame.new(x, 2.3, -1.47), Color3.fromRGB(62, 42, 86), DECO)
				part("Camp", "WickShine", Vector3.new(0.15, 0.15, 0.06), wick * CFrame.new(x + 0.08, 2.43, -1.52), Color3.new(1, 1, 1), DECO)
				part("Camp", "WickFeeler", Vector3.new(0.12, 0.9, 0.12), wick * CFrame.new(x * 1.1, 3.3, -0.5) * CFrame.Angles(0, 0, -x * 0.5), STRIPE, DECO)
				part("Camp", "WickFeelerTip", Vector3.new(0.3, 0.3, 0.3), wick * CFrame.new(x * 1.45, 3.75, -0.5), PAL.warm, { Material = Enum.Material.Neon, CanCollide = false, CastShadow = false })
			end
			part("Camp", "WickSmile", Vector3.new(0.5, 0.12, 0.06), wick * CFrame.new(0, 1.8, -1.47), Color3.fromRGB(62, 42, 86), DECO)
		end
		-- Smudge, the gloomling who is scared of the dark, peeks in from the edge of the ring by a lantern post
		do
			local a = 0.3 + math.pi / 3
			local at = origin + Vector3.new(math.cos(a) * (8.6 * CELL - 2.5), 1, math.sin(a) * (8.6 * CELL - 2.5))
			local smudge = CFrame.lookAt(at, fire)
			local SOOT = Color3.fromRGB(30, 24, 44)
			part("Camp", "SmudgeHead", Vector3.new(1.6, 1.6, 1.6), smudge, SOOT, { Shape = Enum.PartType.Ball })
			for k = 1, 5 do
				local b = k / 5 * math.pi * 2
				part("Camp", "SmudgeFluff", Vector3.new(0.5, 0.5, 0.5), smudge * CFrame.new(math.cos(b) * 0.75, math.sin(b * 2) * 0.35, math.sin(b) * 0.75) * CFrame.Angles(b, b, 0), SOOT, DECO)
			end
			for _, x in { -0.28, 0.28 } do part("Camp", "SmudgeEye", Vector3.new(0.26, 0.36, 0.08), smudge * CFrame.new(x, 0.1, -0.78), Color3.fromRGB(255, 236, 160), { Material = Enum.Material.Neon, CanCollide = false, CastShadow = false }) end
		end
		-- The Deep Gate and the Root Warden (roadmap phase 9, the user 2026-11-08: the next camp needs a boss fight that needs the
		-- camp's top pickaxe; ServerScriptService.Boss runs the fight). In Camp 1's west wall: a door of tangled roots with amber
		-- knots, a CLAY CAVES sign, and the sleeping Warden in front of it. Behind the door: a short timbered alcove that ends at a
		-- fence and a COMING SOON sign (Camp 2 is roadmap phase 10).
		do
			local door = CFrame.new(origin + Vector3.new(-41, 0, 14)) * CFrame.Angles(0, -math.pi / 2, 0) -- faces +X, into the camp
			local ROOT, ROOT_D, AMBER = Color3.fromRGB(82, 66, 80), Color3.fromRGB(60, 48, 64), Color3.fromRGB(255, 186, 92) -- dusky plum bark: brown read orange under the torch
			local g = group("Gate")
			local function gp(name, size, cf, color, props)
				local p = part("Gate", name, size, cf, color, props)
				return p
			end
			-- the rock frame round the opening (10 wide, 11 tall)
			for _, x in { -6.2, 6.2 } do gp("GateCheek", Vector3.new(2.4, 11, 3), door * CFrame.new(x, 5.5, 0.6), PAL.rock[2], { Material = ROCK.Material, MaterialVariant = ROCK.MaterialVariant }) end
			gp("GateLintel", Vector3.new(14.8, 2.4, 3), door * CFrame.new(0, 12.2, 0.6), PAL.rock[2], { Material = ROCK.Material, MaterialVariant = ROCK.MaterialVariant })
			local sign = gp("GateSign", Vector3.new(7, 1.6, 0.3), door * CFrame.new(0, 12.2, -1.0), PAL.bark)
			local sg = Instance.new("SurfaceGui")
			sg.Face, sg.PixelsPerStud, sg.LightInfluence = Enum.NormalId.Front, 40, 0
			local tl = Instance.new("TextLabel")
			tl.Size, tl.BackgroundTransparency, tl.Text, tl.TextScaled, tl.Font = UDim2.fromScale(1, 1), 1, "DEEP GATE  -  CLAY CAVES", true, Enum.Font.FredokaOne
			tl.TextColor3 = Color3.fromRGB(255, 217, 112)
			tl.Parent = sg
			sg.Parent = sign
			-- the root door: thick roots woven across the opening, amber knots glowing where they cross (the door opens per player)
			local roots = {}
			for k = 0, 5 do
				local y = 1.2 + k * 1.8
				local tilt = (k % 2 == 0 and 1 or -1) * 0.22
				table.insert(roots, gp("DoorRoot", Vector3.new(11, 1.3, 1.3), door * CFrame.new(0, y, 0) * CFrame.Angles(0, 0, tilt), k % 2 == 0 and ROOT or ROOT_D, { Material = Enum.Material.Wood }))
			end
			for k = -2, 2 do
				table.insert(roots, gp("DoorRoot", Vector3.new(1.1, 11, 1.1), door * CFrame.new(k * 2.2, 5.6, 0.4) * CFrame.Angles(0, 0, k * 0.06), ROOT_D, { Material = Enum.Material.Wood }))
			end
			for k, at in { { -2.2, 3 }, { 2.2, 6.6 }, { 0, 9.2 } } do
				local kn = gp("DoorKnot", Vector3.new(1.1, 1.1, 1.1), door * CFrame.new(at[1], at[2], -0.7), AMBER, { Material = Enum.Material.Neon, Shape = Enum.PartType.Ball, CanCollide = false, CastShadow = false })
				table.insert(roots, kn)
			end
			for _, p in roots do p:SetAttribute("GateDoor", true) end
			local dark = gp("GateDark", Vector3.new(10, 11, 0.6), door * CFrame.new(0, 5.5, 1.6), Color3.fromRGB(14, 8, 22))
			dark:SetAttribute("GateDoor", true)
			-- the alcove behind: floor, walls, roof, a fence and the COMING SOON sign
			local back = door * CFrame.new(0, 0, 8)
			gp("AlcoveFloor", Vector3.new(10, 1, 14), back * CFrame.new(0, -0.5, 0), PAL.rock[1], { Material = ROCK.Material, MaterialVariant = ROCK.MaterialVariant })
			for _, x in { -5.6, 5.6 } do gp("AlcoveWall", Vector3.new(1.2, 11, 14), back * CFrame.new(x, 5.5, 0), PAL.rock[2], { Material = ROCK.Material, MaterialVariant = ROCK.MaterialVariant }) end
			gp("AlcoveRoof", Vector3.new(12.4, 1.2, 14), back * CFrame.new(0, 11.6, 0), PAL.rock[1], { Material = ROCK.Material, MaterialVariant = ROCK.MaterialVariant })
			gp("AlcoveEnd", Vector3.new(10, 11, 1), back * CFrame.new(0, 5.5, 7.5), PAL.rock[1], { Material = ROCK.Material, MaterialVariant = ROCK.MaterialVariant })
			for _, x in { -3.5, 0, 3.5 } do gp("FencePost", Vector3.new(0.5, 3.4, 0.5), back * CFrame.new(x, 1.7, 3), PAL.bark) end
			for _, y in { 1.2, 2.6 } do gp("FenceRail", Vector3.new(8.4, 0.35, 0.3), back * CFrame.new(0, y, 3.1), PAL.barkLt) end
			local soon = gp("SoonSign", Vector3.new(4.6, 1.6, 0.25), back * CFrame.new(0, 3.9, 2.8), PAL.cream)
			local sg2 = sg:Clone()
			sg2.Face = Enum.NormalId.Front
			sg2.TextLabel.Text, sg2.TextLabel.TextColor3 = "CLAY CAVES: COMING SOON", Color3.fromRGB(111, 88, 176)
			sg2.Parent = soon
			lantern("Gate", "AlcoveLamp", back * CFrame.new(0, 8.5, 5), PAL.warm:Lerp(PAL.cream, 0.5), 20, 0.9)
			-- the Root Warden: a hulking moss-backed root golem asleep in front of the door, three amber knots on its chest
			local w = Instance.new("Model")
			w.Name = "Warden"
			local base = CFrame.new(origin + Vector3.new(-33, 0, 14)) * CFrame.Angles(0, -math.pi / 2, 0) -- faces +X
			local function wp(name, size, cf, color, props)
				local p = part("Gate", name, size, base * cf, color, props)
				p.Parent = w
				return p
			end
			local body = wp("WardenBody", Vector3.new(7, 5.5, 5), CFrame.new(0, 3.6, 0), ROOT)
			wp("WardenMoss", Vector3.new(7.4, 1.2, 5.4), CFrame.new(0, 6.6, 0.3), Color3.fromRGB(96, 150, 104), { Material = Enum.Material.Grass })
			wp("WardenHead", Vector3.new(4.2, 3.4, 3.6), CFrame.new(0, 7.6, -1.4), ROOT_D)
			for _, x in { -0.9, 0.9 } do -- closed eyes (slits); the client lights them when it wakes
				wp("WardenEye", Vector3.new(0.9, 0.25, 0.1), CFrame.new(x, 7.9, -3.24), Color3.fromRGB(40, 28, 46), DECO)
			end
			for _, x in { -1, 1 } do
				wp("WardenArm", Vector3.new(1.8, 5.2, 1.8), CFrame.new(x * 4.4, 3.2, -0.6) * CFrame.Angles(0, 0, x * 0.18), ROOT_D)
				wp("WardenFist", Vector3.new(2.4, 1.8, 2.4), CFrame.new(x * 4.9, 0.9, -1.2), ROOT)
				wp("WardenLeg", Vector3.new(2, 1.6, 2.2), CFrame.new(x * 2, 0.8, 0.6), ROOT_D)
			end
			for k, at in { { -1.8, 4.6 }, { 1.8, 3.4 }, { 0, 2.2 } } do -- the knots: Perfect Strike targets (attributes drive the minigame UI)
				local km = Instance.new("Model")
				km.Name = "Knot" .. k
				local kn = part("Gate", "KnotCore", Vector3.new(1.4, 1.4, 1.4), base * CFrame.new(at[1], at[2], -2.6), AMBER, { Material = Enum.Material.Neon, Shape = Enum.PartType.Ball, CanCollide = false, CastShadow = false })
				kn.Parent = km
				km.PrimaryPart = kn
				km:SetAttribute("Layer", 1)
				km:SetAttribute("Ore", 3)
				km:SetAttribute("OreName", "Root Knot")
				km.Parent = w
				glow(kn, AMBER, 8, 0.6)
			end
			local pr = Instance.new("ProximityPrompt")
			pr.ActionText, pr.ObjectText, pr.KeyboardKeyCode = "Challenge", "Root Warden", Enum.KeyCode.F
			pr.MaxActivationDistance, pr.RequiresLineOfSight, pr.HoldDuration = 14, false, 0.5
			pr.Style = Enum.ProximityPromptStyle.Custom
			pr:SetAttribute("BossGate", true)
			pr.Parent = body
			w.PrimaryPart = body
			w.Parent = g
		end
		-- pastel pup tents (CMP-01): two sloped roofs, a dark doorway, a little flag
		local function tent(i, j, turn, col)
			local base = CFrame.new(W(i, j, 0)) * CFrame.Angles(0, turn, 0)
			local S = 1.45
			for _, s in { -1, 1 } do
				part("Camp", "TentSide", Vector3.new(7, 0.6, 5.6) * S, base * CFrame.new(s * 1.7 * S, 2.5 * S, 0) * CFrame.Angles(0, 0, s * 0.9), col)
				part("Camp", "TentStripe", Vector3.new(7.05, 0.65, 1.2) * S, base * CFrame.new(s * 1.7 * S, 2.5 * S, 0) * CFrame.Angles(0, 0, s * 0.9), PAL.cream, DECO)
			end
			part("Camp", "TentBack", Vector3.new(6.4, 4.6, 0.4) * S, base * CFrame.new(0, 2.1 * S, -2.7 * S), col:Lerp(Color3.new(0, 0, 0), 0.25))
			part("Camp", "Bedroll", Vector3.new(2.2, 0.6, 4) * S, base * CFrame.new(0, 0.3, 0), PAL.lilac, DECO)
			part("Camp", "Door", Vector3.new(2, 3, 0.2) * S, base * CFrame.new(0, 1.5 * S, 2.7 * S), Color3.fromRGB(40, 28, 52), DECO)
			part("Camp", "Pole", Vector3.new(0.3, 2, 0.3), base * CFrame.new(0, 5.4 * S, 2.4 * S), PAL.bark, DECO)
			part("Camp", "Flag", Vector3.new(1.4, 0.8, 0.1), base * CFrame.new(0.7, 6 * S, 2.4 * S), PAL.lilac, DECO)
		end
		tent(-5, 5, 2.4, PAL.pink)
		tent(5, 6, -2.3, Color3.fromRGB(180, 225, 205))
		tent(-6.5, -1.5, 1.3, PAL.lilac)
		-- supply stall: a counter with crates under a striped awning
		local stall = CFrame.new(W(5.5, -3.5, 0)) * CFrame.Angles(0, -0.7, 0)
		part("Camp", "Counter", Vector3.new(8, 3.4, 2.6), stall * CFrame.new(0, 1.7, 0), PAL.plank)
		part("Camp", "CounterTop", Vector3.new(8.4, 0.4, 3), stall * CFrame.new(0, 3.6, 0), Color3.fromRGB(210, 160, 120))
		for _, x in { -3.8, 3.8 } do part("Camp", "Post", Vector3.new(0.5, 7, 0.5), stall * CFrame.new(x, 3.5, -1), PAL.bark) end
		for k = 0, 4 do part("Camp", "Awning", Vector3.new(1.7, 0.3, 4), stall * CFrame.new(-3.4 + k * 1.7, 7.2, 0.4) * CFrame.Angles(-0.35, 0, 0), k % 2 == 0 and PAL.pink or PAL.cream) end
		for k = 0, 2 do part("Camp", "Crate", Vector3.new(2, 2, 2), stall * CFrame.new(-2.6 + k * 2.6, 4.8, 0) * CFrame.Angles(0, k * 0.3, 0), Color3.fromRGB(196, 150, 110)) end
		lantern("Camp", "Lamp", stall * CFrame.new(3.2, 6.2, 1.2), PAL.warm, 24, 1.1)
		-- the rail station on the south side (feedback batch phase 4, 2026-11-08: the minecart ride replaces the lift): rails run
		-- out of a timbered tunnel mouth in the south wall to buffers, a parked cart, a plank platform where riders step off
		local st = CFrame.new(W(-1, -7, 0))
		local railZ0, railZ1 = -11, 6 -- along the station's local z: the tunnel end (south) to the buffers (north)
		for _, x in { -1.25, 1.25 } do
			part("Camp", "Rail", Vector3.new(0.3, 0.3, railZ1 - railZ0), st * CFrame.new(x, 0.45, (railZ0 + railZ1) / 2), Color3.fromRGB(150, 140, 170), { Material = Enum.Material.Metal })
		end
		for z = railZ0 + 1, railZ1 - 1, 2 do
			part("Camp", "Sleeper", Vector3.new(3.4, 0.3, 0.8), st * CFrame.new(0, 0.15, z), PAL.bark)
		end
		for _, x in { -1.5, 1.5 } do -- buffers: a post with a soft pink pad
			part("Camp", "BufferPost", Vector3.new(0.6, 1.6, 0.6), st * CFrame.new(x, 0.8, railZ1 + 0.4), PAL.bark)
			part("Camp", "BufferPad", Vector3.new(0.8, 0.8, 0.4), st * CFrame.new(x, 1.3, railZ1 - 0.05), PAL.pink)
		end
		-- the parked cart: a lilac tub with a butter rim on four dark wheels
		local cart = st * CFrame.new(0, 0, railZ1 - 3)
		-- demo audit 14: the cart was a plain purple box and the platform flat peach. Dark oak planks banded in riveted wrought
		-- iron, axles, flanged wheels, brake shoes; a plank deck on posts. Every cart part keeps a "Cart" name (the ride hides them).
		local OAK, IRON, RIVET = Color3.fromRGB(96, 70, 74), Color3.fromRGB(58, 52, 72), Color3.fromRGB(170, 162, 190)
		local WOODP, METAL = { Material = Enum.Material.WoodPlanks }, { Material = Enum.Material.Metal, CanCollide = false, CastShadow = false }
		local body = part("Camp", "CartBody", Vector3.new(3, 1.8, 3.6), cart * CFrame.new(0, 1.65, 0), OAK, WOODP)
		part("Camp", "CartInside", Vector3.new(2.5, 0.1, 3.1), cart * CFrame.new(0, 2.56, 0), Color3.fromRGB(34, 24, 36), DECO) -- the dark of the tub
		for _, x in { -1, 1 } do
			for _, z in { -1, 1 } do
				part("Camp", "CartBrace", Vector3.new(0.5, 1.74, 0.5), cart * CFrame.new(x * 1.33, 1.65, z * 1.63), IRON, METAL)
				for _, y in { 1.15, 2.15 } do
					part("Camp", "CartRivet", Vector3.new(0.16, 0.16, 0.1), cart * CFrame.new(x * 1.33, y, z * 1.9), RIVET, METAL)
					part("Camp", "CartRivet", Vector3.new(0.1, 0.16, 0.16), cart * CFrame.new(x * 1.6, y, z * 1.63), RIVET, METAL)
				end
			end
			part("Camp", "CartBand", Vector3.new(0.07, 0.28, 2.74), cart * CFrame.new(x * 1.535, 1.65, 0), IRON, METAL)
			part("Camp", "CartBrakeLever", Vector3.new(0.14, 1.5, 0.14), cart * CFrame.new(x * 1.66, 1.5, 0.35) * CFrame.Angles(0.35, 0, 0), IRON, METAL)
			part("Camp", "CartRimS", Vector3.new(0.3, 0.3, 3.3), cart * CFrame.new(x * 1.45, 2.58, 0), IRON, METAL)
		end
		for _, z in { -1, 1 } do
			part("Camp", "CartBand", Vector3.new(2.14, 0.28, 0.07), cart * CFrame.new(0, 1.65, z * 1.835), IRON, METAL)
			part("Camp", "CartAxle", Vector3.new(3.1, 0.3, 0.3), cart * CFrame.new(0, 0.65, z * 1.1), IRON, { Shape = Enum.PartType.Cylinder, Material = Enum.Material.Metal, CanCollide = false })
		end
		local pr = Instance.new("ProximityPrompt") -- ride up: the minecart escape (the server binds prompts with a RideUp attribute)
		pr.ActionText, pr.ObjectText, pr.KeyboardKeyCode = "Ride up", "Minecart", Enum.KeyCode.F
		pr.MaxActivationDistance, pr.RequiresLineOfSight, pr.HoldDuration = 12, false, 0
		pr.Style = Enum.ProximityPromptStyle.Custom
		pr:SetAttribute("RideUp", true)
		pr.Parent = body
		part("Camp", "CartRimF", Vector3.new(3.2, 0.35, 0.3), cart * CFrame.new(0, 2.6, -1.8), IRON, { Material = Enum.Material.Metal })
		part("Camp", "CartRimB", Vector3.new(3.2, 0.35, 0.3), cart * CFrame.new(0, 2.6, 1.8), IRON, { Material = Enum.Material.Metal })
		for _, w in { { -1.35, -1.1 }, { 1.35, -1.1 }, { -1.35, 1.1 }, { 1.35, 1.1 } } do
			part("Camp", "CartWheel", Vector3.new(0.4, 1, 1), cart * CFrame.new(w[1], 0.65, w[2]) * CFrame.Angles(0, 0, math.pi / 2), IRON, { Shape = Enum.PartType.Cylinder, Material = Enum.Material.Metal })
			part("Camp", "CartFlange", Vector3.new(0.12, 1.26, 1.26), cart * CFrame.new(w[1] - math.sign(w[1]) * 0.27, 0.65, w[2]) * CFrame.Angles(0, 0, math.pi / 2), IRON:Lerp(Color3.new(0, 0, 0), 0.25), { Shape = Enum.PartType.Cylinder, Material = Enum.Material.Metal, CanCollide = false })
			part("Camp", "CartHub", Vector3.new(0.46, 0.34, 0.34), cart * CFrame.new(w[1], 0.65, w[2]) * CFrame.Angles(0, 0, math.pi / 2), RIVET, { Shape = Enum.PartType.Cylinder, Material = Enum.Material.Metal, CanCollide = false })
			part("Camp", "CartBrakeShoe", Vector3.new(0.34, 0.44, 0.3), cart * CFrame.new(w[1], 0.72, w[2] + (w[2] > 0 and -0.68 or 0.68)), PAL.bark, DECO)
		end
		-- the tunnel mouth: a dark opening framed in timber, a lantern each side, a sign
		part("Camp", "TunnelDark", Vector3.new(5.4, 6.4, 4), st * CFrame.new(0, 3.2, railZ0 - 2.2), Color3.fromRGB(14, 8, 22), { Material = Enum.Material.SmoothPlastic })
		for _, x in { -4.3, 4.3 } do part("Camp", "TunnelCheek", Vector3.new(2.6, 8.4, 4.4), st * CFrame.new(x, 4.2, railZ0 - 2.4), PAL.rock[2], { Material = ROCK.Material, MaterialVariant = ROCK.MaterialVariant }) end
		part("Camp", "TunnelLintel", Vector3.new(11.2, 2.6, 4.4), st * CFrame.new(0, 8.9, railZ0 - 2.4), PAL.rock[2], { Material = ROCK.Material, MaterialVariant = ROCK.MaterialVariant })
		for _, x in { -3, 3 } do
			part("Camp", "TunnelPost", Vector3.new(0.8, 7.2, 0.8), st * CFrame.new(x, 3.6, railZ0), PAL.bark)
			lantern("Camp", "TunnelLamp", st * CFrame.new(x, 5.2, railZ0 + 0.7), PAL.warm, 22, 0.9)
		end
		part("Camp", "TunnelBeam", Vector3.new(7.6, 0.9, 0.9), st * CFrame.new(0, 7.4, railZ0), PAL.barkLt)
		local sign = part("Camp", "StationSign", Vector3.new(5.6, 1.5, 0.3), st * CFrame.new(0, 8.9, railZ0 + 0.35), PAL.bark)
		local sg = Instance.new("SurfaceGui")
		sg.Face, sg.PixelsPerStud, sg.LightInfluence = Enum.NormalId.Back, 40, 0
		local tl = Instance.new("TextLabel")
		tl.Size, tl.BackgroundTransparency, tl.Text, tl.TextScaled, tl.Font = UDim2.fromScale(1, 1), 1, "CAMP 1 STATION", true, Enum.Font.FredokaOne
		tl.TextColor3 = Color3.fromRGB(255, 217, 112)
		tl.Parent = sg
		sg.Parent = sign
		-- the platform beside the rails: riders step off here (LiftLanding keeps its name for the server)
		part("Camp", "Platform", Vector3.new(5, 1, 12), st * CFrame.new(4.6, 0.5, 0), Color3.fromRGB(104, 78, 80), { Material = Enum.Material.WoodPlanks })
		part("Camp", "PlatformEdge", Vector3.new(0.5, 1.16, 12.3), st * CFrame.new(2.0, 0.5, 0), PAL.bark:Lerp(Color3.new(0, 0, 0), 0.3), { Material = Enum.Material.Wood }) -- a heavy edge beam on the rail side
		for _, z in { -5.6, 0, 5.6 } do
			part("Camp", "PlatformBolt", Vector3.new(0.12, 0.3, 0.3), st * CFrame.new(1.71, 0.7, z), Color3.fromRGB(170, 162, 190), { Material = Enum.Material.Metal, CanCollide = false, CastShadow = false })
		end
		-- station dressing (Gemini r1: "a desolate void"): crates of ore and a sack on the platform, a bench, glowing mushrooms by
		-- the tunnel mouth, a barrel at the buffers
		for k, c in { { 5.6, 1.6, 4.2, 1.2, PAL.plank }, { 5.3, 1.45, 3.1, 0.9, PAL.barkLt }, { 5.7, 2.75, 4.0, 0.8, PAL.plank:Lerp(PAL.cream, 0.3) } } do
			part("Camp", "StationCrate", Vector3.new(c[4], c[4], c[4]), st * CFrame.new(c[1], c[2] - 0.6 + c[4] / 2, c[3]) * CFrame.Angles(0, k * 0.35, 0), c[5])
		end
		part("Camp", "CrateOre", Vector3.new(0.5, 0.4, 0.5), st * CFrame.new(5.62, 2.55, 4.18) * CFrame.Angles(0, 0.4, 0), PAL.teal, { Material = Enum.Material.Glass, Transparency = 0.2, CanCollide = false, CastShadow = false }) -- a glass ore sample (a neon one bleached to a white cube under the lamp)
		part("Camp", "Sack", Vector3.new(1, 1.1, 0.9), st * CFrame.new(3.6, 1.55, -4.6) * CFrame.Angles(0, 0.5, 0.1), PAL.cream:Lerp(PAL.plank, 0.35))
		part("Camp", "BenchSeat", Vector3.new(1, 0.3, 3.2), st * CFrame.new(6.4, 1.85, -1.5), PAL.barkLt)
		for _, z in { -2.8, -0.2 } do part("Camp", "BenchLeg", Vector3.new(0.8, 0.85, 0.3), st * CFrame.new(6.4, 1.425, z), PAL.bark) end
		for k, m in { { -3.6, -10.2, 1.2, PAL.lightMint }, { -4.4, -9.4, 0.8, PAL.lightViolet }, { 3.7, -10.0, 1.0, PAL.lightTeal } } do
			part("Camp", "StationStem", Vector3.new(0.35, m[3], 0.35), st * CFrame.new(m[1], m[3] / 2, m[2]), PAL.cream)
			part("Camp", "StationCap", Vector3.new(m[3] * 0.9, 0.35, m[3] * 0.9), st * CFrame.new(m[1], m[3] + 0.15, m[2]) * CFrame.Angles(0, k, 0), m[4], { Material = Enum.Material.Neon, CanCollide = false, CastShadow = false })
		end
		part("Camp", "StationBarrel", Vector3.new(1.3, 1.7, 1.3), st * CFrame.new(-2.9, 0.85, railZ1 + 0.6), PAL.barkLt, { Shape = Enum.PartType.Cylinder, Orientation = Vector3.new(0, 0, 90) })
		for _, z in { -5, 5 } do -- lantern posts on the platform light the arrival
			part("Camp", "PlatformPost", Vector3.new(0.6, 5, 0.6), st * CFrame.new(6.6, 3.5, z), PAL.bark)
			part("Camp", "PlatformArm", Vector3.new(1.6, 0.4, 0.4), st * CFrame.new(5.9, 5.8, z), PAL.bark)
			lantern("Camp", "PlatformLamp", st * CFrame.new(5.3, 5.1, z), PAL.warm:Lerp(PAL.cream, 0.5), 24, 0.9)
		end
		for k = -2, 2 do -- plank seams across the deck
			part("Camp", "PlankSeam", Vector3.new(5.1, 0.08, 0.16), st * CFrame.new(4.6, 1.02, k * 2.4), PAL.bark:Lerp(Color3.new(0, 0, 0), 0.35), DECO)
		end
		local landing = part("Camp", "LiftLanding", Vector3.new(4, 0.2, 4), st * CFrame.new(4.6, 1.1, 2) * CFrame.Angles(0, math.pi, 0), PAL.plank, { Transparency = 1, CanCollide = false })
		landing:SetAttribute("Landing", true)
		-- the runic boundary ring (CMP-01): glowing mint segments on the floor round the safe zone; inside it you are safe
		local ringR = 8.6 * CELL
		for k = 0, 47 do
			local a = k / 48 * math.pi * 2
			part("Camp", "Rune", Vector3.new(4.6, 0.2, 0.7), CFrame.new(origin + Vector3.new(math.cos(a) * ringR, 0.12, math.sin(a) * ringR)) * CFrame.Angles(0, -a + math.pi / 2, 0), Color3.fromRGB(150, 225, 170), { Material = Enum.Material.Neon, CanCollide = false, CastShadow = false, Transparency = 0.4 }) -- softer: the bloom smeared the ring into yellow glare (i65)
		end
		local zone = part("Camp", "SafeZone", Vector3.new(ringR * 2, 30, ringR * 2), CFrame.new(origin + Vector3.new(0, 15, 0)), PAL.mint, { Transparency = 1, CanCollide = false, CanQuery = false, CastShadow = false })
		zone.Shape = Enum.PartType.Cylinder
		zone.CFrame = CFrame.new(origin + Vector3.new(0, 15, 0)) * CFrame.Angles(0, 0, math.pi / 2)
		zone.Size = Vector3.new(30, ringR * 2, ringR * 2)
		zone:SetAttribute("SafeZone", true)
		-- lantern posts round the ring
		for k = 0, 5 do
			local a = k / 6 * math.pi * 2 + 0.3
			local p = origin + Vector3.new(math.cos(a) * (ringR + 3), 0, math.sin(a) * (ringR + 3))
			part("Camp", "LanternPost", Vector3.new(0.6, 6, 0.6), p + Vector3.new(0, 3, 0), PAL.bark)
			lantern("Camp", "Lantern", p + Vector3.new(0, 6.9, 0), PAL.warm, 30, 1.3)
		end
		local fill = part("Camp", "WarmFill", Vector3.new(1, 1, 1), W(0, 0, 22), PAL.warm, { Transparency = 1, CanCollide = false, CanQuery = false })
		glow(fill, Color3.fromRGB(255, 200, 150), 70, 0.5)
		for _, at in { { -5, 5 }, { 5, 6 }, { -6.5, -1.5 } } do -- a lantern glow by each tent
			lantern("Camp", "TentLamp", W(at[1], at[2], 1.2) + Vector3.new(2.5, 0, 2.5), PAL.warm, 24, 0.9)
		end
		return exits
	end

	-- CHASM (ENV-01): a ledge, a deep drop with a sagging rope bridge, a far ledge; walls very high
	local function chasm(oi, oj, rot, mirror, y0)
		local toIJ, cf = placer(oi, oj, rot, mirror, y0)
		for u = 0, 38 do
			for v = -10, 10 do
				local half = 6 + math.noise(u * 0.18, seed * 0.03, 7.7) * 3 + (u > 9 and u < 29 and 2 or 0)
				if math.abs(v) <= half then
					local deep = u >= 10 and u <= 28
					local f = deep and -86 or (u > 28 and -2 or 0)
					if deep and math.abs(v) > half - 1.5 and hash(u, v, 9) > 0.35 then f = -6 - math.floor(hash(u, v, 4) * 30) end -- ragged ledges down the sides
					local i, j = toIJ(u, v)
					stamp(i, j, y0 + f, y0 + 52 + math.floor(math.noise(u * 0.2, v * 0.2, 2) * 14), "chasm", 2)
				end
			end
		end
		-- rope bridge: 21 planks sagging between two post pairs, rope rails at hand height
		local n = 20
		for k = 0, n do
			local t = k / n
			local sag = -8 * math.sin(t * math.pi)
			part("Chasm", "Plank", Vector3.new(3.5, 0.6, 5.6), cf(9 + t * 20, 0, sag - 0.2), lerpC(PAL.plank, PAL.barkLt, hash(k, 1, 1)))
		end
		for _, side in { -1, 1 } do
			for _, u in { 8.6, 29.4 } do part("Chasm", "BridgePost", Vector3.new(0.7, 5, 0.7), cf(u, side * 0.85, 2.5), PAL.bark) end
			for k = 0, n - 1 do
				local t0, t1 = k / n, (k + 1) / n
				local a = cf(9 + t0 * 20, side * 0.8, 3 - 8 * math.sin(t0 * math.pi)).Position
				local b = cf(9 + t1 * 20, side * 0.8, 3 - 8 * math.sin(t1 * math.pi)).Position
				part("Chasm", "Rail", Vector3.new(0.25, 0.25, (b - a).Magnitude + 0.1), CFrame.lookAt((a + b) / 2, b), PAL.rope, DECO)
			end
		end
		-- glowing teal crystal clusters on both walls all the way down, mint moss glows on the ledges (ENV-01)
		for k = 1, 16 do
			local u = 9 + (k - 1) * 1.3
			local side = (k % 2 == 0) and 1 or -1
			local y = -8 - ((k * 7) % 5) * 15
			local base = cf(u, side * (7.6 + hash(k, 3, 3)), y) * CFrame.Angles(0, 0, side * 0.5)
			for q = 0, 2 do
				local c = part("Chasm", "WallCrystal", Vector3.new(1.6, 2.4 + q, 1.6), base * CFrame.new(q * 1.2 - 1.2, 0, (q % 2) * 1.2) * CFrame.Angles(0.3 * q, k + q, 0.4 - q * 0.3), q == 1 and PAL.lightTeal or PAL.teal, { Material = Enum.Material.Neon, CanCollide = false, CastShadow = false })
				if q == 1 and k % 2 == 1 then glow(c, PAL.lightTeal, 36, 1.5) end
			end
		end
		for k = 0, 7 do
			local u = k < 4 and 1 + k * 2 or 29 + (k - 4) * 2.2
			local m = part("Chasm", "MossGlow", Vector3.new(3, 0.4, 3), cf(u, (k % 2 == 0 and 1 or -1) * (3 + hash(k, 1, 4) * 2), (u > 28 and -2 or 0) + 0.2), PAL.mint, { Material = Enum.Material.Neon, CanCollide = false, CastShadow = false })
			if k % 2 == 0 then glow(m, PAL.lightMint, 18, 0.9) end
		end
		for k, u in { 13, 19, 25 } do -- the bottom of the chasm glows teal far below the bridge (ENV-01 depth)
			local g = part("Chasm", "DeepGlow", Vector3.new(2, 2, 2), cf(u, 0, -74), PAL.teal, { Transparency = 1, CanCollide = false, CanQuery = false })
			glow(g, Color3.fromRGB(80, 200, 210), 70, 3.2)
		end
		for k = 0, 17 do -- a glowing stream winding along the chasm floor, so the drop reads as deep (ENV-01)
			local u = 10 + k
			local v = math.sin(k * 0.6) * 2
			part("Chasm", "Stream", Vector3.new(4.4, 0.6, 5), cf(u, v, -83.5) * CFrame.Angles(0, math.cos(k * 0.6) * 0.5, 0), k % 2 == 0 and PAL.teal or Color3.fromRGB(50, 150, 160), { Material = Enum.Material.Neon, CanCollide = false, CastShadow = false })
		end
		for k = 0, 5 do -- lavender rim lights on the stepped ledges
			local rim = part("Chasm", "RimFill", Vector3.new(1, 1, 1), cf(10 + k * 3.6, (k % 2 == 0 and 1 or -1) * 6, -12 - (k % 3) * 12), PAL.lilac, { Transparency = 1, CanCollide = false, CanQuery = false })
			glow(rim, Color3.fromRGB(150, 110, 195), 36, 1.3)
		end
		do -- kill floor (playtest 2): touching the chasm bottom ends the dive like passing out in the lake (PixelServer); dark mist hides it
			local kf = part("Chasm", "KillFloor", Vector3.new(34, 4, 24), cf(19, 0, -79), PAL.plum or Color3.fromRGB(40, 24, 60), { Transparency = 1, CanCollide = false, CanQuery = false })
			kf:SetAttribute("KillFloor", true)
			local mist = Instance.new("ParticleEmitter")
			mist.Name = "DeepMist"
			mist.Rate, mist.Lifetime, mist.Speed, mist.SpreadAngle = 7, NumberRange.new(4, 7), NumberRange.new(0.3, 0.9), Vector2.new(180, 20)
			mist.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 6), NumberSequenceKeypoint.new(1, 12) })
			mist.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.55), NumberSequenceKeypoint.new(1, 1) })
			mist.Color, mist.LightEmission, mist.LightInfluence = ColorSequence.new(Color3.fromRGB(34, 20, 52), Color3.fromRGB(70, 40, 100)), 0, 0.3
			mist.RotSpeed, mist.Rotation = NumberRange.new(-12, 12), NumberRange.new(0, 360)
			mist.Shape, mist.ShapeStyle = Enum.ParticleEmitterShape.Box, Enum.ParticleEmitterShapeStyle.Volume
			mist.Parent = kf
			local wisp = mist:Clone() -- slow purple wisps curling up out of the mist
			wisp.Name, wisp.Rate, wisp.LightEmission = "DeepWisp", 2, 0.4
			wisp.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 1.6) })
			wisp.Color, wisp.Speed = ColorSequence.new(Color3.fromRGB(150, 100, 210)), NumberRange.new(1, 2)
			wisp.Parent = kf
		end
		for k, y in { 30, -20, -55 } do -- soft lilac fills down the drop so the walls read as lilac and plum, never pitch black
			local fill = part("Chasm", "Fill", Vector3.new(1, 1, 1), cf(14 + k * 5, (k - 2) * 3, y), PAL.lilac, { Transparency = 1, CanCollide = false, CanQuery = false })
			glow(fill, Color3.fromRGB(150, 120, 220), 60, 0.7)
		end
		return { { toIJ(0, 0) } }, { { toIJ(38, 0) } }
	end

	-- GROTTO (ENV-02): a bowl of water under a low dome, rune pillars standing in it, violet quartz round the rim
	local function grotto(oi, oj, rot, mirror, y0)
		local toIJ, cf = placer(oi, oj, rot, mirror, y0)
		local waterY = -3
		for u = 0, 30 do
			for v = -13, 13 do
				local du, dv = (u - 15) / 15, v / 12
				local r = math.sqrt(du * du + dv * dv) + math.noise(u * 0.25, v * 0.25, 4.4) * 0.12
				if r <= 1 or (u <= 4 and math.abs(v) <= 2) then
					local f = math.floor(-14 * math.clamp(1.25 - r * 1.25, 0, 1) + hash(u, v, 5) * 1.5)
					local i, j = toIJ(u, v)
					stamp(i, j, y0 + f, y0 + 26 + math.floor(10 * (1 - r) + math.noise(u * 0.3, v * 0.3, 5) * 5), "grotto", 2)
				end
			end
		end
		local water = part("Grotto", "Water", Vector3.new(30 * CELL, 1, 24 * CELL), cf(15, 0, waterY - 0.5), Color3.fromRGB(75, 215, 220), { Transparency = 0.5, Reflectance = 0.4, CanCollide = false, CastShadow = false, Material = Enum.Material.Glass })
		for k = 0, 5 do -- underwater glow on the basin floor
			local a = k / 6 * math.pi * 2
			local uw = part("Grotto", "UnderGlow", Vector3.new(2, 2, 2), cf(15 + math.cos(a) * 7, math.sin(a) * 5, -12), Color3.fromRGB(60, 230, 225), { Transparency = 1, CanCollide = false, CanQuery = false })
			glow(uw, Color3.fromRGB(60, 230, 225), 26, 3)
		end
		glow(water, PAL.lightTeal, 56, 1.6)
		local bubbles = Instance.new("ParticleEmitter")
		bubbles.Color, bubbles.LightEmission, bubbles.Rate = ColorSequence.new(Color3.fromRGB(200, 255, 250)), 0.6, 10
		bubbles.Size, bubbles.Lifetime, bubbles.Speed = NumberSequence.new(0.35), NumberRange.new(2, 3), NumberRange.new(2, 4)
		bubbles.EmissionDirection, bubbles.Shape = Enum.NormalId.Top, Enum.ParticleEmitterShape.Box
		bubbles.Parent = water
		-- four rune pillars: stone blocks stacked to the ceiling, aqua rune strips that glow
		for k, at in { { 10, -5 }, { 20, -5 }, { 10, 5 }, { 20, 5 } } do
			for s = 0, 7 do
				local y = -14 + s * 5
				part("Grotto", "Pillar", Vector3.new(5 - (s % 2) * 0.6, 5, 5 - (s % 2) * 0.6), cf(at[1], at[2], y + 2.5) * CFrame.Angles(0, (s % 3) * 0.08, 0), lerpC(PAL.rock[3], PAL.rock[4], hash(k, s, 6)))
			end
			part("Grotto", "PillarBase", Vector3.new(8, 2, 8), cf(at[1], at[2], -13), PAL.rock[2])
			part("Grotto", "PillarBase", Vector3.new(6.4, 2, 6.4), cf(at[1], at[2], -11), PAL.rock[3])
			part("Grotto", "PillarCap", Vector3.new(6.4, 2, 6.4), cf(at[1], at[2], 22), PAL.rock[3])
			part("Grotto", "PillarCap", Vector3.new(8, 2, 8), cf(at[1], at[2], 24), PAL.rock[2])
			for fi, face in { 0, math.pi / 2, math.pi, math.pi * 1.5 } do
				for g = 0, 1 do -- square rune glyphs set into each face
					local glyph = part("Grotto", "Rune", Vector3.new(1.2, 1.2, 0.2), cf(at[1], at[2], 2 + g * 6) * CFrame.Angles(0, face, 0) * CFrame.new((g - 0.5) * 1.2, 0, -2.6), Color3.fromRGB(110, 200, 210), { Material = Enum.Material.Neon, CanCollide = false, CastShadow = false })
					if fi == 1 and g == 0 then glow(glyph, PAL.lightTeal, 24, 1.3) end
				end
			end
		end
		-- violet quartz clusters on the rim
		for k = 0, 7 do
			local a = k / 8 * math.pi * 2 + 0.4
			local u, v = 15 + math.cos(a) * 13, math.sin(a) * 10
			local base = cf(u, v, 1)
			for q = 0, 3 do
				local h = 2 + hash(k, q, 7) * 4
				local qcf = base * CFrame.new((q % 2 - 0.5) * 1.6, h / 2 - 0.5, (math.floor(q / 2) - 0.5) * 1.6) * CFrame.Angles(hash(k, q, 8) - 0.5, q, hash(q, k, 9) - 0.5)
				part("Grotto", "QuartzCore", Vector3.new(0.8, h * 0.8, 0.8), qcf, PAL.violet, { Material = Enum.Material.Neon, CanCollide = false, CastShadow = false })
				part("Grotto", "Quartz", Vector3.new(2, h + 1, 2), qcf, Color3.fromRGB(215, 120, 240), { Material = Enum.Material.Glass, Transparency = 0.35, CanCollide = false, CastShadow = false })
			end
			if k % 2 == 0 then glow(group("Grotto"):GetChildren()[#group("Grotto"):GetChildren()], Color3.fromRGB(225, 110, 245), 24, 2.2) end
		end
		return { { toIJ(0, 0) } }, { { toIJ(30, 0) }, { toIJ(15, 12) } }
	end

	-- ROOT SQUEEZE into the MUSHROOM HALL (ENV-03): a low crawl under root beams, then a tall hall of giant glowing mushrooms
	local function mushrooms(oi, oj, rot, mirror, y0)
		local toIJ, cf = placer(oi, oj, rot, mirror, y0)
		for u = 0, 13 do
			for v = -2, 2 do
				if math.abs(v) <= 1 + (hash(u, v, 10) > 0.6 and 1 or 0) then
					local i, j = toIJ(u, v)
					stamp(i, j, y0 - math.floor(u * 0.4), y0 - math.floor(u * 0.4) + 9 + math.floor(hash(u, v, 11) * 3), "squeeze", 2)
				end
			end
		end
		for k = 1, 5 do -- root beams across the squeeze
			part("Mushrooms", "Root", Vector3.new(1.4, 1.4, 16), cf(k * 2.4, 0, 7 - k * 0.4) * CFrame.Angles(0, math.pi / 2 + (hash(k, 1, 2) - 0.5) * 0.6, (hash(k, 2, 3) - 0.5) * 0.3), PAL.bark)
		end
		for k = 0, 15 do -- a gnarled root arch framing the squeeze mouth (ENV-03 framing)
			local a = k / 15 * math.pi
			local len = 6 + hash(k, 5, 5) * 4
			part("Mushrooms", "ArchRoot", Vector3.new(3 + hash(k, 1, 6), 3 + hash(k, 2, 6), len), cf(12.5, math.cos(a) * 2.6, 1 + math.sin(a) * 9) * CFrame.Angles(a - math.pi / 2, math.pi / 2 + (hash(k, 3, 6) - 0.5) * 0.6, 0), k % 3 == 0 and PAL.barkLt or PAL.bark)
		end
		local hy = -6
		for u = 12, 44 do
			for v = -16, 16 do
				local du, dv = (u - 28) / 16, v / 15
				local r = math.sqrt(du * du + dv * dv) + math.noise(u * 0.2, v * 0.2, 6.6) * 0.1
				if r <= 1 then
					local f = hy + math.floor(math.noise(u * 0.12, v * 0.12, 8.8) * 4)
					local i, j = toIJ(u, v)
					stamp(i, j, y0 + f, y0 + 58 + math.floor(math.noise(u * 0.15, v * 0.15, 9.9) * 12 - r * 14), "mush", 2)
				end
			end
		end
		-- giant mushrooms: a cream stalk, a wide glowing cap with darker gills under it and pale spots on top
		local CAPS = { PAL.capMint, PAL.capTeal, PAL.capLilac, PAL.capPink, PAL.capMint }
		local function floorAt(u, v) -- floor height under piece cell (u, v), relative to the piece base
			local i, j = toIJ(math.floor(u + 0.5), math.floor(v + 0.5))
			local c = cells[key(i, j)]
			return c and c.f - y0 or hy
		end
		for k, at in { { 22, -6, 26 }, { 30, 7, 34 }, { 36, -8, 22 }, { 26, 9, 18 }, { 33, 0, 40 } } do
			local h, capW = at[3], 10 + at[3] * 0.3
			local hy = floorAt(at[1], at[2]) -- stand on the real floor (the hall floor rolls up to 4 studs either way)
			for s = 0, math.floor(h / 4) do
				part("Mushrooms", "Stalk", Vector3.new(3.6 - s * 0.05, 4.2, 3.6 - s * 0.05), cf(at[1], at[2], hy + s * 4 + 2) * CFrame.Angles(0, s * 0.15, (s % 2 - 0.5) * 0.05), lerpC(PAL.cream, Color3.fromRGB(200, 186, 214), hash(k, s, 12)))
			end
			local col = CAPS[k]
			local cap = part("Mushrooms", "Cap", Vector3.new(capW, 2.4, capW), cf(at[1], at[2], hy + h + 1.6), col, { Material = Enum.Material.Neon, CastShadow = false })
			part("Mushrooms", "CapMid", Vector3.new(capW * 0.78, 2.4, capW * 0.78), cf(at[1], at[2], hy + h + 3.8), col:Lerp(Color3.new(1, 1, 1), 0.12), { Material = Enum.Material.Neon, CastShadow = false })
			part("Mushrooms", "CapTop", Vector3.new(capW * 0.5, 2, capW * 0.5), cf(at[1], at[2], hy + h + 5.8), col:Lerp(Color3.new(1, 1, 1), 0.25), { Material = Enum.Material.Neon, CastShadow = false })
			for e = 0, 3 do -- drooping rim blocks so the cap edge is not a straight line
				local a = e * math.pi / 2 + k
				part("Mushrooms", "CapRim", Vector3.new(capW * 0.4, 1.6, 2), cf(at[1], at[2], hy + h + 0.4) * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, capW * 0.45), col:Lerp(Color3.new(0, 0, 0), 0.15), { Material = Enum.Material.Neon, CanCollide = false, CastShadow = false })
			end
			part("Mushrooms", "Gills", Vector3.new(capW * 0.9, 0.6, capW * 0.9), cf(at[1], at[2], hy + h + 0.3), col:Lerp(Color3.new(0, 0, 0), 0.55), DECO)
			for q = 0, 3 do
				part("Mushrooms", "Spot", Vector3.new(1.6, 0.5, 1.6), cf(at[1], at[2], hy + h + 4.9) * CFrame.new((hash(k, q, 13) - 0.5) * capW * 0.5, 0, (hash(q, k, 14) - 0.5) * capW * 0.5), Color3.fromRGB(255, 250, 240), { Material = Enum.Material.Neon, CanCollide = false, CastShadow = false })
			end
			glow(cap, col:Lerp(Color3.new(1, 1, 1), 0.35), 44 + h * 0.5, 1.8)
			local under = part("Mushrooms", "UnderGlow", Vector3.new(1, 1, 1), cf(at[1], at[2], hy + h - 4), col, { Transparency = 1, CanCollide = false, CanQuery = false })
			glow(under, col:Lerp(Color3.new(1, 1, 1), 0.3), 40, 2.6)
			local spores = Instance.new("ParticleEmitter")
			spores.Color, spores.LightEmission, spores.Rate = ColorSequence.new(col), 1, 4
			spores.Size, spores.Lifetime, spores.Speed = NumberSequence.new(0.3, 0), NumberRange.new(4, 6), NumberRange.new(0.5, 1.5)
			spores.EmissionDirection, spores.Acceleration = Enum.NormalId.Bottom, Vector3.new(0, -0.5, 0)
			spores.Parent = cap
		end
		for k = 0, 15 do -- floating spores high in the hall, a few casting light
			local sp = part("Mushrooms", "Spore", Vector3.new(0.5, 0.5, 0.5), cf(18 + hash(k, 7, 7) * 20, (hash(k, 8, 7) - 0.5) * 22, 8 + hash(k, 9, 7) * 14), Color3.fromRGB(160, 255, 220), { Material = Enum.Material.Neon, CanCollide = false, CastShadow = false })
			if k % 4 == 0 then glow(sp, Color3.fromRGB(160, 255, 220), 10, 0.8) end
		end
		for k = 0, 13 do -- little glowing mushrooms on the floor
			local u, v = 16 + hash(k, 1, 15) * 24, (hash(k, 2, 15) - 0.5) * 24
			local small = cf(u, v, floorAt(u, v))
			part("Mushrooms", "SmallStalk", Vector3.new(0.6, 1.4, 0.6), small * CFrame.new(0, 0.7, 0), PAL.cream, DECO)
			part("Mushrooms", "SmallCap", Vector3.new(2, 0.7, 2), small * CFrame.new(0, 1.6, 0), CAPS[k % 5 + 1], { Material = Enum.Material.Neon, CanCollide = false, CastShadow = false })
		end
		return { { toIJ(0, 0) } }, { { toIJ(44, 0) } }
	end

	-- the seed: which piece hangs off which camp exit, how far, how deep, mirrored or not; then winding tunnels join them
	local campExits = buildCamp()
	local kinds = { { chasm, "Chasm" }, { grotto, "Grotto" }, { mushrooms, "Mushrooms" } }
	for k = #kinds, 2, -1 do
		local m = rng:NextInteger(1, k)
		kinds[k], kinds[m] = kinds[m], kinds[k]
	end
	local DIR = { [0] = { 1, 0 }, [1] = { 0, 1 }, [2] = { -1, 0 }, [3] = { 0, -1 } }
	local tunnels = {}
	for n, ex in campExits do
		local d = DIR[ex[3]]
		local len = rng:NextInteger(6, 11)
		local side = rng:NextInteger(-4, 4)
		local px, pz = ex[1] + d[1] * len - d[2] * side, ex[2] + d[2] * len + d[1] * side -- piece entry cell
		local y0 = -rng:NextInteger(8, 18)
		local entries = kinds[n][1](px, pz, ex[3], rng:NextNumber() < 0.5, y0)
		group(kinds[n][2]):SetAttribute("Entry", W(px, pz, y0))
		group(kinds[n][2]):SetAttribute("Dir", Vector3.new(d[1], 0, d[2]))
		local e = entries[1]
		table.insert(tunnels, { a = { ex[1] - d[1] * 2, ex[2] - d[2] * 2 }, b = { e[1], e[2] }, d = d, ya = 0, yb = y0 })
	end
	-- tunnels: a curved path of cells 3 to 4 wide; the floor slopes from one end to the other in 1-stud steps
	for _, t in tunnels do
		local ax, az, bx, bz = t.a[1], t.a[2], t.b[1], t.b[2]
		local mx, mz = (ax + bx) / 2 + t.d[2] * rng:NextInteger(-3, 3), (az + bz) / 2 + t.d[1] * rng:NextInteger(-3, 3)
		local steps = math.max(8, math.floor(math.abs(bx - ax) + math.abs(bz - az)) * 3)
		for s = 0, steps do
			local u = s / steps
			local x = (1 - u) ^ 2 * ax + 2 * (1 - u) * u * mx + u * u * bx
			local z = (1 - u) ^ 2 * az + 2 * (1 - u) * u * mz + u * u * bz
			local y = math.floor(t.ya + (t.yb - t.ya) * u + 0.5)
			local w = 1.6 + math.noise(u * 3, seed * 0.07, 1.1) * 0.6
			for di = -2, 2 do
				for dj = -2, 2 do
					if di * di + dj * dj <= w * w then
						stamp(math.floor(x + 0.5) + di, math.floor(z + 0.5) + dj, y, y + 12 + math.floor(hash(x, z, 16) * 4), "tunnel", 1)
					end
				end
			end
		end
	end

	-- build the raster: floors (merged up to 3x3 on equal height and theme), ceilings (merged up to 4x4), walls round the edge
	local list = {}
	for _, c in cells do table.insert(list, c) end
	table.sort(list, function(a, b) return a.i < b.i or (a.i == b.i and a.j < b.j) end)
	local used = {}
	local function at(i, j) return cells[key(i, j)] end
	local nFloor, nCeil, nWall = 0, 0, 0
	for _, c in list do
		local k = key(c.i, c.j)
		if not used[k] then
			local w, h = 1, 1
			while w < 3 do
				local n = at(c.i + w, c.j)
				if n and not used[key(c.i + w, c.j)] and n.f == c.f and n.theme == c.theme then w += 1 else break end
			end
			local ok = true
			while ok and h < 3 do
				for di = 0, w - 1 do
					local n = at(c.i + di, c.j + h)
					if not n or used[key(c.i + di, c.j + h)] or n.f ~= c.f or n.theme ~= c.theme then ok = false break end
				end
				if ok then h += 1 end
			end
			for di = 0, w - 1 do for dj = 0, h - 1 do used[key(c.i + di, c.j + dj)] = true end end
			local th = THEME[c.theme]
			local mossy = math.noise(c.i * 0.15, c.j * 0.15, seed * 0.013) > 0.5 - th.moss
			local col = mossy and PAL.moss[1 + math.floor(hash(c.i, c.j, 17) * 3)] or lerpC(th[1], th[2], hash(c.i, c.j, 18))
			local depth = 16
			part("Floor", "Floor", Vector3.new(w * CELL, depth, h * CELL), W(c.i + (w - 1) / 2, c.j + (h - 1) / 2, c.f - depth / 2), col, ROCK):SetAttribute("Theme", c.theme) -- the minimap colours each area
			nFloor += 1
		end
	end
	used = {}
	for _, c in list do
		local k = key(c.i, c.j)
		if not used[k] then
			local cq = math.floor(c.c / 4) * 4
			local w, h = 1, 1
			local function same(n) return n and math.floor(n.c / 4) * 4 == cq end
			while w < 4 and same(at(c.i + w, c.j)) and not used[key(c.i + w, c.j)] do w += 1 end
			local ok = true
			while ok and h < 4 do
				for di = 0, w - 1 do
					if not same(at(c.i + di, c.j + h)) or used[key(c.i + di, c.j + h)] then ok = false break end
				end
				if ok then h += 1 end
			end
			for di = 0, w - 1 do for dj = 0, h - 1 do used[key(c.i + di, c.j + dj)] = true end end
			part("Ceiling", "Ceiling", Vector3.new(w * CELL, 12, h * CELL), W(c.i + (w - 1) / 2, c.j + (h - 1) / 2, cq + 6), lerpC(PAL.rock[1], PAL.rock[2], hash(c.i, c.j, 19)), { CastShadow = false, Material = ROCK.Material, MaterialVariant = ROCK.MaterialVariant })
			nCeil += 1
			-- audit 10: the cave roof was a black void. Bioluminescent moss patches light it from below and World Tree roots hang
			-- through it, so pillars and the roof keep a silhouette. Only where there is headroom (never in the low tunnels).
			local room = cq - c.f
			local hm = hash(c.i, c.j, 23)
			if hm > 0.74 and room >= 12 then
				local MOSS = Color3.fromRGB(80, 180, 140)
				local mw = 1.6 + hash(c.i, c.j, 24) * 2
				local mossAt = W(c.i, c.j, cq - 0.05) + Vector3.new((hash(c.i, c.j, 25) - 0.5) * 1.6, 0, (hash(c.i, c.j, 26) - 0.5) * 1.6)
				local MOSSP = { Material = Enum.Material.Neon, CanCollide = false, CanQuery = false, CastShadow = false }
				local moss = part("Ceiling", "CeilMoss", Vector3.new(mw * 0.7, 0.5, mw * 0.6), mossAt, MOSS, MOSSP)
				for q = 1, 2 + math.floor(hash(c.i, c.j, 36) * 5) do -- an irregular patch of two to six cushions, each a different size, depth, distance and shade
					local a = q * (1.1 + hash(c.i, q, 37) * 1.4) + hm * 6
					local sz = mw * (0.18 + hash(c.i + q, c.j, 34) * 0.5)
					part("Ceiling", "CeilMoss", Vector3.new(sz, 0.3 + hash(c.i, c.j + q, 35) * 0.6, sz), mossAt + Vector3.new(math.cos(a) * mw * (0.3 + hash(q, c.j, 38) * 0.5), 0, math.sin(a) * mw * (0.3 + hash(c.i, q, 39) * 0.5)), MOSS:Lerp(({ Color3.fromRGB(78, 200, 230), Color3.fromRGB(150, 235, 190), Color3.fromRGB(40, 160, 110) })[q % 3 + 1], 0.6), MOSSP) -- teal, mint and deep emerald
				end
				part("Ceiling", "CeilMossDrip", Vector3.new(0.3, 0.7 + hm, 0.3), moss.CFrame * CFrame.new(mw * 0.2, -0.5, 0), MOSS:Lerp(Color3.new(1, 1, 1), 0.2), { Material = Enum.Material.Neon, CanCollide = false, CanQuery = false, CastShadow = false })
				if hm > 0.82 then glow(moss, hm > 0.94 and Color3.fromRGB(90, 200, 250) or Color3.fromRGB(64, 224, 208), 30, 2.6) end -- the moss washes the rock round it in turquoise
			end
			local hr = hash(c.i, c.j, 27)
			if hr > 0.84 and room >= 16 then
				local n = 2 + math.floor(hash(c.i, c.j, 28) * 3)
				local at = W(c.i, c.j, cq + 0.5) + Vector3.new((hash(c.i, c.j, 29) - 0.5) * 2, 0, (hash(c.i, c.j, 30) - 0.5) * 2)
				local thick = 1.1 + hr * 0.6
				part("Ceiling", "HangRoot", Vector3.new(thick * 1.9, 0.9, thick * 1.9), CFrame.new(at - Vector3.new(0, 0.6, 0)), Color3.fromRGB(74, 46, 34), { CanCollide = false, CanQuery = false, CastShadow = false, Material = Enum.Material.Wood }) -- a collar where the root breaks through the rock
				part("Ceiling", "HangRoot", Vector3.new(thick * 1.4, 0.8, thick * 1.4), CFrame.new(at - Vector3.new(0, 1.3, 0)) * CFrame.Angles(0, 0.6, 0), Color3.fromRGB(86, 54, 40), { CanCollide = false, CanQuery = false, CastShadow = false, Material = Enum.Material.Wood })
				local ROOTP = { CanCollide = false, CanQuery = false, CastShadow = false, Material = Enum.Material.Wood }
				n = math.clamp(math.floor(room / 4.5), 3, 6) + (hash(c.i, c.j, 28) > 0.5 and 1 or 0)
				local yaw, lean = hr * 40, 0.5 + hash(c.i, c.j, 32) * 0.6
				for sgm = 1, n do -- short segments on one sweeping curve: out from the rock, then drooping back down under its own weight
					local len = 1.5 + hash(c.i, sgm, 31) * 1.1
					local tilt = lean * math.sin(sgm / n * math.pi) * (sgm < n * 0.6 and 1 or 0.6)
					local cf = CFrame.new(at) * CFrame.Angles(0, yaw + sgm * 0.25, 0) * CFrame.Angles(tilt, 0, 0)
					part("Ceiling", "HangRoot", Vector3.new(thick, len + thick * 0.5, thick), cf * CFrame.new(0, -len / 2, 0), sgm % 2 == 0 and Color3.fromRGB(96, 62, 44) or Color3.fromRGB(74, 46, 34), ROOTP) -- dark bark (plum roots lit by the moss read as steel ducts)
					at = (cf * CFrame.new(0, -len, 0)).Position
					if sgm >= 2 and hash(c.j, sgm, 33) > 0.45 then -- a thin tendril hangs straight down from the joint, a bead of moss on its end
						local tl = 1.2 + hash(c.i + sgm, c.j, 34) * 2.6
						part("Ceiling", "HangRoot", Vector3.new(0.18, tl, 0.18), CFrame.new(at - Vector3.new(0, tl / 2, 0)), Color3.fromRGB(86, 54, 40), ROOTP)
						part("Ceiling", "CeilMoss", Vector3.new(0.32, 0.32, 0.32), CFrame.new(at - Vector3.new(0, tl + 0.1, 0)), sgm % 2 == 0 and Color3.fromRGB(80, 180, 140) or Color3.fromRGB(40, 160, 110), { Material = Enum.Material.Neon, CanCollide = false, CanQuery = false, CastShadow = false })
					end
					thick *= 0.8
				end
			end
			if hash(c.i, c.j, 20) > 0.9 then -- a stalactite
				local len = 4 + math.floor(hash(c.i, c.j, 21) * 4) * 3
				-- rock-textured and tapered (Gemini r1-r3 kept reading the plain lit block as "a white placeholder hanging from the ceiling")
				part("Ceiling", "Stalactite", Vector3.new(CELL * 0.75, len, CELL * 0.75), W(c.i, c.j, cq - len / 2), PAL.rock[1], { CastShadow = false, Material = ROCK.Material, MaterialVariant = ROCK.MaterialVariant })
				part("Ceiling", "StalactiteTip", Vector3.new(CELL * 0.4, 2, CELL * 0.4), W(c.i, c.j, cq - len - 0.9), PAL.rock[1], { CastShadow = false, Material = ROCK.Material, MaterialVariant = ROCK.MaterialVariant })
			end
		end
	end
	-- walls: every closed cell next to an open one becomes a rock column from below the lowest floor to above the highest
	-- ceiling, cut into chunks of 6 to 16 studs that each take a shade, lighter the higher they sit (hue-shifted lilac)
	local wallDone = {}
	for _, c in list do
		for di = -1, 1 do
			for dj = -1, 1 do
				local wi, wj = c.i + di, c.j + dj
				local wk = key(wi, wj)
				if not cells[wk] and not wallDone[wk] then
					wallDone[wk] = true
					local lo, hi = math.huge, -math.huge
					for ai = -1, 1 do
						for aj = -1, 1 do
							local n = at(wi + ai, wj + aj)
							if n then lo, hi = math.min(lo, n.f), math.max(hi, n.c) end
						end
					end
					lo, hi = lo - 16, hi + 12
					local y = lo
					local s = 0
					while y < hi do
						local hgt = math.min(hi - y, 6 + math.floor(hash(wi, wj, s) * 6) * 2)
						local mid = y + hgt / 2
						local t = math.clamp((mid - lo) / math.max(hi - lo, 1), 0, 1)
						local col = PAL.rock[1 + math.clamp(math.floor(t * 2.2 + hash(wi, wj, s + 30) * 1.4), 0, 3)]
						part("Walls", "Rock", Vector3.new(CELL, hgt, CELL), W(wi, wj, mid), col, { CastShadow = s % 2 == 0, Material = ROCK.Material, MaterialVariant = ROCK.MaterialVariant })
						nWall += 1
						y += hgt
						s += 1
					end
				end
			end
		end
	end
	-- ore deposits (ORE-01/02): crystal clusters against walls of cells you can walk to from camp (a flood fill over steps a
	-- player can jump, 6 studs or less), at least D.spacing apart, out of the camp; dark shards round a dim core so only the glint gives them away
	local D = C.DEPOSIT
	local FOUR = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }
	local reach, queue, qi = { [key(0, 0)] = true }, { at(0, 0) }, 1
	while queue[qi] do
		local c = queue[qi]
		qi += 1
		for _, o in FOUR do
			local n = at(c.i + o[1], c.j + o[2])
			if n and not reach[key(n.i, n.j)] and math.abs(n.f - c.f) <= 6 then
				reach[key(n.i, n.j)] = true
				table.insert(queue, n)
			end
		end
	end
	local spots = {}
	for _, c in list do
		if reach[key(c.i, c.j)] and D.layer[c.theme] and (c.i * c.i + c.j * c.j) * CELL * CELL > 48 * 48 then
			for _, o in FOUR do
				if not at(c.i + o[1], c.j + o[2]) then
					table.insert(spots, { c = c, o = o })
					break
				end
			end
		end
	end
	for k = #spots, 2, -1 do
		local m = rng:NextInteger(1, k)
		spots[k], spots[m] = spots[m], spots[k]
	end
	local placed = {}
	for _, sp in spots do
		if #placed >= D.max then break end
		local c = sp.c
		local pos = W(c.i, c.j, c.f)
		local free = true
		for _, q in placed do
			if (q - pos).Magnitude < D.spacing then free = false break end
		end
		if free then
			table.insert(placed, pos)
			local L = D.layer[c.theme]
			local rareP = D.rare + D.rareDeep * math.clamp(-c.f / 40, 0, 1)
			local roll = rng:NextNumber()
			local idx = roll < rareP and 3 or (roll < rareP + D.uncommon and 2 or 1)
			local ore = C.LAYERS[L][4][idx]
			local dep = Instance.new("Model")
			dep.Name = "Deposit"
			dep:SetAttribute("Layer", L)
			dep:SetAttribute("Ore", idx)
			dep:SetAttribute("OreName", ore[1])
			local wall = Vector3.new(sp.o[1], 0, sp.o[2])
			local foot = pos + wall * (CELL / 2 - 0.9)
			local base = CFrame.lookAt(foot, foot + wall)
			local k = 0.85 + idx * 0.3
			local dark = ore[2]:Lerp(Color3.new(0, 0, 0), 0.35)
			local function shard(size, cf, col, props)
				local p = part("Deposits", "Shard", size * k, cf, col, props)
				p.Parent = dep
				return p
			end
			shard(Vector3.new(2.2, 0.8, 1.6), base * CFrame.new(0, 0.3 * k, 0), PAL.rock[2], { CastShadow = false })
			local core = shard(Vector3.new(0.9, 1.9, 0.9), base * CFrame.new(0, 1.15 * k, -0.1) * CFrame.Angles(0.15, 0, 0.1), ore[2]:Lerp(Color3.new(0, 0, 0), 0.28 - idx * 0.08), { Material = Enum.Material.Neon, CastShadow = false }) -- brighter cores, rarest brightest
			core.Name = "Core"
			for s = 1, 1 + idx do -- shards lean out from the wall, tallest in the middle
				local a = (s / (1 + idx) - 0.5) * 2.4
				local h = 1 + hash(c.i, c.j, s + 40) * 1.1
				shard(Vector3.new(0.7, h, 0.7), base * CFrame.new(math.sin(a) * 0.8, h * 0.45 * k, math.cos(a) * 0.3 - 0.4) * CFrame.Angles(0.35, 0, -a * 0.4), lerpC(dark, ore[2], hash(c.i, s, 41) * 0.6), { CastShadow = false })
			end
			local l = glow(core, ore[2], 7, 0.35)
			l.Name = "Glint"
			dep.PrimaryPart = core
			dep.Parent = group("Deposits")
		end
	end
	do -- carve the cave wall out of the Deep Gate's opening and alcove (the rock cells there would block the door)
		local box = CFrame.new(origin + Vector3.new(-48.5, 5.5, 14)) -- the alcove's centre, 15 x 11 x 10 studs
		for _, p in group("Walls"):GetChildren() do
			local d = box:PointToObjectSpace(p.Position)
			if math.abs(d.X) < 8 and math.abs(d.Y) < 6 and math.abs(d.Z) < 5 then p:Destroy() end
		end
	end
	do -- hidden shrines: a rune stone, a plinth and a little chest in a quiet nook far from camp, away from the deposits
		local SH = D.shrines
		local made = 0
		for _, sp in spots do
			if made >= SH.count then break end
			local c = sp.c
			local pos = W(c.i, c.j, c.f)
			local far = (c.i * c.i + c.j * c.j) * CELL * CELL > SH.minDist * SH.minDist
			local clear = true
			for _, q in placed do if (q - pos).Magnitude < 12 then clear = false break end end
			if far and clear then
				made += 1
				table.insert(placed, pos)
				local wall = Vector3.new(sp.o[1], 0, sp.o[2])
				local foot = pos + wall * (CELL / 2 - 1.2)
				local base = CFrame.lookAt(foot, foot - wall) -- faces out of the wall
				local L = D.layer[c.theme] or 1
				part("Shrines", "ShrineStone", Vector3.new(3, 4.4, 0.8), base * CFrame.new(0, 2.2, 0.9), PAL.rock[3], { Material = ROCK.Material, MaterialVariant = ROCK.MaterialVariant })
				local rune = part("Shrines", "ShrineRune", Vector3.new(1.2, 1.6, 0.2), base * CFrame.new(0, 2.8, 0.4), PAL.lightViolet, { Material = Enum.Material.Neon, CanCollide = false, CastShadow = false })
				glow(rune, PAL.lightViolet, 10, 0.7)
				part("Shrines", "ShrinePlinth", Vector3.new(3.4, 0.8, 2.2), base * CFrame.new(0, 0.4, -0.4), PAL.rock[2], { Material = ROCK.Material, MaterialVariant = ROCK.MaterialVariant })
				local chest = part("Shrines", "ShrineChest", Vector3.new(1.8, 1.1, 1.2), base * CFrame.new(0, 1.35, -0.6), PAL.plank)
				local lid = part("Shrines", "ShrineLid", Vector3.new(1.9, 0.45, 1.3), base * CFrame.new(0, 2.12, -0.6), PAL.barkLt)
				part("Shrines", "ShrineTrim", Vector3.new(0.3, 0.3, 0.1), base * CFrame.new(0, 1.7, -1.25), PAL.warm, { Material = Enum.Material.Neon, CanCollide = false, CastShadow = false })
				lid.Name = "ShrineLid" .. made
				chest:SetAttribute("Lid", lid.Name)
				chest:SetAttribute("Layer", L)
				local pr = Instance.new("ProximityPrompt")
				pr.ActionText, pr.ObjectText, pr.KeyboardKeyCode = "Open", "Hidden Shrine", Enum.KeyCode.E
				pr.MaxActivationDistance, pr.RequiresLineOfSight, pr.HoldDuration = 8, false, 0.6
				pr.Style = Enum.ProximityPromptStyle.Custom
				pr:SetAttribute("CaveShrine", true)
				pr.Parent = chest
			end
		end
		model:SetAttribute("Shrines", made)
	end
	do -- egg nests (playtest 2, board PT2_Eggs): a twig nest with one glowing egg in a quiet nook, a soft shaft of light from above
		-- and drifting motes; free, once an hour per player (PixelServer CaveNest)
		local NE = D.nests
		local EGG_COL = { Color3.fromRGB(159, 217, 154), Color3.fromRGB(255, 170, 120), Color3.fromRGB(140, 205, 235) } -- moss, ember, tide
		local made = 0
		for _, sp in spots do
			if made >= NE.count then break end
			local c = sp.c
			local pos = W(c.i, c.j, c.f)
			local far = (c.i * c.i + c.j * c.j) * CELL * CELL > NE.minDist * NE.minDist
			local clear = true
			for _, q in placed do if (q - pos).Magnitude < 14 then clear = false break end end
			if far and clear then
				made += 1
				table.insert(placed, pos)
				local wall = Vector3.new(sp.o[1], 0, sp.o[2])
				local foot = pos + wall * (CELL / 2 - 1.8)
				local base = CFrame.lookAt(foot, foot - wall)
				local twig = PAL.bark or Color3.fromRGB(120, 86, 70)
				part("Nests", "NestBed", Vector3.new(2.8, 0.4, 2.8), base * CFrame.new(0, 0.2, -0.6), Color3.fromRGB(214, 186, 120))
				for k, o in { { 0, 1.35, 3.2, 0.6 }, { 0, -1.35, 3.2, 0.6 }, { 1.35, 0, 0.6, 3.2 }, { -1.35, 0, 0.6, 3.2 } } do
					part("Nests", "NestTwig", Vector3.new(o[3], 0.55 + k * 0.03, o[4]), base * CFrame.new(o[1], 0.5, -0.6 + o[2]) * CFrame.Angles(0, k * 0.08, 0), twig)
				end
				local col = EGG_COL[(made - 1) % #EGG_COL + 1]
				local egg = part("Nests", "NestEgg", Vector3.new(1.3, 1.3, 1.3), base * CFrame.new(0, 1.35, -0.6), col, { CanCollide = false })
				local mesh = Instance.new("SpecialMesh")
				mesh.MeshType, mesh.Scale = Enum.MeshType.Sphere, Vector3.new(1, 1.3, 1)
				mesh.Parent = egg
				glow(egg, col:Lerp(Color3.new(1, 1, 1), 0.4), 12, 0.9)
				local shaft = part("Nests", "NestShaft", Vector3.new(2.2, 14, 2.2), base * CFrame.new(0, 8, -0.6), Color3.fromRGB(255, 238, 200), { Material = Enum.Material.Neon, Transparency = 0.9, CanCollide = false, CanQuery = false, CastShadow = false })
				shaft:SetAttribute("NoDim", true)
				local motes = Instance.new("ParticleEmitter")
				motes.Rate, motes.Lifetime, motes.Speed, motes.SpreadAngle = 4, NumberRange.new(2, 3.5), NumberRange.new(0.4, 1), Vector2.new(40, 40)
				motes.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.4, 0.18), NumberSequenceKeypoint.new(1, 0) })
				motes.Color, motes.LightEmission, motes.EmissionDirection = ColorSequence.new(col:Lerp(Color3.new(1, 1, 1), 0.5)), 1, Enum.NormalId.Top
				motes.Parent = egg
				local pr = Instance.new("ProximityPrompt")
				pr.ActionText, pr.ObjectText, pr.KeyboardKeyCode = "Take egg", "Egg nest", Enum.KeyCode.E
				pr.MaxActivationDistance, pr.RequiresLineOfSight, pr.HoldDuration = 9, false, 0.5
				pr.Style = Enum.ProximityPromptStyle.Custom
				pr:SetAttribute("CaveNest", true)
				pr.Parent = egg
			end
		end
		model:SetAttribute("Nests", made)
	end
	do -- the Egg Altar (playtest 2, board PT2_Eggs): a stone dais in a far nook, three eggs on pedestals, the odds on a lit tablet
		local AL = C.ALTAR
		for _, sp in spots do
			local c = sp.c
			local pos = W(c.i, c.j, c.f)
			local far = (c.i * c.i + c.j * c.j) * CELL * CELL > 80 * 80
			local clear = true
			for _, q in placed do if (q - pos).Magnitude < 16 then clear = false break end end
			if far and clear then
				table.insert(placed, pos)
				local wall = Vector3.new(sp.o[1], 0, sp.o[2])
				local foot = pos + wall * (CELL / 2 - 2.6)
				local base = CFrame.lookAt(foot, foot - wall)
				local stone = { Material = ROCK.Material, MaterialVariant = ROCK.MaterialVariant }
				local dais = part("Altar", "AltarDais", Vector3.new(7, 0.8, 4.2), base * CFrame.new(0, 0.4, -0.4), PAL.rock[3], stone)
				part("Altar", "AltarStep", Vector3.new(5.6, 0.4, 1.2), base * CFrame.new(0, 0.22, -3.1), PAL.rock[2], stone)
				for k, e in AL.eggs do
					local x = (k - 2) * 2.2
					part("Altar", "AltarPedestal", Vector3.new(1.3, 1.6 + (k == 3 and 0.4 or 0), 1.3), base * CFrame.new(x, 1.6 + (k == 3 and 0.2 or 0), 0), PAL.rock[2], stone)
					local egg = part("Altar", "AltarEgg" .. k, Vector3.new(1, 1, 1), base * CFrame.new(x, 3.05 + (k == 3 and 0.4 or 0), 0), e[4], { CanCollide = false, Material = k == 1 and Enum.Material.Glass or Enum.Material.SmoothPlastic, Transparency = k == 1 and 0.15 or 0 })
					local mesh = Instance.new("SpecialMesh")
					mesh.MeshType, mesh.Scale = Enum.MeshType.Sphere, Vector3.new(1, 1.3, 1)
					mesh.Parent = egg
					glow(egg, e[4], 9, 0.8)
				end
				local tab = part("Altar", "AltarTablet", Vector3.new(4.2, 2.4, 0.4), base * CFrame.new(0, 4.6, 0.9) * CFrame.Angles(math.rad(-12), 0, 0), PAL.rock[3], stone)
				local sg = Instance.new("SurfaceGui")
				sg.Face, sg.SizingMode, sg.PixelsPerStud, sg.LightInfluence = Enum.NormalId.Front, Enum.SurfaceGuiSizingMode.PixelsPerStud, 40, 0
				local lab = Instance.new("TextLabel")
				lab.Size, lab.BackgroundTransparency, lab.TextScaled, lab.Font = UDim2.fromScale(1, 1), 0.15, true, Enum.Font.FredokaOne
				lab.BackgroundColor3, lab.TextColor3 = Color3.fromRGB(46, 34, 66), Color3.fromRGB(255, 236, 200)
				local lines = { "EGG ALTAR  " .. AL.cost .. " COINS" }
				for _, e in AL.eggs do table.insert(lines, e[1] .. " " .. e[2] .. "%") end
				lab.Text = table.concat(lines, "\n")
				lab.Parent = sg
				sg.Parent = tab
				local pr = Instance.new("ProximityPrompt")
				pr.ActionText, pr.ObjectText, pr.KeyboardKeyCode = "Roll an egg", "Egg Altar (" .. AL.cost .. " coins)", Enum.KeyCode.E
				pr.MaxActivationDistance, pr.RequiresLineOfSight, pr.HoldDuration = 9, false, 0.6
				pr.Style = Enum.ProximityPromptStyle.Custom
				pr:SetAttribute("EggAltar", true)
				pr.Parent = dais
				model:SetAttribute("Altar", true)
				break
			end
		end
	end
	for _, o in group("Camp"):GetChildren() do -- Gemini r3: the station and camp timbers were flat salmon blocks under the lamps: real wood grain, a shade darker
		local n = o.Name
		if o.Material == Enum.Material.SmoothPlastic and (n:find("Post") or n:find("Beam") or n:find("Arm") or n == "Pole" or n == "BenchSeat" or n == "BenchLeg" or n == "StationCrate" or n == "StationBarrel" or n == "Counter") then
			o.Material = (n == "StationCrate" or n == "Counter") and Enum.Material.WoodPlanks or Enum.Material.Wood
			o.Color = o.Color:Lerp(Color3.fromRGB(60, 40, 44), 0.35)
		end
	end
	do -- playtest 2 (board 6): a cave again. Every glow that is not ore (crystals, moss, mushrooms, streams, fills, lamps) drops to about half
		local depF = model:FindFirstChild("Deposits")
		for _, o in model:GetDescendants() do
			if depF and o:IsDescendantOf(depF) then continue end
			if model:FindFirstChild("Nests") and o:IsDescendantOf(model.Nests) then continue end
			if o:GetAttribute("Fixture") then continue end -- lantern wicks and their lights are tuned as built
			if model:FindFirstChild("Altar") and o:IsDescendantOf(model.Altar) then continue end -- the altar is a find too -- egg nests are a find, like ore: they keep their glow
			if o:IsA("PointLight") or o:IsA("SpotLight") or o:IsA("SurfaceLight") then
				o.Brightness *= 0.55
				o.Range *= 0.8
				if o.Range >= 40 then o.Shadows = true end -- the big fills lit through rock, flattening the walls
			elseif o:IsA("BasePart") and o.Material == Enum.Material.Neon then
				o.Color = o.Color:Lerp(Color3.new(0, 0, 0), 0.32)
			end
		end
	end
	model:SetAttribute("ZFixed", require(game:GetService("ServerScriptService"):WaitForChild("ZFix")).fix(model)) -- no z-fighting (the user, 2026-11-08)
	model:SetAttribute("Deposits", #placed)
	model:SetAttribute("Reachable", qi - 1)
	model:SetAttribute("Floors", nFloor)
	model:SetAttribute("Ceilings", nCeil)
	model:SetAttribute("Walls", nWall)
	model:SetAttribute("Cells", #list)
	model.Parent = parent
	return model
end

return Cave
