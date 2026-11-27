-- HatchRare (ReplicatedStorage.Shared.HatchRare): the Rare pets' one-beat hatch vignettes (vault Briefs/Pet Hatch Cutscenes
-- (2026-11-26), tier 1: +1.8 s, one smooth camera move, a local nest prop, a whisper caption). Shared.HatchSignature registers
-- them by name; Shared.HatchScene plays them between the build-up and the hang with the same fields as every signature
-- (omen, fastOmen, tint, start, step -> camPos, look, fov, burst, reveal). Everything is built in ctx.world (HatchScene
-- destroys it). Display only.
--   Shinemane   a star-horse: azure and gold crystal shards sprout round the nest, sparks hop between them, a low push-in
--   Goldbristle the quill-badger: gold nuggets and amber quills burst up through the moss into a crown, the camera trucks past
--   Pixiu       the hoard-warden: four jade lantern pillars rise at the corners, red and gold ribbons pulse between them
local M = {}
local WHITE = Color3.new(1, 1, 1)
local AZURE, GOLD = Color3.fromRGB(110, 190, 255), Color3.fromRGB(255, 206, 84)
local AMBER, JADE, RED = Color3.fromRGB(255, 160, 60), Color3.fromRGB(70, 220, 150), Color3.fromRGB(230, 50, 60)

local function neon(ctx, size, cf, col, tr)
	return ctx.part(ctx.world, size, cf, col, { Material = Enum.Material.Neon, Transparency = tr or 0 })
end
local function fly(list, dt, g)
	for i = #list, 1, -1 do
		local b = list[i]
		b.life -= dt
		if b.life <= 0 then b.p:Destroy() table.remove(list, i)
		else
			b.v += Vector3.new(0, -(g or 0), 0) * dt
			b.p.CFrame = (b.p.CFrame + b.v * dt) * CFrame.Angles(b.spin.X * dt, b.spin.Y * dt, b.spin.Z * dt)
			if b.fade then b.p.Transparency = 1 - math.min(1, b.life / b.fade) end
		end
	end
end
local function confetti(ctx, cols, n, speed)
	local st, rnd = ctx.state, ctx.rnd
	st.bits = st.bits or {}
	for i = 1, n do
		local a = rnd:NextNumber(0, math.pi * 2)
		local v = Vector3.new(math.cos(a), rnd:NextNumber(0.6, 1.4), math.sin(a)) * rnd:NextNumber(speed * 0.5, speed)
		table.insert(st.bits, { p = neon(ctx, Vector3.one * rnd:NextNumber(0.12, 0.28), CFrame.new(ctx.NEST + Vector3.new(0, 2, 0)), cols[i % #cols + 1]), v = v, spin = Vector3.new(6, 4, 5), life = 1.4, fade = 1.4 })
	end
end
local function ring(ctx, col, r0)
	local st = ctx.state
	st.rings = st.rings or {}
	local p = ctx.part(ctx.world, Vector3.new(0.12, r0 * 2, r0 * 2), CFrame.new(ctx.NEST + Vector3.new(0, -0.35, 0)) * CFrame.Angles(0, 0, math.pi / 2), col, { Material = Enum.Material.Neon, Transparency = 0.2, Shape = Enum.PartType.Cylinder })
	table.insert(st.rings, { p = p, r = r0, t = 0 })
end
local function growRings(ctx, dt)
	for i = #(ctx.state.rings or {}), 1, -1 do
		local g = ctx.state.rings[i]
		g.t += dt
		local r = g.r + g.t * 16
		g.p.Size = Vector3.new(0.12, r * 2, r * 2)
		g.p.Transparency = 0.2 + g.t / 0.7
		if g.t > 0.7 then g.p:Destroy() table.remove(ctx.state.rings, i) end
	end
end

-- SHINEMANE: a star falls to run the dark --------------------------------------------------------------------------------
local star = { omen = 1.8, fastOmen = 0.9, tint = AZURE }
function star.start(ctx)
	local st, rnd = ctx.state, ctx.rnd
	if ctx.caption then ctx.caption.Text = "A STAR FELL TO RUN THE DARK." end
	st.shards, st.arcs, st.arcAt = {}, {}, 0
	for i = 1, 10 do -- crystal shards round the nest, buried at first, each a tapering stack of two prisms
		local a = i / 10 * math.pi * 2 + rnd:NextNumber(-0.15, 0.15)
		local r = rnd:NextNumber(2.6, 3.6)
		local base = CFrame.new(ctx.NEST + Vector3.new(math.cos(a) * r, -0.6, math.sin(a) * r)) * CFrame.Angles(math.cos(a) * 0.35, 0, -math.sin(a) * 0.35)
		local h = rnd:NextNumber(1.6, 2.8)
		local col = i % 3 == 0 and GOLD or AZURE
		local lo = ctx.part(ctx.world, Vector3.new(0.6, h, 0.6), base, col, { Material = Enum.Material.Glass, Transparency = 0.2 })
		local hi = neon(ctx, Vector3.new(0.3, h * 0.5, 0.3), base, col:Lerp(WHITE, 0.4))
		table.insert(st.shards, { lo = lo, hi = hi, base = base, h = h })
	end
	ctx.sfx("upgrade", 1.3)
end
function star.step(ctx, u, dt)
	local st, rnd = ctx.state, ctx.rnd
	local rise = math.clamp(u * 1.7, 0, 1)
	for _, s in st.shards do
		local up = s.base * CFrame.new(0, -s.h / 2 + rise * (s.h * 0.95), 0)
		s.lo.CFrame, s.hi.CFrame = up, up * CFrame.new(0, s.h * 0.5, 0)
	end
	st.arcAt += dt
	if st.arcAt > 0.08 and u > 0.25 then -- electric arcs hop between the shard tips and the egg
		st.arcAt = 0
		for _, a in st.arcs do a:Destroy() end
		table.clear(st.arcs)
		for _ = 1, 3 do
			local s = st.shards[rnd:NextInteger(1, #st.shards)]
			local p0, p1 = s.hi.Position, ctx.NEST + Vector3.new(rnd:NextNumber(-0.4, 0.4), 1.6 + rnd:NextNumber(0, 1.4), rnd:NextNumber(-0.4, 0.4))
			local mid = (p0 + p1) / 2 + Vector3.new(rnd:NextNumber(-0.5, 0.5), rnd:NextNumber(0, 0.8), rnd:NextNumber(-0.5, 0.5))
			for _, seg in { { p0, mid }, { mid, p1 } } do
				table.insert(st.arcs, neon(ctx, Vector3.new(0.08, 0.08, (seg[2] - seg[1]).Magnitude), CFrame.lookAt((seg[1] + seg[2]) / 2, seg[2]), Color3.fromRGB(190, 230, 255), 0.1))
			end
		end
	end
	local e = u * u * (3 - 2 * u)
	return ctx.NEST + Vector3.new(0.6, 1.2 + e * 1.0, -9 + e * 2.6), ctx.NEST + Vector3.new(0, 2.4 + e * 1.4, 0), 54 - e * 10 -- a low push-in that tilts up into the light
end
function star.burst(ctx)
	for _, a in ctx.state.arcs or {} do a:Destroy() end
	ctx.state.arcs = {}
	ring(ctx, AZURE, 1.5)
	confetti(ctx, { GOLD, WHITE, AZURE }, 34, 9)
	ctx.sfx("claim", 1.3)
end
function star.reveal(ctx, s, dt)
	fly(ctx.state.bits or {}, dt, 7)
	growRings(ctx, dt)
	for _, sh in ctx.state.shards or {} do sh.hi.Transparency = math.min(1, s * 0.6) sh.lo.Transparency = math.min(1, 0.2 + s * 0.5) end
end

-- GOLDBRISTLE: what gleams beneath wakes the spines --------------------------------------------------------------------
local quills = { omen = 1.8, fastOmen = 0.9, tint = AMBER }
function quills.start(ctx)
	local st, rnd = ctx.state, ctx.rnd
	if ctx.caption then ctx.caption.Text = "WHAT GLEAMS BENEATH WAKES THE SPINES." end
	st.q, st.nug, st.bits = {}, {}, {}
	for i = 1, 14 do -- amber quills that burst up and pin round the nest like a crown, leaning out
		local a = i / 14 * math.pi * 2
		local base = CFrame.new(ctx.NEST + Vector3.new(math.cos(a) * 2.7, -1.6, math.sin(a) * 2.7)) * CFrame.Angles(math.sin(a) * 0.45, 0, -math.cos(a) * 0.45)
		local q = ctx.part(ctx.world, Vector3.new(0.32, 2.6, 0.32), base, i % 2 == 0 and AMBER or Color3.fromRGB(70, 44, 30), { Material = i % 2 == 0 and Enum.Material.Neon or Enum.Material.SmoothPlastic })
		table.insert(st.q, { p = q, base = base, d = rnd:NextNumber(0, 0.35) })
	end
	for i = 1, 9 do
		local a = rnd:NextNumber(0, math.pi * 2)
		local n = ctx.part(ctx.world, Vector3.one * rnd:NextNumber(0.35, 0.6), CFrame.new(ctx.NEST + Vector3.new(math.cos(a) * 1.8, -1.2, math.sin(a) * 1.8)), GOLD, { Material = Enum.Material.Metal, Reflectance = 0.35 })
		table.insert(st.nug, { p = n, a = a })
	end
	ctx.sfx("hit", 1.6)
end
function quills.step(ctx, u, dt)
	local st = ctx.state
	for _, q in st.q do
		local k = math.clamp((u - q.d) / 0.35, 0, 1)
		k = 1 - (1 - k) ^ 3
		q.p.CFrame = q.base * CFrame.new(0, k * 2.4, 0)
	end
	for i, n in st.nug do -- nuggets jostle up out of the moss
		local k = math.clamp(u * 1.4 - i * 0.04, 0, 1)
		n.p.CFrame = CFrame.new(ctx.NEST + Vector3.new(math.cos(n.a) * 1.8, -1.2 + k * 1.1 + math.sin(u * 30 + i) * 0.05, math.sin(n.a) * 1.8)) * CFrame.Angles(u * 3 + i, i, 0)
	end
	local e = u * u * (3 - 2 * u)
	return ctx.NEST + Vector3.new(6 - e * 8, 1.0, -7.5), ctx.NEST + Vector3.new(0, 1.8, 0), 46 -- a ground-level truck from right to left
end
function quills.burst(ctx)
	local st, rnd = ctx.state, ctx.rnd
	for _, n in st.nug do
		local out = (n.p.Position - ctx.NEST) * Vector3.new(1, 0, 1)
		out = out.Magnitude > 0.01 and out.Unit or Vector3.xAxis
		table.insert(st.bits, { p = n.p, v = out * rnd:NextNumber(4, 8) + Vector3.new(0, rnd:NextNumber(6, 10), 0), spin = Vector3.new(8, 3, 6), life = 1.5 })
	end
	st.nug = {}
	confetti(ctx, { GOLD, AMBER, WHITE }, 22, 8)
	ring(ctx, GOLD, 1.2)
	ctx.sfx("claim", 1.5)
end
function quills.reveal(ctx, s, dt)
	fly(ctx.state.bits or {}, dt, 16)
	growRings(ctx, dt)
end

-- PIXIU: the warden of the uncounted hoard ----------------------------------------------------------------------------------
local pillars = { omen = 1.8, fastOmen = 0.9, tint = JADE }
function pillars.start(ctx)
	local st = ctx.state
	if ctx.caption then ctx.caption.Text = "WARDEN OF THE UNCOUNTED HOARD." end
	st.cols, st.ribbons, st.bits = {}, {}, {}
	for i, c in { { -3.4, -3.4 }, { 3.4, -3.4 }, { -3.4, 3.4 }, { 3.4, 3.4 } } do
		local base = CFrame.new(ctx.NEST + Vector3.new(c[1], -4.6, c[2]))
		local parts = {}
		for k, d in { { 1.4, 0.6, JADE:Lerp(Color3.new(0, 0, 0), 0.3) }, { 1.0, 3.0, JADE }, { 1.5, 0.5, GOLD }, { 0.9, 0.9, Color3.fromRGB(255, 120, 90) }, { 1.3, 0.4, GOLD } } do
			table.insert(parts, { p = ctx.part(ctx.world, Vector3.new(d[1], d[2], d[1]), base, d[3], { Material = (k == 4) and Enum.Material.Neon or Enum.Material.SmoothPlastic }), y = 0 })
		end
		local y = 0 -- stack the pillar: plinth, shaft, gold collar, lantern, cap
		for _, q in parts do q.y = y + q.p.Size.Y / 2 y += q.p.Size.Y end
		table.insert(st.cols, { base = base, parts = parts, top = y })
	end
	ctx.sfx("upgrade", 0.9)
end
function pillars.step(ctx, u, dt)
	local st = ctx.state
	local rise = 1 - (1 - math.clamp(u * 1.6, 0, 1)) ^ 3
	for _, c in st.cols do for _, q in c.parts do q.p.CFrame = c.base * CFrame.new(0, q.y + rise * 4.6, 0) end end
	if u > 0.55 and #st.ribbons == 0 then -- silk ribbons strung between the lanterns, red and gold
		for i = 1, 4 do
			local a, b = st.cols[i], st.cols[({ 2, 4, 1, 3 })[i]]
			local p0, p1 = a.base.Position + Vector3.new(0, a.top + 4.6 - 1.3, 0), b.base.Position + Vector3.new(0, b.top + 4.6 - 1.3, 0)
			table.insert(st.ribbons, neon(ctx, Vector3.new(0.14, 0.3, (p1 - p0).Magnitude), CFrame.lookAt((p0 + p1) / 2, p1), i % 2 == 0 and GOLD or RED, 0.2))
		end
	end
	for i, r in st.ribbons do r.Transparency = 0.15 + 0.35 * (0.5 + 0.5 * math.sin(u * 40 + i)) end
	local e = u * u * (3 - 2 * u)
	return ctx.NEST + Vector3.new(0, 1.4 + e * 0.6, -10.5 + e * 3), ctx.NEST + Vector3.new(0, 2.2, 0), 50 -- a regal, symmetrical push between the pillars
end
function pillars.burst(ctx)
	local st, rnd = ctx.state, ctx.rnd
	for _, r in st.ribbons do r:Destroy() end
	st.ribbons = {}
	for _, c in st.cols do -- the pillars dissolve into rising jade motes
		for _, q in c.parts do
			table.insert(st.bits, { p = q.p, v = Vector3.new(rnd:NextNumber(-1, 1), rnd:NextNumber(3, 6), rnd:NextNumber(-1, 1)), spin = Vector3.new(2, 3, 1), life = 1.2, fade = 1.2 })
		end
	end
	st.cols = {}
	ring(ctx, JADE, 1.6)
	confetti(ctx, { JADE, GOLD }, 20, 6)
	ctx.sfx("claim", 1.1)
end
function pillars.reveal(ctx, s, dt)
	fly(ctx.state.bits or {}, dt, -1)
	growRings(ctx, dt)
end

M.BY_NAME = { Shinemane = star, Goldbristle = quills, Pixiu = pillars }
return M
