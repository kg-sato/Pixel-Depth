-- CaveV2 (ServerScriptService.CaveV2): layer 1 Rootholm rebuilt as a real cave (vault: Projects/Pixel-_/Briefs/Cave Layout Plan v2
-- (2026-11-18).md; refs art/caves/refs_v2). The owner, 2026-11-18: "the current caves are too much like balls; future ones should
-- resemble actual caves more". The old CaveBuilder kept one floor and one ceiling per 4-stud column, so every space was a dome over a
-- flat floor. This is a true 3D grid of 4-stud voxels, carved by the shapes real caves have:
--   * tubes: oval, wider than tall, flat-bottomed (old water passages)      * canyons: a stream slot under a tall narrow walkway
--   * chambers: wide, low, with a breakdown floor of fallen blocks          * shafts: vertical drops and climbs
-- Every shape leans with the layer's dip, the walls are crumpled by noise (Deep Rock Galactic's pass), steps of one voxel get a
-- ramp so players walk instead of jump, and a decoration pass adds stalactites, stalagmites, columns, hanging roots, moss on
-- upward faces, boulders and rimstone pools. The rock shell (only solid voxels that touch air) is merged into boxes.
--   CaveV2.build(parent, origin, seed) -> Model "CavesV2"; Attachments named Spot_<place> mark the layout for tests.
-- Behind Config.CAVE_V2 (false: preview only, at Config.CAVE_V2_ORIGIN). The live caves are still CaveBuilder.
local M = {}
local V = 4 -- studs per voxel
local DIP = math.rad(6) -- the rock beds tilt down to the east: every shape sinks a little with x

local PAL = {
	rock = { Color3.fromRGB(46, 32, 66), Color3.fromRGB(62, 44, 88), Color3.fromRGB(82, 60, 112), Color3.fromRGB(106, 80, 140) },
	moss = { Color3.fromRGB(88, 52, 92), Color3.fromRGB(112, 66, 112), Color3.fromRGB(126, 80, 124) }, -- dark plum lichen, never green (the owner, 2026-11-17)
	sand = Color3.fromRGB(150, 118, 124), bark = Color3.fromRGB(96, 62, 44), barkDark = Color3.fromRGB(70, 44, 32),
	water = Color3.fromRGB(56, 170, 190), mint = Color3.fromRGB(110, 230, 180), warm = Color3.fromRGB(255, 196, 120),
	flow = Color3.fromRGB(196, 160, 150),
}

local function hash(a, b, c)
	local n = math.sin(a * 12.9898 + b * 78.233 + (c or 0) * 37.719) * 43758.5453
	return n - math.floor(n)
end

function M.build(parent, origin, seed)
	seed = seed or 1
	local rng = Random.new(seed)
	local NX, NY, NZ = 100, 34, 72 -- 400 x 136 x 288 studs
	local CX, CY, CZ = 30, 14, 30 -- voxel of the local origin (camp floor centre)
	local grid = buffer.create(NX * NY * NZ) -- 0 rock, 1 air, 2 water, 3 bark (the root column)
	local function idx(x, y, z) return (x * NY + y) * NZ + z end
	local function inside(x, y, z) return x >= 0 and y >= 0 and z >= 0 and x < NX and y < NY and z < NZ end
	local function get(x, y, z) if not inside(x, y, z) then return 0 end return buffer.readu8(grid, idx(x, y, z)) end
	local function set(x, y, z, v) if inside(x, y, z) then buffer.writeu8(grid, idx(x, y, z), v) end end
	local function toWorld(x, y, z) return origin + Vector3.new((x - CX + 0.5) * V, (y - CY + 0.5) * V, (z - CZ + 0.5) * V) end
	local function toVox(p) -- local studs (x east, y up, z south) -> voxel coordinates (fractional)
		return p.X / V + CX, p.Y / V + CY, p.Z / V + CZ
	end
	local function dipY(xStuds) return -xStuds * math.tan(DIP) end
	local wob = seed * 0.37

	-- carve a passage along a path of local points: an oval cross-section rx (half width) by ry (half height) round the axis,
	-- its bottom cut flat at floorK of ry under the axis so the floor walks; radii breathe along the length with noise
	local function passage(pts, rx, ry, opt)
		opt = opt or {}
		if (opt.fill or 1) == 1 then -- walkable: at least two voxels of headroom over the flat floor and room to turn (path test, 2026-11-19: crawls one voxel high blocked every branch)
			rx, ry = math.max(rx, 4.2), math.max(ry, 5)
			opt.flat = math.min(opt.flat or 0.55, 0.6)
		end
		local floorK = opt.flat or 0.55
		local fill = opt.fill or 1
		for s = 1, #pts - 1 do
			local a, b = pts[s], pts[s + 1]
			local len = (b - a).Magnitude
			local steps = math.max(1, math.ceil(len / (V * 0.5)))
			for t = 0, steps do
				local u = t / steps
				local p = a:Lerp(b, u)
				p = p + Vector3.new(0, dipY(p.X), 0)
				local n = math.noise(p.X * 0.03 + wob, p.Z * 0.03, s) -- the passage breathes: wider and narrower along its length
				local rxi, ryi = rx * (1 + 0.28 * n), ry * (1 + 0.18 * math.noise(p.Z * 0.04, p.X * 0.04 + wob, 7))
				local dir = (b - a).Unit
				local side = Vector3.new(-dir.Z, 0, dir.X)
				if side.Magnitude < 0.1 then side = Vector3.xAxis end
				side = side.Unit
				local vx, vy, vz = toVox(p)
				local rr = math.ceil(math.max(rxi, ryi) / V) + 1
				for x = math.floor(vx - rr), math.ceil(vx + rr) do
					for z = math.floor(vz - rr), math.ceil(vz + rr) do
						for y = math.floor(vy - rr), math.ceil(vy + rr) do
							local w = Vector3.new((x - CX + 0.5) * V, (y - CY + 0.5) * V, (z - CZ + 0.5) * V) - p
							local h = w:Dot(side)
							local d = w.Y
							if d >= -ryi * floorK and (h / rxi) ^ 2 + (d / ryi) ^ 2 <= 1 then
								if get(x, y, z) == 0 then set(x, y, z, fill) end
							end
						end
					end
				end
			end
		end
	end
	-- a chamber: a wide low ellipsoid; its floor is a breakdown slope of fallen blocks (rock left standing under a tilted, noisy plane)
	local function chamber(c, rx, ry, rz, opt)
		opt = opt or {}
		c = c + Vector3.new(0, dipY(c.X), 0)
		local vx, vy, vz = toVox(c)
		for x = math.floor(vx - rx / V) - 1, math.ceil(vx + rx / V) + 1 do
			for z = math.floor(vz - rz / V) - 1, math.ceil(vz + rz / V) + 1 do
				for y = math.floor(vy - ry / V) - 1, math.ceil(vy + ry / V) + 1 do
					local w = Vector3.new((x - CX + 0.5) * V, (y - CY + 0.5) * V, (z - CZ + 0.5) * V) - c
					local n = 0.18 * math.noise(w.X * 0.06 + wob, w.Y * 0.06, w.Z * 0.06)
					if (w.X / rx) ^ 2 + (w.Y / ry) ^ 2 + (w.Z / rz) ^ 2 <= 1 + n then
						local floorAt = -ry * (opt.floor or 0.45) + (opt.slope or 0) * w.X + 3 * math.noise(w.X * 0.09, w.Z * 0.09, wob)
						if w.Y >= floorAt and get(x, y, z) == 0 then set(x, y, z, 1) end
					end
				end
			end
		end
	end
	local function shaft(c, r, h) -- from c up h studs
		c = c + Vector3.new(0, dipY(c.X), 0)
		local vx, vy, vz = toVox(c)
		for x = math.floor(vx - r / V) - 1, math.ceil(vx + r / V) + 1 do
			for z = math.floor(vz - r / V) - 1, math.ceil(vz + r / V) + 1 do
				local w = Vector3.new((x - CX + 0.5) * V, 0, (z - CZ + 0.5) * V) - Vector3.new(c.X, 0, c.Z)
				if w.Magnitude <= r * (1 + 0.2 * math.noise(x * 0.3, z * 0.3, wob)) then
					for y = math.floor(vy), math.ceil(vy + h / V) do if get(x, y, z) == 0 then set(x, y, z, 1) end end
				end
			end
		end
	end
	local function J(a) -- seeded jitter of a waypoint: the branches change with the hour, the main route barely
		return a + Vector3.new(rng:NextNumber(-6, 6), 0, rng:NextNumber(-6, 6))
	end
	local P = Vector3.new
	local spots = {}
	local function spot(name, p) spots[name] = p + P(0, dipY(p.X), 0) end

	-- THE MAIN ROUTE (fixed) ------------------------------------------------------------------------------------------------
	-- Hearth Camp: a wide low tube where an old stream pooled (60 x 26, 12 high), flat sand floor, the lift shaft out of the roof
	passage({ P(-34, 6, 0), P(-10, 6, -2), P(12, 6, 1), P(34, 6, 0) }, 13, 8, { flat = 0.75 })
	shaft(P(0, 10, 4), 5, 34)
	spot("Camp", P(0, 1, 0))
	-- the canyon east: a stream slot (water) under a tall narrow walkway, with a ledge band higher on the north wall
	local canyon = { P(30, 0, 0), P(52, -2, 10), P(76, -4, -6), P(100, -6, 4), P(112, -6, 2) }
	passage(canyon, 6, 14, { flat = 0.0 })
	local slot = {}
	for i, p in canyon do slot[i] = p - P(0, 4, 0) end
	passage(slot, 2.4, 4, { flat = 1, fill = 2 })
	local ledge = {}
	for i, p in canyon do ledge[i] = p + P(0, 10, -5) end
	passage(ledge, 4.5, 3.5, { flat = 0.9 })
	spot("Canyon", P(76, -2, -6))
	-- Root Cathedral: a collapse chamber (72 x 52, 40 high) with a breakdown slope rising to the east, the giant root as its pillar
	chamber(P(146, 8, 0), 38, 22, 28, { floor = 0.42, slope = 0.14 })
	spot("Cathedral", P(130, 0, 6))
	-- the Old Tube: the upper level along the north, the fast way home, linked down to camp (shortcut 1) and into the cathedral roof
	passage({ P(-140, 26, -86), P(-60, 24, -92), P(20, 22, -88), P(100, 22, -90), P(150, 20, -80) }, 9, 5.5, { flat = 0.7 })
	passage({ P(22, 6, -10), P(30, 12, -48), P(26, 22, -86) }, 5, 5, { flat = 0.8 }) -- the climb from camp to the Old Tube
	passage({ P(150, 20, -80), P(150, 16, -44), P(146, 14, -24) }, 6, 6, { flat = 0.8 }) -- the Old Tube drops into the cathedral's north end
	spot("OldTube", P(20, 22, -88))
	-- down from the cathedral's low south-east corner to the Sump Gate, and the lower canyon back west under the camp
	passage({ P(150, 0, 22), P(132, -10, 42), P(116, -22, 58) }, 6, 6, { flat = 0.8 })
	chamber(P(108, -22, 62), 16, 9, 12, { floor = 0.5 })
	spot("SumpGate", P(108, -26, 62))
	passage({ P(100, -24, 62), P(40, -26, 66), P(-20, -26, 60), P(-70, -24, 50) }, 5, 12, { flat = 0.1 })
	-- the Swallow Hole: a crawl west from camp ends at a 22-stud drop into the lower canyon
	passage({ P(-30, 2, 8), P(-48, 2, 24), P(-66, 0, 40) }, 4.5, 3.2, { flat = 0.9 })
	shaft(P(-70, -24, 48), 5, 28)
	spot("SwallowHole", P(-66, 0, 40))

	-- THE BRANCHES (seeded every hour) --------------------------------------------------------------------------------------
	-- B1 ore pocket: a squeeze west of camp into a small low chamber, with a tube up to the Old Tube's west end
	passage({ P(-34, 2, -4), J(P(-60, 2, -14)), J(P(-84, 3, -22)) }, 3.5, 2.6, { flat = 0.95 })
	local b1 = J(P(-98, 4, -26))
	chamber(b1, 12, 6, 9)
	passage({ b1, J(P(-120, 14, -60)), P(-140, 24, -86) }, 4, 4, { flat = 0.85 })
	spot("B1", b1)
	-- B2 glow pool: rimstone terraces stepping down to a lit pool, off the squeeze
	local b2 = J(P(-92, -4, 18))
	passage({ J(P(-66, 2, -8)), b2 }, 4, 3.5, { flat = 0.9 })
	chamber(b2, 14, 7, 11, { floor = 0.55 })
	spot("B2", b2)
	-- B3 gloom nest: a dead end south of the pool
	local b3 = J(P(-112, -6, 52))
	passage({ b2, b3 }, 4, 4, { flat = 0.85 })
	chamber(b3, 11, 7, 10)
	spot("B3", b3)
	-- B4 mural alcove: a keyhole niche east of the cathedral
	local b4 = J(P(206, 12, -22))
	passage({ P(178, 8, -4), b4 }, 4, 6, { flat = 0.6 })
	chamber(b4, 6, 8, 5)
	spot("B4", b4)
	-- B5 chest: a crawl south of the cathedral
	local b5 = J(P(176, 0, 58))
	passage({ P(152, 2, 24), J(P(164, 2, 42)), b5 }, 3.5, 3, { flat = 0.95 })
	chamber(b5, 8, 5, 7)
	spot("B5", b5)

	-- THEMES per place, for floor colours and for CaveProps (it dresses Floor parts by their Theme attribute)
	local REG = {
		{ spots.Camp, "camp" }, { spots.Canyon, "chasm" }, { P(112, -6, 2), "chasm" }, { spots.Cathedral, "grotto" }, { P(150, 8, 0), "grotto" },
		{ spots.OldTube, "chasm" }, { P(-60, 24, -92), "chasm" }, { P(100, 22, -90), "chasm" }, { spots.SumpGate, "grotto" },
		{ P(40, -26, 66), "chasm" }, { P(-20, -26, 60), "chasm" }, { spots.SwallowHole, "squeeze" }, { P(-60, 2, -14), "squeeze" },
		{ spots.B1, "squeeze" }, { spots.B2, "grotto" }, { spots.B3, "mush" }, { spots.B4, "chasm" }, { spots.B5, "squeeze" }, { P(164, 2, 42), "squeeze" },
	}
	local THEMES = { "camp", "tunnel", "chasm", "grotto", "squeeze", "mush" }
	local TI = {} for i, t in THEMES do TI[t] = i end
	local FLOOR = { -- dark, mid and moss share per theme (the old CaveBuilder's floor tints, a step lighter)
		camp = { Color3.fromRGB(128, 100, 110), Color3.fromRGB(158, 126, 130), 0.1 }, tunnel = { Color3.fromRGB(78, 58, 100), Color3.fromRGB(100, 76, 128), 0.3 },
		chasm = { Color3.fromRGB(72, 56, 104), Color3.fromRGB(96, 76, 134), 0.45 }, grotto = { Color3.fromRGB(62, 68, 116), Color3.fromRGB(84, 96, 146), 0.25 },
		squeeze = { Color3.fromRGB(86, 60, 80), Color3.fromRGB(112, 82, 100), 0.1 }, mush = { Color3.fromRGB(70, 56, 100), Color3.fromRGB(92, 74, 128), 0.55 },
	}
	local function themeAt(wp) -- the nearest place's theme (wp in local studs)
		local best, bd = "tunnel", math.huge
		for _, r in REG do
			local d = (r[1] - wp).Magnitude
			if d < bd then best, bd = r[2], d end
		end
		return best
	end

	-- CRUMPLE: rock next to air is eaten or grown a little by 3D noise, so no wall is a clean curve
	local flip = {}
	for x = 1, NX - 2 do
		for y = 1, NY - 2 do
			for z = 1, NZ - 2 do
				local v = get(x, y, z)
				if v == 0 then
					local airN = (get(x + 1, y, z) == 1 and 1 or 0) + (get(x - 1, y, z) == 1 and 1 or 0) + (get(x, y, z + 1) == 1 and 1 or 0) + (get(x, y, z - 1) == 1 and 1 or 0) + (get(x, y + 1, z) == 1 and 1 or 0)
					if airN >= 2 and math.noise(x * 0.31 + wob, y * 0.31, z * 0.31) > 0.25 and get(x, y - 1, z) ~= 1 then table.insert(flip, { x, y, z, 1 }) end -- eaten (never undercut a floor)
				elseif v == 1 and get(x, y + 1, z) == 0 and get(x, y - 1, z) == 1 and get(x, y - 2, z) == 1 and get(x, y - 3, z) == 1 then
					if math.noise(x * 0.27, y * 0.27 + wob, z * 0.27) > 0.42 then table.insert(flip, { x, y, z, 0 }) end -- a knob hangs from the roof (only where 3+ voxels of room stay under it: a crawl must keep its 2)
				end
			end
		end
	end
	for _, f in flip do set(f[1], f[2], f[3], f[4]) end
	-- SMOOTH: where a walkable floor sits 2 or more voxels under its neighbour's (a ledge a player cannot step), the low side is
	-- raised one voxel, twice over, so passages climb in single steps (which then get ramps). Shafts are kept (narrow on purpose).
	local function floorAt(x, z, nearY)
		for y = math.min(NY - 2, nearY + 3), math.max(1, nearY - 3), -1 do
			if get(x, y, z) == 1 and get(x, y - 1, z) == 0 and get(x, y + 1, z) == 1 then return y end
		end
		return nil
	end
	for _ = 1, 2 do
		local raise = {}
		for x = 1, NX - 2 do
			for z = 1, NZ - 2 do
				for y = 1, NY - 4 do
					if get(x, y, z) == 1 and get(x, y - 1, z) == 0 and get(x, y + 1, z) == 1 and get(x, y + 2, z) == 1 and get(x, y + 3, z) == 1 then
						for _, dd in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
							local f = floorAt(x + dd[1], z + dd[2], y)
							if f and f >= y + 2 then table.insert(raise, { x, y, z }) break end
						end
					end
				end
			end
		end
		for _, r in raise do set(r[1], r[2], r[3], 0) end
	end

	local rootC = P(150, 0, 6) + P(0, dipY(150), 0) -- the cathedral's landmark (built after the mesh: a real trunk, not voxels)

	-- THE SUMP'S WATER fills the chamber's real shape up to one voxel over its lowest floor (Gemini r2: a flat sheet cut off in mid-air)
	local sumpY
	do
		local c = spots.SumpGate
		local vx, vy, vz = toVox(c)
		local lowest = math.huge
		for x = math.floor(vx) - 5, math.ceil(vx) + 5 do
			for z = math.floor(vz) - 4, math.ceil(vz) + 4 do
				for y = math.floor(vy) - 5, math.ceil(vy) + 3 do
					if get(x, y, z) == 1 and get(x, y - 1, z) == 0 then lowest = math.min(lowest, y) end
				end
			end
		end
		if lowest < math.huge then
			sumpY = lowest
			for x = math.floor(vx) - 5, math.ceil(vx) + 5 do
				for z = math.floor(vz) - 4, math.ceil(vz) + 4 do
					if get(x, sumpY, z) == 1 then set(x, sumpY, z, 2) end
				end
			end
		end
	end

	-- REACH: which places a player can walk to from the camp, on the voxels (a standing cell is air on rock with air above;
	-- a step moves one cell sideways and at most one voxel up, or any distance down). Model attributes Reach_<place>.
	local function isAirV(v) return v == 1 or v == 2 end
	local function stand(x, y, z) return get(x, y, z) ~= 0 and get(x, y, z) ~= 2 and get(x, y - 1, z) ~= 1 and get(x, y - 1, z) ~= 2 and isAirV(get(x, y + 1, z)) end
	local reach = {}
	do
		local q, qi = {}, 1
		local function push(x, y, z) local k = idx(x, y, z) if not reach[k] then reach[k] = true table.insert(q, { x, y, z }) end end
		local cx, cy, cz = toVox(spots.Camp)
		local sx, sz = math.floor(cx), math.floor(cz)
		for y = math.floor(cy) + 3, 1, -1 do if stand(sx, y, sz) then push(sx, y, sz) break end end
		while q[qi] do
			local c = q[qi]
			qi += 1
			for _, d in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
				local nx, nz = c[1] + d[1], c[3] + d[2]
				for dy = 1, -6, -1 do -- up one, level, or a drop
					local ny = c[2] + dy
					if stand(nx, ny, nz) and (dy <= 0 or isAirV(get(c[1], c[2] + 2, c[3]))) then
						if dy >= -1 or true then push(nx, ny, nz) end
						break
					end
					if get(nx, ny, nz) == 0 and dy <= 0 then break end -- a wall: no drop through rock
				end
			end
		end
	end
	local function reached(p)
		local vx, vy, vz = toVox(p)
		for r = 0, 2 do
			for x = math.floor(vx) - r, math.floor(vx) + r do
				for z = math.floor(vz) - r, math.floor(vz) + r do
					for y = math.floor(vy) - 4, math.floor(vy) + 2 do if reach[idx(x, y, z)] then return true end end
				end
			end
		end
		return false
	end

	-- MESH: every solid voxel that touches air (26 neighbours) is shell; shell voxels merge into boxes per colour key
	local model = Instance.new("Model")
	model.Name = "CavesV2"
	model:SetAttribute("Seed", seed)
	local folders = {}
	local function group(n)
		if not folders[n] then
			local f = Instance.new("Folder")
			f.Name = n
			f.Parent = model
			folders[n] = f
		end
		return folders[n]
	end
	local VARIANT = nil -- Gemini r1: the blotchy PixelCaveRock tile read as dirty camouflage; plain slate, soft tri-tone colours
	local function part(g, name, size, cf, color, props)
		local p = Instance.new("Part")
		p.Name, p.Anchored, p.Size, p.CFrame, p.Color = name, true, size, cf, color
		p.Material, p.TopSurface, p.BottomSurface = Enum.Material.Slate, Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		if VARIANT then p.MaterialVariant = VARIANT end
		for k, v in props or {} do p[k] = v end
		p.Parent = group(g)
		return p
	end
	local function isAir(v) return v == 1 or v == 2 end
	local key = {} -- colour key per shell voxel; 0 = not shell
	local nShell = 0
	for x = 0, NX - 1 do
		for y = 0, NY - 1 do
			for z = 0, NZ - 1 do
				local v = get(x, y, z)
				if v == 0 or v == 3 then
					local touch = false
					for dx = -1, 1 do for dy = -1, 1 do for dz = -1, 1 do
						if not touch and isAir(get(x + dx, y + dy, z + dz)) then touch = true end
					end end end
					if touch then
						local k
						if v == 3 then k = 9
						elseif sumpY and y == sumpY and get(x, y + 1, z) == 1 and (get(x + 1, y + 1, z) == 2 or get(x - 1, y + 1, z) == 2 or get(x, y + 1, z + 1) == 2 or get(x, y + 1, z - 1) == 2 or get(x + 1, y, z) == 2 or get(x - 1, y, z) == 2 or get(x, y, z + 1) == 2 or get(x, y, z - 1) == 2) then
							k = 99 -- wet mud along the water's edge
						elseif isAir(get(x, y + 1, z)) then -- a floor: its place's tint, dark or mid, with moss in the damp hollows
							local th = themeAt(Vector3.new((x - CX + 0.5) * V, (y - CY + 0.5) * V, (z - CZ + 0.5) * V))
							local f = FLOOR[th]
							local moss = math.noise(x * 0.15, z * 0.15, wob) > 0.5 - f[3]
							k = 100 + TI[th] * 10 + (moss and (2 + math.floor(hash(x, z, 3) * 2)) or math.floor(hash(x, z, 4) * 2))
						else
							k = 1 + math.clamp(math.floor((y / NY) * 2.6 + hash(x, y, z) * 1.4), 0, 3) -- walls lighter the higher they sit (hue-shifted lilac)
						end
						key[idx(x, y, z)] = k
						nShell += 1
					end
				end
			end
		end
	end
	local WALL = { Color3.fromRGB(40, 26, 54), Color3.fromRGB(61, 41, 82), Color3.fromRGB(86, 61, 112), Color3.fromRGB(110, 84, 140) } -- deep amethyst slate to soft lavender granite (Gemini r1 palette, a step lighter at the top)
	local function colorOf(k)
		if k == 99 then return Color3.fromRGB(45, 26, 56) end
		if k < 100 then return WALL[k] end
		local th = THEMES[math.floor((k - 100) / 10)]
		local v = k % 10
		local f = FLOOR[th]
		if v >= 2 then return PAL.moss[v == 2 and 1 or 2] end
		return v == 0 and f[1] or f[2]
	end
	local used = {}
	local nParts = 0
	for y = 0, NY - 1 do
		for x = 0, NX - 1 do
			for z = 0, NZ - 1 do
				local i0 = idx(x, y, z)
				local k = key[i0]
				if k and not used[i0] then
					local w, d, h = 1, 1, 1
					while x + w < NX and key[idx(x + w, y, z)] == k and not used[idx(x + w, y, z)] and w < 8 do w += 1 end
					local ok = true
					while ok and z + d < NZ and d < 8 do
						for i = 0, w - 1 do local q = idx(x + i, y, z + d) if key[q] ~= k or used[q] then ok = false break end end
						if ok then d += 1 end
					end
					ok = true
					while ok and y + h < NY and h < 6 do
						for i = 0, w - 1 do for j = 0, d - 1 do local q = idx(x + i, y + h, z + j) if key[q] ~= k or used[q] then ok = false end end end
						if ok then h += 1 end
					end
					for i = 0, w - 1 do for j = 0, d - 1 do for l = 0, h - 1 do used[idx(x + i, y + l, z + j)] = true end end end
					local c = toWorld(x + (w - 1) / 2, y + (h - 1) / 2, z + (d - 1) / 2)
					local isFloor = k >= 100
					local p = part(isFloor and "Floor" or "Walls", isFloor and "Floor" or "Rock", Vector3.new(w * V, h * V, d * V), CFrame.new(c), colorOf(k))
					if isFloor then
						p:SetAttribute("Theme", THEMES[math.floor((k - 100) / 10)])
						p.Material = Enum.Material.Pebble -- packed grit: the floor reads apart from the smooth slate walls (Ground rendered olive: the owner, 2026-11-17, no green floors)
						p.Color = p.Color:Lerp(Color3.fromRGB(160, 120, 132), 0.35)
					end
					p.CastShadow = h > 1
					nParts += 1
				end
			end
		end
	end

	-- (see SMOOTH below the crumple)
	-- THE WORLD ROOT: one giant root of the World Tree comes down through the cathedral roof and spreads into the floor. A trunk of
	-- stacked cylinders that leans and narrows as it rises, bark rings, and six flaring roots at its foot; mint moss on the bark.
	do
		local vx, _, vz = toVox(rootC)
		local x, z = math.floor(vx), math.floor(vz)
		local foot, top
		for y = 1, NY - 2 do
			if get(x, y, z) == 1 and get(x, y - 1, z) == 0 and not foot then foot = toWorld(x, y, z) - Vector3.new(0, V / 2, 0) end
			if foot and get(x, y, z) == 0 and get(x, y - 1, z) == 1 then top = toWorld(x, y, z) break end
		end
		if foot and top then
			local h = top.Y - foot.Y + 6
			local n = math.max(4, math.floor(h / 6))
			local at = foot
			for sgm = 1, n do -- chunky twisted bark blocks (the game's voxel style), each turned and shifted a little: a root, not a silo
				local u = (sgm - 0.5) / n
				local r = 8.5 - 4 * u
				local seg = h / n + 0.8
				local twist = CFrame.Angles(math.sin(sgm * 0.9 + seed) * 0.12, sgm * 0.45, math.cos(sgm * 0.7) * 0.12)
				local cf = CFrame.new(at) * twist * CFrame.new(0, seg / 2, 0)
				part("Landmark", "WorldRoot", Vector3.new(r * 2, seg, r * 1.7), cf, sgm % 2 == 0 and PAL.bark or PAL.barkDark, { Material = Enum.Material.Wood, MaterialVariant = "" })
				part("Landmark", "WorldRootCrease", Vector3.new(r * 2.04, 0.8, r * 1.74), cf * CFrame.new(0, -seg / 2 + 0.3, 0), Color3.fromRGB(43, 22, 12), { Material = Enum.Material.Wood, MaterialVariant = "", CastShadow = false }) -- a dark crease where blocks meet
				part("Landmark", "WorldRoot", Vector3.new(r * 1.6, seg * 0.9, r * 2.1), cf * CFrame.Angles(0, 0.8, 0), sgm % 2 == 1 and PAL.bark or PAL.barkDark, { Material = Enum.Material.Wood, MaterialVariant = "" })
				if hash(sgm, seed, 3) > 0.35 then -- a cushion of glowing moss in a crease of the bark
					part("Landmark", "RootMoss", Vector3.new(2.2, 1.4, 1.2), cf * CFrame.new(r * 0.85, seg * (hash(sgm, 1, 2) - 0.5) * 0.6, 0) * CFrame.Angles(0, 0, 0.3), PAL.mint, { Material = Enum.Material.Neon, MaterialVariant = "", CanCollide = false, CastShadow = false })
				end
				at = (cf * CFrame.new(0, seg / 2 - 0.4, 0)).Position
			end
			for k = 1, 6 do -- the flare: thick roots running out and down into the floor
				local a = k / 6 * math.pi * 2 + seed
				local dir = Vector3.new(math.cos(a), 0, math.sin(a))
				local base = foot + dir * 7 + Vector3.new(0, 3, 0)
				local tip = foot + dir * 20 + Vector3.new(0, -1.5, 0)
				local mid = (base + tip) / 2
				local len = (tip - base).Magnitude + 3
				local fl = Instance.new("WedgePart") -- a tapered flare: thick at the trunk, thinning to the floor
				fl.Name, fl.Anchored, fl.Size, fl.Color, fl.Material = "WorldRootFlare", true, Vector3.new(5, 6, len), PAL.barkDark, Enum.Material.Wood
				fl.CFrame = CFrame.lookAt(mid, tip) * CFrame.new(0, 1, 0)
				fl.Parent = group("Landmark")
				for q = 1, 2 do -- thin strands draping from the knee
					local sl = 3 + hash(k, q, 9) * 5
					part("Landmark", "RootStrand", Vector3.new(0.5, sl, 0.5), CFrame.new(base + dir * (2 + q * 2) + Vector3.new((hash(q, k, 1) - 0.5), 4 - sl / 2, 0)) * CFrame.Angles(0, 0, (hash(k, q, 2) - 0.5) * 0.4), PAL.bark, { Material = Enum.Material.Wood, MaterialVariant = "", CanCollide = false, CastShadow = false })
				end
			end
			local glowP = part("Landmark", "RootGlow", Vector3.new(1, 1, 1), CFrame.new(foot + Vector3.new(0, 10, 0)), PAL.mint, { Transparency = 1, CanCollide = false, CanQuery = false })
			local l = Instance.new("PointLight")
			l.Color, l.Range, l.Brightness, l.Shadows = PAL.mint, 40, 0.8, false
			l.Parent = glowP
		end
	end

	-- RAMPS: a floor one voxel higher next door gets a wedge, so a step is a slope you walk, not a ledge you jump
	local nRamp = 0
	local DIRS = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }
	for x = 1, NX - 2 do
		for y = 1, NY - 3 do
			for z = 1, NZ - 2 do
				if get(x, y, z) == 1 and get(x, y - 1, z) == 0 and get(x, y + 1, z) == 1 then
					for _, dd in DIRS do
						local nx, nz = x + dd[1], z + dd[2]
						if get(nx, y, nz) == 0 and isAir(get(nx, y + 1, nz)) and isAir(get(nx, y + 2, nz)) then -- every one-voxel step, also in one-wide crawls (walk test 2026-11-19)
							local c = toWorld(x, y, z)
							local look = Vector3.new(-dd[1], 0, -dd[2]) -- a WedgePart rises toward its -Z: face it away from the step
							local w = Instance.new("WedgePart")
							w.Name, w.Anchored, w.Size = "Ramp", true, Vector3.new(V, V, V)
							w.CFrame = CFrame.lookAt(c, c + look)
							w.Color, w.Material = PAL.moss[1]:Lerp(PAL.rock[2], 0.5), Enum.Material.Slate
							if VARIANT then w.MaterialVariant = VARIANT end
							w.Parent = group("Ramps")
							nRamp += 1
							break
						end
					end
				end
			end
		end
	end

	-- DECOR: stalactites from roofs with headroom, stalagmites and boulders on floors, columns where roof and floor nearly meet,
	-- hanging roots, glowing moss on the roof, rimstone rims and water in the pool
	local nDecor = 0
	local function deco(...) nDecor += 1 return part("Decor", ...) end
	local NOCOL = { CanCollide = false, CanQuery = false, CastShadow = false }
	for x = 1, NX - 2 do
		for z = 1, NZ - 2 do
			for y = 1, NY - 2 do
				local v = get(x, y, z)
				if v == 1 and get(x, y + 1, z) == 0 then -- a roof voxel above open air
					local room = 0
					while room < 8 and get(x, y - room, z) == 1 do room += 1 end
					local hsh = hash(x, z, y)
					local top = toWorld(x, y, z) + Vector3.new(0, V / 2, 0)
					if room >= 4 and hsh > 0.86 then -- a dripstone, one of three kinds (Gemini r2: every stalactite was the same two-tier block)
						local kind = math.floor(hash(x, z, 51) * 3)
						local len = 2 + hash(z, x, 5) * 5
						local col = PAL.rock[2]:Lerp(PAL.flow, hash(x, z, 52) * 0.4)
						local turn = CFrame.Angles(0, hash(x, z, 53) * 3, 0)
						if kind == 0 then -- a wide cone: three shrinking blocks, no tip colour
							for t = 0, 2 do
								local w2 = 2.8 - t * 0.85
								deco("Stalactite", Vector3.new(w2, len / 3 + 0.3, w2), CFrame.new(top - Vector3.new(0, len / 6 + t * len / 3, 0)) * turn, col, NOCOL)
							end
						elseif kind == 1 then -- twins of different lengths
							for t = 0, 1 do
								local l2 = len * (t == 0 and 1 or 0.6)
								deco("Stalactite", Vector3.new(1.4, l2, 1.4), CFrame.new(top + Vector3.new(t * 1.6 - 0.8, -l2 / 2, (t - 0.5) * 0.8)) * turn, col, NOCOL)
								deco("Stalactite", Vector3.new(0.7, 1, 0.7), CFrame.new(top + Vector3.new(t * 1.6 - 0.8, -l2 - 0.5, (t - 0.5) * 0.8)), PAL.flow, NOCOL)
							end
						else -- a single slender spike
							deco("Stalactite", Vector3.new(1.2, len, 1.2), CFrame.new(top - Vector3.new(0, len / 2, 0)) * turn, col, NOCOL)
							deco("Stalactite", Vector3.new(0.5, 1.4, 0.5), CFrame.new(top - Vector3.new(0, len + 0.7, 0)), PAL.flow, NOCOL)
						end
					elseif room >= 3 and hsh > 0.8 then -- soda straws: thin pale tubes in a cluster
						for s = 1, 3 do
							local l = 0.8 + hash(x + s, z, 6) * 2.2
							deco("Straw", Vector3.new(0.25, l, 0.25), CFrame.new(top + Vector3.new((hash(s, x, z) - 0.5) * 3, -l / 2, (hash(z, s, x) - 0.5) * 3)), PAL.flow, NOCOL)
						end
					elseif room >= 4 and hsh > 0.74 and hsh < 0.78 then -- glowing moss cushion
						local m = deco("CeilMoss", Vector3.new(2.4, 0.5, 2), CFrame.new(top - Vector3.new(0, 0.2, 0)), PAL.mint, { Material = Enum.Material.Neon, CanCollide = false, CanQuery = false, CastShadow = false })
						for q = 1, 3 do -- an irregular patch pressed to the rock, with a thin drip hanging from it
							local a = q * 2.1 + hsh * 6
							deco("CeilMoss", Vector3.new(1 + q * 0.3, 0.3, 0.9 + q * 0.2), CFrame.new(top + Vector3.new(math.cos(a) * 1.6, -0.15, math.sin(a) * 1.6)), PAL.mint:Lerp(PAL.moss[3], 0.4), { Material = Enum.Material.Neon, CanCollide = false, CanQuery = false, CastShadow = false })
						end
						deco("CeilMossDrip", Vector3.new(0.2, 1.2, 0.2), CFrame.new(top + Vector3.new(0.5, -0.8, 0.3)), PAL.mint, { Material = Enum.Material.Neon, CanCollide = false, CanQuery = false, CastShadow = false })
						if hash(z, x, 9) > 0.6 then
							local l = Instance.new("PointLight")
							l.Color, l.Range, l.Brightness, l.Shadows = PAL.mint, 18, 0.9, false
							l.Parent = m
						end
					elseif room >= 5 and hsh > 0.7 and hsh < 0.74 and (x - CX) * V < 60 then -- a hanging root (layer 1: the tree is above)
						local at = top
						local thick = 1.4
						for sgm = 1, 4 do
							local len = 2 + hash(x, sgm, z) * 1.6
							local cf = CFrame.new(at) * CFrame.Angles((hash(sgm, z, x) - 0.5) * 0.7, sgm, 0)
							deco("HangRoot", Vector3.new(thick, len, thick), cf * CFrame.new(0, -len / 2, 0), sgm % 2 == 0 and PAL.bark or PAL.barkDark, { Material = Enum.Material.Wood, MaterialVariant = "", CanCollide = false, CanQuery = false, CastShadow = false })
							at = (cf * CFrame.new(0, -len, 0)).Position
							thick *= 0.75
						end
					end
				elseif v == 1 and get(x, y - 1, z) == 0 then -- a floor voxel
					local hsh = hash(z, x, y + 11)
					local foot = toWorld(x, y, z) - Vector3.new(0, V / 2, 0)
					local head = 0
					while head < 8 and get(x, y + head, z) == 1 do head += 1 end
					local roomy = get(x + 2, y, z) == 1 and get(x - 2, y, z) == 1 and get(x, y, z + 2) == 1 and get(x, y, z - 2) == 1
					if head <= 3 and hsh > 0.93 and roomy then -- a column: floor to roof where they nearly meet, only in an open room (never plugging a crawl)
						deco("Column", Vector3.new(3, head * V, 3), CFrame.new(foot + Vector3.new(0, head * V / 2, 0)), PAL.rock[3], { CastShadow = true })
						deco("ColumnFoot", Vector3.new(4.4, 1.2, 4.4), CFrame.new(foot + Vector3.new(0, 0.6, 0)), PAL.flow:Lerp(PAL.rock[2], 0.5), {})
					elseif head >= 3 and hsh > 0.9 then -- a stalagmite under the drip
						local hgt = 1.6 + hash(x, z, 12) * 3.4
						deco("Stalagmite", Vector3.new(2.4, hgt, 2.4), CFrame.new(foot + Vector3.new(0, hgt / 2, 0)), PAL.rock[2], { CanCollide = roomy, CanQuery = roomy })
						deco("Stalagmite", Vector3.new(1.2, 1.4, 1.2), CFrame.new(foot + Vector3.new(0, hgt + 0.7, 0)), PAL.flow, { CanCollide = false })
					elseif head >= 2 and hsh > 0.8 and hsh < 0.815 then -- lichen flecks low on the rock: faint teal light so no stretch is a dead zone (Gemini r3)
						local lf = deco("Lichen", Vector3.new(1.4, 0.25, 1), CFrame.new(foot + Vector3.new(0, 0.12, 0)) * CFrame.Angles(0, hsh * 20, 0), Color3.fromRGB(94, 234, 212), { Material = Enum.Material.Neon, MaterialVariant = "", CanCollide = false, CanQuery = false, CastShadow = false })
						local ll = Instance.new("PointLight")
						ll.Color, ll.Range, ll.Brightness, ll.Shadows = Color3.fromRGB(94, 234, 212), 8, 0.35, false
						ll.Parent = lf
					elseif head >= 2 and hsh > 0.84 then -- a fallen boulder (breakdown), tilted
						local s = 2 + hash(x, z, 13) * 2.6
						deco("Boulder", Vector3.new(s, s * 0.7, s * 0.9), CFrame.new(foot + Vector3.new(0, s * 0.3, 0)) * CFrame.Angles(hash(x, z, 14) * 0.6, hash(z, x, 15) * 3, 0), PAL.rock[3], { CanCollide = roomy, CanQuery = roomy })
					end
				end
			end
		end
	end
	-- water: the stream slot and the pools carry a sheet of glassy water on top
	local nWater = 0
	for x = 0, NX - 1 do
		for z = 0, NZ - 1 do
			for y = 0, NY - 2 do
				if get(x, y, z) == 2 and get(x, y + 1, z) ~= 2 then
					local w = part("Water", "Water", Vector3.new(V, 0.6, V), CFrame.new(toWorld(x, y, z) + Vector3.new(0, V / 2 - 1.2, 0)), PAL.water, { Material = Enum.Material.Glass, MaterialVariant = "", Transparency = 0.35, CanCollide = false, CastShadow = false })
					nWater += 1
					w.Reflectance = 0.1
				end
			end
		end
	end
	-- LIGHT: warm lanterns along the main route only (the branches stay dark: your torch), the camp fire, a cool shaft of light on the root
	local function lantern(p, color, range, b)
		local post = part("Lights", "LanternPost", Vector3.new(0.6, 5, 0.6), CFrame.new(p + Vector3.new(0, 2.5, 0)), PAL.barkDark, { Material = Enum.Material.Wood, MaterialVariant = "" })
		local lamp = part("Lights", "Lantern", Vector3.new(1.2, 1.4, 1.2), CFrame.new(p + Vector3.new(0, 5.4, 0)), color, { Material = Enum.Material.Neon, MaterialVariant = "", CanCollide = false })
		local l = Instance.new("PointLight")
		l.Color, l.Range, l.Brightness, l.Shadows = color, range, b or 0.45, true
		l.Parent = lamp
		return post
	end
	local function floorUnder(p) -- the walk height under a local point (studs, local frame)
		local vx, vy, vz = toVox(p + Vector3.new(0, dipY(p.X), 0))
		local x, z = math.floor(vx), math.floor(vz)
		for y = math.floor(vy) + 2, 0, -1 do
			if get(x, y, z) == 1 and get(x, y - 1, z) == 0 then return toWorld(x, y, z) - Vector3.new(0, V / 2, 0) end
		end
		return nil
	end
	for _, p in { P(-20, 6, -6), P(20, 6, 6), P(52, 0, 10), P(100, -4, 4), P(120, 4, -12), P(60, 22, -88), P(-60, 24, -92), P(130, -10, 44) } do
		local at = floorUnder(p)
		if at then lantern(at, PAL.warm, 34, 0.42) end
	end
	do
		local fire = floorUnder(P(0, 6, 0))
		if fire then
			local f = part("Lights", "CampFire", Vector3.new(3, 1.2, 3), CFrame.new(fire + Vector3.new(0, 0.6, 0)), Color3.fromRGB(255, 150, 70), { Material = Enum.Material.Neon, MaterialVariant = "" })
			local l = Instance.new("PointLight")
			l.Color, l.Range, l.Brightness, l.Shadows = PAL.warm, 44, 0.6, true
			l.Parent = f
		end
		local cool = part("Lights", "RootShaft", Vector3.new(1, 1, 1), CFrame.new(origin + rootC + Vector3.new(0, 30, 0)), PAL.mint, { Transparency = 1, CanCollide = false })
		local sl = Instance.new("SpotLight")
		sl.Color, sl.Range, sl.Brightness, sl.Angle, sl.Face, sl.Shadows = Color3.fromRGB(160, 230, 255), 50, 1.4, 50, Enum.NormalId.Bottom, true
		sl.Parent = cool
	end
	do -- the sump: a pool of still water over its low floor (Gemini r1: it did not read as flooded)
		local f = floorUnder(spots.SumpGate - Vector3.new(0, dipY(spots.SumpGate.X), 0))
		if f then
			local w = { CFrame = CFrame.new(f + Vector3.new(0, 2.6, 0)) } -- the water itself is voxels now; this is only where the pads float
			for k = 1, 3 do
				local pad = part("Water", "LilyGlow", Vector3.new(2.4, 0.2, 2.4), w.CFrame * CFrame.new((k - 2) * 6, 0.3, (hash(k, 3, 1) - 0.5) * 8), PAL.mint, { Material = Enum.Material.Neon, MaterialVariant = "", Shape = Enum.PartType.Cylinder, CanCollide = false })
				pad.CFrame = pad.CFrame * CFrame.Angles(0, 0, math.pi / 2)
			end
		end
		-- the Swallow Hole: amber spore lights every 14 studs down its wall and a ring of narrow ledges spiralling down
		local top = spots.SwallowHole + Vector3.new(-4, 0, 8)
		for k = 0, 3 do
			local a = k * 1.6
			local at = origin + top + Vector3.new(math.cos(a) * 4.2, -4 - k * 7, math.sin(a) * 4.2)
			part("Decor", "ShaftLedge", Vector3.new(3.4, 0.8, 3), CFrame.new(at) * CFrame.Angles(0, -a, 0), WALL[3], {})
			if k % 2 == 0 then
				local s2 = part("Decor", "SporeGlow", Vector3.new(0.9, 0.9, 0.9), CFrame.new(at + Vector3.new(0, 2, 0)), Color3.fromRGB(255, 186, 90), { Material = Enum.Material.Neon, MaterialVariant = "", CanCollide = false })
				local l = Instance.new("PointLight")
				l.Color, l.Range, l.Brightness, l.Shadows = Color3.fromRGB(255, 186, 90), 16, 0.7, false
				l.Parent = s2
			end
		end
	end
	for name, p in spots do -- markers for tests and later systems (camp ring, shrines, deposits)
		local a = Instance.new("Attachment")
		a.Name = "Spot_" .. name
		a.Parent = workspace.Terrain
		a.WorldPosition = (floorUnder(p - Vector3.new(0, dipY(p.X), 0)) or (origin + p)) + Vector3.new(0, 3, 0)
		a:SetAttribute("CaveV2", true)
		local tag = Instance.new("ObjectValue")
		tag.Name, tag.Value = a.Name, a
		tag.Parent = model
	end
	-- ORE DEPOSITS (plan section 5): base ore lines the main route's walls, mid ore sits in the branch rooms, rare ore only at the dead
	-- ends (B1, B3, B4, B5) and in the cathedral's cracks. Each stands on a reachable floor cell against a wall, 14 studs apart, with
	-- the attributes the rest of the game reads (Layer, Ore, OreName) and the same shard-and-core look as CaveBuilder's.
	local C = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))
	local ORES = C.LAYERS[1][4]
	local DEAD = { spots.B1, spots.B3, spots.B4, spots.B5 }
	local BRANCH = { spots.B2, spots.SwallowHole, spots.OldTube }
	local cands = {}
	for k in reach do
		local z = k % NZ
		local y = math.floor(k / NZ) % NY
		local x = math.floor(k / (NZ * NY))
		for _, d in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
			if get(x + d[1], y, z + d[2]) == 0 and get(x + d[1], y + 1, z + d[2]) == 0 then table.insert(cands, { x, y, z, d }) break end
		end
	end
	local function rank(c) -- dead ends first, then branches, then the rest; shuffled within each by a hash
		local lp = toWorld(c[1], c[2], c[3]) - origin
		for _, d in DEAD do if (d - lp).Magnitude < 20 then return 0 end end
		for _, b in BRANCH do if (b - lp).Magnitude < 24 then return 1 end end
		return 2
	end
	for _, c in cands do c.r = rank(c) + hash(c[1], c[3], c[2]) end
	table.sort(cands, function(a2, b2) return a2.r < b2.r end)
	local placed, nDep = {}, 0
	local CAP, have = { 22, 9, 5 }, { 0, 0, 0 } -- base, mid, rare: rare stays rare
	local campW = origin + spots.Camp
	for _, c in cands do
		if nDep >= 36 then break end
		local w = toWorld(c[1], c[2], c[3]) - Vector3.new(0, V / 2, 0)
		local lp = w - origin
		if (w - campW).Magnitude > 40 then
			local free = true
			for _, q in placed do if (q - w).Magnitude < 10 then free = false break end end
			if free then
				local idx2 = 1
				for _, d in DEAD do if (d - lp).Magnitude < 20 then idx2 = 3 end end
				if idx2 == 1 then for _, b in BRANCH do if (b - lp).Magnitude < 24 then idx2 = 2 end end end
				if idx2 == 1 and (spots.Cathedral - lp).Magnitude < 30 and hash(c[1], c[3], 77) > 0.6 then idx2 = 3 end -- a crack in the cathedral
				if have[idx2] >= CAP[idx2] then continue end
				have[idx2] += 1
				table.insert(placed, w)
				nDep += 1
				local ore = ORES[idx2]
				local dep = Instance.new("Model")
				dep.Name = "Deposit"
				dep:SetAttribute("Layer", 1)
				dep:SetAttribute("Ore", idx2)
				dep:SetAttribute("OreName", ore[1])
				local wall = Vector3.new(c[4][1], 0, c[4][2])
				local foot = w + wall * (V / 2 - 0.9)
				local base = CFrame.lookAt(foot, foot + wall)
				local k = 0.85 + idx2 * 0.3
				local dark = ore[2]:Lerp(Color3.new(0, 0, 0), 0.35)
				local function shard(size, cf, col, props)
					local sp = part("Deposits", "Shard", size * k, cf, col, props)
					sp.Parent = dep
					return sp
				end
				shard(Vector3.new(2.2, 0.8, 1.6), base * CFrame.new(0, 0.3 * k, 0), WALL[3], { CastShadow = false })
				local core = shard(Vector3.new(0.9, 1.9, 0.9), base * CFrame.new(0, 1.15 * k, -0.1) * CFrame.Angles(0.15, 0, 0.1), ore[2]:Lerp(Color3.new(0, 0, 0), 0.28 - idx2 * 0.08), { Material = Enum.Material.Neon, MaterialVariant = "", CastShadow = false })
				core.Name = "Core"
				for sI = 1, 1 + idx2 do -- shards lean out from the wall, tallest in the middle
					local a = (sI / (1 + idx2) - 0.5) * 2.4
					local h = 1 + hash(c[1], c[3], sI + 40) * 1.1
					shard(Vector3.new(0.7, h, 0.7), base * CFrame.new(math.sin(a) * 0.8, h * 0.45 * k, math.cos(a) * 0.3 - 0.4) * CFrame.Angles(0.35, 0, -a * 0.4), dark:Lerp(ore[2], hash(c[1], sI, 41) * 0.6), { CastShadow = false })
				end
				local l = Instance.new("PointLight") -- a faint glint in the ore's colour: a vein reads in the dark from about 30 studs
				l.Name, l.Color, l.Range, l.Brightness, l.Shadows = "Glint", ore[2], 9, 0.6, false
				l.Parent = core
				dep.PrimaryPart = core
				dep.Parent = group("Deposits")
			end
		end
	end
	model:SetAttribute("Deposits", nDep)
	local nReach = 0
	for name, p in spots do
		local r = reached(p)
		model:SetAttribute("Reach_" .. name, r)
		if r then nReach += 1 end
	end
	model:SetAttribute("Reached", nReach)
	model:SetAttribute("Shell", nShell)
	model:SetAttribute("Parts", nParts + nRamp + nDecor + nWater)
	model:SetAttribute("Ramps", nRamp)
	model:SetAttribute("Decor", nDecor)
	model.Parent = parent
	model:SetAttribute("ZFixed", require(game:GetService("ServerScriptService"):WaitForChild("ZFix")).fix(model)) -- no z-fighting (the user, 2026-11-08)
	return model
end

return M
