-- HubMinimap (ReplicatedStorage.Shared.HubMinimap), started by PixelClient. Directive v10.0 (2026-11-16 re-run), HUD anchor 3:
-- the top right holds a minimap with NEXT UP under it, in town as in the caves. Town had no map, so the step card sat alone in
-- the corner. This draws a round obsidian-lavender glass map of the town (north up; the stores as coloured beads with a
-- letter; the player as a cyan arrow) at the same spot as the cave radar, moves the cave radar up into that corner, and
-- stacks the step card (NEXT UP) and the cave's camp pill under it. PixelClient reads `E.vmHook.stepY` for the card's place.
local RunService = game:GetService("RunService")
local M = {}
local OBS, PLUM, VIOLET, MAGENTA, CYAN = Color3.fromRGB(22, 8, 30), Color3.fromRGB(36, 17, 56), Color3.fromRGB(155, 31, 232), Color3.fromRGB(255, 0, 127), Color3.fromRGB(0, 240, 255)
local RADIUS = 62 -- studs of town from the centre to the rim (the stores ring the plaza at about 40; farther is pinned to the rim)
local STOPS = { -- the places worth finding: model name in workspace.Hub, letter, colour
	{ "MineShaft", "M", MAGENTA, "cart" }, { "SellStall", "$", Color3.fromRGB(255, 214, 90), "pouch" }, { "Forge", "F", Color3.fromRGB(255, 140, 60), "hammer" },
	{ "Incubator", "E", Color3.fromRGB(255, 150, 210), "egg" }, { "TrophyHouse", "T", Color3.fromRGB(196, 160, 255), "trophy" },
	{ "NoticeBoard", "Q", CYAN, "scroll" }, { "Campfire", "C", Color3.fromRGB(255, 190, 120), "camp" },
} -- 2026-11-18: each stop shows its jelly icon (Config.UI_GLASS.icon) instead of a letter (Gemini: letters read as debug markers)
local ICON = (require(game:GetService("ReplicatedStorage").Shared:WaitForChild("Config")).UI_GLASS or {}).icon or {}
M.TOP, M.SIZE = 14, 150 -- board pixels (1280 x 592): the map's top edge and its diameter
M.STEP_Y = M.TOP + M.SIZE + 10 -- the NEXT UP card's top edge, docked just under the map (Gemini v10n_r7: "a large empty gap")

function M.start(E)
	local S, new = E.S, E.new
	E.vmHook.stepY = M.STEP_Y
	local root = new("Frame", E.gui, { Name = "HubMinimap", Size = S(M.SIZE, M.SIZE), Position = S(1262, M.TOP), AnchorPoint = Vector2.new(1, 0), BackgroundTransparency = 1, ZIndex = 2, Visible = false })
	new("UIAspectRatioConstraint", root, { AspectRatio = 1 })
	local face = new("CanvasGroup", root, { Name = "Face", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 2 })
	new("UICorner", face, { CornerRadius = UDim.new(0.5, 0) })
	local glass = new("Frame", face, { Name = "Glass", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.1, BorderSizePixel = 0, ZIndex = 2 })
	new("UIGradient", glass, { Rotation = 90, Color = ColorSequence.new(PLUM, OBS) }) -- on its own frame: a gradient on the CanvasGroup tints every bead too
	local rim = new("Frame", root, { Name = "Rim", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 8 })
	new("UICorner", rim, { CornerRadius = UDim.new(0.5, 0) })
	new("UIGradient", new("UIStroke", rim, { Thickness = 3, Color = Color3.new(1, 1, 1) }), { Rotation = 45, Color = ColorSequence.new(VIOLET, CYAN) })
	for _, r in { 0.36, 0.7 } do -- faint range rings
		local ring = new("Frame", face, { Size = UDim2.fromScale(r, r), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, ZIndex = 3 })
		new("UICorner", ring, { CornerRadius = UDim.new(0.5, 0) })
		new("UIStroke", ring, { Color = Color3.fromRGB(196, 160, 255), Thickness = 1, Transparency = 0.75 })
	end
	local plaza = new("Frame", face, { Size = UDim2.fromScale(0.44, 0.5), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = VIOLET, BackgroundTransparency = 0.8, BorderSizePixel = 0, ZIndex = 3 })
	new("UICorner", plaza, { CornerRadius = UDim.new(0.5, 0) })
	local shine = new("Frame", face, { Name = "Shine", Size = UDim2.fromScale(0.68, 0.28), Position = UDim2.fromScale(0.5, 0.05), AnchorPoint = Vector2.new(0.5, 0), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 7, ClipsDescendants = true }) -- the jelly dome shine
	new("UICorner", shine, { CornerRadius = UDim.new(0.5, 0) })
	new("UIGradient", shine, { Rotation = 90, Transparency = NumberSequence.new(0.74, 1) })

	local function onMap(p) -- world x, z to the disc (north up), clamped inside the rim
		local v = Vector2.new(p.X, p.Z) / RADIUS
		if v.Magnitude > 0.86 then v = v.Unit * 0.86 end
		return UDim2.fromScale(0.5 + v.X * 0.5, 0.5 + v.Y * 0.5)
	end
	task.spawn(function()
		local hub = workspace:WaitForChild("Hub", 30)
		for _, s in hub and STOPS or {} do
			local m = hub:WaitForChild(s[1], 10)
			if m and m:IsA("Model") then
				local bead = new("Frame", face, { Name = s[1], Size = UDim2.fromScale(0.13, 0.13), Position = onMap(m:GetBoundingBox().Position), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = s[3], BorderSizePixel = 0, ZIndex = 4 })
				new("UICorner", bead, { CornerRadius = UDim.new(0.5, 0) })
				new("UIStroke", bead, { Color = OBS, Thickness = 1.2 })
				if s[4] and ICON[s[4]] then -- a dark glass bead with a coloured rim and the place's icon on it
					bead.BackgroundColor3, bead.Size = OBS, UDim2.fromScale(0.17, 0.17)
					bead:FindFirstChildOfClass("UIStroke").Color, bead:FindFirstChildOfClass("UIStroke").Thickness = s[3], 1.6
					new("ImageLabel", bead, { Name = "Icon", Image = ICON[s[4]], BackgroundTransparency = 1, Size = UDim2.fromScale(1.25, 1.25), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), ScaleType = Enum.ScaleType.Fit, ZIndex = bead.ZIndex + 1 })
				else
					new("TextLabel", bead, { Text = s[2], Font = Enum.Font.FredokaOne, TextScaled = true, TextColor3 = OBS, BackgroundTransparency = 1, Size = UDim2.fromScale(0.8, 0.8), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 5 })
				end
			end
		end
	end)
	local north = new("Frame", root, { Name = "North", Size = UDim2.fromScale(0.2, 0.14), Position = UDim2.fromScale(0.5, 0.02), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = MAGENTA, BorderSizePixel = 0, ZIndex = 9 })
	new("UICorner", north, { CornerRadius = UDim.new(0.4, 0) })
	new("TextLabel", north, { Text = "N", Font = Enum.Font.FredokaOne, TextScaled = true, TextColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, Size = UDim2.fromScale(0.8, 0.8), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 10 })
	local me = new("TextLabel", face, { Name = "Me", Text = utf8.char(9650), Font = Enum.Font.GothamBlack, TextScaled = true, TextColor3 = CYAN, TextStrokeColor3 = OBS, TextStrokeTransparency = 0, BackgroundTransparency = 1, Size = UDim2.fromScale(0.15, 0.15), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 6 })

	task.spawn(function() -- the cave radar moves up into the same corner; the camp pill sits just under it
		local cave = E.caveHud and E.caveHud:WaitForChild("Minimap", 15)
		if not cave then return end
		cave.Size, cave.Position = S(M.SIZE, M.SIZE), S(1262, M.TOP)
		local pill = E.caveHud:FindFirstChild("CampPill")
		if pill then pill.Position = S(1262 - M.SIZE - 8, M.TOP + M.SIZE - 34) end -- beside the radar, left of it: the NEXT UP card has the space below
	end)
	RunService.RenderStepped:Connect(function()
		root.Visible = E.plr:GetAttribute("InCave") ~= true and not E.plr:GetAttribute("Seated") and not E.isBusy() and not E.vmHook.modalOpen
		if not root.Visible then return end
		local h = E.hrp and E.hrp()
		if h then
			me.Position = onMap(h.Position)
			local look = workspace.CurrentCamera.CFrame.LookVector
			me.Rotation = math.deg(math.atan2(look.X, -look.Z))
		end
	end)
	return root
end

assert(M.STEP_Y + 64 < 592 / 2, "HubMinimap: NEXT UP would fall into the lower half of the screen") -- self-check of the stack
return M
