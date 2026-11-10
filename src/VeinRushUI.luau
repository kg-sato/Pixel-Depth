-- VeinRushUI (ReplicatedStorage.Shared.VeinRushUI), started by PixelClient's cave function. Vein Rush (EXT-02): the vein drops
-- a segment per chisel; a stress fissure glows on one side of each segment, chisel the other side.
-- Demo audit 07: it was a 2D tower of flat rectangles with red bars. Now the vein is a real crystal spire standing in the cave
-- at the deposit: five faceted glass segments with a glowing heart, the fissures are glowing cracks inside the crystal, an iron
-- chisel jabs in from the side you pick, and every strike cleaves the bottom chunk into tumbling glass shards with a small
-- camera shake. The screen keeps only the controls: quality and stars, the time bar, the beat count and the two buttons.
-- The server grades the choices (PixelClient sends them); this module only draws and reads input.
local M = {}

function M.start(E)
	local new, S, fit, text, panel, button, keyCap, tween = E.new, E.S, E.fit, E.text, E.panel, E.button, E.keyCap, E.tween
	local sfx, shake, pop, uiBurst, D, caveHud = E.sfx, E.shake, E.pop, E.uiBurst, E.D, E.caveHud
	local INK, WHITE, MINT, PINK, CREAM, LILAC = E.INK, E.WHITE, E.MINT, E.PINK, E.CREAM, E.LILAC
	local UIS, Debris = game:GetService("UserInputService"), game:GetService("Debris")
	local cam = workspace.CurrentCamera
	local FISSURE = Color3.fromRGB(255, 69, 0)
	local SEG_H, N, PLINTH = 0.66, 5, 1.1 -- small enough that the whole spire sits in the clear middle of the screen from 5 studs

	-- the screen: quality, time, beat, the two chisel buttons
	local vr = new("Frame", caveHud, { Name = "VeinRush", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, ZIndex = 10 })
	new("Frame", vr, { Name = "Dim", Size = UDim2.new(1, 0, 1, 60), Position = UDim2.fromOffset(0, -60), BackgroundColor3 = Color3.fromRGB(26, 18, 40), BackgroundTransparency = 0.78, BorderSizePixel = 0, ZIndex = 9 }) -- light: the spire stands in the world behind it
	local quality = panel(vr, S(560, 84), S(640, 18), Vector2.new(0.5, 0), "card")
	fit(quality, 560, 84)
	quality.ZIndex = 12
	local qText = text(quality, "VEIN RUSH  FLAWLESS", UDim2.fromScale(0.6, 0.4), UDim2.fromScale(0.07, 0.26), nil, INK, 700, false)
	qText.TextXAlignment = Enum.TextXAlignment.Left
	local stars = {}
	for i = 1, 3 do
		stars[i] = new("ImageLabel", quality, { Image = E.SPRITE.star, BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Size = UDim2.fromScale(0.09, 0.56), Position = UDim2.fromScale(0.73 + i * 0.065, 0.46), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 3 })
	end
	local timeBar = panel(vr, S(460, 42), S(640, 110), Vector2.new(0.5, 0), "dark")
	fit(timeBar, 460, 42)
	timeBar.ZIndex = 12
	local timeTrack = new("Frame", timeBar, { Size = UDim2.fromScale(0.9, 0.5), Position = UDim2.fromScale(0.5, 0.45), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.fromRGB(30, 20, 48), BorderSizePixel = 0, ZIndex = 2 })
	new("UICorner", timeTrack, { CornerRadius = UDim.new(0.5, 0) })
	local timeFill = new("Frame", timeTrack, { Size = UDim2.fromScale(1, 1), BackgroundColor3 = MINT, BorderSizePixel = 0, ZIndex = 3 })
	new("UICorner", timeFill, { CornerRadius = UDim.new(0.5, 0) })
	local beatBar = panel(vr, S(200, 36), S(640, 480), Vector2.new(0.5, 0.5), "dark")
	fit(beatBar, 200, 36)
	beatBar.ZIndex = 12
	local beatText = text(beatBar, "BEAT 1 / 10", UDim2.fromScale(0.84, 0.5), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5), CREAM)
	beatText.ZIndex = 3
	local leftBtn = button(vr, "< CHISEL LEFT", S(230, 66), S(230, 470), Vector2.new(0, 1), "mint", "chisel") -- clear of the spire and the stick/jump zones
	local rightBtn = button(vr, "CHISEL RIGHT >", S(230, 66), S(1050, 470), Vector2.new(1, 1), "pink", "chisel")
	rightBtn.Icon.Rotation = 90 -- the chisel points the other way
	leftBtn.ZIndex, rightBtn.ZIndex = 12, 12
	if UIS.KeyboardEnabled then
		keyCap(leftBtn, "A", UDim2.fromScale(0.1, 0.5), UDim2.fromScale(0.06, 0.12))
		keyCap(rightBtn, "D", UDim2.fromScale(0.1, 0.5), UDim2.fromScale(0.94, 0.12))
	end

	-- the spire: built once, parked out of the world between runs
	local spire = new("Model", nil, { Name = "VeinSpire" })
	local function p(parent, size, cf, color, props)
		local q = new("Part", parent, { Size = size, CFrame = cf, Color = color, Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, Material = Enum.Material.Glass, TopSurface = Enum.SurfaceType.Smooth, BottomSurface = Enum.SurfaceType.Smooth })
		for k, v in props or {} do q[k] = v end
		return q
	end
	local root = p(spire, Vector3.new(0.2, 0.2, 0.2), CFrame.new(), WHITE, { Transparency = 1 })
	spire.PrimaryPart = root
	local glowL = new("PointLight", root, { Range = 18, Brightness = 2.2, Shadows = false })
	local slots = {}
	for k = 1, N do -- slot 1 is the bottom segment, the one you chisel now
		local y = PLINTH + (k - 0.5) * SEG_H
		local w = 1.12 - (k - 1) * 0.1 -- the spire tapers toward its tip
		local sl = { glass = {}, fiss = { {}, {} }, edges = {} }
		for i = 0, 2 do -- three glass slabs turned 60 degrees apart make a six-sided crystal; each chunk is narrower at its top
			sl.glass[i + 1] = p(spire, Vector3.new(w, SEG_H - 0.05, w * 0.58), CFrame.new(0, y, 0) * CFrame.Angles(0, i * math.pi / 3, 0), WHITE, { Material = Enum.Material.Neon, Transparency = 0.3 }) -- glowing crystal: plain glass vanished in the dark cave
			table.insert(sl.edges, p(spire, Vector3.new(w * 0.86, 0.1, w * 0.5), CFrame.new(0, y + SEG_H / 2 - 0.05, 0) * CFrame.Angles(0, i * math.pi / 3, 0), WHITE, { Material = Enum.Material.Neon, Transparency = 0.15 })) -- the lit cut face on top of each chunk
		end
		sl.heart = p(spire, Vector3.new(w * 0.34, SEG_H * 0.86, w * 0.34), CFrame.new(0, y, 0) * CFrame.Angles(0, math.pi / 6, 0), WHITE, { Material = Enum.Material.Neon })
		sl.facet = p(spire, Vector3.new(w * 0.2, SEG_H * 0.5, w * 0.2), CFrame.new(w * 0.2, y + 0.05, w * 0.14) * CFrame.Angles(0.3, 0.4, 0.2), WHITE, { Material = Enum.Material.Neon, Transparency = 0.3 }) -- a second, smaller inclusion
		for side = 1, 2 do -- the stress fissure: planes of orange light inside the crystal on that side, breaking the surface in a jagged line
			local sx = side == 1 and -1 or 1
			for n, a in { 0.5, -0.4 } do
				table.insert(sl.fiss[side], p(spire, Vector3.new(w * 0.62, SEG_H * 0.86, 0.06), CFrame.new(sx * w * 0.27, y, w * 0.05 * n) * CFrame.Angles(0, sx * a, sx * 0.35), FISSURE, { Material = Enum.Material.Neon, Transparency = 0.1 }))
			end
			table.insert(sl.fiss[side], p(spire, Vector3.new(w * 0.62, 0.07, w * 0.62), CFrame.new(sx * w * 0.26, y - 0.02, 0) * CFrame.Angles(0, 0.5, sx * 0.5), FISSURE, { Material = Enum.Material.Neon })) -- the crack's edge breaks the surface all the way round that side
		end
		slots[k] = sl
	end
	local tip = { p(spire, Vector3.new(0.56, 0.44, 0.56), CFrame.new(), WHITE, { Transparency = 0.2, Reflectance = 0.2 }), p(spire, Vector3.new(0.3, 0.4, 0.3), CFrame.new(), WHITE, { Transparency = 0.2, Reflectance = 0.2 }) }
	local ROCKV = { Material = Enum.Material.Slate, MaterialVariant = "PixelCaveRock", Transparency = 0 }
	p(spire, Vector3.new(1.9, PLINTH * 0.6, 1.9), CFrame.new(0, PLINTH * 0.3, 0), Color3.fromRGB(70, 50, 98), ROCKV) -- the rock the vein grows out of
	p(spire, Vector3.new(1.4, PLINTH * 0.4, 1.4), CFrame.new(0, PLINTH * 0.8, 0) * CFrame.Angles(0, 0.5, 0), Color3.fromRGB(98, 72, 132), ROCKV)
	local chiselTool = new("Model", spire, { Name = "Chisel" })
	p(chiselTool, Vector3.new(0.2, 0.3, 0.4), CFrame.new(-0.3, 0, 0), Color3.fromRGB(196, 190, 214), { Material = Enum.Material.Metal, Reflectance = 0.3 }) -- the bevelled cutting edge
	p(chiselTool, Vector3.new(0.16, 0.36, 0.36), CFrame.new(0.38, 0, 0), Color3.fromRGB(200, 150, 70), { Material = Enum.Material.Metal }) -- a brass ferrule
	local blade = p(chiselTool, Vector3.new(0.9, 0.24, 0.34), CFrame.new(), Color3.fromRGB(150, 156, 176), { Material = Enum.Material.Metal, Reflectance = 0.35 }) -- cold iron
	p(chiselTool, Vector3.new(0.7, 0.28, 0.28), CFrame.new(0.82, 0, 0), Color3.fromRGB(52, 36, 32), { Material = Enum.Material.SmoothPlastic }) -- a dark leather-wrapped handle
	for _, x in { 0.6, 0.82, 1.04 } do p(chiselTool, Vector3.new(0.06, 0.31, 0.31), CFrame.new(x, 0, 0), Color3.fromRGB(92, 64, 50), { Material = Enum.Material.SmoothPlastic }) end
	p(chiselTool, Vector3.new(0.14, 0.36, 0.36), CFrame.new(1.24, 0, 0), Color3.fromRGB(150, 108, 60), { Material = Enum.Material.Metal })
	chiselTool.PrimaryPart = blade
	local rel = {} -- every part's place inside the spire, so the whole thing can be moved as one
	for _, q in spire:GetDescendants() do if q:IsA("BasePart") then rel[q] = q.CFrame end end

	local live -- { mg, frame = CFrame (its right is the player's right), dropAt, jab = { side, at } }
	local function place(offset)
		local base = live.frame * CFrame.new(0, offset, 0)
		for q, cf in rel do
			if not q:IsDescendantOf(chiselTool) then q.CFrame = base * cf end
		end
	end
	local function draw()
		local mg = live.mg
		local top = 0
		for k, sl in slots do
			local beat = mg.i + k
			local on = beat <= #mg.seq
			if on then top = k end
			local base = mg.col:Lerp(Color3.fromRGB(150, 96, 235), 0.6):Lerp(Color3.new(0, 0, 0), beat % 2 == 0 and 0.3 or 0.42) -- amethyst, tinted by the ore; kept dark enough that the neon holds its colour
			for _, g in sl.glass do
				g.LocalTransparencyModifier = on and 0 or 1
				g.Color = base
			end
			sl.heart.LocalTransparencyModifier, sl.facet.LocalTransparencyModifier = on and 0 or 1, on and 0 or 1
			for _, e in sl.edges do
				e.LocalTransparencyModifier = on and 0 or 1
				e.Color = base:Lerp(WHITE, 0.55)
			end
			sl.heart.Color, sl.facet.Color = base:Lerp(WHITE, 0.3), base:Lerp(WHITE, 0.6)
			for side = 1, 2 do
				local show = on and mg.seq[beat] == side
				for _, f in sl.fiss[side] do f.LocalTransparencyModifier = show and (k <= 2 and 0 or 0.6) or 1 end -- only the next two fissures burn bright
			end
		end
		for i, t in tip do -- the pointed tip rides on the highest segment left
			t.LocalTransparencyModifier = top > 0 and 0 or 1
			t.Color = mg.col:Lerp(WHITE, 0.45)
			rel[t] = CFrame.new(0, PLINTH + top * SEG_H + (i == 1 and 0.2 or 0.58), 0) * CFrame.Angles(0, math.pi / 4, 0)
		end
		glowL.Color = mg.col:Lerp(WHITE, 0.4)
		local g = E.gradeOf(mg.slips)
		qText.Text = "VEIN RUSH  " .. g[1]
		for i, st in stars do st.Image = i <= g[4] and E.SPRITE.star or E.SPRITE.starOff end
		beatText.Text = "BEAT " .. math.min(mg.i + 1, #mg.seq) .. " / " .. #mg.seq
	end
	local function shards(side, col, slip)
		local at = live.frame * CFrame.new(0, PLINTH + SEG_H * 0.5, 0)
		local sx = side == 1 and -1 or 1
		for i = 1, slip and 5 or 9 do -- the cleaved chunk: glass shards (two of them glowing) thrown out to the struck side
			local sz = 0.12 + math.random() * 0.24
			local q = p(workspace, Vector3.new(sz, sz * (0.8 + math.random()), sz), at * CFrame.new((math.random() - 0.5) * 1.2, (math.random() - 0.5) * 0.8, (math.random() - 0.5) * 1.2) * CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6),
				slip and FISSURE or col:Lerp(WHITE, 0.2 + math.random() * 0.4), { Anchored = false, Transparency = i <= 2 and 0 or 0.25, Material = i <= 2 and Enum.Material.Neon or Enum.Material.Glass, Reflectance = 0.2 })
			q.AssemblyLinearVelocity = live.frame:VectorToWorldSpace(Vector3.new(sx * (5 + math.random() * 9), 5 + math.random() * 8, -(math.random() * 6)))
			q.AssemblyAngularVelocity = Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * 24
			tween(q, 0.9, { Transparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			Debris:AddItem(q, 1)
		end
	end

	local api = { frame = vr }
	function api.open(mg)
		local core = mg.dep.PrimaryPart
		local eye = cam.CFrame.Position
		local out = core.CFrame.LookVector * Vector3.new(1, 0, 1) -- the cluster faces its wall
		local at = core.Position - (out.Magnitude > 0.1 and out.Unit or Vector3.zero) * 1.1
		local rp = RaycastParams.new()
		rp.FilterDescendantsInstances = { mg.dep, E.plr.Character }
		local floor = workspace:Raycast(at + Vector3.new(0, 2, 0), Vector3.new(0, -8, 0), rp)
		at = floor and floor.Position or at - Vector3.new(0, 1, 0)
		local away = (at - eye) * Vector3.new(1, 0, 1)
		live = { mg = mg, frame = CFrame.lookAt(at, at + (away.Magnitude > 0.5 and away.Unit or cam.CFrame.LookVector * Vector3.new(1, 0, 1))), dropAt = 0 }
		spire.Parent = workspace
		live.hid = {} -- the deposit steps aside: the spire is the vein now
		for _, q in mg.dep:GetDescendants() do
			if q:IsA("BasePart") then live.hid[q] = q.LocalTransparencyModifier q.LocalTransparencyModifier = 1 end
		end
		draw()
		place(0)
		chiselTool:PivotTo(live.frame * CFrame.new(3, PLINTH + SEG_H * 0.5, 0))
		cam.CFrame = CFrame.lookAt(eye, at + Vector3.new(0, PLINTH + SEG_H * 2.2, 0)) -- turn to the spire (first person keeps the new look)
		vr.Visible = true
		pop(quality, 0.7, 0.3)
		sfx("sparkle", 0.9)
	end
	function api.close()
		vr.Visible = false
		if live and live.hid then
			for q, t in live.hid do if q.Parent then q.LocalTransparencyModifier = t end end
		end
		live = nil
		spire.Parent = nil
	end
	function api.chisel(side)
		local mg = live and live.mg
		if not mg or mg.kind ~= "rush" or mg.sent then return end
		mg.i += 1
		mg.choices[mg.i] = side
		local howTo = caveHud:FindFirstChild("HowTo")
		if howTo and howTo.Visible then howTo.Visible = false end -- the first chisel is in: the card gives the screen back
		live.jab = { side = side, at = os.clock() }
		local at2 = S(640 + (side == 1 and -50 or 50), 400)
		if mg.seq[mg.i] == side then -- struck the fissure: a slip
			mg.slips += 1
			sfx("hit", 0.6)
			shake(0.5)
			shards(side, mg.col, true)
			uiBurst(vr, at2, { Color3.fromRGB(255, 90, 110), PINK }, 8, 0.14)
		else -- a clean cleave: a glass crack, shards, a small shake
			sfx("clink", 1.1 + mg.i * 0.04)
			sfx("breakRock", 1.9)
			shake(0.16)
			shards(side, mg.col, false)
		end
		live.dropAt = os.clock() -- the spire drops one segment
		draw()
		if mg.i >= #mg.seq then E.send(mg) end
	end
	function api.tick(mg)
		if not live then return end
		local now = os.clock()
		local u = math.clamp((now - live.dropAt) / 0.14, 0, 1)
		place(SEG_H * (1 - u) ^ 2 + math.sin(now * 1.7) * 0.03)
		local jab = live.jab
		local side = jab and jab.side or 2
		local sx = side == 1 and -1 or 1
		local j = jab and math.clamp((now - jab.at) / 0.26, 0, 1) or 1
		local reach = 0.85 + 0.75 * math.abs(j * 2 - 1) -- in fast, back out; it waits close by, on the side it last struck
		chiselTool:PivotTo(live.frame * CFrame.new(sx * reach, PLINTH + SEG_H * 0.5 + (reach - 0.85) * 0.7, 0.2) * CFrame.Angles(0, sx < 0 and math.pi or 0, -0.6)) -- a downward strike, 35 degrees
		for _, q in chiselTool:GetChildren() do q.LocalTransparencyModifier = 0 end
		for k, sl in slots do -- hearts and fissures breathe
			sl.heart.Transparency = 0.1 + 0.15 * math.sin(now * 3 + k)
		end
		local left = 1 - (workspace:GetServerTimeNow() - mg.t0) / (#mg.seq * D.rushBeat)
		timeFill.Size = UDim2.fromScale(math.clamp(left, 0, 1), 1)
		timeFill.BackgroundColor3 = left > 0.3 and MINT or PINK
		if left <= 0 then E.send(mg) end
	end
	leftBtn.Activated:Connect(function() api.chisel(1) end)
	rightBtn.Activated:Connect(function() api.chisel(2) end)
	return api
end

return M
