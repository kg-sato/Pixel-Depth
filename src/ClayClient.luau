-- ClayClient (ReplicatedStorage.Shared.ClayClient), started by PixelClient: the player's side of the Clay Caves hall that
-- ServerScriptService.ClayCaves builds (the user's overnight directive, 2026-11-10).
--   * steam vents: each erupts 3.2 s out of every 6. Stand in one while it blows: it throws you up (C.CLAY.launch), then you
--     glide down under a clay-cloth umbrella (fall speed capped at C.CLAY.glideFall, steer with the move keys)
--   * the way down and back: a short fade (Fx "clayTravel")
--   * clay jars: Fx "jar" breaks the jar for this player until its cooldown ends, with the coins and maybe a relic shard
--   * fossil brushing: Fx "fossilBrush" opens a panel. Drag across the clay tiles with slow strokes to wear them away
--     (three strokes a tile); a fast stroke cracks the fossil, three cracks end the try. Uncover the whole amber shape and
--     the server pays (remote Clay "fossil").
--   * the Kiln Keeper: one line of advice per talk
local M = {}

function M.start(E)
	local RunService, UIS = game:GetService("RunService"), game:GetService("UserInputService")
	local plr, C, new, tween, sfx, toast, text = E.plr, E.C, E.new, E.tween, E.sfx, E.toast, E.text
	local K = C.CLAY
	local remote = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Clay", 20)
	local CLAY, CLAY_L, AMBER, CREAM = Color3.fromRGB(150, 78, 58), Color3.fromRGB(196, 112, 78), Color3.fromRGB(255, 176, 84), Color3.fromRGB(240, 222, 190)
	local fxFolder = workspace:FindFirstChild("ClientFX") or workspace
	local function clay() return workspace:FindFirstChild("Caves") and workspace.Caves:FindFirstChild("Clay") end

	-- the travel fade
	local fade = new("Frame", E.top, { Name = "ClayFade", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(20, 12, 26), BackgroundTransparency = 1, Visible = false, ZIndex = 54 })

	-- the tunnel ride between Camp 1 and the Clay Caves (roadmap phase 10: "the alcove becomes a short second minecart ride"):
	-- seen only by this player. A sloping clay tunnel of timber ribs and lamps stands high over the hall; on travel the camera
	-- rides a cart nose down (or up) it for 2.3 s between two fades, while the server moves the character.
	local calm = false
	pcall(function() calm = game:GetService("GuiService").ReducedMotionEnabled end)
	local tunnel
	local function buildTunnel()
		tunnel = new("Model", fxFolder, { Name = "ClayTunnel" })
		local top = CFrame.new(C.CAVE2_ORIGIN + Vector3.new(0, 300, 0)) * CFrame.Angles(-0.32, 0, 0) -- runs along -Z, sloping down
		local function tp(size, cf, color, props)
			local p = new("Part", tunnel, { Size = size, CFrame = top * cf, Color = color, Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, Material = Enum.Material.Sandstone })
			for k, v in props or {} do p[k] = v end
			return p
		end
		local WOOD = Color3.fromRGB(92, 62, 48)
		tp(Vector3.new(11, 1, 150), CFrame.new(0, -3.4, -70), Color3.fromRGB(104, 52, 46))
		tp(Vector3.new(11, 1, 150), CFrame.new(0, 5.4, -70), Color3.fromRGB(58, 36, 72))
		for _, x in { -5.6, 5.6 } do tp(Vector3.new(1, 9.8, 150), CFrame.new(x, 1, -70), CLAY) end
		for _, x in { -1.5, 1.5 } do tp(Vector3.new(0.3, 0.3, 150), CFrame.new(x, -2.7, -70), Color3.fromRGB(138, 128, 168), { Material = Enum.Material.Metal }) end
		for _, z in { 5.4, -145.4 } do tp(Vector3.new(12.2, 9.8, 1), CFrame.new(0, 1, z), Color3.fromRGB(20, 12, 26)) end
		for k = 0, 18 do
			local z = -k * 8
			tp(Vector3.new(3.4, 0.3, 0.9), CFrame.new(0, -2.86, z - 4), WOOD, { Material = Enum.Material.Wood }) -- a tie
			for _, x in { -4.6, 4.6 } do tp(Vector3.new(0.9, 8, 0.9), CFrame.new(x, 0.9, z), WOOD, { Material = Enum.Material.Wood }) end
			tp(Vector3.new(10.2, 0.9, 0.9), CFrame.new(0, 4.6, z), WOOD, { Material = Enum.Material.Wood })
			if k % 2 == 0 then
				local lamp = tp(Vector3.new(0.5, 0.6, 0.5), CFrame.new(k % 4 == 0 and -3.9 or 3.9, 3.2, z - 0.6), AMBER, { Material = Enum.Material.Neon })
				new("PointLight", lamp, { Color = AMBER, Range = 16, Brightness = 0.5, Shadows = false })
			end
		end
		return top
	end
	local tunnelTop
	local function tunnelRide(down)
		local cam = workspace.CurrentCamera
		if cam.CameraType == Enum.CameraType.Scriptable then return false end -- something else owns the view
		tunnelTop = tunnelTop or buildTunnel()
		local t0, len = os.clock() + 0.35, 2.3
		task.delay(0.35, function()
			tween(fade, 0.25, { BackgroundTransparency = 1 })
			cam.CameraType = Enum.CameraType.Scriptable
			E.gui.Enabled = false
			local conn
			local nextClack = 0
			conn = RunService.RenderStepped:Connect(function()
				local t = (os.clock() - t0) / len
				if t >= 1 then
					conn:Disconnect()
					cam.CameraType = Enum.CameraType.Custom
					E.gui.Enabled = true
					return
				end
				if t > 0.86 and fade.BackgroundTransparency > 0.9 then tween(fade, 0.25, { BackgroundTransparency = 0 }) end
				local e = t * t * (3 - 2 * t) -- ease in and out
				local z = down and (-8 - e * 126) or (-134 + e * 126)
				local sway = math.sin(os.clock() * 9) * 0.05
				cam.CFrame = tunnelTop * CFrame.new(math.sin(os.clock() * 2.2) * 0.25, -0.9 + math.abs(math.sin(os.clock() * 13)) * 0.07, z) * CFrame.Angles(0, down and 0 or math.pi, sway)
				if os.clock() >= nextClack then
					nextClack = os.clock() + 0.16
					sfx("step", 0.55)
				end
			end)
		end)
		return true
	end

	-- the umbrella: a clay-cloth canopy over the head while gliding
	local brolly = new("Model", nil, { Name = "GlideUmbrella" })
	local function bp(size, cf, color)
		return new("Part", brolly, { Size = size, CFrame = cf, Color = color, Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, Material = Enum.Material.SmoothPlastic })
	end
	brolly.PrimaryPart = bp(Vector3.new(0.3, 4.4, 0.3), CFrame.new(0, 0, 0), Color3.fromRGB(92, 62, 48))
	for k = 0, 7 do -- eight panels round the pole, alternating cream and clay, drooping at the rim
		local a = k / 8 * math.pi * 2
		bp(Vector3.new(2.6, 0.25, 3.2), CFrame.new(0, 2.2, 0) * CFrame.Angles(0, a, 0) * CFrame.new(0, -0.35, -2.1) * CFrame.Angles(-0.3, 0, 0), k % 2 == 0 and CREAM or CLAY_L)
	end
	bp(Vector3.new(1.2, 0.5, 1.2), CFrame.new(0, 2.5, 0), AMBER)

	local vents, ventsOf, pads = {}, nil, {}
	local function findVents()
		local f = clay()
		if f == ventsOf then return end
		ventsOf, vents, pads = f, {}, {}
		for _, d in f and f.Parent:GetDescendants() or {} do -- the whole cave model: a pad also sits on the secret ledge in Camp 1's chasm
			if d:IsA("BasePart") and d:GetAttribute("BouncePad") then table.insert(pads, { part = d, size = d.Size, power = d:GetAttribute("BouncePad") }) end
			if d:IsA("BasePart") and d:GetAttribute("SteamVent") then
				local em = new("ParticleEmitter", d, {
					Rate = 0, Lifetime = NumberRange.new(1.1, 1.7), Speed = NumberRange.new(38, 56), SpreadAngle = Vector2.new(7, 7), EmissionDirection = Enum.NormalId.Top,
					Color = ColorSequence.new(Color3.fromRGB(236, 232, 244)), LightEmission = 0.25, Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-60, 60),
					Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.4), NumberSequenceKeypoint.new(1, 6) }),
					Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(0.7, 0.8), NumberSequenceKeypoint.new(1, 1) }),
				})
				local hiss = new("ParticleEmitter", d, { -- a thin wisp between eruptions, so the vent reads as alive
					Rate = 6, Lifetime = NumberRange.new(1.5, 2.2), Speed = NumberRange.new(3, 6), SpreadAngle = Vector2.new(12, 12), EmissionDirection = Enum.NormalId.Top,
					Color = ColorSequence.new(Color3.fromRGB(236, 232, 244)), Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 2.2) }),
					Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(1, 1) }),
				})
				table.insert(vents, { part = d, em = em, hiss = hiss, i = d:GetAttribute("SteamVent"), on = false })
			end
		end
	end

	local gliding, launchedAt, told = false, -10, false
	RunService.Heartbeat:Connect(function()
		if plr:GetAttribute("InCave") ~= true then
			if brolly.Parent then brolly.Parent = nil end
			gliding = false
			return
		end
		findVents()
		local h = E.hrp()
		local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
		if not h or not hum then return end
		local now, t = os.clock(), workspace:GetServerTimeNow()
		for _, v in vents do
			local on = (t + v.i * 3) % 6 < 3.2
			if on ~= v.on then
				v.on = on
				v.em.Rate = on and 90 or 0
				if on and (v.part.Position - h.Position).Magnitude < 60 then sfx("open", 0.5) end
			end
			local d = h.Position - v.part.Position
			if on and now - launchedAt > 1.5 and Vector2.new(d.X, d.Z).Magnitude < 2.6 and d.Y > 0 and d.Y < 7 then -- standing in the blast
				launchedAt, gliding = now, true
				local vel = h.AssemblyLinearVelocity
				h.AssemblyLinearVelocity = Vector3.new(vel.X, K.launch, vel.Z)
				sfx("upgrade", 0.6)
				E.shake(0.25)
				if not told then
					told = true
					toast("STEAM UPDRAFT! STEER WITH THE MOVE KEYS AND GLIDE", CREAM, true)
				end
			end
		end
		for _, pd in pads do -- a spore pad: land on the cap and it throws you up, squashing and springing back
			local d = h.Position - pd.part.Position
			if now - launchedAt > 0.4 and Vector2.new(d.X, d.Z).Magnitude < pd.size.X / 2 + 0.3 and d.Y > 0 and d.Y < 5 and h.AssemblyLinearVelocity.Y < 2 then
				launchedAt = now
				local vel = h.AssemblyLinearVelocity
				h.AssemblyLinearVelocity = Vector3.new(vel.X, pd.power, vel.Z)
				sfx("pop", 0.7)
				pd.part.Size = pd.size * Vector3.new(1.25, 0.5, 1.25)
				tween(pd.part, 0.45, { Size = pd.size }, Enum.EasingStyle.Elastic)
			end
		end
		if gliding then
			local vel = h.AssemblyLinearVelocity
			if now - launchedAt > 0.5 and hum.FloorMaterial ~= Enum.Material.Air then
				gliding = false
				sfx("land", 1)
			elseif vel.Y < -K.glideFall then -- the umbrella holds the fall; the move keys carry you across
				local move = hum.MoveDirection * 28
				h.AssemblyLinearVelocity = Vector3.new(vel.X + (move.X - vel.X) * 0.12, -K.glideFall, vel.Z + (move.Z - vel.Z) * 0.12)
			end
			local open = gliding and vel.Y < 6
			if open and not brolly.Parent then brolly.Parent = fxFolder elseif not open and brolly.Parent then brolly.Parent = nil end
			if open then brolly:PivotTo(CFrame.new(h.Position + Vector3.new(0, 3.6, 0)) * CFrame.Angles(0, now * 0.6, 0) * CFrame.Angles(math.sin(now * 3) * 0.06, 0, 0)) end
		elseif brolly.Parent then
			brolly.Parent = nil
		end
	end)

	-- fossil brushing
	local COLS, ROWS, SHAPE = 6, 5, { [8] = 1, [9] = 1, [10] = 1, [14] = 1, [16] = 1, [17] = 1, [20] = 1, [21] = 1, [22] = 1, [23] = 1, [27] = 1 } -- the amber shape's cells (1..30, row by row): a curled shell
	local win = E.panel(E.gui, E.S(560, 430), E.S(640, 300), Vector2.new(0.5, 0.5), "panel")
	E.fit(win, 560, 430)
	win.Name, win.Visible, win.ZIndex = "FossilPanel", false, 30
	if E.addModal then E.addModal(win) end
	E.ribbonTitle(win, "OLD FOSSIL", "ribbonLilac", 0.6)
	local close = E.closeButton(win, "FossilClose")
	pcall(function() close.Modal = true end) -- frees the first-person mouse while the panel is up
	local hint = text(win, "", UDim2.fromScale(0.86, 0.07), UDim2.fromScale(0.5, 0.17), Vector2.new(0.5, 0.5), E.INK, 700, false)
	local board = new("Frame", win, { Size = UDim2.fromScale(0.76, 0.62), Position = UDim2.fromScale(0.5, 0.55), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.fromRGB(104, 52, 46), BorderSizePixel = 0, ZIndex = 31, Active = true })
	new("UIAspectRatioConstraint", board, { AspectRatio = COLS / ROWS })
	new("UICorner", board, { CornerRadius = UDim.new(0.03, 0) })
	local pips = {}
	for k = 1, 3 do
		pips[k] = new("Frame", win, { Size = UDim2.fromScale(0.03, 0.04), Position = UDim2.fromScale(0.44 + (k - 1) * 0.06, 0.93), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = E.MINT, BorderSizePixel = 0, ZIndex = 31 })
		new("UICorner", pips[k], { CornerRadius = UDim.new(1, 0) })
	end
	local tiles, job = {}, nil -- job = { i, left, cracks, last, lastT, acc, tile, roughAt }
	for n = 1, COLS * ROWS do
		local col, row = (n - 1) % COLS, (n - 1) // COLS
		local at, size = UDim2.fromScale((col + 0.5) / COLS, (row + 0.5) / ROWS), UDim2.fromScale(1 / COLS, 1 / ROWS)
		if SHAPE[n] then
			local a = new("Frame", board, { Size = UDim2.fromScale(0.86 / COLS, 0.86 / ROWS), Position = at, AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = AMBER, BorderSizePixel = 0, ZIndex = 32 })
			new("UICorner", a, { CornerRadius = UDim.new(0.2, 0) })
			new("Frame", a, { Size = UDim2.fromScale(0.4, 0.4), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = CREAM, BackgroundTransparency = 0.35, BorderSizePixel = 0, ZIndex = 33 })
		end
		tiles[n] = { f = new("Frame", board, { Size = UDim2.fromScale(0.94 / COLS, 0.94 / ROWS), Position = at, AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = (col + row) % 2 == 0 and CLAY_L or CLAY, BorderSizePixel = 0, ZIndex = 34 }), hp = 3 }
	end
	for _, tl in tiles do new("UICorner", tl.f, { CornerRadius = UDim.new(0.16, 0) }) new("UIStroke", tl.f, { Color = Color3.fromRGB(104, 52, 46), Thickness = 2 }) end
	local brush = new("Frame", board, { Name = "Brush", Size = UDim2.fromScale(0.07, 0.16), AnchorPoint = Vector2.new(0.5, 0.2), BackgroundColor3 = Color3.fromRGB(92, 62, 48), BorderSizePixel = 0, ZIndex = 36, Rotation = 28, Visible = false }) -- the brush under the pointer: a handle and pale bristles
	new("UICorner", brush, { CornerRadius = UDim.new(0.3, 0) })
	new("Frame", brush, { Size = UDim2.fromScale(1.5, 0.34), Position = UDim2.fromScale(0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = CREAM, BorderSizePixel = 0, ZIndex = 37 })
	local function shut(msg, color)
		job = nil
		E.closePanel(win)
		if msg then toast(msg, color or E.PINK, false) end
	end
	close.Activated:Connect(function() shut() end)
	local function show()
		local left = 0
		for n in SHAPE do if tiles[n].hp > 0 then left += 1 end end
		job.left = left
		hint.Text = left > 0 and ("Slow, gentle strokes.  " .. left .. " to uncover") or "Uncovered!"
		for k = 1, 3 do pips[k].BackgroundColor3 = k <= 3 - job.cracks and E.MINT or E.PINK end
	end
	local function stroke(pos)
		local now = os.clock()
		local rel = (pos - board.AbsolutePosition) / board.AbsoluteSize
		brush.Visible, brush.Position = true, UDim2.fromScale(rel.X, rel.Y)
		local last, dt = job.last, now - (job.lastT or now)
		job.last, job.lastT = pos, now
		if rel.X < 0 or rel.X >= 1 or rel.Y < 0 or rel.Y >= 1 then job.tile = nil return end
		local n = math.floor(rel.Y * ROWS) * COLS + math.floor(rel.X * COLS) + 1
		local moved = last and (pos - last).Magnitude or 0
		local speed = dt > 0 and moved / dt / board.AbsoluteSize.X or 0 -- board widths per second
		if speed > 4.5 and now >= (job.roughAt or 0) then -- too rough: a crack
			job.roughAt = now + 0.7
			job.cracks += 1
			sfx("error", 1)
			E.pop(board, 1.05, 0.25)
			hint.Text = "TOO ROUGH! SLOW STROKES"
			if job.cracks >= 3 then shut("The fossil cracked. Try again, gently.") return end
			for k = 1, 3 do pips[k].BackgroundColor3 = k <= 3 - job.cracks and E.MINT or E.PINK end
			return
		end
		if n ~= job.tile then job.tile, job.acc = n, 0 end
		job.acc += moved
		local tl = tiles[n]
		if tl.hp > 0 and job.acc >= board.AbsoluteSize.X / COLS * 0.9 then -- one stroke: about a tile's width of travel
			job.acc = 0
			tl.hp -= 1
			tl.f.BackgroundTransparency = ({ [2] = 0.35, [1] = 0.7, [0] = 1 })[tl.hp]
			sfx("step", 1.5 + (3 - tl.hp) * 0.15)
			show()
			if job.left == 0 then
				sfx("claim", 1.1)
				if remote then remote:FireServer("fossil", job.i) end
				job = nil
			end
		end
	end
	local held = false
	UIS.InputBegan:Connect(function(io)
		if job and (io.UserInputType == Enum.UserInputType.MouseButton1 or io.UserInputType == Enum.UserInputType.Touch) then
			held = true
			job.last, job.lastT = Vector2.new(io.Position.X, io.Position.Y), os.clock()
		end
	end)
	UIS.InputEnded:Connect(function(io)
		if io.UserInputType == Enum.UserInputType.MouseButton1 or io.UserInputType == Enum.UserInputType.Touch then held = false end
	end)
	UIS.InputChanged:Connect(function(io)
		if job and held and (io.UserInputType == Enum.UserInputType.MouseMovement or io.UserInputType == Enum.UserInputType.Touch) then
			stroke(Vector2.new(io.Position.X, io.Position.Y))
		end
	end)
	E.vmHook.fossilStroke = function(x, y) if job then stroke(board.AbsolutePosition + board.AbsoluteSize * Vector2.new(x, y)) end end -- for the Play test

	-- Echo Tap: five drums in a row. Tap one: the server says how far the hollow drum is. Near = a deep note and a wide ring.
	local ewin = E.panel(E.gui, E.S(600, 300), E.S(640, 300), Vector2.new(0.5, 0.5), "panel")
	E.fit(ewin, 600, 300)
	ewin.Name, ewin.Visible, ewin.ZIndex = "EchoPanel", false, 30
	if E.addModal then E.addModal(ewin) end
	E.ribbonTitle(ewin, "ECHO TAP", "ribbonLilac", 0.5)
	local eclose = E.closeButton(ewin, "EchoClose")
	pcall(function() eclose.Modal = true end)
	local ehint = text(ewin, "", UDim2.fromScale(0.88, 0.1), UDim2.fromScale(0.5, 0.26), Vector2.new(0.5, 0.5), E.INK, 700, false)
	local drums, egame = {}, nil -- egame = { i, left, busy }
	for k = 1, 5 do
		local b = new("TextButton", ewin, { Text = "", AutoButtonColor = false, Size = UDim2.fromScale(0.14, 0.46), Position = UDim2.fromScale(0.5 + (k - 3) * 0.17, 0.62), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = k % 2 == 0 and CREAM or CLAY_L, BorderSizePixel = 0, ZIndex = 31 })
		new("UICorner", b, { CornerRadius = UDim.new(0.2, 0) })
		new("UIStroke", b, { Color = Color3.fromRGB(104, 52, 46), Thickness = 3 })
		-- a drum, not a chip: a pale skin on top, two dark hoops and a stand line
		local head = new("Frame", b, { Size = UDim2.fromScale(0.86, 0.2), Position = UDim2.fromScale(0.5, 0.13), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.fromRGB(250, 240, 220), BorderSizePixel = 0, ZIndex = 32 })
		new("UICorner", head, { CornerRadius = UDim.new(0.5, 0) })
		new("UIStroke", head, { Color = Color3.fromRGB(104, 52, 46), Thickness = 2 })
		for _, y in { 0.34, 0.86 } do new("Frame", b, { Size = UDim2.fromScale(1, 0.05), Position = UDim2.fromScale(0.5, y), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.fromRGB(104, 52, 46), BorderSizePixel = 0, ZIndex = 32 }) end
		local ring = new("Frame", b, { Size = UDim2.fromScale(0.2, 0.2), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, ZIndex = 32 })
		new("UIAspectRatioConstraint", ring, { AspectRatio = 1 })
		new("UICorner", ring, { CornerRadius = UDim.new(1, 0) })
		local rs = new("UIStroke", ring, { Color = AMBER, Thickness = 4, Transparency = 1 })
		drums[k] = { b = b, ring = ring, stroke = rs }
		b.Activated:Connect(function()
			if not egame or egame.busy or not remote then return end
			egame.busy = true
			remote:FireServer("echo", egame.i, k)
		end)
	end
	eclose.Activated:Connect(function()
		egame = nil
		E.closePanel(ewin)
	end)
	local function ringOut(k, off, color) -- the ring grows wider the nearer the hollow drum is
		local d = drums[k]
		d.stroke.Color, d.stroke.Transparency = color or AMBER, 0
		d.ring.Size = UDim2.fromScale(0.2, 0.2)
		local wide = 2.6 - math.min(off, 4) * 0.5
		tween(d.ring, 0.5, { Size = UDim2.fromScale(wide, wide) })
		tween(d.stroke, 0.5, { Transparency = 1 })
		E.pop(d.b, 0.9, 0.25)
	end

	local LINES = {
		"Kiln Keeper: \"Mind the vents. They throw you to the roof.\"", "Kiln Keeper: \"Old jars hide older things. Smash a few.\"",
		"Kiln Keeper: \"Brush the pale slabs gently. Fossils crack.\"", "Kiln Keeper: \"The kiln stays lit. You are safe in my ring.\"",
	}
	local line = 0
	game:GetService("ProximityPromptService").PromptTriggered:Connect(function(prompt)
		if prompt:GetAttribute("Keeper") then
			line = line % #LINES + 1
			sfx("pluck", 0.7)
			toast(LINES[line], CREAM, false)
		end
	end)

	E.R.State.OnClientEvent:Connect(function(st) -- a player who freed the critter on an earlier visit finds the cage open and empty
		local f = clay()
		local cage = f and f:FindFirstChild("CritterCage")
		if not cage or cage:GetAttribute("Open") or not (st and st.tips and st.tips.critter1) then return end
		cage:SetAttribute("Open", true)
		for _, p in cage:GetChildren() do if p.Name == "CageBar" or p.Name == "Critter" then p.Transparency = 1 end end
		local pr = cage:FindFirstChildWhichIsA("ProximityPrompt", true)
		if pr then pr.Enabled = false end
	end)
	E.vmHook.echoTap = function(k) if drums[k] and egame and not egame.busy and remote then egame.busy = true remote:FireServer("echo", egame.i, k) end end
	E.R.Fx.OnClientEvent:Connect(function(kind, a, b, c, d)
		if kind == "clayTravel" then
			fade.Visible = true
			tween(fade, 0.3, { BackgroundTransparency = 0 })
			sfx("open", 0.6)
			local rode = not calm and tunnelRide(a == 2) -- a 2.3 s cart ride through a clay tunnel (down, or back up)
			task.delay(rode and 2.75 or 0.8, function()
				tween(fade, 0.7, { BackgroundTransparency = 1 })
				task.delay(0.72, function() fade.Visible = false end)
				toast(a == 2 and "THE CLAY CAVES  -  KILN CAMP" or "BACK AT CAMP 1", CREAM, true)
			end)
		elseif kind == "jar" then
			local f = clay()
			for _, m in f and f:GetChildren() or {} do
				if m:GetAttribute("Jar") == a then
					local parts, pr = {}, m:FindFirstChildWhichIsA("ProximityPrompt", true)
					for _, p in m:GetChildren() do if p:IsA("BasePart") then parts[p] = p.CanCollide p.Transparency, p.CanCollide = 1, false end end
					if pr then pr.Enabled = false end
					if E.burst and m.PrimaryPart then
						E.burst(m.PrimaryPart.Position, Vector3.yAxis, CLAY_L, 22)
						E.burst(m.PrimaryPart.Position, Vector3.yAxis, CREAM, 8)
					end
					task.delay(d or K.jarEvery, function() -- the jar is back for this player
						for p, col in parts do if p.Parent then p.Transparency, p.CanCollide = 0, col end end
						if pr and pr.Parent then pr.Enabled = true end
					end)
				end
			end
			sfx("breakRock", 1.4)
			toast("CLAY JAR  +" .. b .. " COINS", E.GOLD, false)
			if c then toast("RELIC SHARD!  YOU HOLD " .. c, AMBER, true) end
			if E.fly then
				local vp = workspace.CurrentCamera.ViewportSize
				E.fly("coin", UDim2.fromOffset(vp.X / 2, vp.Y * 0.55), E.goldPill, 6, 0.05)
			end
		elseif kind == "echoStart" then
			egame = { i = a, left = b }
			ehint.Text = "One drum is hollow. Deep note, wide ring = close.  " .. b .. " taps"
			E.openPanel(ewin)
		elseif kind == "echoEmpty" then
			toast("This wall is quiet for " .. a .. " more min.", CREAM, false)
		elseif kind == "echoTap" then -- a = the drum, b = how far off, c = coins on a find (-1 = out of taps), d = where it was
			if not egame then return end
			egame.busy = false
			if b == 0 then
				sfx("upgrade", 0.6)
				sfx("claim", 1)
				ringOut(a, 0, E.MINT)
				ehint.Text = "HOLLOW!  +" .. c .. " COINS"
				local done = egame
				egame = nil
				task.delay(1.1, function()
					E.closePanel(ewin)
					toast("ECHO TAP  +" .. c .. " COINS", E.GOLD, true)
					if E.fly then
						local vp = workspace.CurrentCamera.ViewportSize
						E.fly("coin", UDim2.fromOffset(vp.X / 2, vp.Y / 2), E.goldPill, 8, 0.05)
					end
				end)
			else
				sfx("land", 1.5 - (4 - math.min(b, 4)) * 0.22) -- nearer = a deeper thud
				ringOut(a, b)
				egame.left -= 1
				if c == -1 then
					ringOut(d, 0, E.PINK)
					ehint.Text = "Out of taps. It was this one."
					egame = nil
					task.delay(1.4, function() E.closePanel(ewin) end)
				else
					ehint.Text = (b == 1 and "Very close!  " or (b == 2 and "Close.  " or "Far.  ")) .. egame.left .. " taps left"
				end
			end
		elseif kind == "fossilBrush" then
			for _, tl in tiles do tl.hp, tl.f.BackgroundTransparency = 3, 0 end
			job = { i = a, cracks = 0, acc = 0 }
			show()
			E.openPanel(win)
		elseif kind == "clayEgg" then
			if a then
				sfx("coin", 0.9)
				toast("KILN EGG BOUGHT!  HATCH IT IN TOWN", CREAM, true)
				if E.vmHook.emote then E.vmHook.emote("cheer") end
			else
				sfx("error", 1)
				toast("You need " .. b .. " more coins for the egg.", E.PINK, false)
			end
		elseif kind == "critter" then
			local f = clay()
			local cage = f and f:FindFirstChild("CritterCage")
			if a and cage then -- the bars drop away, the critter hops out and is gone in a puff
				sfx("claim", 1.3)
				for _, p in cage:GetChildren() do
					if p.Name == "CageBar" then tween(p, 0.4, { Transparency = 1 }) end
					if p.Name == "Critter" then
						tween(p, 0.5, { CFrame = p.CFrame + Vector3.new(0, 2.5, 3) }, Enum.EasingStyle.Back)
						task.delay(0.55, function() p.Transparency = 1 end)
					end
				end
				task.delay(0.55, function() if E.burst and cage.PrimaryPart then E.burst(cage.PrimaryPart.Position + Vector3.new(0, 3, 3), Vector3.yAxis, Color3.fromRGB(255, 170, 190), 24) end end)
				local pr = cage:FindFirstChildWhichIsA("ProximityPrompt", true)
				if pr then pr.Enabled = false end
				toast("THE CRITTER IS FREE!  IT LEFT YOU AN EGG", CREAM, true)
			else
				toast("The cage is empty. It got away safe.", CREAM, false)
			end
		elseif kind == "secret" then
			if a > 0 then
				sfx("claim", 1.2)
				toast("SECRET LEDGE!  +" .. a .. " GEMS", AMBER, true)
				if E.vmHook.emote then E.vmHook.emote("cheer") end
			else
				toast("The old chest is empty now.", CREAM, false)
			end
		elseif kind == "fossilHave" then
			toast("You already brushed this fossil clean.", CREAM, false)
		elseif kind == "fossilDone" then
			if win.Visible then E.closePanel(win) end
			toast("FOSSIL " .. c .. " / " .. d .. "   +" .. b .. " GEMS", AMBER, true)
			if E.vmHook.emote then E.vmHook.emote("cheer") end
		end
	end)
end

return M
