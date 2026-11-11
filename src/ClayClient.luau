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

	local vents, ventsOf = {}, nil
	local function findVents()
		local f = clay()
		if f == ventsOf then return end
		ventsOf, vents = f, {}
		for _, d in f and f:GetDescendants() or {} do
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

	E.R.Fx.OnClientEvent:Connect(function(kind, a, b, c, d)
		if kind == "clayTravel" then
			fade.Visible = true
			tween(fade, 0.3, { BackgroundTransparency = 0 })
			sfx("open", 0.6)
			task.delay(0.8, function()
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
		elseif kind == "fossilBrush" then
			for _, tl in tiles do tl.hp, tl.f.BackgroundTransparency = 3, 0 end
			job = { i = a, cracks = 0, acc = 0 }
			show()
			E.openPanel(win)
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
