-- ServerScriptService.PixelServer: shafts, digging, backpack, selling, upgrades, frenzy, eggs, crew (server decides everything).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local SS = game:GetService("ServerStorage")
local IS_STUDIO = game:GetService("RunService"):IsStudio()
local C = require(RS:WaitForChild("Shared"):WaitForChild("Config"))
local ProfileStore = require(game:GetService("ServerScriptService"):WaitForChild("ProfileStore"))
local Store = ProfileStore.New(C.SAVE_STORE, C.SAVE_TEMPLATE)

local B, COLS = C.B, C.COLS
local ROWS = #C.LAYERS * C.LAYER_ROWS

-- Remotes
local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
local function remote(name)
	local r = Instance.new("RemoteEvent")
	r.Name = name
	r.Parent = remotes
	return r
end
local DigR, SellR, BuyR, SurfaceR, StateR, FxR = remote("Dig"), remote("Sell"), remote("Buy"), remote("Surface"), remote("State"), remote("Fx")
remotes.Parent = RS

local shafts = Instance.new("Folder")
shafts.Name = "Shafts"
shafts.Parent = workspace

-- Warm dusk light for the surface; the shaft is lit by ambient
Lighting.ClockTime = 16.8
Lighting.Brightness = 2.2
Lighting.Ambient = Color3.fromRGB(96, 80, 72)
Lighting.OutdoorAmbient = Color3.fromRGB(150, 128, 110)
Lighting.EnvironmentDiffuseScale, Lighting.EnvironmentSpecularScale = 0.6, 0.15
Lighting.GlobalShadows, Lighting.ShadowSoftness = true, 0.3
local function effect(cls, props) -- soft sky haze, glow on neon ore, slightly richer colour (Delve reference)
	local e = Lighting:FindFirstChildOfClass(cls) or Instance.new(cls)
	for k, v in props do e[k] = v end
	e.Parent = Lighting
end
effect("Atmosphere", { Density = 0.22, Offset = 0.1, Haze = 1.2, Glare = 0.2, Color = Color3.fromRGB(200, 220, 255), Decay = Color3.fromRGB(120, 140, 180) })
effect("BloomEffect", { Intensity = 0.7, Size = 22, Threshold = 1.2 })
effect("ColorCorrectionEffect", { Saturation = 0.15, Contrast = 0.08, Brightness = 0.02 })
local clouds = workspace.Terrain:FindFirstChildOfClass("Clouds") or Instance.new("Clouds")
clouds.Cover, clouds.Density, clouds.Parent = 0.55, 0.6, workspace.Terrain

local proto = Instance.new("Part")
proto.Anchored = true
proto.Size = Vector3.new(B - C.GAP, B - C.GAP, B)
proto.Material = Enum.Material.SmoothPlastic
proto.TopSurface, proto.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
local gemProto = proto:Clone()
gemProto.CanCollide, gemProto.CanQuery, gemProto.CanTouch = false, false, false

local data = {} -- [player] = shaft state
local equipPick -- defined with the held pickaxe below
local slots = {}

local function layerOf(r)
	return math.clamp(math.ceil(r / C.LAYER_ROWS), 1, #C.LAYERS)
end

local function cellPos(s, r, c)
	return Vector3.new(s.x0 + (c - 0.5) * B, -(r - 0.5) * B, 0)
end

local function shade(col, r, c)
	local h, sat, v = col:ToHSV()
	return Color3.fromHSV(h, sat, math.clamp(v * (0.9 + ((r * 7 + c * 13) % 3) * 0.07), 0, 1))
end

local function newCell(s, r, c)
	local start = C.START[r]
	local kind = start and start[c - s.sc]
	if not kind then
		local rng = Random.new(s.seed + r * 997 + c * 31)
		local x = rng:NextNumber()
		if r > C.START_ROWS and x < C.EGG_CHANCE then
			kind = "egg"
		elseif x < C.ORE3_CHANCE then
			kind = (r > C.START_ROWS and rng:NextNumber() < C.GILDED_CHANCE * 8) and "gild" or "ore3"
		elseif x < C.ORE3_CHANCE + C.ORE2_CHANCE then
			kind = "ore2"
		else
			kind = "base"
		end
	end
	local L = layerOf(r)
	local hpScale, valScale = 2 ^ (L - 1), 3 ^ (L - 1)
	if kind == "egg" then
		return { k = kind, ore = "Fossil Egg", col = C.EGG_COLOR, v = 0, hp = 2 * hpScale, max = 2 * hpScale }
	end
	local o = C.LAYERS[L][4][kind == "base" and 1 or kind == "ore2" and 2 or 3]
	local hp = math.ceil(o[3] * hpScale)
	local cell = { k = kind, ore = o[1], col = o[2], v = o[4] * valScale, hp = hp, max = hp }
	if kind == "gild" then
		cell.ore, cell.col, cell.v = "Gilded " .. o[1], C.GILD_COLOR, cell.v * C.GILD_MULT
	end
	return cell
end

local function buildPart(s, r, c, cell)
	local p = proto:Clone()
	p.Name = r .. "_" .. c
	p.Position = cellPos(s, r, c)
	local base = C.LAYERS[layerOf(r)][4][1][2]
	p.Color = shade(cell.k == "base" and cell.col or base, r, c)
	if cell.k ~= "base" then -- ore pokes out of the face toward the camera as a chunky voxel cluster
		local glow = cell.k == "gild" or cell.k == "egg"
		local flip = (r + c) % 2 == 0 and 1 or -1
		local cluster = cell.k == "egg" and { { 2.2, 2.6, 0, -0.1 }, { 1.4, 0.7, 0, 1.4 } }
			or { { 1.7, 1.5, -0.45 * flip, -0.4 }, { 1.1, 1.0, 0.75 * flip, 0.55 }, { 0.7, 0.7, 0.15 * flip, 1.0 } }
		for i, g in cluster do
			local q = gemProto:Clone()
			q.Name = "Gem"
			q.Color = cell.col:Lerp(Color3.new(1, 1, 1), (i - 1) * 0.12)
			q.Material = glow and Enum.Material.Neon or Enum.Material.SmoothPlastic
			q.Size = Vector3.new(g[1], g[2], 1.1)
			q.Position = p.Position + Vector3.new(g[3], g[4], B / 2 - 0.1)
			q.Parent = p
		end
	end
	if r == 1 then -- grass cap on the surface row
		local g = gemProto:Clone()
		g.Name = "Grass"
		g.Color = shade(C.GRASS, r, c)
		g.Size = Vector3.new(B - C.GAP, 0.9, B)
		g.Position = p.Position + Vector3.new(0, B / 2 - 0.44, 0)
		g.Parent = p
	end
	p:SetAttribute("R", r)
	p:SetAttribute("C", c)
	p.Parent = s.folder
	cell.part = p
end

local function ensureRow(s, r)
	if r < 1 or r > ROWS or s.built[r] then return end
	local row = s.grid[r]
	if not row then
		row = {}
		for c = 1, COLS do row[c] = newCell(s, r, c) end
		s.grid[r] = row
	end
	for c = 1, COLS do
		if row[c].k ~= "air" then buildPart(s, r, c, row[c]) end
	end
	s.built[r] = true
end

local function dropRow(s, r)
	if not s.built[r] then return end
	for c = 1, COLS do
		local cell = s.grid[r][c]
		if cell.part then cell.part:Destroy(); cell.part = nil end
	end
	s.built[r] = nil
end

local function refreshWindow(s)
	for r = 1, ROWS do
		local keep = not C.WINDOW or r <= C.SURFACE_KEEP or (r >= s.row - C.WIN_UP and r <= s.row + C.WIN_DOWN)
		if keep then ensureRow(s, r) else dropRow(s, r) end
	end
end

local function cap(s)
	return C.PACKS[s.pack].cap
end

local function target(s)
	local t = (s.step == 1 and { 1, s.sc }) or (s.step == 2 and { 4, s.sc }) or (s.step == 5 and { 6, s.sc })
	if t and s.grid[t[1]] and s.grid[t[1]][t[2]].k == "air" then return nil end
	return t or nil
end

local function save(s) -- mirror the saved fields into the ProfileStore session (it autosaves and saves on leave)
	local d = s.profile and s.profile.Data
	if not d then return end
	d.gold, d.pick, d.pack, d.best, d.hatched, d.pity, d.step = s.gold, s.pick, s.pack, s.best, s.hatched, s.pity, s.step
	d.eggs, d.lastSeen = s.eggs, os.time()
	local names = {}
	for i, p in s.pets do names[i] = p.name end
	d.pets = names
end

local function sendState(s)
	save(s)
	local pets = {}
	for i, p in s.pets do pets[i] = p.name end
	StateR:FireClient(s.player, {
		gold = s.gold, bag = s.bag, cap = cap(s), pick = s.pick, pack = s.pack, step = s.step, target = target(s),
		pets = pets, x0 = s.x0, sc = s.sc, folder = s.folder.Name, best = s.best, pity = s.pity, eggs = s.eggs,
	})
end

local function surfaceCFrame(s, col)
	return CFrame.new(cellPos(s, 0, col or s.sc) + Vector3.new(0, 1.5, 0.5))
end

local HIGH = { Legendary = true, Mythic = true, Secret = true }
local function rollRarity(s) -- the disclosed odds; at the pity limit only Legendary or better, by their own odds
	local pool = s.pity >= C.PITY - 1 and { C.RARITIES[4], C.RARITIES[5], C.RARITIES[6] } or C.RARITIES
	local total = 0
	for _, t in pool do total += t[2] end
	local x, acc = s.rng:NextNumber() * total, 0
	for _, t in pool do
		acc += t[2]
		if x < acc then return t[1] end
	end
	return pool[#pool][1]
end

local function hatch(s)
	local name = C.FIRST_PET
	if s.hatched > 0 then -- roll the rarity, then a pet of that rarity
		local rarity = rollRarity(s)
		s.pity = HIGH[rarity] and 0 or s.pity + 1
		local pool = {}
		for n, p in C.PETS do if p[1] == rarity then table.insert(pool, n) end end
		table.sort(pool)
		name = pool[s.rng:NextInteger(1, #pool)]
	end
	s.hatched += 1
	if #s.pets < C.MAX_PETS then
		table.insert(s.pets, { name = name, next = os.clock() + C.HATCH_TIME })
	end
	if s.step == 5 then s.step = 6 end
	FxR:FireClient(s.player, "hatch", name)
end

local function hrpOf(plr)
	local ch = plr.Character
	return ch and ch:FindFirstChild("HumanoidRootPart")
end

local function stir(s, r, c) -- Titan's Stir: a loose boulder drops down the dug column from a few rows up
	local top = r - 3
	if top < 1 or not s.grid[top] then return end
	local start = s.grid[top][c].k == "air" and top or top + 1 -- falls out of a solid ceiling or through an open shaft
	FxR:FireClient(s.player, "stir", start, c)
	task.delay(C.STIR_WARN, function()
		if data[s.player] ~= s then return end
		local land
		for rr = start, ROWS do
			local cell = s.grid[rr] and s.grid[rr][c]
			if not cell or cell.k ~= "air" then break end
			land = rr
		end
		if not land then return end
		local pos = cellPos(s, land, c)
		FxR:FireClient(s.player, "fell", land, c, pos)
		local hrp = hrpOf(s.player)
		if hrp and math.abs(hrp.Position.X - pos.X) < B * 0.9 and math.abs(hrp.Position.Y - pos.Y) < B * 1.2 then
			local lost = math.floor(s.bag * C.STIR_LOSS) -- it bursts on your helmet: stun and spill, no rubble
			if s.bag > 0 then s.bagV -= math.floor(s.bagV * lost / s.bag) end
			s.bag -= lost
			s.nextDig = os.clock() + C.STIR_STUN
			FxR:FireClient(s.player, "bonk", lost)
			sendState(s)
			return
		end
		local L = layerOf(land) -- otherwise it lands as rubble and refills the hole
		local o = C.LAYERS[L][4][1]
		local hp = math.ceil(o[3] * 2 ^ (L - 1))
		local rubble = { k = "base", ore = o[1], col = o[2], v = o[4] * 3 ^ (L - 1), hp = hp, max = hp }
		s.grid[land][c] = rubble
		if s.built[land] then buildPart(s, land, c, rubble) end
	end)
end

local function hit(s, r, c, dmg, who, crit)
	local cell = s.grid[r][c]
	cell.hp -= dmg
	if cell.hp > 0 then
		FxR:FireClient(s.player, "hit", r, c, cell.hp / cell.max, who, crit)
		return
	end
	local pos = cell.part.Position
	cell.part:Destroy()
	cell.part = nil
	local k = cell.k
	cell.k = "air"
	if s.step == 1 then s.step = 2 end
	if k == "egg" then
		FxR:FireClient(s.player, "break", r, c, pos, cell.ore, 0, who, 0, cell.col)
		if s.hatched == 0 then
			hatch(s) -- the tutorial egg hatches on the spot
		else
			s.eggs += 1
			FxR:FireClient(s.player, "egg", s.eggs)
		end
		sendState(s)
		return
	end
	local now, v = os.clock(), cell.v
	if k == "gild" and now > s.frenzyUntil then
		s.frenzyUntil, s.combo, s.bank = now + C.FRENZY_TIME, 0, 0
		FxR:FireClient(s.player, "frenzy", C.FRENZY_TIME)
	end
	local combo = 0
	if now < s.frenzyUntil then
		s.combo += 1
		combo = s.combo
		v = math.floor(v * (1 + C.COMBO_STEP * (combo - 1)) + 0.5)
		s.bank += v
	end
	s.bag += 1
	s.bagV += v
	if layerOf(r) == C.STIR_LAYER and s.rng:NextNumber() < C.STIR_CHANCE then stir(s, r, c) end
	FxR:FireClient(s.player, "break", r, c, pos, cell.ore, v, who, combo, cell.col, crit)
	if s.step == 2 and s.bag >= cap(s) then s.step = 3 end
	sendState(s)
end



DigR.OnServerEvent:Connect(function(plr, part)
	local s = data[plr]
	if not s or typeof(part) ~= "Instance" or part.Parent ~= s.folder then return end
	local now = os.clock()
	if now < s.nextDig then return end
	s.nextDig = now + C.DIG_COOLDOWN
	local r, c = part:GetAttribute("R"), part:GetAttribute("C")
	local cell = s.grid[r] and s.grid[r][c]
	local hrp = hrpOf(plr)
	if not cell or cell.part ~= part or not hrp or (hrp.Position - part.Position).Magnitude > C.REACH then return end
	if s.bag >= cap(s) and cell.k ~= "egg" then
		FxR:FireClient(plr, "full")
		return
	end
	-- hit-timing crit, decided on the server clock: the ring restarts on a new block and after each crit
	local dmg, crit = C.PICKS[s.pick].power, false
	local key, t = r * 1000 + c, workspace:GetServerTimeNow()
	if s.critKey ~= key then
		s.critKey, s.critT0 = key, t
		FxR:FireClient(plr, "ring", r, c, t)
	else
		local since = t - s.critT0
		local inCycle = since % C.CRIT_PERIOD
		local closing = inCycle / C.CRIT_PERIOD >= C.CRIT_FROM or (since > C.CRIT_PERIOD and inCycle <= C.CRIT_LATE)
		if closing and now - s.lastHit >= C.CRIT_GAP then
			crit, dmg = true, dmg * C.CRIT_MULT
			s.critT0 = t
			FxR:FireClient(plr, "ring", r, c, t)
		end
	end
	s.lastHit = now
	hit(s, r, c, dmg, "you", crit)
end)

local function sell(s)
	if s.bag <= 0 then return end
	s.gold += s.bagV
	FxR:FireClient(s.player, "sold", s.bagV, s.bag)
	s.bag, s.bagV = 0, 0
	if s.step <= 3 then s.step = 4 end
	sendState(s)
end

SellR.OnServerEvent:Connect(function(plr) -- the "elevator": ride up to the sell stand and sell
	local s = data[plr]
	local hrp = hrpOf(plr)
	if not s or not hrp then return end
	hrp.CFrame = surfaceCFrame(s, 4)
	sell(s)
end)

SurfaceR.OnServerEvent:Connect(function(plr)
	local s = data[plr]
	local hrp = hrpOf(plr)
	if s and hrp then hrp.CFrame = surfaceCFrame(s) end
end)

-- Held pickaxe: Wood and Stone are built from parts, the magical ones are ServerStorage.Pickaxes models (uploaded forge GLBs)
local function pickModel(i)
	local def = C.PICKS[i]
	local lib = SS:FindFirstChild("Pickaxes")
	local src = def.model and lib and lib:FindFirstChild(def.model)
	if src then
		local m = src:Clone()
		m:ScaleTo(C.PICK_SCALE)
		return m
	end
	local m = Instance.new("Model")
	local function part(name, size, y, color, mat)
		local p = Instance.new("Part")
		p.Name, p.Size, p.Color, p.Material, p.CFrame = name, size, color, mat, CFrame.new(0, y, 0)
		p.Parent = m
		return p
	end
	m.PrimaryPart = part("Handle", Vector3.new(0.2, 2.6, 0.2), 1.3, Color3.fromRGB(120, 78, 44), Enum.Material.Wood)
	part("Head", Vector3.new(2.0, 0.32, 0.32), 2.5, i == 1 and Color3.fromRGB(150, 110, 70) or Color3.fromRGB(140, 140, 150), i == 1 and Enum.Material.Wood or Enum.Material.Slate)
	return m
end

equipPick = function(s)
	local ch = s.player.Character
	local hand = ch and (ch:FindFirstChild("RightHand") or ch:FindFirstChild("Right Arm"))
	if not hand then return end
	local old = ch:FindFirstChild("HeldPickaxe")
	if old then old:Destroy() end
	local m = pickModel(s.pick)
	m.Name = "HeldPickaxe"
	local cf, size = m:GetBoundingBox()
	local root = m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart", true)
	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.Massless = false, false, false, false, true
			if p ~= root then -- explicit offsets: a WeldConstraint would capture them after the hand weld has moved the root
				local wp = Instance.new("Weld")
				wp.Part0, wp.Part1, wp.C0 = root, p, root.CFrame:ToObjectSpace(p.CFrame)
				wp.Parent = p
			end
		end
	end
	-- grip a quarter up the handle; the pick plane faces the side camera, head up out of the fist
	local grip = CFrame.new(cf.Position - Vector3.new(0, size.Y * 0.22, 0))
	local w = Instance.new("Weld")
	w.Name, w.Part0, w.Part1 = "PickGrip", hand, root
	w.C0 = CFrame.new(0, -hand.Size.Y * 0.35, 0) * CFrame.Angles(0, math.rad(90), 0)
	w.C1 = root.CFrame:ToObjectSpace(grip)
	w:SetAttribute("BaseC0", w.C0)
	w.Parent = root
	m.Parent = ch
end

BuyR.OnServerEvent:Connect(function(plr, what)
	local s = data[plr]
	local list = (what == "pick" and C.PICKS) or (what == "pack" and C.PACKS)
	if not s or not list then return end
	local nxt = list[s[what] + 1]
	if not nxt or s.gold < nxt.cost then return end
	s.gold -= nxt.cost
	s[what] += 1
	if what == "pick" then equipPick(s) end
	if s.step == 4 then s.step = #s.pets > 0 and 6 or 5 end
	FxR:FireClient(plr, "bought", nxt.name)
	sendState(s)
end)

local function buildStatic(s)
	local f = Instance.new("Folder")
	f.Name = "Static"
	local function part(size, pos, color, props)
		local p = proto:Clone()
		p.Size, p.Position, p.Color = size, pos, color
		for k, v in props or {} do p[k] = v end
		p.Parent = f
		return p
	end
	local depth = ROWS * B
	local midX = s.x0 + COLS * B / 2
	local SIDE, BACK = 6 * B, 18 -- the shaft sits in a thick chunk: side columns and a deep backing show depth from the tilted camera
	local sideX = { s.x0 - SIDE / 2, s.x0 + COLS * B + SIDE / 2 }
	for i, lay in C.LAYERS do
		local y, base = -(i - 0.5) * C.LAYER_ROWS * B, lay[4][1][2]
		part(Vector3.new(COLS * B, C.LAYER_ROWS * B, BACK), Vector3.new(midX, y, -B / 2 - BACK / 2), base:Lerp(Color3.new(), 0.55), { CanQuery = false }) -- dug cells show this
		for _, x in sideX do
			part(Vector3.new(SIDE, C.LAYER_ROWS * B, B + BACK), Vector3.new(x, y, B / 2 - (B + BACK) / 2), base:Lerp(Color3.new(), 0.2), { Material = Enum.Material.Ground })
		end
	end
	for _, x in sideX do -- grass on the side columns
		part(Vector3.new(SIDE, 0.9, B + BACK), Vector3.new(x, 0.45, B / 2 - (B + BACK) / 2), C.GRASS)
	end
	part(Vector3.new(COLS * B + 2 * SIDE, B, B + BACK), Vector3.new(midX, -depth - B / 2, B / 2 - (B + BACK) / 2), Color3.fromRGB(34, 26, 22)) -- floor
	part(Vector3.new(COLS * B + 2 * SIDE, depth + 40, 1), Vector3.new(midX, -depth / 2 + 20, B / 2 + 1.2), Color3.new(), { Transparency = 1, CanQuery = false }) -- keeps players on the plane
	part(Vector3.new(COLS * B + 2 * SIDE, 20, 1), Vector3.new(midX, 10, -B / 2 - 0.5), Color3.new(), { Transparency = 1, CanQuery = false }) -- back wall above ground
	-- Sell stand at the surface (camp art comes later from the Gemini board)
	local standPos = cellPos(s, 0, 3)
	local counter = part(Vector3.new(7, 3, 3), standPos + Vector3.new(0, -0.5, -0.5), Color3.fromRGB(150, 98, 52))
	part(Vector3.new(8, 0.8, 3.6), standPos + Vector3.new(0, 5.5, -0.5), Color3.fromRGB(200, 60, 50))
	part(Vector3.new(0.6, 5, 0.6), standPos + Vector3.new(-3.4, 2.5, -0.5), Color3.fromRGB(96, 64, 36))
	part(Vector3.new(0.6, 5, 0.6), standPos + Vector3.new(3.4, 2.5, -0.5), Color3.fromRGB(96, 64, 36))
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromScale(6, 2)
	bb.StudsOffset = Vector3.new(0, 4.5, 0)
	local t = Instance.new("TextLabel")
	t.Size, t.BackgroundTransparency = UDim2.fromScale(1, 1), 1
	t.Font, t.TextScaled, t.Text = Enum.Font.Arcade, true, "SELL"
	t.TextColor3, t.TextStrokeTransparency = Color3.fromRGB(255, 220, 90), 0
	t.Parent = bb
	bb.Parent = counter
	counter.Touched:Connect(function(hitPart)
		if hitPart.Parent == s.player.Character then sell(s) end
	end)
	-- Incubator at camp: touch it to hatch one stored egg (camp art comes from the board later)
	local incPos = cellPos(s, 0, C.INCUBATOR_COL)
	local base = part(Vector3.new(4.5, 1.2, 3.5), incPos + Vector3.new(0, -1.3, -0.5), Color3.fromRGB(120, 92, 150))
	local dome = part(Vector3.new(3.2, 3.2, 3.2), incPos + Vector3.new(0, 1.0, -0.5), Color3.fromRGB(200, 240, 255), { Shape = Enum.PartType.Ball, Material = Enum.Material.Glass, Transparency = 0.45, CanCollide = false })
	local egg = part(Vector3.new(1.4, 1.8, 1.4), incPos + Vector3.new(0, 0.6, -0.5), C.EGG_COLOR, { Shape = Enum.PartType.Ball, Material = Enum.Material.Neon, CanCollide = false })
	local glow = Instance.new("PointLight")
	glow.Color, glow.Range, glow.Brightness = Color3.fromRGB(255, 220, 160), 10, 1.5
	glow.Parent = egg
	local ib = Instance.new("BillboardGui")
	ib.Name, ib.Size, ib.StudsOffset = "IncubatorSign", UDim2.fromScale(7, 2), Vector3.new(0, 3.6, 0)
	local it = Instance.new("TextLabel")
	it.Size, it.BackgroundTransparency = UDim2.fromScale(1, 1), 1
	it.Font, it.TextScaled, it.Text = Enum.Font.Arcade, true, "HATCH"
	it.TextColor3, it.TextStrokeTransparency = Color3.fromRGB(255, 230, 160), 0
	it.Parent = ib
	ib.Parent = dome
	s.incubatorSign = it
	base.Touched:Connect(function(hitPart)
		if hitPart.Parent ~= s.player.Character or s.eggs <= 0 or os.clock() < (s.nextHatch or 0) then return end
		s.eggs -= 1
		s.nextHatch = os.clock() + C.HATCH_TIME + 1
		hatch(s)
		sendState(s)
	end)
	f.Parent = s.root
end

local function onJoin(plr)
	local profile = Store:StartSessionAsync(tostring(plr.UserId), { Cancel = function() return plr.Parent ~= Players end })
	if not profile then
		plr:Kick("Could not load your save. Please rejoin.")
		return
	end
	profile:AddUserId(plr.UserId)
	profile:Reconcile()
	if plr.Parent ~= Players then
		profile:EndSession()
		return
	end
	profile.OnSessionEnd:Connect(function()
		if plr.Parent == Players then plr:Kick("Your save was opened on another server.") end
	end)
	local d = profile.Data
	local slot = 0
	while slots[slot] do slot += 1 end
	slots[slot] = true
	local root = Instance.new("Folder")
	root.Name = "Shaft_" .. plr.UserId
	local folder = Instance.new("Folder")
	folder.Name = "Blocks"
	folder.Parent = root
	local s = {
		player = plr, slot = slot, x0 = slot * (COLS + C.SHAFT_GAP) * B, sc = C.START_COL, seed = 1000 + slot * 77,
		grid = {}, built = {}, row = 0, root = root, folder = folder, rng = Random.new(),
		gold = d.gold, bag = d.step == 1 and C.PREFILL or 0, bagV = d.step == 1 and C.PREFILL or 0,
		pick = math.clamp(d.pick, 1, #C.PICKS), pack = math.clamp(d.pack, 1, #C.PACKS), pets = {}, step = d.step,
		frenzyUntil = 0, combo = 0, bank = 0, best = d.best, nextDig = 0, hatched = d.hatched, pity = d.pity,
		profile = profile, critKey = 0, critT0 = 0, lastHit = 0, eggs = d.eggs,
	}
	for _, n in d.pets do
		if C.PETS[n] and #s.pets < C.MAX_PETS then table.insert(s.pets, { name = n, next = os.clock() + 2 }) end
	end
	-- Night Shaft: the crew dug while you were away (capped); the report shows once you spawn
	local away = d.lastSeen > 0 and math.min(os.time() - d.lastSeen, C.NIGHT_CAP) or 0
	if away >= C.NIGHT_MIN and #s.pets > 0 then
		local power = 0
		for _, p in s.pets do power += C.PETS[p.name][3] / C.PETS[p.name][4] end
		local gold = math.floor(away / 60 * power * C.NIGHT_RATE)
		if gold > 0 then
			s.gold += gold
			s.nightReport = { math.floor(away / 60), gold }
		end
	end
	data[plr] = s
	local t0 = os.clock()
	buildStatic(s)
	refreshWindow(s)
	root.Parent = shafts
	root:SetAttribute("BuildMs", math.floor((os.clock() - t0) * 1000))
	local function spawned(ch)
		local hrp = ch:WaitForChild("HumanoidRootPart")
		ch:WaitForChild("RightHand", 5)
		task.wait()
		hrp.CFrame = surfaceCFrame(s)
		equipPick(s)
		sendState(s)
		if s.nightReport then
			FxR:FireClient(plr, "night", s.nightReport[1], s.nightReport[2], #s.pets)
			s.nightReport = nil
		end
	end
	plr.CharacterAdded:Connect(spawned)
	if plr.Character then task.spawn(spawned, plr.Character) end
	task.defer(sendState, s)
end
Players.PlayerAdded:Connect(onJoin)
for _, plr in Players:GetPlayers() do task.spawn(onJoin, plr) end

Players.PlayerRemoving:Connect(function(plr)
	local s = data[plr]
	if not s then return end
	save(s)
	s.profile:EndSession()
	s.root:Destroy()
	slots[s.slot] = nil
	data[plr] = nil
end)

-- Tick: window, frenzy end, crew digging
local PET_SCAN = { { 1, 0 }, { 0, -1 }, { 0, 1 }, { 1, -1 }, { 1, 1 }, { 2, 0 }, { -1, -1 }, { -1, 1 } }
while true do
	task.wait(0.2)
	local now = os.clock()
	for plr, s in data do
		local dev = IS_STUDIO and plr:GetAttribute("DevGold") -- Studio-only test hook: set the attribute on the server to add gold
		if dev then
			plr:SetAttribute("DevGold", nil)
			s.gold += dev
			sendState(s)
		end
		local devRow = IS_STUDIO and plr:GetAttribute("DevRow") -- Studio test hook: dig a pocket at that row and go there
		local hrp0 = hrpOf(plr)
		if devRow and hrp0 then
			plr:SetAttribute("DevRow", nil)
			for r = devRow - 1, devRow + 1 do
				ensureRow(s, r)
				for c = s.sc - 1, s.sc + 1 do
					local cell = s.grid[r] and s.grid[r][c]
					if cell and cell.part then cell.part:Destroy(); cell.part = nil; cell.k = "air" end
				end
			end
			hrp0.CFrame = CFrame.new(cellPos(s, devRow + 1, s.sc) + Vector3.new(0, B / 2 + 2.5, 0))
		end
		local devEggs = IS_STUDIO and plr:GetAttribute("DevEggs")
		if devEggs then
			plr:SetAttribute("DevEggs", nil)
			s.eggs += devEggs
			sendState(s)
		end
		local hrp = hrpOf(plr)
		if hrp then
			local row = math.floor(-(hrp.Position.Y - 1) / B) + 1
			local col = math.clamp(math.floor((hrp.Position.X - s.x0) / B) + 1, 1, COLS)
			if row ~= s.row then
				s.row = row
				refreshWindow(s)
			end
			if s.frenzyUntil > 0 and now > s.frenzyUntil then
				s.frenzyUntil = 0
				local newBest = s.combo > s.best
				if newBest then s.best = s.combo end
				FxR:FireClient(plr, "frenzyEnd", s.bank, s.combo, newBest)
			end
			for i, pet in s.pets do
				local stats = C.PETS[pet.name]
				if now >= pet.next and s.bag < cap(s) then
					pet.next = now + stats[4]
					for _, d in PET_SCAN do
						local r, c = row + d[1], col + d[2]
						local cell = s.grid[r] and s.grid[r][c]
						if cell and cell.part then
							FxR:FireClient(plr, "petDig", i, r, c)
							hit(s, r, c, stats[3], pet.name)
							break
						end
					end
				end
			end
		end
	end
end
