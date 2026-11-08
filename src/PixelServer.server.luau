-- ServerScriptService.PixelServer: shafts, digging, backpack, selling, upgrades, frenzy, eggs, crew (server decides everything).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local SS = game:GetService("ServerStorage")
local IS_STUDIO = game:GetService("RunService"):IsStudio()
local C = require(RS:WaitForChild("Shared"):WaitForChild("Config"))
local ProfileStore = require(game:GetService("ServerScriptService"):WaitForChild("ProfileStore"))
local Camp = require(game:GetService("ServerScriptService"):WaitForChild("CampBuilder"))
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

-- Night (key art scene_night.png): moon and stars, lavender ambient, glow sources do the lighting
Lighting.ClockTime = 0.3
Lighting.Brightness = 1.4
Lighting.Ambient = Color3.fromRGB(64, 54, 96)
Lighting.OutdoorAmbient = Color3.fromRGB(104, 92, 156)
Lighting.EnvironmentDiffuseScale, Lighting.EnvironmentSpecularScale = 0.45, 0.35
Lighting.GlobalShadows, Lighting.ShadowSoftness = true, 0.25
local function effect(cls, props)
	local e = Lighting:FindFirstChildOfClass(cls) or Instance.new(cls)
	for k, v in props do e[k] = v end
	e.Parent = Lighting
end
effect("Atmosphere", { Density = 0.3, Offset = 0.1, Haze = 0.5, Glare = 0.2, Color = Color3.fromRGB(70, 56, 120), Decay = Color3.fromRGB(28, 18, 60) })
effect("BloomEffect", { Intensity = 0.8, Size = 24, Threshold = 0.95 })
effect("ColorCorrectionEffect", { Saturation = 0.22, Contrast = 0.12, Brightness = 0.03, TintColor = Color3.fromRGB(240, 230, 255) })
effect("Sky", { StarCount = 3000, MoonAngularSize = 16, CelestialBodiesShown = true })
local clouds = workspace.Terrain:FindFirstChildOfClass("Clouds") or Instance.new("Clouds")
clouds.Cover, clouds.Density, clouds.Color, clouds.Parent = 0.4, 0.5, Color3.fromRGB(120, 110, 170), workspace.Terrain

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

local SHRINE = {} -- [row] = true for the three rows of each hidden shrine room (columns 3 to 7)
for _, r0 in C.SHRINE_ROWS do for r = r0, r0 + 2 do SHRINE[r] = true end end

local function newCell(s, r, c)
	if SHRINE[r] and c >= 3 and c <= 7 then return { k = "air" } end
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

local GILD_ODDS = math.floor(1 / (C.ORE3_CHANCE * C.GILDED_CHANCE * 8) + 0.5) -- true per-block odds for the tags
local EGG_ODDS = math.floor(1 / C.EGG_CHANCE + 0.5)

local function texFor(r, c, kind)
	if r == 1 then return C.TEX.grass end
	if kind == "gild" then return C.TEX.gilded end
	if kind == "egg" then return C.TEX.egg end
	local nm = C.LAYER_TEX[layerOf(r)]
	if kind == "ore2" or kind == "ore3" then return C.TEX[nm .. "_" .. kind] end
	return C.TEX[nm .. "_base" .. ((r * 7 + c * 13) % 2)]
end

local function buildPart(s, r, c, cell)
	local p = proto:Clone()
	p.Name = r .. "_" .. c
	p.Position = cellPos(s, r, c)
	local base = C.LAYERS[layerOf(r)][4][1][2]
	p.Color = shade(base, r, c):Lerp(Color3.new(), 0.25) -- side faces read as the shaded edge of the texture
	local tex = texFor(r, c, cell.k)
	for _, face in { Enum.NormalId.Back, Enum.NormalId.Top } do
		local d = Instance.new("Decal")
		d.Texture, d.Face = tex, face
		if face == Enum.NormalId.Top then d.Color3 = Color3.fromRGB(215, 205, 235) end
		d.Parent = p
	end
	if cell.k == "gild" or cell.k == "egg" then -- rare: whole glowing block with a rarity outline and a true 1 IN N tag (client draws the tag)
		local l = Instance.new("PointLight")
		l.Color, l.Range, l.Brightness = cell.k == "gild" and Color3.fromRGB(255, 210, 110) or Color3.fromRGB(255, 236, 220), 8, 0.8
		l.Parent = p
		p:SetAttribute("Tag", "1 IN " .. (cell.k == "gild" and GILD_ODDS or EGG_ODDS))
		p:SetAttribute("TagColor", cell.k == "gild" and Color3.fromRGB(255, 206, 70) or Color3.fromRGB(176, 101, 245))
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

local function texture(p, face, tex, studs, tint)
	local t = Instance.new("Texture")
	t.Texture, t.Face, t.StudsPerTileU, t.StudsPerTileV = tex, face, studs, studs
	if tint then t.Color3 = tint end
	t.Parent = p
end

local function buildShrine(s, f, L, r0)
	-- hidden shrine room (columns 3 to 7, three rows): pillars, altar with a glowing relic, a chest; mist hides it until you step in
	local a, b = cellPos(s, r0, 3), cellPos(s, r0 + 2, 7)
	local mid = (a + b) / 2
	local lc = C.LAYERS[L][4][3][2]
	local function part(name, size, cf, color, mat)
		local q = proto:Clone()
		q.Name, q.Size, q.CFrame, q.Color, q.Material, q.CanCollide = name, size, cf, color, mat or Enum.Material.SmoothPlastic, false
		q.Parent = f
		return q
	end
	local floorY = b.Y - B / 2
	part("ShrineFloor", Vector3.new(5 * B, 0.6, B), CFrame.new(mid.X, floorY + 0.3, 0), Color3.fromRGB(150, 140, 180), Enum.Material.Slate).CanCollide = true
	for _, dx in { -2, 2 } do
		part("ShrinePillar", Vector3.new(1.4, 3 * B - 1, 1.4), CFrame.new(mid.X + dx * B, mid.Y, -1), Color3.fromRGB(200, 190, 220), Enum.Material.Marble)
	end
	part("Altar", Vector3.new(3, 2, 2), CFrame.new(mid.X, floorY + 1.6, -1), Color3.fromRGB(170, 160, 200), Enum.Material.Marble)
	local relic = part("Relic", Vector3.new(1.4, 1.4, 1.4), CFrame.new(mid.X, floorY + 3.6, -1), lc, Enum.Material.Neon)
	relic.Shape = Enum.PartType.Ball
	relic:SetAttribute("Bob", 0.35)
	local l = Instance.new("PointLight")
	l.Color, l.Range, l.Brightness = lc, 16, 2
	l.Parent = relic
	local chest = part("Chest", Vector3.new(2.6, 1.8, 1.8), CFrame.new(mid.X + 1.2 * B, floorY + 0.9 + 0.6, 0), Color3.fromRGB(160, 100, 60), Enum.Material.WoodPlanks)
	part("ChestLid", Vector3.new(2.8, 0.5, 2), chest.CFrame * CFrame.new(0, 1.1, 0), Color3.fromRGB(255, 206, 70), Enum.Material.Metal)
	local pr = Instance.new("ProximityPrompt")
	pr.ActionText, pr.ObjectText, pr.KeyboardKeyCode, pr.RequiresLineOfSight, pr.MaxActivationDistance = "Open", "Shrine chest", Enum.KeyCode.F, false, 10
	pr.Parent = chest
	pr.Triggered:Connect(function(plr)
		if plr ~= s.player or chest:GetAttribute("Opened") then return end
		chest:SetAttribute("Opened", true)
		pr.Enabled = false
		local gold = 60 * 3 ^ (L - 1)
		s.gold += gold
		FxR:FireClient(plr, "chest", chest.Position, gold, C.LAYERS[L][1])
		sendState(s)
	end)
	local mist = part("ShrineMist", Vector3.new(5 * B + 1, 3 * B + 1, 0.6), CFrame.new(mid.X, mid.Y, B / 2 + 0.4), Color3.fromRGB(26, 18, 44), Enum.Material.SmoothPlastic)
	mist.Transparency, mist.CastShadow = 0.04, false
	local g = Instance.new("SurfaceGui")
	g.Face, g.LightInfluence = Enum.NormalId.Back, 0
	local t = Instance.new("TextLabel")
	t.Size, t.BackgroundTransparency, t.Text, t.TextScaled, t.Font = UDim2.fromScale(1, 1), 1, "?", true, Enum.Font.Arcade
	t.TextColor3, t.TextTransparency = Color3.fromRGB(200, 180, 255), 0.35
	t.Parent = g
	g.Parent = mist
	table.insert(s.shrines, { mist = mist, x0 = a.X - B / 2, x1 = b.X + B / 2, y0 = b.Y - B / 2, y1 = a.Y + B / 2 })
end

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
	local SIDE, BACK = C.CAMP_W * B, 18 -- wide camp ground on both sides; a deep backing shows depth from the tilted camera
	local sideX = { s.x0 - SIDE / 2, s.x0 + COLS * B + SIDE / 2 }
	for i, lay in C.LAYERS do
		local y, base = -(i - 0.5) * C.LAYER_ROWS * B, lay[4][1][2]
		local nm = C.LAYER_TEX[i]
		local back = part(Vector3.new(COLS * B, C.LAYER_ROWS * B, BACK), Vector3.new(midX, y, -B / 2 - BACK / 2), base:Lerp(Color3.new(), 0.55), { CanQuery = false })
		texture(back, Enum.NormalId.Back, C.TEX[nm .. "_cave"], B) -- dug cells show the cave texture
		for _, x in sideX do
			local wall = part(Vector3.new(SIDE, C.LAYER_ROWS * B, B + BACK), Vector3.new(x, y, B / 2 - (B + BACK) / 2), base:Lerp(Color3.new(), 0.3), { Material = Enum.Material.SmoothPlastic })
			texture(wall, Enum.NormalId.Back, C.TEX[nm .. "_wall"], B)
		end
	end
	for _, x in sideX do -- grass on the camp ground
		local g = part(Vector3.new(SIDE, 0.9, B + BACK + 30), Vector3.new(x, 0.45, B / 2 - (B + BACK + 30) / 2), Color3.fromRGB(70, 150, 130), { Material = Enum.Material.Grass })
		texture(g, Enum.NormalId.Back, C.TEX.grass, B)
	end
	part(Vector3.new(COLS * B + 2 * SIDE, B, B + BACK), Vector3.new(midX, -depth - B / 2, B / 2 - (B + BACK) / 2), Color3.fromRGB(34, 26, 22)) -- floor
	part(Vector3.new(COLS * B + 2 * SIDE, depth + 60, 1), Vector3.new(midX, -depth / 2 + 30, B / 2 + 1.2), Color3.new(), { Transparency = 1, CanQuery = false }) -- keeps players on the plane
	part(Vector3.new(COLS * B + 2 * SIDE, 30, 1), Vector3.new(midX, 15, -B / 2 - 0.5), Color3.new(), { Transparency = 1, CanQuery = false }) -- back wall above ground
	local colors = {}
	for i, lay in C.LAYERS do colors[i] = lay[4][1][2] end
	Camp.build(f, {
		x0 = s.x0, width = COLS * B, G = 0.9, sideW = SIDE, owner = s.player, seed = s.seed, layerColors = colors,
		startX = cellPos(s, 0, s.sc).X,
		on = {
			sell = function() sell(s) end,
			forge = function(plr) FxR:FireClient(plr, "openForge") end,
			map = function(plr) FxR:FireClient(plr, "map") end,
			hatch = function(plr)
				if s.eggs <= 0 then FxR:FireClient(plr, "noEggs"); return end
				if os.clock() < (s.nextHatch or 0) then return end
				s.eggs -= 1
				s.nextHatch = os.clock() + C.HATCH_TIME + 1
				hatch(s)
				sendState(s)
			end,
		},
	})
	for L, r0 in C.SHRINE_ROWS do buildShrine(s, f, L, r0) end
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
		profile = profile, critKey = 0, critT0 = 0, lastHit = 0, eggs = d.eggs, shrines = {},
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
		local lantern = Instance.new("PointLight") -- the miner's lantern: caves are dark, light comes from you and the glowing blocks
		lantern.Name, lantern.Color, lantern.Range, lantern.Brightness, lantern.Shadows = "Lantern", Color3.fromRGB(255, 214, 170), 26, 1.7, true
		lantern.Parent = hrp
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
			for i = #s.shrines, 1, -1 do
				local sh = s.shrines[i]
				local q = hrp.Position
				if q.X > sh.x0 - 2 and q.X < sh.x1 + 2 and q.Y > sh.y0 - 2 and q.Y < sh.y1 + 2 then
					table.remove(s.shrines, i)
					FxR:FireClient(plr, "shrine", sh.mist.Position)
					sh.mist:Destroy()
				end
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
