-- CaveWeather (ReplicatedStorage.Shared.CaveWeather), started by PixelClient: the look and sound of the two cave events that
-- ServerScriptService.CaveEvents runs (the user's overnight directive, 2026-11-10).
--   * Roots Stirring: while workspace.RootsStirAt is ahead, a ribbon at the bottom centre carries the warning with a
--     countdown (the top centre holds the step card and prompt bubbles), the ground rumbles and the view trembles harder as the time comes. Fx "rootsSweep": the roots
--     carried us to Camp 1: a root-brown wipe and one line.
--   * Spore storm: while workspace.SporeStorm is ahead and we are in the caves, the air turns turquoise and hazy, glowing
--     spores drift past, and every deposit glints twice as bright. One line when it starts and one when it ends.
local M = {}

function M.start(E)
	local Lighting, RunService = game:GetService("Lighting"), game:GetService("RunService")
	local plr, hook, tween, sfx, new = E.plr, E.vmHook, E.tween, E.sfx, E.new
	local BASE = E.C.CAVE_LIGHT.Atmosphere
	local TEAL = Color3.fromRGB(72, 214, 196)
	local calm = false
	pcall(function() calm = game:GetService("GuiService").ReducedMotionEnabled end)

	-- spores: one emitter on a block that rides with the camera
	local box = new("Part", workspace:FindFirstChild("ClientFX") or workspace, { Name = "SporeBox", Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Transparency = 1, Size = Vector3.new(60, 24, 60) })
	local spores = new("ParticleEmitter", box, {
		Rate = 0, Lifetime = NumberRange.new(4, 7), Speed = NumberRange.new(0.6, 2), SpreadAngle = Vector2.new(180, 180), Color = ColorSequence.new(TEAL),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.2, 0.5), NumberSequenceKeypoint.new(1, 0) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, 0.25), NumberSequenceKeypoint.new(1, 1) }),
		LightEmission = 0.6, Shape = Enum.ParticleEmitterShape.Box, Acceleration = Vector3.new(0.4, 0.15, 0.2),
		Texture = "rbxasset://textures/particles/smoke_main.dds",
	})
	local wipe = new("Frame", E.top, { Name = "RootsWipe", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(46, 34, 44), BackgroundTransparency = 1, Visible = false, ZIndex = 55 })

	local ribbon = new("Frame", E.gui, { Size = E.S(560, 42), Position = E.S(640, 462), AnchorPoint = Vector2.new(0.5, 1), BackgroundColor3 = Color3.fromRGB(36, 18, 54), BorderSizePixel = 0 }) -- 2026-11-18: obsidian amethyst with a pulsing rose rim (Gemini UI round 1: the hot magenta slab fought the cave light); was warning red (Gemini, 2026-11-10: a pale pink pill had no urgency)
	E.fit(ribbon, 560, 42)
	new("UICorner", ribbon, { CornerRadius = UDim.new(0.5, 0) })
	local rstroke = new("UIStroke", ribbon, { Color = Color3.fromRGB(255, 107, 151), Thickness = 2.5 })
	new("UIGradient", ribbon, { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255, 235, 255), Color3.fromRGB(150, 125, 175)) }) -- multiplies the fill: lit top, deeper bottom
	game:GetService("TweenService"):Create(rstroke, TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Transparency = 0.55, Thickness = 1.5 }):Play() -- the urgency now pulses in the rim
	ribbon.Name, ribbon.Visible = "RootsRibbon", false
	local ribbonText = E.text(ribbon, "", UDim2.fromScale(0.84, 0.56), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5), Color3.fromRGB(255, 214, 140), 700) -- inside the round ends: the countdown touched the rim (Gemini round 1)
	local cc = new("ColorCorrectionEffect", Lighting, { Name = "SporeTint", TintColor = Color3.new(1, 1, 1) })
	local storm, glints, nextRumble, lastLeft = false, {}, 0, nil
	local function setStorm(on, inCave)
		if on == storm then return end
		storm = on
		local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
		if atmo and (on or inCave) then -- when you leave the caves mid-storm PixelClient sets the town's air: no tween back to cave values
			tween(atmo, 2.5, on and { Color = TEAL:Lerp(BASE.Color, 0.45), Decay = TEAL:Lerp(BASE.Decay, 0.6), Density = BASE.Density + 0.16, Haze = 2.4 }
				or { Color = BASE.Color, Decay = BASE.Decay, Density = BASE.Density, Haze = BASE.Haze })
		end
		tween(cc, 2.5, { TintColor = on and Color3.fromRGB(196, 255, 244) or Color3.new(1, 1, 1), Brightness = on and 0.04 or 0 })
		spores.Rate = (on and not calm) and 160 or 0
		local deps = workspace:FindFirstChild("Caves") and workspace.Caves:FindFirstChild("Deposits")
		if on then
			for _, d in deps and deps:GetDescendants() or {} do
				if d:IsA("PointLight") and d.Name == "Glint" then glints[d] = d.Brightness d.Brightness *= 1.5 end -- x2 burned the nearest vein out to a white ball
			end
			E.toast("SPORE STORM! FLAWLESS STRIKES GIVE +50% ORE", TEAL, true)
			sfx("sparkle", 0.7)
		else
			for d, b in glints do if d.Parent then d.Brightness = b end end
			table.clear(glints)
			if inCave then E.toast("The spores settle.", TEAL, false) end
		end
	end

	E.R.Fx.OnClientEvent:Connect(function(kind)
		if kind ~= "rootsSweep" then return end
		wipe.Visible, wipe.BackgroundTransparency = true, 0
		sfx("land", 0.5)
		E.shake(0.5)
		tween(wipe, 1.2, { BackgroundTransparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		task.delay(1.25, function() wipe.Visible = false end)
		E.toast("The roots carried you back to camp. Nothing lost.", E.MINT, true, 0.6)
	end)

	RunService.Heartbeat:Connect(function()
		local now = workspace:GetServerTimeNow()
		local inCave = plr:GetAttribute("InCave") == true
		box.Position = workspace.CurrentCamera.CFrame.Position
		local ends = workspace:GetAttribute("SporeStorm")
		setStorm(inCave and ends ~= nil and now < ends, inCave)
		local at = workspace:GetAttribute("RootsStirAt")
		local left = at and inCave and math.ceil(at - now) or nil
		if left and left > 0 then
			if left ~= lastLeft then
				lastLeft = left
				ribbonText.Text = ("THE WORLD TREE ROOTS ARE STIRRING  -  RETURN TO CAMP  %d:%02d"):format(left // 60, left % 60)
				E.pop(ribbon, 1.08, 0.3)
			end
			if os.clock() >= nextRumble then -- a rumble and a tremble, closer together and harder as the time comes
				local k = 1 - math.clamp(left / E.C.EVENTS.rootsWarn, 0, 1)
				nextRumble = os.clock() + 4 - 3 * k
				sfx("land", 0.45 + 0.1 * k)
				if not calm then E.shake(0.08 + 0.3 * k) end
			end
		else
			lastLeft = nil
		end
		local hud = E.gui:FindFirstChild("CaveHud")
		local loot = hud and hud:FindFirstChild("ResultDim")
		ribbon.Visible = left ~= nil and left > 0 and not (E.isBusy and E.isBusy()) and not (loot and loot.Visible) -- not under a minigame or its loot card
	end)
end

return M
