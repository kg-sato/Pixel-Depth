-- BossPhases (ReplicatedStorage.Shared.BossPhases), started by PixelClient. The three-phase boss fights (2026-11-27, vault
-- Briefs/Progression and Boss Fight Overhaul 2.1-2.2): draws what ServerScriptService.Boss decides. Phase banners (ENRAGED,
-- OVERDRIVE) with a warm grade on the screen; the open core after a slam (a glowing voxel heart and STAGGER WINDOW); the stagger
-- itself; the Root Warden's ROOT WALL SNARE (cracks, then three thorn pillars that block you on this screen and burn away under
-- a flare); the Kiln Golem's MAGMA RAIN (shadow rings, then falling magma cubes) and LAVA TIDE (two steam vents puff, then a low
-- glowing ring rolls out); the shatter finisher (1.5 s of slow voxel burst) and the relic chest's haul. Shared.BossClient keeps
-- the bar, the slam, sweep and rings. Reduced Motion skips the shakes and the slow motion. Display only.
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local M = {}
local NAMES = { "Warden", "KilnGolem" }
local AMBER, CYAN, CRIMSON, GOLD = Color3.fromRGB(255, 186, 92), Color3.fromRGB(110, 240, 255), Color3.fromRGB(255, 70, 90), Color3.fromRGB(255, 214, 107)

function M.start(E)
	local calm = false
	pcall(function() calm = game:GetService("GuiService").ReducedMotionEnabled end)
	local folder = Instance.new("Folder")
	folder.Name = "BossPhasesFX"
	folder.Parent = workspace
	local function boss(id) return workspace:FindFirstChild("Caves") and workspace.Caves:FindFirstChild(NAMES[id] or "Warden", true) end
	local function floorUnder(p)
		local rp = RaycastParams.new()
		rp.FilterType = Enum.RaycastFilterType.Exclude
		rp.FilterDescendantsInstances = { folder, E.plr.Character, workspace.CurrentCamera }
		local h = workspace:Raycast(p + Vector3.new(0, 4, 0), Vector3.new(0, -40, 0), rp)
		return h and h.Position or p
	end
	local function part(props)
		local q = Instance.new("Part")
		q.Anchored, q.CanCollide, q.CanQuery, q.CanTouch, q.CastShadow = true, false, false, false, false
		q.Material = Enum.Material.SmoothPlastic
		for k, v in props do q[k] = v end
		q.Parent = props.Parent or folder
		return q
	end
	local function shake(a) if not calm and E.shake then pcall(E.shake, a) end end
	-- a big word in the upper third
	local banner = E.text(E.gui, "", E.S(620, 70), E.S(640, 232), Vector2.new(0.5, 0.5), AMBER, 700, false)
	banner.Name, banner.Visible, banner.Font, banner.ZIndex = "BossPhaseBanner", false, Enum.Font.FredokaOne, 30
	local bs = Instance.new("UIStroke")
	bs.Color, bs.Thickness = Color3.fromRGB(30, 10, 20), 4
	bs.Parent = banner
	local bScale = Instance.new("UIScale")
	bScale.Parent = banner
	local bannerToken = 0
	local function say(t, color, hold)
		bannerToken += 1
		local my = bannerToken
		banner.Text, banner.TextColor3, banner.Visible = t, color, true
		bScale.Scale = 1.6
		TweenService:Create(bScale, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
		task.delay(hold or 1.6, function() if bannerToken == my then banner.Visible = false end end)
	end
	local grade = Instance.new("ColorCorrectionEffect")
	grade.Name, grade.Enabled = "BossPhaseGrade", false
	grade.Parent = Lighting
	local function burst(at, color, n, speed, life)
		for k = 1, n do
			local q = part({ Size = Vector3.one * (0.35 + (k % 3) * 0.2), Material = Enum.Material.Neon, Color = k % 4 == 0 and Color3.new(1, 1, 1) or color, CFrame = CFrame.new(at) })
			local dir = Vector3.new(math.random() - 0.5, math.random() * 0.9 + 0.1, math.random() - 0.5).Unit * (speed * (0.6 + math.random() * 0.6))
			local t0 = os.clock()
			local c
			c = RunService.Heartbeat:Connect(function()
				local u = os.clock() - t0
				if u > life or not q.Parent then c:Disconnect() q:Destroy() return end
				q.CFrame = CFrame.new(at + dir * u + Vector3.new(0, -18 * u * u, 0)) * CFrame.Angles(u * 5, u * 3, 0)
				q.Transparency = u / life
			end)
		end
	end
	local snares = {}
	local function clearSnares(burn)
		for _, p in snares do
			if p.Parent then
				if burn then burst(p.Position, Color3.fromRGB(255, 140, 50), 10, 14, 0.6) end
				p:Destroy()
			end
		end
		table.clear(snares)
	end
	E.R.Fx.OnClientEvent:Connect(function(kind, a, b, c, d, e)
		if kind == "bossPhase" then
			say(a == 2 and "PHASE 2: ENRAGED!" or "PHASE 3: OVERDRIVE!", a == 2 and Color3.fromRGB(255, 120, 90) or CRIMSON, 1.8)
			grade.Enabled, grade.TintColor, grade.Saturation = true, a == 2 and Color3.fromRGB(255, 226, 214) or Color3.fromRGB(255, 205, 200), 0.12
			E.sfx("breakRock", 0.6)
			shake(0.6)
		elseif kind == "bossCore" then -- the open core: a glowing voxel heart on the boss's chest for a seconds
			local w = boss(b)
			if not (w and w.PrimaryPart) then return end
			local pp = w.PrimaryPart
			local core = part({ Name = "OpenCore", Size = Vector3.new(1.6, 1.6, 1.6), Material = Enum.Material.Neon, Color = CYAN, CFrame = pp.CFrame * CFrame.new(0, pp.Size.Y * 0.15, -pp.Size.Z / 2 - 0.6) })
			local ring = part({ Name = "OpenCoreRim", Size = Vector3.new(2.6, 2.6, 0.3), Material = Enum.Material.Neon, Color = GOLD, Transparency = 0.35, CFrame = core.CFrame })
			local l = Instance.new("PointLight")
			l.Color, l.Range, l.Brightness = CYAN, 16, 2
			l.Parent = core
			say("STAGGER WINDOW!  FLARE THE CORE [R]", CYAN, math.min(a, 2.6))
			local t0 = os.clock()
			local conn
			conn = RunService.RenderStepped:Connect(function()
				local u = os.clock() - t0
				if u > a or not core.Parent then conn:Disconnect() core:Destroy() ring:Destroy() return end
				local base = pp.CFrame * CFrame.new(0, pp.Size.Y * 0.15, -pp.Size.Z / 2 - 0.6)
				core.CFrame = base * CFrame.Angles(u * 2, u * 3, 0)
				ring.CFrame = base * CFrame.Angles(0, 0, u * 1.5)
				core.Size = Vector3.one * (1.6 + 0.25 * math.sin(u * 14))
			end)
		elseif kind == "bossStagger" then
			say("STAGGERED!  x2 DAMAGE", GOLD, 2)
			E.sfx("upgrade", 0.7)
			shake(0.8)
			local w = boss(b)
			if w and w.PrimaryPart then burst(w.PrimaryPart.Position, GOLD, 22, 22, 0.7) end
			if c then clearSnares(true) end
		elseif kind == "bossSnare" then -- a = landing time, b = three points, c = boss id
			clearSnares(false)
			local land = a
			local warns = {}
			for _, p in b do
				local f = floorUnder(p)
				table.insert(warns, part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.15, 6.6, 6.6), Material = Enum.Material.Neon, Color = Color3.fromRGB(150, 255, 120), Transparency = 0.5, CFrame = CFrame.new(f + Vector3.new(0, 0.12, 0)) * CFrame.Angles(0, 0, math.pi / 2) }))
			end
			say("ROOT WALL SNARE!  STEP AWAY", Color3.fromRGB(170, 255, 140), 1.2)
			task.delay(math.max(0, land - workspace:GetServerTimeNow()), function()
				for _, wp in warns do wp:Destroy() end
				for _, p in b do -- a thorn pillar of stacked bark blocks with spikes, rising out of the floor
					local f = floorUnder(p)
					local pieces = {}
					for k = 0, 3 do
						local sz = 3.4 - k * 0.6
						table.insert(pieces, part({ Name = "Snare", Size = Vector3.new(sz, 2.2, sz), Material = Enum.Material.Wood, Color = Color3.fromRGB(70 + k * 8, 48, 36), CanCollide = true, CFrame = CFrame.new(f + Vector3.new(0, -8 + k * 2.1, 0)) * CFrame.Angles(0, k * 0.4, 0) }))
					end
					for k = 1, 4 do
						local a2 = k * math.pi / 2
						table.insert(pieces, part({ Name = "SnareThorn", Size = Vector3.new(0.5, 0.5, 1.8), Material = Enum.Material.Neon, Color = Color3.fromRGB(150, 255, 120), CFrame = CFrame.new(f + Vector3.new(math.cos(a2) * 1.6, -5, math.sin(a2) * 1.6)) * CFrame.Angles(0, -a2, 0.6) }))
					end
					for _, q in pieces do
						table.insert(snares, q)
						TweenService:Create(q, TweenInfo.new(0.25, Enum.EasingStyle.Back), { CFrame = q.CFrame + Vector3.new(0, 8, 0) }):Play()
					end
					burst(f, Color3.fromRGB(120, 90, 60), 8, 12, 0.5)
				end
				E.sfx("breakRock", 0.75)
				shake(0.5)
				task.delay(4, function() clearSnares(false) end)
			end)
		elseif kind == "bossMagma" then -- a = landing time, b = points
			local land = a
			say("MAGMA RAIN!", Color3.fromRGB(255, 140, 60), 1.1)
			for _, p in b do
				local f = floorUnder(p)
				local ring = part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.15, 1, 1), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(30, 10, 10), Transparency = 0.3, CFrame = CFrame.new(f + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, 0, math.pi / 2) })
				local bomb = part({ Size = Vector3.new(1.6, 1.6, 1.6), Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 110, 40), CFrame = CFrame.new(f + Vector3.new(0, 34, 0)) })
				local t0, dur = os.clock(), math.max(0.2, land - workspace:GetServerTimeNow())
				local conn
				conn = RunService.Heartbeat:Connect(function()
					local u = math.clamp((os.clock() - t0) / dur, 0, 1)
					ring.Size = Vector3.new(0.15, 1 + u * 6, 1 + u * 6)
					bomb.CFrame = CFrame.new(f + Vector3.new(0, 34 * (1 - u * u), 0)) * CFrame.Angles(u * 6, u * 4, 0)
					if u >= 1 then
						conn:Disconnect()
						ring:Destroy()
						bomb:Destroy()
						burst(f + Vector3.new(0, 0.5, 0), Color3.fromRGB(255, 120, 40), 10, 16, 0.6)
						local cinder = part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.12, 7, 7), Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 80, 30), Transparency = 0.5, CFrame = CFrame.new(f + Vector3.new(0, 0.08, 0)) * CFrame.Angles(0, 0, math.pi / 2) })
						TweenService:Create(cinder, TweenInfo.new(1.1), { Transparency = 1 }):Play()
						task.delay(1.2, function() cinder:Destroy() end)
					end
				end)
			end
			task.delay(math.max(0, land - workspace:GetServerTimeNow()), function() E.sfx("breakRock", 0.9) shake(0.35) end)
		elseif kind == "bossTide" then -- a = start time, b = speed (studs a second)
			local w = boss(c)
			if not (w and w.PrimaryPart) then return end
			local o = floorUnder(w.PrimaryPart.Position)
			say("LAVA TIDE!  JUMP OR GLIDE OVER IT", Color3.fromRGB(255, 150, 60), 1.3)
			local look = w.PrimaryPart.CFrame.RightVector * Vector3.new(1, 0, 1)
			for _, sd in { -1, 1 } do -- two steam vents puff at the arena's edge: their updraft carries a glider over the tide
				local v = o + look.Unit * sd * 16
				for k = 1, 8 do
					task.delay(k * 0.06, function() burst(v + Vector3.new(0, 0.5, 0), Color3.fromRGB(240, 236, 230), 2, 10, 1.1) end)
				end
			end
			local ring = part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.2, 1, 1), Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 100, 30), Transparency = 0.2, CFrame = CFrame.new(o + Vector3.new(0, 0.6, 0)) * CFrame.Angles(0, 0, math.pi / 2) })
			local inner = part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.3, 1, 1), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(40, 14, 10), CFrame = ring.CFrame })
			local conn
			conn = RunService.Heartbeat:Connect(function()
				local t = workspace:GetServerTimeNow() - a
				if t < 0 then return end
				local r = t * b
				if r > 44 then conn:Disconnect() ring:Destroy() inner:Destroy() return end
				ring.Size = Vector3.new(1.2, r * 2 + 2, r * 2 + 2)
				inner.Size = Vector3.new(1.3, math.max(0.5, r * 2 - 2.5), math.max(0.5, r * 2 - 2.5))
			end)
		elseif kind == "bossShatter" then -- the finisher: slow motion, a white flash and the boss bursting into voxels
			local w = boss(a)
			say("SHATTERED!", Color3.new(1, 1, 1), 1.5)
			E.sfx("breakRock", 0.45)
			shake(1)
			local cam = workspace.CurrentCamera
			local fov = cam.FieldOfView
			if not calm then
				TweenService:Create(cam, TweenInfo.new(0.25), { FieldOfView = fov - 10 }):Play()
				task.delay(1.4, function() TweenService:Create(cam, TweenInfo.new(0.4), { FieldOfView = fov }):Play() end)
			end
			grade.Enabled, grade.TintColor, grade.Saturation, grade.Brightness = true, Color3.new(1, 1, 1), 0.4, 0.25
			TweenService:Create(grade, TweenInfo.new(1.5), { Brightness = 0, Saturation = 0 }):Play()
			if w and w.PrimaryPart then
				local at = w.PrimaryPart.Position
				for _, col in { AMBER, Color3.fromRGB(90, 70, 60), CYAN } do burst(at, col, calm and 6 or 18, calm and 10 or 8, 1.5) end -- slow, wide shards: the slow motion
			end
		elseif kind == "bossWin" or kind == "bossLose" then
			grade.Enabled = false
			grade.Brightness, grade.Saturation = 0, 0
			clearSnares(false)
		elseif kind == "bossChest" then -- a = gold, b = gems, c = relic name ("" after the first clear)
			E.toast("RELIC CHEST  +" .. tostring(a) .. " COINS  +" .. tostring(b) .. " GEMS  +2 SHARDS", GOLD, true)
			if c and c ~= "" then say("RELIC: " .. string.upper(c), GOLD, 2.4) end
			if typeof(e) == "Vector3" then burst(e, GOLD, 24, 16, 0.9) end
			E.sfx("coin", 0.8)
		end
	end)
end

return M
