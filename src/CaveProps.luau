-- CaveProps (ServerScriptService.CaveProps): set dressing for the mine caves (night of 2026-11-16, the owner: "add props and
-- fine tune small details using the reference -> demo -> final product workflow while matching our new coloring, detail and
-- themes"; Gemini: "the caves look bare"). Reference: art/refs_props/props_flux_s12.png (local FLUX): cyan crystal clusters,
-- magenta glow mushrooms, timber supports with lanterns, hanging roots with glowing bulbs, rubble with gems, glow pebbles,
-- an old cart on a rail stub, all on obsidian-plum rock.
-- Props stand against the walls (a free floor spot with a wall within a few studs), never in the middle of a passage, and
-- keep away from the camps, deposits, shrines, nests, gates and the Clay hall. Display only: nothing collides except the
-- support posts, nothing can be clicked, raycasts pass through (CanQuery off). Bases sink into the floor (no coplanar faces).
--   CaveProps.build(caves)   -> the folder Caves.Props
local M = {}

local OBSIDIAN, PLUM, VIOLET = Color3.fromRGB(22, 8, 30), Color3.fromRGB(36, 17, 56), Color3.fromRGB(155, 31, 232)
local MAGENTA, CYAN, LAV = Color3.fromRGB(255, 0, 127), Color3.fromRGB(0, 240, 255), Color3.fromRGB(196, 170, 255)
local WOOD, CREAM, AMBER = Color3.fromRGB(92, 58, 44), Color3.fromRGB(240, 222, 214), Color3.fromRGB(255, 176, 72)

-- which props each cave theme gets, as weights
local MIX = {
	grotto = { crystal = 5, pebbles = 3, rubble = 2, roots = 1 },
	mush = { mushrooms = 6, pebbles = 2, roots = 2 },
	tunnel = { support = 4, rubble = 3, cart = 1, crystal = 1 },
	squeeze = { rubble = 3, roots = 3, crystal = 2, pebbles = 1 },
	chasm = { crystal = 4, roots = 2, rubble = 1 },
}
M.MIX = MIX
M.CHANCE = 0.85 -- of a floor slab getting a prop (when it has a wall near one edge)
M.KEEP_OUT = 11 -- studs from deposits, shrines, nests, gates and the camp
M.MAX_LIGHTS = 24
-- low-poly meshes (design3d/cave_props.py, ids in design3d/out/props/ids.txt; Gemini n17_r1: the block-built props read as
-- crude voxel steps). Loaded once from the owner's uploads; if a load fails, that prop falls back to the part-built version.
M.MESH = { crystal = { 104563237686070, 101580352907109, 80182315006407 }, mushrooms = { 74992751047015, 139797019027904 }, rubble = { 118720837194462, 115340167637774 } }
M.HEIGHT = { crystal = 8.5, mushrooms = 6.2, rubble = 2.8 } -- studs tall once placed (the cave's 4-stud cells)
M.SCALE = { crystal = 1.9, mushrooms = 1.8, rubble = 1.7, pebbles = 1.4 } -- roots, supports and carts are built to the room's own size

function M.pick(mix, r) -- weighted pick, r in [0, 1)
	local total = 0
	for _, w in mix do total += w end
	local names = {}
	for n in mix do table.insert(names, n) end
	table.sort(names) -- pairs order is not fixed: sort so a seed always gives the same pick
	local x = r * total
	for _, n in names do
		x -= mix[n]
		if x < 0 then return n end
	end
	return names[#names]
end

function M.build(caves)
	local folder = Instance.new("Folder")
	folder.Name = "Props"
	local rng = Random.new(20261116)
	local lights = 0
	local function part(parent, size, cf, color, mat, props)
		local p = Instance.new("Part")
		p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.Size, p.CFrame, p.Color, p.Material = size, cf, color, mat or Enum.Material.SmoothPlastic
		for k, v in props or {} do p[k] = v end
		p.Parent = parent
		return p
	end
	local function light(p, color, range, b)
		if lights >= M.MAX_LIGHTS then return end
		lights += 1
		local l = Instance.new("PointLight")
		l.Color, l.Range, l.Brightness, l.Shadows = color, range, b, false
		l.Parent = p
	end

	-- the builders: each takes a model, the base CFrame (on the floor, facing out of the wall) and the rng
	local B = {}
	function B.crystal(m, base)
		local col = rng:NextNumber() < 0.75 and CYAN or LAV
		local n = rng:NextInteger(3, 5)
		for i = 1, n do
			local h = (i == 1 and 4.5 or 1.6 + rng:NextNumber() * 2.4) * (0.8 + rng:NextNumber() * 0.4)
			local w = h * 0.26
			local off = i == 1 and Vector3.zero or Vector3.new(rng:NextNumber(-1.4, 1.4), 0, rng:NextNumber(-1.2, 0.6))
			local tilt = i == 1 and CFrame.Angles(math.rad(rng:NextNumber(-8, 8)), 0, math.rad(rng:NextNumber(-10, 10))) or CFrame.Angles(math.rad(rng:NextNumber(-30, 30)), rng:NextNumber(0, 6), math.rad(rng:NextNumber(-34, 34)))
			local cf = base * CFrame.new(off) * tilt * CFrame.new(0, h / 2 - 0.3, 0)
			part(m, Vector3.new(w, h, w), cf * CFrame.Angles(0, math.rad(45), 0), col:Lerp(OBSIDIAN, 0.35), Enum.Material.Glass, { Transparency = 0.2, Reflectance = 0.15 }) -- a deep tinted shell: pale glass read as milky ice under the Realistic light
			part(m, Vector3.new(w * 0.62, h * 0.86, w * 0.62), cf * CFrame.new(0, -h * 0.04, 0), col, Enum.Material.Neon) -- the light inside
			part(m, Vector3.new(w * 0.72, w * 0.72, w * 0.72), cf * CFrame.new(0, h / 2, 0) * CFrame.Angles(math.rad(45), 0, math.rad(45)), col:Lerp(Color3.new(1, 1, 1), 0.3), Enum.Material.Glass, { Transparency = 0.3 }) -- the pointed tip
		end
		part(m, Vector3.new(2.6, 0.5, 2.2), base * CFrame.new(0, 0.05, -0.2) * CFrame.Angles(0, rng:NextNumber(0, 3), 0), PLUM, Enum.Material.Slate) -- the rock it grows from
		light(m:GetChildren()[2], col, 14, 0.9)
	end
	function B.mushrooms(m, base)
		for i = 1, rng:NextInteger(2, 4) do
			local s = i == 1 and 1.6 or 0.6 + rng:NextNumber() * 0.7
			local at = base * CFrame.new(i == 1 and 0 or rng:NextNumber(-1.8, 1.8), 0, i == 1 and 0 or rng:NextNumber(-1.2, 1)) * CFrame.Angles(0, rng:NextNumber(0, 6), math.rad(rng:NextNumber(-8, 8)))
			local stem = 2.2 * s
			part(m, Vector3.new(0.5 * s, stem, 0.5 * s), at * CFrame.new(0, stem / 2 - 0.2, 0), CREAM, Enum.Material.SmoothPlastic)
			local capCol = rng:NextNumber() < 0.8 and MAGENTA or VIOLET
			local cap = part(m, Vector3.new(2.2 * s, 0.7 * s, 2.2 * s), at * CFrame.new(0, stem - 0.1, 0), capCol, Enum.Material.SmoothPlastic)
			part(m, Vector3.new(1.4 * s, 0.6 * s, 1.4 * s), at * CFrame.new(0, stem + 0.35 * s, 0) * CFrame.Angles(0, math.rad(45), 0), capCol:Lerp(Color3.new(1, 1, 1), 0.15), Enum.Material.SmoothPlastic)
			part(m, Vector3.new(1.9 * s, 0.12, 1.9 * s), at * CFrame.new(0, stem - 0.5 * s, 0), capCol, Enum.Material.Neon, { Transparency = 0.25 }) -- the glowing gills under the cap
			for _ = 1, 3 do -- pale spots on the cap
				local a = rng:NextNumber(0, 6.28)
				part(m, Vector3.new(0.3, 0.3, 0.3) * s, at * CFrame.new(math.cos(a) * 0.7 * s, stem + 0.25 * s, math.sin(a) * 0.7 * s), CREAM, Enum.Material.Neon)
			end
			if i == 1 then light(cap, MAGENTA, 12, 0.8) end
		end
	end
	function B.support(m, base) -- two posts and a beam against the wall, a lantern hanging from the beam
		local w = rng:NextNumber(5, 7)
		for _, x in { -w / 2, w / 2 } do
			part(m, Vector3.new(0.9, 9, 0.9), base * CFrame.new(x, 4.3, 0.2), WOOD, Enum.Material.WoodPlanks, { CanCollide = true })
		end
		part(m, Vector3.new(w + 1.4, 0.9, 1.1), base * CFrame.new(0, 8.6, 0.2) * CFrame.Angles(0, 0, math.rad(rng:NextNumber(-3, 3))), WOOD:Lerp(OBSIDIAN, 0.15), Enum.Material.WoodPlanks)
		local hang = base * CFrame.new(rng:NextNumber(-1, 1), 6.6, -0.6)
		part(m, Vector3.new(0.08, 1.6, 0.08), hang * CFrame.new(0, 1.1, 0), Color3.fromRGB(60, 50, 70), Enum.Material.Metal)
		part(m, Vector3.new(0.75, 0.15, 0.75), hang * CFrame.new(0, 0.42, 0), Color3.fromRGB(70, 50, 40), Enum.Material.Metal)
		part(m, Vector3.new(0.75, 0.15, 0.75), hang * CFrame.new(0, -0.42, 0), Color3.fromRGB(70, 50, 40), Enum.Material.Metal)
		local core = part(m, Vector3.new(0.5, 0.7, 0.5), hang, AMBER, Enum.Material.Neon)
		light(core, AMBER, 13, 0.5)
	end
	function B.rubble(m, base)
		for _ = 1, rng:NextInteger(5, 8) do
			local s = rng:NextNumber(0.6, 1.5)
			part(m, Vector3.new(s, s * 0.8, s), base * CFrame.new(rng:NextNumber(-1.6, 1.6), s * 0.25, rng:NextNumber(-1.2, 0.8)) * CFrame.Angles(rng:NextNumber(0, 1), rng:NextNumber(0, 6), rng:NextNumber(0, 1)), PLUM:Lerp(VIOLET, rng:NextNumber(0, 0.25)), Enum.Material.Slate)
		end
		for _ = 1, rng:NextInteger(1, 3) do -- a few gems caught in it
			local g = rng:NextNumber() < 0.5 and CYAN or MAGENTA
			part(m, Vector3.new(0.35, 0.35, 0.35), base * CFrame.new(rng:NextNumber(-1.4, 1.4), 0.55, rng:NextNumber(-1, 0.6)) * CFrame.Angles(math.rad(45), rng:NextNumber(0, 6), math.rad(45)), g, Enum.Material.Neon)
		end
	end
	function B.pebbles(m, base) -- glowing pebbles scattered on the floor, the reference's little cyan and amber dots
		for _ = 1, rng:NextInteger(5, 9) do
			local g = rng:NextNumber() < 0.7 and CYAN or AMBER
			local s = rng:NextNumber(0.22, 0.45)
			part(m, Vector3.new(s, s, s), base * CFrame.new(rng:NextNumber(-3, 3), 0.02, rng:NextNumber(-3, 1.5)) * CFrame.Angles(rng:NextNumber(0, 1), rng:NextNumber(0, 6), 0), g, Enum.Material.Neon, { Transparency = 0.1 })
		end
	end
	function B.cart(m, base) -- an old cart on a short rail stub, tipped a little
		local r = base * CFrame.Angles(0, math.rad(90 + rng:NextNumber(-12, 12)), 0)
		for _, x in { -1.1, 1.1 } do part(m, Vector3.new(0.25, 0.25, 8), r * CFrame.new(x, 0.05, 0), Color3.fromRGB(80, 70, 90), Enum.Material.Metal) end
		for z = -3.5, 3.5, 1.4 do part(m, Vector3.new(3.2, 0.25, 0.5), r * CFrame.new(0, -0.08, z), WOOD, Enum.Material.WoodPlanks) end
		local body = r * CFrame.new(0, 1.35, rng:NextNumber(-1.5, 1.5)) * CFrame.Angles(0, 0, math.rad(rng:NextNumber(-5, 5)))
		part(m, Vector3.new(2.8, 1.6, 3.6), body, WOOD:Lerp(PLUM, 0.2), Enum.Material.WoodPlanks)
		part(m, Vector3.new(2.4, 0.4, 3.2), body * CFrame.new(0, 0.7, 0), Color3.fromRGB(60, 40, 80), Enum.Material.Slate) -- rock heaped inside
		part(m, Vector3.new(0.5, 0.5, 0.5), body * CFrame.new(0.5, 1.0, 0.4) * CFrame.Angles(math.rad(45), 0, math.rad(45)), CYAN, Enum.Material.Neon)
		for _, x in { -1.3, 1.3 } do
			for _, z in { -1.2, 1.2 } do
				part(m, Vector3.new(0.3, 0.9, 0.9), body * CFrame.new(x, -0.8, z), Color3.fromRGB(70, 60, 80), Enum.Material.Metal, { Shape = Enum.PartType.Cylinder })
			end
		end
	end
	function B.roots(m, base, ceilY) -- roots of the World Tree hang from the ceiling, each with a glowing bulb
		if not ceilY then return B.rubble(m, base) end
		local top = ceilY + 0.5
		for i = 1, rng:NextInteger(2, 4) do
			local x, z = rng:NextNumber(-2, 2), rng:NextNumber(-1.5, 1)
			local len = math.min(top - base.Position.Y - 3, rng:NextNumber(4, 9))
			if len < 2 then break end
			local p0 = base * CFrame.new(x, 0, z)
			local y0 = top - base.Position.Y
			local segs = 3
			for k = 1, segs do -- a root in three kinked pieces
				local a, b = y0 - len * (k - 1) / segs, y0 - len * k / segs
				local dx = math.sin(k * 1.7 + i) * 0.25
				part(m, Vector3.new(0.35 - k * 0.06, (a - b) + 0.2, 0.35 - k * 0.06), p0 * CFrame.new(dx, (a + b) / 2, 0) * CFrame.Angles(0, 0, math.rad(dx * 30)), Color3.fromRGB(70, 46, 60), Enum.Material.Wood)
			end
			local bulb = part(m, Vector3.new(0.55, 0.7, 0.55), p0 * CFrame.new(math.sin(segs * 1.7 + i) * 0.25, y0 - len - 0.3, 0), CYAN, Enum.Material.Neon)
			if i == 1 then light(bulb, CYAN, 10, 0.5) end
		end
	end
	M.B = B

	-- the mesh templates, loaded once
	local templates = {}
	for kind, ids in M.MESH do
		for _, id in ids do
			local ok, raw = pcall(function() return game:GetService("InsertService"):LoadAsset(id) end)
			if ok and raw then
				local m = Instance.new("Model")
				for _, d in raw:GetDescendants() do
					if d:IsA("MeshPart") then
						d.Anchored, d.CanCollide, d.CanQuery, d.CanTouch, d.CastShadow = true, false, false, false, false
						local sa = d:FindFirstChildOfClass("SurfaceAppearance") if sa then sa:Destroy() end
						d.TextureID = ""
						d.Parent = m
					end
				end
				raw:Destroy()
				if #m:GetChildren() > 0 then
					templates[kind] = templates[kind] or {}
					table.insert(templates[kind], m)
				end
			end
		end
	end
	local LOOK = { -- each mesh part's look by its name (the roles in design3d/cave_props.py)
		Shell = function(p, c) p.Material, p.Color, p.Transparency, p.Reflectance = Enum.Material.Glass, c:Lerp(OBSIDIAN, 0.12), 0.3, 0.15 end,
		Core = function(p, c) p.Material, p.Color = Enum.Material.Neon, c end, -- full neon (at 0.25 see-through the crystals went dull teal)
		Rock = function(p) p.Material, p.Color = Enum.Material.Slate, PLUM:Lerp(VIOLET, 0.12) end,
		Cap = function(p, c) p.Material, p.Color = Enum.Material.SmoothPlastic, c end,
		Gill = function(p, c) p.Material, p.Color = Enum.Material.Neon, c:Lerp(Color3.new(1, 1, 1), 0.2) end,
		Stem = function(p) p.Material, p.Color = Enum.Material.SmoothPlastic, CREAM end,
		Spot = function(p) p.Material, p.Color = Enum.Material.Neon, CREAM end,
		Gem = function(p, c) p.Material, p.Color = Enum.Material.Neon, c end,
	}
	local function fromMesh(kind, m, base)
		local list = templates[kind]
		if not list then return false end
		local t = list[rng:NextInteger(1, #list)]:Clone()
		local col = kind == "crystal" and (rng:NextNumber() < 0.75 and CYAN or LAV) or kind == "mushrooms" and (rng:NextNumber() < 0.8 and MAGENTA or VIOLET) or (rng:NextNumber() < 0.5 and CYAN or MAGENTA)
		for _, p in t:GetChildren() do
			local f = LOOK[p.Name]
			if f then f(p, col) end
			p.Parent = m
		end
		t:Destroy()
		local cf, size = m:GetBoundingBox()
		m.WorldPivot = cf * CFrame.new(0, -size.Y / 2, 0) -- the foot
		local k = M.HEIGHT[kind] * (0.8 + rng:NextNumber() * 0.4) / size.Y
		m:ScaleTo(k)
		m:PivotTo(base * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0) * CFrame.new(0, -0.25, 0)) -- sunk a little into the floor
		if kind ~= "rubble" then -- a soft pool of its light on the floor round its foot (the reference's glowing ground)
			local r = M.HEIGHT[kind] * 0.9
			part(m, Vector3.new(0.12, r, r), base * CFrame.new(0, 0.04, 0) * CFrame.Angles(0, 0, math.pi / 2), col, Enum.Material.Neon, { Shape = Enum.PartType.Cylinder, Transparency = 0.82 })
		end
		local lit = m:FindFirstChild("Core") or m:FindFirstChild("Gill") or m:FindFirstChild("Gem")
		if lit then light(lit, col, kind == "rubble" and 8 or 14, kind == "rubble" and 0.35 or 0.55) end
		return true
	end

	-- where props may not go
	local keep = {}
	for _, name in { "Deposits", "Shrines", "Nests", "Gate", "Camp", "Altar", "Ziplines", "Clay" } do
		local f = caves:FindFirstChild(name)
		if f then
			for _, d in f:GetDescendants() do
				if d:IsA("BasePart") and (d.Parent == f or d.Parent.Parent == f) then table.insert(keep, d.Position) end
			end
		end
	end
	local landing = caves:FindFirstChild("LiftLanding", true)
	if landing then table.insert(keep, landing.Position) end
	local lanes = {} -- Cave v2: the narrow passages' middle lines (Spot markers in order), a prop never stands within 3.5 studs of them
	for _, v in caves:GetChildren() do
		if v:IsA("ObjectValue") and string.sub(v.Name, 1, 5) == "Spot_" and v.Value then table.insert(lanes, v.Value.WorldPosition) end
	end
	local function clear(pos)
		for _, k in keep do
			if (k - pos).Magnitude < M.KEEP_OUT then return false end
		end
		return true
	end
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Include
	rp.FilterDescendantsInstances = { caves:FindFirstChild("Walls"), caves:FindFirstChild("Floor"), caves:FindFirstChild("Ceiling") }
	local floor = caves:FindFirstChild("Floor")
	local placed = {}
	local count = 0
	for _, f in floor and floor:GetChildren() or {} do
		local mix = MIX[f:GetAttribute("Theme") or ""]
		local layer = caves:GetAttribute("Layer") or 1
		if mix and layer >= 3 then -- deeper layers have no World Tree roots and no timber: crystals, rubble and pebbles only (Cave v2, 2026-11-19)
			mix = { crystal = 5, rubble = 3, pebbles = 2 }
		end
		if mix and f:IsA("BasePart") and rng:NextNumber() < M.CHANCE then
			local topY = f.Position.Y + f.Size.Y / 2
			local spot = Vector3.new(f.Position.X + rng:NextNumber(-0.35, 0.35) * f.Size.X, topY, f.Position.Z + rng:NextNumber(-0.35, 0.35) * f.Size.Z)
			local down = workspace:Raycast(spot + Vector3.new(0, 6, 0), Vector3.new(0, -9, 0), rp)
			if down and down.Instance.Parent == floor and down.Normal.Y > 0.9 then
				spot = down.Position
				local wallDir, wallDist
				for a = 0, 315, 45 do -- the nearest wall at knee height
					local d = Vector3.new(math.cos(math.rad(a)), 0, math.sin(math.rad(a)))
					local hit = workspace:Raycast(spot + Vector3.new(0, 2, 0), d * 7, rp)
					if hit and (not wallDist or hit.Distance < wallDist) then wallDir, wallDist = d, hit.Distance end
				end
				local near = false
				for _, q in placed do if (q - spot).Magnitude < 7 then near = true break end end -- 7 studs apart (Gemini n17_r4: the floor round each prop still bare)
				local roomy = wallDist and wallDist > 1.2 -- a prop needs space between the wall and the walking lane, or it lands in the lane
				for _, q in lanes do if (q - spot).Magnitude < 3.5 then roomy = false break end end
				if wallDir and not near and roomy and clear(spot) then
					local kind = M.pick(mix, rng:NextNumber())
					local at = spot + wallDir * math.max(wallDist - 1.6, 0) -- against the wall, not in the passage (Gemini: 3.5-stud lane clearance)
					local base = CFrame.lookAt(at, at - wallDir) * CFrame.new(0, -0.15, 0) -- facing out of the wall; sunk into the floor
					local ceil = workspace:Raycast(at + Vector3.new(0, 1, 0), Vector3.new(0, 40, 0), rp)
					local m = Instance.new("Model")
					m.Name = "Prop_" .. kind
					m.Parent = folder
					local meshed = fromMesh(kind, m, base)
					if meshed and (kind == "rubble" or kind == "crystal") then B.pebbles(m, base) end -- loose glowing grit round the foot (Gemini n17_r3: lone props on bare floor)
					if meshed and kind == "mushrooms" and templates.mushrooms then -- two little ones beside the big one
						for _ = 1, 2 do
							local side = base * CFrame.new((rng:NextNumber() < 0.5 and -1 or 1) * rng:NextNumber(3.2, 4.6), 0, rng:NextNumber(-1.5, 1.5)) -- clear of the big one's stem
							local sm = Instance.new("Model")
							sm.Parent = m
							if fromMesh("mushrooms", sm, side) then sm:ScaleTo(sm:GetScale() * 0.45) end
						end
					end
					if not meshed then B[kind](m, base, ceil and ceil.Position.Y or nil) end
					if not meshed and M.SCALE[kind] then -- built at person size, then grown to the cave's chunky scale (4-stud cells): at 1x they read as crumbs
						m.WorldPivot = base
						m:ScaleTo(M.SCALE[kind])
					end
					table.insert(placed, spot)
					count += 1
				end
			end
		end
	end
	folder.Parent = caves
	folder:SetAttribute("Count", count)
	return folder
end

do -- self-check: the weighted pick is stable and covers every name
	assert(M.pick({ a = 1, b = 1 }, 0.1) == "a" and M.pick({ a = 1, b = 1 }, 0.9) == "b", "CaveProps: pick")
	for theme, mix in M.MIX do assert(M.pick(mix, 0.999), theme) end
end
return M
