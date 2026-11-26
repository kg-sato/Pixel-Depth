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
	local okR, RIGD = pcall(function() return require(script.Parent:WaitForChild("PetRigData", 5)) end)
	for name, d in DATA do
		if not folder:FindFirstChild(name) then
			local id = okR and RIGD[name] and RIGD[name].id or d.id -- v16: the plate pet replaces the voxel one
			local ok, got = pcall(function() return IS:LoadAsset(id) end)
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

-- Master Directive v15 (@snackdragonstudio's Oakheart, vault Social References Review (2026-11-23)): rare and better pets
-- show thin glowing seams in the cracks between their body plates (two short jagged cracks on each flank of the body, flush
-- on its faces) and a prop that makes their back silhouette their own. Every piece is a rig piece of the Body, so it
-- breathes, sways and rears with it. Neon at a darkened tint and seam-thin: full Neon bloomed manes white (lineup2).
local SEAM = {
	Shinemane = { col = C3(255, 222, 130), prop = "lantern" }, Goldbristle = { col = C3(150, 255, 90), prop = "canopy" },
	Pixiu = { col = C3(255, 196, 80), prop = "ore" }, Fafnir = { col = C3(255, 120, 40), prop = "crest", tint = C3(255, 120, 70) },
	Kirin = { col = C3(110, 230, 255), prop = "crest", tint = C3(150, 230, 255) }, Ouro = { col = C3(205, 120, 255), prop = "crest", tint = C3(190, 120, 255) },
	Ninering = { col = C3(130, 230, 255) },
}
local function seams(m, name, rig)
	local def = SEAM[name]
	if not def then return end
	local body, vol = nil, 0 -- the body plate that carries the cracks: the baked body, else the largest main-coat piece
	for _, g in rig.pieces do
		if g.part == "Body" and (g.role == "Tex" or g.role == "Main") then
			local v = g.size.X * g.size.Y * g.size.Z * (g.role == "Tex" and 10 or 1)
			if v > vol then body, vol = g, v end
		end
	end
	if not body then return end
	local c, h = body.rest.Position, body.size / 2
	local H = h.Y * 2
	local rnd = Random.new(#name * 131 + 7)
	local function piece(size, cf, color, mat, tr)
		local q = Instance.new("Part")
		q.Name, q.Size, q.Color, q.Material, q.Transparency = "Body_Seam", size, color, mat or Enum.Material.Neon, tr or 0
		q.Anchored, q.CanCollide, q.CanQuery, q.CanTouch, q.CastShadow = true, false, false, false, false
		q.CFrame = cf
		q.Parent = m
		table.insert(rig.pieces, { p = q, part = "Body", role = "Seam", rest = cf, piv = rig.piv.Body or Vector3.zero, size = size })
		return q
	end
	local glow = def.col:Lerp(Color3.new(0, 0, 0), 0.3)
	local w = math.max(0.045, H * 0.03)
	for side = -1, 1, 2 do
		local x = c.X + side * (h.X + 0.012)
		for _ = 1, 2 do
			local y, z = c.Y + rnd:NextNumber(-0.35, 0.3) * h.Y, c.Z + rnd:NextNumber(-0.5, 0.5) * h.Z
			local ang = rnd:NextNumber(-1.1, 1.1)
			for k = 1, 3 do -- a jagged crack of three pieces, the last one thinner
				local len = H * rnd:NextNumber(0.13, 0.22)
				local y1, z1 = y + math.sin(ang) * len, z + math.cos(ang) * len
				if math.abs(y1 - c.Y) > h.Y * 0.78 or math.abs(z1 - c.Z) > h.Z * 0.85 then break end
				local a, b = Vector3.new(x, y, z), Vector3.new(x, y1, z1)
				piece(Vector3.new(0.02, k == 3 and w * 0.6 or w, len + w * 0.5), CFrame.lookAt((a + b) / 2, b), glow)
				y, z, ang = y1, z1, ang + rnd:NextNumber(-1.0, 1.0)
			end
		end
	end
	local top, bz = c.Y + h.Y, c.Z + h.Z * 0.1
	if def.prop == "crest" then -- a row of crystal spines down the back, tallest in the middle, each with a glowing core
		for i = 1, 4 do
			local hh = H * (0.42 - math.abs(i - 2.5) * 0.09)
			local zz = c.Z + (i - 2.5) * h.Z * 0.42
			local cf = CFrame.new(c.X, top + hh * 0.32, zz) * CFrame.Angles(0.32, 0, (i % 2 == 0 and 1 or -1) * 0.08)
			piece(Vector3.new(H * 0.13, hh, H * 0.13), cf, def.tint, Enum.Material.Glass, 0.12)
			piece(Vector3.new(H * 0.04, hh * 0.72, H * 0.04), cf, def.col:Lerp(Color3.new(0, 0, 0), 0.35))
		end
	elseif def.prop == "canopy" then -- a little grove on the back: a stub of trunk and three leafy clumps, lighter on top
		local LEAF, LIGHT, BARK = C3(84, 150, 60), C3(132, 200, 84), C3(110, 72, 44)
		piece(Vector3.new(H * 0.1, H * 0.22, H * 0.1), CFrame.new(c.X, top + H * 0.1, bz), BARK, Enum.Material.SmoothPlastic)
		for i, q in { { 0, 0.3, 0, 0.42, 0.22 }, { -0.12, 0.42, 0.08, 0.28, 0.18 }, { 0.1, 0.5, -0.06, 0.24, 0.16 } } do
			piece(Vector3.new(H * q[4], H * q[5], H * q[4]), CFrame.new(c.X + H * q[1], top + H * q[2], bz + H * q[3]) * CFrame.Angles(0, i * 0.5, 0), i == 1 and LEAF or LIGHT, Enum.Material.SmoothPlastic)
		end
		piece(Vector3.new(H * 0.07, H * 0.07, H * 0.07), CFrame.new(c.X + H * 0.16, top + H * 0.34, bz - H * 0.1), def.col:Lerp(Color3.new(0, 0, 0), 0.3)) -- a glowing bud
	elseif def.prop == "lantern" or def.prop == "ore" then -- a pack strapped on: a dark crate, and a glowing lantern or a heap of ore on it
		local WOOD, IRON = C3(96, 64, 42), C3(60, 54, 76)
		piece(Vector3.new(H * 0.34, H * 0.22, H * 0.3), CFrame.new(c.X, top + H * 0.1, bz), WOOD, Enum.Material.WoodPlanks)
		piece(Vector3.new(h.X * 2 + 0.05, H * 0.05, H * 0.06), CFrame.new(c.X, top - H * 0.02, bz), IRON, Enum.Material.Metal) -- the strap over the back
		if def.prop == "lantern" then
			piece(Vector3.new(H * 0.16, H * 0.2, H * 0.16), CFrame.new(c.X, top + H * 0.31, bz), def.col:Lerp(Color3.new(0, 0, 0), 0.3))
			piece(Vector3.new(H * 0.22, H * 0.04, H * 0.22), CFrame.new(c.X, top + H * 0.43, bz), IRON, Enum.Material.Metal)
		else
			for i, q in { { -0.06, 0.04 }, { 0.07, -0.03 }, { 0, 0.02 } } do
				piece(Vector3.new(H * 0.11, H * 0.11, H * 0.11), CFrame.new(c.X + H * q[1], top + H * (0.24 + i * 0.03), bz + H * q[2]) * CFrame.Angles(i, i * 0.7, 0), def.col:Lerp(Color3.new(0, 0, 0), 0.3))
			end
		end
	end
end

local rigBuild, rigAnimate -- the v16 plate pets (defined below, after the action library)
-- client: a fresh, painted model for this pet, or nil while its meshes have not arrived
function M.build(name)
	if rigBuild and M.RIG and M.RIG[name] then return rigBuild(name) end
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
		if role ~= "Tex" and role ~= "Shine" and role ~= "Eye" and c.Color.R + c.Color.G + c.Color.B > 2.55 then -- near-white coats: Shinemane burned into a white block under Camp 1's lanterns (full1119d 147 s, 2026-11-19)
			c.Color = c.Color:Lerp(Color3.fromRGB(150, 144, 172), 0.3)
		end
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
	seams(m, name, rig)
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
-- v16b (the owner 2026-11-25: "move XYZ not just 2 dimensional up and downs"): every act also moves the body sideways (root.x,
-- in body widths), forward and back (root.z, in body lengths, -: forward) and turns it (root.yaw), and one-sided acts get a
-- side (+1 or -1, picked when the act starts): a single front leg stomps (legFL / legFR), the roar sweeps one way first.
ACT.look = { dur = 2.6, fn = function(u) -- a curious look round: the head turns and tilts, the body turns after it, the weight shifts
	local y = key(u, { { 0, 0 }, { 0.18, 0.75 }, { 0.42, 0.75 }, { 0.58, -0.75 }, { 0.84, -0.75 }, { 1, 0 } })
	local tilt = key(u, { { 0, 0 }, { 0.25, 0.22 }, { 0.4, 0.22 }, { 0.5, 0 }, { 0.65, -0.18 }, { 0.8, -0.18 }, { 1, 0 } })
	return { head = CFrame.Angles(key(u, { { 0, 0 }, { 0.3, 0.12 }, { 0.6, 0.12 }, { 1, 0 } }), y, tilt), root = { yaw = y * 0.14, x = y * 0.035, roll = -y * 0.03 }, tail = CFrame.Angles(0, -y * 0.35, 0) }
end }
ACT.shake = { dur = 0.9, fn = function(u) -- a wet-dog shake: the body twists about its spine, the hind end a beat behind the shoulders
	local env = (1 - u) * key(u, { { 0, 0 }, { 0.1, 1 }, { 1, 1 } })
	local d = math.sin(u * math.pi * 14) * env
	local d2 = math.sin(u * math.pi * 14 - 0.9) * env
	return { root = { roll = d * 0.16, yaw = d2 * 0.07, x = d * 0.03 }, head = CFrame.Angles(0, d * 0.25, -d * 0.35), tail = CFrame.Angles(0, d2 * 0.9, 0), squash = math.abs(d) * 0.02 }
end }
ACT.stomp = { dur = 1.4, fn = function(u, side) -- weight onto three legs, one front leg rises and slams, the body drops, settles
	side = side or 1
	local up = key(u, { { 0, 0 }, { 0.12, -0.1 }, { 0.35, 1 }, { 0.45, 1 }, { 0.52, 0 }, { 1, 0 } })
	local hit = key(u, { { 0.48, 0 }, { 0.54, 1 }, { 0.7, -0.3 }, { 0.85, 0 } })
	local leg = CFrame.Angles(-math.max(up, 0) * 1.1, 0, side * math.max(up, 0) * 0.12)
	return { legFL = side < 0 and leg or nil, legFR = side > 0 and leg or nil, root = { pitch = up * 0.09 - hit * 0.03, roll = side * up * 0.05, x = -side * up * 0.04, yaw = side * up * 0.05, lift = -hit * 0.08, pivotBack = true },
		head = CFrame.Angles(-hit * 0.25, -side * up * 0.15, side * up * 0.1), squash = hit * 0.08 }
end, impact = 0.53 }
ACT.roar = { dur = 2.1, fn = function(u, side) -- breathe in (head down, drawn back), roar (lunge, head up and sweeping across), settle
	side = side or 1
	local inh = key(u, { { 0, 0 }, { 0.2, 1 }, { 0.3, 0 } })
	local r = key(u, { { 0.18, 0 }, { 0.32, 1 }, { 0.72, 1 }, { 0.86, -0.15 }, { 1, 0 } })
	local j = math.sin(u * 110) * 0.05 * key(u, { { 0.3, 0 }, { 0.36, 1 }, { 0.7, 1 }, { 0.76, 0 } })
	local sweep = math.sin(math.clamp((u - 0.32) / 0.4, 0, 1) * math.pi * 1.5) * side * 0.35 * math.max(r, 0)
	return { head = CFrame.Angles(r * 0.6 - inh * 0.3 + j, sweep, j - sweep * 0.3), root = { pitch = r * 0.1 - inh * 0.06, lift = -inh * 0.05, pivotBack = true, z = -r * 0.05 + inh * 0.03, yaw = sweep * 0.2 },
		wing = -math.max(r, 0) * 0.75 + inh * 0.2, tail = CFrame.Angles(r * 0.35, -sweep * 0.5, 0), squash = -inh * 0.06 + j * 0.5 }
end, burst = 0.33 }
ACT.flap = { dur = 1.8, fn = function(u) -- crouch with wings cocked, beat up into the air rocking with each beat, land and compress
	local c = key(u, { { 0, 0 }, { 0.18, 1 }, { 0.26, 0 } })
	local f = key(u, { { 0.2, 0 }, { 0.3, 1 }, { 0.82, 1 }, { 0.9, 0 } })
	local land = key(u, { { 0.86, 0 }, { 0.91, 1 }, { 1, 0 } })
	local beat = math.sin((u - 0.2) * math.pi * 8)
	return { wing = c * 0.35 - f * (0.5 + beat * 0.45), root = { lift = -c * 0.12 + f * math.sin(math.clamp((u - 0.25) / 0.6, 0, 1) * math.pi) * 0.4 - land * 0.1, roll = math.sin(u * math.pi * 5) * 0.05 * f, pitch = beat * 0.04 * f, z = -f * 0.03 },
		head = CFrame.Angles(-c * 0.25 + f * 0.2 - beat * 0.05 * f, 0, 0), squash = c * 0.08 + land * 0.1 - f * 0.04 }
end, impact = 0.9 }
ACT.rear = { dur = 1.9, fn = function(u) -- crouch on the haunches, rise and paw the air with alternate hooves, twist, drop hard, settle
	local c = key(u, { { 0, 0 }, { 0.16, 1 }, { 0.24, 0 } })
	local r = key(u, { { 0.16, 0 }, { 0.45, 1 }, { 0.7, 1 }, { 0.8, -0.1 }, { 0.9, 0 } }) -- a slower rise (judge: the kirin snapped up)
	local land = key(u, { { 0.76, 0 }, { 0.81, 1 }, { 0.95, 0 } })
	local up, paw = math.max(r, 0), math.sin(u * 28) * 0.35 * math.max(r, 0)
	return { root = { pitch = r * (0.5 + math.sin(u * 20) * 0.04) - c * 0.06, lift = -c * 0.1 - land * 0.08, pivotBack = true, yaw = math.sin(u * math.pi * 3) * 0.08 * up, roll = math.sin(u * 14) * 0.03 * up },
		legFL = CFrame.Angles(-up * 0.9 + paw, 0, -0.08 * up), legFR = CFrame.Angles(-up * 0.9 - paw, 0, 0.08 * up),
		head = CFrame.Angles(r * 0.35 - land * 0.2, math.sin(u * math.pi * 2) * 0.2 * up, 0), tail = CFrame.Angles(-r * 0.4, math.sin(u * 9) * 0.2 * up, 0), squash = c * 0.07 + land * 0.1 }
end, burst = 0.4, impact = 0.8 }
ACT.armflex = { dur = 1.9, fn = function(u) -- twist back as the pick goes up, hold, slam forward with the whole body, a small rebound
	local up = key(u, { { 0, 0 }, { 0.38, 1 }, { 0.52, 1 }, { 0.6, -0.25 }, { 0.75, 0.12 }, { 1, 0 } })
	local hit = key(u, { { 0.56, 0 }, { 0.61, 1 }, { 0.85, 0 } })
	local lean = key(u, { { 0, 0 }, { 0.38, -1 }, { 0.52, -1 }, { 0.6, 0.8 }, { 0.8, 0 } })
	return { armR = CFrame.Angles(up * 2.5, 0, 0), root = { pitch = lean * 0.1, lift = -hit * 0.1, pivotBack = true, yaw = -lean * 0.12, x = lean * 0.02, z = lean * 0.03 }, head = CFrame.Angles(up * 0.25 - hit * 0.15, lean * 0.1, 0), squash = hit * 0.1 }
end, impact = 0.6, burst = 0.6 }
ACT.tailfan = { dur = 1.8, fn = function(u) -- the tails fan out and sweep while the body sways against them
	local f = key(u, { { 0, 0 }, { 0.2, 1 }, { 0.8, 1 }, { 1, 0 } })
	local sw = math.sin(u * math.pi * 4)
	return { tail = CFrame.Angles(f * 0.35, sw * 0.7 * f, 0), head = CFrame.Angles(0, -sw * 0.15 * f, math.sin(u * math.pi * 2) * 0.2 * f), root = { x = -sw * 0.03 * f, roll = sw * 0.03 * f, yaw = -sw * 0.05 * f } }
end, burst = 0.5 }
ACT.hop = { dur = 1, fn = function(u, side) -- crouch, pounce forward with a playful twist in the air, land, compress, settle back
	side = side or 1
	local c = key(u, { { 0, 0 }, { 0.2, 1 }, { 0.28, 0 } })
	local h = math.sin(math.clamp((u - 0.24) / 0.5, 0, 1) * math.pi)
	local land = key(u, { { 0.72, 0 }, { 0.77, 1 }, { 0.95, 0 } })
	local tw = side * key(u, { { 0.24, 0 }, { 0.5, 0.35 }, { 0.78, 0.3 }, { 1, 0 } })
	return { root = { lift = h * 0.5 - c * 0.12 - land * 0.1, z = -h * 0.1 + c * 0.04, yaw = tw, pitch = -c * 0.06 + h * 0.08 - land * 0.05, roll = -tw * 0.2 }, legF = CFrame.Angles(h * 0.5, 0, 0), head = CFrame.Angles(h * 0.2 - c * 0.2, tw * 0.5, 0), squash = c * 0.12 + land * 0.12 - h * 0.08 }
end, impact = 0.76 }
ACT.sway = { dur = 2.4, fn = function(u) -- a cobra sway: the body weaves, the head draws a figure of eight
	local f = key(u, { { 0, 0 }, { 0.15, 1 }, { 0.85, 1 }, { 1, 0 } })
	return { head = CFrame.Angles(math.sin(u * math.pi * 4) * 0.25 * f, math.sin(u * math.pi * 2) * 0.5 * f, math.sin(u * math.pi * 2) * 0.15 * f), root = { yaw = math.sin(u * math.pi * 2) * 0.12 * f, x = math.sin(u * math.pi * 2 + 0.6) * 0.04 * f, roll = math.sin(u * math.pi * 2 + 1.2) * 0.04 * f } }
end }
ACT.spin = { dur = 2.2, fn = function(u) -- a full turn on the spot as the rings race
	local f = key(u, { { 0, 0 }, { 0.2, 1 }, { 0.8, 1 }, { 1, 0 } })
	return { ring = f * 6, root = { lift = f * 0.25, yaw = math.pi * 2 * key(u, { { 0.15, 0 }, { 0.85, 1 } }), roll = math.sin(u * math.pi * 2) * 0.06 * f }, head = CFrame.Angles(f * 0.15, 0, 0) }
end, burst = 0.5 }
ACT.sniff = { dur = 2.4, fn = function(u, side) -- nose down to the ground, snuffling from side to side, a step in, then back up
	side = side or 1
	local d = key(u, { { 0, 0 }, { 0.2, 1 }, { 0.8, 1 }, { 1, 0 } })
	local sn = math.sin(u * 70) * 0.035 * d
	local sw = math.sin(u * math.pi * 3) * 0.35 * d * side
	return { head = CFrame.Angles(-0.55 * d + sn, sw, sw * 0.2), root = { pitch = -0.07 * d, z = -0.05 * d, yaw = sw * 0.15, x = sw * 0.03 }, legF = CFrame.Angles(0.15 * d, 0, 0), tail = CFrame.Angles(0.15 * d, math.sin(u * math.pi * 6) * 0.3 * d, 0) }
end }
ACT.stretch = { dur = 2.6, fn = function(u) -- a play bow: front legs reach out, chest down, rump up, tail wagging, then a shake-off
	local b = key(u, { { 0, 0 }, { 0.25, 1 }, { 0.7, 1 }, { 0.85, 0 } })
	local wag = math.sin(u * math.pi * 10) * 0.45 * b
	local sh = math.sin(u * math.pi * 30) * key(u, { { 0.8, 0 }, { 0.86, 1 }, { 1, 0 } })
	return { legF = CFrame.Angles(0.75 * b, 0, 0), root = { pitch = -0.16 * b, lift = -0.06 * b, z = -0.04 * b, roll = sh * 0.12, pivotBack = true }, head = CFrame.Angles(0.35 * b, 0, -sh * 0.3 + wag * 0.1), tail = CFrame.Angles(0.4 * b, wag, 0), squash = b * 0.03 }
end }
ACT.preen = { dur = 2.2, fn = function(u, side) -- a bird turns its head right round to its wing and nibbles at the feathers
	side = side or 1
	local f = key(u, { { 0, 0 }, { 0.22, 1 }, { 0.78, 1 }, { 1, 0 } })
	local peck = math.sin(u * 46) * 0.07 * key(u, { { 0.25, 0 }, { 0.3, 1 }, { 0.72, 1 }, { 0.76, 0 } })
	return { head = CFrame.Angles(-0.45 * f + peck, side * 1.25 * f, side * 0.3 * f), root = { roll = side * 0.1 * f, yaw = side * 0.12 * f, x = -side * 0.06 * f }, wing = -0.5 * f + peck * 2, tail = CFrame.Angles(0, -side * 0.3 * f, 0) }
end }
ACT.hero = { dur = 1.65, fn = function(u) -- v15 (Oakheart's hatch showcase): beat 1 (0 to 0.75 s) gathers: a crouch, wings and fins drawn in,
	-- head down, a long inhale; beat 2 (0.75 to 1.65 s) rears onto the hind feet with wings flared wide and a roar, then drops onto the front feet in a burst of dust
	local c = key(u, { { 0, 0 }, { 0.3, 1 }, { 0.44, 1 }, { 0.5, 0 } })
	local r = key(u, { { 0.44, 0 }, { 0.58, 1 }, { 0.8, 1 }, { 0.9, -0.12 }, { 1, 0 } })
	local land = key(u, { { 0.86, 0 }, { 0.9, 1 }, { 1, 0 } })
	local j = math.sin(u * 120) * 0.045 * key(u, { { 0.56, 0 }, { 0.6, 1 }, { 0.78, 1 }, { 0.82, 0 } })
	local up, paw = math.max(r, 0), math.sin(u * 30) * 0.3 * math.max(r, 0)
	return { root = { pitch = r * 0.45 - c * 0.08 + j, lift = -c * 0.14 - land * 0.1, pivotBack = true, yaw = math.sin(u * math.pi * 4) * 0.06 * up, z = c * 0.03 - land * 0.03 }, head = CFrame.Angles(r * 0.28 - c * 0.35 + j, r * 0.25, j),
		wing = c * 0.45 - r * 0.85, tail = CFrame.Angles(-r * 0.35 + c * 0.2, math.sin(u * 12) * 0.2 * up, 0), legFL = CFrame.Angles(-up * 0.9 + paw, 0, -0.06 * up), legFR = CFrame.Angles(-up * 0.9 - paw, 0, 0.06 * up),
		squash = c * 0.1 + land * 0.12 - r * 0.05, charge = c, flare = r }
end, burst = 0.58, impact = 0.9 }
-- the sound of each action on its beat (impact or burst): { name, pitch } from PixelClient's bank (M.sfx); pets far from the
-- camera stay quiet, and a big pet sounds deeper
local ACT_SFX = {
	roar = { { "thud", 0.45 }, { "swing", 0.55 } }, stomp = { { "thud", 0.8 } }, rear = { { "thud", 0.7 }, { "step", 0.8 } },
	armflex = { { "hit", 0.85 }, { "breakRock", 1.2 } }, flap = { { "swing", 1.25 }, { "land", 0.9 } }, hop = { { "land", 1.1 } },
	tailfan = { { "sparkle", 0.9 } }, spin = { { "sparkle", 1.2 } }, shake = { { "step", 1.3 } },
	hero = { { "thud", 0.6 }, { "land", 0.8 } }, heroBurst = { { "swing", 0.5 }, { "sparkle", 0.8 } }, -- v15: the roar sting on the rear-up, the thud on the landing
}
local function actSound(m, act)
	local list = M.sfx and ACT_SFX[act]
	if not list or not m.PrimaryPart then return end
	local d = (workspace.CurrentCamera.CFrame.Position - m.PrimaryPart.Position).Magnitude
	if d > 45 then return end
	local deep = 1 / math.clamp(m:GetScale() ^ 0.3, 1, 1.4)
	for _, sd in list do M.sfx(sd[1], sd[2] * deep) end
end
local ACTS = {
	Tosk = { "look", "shake", "stomp", "sniff" }, Kobold = { "look", "armflex", "stomp", "sniff" }, ["Kepri Scarab"] = { "look", "shake", "hop" },
	Shinemane = { "look", "rear", "shake", "sniff" }, Goldbristle = { "look", "shake", "hop", "stretch" }, Pixiu = { "look", "roar", "stomp", "stretch" },
	Glimwisp = { "look", "tailfan", "hop" }, Selkie = { "look", "roar", "shake" }, Zharbird = { "look", "flap", "roar", "preen" },
	Fafnir = { "look", "roar", "flap", "sniff" }, Kirin = { "look", "rear", "roar", "sniff" }, Ouro = { "sway", "look", "roar" }, Ninering = { "spin", "look" },
}
local QUIET = { look = true, sway = true, sniff = true, stretch = true, preen = true } -- idles that are no signature act

-- ===================================================================================== v16 PLATE PETS (Master Directive v16)
-- The owner's target (the Lure a Pet Showcase video, vault Projects/Pixel-_ ... pets_v16): big armoured creatures with one
-- MeshPart per bone (design3d/pets/pet_plate.py, data in Shared.PetRigData). Tex pieces carry vertex colours (Color stays
-- white so they show as baked), Glow pieces are Neon in the pet's glow colour. Each bone has a parent and a group, and the
-- groups move procedurally: legs walk in diagonal pairs (tripods for six legs), arms swing, wings beat, tails, tendrils and
-- spines ripple, necks and heads look, rings spin on their own axes. The ACT library above drives the clips (look, roar,
-- stomp, flap, rear, spin, hero...) through the same pose fields, so every pet has idle actions and the hatch showcase.
local RIG = (function()
	local ok, r = pcall(function() return require(script.Parent:WaitForChild("PetRigData", 5)) end)
	return ok and r or {}
end)()
M.RIG = RIG
local RIGFX = { -- the v16 voxel pets (design3d/pets/pet_vox.py anchors): orbit = Neon pixel motes circling with trails, the rest emitters
	Tosk = { { "back", "motes", C3(255, 190, 60), { C3(255, 170, 50), 8, 0.5 } }, { "canopy", "leaf", C3(130, 220, 80) },
		{ "tuskL", "orbit", C3(255, 196, 70), { C3(255, 180, 60), 4, 0.3 } }, { "tuskR", "orbit", C3(255, 196, 70), { C3(255, 180, 60), 4, 0.3 } },
		{ "tuskL", "sparkle", C3(255, 210, 110) }, { "tuskR", "sparkle", C3(255, 210, 110) }, { "eyes", "sparkle", C3(255, 170, 50) },
		{ "hoofFL", "motes", C3(255, 190, 70) }, { "hoofFR", "motes", C3(255, 190, 70) }, { "hoofBL", "motes", C3(255, 190, 70) }, { "hoofBR", "motes", C3(255, 190, 70) } },
	Kobold = { { "back", "embers", C3(255, 120, 40), { C3(255, 110, 40), 8, 0.6 } }, { "tail", "orbit", C3(255, 130, 50), { C3(255, 120, 40), 4, 0.3 } },
		{ "tail", "embers", C3(255, 140, 50) }, { "eyes", "sparkle", C3(255, 150, 60) }, { "footL", "dust", C3(200, 140, 100) } },
	["Kepri Scarab"] = { { "gem", "sparkle", C3(80, 255, 180), { C3(60, 255, 170), 6, 0.5 } }, { "gem", "orbit", C3(90, 255, 190) }, { "eyes", "motes", C3(90, 255, 190) } },
	Shinemane = { { "mane", "orbit", C3(110, 240, 255), { C3(100, 230, 255), 8, 0.6 } }, { "mane", "sparkle", C3(140, 245, 255) },
		{ "tail", "motes", C3(120, 240, 255) }, { "tail", "orbit", C3(170, 150, 255) }, { "eyes", "sparkle", C3(140, 245, 255) } },
	Goldbristle = { { "halo", "orbit", C3(255, 210, 70), { C3(255, 200, 70), 6, 0.5 } }, { "back", "coins", C3(255, 210, 70) }, { "eyes", "sparkle", C3(255, 220, 90) } },
	Pixiu = { { "maw", "embers", C3(255, 160, 60), { C3(255, 150, 60), 6, 0.6 } }, { "vault", "coins", C3(255, 210, 80) }, { "tail", "flame", C3(255, 150, 50) },
		{ "tail", "orbit", C3(255, 200, 80) }, { "eyes", "sparkle", C3(255, 90, 110) } },
	Glimwisp = { { "core", "motes", C3(80, 240, 255), { C3(70, 235, 255), 10, 0.9 } }, { "core", "orbit", C3(110, 245, 255) }, { "visor", "sparkle", C3(120, 245, 255) },
		{ "tenA", "motes", C3(90, 240, 255) }, { "tenB", "motes", C3(90, 240, 255) }, { "tenC", "motes", C3(90, 240, 255) }, { "tenD", "motes", C3(90, 240, 255) } },
	Selkie = { { "shell", "bubbles", C3(170, 240, 255), { C3(120, 230, 255), 6, 0.5 } }, { "shell", "orbit", C3(150, 245, 255) }, { "snout", "bubbles", C3(170, 240, 255) } },
	Zharbird = { { "crest", "flame", C3(255, 130, 40), { C3(255, 130, 50), 8, 0.8 } }, { "crest", "orbit", C3(255, 180, 60) }, { "breast", "embers", C3(255, 120, 40) },
		{ "plumeA", "flame", C3(255, 120, 40) }, { "plumeB", "flame", C3(255, 150, 50) }, { "plumeC", "flame", C3(255, 120, 40) } },
	Fafnir = { { "back", "sparkle", C3(190, 120, 255), { C3(170, 110, 255), 10, 0.8 } }, { "back", "orbit", C3(200, 140, 255) }, { "chest", "embers", C3(255, 180, 60) },
		{ "snout", "smoke", C3(120, 110, 120) }, { "tail", "sparkle", C3(190, 120, 255) }, { "tail", "orbit", C3(200, 140, 255) } },
	Kirin = { { "antlers", "sparkle", C3(255, 140, 210), { C3(255, 130, 200), 8, 0.7 } }, { "antlers", "orbit", C3(255, 160, 220) }, { "back", "motes", C3(255, 170, 220) },
		{ "footFL", "motes", C3(120, 255, 190) }, { "footFR", "motes", C3(120, 255, 190) }, { "footBL", "motes", C3(120, 255, 190) }, { "footBR", "motes", C3(120, 255, 190) } },
	Ouro = { { "gem", "sparkle", C3(190, 120, 255), { C3(170, 110, 255), 9, 0.8 } }, { "coil", "motes", C3(200, 150, 255) }, { "coil", "aura", C3(170, 110, 255) }, { "eyes", "sparkle", C3(200, 150, 255) } },
	Ninering = { { "core", "sparkle", C3(90, 230, 255), { C3(80, 220, 255), 12, 1 } }, { "core", "orbit", C3(110, 235, 255) }, { "core", "aura", C3(90, 200, 255) }, { "eyes", "sparkle", C3(120, 235, 255) } },
}

local SIGFX = (function() -- Shared.PetSigFX: the signature effects of each pet, more and richer with rarity
	local ok, r = pcall(function() return require(script.Parent:WaitForChild("PetSigFX", 5)) end)
	return ok and r or nil
end)()
local function anchorAtt(d, rig, anchor) -- an Attachment riding the rig piece nearest one of the pet's anchors
	local a = d.anchors and d.anchors[anchor]
	if not a then return nil end
	local P = (FLIP * CFrame.new(a[2])).Position
	local host, best = nil, math.huge
	for _, g in rig.pieces do
		if g.part == a[1] then
			local dd = (g.p.Position - P).Magnitude
			if dd < best then host, best = g.p, dd end
		end
	end
	if not host then return nil end
	local att = Instance.new("Attachment")
	att.Name = "Fx_sig_" .. anchor
	att.Position = host.CFrame:PointToObjectSpace(P)
	att.Parent = host
	return att, a[1]
end

local RARITY = (function()
	local ok, C = pcall(function() return require(script.Parent:WaitForChild("Config", 5)) end)
	local r = {}
	if ok and C and C.PETS then for n, p in C.PETS do r[n] = p[1] end end
	return r
end)()
local TIER = { Rare = 1, Epic = 1, Legendary = 2, Mythic = 2, Secret = 2 }
local function cube(m, col, sz)
	local q = Instance.new("Part")
	q.Name, q.Size, q.Material, q.Color = "Fx_mote", Vector3.new(sz, sz, sz), Enum.Material.Neon, col
	q.Anchored, q.CanCollide, q.CanQuery, q.CanTouch, q.CastShadow = true, false, false, false, false
	q.Parent = m
	return q
end
local function rigAura(m, name, d, rig) -- the rune ring at the feet, the rising halo, the stomp shockwave (pooled cubes)
	if not d.vox then return end
	local tier = TIER[RARITY[name] or ""] or 0
	local col = d.glow
	local R = math.max(d.size.X, d.size.Z) * 0.42
	rig.aura = { R = R, h = d.height, ring = {}, halo = {}, wave = {}, waveT = -9 }
	if tier >= 1 then for i = 1, 16 do table.insert(rig.aura.ring, cube(m, col, 0.12)) end end
	if tier >= 2 then for i = 1, 14 do table.insert(rig.aura.halo, cube(m, col, 0.1)) end end
	for i = 1, 18 do local q = cube(m, col, 0.14) q.Transparency = 1 table.insert(rig.aura.wave, q) end
end

local function rigFx(m, name, d, rig)
	local list = table.clone(RIGFX[name] or {})
	table.insert(list, { "_feet", "dust", Color3.fromRGB(232, 218, 196) })
	for _, f in list do
		local anchor, kind, col, li = f[1], f[2], f[3], f[4]
		local a = d.anchors and d.anchors[anchor]
		local partName, pos = "Body", Vector3.new(0, 0.05, 0)
		if a then partName, pos = a[1], a[2] end
		local P = (FLIP * CFrame.new(pos)).Position
		local host, best = nil, math.huge
		for _, g in rig.pieces do
			if g.part == partName then
				local dd = (g.p.Position - P).Magnitude
				if dd < best then host, best = g.p, dd end
			end
		end
		if not host then for _, g in rig.pieces do if g.part == "Body" then host = g.p break end end end
		local k = KIND[kind]
		if host and kind == "orbit" then
			local att = Instance.new("Attachment")
			att.Name = "Fx_orbit"
			att.Position = host.CFrame:PointToObjectSpace(P)
			att.Parent = host
			local big = d.vox and 0.65 or math.clamp(d.height / 3, 1, 2.5) -- voxel pets: one or two cells per spark
			local o = { att = att, cubes = {}, r = 0.32 * big, sz = 0.11 * big }
			for i = 1, 6 do
				local q = Instance.new("Part")
				q.Name, q.Size, q.Material, q.Color = "Fx_mote", Vector3.new(o.sz, o.sz, o.sz), Enum.Material.Neon, col
				q.Anchored, q.CanCollide, q.CanQuery, q.CanTouch, q.CastShadow = true, false, false, false, false
				local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
				a0.Position, a1.Position = Vector3.new(0, o.sz * 0.5, 0), Vector3.new(0, -o.sz * 0.5, 0)
				a0.Parent, a1.Parent = q, q
				local tr = Instance.new("Trail")
				tr.Attachment0, tr.Attachment1, tr.Lifetime, tr.LightEmission, tr.FaceCamera = a0, a1, 0.16, 0.6, true -- short and soft (tour full1125b: long bright trails read as debug rays by the walls)
				tr.Color, tr.Transparency = ColorSequence.new(col), NumberSequence.new(0.55, 1)
				tr.Parent = q
				q.Parent = m
				table.insert(o.cubes, q)
			end
			rig.orbits = rig.orbits or {}
			table.insert(rig.orbits, o)
			if li then
				local l = Instance.new("PointLight")
				l.Color, l.Range, l.Brightness, l.Shadows = li[1], li[2] * big, li[3], false
				l.Parent = att
				rig.lights = rig.lights or {}
				table.insert(rig.lights, { l = l, b = li[3] })
			end
		elseif host and k then
			local att = Instance.new("Attachment")
			att.Name = "Fx_" .. kind
			att.Position = host.CFrame:PointToObjectSpace(P)
			att.Parent = host
			local e = Instance.new("ParticleEmitter")
			local big = d.vox and 0.65 or math.clamp(d.height / 3, 1, 2.5) -- voxel pets: one or two cells per spark -- the plate pets are 3 to 8 studs tall: their sparks are bigger
			local sz = {}
			for _, kp in k.size.Keypoints do table.insert(sz, NumberSequenceKeypoint.new(kp.Time, kp.Value * big, kp.Envelope * big)) end
			e.Texture, e.Color, e.Size, e.Transparency = TEX[k.tex], ColorSequence.new(col), NumberSequence.new(sz), k.trans
			e.Rate, e.Lifetime, e.Speed, e.SpreadAngle = k.rate, k.life, NumberRange.new(k.speed.Min * big, k.speed.Max * big), Vector2.new(k.spread, k.spread)
			e.Acceleration, e.Drag, e.LightEmission, e.LightInfluence = (k.accel or Vector3.zero) * big, k.drag or 0, k.light, 0
			e.EmissionDirection, e.LockedToPart = k.dir or Enum.NormalId.Top, k.locked == true
			if k.rot then e.RotSpeed, e.Rotation = NumberRange.new(-k.rot, k.rot), NumberRange.new(0, 360)
			elseif k.tex == "square" then e.Rotation, e.RotSpeed = NumberRange.new(0, 90), NumberRange.new(-40, 40) end
			if kind == "flame" then e.Color = ColorSequence.new(col:Lerp(Color3.new(1, 1, 1), 0.2), col:Lerp(Color3.fromRGB(120, 20, 10), 0.5)) end
			if kind == "aura" then e.ZOffset = -1 end
			e.Parent = att
			if li then
				local l = Instance.new("PointLight")
				l.Color, l.Range, l.Brightness, l.Shadows = li[1], li[2] * big, li[3], false
				l.Parent = att
				rig.lights = rig.lights or {}
				table.insert(rig.lights, { l = l, b = li[3] })
			end
		end
	end
end

rigBuild = function(name)
	local d = RIG[name]
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
	local origin = CFrame.new((lo.X + hi.X) / 2, lo.Y, (lo.Z + hi.Z) / 2)
	local m = Instance.new("Model")
	m.Name = name
	local root = Instance.new("Part")
	root.Name, root.Size, root.Transparency = "Root", Vector3.new(0.2, 0.2, 0.2), 1
	root.Anchored, root.CanCollide, root.CanQuery, root.CanTouch = true, false, false, false
	root.CFrame = CFrame.new(0, ROOT_Y, 0)
	root.Parent = m
	m.PrimaryPart = root
	local rig = { kind = "plate", pieces = {}, piv = {}, par = {}, grp = {}, axis = {}, seed = math.random() * 10, w = 0, lastPos = nil, order = {}, glow = d.glow }
	for part, info in d.parts do
		rig.piv[part] = (FLIP * CFrame.new(info[2])).Position
		rig.par[part] = info[1]
		rig.grp[part] = info[3]
	end
	for part, ax in d.axes or {} do rig.axis[part] = (FLIP * CFrame.new(ax)).Position.Unit end
	local headNamed = false
	for _, p in parts do
		local c = p:Clone()
		local part, role = string.match(p.Name, "^(.-)__(.+)$")
		part, role = part or "Body", role or "Tex"
		local glow = string.sub(role, 1, 4) == "Glow"
		local crystal = string.sub(role, 1, 7) == "Crystal"
		if part == "Head" and not glow and not crystal and not headNamed then c.Name, headNamed = "Head", true else c.Name = part .. "_" .. role end
		if glow then
			c.Material, c.Color = Enum.Material.Neon, d.glow:Lerp(Color3.new(0, 0, 0), 0.25)
		elseif crystal then -- living crystal: glass in the crystal colour, a little see-through (the magic theme, 2026-11-24)
			c.Material, c.Color, c.Transparency = Enum.Material.Glass, d.crystal or d.glow, 0.12
		else
			c.Material, c.Color = Enum.Material.SmoothPlastic, Color3.new(1, 1, 1) -- the vertex colours multiply with Color
		end
		c.Anchored, c.CanCollide, c.CanQuery, c.CanTouch, c.CastShadow = true, false, false, false, not glow and not crystal
		local rest = FLIP * origin:ToObjectSpace(p.CFrame)
		table.insert(rig.pieces, { p = c, part = part, role = glow and "Glow" or (crystal and "Crystal" or "Tex"), rest = rest, size = c.Size })
		c.CFrame = rest
		c.Parent = m
	end
	rigFx(m, name, d, rig)
	rigAura(m, name, d, rig)
	rig.W, rig.L, rig.H = d.size.X, d.size.Y, d.height -- width, length and height at scale 1 (the motion sizes its sway by them)
	if SIGFX then pcall(SIGFX.build, m, name, d, rig, function(a) return anchorAtt(d, rig, a) end) end
	m:SetAttribute("Voxel", true)
	m:SetAttribute("Reach", math.max(d.size.X, d.size.Z) / 4.5) -- PixelClient keeps a big pet this much further off, per unit of scale
	M.rigs[m] = rig
	m.WorldPivot = root.CFrame
	return m
end

rigAnimate = function(m, rig, now, dt, moving)
	dt = math.clamp(dt or 1 / 60, 1e-3, 1 / 20)
	local root = m.PrimaryPart.CFrame
	local pos = root.Position
	local v = rig.lastPos and (pos - rig.lastPos).Magnitude / math.max(dt, 1e-3) or 0
	rig.speed = (rig.speed or 0) + (v - (rig.speed or 0)) * math.min(1, dt * 8)
	if moving == nil then
		moving = v > 2.5
	end
	rig.lastPos = pos
	rig.w += ((moving and 1 or 0) - rig.w) * math.min(1, dt * 6)
	local w, t, s = rig.w, now + rig.seed, m:GetScale()
	if not rig.backZ then
		local z = 0
		for _, g in rig.pieces do z = math.max(z, g.rest.Position.Z) end
		rig.backZ = z * 0.6
	end
	local pose, aw = nil, 1 - w
	if rig.act and math.abs((rig.actT or 0) - (rig.sideT or -99)) > 0.3 then rig.actSide = math.random() < 0.5 and -1 or 1 end -- a new act: which side it favours
	rig.sideT = rig.act and rig.actT or rig.sideT
	if rig.act then
		local a = ACT[rig.act]
		local u = (now - rig.actT) / (a.dur * (rig.act == "hero" and rig.slow or 1))
		if u >= 1 + 0.45 / a.dur then
			rig.act, rig.nextAct = nil, now + 3 + math.random() * 3
		else
			pose = a.fn(math.min(u, 1), rig.actSide)
			local lag = a.fn(math.clamp(u - 0.14 / a.dur, 0, 1), rig.actSide)
			pose.tail, pose.wing = lag.tail, lag.wing
			if a.impact and not rig.hit and u >= a.impact then
				rig.hit = true
				if rig.aura then rig.aura.waveT = now end
				actSound(m, rig.act)
				rig.actT += 0.07
				for _, e in m:GetDescendants() do if e:IsA("ParticleEmitter") and e.Parent.Name == "Fx_dust" then e:Emit(26) end end
			end
			if a.burst and not rig.burst and u >= a.burst then
				rig.burst = true
				if not a.impact then actSound(m, rig.act) elseif ACT_SFX[rig.act .. "Burst"] then actSound(m, rig.act .. "Burst") end
				for _, e in m:GetDescendants() do if e:IsA("ParticleEmitter") and not e.LockedToPart and e.Parent.Name ~= "Fx_dust" then e:Emit(8) end end
			end
		end
	elseif w < 0.2 and now >= (rig.nextAct or now + 1) then
		local list = ACTS[m.Name] or { "look" }
		rig.act, rig.actT, rig.burst, rig.hit = list[math.random(#list)], now, false, false
		if not ACT[rig.act].burst and not ACT[rig.act].impact then actSound(m, rig.act) end
	end
	if not rig.nextAct then rig.nextAct = now + 2 + math.random() * 4 end
	pose = pose or {}
	local rp = pose.root or {}
	-- v16b CREATURE MOTION (the owner 2026-11-25: "move XYZ not just 2 dimensional up and downs. They should feel alive and
	-- replicate real movement of creatures. Plan idle, and all other state animations"; plan: vault Projects/Pixel-_/Briefs/
	-- Pet Motion Plan (2026-11-25).md). The body moves on all six axes in every state. Walking: a stride with stance and swing
	-- phases (each foot planted flat and swept back, then lifted, folded and carried forward, a little outward), the weight
	-- rocking over the supporting legs, the spine twisting with the diagonal pair, a bob twice a stride, a lean into turns and
	-- against speeding up or stopping, a trot that turns into a rocking gallop at speed, small shuffling steps when turning on
	-- the spot; bipeds rock over each leg, the scarab runs on tripods, the seal galumphs, the jelly hovers and pulses, the
	-- serpent weaves. Idle: breathing, a slow shift of weight, a head that darts to look at things (the camera now and then)
	-- and holds there while the body turns a little after it; tails swing out on turns with spring follow-through.
	local TAU = math.pi * 2
	if not rig.loco then
		local legs, nNeck, tent = {}, 0, false
		for part, g in rig.grp do
			if g == "leg" then legs[string.match(part, "^(.-)%d+$") or part] = true end
			if g == "neck" then nNeck += 1 end
			if g == "tentacle" then tent = true end
		end
		local n = 0
		for _ in legs do n += 1 end
		rig.nLegs, rig.nNeck = n, nNeck
		for _, g in rig.grp do if g == "wing" then rig.hasWing = true end end
		rig.loco = m.Name == "Ouro" and "serpent" or (n == 6 and "hex") or (n == 2 and "biped") or (n == 0 and (tent and "float" or "seal")) or "quad"
	end
	local loco = rig.loco
	local base = root * CFrame.new(0, -ROOT_Y * s, 0)
	local idle = 1 - w
	local lk = root.LookVector
	local yaw0 = math.atan2(-lk.X, -lk.Z)
	local dyaw = rig.lastYaw and ((yaw0 - rig.lastYaw + math.pi) % TAU - math.pi) or 0
	rig.lastYaw = yaw0
	rig.yr = (rig.yr or 0) + (math.clamp(dyaw / dt, -4, 4) - (rig.yr or 0)) * math.min(1, dt * 5) -- the turn rate (+: to its left)
	-- the stride follows the real ground speed (v16, full1124c view 18): a faster walk is a faster cadence, never a glide
	local spd = rig.speed or 0
	if moving then spd = math.max(spd, 9) end -- a caller that says 'walking' without moving the model (lineups, showcases)
	local su = spd / math.max(s, 0.3) -- the speed in the pet's own size
	rig.acc = (rig.acc or 0) + ((su - (rig.su or su)) / dt - (rig.acc or 0)) * math.min(1, dt * 3)
	rig.su = su
	rig.run = (rig.run or 0) + (math.clamp((su - 11) / 7, 0, 1) * w - (rig.run or 0)) * math.min(1, dt * 3)
	local run = rig.run
	local turn = math.clamp(math.abs(rig.yr) * 0.35, 0, 0.6) * idle -- turning on the spot: a shuffle of small steps
	local wl = math.max(w, turn)
	rig.gp = (rig.gp or 0) + dt * math.clamp(3.5 + spd * 0.9 / math.max(s, 0.3), 3.5, 15) * (1 - 0.15 * run) -- a gallop: longer, slower strides
	local gp = rig.gp
	local step = math.sin(gp)
	local breathe = math.sin(t * 2.6) -- a breath every 2.4 s
	local W, L, Hh = rig.W or 3, rig.L or 4, rig.H or 4
	-- the gait's own body motion (studs at scale 1, radians), by the way the creature gets about
	local gx, gy, gz, gpit, gyaw, groll = 0, 0, 0, 0, 0, 0
	local sn, c2 = math.sin(gp), math.cos(gp * 2)
	if loco == "float" then -- hovers, drifts and turns lazily; each pulse of the bell pushes it on, nose down
		gy = Hh * (0.06 + 0.03 * math.sin(t * 1.5)) + Hh * 0.04 * math.max(0, sn) * w
		gpit = -0.2 * w + 0.04 * math.sin(t * 1.1) * idle
		gx, gz = W * 0.04 * math.sin(t * 0.4) * idle, L * 0.04 * math.cos(t * 0.31) * idle
		gyaw = 0.25 * math.sin(t * 0.23) * idle
		groll = 0.05 * math.sin(t * 0.8) * idle
	elseif loco == "seal" then -- galumphing: the front rises as the rear pushes
		gpit = sn * 0.1 * wl
		gy = math.max(0, sn) * 0.06 * Hh * wl
		gz = math.cos(gp) * 0.03 * L * wl
		gyaw = math.sin(gp * 0.5) * 0.04 * wl
	elseif loco == "biped" then -- the weight rocks over each stance leg, the hips twist
		gx = sn * 0.08 * W * wl
		groll = sn * 0.11 * wl
		gyaw = sn * 0.1 * wl
		gy = math.abs(sn) * 0.03 * Hh * wl
		gpit = c2 * 0.02 * wl - 0.04 * w
	elseif loco == "serpent" then -- the coil weaves from side to side as the front legs pull
		gx = sn * 0.025 * W * wl + math.sin(t * 0.6) * 0.02 * W * idle
		groll = sn * 0.03 * wl
		gyaw = sn * 0.07 * wl + math.sin(t * 0.5) * 0.05 * idle
		gy = math.abs(sn) * 0.015 * Hh * wl
	elseif loco == "hex" then -- a scuttle: tripods, almost no bob, a quick wiggle
		gyaw = sn * 0.04 * wl
		groll = sn * 0.03 * wl
		gx = sn * 0.015 * W * wl
		gy = math.abs(math.sin(gp * 1.5)) * 0.012 * Hh * wl
	else -- quadrupeds: a trot on diagonal pairs that becomes a rocking gallop at speed
		local trot = 1 - run
		gx = sn * 0.035 * W * wl * trot
		groll = (sn * 0.075 * trot + math.sin(gp + 0.6) * 0.03 * run) * wl -- the hips drop over the swinging leg
		gyaw = sn * 0.06 * wl * trot
		gy = (math.abs(sn) * 0.02 * trot + math.max(0, math.sin(gp + 0.6)) * 0.06 * run) * Hh * wl
		gz = (c2 * 0.012 * trot + math.cos(gp) * 0.03 * run) * L * wl
		gpit = (c2 * 0.015 * trot + sn * 0.1 * run) * wl
	end
	-- the gaze: pick something to look at every 1 to 4 s (the camera a third of the time), dart the head there and hold
	local gzs = rig.gaze
	if not gzs then gzs = { y = 0, p = 0, vy = 0, vp = 0, ty = 0, tp = 0, nt = now + 0.3 } rig.gaze = gzs end
	if now >= gzs.nt then
		gzs.nt = now + 0.8 + math.random() * 2.2
		local ws = m:FindFirstAncestorWhichIsA("Workspace")
		local cam = ws and ws.CurrentCamera
		if cam and math.random() < 0.35 then
			local lp = root:PointToObjectSpace(cam.CFrame.Position)
			gzs.ty = math.clamp(math.atan2(-lp.X, -lp.Z), -0.8, 0.8)
			gzs.tp = math.clamp(math.atan2(lp.Y - Hh * s * 0.6, math.sqrt(lp.X * lp.X + lp.Z * lp.Z)), -0.25, 0.35)
		else
			gzs.ty, gzs.tp = (math.random() * 2 - 1) * 0.85, (math.random() * 2 - 1) * 0.22
		end
	end
	local ty, tp = gzs.ty * (1 - 0.7 * w) * (1 - turn) + rig.yr * (0.12 * w + 0.4 * turn), gzs.tp * (1 - 0.7 * w) -- the head leads into turns
	gzs.vy += ((ty - gzs.y) * 70 - gzs.vy * 16.7) * dt -- critically damped: a quick dart that stops without wobble
	gzs.vp += ((tp - gzs.p) * 70 - gzs.vp * 16.7) * dt
	gzs.y += gzs.vy * dt
	gzs.p += gzs.vp * dt
	local ts = rig.tailS
	if not ts then ts = { a = 0, v = 0 } rig.tailS = ts end
	ts.v += ((-rig.yr * 0.3 - ts.a) * 22 - ts.v * 3.2) * dt -- the tail swings out against a turn, overshoots and settles
	ts.a += ts.v * dt
	local lean = math.clamp(rig.yr * 0.07 * (0.3 + w), -0.2, 0.2) -- into the turn
	local brake = math.clamp(-rig.acc * 0.004, -0.07, 0.07) -- forward to speed up, back to stop
	-- standing: the weight drifts from side to side (two rates, so it never looks like a metronome); a fidget step leans off
	-- the lifted foot (judge s5a: idle read as a frozen statue at 1-2 degrees)
	local fz, fside = 0, 0
	if loco == "quad" or loco == "biped" or loco == "hex" then
		local fd = rig.fid
		if fd and not rig.act then
			local q = (now - fd.t0) / 0.6
			if q > 0 and q < 1 then fz, fside = math.sin(math.pi * q) * idle, fd.side end
		end
		if idle > 0.85 and not rig.act and rig.legC and now >= (rig.fidN or now + 1) then
			local list = {}
			for pre in rig.legC do table.insert(list, pre) end
			local pre = list[math.random(#list)]
			local pv1 = rig.piv[pre .. "1"]
			rig.fid = { leg = pre, t0 = now, side = pv1 and (pv1.X >= 0 and 1 or -1) or 1 }
		end
		if not rig.fidN or now >= rig.fidN then rig.fidN = now + 2.2 + math.random() * 2.8 end
	end
	local shift = (math.sin(t * 0.9 + rig.seed) * 0.7 + math.sin(t * 1.9 + rig.seed * 2) * 0.3) * idle - fside * fz * 0.5
	local pitch = (rp.pitch or 0) * aw + gpit + brake + (math.sin(t * 1.1) * 0.035 + breathe * 0.02) * idle
	local yaw = (rp.yaw or 0) * aw + gyaw + gzs.y * 0.2 * idle + shift * 0.06 - rig.yr * 0.1 * turn
	local roll = (rp.roll or 0) * aw + groll + lean - shift * 0.07 + math.sin(t * 0.8 + 1) * 0.02 * idle
	local P = Vector3.new(0, 0, rp.pivotBack and rig.backZ or 0) * s
	local lift = ((rp.lift or 0) * aw + gy + breathe * 0.1 * idle) * s
	local ox, oz = ((rp.x or 0) * aw * W + gx + shift * 0.05 * W) * s, ((rp.z or 0) * aw * L + gz + math.sin(t * 0.6 + rig.seed) * 0.025 * L * idle) * s
	base = base * CFrame.new(ox, lift, oz) * CFrame.new(P) * CFrame.Angles(pitch, yaw, roll) * CFrame.new(-P)
	local xf = {}
	local function localOf(part)
		local grp = rig.grp[part] or "body"
		local prefix, k = string.match(part, "^(.-)(%d+)$")
		k = tonumber(k) or 1
		local pv = rig.piv[part] or Vector3.zero
		if grp == "leg" or grp == "arm" then
			local first = rig.piv[(prefix or part) .. "1"] or pv
			local side = first.X >= 0 and 1 or -1
			local front = first.Z <= 0 and 1 or -1 -- the pets look -Z after FLIP
			if loco == "seal" then -- flippers stroke together: down and back, then up and out
				local st = math.sin(gp)
				if k == 1 then return CFrame.Angles(st * 0.5 * wl + breathe * 0.04 * idle, 0, side * (0.12 + 0.18 * math.cos(gp)) * wl + side * math.sin(t * 1.2) * 0.06 * idle) end
				return CFrame.Angles(-math.max(0, st) * 0.4 * wl, 0, side * 0.1 * math.sin(gp - 0.8) * wl)
			end
			local off
			if grp == "arm" or rig.nLegs == 2 then
				off = side > 0 and 0 or math.pi
			elseif rig.nLegs == 6 then
				local idx = tonumber(string.match(prefix or "", "(%d)_$")) or 1
				off = ((idx % 2 == 1) == (side > 0)) and 0 or math.pi -- the tripod gait
			else
				local trotOff = side * front > 0 and 0 or math.pi
				local galOff = (front > 0 and 0 or 3.6) + (side > 0 and 0.55 or 0)
				off = trotOff + (galOff - trotOff) * run
			end
			local c = ((gp + off) / TAU) % 1
			if k == 1 and prefix then
				rig.legC = rig.legC or {}
				local pc = rig.legC[prefix]
				if pc and c < pc - 0.5 then -- the phase wrapped: this foot just landed
					rig.contact = rig.contact or {}
					rig.contact[prefix] = now
				end
				rig.legC[prefix] = c
			end
			local hip, up
			if c < 0.6 then
				hip, up = math.cos(math.pi * c / 0.6), 0 -- stance (60%): the planted foot sweeps back under the body
			else
				local q = (c - 0.6) / 0.4
				hip, up = -math.cos(math.pi * q), math.sin(math.pi * q) -- swing (40%): lifted, folded and carried forward
			end
			local fq = (grp == "leg" and rig.fid and rig.fid.leg == prefix) and fz or 0
			local h1 = hip * (grp == "arm" and 0.4 or 0.42) * (1 + 0.4 * run) * wl - fq * 0.25
			local k2 = -(up * (0.8 + 0.35 * run) + math.max(0, hip) * 0.12) * wl - fq * 0.75
			if k == 1 then
				local r = CFrame.Angles(h1 + breathe * 0.03 * idle, 0, side * up * 0.09 * wl) -- the swinging leg also swings a little outward
				local lf = pose.legF
				if side > 0 and pose.legFR then lf = pose.legFR elseif side < 0 and pose.legFL then lf = pose.legFL end
				if grp == "leg" and lf and front > 0 then r = r * CFrame.new():Lerp(lf, aw) end
				if grp == "arm" and pose.armR then r = r * CFrame.new():Lerp(pose.armR, aw) end
				return r
			elseif k == 2 then
				return CFrame.Angles(k2, 0, 0) -- the knee folds to lift the foot
			end
			return CFrame.Angles(-(h1 + k2) + up * 0.35 * wl + fq * 0.3, 0, -side * up * 0.09 * wl) -- the sole stays level while the foot is down: flat, planted feet
		elseif grp == "wing" then
			local first = rig.piv[(prefix or part) .. "1"] or pv
			local side = first.X >= 0 and 1 or -1
			local beat = math.sin(t * (3 + 9 * w) - (k - 1) * 0.6) * (0.14 + 0.28 * w)
			local spread = (pose.wing or 0) * aw - math.abs(rig.yr) * 0.08 -- wings lift a little to balance in a turn
			return CFrame.Angles(math.sin(t * 1.7 + side) * 0.05, 0, side * (beat * (k == 1 and 1 or 0.7) + spread * (k == 1 and 1 or 0.5)))
		elseif grp == "tail" or grp == "spine" then
			local amp = grp == "spine" and 0.05 or (0.12 + 0.03 * k)
			local wave = loco == "serpent" and 1.8 or 1
			local r = CFrame.Angles(math.sin(t * 1.6 - k * 0.5) * amp * 0.35 + (loco == "seal" and math.sin(gp - k * 0.7) * 0.12 * wl or 0) + run * 0.1,
				math.sin(t * (2.2 + 3 * w) - k * 0.7 * wave) * amp * wave * (1 + 0.6 * idle) + math.sin(gp - k * 0.6) * 0.1 * w + ts.a * 0.18
				+ (grp == "tail" and math.max(0, math.sin(t * 0.55 + rig.seed)) ^ 6 * math.sin(t * 7 - k * 0.9) * 0.3 * idle or 0), 0)
			if grp == "tail" and k == 1 and pose.tail then r = r * CFrame.new():Lerp(pose.tail, aw) end
			return r
		elseif grp == "tentacle" then -- trail behind the motion, flare with each pulse, lag on turns
			local ph = (#(prefix or "") * 1.7) + k * 0.8
			return CFrame.Angles(math.sin(t * 1.4 - ph) * (0.1 + 0.05 * k) - w * 0.25 + math.max(0, math.sin(gp - k * 0.5)) * 0.15 * w, ts.a * 0.15, math.cos(t * 1.1 - ph) * (0.08 + 0.04 * k))
		elseif grp == "neck" then
			local nk = loco == "serpent" and math.sin(t * 0.9 - k * 0.8) * 0.1 or 0
			local share = 0.4 / math.max(rig.nNeck or 1, 1)
			local bob = CFrame.identity
			if k == 1 and loco == "biped" and rig.hasWing then
				local ph = (gp * 2 / TAU) % 1
				local hold = ph < 0.7 and ph / 0.7 or 1 - (ph - 0.7) / 0.3
				bob = CFrame.new(0, 0, (hold - 0.5) * 0.09 * L * s * w * (1 - 0.6 * run))
			end
			local r = bob * CFrame.Angles(math.sin(t * 1.3 - 0.5) * 0.04 * idle + breathe * 0.03 * idle + gzs.p * share, gzs.y * share * (pose.head and 0.3 or 1) + nk, 0)
			if pose.head then r = r * CFrame.new():Lerp(pose.head, aw * 0.4) end
			return r
		elseif grp == "head" then
			local twitch = (t % (2.7 + rig.seed % 1.3)) < 0.14 and 0.1 or 0
			local share = ((rig.nNeck or 0) > 0 and 0.6 or 1) * (pose.head and 0.25 or 1)
			local r = CFrame.Angles(gzs.p * share + math.sin(t * 1.3) * 0.05 * idle - step * 0.04 * w, gzs.y * share, math.sin(t * 0.9) * 0.06 * idle + twitch * idle + gzs.y * 0.25 * idle)
			if (rig.nNeck or 0) == 0 and loco == "biped" and rig.hasWing then
				local ph = (gp * 2 / TAU) % 1
				local hold = ph < 0.7 and ph / 0.7 or 1 - (ph - 0.7) / 0.3
				r = CFrame.new(0, 0, (hold - 0.5) * 0.09 * L * s * w * (1 - 0.6 * run)) * r
			end
			r = r * CFrame.Angles(-gpit * 0.7, -gyaw * 0.6, -groll * 0.7) -- the head stays steady while the body rocks under it
			if pose.head then r = r * CFrame.new():Lerp(pose.head, aw) end
			return r
		elseif grp == "ring" then
			local ax = rig.axis[part] or Vector3.yAxis
			rig.spin = rig.spin or {}
			rig.spin[part] = (rig.spin[part] or 0) + dt * (0.35 + 0.12 * k) * ((k % 2 == 0) and -1 or 1) * (1 + (pose.ring or 0) * aw)
			return CFrame.fromAxisAngle(ax, rig.spin[part])
		end
		return CFrame.identity
	end
	local function xfOf(part)
		if xf[part] then return xf[part] end
		local pv = (rig.piv[part] or Vector3.zero) * s
		local own = CFrame.new(pv) * localOf(part) * CFrame.new(-pv)
		local par = rig.par[part]
		local r = par and xfOf(par) * own or own
		xf[part] = r
		return r
	end
	if not rig.nLegs then
		local legs = {}
		for part, g in rig.grp do if g == "leg" then local pre = string.match(part, "^(.-)%d+$") legs[pre or part] = true end end
		local n = 0 for _ in legs do n += 1 end
		rig.nLegs = n
	end
	local sq = (pose.squash or 0) * aw
	local pulse = 0.5 + 0.5 * math.sin(t * 2.4)
	local dim, lit = rig.glow:Lerp(Color3.new(0, 0, 0), 0.5), rig.glow:Lerp(Color3.new(1, 1, 1), 0.08)
	for i, g in rig.pieces do
		g.p.CFrame = base * xfOf(g.part) * (g.rest.Rotation + g.rest.Position * s) * (g.part == "Body" and CFrame.new(0, -sq * 0.1, 0) or CFrame.identity)
		if g.role == "Glow" then g.p.Color = dim:Lerp(lit, 0.5 + 0.5 * math.sin(t * 2.4 + i * 0.7)) end
	end
	for _, l in rig.lights or {} do l.l.Brightness = l.b * (0.7 + 0.5 * pulse) end
	local au = rig.aura
	if au then
		local g = root * CFrame.new(0, -ROOT_Y * s + 0.06 * s, 0)
		local n = #au.ring
		for i2, q in au.ring do
			local ph = (t * 0.3 + i2 * 0.618) % 1
			local a2 = i2 * 2.4 + math.floor(t * 0.3 + i2 * 0.618) * 1.7 + ph * 0.6
			local rr = au.R * s * (0.55 + 0.5 * ((i2 * 0.37) % 1))
			q.CFrame = g * CFrame.new(math.cos(a2) * rr + math.sin(t * 2 + i2) * 0.08 * s, ph * au.h * s * 0.35, math.sin(a2) * rr) * CFrame.Angles(t * 2 + i2, -a2, 0)
			q.Size = Vector3.one * 0.12 * s * (1 - 0.6 * ph)
			q.Transparency = 0.1 + 0.9 * (ph < 0.12 and 1 - ph / 0.12 or ph)
		end
		local hp = (t * 0.32) % 1
		n = #au.halo
		for i2, q in au.halo do
			local a2 = -t * 0.8 + i2 / n * math.pi * 2
			local rr = au.R * s * (0.9 - 0.25 * hp)
			q.CFrame = g * CFrame.new(math.cos(a2) * rr, hp * au.h * s * 0.9, math.sin(a2) * rr)
			q.Transparency = 0.1 + 0.9 * hp
		end
		local wt = now - au.waveT
		n = #au.wave
		for i2, q in au.wave do
			if wt >= 0 and wt < 0.6 then
				local a2 = i2 / n * math.pi * 2
				local rr = au.R * s * (0.4 + 2.2 * wt / 0.6)
				local y = 0.05 * s
				if i2 % 2 == 0 then -- a clod: up and out on an arc, tumbling
					rr = au.R * s * (0.5 + 1.3 * wt / 0.6)
					y = math.max(0, (3.2 * wt - 9 * wt * wt) * (0.8 + 0.4 * ((i2 * 0.29) % 1))) * s
				end
				q.CFrame = g * CFrame.new(math.cos(a2) * rr, y, math.sin(a2) * rr) * CFrame.Angles(wt * 9 * (1 - i2 % 2), a2, wt * 6 * (1 - i2 % 2))
				q.Transparency = wt / 0.6
				q.Size = Vector3.one * (0.22 - 0.12 * wt / 0.6) * s
			elseif q.Transparency < 1 then
				q.Transparency = 1
			end
		end
	end
	for oi, o in rig.orbits or {} do
		local c = o.att.WorldPosition
		local n = #o.cubes
		for i, q in o.cubes do
			local a = t * (1.6 + 0.2 * oi) + i / n * math.pi * 2
			local r = o.r * s * (1 + 0.15 * math.sin(t * 3 + i))
			q.CFrame = CFrame.new(c + Vector3.new(math.cos(a) * r, math.sin(a * 2 + t) * 0.35 * r, math.sin(a) * r)) * CFrame.Angles(t * 2 + i, t * 1.5, 0)
			q.Size = Vector3.one * o.sz * s * (0.75 + 0.25 * math.sin(t * 5 + i * 1.3))
		end
	end
	if rig.sig and SIGFX then SIGFX.step(m, rig, now, t, dt, s, root * CFrame.new(0, -ROOT_Y * s + 0.06 * s, 0)) end
end

-- every frame, after the model was pivoted: pose the parts. now: os.clock(); moving: overrides the speed guess
-- directive v13: start the pet's signature act now (the hatch fires it on the landing frame instead of after 2 to 6 s)
local HERO = { Rare = true, Epic = true, Legendary = true, Mythic = true, Secret = true }
function M.hero(m)
	local rig = M.rigs[m]
	if not rig then return end
	local okC, Cfg = pcall(require, script.Parent:FindFirstChild("Config"))
	local info = okC and Cfg.PETS and Cfg.PETS[m.Name]
	if info and HERO[info[1]] then -- v15: rare and better pets land with the two-beat showcase (gather, then rear up and roar)
		rig.act, rig.actT, rig.burst, rig.hit = "hero", os.clock(), false, false
		rig.slow = game:GetService("RunService"):IsStudio() and tonumber(workspace:GetAttribute("DevHeroSlow")) or nil -- Studio test hook: play the showcase slower for stills (spike/v15_hatch.py)
		if game:GetService("RunService"):IsStudio() then workspace:SetAttribute("DevHeroAt", os.clock()) end -- Studio test hook: when the showcase began (a test's own Lua runs another copy of this module)
		return
	end
	local list = ACTS[m.Name] or { "look" }
	local pick = list[1]
	for _, a in list do
		if a == "roar" or a == "flap" or a == "rear" or a == "tailfan" then pick = a break end
		if not QUIET[a] then pick = a end
	end
	rig.act, rig.actT, rig.burst, rig.hit = pick, os.clock(), false, false
end

function M.animate(m, now, dt, moving)
	local rig = M.rigs[m]
	if not rig or not m.PrimaryPart then return end
	if rig.kind == "plate" then return rigAnimate(m, rig, now, dt, moving) end
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
		local u = (now - rig.actT) / (a.dur * (rig.act == "hero" and rig.slow or 1))
		if u >= 1 + 0.45 / a.dur then -- run on until the last chain segment has settled too (a snap when it was cut at u = 1)
			rig.act, rig.nextAct = nil, now + 3 + math.random() * 3
		else
			pose = a.fn(math.min(u, 1))
			local lag = a.fn(math.clamp(u - 0.14 / a.dur, 0, 1)) -- the tail and the wings lag the body (follow-through)
			pose.tail, pose.wing = lag.tail, lag.wing
			rig.lagFn = function(k) return a.fn(math.clamp(u - 0.14 * k / a.dur, 0, 1)) end -- later segments lag more
			if a.impact and not rig.hit and u >= a.impact then -- a dust ring at the feet on the impact frame
				rig.hit = true
				actSound(m, rig.act)
				rig.actT += 0.07 -- hit-stop: the pose holds on the impact frame for a beat
				for _, e in m:GetDescendants() do
					if e:IsA("ParticleEmitter") and e.Parent.Name == "Fx_dust" then e:Emit(26) end
				end
			end
			if a.burst and not rig.burst and u >= a.burst then -- a puff from every effect on the pet on the beat
				rig.burst = true
				if not a.impact then actSound(m, rig.act) elseif ACT_SFX[rig.act .. "Burst"] then actSound(m, rig.act .. "Burst") end
				for _, e in m:GetDescendants() do
					if e:IsA("ParticleEmitter") and not e.LockedToPart and e.Parent.Name ~= "Fx_dust" then e:Emit(8) end
				end
			end
		end
	elseif w < 0.2 and now >= (rig.nextAct or now + 1) then
		local list = ACTS[m.Name] or { "look" }
		rig.act, rig.actT, rig.burst, rig.hit = list[math.random(#list)], now, false, false
		if not ACT[rig.act].burst and not ACT[rig.act].impact then actSound(m, rig.act) end -- no beat: it sounds as it starts
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
