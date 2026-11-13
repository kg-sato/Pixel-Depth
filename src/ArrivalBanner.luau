-- ArrivalBanner (ReplicatedStorage.Shared.ArrivalBanner), started by PixelClient with the cut-glass kit. Directive v8: the
-- logo's liquid-light landing is also the arrival banner of each place. When you step out of the cart in the caves, come up
-- to town, or walk into the Clay Caves hall, the place's name lands across the upper screen in jelly letters, one by one, each
-- tall and thin first and springing to shape, the whole word shaking as the last one lands (the motion measured on the
-- reference reel, see Shared.LoadingScreen), with a small line under it. It holds two seconds and lifts away. Display only.
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local M = {}

local MID = Vector2.new(0.5, 0.5)

function M.start(E)
	if not E.GLASS then return end
	local JellyText = require(script.Parent:WaitForChild("JellyText"))
	local plr, C, new = E.plr, E.C, E.new
	local calm = false
	pcall(function() calm = game:GetService("GuiService").ReducedMotionEnabled end)
	local root = new("Frame", E.top, { Name = "Arrival", Size = UDim2.fromScale(0.6, 0.2), Position = UDim2.fromScale(0.5, 0.24), AnchorPoint = MID, BackgroundTransparency = 1, Visible = false, ZIndex = 4 })
	local scale = new("UIScale", root, {})
	local wordBox = new("Frame", root, { Size = UDim2.fromScale(1, 0.66), BackgroundTransparency = 1, ZIndex = 4 })
	local word = JellyText.new(wordBox, "ROOTHOLM", { glow = true, z = 4 })
	local sub = new("TextLabel", root, { Text = "", Font = E.HEAD, TextScaled = true, TextColor3 = Color3.new(1, 1, 1), TextStrokeTransparency = 0.3, TextStrokeColor3 = Color3.fromRGB(30, 21, 58), BackgroundTransparency = 1, Size = UDim2.fromScale(0.6, 0.22), Position = UDim2.fromScale(0.5, 0.84), AnchorPoint = MID, TextTransparency = 1, ZIndex = 4 })
	local token = 0

	local function show(name, line, color)
		token += 1
		local my = token
		word.tint(color)
		word.set(name)
		sub.Text, sub.TextTransparency = line, 1
		root.Visible, root.Position, root.Rotation = true, UDim2.fromScale(0.5, 0.24), 0
		for _, g in word.glyphs do g.img.ImageTransparency = 0 if g.glow then g.glow.ImageTransparency = 0.62 end end
		if calm then
			scale.Scale = 1
		else
			word.pop(0.07) -- one letter after the other
			local n = #word.glyphs
			scale.Scale = 1
			task.delay(n * 0.07 + 0.1, function() -- the shake as the last letter lands: thrown right, sprung back
				if my ~= token then return end
				word.pop(0) -- every letter wobbles together
				root.Position = UDim2.fromScale(0.535, 0.245)
				root.Rotation = 2
				TweenService:Create(root, TweenInfo.new(0.5, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), { Position = UDim2.fromScale(0.5, 0.24), Rotation = 0 }):Play()
				scale.Scale = 1.06
				TweenService:Create(scale, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
				pcall(E.sfx, "land", 1.1)
			end)
		end
		TweenService:Create(sub, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.5), { TextTransparency = 0 }):Play()
		task.delay(2.6, function()
			if my ~= token then return end
			TweenService:Create(root, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = UDim2.fromScale(0.5, 0.16) }):Play()
			TweenService:Create(sub, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
			for _, g in word.glyphs do
				TweenService:Create(g.img, TweenInfo.new(0.3), { ImageTransparency = 1 }):Play()
				if g.glow then TweenService:Create(g.glow, TweenInfo.new(0.3), { ImageTransparency = 1 }):Play() end
			end
			task.delay(0.4, function() if my == token then root.Visible = false end end)
		end)
	end

	-- where am I: town, Camp 1's caves, or the Clay Caves hall (the same test the death screen uses)
	local place, since, first = nil, 0, true
	RunService.Heartbeat:Connect(function()
		local now = os.clock()
		if now - since < 0.5 then return end
		since = now
		if plr:GetAttribute("Seated") or E.isBusy() then return end
		local h = E.hrp()
		if not h then return end
		local here = "town"
		if plr:GetAttribute("InCave") then
			here = (C.CAVE2_ORIGIN and (h.Position - C.CAVE2_ORIGIN).Magnitude < 130) and "clay" or "camp1"
		end
		if here ~= place then
			place = here
			if first then first = false return end -- not at the very start: the loading logo has just played
			if here == "town" then show("HOLLOW MOUNTAIN", "the miners' town", Color3.fromRGB(255, 205, 80))
			elseif here == "clay" then show(string.upper(C.LAYERS[2][1]), string.lower(C.LAYERS[2][2]), Color3.fromRGB(255, 120, 190))
			else show(string.upper(C.LAYERS[1][1]), "camp 1  -  " .. string.lower(C.LAYERS[1][2]), Color3.fromRGB(110, 215, 255)) end
		end
	end)
	plr:GetAttributeChangedSignal("DevArrival"):Connect(function() -- Studio test hook
		if plr:GetAttribute("DevArrival") then show(string.upper(C.LAYERS[1][1]), "camp 1  -  " .. string.lower(C.LAYERS[1][2]), Color3.fromRGB(110, 215, 255)) end
	end)
end

return M
