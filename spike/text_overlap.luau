-- Text overlap scan (Play, Client), 2026-11-18 (the owner: "a lot of text is overlapping, verify and fix all instances").
-- Measures the INK of every drawn word (Gumdrop's GumBox, the 3D jelly row, plain TextBounds) in the player's guis, then reports:
--   TXT  two words whose ink overlaps (different labels, not a drop-shadow copy)
--   ICON a jelly icon (IconPass PassIcon or a kit Icon) over another word's ink
--   SPILL a word whose ink runs out of its own label by more than 3 px
-- _G.TEXT_SCAN_FORCE = true also opens every hidden panel one at a time (children of each ScreenGui / SurfaceGui), scans it, and
-- hides it again, so closed menus are checked too. Returns "0 issues" or one line per issue.
local pg = game.Players.LocalPlayer.PlayerGui
local force = _G.TEXT_SCAN_FORCE == true

local function shown(o, root)
	local p = o
	while p and p ~= root.Parent do
		if p:IsA("GuiObject") and not p.Visible then return false end
		if p:IsA("LayerCollector") and not p.Enabled then return false end
		p = p.Parent
	end
	return true
end

local function inkOf(l)
	if l.TextTransparency > 0.9 or l.Text == "" or l.AbsoluteSize.X < 2 or l.AbsoluteSize.Y < 2 then return nil end -- a billboard out of its range has no size: not drawn
	local jel = l:FindFirstChild("Jelly")
	if jel and jel:IsA("GuiObject") and jel.Visible then
		local p, s = jel.AbsolutePosition, jel.AbsoluteSize
		return Rect.new(p.X + 1, p.Y + s.Y * 0.08, p.X + s.X - 1, p.Y + s.Y * 0.92)
	end
	local gum = l:FindFirstChild("Gum")
	if gum and gum.Visible and l:GetAttribute("GumBox") then
		local r, p = l:GetAttribute("GumBox"), gum.AbsolutePosition
		return Rect.new(p.X + r.Min.X, p.Y + r.Min.Y, p.X + r.Max.X, p.Y + r.Max.Y)
	end
	if l.MaxVisibleGraphemes == 0 then return nil end
	local tb, p, s = l.TextBounds, l.AbsolutePosition, l.AbsoluteSize
	if tb.X < 1 then return nil end
	local pad = l:FindFirstChildOfClass("UIPadding")
	local L = pad and (pad.PaddingLeft.Scale * s.X + pad.PaddingLeft.Offset) or 0
	local R = pad and (pad.PaddingRight.Scale * s.X + pad.PaddingRight.Offset) or 0
	local T = pad and (pad.PaddingTop.Scale * s.Y + pad.PaddingTop.Offset) or 0
	local B = pad and (pad.PaddingBottom.Scale * s.Y + pad.PaddingBottom.Offset) or 0
	local w, h = s.X - L - R, s.Y - T - B
	local xa, ya = l.TextXAlignment, l.TextYAlignment
	local x = p.X + L + (xa == Enum.TextXAlignment.Left and 0 or (xa == Enum.TextXAlignment.Right and w - tb.X or (w - tb.X) / 2))
	local y = p.Y + T + (ya == Enum.TextYAlignment.Top and 0 or (ya == Enum.TextYAlignment.Bottom and h - tb.Y or (h - tb.Y) / 2))
	return Rect.new(x, y + tb.Y * 0.15, x + tb.X, y + tb.Y * 0.85) -- the ink, not the line box
end

local function inter(a, b, pad)
	return a.Min.X < b.Max.X - pad and b.Min.X < a.Max.X - pad and a.Min.Y < b.Max.Y - pad and b.Min.Y < a.Max.Y - pad
end
local function name(o) return (o:GetFullName():gsub("^Players%.[^%.]+%.PlayerGui%.", "")) end

local issues, seen = {}, {}
local function add(line) if not seen[line] then seen[line] = true table.insert(issues, line) end end

local function scan(root)
	local words, icons = {}, {}
	for _, d in root:GetDescendants() do
		if (d:IsA("TextLabel") or d:IsA("TextButton")) and shown(d, root) then
			local r = inkOf(d)
			if r and r.Width > 2 then table.insert(words, { o = d, r = r }) end
		elseif d:IsA("ImageLabel") and (d.Name == "PassIcon" or d.Name == "Icon") and d.Image ~= "" and d.ImageTransparency < 0.9 and shown(d, root) then
			local p, s = d.AbsolutePosition, d.AbsoluteSize
			table.insert(icons, { o = d, r = Rect.new(p.X + s.X * 0.15, p.Y + s.Y * 0.15, p.X + s.X * 0.85, p.Y + s.Y * 0.85) })
		end
	end
	for i, a in words do
		local box, bp = a.o.AbsoluteSize, a.o.AbsolutePosition
		if a.r.Min.X < bp.X - 3 or a.r.Max.X > bp.X + box.X + 3 then
			add(("SPILL %q %s (ink %d px wide, box %d)"):format(a.o.Text, name(a.o), a.r.Width, box.X))
		end
		for j = i + 1, #words do
			local b = words[j]
			local related = a.o:IsAncestorOf(b.o) or b.o:IsAncestorOf(a.o)
			local shadow = a.o.Text == b.o.Text and (a.o.AbsolutePosition - b.o.AbsolutePosition).Magnitude < 8
			if not related and not shadow and inter(a.r, b.r, 2) then
				add(("TXT %q x %q  [%s | %s]"):format(a.o.Text, b.o.Text, name(a.o), name(b.o)))
			end
		end
		for _, c in icons do
			-- an icon drawn under the word (the minimap's player arrow over a place bead) is not hiding it
			if c.o.Parent ~= a.o and c.o.Parent ~= a.o.Parent and c.o.ZIndex >= a.o.ZIndex and inter(a.r, c.r, 3) then
				add(("ICON %s over %q  [%s]"):format(name(c.o), a.o.Text, name(a.o)))
			elseif c.o.Parent == a.o and inter(a.r, c.r, 3) then
				add(("ICON own icon over %q  [%s]"):format(a.o.Text, name(a.o)))
			end
		end
	end
end

for _, g in pg:GetChildren() do
	if g:IsA("LayerCollector") and g.Enabled and g.Name ~= "Freecam" then scan(g) end
end

-- WORLD: cards and billboards in the 3D world (station cards, signs, name tags) projected onto the screen, against the screen's
-- words and each other. A world card counts as one block of text: its whole face on screen.
local cam = workspace.CurrentCamera
local inset = game:GetService("GuiService"):GetGuiInset()
local screenInk = {}
for _, g in pg:GetChildren() do
	if g:IsA("ScreenGui") and g.Enabled then
		local off = g.IgnoreGuiInset and Vector2.zero or inset
		for _, d in g:GetDescendants() do
			if (d:IsA("TextLabel") or d:IsA("TextButton")) and shown(d, g) then
				local r = inkOf(d)
				if r and r.Width > 2 then table.insert(screenInk, { o = d, r = Rect.new(r.Min + off, r.Max + off) }) end
			end
		end
	end
end
local function hasText(gui)
	for _, d in gui:GetDescendants() do
		if (d:IsA("TextLabel") or d:IsA("TextButton")) and d.Text ~= "" and d.TextTransparency < 0.9 and shown(d, gui) then return true end
	end
	return false
end
local world = {}
for _, d in workspace:GetDescendants() do -- the words inside each world card, checked on the card's own canvas
	if (d:IsA("SurfaceGui") or d:IsA("BillboardGui")) and d.Enabled and hasText(d) then scan(d) end
end
for _, d in workspace:GetDescendants() do
	if d:IsA("SurfaceGui") and d.Enabled and hasText(d) then
		local part = d.Adornee or d.Parent
		if part and part:IsA("BasePart") and part.Transparency < 1.01 then
			local cf, sz = part.CFrame, part.Size / 2
			local xs, ys, ok = {}, {}, true
			for _, c in { Vector3.new(-sz.X, -sz.Y, -sz.Z), Vector3.new(sz.X, -sz.Y, -sz.Z), Vector3.new(-sz.X, sz.Y, -sz.Z), Vector3.new(sz.X, sz.Y, -sz.Z) } do
				local v, on = cam:WorldToViewportPoint(cf:PointToWorldSpace(c))
				if v.Z <= 0 then ok = false end
				table.insert(xs, v.X) table.insert(ys, v.Y)
			end
			local r = ok and Rect.new(math.min(table.unpack(xs)), math.min(table.unpack(ys)), math.max(table.unpack(xs)), math.max(table.unpack(ys)))
			local vp = cam.ViewportSize
			if r and r.Max.X > 0 and r.Min.X < vp.X and r.Max.Y > 0 and r.Min.Y < vp.Y and r.Width > 12 and r.Height > 6 then
				-- hidden behind a wall? sample the middle with a ray from the camera
				local mid = cf.Position
				local hit = workspace:Raycast(cam.CFrame.Position, (mid - cam.CFrame.Position) * 0.98)
				if not hit or hit.Instance == part or hit.Instance:IsDescendantOf(part) then
					table.insert(world, { o = d, r = r })
				end
			end
		end
	elseif d:IsA("BillboardGui") and d.Enabled and hasText(d) then
		local at = d.Adornee or d.Parent
		local pos = at and (at:IsA("BasePart") and at.Position or (at:IsA("Attachment") and at.WorldPosition) or (at:IsA("Model") and at:GetPivot().Position))
		if pos then
			local v = cam:WorldToViewportPoint(pos + d.StudsOffsetWorldSpace)
			local s2 = d.AbsoluteSize
			if v.Z > 0 and s2.X > 4 then
				local c = Vector2.new(v.X, v.Y) + Vector2.new(d.StudsOffset.X, -d.StudsOffset.Y) * 0 -- StudsOffset is in studs on screen axes: left as an approximation
				table.insert(world, { o = d, r = Rect.new(c - s2 / 2, c + s2 / 2) })
			end
		end
	end
end
for i, a in world do
	for _, b in screenInk do
		if inter(a.r, b.r, 3) then add(("WORLD %s over screen %q  [%s]"):format(name(a.o), b.o.Text, name(b.o))) end
	end
	for j = i + 1, #world do
		local b = world[j]
		local pa, pb = a.o.Adornee or a.o.Parent, b.o.Adornee or b.o.Parent
		-- a sign's front and back faces are one sign
		if pa ~= pb and inter(a.r, b.r, 3) then add(("WORLD %s x %s"):format(name(a.o), name(b.o))) end
	end
end
if force then
	for _, g in pg:GetChildren() do
		if g:IsA("LayerCollector") then
			local wasOn = g.Enabled
			g.Enabled = true
			for _, panel in g:GetChildren() do
				if panel:IsA("GuiObject") and not panel.Visible then
					panel.Visible = true
					task.wait(0.35) -- Gumdrop lays out on the next frame
					local before = #issues
					scan(panel)
					for k = before + 1, #issues do issues[k] = "[forced " .. g.Name .. "." .. panel.Name .. "] " .. issues[k] end
					panel.Visible = false
				end
			end
			g.Enabled = wasOn
		end
	end
end
return #issues == 0 and "0 issues" or (#issues .. " issues\n" .. table.concat(issues, "\n"))
