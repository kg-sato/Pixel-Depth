-- HUD overlap check (Play, Client): every visible HUD widget's rectangle against every other one. Returns "0 overlaps" or the pairs.
-- Widgets are the visible children of PixelHUD, CaveHud and the left column's rows; full-screen layers and containers are skipped.
-- World prompts (PromptUI) follow the world, so they are listed apart: they must be 0 while a modal or a loot card is up.
local gui = game.Players.LocalPlayer.PlayerGui.PixelHUD
local screen = gui.AbsoluteSize
local CONTAINER = { CaveHud = true, LeftColumn = true, Currency = true, Bag = true, Tracker = true, TrackerCard = true, Buttons = true, Feed = true }
local SKIP = { Glints = true, Scrim = true, ResultDim = true, Dim = true, PerfectStrike = true, VeinRush = true }
local list, prompts = {}, {}
local function walk(parent)
	for _, o in parent:GetChildren() do
		if o:IsA("GuiObject") and o.Visible then
			if CONTAINER[o.Name] or (o.Name == "PerfectStrike" or o.Name == "VeinRush") then
				walk(o)
			elseif not SKIP[o.Name] and o.AbsoluteSize.X > 4 and o.AbsoluteSize.Y > 4 and (o.AbsoluteSize.X < screen.X * 0.9 or o.AbsoluteSize.Y < screen.Y * 0.9) then
				local drawn = o.BackgroundTransparency < 1 or o:FindFirstChildWhichIsA("GuiObject") ~= nil or o:IsA("TextLabel") or o:IsA("ImageLabel")
				if drawn then table.insert(o.Name == "PromptUI" and prompts or list, o) end
			end
		end
	end
end
walk(gui)
local out, n = {}, 0
local function hit(a, b, pad)
	local a1, a2, b1, b2 = a.AbsolutePosition, a.AbsolutePosition + a.AbsoluteSize, b.AbsolutePosition, b.AbsolutePosition + b.AbsoluteSize
	return a1.X < b2.X - pad and b1.X < a2.X - pad and a1.Y < b2.Y - pad and b1.Y < a2.Y - pad
end
for i = 1, #list do
	for j = i + 1, #list do
		if hit(list[i], list[j], 1) then
			n += 1
			table.insert(out, list[i].Name .. " x " .. list[j].Name)
		end
	end
end
local pOver = 0
for _, p in prompts do
	for _, w in list do if hit(p, w, 1) then pOver += 1 table.insert(out, "PROMPT x " .. w.Name) end end
end
return n .. " overlaps, " .. pOver .. " prompt overlaps, " .. #list .. " widgets, " .. #prompts .. " prompts, screen " .. screen.X .. "x" .. screen.Y .. (#out > 0 and ("\n" .. table.concat(out, "\n")) or "")
