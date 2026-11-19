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
	local function set(x, y, z, v) if inside(x, y, z) then buffer.writeu8(grid, idx(x, y, z), v) end end
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
	if opt.camp then
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
	passage({ P(-34, 2, -4), J(P(-60, 2, -14)), J(P(-84, 3, -22)) }, 5, 5, { flat = 0.6 })
	local b1 = J(P(-98, 4, -26)) chamber(b1, 12, 7, 9) passage({ b1, J(P(-120, 14, -60)), P(-130, 22, -84) }, 5, 5, { flat = 0.7 }) spot("B1", b1)
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
	passage({ P(-34, 2, -4), J(P(-60, 2, -14)), J(P(-84, 3, -22)) }, 4.2, 5, { flat = 0.6 })
	local b1 = J(P(-98, 4, -26)) chamber(b1, 12, 8, 9) passage({ b1, J(P(-120, 14, -60)), P(-130, 24, -84) }, 4.2, 5, { flat = 0.8 }) spot("B1", b1)
	local b2 = J(P(-92, -4, 18)) passage({ J(P(-66, 2, -8)), b2 }, 4.2, 5, { flat = 0.8 }) chamber(b2, 13, 9, 11, { floor = 0.55 }) spot("B2", b2)
	local b3 = J(P(-112, -6, 52)) passage({ b2, b3 }, 4.2, 5, { flat = 0.8 }) chamber(b3, 11, 9, 10) spot("B3", b3)
	local b4 = J(P(200, 12, -22)) passage({ P(176, 10, -4), b4 }, 4.2, 7, { flat = 0.6 }) chamber(b4, 7, 10, 6) spot("B4", b4)
	local b5 = J(P(176, 0, 58)) passage({ P(152, 2, 24), J(P(164, 2, 42)), b5 }, 4.2, 5, { flat = 0.8 }) chamber(b5, 8, 7, 7) spot("B5", b5)
	else
	-- LAYER 2, TITAN'S REST (plan sections 3 to 6): clay country. Wide, low bedding-plane galleries (old floods spread sideways
	-- between soft clay beds), the Titan's Hall (a huge collapse chamber where a stone giant lies asleep), an upper gallery, a clay
	-- pool, a lower gallery back under the hall and a footprint drop; the same five branch slots as layer 1.
	passage({ P(36, 2, 0), P(70, 0, 12), P(104, -2, 6), P(118, -2, 2) }, 16, 5, { flat = 0.8 }) -- the bedding plane east: wide, low, flat
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
	passage({ P(-34, 2, -4), J(P(-62, 2, -16)), J(P(-86, 3, -24)) }, 5, 4, { flat = 0.9 })
	local b1 = J(P(-100, 4, -28)) chamber(b1, 14, 6, 10) passage({ b1, J(P(-118, 12, -58)), P(-130, 20, -82) }, 5, 4, { flat = 0.85 }) spot("B1", b1)
	local b2 = J(P(-94, -4, 20)) passage({ J(P(-68, 2, -10)), b2 }, 5, 4, { flat = 0.9 }) chamber(b2, 16, 7, 12, { floor = 0.55 }) spot("B2", b2)
	local b3 = J(P(-114, -6, 54)) passage({ b2, b3 }, 5, 4, { flat = 0.85 }) chamber(b3, 12, 7, 10) spot("B3", b3)
	local b4 = J(P(214, 12, -22)) passage({ P(190, 8, -4), b4 }, 5, 6, { flat = 0.6 }) chamber(b4, 7, 8, 6) spot("B4", b4)
	local b5 = J(P(180, 0, 62)) passage({ P(160, 2, 28), J(P(170, 2, 46)), b5 }, 5, 4, { flat = 0.9 }) chamber(b5, 9, 5, 8) spot("B5", b5)
	end
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
	local WALL0 = nil
	local WALL = L == 4 and { Color3.fromRGB(26, 18, 20), Color3.fromRGB(42, 28, 30), Color3.fromRGB(62, 40, 40), Color3.fromRGB(88, 52, 48) } -- layer 4: basalt, warmer where the glow reaches
		or L == 3 and { Color3.fromRGB(20, 22, 48), Color3.fromRGB(32, 36, 72), Color3.fromRGB(48, 54, 100), Color3.fromRGB(70, 76, 132) } -- layer 3: night-blue granite
		or L == 2 and { Color3.fromRGB(62, 30, 22), Color3.fromRGB(104, 54, 42), Color3.fromRGB(140, 80, 62), Color3.fromRGB(170, 108, 82) } -- the damp foot of the walls darker (Gemini l2r1) -- layer 2: fired clay, darker low, sun-baked high
		or { Color3.fromRGB(40, 26, 54), Color3.fromRGB(61, 41, 82), Color3.fromRGB(86, 61, 112), Color3.fromRGB(110, 84, 140) } -- deep amethyst slate to soft lavender granite (Gemini r1 palette, a step lighter at the top)
	local function colorOf(k)
		if k == 99 then return Color3.fromRGB(45, 26, 56) end
		if k < 100 then return WALL[k] end
		local th = THEMES[math.floor((k - 100) / 10)]
		local v = k % 10
		local f = FLOOR[th]
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
						p.Material = Enum.Material.Pebble -- packed grit: the floor reads apart from the smooth slate walls (Ground rendered olive: the owner, 2026-11-17, no green floors)
						p.Color = p.Color:Lerp(({ Color3.fromRGB(160, 120, 132), Color3.fromRGB(160, 120, 132), Color3.fromRGB(150, 160, 210), Color3.fromRGB(110, 84, 80) })[L], 0.35) -- grit in the layer's own light
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
		end
	end

	if L == 4 then -- THE MAGMA LAKE under the hall's floor edge and basalt columns round it: hexagon-ish stacks, lit from below
		local vx, vy, vz = toVox(rootC)
		local lake = part("Landmark", "MagmaLake", Vector3.new(60, 1, 44), CFrame.new(origin + rootC + P(0, -6, 0)), Color3.fromRGB(255, 96, 40), { Material = Enum.Material.Neon, MaterialVariant = "", CanCollide = false, CastShadow = false })
		local ll = Instance.new("PointLight")
		ll.Color, ll.Range, ll.Brightness, ll.Shadows = Color3.fromRGB(255, 110, 50), 60, 1.2, false
		ll.Parent = lake
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
						if get(nx, y, nz) == 0 and isAir(get(nx, y + 1, nz)) and isAir(get(nx, y + 2, nz)) then -- every one-voxel step, also in one-wide crawls (walk test 2026-11-19)
							local c = toWorld(x, y, z)
							local look = Vector3.new(-dd[1], 0, -dd[2]) -- a WedgePart rises toward its -Z: face it away from the step
							local w = Instance.new("WedgePart")
							w.Name, w.Anchored, w.Size = "Ramp", true, Vector3.new(V, V, V)
							w.CFrame = CFrame.lookAt(c, c + look)
							w.Color, w.Material = colorOf(100 + TI[themeAt(Vector3.new((x - CX + 0.5) * V, (y - CY + 0.5) * V, (z - CZ + 0.5) * V))] * 10 + 1):Lerp(({ Color3.fromRGB(160, 120, 132), Color3.fromRGB(160, 120, 132), Color3.fromRGB(150, 160, 210), Color3.fromRGB(110, 84, 80) })[L], 0.35), Enum.Material.Pebble -- the step is floor: the floor's own colour and grit
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
					if room >= 4 and hsh > 0.86 then -- a dripstone, one of three kinds (Gemini r2: every stalactite was the same two-tier block)
						local kind = math.floor(hash(x, z, 51) * 3)
						local len = 2 + hash(z, x, 5) * 5
						local col = ROCK2:Lerp(FLOW, hash(x, z, 52) * 0.4)
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
								deco("Stalactite", Vector3.new(0.7, 1, 0.7), CFrame.new(top + Vector3.new(t * 1.6 - 0.8, -l2 - 0.5, (t - 0.5) * 0.8)), FLOW, NOCOL)
							end
						else -- a single slender spike
							deco("Stalactite", Vector3.new(1.2, len, 1.2), CFrame.new(top - Vector3.new(0, len / 2, 0)) * turn, col, NOCOL)
							deco("Stalactite", Vector3.new(0.5, 1.4, 0.5), CFrame.new(top - Vector3.new(0, len + 0.7, 0)), FLOW, NOCOL)
						end
					elseif room >= 3 and hsh > 0.8 then -- soda straws: thin pale tubes in a cluster
						for s = 1, 3 do
							local l = 0.8 + hash(x + s, z, 6) * 2.2
							deco("Straw", Vector3.new(0.25, l, 0.25), CFrame.new(top + Vector3.new((hash(s, x, z) - 0.5) * 3, -l / 2, (hash(z, s, x) - 0.5) * 3)), FLOW, NOCOL)
						end
					elseif L == 3 and room >= 5 and hsh > 0.7 and hsh < 0.74 then -- starlight druses: tiny crystals twinkling high in the vaults
						local dr = deco("Druse", Vector3.new(0.5, 0.9, 0.5), CFrame.new(top - Vector3.new(0, 0.45, 0)) * CFrame.Angles(0.3, hsh * 9, 0.2), Color3.fromRGB(147, 197, 253), { Material = Enum.Material.Neon, MaterialVariant = "", CanCollide = false, CanQuery = false, CastShadow = false })
						if hash(x, z, 77) > 0.5 then
							local dl = Instance.new("PointLight")
							dl.Color, dl.Range, dl.Brightness, dl.Shadows = Color3.fromRGB(147, 197, 253), 6, 0.25, false
							dl.Parent = dr
						end
					elseif room >= 4 and hsh > 0.74 and hsh < 0.78 then -- glowing moss cushion
						local m = deco("CeilMoss", Vector3.new(2.4, 0.5, 2), CFrame.new(top - Vector3.new(0, 0.2, 0)), GLOW, { Material = Enum.Material.Neon, CanCollide = false, CanQuery = false, CastShadow = false })
						for q = 1, 3 do -- an irregular patch pressed to the rock, with a thin drip hanging from it
							local a = q * 2.1 + hsh * 6
							deco("CeilMoss", Vector3.new(1 + q * 0.3, 0.3, 0.9 + q * 0.2), CFrame.new(top + Vector3.new(math.cos(a) * 1.6, -0.15, math.sin(a) * 1.6)), GLOW:Lerp(PAL.moss[3], 0.4), { Material = Enum.Material.Neon, CanCollide = false, CanQuery = false, CastShadow = false })
						end
						deco("CeilMossDrip", Vector3.new(0.2, 1.2, 0.2), CFrame.new(top + Vector3.new(0.5, -0.8, 0.3)), GLOW, { Material = Enum.Material.Neon, CanCollide = false, CanQuery = false, CastShadow = false })
						if hash(z, x, 9) > 0.6 then
							local l = Instance.new("PointLight")
							l.Color, l.Range, l.Brightness, l.Shadows = GLOW, 18, 0.9, false
							l.Parent = m
						end
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
					if head <= 3 and hsh > 0.93 and roomy then -- a column: floor to roof where they nearly meet, only in an open room (never plugging a crawl)
						deco("Column", Vector3.new(3, head * V, 3), CFrame.new(foot + Vector3.new(0, head * V / 2, 0)), ROCK3, { CastShadow = true })
						deco("ColumnFoot", Vector3.new(4.4, 1.2, 4.4), CFrame.new(foot + Vector3.new(0, 0.6, 0)), FLOW:Lerp(ROCK2, 0.5), {})
					elseif head >= 3 and hsh > 0.9 then -- a stalagmite under the drip
						local hgt = 1.6 + hash(x, z, 12) * 3.4
						deco("Stalagmite", Vector3.new(2.4, hgt, 2.4), CFrame.new(foot + Vector3.new(0, hgt / 2, 0)), ROCK2, { CanCollide = roomy, CanQuery = roomy })
						deco("Stalagmite", Vector3.new(1.2, 1.4, 1.2), CFrame.new(foot + Vector3.new(0, hgt + 0.7, 0)), FLOW, { CanCollide = false })
					elseif head >= 2 and hsh > 0.8 and hsh < (L == 4 and 0.835 or 0.815) then -- lichen flecks (in Muspell: glowing cracks, more of them) low on the rock: faint teal light so no stretch is a dead zone (Gemini r3)
						local lf = deco("Lichen", Vector3.new(1.4, 0.25, 1), CFrame.new(foot + Vector3.new(0, 0.12, 0)) * CFrame.Angles(0, hsh * 20, 0), GLOW, { Material = Enum.Material.Neon, MaterialVariant = "", CanCollide = false, CanQuery = false, CastShadow = false })
						local ll = Instance.new("PointLight")
						ll.Color, ll.Range, ll.Brightness, ll.Shadows = GLOW, 8, 0.35, false
						ll.Parent = lf
					elseif head >= 2 and hsh > 0.84 then -- a fallen boulder (breakdown), tilted
						local s = 2 + hash(x, z, 13) * 2.6
						deco("Boulder", Vector3.new(s, s * 0.7, s * 0.9), CFrame.new(foot + Vector3.new(0, s * 0.3, 0)) * CFrame.Angles(hash(x, z, 14) * 0.6, hash(z, x, 15) * 3, 0), ROCK3, { CanCollide = roomy, CanQuery = roomy })
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
		local lamp = part("Lights", "Lantern", Vector3.new(1.2, 1.4, 1.2), CFrame.new(p + Vector3.new(0, 5.4, 0)), color, { Material = Enum.Material.Neon, MaterialVariant = "", CanCollide = false })
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
			local rope = Instance.new("TrussPart") -- the rope ladder up the Swallow Hole: climb it to get back
			local sx, sz = (-70 + 2.6), 48 + 2.6
			local bottom = floorUnder(P(sx, -24, sz)) or foot
			local h = 30
			rope.Name, rope.Anchored, rope.Size, rope.Color, rope.Material = "RopeLadder", true, Vector3.new(2, h, 2), Color3.fromRGB(196, 160, 110), Enum.Material.Fabric
			rope.CFrame = CFrame.new(bottom + Vector3.new(0, h / 2, 0))
			rope.Parent = group("Moss")
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
				nDep += 1
				local ore = ORES[idx2]
				local dep = Instance.new("Model")
				dep.Name = "Deposit"
				dep:SetAttribute("Layer", L)
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
	local walls = {} -- free wall spots for other builders (CaveBuilder's shrines, nests, altar), best first: dead ends, branches, the rest
	for _, c in cands do
		local w = toWorld(c[1], c[2], c[3]) - Vector3.new(0, V / 2, 0)
		if (w - campW).Magnitude > (opt.camp and 58 or 40) then table.insert(walls, { pos = w, dir = Vector3.new(c[4][1], 0, c[4][2]) }) end
	end
	model.Parent = parent
	model:SetAttribute("ZFixed", require(game:GetService("ServerScriptService"):WaitForChild("ZFix")).fix(model)) -- no z-fighting (the user, 2026-11-08)
	return model, { walls = walls }
end

-- Layer tint for the shared prop set (CaveProps makes cyan crystals for every cave): call after CaveProps.build on a layer 2+ model.
function M.tintProps(model, layer)
	local TO = ({ nil, Color3.fromRGB(245, 158, 11), Color3.fromRGB(150, 140, 255), Color3.fromRGB(255, 110, 50) })[layer]
	local props = model:FindFirstChild("Props")
	if not TO or not props then return 0 end
	local n = 0
	for _, d in props:GetDescendants() do
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
