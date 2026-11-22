-- HudCompact (ReplicatedStorage.Shared.HudCompact), started by PixelClient after the HUD's rows exist. Directive v10
-- (2026-11-14, audit of the 14c video: "6+ disconnected boxes crowd the top and sides"): the row of square buttons (BAG,
-- MINE / SURFACE, WARDROBE, QUESTS and the touch TOOLS button) folds away behind ONE small MENU button that sits in the
-- currency strip. A click or tap on MENU drops the row down; it folds again after a button is used, after 8 seconds with
-- no pointer on it, or on a second click. Every key (B, Q, V, J, Tab) works as before, menu open or shut.
-- A red dot on MENU says that a button inside wants attention (the quest reward dot).
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")
local M = {}

function M.start(E)
	local col = E.gui:WaitForChild("LeftColumn", 15)
	local row, money = col and col:WaitForChild("Buttons", 10), col and col:WaitForChild("Currency", 10)
	if not row or not money then return end
	local menu = E.panel(money, UDim2.fromScale(0.07, 1), UDim2.new(), nil, "pillLilac")
	menu.Name, menu.LayoutOrder = "MenuButton", 9
	E.new("UIAspectRatioConstraint", menu, { AspectRatio = 2.3, DominantAxis = Enum.DominantAxis.Height }) -- directive v14: 1.75 left no room for the book icon beside the M
	local word = E.text(menu, "MENU", UDim2.fromScale(0.6, 0.46), UDim2.fromScale(0.56, 0.47), Vector2.new(0.5, 0.5), E.WHITE, 700, false)
	word.Name, word.Font = "Word", E.HEAD or word.Font
	local hit = E.new("TextButton", menu, { Name = "Hit", Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 6 })
	local dot = E.new("Frame", menu, { Name = "Dot", Size = UDim2.fromScale(0.2, 0.2), SizeConstraint = Enum.SizeConstraint.RelativeYY, Position = UDim2.fromScale(0.97, 0.05), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.fromRGB(255, 0, 127), BorderSizePixel = 0, Visible = false, ZIndex = 7 })
	E.new("UICorner", dot, { CornerRadius = UDim.new(0.5, 0) })
	local sc = E.new("UIScale", menu, {})
	-- the quick way home (directive v10: "a one-click fast-travel pill in the top strip"): in the caves a HOME pill sits beside
	-- MENU and starts the hearthstone hold (Shared.Hearth; the server decides whether and when it works). While the
	-- hearthstone cools down the pill shows the time left.
	local home = E.panel(money, UDim2.fromScale(0.07, 1), UDim2.new(), nil, "pillLilac")
	home.Name, home.LayoutOrder, home.Visible = "HomeButton", 10, false
	E.new("UIAspectRatioConstraint", home, { AspectRatio = 2.3, DominantAxis = Enum.DominantAxis.Height })
	-- directive v13: the jelly home icon sits on the pill, so a cooldown clock reads as "hearthstone recharging", not a second event timer
	local homeIcon = E.new("ImageLabel", home, { Name = "Icon", Image = E.ICON.home or "", BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Size = UDim2.fromScale(0.34, 0.7), Position = UDim2.fromScale(0.21, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 5 }) -- named "Icon": IconPass then adds no second house (tour views full1122e: two houses before HOME)
	local homeWord = E.text(home, "HOME", UDim2.fromScale(0.56, 0.46), UDim2.fromScale(0.64, 0.47), Vector2.new(0.5, 0.5), E.WHITE, 700, false)
	homeWord.Name, homeWord.Font = "Word", E.HEAD or homeWord.Font
	local homeHit = E.new("TextButton", home, { Name = "Hit", Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 6 })
	homeHit.Activated:Connect(function()
		E.sfx("click", 1.1)
		if E.vmHook.home then E.vmHook.home() end
	end)
	task.delay(1, function() -- v10 (Gemini: "a chrome minimap ring from another UI"): the cave minimap's ring, face and rim on the lavender palette
		local mm = E.caveHud and E.caveHud:FindFirstChild("Minimap")
		for _, d in mm and mm:GetDescendants() or {} do
			if d:IsA("ImageLabel") and E.GLASS and d.Image == E.GLASS.ring then d.ImageColor3 = Color3.fromRGB(196, 160, 255)
			elseif d:IsA("CanvasGroup") and math.abs(d.BackgroundColor3.R - 36 / 255) < 0.01 and math.abs(d.BackgroundColor3.B - 24 / 255) < 0.01 then d.BackgroundColor3 = Color3.fromRGB(26, 12, 40)
			elseif d:IsA("UIGradient") and d.Parent:IsA("UIStroke") then d.Color = ColorSequence.new(Color3.fromRGB(155, 31, 232), Color3.fromRGB(0, 240, 255)) end
		end
	end)
	local open, openedAt = false, 0
	local rowScale = row:FindFirstChildOfClass("UIScale") or E.new("UIScale", row, {})
	local function set(on)
		if open == on then return end
		open, openedAt = on, os.clock()
		E.plr:SetAttribute("MenuOpen", on) -- read by the tests
		if on then
			row.Visible = true
			rowScale.Scale = 0.6
			TweenService:Create(rowScale, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
		else
			row.Visible = false
		end
	end
	row.Visible = false
	E.plr:SetAttribute("MenuOpen", false)
	hit.Activated:Connect(function()
		sc.Scale = 0.9
		TweenService:Create(sc, TweenInfo.new(0.3, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), { Scale = 1 }):Play()
		E.sfx("click", 1.1)
		set(not open)
	end)
	local function wire(b) -- using a button inside folds the menu again
		if b:IsA("GuiButton") then b.Activated:Connect(function() task.delay(0.15, function() set(false) end) end) end
	end
	-- v10 (Gemini: "flat milky pastel squares"): every button in the row wears the dark smoked skin, whatever kind it was made as
	local darkImage
	local function darken()
		for _, b in row:GetChildren() do
			local sk = b:IsA("GuiButton") and b:FindFirstChild("Skin")
			if sk and (not darkImage or sk.Image ~= darkImage) then
				E.setKind(b, "dark")
				darkImage = darkImage or sk.Image
			end
		end
	end
	local plank = E.gui:FindFirstChild("StepCard") and E.gui.StepCard:FindFirstChild("Plank")
	if plank then plank.Visible = false end -- and the quest card loses its slanted pink NEXT UP plank: one rounded card
	for _, b in row:GetChildren() do wire(b) end
	row.ChildAdded:Connect(wire)
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < 0.25 then return end
		acc = 0
		local want = false
		for _, b in row:GetChildren() do
			local d = b:IsA("GuiObject") and b:FindFirstChild("Dot")
			if d and d.Visible then want = true end
		end
		dot.Visible = want and not open
		darken()
		home.Visible = E.plr:GetAttribute("InCave") == true
		local why = home.Visible and E.vmHook.homeWhy and E.vmHook.homeWhy()
		homeWord.Text = why or "HOME"
		local cooling = type(why) == "string" and why:find(":") ~= nil -- "1:25": the hearthstone is recharging, the pill steps back to 45%
		homeIcon.ImageTransparency, homeWord.TextTransparency = cooling and 0.55 or 0, cooling and 0.4 or 0
		if open then
			local m = UIS:GetMouseLocation() - GuiService:GetGuiInset()
			local p, s = row.AbsolutePosition, row.AbsoluteSize
			local over = UIS.MouseEnabled and m.X >= p.X and m.X <= p.X + s.X * 0.3 and m.Y >= p.Y - 80 and m.Y <= p.Y + s.Y
			if over then openedAt = os.clock() end
			if os.clock() - openedAt > 8 then set(false) end
		end
	end)
end

return M
