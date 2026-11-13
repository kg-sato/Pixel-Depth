-- DiegeticHUD (ReplicatedStorage.Shared.DiegeticHUD), started by SurvivalHUD when the cut-glass kit is on (Config.UI_KIT = "glass").
-- Directive v8 (2026-11-12): the wooden survival disc becomes two liquid glass orbs with a cut-glass hex hotbar between them
-- (refs: Instagram De32zOxqhxU and DeFJqVLj_wV, dual vitals orbs beside a glass hotbar; DfbjiL-TBuK, radial cooldown sweeps).
--   * left orb   = Lantern: warm amber oil, its level is the torch fuel; it turns violet and gutters when nearly out
--   * hex slots  = FLARE [R] with its count and recharge sweep, SONAR [T] with its cooldown, PING [Z]
--   * right orb  = Vitality: rose crystal light, its level is HP, the number sits in the glass
--   * fear       = frost creeps in from the screen edges (the old disc showed a face instead)
-- The liquid is a swirl image turning inside two CanvasGroups (a round one for the ball, a flat one for the level): a rotated
-- image is only clipped by a CanvasGroup. Values: E.cave (fuel, fear), player attributes HP and Flares (server), the actions
-- call the same functions as their keys. The root keeps the name "Survival" so the focus and tracker code still find it.
local M = {}

function M.start(E)
	local C, plr, cave, caveHud, new, S, text, tween, G = E.C, E.plr, E.cave, E.caveHud, E.new, E.S, E.text, E.tween, E.GLASS
	local hook = E.vmHook
	local UIS = game:GetService("UserInputService")
	local touch = (UIS.TouchEnabled and not UIS.KeyboardEnabled) or plr:GetAttribute("DevTouch") == true
	local MID = Vector2.new(0.5, 0.5)
	local AMBER, VIOLET, ROSE, CYAN = Color3.fromRGB(255, 178, 56), Color3.fromRGB(150, 110, 235), Color3.fromRGB(255, 96, 150), Color3.fromRGB(120, 232, 255)
	local W, Hh = touch and 232 or 460, 112 -- board pixels; on touch the thumb buttons replace the hex slots

	local root = new("Frame", caveHud, { Name = "Survival", Size = S(W, Hh), Position = S(22, 578), AnchorPoint = Vector2.new(0, 1), BackgroundTransparency = 1, ZIndex = 2 })
	new("UIAspectRatioConstraint", root, { AspectRatio = W / Hh, DominantAxis = Enum.DominantAxis.Height })
	local function X(px) return px / W end

	local function orb(name, cx, tint, iconImage)
		local o = new("Frame", root, { Name = name, Size = UDim2.fromScale(X(Hh), 1), Position = UDim2.fromScale(X(cx), 0.5), AnchorPoint = MID, BackgroundTransparency = 1, ZIndex = 2 })
		new("UIAspectRatioConstraint", o, { AspectRatio = 1 })
		local ball = new("CanvasGroup", o, { Name = "Ball", Size = UDim2.fromScale(0.84, 0.84), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = MID, BackgroundColor3 = Color3.fromRGB(20, 12, 38), BackgroundTransparency = 0.45, BorderSizePixel = 0, ZIndex = 2 })
		new("UICorner", ball, { CornerRadius = UDim.new(0.5, 0) })
		local level = new("CanvasGroup", ball, { Name = "Level", Size = UDim2.fromScale(1, 1), Position = UDim2.fromScale(0, 1), AnchorPoint = Vector2.new(0, 1), BackgroundTransparency = 1, BorderSizePixel = 0 })
		local liquid = new("ImageLabel", level, { Name = "Liquid", Image = G.orbLiquid, ImageColor3 = tint, BackgroundTransparency = 1, Size = UDim2.fromScale(1.5, 1.5), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = MID })
		local glow = new("Frame", level, { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.25, BorderSizePixel = 0, ZIndex = 2 }) -- lighter at the surface, deeper below
		local shade = new("UIGradient", glow, { Rotation = 90, Color = ColorSequence.new(tint:Lerp(Color3.new(1, 1, 1), 0.55), tint:Lerp(Color3.new(0, 0, 0), 0.45)), Transparency = NumberSequence.new(0.85, 0.4) })
		local surf = new("Frame", level, { Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.25, BorderSizePixel = 0, ZIndex = 3 })
		local shell = new("ImageLabel", o, { Name = "Shell", Image = G.orbShell, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 4 })
		local ic = new("ImageLabel", o, { Name = "Icon", Image = iconImage, BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Size = UDim2.fromScale(0.42, 0.42), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = MID, ZIndex = 5 })
		local self = { root = o, shell = shell, icon = ic, liquid = liquid, fill = 1, shown = 1 }
		function self.tint(c)
			liquid.ImageColor3 = c
			shade.Color = ColorSequence.new(c:Lerp(Color3.new(1, 1, 1), 0.55), c:Lerp(Color3.new(0, 0, 0), 0.45))
		end
		function self.step(dt, now, spin)
			self.shown += (self.fill - self.shown) * math.min(1, dt * 6) -- the level eases to its value, it never jumps
			local f = math.clamp(self.shown + math.sin(now * 2.2 + cx) * 0.012, 0.02, 1) -- a slow slosh
			level.Size = UDim2.fromScale(1, f)
			liquid.Size = UDim2.fromScale(1.5, 1.5 / f)
			liquid.Position = UDim2.fromScale(0.5, 1 - 0.5 / f)
			liquid.Rotation = now * spin
			surf.Visible = f < 0.97
		end
		return self
	end

	local lantern = orb("Lantern", Hh / 2, AMBER, C.HUD_ICON.torch)
	local vital = orb("Vitality", W - Hh / 2, ROSE, C.HUD_ICON.heart)
	vital.icon.Position, vital.icon.Size = UDim2.fromScale(0.5, 0.4), UDim2.fromScale(0.36, 0.36)
	local hpText = text(vital.root, "", UDim2.fromScale(0.5, 0.3), UDim2.fromScale(0.5, 0.68), MID, Color3.new(1, 1, 1), 700)
	hpText.Font, hpText.ZIndex, hpText.TextStrokeColor3 = E.HEAD, 6, Color3.fromRGB(96, 20, 56)

	-- the hex hotbar between the orbs (keyboard and gamepad; phones have their own thumb buttons)
	local slots = {}
	local function hex(name, i, key, iconImage, act)
		local b = new("ImageButton", root, { Name = name, Image = G.hex, BackgroundTransparency = 1, AutoButtonColor = false, Size = UDim2.fromScale(X(76), 76 / Hh), Position = UDim2.fromScale(X(Hh + 14 + (i - 1) * 66 + 38), 0.5 + (i % 2 == 0 and 0.08 or -0.08)), AnchorPoint = MID, ZIndex = 3 })
		new("UIAspectRatioConstraint", b, { AspectRatio = 1 })
		local img
		if iconImage then
			img = new("ImageLabel", b, { Image = iconImage, BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Size = UDim2.fromScale(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.47), AnchorPoint = MID, ZIndex = 4 })
		else -- the sonar has no icon in the kit: three rings
			img = new("Frame", b, { Size = UDim2.fromScale(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.47), AnchorPoint = MID, BackgroundTransparency = 1, ZIndex = 4 })
			for r = 1, 3 do
				local ring = new("Frame", img, { Size = UDim2.fromScale(r / 3, r / 3), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = MID, BackgroundTransparency = 1, ZIndex = 4 })
				new("UICorner", ring, { CornerRadius = UDim.new(0.5, 0) })
				new("UIStroke", ring, { Color = CYAN, Thickness = 2, Transparency = (r - 1) * 0.25 })
			end
		end
		local cap = new("Frame", b, { Name = "KeyHint", Size = UDim2.fromScale(0.46, 0.36), Position = UDim2.fromScale(0.5, 0.98), AnchorPoint = MID, BackgroundColor3 = Color3.fromRGB(24, 16, 46), BackgroundTransparency = 0.1, BorderSizePixel = 0, ZIndex = 5 })
		new("UICorner", cap, { CornerRadius = UDim.new(0.3, 0) })
		new("UIStroke", cap, { Color = Color3.fromRGB(214, 200, 255), Thickness = 1, Transparency = 0.2 })
		local kt = text(cap, key, UDim2.fromScale(0.8, 0.8), UDim2.fromScale(0.5, 0.5), MID, Color3.new(1, 1, 1), 700, false)
		kt.Font, kt.ZIndex = E.HEAD, 6
		local note = text(b, "", UDim2.fromScale(0.62, 0.4), UDim2.fromScale(0.86, 0.14), MID, Color3.new(1, 1, 1), 700)
		note.Font, note.ZIndex, note.TextStrokeColor3 = E.HEAD, 6, Color3.fromRGB(46, 30, 96)
		local veil = new("ImageLabel", b, { Image = G.hex, ImageColor3 = Color3.fromRGB(12, 6, 26), ImageTransparency = 1, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 5 }) -- dims the slot while it recharges
		b.Activated:Connect(function() if act then act() end end)
		b.MouseEnter:Connect(function() b.Image = G.hexOn end)
		b.MouseLeave:Connect(function() b.Image = G.hex end)
		local s = { b = b, img = img, note = note, veil = veil }
		slots[name] = s
		return s
	end
	local flare, sonar
	if not touch then
		flare = hex("Flare", 1, "R", C.HUD_ICON.flare, function() if cave.flare then cave.flare() end end)
		sonar = hex("Sonar", 2, "T", nil, function() if hook.sonar then hook.sonar() end end)
		hex("Ping", 3, "Z", E.ICON.map, function() if hook.ping then hook.ping() end end)
	end

	plr:GetAttributeChangedSignal("DevTouch"):Connect(function() -- a touch test switched on after the start: the thumb buttons take over, the hex slots go
		local on = plr:GetAttribute("DevTouch") == nil
		for _, sl in slots do sl.b.Visible = on end
	end)
	-- the numbers, on hover or tap, and for a moment when a state changes
	local tipBox = new("Frame", root, { Name = "Numbers", Size = UDim2.fromScale(X(250), 0.28), Position = UDim2.fromScale(0, -0.06), AnchorPoint = Vector2.new(0, 1), BackgroundColor3 = Color3.fromRGB(24, 16, 46), BackgroundTransparency = 0.15, BorderSizePixel = 0, Visible = false, ZIndex = 7 })
	new("UICorner", tipBox, { CornerRadius = UDim.new(0.3, 0) })
	new("UIStroke", tipBox, { Color = Color3.fromRGB(214, 200, 255), Thickness = 1, Transparency = 0.3 })
	local tipT = text(tipBox, "", UDim2.fromScale(0.9, 0.62), UDim2.fromScale(0.5, 0.5), MID, Color3.new(1, 1, 1), 700, false)
	tipT.ZIndex = 8
	local tipUntil = 0
	for _, o in { lantern, vital } do
		local hit = new("TextButton", o.root, { Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 9 })
		hit.MouseEnter:Connect(function() tipUntil = os.clock() + 60 end)
		hit.MouseLeave:Connect(function() tipUntil = os.clock() + 0.4 end)
		hit.Activated:Connect(function() tipUntil = os.clock() + 3 end)
	end

	-- fear: frost creeps in from the four screen edges
	local frost = {}
	for i, d in { { UDim2.fromScale(1, 0.26), UDim2.fromScale(0, 0), 90 }, { UDim2.fromScale(1, 0.26), UDim2.fromScale(0, 0.74), 270 }, { UDim2.fromScale(0.2, 1), UDim2.fromScale(0, 0), 0 }, { UDim2.fromScale(0.2, 1), UDim2.fromScale(0.8, 0), 180 } } do
		local f = new("Frame", E.top, { Name = "Frost" .. i, Size = d[1], Position = d[2], BackgroundColor3 = Color3.fromRGB(206, 226, 255), BackgroundTransparency = 0, BorderSizePixel = 0, Visible = false, ZIndex = 1 })
		frost[i] = { f = f, g = new("UIGradient", f, { Rotation = d[3], Transparency = NumberSequence.new(1) }) }
	end

	local function bump(o, from)
		local sc = o:FindFirstChild("Pop") or new("UIScale", o, { Name = "Pop" })
		sc.Scale = from
		tween(sc, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
	end
	local shownHp, lastFl, flareAt, lastFrost = -1, nil, 0, -1
	game:GetService("RunService").RenderStepped:Connect(function(dt)
		local inCave = caveHud.Visible and root.Visible
		local fear = inCave and (cave.fear or 0) or 0
		local fa = math.floor(math.clamp((fear - 0.25) * 0.9, 0, 0.55) * 50 + 0.5) / 50 -- 0 calm .. 0.55 terrified, in small steps
		if fa ~= lastFrost then
			lastFrost = fa
			for _, fr in frost do
				fr.f.Visible = fa > 0
				fr.g.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1 - fa), NumberSequenceKeypoint.new(0.35, 1 - fa * 0.35), NumberSequenceKeypoint.new(1, 1) })
			end
		end
		if not inCave then return end
		local now = os.clock()
		local fuel = cave.fuel or 1
		lantern.fill = fuel
		lantern.tint(VIOLET:Lerp(AMBER, math.clamp(fuel * 2.2, 0, 1)))
		lantern.step(dt, now, 34)
		lantern.icon.ImageTransparency = fuel < 0.2 and 0.25 + 0.25 * math.sin(now * 9) or 0
		lantern.icon.Rotation = math.noise(now * 3) * 8
		lantern.shell.ImageColor3 = fuel < 0.2 and Color3.new(1, 1, 1):Lerp(VIOLET, 0.5 + 0.5 * math.sin(now * 6)) or Color3.new(1, 1, 1)
		local hp, maxHp = plr:GetAttribute("HP") or C.GLOOM.hp, C.GLOOM.hp
		vital.fill = hp / maxHp
		vital.step(dt, now, -26)
		vital.shell.ImageColor3 = hp <= maxHp / 3 and Color3.new(1, 1, 1):Lerp(Color3.fromRGB(255, 70, 90), 0.5 + 0.5 * math.sin(now * 7)) or Color3.new(1, 1, 1)
		if hp ~= shownHp then
			if shownHp >= 0 then bump(vital.root, hp < shownHp and 1.3 or 1.15); tipUntil = now + 2 end
			shownHp = hp
			hpText.Text = tostring(hp)
		end
		if flare then
			local fl = plr:GetAttribute("Flares") or C.GLOOM.flares
			if fl ~= lastFl then
				if lastFl and fl < lastFl then flareAt = now; bump(flare.b, 1.25) end
				lastFl = fl
				flare.note.Text = "x" .. fl
				flare.note.TextColor3 = fl > 0 and Color3.new(1, 1, 1) or Color3.fromRGB(255, 120, 140)
			end
			flare.veil.ImageTransparency = fl <= 0 and 0.35 or (now - flareAt < 1.5 and 0.35 + 0.65 * (now - flareAt) / 1.5 or 1)
			local left = hook.sonarLeft and hook.sonarLeft() or 0
			sonar.veil.ImageTransparency = left > 0 and 0.35 or 1
			sonar.note.Text = left > 0 and tostring(math.ceil(left)) or ""
		end
		tipBox.Visible = now < tipUntil
		if tipBox.Visible then
			tipT.Text = "HP " .. hp .. "/" .. maxHp .. "   LANTERN " .. math.floor(fuel * 100 + 0.5) .. "%"
		end
	end)
	return root
end

return M
