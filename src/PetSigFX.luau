-- PetSigFX (ReplicatedStorage.Shared.PetSigFX), driven by PetVoxels for the v16 voxel pets. The owner (2026-11-25): "Add more
-- unique VFX matching each pet's theme and rarity / characteristics. Higher rarity pets should have more / better VFX." Every
-- pet gets signature effects built from Neon pixel cubes (the same voxel look as the pets), all moving in three dimensions and
-- animated each frame: Common pets have 2, Rare 3, Epic 4, Legendary 6, Mythic 7 and the Secret 8 with a prismatic colour shift.
-- Kinds: fireflies (wandering, blinking motes), steps (footprints: bloom, print, cloud, flame, crack, sand), fountain (ballistic
-- sparks or coins), glint (star flashes facing the camera), echo (a pixel trail behind a moving part), spiral (motes rising round
-- the body), pulse (expanding rings), bolt (pixel lightning), shards (orbiting crystal armour), vortex (motes sucked into a
-- point), runes (turning rune circles), pillar (rising square frames of light), comet, copy (Ninering's ore copies), drip.
-- Stomps and the hatch roar 'kick' the effects (a burst from each). Display only; Reduced Motion builds none; hidden past 140
-- studs from the camera and updated every other frame past 60.
local GuiService = game:GetService("GuiService")
local M = {}
local C3 = Color3.fromRGB
local TAU = math.pi * 2
local GRAV = Vector3.new(0, -9, 0) -- in pet units per second squared (one unit = a 6-stud pet at scale 1)
local WHITE = Color3.new(1, 1, 1)

-- the signature list of each pet: { kind, params }. anchor: a rig anchor (design3d/pets/pet_vox.py), nil = the body.
-- Radii: r is in pet units next to an anchor, in body radii (x.R) round the body; h is in body heights.
local SIG = {
	Tosk = { -- Common hauler of the forest: fireflies round its canopy, a flower blooms in every hoofprint
		{ "fireflies", { anchor = "canopy", n = 6, r = 0.9, col = C3(255, 214, 90), col2 = C3(170, 255, 120) } },
		{ "steps", { feet = { "hoofFL", "hoofBR", "hoofFR", "hoofBL" }, style = "bloom", col = C3(255, 150, 200), col2 = C3(255, 220, 90) } },
	},
	Kobold = { -- Common ember digger: its claws strike sparks, its steps leave glowing cracks
		{ "fountain", { anchor = "footL", n = 6, period = 1.5, burst = 3, up = 3.2, spread = 1.6, life = 0.7, col = C3(255, 170, 60), col2 = C3(255, 240, 160) } },
		{ "steps", { feet = { "footL", "footBR", "footR", "footBL" }, style = "crack", col = C3(255, 110, 30) } },
	},
	["Kepri Scarab"] = { -- Common fast digger: sand sprays from six feet, the gem sends out a ring
		{ "steps", { feet = { "foot0L", "foot1R", "foot2L", "foot0R", "foot1L", "foot2R" }, style = "sand", col = C3(222, 190, 120), pool = 6 } },
		{ "pulse", { anchor = "gem", n = 10, r1 = 1.1, period = 2, col = C3(90, 255, 190), size = 0.11 } },
	},
	Shinemane = { -- Rare light bearer: stars glint in the mane, glowing hoofprints, a trail of light behind the tail
		{ "glint", { anchor = "mane", n = 3, r = 1.0, col = C3(200, 250, 255) } },
		{ "steps", { feet = { "footFL", "footBR", "footFR", "footBL" }, style = "print", col = C3(120, 240, 255) } },
		{ "echo", { anchor = "tail", n = 9, col = C3(150, 245, 255), col2 = C3(170, 150, 255), size = 0.17 } },
	},
	Goldbristle = { -- Rare luck: coins pop off its back, lucky stars flash, clover-gold motes spiral up
		{ "fountain", { anchor = "back", n = 8, period = 1.2, burst = 2, up = 4.2, spread = 1.3, life = 1.1, shape = "coin", col = C3(255, 205, 60), col2 = C3(255, 236, 140) } },
		{ "glint", { n = 3, r = 1.0, col = C3(255, 240, 160) } },
		{ "spiral", { n = 10, r = 0.55, h = 0.95, speed = 0.18, col = C3(120, 240, 110), col2 = C3(255, 220, 90), size = 0.11 } },
	},
	Pixiu = { -- Rare treasure eater: coins swirl into its maw, golden prints, the vault rings out
		{ "vortex", { anchor = "maw", n = 10, R = 2.4, period = 1.6, shape = "coin", col = C3(255, 210, 80), col2 = C3(255, 248, 190) } },
		{ "steps", { feet = { "footFL", "footBR", "footFR", "footBL" }, style = "print", col = C3(255, 190, 70) } },
		{ "pulse", { anchor = "vault", n = 12, r1 = 1.4, period = 2.4, col = C3(255, 200, 80) } },
	},
	Glimwisp = { -- Epic deep light: sonar rings from the core, light trails off every tendril, plankton, rising motes
		{ "pulse", { anchor = "core", n = 14, r1 = 2.4, period = 2.2, rings = 2, col = C3(110, 245, 255) } },
		{ "echo", { anchor = "tenA", n = 6, col = C3(90, 240, 255), col2 = C3(180, 140, 255), size = 0.13 } },
		{ "echo", { anchor = "tenB", n = 6, col = C3(90, 240, 255), col2 = C3(180, 140, 255), size = 0.13 } },
		{ "echo", { anchor = "tenC", n = 6, col = C3(90, 240, 255), col2 = C3(180, 140, 255), size = 0.13 } },
		{ "echo", { anchor = "tenD", n = 6, col = C3(90, 240, 255), col2 = C3(180, 140, 255), size = 0.13 } },
		{ "fireflies", { anchor = "core", n = 7, r = 2.0, col = C3(160, 255, 240), col2 = C3(120, 200, 255) } },
		{ "spiral", { n = 10, r = 0.5, h = 1.15, speed = 0.22, col = C3(120, 245, 255), col2 = C3(220, 255, 255) } },
	},
	Selkie = { -- Epic oxygen bringer: bubble rings rise from the snout, water drips, a water swirl, glowing plankton
		{ "pulse", { anchor = "snout", n = 8, r1 = 0.55, period = 1.8, rings = 2, rise = 1.8, wobble = true, col = C3(200, 248, 255), size = 0.1 } },
		{ "drip", { from = { "gills", "snout" }, n = 5, col = C3(150, 230, 255) } },
		{ "spiral", { n = 14, r = 0.62, h = 0.8, speed = 0.3, turns = 2, col = C3(90, 200, 255), col2 = C3(230, 255, 255) } },
		{ "fireflies", { anchor = "shell", n = 6, r = 1.5, col = C3(120, 255, 220), col2 = C3(90, 180, 255) } },
	},
	Zharbird = { -- Epic firebird: flame trails behind its plumes, an ember column, crest sparks, burning footprints
		{ "echo", { anchor = "plumeA", n = 8, rise = true, col = C3(255, 210, 80), col2 = C3(255, 60, 20) } },
		{ "echo", { anchor = "plumeB", n = 8, rise = true, col = C3(255, 210, 80), col2 = C3(255, 60, 20) } },
		{ "echo", { anchor = "plumeC", n = 8, rise = true, col = C3(255, 210, 80), col2 = C3(255, 60, 20) } },
		{ "spiral", { n = 12, r = 0.45, h = 1.2, speed = 0.35, col = C3(255, 180, 50), col2 = C3(255, 70, 20) } },
		{ "fountain", { anchor = "crest", n = 8, period = 0.9, burst = 2, up = 2.6, spread = 1, life = 0.8, col = C3(255, 220, 120), col2 = C3(255, 100, 30) } },
		{ "steps", { feet = { "footL", "footR" }, style = "flame", col = C3(255, 190, 60), col2 = C3(255, 70, 20) } },
	},
	Fafnir = { -- Legendary cave-in armour: crystal plates orbit it, arcane lightning on its spines, breath sparks, rune ground
		{ "shards", { n = 8, rings = 2, r = 0.72, y = 0.5, len = 0.75, col = C3(190, 130, 255) } },
		{ "bolt", { anchor = "back", to = "tail", segs = 6, period = 2.2, col = C3(205, 160, 255) } },
		{ "bolt", { anchor = "back", to = "ground", segs = 6, period = 3.1, col = C3(205, 160, 255) } },
		{ "fountain", { anchor = "snout", n = 8, period = 1.1, burst = 3, up = 1.4, fwd = 2.2, spread = 0.7, life = 0.7, col = C3(255, 200, 80), col2 = C3(255, 80, 20) } },
		{ "steps", { feet = { "footFL", "footBR", "footFR", "footBL" }, style = "crack", col = C3(255, 120, 40) } },
		{ "runes", { r = 0.8, n = 20, col = C3(180, 110, 255), col2 = C3(255, 170, 70) } },
	},
	Kirin = { -- Legendary cleanser: lightning crackles off the antlers, clouds puff under its hooves, a petal storm, a rune halo
		{ "bolt", { anchor = "antlers", to = "sky", segs = 5, period = 2.4, col = C3(170, 235, 255) } },
		{ "bolt", { anchor = "antlers", to = "ground", segs = 7, period = 3.6, col = C3(170, 235, 255) } },
		{ "steps", { feet = { "footFL", "footBR", "footFR", "footBL" }, style = "cloud", col = C3(244, 246, 255) } },
		{ "spiral", { n = 14, r = 0.75, h = 1.0, speed = 0.22, turns = 1.2, shape = "petal", col = C3(255, 176, 70), col2 = C3(255, 236, 180) } }, -- v16.1: amber-gold petals for the sapphire coat (were pink)
		{ "runes", { plane = "back", anchor = "antlers", r = 0.32, n = 16, col = C3(255, 196, 90), col2 = C3(150, 225, 255) } },
		{ "glint", { anchor = "antlers", n = 2, r = 0.9, col = C3(255, 240, 250) } },
	},
	Ouro = { -- Mythic all-rounder: counter-turning rune circles, a void drawn into its gem, two comets, a light column, lightning
		{ "runes", { r = 0.95, n = 24, double = true, col = C3(180, 110, 255), col2 = C3(255, 120, 200) } },
		{ "vortex", { anchor = "gem", n = 12, R = 2.6, period = 1.8, col = C3(120, 60, 200), col2 = C3(230, 190, 255) } },
		{ "comet", { r = 0.95, y = 0.45, tilt = 0.5, speed = 1.3, n = 10, col = C3(255, 150, 225), col2 = C3(150, 90, 255) } },
		{ "comet", { r = 1.05, y = 0.6, tilt = -0.7, speed = -1.0, n = 10, col = C3(200, 160, 255), col2 = C3(110, 70, 220) } },
		{ "bolt", { anchor = "gem", to = "ground", segs = 7, period = 2.6, col = C3(220, 170, 255) } },
		{ "pillar", { h = 1.5, w = 0.55, col = C3(170, 110, 255) } },
		{ "glint", { n = 3, r = 1.1, col = C3(240, 210, 255) } },
	},
	Ninering = { -- Secret ore copier, all prismatic: ores copy themselves round the core, a light column, rune circles, comets,
		-- rings of light from the core, a star field
		{ "copy", { anchor = "core" } },
		{ "pillar", { h = 1.4, w = 0.5, col = C3(120, 230, 255) } },
		{ "runes", { r = 0.9, n = 24, double = true, col = C3(110, 230, 255), col2 = C3(255, 230, 140) } },
		{ "comet", { r = 0.85, y = 0.5, tilt = 0.6, speed = 1.2, n = 10, col = C3(140, 240, 255), col2 = C3(255, 150, 230) } },
		{ "comet", { r = 0.95, y = 0.55, tilt = -0.6, speed = -1.4, n = 10, col = C3(255, 230, 140), col2 = C3(140, 240, 255) } },
		{ "pulse", { anchor = "core", n = 16, r1 = 2.8, period = 2.6, rings = 2, plane = "face", col = C3(120, 235, 255) } },
		{ "glint", { n = 4, r = 1.2, col = C3(255, 255, 255) } },
		{ "fireflies", { anchor = "core", n = 8, r = 2.6, col = C3(200, 240, 255), col2 = C3(255, 220, 160) } },
	},
}
M.SIG = SIG
local PRISM = { Ninering = true }

local function newPart(e, m, col, mat)
	local q = Instance.new("Part")
	q.Name, q.Material, q.Color, q.Transparency = "Fx_sig", mat or Enum.Material.Neon, col, 1
	q.Size = Vector3.one * 0.1
	q.Anchored, q.CanCollide, q.CanQuery, q.CanTouch, q.CastShadow = true, false, false, false, false
	q.CFrame = m.PrimaryPart and m.PrimaryPart.CFrame or CFrame.identity -- at the root: a fresh model's bounding box stays the pet's
	q.Parent = m
	table.insert(e.parts, q)
	return q
end
local function hideAll(list) for _, q in list do if q.Transparency < 1 then q.Transparency = 1 end end end
local function fadeIO(ph, a, b) -- 0 visible .. 1 hidden: fades in over [0, a], out over [b, 1]
	if ph < a then return 1 - ph / a end
	if ph > b then return (ph - b) / (1 - b) end
	return 0
end

local B, S = {}, {}

-- FIREFLIES: motes wander on slow paths round an anchor and blink
B.fireflies = function(e, p, m)
	e.ph = {}
	for i = 1, p.n do
		newPart(e, m, i % 2 == 0 and (p.col2 or p.col) or p.col)
		e.ph[i] = { e.rnd:NextNumber(0, TAU), e.rnd:NextNumber(0, TAU), e.rnd:NextNumber(0, TAU), e.rnd:NextNumber(0.55, 1.15), e.rnd:NextNumber(0, TAU) }
	end
end
S.fireflies = function(e, x)
	local A = e.att and e.att.WorldPosition or x.c
	local r = e.p.r * (e.att and x.u or x.R)
	for i, q in e.parts do
		local f = e.ph[i]
		local tt = x.t * f[4]
		local off = Vector3.new(math.sin(tt * 0.9 + f[1]), math.sin(tt * 1.3 + f[2]) * 0.6, math.cos(tt * 0.7 + f[3]))
		local blink = math.sin(x.t * 1.9 * f[4] + f[5])
		q.Transparency = blink > 0.1 and 0.05 or (blink > -0.25 and 0.55 or 1)
		q.Size = Vector3.one * 0.11 * x.u
		q.CFrame = CFrame.new(A + off * r) * CFrame.Angles(tt, tt * 0.7, 0)
	end
end

-- STEPS: a footprint where a foot lands while walking (one per foot per stride), at every foot on a stomp
local STEPK = { bloom = 6, print = 3, cloud = 4, flame = 4, crack = 3, sand = 5 }
local STEPL = { bloom = 1.8, print = 1.3, cloud = 0.9, flame = 0.75, crack = 1.5, sand = 0.7 }
local STYLE = {}
STYLE.bloom = function(pr, u, x) -- a sprout grows and opens four petals, then fades
	local s = x.u * 1.8
	local grow = math.min(u / 0.25, 1)
	local fade = u > 0.72 and (u - 0.72) / 0.28 or 0
	local base = CFrame.new(pr.pos) * CFrame.Angles(0, pr.yaw, 0)
	local h = 0.3 * s * grow
	pr.q[1].Size = Vector3.new(0.06 * s, math.max(h, 0.01), 0.06 * s)
	pr.q[1].CFrame = base * CFrame.new(0, h / 2, 0) * CFrame.Angles(0, 0, math.sin(x.t * 2 + pr.yaw) * 0.12)
	pr.q[1].Transparency = fade
	local open = math.clamp((u - 0.18) / 0.3, 0, 1)
	open = open * (1 + 0.35 * math.sin(math.pi * open)) -- springs open past full, then settles
	local blow = u > 0.62 and (u - 0.62) / 0.38 or 0
	pr.q[2].Size = Vector3.one * 0.1 * s * open
	pr.q[2].CFrame = base * CFrame.new(0, h + 0.03 * s, 0)
	pr.q[2].Transparency = math.max(fade, 1 - open)
	for j = 3, 6 do
		local a = (j - 3) / 4 * TAU
		local q = pr.q[j]
		q.Size = Vector3.new(0.12, 0.04, 0.12) * s * open
		local d = (0.1 + 0.5 * blow) * s * open
		q.CFrame = base * CFrame.new(math.cos(a) * d, h + 0.02 * s + blow * (0.5 + 0.15 * j) * s, math.sin(a) * d) * CFrame.Angles(blow * 5 * (j % 2 == 0 and 1 or -1), -a + blow * 2, 0.45 * open + blow * 3)
		q.Transparency = math.max(blow * blow, 1 - math.min(open, 1))
	end
end
STYLE.print = function(pr, u, x) -- a glowing pad fades as two sparks rise off it
	local s = x.u * 1.3
	pr.q[1].Size = Vector3.new(0.5 * s, 0.025 * s, 0.5 * s) * (1 - 0.3 * u)
	pr.q[1].CFrame = CFrame.new(pr.pos) * CFrame.Angles(0, pr.yaw, 0)
	pr.q[1].Transparency = 0.3 + 0.7 * u
	for j = 2, 3 do
		local a = pr.dir[j]
		pr.q[j].Size = Vector3.one * 0.1 * s * (1 - u)
		pr.q[j].CFrame = CFrame.new(pr.pos + Vector3.new(math.cos(a) * 0.18, 0.1 + u * 1.0, math.sin(a) * 0.18) * s) * CFrame.Angles(u * 4, a, 0)
		pr.q[j].Transparency = u
	end
end
STYLE.cloud = function(pr, u, x) -- puffs roll outward and grow
	local s = x.u * 1.3
	local k = 1 - (1 - u) ^ 3
	for j, q in pr.q do
		local a = pr.dir[j]
		q.Size = Vector3.one * (0.16 + 0.26 * k) * s
		q.CFrame = CFrame.new(pr.pos + Vector3.new(math.cos(a) * 0.5 * k, 0.08 + 0.14 * k, math.sin(a) * 0.5 * k) * s) * CFrame.Angles(0, a + k, k * 0.6)
		q.Transparency = 0.15 + 0.85 * u * u
	end
end
STYLE.flame = function(pr, u, x) -- a lick of flame climbs and twists off the print
	local s = x.u
	for j, q in pr.q do
		local k = math.clamp(u * 1.3 - (j - 1) * 0.08, 0, 1)
		local a = pr.dir[j] + k * 2.5
		q.Size = Vector3.one * 0.18 * s * (1 - k)
		q.CFrame = CFrame.new(pr.pos + Vector3.new(math.cos(a) * 0.14, 0.05 + k * 0.85, math.sin(a) * 0.14) * s) * CFrame.Angles(0, a, k * 2)
		q.Transparency = k >= 1 and 1 or 0.1 + 0.8 * k
	end
end
STYLE.crack = function(pr, u, x) -- glowing cracks split out from the print, then cool
	local s = x.u * 1.3
	local g = math.min(u / 0.12, 1)
	for j, q in pr.q do
		local a = pr.dir[j]
		local len = math.max((0.35 + 0.2 * (j % 2)) * s * g, 0.01)
		local d = Vector3.new(math.cos(a), 0, math.sin(a))
		local mid = pr.pos + d * len * 0.5
		q.Size = Vector3.new(0.06 * s, 0.025 * s, len)
		q.CFrame = CFrame.lookAt(mid, mid + d)
		q.Transparency = 0.1 + 0.9 * math.max(0, (u - 0.35) / 0.65)
	end
end
STYLE.sand = function(pr, u, x) -- grains kicked up and out, falling back
	local s = x.u
	local tt = u * 0.7
	for j, q in pr.q do
		local a = pr.dir[j]
		local v = Vector3.new(math.cos(a) * 1.3, 2.2 + (j % 3) * 0.5, math.sin(a) * 1.3)
		local d = v * tt + GRAV * (0.5 * tt * tt)
		q.Size = Vector3.one * 0.08 * s
		q.CFrame = CFrame.new(pr.pos + Vector3.new(d.X, math.max(d.Y, 0), d.Z) * s) * CFrame.Angles(u * 5, a, 0)
		q.Transparency = u > 0.6 and (u - 0.6) / 0.4 or 0
	end
end
B.steps = function(e, p, m, anchor)
	e.feet, e.seen = {}, {}
	for _, f in p.feet do
		local a, part = anchor(f)
		if a then table.insert(e.feet, { att = a, leg = part and string.match(part, "^(.-)%d+$") or f }) end
	end
	e.prints, e.pi, e.fi = {}, 0, 0
	for i = 1, p.pool or 6 do
		local pr = { q = {}, t0 = -99, pos = Vector3.zero, dir = {}, yaw = 0 }
		for j = 1, STEPK[p.style] do
			local col, mat = p.col, Enum.Material.Neon
			if p.style == "bloom" then col = j == 1 and C3(96, 180, 74) or (j == 2 and p.col2 or p.col) end
			if p.style == "flame" and j > 2 then col = p.col2 or p.col end
			if p.style == "cloud" or p.style == "sand" then mat = Enum.Material.SmoothPlastic end
			pr.q[j] = newPart(e, m, col, mat)
			pr.dir[j] = 0
		end
		e.prints[i] = pr
	end
end
local function spawnPrint(e, x, pos)
	e.pi = e.pi % #e.prints + 1
	local pr = e.prints[e.pi]
	pr.t0, pr.pos, pr.yaw = x.now, Vector3.new(pos.X, x.g.Position.Y + 0.02 * x.u, pos.Z), e.rnd:NextNumber(0, TAU)
	for j in pr.dir do pr.dir[j] = e.rnd:NextNumber(0, TAU) end
end
S.steps = function(e, x)
	local nf = #e.feet
	if nf == 0 then return end
	if x.kick then for _, ft in e.feet do spawnPrint(e, x, ft.att.WorldPosition) end end
	for _, ft in e.feet do -- a print the moment that leg's stance begins (its foot lands)
		local c = x.contact and x.contact[ft.leg]
		if c and c ~= e.seen[ft] then
			e.seen[ft] = c
			if x.w > 0.45 then spawnPrint(e, x, ft.att.WorldPosition) end
		end
	end
	local L, st = STEPL[e.p.style], STYLE[e.p.style]
	for _, pr in e.prints do
		local u = (x.now - pr.t0) / L
		if u < 0 or u >= 1 then
			if pr.live then pr.live = false hideAll(pr.q) end
		else
			pr.live = true
			st(pr, u, x)
		end
	end
end

-- FOUNTAIN: sparks or coins thrown up from an anchor in a burst every period, falling back under gravity
B.fountain = function(e, p, m)
	e.ps, e.next, e.pi = {}, 0, 0
	for i = 1, p.n do e.ps[i] = { q = newPart(e, m, i % 3 == 0 and (p.col2 or p.col) or p.col), t0 = -99, A = Vector3.zero, v = Vector3.zero, spin = 0 } end
end
S.fountain = function(e, x)
	local A = e.att and e.att.WorldPosition or x.c
	if x.now >= e.next or x.kick then
		for _ = 1, (e.p.burst or 2) * (x.kick and 2 or 1) do
			e.pi = e.pi % #e.ps + 1
			local pc = e.ps[e.pi]
			local a, sp = e.rnd:NextNumber(0, TAU), (e.p.spread or 1) * e.rnd:NextNumber(0.4, 1)
			pc.t0, pc.A, pc.spin = x.now, A, e.rnd:NextNumber(5, 10)
			pc.v = Vector3.new(math.cos(a) * sp, (e.p.up or 3) * e.rnd:NextNumber(0.75, 1.1), math.sin(a) * sp) + x.g.LookVector * (e.p.fwd or 0)
		end
		e.next = x.now + (e.p.period or 1.2) * e.rnd:NextNumber(0.8, 1.2)
	end
	local L, gy = e.p.life or 0.9, x.g.Position.Y + 0.05 * x.u
	for _, pc in e.ps do
		local tt, q = x.now - pc.t0, pc.q
		if tt < 0 or tt >= L then
			if q.Transparency < 1 then q.Transparency = 1 end
		else
			local P = pc.A + (pc.v * tt + GRAV * (0.5 * tt * tt)) * x.u
			if P.Y < gy then P = Vector3.new(P.X, gy, P.Z) end
			q.Transparency = fadeIO(tt / L, 0.01, 0.65)
			if e.p.shape == "coin" then
				q.Size = Vector3.new(0.22, 0.22, 0.06) * x.u
				q.CFrame = CFrame.new(P) * CFrame.Angles(0, tt * pc.spin, 0.35)
			else
				q.Size = Vector3.one * 0.1 * x.u * (1 - 0.5 * tt / L)
				q.CFrame = CFrame.new(P) * CFrame.Angles(tt * pc.spin, tt * 3, 0)
			end
		end
	end
end

-- GLINT: four-pointed stars pop at random spots by an anchor (or round the body), facing the camera
B.glint = function(e, p, m)
	e.st = {}
	for i = 1, p.n do
		local st = { q = {}, t0 = -99, L = 0.5, wait = e.rnd:NextNumber(0, 1.5), off = Vector3.zero, rot = 0 }
		st.q[1] = newPart(e, m, WHITE)
		e.keep = e.keep or {}
		e.keep[st.q[1]] = true
		st.q[2] = newPart(e, m, p.col)
		st.q[3] = newPart(e, m, p.col)
		e.st[i] = st
	end
end
S.glint = function(e, x)
	local A = e.att and e.att.WorldPosition or x.c
	local r = e.p.r * (e.att and x.u or x.R)
	for _, st in e.st do
		local u = (x.now - st.t0) / st.L
		if (u >= 1 and x.now >= st.wait) or x.kick then
			st.t0, st.L = x.now, e.rnd:NextNumber(0.4, 0.6)
			st.wait = st.t0 + st.L + e.rnd:NextNumber(0.3, 1.4)
			st.off = Vector3.new(e.rnd:NextNumber(-1, 1), e.rnd:NextNumber(-0.6, 1), e.rnd:NextNumber(-1, 1)).Unit * e.rnd:NextNumber(0.5, 1)
			st.rot = e.rnd:NextNumber(-0.4, 0.4)
			u = 0
		end
		if u >= 1 then
			hideAll(st.q)
		else
			local k = math.sin(math.pi * u)
			local P = A + st.off * r
			local cf = ((x.cam - P).Magnitude > 0.01 and CFrame.lookAt(P, x.cam) or CFrame.new(P)) * CFrame.Angles(0, 0, st.rot + u * 0.6)
			local len, th = 0.7 * x.u * k, 0.045 * x.u
			st.q[1].Size, st.q[1].CFrame, st.q[1].Transparency = Vector3.one * 0.12 * x.u * k, cf, 0
			st.q[2].Size, st.q[2].CFrame, st.q[2].Transparency = Vector3.new(th, len, th), cf, 0.1
			st.q[3].Size, st.q[3].CFrame, st.q[3].Transparency = Vector3.new(len * 0.75, th, th), cf, 0.1
		end
	end
end

-- ECHO: a pixel trail of cubes following where a moving part has been (fire trails rise as they cool)
B.echo = function(e, p, m)
	e.hist, e.next = {}, 0
	for i = 1, p.n do newPart(e, m, p.col:Lerp(p.col2 or p.col, (i - 1) / math.max(p.n - 1, 1))) end
end
S.echo = function(e, x)
	local A = e.att and e.att.WorldPosition or x.c
	local H = e.hist
	if H[1] and (H[1][1] - A).Magnitude > 4 * x.u then table.clear(H) end -- the pet was moved in one jump (a teleport, the hatch)
	if x.now >= e.next or not H[1] then
		e.next = x.now + 1 / 30
		table.insert(H, 1, { A, x.now })
		while #H > #e.parts + 1 do table.remove(H) end
	else
		H[1][1] = A
	end
	local n = #e.parts
	for i, q in e.parts do
		local h = H[math.min(i, #H)]
		local k = (i - 1) / n
		local age = x.now - h[2]
		local P = h[1] + (e.p.rise and Vector3.new(0, age * 1.6 * x.u, 0) or Vector3.zero)
		q.Size = Vector3.one * (e.p.size or 0.16) * x.u * (1 - 0.65 * k)
		q.CFrame = CFrame.new(P) * CFrame.Angles(x.t * 3 + i, x.t * 2 + i * 0.5, 0)
		q.Transparency = 0.05 + 0.85 * k
	end
end

-- SPIRAL: motes climbing round the body (or an anchor) in two strands, narrowing as they rise
B.spiral = function(e, p, m)
	for _ = 1, p.n do newPart(e, m, p.col, p.shape == "petal" and Enum.Material.SmoothPlastic or nil) end
end
S.spiral = function(e, x)
	local base = e.att and e.att.WorldPosition or x.g.Position
	local n = #e.parts
	local R, Hh = e.p.r * x.R, e.p.h * x.H
	for i, q in e.parts do
		local ph = (x.t * e.p.speed + i / n) % 1
		local a = ph * TAU * (e.p.turns or 1.5) + (i % 2) * math.pi + x.t * 0.4
		local rr = R * (1 - 0.35 * ph)
		local P = base + Vector3.new(math.cos(a) * rr, (0.15 + 0.85 * ph) * Hh, math.sin(a) * rr)
		q.Color = e.p.col:Lerp(e.p.col2 or e.p.col, ph)
		local cyc = math.floor(x.t * e.p.speed + i / n)
		q.Transparency = (cyc + i) % 3 == 0 and 1 or 0.05 + 0.95 * fadeIO(ph, 0.1, 0.7)
		if e.p.shape == "petal" then
			q.Size = Vector3.new(0.2, 0.04, 0.13) * x.u
			q.CFrame = CFrame.new(P) * CFrame.Angles(x.t * 2 + i, -a, math.sin(x.t * 3 + i) * 0.8)
		else
			q.Size = Vector3.one * (e.p.size or 0.12) * x.u * (1 - 0.5 * ph)
			q.CFrame = CFrame.new(P) * CFrame.Angles(x.t * 2 + i, x.t, 0)
		end
	end
end

-- PULSE: rings of cubes expanding from an anchor (flat, or upright facing forward), optionally rising like bubble rings
B.pulse = function(e, p, m)
	for _ = 1, p.n * (p.rings or 1) do newPart(e, m, p.col) end
end
S.pulse = function(e, x)
	local A = e.att and e.att.WorldPosition or x.c
	local n, rings, per = e.p.n, e.p.rings or 1, e.p.period or 2
	local ax1, ax2 = x.g.RightVector, x.g.LookVector
	if e.p.plane == "face" then ax2 = x.g.UpVector end
	for k = 1, rings do
		local ph = ((x.t + (k - 1) * per / rings) / per) % 1
		local r = e.p.r1 * x.u * (1 - (1 - ph) ^ 3)
		local up = Vector3.new(0, (e.p.rise or 0) * ph * x.u, 0)
		for i = 1, n do
			local q = e.parts[(k - 1) * n + i]
			local a = i / n * TAU + x.t * 0.6
			local wob = e.p.wobble and math.sin(a * 3 + x.t * 6) * 0.08 * x.u or 0
			local P = A + (ax1 * math.cos(a) + ax2 * math.sin(a)) * (r + wob) + up
			q.Size = Vector3.one * (e.p.size or 0.13) * x.u * (1 - 0.5 * ph)
			q.CFrame = r > 0.01 and CFrame.lookAt(P, A + up) or CFrame.new(P)
			q.Transparency = 0.1 + 0.9 * fadeIO(ph, 0.06, 0.35)
		end
	end
end

-- BOLT: pixel lightning from an anchor to another anchor, the ground or the sky, flickering and re-forking for a moment
B.bolt = function(e, p, m, anchor)
	e.to = (p.to ~= "ground" and p.to ~= "sky") and anchor(p.to) or nil
	for _ = 1, p.segs or 6 do newPart(e, m, p.col) end
	e.tip = newPart(e, m, WHITE)
	e.on, e.next, e.roll, e.jit, e.B = -99, e.rnd:NextNumber(0.5, p.period or 2), 0, {}, Vector3.zero
	if e.att then
		e.light = Instance.new("PointLight")
		e.light.Color, e.light.Range, e.light.Brightness, e.light.Shadows = p.col, 8, 0, false
		e.light.Parent = e.att
	end
end
S.bolt = function(e, x)
	local A = e.att and e.att.WorldPosition or x.c
	if x.now >= e.next or (x.kick and x.now - e.on > 0.3) then
		e.on, e.next = x.now, x.now + (e.p.period or 2.5) * e.rnd:NextNumber(0.7, 1.3)
		local a = e.rnd:NextNumber(0, TAU)
		if e.p.to == "ground" then
			local r = e.rnd:NextNumber(0.8, 1.3)
			e.B = Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
		else
			e.B = Vector3.new(math.cos(a) * 0.5, 1, math.sin(a) * 0.5)
		end
	end
	local u, DUR = x.now - e.on, 0.3
	if u > DUR then
		if e.tip.Transparency < 1 then hideAll(e.parts) end
		if e.light and e.light.Brightness ~= 0 then e.light.Brightness = 0 end
		return
	end
	local Bp
	if e.to then Bp = e.to.WorldPosition
	elseif e.p.to == "ground" then Bp = x.g.Position + e.B * x.R
	else Bp = A + e.B * x.H * 0.55 end
	local n = #e.parts - 1
	if x.now >= e.roll then -- a new fork every few frames
		e.roll = x.now + 0.05
		for i = 1, n do e.jit[i] = Vector3.new(e.rnd:NextNumber(-1, 1), e.rnd:NextNumber(-1, 1), e.rnd:NextNumber(-1, 1)) end
	end
	local amp = math.min((Bp - A).Magnitude * 0.16, 0.7 * x.u)
	local flick = math.floor(u / 0.04) % 3 ~= 1
	local prev = A
	for i = 1, n do
		local P = i == n and Bp or A:Lerp(Bp, i / n) + e.jit[i] * amp
		local q = e.parts[i]
		local L = (P - prev).Magnitude
		q.Size = Vector3.new(0.06 * x.u, 0.06 * x.u, L + 0.05 * x.u)
		q.CFrame = L > 1e-3 and CFrame.lookAt((prev + P) / 2, P) or CFrame.new(P)
		q.Transparency = flick and 0 or 0.65
		prev = P
	end
	e.tip.Size = Vector3.one * 0.22 * x.u * (1 - u / DUR)
	e.tip.CFrame = CFrame.new(Bp) * CFrame.Angles(u * 20, u * 14, 0)
	e.tip.Transparency = u / DUR
	if e.light then e.light.Brightness = flick and 2.2 or 0.6 end
end

-- SHARDS: crystal plates (glass round a glowing core) orbiting the body on two tilted rings, turning opposite ways
B.shards = function(e, p, m)
	e.sh = {}
	for i = 1, p.n do e.sh[i] = { newPart(e, m, p.col, Enum.Material.Glass), newPart(e, m, p.col:Lerp(WHITE, 0.25)) } end
end
S.shards = function(e, x)
	local c0 = x.g.Position + x.g.UpVector * e.p.y * x.H
	local rings, n = e.p.rings or 2, #e.sh
	for i, sh in e.sh do
		local ring = i % rings
		local dir = ring == 0 and 1 or -0.8
		local tilt = (ring == 0 and 1 or -1) * (e.p.tilt or 0.32)
		local a = x.t * 0.55 * dir + i / n * TAU
		local rx, rz = e.p.r * x.W * (1 + 0.05 * math.sin(x.t * 2 + i)), e.p.r * x.L * 0.62
		local fr = x.g.Rotation * CFrame.Angles(tilt, 0, tilt * 0.6)
		local P = c0 + fr:VectorToWorldSpace(Vector3.new(math.cos(a) * rx, math.sin(x.t * 1.4 + i) * 0.12 * x.u, math.sin(a) * rz))
		local cf = CFrame.lookAt(P, c0) * CFrame.Angles(0, 0, 0.4 * math.sin(x.t + i))
		local len = e.p.len * x.u
		sh[1].Size, sh[1].CFrame, sh[1].Transparency = Vector3.new(0.18 * x.u, len, 0.09 * x.u), cf, 0.25
		sh[2].Size, sh[2].CFrame = Vector3.new(0.05 * x.u, len * 0.7, 0.12 * x.u), cf
		sh[2].Transparency = 0.1 + 0.35 * (0.5 + 0.5 * math.sin(x.t * 3 + i))
	end
end

-- VORTEX: motes (or coins) spiralling in from a wide ring and vanishing into an anchor
B.vortex = function(e, p, m)
	e.ph = {}
	for i = 1, p.n do
		newPart(e, m, i % 2 == 0 and (p.col2 or p.col) or p.col)
		e.ph[i] = { e.rnd:NextNumber(0, TAU), e.rnd:NextNumber(-0.5, 0.5) }
	end
end
S.vortex = function(e, x)
	local A = e.att and e.att.WorldPosition or x.c
	local n = #e.parts
	for i, q in e.parts do
		local f = e.ph[i]
		local ph = (x.t / (e.p.period or 1.6) + i / n) % 1
		local r = e.p.R * x.u * (1 - ph) ^ 1.4
		local a = f[1] + ph * TAU * 1.2
		local P = A + Vector3.new(math.cos(a) * r, f[2] * r, math.sin(a) * r)
		local k = 0.35 + 0.65 * (1 - ph)
		if e.p.shape == "coin" then
			q.Size = Vector3.new(0.2, 0.2, 0.05) * x.u * k
			q.CFrame = CFrame.new(P) * CFrame.Angles(0, x.t * 6 + i, 0.4)
		else
			q.Size = Vector3.one * 0.12 * x.u * k
			q.CFrame = CFrame.new(P) * CFrame.Angles(x.t * 3 + i, x.t * 2, 0)
		end
		q.Transparency = 0.05 + 0.95 * fadeIO(ph, 0.15, 0.9)
	end
end

-- RUNES: a rune circle of dashes turning one way and glyph blocks turning the other, flat at the feet or upright behind an
-- anchor (a halo); 'double' adds a second, smaller counter-turning circle
B.runes = function(e, p, m)
	e.n = p.n
	for _ = 1, p.n do newPart(e, m, p.col:Lerp(Color3.new(0, 0, 0), 0.2)) end
	for _ = 1, p.n // 2 do newPart(e, m, p.col2 or p.col) end
	if p.double then for _ = 1, p.n // 2 do newPart(e, m, (p.col2 or p.col):Lerp(Color3.new(0, 0, 0), 0.15)) end end
end
S.runes = function(e, x)
	local c0, ax1, ax2, nrm
	if e.p.plane == "back" then
		c0 = (e.att and e.att.WorldPosition or x.c) - x.g.LookVector * 0.35 * x.u
		ax1, ax2, nrm = x.g.RightVector, x.g.UpVector, x.g.LookVector
	else
		c0 = x.g.Position + Vector3.new(0, 0.04 * x.u, 0)
		ax1, ax2, nrm = x.g.RightVector, x.g.LookVector, x.g.UpVector
	end
	local R = e.p.r * (e.p.plane == "back" and x.H or x.R)
	local n = e.n
	local breathe = 0.5 + 0.5 * math.sin(x.t * 1.6)
	local function ring(i0, cnt, rr, spin, len, th, tr)
		for i = 1, cnt do
			local q = e.parts[i0 + i]
			local a = i / cnt * TAU + spin
			local rad = ax1 * math.cos(a) + ax2 * math.sin(a)
			local tan = -ax1 * math.sin(a) + ax2 * math.cos(a)
			local P = c0 + rad * rr
			q.Size = Vector3.new(th, th * 0.45, len)
			q.CFrame = CFrame.lookAt(P, P + tan, nrm)
			q.Transparency = tr + 0.25 * math.sin(x.t * 3 + i * 0.9)
		end
	end
	ring(0, n, R, x.t * 0.35, R * TAU / n * 0.6, 0.07 * x.u, 0.2 + 0.25 * breathe) -- the outer dashes
	ring(n, n // 2, R * 0.82, -x.t * 0.55, 0.12 * x.u, 0.12 * x.u, 0.15) -- the glyph blocks
	if e.p.double then ring(n + n // 2, n // 2, R * 0.55, x.t * 0.8, R * 0.55 * TAU / (n // 2) * 0.5, 0.06 * x.u, 0.25) end
end

-- PILLAR: square frames of light rising up through the pet from the ground, turning and shrinking as they climb
B.pillar = function(e, p, m)
	for _ = 1, 4 * 4 do newPart(e, m, p.col:Lerp(Color3.new(0, 0, 0), 0.15)) end
end
S.pillar = function(e, x)
	local base = x.g.Position
	for f = 1, 4 do
		local ph = (x.t * 0.3 + f / 4) % 1
		local w = e.p.w * x.R * (1 - 0.55 * ph)
		local fr = CFrame.new(base + Vector3.new(0, ph * e.p.h * x.H, 0)) * CFrame.Angles(0, x.t * 0.7 + ph * 2.5, 0)
		local tr = 0.2 + 0.8 * fadeIO(ph, 0.08, 0.55)
		for k = 1, 4 do
			local q = e.parts[(f - 1) * 4 + k]
			q.Size = Vector3.new(w * 2, 0.05 * x.u, 0.06 * x.u)
			q.CFrame = fr * CFrame.Angles(0, k / 4 * TAU, 0) * CFrame.new(0, 0, w)
			q.Transparency = tr
		end
	end
end

-- COMET: a bright head on a tilted orbit round the body with a fading pixel tail behind it
B.comet = function(e, p, m)
	for i = 1, p.n do newPart(e, m, p.col:Lerp(p.col2 or p.col, (i - 1) / math.max(p.n - 1, 1))) end
end
S.comet = function(e, x)
	local c0 = x.g.Position + x.g.UpVector * e.p.y * x.H
	local fr = x.g.Rotation * CFrame.Angles(e.p.tilt or 0.4, 0, (e.p.tilt or 0.4) * 0.6)
	local rx, rz = e.p.r * x.R, e.p.r * x.R * 0.85
	local n, sg = #e.parts, math.sign(e.p.speed)
	for i, q in e.parts do
		local a = x.t * e.p.speed - (i - 1) * 0.075 * sg
		local P = c0 + fr:VectorToWorldSpace(Vector3.new(math.cos(a) * rx, math.sin(a * 2) * 0.1 * x.u, math.sin(a) * rz))
		local k = (i - 1) / n
		q.Size = Vector3.one * (i == 1 and 0.26 or 0.18 * (1 - k)) * x.u
		q.CFrame = CFrame.new(P) * CFrame.Angles(x.t * 4 + i, x.t * 3, 0)
		q.Transparency = i == 1 and 0 or 0.1 + 0.85 * k
	end
end

-- COPY: three ores orbit the core; one at a time splits off a flickering hologram copy that drifts away and fades
local ORES = { C3(255, 110, 90), C3(110, 255, 160), C3(255, 220, 90) }
B.copy = function(e, p, m)
	e.ores, e.next, e.noPrism = {}, 1, true
	for i = 1, 3 do e.ores[i] = { newPart(e, m, ORES[i]), newPart(e, m, ORES[i]:Lerp(WHITE, 0.3)), -99 } end
end
S.copy = function(e, x)
	local A = e.att and e.att.WorldPosition or x.c
	if x.now >= e.next or x.kick then
		e.ores[e.rnd:NextInteger(1, 3)][3] = x.now
		e.next = x.now + 1.1
	end
	for i, o in e.ores do
		local a = x.t * 0.9 + i / 3 * TAU
		local P = A + Vector3.new(math.cos(a) * 1.0, 0.3 * math.sin(x.t * 2 + i), math.sin(a) * 1.0) * x.u
		local rot = CFrame.Angles(x.t, x.t * 1.3 + i, 0.6)
		o[1].Size, o[1].CFrame, o[1].Transparency = Vector3.one * 0.24 * x.u, CFrame.new(P) * rot, 0
		local u = (x.now - o[3]) / 0.9
		if u >= 0 and u < 1 then
			local out = (P - A).Magnitude > 1e-3 and (P - A).Unit or Vector3.xAxis
			o[2].Size = o[1].Size * (1 + 0.35 * u)
			o[2].CFrame = CFrame.new(P + (out * 0.7 + Vector3.new(0, 0.55, 0)) * u * x.u) * rot
			o[2].Transparency = (math.floor(u * 14) % 2 == 0) and 0.3 + 0.6 * u or 0.7 + 0.3 * u -- a hologram flicker
		elseif o[2].Transparency < 1 then
			o[2].Transparency = 1
		end
	end
end

-- DRIP: drops fall from an anchor and splash flat on the ground
B.drip = function(e, p, m, anchor)
	e.src, e.ds, e.next = {}, {}, 0
	for _, a in p.from do
		local at = anchor(a)
		if at then table.insert(e.src, at) end
	end
	for i = 1, p.n do e.ds[i] = { newPart(e, m, p.col), newPart(e, m, p.col:Lerp(WHITE, 0.4)), -99, Vector3.zero } end
end
S.drip = function(e, x)
	if #e.src == 0 then return end
	if x.now >= e.next then
		e.next = x.now + e.rnd:NextNumber(0.25, 0.6)
		for _, d in e.ds do
			if x.now - d[3] > 1.6 then
				d[3] = x.now
				d[4] = e.src[e.rnd:NextInteger(1, #e.src)].WorldPosition + Vector3.new(e.rnd:NextNumber(-0.6, 0.6), -0.1, e.rnd:NextNumber(-0.6, 0.6)) * x.u
				break
			end
		end
	end
	local gy = x.g.Position.Y
	for _, d in e.ds do
		local tt, P0 = x.now - d[3], d[4]
		local th = math.sqrt(2 * math.max(P0.Y - gy, 0) / (9 * x.u))
		if tt < 0 or tt > th + 0.35 then
			hideAll({ d[1], d[2] })
		elseif tt <= th then
			d[1].Size, d[1].Transparency = Vector3.new(0.08, 0.14, 0.08) * x.u, 0.1
			d[1].CFrame = CFrame.new(P0 - Vector3.new(0, 4.5 * x.u * tt * tt, 0))
			if d[2].Transparency < 1 then d[2].Transparency = 1 end
		else
			if d[1].Transparency < 1 then d[1].Transparency = 1 end
			local u = (tt - th) / 0.35
			d[2].Size = Vector3.new(0.05 + 0.4 * u, 0.025, 0.05 + 0.4 * u) * x.u
			d[2].CFrame = CFrame.new(P0.X, gy + 0.02 * x.u, P0.Z)
			d[2].Transparency = 0.2 + 0.8 * u
		end
	end
end

-- build the signature effects of a pet; anchor(name) returns an Attachment riding that anchor's piece, or nil
function M.build(m, name, d, rig, anchor)
	local list = SIG[name]
	if not list or not d.vox then return end
	local calm = false
	pcall(function() calm = GuiService.ReducedMotionEnabled end)
	if calm then return end
	local H = d.height or 5
	local sg = { list = {}, prism = PRISM[name], H = H, W = d.size.X, L = d.size.Y, R = math.max(d.size.X, d.size.Y) * 0.5, k = math.clamp(H / 6, 0.6, 1.5), ctx = {}, frame = 0 }
	sg.lastWave = rig.aura and rig.aura.waveT
	for i, spec in list do
		local kind, p = spec[1], spec[2]
		local e = { kind = kind, p = p, parts = {}, rnd = Random.new(#name * 97 + i * 31), att = p.anchor and anchor(p.anchor) or nil }
		local ok, err = pcall(B[kind], e, p, m, anchor)
		if ok then
			table.insert(sg.list, e)
		else
			warn("PetSigFX", name, kind, err)
			for _, q in e.parts do q:Destroy() end
		end
	end
	rig.sig = sg
end

-- every frame after the pose: g is the ground under the pet in the pet's frame (looking -Z), s its scale
function M.step(m, rig, now, t, dt, s, g)
	local sg = rig.sig
	if not sg then return end
	local ws = m:FindFirstAncestorWhichIsA("Workspace") -- the pet's own world (a test's Lua can see another DataModel's 'workspace')
	local cam = ws and ws.CurrentCamera
	local camPos = cam and cam.CFrame.Position or g.Position
	local inWorld = ws ~= nil
	local dist = (camPos - g.Position).Magnitude
	if not inWorld or dist > 140 * math.max(s, 0.5) then -- a pet card's viewport shows the pet alone (rune circles overflowed the card)
		if not sg.hidden then
			sg.hidden = true
			for _, e in sg.list do
				hideAll(e.parts)
				if e.light then e.light.Brightness = 0 end
			end
		end
		return
	end
	sg.hidden = false
	sg.frame += 1
	local kick = false
	local au = rig.aura
	if au and au.waveT ~= sg.lastWave then
		sg.lastWave = au.waveT
		kick = true
	end
	if rig.burst and not sg.lastBurst then kick = true end
	sg.lastBurst = rig.burst
	if inWorld and dist > 60 and sg.frame % 2 == 1 and not kick then return end -- far away: every other frame
	local x = sg.ctx
	x.t, x.now, x.dt, x.s, x.g, x.kick, x.cam, x.w, x.gp, x.contact = t, now, dt, s, g, kick, camPos, rig.w or 0, rig.gp, rig.contact
	x.u, x.R, x.H, x.W, x.L = s * sg.k, sg.R * s, sg.H * s, sg.W * s * 0.5, sg.L * s * 0.5
	x.c = (g * CFrame.new(0, sg.H * 0.5 * s, 0)).Position
	for _, e in sg.list do
		local ok, err = pcall(S[e.kind], e, x)
		if not ok and not e.warned then e.warned = true warn("PetSigFX step", e.kind, err) end
	end
	if sg.prism then -- the Secret's colours drift through the spectrum, its orbit motes and auras with them
		local j = 0
		local function hue(q)
			j += 1
			q.Color = Color3.fromHSV((t * 0.12 + j * 0.037) % 1, 0.45, 1)
		end
		for _, e in sg.list do
			if not e.noPrism then
				for _, q in e.parts do
					if q.Transparency < 1 and not (e.keep and e.keep[q]) then hue(q) end
				end
			end
		end
		for _, o in rig.orbits or {} do for _, q in o.cubes do hue(q) end end
		if au then for _, q in au.ring do hue(q) end for _, q in au.halo do hue(q) end end
	end
end

return M
