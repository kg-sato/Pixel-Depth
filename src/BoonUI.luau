-- BoonUI (ReplicatedStorage.Shared.BoonUI), started by PixelClient. The choice card of a boon shrine: the server
-- (ServerScriptService.BoonShrine) sends two blessings, the player picks one (click, or keys 1 and 2) or closes the card
-- and comes back later. Display and the request only: the server keeps the offer and applies the boon.
local M = {}

function M.start(E)
	local C, R, gui, new, S, fit, text, panel, button = E.C, E.R, E.gui, E.new, E.S, E.fit, E.text, E.panel, E.button
	local BoonR = R:WaitForChild("Boon", 20)
	if not BoonR then return end
	local INK, WHITE, MID = E.INK, E.WHITE, Vector2.new(0.5, 0.5)
	local MUTED = Color3.fromRGB(107, 90, 128)
	local LOOK = { flare = { E.PINK, C.HUD_ICON.flare }, shield = { E.BUTTER, E.ICON.star }, wind = { E.MINT, C.HUD_ICON.heart } }

	local RUNE = Color3.fromRGB(196, 160, 255)
	local TAG = { flare = "THIS DIVE", shield = "30 SECONDS", wind = "RIGHT NOW" } -- when the blessing acts
	local win = panel(gui, S(620, 340), S(640, 300), MID, "dark") -- a dark rune stone, not the white shop panel (Gemini r1: shrine feel 3.5)
	fit(win, 620, 340)
	win.Name, win.Visible = "Boon", false
	if E.addModal then E.addModal(win) end
	E.ribbonTitle(win, "THE RUNE WHISPERS", "ribbonLilac", 0.56)
	local close = E.closeButton(win, "BoonClose")
	do -- directive v13 round 2 (Gemini: the bright town bled through the glass): an opaque dark core behind the content
		local backing = new("Frame", win, { Name = "Backing", Size = UDim2.fromScale(0.97, 0.94), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = MID, BackgroundColor3 = Color3.fromRGB(14, 8, 28), BackgroundTransparency = 0.12, BorderSizePixel = 0, ZIndex = 2 })
		new("UICorner", backing, { CornerRadius = UDim.new(0.04, 0) })
	end
	local note = text(win, "Accept one blessing.", UDim2.fromScale(0.7, 0.07), UDim2.fromScale(0.5, 0.17), MID, Color3.fromRGB(240, 238, 248), 700, false)
	note.ZIndex = 6
	local halos = {}

	local PALE, GOLDRIM, CYANRIM = Color3.fromRGB(206, 194, 236), Color3.fromRGB(255, 206, 110), Color3.fromRGB(110, 225, 255)
	-- directive v13 (Hades crest card, Slay the Spire card reward): dark rune-slate plates with a gold outer rule and a glowing
	-- cyan inner rim, a painted art plate up top, pale lettering; no more pale shop paper
	local function runePlate(parent, size, pos)
		local f = new("Frame", parent, { Size = size, Position = pos, AnchorPoint = MID, BackgroundColor3 = Color3.fromRGB(24, 14, 42), BackgroundTransparency = 0.03, BorderSizePixel = 0, ZIndex = 6 })
		new("UICorner", f, { CornerRadius = UDim.new(0.07, 0) })
		new("UIStroke", f, { Color = GOLDRIM, Thickness = 2, Transparency = 0.12 })
		new("UIGradient", f, { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(110, 100, 150)) })
		local inner = new("Frame", f, { Name = "InnerRim", Size = UDim2.new(1, -12, 1, -12), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = MID, BackgroundTransparency = 1, ZIndex = 6 })
		new("UICorner", inner, { CornerRadius = UDim.new(0.065, 0) })
		new("UIStroke", inner, { Color = CYANRIM, Thickness = 1.5, Transparency = 0.3 })
		return f
	end
	local crestModel = require(script.Parent:WaitForChild("Crests")).model -- the blessings as chunky voxel objects (Shared.Crests, shown by Shared.ModelCard)
	local cards = {}
	for i = 1, 2 do
		local card = runePlate(win, UDim2.fromScale(0.4, 0.68), UDim2.fromScale(i == 1 and 0.27 or 0.73, 0.59))
		for k, size in { 0.46, 0.56 } do -- rune rings breathing around the gift
			local ring = new("Frame", card, { Size = UDim2.fromScale(size, size), SizeConstraint = Enum.SizeConstraint.RelativeYY, Position = UDim2.fromScale(0.5, 0.25), AnchorPoint = MID, BackgroundTransparency = 1, ZIndex = 6 })
			new("UICorner", ring, { CornerRadius = UDim.new(0.5, 0) })
			table.insert(halos, { new("UIStroke", ring, { Color = RUNE, Thickness = k == 1 and 3 or 2 }), k, i })
		end
		local tag = panel(card, UDim2.fromScale(0.46, 0.09), UDim2.fromScale(0.5, 0.735), MID, "pillLilac") -- under the words, clear of the crest rings (Gemini v13: the tag cut into the crest)
		tag.ZIndex = 8
		local tagText = text(tag, "", UDim2.fromScale(0.84, 0.6), UDim2.fromScale(0.5, 0.5), MID, INK, 700, false)
		tagText.ZIndex = 9
		-- the painted art plate: a rounded crest in the blessing's colour, lit from above, in a gold frame, a dark vignette behind it
		local vign = new("Frame", card, { Size = UDim2.fromScale(0.5, 0.5), SizeConstraint = Enum.SizeConstraint.RelativeYY, Position = UDim2.fromScale(0.5, 0.25), AnchorPoint = MID, BackgroundColor3 = Color3.fromRGB(8, 4, 18), BackgroundTransparency = 0.35, BorderSizePixel = 0, ZIndex = 6 })
		new("UICorner", vign, { CornerRadius = UDim.new(0.5, 0) })
		local disc = new("Frame", card, { Size = UDim2.fromScale(0.36, 0.36), SizeConstraint = Enum.SizeConstraint.RelativeYY, Position = UDim2.fromScale(0.5, 0.25), AnchorPoint = MID, Rotation = 45, BorderSizePixel = 0, ZIndex = 7 })
		new("UICorner", disc, { CornerRadius = UDim.new(0.22, 0) })
		new("UIStroke", disc, { Color = GOLDRIM, Thickness = 3 })
		new("UIGradient", disc, { Rotation = 45, Color = ColorSequence.new(WHITE, Color3.fromRGB(120, 100, 150)) })
		local img = new("ImageLabel", disc, { BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Size = UDim2.fromScale(0.7, 0.7), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = MID, Rotation = -45, ZIndex = 8, Visible = false })
		-- round 2 (Gemini: "flat clip-art icons"): the blessing stands on the plate as a small turning voxel model
		local crestHost = new("Frame", card, { Name = "Crest3D", Size = UDim2.fromScale(0.36, 0.36), SizeConstraint = Enum.SizeConstraint.RelativeYY, Position = UDim2.fromScale(0.5, 0.25), AnchorPoint = MID, BackgroundTransparency = 1, ZIndex = 8 })
		local name = text(card, "", UDim2.fromScale(0.9, 0.12), UDim2.fromScale(0.5, 0.52), MID, WHITE, 700, false)
		if E.HEAD then name.Font = E.HEAD end -- a headline: jelly letters with the glass kit
		name.ZIndex = 7
		local what = text(card, "", UDim2.fromScale(0.88, 0.1), UDim2.fromScale(0.5, 0.63), MID, PALE, 700, false)
		what.ZIndex = 7
		local take = button(card, "ACCEPT", UDim2.fromScale(0.7, 0.15), UDim2.fromScale(0.5, 0.875), MID, "lilac")
		take.ZIndex = 7
		take.Label.ZIndex = 8
		local cap = E.keyCap(take, tostring(i), UDim2.fromScale(0.2, 0.74), UDim2.fromScale(0.12, 0.46)) -- the key sits on the button it presses
		cap.ZIndex = 9
		local whole = new("TextButton", card, { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 6 }) -- the whole card is the target
		cards[i] = { crestHost = crestHost, disc = disc, img = img, name = name, what = what, take = take, tag = tagText, whole = whole, card = card, scale = new("UIScale", card, { Scale = 1 }), home = card.Position, size = card.Size }
	end

	local function shut() if win.Visible then E.closePanel(win) end end
	local function pick(i)
		if not win.Visible then return end
		BoonR:FireServer("pick", i)
		shut()
	end
	for i, c in cards do
		c.take.Activated:Connect(function() pick(i) end)
		c.whole.Activated:Connect(function() pick(i) end)
	end
	game:GetService("RunService").RenderStepped:Connect(function()
		if not win.Visible then return end
		for _, hl in halos do hl[1].Transparency = 0.35 + 0.3 * math.sin(os.clock() * 2.4 + hl[2] * 1.3 + hl[3]) end
	end)
	close.Activated:Connect(shut)
	game:GetService("UserInputService").InputBegan:Connect(function(io, gp)
		if gp or not win.Visible then return end
		if io.KeyCode == Enum.KeyCode.One then pick(1) elseif io.KeyCode == Enum.KeyCode.Two then pick(2) end
	end)

	R.Fx.OnClientEvent:Connect(function(kind, a, b)
		if kind == "boonOffer" then
			for i, id in { a, b } do
				local def, look, c = C.BOON.list[id], LOOK[id], cards[i]
				if not def or not look then return end
				c.disc.BackgroundColor3, c.img.Image = look[1], look[2]
				local m = crestModel(id)
				if m then
					if not c.crest then c.crest = require(script.Parent:WaitForChild("ModelCard")).attach(c.crestHost, c.card, { z = 8 }) end
					c.crest.set(m, look[1])
				else
					c.img.Visible = true
				end
				c.name.Text, c.what.Text, c.tag.Text = string.upper(def[1]), def[2], TAG[id] or ""
			end
			if not (E.isBusy and E.isBusy()) then
				E.openPanel(win)
				pcall(E.sfx, "sparkle", 0.9)
				-- the two cards are dealt one after the other (card draw reel, vault Instagram Saved Posts Review 2026-11-12):
				-- directive v13: a true asymmetric squash and stretch: the card flies up stretched (80% wide, 120% tall), lands
				-- squashed (120% wide, 80% tall) and springs back to its shape; then an edge glow ring as each one lands
				local calm = false
				pcall(function() calm = game:GetService("GuiService").ReducedMotionEnabled end)
				for i, c in cards do
					local W, H = c.size.X.Scale, c.size.Y.Scale
					if calm then c.card.Position, c.card.Size, c.scale.Scale = c.home, c.size, 1 continue end
					c.card.Position, c.card.Size, c.scale.Scale = c.home + UDim2.fromScale(0, 0.9), UDim2.fromScale(W * 0.8, H * 1.2), 1
					task.delay(0.12 + (i - 1) * 0.16, function()
						if not win.Visible then return end
						E.tween(c.card, 0.15, { Position = c.home }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out).Completed:Connect(function()
							E.tween(c.card, 0.07, { Size = UDim2.fromScale(W * 1.2, H * 0.8) }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out).Completed:Connect(function()
								E.tween(c.card, 0.42, { Size = c.size }, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)
							end)
						end)
						pcall(E.sfx, "tick", 1 + i * 0.12)
						local ring = new("Frame", c.card, { Size = UDim2.fromScale(1, 1), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = MID, BackgroundTransparency = 1, ZIndex = 5 })
						new("UICorner", ring, { CornerRadius = UDim.new(0.08, 0) })
						local st = new("UIStroke", ring, { Color = RUNE, Thickness = 4 })
						task.delay(0.15, function()
							E.tween(ring, 0.35, { Size = UDim2.new(1, 32, 1, 32) })
							E.tween(st, 0.35, { Transparency = 1 }).Completed:Connect(function() ring:Destroy() end)
						end)
					end)
				end
			end
		elseif kind == "boonTaken" then
			local def = C.BOON.list[a]
			E.toast((def and def[1] or "Blessing") .. " is yours for this dive", nil, false, 3)
			pcall(E.sfx, "upgrade", 1.1)
			if E.vmHook.emote then E.vmHook.emote("cheer") end
		elseif kind == "boonSpent" then
			E.toast("The rune is quiet until your next dive", nil, false, 2.5)
		end
	end)
end

return M
