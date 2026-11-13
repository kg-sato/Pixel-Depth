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
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local M = {}

local MID = Vector2.new(0.5, 0.5)

function M.start(E)
	if not E.GLASS then return end
	local cave, caveHud, plr = E.cave, E.caveHud, E.plr
	local ps = caveHud:WaitForChild("PerfectStrike", 10)
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
				elseif k == "pill" or k == "dark" then set(o, "Visible", false)
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
				elseif k > 0.8 and k < 0.87 then set(o, "BackgroundTransparency", 0.42) -- the face: smoked glass, so the needle and marks stand out while the rock still shows (0.8 let the rock swallow them)
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
	local say = new("Frame", ps, { Name = "Say", Size = UDim2.fromScale(0.5, 0.11), Position = UDim2.fromScale(0.5, 0.13), AnchorPoint = MID, BackgroundTransparency = 1, Visible = false, ZIndex = 13 })
	local sayText = JellyText.new(say, "STRIKE ON GOLD!", { color = Color3.fromRGB(255, 226, 130), glow = true, z = 13 })

	local dep, kind, lockCol, at = nil, nil, Color3.new(1, 1, 1), nil
	local aim = 0
	local function stop()
		dep, kind, at = nil, nil, nil
		dial.Size, dial.Position = home.size, home.pos
		lock.Enabled = false
		undress()
		say.Visible = false
	end

	local inner = cave.mg
	cave.mg = function(what, ...)
		inner(what, ...)
		if what == "mgStart" then
			local d, which = ...
			local core = d and d.PrimaryPart
			if not core then return end
			dep, kind, aim = d, which, 0
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
				say.Visible = true
				sayText.set("STRIKE ON GOLD!")
				sayText.pop()
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
		local px = math.clamp(5.4 / (2 * math.max(v.Z, 2) * math.tan(math.rad(cam.FieldOfView / 2))) * vp.Y, vp.Y * 0.3, vp.Y * 0.4)
		local goal = Vector2.new(math.clamp(x, vp.X * 0.3, vp.X * 0.7), math.clamp(y, vp.Y * 0.42, vp.Y * 0.55))
		at = at and at:Lerp(goal, 0.25) or goal
		local o = ps.AbsolutePosition
		dial.Size = UDim2.fromOffset(px, px)
		dial.Position = UDim2.fromOffset(at.X - o.X, at.Y - inset.Y - o.Y)
	end)
end

return M
