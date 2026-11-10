-- SurvivalHUD (ReplicatedStorage.Shared.SurvivalHUD), started by PixelClient. Demo audit 02: the three stacked bars (HP, TORCH,
-- CALM) ate a third of the screen height. They are one survival talisman now, bottom left, about 110 px across:
--   * outer ring  = torch fuel (amber, turning violet as it burns low; the flame on top flickers under 20%)
--   * centre      = the chibi face (calm, uneasy, scared); it glances toward the camp light and quivers when a gloomling is
--                   within 20 studs
--   * inner arc   = three heart crystals for HP (a gloomling hit takes one)
--   * collar slot = the flare, [R] xN, with a radial wipe while it recharges
-- Hover or tap the talisman for the exact numbers. The torch and fear values come from PixelClient (E.cave), HP and flares
-- from the player's attributes (server), the flare itself from GloomClient (E.cave.flare).
local M = {}

function M.start(E)
	local C, plr, cave, caveHud, new, S, text, tween = E.C, E.plr, E.cave, E.caveHud, E.new, E.S, E.text, E.tween
	local INK, CREAM, PINK = E.INK, Color3.fromRGB(255, 247, 236), E.PINK
	local Radial = require(script.Parent:WaitForChild("Radial"))
	local AMBER, VIOLET, PLUM = Color3.fromRGB(255, 196, 60), Color3.fromRGB(150, 110, 235), Color3.fromRGB(38, 28, 58)

	local root = new("Frame", caveHud, { Name = "Survival", Size = S(118, 118), Position = S(20, 572), AnchorPoint = Vector2.new(0, 1), BackgroundTransparency = 1, ZIndex = 2 })
	new("UIAspectRatioConstraint", root, { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height })
	local function disc(parent, w, h, pos, color, transparency, z)
		local f = new("Frame", parent, { Size = UDim2.fromScale(w, h), Position = pos, AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = color, BackgroundTransparency = transparency, BorderSizePixel = 0, ZIndex = z })
		new("UICorner", f, { CornerRadius = UDim.new(0.5, 0) })
		return f
	end
	disc(root, 1, 1, UDim2.fromScale(0.5, 0.54), Color3.fromRGB(16, 10, 28), 0.6, 1) -- soft drop shadow
	local back = disc(root, 0.98, 0.98, UDim2.fromScale(0.5, 0.5), Color3.new(1, 1, 1), 0.5, 2) -- frosted dark-violet glass
	new("UIGradient", back, { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(92, 74, 132), Color3.fromRGB(34, 24, 54)) })
	new("UIStroke", back, { Color = Color3.fromRGB(150, 112, 62), Thickness = 2 }) -- a thin bronze rim (a wide gold one read as the meter itself)
	local inner = disc(root, 0.92, 0.92, UDim2.fromScale(0.5, 0.5), Color3.new(1, 1, 1), 1, 3)
	new("UIStroke", inner, { Color = Color3.fromRGB(120, 84, 44), Thickness = 1.5, Transparency = 0.2 }) -- the rim's dark inner edge
	local sheen = disc(root, 0.5, 0.22, UDim2.fromScale(0.36, 0.25), Color3.new(1, 1, 1), 0.55, 7) -- a specular arc on the glass dome, top left
	sheen.Rotation = -28
	new("UIGradient", sheen, { Rotation = 90, Transparency = NumberSequence.new(0, 1) })
	local ringBox = new("Frame", root, { Size = UDim2.fromScale(0.94, 0.94), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, ZIndex = 4 })
	local ring = Radial.arc(ringBox, { name = "TorchRing", thick = 0.11, color = AMBER, track = Color3.fromRGB(104, 66, 58), trackTransparency = 0.1, z = 4 }) -- a burn meter in a copper channel (a dark one vanished against the cave)
	for i = 0, 19 do -- dark notches cut the ring into beads, like the reference dial: the burn reads bead by bead
		local t = new("Frame", ringBox, { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Rotation = i * 18 + 9, ZIndex = 5 })
		new("Frame", t, { Size = UDim2.fromScale(0.026, 0.125), Position = UDim2.fromScale(0.5, 0), AnchorPoint = Vector2.new(0.5, 0), BackgroundColor3 = Color3.fromRGB(30, 20, 44), BorderSizePixel = 0, ZIndex = 5 })
	end
	local flame = new("ImageLabel", root, { Name = "Flame", Image = C.HUD_ICON.torch, BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Size = UDim2.fromScale(0.36, 0.36), Position = UDim2.fromScale(0.5, 0.04), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 8 })
	local face = new("ImageLabel", root, { Name = "Face", Image = C.HUD_ICON.calm, BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Size = UDim2.fromScale(0.42, 0.42), Position = UDim2.fromScale(0.5, 0.39), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 5 })
	local tray = new("Frame", root, { Size = UDim2.fromScale(0.64, 0.24), Position = UDim2.fromScale(0.5, 0.74), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.fromRGB(28, 18, 44), BackgroundTransparency = 0.25, BorderSizePixel = 0, ZIndex = 5 }) -- the hearts' own tray
	new("UICorner", tray, { CornerRadius = UDim.new(0.5, 0) })
	new("UIStroke", tray, { Color = CREAM, Thickness = 1.5, Transparency = 0.4 })
	local hearts = {}
	for i, a in { 215, 180, 145 } do -- three heart crystals in the tray, left to right
		local r = math.rad(a)
		hearts[i] = new("ImageLabel", root, { Name = "Heart" .. i, Image = C.HUD_ICON.heart, BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Size = UDim2.fromScale(0.21, 0.21), Position = UDim2.fromScale(0.5 + math.sin(r) * 0.34, 0.74), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 6 })
	end

	-- the flare collar: a small glass slot hooked on the talisman's right shoulder
	local collar = new("TextButton", root, { Name = "Flare", Text = "", AutoButtonColor = false, Size = UDim2.fromScale(0.8, 0.36), Position = UDim2.fromScale(0.92, 0.77), AnchorPoint = Vector2.new(0, 0.5), BackgroundColor3 = Color3.fromRGB(29, 18, 43), BackgroundTransparency = 0.1, BorderSizePixel = 0, ZIndex = 3 })
	new("UICorner", collar, { CornerRadius = UDim.new(0.5, 0) })
	new("UIStroke", collar, { Color = Color3.fromRGB(150, 112, 62), Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }) -- the same bronze rim: one piece of hardware
	local flareBox = new("Frame", collar, { Size = UDim2.fromScale(0.36, 0.86), Position = UDim2.fromScale(0.2, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, ZIndex = 4 })
	new("UIAspectRatioConstraint", flareBox, { AspectRatio = 1 })
	new("ImageLabel", flareBox, { Image = C.HUD_ICON.flare, BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Size = UDim2.fromScale(1, 1), ZIndex = 4 })
	local wipe = Radial.arc(flareBox, { name = "Cooldown", color = Color3.fromRGB(20, 12, 34), fillTransparency = 0.4, z = 5, value = 0 })
	local key = new("Frame", collar, { Size = UDim2.fromScale(0.24, 0.62), Position = UDim2.fromScale(0.53, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = CREAM, BorderSizePixel = 0, ZIndex = 4 })
	new("UICorner", key, { CornerRadius = UDim.new(0.25, 0) })
	text(key, "R", UDim2.fromScale(0.7, 0.8), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5), INK, 700, false).ZIndex = 5
	local count = text(collar, "x2", UDim2.fromScale(0.26, 0.6), UDim2.fromScale(0.82, 0.5), Vector2.new(0.5, 0.5), CREAM, 700, false)
	count.ZIndex = 5
	collar.Activated:Connect(function() if cave.flare then cave.flare() end end)

	-- the numbers, on hover or tap (and for a moment whenever a state changes)
	local tipBox = new("Frame", root, { Name = "Numbers", Size = UDim2.fromScale(1.9, 0.28), Position = UDim2.fromScale(0, -0.08), AnchorPoint = Vector2.new(0, 1), BackgroundColor3 = PLUM, BackgroundTransparency = 0.15, BorderSizePixel = 0, Visible = false, ZIndex = 7 })
	new("UICorner", tipBox, { CornerRadius = UDim.new(0.4, 0) })
	local tipT = text(tipBox, "", UDim2.fromScale(0.9, 0.62), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5), CREAM, 700, false)
	tipT.ZIndex = 8
	local tipUntil = 0
	local function showNumbers(sec) tipUntil = os.clock() + sec end
	local hit = new("TextButton", root, { Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 9 })
	hit.MouseEnter:Connect(function() showNumbers(60) end)
	hit.MouseLeave:Connect(function() showNumbers(0.4) end)
	hit.Activated:Connect(function() showNumbers(3) end)

	local shownHp, level, lastFl, flareAt = -1, 0, nil, 0
	local function bump(o, from)
		local sc = o:FindFirstChild("Pop") or new("UIScale", o, { Name = "Pop" })
		sc.Scale = from
		tween(sc, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
	end
	game:GetService("RunService").RenderStepped:Connect(function()
		if not caveHud.Visible or not root.Visible then return end
		local now = os.clock()
		local fuel, fear = cave.fuel or 1, cave.fear or 0
		-- torch ring: amber to violet, the flame gutters when nearly out
		ring.set(fuel)
		ring.color(VIOLET:Lerp(AMBER, math.clamp(fuel * 2.2, 0, 1)):Lerp(Color3.new(1, 1, 1), 0.12))
		flame.ImageTransparency = fuel < 0.2 and 0.25 + 0.25 * math.sin(now * 9) or 0
		flame.Rotation = math.noise(now * 3) * 8
		-- hearts
		local hp = plr:GetAttribute("HP") or C.GLOOM.hp
		local per = C.GLOOM.hp / #hearts
		for i, h in hearts do
			local f = math.clamp((hp - (i - 1) * per) / per, 0, 1)
			h.ImageTransparency = 0.75 - 0.75 * f
			h.ImageColor3 = Color3.fromRGB(120, 100, 150):Lerp(Color3.new(1, 1, 1), f)
		end
		if hp ~= shownHp then
			if shownHp >= 0 then
				for _, h in hearts do bump(h, hp < shownHp and 1.5 or 1.25) end
			end
			shownHp = hp
		end
		-- the face: which one, where it looks, how it shakes
		local lv = fear < 0.25 and 0 or (fear < 0.6 and 1 or 2)
		if lv ~= level then
			level = lv
			face.Image = lv == 0 and C.HUD_ICON.calm or (lv == 1 and C.HUD_ICON.uneasy or C.HUD_ICON.scared)
			bump(face, 1.3)
		end
		local h = E.hrp()
		local near = math.huge
		local gloom = workspace:FindFirstChild("Gloom")
		if h and gloom then
			for _, g in gloom:GetChildren() do
				if g:IsA("BasePart") then near = math.min(near, (g.Position - h.Position).Magnitude) end
			end
		end
		local quiver = near < 20 and (1 - near / 20) * 0.03 + 0.01 or (lv == 2 and 0.008 or 0)
		local lookX, lookY = 0, 0
		if h then -- glance toward the camp light (the nearest safe light), as the camera sees it
			local to = workspace.CurrentCamera.CFrame:VectorToObjectSpace(C.CAVE_ORIGIN - h.Position)
			if to.Magnitude > 6 then
				lookX = math.clamp(to.X / 40, -1, 1) * 0.035
				lookY = (to.Z > 0 and 0.012 or -0.012) -- behind us: the eyes drop; ahead: they lift
			end
		end
		face.Position = UDim2.fromScale(0.5 + lookX + math.sin(now * 47) * quiver, 0.39 + lookY + math.cos(now * 53) * quiver)
		face.Rotation = lv == 2 and math.sin(now * 40) * 5 * (fear - 0.5) or 0
		-- flare collar
		local fl = plr:GetAttribute("Flares") or C.GLOOM.flares
		if fl ~= lastFl then
			if lastFl and fl < lastFl then
				flareAt = now
				bump(collar, 1.25)
			end
			lastFl = fl
			count.Text = "x" .. fl
			collar.BackgroundColor3 = fl > 0 and PLUM or Color3.fromRGB(70, 60, 86)
			count.TextColor3 = fl > 0 and CREAM or PINK
		end
		wipe.root.Visible = fl <= 0 or now - flareAt < 1.5
		wipe.set(fl > 0 and math.clamp(1 - (now - flareAt) / 1.5, 0, 1) or 1) -- a short recharge sweep after each flare; spent = covered
		-- numbers
		tipBox.Visible = now < tipUntil
		if tipBox.Visible then
			tipT.Text = "HP " .. hp .. "   TORCH " .. math.floor(fuel * 100 + 0.5) .. "%   " .. (lv == 0 and "CALM" or (lv == 1 and "UNEASY" or "SCARED"))
		end
	end)
	return root
end

return M
