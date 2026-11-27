-- HatchEpic (ReplicatedStorage.Shared.HatchEpic): the Epic pets' two-shot hatch vignettes (vault Briefs/Pet Hatch Cutscenes
-- (2026-11-26), tier 2: +3.2 s, a wide establishing shot then a hard cut to a close orbit, a colour grade and floating voxel set
-- props). Registered by Shared.HatchSignature; same fields as every signature. The grade is a ColorCorrectionEffect under the
-- camera that dies with ctx.world. Display only.
--   Glimwisp  lanterns: the cave dims to indigo, eighteen seafoam and magenta lanterns drift up; then foxfire coils into the egg
--   Selkie    tide: caustic rings sweep the floor, bubbles rise; then the camera surfaces as the bubbles close into a dome
--   Zharbird  ember: the nest cracks with magma veins, ash drifts up; then a spiral of ember feathers whips round the egg
local M = {}
local WHITE = Color3.new(1, 1, 1)
local SEAFOAM, MAGENTA, TEAL, CORAL = Color3.fromRGB(120, 255, 214), Color3.fromRGB(255, 90, 200), Color3.fromRGB(70, 200, 230), Color3.fromRGB(255, 140, 120)
local EMBER, CRIMSON, ASH = Color3.fromRGB(255, 140, 40), Color3.fromRGB(220, 40, 40), Color3.fromRGB(70, 64, 70)
local CUT = 0.48 -- the hard cut between the two shots

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
local function grade(ctx, tint, sat, bright)
	local cc = Instance.new("ColorCorrectionEffect")
	cc.TintColor, cc.Saturation, cc.Brightness = tint, sat or 0, bright or 0
	cc.Parent = workspace.CurrentCamera
	ctx.world.Destroying:Connect(function() cc:Destroy() end)
	ctx.state.grade = cc
	return cc
end
local function burst(ctx, cols, n, speed, g)
	local st, rnd = ctx.state, ctx.rnd
	st.bits = st.bits or {}
	for i = 1, n do
		local a = rnd:NextNumber(0, math.pi * 2)
		local v = Vector3.new(math.cos(a), rnd:NextNumber(0.4, 1.4), math.sin(a)) * rnd:NextNumber(speed * 0.5, speed)
		table.insert(st.bits, { p = neon(ctx, Vector3.one * rnd:NextNumber(0.15, 0.32), CFrame.new(ctx.NEST + Vector3.new(0, 2, 0)), cols[i % #cols + 1]), v = v, spin = Vector3.new(5, 4, 6), life = 1.5, fade = 1.5 })
	end
	st.g = g
end

-- GLIMWISP: mist remembers where the lost walked ----------------------------------------------------------------------------
local lanterns = { omen = 3.2, fastOmen = 0.9, tint = SEAFOAM }
function lanterns.start(ctx)
	local st, rnd = ctx.state, ctx.rnd
	if ctx.caption then ctx.caption.Text = "MIST REMEMBERS WHERE THE LOST WALKED." end
	grade(ctx, Color3.fromRGB(176, 170, 255), -0.15, -0.05)
	st.lan, st.fox = {}, {}
	for i = 1, 18 do -- little voxel lanterns: a glowing core under a dark cap, drifting up from below at their own pace
		local a, r = rnd:NextNumber(0, math.pi * 2), rnd:NextNumber(1.5, 7)
		local col = i % 2 == 0 and SEAFOAM or MAGENTA
		local core = neon(ctx, Vector3.new(0.5, 0.6, 0.5), CFrame.new(ctx.NEST + Vector3.new(math.cos(a) * r, -3 - rnd:NextNumber(0, 4), math.sin(a) * r)), col, 0.1)
		local cap = ctx.part(ctx.world, Vector3.new(0.7, 0.16, 0.7), core.CFrame * CFrame.new(0, 0.38, 0), Color3.fromRGB(40, 30, 60))
		table.insert(st.lan, { core = core, cap = cap, v = rnd:NextNumber(1.6, 3), sway = rnd:NextNumber(0, 6) })
	end
	for i = 1, 16 do table.insert(st.fox, neon(ctx, Vector3.one * 0.34, CFrame.new(ctx.NEST), i % 2 == 0 and TEAL or CORAL, 0.15)) end
	ctx.sfx("upgrade", 1.1)
end
function lanterns.step(ctx, u, dt)
	local st = ctx.state
	for _, l in st.lan do
		local p = l.core.Position + Vector3.new(math.sin(u * 6 + l.sway) * 0.3 * dt, l.v * dt, 0)
		l.core.CFrame = CFrame.new(p) * CFrame.Angles(0, u * 2 + l.sway, 0)
		l.cap.CFrame = l.core.CFrame * CFrame.new(0, 0.38, 0)
	end
	local k = math.clamp((u - 0.35) / 0.65, 0, 1) -- the foxfire ribbon orbits faster and closes on the egg
	for i, f in st.fox do
		local a = u * (6 + k * 22) + i * 0.4
		local r = 4.2 - k * 3.2
		f.CFrame = CFrame.new(ctx.NEST + Vector3.new(math.cos(a) * r, 1.6 + math.sin(a * 0.5 + i) * 0.6, math.sin(a) * r))
		f.Transparency = 0.6 - k * 0.5
	end
	if u < CUT then -- shot 1: wide and low, looking up through the rising lanterns
		return ctx.NEST + Vector3.new(-1.5, 0.4, -11.5), ctx.NEST + Vector3.new(0, 4.5, 0), 62
	end
	local v = (u - CUT) / (1 - CUT) -- shot 2: a close glide round the egg, 28 degrees to -10
	local a = math.rad(28 - v * 38)
	return ctx.NEST + Vector3.new(math.sin(a) * 6.5, 2.2, -math.cos(a) * 6.5), ctx.NEST + Vector3.new(0, 1.9, 0), 46
end
function lanterns.burst(ctx)
	for _, f in ctx.state.fox or {} do f:Destroy() end
	ctx.state.fox = {}
	burst(ctx, { SEAFOAM, CORAL, WHITE, MAGENTA }, 36, 8, 3)
	ctx.sfx("claim", 1.25)
end
function lanterns.reveal(ctx, s, dt)
	local st = ctx.state
	fly(st.bits or {}, dt, st.g)
	if st.grade then st.grade.Saturation = math.min(0, -0.15 + s * 0.2) end
	for _, l in st.lan or {} do
		l.core.CFrame = l.core.CFrame + Vector3.new(0, l.v * dt, 0)
		l.cap.CFrame = l.core.CFrame * CFrame.new(0, 0.38, 0)
	end
end

-- SELKIE: deeper than torches dared swim ------------------------------------------------------------------------------------
local tide = { omen = 3.2, fastOmen = 0.9, tint = TEAL }
function tide.start(ctx)
	local st, rnd = ctx.state, ctx.rnd
	if ctx.caption then ctx.caption.Text = "DEEPER THAN TORCHES DARED SWIM." end
	grade(ctx, Color3.fromRGB(170, 236, 255), 0.05, -0.04)
	st.rings, st.bub, st.ringAt = {}, {}, 0
	for i = 1, 26 do
		local a, r = rnd:NextNumber(0, math.pi * 2), rnd:NextNumber(1, 6)
		local b = ctx.part(ctx.world, Vector3.one * rnd:NextNumber(0.2, 0.45), CFrame.new(ctx.NEST + Vector3.new(math.cos(a) * r, rnd:NextNumber(-0.5, 3), math.sin(a) * r)), Color3.fromRGB(220, 250, 255), { Material = Enum.Material.Neon, Transparency = 0.55 }) -- lit bubbles: Glass read as dark cubes in the cave
		table.insert(st.bub, { p = b, a = a, r = r, y = b.Position.Y - ctx.NEST.Y, v = rnd:NextNumber(0.8, 1.8), dome = Vector3.new(rnd:NextNumber(-1, 1), rnd:NextNumber(0.1, 1), rnd:NextNumber(-1, 1)).Unit })
	end
	ctx.sfx("hit", 0.7)
end
function tide.step(ctx, u, dt)
	local st = ctx.state
	st.ringAt += dt
	if st.ringAt > 0.45 and u < 0.85 then -- caustic rings sweep across the floor
		st.ringAt = 0
		table.insert(st.rings, { p = ctx.part(ctx.world, Vector3.new(0.08, 1, 1), CFrame.new(ctx.NEST + Vector3.new(0, -0.45, 0)) * CFrame.Angles(0, 0, math.pi / 2), TEAL, { Material = Enum.Material.Neon, Transparency = 0.3, Shape = Enum.PartType.Cylinder }), t = 0 })
	end
	for i = #st.rings, 1, -1 do
		local g = st.rings[i]
		g.t += dt
		g.p.Size = Vector3.new(0.08, 1 + g.t * 14, 1 + g.t * 14)
		g.p.Transparency = 0.3 + g.t / 1.1
		if g.t > 1.1 then g.p:Destroy() table.remove(st.rings, i) end
	end
	local k = math.clamp((u - CUT) / (1 - CUT), 0, 1)
	for _, b in st.bub do -- rising bubbles that, in the second shot, close into a copper-lit dome round the egg
		b.y += b.v * dt * (1 - k)
		if b.y > 5 then b.y = -0.5 end
		local free = ctx.NEST + Vector3.new(math.cos(b.a) * b.r, b.y, math.sin(b.a) * b.r)
		local dome = ctx.NEST + Vector3.new(0, 1.6, 0) + b.dome * 2.8
		b.p.CFrame = CFrame.new(free:Lerp(dome, k * k))
		b.p.Color = Color3.fromRGB(220, 250, 255):Lerp(Color3.fromRGB(255, 180, 110), k * 0.6)
	end
	if u < CUT then -- shot 1: high over the pool, the rings sweeping under
		return ctx.NEST + Vector3.new(4, 8, -8), ctx.NEST + Vector3.new(0, 0, 0), 58
	end
	local v = (u - CUT) / (1 - CUT) -- shot 2: the camera surfaces, rising and closing in
	return ctx.NEST + Vector3.new(1.2, 0.2 + v * 2.4, -7.5 + v * 1.5), ctx.NEST + Vector3.new(0, 1.8, 0), 62 - v * 17
end
function tide.burst(ctx)
	local st, rnd = ctx.state, ctx.rnd
	for _, b in st.bub or {} do
		local out = (b.p.Position - ctx.NEST)
		out = out.Magnitude > 0.01 and out.Unit or Vector3.yAxis
		st.bits = st.bits or {}
		table.insert(st.bits, { p = b.p, v = out * rnd:NextNumber(4, 8), spin = Vector3.new(1, 1, 1), life = 1, fade = 1 })
	end
	st.bub = {}
	for i = 1, 24 do -- the splash column
		local p = ctx.part(ctx.world, Vector3.one * 0.3, CFrame.new(ctx.NEST + Vector3.new(rnd:NextNumber(-0.6, 0.6), 0.5, rnd:NextNumber(-0.6, 0.6))), i % 3 == 0 and TEAL or Color3.fromRGB(235, 250, 255), { Material = Enum.Material.Neon, Transparency = 0.2 })
		table.insert(st.bits, { p = p, v = Vector3.new(rnd:NextNumber(-2, 2), rnd:NextNumber(10, 16), rnd:NextNumber(-2, 2)), spin = Vector3.new(3, 2, 4), life = 1.3, fade = 1.3 })
	end
	st.g = 22
	ctx.sfx("claim", 1.0)
end
function tide.reveal(ctx, s, dt)
	fly(ctx.state.bits or {}, dt, ctx.state.g)
	if ctx.state.grade then ctx.state.grade.Brightness = -0.04 + math.min(0.04, s * 0.04) end
end

-- ZHARBIRD: from cold slag, the first spark ---------------------------------------------------------------------------------
local ember = { omen = 3.2, fastOmen = 0.9, tint = EMBER }
function ember.start(ctx)
	local st, rnd = ctx.state, ctx.rnd
	if ctx.caption then ctx.caption.Text = "FROM COLD SLAG, THE FIRST SPARK." end
	grade(ctx, Color3.fromRGB(255, 200, 186), 0.1, -0.06)
	st.veins, st.ash, st.feath = {}, {}, {}
	for i = 1, 9 do -- magma fissures that crack outward from the nest
		local a = i / 9 * math.pi * 2 + rnd:NextNumber(-0.2, 0.2)
		table.insert(st.veins, { a = a, len = rnd:NextNumber(4, 7), p = neon(ctx, Vector3.new(0.22, 0.06, 0.1), CFrame.new(ctx.NEST), i % 2 == 0 and EMBER or CRIMSON, 0.05) })
	end
	for i = 1, 26 do
		table.insert(st.ash, { p = ctx.part(ctx.world, Vector3.one * rnd:NextNumber(0.12, 0.22), CFrame.new(ctx.NEST + Vector3.new(rnd:NextNumber(-6, 6), rnd:NextNumber(-1, 4), rnd:NextNumber(-6, 6))), ASH), v = rnd:NextNumber(0.6, 1.6) })
	end
	for i = 1, 20 do
		local w = Instance.new("WedgePart") -- an ember feather: a thin wedge, amber or crimson
		w.Size, w.Anchored, w.CanCollide, w.CanQuery, w.CanTouch, w.CastShadow = Vector3.new(0.12, 0.5, 1.4), true, false, false, false, false
		w.Material, w.Color, w.Transparency = Enum.Material.Neon, i % 2 == 0 and EMBER or CRIMSON, 1
		w.Parent = ctx.world
		table.insert(st.feath, w)
	end
	ctx.sfx("upgrade", 0.6)
end
function ember.step(ctx, u, dt)
	local st = ctx.state
	for _, v in st.veins do -- the fissures lengthen across the floor
		local l = v.len * math.clamp(u * 1.8, 0, 1)
		local dir = Vector3.new(math.cos(v.a), 0, math.sin(v.a))
		v.p.Size = Vector3.new(0.22, 0.06, math.max(0.1, l))
		v.p.CFrame = CFrame.lookAt(ctx.NEST + Vector3.new(0, -0.5, 0) + dir * (1.4 + l / 2), ctx.NEST + Vector3.new(0, -0.5, 0) + dir * 10)
	end
	for _, a in st.ash do a.p.CFrame = (a.p.CFrame + Vector3.new(0, a.v * dt, 0)) * CFrame.Angles(dt, dt * 2, 0) end
	local k = math.clamp((u - CUT) / (1 - CUT), 0, 1)
	for i, f in st.feath do -- the spiral pillar of feathers whips tighter round the egg
		local a = u * (8 + k * 26) + i * 0.62
		local r = 3.4 - k * 1.6
		local y = 0.2 + (i / #st.feath) * 4.6
		f.Transparency = 1 - k * 0.9
		f.CFrame = CFrame.lookAt(ctx.NEST + Vector3.new(math.cos(a) * r, y, math.sin(a) * r), ctx.NEST + Vector3.new(math.cos(a + 0.6) * r, y + 0.3, math.sin(a + 0.6) * r))
	end
	if u < CUT then -- shot 1: a side-on close-up along the cracking floor
		return ctx.NEST + Vector3.new(-6.5, 1.0, -3.5), ctx.NEST + Vector3.new(0, 1.0, 0), 50
	end
	local v = (u - CUT) / (1 - CUT) -- shot 2: low, tilting steeply up into the spiral
	return ctx.NEST + Vector3.new(0.5, 0.4, -6.8), ctx.NEST + Vector3.new(0, 2 + v * 4, 0), 58
end
function ember.burst(ctx)
	local st = ctx.state
	for _, f in st.feath or {} do f:Destroy() end
	st.feath = {}
	for s = -1, 1, 2 do -- a wing-spread shadow flashes across the light
		local w = Instance.new("WedgePart")
		w.Size, w.Anchored, w.CanCollide, w.CanQuery, w.CanTouch, w.CastShadow = Vector3.new(0.2, 3.2, 6), true, false, false, false, false
		w.Material, w.Color, w.Transparency = Enum.Material.SmoothPlastic, Color3.fromRGB(20, 6, 6), 0.1
		w.CFrame = CFrame.new(ctx.NEST + Vector3.new(s * 3.4, 3.6, 0.8)) * CFrame.Angles(0, s * math.pi / 2, s * 0.35)
		w.Parent = ctx.world
		st.wings = st.wings or {}
		table.insert(st.wings, w)
	end
	burst(ctx, { EMBER, CRIMSON, Color3.fromRGB(255, 230, 140) }, 40, 9, 5)
	ctx.sfx("claim", 0.8)
end
function ember.reveal(ctx, s, dt)
	local st = ctx.state
	fly(st.bits or {}, dt, st.g)
	for _, w in st.wings or {} do w.Transparency = math.min(1, 0.1 + s * 1.4) end
	for _, v in st.veins or {} do v.p.Transparency = math.min(1, 0.05 + s * 0.5) end
end

M.BY_NAME = { Glimwisp = lanterns, Selkie = tide, Zharbird = ember }
return M
