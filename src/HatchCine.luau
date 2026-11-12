-- HatchCine (ReplicatedStorage.Shared.HatchCine), started by PixelClient. The Secret hatch plays as a cutscene on top
-- of the normal hatch show (PixelClient.hatchShow calls E.vmHook.hatchCine for the Secret tier only):
--   letterbox bars close in, the egg camera pushes in (its field of view drops from 30 to 20 while the egg builds),
--   the shell rattles harder and harder (the whole stage jolts, the world camera shakes), a long white flash on the
--   burst with a thud, then the bar edges light up and the bars keep the frame until the card is closed (the hatch
--   show itself names the pet and its rarity).
-- Display only. Under Reduced Motion the rattle and the long flash are left out.
local M = {}

function M.start(E)
	local RunService, TweenService = game:GetService("RunService"), game:GetService("TweenService")
	local new = E.new
	local calm = false
	pcall(function() calm = game:GetService("GuiService").ReducedMotionEnabled end)
	local BLACK = Color3.fromRGB(8, 5, 14)

	E.vmHook.hatchCine = function(h) -- h: ov (the overlay), stage (shaken as one piece), vcam (the egg camera), buildT (seconds the egg builds)
		-- the game HUD steps out for the whole scene and the town behind goes almost black (Gemini r1: the dimmed HUD bled through the framing)
		E.gui.Enabled = false
		h.ov.Destroying:Connect(function() E.gui.Enabled = true end)
		task.delay(0.35, function() if h.ov.Parent then TweenService:Create(h.ov, TweenInfo.new(0.4), { BackgroundTransparency = 0.03 }):Play() end end)
		local bars = {}
		for i, y in { 0, 1 } do
			local b = new("Frame", h.ov, { Size = UDim2.fromScale(1, 0.085), Position = UDim2.fromScale(0, y == 0 and -0.085 or 1), BackgroundColor3 = BLACK, BorderSizePixel = 0, ZIndex = 34 })
			local edge = new("Frame", b, { Size = UDim2.new(1, 0, 0, 2), Position = UDim2.fromScale(0, y == 0 and 1 or 0), AnchorPoint = Vector2.new(0, y == 0 and 1 or 0), BackgroundColor3 = E.WHITE, BackgroundTransparency = 0.6, BorderSizePixel = 0, ZIndex = 35 })
			TweenService:Create(b, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Position = UDim2.fromScale(0, y == 0 and 0 or 0.915) }):Play()
			bars[i] = { b, edge }
		end
		TweenService:Create(h.vcam, TweenInfo.new(h.buildT, Enum.EasingStyle.Sine, Enum.EasingDirection.In), { FieldOfView = 20 }):Play() -- the push in
		local t0, live = os.clock(), true
		local conn
		conn = RunService.RenderStepped:Connect(function()
			if not live or not h.stage.Parent then conn:Disconnect() return end
			if calm then return end
			local u = math.clamp((os.clock() - t0) / h.buildT, 0, 1)
			local beat = (os.clock() - t0) % (0.55 - 0.3 * u) -- rattles come faster toward the end
			local jolt = math.exp(-beat * 14) * u
			h.stage.Rotation = math.sin(os.clock() * 70) * 2.2 * jolt
			if beat < 0.03 and u > 0.25 then E.shake(0.25 + 0.5 * u) end
		end)
		return {
			burst = function()
				live = false
				h.stage.Rotation = 0
				local white = new("Frame", h.ov, { Size = UDim2.fromScale(1, 1), BackgroundColor3 = E.WHITE, BackgroundTransparency = 0, BorderSizePixel = 0, ZIndex = 33 })
				TweenService:Create(white, TweenInfo.new(calm and 0.2 or 0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 }):Play()
				task.delay(0.8, function() white:Destroy() end)
				if not calm then E.shake(1) end
				task.delay(0.25, function() -- after the white has thinned: the bar edges light up and a thud lands
					pcall(E.sfx, "land", 0.7)
					for _, bar in bars do bar[2].BackgroundTransparency = 0 end
				end)
				task.delay(0.5, function() -- a rainbow SECRET badge pops onto the foot of the card: the rarity gets its own tier, apart from the perk line
					if not h.ov.Parent then return end
					local badge = new("Frame", h.ov, { Size = UDim2.fromScale(0.1, 0.045), Position = UDim2.fromScale(0.5, 0.715), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = E.WHITE, BorderSizePixel = 0, ZIndex = 36 })
					new("UICorner", badge, { CornerRadius = UDim.new(0.5, 0) })
					new("UIStroke", badge, { Color = E.INK, Thickness = 3 })
					new("UIGradient", badge, { Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 170, 190)), ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 226, 140)), ColorSequenceKeypoint.new(0.66, Color3.fromRGB(150, 230, 196)), ColorSequenceKeypoint.new(1, Color3.fromRGB(190, 170, 244)) }) })
					local word = E.text(badge, "SECRET", UDim2.fromScale(0.8, 0.66), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5), E.INK, 700, false)
					word.ZIndex = 37
					local sc = new("UIScale", badge, { Scale = calm and 1 or 0.2 })
					TweenService:Create(sc, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
				end)
			end,
		}
	end
end

return M
