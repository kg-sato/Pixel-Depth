-- PetVoxels (ReplicatedStorage.Shared.PetVoxels): the 13 voxel pets (2026-11-17, brief: vault Projects/Pixel-_/Briefs/
-- Egg Hatching v3 (2026-11-17).md; designs and build: design3d/pets/pets.py -> build_pets.py -> make_lua.py).
-- Each pet is a Model asset of MeshParts named "<Part>__<Role>". The server loads them once into ReplicatedStorage.PetMeshes
-- (InsertService only runs on the server); the client clones one per pet, paints each MeshPart from the palette (Accent and
-- Ring glow as Neon) and moves the parts every frame about their joints (Shared.PetVoxelsData pivots), so the pets live:
--   * idle: the body breathes, the head nods and looks about, the tail sways, wings tuck and open, rings orbit
--   * moving: the legs swing in pairs, the body bobs on each step, the head and tail lag behind (follow-through, research
--     note Craft Videos for Weak Grades: ears, tails and wings settle after the body stops)
--   * a blink every 3 to 5 s (the Eye and Shine parts flatten for 0.12 s)
-- The model faces -Z like the old cube pets, its pivot (the invisible Root) sits 0.92 studs above the feet as before, so the
-- follow code, PetCompanion and the hatch show keep working. Display only.
local RS = game:GetService("ReplicatedStorage")
local DATA = require(script.Parent:WaitForChild("PetVoxelsData"))
local M = {}
M.DATA = DATA
local GLOW = { Gem = true } -- gems are their own small parts (VOXEL_KEEP=Gem) and glow like Cataclysm's emissive slits; Neon -- Neon bloomed whole manes and rings into white blobs in the game's lighting (capture pets_lineup2); the accent glows through its PointLight instead
local FLIP = CFrame.Angles(0, math.pi, 0) -- the meshes look +Z; the game's pets look -Z
local ROOT_Y = 0.92

-- server: load every pet's meshes into ReplicatedStorage.PetMeshes (once, in the background)
function M.serverLoad()
	local folder = RS:FindFirstChild("PetMeshes") or Instance.new("Folder")
	folder.Name, folder.Parent = "PetMeshes", RS
	local IS = game:GetService("InsertService")
	for name, d in DATA do
		if not folder:FindFirstChild(name) then
			local ok, got = pcall(function() return IS:LoadAsset(d.id) end)
			if ok and got then
				local m = got:FindFirstChildWhichIsA("Model") or got
				m.Name = name
				for _, p in m:GetDescendants() do
					if p:IsA("BasePart") then p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false end
				end
				m.Parent = folder
				if got ~= m then got:Destroy() end
			else
				warn("PetVoxels: could not load", name, got)
			end
		end
	end
	-- the hatch grotto and egg meshes for Shared.HatchScene (design3d/hatch/out/ids.txt)
	local art = RS:FindFirstChild("HatchArt") or Instance.new("Folder")
	art.Name, art.Parent = "HatchArt", RS
	for name, id in { HatchGrotto = 86530287643343, HatchEgg = 75251659522967 } do
		if not art:FindFirstChild(name) then
			local ok, got = pcall(function() return IS:LoadAsset(id) end)
			if ok and got then
				local m = got:FindFirstChildWhichIsA("Model") or got
				m.Name = name
				for _, p in m:GetDescendants() do
					if p:IsA("BasePart") then p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false end
				end
				m.Parent = art
				if got ~= m then got:Destroy() end
			else
				warn("PetVoxels: could not load", name, got)
			end
		end
	end
end

-- PET VFX (2026-11-18, the owner: the pets "still need VFX"; refs: Cataclysm's Ignis and Harbinger glow from emissive slits,
-- fire and sparks; Alex's Mobs give eyes and cores their own light). Each pet's signature part emits something that tells
-- its job: the boar's lantern, the kobold's lamp and crystal pick, the dragon's smoking nostrils, the kirin's cloud hooves
-- and crackling horn, the firebird's burning crest. Legendary and up also wear a soft aura. Points are builder voxels
-- (design3d/pets/pets.py) on a moving part, so the effect rides that part as it animates; Model:ScaleTo scales them too.
local TEX = {
	spark = "rbxasset://textures/particles/sparkles_main.dds",
	smoke = "rbxasset://textures/particles/smoke_main.dds",
	fire = "rbxasset://textures/particles/fire_main.dds",
	glow = "rbxassetid://77591933607769", -- the soft radial glow (art/forge/fx)
	star = "rbxassetid://100737048426546", -- the soft-kit star sprite
	square = "rbxassetid://99045074723360", -- a voxel: hard-edged square sprite (art/fx/voxel_square.png; Gemini: soft flares clashed with the blocks)
	puff = "rbxassetid://106055573888260", -- a blocky smoke puff (art/fx/voxel_puff.png)
}
local function NS(a, b) return NumberSequence.new(a, b) end
local KIND = {
	motes = { tex = "square", size = NS(0.224, 0.0), rate = 7.5, life = NumberRange.new(1.4, 2.4), speed = NumberRange.new(0.2, 0.6), spread = 180, accel = Vector3.new(0, 0.5, 0), trans = NS(0.1, 1), light = 1 },
	sparkle = { tex = "square", size = NS(0.352, 0.0), rate = 4.5, life = NumberRange.new(0.5, 0.9), speed = NumberRange.new(0.3, 0.7), spread = 180, trans = NS(0, 1), light = 1, rot = 120 },
	embers = { tex = "square", size = NS(0.144, 0.0), rate = 13.5, life = NumberRange.new(0.7, 1.3), speed = NumberRange.new(1, 2), spread = 30, accel = Vector3.new(0, 1.2, 0), trans = NS(0, 1), light = 1, drag = 1 },
	smoke = { tex = "puff", size = NS(0.192, 0.8), rate = 6.0, life = NumberRange.new(0.8, 1.4), speed = NumberRange.new(0.6, 1), spread = 12, accel = Vector3.new(0, 0.6, 0), trans = NS(0.45, 1), light = 0, dir = Enum.NormalId.Front },
	flame = { tex = "square", size = NS(0.24, 0.04), rate = 24, life = NumberRange.new(0.35, 0.6), speed = NumberRange.new(1, 1.6), spread = 10, trans = NS(0.1, 1), light = 0.45 }, -- small and not too bright: big squares bloomed white (stills lineup_v7)
	bubbles = { tex = "square", size = NS(0.16, 0.256), rate = 4.5, life = NumberRange.new(1.2, 1.8), speed = NumberRange.new(0.6, 1), spread = 15, accel = Vector3.new(0, 0.4, 0), trans = NS(0.3, 1), light = 0.6 },
	puff = { tex = "puff", size = NS(0.288, 0.8), rate = 6.0, life = NumberRange.new(0.7, 1.1), speed = NumberRange.new(0.1, 0.3), spread = 180, trans = NS(0.35, 1), light = 0.3 },
	zap = { tex = "square", size = NS(0.224, 0.0), rate = 10.5, life = NumberRange.new(0.1, 0.2), speed = NumberRange.new(2, 4), spread = 180, trans = NS(0, 1), light = 1 },
	leaf = { tex = "square", size = NS(0.16, 0.08), rate = 3.0, life = NumberRange.new(1.5, 2.2), speed = NumberRange.new(0.3, 0.5), spread = 180, accel = Vector3.new(0, -0.3, 0), trans = NS(0.1, 1), light = 0.5, rot = 60 },
	coins = { tex = "square", size = NS(0.256, 0.096), rate = 4.5, life = NumberRange.new(0.6, 1), speed = NumberRange.new(0.4, 0.8), spread = 60, accel = Vector3.new(0, -2.5, 0), trans = NS(0, 1), light = 1, rot = 200 },
	dust = { tex = "puff", size = NS(0.6, 1.5), rate = 0, life = NumberRange.new(0.7, 1.1), speed = NumberRange.new(2, 3.2), spread = 85, accel = Vector3.new(0, -1.5, 0), trans = NS(0.1, 1), light = 0.25, drag = 3 }, -- impacts only (PetVoxels.animate)
	aura = { tex = "glow", size = NS(3.84, 3.84), rate = 2.1, life = NumberRange.new(1.6, 2.2), speed = NumberRange.new(0, 0), spread = 0, trans = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.4, 0.82), NumberSequenceKeypoint.new(1, 1) }), light = 1, locked = true },
}
local C3 = Color3.fromRGB
local FX = {
	Tosk = { { "Body", -6, 9, -5, "motes", C3(255, 190, 90), { C3(255, 180, 90), 6, 0.8 } } },
	Kobold = { { "Head", 0, 19, 7, "motes", C3(255, 220, 140), { C3(255, 220, 140), 7, 1 } }, { "ArmR", 11, 10, 1, "sparkle", C3(120, 230, 255), { C3(120, 230, 255), 4, 0.6 } } },
	["Kepri Scarab"] = { { "Head", 0, 15, 8, "sparkle", C3(255, 210, 80) }, { "Body", 0, 9, -3, "motes", C3(255, 200, 80), { C3(255, 200, 80), 5, 0.5 } } },
	Shinemane = { { "Head", 0, 20, 4, "motes", C3(255, 240, 170), { C3(255, 240, 180), 7, 0.9 } }, { "Head", 0, 20, 11, "sparkle", C3(255, 230, 120) } },
	Goldbristle = { { "Body", 0, 12, -1, "coins", C3(255, 210, 70) }, { "Head", 0, 10, 6, "leaf", C3(110, 230, 100) } },
	Pixiu = { { "Head", 0, 6, 9, "coins", C3(255, 210, 70), { C3(255, 210, 90), 4, 0.6 } }, { "Head", 0, 19, 8, "sparkle", C3(255, 230, 120) } },
	Glimwisp = { { "Tail", -5, 15, -9, "flame", C3(90, 255, 220) }, { "Tail", 0, 15, -9, "flame", C3(90, 255, 220), { C3(90, 255, 220), 7, 1 } }, { "Tail", 5, 15, -9, "flame", C3(90, 255, 220) } },
	Selkie = { { "Body", 0, 12, -1, "bubbles", C3(180, 230, 255) }, { "Head", 0, 12, 10, "bubbles", C3(180, 230, 255) } },
	Zharbird = { { "Head", 0, 21, 1, "flame", C3(255, 140, 40), { C3(255, 150, 60), 7, 1.1 } }, { "Tail", 0, 10, -11, "embers", C3(255, 160, 60) } },
	Fafnir = { { "Head", 0, 18, 14, "smoke", C3(120, 110, 110) }, { "Head", 0, 15, 12, "embers", C3(255, 140, 40), { C3(255, 140, 50), 5, 0.7 } }, { "Body", 0, 6, 0, "aura", C3(255, 200, 70) } },
	Kirin = { { "Leg1", -3, 0, 4, "puff", C3(240, 245, 255) }, { "Leg2", 3, 0, 4, "puff", C3(240, 245, 255) }, { "Leg3", -3, 0, -6, "puff", C3(240, 245, 255) }, { "Leg4", 3, 0, -6, "puff", C3(240, 245, 255) },
		{ "Head", 0, 26, 5, "zap", C3(140, 230, 255), { C3(140, 230, 255), 6, 0.8 } }, { "Body", 0, 6, 0, "aura", C3(255, 200, 70) } },
	Ouro = { { "Head", 0, 19, 8, "sparkle", C3(255, 90, 150), { C3(255, 90, 150), 6, 0.8 } }, { "Body", 0, 9, 0, "motes", C3(255, 110, 170) }, { "Body", 0, 6, 0, "aura", C3(255, 70, 130) } },
	Ninering = { { "Body", 0, 16, -3, "sparkle", C3(255, 230, 140), { C3(255, 230, 160), 8, 1 } }, { "Body", 0, 9, 4, "motes", C3(130, 230, 255) }, { "Body", 0, 6, 0, "aura", C3(255, 255, 255) } },
}
local function addFx(m, name, d, rig)
	local list = FX[name]
	if not list or not d.cx then return end
	list = table.clone(list)
	table.insert(list, { "Body", d.cx - 0.5, 0, d.cz - 0.5, "dust", Color3.fromRGB(232, 218, 196) }) -- under the middle of the pet
	for _, f in list do
		local part, x, y, z, kind, col, li = f[1], f[2], f[3], f[4], f[5], f[6], f[7]
		local host, best = nil, math.huge -- the nearest segment of that part (tails and wings are chains: Tail, Tail2, Tail3)
		local P0 = (FLIP * CFrame.new((x + 0.5 - d.cx) * d.vox, (y + 0.5) * d.vox, (z + 0.5 - d.cz) * d.vox)).Position
		for _, g in rig.pieces do
			if (g.part == part or string.match(g.part, "^" .. part .. "%d$")) and g.role ~= "Eye" and g.role ~= "Shine" then
				local dd = (g.p.Position - P0).Magnitude
				if dd < best then host, best = g.p, dd end
			end
		end
		local k = KIND[kind]
		if host and k then
			local P = (FLIP * CFrame.new((x + 0.5 - d.cx) * d.vox, (y + 0.5) * d.vox, (z + 0.5 - d.cz) * d.vox)).Position -- the pet's frame: feet at 0, looking -Z
			local att = Instance.new("Attachment")
			att.Name = "Fx_" .. kind
			if kind == "dust" then att.Position = host.CFrame:PointToObjectSpace(Vector3.new(0, 0.05, 0)) end -- the feet, centred
			att.Position = host.CFrame:PointToObjectSpace(P)
			att.Parent = host
			local e = Instance.new("ParticleEmitter")
			e.Texture, e.Color, e.Size, e.Transparency = TEX[k.tex], ColorSequence.new(col), k.size, k.trans
			e.Rate, e.Lifetime, e.Speed, e.SpreadAngle = k.rate, k.life, k.speed, Vector2.new(k.spread, k.spread)
			e.Acceleration, e.Drag, e.LightEmission, e.LightInfluence = k.accel or Vector3.zero, k.drag or 0, k.light, 0
			e.EmissionDirection, e.LockedToPart = k.dir or Enum.NormalId.Top, k.locked == true
			if k.rot then e.RotSpeed, e.Rotation = NumberRange.new(-k.rot, k.rot), NumberRange.new(0, 360)
			elseif k.tex == "square" then e.Rotation, e.RotSpeed = NumberRange.new(0, 90), NumberRange.new(-40, 40) end
			if kind == "flame" then e.Color = ColorSequence.new(col:Lerp(Color3.new(1, 1, 1), 0.2), col:Lerp(Color3.fromRGB(120, 20, 10), 0.5)) end -- hot core, darker tips
			if kind == "aura" then e.ZOffset = -1 end
			e.Parent = att
			if li then
				local l = Instance.new("PointLight")
				l.Color, l.Range, l.Brightness, l.Shadows = li[1], li[2], li[3], false
				l.Parent = att
			end
		end
	end
end

-- client: a fresh, painted model for this pet, or nil while its meshes have not arrived
function M.build(name)
	local d = DATA[name]
	local folder = RS:FindFirstChild("PetMeshes")
	local src = d and folder and folder:FindFirstChild(name)
	if not src then return nil end
	local parts = {}
	local lo, hi = Vector3.new(math.huge, math.huge, math.huge), Vector3.new(-math.huge, -math.huge, -math.huge)
	for _, p in src:GetDescendants() do
		if p:IsA("BasePart") then
			table.insert(parts, p)
			local h = p.Size / 2
			lo, hi = lo:Min(p.Position - h), hi:Max(p.Position + h)
		end
	end
	if #parts == 0 then return nil end
	local origin = CFrame.new((lo.X + hi.X) / 2, lo.Y, (lo.Z + hi.Z) / 2) -- the feet, centred (as the voxels were)
	local m = Instance.new("Model")
	m.Name = name
	local root = Instance.new("Part")
	root.Name, root.Size, root.Transparency = "Root", Vector3.new(0.2, 0.2, 0.2), 1
	root.Anchored, root.CanCollide, root.CanQuery, root.CanTouch = true, false, false, false
	root.CFrame = CFrame.new(0, ROOT_Y, 0)
	root.Parent = m
	m.PrimaryPart = root
	local rig = { pieces = {}, piv = {}, seed = math.random() * 10, w = 0, lastPos = nil, scale0 = 1, hasNeck = d.pivots.Neck ~= nil }
	for _, p in parts do
		local c = p:Clone()
		local part, role = string.match(p.Name, "^(.-)__(.+)$")
		part, role = part or "Body", role or "Main"
		c.Name = part == "Head" and role == "Main" and "Head" or (part .. "_" .. role) -- PetCompanion looks for "Head"
		if role ~= "Tex" then c.Color = d.palette[role] or Color3.new(1, 1, 1) end -- "Tex": a baked texture (colour, voxel occlusion, edge light) covers the part
		c.Material = GLOW[role] and Enum.Material.Neon or Enum.Material.SmoothPlastic
		if GLOW[role] then c.Color = c.Color:Lerp(Color3.new(0, 0, 0), 0.35) end -- a dimmer Neon: full colour blew Shinemane's star into a white square (Gemini lineup_after)
		c.Anchored, c.CanCollide, c.CanQuery, c.CanTouch, c.CastShadow = true, false, false, false, false
		local rest = FLIP * origin:ToObjectSpace(p.CFrame) -- in the pet's own frame: feet at 0, looking -Z
		local piv = d.pivots[part]
		piv = piv and (FLIP * CFrame.new(piv)).Position or Vector3.zero
		table.insert(rig.pieces, { p = c, part = part, role = role, rest = rest, piv = piv, size = c.Size })
		rig.piv[part] = piv
		c.CFrame = CFrame.new(0, 0, 0) * rest
		c.Parent = m
	end
	for _, g in rig.pieces do
		if g.role == "Accent" and g.part == "Body" and not rig.light then -- the signature glow lights the pet's feet a little
			local l = Instance.new("PointLight")
			l.Color, l.Range, l.Brightness = d.palette.Accent, 4, 0.35 -- soft: brighter lights washed out faces and white coats (Gemini n17_hatch)
			l.Parent = g.p
			rig.light = l
		end
	end
	addFx(m, name, d, rig)
	m:SetAttribute("Voxel", true)
	M.rigs[m] = rig
	m.WorldPivot = root.CFrame
	return m
end
M.rigs = setmetatable({}, { __mode = "k" })

-- IDLE ACTIONS (2026-11-18, the owner: "add motion"; vault Research/3D and Art/Minecraft Mod Mob Quality (2026-11-18).md:
-- Minecraft Legends moved to keyframed idles so every mob has its own). While a pet stands still it plays a short keyframed
-- action every 4 to 8 s, picked from its own set: the dragon roars (head up, wings out, a puff from every emitter), the
-- horses rear, the kobold raises its pickaxe and slams it down, the firebird flaps, the spirit fox fans its tails. Keys are
-- { u (0..1 of the action), value } eased with smoothstep. Walking cancels an action smoothly (its weight is 1 - w).
local function key(u, pts)
	if u <= pts[1][1] then return pts[1][2] end
	for i = 2, #pts do
		local a, b = pts[i - 1], pts[i]
		if u <= b[1] then
			local x = (u - a[1]) / math.max(b[1] - a[1], 1e-4)
			return a[2] + (b[2] - a[2]) * x * x * (3 - 2 * x)
		end
	end
	return pts[#pts][2]
end
-- each action: dur (s), burst (emit from the pet's effects at this u), and fn(u) -> pose:
--   head = CFrame, root = { pitch, roll, lift, pivotBack (true: rock about the hind feet) }, tail = CFrame,
--   wing = spread (negative raises and spreads, positive folds), armR = CFrame, legF = CFrame (front legs), ring = speed boost
local ACT = {}
ACT.look = { dur = 2.6, fn = function(u)
	return { head = CFrame.Angles(key(u, { { 0, 0 }, { 0.3, 0.12 }, { 0.6, 0.12 }, { 1, 0 } }), key(u, { { 0, 0 }, { 0.18, 0.75 }, { 0.42, 0.75 }, { 0.58, -0.75 }, { 0.84, -0.75 }, { 1, 0 } }), 0) }
end }
ACT.shake = { dur = 0.9, fn = function(u)
	local d = math.sin(u * math.pi * 14) * (1 - u) * key(u, { { 0, 0 }, { 0.1, 1 }, { 1, 1 } })
	return { root = { roll = d * 0.14 }, head = CFrame.Angles(0, 0, -d * 0.3), tail = CFrame.Angles(0, d * 0.8, 0) }
end }
ACT.stomp = { dur = 1.4, fn = function(u) -- lean back, lift, slam, compress, settle with a small overshoot
	local up = key(u, { { 0, 0 }, { 0.12, -0.1 }, { 0.35, 1 }, { 0.45, 1 }, { 0.52, 0 }, { 1, 0 } })
	local hit = key(u, { { 0.48, 0 }, { 0.54, 1 }, { 0.7, -0.3 }, { 0.85, 0 } })
	return { legF = CFrame.Angles(-math.max(up, 0) * 1.1, 0, 0), root = { pitch = up * 0.12 - hit * 0.03, lift = -hit * 0.08, pivotBack = true }, head = CFrame.Angles(-hit * 0.25, 0, 0), squash = hit * 0.08 }
end, impact = 0.53 }
ACT.roar = { dur = 2.1, fn = function(u) -- breathe in (head down, chest swells), roar (head up, wings out, a tremble), overshoot down, settle
	local inh = key(u, { { 0, 0 }, { 0.2, 1 }, { 0.3, 0 } })
	local r = key(u, { { 0.18, 0 }, { 0.32, 1 }, { 0.72, 1 }, { 0.86, -0.15 }, { 1, 0 } })
	local j = math.sin(u * 110) * 0.05 * key(u, { { 0.3, 0 }, { 0.36, 1 }, { 0.7, 1 }, { 0.76, 0 } })
	return { head = CFrame.Angles(r * 0.6 - inh * 0.3 + j, 0, j), root = { pitch = r * 0.1 - inh * 0.06, lift = -inh * 0.05, pivotBack = true }, wing = -math.max(r, 0) * 0.75 + inh * 0.2, tail = CFrame.Angles(r * 0.35, 0, 0), squash = -inh * 0.06 + j * 0.5 }
end, burst = 0.33 }
ACT.flap = { dur = 1.8, fn = function(u) -- crouch with wings cocked, beat up into the air, land and compress
	local c = key(u, { { 0, 0 }, { 0.18, 1 }, { 0.26, 0 } })
	local f = key(u, { { 0.2, 0 }, { 0.3, 1 }, { 0.82, 1 }, { 0.9, 0 } })
	local land = key(u, { { 0.86, 0 }, { 0.91, 1 }, { 1, 0 } })
	return { wing = c * 0.35 - f * (0.5 + math.sin((u - 0.2) * math.pi * 8) * 0.45), root = { lift = -c * 0.12 + f * math.sin(math.clamp((u - 0.25) / 0.6, 0, 1) * math.pi) * 0.4 - land * 0.1 }, head = CFrame.Angles(-c * 0.25 + f * 0.2, 0, 0), squash = c * 0.08 + land * 0.1 - f * 0.04 }
end, impact = 0.9 }
ACT.rear = { dur = 1.9, fn = function(u) -- crouch on the haunches, rise and paw the air, drop hard, settle
	local c = key(u, { { 0, 0 }, { 0.16, 1 }, { 0.24, 0 } })
	local r = key(u, { { 0.16, 0 }, { 0.45, 1 }, { 0.7, 1 }, { 0.8, -0.1 }, { 0.9, 0 } }) -- a slower rise (judge: the kirin snapped up)
	local land = key(u, { { 0.76, 0 }, { 0.81, 1 }, { 0.95, 0 } })
	return { root = { pitch = r * (0.5 + math.sin(u * 20) * 0.04) - c * 0.06, lift = -c * 0.1 - land * 0.08, pivotBack = true }, legF = CFrame.Angles(-math.max(r, 0) * 0.9 + math.sin(u * 28) * 0.35 * math.max(r, 0), 0, 0), head = CFrame.Angles(r * 0.35 - land * 0.2, 0, 0), tail = CFrame.Angles(-r * 0.4, 0, 0), squash = c * 0.07 + land * 0.1 }
end, burst = 0.4, impact = 0.8 }
ACT.armflex = { dur = 1.9, fn = function(u) -- lean back as the pick goes up, hold, slam forward, compress, a small rebound
	local up = key(u, { { 0, 0 }, { 0.38, 1 }, { 0.52, 1 }, { 0.6, -0.25 }, { 0.75, 0.12 }, { 1, 0 } })
	local hit = key(u, { { 0.56, 0 }, { 0.61, 1 }, { 0.85, 0 } })
	local lean = key(u, { { 0, 0 }, { 0.38, -1 }, { 0.52, -1 }, { 0.6, 0.8 }, { 0.8, 0 } })
	return { armR = CFrame.Angles(up * 2.5, 0, 0), root = { pitch = lean * 0.1, lift = -hit * 0.1, pivotBack = true }, head = CFrame.Angles(up * 0.25 - hit * 0.15, 0, 0), squash = hit * 0.1 }
end, impact = 0.6, burst = 0.6 }
ACT.tailfan = { dur = 1.8, fn = function(u)
	local f = key(u, { { 0, 0 }, { 0.2, 1 }, { 0.8, 1 }, { 1, 0 } })
	return { tail = CFrame.Angles(f * 0.35, math.sin(u * math.pi * 4) * 0.7 * f, 0), head = CFrame.Angles(0, 0, math.sin(u * math.pi * 2) * 0.2 * f) }
end, burst = 0.5 }
ACT.hop = { dur = 1, fn = function(u) -- crouch, spring up, land, compress, settle
	local c = key(u, { { 0, 0 }, { 0.2, 1 }, { 0.28, 0 } })
	local h = math.sin(math.clamp((u - 0.24) / 0.5, 0, 1) * math.pi)
	local land = key(u, { { 0.72, 0 }, { 0.77, 1 }, { 0.95, 0 } })
	return { root = { lift = h * 0.5 - c * 0.12 - land * 0.1 }, head = CFrame.Angles(h * 0.2 - c * 0.2, 0, 0), squash = c * 0.12 + land * 0.12 - h * 0.08 }
end, impact = 0.76 }
ACT.sway = { dur = 2.4, fn = function(u)
	local f = key(u, { { 0, 0 }, { 0.15, 1 }, { 0.85, 1 }, { 1, 0 } })
	return { head = CFrame.Angles(math.sin(u * math.pi * 4) * 0.25 * f, math.sin(u * math.pi * 2) * 0.5 * f, 0) }
end }
ACT.spin = { dur = 2.2, fn = function(u)
	local f = key(u, { { 0, 0 }, { 0.2, 1 }, { 0.8, 1 }, { 1, 0 } })
	return { ring = f * 6, root = { lift = f * 0.25 }, head = CFrame.Angles(f * 0.15, 0, 0) }
end, burst = 0.5 }
local ACTS = {
	Tosk = { "look", "shake", "stomp" }, Kobold = { "look", "armflex", "stomp" }, ["Kepri Scarab"] = { "look", "shake", "hop" },
	Shinemane = { "look", "rear", "shake" }, Goldbristle = { "look", "shake", "hop" }, Pixiu = { "look", "roar", "stomp" },
	Glimwisp = { "look", "tailfan", "hop" }, Selkie = { "look", "roar", "shake" }, Zharbird = { "look", "flap", "roar" },
	Fafnir = { "look", "roar", "flap" }, Kirin = { "look", "rear", "roar" }, Ouro = { "sway", "look", "roar" }, Ninering = { "spin", "look" },
}

-- every frame, after the model was pivoted: pose the parts. now: os.clock(); moving: overrides the speed guess
function M.animate(m, now, dt, moving)
	local rig = M.rigs[m]
	if not rig or not m.PrimaryPart then return end
	dt = math.min(dt or 1 / 60, 1 / 20)
	local root = m.PrimaryPart.CFrame
	local pos = root.Position
	if moving == nil then
		local v = rig.lastPos and (pos - rig.lastPos).Magnitude / math.max(dt, 1e-3) or 0
		moving = v > 2.5
	end
	rig.lastPos = pos
	rig.w += ((moving and 1 or 0) - rig.w) * math.min(1, dt * 6) -- 0 standing .. 1 walking, eased (the lag is the follow-through)
	local w, t, s = rig.w, now + rig.seed, m:GetScale()
	if not rig.backZ then -- the hind end in the pet's frame (+Z is behind), for rearing about the hind feet
		local z = 0
		for _, g in rig.pieces do z = math.max(z, g.rest.Position.Z) end
		rig.backZ = z * 0.7
	end
	-- the idle action: start one now and then while standing, ease it out when the pet walks
	local pose, aw = nil, 1 - w
	if rig.act then
		local a = ACT[rig.act]
		local u = (now - rig.actT) / a.dur
		if u >= 1 + 0.45 / a.dur then -- run on until the last chain segment has settled too (a snap when it was cut at u = 1)
			rig.act, rig.nextAct = nil, now + 3 + math.random() * 3
		else
			pose = a.fn(math.min(u, 1))
			local lag = a.fn(math.clamp(u - 0.14 / a.dur, 0, 1)) -- the tail and the wings lag the body (follow-through)
			pose.tail, pose.wing = lag.tail, lag.wing
			rig.lagFn = function(k) return a.fn(math.clamp(u - 0.14 * k / a.dur, 0, 1)) end -- later segments lag more
			if a.impact and not rig.hit and u >= a.impact then -- a dust ring at the feet on the impact frame
				rig.hit = true
				rig.actT += 0.07 -- hit-stop: the pose holds on the impact frame for a beat
				for _, e in m:GetDescendants() do
					if e:IsA("ParticleEmitter") and e.Parent.Name == "Fx_dust" then e:Emit(26) end
				end
			end
			if a.burst and not rig.burst and u >= a.burst then -- a puff from every effect on the pet on the beat
				rig.burst = true
				for _, e in m:GetDescendants() do
					if e:IsA("ParticleEmitter") and not e.LockedToPart and e.Parent.Name ~= "Fx_dust" then e:Emit(8) end
				end
			end
		end
	elseif w < 0.2 and now >= (rig.nextAct or now + 1) then
		local list = ACTS[m.Name] or { "look" }
		rig.act, rig.actT, rig.burst, rig.hit = list[math.random(#list)], now, false, false
	end
	if not rig.nextAct then rig.nextAct = now + 2 + math.random() * 4 end
	pose = pose or {}
	local rp = pose.root or {}
	local base = root * CFrame.new(0, -ROOT_Y * s, 0) -- the feet
	-- standing, the weight shifts from foot to foot and the body sways a little (judge: idle pets read as frozen statues)
	local idle = 1 - w
	rp = { pitch = (rp.pitch or 0) + math.sin(t * 1.1) * 0.025 * idle / math.max(aw, 0.01), roll = (rp.roll or 0) + math.sin(t * 0.8 + 1) * 0.035 * idle / math.max(aw, 0.01), lift = rp.lift, pivotBack = rp.pivotBack }
	if rp.pitch or rp.roll or rp.lift then
		local P = Vector3.new(0, 0, rp.pivotBack and rig.backZ or 0) * s
		base = base * CFrame.new(0, (rp.lift or 0) * aw * s, 0) * CFrame.new(P) * CFrame.Angles((rp.pitch or 0) * aw, 0, (rp.roll or 0) * aw) * CFrame.new(-P)
	end
	local step = math.sin(t * 11)
	local breathe = math.sin(t * 2.2)
	local bodyLift = (math.abs(step) * 0.06 * w + breathe * 0.025 * (1 - w)) -- studs
	local blink = (t % (3 + rig.seed % 2)) < 0.12
	local twitch = (t % (2.7 + rig.seed % 1.3)) < 0.14 and 0.12 or 0 -- a quick head flick now and then: alive between actions
	-- big crew pets fold their wings by their sides while they walk with you; they open them to flap and to roar
	local foldWant = (s > 1.6 and not pose.wing) and 1 or 0
	rig.fold = (rig.fold or foldWant) + (foldWant - (rig.fold or foldWant)) * math.min(1, dt * 4)
	rig.ringPhase = (rig.ringPhase or 0) + dt * 0.8 * (1 + (pose.ring or 0) * aw)
	-- CHAINS: Tail -> Tail2 -> Tail3, WingL -> WingL2, Neck -> Head (design3d/pets/pets.py add_chains). Each segment's own bend
	-- rides its parent's, and each later segment plays the motion a little later, so a flick or a beat ripples to the tip.
	local lagPose = rig.act and rig.lagFn or nil
	local xf = {}
	local function local_(name)
		local base1, k = string.match(name, "^(%a+)(%d)$")
		k = tonumber(k) or 1
		local stem = base1 or name
		if stem == "Head" or name == "Head" then
			local r = CFrame.Angles(math.sin(t * 1.3) * 0.1 * (1 - w) - step * 0.05 * w, math.sin(t * 0.7) * 0.35 * (1 - w) * (pose.head and 0.3 or 1), math.sin(t * 0.9) * 0.08 + twitch * (1 - w))
			if pose.head then r = r * CFrame.new():Lerp(pose.head, aw) end
			if rig.hasNeck then r = CFrame.new():Lerp(r, 0.65) end -- the neck takes the rest
			return r
		elseif name == "Neck" then
			local r = CFrame.Angles(math.sin(t * 1.3 - 0.5) * 0.06 * (1 - w) + breathe * 0.03 * (1 - w), math.sin(t * 0.7 - 0.4) * 0.15 * (1 - w), 0)
			if pose.head then r = r * CFrame.new():Lerp(pose.head, aw * 0.4) end
			return r
		elseif string.sub(name, 1, 3) == "Leg" then
			local n = tonumber(string.sub(name, 4)) or 1
			local phase = (n % 2 == (n > 2 and 1 or 0)) and 1 or -1 -- diagonal pairs swing together
			local r = CFrame.Angles(step * 0.55 * w * phase, 0, 0)
			if pose.legF and n <= 2 then r = r * CFrame.new():Lerp(pose.legF, aw) end
			return r
		elseif string.sub(name, 1, 3) == "Arm" then
			local r = CFrame.Angles(-step * 0.5 * w + breathe * 0.05, 0, 0)
			if pose.armR and name == "ArmR" then r = r * CFrame.new():Lerp(pose.armR, aw) end
			return r
		elseif stem == "Tail" then -- a wave: each segment swings later and a little further than the one before
			local ph = (k - 1) * 0.9
			local r = CFrame.Angles(0.1 * w / k, math.sin(t * (3 + 5 * w) - ph) * (0.22 + 0.12 * w) * (k == 1 and 1 or 0.8), 0)
			local tp = k == 1 and pose.tail or (lagPose and lagPose(k) or {}).tail
			if tp then r = r * CFrame.new():Lerp(tp, aw / k) end
			return r
		elseif stem == "WingL" or stem == "WingR" or string.sub(name, 1, 3) == "Fin" then
			local side = (stem == "WingL" or name == "FinL") and -1 or 1
			local ph = (k - 1) * 0.8
			local spread = ((k == 1 and pose.wing) or (lagPose and lagPose(k) or {}).wing or 0) * aw * (k == 1 and 1 or 0.5)
			local f = string.sub(name, 1, 4) == "Wing" and rig.fold or 0
			if k == 1 then
				return CFrame.Angles(0, side * 1.1 * f, side * (math.sin(t * (4 + 10 * w) - ph) * (0.18 + 0.3 * w) * (1 - f * 0.7) + spread + 0.3 * f))
			end
			return CFrame.Angles(0, side * 0.3 * f, side * (math.sin(t * (4 + 10 * w) - ph) * (0.12 + 0.2 * w) * (1 - f * 0.7) + spread + 0.35 * f)) -- the outer wing lags and tucks in further
		end
		return CFrame.identity
	end
	local function parentOf(name)
		if name == "Head" and rig.hasNeck then return "Neck" end
		local stem, k = string.match(name, "^(%a+)(%d)$")
		if stem and tonumber(k) >= 2 then return tonumber(k) == 2 and stem or (stem .. (tonumber(k) - 1)) end
		return nil
	end
	local function xfOf(name) -- the part's transform in the pet's frame (studs at scale s), parents first
		if xf[name] then return xf[name] end
		local pv = (rig.piv[name] or Vector3.zero) * s
		local own = CFrame.new(pv) * local_(name) * CFrame.new(-pv)
		local par = parentOf(name)
		local r = par and xfOf(par) * own or own
		xf[name] = r
		return r
	end
	for _, g in rig.pieces do
		local name = g.part
		local lift = string.sub(name, 1, 3) == "Leg" and 0 or bodyLift
		if string.sub(name, 1, 4) == "Ring" then -- the nine rings orbit and bob about the spirit
			local n = tonumber(string.sub(name, 5)) or 1
			local a = rig.ringPhase
			local off = Vector3.new(g.piv.X, 0, g.piv.Z)
			local turned = CFrame.Angles(0, a, 0) * off
			g.p.CFrame = base * CFrame.new(turned.X * s, (g.piv.Y + math.sin(t * 2 + n) * 0.12 + bodyLift) * s, turned.Z * s) * CFrame.Angles(0, a + n, 0) * (CFrame.new(-g.piv) * g.rest).Rotation
			continue
		end
		local cf = base * CFrame.new(0, lift * s, 0) * xfOf(name) * (g.rest.Rotation + g.rest.Position * s)
		if g.role == "Eye" or g.role == "Shine" then
			local want = blink and Vector3.new(g.size.X, g.size.Y * 0.15, g.size.Z) or g.size
			if g.p.Size ~= want * s then g.p.Size = want * s end
		elseif name == "Body" and g.role == "Tex" then -- the chest breathes
			local sq = (pose.squash or 0) * aw -- squash and stretch: down and wide on impacts, tall on the leap
			local b = 1 + (1 - w) * 0.035 * (breathe + 1) * 0.5 -- breathing reads at game size (judge: no visible breath at 1.8%)
			local want = g.size * s * Vector3.new(b * (1 + sq * 0.5), b * (1 - sq), b * (1 + sq * 0.5))
			if (g.p.Size - want).Magnitude > 1e-3 then g.p.Size = want end
		end
		g.p.CFrame = cf
	end
end

return M
