-- Glossify (ServerScriptService.Glossify): the glass and reflections pass for the 3D world (the user, 2026-11-09: "glass and reflections
-- ... applied in all parts of the game ... terrain, items, vfx, UI, HUD, blocks, ores"; board GlassPass, vault Research/3D and Art/
-- Glass and Reflections). Everything runs on the server at start and replicates:
--  * lighting: the realistic style with shadows and full environment reflections (the soft style had no specular to show)
--  * the hub: every pixel Texture becomes a MaterialVariant (the texture as its colour map plus a roughness map), so the textured
--    surfaces themselves shine: wet cobbles and lanes, polished stone and roofs, satin wood; windows turn to real glass
--  * plain parts get a polished gloss; neon, glass and see-through parts are left alone
--  * caves: the cave rock variant gets a wet roughness map (glossy puddles and drips that catch the torch)
--  * ores, eggs and the altar eggs: a glass shell around a glowing core
local MaterialService = game:GetService("MaterialService")
local Lighting = game:GetService("Lighting")

local M = {}
local ID = { -- art/glass/tex/asset_ids.json
	white = "rbxassetid://129653169462240", black = "rbxassetid://87848805123183", flat = "rbxassetid://99622743501122",
	glass = "rbxassetid://123712911660861", low = "rbxassetid://71146495128257", mid = "rbxassetid://139294868335982",
	soft = "rbxassetid://74913937734915", wetrock = "rbxassetid://138624115205209",
}
-- roughness class per hub texture (HubBuilder TEX): wet stone floors shine most, roofs and walls are polished, wood satin, plants soft
local CLASS = {
	cobble = "low", cobble_soft = "low", cobble_lane = "low", flagstone = "low", path = "low", iron = "low",
	stonebrick = "mid", rockface = "mid", shingle_teal = "mid", shingle_plum = "mid", moss_roof = "mid", plaster = "mid",
	planks = "mid", planks_light = "mid", logs = "mid", beam = "mid", bark = "mid", wood_frame = "mid",
	awning = "soft", leaves = "soft", grass = "soft",
}
M.ID = ID

-- the variants are made in Edit mode (spike/make_variants.luau): game scripts may not write MaterialVariant maps (Plugin capability)
local function variant(name)
	return MaterialService:FindFirstChild(name)
end

function M.lighting(cave)
	if not cave then -- a real night in town: dim moonlight and indigo shade, so the lantern pools carry the scene
		Lighting.OutdoorAmbient, Lighting.Ambient = Color3.fromRGB(40, 36, 78), Color3.fromRGB(26, 22, 48)
		Lighting.Brightness, Lighting.ExposureCompensation = 0.4, -0.25 -- tuned under the Realistic style (set in Edit mode; Soft flattened the night to daylight)
	end -- a deeper night in town, so the lantern pools carry the scene (was 80, 74, 136)
	for k, v in {
		LightingStyle = Enum.LightingStyle.Realistic, GlobalShadows = true, ShadowSoftness = 0.25,
		EnvironmentSpecularScale = cave and 0.85 or 1, EnvironmentDiffuseScale = cave and 0.35 or 0.18,
	} do
		pcall(function() Lighting[k] = v end)
	end
end

local function plainGloss(p, class)
	local name = "PD_Gloss_" .. class
	if not variant(name) then return end
	p.Material, p.MaterialVariant = Enum.Material.SmoothPlastic, name
end

-- wet glints (audit 11; the Minecraft shader packs' screen-space reflections stand-in): under every lantern a soft streak of
-- its light lies on the damp ground. Thin layers 0.04 studs apart, so nothing is coplanar with the ground or each other.
-- round: a pool (first-person caves) instead of a streak stretched toward the town's south camera
local function wetGlints(root, round)
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	for _, p in root:GetDescendants() do
		if p:IsA("BasePart") and p.Name == "Lantern" then
			rp.FilterDescendantsInstances = {}
			local hit = workspace:Raycast(p.Position + Vector3.new(0, 0, 1.6), Vector3.new(0, -16, 0), rp) -- beside the post, on the camera side
			if hit and hit.Normal.Y > 0.95 and hit.Instance.Transparency < 0.5 then
				for k, sz in { Vector3.new(2.63, 0.04, 5.37), Vector3.new(1.33, 0.04, 3.17), Vector3.new(0.33, 0.04, 1.77) } do -- three feathered layers, no hard edge
					local g = Instance.new("Part")
					g.Name, g.Size, g.Material, g.Color = "WetGlint", round and Vector3.new(sz.Z, 0.04, sz.Z) or sz, Enum.Material.Neon, p.Color:Lerp(Color3.new(1, 1, 1), 0.25 * k)
					g.Transparency = k == 3 and 0.8 or 0.985 - k * 0.025 -- two faint feathers and a narrow core: a streak of light, not a painted oval
					g.CFrame = CFrame.new(hit.Position + Vector3.new(0.013, 0.05 + 0.04 * k, round and 0 or 0.4))
					g.Anchored, g.CanCollide, g.CanQuery, g.CanTouch, g.CastShadow = true, false, false, false, false
					local oval = Instance.new("SpecialMesh") -- a soft oval, not a hard rectangle
					oval.MeshType = Enum.MeshType.Sphere
					oval.Parent = g
					g.Parent = p.Parent
				end
			end
		end
	end
end

-- the hub: textures to variants
function M.hub(hub)
	local made, glassed = 0, 0
	for _, p in hub:GetDescendants() do
		if p:IsA("BasePart") and p.Transparency < 0.5 and p.Material ~= Enum.Material.Neon and p.Material ~= Enum.Material.Glass then
			local tex
			for _, t in p:GetChildren() do
				if t:IsA("Texture") and CLASS[t.Name] ~= nil or (t:IsA("Texture") and t.Name == "glass") then tex = t break end
			end
			if tex and tex.Name == "glass" then -- windows become real glass with a warm interior glow behind them
				for _, t in p:GetChildren() do if t:IsA("Texture") then t:Destroy() end end
				p.Material, p.Transparency, p.Reflectance = Enum.Material.Glass, 0.35, 0.32
				glassed += 1
			elseif tex then
				local studs = math.floor(tex.StudsPerTileU * 10 + 0.5) / 10
				local name = "PD_" .. tex.Name .. "_" .. studs
				if not variant(name) then continue end -- not made yet (run spike/make_variants.luau): keep the texture
				local tint = tex.Color3
				for _, t in p:GetChildren() do if t:IsA("Texture") and t.Name == tex.Name then t:Destroy() end end
				p.Material, p.MaterialVariant, p.Color = Enum.Material.SmoothPlastic, name, tint
				if CLASS[tex.Name] == "low" then p.Reflectance = 0.3 end -- damp stone picks up the night sky
				made += 1
			elseif p.Material == Enum.Material.SmoothPlastic or p.Material == Enum.Material.Plastic then
				local n = p.Name
				local soft = n:find("Leaf") or n:find("Bush") or n:find("Tuft") or n:find("Grass") or n:find("Flower") or n:find("Petal") or n:find("Moss")
				plainGloss(p, soft and "soft" or "mid")
			end
		end
	end
	wetGlints(hub)
	return made, glassed
end

-- glass shell around a glowing core (ores, eggs)
local function shell(core, color, grow, transparency)
	local s = core:Clone()
	for _, c in s:GetChildren() do c:Destroy() end
	s.Name = "GlassShell"
	s.Material, s.Transparency, s.Reflectance = Enum.Material.Glass, transparency or 0.4, 0.4
	s.Color = color
	s.Size = core.Size * (grow or 1.22)
	s.CanCollide, s.CanQuery, s.CanTouch, s.CastShadow = false, false, false, false
	s.Parent = core.Parent
	return s
end

function M.caves(caves)
	-- the cave rock's wet roughness map is set in Edit mode with the variants (spike/make_variants.luau)
	local ores, eggs = 0, 0
	local deps = caves:FindFirstChild("Deposits")
	for _, dep in deps and deps:GetChildren() or {} do
		local core = dep:FindFirstChild("Core")
		if core then
			ores += 1
			if dep:GetAttribute("OreName") == "Ashcoal" then -- audit: a dark core in a dark shell was invisible. A warmer plum heart, a lilac
				-- light and two ember flecks: coal that still smoulders reads at once and stays the darkest ore
				core.Color = core.Color:Lerp(Color3.fromHex("5a4d66"), 1):Lerp(Color3.fromRGB(196, 176, 240), 0.3)
				local l = core:FindFirstChildOfClass("PointLight")
				if l then l.Color = Color3.fromRGB(186, 160, 235) end
				for k, o in { Vector3.new(0.34, 0.5, -0.5), Vector3.new(-0.3, -0.2, -0.52) } do
					local e = Instance.new("Part")
					e.Name, e.Size, e.Material, e.Color = "Ember", Vector3.one * (0.26 - k * 0.04), Enum.Material.Neon, Color3.fromRGB(255, 150, 70)
					e.CFrame = core.CFrame * CFrame.new(o)
					e.Anchored, e.CanCollide, e.CanQuery, e.CanTouch, e.CastShadow = true, false, false, false, false
					e.Parent = dep
				end
			end
			local col = core.Color
			core.Size *= 0.72 -- the neon heart sits inside a faceted glass shell
			shell(core, col:Lerp(Color3.new(1, 1, 1), 0.35), 1.55, 0.45)
			for _, p in dep:GetChildren() do
				if p:IsA("BasePart") and p.Name == "Shard" and p.Size.Y > p.Size.X * 1.2 then -- the leaning crystals turn to glass
					p.Material, p.Transparency, p.Reflectance = Enum.Material.Glass, 0.22, 0.35
					p.Color = p.Color:Lerp(Color3.new(1, 1, 1), 0.2)
				end
			end
		end
	end
	for _, e in caves:GetDescendants() do -- eggs (nests and the altar): a glass egg around a small glowing core
		if e:IsA("BasePart") and (e.Name == "NestEgg" or e.Name:match("^AltarEgg%d$")) and not e:FindFirstChild("EggCore") then
			eggs += 1
			local core = Instance.new("Part")
			core.Name, core.Shape, core.Material = "EggCore", Enum.PartType.Ball, Enum.Material.Neon
			core.Size, core.CFrame, core.Color = Vector3.one * math.min(e.Size.X, e.Size.Z) * 0.5, e.CFrame, e.Color
			core.Anchored, core.CanCollide, core.CanQuery, core.CanTouch, core.CastShadow = true, false, false, false, false
			core.Parent = e
			e.Material, e.Transparency, e.Reflectance = Enum.Material.Glass, 0.3, 0.2
			e.Color = e.Color:Lerp(Color3.new(1, 1, 1), 0.35)
		end
	end
	-- the rest of the caves (camp props, station, beams, tents): a polished gloss where they are plain plastic
	for _, p in caves:GetDescendants() do
		if p:IsA("BasePart") and p.Transparency < 0.5 and (p.Material == Enum.Material.SmoothPlastic or p.Material == Enum.Material.Plastic) and p.MaterialVariant == "" and p.Name ~= "GlassShell" then
			plainGloss(p, "mid")
		end
	end
	wetGlints(caves, true)
	return ores, eggs
end

return M
