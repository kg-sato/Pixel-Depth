-- DeathScreen (ReplicatedStorage.Shared.DeathScreen), started by PixelClient (the user's overnight directive, 2026-11-10: the
-- defeat screen was a bare line of text on black). E.vmHook.death(lost, why) plays when the server has woken us at Camp 1
-- after a fall ("fell") or a faint in the lake:
--   1 the view tumbles and the dark closes in from the screen edges, with soot drifting to the centre
--   2 a soft card: LOST TO THE GLOOM, and the lost ore counting down to nothing
--   3 the dark lifts on the campfire with a burst of embers (WorldFX adds the groggy wake)
local M = {}

function M.start(E)
	local RunService = game:GetService("RunService")
	local new, text, tween, top = E.new, E.text, E.tween, E.top
	local DARK, SOOT = Color3.fromRGB(22, 14, 36), Color3.fromRGB(60, 38, 92)
	local calm = false
	pcall(function() calm = game:GetService("GuiService").ReducedMotionEnabled end)

	local layer = new("Frame", top, { Name = "DeathScreen", Size = UDim2.fromScale(1, 1), BackgroundColor3 = DARK, BackgroundTransparency = 1, Visible = false, ZIndex = 60 })
	local edges = {}
	for i, rot in { 0, 180, 90, 270 } do -- four soft bands of dark that close in from the edges
		local f = new("Frame", layer, { Size = UDim2.fromScale(1, 1), BackgroundColor3 = SOOT, BorderSizePixel = 0, ZIndex = 61 })
		new("UIGradient", f, { Rotation = rot, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.35, 1), NumberSequenceKeypoint.new(1, 1) }) })
		edges[i] = f
	end
	local card = E.panel(layer, UDim2.fromScale(0.42, 0.3), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5), "card")
	card.ZIndex = 63
	new("UIAspectRatioConstraint", card, { AspectRatio = 2.6 })
	local title = text(card, "LOST TO THE GLOOM", UDim2.fromScale(0.86, 0.26), UDim2.fromScale(0.5, 0.24), Vector2.new(0.5, 0.5), E.LILAC, 700)
	local tally = text(card, "", UDim2.fromScale(0.8, 0.24), UDim2.fromScale(0.5, 0.54), Vector2.new(0.5, 0.5), E.PINK, 700, false)
	local note = text(card, "You wake by the campfire.", UDim2.fromScale(0.8, 0.14), UDim2.fromScale(0.5, 0.8), Vector2.new(0.5, 0.5), E.CREAM, 700, false)
	title.ZIndex, tally.ZIndex, note.ZIndex = 64, 64, 64
	local scale = new("UIScale", card, { Scale = 1 })

	local tumbleAt = -10
	RunService:BindToRenderStep("PD_DeathTumble", Enum.RenderPriority.Camera.Value + 3, function()
		local t = (os.clock() - tumbleAt) / 0.9
		if t >= 1 or calm then return end
		local k = (1 - t) ^ 2 -- the view rolls over and looks up at the way we fell, then settles
		local cam = workspace.CurrentCamera
		cam.CFrame = cam.CFrame * CFrame.Angles(0.9 * k, 0, 1.4 * k * math.sin(t * 5))
	end)

	local playing = false
	E.vmHook.death = function(lost, why)
		if playing then return end
		playing = true
		lost = lost or 0
		tumbleAt = os.clock()
		title.Text = why == "fell" and "LOST TO THE GLOOM" or "THE LAKE TOOK YOU"
		tally.Text = lost > 0 and ("-" .. E.commas(lost) .. " ORE") or "NOTHING LOST"
		layer.Visible, layer.BackgroundTransparency, card.Visible = true, 1, false
		for _, f in edges do f.BackgroundTransparency = 1 end
		tween(layer, 0.5, { BackgroundTransparency = 0.08 })
		for _, f in edges do tween(f, 0.35, { BackgroundTransparency = 0 }) end
		E.sfx("land", 0.6)
		if not calm then -- soot: small dark flakes drift from the edges to the middle
			for _ = 1, 26 do
				local a = math.random() * math.pi * 2
				local s = math.random(6, 16)
				local p = new("Frame", layer, { Size = UDim2.fromOffset(s, s), Position = UDim2.fromScale(0.5 + math.cos(a) * 0.62, 0.5 + math.sin(a) * 0.62), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = SOOT:Lerp(Color3.new(0, 0, 0), math.random() * 0.5), BorderSizePixel = 0, Rotation = math.random(0, 90), ZIndex = 62 })
				tween(p, 1.1 + math.random() * 0.8, { Position = UDim2.fromScale(0.5 + math.cos(a) * 0.12, 0.5 + math.sin(a) * 0.12), BackgroundTransparency = 1, Rotation = p.Rotation + 180 }, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
				task.delay(2, function() p:Destroy() end)
			end
		end
		task.delay(0.55, function()
			card.Visible, scale.Scale = true, 0.8
			tween(scale, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
			E.sfx("error", 0.7)
			if lost > 0 then -- the lost ore counts down to nothing
				local t0 = os.clock()
				while os.clock() - t0 < 0.9 do
					tally.Text = "-" .. E.commas(math.ceil(lost * (1 - (os.clock() - t0) / 0.9))) .. " ORE"
					task.wait(0.04)
				end
				tally.Text = "-" .. E.commas(lost) .. " ORE"
			end
		end)
		task.delay(2.7, function()
			tween(scale, 0.2, { Scale = 0.85 })
			tween(layer, 0.7, { BackgroundTransparency = 1 })
			for _, f in edges do tween(f, 0.7, { BackgroundTransparency = 1 }) end
			task.delay(0.2, function() card.Visible = false end)
			local h = E.hrp()
			if h and E.burst then E.burst(h.Position + h.CFrame.LookVector * 4 - Vector3.new(0, 2, 0), Vector3.yAxis, Color3.fromRGB(255, 170, 84), 26) end -- embers
			task.delay(0.72, function()
				layer.Visible = false
				playing = false
			end)
		end)
	end
	E.vmHook.deathPlaying = function() return playing end
end

return M
