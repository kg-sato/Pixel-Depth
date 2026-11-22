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

function M.build(parent, origin, seed, opt)
	opt = opt or {}
	seed = seed or 1
	local L = opt.layer or 1 -- 1 Rootholm, 2 Titan's Rest 3 Glitterhall, 4 Muspell (plan section 3)
	local GLOW = ({ PAL.mint, Color3.fromRGB(64, 210, 196), Color3.fromRGB(140, 190, 255), Color3.fromRGB(255, 140, 60) })[L] -- each layer's own glow: mint moss, teal glass, ice crystal, ember
	local rng = Random.new(seed)
	local NX, NY, NZ = 100, 34, 72 -- 400 x 136 x 288 studs
	local CX, CY, CZ = 30, 14, 30 -- voxel of the local origin (camp floor centre)
	local grid = buffer.create(NX * NY * NZ) -- 0 rock, 1 air, 2 water, 3 bark (the root column)
	local function idx(x, y, z) return (x * NY + y) * NZ + z end
	local function inside(x, y, z) return x >= 0 and y >= 0 and z >= 0 and x < NX and y < NY and z < NZ end
	local function get(x, y, z) if not inside(x, y, z) then return 0 end return buffer.readu8(grid, idx(x, y, z)) end
	local function set(x, y, z, v) -- the outermost voxels of the grid stay rock: a passage carved to the edge opened a hole to the sky (Gemini, 2026-11-19)
		if inside(x, y, z) and (v == 0 or (x > 0 and y > 0 and z > 0 and x < NX - 1 and y < NY - 1 and z < NZ - 1)) then buffer.writeu8(grid, idx(x, y, z), v) end
	end
	local function toWorld(x, y, z) return origin + Vector3.new((x - CX + 0.5) * V, (y - CY + 0.5) * V, (z - CZ + 0.5) * V) end
	local function toVox(p) -- local studs (x east, y up, z south) -> voxel coordinates (fractional)
		return p.X / V + CX, p.Y / V + CY, p.Z / V + CZ
	end
	local function dipY(xStuds) return -xStuds * math.tan(DIP) end
	local wob = seed * 0.37
	local function inCamp(x, z) -- the live camp's footprint (CaveBuilder's props stand there on a flat floor): no crumple, no rubble
		if not opt.camp then return false end
		local lx, lz = (x - CX + 0.5) * V, (z - CZ + 0.5) * V
		return (lx / 56) ^ 2 + (lz / 52) ^ 2 <= 1 or (lx < -36 and lx > -64 and lz > 4 and lz < 24)
	end

	-- carve a passage along a path of local points: an oval cross-section rx (half width) by ry (half height) round the axis,
	-- its bottom cut flat at floorK of ry under the axis so the floor walks; radii breathe along the length with noise
	local trench = {} -- keyhole slot cells (directive v14): their side ramps are thinned so the slot reads crisp
	local function passage(pts, rx, ry, opt)
		opt = opt or {}
		if (opt.fill or 1) == 1 then -- walkable: at least two voxels of headroom over the flat floor and room to turn (path test, 2026-11-19: crawls one voxel high blocked every branch)
			rx, ry = math.max(rx, 4.2), math.max(ry, 5)
			opt.flat = math.min(opt.flat or 0.55, 0.6)
		end
		local floorK = opt.flat or 0.55
		local fill = opt.fill or 1
		-- directive v14 (Recipe A): a wide walkable tube gets a keyhole: a narrower meandering slot one voxel deep down its floor,
		-- with a rock bench left on each side, and a roof cut flat along the bedding plane (a phreatic tube over a vadose trench)
		local kh = opt.keyhole ~= false and fill == 1 and rx >= 6 and floorK >= 0.3
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
							elseif kh and d < -ryi * floorK and d >= -ryi * floorK - V * 1.05 and math.abs(h - math.sin((p.X + p.Z) * 0.045 + wob) * rxi * 0.22) <= math.max(4.6, rxi * 0.42) and not inCamp(x, z) then
								if get(x, y, z) == 0 then set(x, y, z, fill) trench[idx(x, y, z)] = true end -- the slot: at least 9 studs wide, one voxel under the benches
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
	local function noodle(a, b, amp, k) -- directive v14 (Minecraft 1.18 noodle caves): a wandering flank loop, never under 2 voxels wide or high
		local pts, dir = { a }, (b - a).Unit
		local side = Vector3.new(-dir.Z, 0, dir.X).Unit
		for i = 1, 5 do
			local u = i / 6
			table.insert(pts, a:Lerp(b, u) + side * math.sin(u * math.pi) * amp * (0.7 + 0.6 * math.noise(u * 3, k, wob)) + Vector3.new(0, math.noise(u * 2.3, k * 1.7, wob) * 3, 0))
		end
		table.insert(pts, b)
		passage(pts, 4.4, 5, { flat = 0.8, keyhole = false })
	end
	local function dome(c, ry, r) -- directive v14 (Recipe A3): a corbelled breakdown vault over a chamber: slabs two voxels high, each a voxel narrower
		c = c + Vector3.new(0, dipY(c.X), 0)
		local vx, vy, vz = toVox(c + Vector3.new(0, ry * 0.35, 0))
		for s = 0, 6 do
			local rr = r - s * V
			if rr < V * 1.6 then break end
			local sk = Vector3.new(s * V * 0.6, 0, s * V * 0.35) -- each tier steps off along a fault, not round one centre (Gemini v14p2: a ziggurat)
			for x = math.floor(vx - rr / V) - 1, math.ceil(vx + rr / V) + 1 + s do
				for z = math.floor(vz - rr / V) - 1, math.ceil(vz + rr / V) + 1 + s do
					local wx, wz = (x - CX + 0.5) * V - c.X - sk.X, (z - CZ + 0.5) * V - c.Z - sk.Z
					if math.sqrt(wx * wx + wz * wz) <= rr * (1 + 0.18 * math.noise(math.atan2(wz, wx) * 2, s + 0.5, wob)) then
						for y = math.floor(vy) + s * 2, math.floor(vy) + s * 2 + 1 do if get(x, y, z) == 0 then set(x, y, z, 1) end end
					end
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
	if opt.hall then
		-- the live layer 2 (C.CAVE_V2_L2): ClayCaves builds its closed hall (x -80..80, z -60..60, y 0..76) with doors at x = +-80, z 0.
		-- v2 keeps that box as rock (cleared again after carving, below) and runs a gallery out of each door.
		passage({ P(-80, 4, 0), P(-100, 4, 6), P(-110, 4, 20) }, 5, 5, { flat = 0.8 })
		passage({ P(80, 4, 0), P(100, 4, -4), P(116, 2, 0) }, 5, 5, { flat = 0.8 })
		spots.Camp = P(-100, 1, 6)
		spots.HallEast = P(100, 1, -4) -- the hall itself is walkable in the game: the reach flood starts from both of its doors
	elseif opt.camp then
		-- the live game: CaveBuilder builds the camp's props and systems (fire, Wick, tents, stall, rail station, the Deep Gate and
		-- the Root Warden, the safe ring) on a flat floor at the origin; v2 gives them a room that fits: a wide low chamber about
		-- 100 x 92 studs, floor exactly at y 0 (the dip is not applied here), a lumpy roof 22 to 30 high, and the Deep Gate alcove
		for x = CX - 13, CX + 13 do
			for z = CZ - 12, CZ + 12 do
				local lx, lz = (x - CX + 0.5) * V, (z - CZ + 0.5) * V
				local a = math.atan2(lz, lx)
				local r = math.sqrt((lx / 50) ^ 2 + (lz / 46) ^ 2)
				if r <= 1 + 0.08 * math.noise(a * 1.7, wob, 3.1) then
					local roof = 22 + 8 * (1 - r * r) + 3 * math.noise(lx * 0.07, lz * 0.07, wob)
					for y = CY, CY + math.floor(roof / V) do set(x, y, z, 1) end
				end
			end
		end
		for x = CX - 15, CX - 10 do for z = CZ + 2, CZ + 4 do for y = CY, CY + 2 do set(x, y, z, 1) end end end -- the Deep Gate alcove behind the west wall
		spots.Camp = P(0, 1, 0)
	else
		if L == 2 then -- the Kiln hall: wide and low, a kiln's warmth under a clay roof
			chamber(P(0, 8, 0), 40, 14, 32, { floor = 0.5 })
		else
			passage({ P(-34, 6, 0), P(-10, 6, -2), P(12, 6, 1), P(34, 6, 0) }, 13, 8, { flat = 0.75 })
		end
		shaft(P(0, 10, 4), 5, 34)
		spot("Camp", P(0, 1, 0))
	end
	if L == 1 then
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
	local b1 = J(P(-98, 4, -26)) -- the chamber first: the squeeze then ends exactly in it (seed 11 left B1 sealed off)
	passage({ P(-34, 2, -4), J(P(-60, 2, -14)), J(P(-84, 3, -22)), b1 }, 3.5, 2.6, { flat = 0.95 })
	
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

	elseif L == 4 then
	-- LAYER 4, MUSPELL (plan sections 3 to 6): lava tubes. Smooth round tubes left when molten rock drained, with "lava shelves"
	-- (ledges along the walls where the flow paused), the Magma Hall over a glowing lake far below, basalt columns, a cooled upper
	-- tube, an ash pool, a lower tube and a vent drop. Light comes from below: the lake, the cracks, the vents.
	local tube = { P(34, 4, 0), P(62, 2, -8), P(90, 0, 6), P(116, -2, 0) }
	passage(tube, 8, 8, { flat = 0.55 }) -- round, not wide: a lava tube
	local shelf = {} for i2, q in tube do shelf[i2] = q + P(0, 4, 6) end
	passage(shelf, 4, 2.5, { flat = 0.9 }) -- the lava shelf along the south wall
	spot("Canyon", P(90, 0, 6))
	chamber(P(152, 10, 0), 40, 24, 30, { floor = 0.3, slope = 0.0 }) -- the Magma Hall
	spot("Cathedral", P(130, 0, 6))
	passage({ P(-130, 22, -84), P(-40, 20, -88), P(40, 20, -86), P(120, 18, -82), P(152, 18, -74) }, 8, 7, { flat = 0.6 })
	passage({ P(22, 6, -12), P(30, 12, -48), P(28, 20, -84) }, 5, 5, { flat = 0.8 })
	passage({ P(152, 18, -74), P(152, 16, -44), P(150, 14, -24) }, 6, 6, { flat = 0.8 })
	spot("OldTube", P(40, 20, -86))
	passage({ P(152, 0, 22), P(134, -10, 42), P(116, -22, 58) }, 6, 6, { flat = 0.8 })
	chamber(P(108, -22, 62), 16, 9, 12, { floor = 0.5 })
	spot("SumpGate", P(108, -26, 62))
	passage({ P(100, -24, 62), P(40, -26, 66), P(-20, -26, 60), P(-68, -24, 50) }, 7, 7, { flat = 0.55 })
	passage({ P(-30, 2, 8), P(-48, 2, 24), P(-64, 0, 40) }, 5, 5, { flat = 0.8 })
	shaft(P(-68, -24, 46), 5, 28) -- the vent drop
	spot("SwallowHole", P(-64, 0, 40))
	local b1 = J(P(-98, 4, -26)) -- the chamber first: the squeeze then ends exactly in it (seed 11 left B1 sealed off)
	passage({ P(-34, 2, -4), J(P(-60, 2, -14)), J(P(-84, 3, -22)), b1 }, 5, 5, { flat = 0.6 })
	 chamber(b1, 12, 7, 9) passage({ b1, J(P(-120, 14, -60)), P(-130, 22, -84) }, 5, 5, { flat = 0.7 }) spot("B1", b1)
	local b2 = J(P(-92, -4, 18)) passage({ J(P(-66, 2, -8)), b2 }, 5, 5, { flat = 0.7 }) chamber(b2, 13, 8, 11, { floor = 0.5 }) spot("B2", b2)
	local b3 = J(P(-112, -6, 52)) passage({ b2, b3 }, 5, 5, { flat = 0.7 }) chamber(b3, 11, 8, 10) spot("B3", b3)
	local b4 = J(P(200, 12, -22)) passage({ P(176, 10, -4), b4 }, 5, 6, { flat = 0.6 }) chamber(b4, 7, 9, 6) spot("B4", b4)
	local b5 = J(P(176, 0, 58)) passage({ P(152, 2, 24), J(P(164, 2, 42)), b5 }, 5, 5, { flat = 0.7 }) chamber(b5, 8, 6, 7) spot("B5", b5)
	elseif L == 3 then
	-- LAYER 3, GLITTERHALL (plan sections 3 to 6): keyhole galleries (a round tube with a slot cut down its floor) lined with geodes,
	-- the Crystal Cathedral (tall, narrow, high: crystal columns from floor to roof), a cold upper tube, a geode pool, a lower slot
	-- and a crystal chimney drop. Very dark: the only lamps are at camp; the crystals light the way.
	local kh = { P(34, 6, 0), P(58, 4, -10), P(84, 2, 8), P(112, 0, 0) }
	passage(kh, 7, 6, { flat = 0.7 }) -- the keyhole's tube
	local khs = {} for i2, q in kh do khs[i2] = q - P(0, 7, 0) end
	passage(khs, 2.6, 6, { flat = 0.2 }) -- and the slot cut down its floor
	spot("Canyon", P(84, 2, 8))
	chamber(P(150, 14, 0), 30, 32, 26, { floor = 0.38, slope = 0.05 }) -- the Crystal Cathedral: tall rather than wide
	spot("Cathedral", P(136, 0, 6))
	passage({ P(-130, 24, -84), P(-40, 22, -88), P(40, 22, -86), P(120, 20, -82), P(150, 20, -74) }, 8, 5, { flat = 0.75 })
	passage({ P(22, 6, -12), P(30, 12, -48), P(28, 22, -84) }, 5, 5, { flat = 0.8 })
	passage({ P(150, 20, -74), P(150, 18, -44), P(148, 16, -24) }, 6, 6, { flat = 0.8 })
	spot("OldTube", P(40, 22, -86))
	passage({ P(150, 0, 22), P(132, -10, 42), P(116, -22, 58) }, 6, 6, { flat = 0.8 })
	chamber(P(108, -22, 62), 16, 9, 12, { floor = 0.5 })
	spot("SumpGate", P(108, -26, 62))
	passage({ P(100, -24, 62), P(40, -26, 66), P(-20, -26, 60), P(-68, -24, 50) }, 5, 12, { flat = 0.15 })
	passage({ P(-30, 2, 8), P(-48, 2, 24), P(-64, 0, 40) }, 5, 4, { flat = 0.9 })
	shaft(P(-68, -24, 46), 5, 28) -- the crystal chimney
	spot("SwallowHole", P(-64, 0, 40))
	local b1 = J(P(-98, 4, -26)) -- the chamber first: the squeeze then ends exactly in it (seed 11 left B1 sealed off)
	passage({ P(-34, 2, -4), J(P(-60, 2, -14)), J(P(-84, 3, -22)), b1 }, 4.2, 5, { flat = 0.6 })
	 chamber(b1, 12, 8, 9) passage({ b1, J(P(-120, 14, -60)), P(-130, 24, -84) }, 4.2, 5, { flat = 0.8 }) spot("B1", b1)
	local b2 = J(P(-92, -4, 18)) passage({ J(P(-66, 2, -8)), b2 }, 4.2, 5, { flat = 0.8 }) chamber(b2, 13, 9, 11, { floor = 0.55 }) spot("B2", b2)
	local b3 = J(P(-112, -6, 52)) passage({ b2, b3 }, 4.2, 5, { flat = 0.8 }) chamber(b3, 11, 9, 10) spot("B3", b3)
	local b4 = J(P(200, 12, -22)) passage({ P(176, 10, -4), b4 }, 4.2, 7, { flat = 0.6 }) chamber(b4, 7, 10, 6) spot("B4", b4)
	local b5 = J(P(176, 0, 58)) passage({ P(152, 2, 24), J(P(164, 2, 42)), b5 }, 4.2, 5, { flat = 0.8 }) chamber(b5, 8, 7, 7) spot("B5", b5)
	else
	-- LAYER 2, TITAN'S REST (plan sections 3 to 6): clay country. Wide, low bedding-plane galleries (old floods spread sideways
	-- between soft clay beds), the Titan's Hall (a huge collapse chamber where a stone giant lies asleep), an upper gallery, a clay
	-- pool, a lower gallery back under the hall and a footprint drop; the same five branch slots as layer 1.
	passage({ P(36, 2, 0), P(52, 1, 8), P(64, 0, 12) }, 16, 5, { flat = 0.8 }) -- the bedding plane east: wide, low, flat
	-- directive v13 (story01 12:00): a narrow foggy threshold pinch before the Titan's Hall opens out. The wide plane above ends
	-- at x 64 (its end slab carves to about x 92), so the throat is narrow from there to the hall's west wall near x 108
	passage({ P(64, 0, 12), P(90, -2, 7), P(118, -2, 2) }, 4.6, 5.5, { flat = 0.8 })
	spot("Canyon", P(76, -2, 6))
	chamber(P(156, 10, 0), 48, 26, 36, { floor = 0.4, slope = 0.08 }) -- the Titan's Hall
	spot("Cathedral", P(132, 0, 6))
	passage({ P(-130, 20, -82), P(-40, 18, -86), P(40, 18, -84), P(120, 16, -80), P(156, 16, -74) }, 11, 5, { flat = 0.75 }) -- the upper gallery
	passage({ P(20, 4, -20), P(28, 10, -50), P(28, 18, -82) }, 5, 5, { flat = 0.8 })
	passage({ P(156, 16, -74), P(156, 14, -46), P(152, 12, -28) }, 6, 6, { flat = 0.8 })
	spot("OldTube", P(40, 18, -84))
	passage({ P(156, 0, 26), P(136, -10, 44), P(118, -18, 58) }, 7, 6, { flat = 0.8 })
	chamber(P(110, -18, 62), 18, 8, 14, { floor = 0.5 }) -- the clay pool
	spot("SumpGate", P(110, -22, 62))
	passage({ P(100, -20, 62), P(40, -22, 66), P(-20, -22, 60), P(-66, -20, 50) }, 12, 5, { flat = 0.8 }) -- the lower gallery
	passage({ P(-30, 2, 8), P(-48, 2, 24), P(-64, 0, 40) }, 5, 4, { flat = 0.9 })
	shaft(P(-68, -20, 46), 6, 24) -- the footprint drop: a giant's heel punched through the floor
	spot("SwallowHole", P(-64, 0, 40))
	local b1 = J(P(-100, 4, -28)) -- the chamber first: the squeeze then ends exactly in it (seed 11 left B1 sealed off)
	passage({ P(-34, 2, -4), J(P(-62, 2, -16)), J(P(-86, 3, -24)), b1 }, 5, 4, { flat = 0.9 })
	 chamber(b1, 14, 6, 10) passage({ b1, J(P(-118, 12, -58)), P(-130, 20, -82) }, 5, 4, { flat = 0.85 }) spot("B1", b1)
	local b2 = J(P(-94, -4, 20)) passage({ J(P(-68, 2, -10)), b2 }, 5, 4, { flat = 0.9 }) chamber(b2, 16, 7, 12, { floor = 0.55 }) spot("B2", b2)
	local b3 = J(P(-114, -6, 54)) passage({ b2, b3 }, 5, 4, { flat = 0.85 }) chamber(b3, 12, 7, 10) spot("B3", b3)
	local b4 = J(P(214, 12, -22)) passage({ P(190, 8, -4), b4 }, 5, 6, { flat = 0.6 }) chamber(b4, 7, 8, 6) spot("B4", b4)
	local b5 = J(P(180, 0, 62)) passage({ P(160, 2, 28), J(P(170, 2, 46)), b5 }, 5, 4, { flat = 0.9 }) chamber(b5, 9, 5, 8) spot("B5", b5)
	end
	if L >= 2 then -- directive v13 (level01 #6, "pure linear backtracking"): the deep layers' branch chambers loop back instead of
		-- ending: B1 round to B2, B3 back to the swallow hole, B4 round the far side to B5 (spots carry the dip: take it off first)
		local function raw(q) return q and (q - P(0, dipY(q.X), 0)) end
		local b1, b2, b3, b4, b5 = raw(spots.B1), raw(spots.B2), raw(spots.B3), raw(spots.B4), raw(spots.B5)
		if b1 and b2 then passage({ b1, P(-114, 2, -4), b2 }, 4.2, 4.5, { flat = 0.8 }) end
		if b3 then passage({ b3, P(-82, -2, 46), P(-64, 0, 40) }, 4.2, 4.5, { flat = 0.8 }) end
		if b4 and b5 then passage({ b4, P(208, 6, 18), b5 }, 4.2, 4.5, { flat = 0.8 }) end
	end
	-- directive v14: a noodle flank loop off the main route, and a stepped vault over each layer's landmark chamber
	if opt.hall then
		noodle(P(96, 2, -14), P(150, 4, -30), 14, 2)
	elseif not opt.camp or L == 1 then
		noodle(P(52, 0, 34), P(104, -6, 10), 16, 1)
	end
	if L == 1 then dome(P(146, 8, 0), 22, 24)
	elseif L == 2 then dome(P(156, 10, 0), 26, 30)
	elseif L == 3 then dome(P(150, 14, 0), 32, 22)
	else dome(P(152, 10, 0), 24, 30) end
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
	if L == 4 then -- ash and cooled crust, with glowing cracks in the hot spots
		FLOOR = {
			camp = { Color3.fromRGB(84, 60, 58), Color3.fromRGB(104, 76, 70), 0.05 }, tunnel = { Color3.fromRGB(54, 38, 38), Color3.fromRGB(70, 50, 48), 0.15 },
			chasm = { Color3.fromRGB(50, 34, 34), Color3.fromRGB(66, 46, 44), 0.25 }, grotto = { Color3.fromRGB(58, 40, 40), Color3.fromRGB(76, 52, 50), 0.3 },
			squeeze = { Color3.fromRGB(56, 38, 36), Color3.fromRGB(72, 50, 46), 0.15 }, mush = { Color3.fromRGB(60, 40, 44), Color3.fromRGB(78, 54, 56), 0.2 },
		}
	elseif L == 3 then -- cold slate floors with frost-white crystal grit
		FLOOR = {
			camp = { Color3.fromRGB(70, 74, 112), Color3.fromRGB(92, 96, 138), 0.05 }, tunnel = { Color3.fromRGB(44, 48, 86), Color3.fromRGB(60, 66, 108), 0.2 },
			chasm = { Color3.fromRGB(40, 44, 82), Color3.fromRGB(56, 60, 102), 0.25 }, grotto = { Color3.fromRGB(48, 52, 96), Color3.fromRGB(66, 72, 120), 0.35 },
			squeeze = { Color3.fromRGB(46, 46, 80), Color3.fromRGB(62, 62, 100), 0.15 }, mush = { Color3.fromRGB(52, 44, 90), Color3.fromRGB(70, 60, 116), 0.3 },
		}
	elseif L == 2 then -- warm clay floors, a little teal glass in the damp ones
		FLOOR = {
			camp = { Color3.fromRGB(176, 124, 90), Color3.fromRGB(196, 142, 104), 0.08 }, tunnel = { Color3.fromRGB(156, 104, 72), Color3.fromRGB(176, 122, 86), 0.15 }, -- Gemini l2r1: warm biscuit, well lighter than the walls
			chasm = { Color3.fromRGB(150, 98, 70), Color3.fromRGB(170, 116, 84), 0.2 }, grotto = { Color3.fromRGB(146, 108, 90), Color3.fromRGB(166, 126, 104), 0.3 },
			squeeze = { Color3.fromRGB(158, 104, 74), Color3.fromRGB(178, 122, 88), 0.1 }, mush = { Color3.fromRGB(150, 100, 82), Color3.fromRGB(170, 118, 96), 0.25 },
		}
	end
	local function themeAt(wp) -- the nearest place's theme (wp in local studs)
		local best, bd = "tunnel", math.huge
		for _, r in REG do
			local d = (r[1] - wp).Magnitude
			if d < bd then best, bd = r[2], d end
		end
		return best
	end

	if opt.hall then -- the hall's box stays solid: ClayCaves builds there
		local hx0, hx1 = math.floor(toVox(P(-82, 0, 0))), math.ceil(toVox(P(82, 0, 0)))
		local _, hy0 = toVox(P(0, -6, 0))
		local _, hy1 = toVox(P(0, 80, 0))
		local _, _, hz0 = toVox(P(0, 0, -62))
		local _, _, hz1 = toVox(P(0, 0, 62))
		for x = hx0, hx1 do for y = math.floor(hy0), math.ceil(hy1) do for z = math.floor(hz0), math.ceil(hz1) do set(x, y, z, 0) end end end
		do -- and the two rooms behind its north wall (ClayCaves: the Jar Gallery x -6..28 and the Fossil Dig x 34..74, z -110..-60)
			local ax0, ay0, az0 = toVox(P(-12, -6, -116))
			local ax1, ay1, az1 = toVox(P(80, 52, -56))
			for x = math.floor(ax0), math.ceil(ax1) do for y = math.floor(ay0), math.ceil(ay1) do for z = math.floor(az0), math.ceil(az1) do set(x, y, z, 0) end end end
		end
		for _, sx in { -1, 1 } do -- the hall's doors open through the box's rim onto the galleries (the refill had sealed them)
			for x = math.floor(toVox(P(sx * 76, 0, 0))), math.ceil(toVox(P(sx * 92, 0, 0))), sx do
				for z = math.floor(select(3, toVox(P(0, 0, -8)))), math.ceil(select(3, toVox(P(0, 0, 8)))) do
					for y = math.floor(select(2, toVox(P(0, 0.5, 0)))), math.ceil(select(2, toVox(P(0, 14, 0)))) do set(x, y, z, 1) end
				end
			end
		end
		-- the drop was under the hall's floor: it moves out to the west gallery and drops into the lower gallery's west end
		passage({ P(-110, 4, 20), P(-106, 1, 40) }, 5, 5, { flat = 0.8 })
		shaft(P(-106, -20, 44), 6, 24)
		passage({ P(-66, -20, 50), P(-90, -20, 48), P(-106, -20, 44) }, 12, 5, { flat = 0.8 })
		spot("SwallowHole", P(-106, 1, 40))
		local b1 = spots.B1 - P(0, dipY(spots.B1.X), 0) -- B1's squeeze began inside the hall: a short tube joins it to the west gallery
		passage({ P(-100, 4, 6), (P(-100, 4, 6) + b1) / 2, b1 }, 5, 5, { flat = 0.8 })
	end

	-- CRUMPLE: rock next to air is eaten or grown a little by 3D noise, so no wall is a clean curve
	local flip = {}
	for x = 1, NX - 2 do
		for y = 1, NY - 2 do
			for z = 1, NZ - 2 do
				local v = get(x, y, z)
				if inCamp(x, z) then continue end
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
					if not inCamp(x, z) and get(x, y, z) == 1 and get(x, y - 1, z) == 0 and get(x, y + 1, z) == 1 and get(x, y + 2, z) == 1 and get(x, y + 3, z) == 1 then
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

	-- STRATA (directive v14, Recipe B): tilted, domain-warped rock beds 8 studs thick sweep across the walls instead of a random
	-- colour per block; band 4 is a hard limestone bed that juts out one voxel where it meets open air high on a wall
	local function strata(lx, ly, lz)
		return math.floor((ly + 0.3 * lx + 0.22 * lz + 7 * math.noise(lx / 56, lz / 56, wob * 0.5 + 0.3)) / 12) % 5 -- 12-stud beds dipping on both axes, about 20 degrees (Gemini v14p2_r3: horizontal stripes, checkerboard)
	end
	do
		local add = {}
		for x = 2, NX - 3 do
			for z = 2, NZ - 3 do
				if inCamp(x, z) then continue end
				for y = 7, NY - 3 do
					if get(x, y, z) == 1 and get(x, y - 1, z) == 1 and get(x, y - 2, z) == 1 and get(x, y - 3, z) == 1
						and (get(x, y - 4, z) == 0 or get(x, y - 5, z) == 0 or get(x, y - 6, z) == 0) then -- 12+ studs over a floor (not in a deep shaft)
						for _, dd in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
							local wx, wz = x + dd[1], z + dd[2]
							if get(wx, y, wz) == 0 and get(x - dd[1], y, z - dd[2]) == 1 and get(x - 2 * dd[1], y, z - 2 * dd[2]) == 1
								and strata((wx - CX + 0.5) * V, (y - CY + 0.5) * V, (wz - CZ + 0.5) * V) == 4 then
								table.insert(add, { x, y, z })
								break
							end
						end
					end
				end
			end
		end
		for _, a in add do set(a[1], a[2], a[3], 0) end
	end
	do -- CEILING POCKETS (directive v14, Gemini v14p2_r5: "flat parking-garage ceilings"): over 3+ voxels of headroom, noise lifts patches
		-- of a flat roof one or two voxels, only where solid rock stays above, so roofs step up into pockets and corbels
		local lift = {}
		for x = 2, NX - 3 do
			for z = 2, NZ - 3 do
				if inCamp(x, z) then continue end
				for y = 4, NY - 5 do
					if get(x, y, z) == 1 and get(x, y + 1, z) == 0 and get(x, y - 1, z) == 1 and get(x, y - 2, z) == 1 and get(x, y - 3, z) == 1 and get(x, y + 2, z) == 0 and get(x, y + 3, z) == 0 then
						local n = math.noise(x * 0.18 + wob, z * 0.18, y * 0.1 + 0.5)
						if n > 0.2 then table.insert(lift, { x, y + 1, z, n > 0.36 and get(x, y + 4, z) == 0 }) end -- part budget: about a quarter of each flat roof
					end
				end
			end
		end
		for _, l in lift do
			set(l[1], l[2], l[3], 1)
			if l[4] then set(l[1], l[2] + 1, l[3], 1) end
		end
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
	local function stand(x, y, z) return isAirV(get(x, y, z)) and not isAirV(get(x, y - 1, z)) and isAirV(get(x, y + 1, z)) end -- shallow water is walked through
	local reach = {}
	do
		local q, qi = {}, 1
		local function push(x, y, z) local k = idx(x, y, z) if not reach[k] then reach[k] = true table.insert(q, { x, y, z }) end end
		for _, sp in { spots.Camp, spots.HallEast } do
			local cx, cy, cz = toVox(sp)
			local sx, sz = math.floor(cx), math.floor(cz)
			for y = math.floor(cy) + 3, 1, -1 do if stand(sx, y, sz) then push(sx, y, sz) break end end
		end
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

	-- ORE SPOTS, chosen before the mesh (directive v14, Recipe F: each deposit sits in a real vug, a niche one voxel deep cut into its
	-- bed, only where the rock behind is two voxels thick so a niche never opens into another passage).
	-- ORE DEPOSITS (plan section 5): base ore lines the main route's walls, mid ore sits in the branch rooms, rare ore only at the dead
	-- ends (B1, B3, B4, B5) and in the cathedral's cracks. Each stands on a reachable floor cell against a wall, 14 studs apart, with
	-- the attributes the rest of the game reads (Layer, Ore, OreName) and the same shard-and-core look as CaveBuilder's.
	local C = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))
	local ORES = C.LAYERS[L][4]
	local DEAD = { spots.B1, spots.B3, spots.B4, spots.B5 }
	local BRANCH = { spots.B2, spots.SwallowHole, spots.OldTube }
	local cands = {}
	for k in reach do
		local z = k % NZ
		local y = math.floor(k / NZ) % NY
		local x = math.floor(k / (NZ * NY))
		for _, d in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
			if get(x + d[1], y, z + d[2]) == 0 and get(x + d[1], y + 1, z + d[2]) == 0 then
				local wx, wz = (x + d[1] - CX + 0.5) * V, (z + d[2] - CZ + 0.5) * V
				table.insert(cands, { x, y, z, d, contact = strata(wx, (y - CY + 0.5) * V, wz) ~= strata(wx, (y - CY + 1.5) * V, wz) }) -- directive v14 (Recipe F): where two beds meet
				break
			end
		end
	end
	local function rank(c) -- dead ends first, then branches, then the rest; shuffled within each by a hash
		local lp = toWorld(c[1], c[2], c[3]) - origin
		for _, d in DEAD do if (d - lp).Magnitude < 20 then return 0 end end
		for _, b in BRANCH do if (b - lp).Magnitude < 24 then return 1 end end
		return 2
	end
	for _, c in cands do c.r = rank(c) + hash(c[1], c[3], c[2]) * (c.contact and 0.35 or 1) end -- bed contacts first within each rank
	table.sort(cands, function(a2, b2) return a2.r < b2.r end)
	local placed, nDep, chosen = {}, 0, {}
	local CAP, have = { 22, 9, 5 }, { 0, 0, 0 } -- base, mid, rare: rare stays rare
	local campW = origin + spots.Camp
	for _, c in cands do
		if #chosen >= 36 then break end
		local w = toWorld(c[1], c[2], c[3]) - Vector3.new(0, V / 2, 0)
		local lp = w - origin
		if (w - campW).Magnitude > (opt.camp and 58 or 40) then
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
				table.insert(chosen, { c = c, idx2 = idx2, w = w })
				local nx2, nz2 = c[1] + c[4][1], c[3] + c[4][2]
				if get(nx2 + c[4][1], c[2], nz2 + c[4][2]) == 0 and get(nx2 + c[4][1], c[2] + 1, nz2 + c[4][2]) == 0 and get(nx2, c[2] + 2, nz2) == 0 then
					set(nx2, c[2], nz2, 1)
					set(nx2, c[2] + 1, nz2, 1)
					c.niche = true
				end
			end
		end
	end
	-- MESH: every solid voxel that touches air (26 neighbours) is shell; shell voxels merge into boxes per colour key
	local model = Instance.new("Model")
	model.Name = "CavesV2"
	model:SetAttribute("Seed", seed)
	model:SetAttribute("Layer", L)
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
				local lx, ly, lz = (x - CX + 0.5) * V, (y - CY + 0.5) * V, (z - CZ + 0.5) * V
				local hallRock = opt.hall and ((math.abs(lx) < 80 and math.abs(lz) < 60 and ly > -6) or (lx > -12 and lx < 80 and lz > -116 and lz < -56 and ly > -6 and ly < 52)) -- ClayCaves draws its own walls there
				if (v == 0 or v == 3) and not hallRock then
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
							k = 100 + TI[th] * 10 + (moss and 2 or 1) -- one matte tone per place and one for the damp hollows (directive v14, Recipe C: no per-block floor noise; the floors merge into big slabs)
							if not moss then -- a ledge lip (tour grades 6.7-6.8: "path boundaries and drop-offs dissolve into murk"): a floor block over a drop of 2+ voxels
								for _, d in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
									if isAir(get(x + d[1], y, z + d[2])) and isAir(get(x + d[1], y - 1, z + d[2])) and isAir(get(x + d[1], y + 1, z + d[2])) then k = 100 + TI[th] * 10 + 4 break end
								end
							end
						else -- a wall or a roof: its rock bed (directive v14), a step lighter high up, darker overhead
							k = (isAir(get(x, y - 1, z)) and 20 or (ly > 26 and 10 or 0)) + 1 + strata(lx, ly, lz)
						end
						key[idx(x, y, z)] = k
						nShell += 1
					end
				end
			end
		end
	end
	local WALL0 = nil
	local WALL = L == 4 and { Color3.fromRGB(26, 18, 20), Color3.fromRGB(42, 28, 30), Color3.fromRGB(62, 40, 40), Color3.fromRGB(88, 52, 48) } -- layer 4: basalt, warmer where the glow reaches
		or L == 3 and { Color3.fromRGB(20, 22, 48), Color3.fromRGB(32, 36, 72), Color3.fromRGB(48, 54, 100), Color3.fromRGB(70, 76, 132) } -- layer 3: night-blue granite
		or L == 2 and { Color3.fromRGB(62, 30, 22), Color3.fromRGB(104, 54, 42), Color3.fromRGB(140, 80, 62), Color3.fromRGB(170, 108, 82) } -- the damp foot of the walls darker (Gemini l2r1) -- layer 2: fired clay, darker low, sun-baked high
		or { Color3.fromRGB(40, 26, 54), Color3.fromRGB(61, 41, 82), Color3.fromRGB(86, 61, 112), Color3.fromRGB(110, 84, 140) } -- deep amethyst slate to soft lavender granite (Gemini r1 palette, a step lighter at the top)
	local ACCENT = ({ Color3.fromRGB(168, 86, 52), Color3.fromRGB(176, 92, 48), Color3.fromRGB(150, 176, 236), Color3.fromRGB(170, 54, 30) })[L] -- iron stain in the upper layers, frost in Glitterhall, ember in Muspell (Gemini v14p2_r2: no terracotta in the blue layer)
	local STRATA = { WALL[1], WALL[2]:Lerp(Color3.fromRGB(64, 72, 132), L == 4 and 0 or 0.22), WALL[3]:Lerp(ACCENT, 0.38), WALL[2]:Lerp(WALL[3], 0.5), WALL[4]:Lerp(Color3.fromRGB(236, 222, 236), 0.22) } -- dark shale, a cool bed, an iron-stained bed, mid, and the pale hard limestone (directive v14: the bands must read under the torch)
	local function colorOf(k)
		if k == 99 then return ({ Color3.fromRGB(45, 26, 56), Color3.fromRGB(60, 34, 26), Color3.fromRGB(224, 242, 254), Color3.fromRGB(24, 18, 22) })[L] end -- the pool's shore: wet mud, wet clay, frost (Gemini l3r1), cooled obsidian
		if k == 9 then return PAL.bark end
		if k < 100 then -- rock beds: ceilings 22% darker, the upper walls lifted toward the top tone (directive v14, Recipe C)
			local c = STRATA[(k - 1) % 10 + 1]
			if k >= 20 then return c:Lerp(Color3.new(0, 0, 0), 0.22) elseif k >= 10 then return c:Lerp(WALL[4], 0.22) end
			return c
		end
		local th = THEMES[math.floor((k - 100) / 10)]
		local v = k % 10
		local f = FLOOR[th]
		if v == 4 then return f[2]:Lerp(Color3.fromRGB(255, 240, 222), 0.32) end -- a ledge lip: the walking edge over a drop, a step paler than its floor
		if v >= 2 then return L == 4 and (v == 2 and Color3.fromRGB(236, 80, 40) or Color3.fromRGB(255, 140, 60)) or L == 3 and (v == 2 and Color3.fromRGB(120, 130, 200) or Color3.fromRGB(170, 180, 230)) or L == 2 and (v == 2 and Color3.fromRGB(70, 150, 140) or Color3.fromRGB(96, 176, 160)) or PAL.moss[v == 2 and 1 or 2] end -- layer 2: teal glass seams, not moss
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
						p.Material = Enum.Material.Slate -- directive v14 (audit: the Pebble carpet fought the ore glints): matte slate, lighter and warmer than the walls
						p.Color = p.Color:Lerp(({ Color3.fromRGB(176, 136, 140), Color3.fromRGB(196, 150, 120), Color3.fromRGB(160, 170, 214), Color3.fromRGB(120, 92, 86) })[L], 0.28)
					end
					p.CastShadow = h > 1
					nParts += 1
				end
			end
		end
	end

	-- (see SMOOTH below the crumple)
	local function floorUnder(p) -- the walk height under a local point (studs, local frame)
		local vx, vy, vz = toVox(p + Vector3.new(0, dipY(p.X), 0))
		local x, z = math.floor(vx), math.floor(vz)
		for y = math.floor(vy) + 2, 0, -1 do
			if get(x, y, z) == 1 and get(x, y - 1, z) == 0 then return toWorld(x, y, z) - Vector3.new(0, V / 2, 0) end
		end
		return nil
	end
	-- THE WORLD ROOT: one giant root of the World Tree comes down through the cathedral roof and spreads into the floor. A trunk of
	-- stacked cylinders that leans and narrows as it rises, bark rings, and six flaring roots at its foot; mint moss on the bark.
	if L == 1 then
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

	elseif L == 2 then -- THE SLEEPING TITAN (layer 2's landmark): a stone giant's face lies tilted in the hall's floor, eyes shut, teal glass seams
		local vx, _, vz = toVox(rootC + P(6, 0, 0))
		local x, z = math.floor(vx), math.floor(vz)
		local foot
		for y = 1, NY - 2 do if get(x, y, z) == 1 and get(x, y - 1, z) == 0 then foot = toWorld(x, y, z) - Vector3.new(0, V / 2, 0) break end end
		if foot then
			local STONE, STONE_D, TEAL = Color3.fromRGB(150, 128, 120), Color3.fromRGB(112, 92, 88), Color3.fromRGB(64, 210, 196)
			local face = CFrame.new(foot + Vector3.new(0, 7, 0)) * CFrame.Angles(math.rad(-58), math.rad(-20), math.rad(8)) -- lying back, turned to the hall's door
			local function tp(n, size, cf, col, props) return part("Landmark", n, size, face * cf, col, props or { Material = Enum.Material.Slate, MaterialVariant = "" }) end
			tp("TitanFace", Vector3.new(26, 30, 8), CFrame.new(0, 0, 0), STONE)
			tp("TitanBrow", Vector3.new(24, 4, 6), CFrame.new(0, 7, -5), STONE_D)
			tp("TitanNose", Vector3.new(5, 10, 6), CFrame.new(0, 0, -6), STONE)
			tp("TitanLip", Vector3.new(12, 2.4, 3), CFrame.new(0, -8, -5), STONE_D)
			local UMBER = Color3.fromRGB(42, 21, 13)
			for _, ex in { -6.5, 6.5 } do
				tp("TitanSocket", Vector3.new(8, 4, 1), CFrame.new(ex, 3.2, -4.1), UMBER) -- the deep sockets read the face from across the hall
				tp("TitanLid", Vector3.new(7, 1.4, 1.2), CFrame.new(ex, 3.5, -4.7), STONE_D)
				tp("TitanTear", Vector3.new(0.6, 6, 0.4), CFrame.new(ex + 1, -0.5, -4.6) * CFrame.Angles(0, 0, 0.15), Color3.fromRGB(64, 210, 196), { Material = Enum.Material.Neon, MaterialVariant = "", CanCollide = false, CastShadow = false }) -- a teal seam weeps from each lid
			end
			tp("TitanMouth", Vector3.new(10, 1.2, 1), CFrame.new(0, -8.6, -6.6), UMBER)
			tp("TitanChin", Vector3.new(16, 5, 7), CFrame.new(0, -13, -1), STONE_D)
			for k = 1, 5 do -- glowing teal seams where the stone cracked
				tp("TitanSeam", Vector3.new(0.6, 6 + k, 0.4), CFrame.new(-10 + k * 4, (k % 2) * 4 - 2, -4.3) * CFrame.Angles(0, 0, (k - 3) * 0.3), TEAL, { Material = Enum.Material.Neon, MaterialVariant = "", CanCollide = false, CastShadow = false })
			end
			local gl = tp("TitanGlow", Vector3.new(1, 1, 1), CFrame.new(0, 0, -8), TEAL, { Transparency = 1, CanCollide = false, CanQuery = false })
			local l = Instance.new("PointLight")
			l.Color, l.Range, l.Brightness, l.Shadows = TEAL, 44, 0.8, false
			l.Parent = gl
			-- directive v13 (story01 12:00, light01): warm excavation light rises from the floor along the face, so its brow and
			-- chin cut a silhouette against the dark (old dig lamps left at its chin)
			for k, o in { P(-9, -11, -5), P(9, -11, -5), P(0, -15, -3) } do
				local lamp = part("Landmark", "DigLamp", Vector3.new(0.9, 1.2, 0.9), face * CFrame.new(o), Color3.fromRGB(255, 190, 110), { Material = Enum.Material.Neon, MaterialVariant = "", CanCollide = false, CastShadow = false })
				local sl = Instance.new("SpotLight")
				sl.Face, sl.Angle, sl.Range, sl.Brightness, sl.Color, sl.Shadows = Enum.NormalId.Top, 70, 34, 2.2, Color3.fromRGB(255, 176, 96), k == 3
				sl.Parent = lamp
			end
		end
		-- Waitomo drapery ribs: honey limestone curtains hanging in rows from the vault over the hall (sheet_caves #4)
		for k = 1, 14 do
			local at = rootC + P(-24 + k * 3.6, 0, (hash(k, seed, 21) - 0.5) * 26)
			local vx, vy, vz = toVox(at)
			local x, z = math.floor(vx), math.floor(vz)
			local roof
			for y = math.floor(vy), NY - 2 do if get(x, y, z) == 1 and get(x, y + 1, z) == 0 then roof = toWorld(x, y, z) + Vector3.new(0, V / 2, 0) break end end -- air under rock: the vault (it looked for rock under air and never found one)
			if roof then
				local len = 3 + hash(k, seed, 22) * 7
				for q = 0, 2 do -- each curtain: three overlapping tapered blades
					local w = 2.6 - q * 0.7
					part("Landmark", "Drapery", Vector3.new(w, len - q * 1.2, 0.5), CFrame.new(roof + Vector3.new(q * 0.4, -(len - q * 1.2) / 2 + 0.6, q * 0.3)) * CFrame.Angles(0, k * 0.7, (q - 1) * 0.08), Color3.fromRGB(196, 150, 96):Lerp(Color3.fromRGB(236, 200, 140), q / 2), { Material = Enum.Material.Limestone, MaterialVariant = "", CanCollide = false })
				end
			end
		end
	end
	-- mint glow-pebble breadcrumbs at the branch forks: five small lit pebbles in a line pointing back toward the camp (level01 #6)
	if L == 2 or L == 3 or L == 4 then
		local home = spots.Camp or rootC
		for _, b in { "B1", "B2", "B3", "B4", "B5" } do
			local at = spots[b]
			if at then
				local dir = (home - at) * Vector3.new(1, 0, 1)
				dir = dir.Magnitude > 1 and dir.Unit or Vector3.xAxis
				for k = 0, 4 do
					local f = floorUnder(at - P(0, dipY(at.X), 0) + dir * (k * 2.2)) -- the spots carry the dip; floorUnder adds it
					if f then part("Landmark", "GlowPebble", Vector3.new(0.5, 0.3, 0.5), CFrame.new(f + Vector3.new(0, 0.12, 0)) * CFrame.Angles(0, k, 0), Color3.fromRGB(120, 255, 200), { Material = Enum.Material.Neon, MaterialVariant = "", CanCollide = false, CastShadow = false }) end
				end
			end
		end
	end

	if L == 2 then -- directive v13 (story01 12:00): a low warm mist hangs in the threshold throat, lit from the floor by two old dig
		-- lamps at the hall's mouth, so the Titan's Hall opens out of the fog
		local mid = floorUnder(P(98, -2, 5))
		if mid then
			local fog = part("Landmark", "ThresholdFog", Vector3.new(12, 1, 6), CFrame.new(mid + Vector3.new(0, 2.6, 0)), Color3.new(1, 1, 1), { Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false })
			local e = Instance.new("ParticleEmitter")
			e.Texture, e.Shape = "rbxasset://textures/particles/smoke_main.dds", Enum.ParticleEmitterShape.Box
			e.Color = ColorSequence.new(Color3.fromRGB(222, 190, 160), Color3.fromRGB(150, 172, 182))
			e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 5), NumberSequenceKeypoint.new(1, 9) })
			e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.8), NumberSequenceKeypoint.new(0.7, 0.85), NumberSequenceKeypoint.new(1, 1) })
			e.Lifetime, e.Rate, e.Speed, e.SpreadAngle = NumberRange.new(6, 9), 5, NumberRange.new(0.3, 0.8), Vector2.new(180, 20)
			e.Rotation, e.RotSpeed, e.LightEmission, e.LightInfluence = NumberRange.new(0, 360), NumberRange.new(-8, 8), 0.05, 1
			e.Acceleration = Vector3.new(0.4, 0.04, 0) -- it drifts toward the hall
			e.Parent = fog
		end
		for _, z in { -1, 7 } do
			local f = floorUnder(P(110, -2, z))
			if f then
				local lamp = part("Landmark", "DigLamp", Vector3.new(0.9, 1.2, 0.9), CFrame.new(f + Vector3.new(0, 0.6, 0)), Color3.fromRGB(255, 190, 110), { Material = Enum.Material.Neon, MaterialVariant = "", CanCollide = false, CastShadow = false })
				local sl = Instance.new("SpotLight")
				sl.Face, sl.Angle, sl.Range, sl.Brightness, sl.Color, sl.Shadows = Enum.NormalId.Top, 75, 26, 1.8, Color3.fromRGB(255, 176, 96), false
				sl.Parent = lamp
			end
		end
	end
	-- directive v13 (light01; Graphics Levels 1-3 on phones): thin glowing rims in the layer's own glow on the lip of every drop of
	-- two voxels (8 studs) or more, dashed (every other cell), so a cliff edge reads on low quality with no light at all. Capped
	-- at 140; the count is the model's attribute RimGuides.
	do
		local made = 0
		model:SetAttribute("RimGuides", 0)
		for x = 1, NX - 2 do
			if made >= 140 then break end
			for z = 1, NZ - 2 do
				for y = 2, NY - 3 do
					if made < 140 and (x + y + z) % 2 == 0 and get(x, y, z) == 1 and get(x, y + 1, z) == 1 and get(x, y - 1, z) == 0 and not inCamp(x, z) then
						for _, d in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
							local nx, nz = x + d[1], z + d[2]
							if get(nx, y, nz) == 1 and get(nx, y - 1, nz) == 1 and get(nx, y - 2, nz) == 1 then
								local top = toWorld(x, y, z) - Vector3.new(0, V / 2, 0) + Vector3.new(d[1], 0, d[2]) * (V / 2 - 0.2)
								part("RimGuides", "RimGuide", d[1] ~= 0 and Vector3.new(0.22, 0.14, V * 0.8) or Vector3.new(V * 0.8, 0.14, 0.22), CFrame.new(top + Vector3.new(0, 0.08, 0)), GLOW,
									{ Material = Enum.Material.Neon, MaterialVariant = "", Transparency = 0.15, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false })
								made += 1
								model:SetAttribute("RimGuides", made)
								break
							end
						end
					end
				end
			end
		end
	end

	if L == 4 then -- THE MAGMA LAKE under the hall's floor edge and basalt columns round it: hexagon-ish stacks, lit from below
		local vx, vy, vz = toVox(rootC)
		local lake = part("Landmark", "MagmaLake", Vector3.new(60, 1, 44), CFrame.new(origin + rootC + P(0, -6, 0)), Color3.fromRGB(255, 96, 40), { Material = Enum.Material.Neon, MaterialVariant = "", CanCollide = false, CastShadow = false })
		local ll = Instance.new("PointLight")
		ll.Color, ll.Range, ll.Brightness, ll.Shadows = Color3.fromRGB(255, 110, 50), 60, 1.2, false
		ll.Parent = lake
		do -- directive v13 (Gemini phase 5: a still neon sheet): slow bubbles swell and pop all over the lake's face
			local b = Instance.new("ParticleEmitter")
			b.Texture, b.Shape, b.ShapeStyle = "rbxasset://textures/particles/sparkles_main.dds", Enum.ParticleEmitterShape.Box, Enum.ParticleEmitterShapeStyle.Volume
			b.Color, b.LightEmission, b.Rate = ColorSequence.new(Color3.fromRGB(255, 200, 90), Color3.fromRGB(255, 90, 30)), 0.8, 14
			b.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(0.8, 1.3), NumberSequenceKeypoint.new(1, 0) })
			b.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(0.8, 0.2), NumberSequenceKeypoint.new(1, 1) })
			b.Lifetime, b.Speed, b.EmissionDirection = NumberRange.new(0.8, 1.4), NumberRange.new(0.6, 1.4), Enum.NormalId.Top
			b.Parent = lake
		end
		part("Landmark", "MagmaCrust", Vector3.new(64, 0.8, 48), lake.CFrame * CFrame.new(0, -0.2, 0), Color3.fromRGB(24, 18, 22), { Material = Enum.Material.Glass, MaterialVariant = "", Transparency = 0.2, CanCollide = false }) -- the cooled obsidian rim round the glow
		for k = 1, 3 do -- floating rafts of dark slag
			part("Landmark", "SlagRaft", Vector3.new(4 + k, 0.8, 3 + k * 0.5), lake.CFrame * CFrame.new((k - 2) * 14, 0.6, (hash(k, seed, 8) - 0.5) * 20) * CFrame.Angles(0, k, 0), Color3.fromRGB(30, 22, 24), { Material = Enum.Material.Basalt, MaterialVariant = "", CanCollide = false })
		end
		local vent = floorUnder(P(-68, -24, 46)) -- a vent at the bottom of the drop: a rising glow and sparks
		if vent then
			local v = part("Landmark", "MagmaVent", Vector3.new(3, 0.6, 3), CFrame.new(vent + Vector3.new(0, 0.3, 0)), Color3.fromRGB(255, 85, 0), { Material = Enum.Material.Neon, MaterialVariant = "", CanCollide = false })
			local vl = Instance.new("PointLight")
			vl.Color, vl.Range, vl.Brightness, vl.Shadows = Color3.fromRGB(255, 85, 0), 24, 1.6, false
			vl.Parent = v
			local e = Instance.new("ParticleEmitter")
			e.Texture, e.Color, e.LightEmission = "rbxasset://textures/particles/sparkles_main.dds", ColorSequence.new(Color3.fromRGB(255, 150, 60)), 1
			e.Size, e.Rate, e.Lifetime, e.Speed, e.SpreadAngle = NumberSequence.new(0.3, 0), 8, NumberRange.new(2, 3.5), NumberRange.new(4, 7), Vector2.new(12, 12)
			e.Parent = v
		end
		-- directive v13 (Giant's Causeway, sheet_caves #3): stepping plinths of hexagonal basalt, 1 to 6 studs, in uneven clusters
		-- by the lake's shore, and a dark wrought-iron grate walk on two rails across the lake, hung from the vault on chains
		for k = 1, 7 do
			local a = k / 7 * math.pi * 2 + 0.3
			local c0 = origin + rootC + P(math.cos(a) * 34, -4, math.sin(a) * 24)
			for i = 0, 6 do
				local ring = i == 0 and Vector3.zero or Vector3.new(math.cos(i / 6 * math.pi * 2) * 2.1, 0, math.sin(i / 6 * math.pi * 2) * 2.1)
				local hh = 1 + math.floor(hash(k, i, 31) * 6)
				for t = 0, 1 do
					part("Landmark", "CausewayStep", Vector3.new(2, hh, 2), CFrame.new(c0 + ring + Vector3.new(0, hh / 2, 0)) * CFrame.Angles(0, t * math.pi / 6 + i * 0.1, 0), Color3.fromRGB(46 + i * 2, 34, 36), { Material = Enum.Material.Basalt, MaterialVariant = "" })
				end
			end
		end
		do
			local y = lake.Position.Y + 2.2
			local a0, a1 = lake.Position + Vector3.new(-30, 0, 0), lake.Position + Vector3.new(30, 0, 0)
			for _, sd in { -1.6, 1.6 } do
				part("Landmark", "GrateRail", Vector3.new(60, 0.4, 0.4), CFrame.new((a0 + a1) / 2 + Vector3.new(0, 2.2, sd)), Color3.fromRGB(28, 24, 28), { Material = Enum.Material.Metal, MaterialVariant = "" })
			end
			for k = -14, 14 do
				part("Landmark", "GrateSlat", Vector3.new(0.5, 0.2, 3.6), CFrame.new(lake.Position + Vector3.new(k * 2, 2.05, 0)), Color3.fromRGB(36, 30, 34), { Material = Enum.Material.Metal, MaterialVariant = "" })
				if k % 4 == 0 then -- chains up to the vault
					for _, sd in { -1.6, 1.6 } do
						part("Landmark", "GrateChain", Vector3.new(0.25, 18, 0.25), CFrame.new(lake.Position + Vector3.new(k * 2, 2.2 + 9, sd)), Color3.fromRGB(46, 40, 44), { Material = Enum.Material.DiamondPlate, MaterialVariant = "", CanCollide = false })
					end
				end
			end
		end
		for k = 1, 9 do
			local a = k / 9 * math.pi * 2
			local at = origin + rootC + P(math.cos(a) * 26, 0, math.sin(a) * 18)
			local h = 6 + hash(k, seed, 4) * 14
			for q = 0, 4 do -- a cluster of five basalt columns, each a different height: natural stepping stones (Gemini l4r1)
				local o2 = q == 0 and Vector3.zero or Vector3.new(math.cos(q * 1.57 + k) * 2.4, 0, math.sin(q * 1.57 + k) * 2.4)
				local ch = h - q * (1 + hash(k, q, 6) * 3)
				for t = 0, 1 do -- two blocks turned 30 degrees apart: a six-sided profile
					part("Landmark", "BasaltColumn", Vector3.new(2.4, ch, 2.4), CFrame.new(at + o2 + Vector3.new(0, ch / 2 - 4, 0)) * CFrame.Angles(0, q * 0.5 + t * math.pi / 6, 0), Color3.fromRGB(40 + q * 3, 30, 32), { Material = Enum.Material.Basalt, MaterialVariant = "" })
				end
			end
		end
	end
	if L == 3 then -- directive v13 (Naica #5, Reed Flute #6): three huge translucent crystal ribs lean diagonally across the hall
		-- over still, dark obsidian pools that mirror their light; the walkways stay clear between them
		for k = 1, 3 do
			local a = k * 2.1 + seed
			local foot = floorUnder(rootC - P(0, dipY(rootC.X), 0) + P(math.cos(a) * 20, 0, math.sin(a) * 15)) -- floorUnder adds the dip itself: rootC carries it already
			if foot then
				local cf = CFrame.new(foot) * CFrame.Angles(0, a + math.pi, 0) * CFrame.Angles(math.rad(52), 0, 0) * CFrame.new(0, 24, 0)
				part("Landmark", "CrystalRib", Vector3.new(4.5, 52, 4.5), cf, Color3.fromRGB(200, 220, 255), { Material = Enum.Material.Glass, MaterialVariant = "", Transparency = 0.35, CanCollide = false })
				part("Landmark", "CrystalRibCore", Vector3.new(1.2, 48, 1.2), cf, Color3.fromRGB(170, 210, 255), { Material = Enum.Material.Neon, MaterialVariant = "", Transparency = 0.45, CanCollide = false, CastShadow = false })
			end
			local pool = floorUnder(rootC - P(0, dipY(rootC.X), 0) + P(math.cos(a + 1) * 12, 0, math.sin(a + 1) * 9))
			if pool then
				part("Landmark", "ObsidianPool", Vector3.new(9, 0.2, 6.5), CFrame.new(pool + Vector3.new(0, 0.13, 0)) * CFrame.Angles(0, a, 0), Color3.fromRGB(12, 10, 24), { Material = Enum.Material.Glass, MaterialVariant = "", Reflectance = 0.45, CanCollide = false })
				part("Landmark", "PoolRim", Vector3.new(9.8, 0.14, 7.3), CFrame.new(pool + Vector3.new(0, 0.05, 0)) * CFrame.Angles(0, a, 0), Color3.fromRGB(120, 150, 255), { Material = Enum.Material.Neon, MaterialVariant = "", Transparency = 0.55, CanCollide = false, CastShadow = false })
			end
		end
	end
	if L == 3 then -- THE CRYSTAL CATHEDRAL: five great crystal columns from floor toward the roof, violet and blue, each lighting the hall
		local COLS = { Color3.fromRGB(156, 92, 206), Color3.fromRGB(70, 146, 255), Color3.fromRGB(190, 160, 255) }
		for k = 1, 5 do
			local a = k / 5 * math.pi * 2 + seed
			local at = rootC + P(math.cos(a) * 18, 0, math.sin(a) * 14) + P(10, 0, 0) -- round the hall's far half, clear of the way in
			local vx, _, vz = toVox(at)
			local x, z = math.floor(vx), math.floor(vz)
			local foot, top
			for y = 1, NY - 2 do
				if get(x, y, z) == 1 and get(x, y - 1, z) == 0 and not foot then foot = toWorld(x, y, z) - Vector3.new(0, V / 2, 0) end
				if foot and get(x, y, z) == 0 and get(x, y - 1, z) == 1 then top = toWorld(x, y, z) break end
			end
			if foot then
				local h = math.min(((top or foot + Vector3.new(0, 40, 0)).Y - foot.Y) * (0.55 + hash(k, seed, 1) * 0.35), 44)
				local col = COLS[k % 3 + 1]
				local tilt = CFrame.Angles((hash(k, 2, seed) - 0.5) * 0.3, a, (hash(k, 3, seed) - 0.5) * 0.3)
				for q = 0, 1 do -- two blocks turned 45 degrees apart: a faceted eight-sided prism, narrowing a little toward the top
					part("Landmark", "CrystalColumn", Vector3.new(5 - q * 0.4, h, 5 - q * 0.4), CFrame.new(foot) * tilt * CFrame.new(0, h / 2, 0) * CFrame.Angles(0, q * math.pi / 4, 0), col, { Material = Enum.Material.Glass, MaterialVariant = "", Transparency = 0.15, Reflectance = 0.2 })
				end
				for b = 1, 3 do -- smaller crystals branching off its foot
					local bh = h * (0.18 + hash(k, b, 9) * 0.2)
					local ba = b * 2.1 + k
					part("Landmark", "CrystalShard", Vector3.new(1.8, bh, 1.8), CFrame.new(foot + Vector3.new(math.cos(ba) * 3.6, 0, math.sin(ba) * 3.6)) * CFrame.Angles(math.cos(ba) * 0.5, ba, math.sin(ba) * 0.5) * CFrame.new(0, bh / 2, 0), col, { Material = Enum.Material.Glass, MaterialVariant = "", Transparency = 0.2 })
				end
				local core = part("Landmark", "CrystalCore", Vector3.new(2, h * 0.8, 2), CFrame.new(foot) * tilt * CFrame.new(0, h * 0.45, 0), col, { Material = Enum.Material.Neon, MaterialVariant = "", CanCollide = false, CastShadow = false })
				local tip = Instance.new("WedgePart")
				tip.Name, tip.Anchored, tip.Size, tip.Color, tip.Material, tip.Transparency = "CrystalTip", true, Vector3.new(5, 5, 5), col, Enum.Material.Glass, 0.15
				tip.CFrame = CFrame.new(foot) * tilt * CFrame.new(0, h + 2.5, 0)
				tip.Parent = group("Landmark")
				local l = Instance.new("PointLight")
				l.Color, l.Range, l.Brightness, l.Shadows = col, 30, 0.9, false
				l.Parent = core
			end
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
						if get(nx, y, nz) == 0 and isAir(get(nx, y + 1, nz)) and isAir(get(nx, y + 2, nz)) and not (trench[idx(x, y, z)] and hash(x, z, 91) > 0.3) then -- every one-voxel step, also in one-wide crawls (walk test 2026-11-19); a keyhole slot keeps one side ramp in three (directive v14)
							local c = toWorld(x, y, z)
							local look = Vector3.new(-dd[1], 0, -dd[2]) -- a WedgePart rises toward its -Z: face it away from the step
							local w = Instance.new("WedgePart")
							w.Name, w.Anchored, w.Size = "Ramp", true, Vector3.new(V, V, V)
							w.CFrame = CFrame.lookAt(c, c + look)
							w.Color, w.Material = colorOf(100 + TI[themeAt(Vector3.new((x - CX + 0.5) * V, (y - CY + 0.5) * V, (z - CZ + 0.5) * V))] * 10 + 1):Lerp(({ Color3.fromRGB(176, 136, 140), Color3.fromRGB(196, 150, 120), Color3.fromRGB(160, 170, 214), Color3.fromRGB(120, 92, 86) })[L], 0.28), Enum.Material.Slate -- the step is floor: the floor's own colour (matte, directive v14)
							if VARIANT then w.MaterialVariant = VARIANT end
							w.Transparency, w.CastShadow = 1, false -- directive v14 (Gemini v14p2_r4: smooth wedges): the slope is walked but not seen
							w.Parent = group("Ramps")
							nRamp += 1
							local sc = c + Vector3.new(dd[1] * V / 4, -V / 4, dd[2] * V / 4) -- a half-height step against the rise: two 2-stud stairs
							part("Ramps", "RampStep", Vector3.new(V, V / 2, V / 2), CFrame.lookAt(sc, sc + Vector3.new(dd[1], 0, dd[2])), w.Color, { CanCollide = false, CanQuery = false })
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
	local ROCK2, ROCK3 = WALL[2], WALL[3] -- dripstone and boulders in the layer's own rock
	local FLOW = ({ PAL.flow, Color3.fromRGB(214, 170, 140), Color3.fromRGB(200, 214, 255), Color3.fromRGB(120, 90, 84) })[L] -- calcite tips: pale pink, pale clay, frost, ash
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
					local fis = math.abs(math.noise((x - CX + 0.5) * V / 22, (z - CZ + 0.5) * V / 22, seed * 0.13 + 0.5)) < 0.09 -- directive v14 (Recipe D): water seeps down the roof's joint lines
					if fis and room >= 5 and hsh > 0.5 and hsh < 0.6 then -- a curtain drapery hangs from the crack, a sawtooth fringe of drips, lit from behind
						local cfb = CFrame.new(top) * CFrame.Angles(0, hash(x, z, 61) * math.pi, 0)
						local len0 = 3 + hash(z, x, 62) * 3
						local col = FLOW:Lerp(Color3.fromRGB(236, 176, 110), 0.45)
						local sheet
						for t = -2, 2 do -- a ribbon of flowstone folded in a tight zigzag, its hem stepping down on a diagonal, banded like cave bacon (Gemini: boards read as lumber)
							local sl = len0 * (0.45 + 0.14 * (t + 2)) + hash(x + t, z, 63) * 0.6
							local sp = deco("Curtain", Vector3.new(1.45, sl, 0.95), cfb * CFrame.new(t * 0.85, -sl / 2, t % 2 == 0 and 0.3 or -0.3) * CFrame.Angles(0, t % 2 == 0 and 0.62 or -0.62, 0), t % 2 == 0 and col or col:Lerp(Color3.fromRGB(150, 70, 50), 0.3), NOCOL)
							if t == 0 then sheet = sp end
						end
						if hash(x, z, 64) > 0.85 then
							local cl = Instance.new("PointLight")
							cl.Color, cl.Range, cl.Brightness, cl.Shadows = Color3.fromRGB(255, 190, 120), 9, 0.45, false
							cl.Parent = sheet
						end
					elseif room >= 4 and (fis and hsh > 0.62 or hsh > 0.99) then -- a dripstone, one of three kinds (Gemini r2: every stalactite was the same two-tier block); chained along the cracks (directive v14)
						local kind = math.floor(hash(x, z, 51) * 3)
						local len = 2 + hash(z, x, 5) * 5
						local col = ROCK2:Lerp(FLOW, hash(x, z, 52) * 0.4)
						local turn = CFrame.Angles(0, hash(x, z, 53) * 3, 0)
						if kind == 0 then -- a wide cone: three shrinking blocks, no tip colour
							for t = 0, 2 do
								local w2 = 2.8 - t * 0.85
								deco("Stalactite", Vector3.new(w2, len / 3 + 0.3, w2), CFrame.new(top - Vector3.new(0, len / 6 + t * len / 3, 0)) * turn, col, NOCOL)
							end
						elseif kind == 1 then -- twins of different lengths, each a two-step taper (directive v14: no pale dowel tips)
							for t = 0, 1 do
								local l2 = len * (t == 0 and 1 or 0.6)
								local at = top + Vector3.new(t * 1.8 - 0.9, 0, (t - 0.5) * 0.9)
								deco("Stalactite", Vector3.new(2, l2 * 0.55, 2), CFrame.new(at - Vector3.new(0, l2 * 0.275, 0)) * turn, col, NOCOL)
								deco("Stalactite", Vector3.new(1.1, l2 * 0.5, 1.1), CFrame.new(at - Vector3.new(0, l2 * 0.75 - 0.1, 0)) * turn * CFrame.Angles(0, 0.785, 0), col:Lerp(FLOW, 0.25), NOCOL)
							end
						else -- a long tooth: three shrinking steps, each turned a little
							for t = 0, 2 do
								local w2, seg = 2.4 - t * 0.75, len / 3 + 0.4
								deco("Stalactite", Vector3.new(w2, seg, w2), CFrame.new(top - Vector3.new(0, seg / 2 + t * (seg - 0.4), 0)) * turn * CFrame.Angles(0, t * 0.6, 0), col:Lerp(FLOW, t * 0.12), NOCOL)
							end
						end
					elseif L == 3 and room >= 5 and hsh > 0.7 and hsh < 0.74 then -- starlight druses: tiny crystals twinkling high in the vaults
						local dr = deco("Druse", Vector3.new(0.5, 0.9, 0.5), CFrame.new(top - Vector3.new(0, 0.45, 0)) * CFrame.Angles(0.3, hsh * 9, 0.2), Color3.fromRGB(147, 197, 253), { Material = Enum.Material.Neon, MaterialVariant = "", CanCollide = false, CanQuery = false, CastShadow = false })
						if hash(x, z, 77) > 0.5 then
							local dl = Instance.new("PointLight")
							dl.Color, dl.Range, dl.Brightness, dl.Shadows = Color3.fromRGB(147, 197, 253), 6, 0.25, false
							dl.Parent = dr
						end
					elseif room >= 4 and hsh > 0.74 and hsh < 0.76 then -- a dim glow seeping from a crack in the roof (Gemini v14p2_r3: moss tufts
						-- and drips read as ceiling fixtures and pendant lamps): only the light, from a hidden point in the rock
						local m = deco("RoofGlow", Vector3.new(0.4, 0.4, 0.4), CFrame.new(top + Vector3.new(0, 0.3, 0)), GLOW, { Transparency = 1, CanCollide = false, CanQuery = false, CastShadow = false })
						local l = Instance.new("PointLight")
						l.Color, l.Range, l.Brightness, l.Shadows = GLOW, 16, 0.7, false
						l.Parent = m
					elseif L == 1 and room >= 5 and hsh > 0.7 and hsh < 0.74 and (x - CX) * V < 60 then -- a hanging root (layer 1: the tree is above)
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
				elseif v == 1 and get(x, y - 1, z) == 0 and not inCamp(x, z) then -- a floor voxel (none in the live camp: its own props stand there)
					local hsh = hash(z, x, y + 11)
					local foot = toWorld(x, y, z) - Vector3.new(0, V / 2, 0)
					local head = 0
					while head < 8 and get(x, y + head, z) == 1 do head += 1 end
					local roomy = get(x + 2, y, z) == 1 and get(x - 2, y, z) == 1 and get(x, y, z + 2) == 1 and get(x, y, z - 2) == 1
					local skirtD -- directive v14: the wall beside this floor cell (talus and flowstone keep to the wall foot, the lanes stay clear)
					for _, dd in DIRS do if get(x + dd[1], y, z + dd[2]) == 0 and get(x + dd[1], y + 1, z + dd[2]) == 0 then skirtD = dd break end end
					local fis = math.abs(math.noise((x - CX + 0.5) * V / 22, (z - CZ + 0.5) * V / 22, seed * 0.13 + 0.5)) < 0.09
					if head <= 3 and hsh > 0.93 and roomy then -- a column: floor to roof where they nearly meet, only in an open room (never plugging a crawl)
						local hgt, rot = head * V, CFrame.Angles(0, hsh * 3, 0) -- directive v14: flared at floor and roof, not a square post
						deco("Column", Vector3.new(2.4, hgt, 2.4), CFrame.new(foot + Vector3.new(0, hgt / 2, 0)) * rot, ROCK3, { CastShadow = true })
						for q, e in { { 4.8, 0.7 }, { 3.6, 2.0 }, { 4.8, hgt - 0.7 }, { 3.6, hgt - 2.0 } } do
							deco("ColumnFoot", Vector3.new(e[1], 1.4, e[1]), CFrame.new(foot + Vector3.new(0, e[2], 0)) * rot * CFrame.Angles(0, q % 2 == 0 and 0.785 or 0, 0), q % 2 == 0 and ROCK2:Lerp(ROCK3, 0.5) or ROCK2, {})
						end
					elseif head >= 3 and (fis and skirtD and hsh > 0.65 or hsh > 0.96) then -- a stalagmite under the drip (under the cracks, by the wall: directive v14)
						local hgt = 1.6 + hash(x, z, 12) * 3.4
						for t = 0, 2 do -- three shrinking steps (directive v14: no pale cube on top)
							local w2, seg = 3 - t * 0.85, hgt / 3 + 0.3
							deco("Stalagmite", Vector3.new(w2, seg, w2), CFrame.new(foot + Vector3.new(0, seg / 2 + t * (seg - 0.3), 0)) * CFrame.Angles(0, t * 0.5 + hsh * 3, 0), ROCK2:Lerp(FLOW, t * 0.12), t == 0 and { CanCollide = roomy, CanQuery = roomy } or NOCOL)
						end
					elseif head >= 2 and hsh > 0.8 and hsh < (L == 4 and 0.835 or 0.815) then -- lichen flecks (in Muspell: glowing cracks, more of them) low on the rock: faint teal light so no stretch is a dead zone (Gemini r3)
						local lf = deco("Lichen", Vector3.new(0.6, 0.2, 0.45), CFrame.new(foot + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, hsh * 20, 0), GLOW, { Material = Enum.Material.Neon, MaterialVariant = "", CanCollide = false, CanQuery = false, CastShadow = false })
						for q = 1, 2 do deco("Lichen", Vector3.new(0.35, 0.16, 0.3), CFrame.new(foot + Vector3.new(math.cos(q * 2.4 + hsh * 9) * 0.8, 0.08, math.sin(q * 2.4 + hsh * 9) * 0.8)), GLOW:Lerp(ROCK2, 0.3), { Material = Enum.Material.Neon, MaterialVariant = "", CanCollide = false, CanQuery = false, CastShadow = false }) end -- a scatter of flecks, not one arcade button (Gemini v14p2)
						local ll = Instance.new("PointLight")
						ll.Color, ll.Range, ll.Brightness, ll.Shadows = GLOW, 8, 0.35, false
						ll.Parent = lf
					elseif head >= 3 and roomy and not skirtD and hsh > 0.88 and hsh < 0.92 then -- directive v14 (Gemini: dead-flat floors): a low stepped sediment shelf, two worn plates
						local s = 3 + hash(x, z, 91) * 3
						local fc = colorOf(100 + TI[themeAt(Vector3.new((x - CX + 0.5) * V, (y - CY + 0.5) * V, (z - CZ + 0.5) * V))] * 10 + 1):Lerp(Color3.new(0, 0, 0), 0.12)
						deco("SedimentSlab", Vector3.new(s, 0.5, s * 0.8), CFrame.new(foot + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, hsh * 9, 0), fc, {})
						deco("SedimentSlab", Vector3.new(s * 0.6, 0.4, s * 0.5), CFrame.new(foot + Vector3.new(0.4, 0.62, 0.3)) * CFrame.Angles(0, hsh * 13, 0), fc:Lerp(Color3.new(1, 1, 1), 0.08), {})
					elseif head >= 2 and skirtD and hsh > 0.93 then -- directive v14 (Recipe A3/F): breakdown talus, angular blocks stacked against the wall's foot
						local into = Vector3.new(skirtD[1], 0, skirtD[2])
						for q = 0, 1 + math.floor(hash(x, z, 71) * 2) - 1 do
							local s = (2.6 + hash(x, z, 72 + q) * 1.6) * (1 - q * 0.3)
							local at = foot + into * (V / 2 - s * 0.35) + Vector3.new((hash(z, x, 73 + q) - 0.5) * 1.6, s * 0.32 + q * s * 0.55, (hash(x, q, 74) - 0.5) * 1.6)
							deco("Talus", Vector3.new(s, s * 0.62, s * 0.85), CFrame.new(at) * CFrame.Angles(hash(x, z, 75 + q) * 0.5, hash(z, x, 76 + q) * 3, hash(q, x, z) * 0.35), q == 0 and ROCK3 or ROCK2, NOCOL)
						end
					elseif head >= 2 and hsh > 0.93 and roomy then -- a fallen boulder (breakdown), tilted
						local s = 2 + hash(x, z, 13) * 2.6
						deco("Boulder", Vector3.new(s, s * 0.7, s * 0.9), CFrame.new(foot + Vector3.new(0, s * 0.3, 0)) * CFrame.Angles(hash(x, z, 14) * 0.6, hash(z, x, 15) * 3, 0), ROCK3, { CanCollide = roomy, CanQuery = roomy })
					end
				end
			end
		end
	end
	-- RIMSTONE (directive v14, Recipe E): on layers 2 and 3 a short run of travertine dams steps down a gentle floor, each holding a
	-- shallow glowing pool. Decor only (no collision): the floor under them stays the walk
	local function rimstone(sp, n)
		if not sp then return end
		local raw = sp - Vector3.new(0, dipY(sp.X), 0)
		local f0 = floorUnder(raw)
		if not f0 then return end
		local dir
		for i = 0, 7 do
			local d = Vector3.new(math.cos(i * math.pi / 4), 0, math.sin(i * math.pi / 4))
			local f1 = floorUnder(raw + d * 16)
			if f1 and math.abs(f1.Y - f0.Y) <= 4.5 then dir = d break end
		end
		if not dir then return end
		local side = Vector3.new(-dir.Z, 0, dir.X)
		local tint = ({ PAL.flow, Color3.fromRGB(214, 160, 120), Color3.fromRGB(200, 214, 255), Color3.fromRGB(120, 90, 84) })[L]
		local pool = L == 2 and Color3.fromRGB(255, 176, 96) or GLOW
		for t = 0, n - 1 do
			local c = f0 + dir * (t * 5.4)
			local top, R = (n - t) * 1.1, 3.4 - t * 0.25
			for q = 0, 2 do -- the basin: three turned blocks make a rounded body (Gemini v14p2_r2: one box read as a water trough)
				deco("RimBasin", Vector3.new(R * 1.75, top - q * 0.05, R * 1.45), CFrame.lookAt(c + Vector3.new(0, top / 2, 0), c + Vector3.new(0, top / 2, 0) + dir) * CFrame.Angles(0, q * math.pi / 6, 0), tint:Lerp(ROCK2, 0.3 + q * 0.05), NOCOL)
			end
			local pl = deco("RimPool", Vector3.new(R * 1.75, 0.2, R * 1.45), CFrame.lookAt(c + Vector3.new(0, top + 0.15, 0), c + Vector3.new(0, top + 0.15, 0) + dir), pool, { Material = Enum.Material.Glass, MaterialVariant = "", Transparency = 0.3, CanCollide = false, CanQuery = false, CastShadow = false })
			for q = -3, 3 do -- the dam: square blocks stepping round the downhill edge in the voxel grain (Gemini v14p2: a smooth curb clashed)
				local out = dir * math.cos(q * 0.36) + side * math.sin(q * 0.36)
				local lp = c + out * R * (0.8 + hash(t, q, 84) * 0.14) + Vector3.new(0, top + 0.2 + hash(q, t, 85) * 0.35, 0)
				deco("RimLip", Vector3.new(1.2 + hash(t, q, 86) * 0.6, 0.8 + hash(q, t, 87) * 0.5, 1.3), CFrame.lookAt(lp, lp + out) * CFrame.Angles(0, (hash(t, q, 88) - 0.5) * 0.5, 0), (q % 2 == 0) and tint:Lerp(Color3.new(1, 1, 1), 0.2) or tint, NOCOL) -- staggered travertine, not dressed ashlar
			end
			if t == 0 then
				local gl = Instance.new("PointLight")
				gl.Color, gl.Range, gl.Brightness, gl.Shadows = pool, 14, 0.7, false
				gl.Parent = pl
			end
		end
	end
	if L == 2 then rimstone(spots.B2, 3) rimstone(spots.Cathedral, 4)
	elseif L == 3 then rimstone(spots.B2, 3) rimstone(spots.B3, 2) end
	-- water: the stream slot and the pools carry a sheet of glassy water on top
	local nWater = 0
	for x = 0, NX - 1 do
		for z = 0, NZ - 1 do
			for y = 0, NY - 2 do
				if get(x, y, z) == 2 and get(x, y + 1, z) ~= 2 then
					local hot = L == 4 -- in Muspell the streams and pools are lava (no swimming: it is only a glow on the floor of the slot)
					local w = part("V2Water", hot and "LavaFlow" or "StreamWater", Vector3.new(V, 0.6, V), CFrame.new(toWorld(x, y, z) + Vector3.new(0, V / 2 - 1.2, 0)), hot and Color3.fromRGB(255, 96, 36) or PAL.water, hot and { Material = Enum.Material.Neon, MaterialVariant = "", CanCollide = false, CastShadow = false } or { Material = Enum.Material.Glass, MaterialVariant = "", Transparency = 0.35, CanCollide = false, CastShadow = false })
					if hot and hash(x, z, 5) > 0.82 then
						local hl = Instance.new("PointLight")
						hl.Color, hl.Range, hl.Brightness, hl.Shadows = Color3.fromRGB(255, 110, 50), 18, 0.8, false
						hl.Parent = w
					end
					nWater += 1
					w.Reflectance = 0.1
				end
			end
		end
	end
	-- LIGHT: warm lanterns along the main route only (the branches stay dark: your torch), the camp fire, a cool shaft of light on the root
	local function lantern(p, color, range, b)
		local post = part("Lights", "LanternPost", Vector3.new(0.6, 5, 0.6), CFrame.new(p + Vector3.new(0, 2.5, 0)), PAL.barkDark, { Material = Enum.Material.Wood, MaterialVariant = "" })
		-- a caged lantern, not a bare neon block: up close the 1.2-stud neon cube blew out to a flat yellow slab (Gemini full1120v/w)
		local lamp = part("Lights", "Lantern", Vector3.new(0.55, 0.8, 0.55), CFrame.new(p + Vector3.new(0, 5.4, 0)), color:Lerp(Color3.new(0, 0, 0), 0.2), { Material = Enum.Material.Neon, MaterialVariant = "", CanCollide = false })
		local IRON = Color3.fromRGB(44, 38, 52)
		for _, y in { 0.78, -0.78 } do part("Lights", "LanternCap", Vector3.new(1.3, 0.22, 1.3), CFrame.new(p + Vector3.new(0, 5.4 + y, 0)), IRON, { Material = Enum.Material.Metal, MaterialVariant = "", CanCollide = false }) end
		for _, c in { { 0.55, 0.55 }, { -0.55, 0.55 }, { 0.55, -0.55 }, { -0.55, -0.55 } } do part("Lights", "LanternBar", Vector3.new(0.12, 1.34, 0.12), CFrame.new(p + Vector3.new(c[1], 5.4, c[2])), IRON, { Material = Enum.Material.Metal, MaterialVariant = "", CanCollide = false }) end
		part("Lights", "LanternGlass", Vector3.new(1.0, 1.3, 1.0), CFrame.new(p + Vector3.new(0, 5.4, 0)), color:Lerp(Color3.fromRGB(255, 240, 210), 0.3), { Material = Enum.Material.Glass, MaterialVariant = "", Transparency = 0.6, CanCollide = false, CastShadow = false })
		local l = Instance.new("PointLight")
		l.Color, l.Range, l.Brightness, l.Shadows = color, range, b or 0.45, true
		l.Parent = lamp
		return post
	end
	for _, p in { P(-20, 6, -6), P(20, 6, 6), P(52, 0, 10), P(100, -4, 4), P(120, 4, -12), P(60, 22, -88), P(-60, 24, -92), P(130, -10, 44) } do
		local at = floorUnder(p)
		if at and L ~= 3 and not (opt.camp and (at - origin).Magnitude < 52) then lantern(at, PAL.warm, 34, 0.42) end -- layer 3 has no lamps past camp: the crystals light it
	end
	do
		local fire = not opt.camp and floorUnder(P(0, 6, 0))
		if fire then
			local f = part("Lights", "CampFire", Vector3.new(3, 1.2, 3), CFrame.new(fire + Vector3.new(0, 0.6, 0)), Color3.fromRGB(255, 150, 70), { Material = Enum.Material.Neon, MaterialVariant = "" })
			do local okPF, PF = pcall(require, game:GetService("ReplicatedStorage"):WaitForChild("Shared"):FindFirstChild("PixelFire")) if okPF then PF.attach(f, Color3.fromRGB(255, 200, 100), Color3.fromRGB(240, 90, 40), 3) end end -- chunky pixel flames (Shared.PixelFire)
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
			for k = 1, (L == 1 and 3 or 0) do -- glowing pads on layer 1's pool only (clay, ice and lava pools have none)
				local pad = part("V2Water", "LilyGlow", Vector3.new(2.4, 0.2, 2.4), w.CFrame * CFrame.new((k - 2) * 6, 0.3, (hash(k, 3, 1) - 0.5) * 8), PAL.mint, { Material = Enum.Material.Neon, MaterialVariant = "", Shape = Enum.PartType.Cylinder, CanCollide = false })
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
	-- MOSS, the lost apprentice (plan section 5, layer 1 only): sits at the bottom of the Swallow Hole by the rope he could not climb. A chunky
	-- voxel miner in a butter helmet with a lamp, a moss-green scarf and a satchel. His head is "MossHead": GloomClient gives him a
	-- speech bubble like Wick's. The rope ladder beside him climbs the shaft back to the crawl (a TrussPart: the shortcut up).
	if L == 1 then
		local foot = floorUnder(P(-72, -24, 50))
		if foot then
			local base = CFrame.lookAt(foot, foot + Vector3.new(1, 0, -0.3))
			local SKIN, HELM, SCARF, COAT, DARK = Color3.fromRGB(240, 200, 170), Color3.fromRGB(255, 210, 90), Color3.fromRGB(110, 190, 120), Color3.fromRGB(150, 110, 180), Color3.fromRGB(50, 32, 60)
			local function mp(n, size, cf, col, props) return part("Moss", n, size, base * cf, col, props) end
			mp("MossLegs", Vector3.new(1.6, 1, 1.4), CFrame.new(0, 0.5, 0), DARK)
			mp("MossBody", Vector3.new(2, 1.8, 1.6), CFrame.new(0, 1.9, 0), COAT)
			mp("MossScarf", Vector3.new(2.1, 0.5, 1.7), CFrame.new(0, 2.7, 0), SCARF)
			local head = mp("MossHead", Vector3.new(1.8, 1.7, 1.7), CFrame.new(0, 3.75, 0), SKIN)
			mp("MossHelmet", Vector3.new(2, 0.8, 1.9), CFrame.new(0, 4.75, 0.05), HELM)
			local lamp = mp("MossLamp", Vector3.new(0.6, 0.6, 0.3), CFrame.new(0, 4.75, -1.05), Color3.fromRGB(255, 240, 180), { Material = Enum.Material.Neon, MaterialVariant = "", CanCollide = false })
			local ll = Instance.new("SpotLight")
			ll.Color, ll.Range, ll.Brightness, ll.Angle, ll.Face, ll.Shadows = Color3.fromRGB(255, 220, 150), 18, 0.9, 50, Enum.NormalId.Front, true
			ll.Parent = lamp
			for _, x in { -0.4, 0.4 } do mp("MossEye", Vector3.new(0.28, 0.4, 0.1), CFrame.new(x, 3.85, -0.86), DARK, { CanCollide = false }) end
			mp("MossSatchel", Vector3.new(0.9, 1, 0.6), CFrame.new(1.25, 1.8, 0.2), Color3.fromRGB(170, 110, 70))
			mp("MossLantern", Vector3.new(0.7, 0.9, 0.7), CFrame.new(-1.6, 0.45, -0.6), Color3.fromRGB(255, 190, 110), { Material = Enum.Material.Neon, MaterialVariant = "", CanCollide = false })
			head:SetAttribute("Npc", "Moss")
			local pr = Instance.new("ProximityPrompt") -- PixelServer pays the first find (s.found.moss)
			pr.ActionText, pr.ObjectText, pr.KeyboardKeyCode, pr.HoldDuration, pr.MaxActivationDistance = "Help up", "Moss", Enum.KeyCode.E, 0.4, 9
			pr:SetAttribute("FindMoss", true)
			pr.Parent = head
			local rope = Instance.new("TrussPart") -- the rope ladder up the Swallow Hole: climb it to get back
			local sx, sz = (-70 + 2.6), 48 + 2.6
			local bottom = floorUnder(P(sx, -24, sz)) or foot
			local h = 30
			rope.Name, rope.Anchored, rope.Size, rope.Color, rope.Material = "RopeLadder", true, Vector3.new(2, h, 2), Color3.fromRGB(196, 160, 110), Enum.Material.Fabric
			rope.CFrame = CFrame.new(bottom + Vector3.new(0, h / 2, 0))
			rope.Parent = group("Moss")
		end
	end
	if L >= 3 and not opt.camp and not opt.hall then -- directive v14 phase 4: CREW RIDE at Camps 3 and 4, a parked crew cart on a
		-- siding by the camp (the Kiln Camp's look); PixelServer signs every "CampCartBody" and its V prompt boards the shared crew
		local f = floorUnder(Vector3.new(14, 0, 9))
		if f then
			local cart = CFrame.new(f) * CFrame.Angles(0, math.pi / 2, 0)
			local IRONC, OAKC = Color3.fromRGB(62, 56, 78), Color3.fromRGB(128, 86, 54)
			local MET, WOOD = { Material = Enum.Material.Metal, MaterialVariant = "", CanCollide = false }, { Material = Enum.Material.Wood, MaterialVariant = "", CanCollide = false }
			for _, x in { -0.9, 0.9 } do part("Camp", "CampRail", Vector3.new(0.25, 0.2, 7.5), cart * CFrame.new(x, 0.1, 0), IRONC, MET) end
			for z = -3, 3, 1.5 do part("Camp", "CampSleeper", Vector3.new(2.8, 0.14, 0.6), cart * CFrame.new(0, 0.03, z), PAL.barkDark, WOOD) end
			for _, w in { { -1.2, -1.1 }, { 1.2, -1.1 }, { -1.2, 1.1 }, { 1.2, 1.1 } } do
				part("Camp", "CampWheel", Vector3.new(0.3, 0.9, 0.9), cart * CFrame.new(w[1], 0.62, w[2]), IRONC, { Shape = Enum.PartType.Cylinder, Material = Enum.Material.Metal, MaterialVariant = "", CanCollide = false })
			end
			part("Camp", "CampCartBody", Vector3.new(3, 1.8, 3.6), cart * CFrame.new(0, 1.97, 0), OAKC, { Material = Enum.Material.WoodPlanks, MaterialVariant = "" })
			part("Camp", "CampCartRim", Vector3.new(3.2, 0.25, 3.8), cart * CFrame.new(0, 2.93, 0), IRONC, MET)
			part("Camp", "CampCartOre", Vector3.new(2.2, 0.5, 2.6), cart * CFrame.new(0, 2.9, 0), GLOW:Lerp(Color3.new(1, 1, 1), 0.3), { Material = Enum.Material.Neon, MaterialVariant = "", CanCollide = false })
			for _, z in { -3.9, 3.9 } do part("Camp", "CampBuffer", Vector3.new(2.6, 0.9, 0.5), cart * CFrame.new(0, 0.75, z), PAL.barkDark, { Material = Enum.Material.Wood, MaterialVariant = "" }) end
			nDecor += 17
		end
	end
	-- FIREFLIES over the cathedral, the canyon and the glow pool: slow warm specks (plan: critters)
	for _, at in { spots.Cathedral + P(0, 10, 0), spots.Canyon + P(0, 8, 0), spots.B2 + P(0, 5, 0) } do
		local holder = part("Lights", "Fireflies", Vector3.new(24, 8, 24), CFrame.new(origin + at), PAL.mint, { Transparency = 1, CanCollide = false, CanQuery = false })
		local e = Instance.new("ParticleEmitter")
		e.Texture, e.Color, e.LightEmission = "rbxasset://textures/particles/sparkles_main.dds", ColorSequence.new(Color3.fromRGB(255, 230, 140)), 1
		e.Size, e.Transparency = NumberSequence.new(0.25, 0.1), NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.1), NumberSequenceKeypoint.new(1, 1) })
		e.Rate, e.Lifetime, e.Speed, e.SpreadAngle = 6, NumberRange.new(3, 5), NumberRange.new(0.3, 0.8), Vector2.new(180, 180)
		e.Acceleration, e.Shape, e.ShapeStyle = Vector3.new(0, 0.15, 0), Enum.ParticleEmitterShape.Box, Enum.ParticleEmitterShapeStyle.Volume
		e.Parent = holder
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
	for _, ch in chosen do -- the deposits, built into the niches chosen before the mesh
		local c, idx2, w = ch.c, ch.idx2, ch.w
		do
			do
				nDep += 1
				local ore = ORES[idx2]
				local dep = Instance.new("Model")
				dep.Name = "Deposit"
				dep:SetAttribute("Layer", L)
				dep:SetAttribute("Ore", idx2)
				dep:SetAttribute("OreName", ore[1])
				local wall = Vector3.new(c[4][1], 0, c[4][2])
				local foot = w + wall * ((c.niche and V or 0) + V / 2 - 0.9) -- at the back of its niche (directive v14)
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
	local walls = {} -- free wall spots for other builders (CaveBuilder's shrines, nests, altar), best first: dead ends, branches, the rest
	for _, c in cands do
		local w = toWorld(c[1], c[2], c[3]) - Vector3.new(0, V / 2, 0)
		if not c.niche and (w - campW).Magnitude > (opt.camp and 58 or 40) then table.insert(walls, { pos = w, dir = Vector3.new(c[4][1], 0, c[4][2]) }) end
	end
	model.Parent = parent
	model:SetAttribute("ZFixed", require(game:GetService("ServerScriptService"):WaitForChild("ZFix")).fix(model)) -- no z-fighting (the user, 2026-11-08)
	return model, { walls = walls }
end

-- Layer tint for the shared prop set (CaveProps makes cyan crystals for every cave): call after CaveProps.build on a layer 2+ model.
-- directive v13 phase 7 (vault Research/Roblox Engine/First-Person Feel, Mobile Touch and Cross-Tier Lighting, section 4):
-- the streaming foundation. M.chunk(caves, size) moves the rock and floor blocks of the Walls and Floor folders into Models of
-- one size x size stud cell each (attribute CaveChunk), ModelStreamingMode Atomic, so with StreamingEnabled a room streams in
-- whole and a phone never shows half a cave wall. PixelServer runs it only when workspace.StreamingEnabled is on (it is off
-- today); ZFix and the other readers find a block through its folder either way. Returns the number of chunks made.
function M.chunk(caves, size)
	size = size or 64
	local made = 0
	for _, fname in { "Walls", "Floor" } do
		for _, folder in caves:GetDescendants() do
			if folder.Name == fname and folder:IsA("Folder") then
				local cells = {}
				for _, p in folder:GetChildren() do
					if p:IsA("BasePart") then
						local k = math.floor(p.Position.X / size) .. "_" .. math.floor(p.Position.Z / size)
						local m = cells[k]
						if not m then
							m = Instance.new("Model")
							m.Name = "Chunk_" .. k
							m:SetAttribute("CaveChunk", true)
							pcall(function() m.ModelStreamingMode = Enum.ModelStreamingMode.Atomic end)
							m.Parent = folder
							cells[k] = m
							made += 1
						end
						p.Parent = m
					end
				end
			end
		end
	end
	return made
end

function M.tintProps(model, layer, near, radius) -- near, radius: only props within radius studs of near (the live caves hold two layers)
	local TO = ({ nil, Color3.fromRGB(245, 158, 11), Color3.fromRGB(150, 140, 255), Color3.fromRGB(255, 110, 50) })[layer]
	local props = model:FindFirstChild("Props")
	if not TO or not props then return 0 end
	local n = 0
	for _, d in props:GetDescendants() do
		local far = near and d:IsA("BasePart") and (d.Position - near).Magnitude > radius
		if far then continue end
		if d:IsA("BasePart") and d.Material == Enum.Material.Glass then -- the crystal's clear shell: amber seen through cyan glass came out green
			local h, sat = d.Color:ToHSV()
			if h > 0.42 and h < 0.58 and sat > 0.4 then d.Color = TO:Lerp(Color3.new(1, 1, 1), 0.25) end
		elseif d:IsA("BasePart") and d.Material == Enum.Material.Neon and not (d:IsA("MeshPart") and d.TextureID ~= "") then
			local h, sat = d.Color:ToHSV()
			local mesh = d:FindFirstChildOfClass("SpecialMesh")
			local vc = mesh and mesh.VertexColor
			local cyanMesh = vc and vc.Y > 0.6 and vc.Z > 0.6 and vc.X < 0.5
			if (h > 0.42 and h < 0.58 and sat > 0.4) or cyanMesh then -- cyan crystals take the layer's glow
				d.Color = TO
				if mesh then mesh.VertexColor = Vector3.one end -- the mesh's own cyan multiplies the colour: amber x cyan came out green
				n += 1
			end
		elseif d:IsA("PointLight") then
			local h = d.Color:ToHSV()
			if h > 0.42 and h < 0.58 then d.Color = TO end
		end
	end
	return n
end

return M
