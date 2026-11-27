-- JourneyUI (ReplicatedStorage.Shared.JourneyUI), started by PixelClient. Progression and Boss Fight Overhaul 1.4 (2026-11-27):
-- one screen that says why you upgrade and where each gate sits. A vertical roadmap, Town then layers 1 to 7, one card each:
-- its camp, the pickaxe tiers its ore needs, its ore worth (x the layer multiplier), its gate boss (LOCKED, READY TO CHALLENGE or
-- DEFEATED) and, on the card you are working toward, a progress bar (your tier against the boss's tier) and GUIDE ME, which lays
-- the town's gold trail to the forge or the mine (Shared.TownGuide). Opens from the tracker pill, the JOURNEY button in the menu
-- row, the M key and the quest board's map. Layers 3 to 7 are the boss outlook: their names, tiers and relics, not yet built.
local UIS = game:GetService("UserInputService")
local M = {}
-- the gate boss of each layer: name, the tier its fight asks for, the arena trick, the first-clear relic
M.BOSSES = {
	{ "ROOT WARDEN", nil, "Root Wall Snare: burn the thicket with a flare", "Heartwood Sigil (+1 flare)" },
	{ "KILN GOLEM", nil, "Magma Rain and the Lava Tide: glide over it", "Kiln Crown Emblem (+15% glider lift)" },
	{ "VALKYRIE PRISM", 17, "Mirror prism beams and chime shields", "Resonance Shard (+10% perfect window)" },
	{ "SURT'S FORGEHOUND", 21, "Forge anvil waves, chain tethers", "Cinderheart Core (+20% heat resist)" },
	{ "THE BLIND SEER", 25, "Echo rings, blind zones lit by flares", "Eye of Mimir (+12% rare and geode sense)" },
	{ "SPORE MONARCH", 27, "Shifting spore pillars, pollen gusts", "Alfglow Mantle (+1 soul shard)" },
	{ "NIDHOGG, GAP-EATER", 29, "Coil phases over the abyss bridge", "Worldheart Crown (server title, mythic aura)" },
}
M.CAMPS = { "CAMP 1", "KILN CAMP", "GLITTER CAMP", "FORGE CAMP", "WELL CAMP", "SPORE CAMP", "GAP CAMP" }

function M.start(E)
	local C, R, new = E.C, E.R, E.new
	M.BOSSES[1][2], M.BOSSES[2][2] = C.BOSS.needTier, C.BOSS2.needTier
	local state = {}
	local GOLD, MINT, LILAC, INK, DIM = Color3.fromRGB(255, 214, 107), Color3.fromRGB(127, 220, 180), Color3.fromRGB(196, 170, 255), Color3.fromRGB(26, 18, 46), Color3.fromRGB(150, 136, 180)
	local win = E.panel(E.gui, E.S(760, 520), E.S(640, 312), Vector2.new(0.5, 0.5), "panel")
	E.fit(win, 760, 520)
	win.Name, win.Visible = "Journey", false
	if E.addModal then E.addModal(win) end
	win.ClipsDescendants = true
	local title = E.text(win, "YOUR JOURNEY", UDim2.fromScale(0.6, 0.08), UDim2.fromScale(0.5, 0.07), Vector2.new(0.5, 0.5), E.WHITE, 700, false)
	title.Font, title.ZIndex = E.HEAD or title.Font, 6
	local sub = E.text(win, "", UDim2.fromScale(0.86, 0.045), UDim2.fromScale(0.5, 0.125), Vector2.new(0.5, 0.5), LILAC, 700, false)
	sub.ZIndex = 6
	local close = E.closeButton(win, "JourneyClose")
	local list = new("ScrollingFrame", win, { Name = "Roadmap", Size = UDim2.fromScale(0.92, 0.8), Position = UDim2.fromScale(0.5, 0.57), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 8, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 5 })
	new("UIListLayout", list, { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder })
	new("UIPadding", list, { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 14), PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 8) })
	local function label(parent, s, size, pos, color, align, h)
		local t = new("TextLabel", parent, { Text = s, Size = size, Position = pos, BackgroundTransparency = 1, Font = E.HEAD or Enum.Font.FredokaOne, TextScaled = true, TextColor3 = color, TextXAlignment = align or Enum.TextXAlignment.Left, ZIndex = 7 })
		new("UITextSizeConstraint", t, { MinTextSize = 12, MaxTextSize = h or 26 })
		return t
	end
	local cards = {}
	local function card(i)
		local f = new("Frame", list, { Name = "Stop" .. i, LayoutOrder = i, Size = UDim2.new(1, 0, 0, i == 0 and 64 or 128), BackgroundColor3 = INK, BackgroundTransparency = 0.1, BorderSizePixel = 0, ZIndex = 6 })
		new("UICorner", f, { CornerRadius = UDim.new(0, 12) })
		local edge = new("UIStroke", f, { Color = DIM, Thickness = 2, Transparency = 0.2 })
		new("UIPadding", f, { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8) })
		local c = { f = f, edge = edge }
		c.name = label(f, "", UDim2.new(0.62, 0, 0, 26), UDim2.new(0, 0, 0, 0), E.WHITE, nil, 28)
		c.status = label(f, "", UDim2.new(0.38, 0, 0, 22), UDim2.new(0.62, 0, 0, 2), GOLD, Enum.TextXAlignment.Right, 22)
		if i > 0 then
			c.ores = label(f, "", UDim2.new(1, 0, 0, 18), UDim2.new(0, 0, 0, 30), LILAC, nil, 18)
			c.boss = label(f, "", UDim2.new(1, 0, 0, 18), UDim2.new(0, 0, 0, 52), DIM, nil, 18)
			local track = new("Frame", f, { Size = UDim2.new(0.62, 0, 0, 14), Position = UDim2.new(0, 0, 0, 80), BackgroundColor3 = Color3.fromRGB(46, 34, 72), BorderSizePixel = 0, ZIndex = 7 })
			new("UICorner", track, { CornerRadius = UDim.new(0.5, 0) })
			c.fill = new("Frame", track, { Size = UDim2.fromScale(0, 1), BackgroundColor3 = GOLD, BorderSizePixel = 0, ZIndex = 8 })
			new("UICorner", c.fill, { CornerRadius = UDim.new(0.5, 0) })
			c.track = track
			c.tier = label(f, "", UDim2.new(0.62, 0, 0, 16), UDim2.new(0, 0, 0, 96), DIM, nil, 16)
			c.guide = E.button(f, "GUIDE ME", UDim2.new(0.3, 0, 0, 44), UDim2.new(1, 0, 0, 62), Vector2.new(1, 0), "mint", "map")
			c.guide.Name, c.guide.ZIndex = "GuideMe", 8
			c.guide.Visible = false
		else
			c.ores = label(f, "", UDim2.new(1, 0, 0, 18), UDim2.new(0, 0, 0, 30), LILAC, nil, 18)
		end
		cards[i] = c
		return c
	end
	for i = 0, #C.LAYERS do card(i) end
	local function bossBeaten(i) return state.tips ~= nil and state.tips["gate" .. i] == true end
	local function goal() -- the stop the player works toward: the first layer whose boss is not beaten
		for i = 1, #C.LAYERS do if not bossBeaten(i) then return i end end
		return #C.LAYERS
	end
	local function guideFor(i)
		local need = M.BOSSES[i][2] or 1
		local key = (state.pick or 1) < need and "forge" or "mine"
		if E.plr:GetAttribute("InCave") then
			E.toast(key == "forge" and ("FORGE TIER " .. need .. " FIRST  \u{00B7}  RIDE UP TO TOWN") or (M.BOSSES[i][1] .. " WAITS BEYOND THE DEEP GATE"), GOLD, true)
		elseif E.vmHook.townGuide then
			E.vmHook.townGuide(key)
		end
		E.closePanel(win)
	end
	local function refresh()
		local pick = state.pick or 1
		local g = goal()
		local name = C.PICKS[pick] and C.PICKS[pick].name or ""
		sub.Text = "TIER " .. pick .. "  \u{00B7}  " .. string.upper(name) .. "  \u{00B7}  FORGE TEMPER LV " .. tostring(state.lv and state.lv[tostring(state.equip or pick)] or 1)
		local t = cards[0]
		t.name.Text, t.status.Text = "TOWN", "HOME"
		t.ores.Text = "Gold: pickaxes, packs, charms  \u{00B7}  Gems: forge temper, eggs  \u{00B7}  Shards: Soul Tree"
		for i = 1, #C.LAYERS do
			local c, L, b = cards[i], C.LAYERS[i], M.BOSSES[i]
			local built = i <= 2
			local need = b[2] or 1
			c.name.Text = "L" .. i .. "  " .. string.upper(L[1]) .. "  \u{00B7}  " .. (built and M.CAMPS[i] or "COMING SOON")
			local ores = {}
			for o, ore in L[4] do table.insert(ores, ore[1] .. " T" .. C.minTier(i, o)) end
			c.ores.Text = table.concat(ores, "   ") .. "   \u{00B7}   ORE x" .. C.layerValueMult(i)
			c.boss.Text = b[1] .. " (TIER " .. need .. ")  \u{00B7}  " .. b[3] .. "  \u{00B7}  " .. b[4]
			local status, col
			if bossBeaten(i) then status, col = "DEFEATED", MINT
			elseif not built then status, col = "LOCKED", DIM
			elseif pick >= need then status, col = "READY TO CHALLENGE", GOLD
			else status, col = "LOCKED  \u{00B7}  NEED T" .. need, Color3.fromRGB(255, 140, 150) end
			c.status.Text, c.status.TextColor3 = status, col
			local active = i == g
			c.edge.Color, c.edge.Thickness = active and GOLD or DIM, active and 3 or 2
			c.fill.Size = UDim2.fromScale(math.clamp(pick / need, 0, 1), 1)
			c.tier.Text = "CURRENT: TIER " .. pick .. "  /  TARGET: TIER " .. need
			c.guide.Visible = active and built
			c.track.Visible, c.tier.Visible = active or not bossBeaten(i), active or not bossBeaten(i)
		end
	end
	for i = 1, #C.LAYERS do cards[i].guide.Activated:Connect(function() guideFor(i) end) end
	local function open()
		if win.Visible then E.closePanel(win) return end
		refresh()
		E.openPanel(win)
		task.defer(function() -- scroll the working card into view
			local c = cards[goal()]
			if c then list.CanvasPosition = Vector2.new(0, math.max(0, c.f.AbsolutePosition.Y - list.AbsolutePosition.Y + list.CanvasPosition.Y - 80)) end
		end)
	end
	M.open = open
	E.vmHook.journey = open
	close.Activated:Connect(function() E.closePanel(win) end)
	R.State.OnClientEvent:Connect(function(st) if type(st) == "table" then state = st if win.Visible then refresh() end end end)
	UIS.InputBegan:Connect(function(input, typing)
		if not typing and input.KeyCode == Enum.KeyCode.M and not (E.isBusy and E.isBusy()) then open() end
	end)
	R.Fx.OnClientEvent:Connect(function(kind) -- the quest board's map wing opens the journey instead of the old depth map
		if kind == "map" then
			task.defer(function()
				local old = E.gui:FindFirstChild("Map")
				if old and old.Visible then E.closePanel(old) end
				if not win.Visible then open() end
			end)
		end
	end)
	-- the JOURNEY button in the menu row, and the tracker pill opens it too
	local btn = E.button(E.gui, "JOURNEY", E.S(76, 76), E.S(20, 480), nil, "lilac", "map", true)
	E.fit(btn, 1, 1)
	btn.Name = "JourneyButton"
	if E.addRow then E.addRow(btn) end
	btn.Activated:Connect(open)
	task.spawn(function()
		local pill = E.gui:WaitForChild("LeftColumn", 20)
		pill = pill and pill:FindFirstChild("TrackerPill", true)
		if pill and pill:IsA("GuiObject") then -- a click or tap on the pill (InputBegan, so the pill's own hover still works)
			pill.Active = true
			pill.InputBegan:Connect(function(i)
				if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then open() end
			end)
		end
	end)
	E.plr:GetAttributeChangedSignal("DevJourney"):Connect(function() if E.plr:GetAttribute("DevJourney") then open() end end) -- Studio test hook
end

return M
