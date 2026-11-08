-- ServerScriptService.CampBuilder: the night mining camp on each side of a player's shaft (key art scene_night.png, Claude Design board).
-- Scale: the miner is about 5 studs tall, so doors are 7, huts 10 to 12, the lift 18 and the world tree 60.
-- Everything stands behind the walking plane (front faces at z = -3) so it never blocks digging or walking.
local Camp = {}

local WOOD, WOOD_DK, STONE, ROOF = Color3.fromRGB(150, 98, 72), Color3.fromRGB(96, 62, 58), Color3.fromRGB(122, 112, 150), Color3.fromRGB(150, 70, 96)
local CREAM, PINK, LILAC, MINT, GOLD = Color3.fromRGB(255, 236, 214), Color3.fromRGB(245, 150, 190), Color3.fromRGB(170, 140, 220), Color3.fromRGB(140, 226, 196), Color3.fromRGB(255, 206, 70)
local LAMP = Color3.fromRGB(255, 196, 130)

local function part(parent, name, size, cf, color, mat, props)
	local p = Instance.new("Part")
	p.Name, p.Size, p.CFrame, p.Color = name, size, cf, color
	p.Material = mat or Enum.Material.SmoothPlastic
	p.Anchored, p.TopSurface, p.BottomSurface = true, Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.CanCollide = false
	for k, v in props or {} do p[k] = v end
	p.Parent = parent
	return p
end

local function wedgeRoof(parent, w, d, h, cf, color) -- two wedges meeting at the ridge (ridge runs along x)
	for _, s in { -1, 1 } do
		local wd = Instance.new("WedgePart")
		wd.Name, wd.Anchored, wd.CanCollide, wd.Color, wd.Material = "Roof", true, false, color, Enum.Material.SmoothPlastic
		wd.Size = Vector3.new(w, h, d / 2)
		wd.CFrame = cf * CFrame.new(0, 0, s * d / 4) * CFrame.Angles(0, s == 1 and 0 or math.pi, 0)
		wd.Parent = parent
	end
end

local function light(p, color, range, brightness, shadows)
	local l = Instance.new("PointLight")
	l.Color, l.Range, l.Brightness, l.Shadows = color, range, brightness, shadows or false
	l.Parent = p
	return l
end

local function sign(parent, text, cf, w, h, bg, fg)
	local board = part(parent, "Sign", Vector3.new(w, h, 0.3), cf, bg or WOOD_DK, Enum.Material.Wood)
	local g = Instance.new("SurfaceGui")
	g.Face, g.SizingMode, g.PixelsPerStud, g.LightInfluence = Enum.NormalId.Back, Enum.SurfaceGuiSizingMode.PixelsPerStud, 40, 0
	local t = Instance.new("TextLabel")
	t.Size, t.BackgroundTransparency, t.Text, t.TextScaled = UDim2.fromScale(1, 1), 1, text, true
	t.Font, t.TextColor3, t.TextStrokeTransparency, t.TextStrokeColor3 = Enum.Font.Arcade, fg or CREAM, 0, Color3.fromRGB(11, 14, 31)
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft, pad.PaddingRight, pad.PaddingTop, pad.PaddingBottom = UDim.new(0.08, 0), UDim.new(0.08, 0), UDim.new(0.15, 0), UDim.new(0.15, 0)
	pad.Parent = t
	t.Parent = g
	g.Parent = board
	return board
end

local function lamp(parent, pos)
	part(parent, "LampPost", Vector3.new(0.5, 7, 0.5), CFrame.new(pos + Vector3.new(0, 3.5, 0)), WOOD_DK, Enum.Material.Wood)
	part(parent, "LampArm", Vector3.new(1.6, 0.3, 0.3), CFrame.new(pos + Vector3.new(0.6, 6.8, 0)), WOOD_DK, Enum.Material.Wood)
	local bulb = part(parent, "Lantern", Vector3.new(0.9, 1.1, 0.9), CFrame.new(pos + Vector3.new(1.2, 6.1, 0)), LAMP, Enum.Material.Neon)
	light(bulb, LAMP, 18, 1.4, true)
end

local function prompt(p, action, object)
	local pr = Instance.new("ProximityPrompt")
	pr.ActionText, pr.ObjectText, pr.KeyboardKeyCode = action, object, Enum.KeyCode.F
	pr.MaxActivationDistance, pr.RequiresLineOfSight, pr.HoldDuration = 14, false, 0
	pr.Parent = p
	return pr
end

-- opts: x0 (shaft left edge), width (shaft width in studs), G (ground top y), sideW (camp width per side), owner, on = {sell, forge, hatch, map}
function Camp.build(folder, opts)
	local x0, xR, G, Z = opts.x0, opts.x0 + opts.width, opts.G, -3
	local camp = Instance.new("Model")
	camp.Name = "Camp"
	local function at(x, y, z) return CFrame.new(x, G + y, z) end
	local function hook(pr, key)
		pr.Triggered:Connect(function(plr)
			if plr == opts.owner and opts.on[key] then opts.on[key](plr) end
		end)
	end

	-- ground dressing: stone path slabs, flowers, tufts, rocks (left and right of the shaft)
	local rng = Random.new(opts.seed or 7)
	for side = -1, 1, 2 do
		local edge = side < 0 and x0 or xR
		for i = 0, math.floor(opts.sideW / 3) - 1 do
			local x = edge + side * (2 + i * 3)
			part(camp, "Path", Vector3.new(2.6, 0.25, 2.2), at(x, 0.1, 0.2) * CFrame.Angles(0, rng:NextNumber(-0.2, 0.2), 0), Color3.fromRGB(150, 140, 170), Enum.Material.Slate)
			if rng:NextNumber() < 0.6 then
				local fc = ({ PINK, GOLD, LILAC, CREAM })[rng:NextInteger(1, 4)]
				local fx = x + rng:NextNumber(-1.2, 1.2)
				part(camp, "Stem", Vector3.new(0.12, 0.7, 0.12), at(fx, 0.35, Z + 1.2), Color3.fromRGB(90, 170, 120))
				part(camp, "Flower", Vector3.new(0.45, 0.45, 0.45), at(fx, 0.8, Z + 1.2), fc, Enum.Material.Neon, { Shape = Enum.PartType.Ball })
			end
			if rng:NextNumber() < 0.35 then
				part(camp, "Rock", Vector3.new(rng:NextNumber(0.8, 1.6), rng:NextNumber(0.5, 1), rng:NextNumber(0.8, 1.4)), at(x + 1, 0.3, Z + 1.6) * CFrame.Angles(0, rng:NextNumber(0, 3), 0), Color3.fromRGB(110, 100, 140), Enum.Material.Slate)
			end
		end
	end

	-- 1. Lift headframe beside the shaft (the SELL button "rides the lift")
	local lx = x0 - 4
	for _, s in { -1, 1 } do
		part(camp, "LiftLeg", Vector3.new(0.7, 19, 0.7), at(lx + s * 2.6, 9, Z - 2) * CFrame.Angles(0, 0, s * 0.12), WOOD, Enum.Material.Wood)
	end
	for _, y in { 6, 12 } do part(camp, "LiftBeam", Vector3.new(5.6, 0.5, 0.5), at(lx, y, Z - 2), WOOD_DK, Enum.Material.Wood) end
	local wheel = part(camp, "LiftWheel", Vector3.new(0.5, 3.4, 3.4), at(lx, 18, Z - 2) * CFrame.Angles(0, math.pi / 2, 0), Color3.fromRGB(90, 84, 110), Enum.Material.Metal, { Shape = Enum.PartType.Cylinder })
	part(camp, "Rope", Vector3.new(0.15, 12, 0.15), at(lx + 1.6, 11, Z - 2), CREAM, Enum.Material.Fabric)
	local cage = part(camp, "LiftCage", Vector3.new(3.4, 3.6, 3), at(lx + 0.5, 3.6, Z - 2), Color3.fromRGB(110, 80, 70), Enum.Material.WoodPlanks, { Transparency = 0.15 })
	local cageLight = part(camp, "CageLamp", Vector3.new(0.6, 0.6, 0.6), at(lx + 0.5, 5.8, Z - 0.4), LAMP, Enum.Material.Neon)
	light(cageLight, LAMP, 12, 1.2)
	wheel:SetAttribute("Spin", 1.5)
	cage:SetAttribute("Bob", 0.4)

	-- 2. Sell stall: counter, striped awning, ore crates, SELL sign
	local sx = x0 - 18
	local counter = part(camp, "SellCounter", Vector3.new(8, 3, 3), at(sx, 1.5, Z - 1.5), WOOD, Enum.Material.WoodPlanks)
	for _, s in { -1, 1 } do part(camp, "StallPost", Vector3.new(0.5, 7.5, 0.5), at(sx + s * 3.8, 3.75, Z - 0.3), WOOD_DK, Enum.Material.Wood) end
	for i = 0, 7 do
		part(camp, "Awning", Vector3.new(1.05, 0.4, 4.2), at(sx - 3.68 + i * 1.05, 7.6, Z - 1.6) * CFrame.Angles(math.rad(-14), 0, 0), i % 2 == 0 and PINK or CREAM)
	end
	for i, oc in { Color3.fromRGB(226, 128, 62), Color3.fromRGB(122, 112, 190), GOLD } do
		local crate = part(camp, "Crate", Vector3.new(1.8, 1.2, 1.4), at(sx - 4.5 + i * 2.2, 3.6, Z - 1.4), WOOD_DK, Enum.Material.WoodPlanks)
		part(camp, "Ore", Vector3.new(1.2, 0.6, 0.9), crate.CFrame * CFrame.new(0, 0.7, 0), oc, i == 3 and Enum.Material.Neon or Enum.Material.SmoothPlastic)
	end
	sign(camp, "SELL", at(sx, 9.4, Z), 4.2, 1.6, WOOD_DK, GOLD)
	hook(prompt(counter, "Sell ore", "Sell stall"), "sell")

	-- 3. Forge hut: stone walls, peaked roof, glowing furnace mouth, chimney smoke, anvil
	local fxp = x0 - 36
	part(camp, "ForgeWall", Vector3.new(12, 8, 9), at(fxp, 4, Z - 4.5), STONE, Enum.Material.Cobblestone)
	wedgeRoof(camp, 13, 10.4, 3.6, at(fxp, 9.8, Z - 4.5), ROOF)
	local mouth = part(camp, "FurnaceMouth", Vector3.new(4, 3.2, 0.4), at(fxp - 2, 2.2, Z + 0.05), Color3.fromRGB(255, 140, 60), Enum.Material.Neon)
	light(mouth, Color3.fromRGB(255, 150, 80), 20, 2.4, true):SetAttribute("Flicker", 1)
	part(camp, "Door", Vector3.new(3, 6, 0.3), at(fxp + 3.4, 3, Z + 0.05), WOOD_DK, Enum.Material.WoodPlanks)
	local chimney = part(camp, "Chimney", Vector3.new(2, 6, 2), at(fxp + 4, 11, Z - 6), STONE, Enum.Material.Cobblestone)
	local smoke = Instance.new("ParticleEmitter")
	smoke.Rate, smoke.Lifetime, smoke.Speed = 3, NumberRange.new(3, 5), NumberRange.new(2, 3)
	smoke.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 4) })
	smoke.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1) })
	smoke.Color, smoke.EmissionDirection = ColorSequence.new(Color3.fromRGB(150, 140, 180)), Enum.NormalId.Top
	smoke.Parent = chimney
	local anvil = part(camp, "Anvil", Vector3.new(2.6, 1.2, 1.2), at(fxp - 7.5, 2.2, Z + 1), Color3.fromRGB(80, 80, 104), Enum.Material.Metal)
	part(camp, "AnvilBase", Vector3.new(1.2, 1.6, 1), at(fxp - 7.5, 0.8, Z + 1), WOOD_DK, Enum.Material.Wood)
	sign(camp, "FORGE", at(fxp, 8.6, Z + 0.1), 5, 1.6, WOOD_DK, Color3.fromRGB(255, 170, 110))
	hook(prompt(anvil, "Upgrade", "Forge"), "forge")

	-- 4. Notice board (daily relic chest comes here) and 5. campfire with log benches
	local nbx = x0 - 48
	for _, s in { -1, 1 } do part(camp, "BoardPost", Vector3.new(0.4, 6, 0.4), at(nbx + s * 2, 3, Z), WOOD_DK, Enum.Material.Wood) end
	sign(camp, "NOTICES", at(nbx, 4.4, Z + 0.1), 4.4, 3, WOOD, CREAM)
	local cfx = x0 - 57
	for i = 0, 7 do
		local a = i / 8 * math.pi * 2
		part(camp, "FireStone", Vector3.new(0.9, 0.6, 0.9), at(cfx + math.cos(a) * 1.6, 0.3, Z + 1 + math.sin(a) * 1.2), Color3.fromRGB(110, 100, 140), Enum.Material.Slate)
	end
	local fire = part(camp, "Fire", Vector3.new(1.2, 1.4, 1.2), at(cfx, 0.8, Z + 1), Color3.fromRGB(255, 170, 80), Enum.Material.Neon, { Transparency = 0.2 })
	local flame = Instance.new("Fire")
	flame.Size, flame.Heat, flame.Color, flame.SecondaryColor = 4, 8, Color3.fromRGB(255, 160, 80), Color3.fromRGB(255, 90, 140)
	flame.Parent = fire
	light(fire, Color3.fromRGB(255, 170, 110), 24, 2.2, true):SetAttribute("Flicker", 1)
	for _, s in { -1, 1 } do part(camp, "LogBench", Vector3.new(3.4, 0.9, 0.9), at(cfx + s * 3.6, 0.45, Z + 1) * CFrame.Angles(0, math.pi / 2, 0), WOOD, Enum.Material.Wood) end

	-- 6. Tent (A-frame canvas) with a hanging lantern
	local tx = x0 - 68
	wedgeRoof(camp, 7, 7, 5.6, at(tx, 2.8, Z - 3.6), LILAC)
	part(camp, "TentFlap", Vector3.new(1.6, 3.4, 0.2), at(tx, 1.7, Z - 0.05), Color3.fromRGB(70, 50, 100))
	local tl = part(camp, "TentLamp", Vector3.new(0.6, 0.8, 0.6), at(tx + 2.4, 3.6, Z), LAMP, Enum.Material.Neon)
	light(tl, LAMP, 10, 1)

	-- 7. Eggs dome (incubator): base, glass dome, three glowing eggs, EGGS sign
	local ex = xR + 10
	local base = part(camp, "IncubatorBase", Vector3.new(1.4, 9, 9), at(ex, 0.7, Z - 4.5) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(150, 120, 190), Enum.Material.SmoothPlastic, { Shape = Enum.PartType.Cylinder })
	part(camp, "Dome", Vector3.new(8.4, 8.4, 8.4), at(ex, 1.4, Z - 4.5), Color3.fromRGB(200, 236, 255), Enum.Material.Glass, { Shape = Enum.PartType.Ball, Transparency = 0.55 })
	for i, ec in { PINK, Color3.fromRGB(255, 240, 220), MINT } do
		local egg = part(camp, "IncubatorEgg", Vector3.new(1.6, 2.1, 1.6), at(ex - 3 + i * 1.5 + (i - 2) * 0.3, 2.6, Z - 4.5 + (i == 2 and -1 or 0.6)), ec, Enum.Material.Neon, { Shape = Enum.PartType.Ball })
		egg:SetAttribute("Bob", 0.25 + i * 0.05)
		if i == 2 then light(egg, Color3.fromRGB(255, 220, 190), 16, 1.6) end
	end
	sign(camp, "EGGS", at(ex, 6.6, Z + 0.2), 3.6, 1.4, Color3.fromRGB(70, 50, 110), Color3.fromRGB(255, 220, 240))
	hook(prompt(base, "Hatch an egg", "Incubator"), "hatch")
	opts.incubatorSign = camp:FindFirstChild("Sign")

	-- 8. Map board (new areas) with the seven layer colours
	local mx = xR + 24
	for _, s in { -1, 1 } do part(camp, "MapPost", Vector3.new(0.4, 7, 0.4), at(mx + s * 2.4, 3.5, Z), WOOD_DK, Enum.Material.Wood) end
	local board = part(camp, "MapBoard", Vector3.new(5.4, 3.4, 0.3), at(mx, 4.6, Z + 0.05), Color3.fromRGB(235, 220, 190), Enum.Material.WoodPlanks)
	for i, lc in opts.layerColors do
		part(camp, "MapLayer", Vector3.new(4.6, 0.36, 0.1), at(mx, 6 - i * 0.42, Z + 0.25), lc)
	end
	sign(camp, "MAP", at(mx, 7.4, Z + 0.1), 2.6, 1, WOOD_DK, CREAM)
	hook(prompt(board, "Look at the map", "Map board"), "map")

	-- 9. Guest cabins (guests arrive over the first week) and a bench
	for i = 0, 1 do
		local gx = xR + 36 + i * 11
		part(camp, "Cabin", Vector3.new(8, 6.5, 7), at(gx, 3.25, Z - 3.5), Color3.fromRGB(130, 86, 70), Enum.Material.WoodPlanks)
		wedgeRoof(camp, 9, 8.4, 3, at(gx, 8, Z - 3.5), i == 0 and Color3.fromRGB(90, 120, 170) or Color3.fromRGB(110, 150, 120))
		local win = part(camp, "Window", Vector3.new(2, 1.8, 0.2), at(gx - 1.8, 3.8, Z + 0.05), i == 0 and LAMP or Color3.fromRGB(60, 50, 80), i == 0 and Enum.Material.Neon or Enum.Material.Glass)
		if i == 0 then light(win, LAMP, 10, 0.9) end
		part(camp, "CabinDoor", Vector3.new(2, 4.6, 0.2), at(gx + 2, 2.3, Z + 0.05), WOOD_DK, Enum.Material.WoodPlanks)
	end
	sign(camp, "GUESTS SOON", at(xR + 41.5, 1.6, Z + 1.2), 4.4, 1.2, WOOD, CREAM)
	part(camp, "Bench", Vector3.new(4, 0.4, 1.2), at(xR + 53, 1.4, Z + 1.4), WOOD, Enum.Material.Wood)

	-- 10. Trophy wall (boss trophies go here)
	local twx = xR + 60
	part(camp, "TrophyWall", Vector3.new(7, 6, 1), at(twx, 3, Z - 0.6), STONE, Enum.Material.Slate)
	for i = -1, 1 do part(camp, "Plaque", Vector3.new(1.6, 1.6, 0.3), at(twx + i * 2.2, 3.6, Z), Color3.fromRGB(90, 76, 60), Enum.Material.Wood) end
	sign(camp, "TROPHIES", at(twx, 6.7, Z), 4, 1, WOOD_DK, GOLD)

	-- 11. World tree at the far right edge: trunk, roots into the ground, teal canopy with hanging lights
	local wx = xR + opts.sideW - 6
	part(camp, "Trunk", Vector3.new(7, 40, 7), at(wx, 20, Z - 8), Color3.fromRGB(88, 70, 120), Enum.Material.Wood)
	for i = 0, 3 do
		local a = i / 4 * math.pi * 2 + 0.4
		part(camp, "Root", Vector3.new(2, 2, 10), at(wx + math.cos(a) * 5, 0.5, Z - 8 + math.sin(a) * 4) * CFrame.Angles(0.2, a, 0), Color3.fromRGB(78, 60, 108), Enum.Material.Wood)
	end
	for i = 0, 5 do
		local a = i / 6 * math.pi * 2
		part(camp, "Canopy", Vector3.new(16, 11, 16), at(wx + math.cos(a) * 9, 40 + math.sin(a * 2) * 2, Z - 8 + math.sin(a) * 6), Color3.fromRGB(60, 150, 150), Enum.Material.Grass, { Shape = Enum.PartType.Ball })
		local fl = part(camp, "TreeLight", Vector3.new(0.6, 0.6, 0.6), at(wx + math.cos(a) * 10, 33, Z - 2 + math.sin(a) * 2), MINT, Enum.Material.Neon)
		fl:SetAttribute("Bob", 0.3)
		if i % 2 == 0 then light(fl, MINT, 12, 0.9) end
	end

	-- 12. Lamp posts and fences tie the camp together; 13. start sign over the glowing first block
	for _, x in { x0 - 10, x0 - 27, x0 - 44, x0 - 62, xR + 4, xR + 18, xR + 30, xR + 55 } do lamp(camp, Vector3.new(x, G, Z + 1.6)) end
	for side = -1, 1, 2 do
		local x = side < 0 and x0 - opts.sideW + 1 or xR + opts.sideW - 1
		for k = 0, 2 do part(camp, "FencePost", Vector3.new(0.4, 2.4, 0.4), at(x, 1.2, Z + 2 - k * 1.8), WOOD_DK, Enum.Material.Wood) end
		part(camp, "FenceRail", Vector3.new(0.2, 0.3, 4), at(x, 1.8, Z + 0.2), WOOD, Enum.Material.Wood)
	end
	local sx0 = opts.startX
	part(camp, "StartPost", Vector3.new(0.4, 6, 0.4), CFrame.new(sx0 + 3, 3, Z), WOOD_DK, Enum.Material.Wood)
	sign(camp, "DIG HERE", CFrame.new(sx0 + 3, 5.4, Z + 0.1), 4, 1.4, Color3.fromRGB(40, 110, 70), Color3.fromRGB(220, 255, 220))

	camp.Parent = folder
	return camp
end

return Camp
