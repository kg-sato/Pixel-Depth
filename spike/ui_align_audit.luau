-- UI alignment audit (Client, Play; read only). Whole Game Polish audit 2026-11-26, gate 1: on every visible screen gui of this
-- player it counts (1) text labels and buttons drawn under 11 px, (2) sibling text elements whose boxes overlap by more than
-- 2 px square (two different words on top of each other), (3) text elements sticking out of their parent by more than 2 px when
-- the parent does not clip. Returns "small N  overlap N  out N" and the first examples of each.
local pg = game.Players.LocalPlayer:WaitForChild("PlayerGui")
local function shown(o)
	local p = o
	while p and not p:IsA("LayerCollector") do
		if p:IsA("GuiObject") and not p.Visible then return false end
		if p:IsA("CanvasGroup") and p.GroupTransparency > 0.95 then return false end
		p = p.Parent
	end
	return p ~= nil and p.Enabled and (p:IsA("ScreenGui") or p:IsA("SurfaceGui")) -- a menu stands in the world while open (Shared.SpatialPanels moves it into a SurfaceGui)
end
local function isText(o) return (o:IsA("TextLabel") or o:IsA("TextButton")) and o.Text ~= "" and o.TextTransparency < 0.9 end
local function rect(o) return o.AbsolutePosition, o.AbsolutePosition + o.AbsoluteSize end
local small, over, out = {}, {}, {}
local function drawnX(o) -- the drawn words' left and right, not the box: a scaled label's box may be wider than its text
	local a0, a1 = o.AbsolutePosition, o.AbsolutePosition + o.AbsoluteSize
	local tw = math.min(o.TextBounds.X, o.AbsoluteSize.X)
	local cx = o.TextXAlignment == Enum.TextXAlignment.Left and a0.X + tw / 2 or (o.TextXAlignment == Enum.TextXAlignment.Right and a1.X - tw / 2 or (a0.X + a1.X) / 2)
	return cx - tw / 2, cx + tw / 2
end
local function path(o) return o:GetFullName():gsub("^.-PlayerGui%.", "") end
for _, o in pg:GetDescendants() do
	if isText(o) and shown(o) and o.AbsoluteSize.X > 2 then
		local lines = math.max(1, select(2, string.gsub(o.Text, "\n", "")) + 1)
		local px = o.TextBounds.Y / lines
		if px > 0 and px < 10.5 then table.insert(small, string.format("%s %.0fpx '%s'", path(o), px, o.Text:sub(1, 24))) end
		local par = o.Parent
		if par and par:IsA("GuiObject") and not par.ClipsDescendants and par.AbsoluteSize.X > 4 then
			local a0, a1 = rect(o)
			local b0, b1 = rect(par)
			-- the drawn words, not the box: a scaled label's box may be wider than its text
			local tw = math.min(o.TextBounds.X, o.AbsoluteSize.X)
			local cx = o.TextXAlignment == Enum.TextXAlignment.Left and a0.X + tw / 2 or (o.TextXAlignment == Enum.TextXAlignment.Right and a1.X - tw / 2 or (a0.X + a1.X) / 2)
			local l, r = cx - tw / 2, cx + tw / 2
			if l < b0.X - 2 or r > b1.X + 2 then table.insert(out, string.format("%s '%s' %.0f..%.0f vs %.0f..%.0f", path(o), o.Text:sub(1, 20), l, r, b0.X, b1.X)) end
		end
	end
end
local checked = {}
for _, par in pg:GetDescendants() do
	if (par:IsA("GuiObject") or par:IsA("LayerCollector")) and not checked[par] then
		checked[par] = true
		local kids = {}
		for _, k in par:GetChildren() do if isText(k) and shown(k) then table.insert(kids, k) end end
		for i = 1, #kids do for j = i + 1, #kids do
			local a, b = kids[i], kids[j]
			if a.Text ~= b.Text then
				local a0, a1 = rect(a)
				local b0, b1 = rect(b)
				local al, ar = drawnX(a)
				local bl, br = drawnX(b)
				local w = math.min(ar, br) - math.max(al, bl)
				local h = math.min(a1.Y, b1.Y) - math.max(a0.Y, b0.Y)
				-- the words' own heights: scaled labels often have tall empty boxes
				local ah, bh = math.min(a.TextBounds.Y, a.AbsoluteSize.Y), math.min(b.TextBounds.Y, b.AbsoluteSize.Y)
				local ac, bc = (a0.Y + a1.Y) / 2, (b0.Y + b1.Y) / 2
				local th = math.min(ac + ah / 2, bc + bh / 2) - math.max(ac - ah / 2, bc - bh / 2)
				if w > 0 and h > 0 and th > 0 and w * math.min(h, th) > 2 then table.insert(over, string.format("%s: '%s' x '%s'", path(par), a.Text:sub(1, 16), b.Text:sub(1, 16))) end
			end
		end end
	end
end
local function first(t, n) local r = {} for i = 1, math.min(n, #t) do r[i] = t[i] end return table.concat(r, " | ") end
return string.format("small %d  overlap %d  out %d\nSMALL: %s\nOVERLAP: %s\nOUT: %s", #small, #over, #out, first(small, 12), first(over, 12), first(out, 12))
