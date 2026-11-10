-- WorldFX (ReplicatedStorage.Shared.WorldFX), started by PixelClient: the playtest 2 VFX and motion sheet (board PT2_VFX; the user,
-- 2026-11-09: "the final version ... should also include a large amount of extra vfx and animations"). Client-only life in the world:
-- the daily chest hovers with turning rays, signs sway, NPCs breathe, blink and wave, Bolt nods when he buys ore, nest eggs rock and
-- chime when you come near, dust motes float in the torchlight, banked ore streams into the camp fire, a fall or a faint wakes you
-- with a groggy tilt, and the screen edges soften around a minigame. Every effect is cosmetic; the server decides nothing here.
local M = {}

function M.start(E)
	local R, plr, sfx, toast, burst, tween, new, isBusy = E.R, E.plr, E.sfx, E.toast, E.burst, E.tween, E.new, E.isBusy
	local RunService = game:GetService("RunService")
	local cam = workspace.CurrentCamera
	local RAYS = "rbxassetid://98789616938156" -- feathered rays (art/forge/fx)
	local calm = false -- reduced motion: set from the player's setting when there is one
	pcall(function() calm = game:GetService("GuiService").ReducedMotionEnabled end)

	-- hub pieces (the server rebuilds the hub at start, so find them lazily)
	local hubState = { ready = false }
	local function scanHub()
		local hub = workspace:FindFirstChild("Hub")
		if not hub then return end
		hubState.ready = true
		-- the daily chest: hover and rays
		local chest = hub:FindFirstChild("DailyChest", true)
		if chest and chest:IsA("Model") then
			hubState.chest, hubState.chestBase = chest, chest:GetPivot()
			local core = chest:FindFirstChild("Chest")
			if core then
				local bb = new("BillboardGui", core, { Name = "ChestRays", Size = UDim2.fromScale(9, 9), LightInfluence = 0, AlwaysOnTop = false, MaxDistance = 140 })
				hubState.rays = new("ImageLabel", bb, { Image = RAYS, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ImageColor3 = Color3.fromRGB(255, 226, 140), ImageTransparency = 0.55 })
			end
		end
		-- signs: each plate sways a little about its top edge
		hubState.signs = {}
		for _, d in hub:GetDescendants() do
			if d:IsA("BasePart") and (d.Name == "Sign" or d.Name == "SignFrame" or d.Name == "SignTrim") then
				local top = d.CFrame * CFrame.new(0, d.Size.Y / 2, 0)
				table.insert(hubState.signs, { p = d, top = top, off = top:ToObjectSpace(d.CFrame), seed = (d.Position.X + d.Position.Z) * 0.13 })
			end
		end
		-- NPCs built from parts (Bolt, Maribel, Pip): breathing, blinks, a wave when you come near
		hubState.npcs = {}
		for _, n in { "Bolt", "Maribel", "Pip" } do
			local m = hub:FindFirstChild(n, true)
			if m and m:IsA("Model") then
				local parts = {}
				for _, p in m:GetChildren() do
					if p:IsA("BasePart") then table.insert(parts, { p = p, cf = p.CFrame, size = p.Size, name = p.Name }) end
				end
				local body = m:FindFirstChild("Body")
				table.insert(hubState.npcs, { m = m, parts = parts, body = body, seed = #hubState.npcs * 1.7, wave = 0, nod = 0 })
			end
		end
	end

	-- caves pieces
	local caveState = { nests = {}, chimed = {} }
	local function scanCaves()
		local caves = workspace:FindFirstChild("Caves")
		if not caves then return end
		caveState.caves = caves
		local nests = caves:FindFirstChild("Nests")
		for _, d in nests and nests:GetChildren() or {} do
			if d.Name == "NestEgg" and d:IsA("BasePart") then table.insert(caveState.nests, { p = d, cf = d.CFrame, seed = #caveState.nests * 2.3 }) end
		end
		caveState.flame = caves:FindFirstChild("Flame", true)
	end

	-- dust motes that float in the torchlight around you (caves only)
	local moteAnchor = new("Part", nil, { Name = "DustMotes", Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Transparency = 1, Size = Vector3.new(14, 6, 14) })
	local motes = new("ParticleEmitter", moteAnchor, {
		Rate = 10, Lifetime = NumberRange.new(4, 7), Speed = NumberRange.new(0.05, 0.25), SpreadAngle = Vector2.new(180, 180),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.3, 0.07), NumberSequenceKeypoint.new(1, 0) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.35), NumberSequenceKeypoint.new(1, 1) }),
		Color = ColorSequence.new(Color3.fromRGB(255, 236, 210)), LightInfluence = 1, LightEmission = 0.2, RotSpeed = NumberRange.new(-20, 20),
		Shape = Enum.ParticleEmitterShape.Box, ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume, Acceleration = Vector3.new(0, 0.02, 0),
	})
	motes.Enabled = false

	-- the minigame vignette: four soft edges that close in while a minigame holds you
	local vg = new("ScreenGui", plr:WaitForChild("PlayerGui"), { Name = "WorldFXGui", IgnoreGuiInset = true, ResetOnSpawn = false, DisplayOrder = 1 })
	local edges = {}
	for i, e in { { UDim2.fromScale(1, 0.22), UDim2.fromScale(0, 0), 90 }, { UDim2.fromScale(1, 0.22), UDim2.fromScale(0, 0.78), -90 }, { UDim2.fromScale(0.18, 1), UDim2.fromScale(0, 0), 0 }, { UDim2.fromScale(0.18, 1), UDim2.fromScale(0.82, 0), 180 } } do
		local f = new("Frame", vg, { Size = e[1], Position = e[2], BackgroundColor3 = Color3.fromRGB(16, 10, 28), BorderSizePixel = 0, BackgroundTransparency = 1 })
		new("UIGradient", f, { Rotation = e[3], Transparency = NumberSequence.new(0, 1) })
		edges[i] = f
	end
	local vgOn = 0

	-- groggy wake after a fall or a faint
	local grogUntil = 0
	R.Fx.OnClientEvent:Connect(function(kind, a)
		if kind == "drowned" then
			grogUntil = os.clock() + 2.6
		elseif kind == "soldPick" then -- Bolt nods and his eyes sparkle when he buys your ore
			for _, n in hubState.npcs or {} do
				if n.m.Name == "Bolt" then
					n.nod = os.clock()
					if burst and n.body then burst(n.body.Position + Vector3.new(0, 4, 0), Vector3.yAxis, Color3.fromRGB(255, 230, 150), 14) end
				end
			end
		elseif kind == "sold" and plr:GetAttribute("InCave") and caveState.flame then -- banked ore streams into the camp fire
			local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
			if root then
				for k = 1, 8 do
					task.delay(k * 0.05, function()
						local orb = new("Part", workspace, { Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Shape = Enum.PartType.Ball, Size = Vector3.one * 0.5, Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 214, 140), CFrame = CFrame.new(root.Position + Vector3.new(math.random() - 0.5, 1, math.random() - 0.5)) })
						local from, to = orb.Position, caveState.flame.Position
						local mid = (from + to) / 2 + Vector3.new(0, 5, 0)
						local t0 = os.clock()
						local c
						c = RunService.Heartbeat:Connect(function()
							local u = math.min((os.clock() - t0) / 0.55, 1)
							orb.Position = (1 - u) ^ 2 * from + 2 * (1 - u) * u * mid + u * u * to
							if u >= 1 then
								c:Disconnect()
								orb:Destroy()
							end
						end)
					end)
				end
				task.delay(0.6, function() if burst then burst(caveState.flame.Position, Vector3.yAxis, Color3.fromRGB(255, 200, 120), 20) end end)
			end
		end
	end)

	local lastScan = 0
	RunService:BindToRenderStep("WorldFX", Enum.RenderPriority.Camera.Value + 30, function()
		local now = os.clock()
		if now - lastScan > 3 then -- the hub and caves are built by the server after join
			lastScan = now
			if not hubState.ready then scanHub() end
			if not caveState.caves then scanCaves() end
		end
		local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
		local inCave = plr:GetAttribute("InCave") == true

		-- the chest hovers and its rays turn
		if hubState.chest and not inCave then
			hubState.chest:PivotTo(hubState.chestBase * CFrame.new(0, calm and 0 or 0.12 + math.sin(now * 1.8) * 0.12, 0))
			if hubState.rays then hubState.rays.Rotation = (now * 14) % 360 end
		end
		-- signs sway
		if not inCave and not calm then
			for _, s in hubState.signs or {} do
				s.p.CFrame = s.top * CFrame.Angles(math.sin(now * 1.3 + s.seed) * 0.035, 0, math.sin(now * 0.9 + s.seed) * 0.02) * s.off
			end
		end
		-- NPCs breathe, blink, wave at you within 10 studs; Bolt nods after a sale
		if not inCave then
			for _, n in hubState.npcs or {} do
				local near = root and n.body and (root.Position - n.body.Position).Magnitude < 10
				n.wave = math.clamp(n.wave + (near and 1 or -1) * (1 / 60) * 3, 0, 1)
				local breathe = calm and 0 or math.sin(now * 2.2 + n.seed) * 0.05
				local nod = math.max(0, 1 - (now - n.nod) / 0.7)
				local blink = ((now + n.seed) % 3.9) < 0.12
				for _, q in n.parts do
					local up = (q.name == "Leg") and 0 or breathe
					local cf = q.cf + Vector3.new(0, up, 0)
					if q.name == "Head" or q.name == "Mask" or q.name == "Eye" or q.name == "Pupil" or q.name == "Ear" or q.name == "EarIn" or q.name == "Bang" or q.name == "Hair" then
						cf = cf * CFrame.Angles(math.sin(nod * math.pi * 2) * 0.18 * nod, 0, 0)
					end
					if (q.name == "Eye" or q.name == "Pupil") then q.p.Size = Vector3.new(q.size.X, blink and 0.05 or q.size.Y, q.size.Z) end
					if q.name == "Arm" and n.body and q.cf.Position.X > n.body.Position.X == (n.m.Name ~= "Bolt") then -- one arm waves
						local pivot = q.cf * CFrame.new(0, q.size.Y / 2, 0)
						cf = pivot * CFrame.Angles(0, 0, n.wave * (2.4 + math.sin(now * 9) * 0.35) * (q.cf.Position.X > n.body.Position.X and 1 or -1)) * CFrame.new(0, -q.size.Y / 2, 0) + Vector3.new(0, up, 0)
					end
					q.p.CFrame = cf
				end
			end
		end

		-- caves: nest eggs rock and chime once when you come near; dust motes around you
		if inCave and root then
			for i, e in caveState.nests do
				if e.p.Parent then
					local wob = (now + e.seed) % 4 < 0.8 and math.sin((now + e.seed) % 4 / 0.8 * math.pi * 3) * 0.14 or 0
					e.p.CFrame = e.cf * CFrame.Angles(wob, 0, wob * 0.6)
					if not caveState.chimed[i] and (e.p.Position - root.Position).Magnitude < 30 then
						caveState.chimed[i] = true
						sfx("sparkle", 0.8)
						task.delay(0.25, function() sfx("sparkle", 1.2) end)
						toast("A soft chime... an egg nest is close!", Color3.fromRGB(255, 196, 220), false)
					end
				end
			end
			moteAnchor.Parent = workspace
			moteAnchor.CFrame = CFrame.new(root.Position + Vector3.new(0, 1.5, 0))
			motes.Enabled = true
		else
			motes.Enabled = false
		end

		-- the minigame vignette
		vgOn += ((isBusy() and 1 or 0) - vgOn) * 0.12
		for _, f in edges do f.BackgroundTransparency = 1 - vgOn * 0.55 end

		-- groggy wake: the view rolls and settles
		if now < grogUntil and not calm then
			local k = (grogUntil - now) / 2.6
			cam.CFrame = cam.CFrame * CFrame.Angles(0, 0, math.sin(now * 3) * 0.12 * k)
		end
	end)
end

return M
