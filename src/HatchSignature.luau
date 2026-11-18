-- HatchSignature (ReplicatedStorage.Shared.HatchSignature): a set piece of its own for every Legendary, Mythic and Secret
-- hatch (2026-11-18, the owner: "make secret pets / legendaries have unique cutscenes"). Shared.HatchScene plays an OMEN
-- beat between the build-up and the hang when M.get(name, rarity) returns one, so the player knows WHICH pet is coming
-- before the shell breaks:
--   Fafnir   the hoard: gold coins rain onto the nest, a fire wakes under it and two slit eyes open in the dark behind
--   Kirin    the storm: clouds pour into the cave and lightning strikes the egg; it hatches in a cleansing ripple and petals
--   Ouro     the coil: a serpent of light winds round the egg and tightens while the camera circles; it hatches inside its halo
--   Ninering the void: the cave vanishes into a starfield and nine gold rings come down one by one, each with a chime
-- A pet without its own entry falls back to its rarity's (Legendary = hoard, Mythic = coil, Secret = void).
-- Fields: tint (the cave lights' colour in the reveal), omen (seconds; the Fast cutscenes setting skips the omen but keeps the burst and the reveal), still (the egg stops
-- rocking in the omen), start(ctx), step(ctx, u 0..1, dt) -> camPos?, look?, fov?, burst(ctx), reveal(ctx, s since burst, dt).
-- ctx = { world, egg, NEST, rc, part, light, sfx, rnd, caption, state }. Everything is parented to ctx.world, which
-- HatchScene destroys at the end, and Lighting is restored by HatchScene too. Display only.
local Lighting = game:GetService("Lighting")
local M = {}
local WHITE = Color3.new(1, 1, 1)
local GOLD = Color3.fromRGB(255, 200, 60)
local FIRE = Color3.fromRGB(255, 120, 30)
local CYANW = Color3.fromRGB(190, 240, 255)
local PINK = Color3.fromRGB(255, 90, 150)

local function neon(ctx, size, cf, col, tr, shape)
	return ctx.part(ctx.world, size, cf, col, { Material = Enum.Material.Neon, Transparency = tr or 0, Shape = shape or Enum.PartType.Block })
end
local function fly(list, dt, g) -- simple ballistic bits: { p, v, spin, life, fade?, tr? }
	for i = #list, 1, -1 do
		local b = list[i]
		b.life -= dt
		if b.life <= 0 then
			b.p:Destroy()
			table.remove(list, i)
		else
			b.v += Vector3.new(0, -(g or 0), 0) * dt
			b.p.CFrame = (b.p.CFrame + b.v * dt) * CFrame.Angles(b.spin.X * dt, b.spin.Y * dt, b.spin.Z * dt)
			if b.fade then b.p.Transparency = 1 - math.min(1, b.life / b.fade) * (1 - (b.tr or 0)) end
		end
	end
end

-- FAFNIR: the hoard ------------------------------------------------------------------------------------------------------
local hoard = { omen = 1.8, tint = FIRE }
function hoard.start(ctx)
	local st = ctx.state
	st.coins, st.bits, st.n = {}, {}, 0
	st.fire = ctx.light(ctx.part(ctx.world, Vector3.one * 0.2, CFrame.new(ctx.NEST + Vector3.new(0, -0.3, -1.2)), WHITE, { Transparency = 1 }), FIRE, 12, 0)
	st.eyes = {}
	local skull = CFrame.new(ctx.NEST + Vector3.new(0, 7.2, 7.9))
	local DARKH = Color3.fromRGB(26, 12, 10)
	for _, d in { { Vector3.new(9.5, 3.2, 0.6), Vector3.new(0, 0, 0) }, { Vector3.new(4.5, 2.2, 0.6), Vector3.new(0, -2.4, -0.2) }, { Vector3.new(0.9, 3.4, 0.6), Vector3.new(-4.2, 2.6, 0.1), -0.5 }, { Vector3.new(0.9, 3.4, 0.6), Vector3.new(4.2, 2.6, 0.1), 0.5 } } do
		ctx.part(ctx.world, d[1], skull * CFrame.new(d[2]) * CFrame.Angles(0, 0, d[3] or 0), DARKH) -- brow, snout, horns: a head the size of the cave
	end
	for s = -1, 1, 2 do -- slit pupils in the dark behind the egg: something big is watching
		local at = CFrame.new(ctx.NEST + Vector3.new(s * 3.2, 7.4, 7.5)) * CFrame.Angles(0, 0, s * 0.22) -- big and high: a dragon the size of the cave (Gemini sg2)
		local bars = {}
		for k, w in { 2.8, 2.0, 1.1 } do -- an almond: wide in the middle, narrow at the lids
			bars[k] = { p = neon(ctx, Vector3.new(w, 0.05, 0.1), at, Color3.fromRGB(255, 150, 20):Lerp(Color3.fromRGB(255, 220, 90), (k - 1) / 2), 0.25), w = w, h = 1 - (k - 1) * 0.35 }
		end
		local slit = ctx.part(ctx.world, Vector3.new(0.45, 0.05, 0.05), at * CFrame.new(0, 0, -0.35), Color3.fromRGB(14, 4, 2))
		table.insert(st.eyes, { at = at, bars = bars, s = slit })
	end
	ctx.sfx("upgrade", 0.55)
end
function hoard.step(ctx, u, dt)
	local st, rnd = ctx.state, ctx.rnd
	while st.n < u * 260 do -- a rain of coins that gets heavier
		st.n += 1
		local a, r = rnd:NextNumber(0, math.pi * 2), rnd:NextNumber(0.6, 4.2)
		local c = ctx.part(ctx.world, Vector3.new(0.08, 0.42, 0.42), CFrame.new(ctx.NEST + Vector3.new(math.cos(a) * r, rnd:NextNumber(7, 11), math.sin(a) * r)) * CFrame.Angles(rnd:NextNumber(0, 6), rnd:NextNumber(0, 6), 0), GOLD,
			{ Material = Enum.Material.Metal, Reflectance = 0.35, Shape = Enum.PartType.Cylinder })
		table.insert(st.coins, { p = c, v = -rnd:NextNumber(4, 8), floor = ctx.NEST.Y - 0.55 + rnd:NextNumber(0, 0.35) * (1 - r / 5) })
		if st.n % 14 == 0 then ctx.sfx("hit", 1.7 + rnd:NextNumber(0, 0.4)) end
	end
	for _, c in st.coins do
		if c.v then
			c.v -= 30 * dt
			local y = c.p.Position.Y + c.v * dt
			if y <= c.floor then -- it lands and lies flat
				c.p.CFrame, c.v = CFrame.new(c.p.Position.X, c.floor, c.p.Position.Z) * CFrame.Angles(0, rnd:NextNumber(0, 6), math.pi / 2), nil
			else
				c.p.CFrame = (c.p.CFrame + Vector3.new(0, c.v * dt, 0)) * CFrame.Angles(dt * 9, 0, dt * 5)
			end
		end
	end
	st.fire.Brightness, st.fire.Range = u * 3.5, 6 + u * 8
	for _, e in st.eyes do -- the eyes open late and narrow to slits
		local o = math.clamp((u - 0.45) / 0.3, 0, 1)
		for _, b in e.bars do
			b.p.Size = Vector3.new(b.w, 0.05 + o * 1.3 * b.h, 0.1)
			b.p.CFrame = e.at * CFrame.new(0, 0, -0.01 * b.h)
		end
		e.s.Size = Vector3.new(0.55 - o * 0.15, 0.05 + o * 1.3, 0.05)
	end
	Lighting.Ambient = Color3.fromRGB(10, 8, 30):Lerp(Color3.fromRGB(44, 18, 8), u)
	return ctx.NEST + Vector3.new(1.8 - u * 2.4, 1.5, -8.4 + u * 0.8), ctx.NEST + Vector3.new(0, 3.3, 0), 50 - u * 8 -- low, looking up at the egg on its hoard
end
function hoard.burst(ctx)
	local st = ctx.state
	for _, e in st.eyes or {} do
		for _, b in e.bars do b.p:Destroy() end
		e.s:Destroy()
	end
	st.eyes, st.blades = {}, {}
	for _, c in st.coins or {} do -- the blast throws the hoard out, some of it at the lens
		local out = (c.p.Position - ctx.NEST) * Vector3.new(1, 0, 1)
		out = out.Magnitude > 0.01 and out.Unit or Vector3.xAxis
		table.insert(st.bits, { p = c.p, v = out * ctx.rnd:NextNumber(5, 11) + Vector3.new(0, ctx.rnd:NextNumber(5, 11), -ctx.rnd:NextNumber(2, 9)), spin = Vector3.new(9, 5, 7), life = 1.4 })
	end
	st.coins = {}
	for i = 1, 18 do -- a ring of fire jumps up round the nest
		local a = i / 18 * math.pi * 2
		local b = neon(ctx, Vector3.new(0.35, 0.2, 0.35), CFrame.new(ctx.NEST + Vector3.new(math.cos(a) * 3.1, -0.4, math.sin(a) * 3.1)), i % 2 == 0 and FIRE or GOLD, 0.1)
		table.insert(st.blades, { p = b, h = 2.2 + (i % 3) * 0.7 })
	end
	if st.fire then st.fire.Brightness = 5 end
	ctx.sfx("claim", 0.7)
end
function hoard.reveal(ctx, s, dt)
	local st, rnd = ctx.state, ctx.rnd
	for _, b in st.blades or {} do
		local u = math.clamp(s / 0.9, 0, 1)
		local h = b.h * math.sin(math.min(u * 1.6, 1) * math.pi / 2) * (1 - u * 0.6)
		local p = b.p.Position
		b.p.Size = Vector3.new(0.35 * (1 - u * 0.7), math.max(0.05, h), 0.35 * (1 - u * 0.7))
		b.p.CFrame = CFrame.new(p.X, ctx.NEST.Y - 0.5 + h / 2, p.Z)
		b.p.Transparency = 0.1 + u * 0.9
	end
	if st.fire then st.fire.Brightness = math.max(1.2, 5 - s * 4) end
	st.ember = (st.ember or 0) + dt * 14 -- embers rise off the hoard
	while st.ember >= 1 and s < 5 do
		st.ember -= 1
		local a, r = rnd:NextNumber(0, math.pi * 2), rnd:NextNumber(0.5, 4)
		table.insert(st.bits, { p = neon(ctx, Vector3.one * 0.1, CFrame.new(ctx.NEST + Vector3.new(math.cos(a) * r, -0.3, math.sin(a) * r)), rnd:NextNumber() < 0.5 and FIRE or GOLD), v = Vector3.new(rnd:NextNumber(-0.4, 0.4), rnd:NextNumber(1.5, 3), rnd:NextNumber(-0.4, 0.4)), spin = Vector3.one * 3, life = 1.6, fade = 1.6 })
	end
	fly(st.bits or {}, dt, 9)
	Lighting.Ambient = Lighting.Ambient:Lerp(Color3.fromRGB(46, 22, 12), 0.5)
end

-- KIRIN: the storm -------------------------------------------------------------------------------------------------------
local storm = { omen = 1.9, tint = Color3.fromRGB(90, 200, 255) }
function storm.start(ctx)
	local st, rnd = ctx.state, ctx.rnd
	st.clouds, st.bits = {}, {}
	for i = 1, 40 do -- rolling voxel thunderclouds: clumps of dark cubes (Gemini sg2: the translucent balls read as bubbles)
		local a, r = (i % 10) / 10 * math.pi * 2 + rnd:NextNumber(-0.2, 0.2), rnd:NextNumber(3.5, 7.5)
		local sz = rnd:NextNumber(1.2, 2.4)
		local c = ctx.part(ctx.world, Vector3.one * sz, CFrame.new(ctx.NEST + Vector3.new(math.cos(a) * r, rnd:NextNumber(7, 9), math.sin(a) * r)) * CFrame.Angles(0, rnd:NextNumber(0, 3), 0), Color3.fromRGB(34, 36, 54):Lerp(Color3.fromRGB(74, 78, 104), rnd:NextNumber()), { Material = Enum.Material.SmoothPlastic })
		table.insert(st.clouds, { p = c, a = a, r = r, y = c.Position.Y - ctx.NEST.Y })
	end
	st.flash = ctx.light(ctx.part(ctx.world, Vector3.one * 0.2, CFrame.new(ctx.NEST + Vector3.new(0, 5, -1)), WHITE, { Transparency = 1 }), CYANW, 11, 0)
	ctx.sfx("swing", 0.6)
end
function storm.step(ctx, u, dt)
	local st, rnd = ctx.state, ctx.rnd
	for _, c in st.clouds do -- they pour down and swirl round the egg
		local a = c.a + u * 1.6
		c.p.CFrame = CFrame.new(ctx.NEST + Vector3.new(math.cos(a) * c.r, c.y - u * 2.5, math.sin(a) * c.r)) * c.p.CFrame.Rotation
	end
	local function bolt(from, goal, w, parent)
		for k = 1, 8 do
			local to = k == 8 and goal or from:Lerp(goal, 1 / (9 - k)) + Vector3.new(rnd:NextNumber(-0.9, 0.9), 0, rnd:NextNumber(-0.5, 0.5))
			ctx.part(parent, Vector3.new(w, w, (to - from).Magnitude + w), CFrame.lookAt((from + to) / 2, to), CYANW, { Material = Enum.Material.Neon })
			if k == 3 or k == 5 then -- a branch
				local br = to + Vector3.new(rnd:NextNumber(-2.5, 2.5), -rnd:NextNumber(1.5, 3), rnd:NextNumber(-1, 1))
				ctx.part(parent, Vector3.new(w * 0.6, w * 0.6, (br - to).Magnitude), CFrame.lookAt((to + br) / 2, br), CYANW, { Material = Enum.Material.Neon })
			end
			from = to
		end
	end
	st.strikes = st.strikes or {}
	for _, at in { 0.4, 0.72 } do
		if u >= at and not st.strikes[at] then -- two strikes: a warning off to the side, then one onto the egg
			st.strikes[at] = true
			local m = Instance.new("Model")
			m.Parent = ctx.world
			if at < 0.5 then
				bolt(ctx.NEST + Vector3.new(-5, 13, 5), ctx.NEST + Vector3.new(-4.5, -0.4, 4), 0.22, m)
			else
				bolt(ctx.NEST + Vector3.new(0.6, 14, 1), ctx.NEST + Vector3.new(0, 3.7, 0), 0.38, m)
			end
			st.bolts = st.bolts or {}
			table.insert(st.bolts, m)
			st.flash.Brightness = at < 0.5 and 3 or 6
			st.amb = at < 0.5 and 0.6 or 1 -- the whole cave blinks white-blue for a frame or two
			ctx.sfx("claim", at < 0.5 and 1.9 or 1.6)
			ctx.sfx("swing", 0.7)
		end
	end
	st.flash.Brightness = math.max(0, st.flash.Brightness - dt * 14)
	for _, m in st.bolts or {} do
		for _, p in m:GetChildren() do p.Transparency = math.min(1, p.Transparency + dt * 1.4) end
	end
	st.amb = math.max(0, (st.amb or 0) - dt * 6)
	Lighting.Ambient = Color3.fromRGB(10, 8, 30):Lerp(Color3.fromRGB(14, 16, 34), u):Lerp(Color3.fromRGB(150, 190, 230), st.amb)
	local a = -0.7 + u * 0.7 -- the camera swings in from the side under the storm
	return ctx.NEST + Vector3.new(math.sin(a) * 8.6, 2.4 + u * 1.2, -math.cos(a) * 8.6), ctx.NEST + Vector3.new(0, 2.6 + (1 - u) * 1.2, 0), 50 - u * 6
end
function storm.burst(ctx)
	local st = ctx.state
	st.ripple = neon(ctx, Vector3.new(0.1, 1, 1), CFrame.new(ctx.NEST + Vector3.new(0, -0.35, 0)) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(210, 250, 255), 0, Enum.PartType.Cylinder)
	st.ripple2 = neon(ctx, Vector3.new(0.12, 1, 1), st.ripple.CFrame, Color3.fromRGB(90, 220, 255), 1, Enum.PartType.Cylinder)
	for _, c in st.clouds or {} do c.v = (c.p.Position - ctx.NEST) * Vector3.new(1, 0, 1) end
	ctx.sfx("sparkle", 0.9)
end
function storm.reveal(ctx, s, dt)
	local st, rnd = ctx.state, ctx.rnd
	for _, m in st.bolts or {} do
		for _, p in m:GetChildren() do p.Transparency = math.min(1, p.Transparency + dt * 3) end
	end
	if st.ripple then -- a cleansing ring of water light rolls out across the floor
		local u = math.clamp(s / 1.1, 0, 1)
		st.ripple.Size = Vector3.new(0.1, 1 + u * 24, 1 + u * 24)
		st.ripple.Transparency = u
		local u2 = math.clamp((s - 0.25) / 1.1, 0, 1)
		st.ripple2.Size = Vector3.new(0.12, 1 + u2 * 20, 1 + u2 * 20)
		st.ripple2.Transparency = u2 < 0.01 and 1 or u2
	end
	for _, c in st.clouds or {} do
		if c.v then
			c.p.CFrame += c.v * dt * 0.5
			c.p.Transparency = math.min(1, 0.55 + s * 0.35)
		end
	end
	st.petal = (st.petal or 0) + dt * 28 -- petals drift down through the light
	while st.petal >= 1 and s < 5 do
		st.petal -= 1
		local near = rnd:NextNumber() < 0.35 -- some drift right past the lens
		table.insert(st.bits, { p = neon(ctx, Vector3.new(0.34, 0.05, 0.26) * (near and 0.7 or 1), CFrame.new(ctx.NEST + Vector3.new(rnd:NextNumber(-5, 5) * (near and 0.5 or 1), rnd:NextNumber(5.5, 7.5), near and rnd:NextNumber(-6, -4) or rnd:NextNumber(-2, 4))), rnd:NextNumber() < 0.6 and Color3.fromRGB(255, 120, 175) or Color3.fromRGB(255, 200, 225), 0), v = Vector3.new(rnd:NextNumber(-0.6, 0.6), -rnd:NextNumber(1, 1.8), 0), spin = Vector3.new(rnd:NextNumber(-3, 3), rnd:NextNumber(-3, 3), rnd:NextNumber(-3, 3)), life = 4 })
	end
	fly(st.bits or {}, dt)
	Lighting.Ambient = Lighting.Ambient:Lerp(Color3.fromRGB(26, 22, 48), 0.5)
end

-- OURO: the coil ---------------------------------------------------------------------------------------------------------
local coil = { omen = 2.0, tint = PINK }
local SEG = 30
function coil.start(ctx)
	local st = ctx.state
	st.segs, st.bits = {}, {}
	for i = 1, SEG do
		local sz = i == SEG and 0.8 or 0.62 - i / SEG * 0.32 -- the head leads, the tail thins
		table.insert(st.segs, neon(ctx, Vector3.one * sz, CFrame.new(ctx.NEST), i == SEG and PINK:Lerp(WHITE, 0.3) or (i % 3 == 0 and PINK or Color3.fromRGB(150, 70, 200)), 0.05))
	end
	st.glow = ctx.light(ctx.part(ctx.world, Vector3.one * 0.2, CFrame.new(ctx.NEST + Vector3.new(0, 1.8, 0)), WHITE, { Transparency = 1 }), PINK, 12, 0)
	st.segs[SEG].Size = Vector3.new(1.3, 1.0, 1.7) -- the serpent's head: eyes, a jaw and horns (Gemini sg2: the coil read as a hula hoop)
	st.headBits = {}
	local HEAD = {
		{ Vector3.new(0.68, 0.2, 0.35), Vector3.new(0.12, 0.3, 0.36), WHITE },
		{ Vector3.new(-0.68, 0.2, 0.35), Vector3.new(0.12, 0.3, 0.36), WHITE },
		{ Vector3.new(0, -0.62, 0.3), Vector3.new(1.0, 0.24, 1.3), Color3.fromRGB(120, 50, 170) },
		{ Vector3.new(0.45, 0.75, -0.5), Vector3.new(0.16, 0.7, 0.16), PINK },
		{ Vector3.new(-0.45, 0.75, -0.5), Vector3.new(0.16, 0.7, 0.16), PINK },
	}
	for _, d in HEAD do table.insert(st.headBits, { p = neon(ctx, d[2], CFrame.new(ctx.NEST), d[3], 0), off = d[1] }) end
	ctx.sfx("upgrade", 0.5)
end
local function coilRing(ctx, u, r, spin)
	for i, p in ctx.state.segs do
		local a = spin + i / SEG * math.pi * 1.85 -- a gap where the head meets the tail
		p.CFrame = CFrame.new(ctx.NEST + Vector3.new(0, 1.9 + math.sin(a * 2 + u * 6) * 0.25, 0)) * CFrame.Angles(0.35, 0, 0.2) * CFrame.new(math.cos(a) * r, 0, math.sin(a) * r) * CFrame.Angles(0, -a, 0)
	end
	local head = ctx.state.segs[SEG]
	if head then
		for _, b in ctx.state.headBits or {} do b.p.CFrame = head.CFrame * CFrame.Angles(0, -math.pi / 2, 0) * CFrame.new(b.off) end -- the head looks along the coil
	end
end
function coil.step(ctx, u, dt)
	local st = ctx.state
	st.spin = (st.spin or 0) + dt * (2 + u * 7)
	coilRing(ctx, u, 4.6 - u * 2.4, st.spin)
	st.glow.Brightness = u * 3
	st.beat = (st.beat or 0) + dt * (2 + u * 6) -- a heartbeat that quickens
	if st.beat >= 1 then
		st.beat -= 1
		ctx.sfx("hit", 0.5 + u * 0.6)
	end
	Lighting.Ambient = Color3.fromRGB(10, 8, 30):Lerp(Color3.fromRGB(46, 10, 34), u)
	local a = math.sin(u * math.pi) * 1.3 -- the camera circles out and comes back to the front for the hang
	return ctx.NEST + Vector3.new(math.sin(a) * 9, 2.6 + math.sin(u * math.pi) * 1.4, -math.cos(a) * 9), ctx.NEST + Vector3.new(0, 2, 0), 46 - u * 6
end
function coil.burst(ctx)
	local st, rnd = ctx.state, ctx.rnd
	for _, p in st.segs or {} do -- the coil snaps and flies apart
		local out = (p.Position - ctx.NEST) * Vector3.new(1, 0, 1)
		out = out.Magnitude > 0.01 and out.Unit or Vector3.xAxis
		table.insert(st.bits, { p = p, v = out * rnd:NextNumber(8, 14) + Vector3.new(0, rnd:NextNumber(2, 6), -rnd:NextNumber(0, 4)), spin = Vector3.new(6, 4, 8), life = 1.2, fade = 1.2, tr = 0.05 })
	end
	for _, b in st.headBits or {} do table.insert(st.bits, { p = b.p, v = Vector3.new(0, 4, -6), spin = Vector3.new(5, 5, 5), life = 0.8, fade = 0.8 }) end
	st.headBits = {}
	st.segs, st.halo = {}, {}
	st.wave = neon(ctx, Vector3.new(0.14, 1, 1), CFrame.new(ctx.NEST + Vector3.new(0, 2, 0)) * CFrame.Angles(0, math.pi / 2, 0), PINK:Lerp(WHITE, 0.3), 0, Enum.PartType.Cylinder) -- an ouroboros shockwave that rolls at the lens
	for i = 1, 26 do -- the ouroboros halo behind the pet
		table.insert(st.halo, neon(ctx, Vector3.one * 0.01, CFrame.new(ctx.NEST), i % 4 == 0 and PINK or Color3.fromRGB(170, 80, 220), 0.15))
	end
	if st.glow then st.glow.Brightness = 5 end
	ctx.sfx("claim", 0.55)
end
function coil.reveal(ctx, s, dt)
	local st = ctx.state
	fly(st.bits or {}, dt, 12)
	if st.wave then
		local w = math.clamp(s / 0.7, 0, 1)
		st.wave.Size = Vector3.new(0.14, 1 + w * 16, 1 + w * 16)
		st.wave.Transparency = w
	end
	local g = math.clamp((s - 0.3) / 0.5, 0, 1)
	for i, p in st.halo or {} do
		local a = s * 0.6 + i / 26 * math.pi * 1.85 + 0.4
		p.Size = Vector3.one * math.max(0.01, (0.5 - i / 26 * 0.25) * g)
		p.CFrame = CFrame.new(ctx.NEST + Vector3.new(math.cos(a) * 3.3, 3 + math.sin(a) * 3.3, 3)) * CFrame.Angles(0, 0, a)
	end
	if st.glow then st.glow.Brightness = math.max(1.5, 5 - s * 3) end
	Lighting.Ambient = Lighting.Ambient:Lerp(Color3.fromRGB(42, 12, 34), 0.5)
end

-- NINERING: the void -----------------------------------------------------------------------------------------------------
local void = { omen = 2.6, still = true }
function void.start(ctx)
	local st, rnd = ctx.state, ctx.rnd
	st.hid, st.rings, st.stars = {}, {}, {}
	for _, d in ctx.world:GetDescendants() do -- the cave is gone: only the egg is left
		if not d:IsDescendantOf(ctx.egg) then
			if d:IsA("BasePart") and d.Transparency < 1 then
				d.LocalTransparencyModifier = 1
			elseif d:IsA("Light") and d.Enabled then
				d.Enabled = false
			end
		end
	end
	for i = 1, 90 do
		local dir = Vector3.new(rnd:NextNumber(-1, 1), rnd:NextNumber(-0.3, 1), rnd:NextNumber(0.2, 1)).Unit
		table.insert(st.stars, neon(ctx, Vector3.one * rnd:NextNumber(0.08, 0.22), CFrame.new(ctx.NEST + dir * rnd:NextNumber(18, 30)), i % 7 == 0 and GOLD or WHITE, 0.1))
	end
	st.l = ctx.light(ctx.part(ctx.world, Vector3.one * 0.2, CFrame.new(ctx.NEST + Vector3.new(0, 3, -3)), WHITE, { Transparency = 1 }), Color3.fromRGB(255, 236, 190), 10, 0.6)
	if ctx.caption then ctx.caption.Text, ctx.caption.TextColor3 = "???", WHITE end
	ctx.sfx("swing", 0.45)
end
local function goldRing(ctx)
	local m = {}
	for k = 1, 14 do table.insert(m, { p = neon(ctx, Vector3.new(0.1, 0.1, 0.36), CFrame.new(ctx.NEST), GOLD, 0), a = k / 14 * math.pi * 2 }) end
	return m
end
local function placeRing(m, c, face, rad)
	for _, b in m do b.p.CFrame = CFrame.new(c) * face * CFrame.new(math.cos(b.a) * rad, math.sin(b.a) * rad, 0) * CFrame.Angles(0, 0, b.a) end
end
local function facing(a, turn)
	return CFrame.lookAt(Vector3.zero, Vector3.new(math.cos(a), 0, math.sin(a))) * CFrame.Angles(0, turn, 0)
end
function void.step(ctx, u, dt)
	local st = ctx.state
	for i = 1, 9 do
		local at = (i - 1) / 10
		if u >= at and not st.rings[i] then
			st.rings[i] = goldRing(ctx)
			ctx.sfx("sparkle", 0.7 + i * 0.09)
		end
		if st.rings[i] then -- each ring falls into its place in the circle, then turns
			local e = 1 - (1 - math.clamp((u - at) / 0.12, 0, 1)) ^ 3
			local a = i / 9 * math.pi * 2 + u * 0.8
			placeRing(st.rings[i], ctx.NEST + Vector3.new(math.cos(a) * 3.4, 1.8 + (i % 3) * 0.6 + (1 - e) * 9, math.sin(a) * 3.4), facing(a, u * 3 + i), 0.75)
		end
	end
	for i, s in st.stars do s.Transparency = 0.1 + (math.sin(u * 20 + i) + 1) * 0.3 end
	Lighting.Ambient, Lighting.OutdoorAmbient = Color3.new(0, 0, 0), Color3.new(0, 0, 0)
	return ctx.NEST + Vector3.new(0, 2.2 + u * 3, -11.5 + u * 2), ctx.NEST + Vector3.new(0, 1.9, 0), 42
end
function void.burst(ctx)
	local st = ctx.state
	for _, m in st.rings or {} do
		for _, b in m do b.p.Color = WHITE end
	end
	if st.l then st.l.Brightness, st.l.Range = 4, 16 end
	ctx.sfx("claim", 1.3)
	ctx.sfx("sparkle", 0.6)
end
function void.reveal(ctx, s, dt)
	local st = ctx.state
	for i, m in st.rings or {} do -- the nine rings orbit the pet, wide, golden again
		local a = (i - 0.5) / 9 * math.pi * 2 * 0.5 * 2 + s * 0.15
		local w = math.clamp(s / 0.7, 0, 1)
		for _, b in m do b.p.Color = WHITE:Lerp(GOLD, w) end
		-- a wide arch behind the pet, clear of it (stills sg1: nine rings round the pet hid it)
		local arch = ctx.NEST + Vector3.new(0, 3.2, 5.5) + Vector3.new(math.cos(a * 0.5 + 0.2) * 7.2, math.sin(a * 0.5 + 0.2) * 5, 0)
		local near = ctx.NEST + Vector3.new(math.cos(a) * 3.4, 2.6, math.sin(a) * 3.4)
		placeRing(m, near:Lerp(arch, 1 - (1 - w) ^ 3) + Vector3.new(0, math.sin(s * 1.5 + i) * 0.15, 0), CFrame.Angles(0, 0, s * 0.8 + i), 0.7)
	end
	for i, p in st.stars or {} do p.Transparency = 0.1 + (math.sin(s * 6 + i) + 1) * 0.3 end
	if st.l then st.l.Brightness = math.max(1.4, 4 - s * 3) end
	Lighting.Ambient, Lighting.OutdoorAmbient = Color3.fromRGB(12, 10, 26), Color3.fromRGB(12, 10, 26)
end

M.BY_NAME = { Fafnir = hoard, Kirin = storm, Ouro = coil, Ninering = void }
M.BY_RARITY = { Legendary = hoard, Mythic = coil, Secret = void }
function M.get(name, rarity)
	return M.BY_NAME[name] or M.BY_RARITY[rarity]
end
return M
