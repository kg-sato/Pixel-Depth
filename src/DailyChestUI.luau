-- DailyChestUI (ReplicatedStorage.Shared.DailyChestUI), started by PixelClient. The daily chest show, moved out of PixelClient
-- (directive v8, 2026-11-12: keep PixelClient under the size line) and rebuilt for the cut-glass kit: the chest is a real 3D
-- model in a ViewportFrame whose lid swings open on its hinge, on a frosted glass card. The seven steps of the opening come from
-- a saved reference (Instagram Deo9lu7tzCT, @vasilev.yegor; vault: Instagram Saved Posts Review 2026-11-12): 1 a wobble that
-- speeds up and a squash, 2 a spring stretch, 3 the slam with a short freeze, 4 light from inside, 5 a shockwave ring,
-- 6 stars that fly and pop, 7 floating dust. Coins and gems then fly to their pills. Display only: the server grants the chest.
-- Returns { show(gold, streak, gems), fly(iconName, from, toObj, n, delay) }.
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local M = {}

function M.start(E)
	local gui, new, S, panel, fit, text, icon, button, tween, pop, sfx, shake = E.gui, E.new, E.S, E.panel, E.fit, E.text, E.icon, E.button, E.tween, E.pop, E.sfx, E.shake
	local commas, ICON, DEEP, goldPill, gemPill, WHITE, BUTTER, PLUM_SOFT, DEEP_GEM, GLASS = E.commas, E.ICON, E.DEEP, E.goldPill, E.gemPill, E.WHITE, E.BUTTER, E.PLUM_SOFT, E.DEEP_GEM, E.GLASS
	local function scaler(o) return o:FindFirstChild("Pop") or new("UIScale", o, { Name = "Pop" }) end
	local FX_GLOW, FX_RAYS = "rbxassetid://77591933607769", "rbxassetid://98789616938156"
	local CHEST = { closed = "rbxassetid://139518055862953", open = "rbxassetid://120090896134682" } -- brass-bound field chest (art/icons_notebook); the pink one was 97587431872757 / 130450967787337
	task.spawn(function() -- load the chest art up front, or the open frame blinks empty on first use
		local warm = {}
		for _, id in CHEST do table.insert(warm, new("ImageLabel", nil, { Image = id })) end
		pcall(function() game:GetService("ContentProvider"):PreloadAsync(warm) end)
	end)
	-- the daily chest show, in its own layer above everything
	local layer = new("ScreenGui", gui.Parent, { Name = "DailyChest", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 12, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Enabled = false })
	local scrim = new("TextButton", layer, { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(26, 18, 40), BackgroundTransparency = 1, Text = "", AutoButtonColor = false })
	local rays = new("ImageLabel", layer, { Image = FX_RAYS, ImageColor3 = Color3.fromRGB(255, 226, 150), BackgroundTransparency = 1, ImageTransparency = 1, Size = S(560, 560), Position = S(640, 268), AnchorPoint = Vector2.new(0.5, 0.5) })
	new("UIAspectRatioConstraint", rays, { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height })
	local glow = new("ImageLabel", layer, { Image = FX_GLOW, ImageColor3 = Color3.fromRGB(255, 220, 160), BackgroundTransparency = 1, ImageTransparency = 1, Size = S(420, 420), Position = S(640, 268), AnchorPoint = Vector2.new(0.5, 0.5) })
	new("UIAspectRatioConstraint", glow, { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height })
	-- the chest: with the cut-glass kit a real 3D chest in a ViewportFrame whose lid swings open on its hinge; otherwise the painted picture
	local chest, lidOpen = nil, false
	local setLid
	if GLASS then
		chest = new("ViewportFrame", layer, { BackgroundTransparency = 1, Size = S(280, 280), Position = S(640, 268), AnchorPoint = Vector2.new(0.5, 0.5), Ambient = Color3.fromRGB(150, 130, 190), LightColor = Color3.fromRGB(255, 240, 215), LightDirection = Vector3.new(-0.5, -1, -0.6) })
		local cam = new("Camera", chest, { FieldOfView = 34, CFrame = CFrame.lookAt(Vector3.new(5.2, 4.6, 8.4), Vector3.new(0, 1.5, 0)) })
		chest.CurrentCamera = cam
		local WOOD, WOOD_D, BRASS, BRASS_D = Color3.fromRGB(156, 100, 60), Color3.fromRGB(104, 64, 40), Color3.fromRGB(240, 196, 96), Color3.fromRGB(176, 124, 40)
		local function box(size, cf, color, mat)
			return new("Part", chest, { Size = size, CFrame = cf, Color = color, Material = mat or Enum.Material.SmoothPlastic, Anchored = true, TopSurface = Enum.SurfaceType.Smooth, BottomSurface = Enum.SurfaceType.Smooth })
		end
		box(Vector3.new(4.4, 2.2, 3), CFrame.new(0, 1.1, 0), WOOD)
		box(Vector3.new(4.5, 0.3, 3.1), CFrame.new(0, 0.15, 0), WOOD_D)
		for _, x in { -1.5, 1.5 } do box(Vector3.new(0.5, 2.24, 3.08), CFrame.new(x, 1.1, 0), BRASS, Enum.Material.Metal) end
		box(Vector3.new(4.48, 0.26, 3.08), CFrame.new(0, 2.1, 0), BRASS_D, Enum.Material.Metal)
		box(Vector3.new(0.8, 0.9, 0.2), CFrame.new(0, 1.75, 1.56), BRASS, Enum.Material.Metal) -- the lock plate
		box(Vector3.new(0.26, 0.34, 0.24), CFrame.new(0, 1.66, 1.6), Color3.fromRGB(60, 36, 26))
		local glowIn = box(Vector3.new(3.9, 0.3, 2.5), CFrame.new(0, 2.14, 0), Color3.fromRGB(255, 226, 130), Enum.Material.Neon) -- the light of the treasure, seen when the lid is up
		glowIn.Transparency = 1
		local hinge = CFrame.new(0, 2.24, -1.5)
		local lid = {}
		local function lidPart(size, off, color, mat) table.insert(lid, { p = box(size, hinge * off, color, mat), off = off }) end
		lidPart(Vector3.new(4.4, 0.8, 3), CFrame.new(0, 0.4, 1.5), WOOD)
		lidPart(Vector3.new(4.4, 0.5, 2.3), CFrame.new(0, 1.05, 1.5), WOOD)
		lidPart(Vector3.new(4.4, 0.3, 1.4), CFrame.new(0, 1.45, 1.5), WOOD_D)
		for _, x in { -1.5, 1.5 } do
			lidPart(Vector3.new(0.5, 0.84, 3.08), CFrame.new(x, 0.4, 1.5), BRASS, Enum.Material.Metal)
			lidPart(Vector3.new(0.5, 0.54, 2.38), CFrame.new(x, 1.05, 1.5), BRASS, Enum.Material.Metal)
			lidPart(Vector3.new(0.5, 0.34, 1.48), CFrame.new(x, 1.45, 1.5), BRASS, Enum.Material.Metal)
		end
		lidPart(Vector3.new(0.8, 0.5, 0.2), CFrame.new(0, 0.3, 3.06), BRASS_D, Enum.Material.Metal)
		local angle = new("NumberValue", chest, { Name = "Lid" })
		angle.Changed:Connect(function(a)
			for _, l in lid do l.p.CFrame = hinge * CFrame.Angles(-a, 0, 0) * l.off end
		end)
		setLid = function(open)
			lidOpen = open
			glowIn.Transparency = open and 0 or 1
			if open then tween(angle, 0.22, { Value = math.rad(112) }, Enum.EasingStyle.Back) else angle.Value = 0 end
		end
	else
		chest = new("ImageLabel", layer, { Image = CHEST.closed, BackgroundTransparency = 1, Size = S(250, 250), Position = S(640, 268), AnchorPoint = Vector2.new(0.5, 0.5), ScaleType = Enum.ScaleType.Fit })
		setLid = function(open)
			lidOpen = open
			chest.Image = open and CHEST.open or CHEST.closed
		end
	end
	new("UIAspectRatioConstraint", chest, { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height })
	local title = panel(layer, S(440, 84), S(640, 70), Vector2.new(0.5, 0.5), "ribbonPink")
	fit(title, 440, 84)
	local titleT = text(title, "DAILY CHEST", UDim2.fromScale(0.62, 0.52), UDim2.fromScale(0.5, 0.42), Vector2.new(0.5, 0.5), WHITE)
	titleT.TextStrokeColor3 = DEEP.ribbonPink
	local card = panel(layer, S(640, 210), S(640, 486), Vector2.new(0.5, 0.5), "panel") -- the kit card holding rewards, streak and COLLECT
	fit(card, 640, 210)
	card.Visible = false
	local reward = panel(layer, S(420, 64), S(640, 418), Vector2.new(0.5, 0.5), "pill")
	fit(reward, 420, 64)
	local rCoin = icon(reward, "coin", UDim2.fromScale(0.12, 0.62), UDim2.fromScale(0.12, 0.5), Vector2.new(0.5, 0.5))
	new("UIAspectRatioConstraint", rCoin, { AspectRatio = 1 })
	local rGold = text(reward, "", UDim2.fromScale(0.3, 0.5), UDim2.fromScale(0.2, 0.5), Vector2.new(0, 0.5), Color3.fromRGB(184, 122, 26), 700, false)
	rGold.TextXAlignment = Enum.TextXAlignment.Left
	local rGemI = icon(reward, "gem", UDim2.fromScale(0.12, 0.62), UDim2.fromScale(0.58, 0.5), Vector2.new(0.5, 0.5))
	new("UIAspectRatioConstraint", rGemI, { AspectRatio = 1 })
	local rGems = text(reward, "", UDim2.fromScale(0.3, 0.5), UDim2.fromScale(0.66, 0.5), Vector2.new(0, 0.5), DEEP_GEM, 700, false)
	rGems.TextXAlignment = Enum.TextXAlignment.Left
	local track = new("Frame", layer, { Size = S(560, 56), Position = S(640, 500), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1 })
	local bar = new("Frame", track, { Size = UDim2.fromScale(6 / 7, 0.22), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = GLASS and Color3.fromRGB(150, 130, 214) or Color3.fromRGB(205, 188, 150), BorderSizePixel = 0 })
	new("UICorner", bar, { CornerRadius = UDim.new(0.5, 0) })
	new("UIStroke", bar, { Color = GLASS and Color3.fromRGB(46, 30, 96) or Color3.fromRGB(59, 36, 22), Thickness = GLASS and 1.5 or 2 })
	local barFill = new("Frame", bar, { Size = UDim2.fromScale(0, 1), BackgroundColor3 = BUTTER, BorderSizePixel = 0 })
	new("UICorner", barFill, { CornerRadius = UDim.new(0.5, 0) })
	local streakT = text(track, "", UDim2.fromScale(0.4, 0.36), UDim2.fromScale(0.5, -0.22), Vector2.new(0.5, 0.5), PLUM_SOFT, 700, false)
	local days = {}
	for d = 1, 7 do
		local c = new("Frame", track, { Size = UDim2.fromScale(0.11, 0.9), Position = UDim2.fromScale((d - 0.5) / 7, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0 })
		new("UIAspectRatioConstraint", c, { AspectRatio = 1 })
		new("UICorner", c, { CornerRadius = UDim.new(0.5, 0) })
		local st = new("UIStroke", c, { Thickness = 3 })
		local l = text(c, tostring(d), UDim2.fromScale(0.6, 0.55), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5), WHITE)
		if d == 7 then -- the day 7 jackpot: a little chest instead of the number
			l.Visible = false
			new("ImageLabel", c, { Image = CHEST.closed, BackgroundTransparency = 1, Size = UDim2.fromScale(1.25, 1.25), Position = UDim2.fromScale(0.5, 0.45), AnchorPoint = Vector2.new(0.5, 0.5), ScaleType = Enum.ScaleType.Fit, ZIndex = 3 })
		end
		days[d] = { c = c, st = st, l = l }
	end
	local collect = button(layer, "COLLECT", S(220, 64), S(640, 560), Vector2.new(0.5, 0.5), "mint", "coin")
	fit(collect, 220, 64)
	local busy, spin = false, nil
	local flyLayer = new("ScreenGui", gui.Parent, { Name = "RewardFly", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 13 })
	local fly
	fly = function(iconName, from, toObj, n, delay0)
		local inset = GuiService:GetGuiInset()
		for k = 1, n do
			task.delay(delay0 + k * 0.05, function()
				local to = toObj.AbsolutePosition + toObj.AbsoluteSize * Vector2.new(0.15, 0.5) + inset
				local ic = icon(flyLayer, iconName, UDim2.fromOffset(34, 34), from, Vector2.new(0.5, 0.5))
				ic.ZIndex = 20
				local mid = from + UDim2.fromOffset(math.random(-160, 160), -math.random(80, 180))
				tween(ic, 0.35, { Position = mid, Rotation = math.random(-90, 90) }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out).Completed:Connect(function()
					tween(ic, 0.4, { Position = UDim2.fromOffset(to.X, to.Y), Size = UDim2.fromOffset(20, 20) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In).Completed:Connect(function()
						ic:Destroy()
						sfx("coin", (1 + k * 0.03) * (0.95 + math.random() * 0.1))
						if k % 3 == 1 then pop(toObj, 1.12, 0.2) end -- the pill takes each landing
					end)
				end)
			end)
		end
	end
	local function show(gold, streak, gems)
		if busy then return end
		busy = true
		layer.Enabled = true
		setLid(false)
		chest.Rotation = 0
		rays.ImageTransparency, glow.ImageTransparency, scrim.BackgroundTransparency = 1, 1, 1
		titleT.Text = "DAY " .. streak .. " CHEST"
		rGold.Text, rGems.Text = "+" .. commas(gold), "+" .. commas(gems)
		for _, o in { title, reward, track, collect, card } do o.Visible = false end
		barFill.Size = UDim2.fromScale(0, 1)
		streakT.Text = streak >= 7 and "7 DAY STREAK! JACKPOT" or (streak .. " DAY STREAK  -  DAY 7 JACKPOT")
		tween(scrim, 0.25, { BackgroundTransparency = 0.25 })
		-- drop in
		chest.Position = S(640, 120)
		scaler(chest).Scale = 0.8
		tween(chest, 0.45, { Position = S(640, 268) }, Enum.EasingStyle.Bounce)
		tween(scaler(chest), 0.45, { Scale = 1 }, Enum.EasingStyle.Back)
		title.Visible = true
		pop(title, 0.6, 0.35)
		-- wind-up (chest opening in 7 steps, vasilev.yegor reel, vault Instagram Saved Posts Review 2026-11-12):
		-- 1 the wobble gets faster and harder, then the chest squashes down; 2 it springs up tall
		local ratio = chest:FindFirstChildOfClass("UIAspectRatioConstraint") -- squash and stretch: width through the ratio, height through the scale
		ratio.AspectRatio = 1
		local t0, gap = 0.55, 0.22
		for k = 1, 7 do
			task.delay(t0, function()
				sfx("swing", 0.8 + k * 0.08)
				local a = 3 + k * 1.6
				tween(chest, gap * 0.4, { Rotation = (k % 2 == 0) and a or -a }).Completed:Connect(function() tween(chest, gap * 0.4, { Rotation = 0 }) end)
			end)
			t0 += gap
			gap *= 0.8
		end
		task.delay(1.4, function()
			tween(ratio, 0.1, { AspectRatio = 1.32 })
			tween(scaler(chest), 0.1, { Scale = 0.84 })
		end)
		task.delay(1.52, function()
			tween(ratio, 0.07, { AspectRatio = 0.8 })
			tween(scaler(chest), 0.07, { Scale = 1.18 }, Enum.EasingStyle.Back)
		end)
		-- burst open: a flash, rays and glow, the lid flips (open art), coins and gems fly to the pills
		task.delay(1.6, function()
			setLid(true)
			sfx("upgrade", 1)
			sfx("sparkle", 1.2)
			-- 3 slam: the lid flies open, the picture holds for a few frames (hit-stop), then everything lets go
			scaler(chest).Scale = 1.3
			task.wait(0.07)
			tween(scaler(chest), 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
			tween(ratio, 0.45, { AspectRatio = 1 }, Enum.EasingStyle.Elastic)
			do -- 5 shockwave: a ring of light rushes out on the slam
				local ring = new("Frame", layer, { Size = S(80, 80), Position = S(640, 290), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, ZIndex = 4 })
				new("UIAspectRatioConstraint", ring, { AspectRatio = 1.9, DominantAxis = Enum.DominantAxis.Height })
				new("UICorner", ring, { CornerRadius = UDim.new(0.5, 0) })
				local rs = new("UIStroke", ring, { Color = Color3.fromRGB(255, 240, 190), Thickness = 7 })
				tween(ring, 0.4, { Size = S(520, 520) }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
				tween(rs, 0.4, { Transparency = 1, Thickness = 1 }).Completed:Connect(function() ring:Destroy() end)
			end
			glow.ImageTransparency, rays.ImageTransparency = 0, 0.2
			scaler(glow).Scale = 0.4
			tween(scaler(glow), 0.4, { Scale = 1 }, Enum.EasingStyle.Back)
			tween(glow, 0.6, { ImageTransparency = 0.35 })
			if spin then spin:Disconnect() end
			spin = RunService.RenderStepped:Connect(function() rays.Rotation = os.clock() * 20 % 360 end)
			local from = S(640, 250)
			fly("coin", from, goldPill, 10, 0.1)
			fly("gem", from, gemPill, math.min(8, gems), 0.25)
			card.Visible, reward.Visible = true, true
			pop(card, 0.8, 0.3)
			pop(reward, 0.6, 0.35)
			shake(0.6)
			for k = 1, 9 do -- 6 stars: they shoot up and out, then pop like bubbles
				local sp = new("ImageLabel", layer, { Image = ICON.star, BackgroundTransparency = 1, Size = S(54, 54), Position = S(640, 250), AnchorPoint = Vector2.new(0.5, 0.5), Rotation = math.random(-30, 30), ZIndex = 5 })
				new("UIAspectRatioConstraint", sp, { AspectRatio = 1 })
				scaler(sp).Scale = 0
				task.delay(0.2 + k * 0.03, function()
					tween(scaler(sp), 0.2, { Scale = 0.6 + math.random() * 0.6 }, Enum.EasingStyle.Back)
					tween(sp, 0.7 + math.random() * 0.4, { Position = S(640 + (k - 5) * 46 + math.random(-20, 20), 250 - 90 - math.random(0, 110)), Rotation = math.random(-60, 60) }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out).Completed:Connect(function()
						tween(scaler(sp), 0.09, { Scale = 1.5 }).Completed:Connect(function() sp:Destroy() end)
						tween(sp, 0.09, { ImageTransparency = 1 })
					end)
				end)
			end
			task.spawn(function() -- 7 magic dust: tiny sparks keep floating up while the chest stands open
				while layer.Enabled and lidOpen do
					local d = new("Frame", layer, { Size = UDim2.fromOffset(5, 5), Position = S(640 + math.random(-80, 80), 262), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.fromRGB(255, 232, 170), BorderSizePixel = 0, ZIndex = 5 })
					new("UICorner", d, { CornerRadius = UDim.new(0.5, 0) })
					tween(d, 1.3, { Position = d.Position - UDim2.fromScale(math.random(-20, 20) / 1280, (90 + math.random(0, 80)) / 592), BackgroundTransparency = 1 }, Enum.EasingStyle.Sine, Enum.EasingDirection.Out).Completed:Connect(function() d:Destroy() end)
					task.wait(0.09)
				end
			end)
		end)
		-- the streak track fills up to today, today pops
		task.delay(2.1, function()
			track.Visible = true
			tween(barFill, 0.5, { Size = UDim2.fromScale(math.clamp((streak - 1) / 6, 0, 1), 1) }, Enum.EasingStyle.Quad)
			for d, o in days do
				local done, today = d < streak, d == streak
				o.c.BackgroundColor3 = (done or today) and Color3.fromRGB(240, 180, 58) or (GLASS and Color3.fromRGB(226, 216, 250) or Color3.fromRGB(227, 210, 166))
				o.st.Color = GLASS and Color3.fromRGB(46, 30, 96) or Color3.fromRGB(59, 36, 22)
				o.st.Thickness = GLASS and 2 or 3
				o.l.TextColor3 = (done or today) and WHITE or (GLASS and Color3.fromRGB(96, 80, 150) or Color3.fromRGB(110, 92, 70))
				scaler(o.c).Scale = 0.3
				task.delay(d * 0.05, function() tween(scaler(o.c), 0.3, { Scale = today and 1.25 or 1 }, Enum.EasingStyle.Back) end)
			end
		end)
		task.delay(2.6, function()
			collect.Visible = true
			pop(collect, 0.5, 0.3)
		end)
	end
	local function hide()
		if not collect.Visible then return end
		tween(scrim, 0.2, { BackgroundTransparency = 1 })
		for _, o in { chest, title, reward, track, collect, rays, glow, card } do tween(scaler(o), 0.18, { Scale = 0 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In) end
		task.delay(0.22, function()
			layer.Enabled = false
			for _, o in { chest, title, reward, track, collect, rays, glow, card } do scaler(o).Scale = 1 end
			if spin then spin:Disconnect() spin = nil end
			busy = false
		end)
	end
	collect.Activated:Connect(hide)
	scrim.Activated:Connect(hide)

	return { show = show, fly = fly }
end

return M
