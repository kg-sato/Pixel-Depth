-- TouchControls (ReplicatedStorage.Shared.TouchControls), started by PixelClient. On a phone or tablet (touch, no keyboard) the
-- cave tools get their own thumb buttons on the right edge, above Roblox's jump button: a large FLARE, with SONAR and PING
-- beside it. Before this they sat only behind keys (R, T, Z) and inside the tool wheel, where a panicked tap could land on
-- CHEER (Gemini review 2026-11-12: "separate panic survival tools from the menu wheel"). In town a NOTES button opens the
-- notebook (key N). Key caps are hidden on touch: there are no keys to press.
-- Each button calls the same function its key calls, so the server checks stay where they were.
-- Studio hook: client attribute DevTouch shows the touch layout on a PC.
local M = {}

function M.start(E)
	local UIS, RunService = game:GetService("UserInputService"), game:GetService("RunService")
	local C, plr, S, hook = E.C, E.plr, E.S, E.vmHook
	local function isTouch() return (UIS.TouchEnabled and not UIS.KeyboardEnabled) or plr:GetAttribute("DevTouch") ~= nil end
	local function inCave() return plr:GetAttribute("InCave") == true end

	-- name, board size, board position (anchor: right edge, centre), kind, icon, action
	local flare = E.button(E.gui, "FLARE", S(96, 96), S(1256, 402), Vector2.new(1, 0.5), "pink", "star", true)
	local sonar = E.button(E.gui, "SONAR", S(76, 76), S(1150, 412), Vector2.new(1, 0.5), "mint", "map", true)
	local ping = E.button(E.gui, "PING", S(76, 76), S(1064, 412), Vector2.new(1, 0.5), "lilac", "map", true)
	local notes = E.button(E.gui, "NOTES", S(76, 76), S(1256, 402), Vector2.new(1, 0.5), "butter", "hammer", true)
	flare.Name, sonar.Name, ping.Name, notes.Name = "TouchFlare", "TouchSonar", "TouchPing", "TouchNotes"
	for _, b in { flare, sonar, ping, notes } do
		E.fit(b, 1, 1)
		b.Visible = false
	end
	flare.Icon.Image = C.HUD_ICON.flare
	-- the sonar has no icon in the kit: three rings
	sonar.Icon.Image = ""
	for i, k in { 0.22, 0.44, 0.66 } do
		local r = E.new("Frame", sonar.Icon, { Size = UDim2.fromScale(k, k), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = E.MINT, BackgroundTransparency = i == 1 and 0 or 1, BorderSizePixel = 0, ZIndex = 3 })
		E.new("UICorner", r, { CornerRadius = UDim.new(0.5, 0) })
		E.new("UIStroke", r, { Color = Color3.fromRGB(255, 244, 214), Thickness = 2.5 })
	end
	local count = E.text(flare, "", UDim2.fromScale(0.36, 0.3), UDim2.fromScale(0.86, 0.14), Vector2.new(0.5, 0.5), Color3.fromRGB(255, 244, 214))
	count.Font, count.ZIndex = Enum.Font.Bangers, 5

	flare.Activated:Connect(function() if E.cave.flare then E.cave.flare() end end)
	sonar.Activated:Connect(function() if hook.sonar then hook.sonar() end end)
	ping.Activated:Connect(function() if hook.ping then hook.ping() end end)
	notes.Activated:Connect(function() if hook.notebook then hook.notebook() end end)

	local function hideKeys(touch)
		for _, d in E.gui:GetDescendants() do
			if d.Name == "KeyHint" and d:IsA("GuiObject") then d.Visible = not touch end
		end
	end
	local was
	RunService.Heartbeat:Connect(function()
		local touch = isTouch()
		if touch ~= was then
			was = touch
			hideKeys(touch)
		end
		local free = touch and not E.isBusy() and not hook.wheelOpen and not plr:GetAttribute("Seated")
		for _, m in hook.modals or {} do if m.Visible then free = false end end
		local cave = free and inCave()
		flare.Visible, sonar.Visible, ping.Visible = cave, cave, cave
		notes.Visible = free and not inCave() and not plr:GetAttribute("InMine")
		if cave then
			local n = plr:GetAttribute("Flares") or C.GLOOM.flares
			count.Text = "x" .. n
			E.setKind(flare, n > 0 and "pink" or "off")
			local left = hook.sonarLeft and hook.sonarLeft() or 0
			sonar.Text = left > 0 and tostring(math.ceil(left)) or "SONAR"
			E.setKind(sonar, left > 0 and "off" or "mint")
		end
	end)
	plr:GetAttributeChangedSignal("DevTouch"):Connect(function() was = nil end)
end

return M
