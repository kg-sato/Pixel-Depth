-- BossClient (ReplicatedStorage.Shared.BossClient), started by PixelClient: what the Root Warden fight looks like for the player
-- fighting it (server: ServerScriptService.Boss). The Warden wakes (amber eyes, a rumble), a boss bar shows its knots, each slam
-- is telegraphed (it rises, a pink ring spreads on the floor, JUMP!), cracked knots go dark, and a win opens the Deep Gate:
-- its roots fade and stop colliding for this player (for good once tips.gate1 is saved).
local M = {}

function M.start(E)
	local R, plr, gui, new, S, fit, panel, text, toast, sfx, shake, burst, tween = E.R, E.plr, E.gui, E.new, E.S, E.fit, E.panel, E.text, E.toast, E.sfx, E.shake, E.burst, E.tween
	local INK, PINK, GOLD, MINT = E.INK, E.PINK, E.GOLD, E.MINT
	local AMBER = Color3.fromRGB(255, 186, 92)
	-- two bosses share this client (server: Boss.DEFS): every Fx event carries the boss number last, use(id) switches to it
	local NAMES, TITLES = { "Warden", "KilnGolem" }, { "ROOT WARDEN", "KILN GOLEM" }
	local now, bases = 1, {}
	local function warden() return workspace:FindFirstChild("Caves") and workspace.Caves:FindFirstChild(NAMES[now], true) end

	-- the boss bar: name and one pip per knot
	local bar = panel(gui, S(360, 64), S(640, 120), Vector2.new(0.5, 0.5), "pillButter")
	fit(bar, 360, 64)
	bar.Name, bar.Visible = "BossBar", false
	local barTitle = text(bar, "ROOT WARDEN", UDim2.fromScale(0.8, 0.4), UDim2.fromScale(0.5, 0.3), Vector2.new(0.5, 0.5), Color3.fromRGB(184, 122, 26), 700, false)
	local pips = {}
	for k = 1, 3 do
		local p = new("Frame", bar, { Size = UDim2.fromScale(0.16, 0.28), Position = UDim2.fromScale(0.3 + (k - 1) * 0.2, 0.7), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = AMBER, BorderSizePixel = 0, ZIndex = 3 })
		new("UICorner", p, { CornerRadius = UDim.new(0.5, 0) })
		new("UIStroke", p, { Color = INK, Thickness = 2 })
		pips[k] = p
	end
	game:GetService("RunService").Heartbeat:Connect(function() -- beside the dial while a Perfect Strike is up: at the top it lay on the strike's title
		if not bar.Visible then return end
		local hud = gui:FindFirstChild("CaveHud")
		local ps = hud and hud:FindFirstChild("PerfectStrike")
		bar.Position = (ps and ps.Visible) and S(1050, 300) or S(640, 120)
	end)
	local jump = text(gui, "JUMP!", S(420, 110), S(640, 300), Vector2.new(0.5, 0.5), PINK, 700, false)
	jump.Visible = false
	new("UIStroke", jump, { Color = INK, Thickness = 4 })

	local base -- the boss's resting pivot
	local function use(id)
		if type(id) ~= "number" or id == now or not NAMES[id] then return end
		bases[now] = base
		now = id
		base = bases[now]
		barTitle.Text = TITLES[now]
	end
	local function eyes(on)
		local w = warden()
		if not w then return end
		for _, p in w:GetDescendants() do
			if p.Name == "WardenEye" then
				p.Color = on and AMBER or Color3.fromRGB(40, 28, 46)
				p.Material = on and Enum.Material.Neon or Enum.Material.SmoothPlastic
				p.Size = on and Vector3.new(0.9, 0.7, 0.1) or Vector3.new(0.9, 0.25, 0.1)
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
	local function resetKnots()
		local w = warden()
		if not w then return end
		for k = 1, 3 do
			local kn = w:FindFirstChild("Knot" .. k)
			if kn and kn.PrimaryPart then kn.PrimaryPart.Transparency = 0 end
		end
		for _, p in pips do p.BackgroundColor3 = AMBER end
	end

	local ID_AT = { bossStart = 2, bossKnot = 3, bossSlam = 2, bossWin = 3, bossLose = 1, bossLocked = 2, bossOpen = 1, bossHit = 2, bossDodge = 1, bossHold = 1 }
	R.Fx.OnClientEvent:Connect(function(kind, a, b, c)
		if ID_AT[kind] then use(({ a, b, c })[ID_AT[kind]]) end
		if kind == "bossStart" then
			local w = warden()
			base = base or (w and w:GetPivot())
			resetKnots()
			prompt(false)
			bar.Visible = true
			eyes(true)
			shake(0.6)
			sfx("breakRock", 0.5)
			toast(now == 2 and "THE KILN GOLEM WAKES!  SEAL ITS 3 VENTS" or "THE ROOT WARDEN WAKES!  CRACK ITS 3 KNOTS", AMBER, true)
		elseif kind == "bossKnot" then
			pips[3 - a].BackgroundColor3 = Color3.fromRGB(90, 80, 110)
			if b and b.PrimaryPart then
				burst(b.PrimaryPart.Position, Vector3.yAxis, AMBER, 40)
				b.PrimaryPart.Transparency = 1
			end
			sfx("breakRock", 0.8)
			toast(a > 0 and ("KNOT CRACKED!  " .. a .. " TO GO") or "THE LAST KNOT CRACKS!", MINT, true)
		elseif kind == "bossHold" then
			toast("The knot holds! Two PERFECT swings crack it", PINK, false)
		elseif kind == "bossSlam" then -- it rises, a ring spreads, then it lands at the server time `a`
			local w = warden()
			if not w or not w.PrimaryPart then return end
			base = base or w:GetPivot()
			local land = a
			local ring = new("Part", workspace, { Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.2, 1, 1), Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, Material = Enum.Material.Neon, Color = PINK, Transparency = 0.35,
				CFrame = CFrame.new(w.PrimaryPart.Position.X, base.Position.Y + 0.15, w.PrimaryPart.Position.Z) * CFrame.Angles(0, 0, math.pi / 2) })
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
					tween(ring, 0.4, { Transparency = 1 }).Completed:Connect(function() ring:Destroy() end)
					jump.Visible = false
				end
			end)
		elseif kind == "bossHit" then
			toast("SLAMMED!  JUMP WHEN IT LANDS", PINK, true)
		elseif kind == "bossDodge" then
			toast("DODGED!", MINT, false)
		elseif kind == "bossWin" then
			bar.Visible = false
			eyes(false)
			prompt(true)
			openDoor(true)
			sfx("upgrade", 1)
			local won = now
			toast(won == 2 and "THE KILN GOLEM YIELDS!" or "THE DEEP GATE IS OPEN!", GOLD, true)
			task.delay(2.2, function() toast("+" .. a .. " COINS  +" .. b .. " GEMS", GOLD, true) end)
			task.delay(4.4, function() toast(won == 2 and "The road past the kiln opens with the next camp." or "LANTERN FOUND! Old Gran's first lost lantern", MINT, true) end)
		elseif kind == "bossLose" then
			bar.Visible = false
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
