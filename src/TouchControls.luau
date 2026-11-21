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
	-- directive v13: the device's own preferred input, not "touch and no keyboard" (a touch laptop or an iPad with a keyboard)
	local function isTouch() return UIS.PreferredInput == Enum.PreferredInput.Touch or plr:GetAttribute("DevTouch") ~= nil end
	pcall(function() -- the HUD keeps clear of notches and the home bar; interactive pieces stay in the core-UI safe area
		E.gui.SafeAreaCompatibility = Enum.SafeAreaCompatibility.FullscreenExtension
		E.gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	end)
	local function inCave() return plr:GetAttribute("InCave") == true end

	-- name, board size, board position (anchor: right edge, centre), kind, icon, action
	local flare = E.button(E.gui, "FLARE", S(86, 86), S(1256, 402), Vector2.new(1, 0.5), "pink", "star", true) -- round 2: one family of squircles (Gemini: mismatched sizes)
	-- the thumb arc above Roblox's jump button: FLARE biggest at the edge, SONAR and PING stepping up and inward
	local sonar = E.button(E.gui, "SONAR", S(78, 78), S(1158, 380), Vector2.new(1, 0.5), "mint", "sonar", true)
	local ping = E.button(E.gui, "PING", S(78, 78), S(1076, 330), Vector2.new(1, 0.5), "lilac", "pin", true)
	local notes = E.button(E.gui, "NOTES", S(76, 76), S(1256, 402), Vector2.new(1, 0.5), "butter", "book", true)
	local clinkB = E.button(E.gui, "CLINK", S(66, 66), S(992, 292), Vector2.new(1, 0.5), "butter", "smile", true) -- directive v13: the clink salute (Shared.Clink)
	flare.Name, sonar.Name, ping.Name, notes.Name, clinkB.Name = "TouchFlare", "TouchSonar", "TouchPing", "TouchNotes", "TouchClink"
	clinkB.Activated:Connect(function() if hook.clink then hook.clink() end end)
	for _, b in { flare, sonar, ping, notes, clinkB } do
		E.fit(b, 1, 1)
		b.Visible = false
	end
	flare.Icon.Image = C.HUD_ICON.flare
	-- directive v13: the jelly sonar and pin icons (Config.UI_GLASS.icon) replace the three drawn rings and the borrowed map
	if E.ICON.sonar then sonar.Icon.Image = E.ICON.sonar end
	if E.ICON.pin then ping.Icon.Image = E.ICON.pin end
	local count = E.text(flare, "", UDim2.fromScale(0.3, 0.24), UDim2.fromScale(0.78, 0.2), Vector2.new(0.5, 0.5), Color3.fromRGB(255, 244, 214))
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
		flare.Visible, sonar.Visible, ping.Visible, clinkB.Visible = cave, cave, cave, cave
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
	UIS:GetPropertyChangedSignal("PreferredInput"):Connect(function() was = nil end) -- a keyboard plugged in or a pad picked up: the layout follows
end

return M
