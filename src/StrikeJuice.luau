-- StrikeJuice (ReplicatedStorage.Shared.StrikeJuice), started by PixelClient. Night of 2026-11-16, the owner: "work on the
-- minigame: how other games make it satisfying, with sfx, vfx and small fine tuning". What this adds to Perfect Strike,
-- and the game each idea comes from (vault: Research/Game Design/Timing Minigame Juice (2026-11-16).md):
--   * the cue before the hit (Clair Obscur's parry whoosh, Rhythm Heaven's music cue): as the needle nears the gold, a dry
--     tick on each 15 degree notch, rising in pitch, and the gold arc in the world heats up (a glow that grows and brightens)
--   * one timbre per grade (rhythm games: a sharp ping for PERFECT, a dull knock for the rest), and EARLY / LATE told on an
--     OK so the player learns which way they missed (rhythm games' offset readout)
--   * the rock answers every swing (Deep Rock Galactic, The Forge): a glowing crack opens where the eye's line meets the
--     rock, the deposit jolts back and springs home, and rock chips fall with real physics and bounce on the floor
--   * the stakes rise on the last swing of a clean run (Peggle's Extreme Fever): a soft drum roll and "FLAWLESS?" in the
--     world title; a flawless run lands a bell run and "FLAWLESS!", a near miss a soft falling "aww" and "SO CLOSE!"
--   * a short rumble on a gamepad (HapticService) on each hit
-- Display and sound only: the server still times and grades every swing (PixelClient sends the strike).
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local M = {}

local GOLD, LILAC, WHITE = Color3.fromRGB(255, 214, 92), Color3.fromRGB(196, 170, 255), Color3.new(1, 1, 1)

-- signed angle from a to b in degrees, in [-180, 180)
function M.diff(a, b) return (b - a + 180) % 360 - 180 end

function M.start(E)
	local cave, plr, sfx = E.cave, E.plr, E.sfx
	local ps = E.caveHud:WaitForChild("PerfectStrike", 60)
	while ps and not cave.mg do task.wait(0.2) end
	local needle, arc = ps and ps:FindFirstChild("Needle", true), ps and ps:FindFirstChild("Arc", true)
	if not needle or not arc then return end
	local pg = plr:WaitForChild("PlayerGui")
	local STRIKES = E.C.DEPOSIT.strikes
	local fx = Instance.new("Folder")
	fx.Name, fx.Parent = "StrikeJuiceFX", workspace

	local function rumble(big)
		pcall(function()
			local H = game:GetService("HapticService")
			local m = big and Enum.VibrationMotor.Large or Enum.VibrationMotor.Small
			H:SetMotor(Enum.UserInputType.Gamepad1, m, big and 0.8 or 0.4)
			task.delay(big and 0.14 or 0.07, function() H:SetMotor(Enum.UserInputType.Gamepad1, m, 0) end)
		end)
	end

	local run -- the live strike: { dep, col, streak, n, cracks, pivot, lastTick, roll, base }
	local function worldTitle() local w = pg:FindFirstChild("StrikeReticle") return w and w:FindFirstChild("Title") end
	local function say(msg, col, hold)
		local t = worldTitle()
		if not t or not run then return end
		run.sayId = (run.sayId or 0) + 1
		local id, r = run.sayId, run
		if not r.base then r.base = { t.Text, t.TextColor3 } end
		t.Text, t.TextColor3 = msg, col
		local sc = t:FindFirstChild("SayPop") or Instance.new("UIScale")
		sc.Name, sc.Parent, sc.Scale = "SayPop", t, 1.45
		TweenService:Create(sc, TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
		if hold then return end
		task.delay(0.85, function() if r.sayId == id and t.Parent then t.Text, t.TextColor3 = r.base[1], r.base[2] end end)
	end

	-- the heat glow on the world arc (made on the copy; the mirror only touches pieces tagged with an MId)
	local function glowFor()
		local w = pg:FindFirstChild("StrikeReticle")
		local a = w and w:FindFirstChild("Arc", true)
		if not a then return nil end
		local g = a:FindFirstChild("Heat")
		if not g then
			g = Instance.new("ImageLabel")
			g.Name, g.Image, g.BackgroundTransparency, g.ImageColor3, g.ImageTransparency = "Heat", "rbxassetid://77591933607769", 1, GOLD, 1
			g.Size, g.Position, g.AnchorPoint, g.ZIndex = UDim2.fromScale(0.34, 0.34), UDim2.fromScale(0.5, 0.25), Vector2.new(0.5, 0.5), 10
			g.Parent = a
		end
		return g
	end

	-- the crack: glowing slivers split the rock out from under the reticle's ring (the plate lies on the rock face, so they
	-- start at its rim), longer and brighter on a PERFECT; without the plate they start where the eye's line meets the rock
	local function crack(perfect)
		local core = run and run.dep.PrimaryPart
		if not core then return end
		local cam = workspace.CurrentCamera
		local plate = cam:FindFirstChild("ReticleAnchor")
		local basis, r0
		if plate then
			basis, r0 = plate.CFrame * CFrame.new(0, -plate.Size.Y * 0.07, 0.06), plate.Size.X * 0.47 -- the dial's middle, a hair behind the plate
		else
			local rp = RaycastParams.new()
			rp.FilterType, rp.FilterDescendantsInstances = Enum.RaycastFilterType.Include, { run.dep }
			local hit = workspace:Raycast(cam.CFrame.Position, (core.Position - cam.CFrame.Position) * 1.1, rp)
			local at, nrm = hit and hit.Position or core.Position, hit and hit.Normal or (cam.CFrame.Position - core.Position).Unit
			basis, r0 = CFrame.lookAt(at + nrm * 0.04, at + nrm * 2), 0
		end
		local col = run.col:Lerp(WHITE, perfect and 0.75 or 0.5) -- light from inside the rock: the ore's colour, very bright
		for i = 1, perfect and 4 or 2 do
			local deg = (#run.cracks * 29 + i * 97) % 360
			if deg > 45 and deg < 135 then deg += 120 end -- never up through the title above the ring
			local ang = math.rad(deg)
			local len = (perfect and 1.1 or 0.6) + math.random() * 0.7
			local dir = basis:VectorToWorldSpace(Vector3.new(math.cos(ang), math.sin(ang), 0))
			local bend = basis:VectorToWorldSpace(Vector3.new(-math.sin(ang), math.cos(ang), 0)) * (math.random() - 0.5) * 0.5
			local from = basis.Position + dir * r0
			for seg = 1, 2 do -- two segments with a kink, so it reads as a crack, not a stick
				local d2 = (dir + bend * (seg - 1)).Unit
				local l2 = len * (seg == 1 and 0.55 or 0.45)
				local p = Instance.new("Part")
				p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
				p.Material, p.Color, p.Transparency = Enum.Material.Neon, col, 0.05
				p.Size = Vector3.new(0.1, 0.1, 0.01)
				local mid = from + d2 * l2 / 2
				p.CFrame = CFrame.lookAt(mid, mid + d2)
				p.Parent = fx
				local w = (perfect and 0.16 or 0.1) * (seg == 1 and 1 or 0.6)
				local halo = p:Clone() -- a soft glow round the crack (a fainter, 3x thicker copy, Motion rule for glow on a line)
				halo.Transparency, halo.Parent = 0.8, fx
				for _, q in { { p, w }, { halo, w * 3 } } do
					local tw = TweenService:Create(q[1], TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.new(q[2], q[2], l2) })
					task.delay((seg - 1) * 0.05, function() tw:Play() end) -- the crack runs outward
					table.insert(run.cracks, q[1])
				end
				from += d2 * l2
			end
		end
	end

	-- rock chips with real physics: they fall, bounce on the floor and fade (client parts, nothing sent)
	local function chips(n, col)
		local core = run and run.dep.PrimaryPart
		if not core then return end
		local toEye = (workspace.CurrentCamera.CFrame.Position - core.Position) * Vector3.new(1, 0, 1)
		toEye = toEye.Magnitude > 0.1 and toEye.Unit or Vector3.xAxis
		for _ = 1, n do
			local s = 0.18 + math.random() * 0.22
			local p = Instance.new("Part")
			p.Size, p.Color, p.Material = Vector3.one * s, col:Lerp(Color3.fromRGB(60, 44, 70), math.random() * 0.5), Enum.Material.Rock
			p.CanQuery, p.CanTouch, p.CastShadow, p.Massless = false, false, false, true
			p.CFrame = CFrame.new(core.Position + toEye * 1.2 + Vector3.new(math.random() - 0.5, math.random(), math.random() - 0.5)) * CFrame.Angles(math.random() * 6, math.random() * 6, 0)
			p.Parent = fx
			p.AssemblyLinearVelocity = toEye * (6 + math.random() * 6) + Vector3.new(math.random(-5, 5), 8 + math.random() * 6, math.random(-5, 5))
			p.AssemblyAngularVelocity = Vector3.new(math.random(-12, 12), math.random(-12, 12), math.random(-12, 12))
			task.delay(1.3, function() TweenService:Create(p, TweenInfo.new(0.4), { Transparency = 1, Size = p.Size * 0.4 }):Play() end)
			task.delay(1.8, function() p:Destroy() end)
		end
	end

	-- the deposit jolts away from the eye and springs back (client side only; the pivot is put back exactly)
	local function jolt(amount)
		local dep = run and run.dep
		if not dep or not dep.Parent then return end
		run.joltId = (run.joltId or 0) + 1
		local r, id, home = run, run.joltId, run.pivot
		local away = (home.Position - workspace.CurrentCamera.CFrame.Position) * Vector3.new(1, 0, 1)
		away = away.Magnitude > 0.1 and away.Unit or Vector3.zAxis
		local t0 = os.clock()
		local conn
		conn = RunService.RenderStepped:Connect(function()
			local t = os.clock() - t0
			if run ~= r or r.joltId ~= id or t > 0.35 or not dep.Parent then
				conn:Disconnect()
				if dep.Parent and (run ~= r or r.joltId == id) then dep:PivotTo(home) end
				return
			end
			dep:PivotTo(home + away * (math.exp(-t * 14) * math.cos(t * 40) * amount)) -- a damped spring: back, overshoot, settle
		end)
	end

	local function stopRoll() if run and run.roll then run.roll:Destroy() run.roll = nil end end
	local function finish()
		if not run then return end
		stopRoll()
		local r = run
		run = nil
		if r.dep.Parent and r.pivot then r.dep:PivotTo(r.pivot) end
		for _, c in r.cracks do -- the cracks flare white as the rock gives, then go
			TweenService:Create(c, TweenInfo.new(0.25), { Transparency = 1, Color = WHITE }):Play()
			task.delay(0.3, function() c:Destroy() end)
		end
		local t = worldTitle()
		if t and r.base then t.Text, t.TextColor3 = r.base[1], r.base[2] end
	end

	plr:GetAttributeChangedSignal("DevStrike"):Connect(function() if cave.strike then cave.strike() end end) -- test hook: a real swing (spike/sj_test.py)

	local inner = cave.mg
	cave.mg = function(what, ...)
		inner(what, ...)
		if what == "mgStart" then
			local dep, which = ...
			finish()
			if which ~= "strike" or not dep or not dep.PrimaryPart then return end
			local ore = E.C.LAYERS[dep:GetAttribute("Layer")][4][dep:GetAttribute("Ore")]
			run = { dep = dep, col = ore and ore[2] or GOLD, streak = 0, n = 0, cracks = {}, pivot = dep:GetPivot() }
			run.knot = dep:GetAttribute("OreName") == "Root Knot" or dep:GetAttribute("OreName") == "Kiln Vent" -- boss knots: no flawless stakes
		elseif what == "mgStrike" and run then
			local n, perfect = ...
			local prev = run.streak
			run.n = n
			local off = cave.strikeOff -- needle minus arc at the moment of the swing (PixelClient sets it)
			cave.strikeOff = nil
			stopRoll()
			if perfect then
				run.streak += 1
				sfx("ping", 1 + 0.06 * (run.streak - 1))
				sfx("crack", 1.1)
				crack(true)
				jolt(0.32)
				chips(3, run.col)
				rumble(true)
				if n < STRIKES then say(run.streak > 1 and ("PERFECT x" .. run.streak) or "PERFECT!", GOLD) end
			else
				run.streak = 0
				sfx("thud", 0.95)
				sfx("crack", 0.8)
				crack(false)
				jolt(0.14)
				chips(2, run.col)
				rumble(false)
				if n < STRIKES and off then say(off < 0 and "TOO EARLY" or "TOO LATE", LILAC) end
			end
			if run.knot then return end
			if n == STRIKES - 1 and run.streak == STRIKES - 1 then -- one swing from flawless: the stakes rise
				local s = Instance.new("Sound")
				s.SoundId, s.Volume, s.Looped = "rbxassetid://72096035734767", 0.35, true
				s.Parent = game:GetService("SoundService")
				s:Play()
				run.roll = s
				task.delay(0.6, function() if run and run.n == STRIKES - 1 then say("FLAWLESS?", GOLD, true) end end)
			elseif n >= STRIKES then
				if run.streak >= STRIKES then
					sfx("flawless", 1)
					say("FLAWLESS!", GOLD, true)
				elseif not perfect and prev == STRIKES - 1 then
					sfx("aww", 1)
					say("SO CLOSE!", LILAC, true)
				end
			end
		elseif what == "mgEnd" then
			task.delay(0.35, finish)
		end
	end

	RunService.RenderStepped:Connect(function()
		if not run then return end
		if not cave.mgBusy then finish() return end
		local d = M.diff(needle.Rotation, arc.Rotation) -- > 0: the gold is still ahead of the needle
		local near = (d > 0 and d < 90) and (1 - d / 90) or ((d <= 0 and d > -10) and 1 or 0)
		local g = glowFor()
		if g then
			g.ImageTransparency = 1 - near * 0.75
			g.Size = UDim2.fromScale(0.26 + near * 0.18, 0.26 + near * 0.18)
		end
		local notch = (d > 0 and d < 75) and math.floor(d / 15) or -1 -- a tick on each notch the needle crosses on the way in
		if notch >= 0 and run.lastTick and notch ~= run.lastTick then sfx("tick", 1 + (5 - notch) * 0.12) end
		run.lastTick = notch
	end)
end

assert(M.diff(350, 10) == 20 and M.diff(10, 350) == -20, "StrikeJuice: diff") -- self-check
return M
