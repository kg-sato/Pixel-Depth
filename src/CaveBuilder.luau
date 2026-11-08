-- CaveBuilder: the shared cave world of the cave exploration rework (vault: Projects/Pixel-_/Briefs/Cave Exploration Rework.md,
-- numbers in Briefs/Cave Rework Reference Board (2026-11-08).md, refs in art/caves/refs).
-- Cave.build(parent, origin, seed) builds Camp 1 (fixed) and three hand-made pieces that the seed places, turns, mirrors and joins
-- with winding tunnels: a chasm with a rope bridge (ENV-01), a flooded crystal grotto (ENV-02), and a root squeeze opening into a
-- giant mushroom hall (ENV-03).
-- How it is built: a 2.5D raster of 4-stud cells. Each open cell has a floor height and a ceiling height; pieces and tunnels
-- stamp into the raster, then floors, ceilings and walls are built from it as voxel columns. Floors move in 1-stud steps so the
-- player can walk them; neighbouring cells with the same height merge (up to 3x3) to keep the part count down.
local Cave = {}

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
		glow(flame, Color3.fromRGB(255, 185, 95), 40, 3.4, true)
		local sparks = Instance.new("ParticleEmitter")
		sparks.Color, sparks.LightEmission, sparks.Rate = ColorSequence.new(PAL.warm), 1, 6
		sparks.Size, sparks.Lifetime, sparks.Speed = NumberSequence.new(0.25, 0), NumberRange.new(1.5, 2.5), NumberRange.new(3, 6)
		sparks.SpreadAngle, sparks.Acceleration = Vector2.new(15, 15), Vector3.new(0, 1, 0)
		sparks.Parent = flame
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
		part("Camp", "Lamp", Vector3.new(1, 1.2, 1), stall * CFrame.new(3.2, 6.2, 1.2), PAL.warm, { Material = Enum.Material.Neon, CanCollide = false })
		glow(group("Camp"):FindFirstChild("Lamp"), PAL.warm, 18, 1)
		-- lift winch on the south side: an A-frame, a drum, the rope up into the dark, the landing platform (players arrive here)
		local lift = CFrame.new(W(-1, -7, 0))
		part("Camp", "LiftDeck", Vector3.new(10, 1, 10), lift * CFrame.new(0, 0.5, 0), PAL.plank)
		for _, x in { -4.5, 4.5 } do
			for _, z in { -4.5, 4.5 } do part("Camp", "LiftPost", Vector3.new(0.8, 14, 0.8), lift * CFrame.new(x, 7, z), PAL.bark) end
		end
		part("Camp", "LiftBeam", Vector3.new(10.8, 0.8, 0.8), lift * CFrame.new(0, 14, 0), PAL.bark)
		part("Camp", "Drum", Vector3.new(2.4, 2.4, 6), lift * CFrame.new(0, 12.6, 0) * CFrame.Angles(0, 0, 0), PAL.barkLt)
		part("Camp", "Rope", Vector3.new(0.4, 60, 0.4), lift * CFrame.new(0, 44, 0), PAL.rope, DECO)
		local landing = part("Camp", "LiftLanding", Vector3.new(4, 0.2, 4), lift * CFrame.new(0, 1.1, 0), PAL.plank, { Transparency = 1, CanCollide = false })
		landing:SetAttribute("Landing", true)
		-- the runic boundary ring (CMP-01): glowing mint segments on the floor round the safe zone; inside it you are safe
		local ringR = 8.6 * CELL
		for k = 0, 47 do
			local a = k / 48 * math.pi * 2
			part("Camp", "Rune", Vector3.new(4.6, 0.2, 0.7), CFrame.new(origin + Vector3.new(math.cos(a) * ringR, 0.12, math.sin(a) * ringR)) * CFrame.Angles(0, -a + math.pi / 2, 0), Color3.fromRGB(190, 230, 120), { Material = Enum.Material.Neon, CanCollide = false, CastShadow = false, Transparency = 0.05 })
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
			local l = part("Camp", "Lantern", Vector3.new(1.2, 1.4, 1.2), p + Vector3.new(0, 6.4, 0), PAL.warm, { Material = Enum.Material.Neon, CanCollide = false })
			glow(l, PAL.warm, 28, 1.3)
		end
		local fill = part("Camp", "WarmFill", Vector3.new(1, 1, 1), W(0, 0, 22), PAL.warm, { Transparency = 1, CanCollide = false, CanQuery = false })
		glow(fill, Color3.fromRGB(255, 200, 150), 70, 1.1)
		for _, at in { { -5, 5 }, { 5, 6 }, { -6.5, -1.5 } } do -- a lantern glow by each tent
			local l = part("Camp", "TentLamp", Vector3.new(0.8, 1, 0.8), W(at[1], at[2], 1.2) + Vector3.new(2.5, 0, 2.5), PAL.warm, { Material = Enum.Material.Neon, CanCollide = false, CastShadow = false })
			glow(l, PAL.warm, 22, 1.2)
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
		local water = part("Grotto", "Water", Vector3.new(30 * CELL, 1, 24 * CELL), cf(15, 0, waterY - 0.5), Color3.fromRGB(75, 215, 220), { Transparency = 0.5, Reflectance = 0.25, CanCollide = false, CastShadow = false, Material = Enum.Material.Glass })
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
		for k, at in { { 22, -6, 26 }, { 30, 7, 34 }, { 36, -8, 22 }, { 26, 9, 18 }, { 33, 0, 40 } } do
			local h, capW = at[3], 10 + at[3] * 0.3
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
			local small = cf(u, v, hy + 0.5)
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
			part("Floor", "Floor", Vector3.new(w * CELL, depth, h * CELL), W(c.i + (w - 1) / 2, c.j + (h - 1) / 2, c.f - depth / 2), col, ROCK)
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
			if hash(c.i, c.j, 20) > 0.9 then -- a stalactite
				local len = 4 + math.floor(hash(c.i, c.j, 21) * 4) * 3
				part("Ceiling", "Stalactite", Vector3.new(CELL * 0.75, len, CELL * 0.75), W(c.i, c.j, cq - len / 2), PAL.rock[2], { CastShadow = false })
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
	model:SetAttribute("Floors", nFloor)
	model:SetAttribute("Ceilings", nCeil)
	model:SetAttribute("Walls", nWall)
	model:SetAttribute("Cells", #list)
	model.Parent = parent
	return model
end

return Cave
