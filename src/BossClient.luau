-- BossClient (ReplicatedStorage.Shared.BossClient), started by PixelClient: what the Root Warden fight looks like for the player
-- fighting it (server: ServerScriptService.Boss). The Warden wakes (amber eyes, a rumble), a boss bar shows its knots, each slam
-- is telegraphed (it rises, a pink ring spreads on the floor, JUMP!), cracked knots go dark, and a win opens the Deep Gate:
-- its roots fade and stop colliding for this player (for good once tips.gate1 is saved).
local M = {}

function M.start(E)
	local C = require(script.Parent:WaitForChild("Config"))
	local R, plr, gui, new, S, fit, panel, text, toast, sfx, shake, burst, tween = E.R, E.plr, E.gui, E.new, E.S, E.fit, E.panel, E.text, E.toast, E.sfx, E.shake, E.burst, E.tween
	local INK, PINK, GOLD, MINT = E.INK, E.PINK, E.GOLD, E.MINT
	local AMBER, FIRE = Color3.fromRGB(255, 186, 92), Color3.fromRGB(255, 132, 56)
	-- two bosses share this client (server: Boss.DEFS): every Fx event carries the boss number last, use(id) switches to it
	local NAMES, TITLES = { "Warden", "KilnGolem" }, { "ROOT WARDEN", "KILN GOLEM" }
	local now, bases = 1, {}
	local function warden() return workspace:FindFirstChild("Caves") and workspace.Caves:FindFirstChild(NAMES[now], true) end

	-- the boss frame (phase C, 2026-11-13): a smoked glass bar with the name in jelly and one glass segment per knot
	local bar = panel(gui, S(440, 74), S(640, 70), Vector2.new(0.5, 0.5), "pill") -- over the tip ribbon, which sits under it
	fit(bar, 440, 74)
	bar.Name, bar.Visible = "BossBar", false
	local barTitle = text(bar, "ROOT WARDEN", UDim2.fromScale(0.8, 0.44), UDim2.fromScale(0.5, 0.3), Vector2.new(0.5, 0.5), Color3.fromRGB(236, 224, 255), 700, false)
	barTitle.Font = Enum.Font.FredokaOne -- Shared.JellyHUD turns this font into jelly letters
	local pips = {}
	for k = 1, 3 do
		local p = new("Frame", bar, { Size = UDim2.fromScale(0.27, 0.24), Position = UDim2.fromScale(0.21 + (k - 1) * 0.29, 0.72), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.fromRGB(255, 0, 127), BorderSizePixel = 0, ZIndex = 3 })
		new("UICorner", p, { CornerRadius = UDim.new(0.4, 0) })
		new("UIStroke", p, { Color = Color3.fromRGB(255, 236, 190), Thickness = 1.5, Transparency = 0.3 })
		new("UIGradient", p, { Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(200, 150, 110)) }) -- a lit top edge, as on the glass pills
		pips[k] = p
	end
	for _, x in { -0.02, 1.02 } do -- a turquoise crystal spur at each end of the bar, like the ones on the Warden's back (Gemini, 2026-11-13: the bar had nothing of the boss in it)
		local spur = new("Frame", bar, { Size = UDim2.fromScale(0.07, 0.42), Position = UDim2.fromScale(x, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), Rotation = 45, BackgroundColor3 = Color3.fromRGB(155, 31, 232), BorderSizePixel = 0, ZIndex = 4 })
		new("UIAspectRatioConstraint", spur, { AspectRatio = 1 })
		new("UIStroke", spur, { Color = Color3.fromRGB(200, 255, 246), Thickness = 1.5 })
		new("UIGradient", spur, { Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(120, 200, 200)) })
	end
	-- the name lands big when the boss wakes
	local banner = text(gui, "ROOT WARDEN", S(520, 80), S(640, 182), Vector2.new(0.5, 0.5), AMBER, 700, false) -- top third, smaller: centred it covered the fight (full1119d 221 s, 2026-11-19)
	banner.Name, banner.Visible, banner.Font = "BossBanner", false, Enum.Font.FredokaOne
	local bannerScale = new("UIScale", banner, { Scale = 1 })
	game:GetService("RunService").Heartbeat:Connect(function() -- beside the dial while a Perfect Strike is up: at the top it lay on the strike's title
		if not bar.Visible then return end
		local hud = gui:FindFirstChild("CaveHud")
		local ps = hud and hud:FindFirstChild("PerfectStrike")
		bar.Position = S(640, 70) -- directive v10 re-run: the strike dial now hangs on the knot in the world with no title bar, so the boss bar keeps its place (Gemini: "kicked out of top-centre")
	end)
	local jump = text(gui, "JUMP!", S(420, 110), S(640, 300), Vector2.new(0.5, 0.5), PINK, 700, false)
	jump.Visible, jump.Font = false, Enum.Font.FredokaOne
	new("UIStroke", jump, { Color = INK, Thickness = 4 })

	local base -- the boss's resting pivot
	local function use(id)
		if type(id) ~= "number" or id == now or not NAMES[id] then return end
		bases[now] = base
		now = id
		base = bases[now]
		barTitle.Text = TITLES[now]
	end
	local function floorAt(w) -- the point on the floor under the boss (its pivot is the middle of its body): attacks are drawn there
		local o = w.PrimaryPart.Position
		local rp = RaycastParams.new()
		rp.FilterDescendantsInstances = { w, plr.Character }
		rp.FilterType = Enum.RaycastFilterType.Exclude
		local hit = workspace:Raycast(o, Vector3.new(0, -14, 0), rp)
		return Vector3.new(o.X, (hit and hit.Position.Y or o.Y - 3.6) + 0.15, o.Z)
	end
	local function crew(hide) -- directive v10: the crew pets stand back for the fight (a white pet beside the boss was taken for the boss)
		local PETS = require(script.Parent.Config).PETS
		for _, m in workspace:GetDescendants() do
			if m:IsA("Model") and PETS[m.Name] and not m:FindFirstAncestor("Hub") and not m:FindFirstAncestor("Caves") and not m:FindFirstAncestor("TrophyFX") then
				for _, p in m:GetDescendants() do
					if p:IsA("BasePart") then p.LocalTransparencyModifier = hide and 1 or 0 elseif p:IsA("Light") or p:IsA("BillboardGui") then p.Enabled = not hide end
				end
			end
		end
	end
	-- v10: while the boss bar is up the exploring HUD steps back (coins, the menu, the quest card, the map, the how-to card), so
	-- the boss and the strike dial own the picture
	-- directive v13 ("the camera stands at its feet"): while a boss fight runs and no strike dial is up, the view widens from 70
	-- to 82 degrees (E.vmHook.bossFov, added by PixelClient), the camera tips up toward its chest as it winds up a slam or a sweep,
	-- and a cool turquoise (Warden) or magma (Golem) rim light stands behind it, so its silhouette fills the frame head to toe
	local RunServiceB = game:GetService("RunService")
	local rim, tilt, tiltGoalUntil = nil, 0, 0
	E.vmHook.bossFov = 0
	R.Fx.OnClientEvent:Connect(function(kind)
		if kind == "bossSlam" or kind == "bossSweep" then tiltGoalUntil = os.clock() + 1.1 end
	end)
	RunServiceB:BindToRenderStep("BossFraming", Enum.RenderPriority.Camera.Value + 3, function(dt)
		local fight = bar.Visible
		local w = fight and warden()
		local busy = E.cave and E.cave.mgBusy
		E.vmHook.bossFov += (((fight and not busy) and 12 or 0) - E.vmHook.bossFov) * math.min(1, dt * 2.5)
		local tg = (fight and not busy and os.clock() < tiltGoalUntil) and math.rad(4) or 0
		tilt += (tg - tilt) * math.min(1, dt * (tg > tilt and 6 or 3))
		if math.abs(tilt) > 0.0005 then
			local cam = workspace.CurrentCamera
			cam.CFrame = cam.CFrame * CFrame.Angles(tilt, 0, 0)
		end
		if w and w.PrimaryPart then
			if not rim then
				rim = Instance.new("Part")
				rim.Name, rim.Anchored, rim.CanCollide, rim.CanQuery, rim.CanTouch, rim.Transparency, rim.Size = "BossRim", true, false, false, false, 1, Vector3.one
				local l = Instance.new("PointLight")
				l.Range, l.Brightness, l.Shadows = 26, 2.2, false
				l.Parent = rim
				local sl = Instance.new("SpotLight") -- round 2 (Gemini: "add a strong rim backlight"): a back light aimed past the boss at the player, so its edges glow
				sl.Name, sl.Face, sl.Angle, sl.Range, sl.Brightness, sl.Shadows = "RimSpot", Enum.NormalId.Front, 70, 44, 5, true
				sl.Parent = rim
				rim.Parent = workspace:FindFirstChild("ClientFX") or workspace
			end
			local h = E.hrp and E.hrp()
			local bp = w.PrimaryPart.Position
			local away = h and (bp - h.Position) * Vector3.new(1, 0, 1) or Vector3.zAxis
			away = away.Magnitude > 0.1 and away.Unit or Vector3.zAxis
			rim.CFrame = CFrame.lookAt(bp + away * 7 + Vector3.new(0, 7.5, 0), h and h.Position or bp) -- behind and above, facing the player
			local rc = now == 2 and Color3.fromRGB(255, 120, 50) or Color3.fromRGB(80, 230, 220)
			rim.PointLight.Color, rim.RimSpot.Color = rc, rc
			rim.PointLight.Enabled, rim.RimSpot.Enabled = true, true
		elseif rim then
			rim.PointLight.Enabled, rim.RimSpot.Enabled = false, false
		end
	end)
	local stepped = {}
	game:GetService("RunService"):BindToRenderStep("BossHudStepBack", Enum.RenderPriority.Last.Value + 20, function() -- last in the frame: the HUD's own code shows these again between two strikes
		local fight = bar.Visible
		for _, n in { "LeftColumn", "StepCard", "Minimap", "HowTo", "DepthGauge" } do
			local o = E.gui:FindFirstChild(n, true)
			if o then
				if fight then
					if o.Visible then
						stepped[o] = true
						o.Visible = false
					end
				elseif stepped[o] then
					stepped[o] = nil
					if n ~= "HowTo" then o.Visible = true end
				end
			end
		end
	end)
	local function eyes(on)
		crew(on)
		local w = warden()
		if not w then return end
		for _, p in w:GetDescendants() do
			if p.Name == "WardenEye" then
				p.Color = on and Color3.fromRGB(120, 255, 240) or Color3.fromRGB(24, 90, 96) -- awake: wide turquoise eyes (directive v10, the crystalline look)
				p.Material = on and Enum.Material.Neon or Enum.Material.SmoothPlastic
				p.Size = on and Vector3.new(1.1, 0.75, 0.1) or Vector3.new(0.9, 0.25, 0.1)
			end
		end
	end
	local function openDoor(animate)
		local caves = workspace:FindFirstChild("Caves")
		if not caves then return end
		for _, p in caves:GetDescendants() do
			if now == 1 and p:IsA("BasePart") and p:GetAttribute("GateDoor") then
				p.CanCollide = false
				if animate then tween(p, 1.2, { Transparency = 1 }) else p.Transparency = 1 end
				for _, l in p:GetChildren() do if l:IsA("PointLight") then l.Enabled = false end end
			end
		end
		local w = warden()
		if w and w.PrimaryPart then -- the Warden steps aside and nods off again
			base = base or w:GetPivot()
			w:PivotTo(base * CFrame.new(7, 0, 2) * CFrame.Angles(0, 0.5, 0))
		end
	end
	local function prompt(on) -- the Challenge prompt steps aside while the fight runs
		local w = warden()
		local pr = w and w.PrimaryPart and w.PrimaryPart:FindFirstChildOfClass("ProximityPrompt")
		if pr then pr.Enabled = on end
	end
	local TENT = { TentSide = true, TentStripe = true, TentBack = true, Door = true, Bedroll = true }
	local function tents(fade) -- Camp 1's tents step back while a fight runs: from the arena a tent roof cut across a quarter of the view (Orchestrator round 3)
		local cv = workspace:FindFirstChild("Caves")
		for _, d in cv and cv:GetDescendants() or {} do
			if d:IsA("BasePart") and TENT[d.Name] then d.LocalTransparencyModifier = fade and 0.85 or 0 end
		end
	end
	local function resetKnots()
		local w = warden()
		if not w then return end
		for k = 1, 3 do
			local kn = w:FindFirstChild("Knot" .. k)
			if kn and kn.PrimaryPart then kn.PrimaryPart.Transparency = 0 end
		end
		for _, p in pips do p.BackgroundColor3 = Color3.fromRGB(255, 0, 127) end
		local old = w:FindFirstChild("Cracks")
		if old then old:Destroy() end
	end
	local function crackBody(n) -- each cracked knot splits the stone a little more (Gemini full1119j: "pristine until the last knot")
		local w = warden()
		local body = w and (w:FindFirstChild("WardenBody", true) or w.PrimaryPart)
		if not body then return end
		local f = w:FindFirstChild("Cracks") or Instance.new("Folder")
		f.Name, f.Parent = "Cracks", w
		local rnd = Random.new(n * 7)
		for _ = 1, 3 do
			local c = Instance.new("Part")
			c.Name, c.Material, c.Color = "Crack", Enum.Material.Neon, Color3.fromRGB(255, 170, 70)
			c.Size = Vector3.new(0.14, 1.2 + rnd:NextNumber() * 1.4, 0.08)
			c.CanCollide, c.CanQuery, c.CanTouch, c.CastShadow, c.Massless, c.Anchored = false, false, false, false, true, false
			local x, y = rnd:NextNumber(-0.4, 0.4) * body.Size.X, rnd:NextNumber(-0.35, 0.35) * body.Size.Y
			c.CFrame = body.CFrame * CFrame.new(x, y, -body.Size.Z / 2 - 0.03) * CFrame.Angles(0, 0, rnd:NextNumber(-0.9, 0.9))
			local wc = Instance.new("WeldConstraint")
			wc.Part0, wc.Part1, wc.Parent = body, c, c
			c.Parent = f
		end
	end

	local ID_AT = { bossStart = 2, bossKnot = 3, bossSlam = 2, bossWin = 3, bossLose = 1, bossLocked = 2, bossOpen = 1, bossHit = 2, bossDodge = 1, bossHold = 1, bossSweep = 3, bossRings = 2 }
	R.Fx.OnClientEvent:Connect(function(kind, a, b, c)
		if ID_AT[kind] then use(({ a, b, c })[ID_AT[kind]]) end
		if kind == "bossStart" then
			local w = warden()
			base = base or (w and w:GetPivot())
			if w and base then w:PivotTo(base) end -- up again after a win's slump
			resetKnots()
			prompt(false)
			tents(true)
			bar.Visible = true
			banner.Text, banner.Visible, bannerScale.Scale = TITLES[now], true, 1.7
			tween(bannerScale, 0.45, { Scale = 1 }, Enum.EasingStyle.Back)
			task.delay(1.2, function()
				tween(bannerScale, 0.2, { Scale = 0 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
				task.delay(0.22, function() banner.Visible = false end)
			end)
			eyes(true)
			shake(0.6)
			sfx("breakRock", 0.5)
			local n = now
			task.delay(1.6, function() toast(n == 2 and "THE KILN GOLEM WAKES!  SEAL ITS 3 VENTS" or "THE ROOT WARDEN WAKES!  CRACK ITS 3 KNOTS", AMBER, true) end) -- directive v14: after the banner, so bar, banner and toast never stack
		elseif kind == "bossKnot" then
			pips[3 - a].BackgroundColor3 = Color3.fromRGB(90, 80, 110)
			if b and b.PrimaryPart then
				burst(b.PrimaryPart.Position, Vector3.yAxis, AMBER, 40)
				b.PrimaryPart.Transparency = 1
			end
			sfx("breakRock", 0.8)
			crackBody(3 - a)
			toast(a > 0 and ("KNOT CRACKED!  " .. a .. " TO GO") or "THE LAST KNOT CRACKS!", MINT, true)
		elseif kind == "bossHold" then
			toast("The knot holds! Two PERFECT swings crack it", PINK, false)
		elseif kind == "bossSlam" then -- it rises, a ring spreads, then it lands at the server time `a`
			local w = warden()
			if not w or not w.PrimaryPart then return end
			base = base or w:GetPivot()
			local land = a
			jump.Text = "JUMP!"
			local ring = new("Part", workspace, { Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.2, 1, 1), Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, Material = Enum.Material.Neon, Color = PINK, Transparency = 0.35,
				CFrame = CFrame.new(floorAt(w)) * CFrame.Angles(0, 0, math.pi / 2) })
			local conn
			conn = game:GetService("RunService").RenderStepped:Connect(function()
				local left = land - workspace:GetServerTimeNow()
				local k = math.clamp(1 - left / 1.1, 0, 1)
				w:PivotTo(base * CFrame.new(0, math.sin(k * math.pi * 0.5) * 2.2 * (left > 0 and 1 or 0), 0))
				ring.Size = Vector3.new(0.2, 2 + k * 44, 2 + k * 44)
				jump.Visible = left < 0.55 and left > -0.1
				if left <= 0 then
					conn:Disconnect()
					w:PivotTo(base)
					shake(0.8)
					sfx("breakRock", 0.6)
					burst(base.Position + Vector3.new(0, 1, 0), Vector3.yAxis, Color3.fromRGB(150, 120, 100), 50)
					local fl = floorAt(w) -- directive v10 (reference De5J8mwAd_1): crystal spikes erupt round it, one after another
					for i = 1, 8 do
						task.delay(i * 0.04, function()
							local ang = i / 8 * math.pi * 2
							local sp = new("Part", workspace, { Size = Vector3.new(1.1, 0.4, 1.1), Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, Material = Enum.Material.Glass,
								Color = now == 2 and Color3.fromRGB(255, 150, 60) or Color3.fromRGB(64, 224, 208), Transparency = 0.15,
								CFrame = CFrame.new(fl + Vector3.new(math.cos(ang) * 7, 0, math.sin(ang) * 7)) * CFrame.Angles(math.cos(ang) * 0.25, ang, math.sin(ang) * 0.25) })
							tween(sp, 0.16, { Size = Vector3.new(1.1, 5.5, 1.1) }, Enum.EasingStyle.Back)
							task.delay(0.7, function() tween(sp, 0.35, { Size = Vector3.new(0.2, 0.2, 0.2), Transparency = 1 }).Completed:Connect(function() sp:Destroy() end) end)
						end)
					end
					tween(ring, 0.4, { Transparency = 1 }).Completed:Connect(function() ring:Destroy() end)
					jump.Visible = false
				end
			end)
		elseif kind == "bossSweep" then -- a lane from the boss through where you stood glows, then roots (or flames) tear along it at the server time `a`
			local w = warden()
			if not w or not w.PrimaryPart then return end
			base = base or w:GetPivot()
			local land, dir, ATK, hot = a, b, C.BOSS_ATK, now == 2 and FIRE or PINK
			local len = (now == 2 and C.BOSS2 or C.BOSS).leash
			local o = floorAt(w)
			local lane = new("Part", workspace, { Size = Vector3.new(ATK.sweepW, 0.2, len), CFrame = CFrame.lookAt(o + dir * len / 2, o + dir * len), Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, Material = Enum.Material.Neon, Color = hot, Transparency = 0.8 })
			jump.Text = "STEP ASIDE!"
			sfx("swing", 0.5)
			local conn
			conn = game:GetService("RunService").RenderStepped:Connect(function()
				local left = land - workspace:GetServerTimeNow()
				local k = math.clamp(1 - left / ATK.sweepWind, 0, 1)
				lane.Transparency = 0.8 - k * 0.45 + math.sin(os.clock() * 18) * 0.05 -- brighter and flickering as it nears
				jump.Visible = left < 0.9 and left > -0.1
				if left <= 0 then
					conn:Disconnect()
					jump.Visible = false
					shake(0.7)
					sfx("breakRock", 0.7)
					for i = 1, 8 do -- spikes shoot up along the lane, the near ones first
						local at = o + dir * (i / 8 * len - 1.5) + dir:Cross(Vector3.yAxis) * ((i % 3) - 1) * ATK.sweepW * 0.25
						local sp = new("Part", workspace, { Size = Vector3.new(1.5, 0.4, 1.5), CFrame = CFrame.new(at) * CFrame.Angles(0, i, 0), Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false,
							Material = now == 2 and Enum.Material.Neon or Enum.Material.Wood, Color = now == 2 and FIRE or Color3.fromRGB(96, 66, 50) })
						task.delay(i * 0.03, function()
							local h = 5 + (i % 3) * 1.5
							tween(sp, 0.14, { Size = Vector3.new(1.5, h, 1.5), CFrame = CFrame.new(at + Vector3.new(0, h / 2, 0)) * CFrame.Angles(0.12 * ((i % 3) - 1), i, 0) })
							burst(at, Vector3.yAxis, hot, 10)
							task.delay(0.5, function() tween(sp, 0.35, { Size = Vector3.new(1.2, 0.2, 1.2), CFrame = CFrame.new(at), Transparency = 1 }).Completed:Connect(function() sp:Destroy() end) end)
						end)
					end
					tween(lane, 0.45, { Transparency = 1 }).Completed:Connect(function() lane:Destroy() end)
				end
			end)
		elseif kind == "bossRings" then -- three bands round the boss, shown at once, land one after another from the server time `a`: stand in a gap
			local w = warden()
			if not w or not w.PrimaryPart then return end
			base = base or w:GetPivot()
			local t0, ATK, hot = a, C.BOSS_ATK, now == 2 and FIRE or Color3.fromRGB(255, 0, 127) -- magenta, not pale pink: at Brightness 2 the pink rings bloomed white over the floor (Gemini v10n_r7)
			local o = floorAt(w) - Vector3.new(0, 0.03, 0)
			local made = {}
			for k, r in ATK.rings do
				local d = 2 * r + ATK.ringW
				local p = new("Part", workspace, { Size = Vector3.new(d, 0.1, d), CFrame = CFrame.new(o), Transparency = 1, Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false })
				local sg = new("SurfaceGui", p, { Face = Enum.NormalId.Top, SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud, PixelsPerStud = 12, LightInfluence = 0, Brightness = 1.2 })
				local f = new("Frame", sg, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale((2 * r - ATK.ringW) / d, (2 * r - ATK.ringW) / d), BackgroundTransparency = 1 })
				new("UICorner", f, { CornerRadius = UDim.new(0.5, 0) })
				made[k] = { part = p, stroke = new("UIStroke", f, { Color = hot, Thickness = ATK.ringW * 12, Transparency = 0.75 }), r = r }
			end
			jump.Text = "FIND A GAP!"
			sfx("swing", 0.6)
			local conn
			conn = game:GetService("RunService").RenderStepped:Connect(function()
				local t = workspace:GetServerTimeNow()
				jump.Visible = t0 - t < 1 and t0 - t > -0.1
				local live = false
				for k, m in made do
					local left = t0 + (k - 1) * ATK.ringGap - t
					if not m.done then
						live = true
						m.stroke.Transparency = math.clamp(0.75 - (1 - left / ATK.ringWind) * 0.4, 0.3, 0.75) + math.sin(os.clock() * 16 + k) * 0.04
						if left <= 0 then
							m.done = true
							m.stroke.Color, m.stroke.Transparency = Color3.new(1, 1, 1), 0
							shake(0.45)
							sfx("breakRock", 0.7 + k * 0.12)
							for q = 0, 5 do burst(o + Vector3.new(math.cos(q * 1.05 + k) * m.r, 0.5, math.sin(q * 1.05 + k) * m.r), Vector3.yAxis, hot, 8) end
							tween(m.stroke, 0.4, { Transparency = 1 }).Completed:Connect(function() m.part:Destroy() end)
						end
					end
				end
				if not live then
					conn:Disconnect()
					jump.Visible = false
				end
			end)
		elseif kind == "bossHit" then
			toast(c == "sweep" and "SWEPT!  STEP OUT OF THE LANE" or c == "rings" and "CAUGHT!  STAND BETWEEN THE RINGS" or "SLAMMED!  JUMP WHEN IT LANDS", PINK, true)
		elseif kind == "bossDodge" then
			toast("DODGED!", MINT, false)
		elseif kind == "bossWin" then
			bar.Visible = false
			tents(false)
			eyes(false)
			prompt(true)
			openDoor(true)
			sfx("upgrade", 1)
			do -- the stone gives: a spill of basalt chunks rolls off the beaten boss (Gemini full1119k), client only, gone in 5 s
				local w = warden()
				local body = w and (w:FindFirstChild("WardenBody", true) or w.PrimaryPart)
				if body then
					local rnd = Random.new()
					for k = 1, 10 do
						local c = Instance.new("Part")
						local sz = rnd:NextNumber(0.5, 1.2)
						c.Name, c.Size, c.Color, c.Material = "Rubble", Vector3.new(sz, sz * rnd:NextNumber(0.6, 1), sz), Color3.fromRGB(46, 42, 58), Enum.Material.Slate
						c.CFrame = body.CFrame * CFrame.new(rnd:NextNumber(-2.5, 2.5), rnd:NextNumber(0, 2.5), rnd:NextNumber(-2.5, 2.5)) * CFrame.Angles(rnd:NextNumber(0, 6), rnd:NextNumber(0, 6), 0)
						c.CanQuery, c.CanTouch, c.CastShadow = false, false, true
						c.Parent = workspace
						c.AssemblyLinearVelocity = Vector3.new(rnd:NextNumber(-10, 10), rnd:NextNumber(8, 16), rnd:NextNumber(-10, 10))
						game:GetService("Debris"):AddItem(c, 5)
						if k % 3 == 0 then c.Material, c.Color = Enum.Material.Glass, Color3.fromRGB(0, 240, 255) end -- a few crystal shards in the spill
					end
				end
			end
			do -- directive v13 (Gemini round 1: the beaten boss stood as it fought): it sinks and bows forward over 1.4 s, eyes out
				local w = warden()
				if w then
					base = base or w:GetPivot()
					local from, t0 = base, os.clock()
					local slump = from * CFrame.new(0, -1.4, 0) * CFrame.Angles(-0.2, 0, 0)
					local conn
					conn = game:GetService("RunService").RenderStepped:Connect(function()
						local k = math.clamp((os.clock() - t0) / 1.4, 0, 1)
						if not w.Parent then conn:Disconnect() return end
						w:PivotTo(from:Lerp(slump, 1 - (1 - k) ^ 3))
						if k >= 1 then conn:Disconnect() end
					end)
				end
			end
			local won = now
			toast(won == 2 and "THE KILN GOLEM YIELDS!" or "THE DEEP GATE IS OPEN!", GOLD, true)
			task.delay(2.2, function() -- the reward: the 3D chest of the daily reward with the boss's name (the server has already paid)
				local chest = E.vmHook and E.vmHook.rewardChest
				-- a short title: "ROOT WARDEN CHEST" ran out of the ribbon and read "ROOT W" (Gemini full1122d 298 s)
				if chest then chest(a, b, ({ "WARDEN", "GOLEM" })[won] .. " CHEST", won == 2 and "The Kiln Golem yields its hoard!" or "The Deep Gate is open!") else toast("+" .. a .. " COINS  +" .. b .. " GEMS", GOLD, true) end
			end)
			task.delay(4.4, function() toast(won == 2 and "The road past the kiln opens with the next camp." or "LANTERN FOUND! Old Gran's first lost lantern", MINT, true) end)
		elseif kind == "bossLose" then
			bar.Visible = false
			tents(false)
			eyes(false)
			prompt(true)
			local w = warden()
			if w and base then w:PivotTo(base) end
			resetKnots()
			toast(now == 2 and "The Golem pushed you back. Catch your breath and try again!" or "The Warden pushed you back. Catch your breath and try again!", PINK, true)
		elseif kind == "bossLocked" then
			toast("TOO TOUGH FOR THAT PICK. HOLD THE " .. string.upper(a) .. " (BOLT CAN FORGE IT)", PINK, true)
		elseif kind == "bossOpen" then
			toast(now == 2 and "The Golem sleeps. You have already beaten it." or "The Warden is asleep. The way to the Clay Caves is open for you.", MINT, false)
		end
	end)
	-- a returning player who already won: the door is open for them
	task.spawn(function()
		while true do
			local st = E.getState()
			if st and st.tips and st.tips.gate1 and plr:GetAttribute("InCave") then
				openDoor(false)
				break
			end
			task.wait(2)
		end
	end)
end

return M
