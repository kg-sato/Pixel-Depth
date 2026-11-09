-- ServerScriptService.PixelServer: the shared camp hub, private 3D voxel mines, digging, backpack, selling, upgrades, frenzy, eggs, crew.
-- The server decides everything. Everyone shares the hub (HubBuilder, at the origin); each player owns a mine far away
-- (MINE_X0 + slot * PLOT_GAP) made of B-stud cells; the lift in the hub moves you between them.
-- Cells: row r (1 = first row under the crust, down), column c (+x) and depth d (+z), 1..MINE_W. Only rock surfaces
-- that face the open cave around the player are Parts: a flood fill from the player's cell decides which (refresh).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local SS = game:GetService("ServerStorage")
local IS_STUDIO = game:GetService("RunService"):IsStudio()
local C = require(RS:WaitForChild("Shared"):WaitForChild("Config"))
local ProfileStore = require(game:GetService("ServerScriptService"):WaitForChild("ProfileStore"))
local HubBuilder = require(game:GetService("ServerScriptService"):WaitForChild("HubBuilder"))
local CaveBuilder = require(game:GetService("ServerScriptService"):WaitForChild("CaveBuilder"))
local Store = ProfileStore.New(C.SAVE_STORE, C.SAVE_TEMPLATE)

local B, W = C.B, C.MINE_W
local ROWS = #C.LAYERS * C.LAYER_ROWS
local E1, E2, DROP = C.ENTRY[1], C.ENTRY[2], C.ENTRY_DROP
local TOP = -C.CRUST * B -- y of the mine's top face (the crust is above it)

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

local oldHub = workspace:FindFirstChild("Hub") -- always build the current hub (an Edit-mode preview may be saved in the place)
if oldHub then oldHub:Destroy() end
local hub = HubBuilder.build(workspace, Vector3.zero)
local HUB_SPAWN = hub:FindFirstChild("SpawnPoint").CFrame
local HUB_SELL = hub:FindFirstChild("SellPoint", true)

-- Caves (cave exploration rework): one shared cave world per server, built from the hour's seed at C.CAVE_ORIGIN.
-- The lift takes players to Camp 1 instead of their private block mine while C.CAVES_ON is true (the old mine code stays).
local caveLanding
if C.CAVES_ON then
	local oldCaves = workspace:FindFirstChild("Caves") -- an Edit-mode preview may be saved in the place
	if oldCaves then oldCaves:Destroy() end
	local caves = CaveBuilder.build(workspace, C.CAVE_ORIGIN, os.time() // 3600)
	caveLanding = caves:FindFirstChild("LiftLanding", true)
end

local plots = Instance.new("Folder")
plots.Name = "Shafts"
plots.Parent = workspace

-- Night (key art scene_night.png): moonlit lilac camp outdoors; under the crust it is dark, light comes from the lantern and glowing things
Lighting.ClockTime = 0.4
Lighting.Brightness = 0.8
Lighting.ExposureCompensation = -0.25
Lighting.Ambient = Color3.fromRGB(30, 24, 50)
Lighting.OutdoorAmbient = Color3.fromRGB(80, 74, 136) -- cool indigo shadows; the lanterns carry the warm light
Lighting.EnvironmentDiffuseScale, Lighting.EnvironmentSpecularScale = 0.3, 0.25
Lighting.GlobalShadows, Lighting.ShadowSoftness = true, 0.3
local function effect(cls, props)
	local e = Lighting:FindFirstChildOfClass(cls) or Instance.new(cls)
	for k, v in props do e[k] = v end
	e.Parent = Lighting
end
effect("Atmosphere", { Density = 0.3, Offset = 0.12, Haze = 1.4, Glare = 0, Color = Color3.fromRGB(86, 70, 140), Decay = Color3.fromRGB(34, 22, 66) })
effect("BloomEffect", { Intensity = 0.35, Size = 22, Threshold = 1.3 })
effect("ColorCorrectionEffect", { Saturation = 0.06, Contrast = 0.12, Brightness = 0.02, TintColor = Color3.fromRGB(242, 234, 255) })
effect("Sky", { StarCount = 3000, MoonAngularSize = 18, CelestialBodiesShown = true })
local clouds = workspace.Terrain:FindFirstChildOfClass("Clouds") or Instance.new("Clouds")
clouds.Cover, clouds.Density, clouds.Color, clouds.Parent = 0.45, 0.5, Color3.fromRGB(120, 110, 176), workspace.Terrain

local proto = Instance.new("Part")
proto.Anchored = true
proto.Size = Vector3.new(B, B, B)
proto.Material = Enum.Material.SmoothPlastic
proto.TopSurface, proto.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth

local data = {} -- [player] = plot state
local equipPick -- defined with the held pickaxe below
local slots = {}

local function layerOf(r)
	return math.clamp(math.ceil(r / C.LAYER_ROWS), 1, #C.LAYERS)
end
local function keyOf(r, c, d)
	return (r + 8) * 4096 + (c + 4) * 64 + (d + 4)
end
local function cellPos(s, r, c, d)
	return Vector3.new(s.ox + (c - 0.5 - W / 2) * B, TOP - (r - 0.5) * B, s.oz + (d - 0.5 - W / 2) * B)
end
local function cellOf(s, pos) -- row, column, depth of a world position (rows < 1 are in the crust or the sky)
	return math.floor((TOP - pos.Y) / B) + 1, math.floor((pos.X - s.ox) / B + W / 2) + 1, math.floor((pos.Z - s.oz) / B + W / 2) + 1
end

-- Neighbours: dr, dc, dd and the face of a block that looks at that neighbour
local NB = {
	{ -1, 0, 0, Enum.NormalId.Top }, { 1, 0, 0, Enum.NormalId.Bottom }, { 0, 1, 0, Enum.NormalId.Right },
	{ 0, -1, 0, Enum.NormalId.Left }, { 0, 0, 1, Enum.NormalId.Back }, { 0, 0, -1, Enum.NormalId.Front },
}

local SHRINE = {} -- [row] = room rows (3 rows from each shrine row; columns and depths 3..7)
for _, r0 in C.SHRINE_ROWS do for r = r0, r0 + 2 do SHRINE[r] = true end end
local function inShrine(r, c, d)
	return SHRINE[r] and c >= 3 and c <= 7 and d >= 3 and d <= 7
end

-- Generation (pure, deterministic per plot seed)
local function caveAt(s, r, c, d)
	if r < 4 or r > ROWS or c < 1 or c > W or d < 1 or d > W then return false end
	if r < C.CAVE_START and math.abs(c - E1 - 0.5) < 5 and math.abs(d - E2 - 0.5) < 5 then return false end -- the tutorial column stays solid
	local sx, sy = C.CAVE_SCALE[1], C.CAVE_SCALE[2]
	local L = layerOf(r)
	if math.noise(c / sx + s.nx, r / sy + 0.31, d / sx + s.nz) > C.CAVE_LEVEL - math.min(L - 1, 3) * 0.03 then return true end
	local w = C.WORM_WIDTH
	if math.abs(math.noise(c / 11 + s.nx + 40.7, r / 9, d / 11 + s.nz)) > w then return false end
	return math.abs(math.noise(c / 11 + s.nx, r / 9 + 70.3, d / 11 + s.nz + 20.9)) < w
end

local H4 = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }
local function wetAt(s, r, c, d) -- a pool sits on a cave floor where no open neighbour would let it spill
	if caveAt(s, r + 1, c, d) then return false end
	if math.noise(c / 7 + s.nx + 9.1, r / 5 + 0.7, d / 7 + s.nz) < 0.08 then return false end
	for _, o in H4 do
		local cc, dd = c + o[1], d + o[2]
		if caveAt(s, r, cc, dd) and caveAt(s, r + 1, cc, dd) then return false end
	end
	return Random.new(s.seed * 13 + keyOf(r, c, d)):NextNumber() < C.WATER_CHANCE
end

local function genKind(s, r, c, d)
	if c < 1 or c > W or d < 1 or d > W or r > ROWS then return "bedrock" end
	local hole = (c == E1 or c == E1 + 1) and (d == E2 or d == E2 + 1)
	if r < 1 then return "crust" end
	if hole then
		if r <= DROP then return "air" end
		local k = C.START[r - DROP]
		if k then return k end
	end
	if inShrine(r, c, d) then return "air" end
	if caveAt(s, r, c, d) then return wetAt(s, r, c, d) and "water" or "air" end
	local rng = Random.new(s.seed * 7919 + keyOf(r, c, d))
	local x = rng:NextNumber()
	local deep = r > DROP + C.START_ROWS
	if deep and x < C.EGG_CHANCE then return "egg" end
	if x < C.ORE3_CHANCE then return (deep and rng:NextNumber() < C.GILDED_CHANCE * 8) and "gild" or "ore3" end
	if x < C.ORE3_CHANCE + C.ORE2_CHANCE then return "ore2" end
	return "base"
end

local function genAt(s, k, r, c, d)
	local g = s.gen[k]
	if g == nil then
		g = genKind(s, r, c, d)
		s.gen[k] = g
	end
	return g
end
local function kindAt(s, r, c, d)
	local k = keyOf(r, c, d)
	return s.mods[k] or genAt(s, k, r, c, d)
end
local function isOpen(kind)
	return kind == "air" or kind == "water"
end
local UNBREAKABLE = { bedrock = true, crust = true }

local function cellInfo(kind, r) -- ore name, colour, value and hp of a solid cell
	local L = layerOf(r)
	local hpScale, valScale = 2 ^ (L - 1), 3 ^ (L - 1)
	if kind == "egg" then
		return { ore = "Fossil Egg", col = C.EGG_COLOR, v = 0, hp = 2 * hpScale }
	end
	local o = C.LAYERS[L][4][(kind == "ore2" and 2) or ((kind == "ore3" or kind == "gild") and 3) or 1]
	local info = { ore = o[1], col = o[2], v = o[4] * valScale, hp = math.ceil(o[3] * hpScale) }
	if kind == "gild" then
		info.ore, info.col, info.v = "Gilded " .. o[1], C.GILD_COLOR, info.v * C.GILD_MULT
	end
	return info
end

local GILD_ODDS = math.floor(1 / (C.ORE3_CHANCE * C.GILDED_CHANCE * 8) + 0.5) -- true per-block odds for the tags
local EGG_ODDS = math.floor(1 / C.EGG_CHANCE + 0.5)

local function texFor(kind, r, c, d)
	if kind == "gild" then return C.TEX.gilded end
	if kind == "egg" then return C.TEX.egg end
	local nm = C.LAYER_TEX[layerOf(math.max(r, 1))]
	if kind == "bedrock" then return C.TEX[nm .. "_wall"] end
	if kind == "ore2" or kind == "ore3" then return C.TEX[nm .. "_" .. kind] end
	return C.TEX[nm .. "_base" .. ((r * 7 + c * 13 + d * 5) % 2)]
end

local function shade(col, r, c, d)
	local h, sat, v = col:ToHSV()
	return Color3.fromHSV(h, sat, math.clamp(v * (0.85 + ((r * 7 + c * 13 + d * 3) % 3) * 0.07), 0, 1))
end

local FACE_SHADE = { [Enum.NormalId.Top] = 1, [Enum.NormalId.Front] = 0.86, [Enum.NormalId.Back] = 0.86, [Enum.NormalId.Left] = 0.78, [Enum.NormalId.Right] = 0.78, [Enum.NormalId.Bottom] = 0.6 }
-- A block shows its texture on every face that looks into open space; a natural cave floor gets a mossy top
local function updateFaces(s, p, r, c, d, kind)
	for _, n in NB do
		local face = n[4]
		if not p:FindFirstChild(face.Name) then
			local rr, cc, dd = r + n[1], c + n[2], d + n[3]
			local nk = rr >= 1 and kindAt(s, rr, cc, dd) or "crust"
			if isOpen(nk) then
				local dc = Instance.new("Decal")
				dc.Name, dc.Face = face.Name, face
				local mossy = face == Enum.NormalId.Top and kind ~= "gild" and kind ~= "egg" and not s.mods[keyOf(rr, cc, dd)] and rr >= C.CAVE_START
				dc.Texture = mossy and C.TEX.moss_top or texFor(kind, r, c, d)
				local k = FACE_SHADE[face]
				dc.Color3 = Color3.new(k, k, k * 1.04)
				dc.Parent = p
			end
		end
	end
end

local function buildBlock(s, k, r, c, d, fake)
	local p = proto:Clone()
	p.Name = r .. "_" .. c .. "_" .. d
	p.Position = cellPos(s, r, c, d)
	p:SetAttribute("R", r)
	p:SetAttribute("C", c)
	p:SetAttribute("D", d)
	if fake then -- closes the view where the open cave goes on past the render box: reads as darkness
		p.Color, p.Material = Color3.fromRGB(6, 4, 12), Enum.Material.SmoothPlastic
		p.CastShadow, p.CanCollide = false, false
		p:SetAttribute("Fake", true)
	else
		local kind = kindAt(s, r, c, d)
		local base = C.LAYERS[layerOf(math.max(r, 1))][4][1][2]
		p.Color = shade(kind == "bedrock" and base:Lerp(Color3.new(), 0.5) or base, r, c, d)
		updateFaces(s, p, r, c, d, kind)
		if kind == "gild" or kind == "egg" then -- rare: glowing block with a rarity outline and a true 1 IN N tag (the client draws the tag)
			local l = Instance.new("PointLight")
			l.Color, l.Range, l.Brightness = kind == "gild" and Color3.fromRGB(255, 210, 110) or Color3.fromRGB(255, 220, 236), 10, 0.6
			l.Parent = p
			p:SetAttribute("Tag", "1 IN " .. (kind == "gild" and GILD_ODDS or EGG_ODDS))
			p:SetAttribute("TagColor", kind == "gild" and Color3.fromRGB(255, 206, 70) or Color3.fromRGB(255, 157, 176))
		end
		if kind == "bedrock" then p:SetAttribute("Bedrock", true) end
		if kind == "ore3" then p:SetAttribute("Ore", C.LAYERS[layerOf(r)][4][3][2]) end
	end
	p.Parent = s.folder
	s.parts[k] = p
	return p
end

-- Cave dressing (only in natural caves): glowing pastel mushrooms and crystals on floors, stalactites on ceilings, pebbles, pools
local function decoPart(f, size, cf, color, neon, shape)
	local q = Instance.new("Part")
	q.Anchored, q.CanCollide, q.CanQuery, q.CanTouch, q.CastShadow = true, false, false, false, false
	q.Size, q.CFrame, q.Color = size, cf, color
	q.Material = neon and Enum.Material.Neon or Enum.Material.SmoothPlastic
	q.TopSurface, q.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	if shape then q.Shape = shape end
	q.Parent = f
	return q
end

local function buildDeco(s, k, r, c, d)
	if s.mods[k] or s.noDeco[k] then return end -- dug cells stay bare
	local kind = genAt(s, k, r, c, d)
	local f = Instance.new("Folder")
	f.Name = "D" .. k
	local pos = cellPos(s, r, c, d)
	local floorY, ceilY = pos.Y - B / 2, pos.Y + B / 2
	local rng = Random.new(s.seed * 31 + k)
	local L = layerOf(r)
	local wall = C.LAYERS[L][4][1][2]
	if kind == "water" then
		local w = decoPart(f, Vector3.new(B, B * 0.6, B), CFrame.new(pos.X, floorY + B * 0.3, pos.Z), Color3.fromRGB(70, 150, 200))
		w.Transparency, w.Name = 0.5, "Water"
		local surf = decoPart(f, Vector3.new(B, 0.05, B), CFrame.new(pos.X, floorY + B * 0.6 + 0.03, pos.Z), Color3.fromRGB(150, 225, 240))
		surf.Transparency, surf.Name = 0.55, "WaterSurface"
		local t = Instance.new("Texture")
		t.Texture, t.Face, t.StudsPerTileU, t.StudsPerTileV, t.Transparency = C.TEX.water_top, Enum.NormalId.Top, B, B, 0.1
		t.Parent = surf
		surf:SetAttribute("Ripple", true)
	elseif r < ROWS and not isOpen(kindAt(s, r + 1, c, d)) and r >= C.CAVE_START then
		local x = rng:NextNumber()
		local tint = C.PASTEL[rng:NextInteger(1, #C.PASTEL)]
		if x < C.DECO.mushroom then
			for i = 1, rng:NextInteger(1, 3) do
				local h = rng:NextNumber(0.7, 1.8) * (i == 1 and 1.3 or 1)
				local px, pz = pos.X + rng:NextNumber(-1.3, 1.3), pos.Z + rng:NextNumber(-1.3, 1.3)
				decoPart(f, Vector3.new(0.35, h, 0.35), CFrame.new(px, floorY + h / 2, pz), Color3.fromRGB(240, 228, 220))
				local cap = decoPart(f, Vector3.new(h * 0.9, h * 0.45, h * 0.9), CFrame.new(px, floorY + h, pz), tint, true)
				cap.Shape = Enum.PartType.Ball
				cap:SetAttribute("Glow", true)
				if i == 1 and rng:NextNumber() < 0.5 then
					local l = Instance.new("PointLight")
					l.Color, l.Range, l.Brightness = tint, 9, 0.9
					l.Parent = cap
				end
			end
		elseif x < C.DECO.mushroom + C.DECO.crystal then
			for i = 1, rng:NextInteger(2, 4) do
				local h = rng:NextNumber(1, 2.6)
				local cf = CFrame.new(pos.X + rng:NextNumber(-1, 1), floorY + h * 0.4, pos.Z + rng:NextNumber(-1, 1)) * CFrame.Angles(rng:NextNumber(-0.4, 0.4), rng:NextNumber(0, 6), rng:NextNumber(-0.4, 0.4))
				local q = decoPart(f, Vector3.new(0.55, h, 0.55), cf, tint, true)
				q:SetAttribute("Glow", true)
				if i == 1 then
					local l = Instance.new("PointLight")
					l.Color, l.Range, l.Brightness = tint, 11, 1.2
					l.Parent = q
				end
			end
		elseif x < 0.55 then
			for _ = 1, rng:NextInteger(2, 5) do -- pebbles and grass tufts
				local sz = rng:NextNumber(0.3, 0.8)
				decoPart(f, Vector3.new(sz, sz * 0.6, sz), CFrame.new(pos.X + rng:NextNumber(-1.6, 1.6), floorY + sz * 0.3, pos.Z + rng:NextNumber(-1.6, 1.6)) * CFrame.Angles(0, rng:NextNumber(0, 3), 0),
					rng:NextNumber() < 0.5 and Color3.fromRGB(110, 199, 166) or wall:Lerp(Color3.new(1, 1, 1), 0.25))
			end
		end
	end
	if kind == "air" and r > 1 and not isOpen(kindAt(s, r - 1, c, d)) and rng:NextNumber() < C.DECO.drip then
		for _ = 1, rng:NextInteger(1, 3) do -- pixel stalactites: stacked shrinking blocks
			local px, pz = pos.X + rng:NextNumber(-1.4, 1.4), pos.Z + rng:NextNumber(-1.4, 1.4)
			local y, w = ceilY, rng:NextNumber(0.7, 1.1)
			for _ = 1, rng:NextInteger(2, 3) do
				local h = w * 0.9
				decoPart(f, Vector3.new(w, h, w), CFrame.new(px, y - h / 2, pz), wall:Lerp(Color3.fromRGB(200, 180, 230), 0.25))
				y -= h
				w *= 0.6
			end
			if rng:NextNumber() < 0.35 then
				decoPart(f, Vector3.new(0.22, 0.22, 0.22), CFrame.new(px, y - 0.3, pz), Color3.fromRGB(140, 227, 192), true):SetAttribute("Drip", true)
			end
		end
	end
	if #f:GetChildren() == 0 then
		f:Destroy()
		return
	end
	f.Parent = s.decoFolder
	s.decos[k] = f
end

-- Render pass: flood the open cells around the player (inside the view box); every solid neighbour is a visible surface
local function refresh(s)
	local pr, pc, pd = s.pr, s.pc, s.pd
	local queue = {}
	if pr < 1 then -- in the hub: keep the landing under the lift ready
		for _, cc in { E1, E1 + 1 } do for _, dd in { E2, E2 + 1 } do table.insert(queue, { 1, cc, dd }) end end
		pr, pc, pd = 1 + C.VIEW_UP, E1, E2
	else
		table.insert(queue, { pr, pc, pd })
		table.insert(queue, { pr - 1, pc, pd })
	end
	local seen, need, open = {}, {}, {}
	local R, UP, DN = C.VIEW_R, C.VIEW_UP, C.VIEW_DOWN
	local head = 1
	while head <= #queue and head <= C.VIEW_MAX do
		local q = queue[head]
		head += 1
		local r, c, d = q[1], q[2], q[3]
		local k = keyOf(r, c, d)
		if not seen[k] and r >= 1 then
			seen[k] = true
			if isOpen(kindAt(s, r, c, d)) then
				open[k] = q
				for _, n in NB do
					local rr, cc, dd = r + n[1], c + n[2], d + n[3]
					if rr >= 1 then
						local nk = keyOf(rr, cc, dd)
						if not seen[nk] then
							if math.abs(cc - pc) > R or math.abs(dd - pd) > R or rr < pr - UP or rr > pr + DN then
								seen[nk] = true
								need[nk] = { rr, cc, dd, isOpen(kindAt(s, rr, cc, dd)) }
							else
								table.insert(queue, { rr, cc, dd })
							end
						end
					end
				end
			else
				need[k] = q
			end
		end
	end
	for k, p in s.parts do
		local n = need[k]
		if not n or (n[4] or false) ~= (p:GetAttribute("Fake") or false) then
			p:Destroy()
			s.parts[k] = nil
		end
	end
	for k, n in need do
		local p = s.parts[k]
		if not p then
			buildBlock(s, k, n[1], n[2], n[3], n[4])
		elseif not n[4] then
			updateFaces(s, p, n[1], n[2], n[3], kindAt(s, n[1], n[2], n[3]))
		end
	end
	for k, f in s.decos do
		if not open[k] then
			f:Destroy()
			s.decos[k] = nil
		end
	end
	for k, q in open do
		if not s.decos[k] then buildDeco(s, k, q[1], q[2], q[3]) end
	end
end

local function cap(s)
	return C.PACKS[s.pack].cap
end

local function target(s) -- tutorial target cell {r, c, d}
	local t = (s.step == 1 and { DROP + 1, E1, E2 }) or (s.step == 2 and { DROP + 4, E1, E2 }) or (s.step == 5 and { DROP + 6, E1, E2 })
	if t and isOpen(kindAt(s, t[1], t[2], t[3])) then
		if s.step == 2 or s.step == 5 then -- that cell is gone: point at any remaining cell of the same row
			for _, cc in { E1, E1 + 1 } do for _, dd in { E2, E2 + 1 } do
				if not isOpen(kindAt(s, t[1], cc, dd)) then return { t[1], cc, dd } end
			end end
		end
		return nil
	end
	return t or nil
end

local function save(s) -- mirror the saved fields into the ProfileStore session (it autosaves and saves on leave)
	local d = s.profile and s.profile.Data
	if not d then return end
	d.gold, d.pick, d.pack, d.best, d.hatched, d.pity, d.step = s.gold, s.pick, s.pack, s.best, s.hatched, s.pity, s.step
	d.eggs, d.lastSeen, d.deepest = s.eggs, os.time(), s.deepest
	d.gems, d.lv, d.equip = s.gems, s.lv, s.equip
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
		pets = pets, ox = s.ox, oz = s.oz, folder = s.folder.Name, best = s.best, pity = s.pity, eggs = s.eggs,
		deepest = s.deepest, goal = s.goal, gems = s.gems, lv = s.lv, equip = s.equip,
	})
end

local function spawnCFrame()
	return HUB_SPAWN * CFrame.new(math.random(-30, 30) / 10, 0, math.random(-10, 10) / 10)
end

local function landingCFrame(s) -- standing on the first tutorial blocks under the lift in your mine
	local p = cellPos(s, DROP, E1, E2) + Vector3.new(B / 2, 0.5, B / 2)
	return CFrame.lookAt(p, p + Vector3.new(0, 0, -1))
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

local function stir(s, r, c, d) -- Titan's Stir: a loose boulder drops down the dug column from a few rows up
	local top = r - 3
	if top < 1 then return end
	local start = isOpen(kindAt(s, top, c, d)) and top or top + 1
	FxR:FireClient(s.player, "stir", cellPos(s, start, c, d))
	task.delay(C.STIR_WARN, function()
		if data[s.player] ~= s then return end
		local land
		for rr = start, ROWS do
			if not isOpen(kindAt(s, rr, c, d)) then break end
			land = rr
		end
		if not land then return end
		local pos = cellPos(s, land, c, d)
		FxR:FireClient(s.player, "fell", pos)
		local hrp = hrpOf(s.player)
		if hrp and math.abs(hrp.Position.X - pos.X) < B * 0.9 and math.abs(hrp.Position.Z - pos.Z) < B * 0.9 and math.abs(hrp.Position.Y - pos.Y) < B * 1.4 then
			local lost = math.floor(s.bag * C.STIR_LOSS) -- it bursts on your helmet: stun and spill, no rubble
			if s.bag > 0 then s.bagV -= math.floor(s.bagV * lost / s.bag) end
			s.bag -= lost
			s.nextDig = os.clock() + C.STIR_STUN
			FxR:FireClient(s.player, "bonk", lost)
			sendState(s)
			return
		end
		s.mods[keyOf(land, c, d)] = "base" -- otherwise it lands as rubble and refills the hole
		s.hp[keyOf(land, c, d)] = nil
		refresh(s)
	end)
end

local function breakCell(s, k, r, c, d)
	local p = s.parts[k]
	if p then p:Destroy() end
	s.parts[k] = nil
	s.mods[k] = "air"
	s.hp[k] = nil
	for _, nk in { keyOf(r - 1, c, d), keyOf(r + 1, c, d) } do -- the floor or ceiling under the cave dressing is gone
		s.noDeco[nk] = true
		if s.decos[nk] then s.decos[nk]:Destroy(); s.decos[nk] = nil end
	end
	refresh(s)
end

local function hit(s, r, c, d, dmg, who, crit)
	local k = keyOf(r, c, d)
	local kind = kindAt(s, r, c, d)
	if isOpen(kind) or UNBREAKABLE[kind] then return end
	local info = cellInfo(kind, r)
	local hp = (s.hp[k] or info.hp) - dmg
	local p = s.parts[k]
	if hp > 0 then
		s.hp[k] = hp
		FxR:FireClient(s.player, "hit", p, hp / info.hp, who, crit)
		return
	end
	local pos = cellPos(s, r, c, d)
	breakCell(s, k, r, c, d)
	if s.step == 1 then s.step = 2 end
	if r > s.deepest then
		local L0, L1 = layerOf(math.max(s.deepest, 1)), layerOf(r)
		s.deepest = r
		if L1 > L0 and s.deepest > 1 then -- first time into a new layer: a depth reward
			local bonus = 25 * 3 ^ (L1 - 1)
			s.gold += bonus
			FxR:FireClient(s.player, "newLayer", L1, bonus)
		end
	end
	if kind == "egg" then
		FxR:FireClient(s.player, "break", pos, info.ore, 0, who, 0, info.col, crit, kind)
		if s.hatched == 0 then
			hatch(s) -- the tutorial egg hatches on the spot
		else
			s.eggs += 1
			FxR:FireClient(s.player, "egg", s.eggs)
		end
		sendState(s)
		return
	end
	local now, v = os.clock(), info.v
	if kind == "gild" and now > s.frenzyUntil then
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
	if layerOf(r) == C.STIR_LAYER and s.rng:NextNumber() < C.STIR_CHANCE then stir(s, r, c, d) end
	FxR:FireClient(s.player, "break", pos, info.ore, v, who, combo, info.col, crit, kind)
	if s.step == 2 and s.bag >= cap(s) then s.step = 3 end
	sendState(s)
end

DigR.OnServerEvent:Connect(function(plr, part)
	local s = data[plr]
	if not s or typeof(part) ~= "Instance" or part.Parent ~= s.folder then return end
	local now = os.clock()
	if now < s.nextDig then return end
	local r, c, d = part:GetAttribute("R"), part:GetAttribute("C"), part:GetAttribute("D")
	if type(r) ~= "number" or type(c) ~= "number" or type(d) ~= "number" then return end
	local k = keyOf(r, c, d)
	local ch = plr.Character
	local headPart = ch and (ch:FindFirstChild("Head") or ch:FindFirstChild("HumanoidRootPart"))
	if s.parts[k] ~= part or part:GetAttribute("Fake") or not headPart or (headPart.Position - part.Position).Magnitude > C.REACH then return end
	local kind = kindAt(s, r, c, d)
	if UNBREAKABLE[kind] then
		FxR:FireClient(plr, "bedrock", part.Position)
		return
	end
	s.nextDig = now + C.DIG_COOLDOWN
	if s.bag >= cap(s) and kind ~= "egg" then
		FxR:FireClient(plr, "full")
		return
	end
	-- hit-timing crit, decided on the server clock: the ring restarts on a new block and after each crit
	local dmg, crit = C.PICKS[s.equip].power, false
	local t = workspace:GetServerTimeNow()
	if s.critKey ~= k then
		s.critKey, s.critT0 = k, t
		FxR:FireClient(plr, "ring", part, t)
	else
		local since = t - s.critT0
		local inCycle = since % C.CRIT_PERIOD
		local closing = inCycle / C.CRIT_PERIOD >= C.CRIT_FROM or (since > C.CRIT_PERIOD and inCycle <= C.CRIT_LATE)
		if closing and now - s.lastHit >= C.CRIT_GAP then
			crit, dmg = true, dmg * C.CRIT_MULT
			s.critT0 = t
			FxR:FireClient(plr, "ring", part, t)
		end
	end
	s.lastHit = now
	hit(s, r, c, d, dmg, "you", crit)
end)

local function sell(s)
	if s.bag <= 0 then return end
	s.gold += s.bagV
	FxR:FireClient(s.player, "sold", s.bagV, s.bag)
	s.bag, s.bagV = 0, 0
	if s.step <= 3 then s.step = 4 end
	sendState(s)
end

SellR.OnServerEvent:Connect(function(plr) -- the lift: ride up to the sell stall and sell
	local s = data[plr]
	local hrp = hrpOf(plr)
	if not s or not hrp then return end
	hrp.CFrame = HUB_SELL and (HUB_SELL.CFrame * CFrame.Angles(0, math.pi, 0) + Vector3.new(0, 1, 0)) or spawnCFrame() -- face the stall
	plr:SetAttribute("InMine", false)
	plr:SetAttribute("InCave", false)
	FxR:FireClient(plr, "lift", false)
	sell(s)
end)

local enterMine -- defined below
SurfaceR.OnServerEvent:Connect(function(plr, dir) -- the rail lift button: "down" into your mine, otherwise up to camp
	local s = data[plr]
	local hrp = hrpOf(plr)
	if s and dir == "down" then
		enterMine(s)
		return
	end
	if s and hrp then
		hrp.CFrame = spawnCFrame()
		plr:SetAttribute("InMine", false)
		plr:SetAttribute("InCave", false)
		FxR:FireClient(plr, "lift", false)
		sendState(s) -- the bag pill switches back from the cave's unbanked count
	end
end)

enterMine = function(s)
	local hrp = hrpOf(s.player)
	if not hrp or s.player:GetAttribute("InMine") or s.player:GetAttribute("InCave") then return end
	if caveLanding then
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.CFrame = caveLanding.CFrame + Vector3.new(0, 3, 0)
		s.player:SetAttribute("InCave", true)
		FxR:FireClient(s.player, "lift", true)
		sendState(s) -- the bag pill turns into the unbanked ore count in the caves
		return
	end
	s.pr = -99 -- render the landing now
	hrp.AssemblyLinearVelocity = Vector3.zero
	hrp.CFrame = landingCFrame(s)
	s.player:SetAttribute("InMine", true)
	FxR:FireClient(s.player, "lift", true)
end

-- Cave ore deposits (stage 4, refs ORE-01/02, EXT-01/02, board artboard CaveUI). Deposits are shared, loot is per player:
-- each player extracts each deposit once. Its prompt starts a minigame; the server keeps the clock, the gold arc and the
-- crack sequence, grades the result and pays ore from the deposit's own attributes into the unbanked bag (no bag limit).
local ExtractR = remote("Extract")
local D = C.DEPOSIT
local function finishMinigame(s)
	local mg = s.mg
	if not mg then return end
	s.mg = nil
	local count, grade
	if mg.kind == "strike" then
		count, grade = D.strikes * D.chunks + mg.perfects * D.bonus, mg.perfects
	else
		for _, g in D.grades do
			if (mg.slips or math.huge) <= g[2] then
				count, grade = math.max(1, math.floor(D.rushChunks * g[3] + 0.5)), g[1]
				break
			end
		end
	end
	local L, idx = mg.dep:GetAttribute("Layer"), mg.dep:GetAttribute("Ore")
	local o = C.LAYERS[L][4][idx]
	local v = math.floor(o[4] * 3 ^ (L - 1) * C.pickValue(s.equip, s.lv[tostring(s.equip)]) + 0.5)
	s.bag += count
	s.bagV += count * v
	s.claimed[mg.dep] = true
	FxR:FireClient(s.player, "mgEnd", mg.dep, o[1], count, count * v, o[2], grade)
	sendState(s)
end
local caveDeposits = caveLanding and workspace.Caves:FindFirstChild("Deposits")
for _, dep in caveDeposits and caveDeposits:GetChildren() or {} do
	local core = dep.PrimaryPart
	local pr = Instance.new("ProximityPrompt")
	pr.ActionText, pr.ObjectText, pr.KeyboardKeyCode, pr.GamepadKeyCode = "Extract", dep:GetAttribute("OreName"), Enum.KeyCode.E, Enum.KeyCode.ButtonX
	pr.RequiresLineOfSight, pr.MaxActivationDistance, pr.HoldDuration = false, D.reach, 0
	pr.Style = Enum.ProximityPromptStyle.Custom -- drawn by PixelClient
	pr.Parent = core
	pr.Triggered:Connect(function(plr)
		local s, hrp = data[plr], hrpOf(plr)
		if not s or not hrp or s.mg or s.claimed[dep] or not plr:GetAttribute("InCave") then return end
		if (hrp.Position - core.Position).Magnitude > D.reach + 4 then return end
		local now = workspace:GetServerTimeNow()
		if dep:GetAttribute("Ore") < 3 then
			s.mg = { kind = "strike", dep = dep, t0 = now, arc = s.rng:NextNumber() * 360, zone = C.strikeArc(s.lv[tostring(s.equip)]), swings = 0, perfects = 0, last = 0, deadline = now + D.strikes * 4 + 2 }
			FxR:FireClient(plr, "mgStart", dep, "strike", now, s.mg.arc, s.mg.zone)
		else
			local seq = {} -- the side of the red crack on each beat: 1 left, 2 right; chiseling that side slips
			for i = 1, s.rng:NextInteger(D.rush[1], D.rush[2]) do seq[i] = s.rng:NextInteger(1, 2) end
			s.mg = { kind = "rush", dep = dep, t0 = now, seq = seq, deadline = now + #seq * D.rushBeat + 3 }
			FxR:FireClient(plr, "mgStart", dep, "rush", now, seq)
		end
	end)
end
ExtractR.OnServerEvent:Connect(function(plr, what, arg)
	local s = data[plr]
	local mg = s and s.mg
	if not mg then return end
	local now = workspace:GetServerTimeNow()
	if what == "strike" and mg.kind == "strike" then
		if now - mg.last < 0.25 then return end
		mg.last = now
		-- the moment the player pressed, trusted only within their network delay
		-- shortcut: a cheater can pick the best moment inside that 0.08-0.35 s window; send server-timed swing windows if it matters
		local window = math.clamp(plr:GetNetworkPing() * 2 + 0.08, 0.08, 0.35)
		local t = (type(arg) == "number" and arg == arg) and math.clamp(arg, now - window, now) or now
		local needle = ((t - mg.t0) / D.strikePeriod % 1) * 360
		local perfect = math.abs((needle - mg.arc + 180) % 360 - 180) <= mg.zone / 2 + 2
		mg.swings += 1
		if perfect then mg.perfects += 1 end
		mg.arc = (mg.arc + 90 + s.rng:NextNumber() * 180) % 360
		FxR:FireClient(plr, "mgStrike", mg.swings, perfect, mg.arc)
		if mg.swings >= D.strikes then finishMinigame(s) end
	elseif what == "rush" and mg.kind == "rush" and type(arg) == "table" then
		local slips = 0
		for i, crack in mg.seq do
			if (arg[i] ~= 1 and arg[i] ~= 2) or arg[i] == crack then slips += 1 end
		end
		local took = now - mg.t0
		if took > #mg.seq * D.rushBeat + 1.5 or took < #mg.seq * 0.12 then slips = math.huge end -- out of time, or faster than hands
		mg.slips = slips
		finishMinigame(s)
	end
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
	local wood, woodDk = Color3.fromRGB(176, 120, 82), Color3.fromRGB(110, 70, 56)
	local head, headLt, headDk = i == 1 and Color3.fromRGB(214, 168, 112) or Color3.fromRGB(150, 146, 172), i == 1 and Color3.fromRGB(240, 204, 150) or Color3.fromRGB(196, 194, 214), i == 1 and Color3.fromRGB(150, 100, 70) or Color3.fromRGB(96, 92, 120)
	local function cube(name, size, pos, color)
		local p = Instance.new("Part")
		p.Name, p.Size, p.Color, p.Material, p.CFrame = name, size, color, Enum.Material.SmoothPlastic, CFrame.new(pos)
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.Parent = m
		return p
	end
	m.PrimaryPart = cube("Handle", Vector3.new(0.34, 2.7, 0.34), Vector3.new(0, 1.35, 0), wood)
	cube("Grip", Vector3.new(0.4, 0.7, 0.4), Vector3.new(0, 0.45, 0), woodDk)
	cube("Bind", Vector3.new(0.5, 0.4, 0.5), Vector3.new(0, 2.55, 0), woodDk)
	cube("Head", Vector3.new(0.7, 0.6, 0.6), Vector3.new(0, 2.85, 0), head)
	for _, s in { -1, 1 } do -- each arm: three cubes curving down to a bright tip
		cube("Arm", Vector3.new(0.55, 0.5, 0.5), Vector3.new(s * 0.6, 2.88, 0), head)
		cube("Arm", Vector3.new(0.5, 0.45, 0.46), Vector3.new(s * 1.08, 2.74, 0), headDk)
		cube("Tip", Vector3.new(0.42, 0.42, 0.42), Vector3.new(s * 1.5, 2.5, 0), headLt)
	end
	return m
end

equipPick = function(s)
	local ch = s.player.Character
	local hand = ch and (ch:FindFirstChild("RightHand") or ch:FindFirstChild("Right Arm"))
	if not hand then return end
	local old = ch:FindFirstChild("HeldPickaxe")
	if old then old:Destroy() end
	local m = pickModel(s.equip)
	m.Name = "HeldPickaxe"
	m:SetAttribute("Tier", s.equip)
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
	local grip = CFrame.new(cf.Position - Vector3.new(0, size.Y * 0.22, 0))
	local w = Instance.new("Weld")
	w.Name, w.Part0, w.Part1 = "PickGrip", hand, root
	w.C0 = CFrame.new(0, -hand.Size.Y * 0.35, 0) * CFrame.Angles(0, math.rad(90), 0)
	w.C1 = root.CFrame:ToObjectSpace(grip)
	w:SetAttribute("BaseC0", w.C0)
	w.Parent = root
	m.Parent = ch
end

-- The torch (the user, 2026-11-08: pickaxe in the right hand, torch in the left). Its flame carries the "Lantern" light the
-- client dims in the caves. Below ground both tools are in hand; in town the pickaxe rides on the back and the torch is put away.
local function buildTorch(ch)
	local hand = ch:FindFirstChild("LeftHand") or ch:FindFirstChild("Left Arm")
	if not hand then return end
	local old = ch:FindFirstChild("HeldTorch")
	if old then old:Destroy() end
	local m = Instance.new("Model")
	m.Name = "HeldTorch"
	local function tp(name, size, color, mat)
		local p = Instance.new("Part")
		p.Name, p.Size, p.Color, p.Material = name, size, color, mat or Enum.Material.SmoothPlastic
		p.CanCollide, p.CanQuery, p.CanTouch, p.Massless, p.CastShadow = false, false, false, true, false
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.Parent = m
		return p
	end
	local handle = tp("Handle", Vector3.new(0.32, 1.7, 0.32), Color3.fromRGB(122, 84, 58))
	local pieces = {
		{ tp("Wrap", Vector3.new(0.46, 0.36, 0.46), Color3.fromRGB(78, 56, 44)), 0.72 },
		{ tp("Flame", Vector3.new(0.52, 0.56, 0.52), Color3.fromRGB(255, 150, 60), Enum.Material.Neon), 1.12 },
		{ tp("Core", Vector3.new(0.3, 0.34, 0.3), Color3.fromRGB(255, 236, 160), Enum.Material.Neon), 1.16 },
	}
	for _, piece in pieces do
		local wd = Instance.new("Weld")
		wd.Part0, wd.Part1, wd.C0 = handle, piece[1], CFrame.new(0, piece[2], 0)
		wd.Parent = piece[1]
	end
	local flame = m:FindFirstChild("Flame")
	local light = Instance.new("PointLight")
	light.Name, light.Color, light.Range, light.Brightness, light.Shadows = "Lantern", Color3.fromRGB(255, 220, 180), 28, 1.1, true
	light.Parent = flame
	local sparks = Instance.new("ParticleEmitter")
	sparks.Name, sparks.Rate, sparks.Lifetime, sparks.Speed = "Sparks", 6, NumberRange.new(0.4, 0.8), NumberRange.new(1, 2.5)
	sparks.Size, sparks.LightEmission = NumberSequence.new(0.12, 0), 1
	sparks.Color, sparks.SpreadAngle, sparks.Acceleration = ColorSequence.new(Color3.fromRGB(255, 200, 110)), Vector2.new(25, 25), Vector3.new(0, 3, 0)
	sparks.Parent = flame
	m.PrimaryPart = handle
	local w = Instance.new("Weld")
	w.Name, w.Part0, w.Part1 = "TorchGrip", hand, handle
	w.C0 = CFrame.new(0, -hand.Size.Y * 0.4, 0) * CFrame.Angles(math.rad(-70), 0, 0) * CFrame.new(0, 0.45, 0) -- forward and a little up from the fist
	w.Parent = handle
	m.Parent = ch
end
local function mountGear(s)
	local ch = s.player.Character
	if not ch then return end
	local under = s.player:GetAttribute("InCave") == true or s.player:GetAttribute("InMine") == true
	local pick = ch:FindFirstChild("HeldPickaxe")
	local grip = pick and pick:FindFirstChild("PickGrip", true)
	local hand = ch:FindFirstChild("RightHand") or ch:FindFirstChild("Right Arm")
	local back = ch:FindFirstChild("UpperTorso") or ch:FindFirstChild("Torso")
	if grip and hand and back then
		if under then
			grip.Part0, grip.C0 = hand, grip:GetAttribute("BaseC0")
		else -- slung across the back, head up over the left shoulder
			grip.Part0, grip.C0 = back, CFrame.new(0, 0.1, back.Size.Z / 2 + 0.3) * CFrame.Angles(0, 0, math.rad(40)) * CFrame.Angles(0, math.rad(90), 0)
		end
	end
	local torch = ch:FindFirstChild("HeldTorch")
	if torch then
		for _, p in torch:GetDescendants() do
			if p:IsA("BasePart") then p.Transparency = under and 0 or 1 end
			if p:IsA("PointLight") or p:IsA("ParticleEmitter") then p.Enabled = under end
		end
	end
end

BuyR.OnServerEvent:Connect(function(plr, what, arg)
	local s = data[plr]
	if s and (what == "upgrade" or what == "equip") then -- forge v2: level an owned pickaxe with gems, or hold another owned one
		if type(arg) ~= "number" or arg ~= arg or arg % 1 ~= 0 or arg < 1 or arg > s.pick then return end
		if what == "equip" then
			if arg == s.equip then return end
			s.equip = arg
			equipPick(s)
			mountGear(s)
			FxR:FireClient(plr, "equipped", arg)
		else
			local lv = s.lv[tostring(arg)] or 1
			local cost = C.upgradeCost(arg, lv)
			if not cost or s.gems < cost then return end
			s.gems -= cost
			s.lv[tostring(arg)] = lv + 1
			FxR:FireClient(plr, "upgraded", arg, lv + 1)
		end
		sendState(s)
		return
	end
	local list = (what == "pick" and C.PICKS) or (what == "pack" and C.PACKS)
	if not s or not list then return end
	local nxt = list[s[what] + 1]
	if not nxt or s.gold < nxt.cost then return end
	s.gold -= nxt.cost
	s[what] += 1
	if what == "pick" then
		s.equip = s.pick -- a new pickaxe goes straight into the hand
		equipPick(s)
		mountGear(s)
	end
	if s.step == 4 then s.step = #s.pets > 0 and 6 or 5 end
	FxR:FireClient(plr, "bought", nxt.name, what)
	sendState(s)
end)

local function texture(p, face, tex, studs, tint)
	local t = Instance.new("Texture")
	t.Texture, t.Face, t.StudsPerTileU, t.StudsPerTileV = tex, face, studs, studs
	if tint then t.Color3 = tint end
	t.Parent = p
	return t
end

local function buildShrine(s, f, L, r0)
	-- hidden shrine room (rows r0..r0+2, columns and depths 3..7): pillars, altar with a glowing relic, a chest
	local a, b = cellPos(s, r0, 3, 3), cellPos(s, r0 + 2, 7, 7)
	local mid = (a + b) / 2
	local lc = C.LAYERS[L][4][3][2]
	local function part(name, size, cf, color, mat)
		local q = proto:Clone()
		q.Name, q.Size, q.CFrame, q.Color, q.Material, q.CanCollide = name, size, cf, color, mat or Enum.Material.SmoothPlastic, false
		q.Parent = f
		return q
	end
	local floorY = b.Y - B / 2
	part("ShrineFloor", Vector3.new(5 * B, 0.6, 5 * B), CFrame.new(mid.X, floorY + 0.3, mid.Z), Color3.fromRGB(200, 190, 230), Enum.Material.Marble).CanCollide = true
	for _, o in { { -2, -2 }, { 2, -2 }, { -2, 2 }, { 2, 2 } } do
		part("ShrinePillar", Vector3.new(1.4, 3 * B - 1, 1.4), CFrame.new(mid.X + o[1] * B, mid.Y, mid.Z + o[2] * B), Color3.fromRGB(230, 220, 245), Enum.Material.Marble)
	end
	part("Altar", Vector3.new(3, 2, 3), CFrame.new(mid.X, floorY + 1.6, mid.Z), Color3.fromRGB(190, 176, 228), Enum.Material.Marble)
	local relic = part("Relic", Vector3.new(1.6, 1.6, 1.6), CFrame.new(mid.X, floorY + 3.8, mid.Z), lc, Enum.Material.Neon)
	relic.Shape = Enum.PartType.Ball
	relic:SetAttribute("Bob", 0.35)
	local l = Instance.new("PointLight")
	l.Color, l.Range, l.Brightness, l.Shadows = lc, 18, 2, true
	l.Parent = relic
	local chest = part("Chest", Vector3.new(2.6, 1.8, 1.8), CFrame.new(mid.X + 1.4 * B, floorY + 1.5, mid.Z), Color3.fromRGB(160, 100, 60), Enum.Material.WoodPlanks)
	local lid = part("ChestLid" .. L, Vector3.new(2.8, 0.5, 2), chest.CFrame * CFrame.new(0, 1.1, 0), Color3.fromRGB(255, 206, 70), Enum.Material.Metal)
	chest:SetAttribute("Lid", lid.Name)
	local pr = Instance.new("ProximityPrompt")
	pr.ActionText, pr.ObjectText, pr.KeyboardKeyCode, pr.RequiresLineOfSight, pr.MaxActivationDistance = "Open", "Shrine chest", Enum.KeyCode.F, false, 10
	pr.Style = Enum.ProximityPromptStyle.Custom -- drawn by PixelClient
	pr.Parent = chest
	pr.Triggered:Connect(function(plr)
		if plr ~= s.player or chest:GetAttribute("Opened") then return end
		chest:SetAttribute("Opened", true)
		pr.Enabled = false
		local gold = 60 * 3 ^ (L - 1)
		s.gold += gold
		FxR:FireClient(plr, "chest", chest, gold, C.LAYERS[L][1])
		sendState(s)
	end)
	table.insert(s.shrines, { lo = a - Vector3.new(B / 2, -B / 2, B / 2), hi = b + Vector3.new(B / 2, -B / 2, B / 2), pos = relic.Position })
end

local function buildStatic(s)
	-- the crust over the mine (closed: you arrive by lift) and a lamp-lit lift cage at the landing; shrines below
	local f = Instance.new("Folder")
	f.Name = "Static"
	local T = C.CRUST * B
	local crust = proto:Clone()
	crust.Name, crust.Size, crust.Position, crust.Color = "Crust", Vector3.new(W * B + 8, T, W * B + 8), Vector3.new(s.ox, -T / 2, s.oz), Color3.fromRGB(46, 34, 54)
	crust.Parent = f
	texture(crust, Enum.NormalId.Bottom, C.TEX.rootholm_wall, B)
	local land = cellPos(s, 1, E1, E2) + Vector3.new(B / 2, 0, B / 2)
	for _, o in { { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } } do
		local post = proto:Clone()
		post.Name, post.Size, post.Color, post.Material = "CagePost", Vector3.new(0.7, DROP * B, 0.7), Color3.fromRGB(176, 120, 82), Enum.Material.SmoothPlastic
		post.Position = land + Vector3.new(o[1] * (B - 0.4), -(DROP - 1) * B / 2, o[2] * (B - 0.4))
		post.CanCollide = false
		post.Parent = f
	end
	local lamp = proto:Clone()
	lamp.Name, lamp.Size, lamp.Position, lamp.Color, lamp.Material, lamp.CanCollide = "CageLamp", Vector3.new(1, 1.2, 1), land + Vector3.new(B - 1, 0, B - 1), Color3.fromRGB(255, 206, 120), Enum.Material.Neon, false
	local l = Instance.new("PointLight")
	l.Color, l.Range, l.Brightness, l.Shadows = Color3.fromRGB(255, 206, 150), 20, 0.9, true
	l.Parent = lamp
	lamp.Parent = f
	local up = proto:Clone() -- ride the lift back up to the camp
	up.Name, up.Size, up.Position, up.Color, up.Material, up.CanCollide = "LiftLever", Vector3.new(0.6, 2.4, 0.6), land + Vector3.new(-B + 1, -B, B - 1), Color3.fromRGB(255, 214, 92), Enum.Material.Metal, false
	up.Parent = f
	local pr = Instance.new("ProximityPrompt")
	pr.ActionText, pr.ObjectText, pr.KeyboardKeyCode, pr.RequiresLineOfSight, pr.MaxActivationDistance = "Ride up", "Lift", Enum.KeyCode.F, false, 12
	pr.Style = Enum.ProximityPromptStyle.Custom -- drawn by PixelClient
	pr.Parent = up
	pr.Triggered:Connect(function(plr)
		local hrp = hrpOf(plr)
		if plr ~= s.player or not hrp then return end
		hrp.CFrame = spawnCFrame()
		plr:SetAttribute("InMine", false)
		FxR:FireClient(plr, "lift", false)
	end)
	for L, r0 in C.SHRINE_ROWS do buildShrine(s, f, L, r0) end
	f.Parent = s.root
end

-- Hub stations: every prompt in the hub belongs to whoever triggers it
local function dailyChest(s)
	local day = math.floor(os.time() / 86400)
	local d = s.profile.Data
	if d.chestDay == day then
		FxR:FireClient(s.player, "chestWait", 86400 - os.time() % 86400)
		return
	end
	s.streak = d.chestDay == day - 1 and math.min((d.streak or 0) + 1, 7) or math.max(d.streak or 0, 1) -- a missed day only pauses the streak
	d.chestDay, d.streak = day, s.streak
	local gold = C.CHEST_GOLD * s.streak * 3 ^ (layerOf(math.max(s.deepest, 1)) - 1)
	s.gold += gold
	FxR:FireClient(s.player, "dailyChest", gold, s.streak)
	sendState(s)
end

local STATION = {
	sell = function(s) sell(s) end,
	forge = function(s) FxR:FireClient(s.player, "openForge") end,
	map = function(s) FxR:FireClient(s.player, "map", s.deepest) end,
	chest = dailyChest,
	enter = function(s) enterMine(s) end,
	hatch = function(s)
		if s.eggs <= 0 then FxR:FireClient(s.player, "noEggs"); return end
		if os.clock() < (s.nextHatch or 0) then return end
		s.eggs -= 1
		s.nextHatch = os.clock() + C.HATCH_TIME + 1
		hatch(s)
		sendState(s)
	end,
}
for _, d in hub:GetDescendants() do
	if d:IsA("ProximityPrompt") and d.Parent:GetAttribute("Station") then
		local kind = d.Parent:GetAttribute("Station")
		d.Triggered:Connect(function(plr)
			local s = data[plr]
			if s and STATION[kind] then STATION[kind](s) end
		end)
	end
end
local pit = hub:FindFirstChild("PitFloor", true) -- jumping into the glowing pit also takes the lift down
pit.Touched:Connect(function(hitPart)
	local plr = Players:GetPlayerFromCharacter(hitPart.Parent)
	local s = plr and data[plr]
	if s then enterMine(s) end
end)

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
	local decoFolder = Instance.new("Folder")
	decoFolder.Name = "Deco"
	decoFolder.Parent = root
	local seed = 1000 + slot * 77
	local s = {
		player = plr, slot = slot, ox = C.MINE_X0 + slot * C.PLOT_GAP, oz = 0, seed = seed, nx = (seed % 97) * 0.731 + 0.123, nz = (seed % 89) * 0.577 + 0.311,
		gen = {}, mods = {}, hp = {}, parts = {}, decos = {}, noDeco = {}, pr = 0, pc = E1, pd = E2,
		root = root, folder = folder, decoFolder = decoFolder, rng = Random.new(),
		gold = d.gold, bag = d.step == 1 and C.PREFILL or 0, bagV = d.step == 1 and C.PREFILL or 0,
		pick = math.clamp(d.pick, 1, #C.PICKS), pack = math.clamp(d.pack, 1, #C.PACKS), pets = {}, step = d.step,
		frenzyUntil = 0, combo = 0, bank = 0, best = d.best, nextDig = 0, hatched = d.hatched, pity = d.pity,
		profile = profile, critKey = 0, critT0 = 0, lastHit = 0, eggs = d.eggs, shrines = {}, deepest = d.deepest or 0, streak = d.streak or 0,
		claimed = {}, -- cave deposits this player has extracted (loot is per player)
		gems = d.gems or 0, lv = d.lv or {}, -- forge levels keyed by pickaxe tier as a string (DataStore-safe keys)
	}
	s.equip = (d.equip or 0) >= 1 and math.min(d.equip, s.pick) or s.pick
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
	refresh(s)
	root.Parent = plots
	root:SetAttribute("BuildMs", math.floor((os.clock() - t0) * 1000))
	local function spawned(ch)
		local hrp = ch:WaitForChild("HumanoidRootPart")
		ch:WaitForChild("RightHand", 5)
		task.wait()
		hrp.CFrame = spawnCFrame()
		plr:SetAttribute("InMine", false)
		plr:SetAttribute("InCave", false)
		ch:WaitForChild("LeftHand", 5)
		buildTorch(ch) -- the miner's light: the caves are dark, light comes from your torch and the glowing things
		equipPick(s)
		mountGear(s)
		sendState(s)
		if s.nightReport then
			FxR:FireClient(plr, "night", s.nightReport[1], s.nightReport[2], #s.pets)
			s.nightReport = nil
		end
	end
	plr.CharacterAdded:Connect(spawned)
	plr:GetAttributeChangedSignal("InCave"):Connect(function() mountGear(s) end)
	plr:GetAttributeChangedSignal("InMine"):Connect(function() mountGear(s) end)
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

-- Tick: render box, frenzy end, shrines, crew digging
local PET_SCAN = { { 1, 0, 0 }, { 0, 1, 0 }, { 0, -1, 0 }, { 0, 0, 1 }, { 0, 0, -1 }, { 1, 1, 0 }, { 1, -1, 0 }, { 1, 0, 1 }, { 1, 0, -1 }, { 2, 0, 0 } }
while true do
	task.wait(0.1)
	local now = os.clock()
	for plr, s in data do
		local hrp = hrpOf(plr)
		if IS_STUDIO then -- Studio-only test hooks: set these attributes on the server
			local dev = plr:GetAttribute("DevGold")
			if dev then
				plr:SetAttribute("DevGold", nil)
				s.gold += dev
				sendState(s)
			end
			local devGems = plr:GetAttribute("DevGems")
			if devGems then
				plr:SetAttribute("DevGems", nil)
				s.gems += devGems
				sendState(s)
			end
			local devRow = plr:GetAttribute("DevRow") -- dig a pocket at that row under the entrance and go there
			if devRow and hrp then
				plr:SetAttribute("DevRow", nil)
				for r = devRow - 2, devRow do
					for c = E1, E1 + 1 do for d = E2, E2 + 1 do
						s.mods[keyOf(r, c, d)] = "air"
						local p = s.parts[keyOf(r, c, d)]
						if p then p:Destroy(); s.parts[keyOf(r, c, d)] = nil end
					end end
				end
				hrp.CFrame = CFrame.new(cellPos(s, devRow, E1, E2) + Vector3.new(B / 2, 0, B / 2))
				s.pr = -99
			end
			local devCave = plr:GetAttribute("DevCave") -- go to the first open cave floor at or below that row
			if devCave and hrp then
				plr:SetAttribute("DevCave", nil)
				local best
				for r = devCave, math.min(devCave + 60, ROWS - 1) do
					for c = 2, W - 1 do
						for d = 2, W - 1 do
							if not best and genAt(s, keyOf(r, c, d), r, c, d) == "air" and genAt(s, keyOf(r - 1, c, d), r - 1, c, d) == "air" and not isOpen(kindAt(s, r + 1, c, d)) then
								best = { r, c, d }
							end
						end
					end
					if best then break end
				end
				if best then
					hrp.CFrame = CFrame.new(cellPos(s, best[1], best[2], best[3]) + Vector3.new(0, 1, 0))
					plr:SetAttribute("InMine", true)
					s.pr = -99
				end
			end
			local devEggs = plr:GetAttribute("DevEggs")
			if devEggs then
				plr:SetAttribute("DevEggs", nil)
				s.eggs += devEggs
				sendState(s)
			end
		end
		if s.mg and workspace:GetServerTimeNow() > s.mg.deadline then -- a minigame left unfinished pays what it earned (Vein Rush: Chipped)
			finishMinigame(s)
		end
		if hrp and plr:GetAttribute("InCave") and s.bag > 0 then -- Camp 1's ring banks the unbanked ore (CMP-01)
			local o = C.CAVE_ORIGIN
			if Vector2.new(hrp.Position.X - o.X, hrp.Position.Z - o.Z).Magnitude < C.CAMP_RING and math.abs(hrp.Position.Y - o.Y) < 30 then sell(s) end
		end
		if hrp and not plr:GetAttribute("InCave") then
			local r, c, d = cellOf(s, hrp.Position)
			if r ~= s.pr or c ~= s.pc or d ~= s.pd then
				s.pr, s.pc, s.pd = r, c, d
				refresh(s)
			end
			for i = #s.shrines, 1, -1 do
				local sh, q = s.shrines[i], hrp.Position
				if q.X > sh.lo.X and q.X < sh.hi.X and q.Z > sh.lo.Z and q.Z < sh.hi.Z and q.Y < sh.lo.Y and q.Y > sh.hi.Y then
					table.remove(s.shrines, i)
					FxR:FireClient(plr, "shrine", sh.pos)
				end
			end
			if s.frenzyUntil > 0 and now > s.frenzyUntil then
				s.frenzyUntil = 0
				local newBest = s.combo > s.best
				if newBest then s.best = s.combo end
				FxR:FireClient(plr, "frenzyEnd", s.bank, s.combo, newBest)
			end
			if r >= 1 then -- the crew digs next to you in the mine
				for i, pet in s.pets do
					local stats = C.PETS[pet.name]
					if now >= pet.next and s.bag < cap(s) then
						pet.next = now + stats[4]
						for _, o in PET_SCAN do
							local rr, cc, dd = r + o[1], c + o[2], d + o[3]
							local kind = kindAt(s, rr, cc, dd)
							local p = s.parts[keyOf(rr, cc, dd)]
							if p and not isOpen(kind) and not UNBREAKABLE[kind] then
								FxR:FireClient(plr, "petDig", i, p)
								hit(s, rr, cc, dd, stats[3], pet.name)
								break
							end
						end
					end
				end
			end
		end
	end
end
