-- MiningReticle (ReplicatedStorage.Shared.MiningReticle), started by PixelClient with the cut-glass kit.
-- Directive v8 (2026-11-12), video audit point 3: the Perfect Strike dial sat in the middle of the screen as a flat 2D clock
-- while the camera looked at a wall. Now the game happens on the rock:
--   * the dial leaves the middle of the screen and rides on the deposit: every frame it is placed at the rock's place on screen
--     and sized by its distance, so the needle turns ON the ore (it stays a child of the HUD, so input and tests are unchanged)
--   * four neon corner brackets lock on to the deposit for both minigames (reference: Instagram De0Df23iOe3, @noio, glowing
--     wireframe brackets round a target); they punch outward and flash white on every strike
--   * the title and hint bars shrink to one slim line at the top
-- The dial is held inside the middle of the view, so it can always be played even when the rock is off screen. Display only: PixelClient
-- still owns the needle, the input and the server messages; this module only moves and dresses its widgets (E.cave.mg is wrapped).
-- Directive v10.0 re-run (2026-11-16): the dial is now drawn IN the world. A copy of the dial lives in a SurfaceGui (StrikeReticle)
-- on a plate laid on the rock face (or the boss) where the eye's line meets it, so it sits on the rock in 3D; the title line rides above the ring inside the same billboard. The 2D
-- original stays in the HUD (CaveHud.PerfectStrike...Needle and Arc) but parked off screen: PixelClient still turns its
-- needle, the tests and the autopilot still read its Rotation, and every frame the copy takes the original's look.
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local M = {}

local MID = Vector2.new(0.5, 0.5)

function M.start(E)
	if not E.GLASS then return end
	local cave, caveHud, plr = E.cave, E.caveHud, E.plr
	local ps = caveHud:WaitForChild("PerfectStrike", 60) -- 10 s was too short on a slow start: the module quit and the 2D clock came back (2026-11-16)
	while ps and not cave.mg do task.wait(0.2) end
	local needle = ps and ps:FindFirstChild("Needle", true)
	if not needle or not cave.mg then return end
	local dial = needle.Parent
	local home = { parent = dial.Parent, size = dial.Size, pos = dial.Position }
	local function new(cls, parent, props)
		local o = Instance.new(cls)
		for k, v in props do o[k] = v end
		o.Parent = parent
		return o
	end
	local pg = plr:WaitForChild("PlayerGui")
	local lock = new("BillboardGui", pg, { Name = "OreLock", Size = UDim2.fromScale(3.4, 3.4), AlwaysOnTop = false, StudsOffset = Vector3.new(0, 0, 2.5), LightInfluence = 0, -- drawn in the world, pulled 3.5 studs toward the eye so the rock does not swallow it (always-on-top world guis do not show in this game's captures)
		 ResetOnSpawn = false, Enabled = false, MaxDistance = 60 })
	local frame = new("Frame", lock, { Size = UDim2.fromScale(1, 1), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = MID, BackgroundTransparency = 1 })
	local punch = new("UIScale", frame, {})
	local bars = {}
	for _, c in { { 0, 0 }, { 1, 0 }, { 0, 1 }, { 1, 1 } } do -- four corners, each an L of two bars with a soft halo
		for _, horiz in { true, false } do
			local b = new("Frame", frame, { Size = horiz and UDim2.fromScale(0.22, 0.04) or UDim2.fromScale(0.04, 0.22), Position = UDim2.fromScale(c[1], c[2]), AnchorPoint = Vector2.new(c[1], c[2]), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0 })
			new("UIStroke", b, { Color = Color3.new(1, 1, 1), Thickness = 3, Transparency = 0.75 })
			table.insert(bars, b)
		end
	end
	local function tint(col)
		for _, b in bars do
			b.BackgroundColor3 = col
			b:FindFirstChildOfClass("UIStroke").Color = col
		end
	end

	-- The dial becomes a glass reticle while it rides on the rock (directive v8, audit point 3: "2D minigames blind the
	-- player"): its case and face turn clear so the ore shows through, leaving a bright ring, the gold arc, the notches and
	-- the glowing needle. The dark backdrop, the dial's shadow and the two bars are hidden; one jelly line at the top says
	-- what to do. Everything is put back when the minigame ends.
	local JellyText = require(script.Parent:WaitForChild("JellyText"))
	local dressed = {} -- { instance, property, old value }
	local function set(o, prop, v)
		table.insert(dressed, { o, prop, o[prop] })
		o[prop] = v
	end
	local ringStroke
	local function dress()
		if #dressed > 0 then return end
		for _, o in ps:GetChildren() do
			if o:IsA("Frame") and o ~= dial then
				local k = o:GetAttribute("Kind")
				if o.Name == "Dim" then set(o, "BackgroundTransparency", 1)
				elseif k == "pill" or k == "dark" then o.Visible = false -- the 2D title bars are never wanted again (the title rides on the rock): not put back, so none flashes up at the top between two knots
				elseif o:FindFirstChildOfClass("UICorner") and o.Size == home.size and o.BackgroundTransparency < 1 and not k then set(o, "Visible", false) end -- the dial's shadow disc
			end
		end
		set(dial, "BackgroundTransparency", 1)
		for _, o in dial:GetChildren() do
			if o:IsA("Frame") and o:FindFirstChildOfClass("UICorner") and o.Name == "Frame" then
				local k = o.Size.X.Scale
				if k > 0.95 then -- the outer case: a bright ring only
					set(o, "BackgroundTransparency", 1)
					ringStroke = ringStroke or new("UIStroke", o, { Color = Color3.new(1, 1, 1), Thickness = 6, Transparency = 0 })
					ringStroke.Enabled = true
				elseif k > 0.8 and k < 0.87 and pg:FindFirstChild("BossBar", true) and pg:FindFirstChild("BossBar", true).Visible then -- v10 (Gemini: "the dial vibrates over the boss's glowing heart"): a dark plum plate in a boss fight
					set(o, "BackgroundColor3", Color3.fromRGB(22, 8, 30))
					set(o, "BackgroundTransparency", 0.3)
				elseif k > 0.8 and k < 0.87 then set(o, "BackgroundTransparency", 0.72) -- the face: smoked glass, so the needle and marks stand out while the rock still shows (0.8 let the rock swallow them)
				elseif k > 0.2 then set(o, "BackgroundTransparency", 1) end
			end
		end
	end
	local function undress()
		for i = #dressed, 1, -1 do
			local d = dressed[i]
			if d[1].Parent then d[1][d[2]] = d[3] end
		end
		table.clear(dressed)
		if ringStroke then ringStroke.Enabled = false end
	end
	local say = new("Frame", ps, { Name = "Say", Size = UDim2.fromScale(0.34, 0.07), Position = UDim2.fromScale(0.5, 0.15), AnchorPoint = MID, BackgroundTransparency = 1, Visible = false, ZIndex = 13 })
	local sayText = JellyText.new(say, "STRIKE ON GOLD!", { color = Color3.fromRGB(236, 224, 255), glow = true, z = 13 })

	local world = new("SurfaceGui", pg, { Name = "StrikeReticle", Face = Enum.NormalId.Front, SizingMode = Enum.SurfaceGuiSizingMode.FixedSize, CanvasSize = Vector2.new(300, 360), AlwaysOnTop = false, LightInfluence = 0, Brightness = 1.3, ResetOnSpawn = false, Enabled = false, MaxDistance = 80 }) -- painted ON the rock: a plate laid on the rock face (Gemini v10n_r8: "a flat clock pasted over the rock")
	local worldTitle = new("TextLabel", world, { Name = "Title", Text = "STRIKE ON GOLD", Font = Enum.Font.FredokaOne, TextScaled = true, TextColor3 = Color3.fromRGB(236, 224, 255), TextStrokeColor3 = Color3.fromRGB(22, 8, 30), TextStrokeTransparency = 0.2, BackgroundTransparency = 1, Size = UDim2.fromScale(0.52, 0.085), Position = UDim2.fromScale(0.5, 0.005), AnchorPoint = Vector2.new(0.5, 0) }) -- 0.52 wide: at 0.8 the corner brackets cut its first and last letters (full1119d 186 s, 2026-11-19)
	local anchor = new("Part", nil, { Name = "ReticleAnchor", Size = Vector3.new(3.6, 4.3, 0.05), Transparency = 1, Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false })
	local mirror -- { copy = the dial's copy, pairs = { { original, copy } } }
	local PROPS = { GuiObject = { "Rotation", "Visible", "Size", "Position", "BackgroundColor3", "BackgroundTransparency" }, UIStroke = { "Color", "Transparency", "Enabled", "Thickness" }, UIGradient = { "Rotation", "Offset" } }
	local function mirrorStart()
		if mirror then mirror.copy:Destroy() end
		local orig = dial:GetDescendants()
		for k, d in orig do d:SetAttribute("MId", k) end -- pair each piece with its copy by tag: GetDescendants order differs between the two
		local copy = dial:Clone()
		copy.Name, copy.Size, copy.Position, copy.AnchorPoint = "Dial", UDim2.fromScale(1, 300 / 360), UDim2.fromScale(0.5, 1), Vector2.new(0.5, 1)
		for _, c in copy:GetChildren() do if c:IsA("UIAspectRatioConstraint") or c:IsA("UIScale") then c:Destroy() end end -- the pop scale stuck at 0.6 on the copy (measured 2026-11-16)
		for _, c in copy:GetChildren() do -- a reticle, not a clock (Gemini v10n_r6: "literally an analog clock face"): the notches, rune marks and rivets go
			if c:IsA("Frame") and c.Name == "Frame" and c.BackgroundTransparency == 1 and c.Size == UDim2.fromScale(1, 1) then
				local mark = c:FindFirstChildOfClass("Frame")
				if mark and mark.Size.X.Scale < 0.05 then c:Destroy() end
			end
		end
		copy.Parent = world
		local byId, pairs_ = {}, {}
		for _, c in copy:GetDescendants() do byId[c:GetAttribute("MId") or 0] = c end
		for k, o in orig do
			local c = byId[k]
			local list = c and (o:IsA("GuiObject") and PROPS.GuiObject or PROPS[o.ClassName])
			if list then table.insert(pairs_, { o, c, list }) end
		end
		local back = new("Frame", copy, { Name = "Back", Size = UDim2.fromScale(0.94, 0.94), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = MID, BackgroundColor3 = Color3.fromRGB(22, 8, 30), BackgroundTransparency = 0.38, BorderSizePixel = 0, ZIndex = 9 }) -- obsidian glass behind the needle: the rock behind a clear face swallowed it
		new("UICorner", back, { CornerRadius = UDim.new(0.5, 0) })
		mirror = { copy = copy, pairs = pairs_ }
	end
	local function mirrorStop()
		if mirror then mirror.copy:Destroy() mirror = nil end
		world.Enabled = false
		anchor.Parent = nil
	end
	local dep, kind, lockCol, at = nil, nil, Color3.new(1, 1, 1), nil
	local depParts = {} -- the deposit's parts, for keeping the plate in front of every crystal
	local aim = 0
	local function stop()
		dep, kind, at = nil, nil, nil
		dial.Size, dial.Position = home.size, home.pos
		lock.Enabled = false
		undress()
		say.Visible = false
		mirrorStop()
	end

	local inner = cave.mg
	local wrapped
	wrapped = function(what, ...)
		inner(what, ...)
		if what == "mgStart" then
			local d, which = ...
			local core = d and d.PrimaryPart
			if not core then return end
			dep, kind, aim = d, which, 0
			depParts = {}
			for _, q in d:GetDescendants() do if q:IsA("BasePart") then table.insert(depParts, q) end end
			local ore = E.C.LAYERS[d:GetAttribute("Layer")][4][d:GetAttribute("Ore")]
			lockCol = (ore and ore[2] or Color3.fromRGB(120, 232, 255)):Lerp(Color3.new(1, 1, 1), 0.65)
			tint(lockCol)
			lock.Adornee = core
			lock.Enabled = which == "strike" -- Vein Rush has its own spire and two wide buttons: the brackets ran through them
			punch.Scale = 1.5 -- the brackets close in on the rock
			TweenService:Create(punch, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
			if which == "strike" then
				dress()
				if ringStroke then ringStroke.Color = lockCol end
				say.Visible = false -- the title rides in the world above the ring now
				mirrorStart()
				anchor.Parent = workspace.CurrentCamera
				world.Adornee, world.Enabled = anchor, true
				worldTitle.TextColor3 = lockCol
			end
		elseif what == "mgStrike" and dep then -- every swing: a white flash and a punch outward (1 frame white, then back to the ore's colour)
			tint(Color3.new(1, 1, 1))
			punch.Scale = 1.16
			TweenService:Create(punch, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
			task.delay(0.06, function() if dep then tint(lockCol) end end)
		elseif what == "mgEnd" then
			stop()
		end
	end
	cave.mg = wrapped

	RunService:BindToRenderStep("PixelMiningReticle", Enum.RenderPriority.Camera.Value + 2, function()
		if not dep then return end
		local core = dep.PrimaryPart
		if not core or not cave.mgBusy then -- the minigame ended some other way (left, died, reset)
			stop()
			return
		end
		frame.Rotation = 0
		if kind ~= "strike" then return end
		do -- the view turns to the rock and holds it in the middle, so the game is played on the ore itself
			local cam = workspace.CurrentCamera
			local want = CFrame.lookAt(cam.CFrame.Position, core.Position)
			aim = math.min(1, aim + 1 / 60 / 0.35)
			cam.CFrame = cam.CFrame:Lerp(want, aim * aim * (3 - 2 * aim))
		end
		if not ps.Visible then return end
		-- the dial rides on the rock: its place on screen, held inside the middle of the view, its size from the distance
		local cam = workspace.CurrentCamera
		local v = cam:WorldToViewportPoint(core.Position)
		local vp = cam.ViewportSize
		local inset = game:GetService("GuiService"):GetGuiInset()
		local x, y = v.X, v.Y
		if v.Z < 0 then x, y = vp.X / 2, vp.Y / 2 end -- behind the camera: the middle
		local px = math.clamp(5.6 / (2 * math.max(v.Z, 2) * math.tan(math.rad(cam.FieldOfView / 2))) * vp.Y, vp.Y * 0.3, vp.Y * 0.4) -- the owner, 2026-11-15: at 13 to 19% the game was too small to play -- directive v9: a reticle on the ore, not a clock over the view (it was 30 to 40% of the height)
		local goal = Vector2.new(math.clamp(x, vp.X * 0.25, vp.X * 0.75), math.clamp(y, vp.Y * 0.46, vp.Y * 0.56))
		at = at and at:Lerp(goal, 0.25) or goal
		local o = ps.AbsolutePosition
		dial.Size = UDim2.fromOffset(px, px)
		dial.Position = UDim2.fromOffset(at.X - o.X, at.Y - inset.Y - o.Y)
		if mirror then
			local eye = cam.CFrame.Position
			-- the plate lies on the face of the rock (or of the boss) where the line from the eye meets it, turned toward the eye
			-- just enough to stay readable (at most about 50 degrees off), and sized from the distance so the game stays big
			local rp = RaycastParams.new()
			rp.FilterType, rp.FilterDescendantsInstances = Enum.RaycastFilterType.Exclude, { plr.Character, anchor, workspace.CurrentCamera }
			local to = core.Position - eye
			local hit = workspace:Raycast(eye, to * 1.05, rp)
			local at = hit and hit.Position or core.Position
			local v = (eye - at).Unit
			local n = hit and hit.Normal or v
			for _ = 1, 3 do if n:Dot(v) < 0.65 then n = (n + v).Unit end end
			local dist = (at - eye).Magnitude
			local k = math.clamp(dist * 0.27, 1.6, 3.3) -- studs across the dial: about a quarter of the view high (Gemini audit 2026-11-18: at a third it read as a 2D clock hijacking the screen)
			-- the owner, 2026-11-17: "the wheel is covered by the gemstone itself". The ray met the rock behind the crystals, so
			-- gems standing out of the deposit poked through the plate. Now the plate sits just in front of the nearest corner of
			-- any deposit part inside the dial's circle, facing the eye, so nothing of the gem can cover it.
			local dir = to.Unit
			local near = (at - eye):Dot(dir)
			for _, q in depParts do
				local h = q.Size / 2
				for _, c in { Vector3.new(h.X, h.Y, h.Z), Vector3.new(-h.X, h.Y, h.Z), Vector3.new(h.X, -h.Y, h.Z), Vector3.new(h.X, h.Y, -h.Z), Vector3.new(-h.X, -h.Y, h.Z), Vector3.new(-h.X, h.Y, -h.Z), Vector3.new(h.X, -h.Y, -h.Z), Vector3.new(-h.X, -h.Y, -h.Z) } do
					local rel = q.CFrame * c - eye
					local along = rel:Dot(dir)
					if along > 1 and along < near and (rel - dir * along).Magnitude < k * 1.3 + 0.5 then near = along end -- wide enough that no deposit block covers the smaller dial
				end
			end
			if near < (at - eye):Dot(dir) - 0.05 then at, n = eye + dir * (near - 0.15), v end
			anchor.Size = Vector3.new(k * 1.2, k * 1.44, 0.05)
			local glow = anchor:FindFirstChild("RockGlow") or new("PointLight", anchor, { Name = "RockGlow", Color = Color3.fromRGB(255, 200, 90), Shadows = false }) -- the dial lights the rock it sits on, so it reads as part of the world
			glow.Range, glow.Brightness = k * 1.6, 0.9 + math.sin(os.clock() * 6) * 0.25
			lock.Size = UDim2.fromScale(k * 1.25, k * 1.25) -- the brackets hug the smaller dial instead of framing half the view
			local up = math.abs(n.Y) > 0.9 and cam.CFrame.UpVector or Vector3.yAxis
			local pos = at + n * 0.12 + up * (k * 0.05)
			anchor.CFrame = CFrame.lookAt(pos, pos + n, up)
			dial.Position = UDim2.fromOffset(-4 * px, -4 * px) -- parked off screen: the needle still turns for the tests and the autopilot
			for _, pr in mirror.pairs do
				local a, c = pr[1], pr[2]
				for _, k in pr[3] do if c[k] ~= a[k] then c[k] = a[k] end end
			end
		end
		local boss = pg:FindFirstChild("BossBar", true) -- v10 (Gemini: "the UI smothers the boss"): in a boss fight only the dial is drawn, no title and no brackets
		if boss and boss.Visible then
			say.Visible = false
			lock.Enabled = false
			worldTitle.Visible = false
		else
			worldTitle.Visible = true
		end
	end)
end

return M
