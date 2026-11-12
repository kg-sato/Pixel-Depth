-- HUD contrast check (Client, Play): every visible TextLabel / TextButton of PlayerGui against the nearest opaque
-- background behind it, with Color3:GetContrastRatio (new in November 2026). Lists text under 3:1 that has no outline.
-- python spike/night.py lua Client @spike/hud_contrast.luau
local pg = game.Players.LocalPlayer.PlayerGui
local function shown(o)
	local a = o
	while a and a ~= pg do
		if a:IsA("GuiObject") and not a.Visible then return false end
		if a:IsA("ScreenGui") and not a.Enabled then return false end
		a = a.Parent
	end
	return true
end
local KIND = { -- the kit's skins are images: their middle colour, read off art/ui_soft by eye (approximate)
	panel = Color3.fromRGB(246, 241, 251), card = Color3.fromRGB(255, 250, 240), pill = Color3.fromRGB(255, 250, 243), dark = Color3.fromRGB(72, 56, 100),
	mint = Color3.fromRGB(140, 222, 188), pink = Color3.fromRGB(255, 170, 188), lilac = Color3.fromRGB(196, 178, 240), butter = Color3.fromRGB(255, 222, 130),
	sky = Color3.fromRGB(150, 204, 255), off = Color3.fromRGB(206, 202, 216), keycap = Color3.fromRGB(250, 248, 255), keycapDown = Color3.fromRGB(230, 226, 240),
	slot = Color3.fromRGB(240, 234, 248), tab = Color3.fromRGB(214, 204, 240), tabOn = Color3.fromRGB(255, 240, 200), ribbonPink = Color3.fromRGB(255, 170, 188),
	ribbonLilac = Color3.fromRGB(196, 178, 240), pillButter = Color3.fromRGB(255, 232, 170), pillLilac = Color3.fromRGB(214, 204, 240), pillMint = Color3.fromRGB(180, 234, 210), pillPink = Color3.fromRGB(255, 200, 214),
}
local function backOf(o) -- the nearest ancestor that paints a colour: a Frame's own colour, or its kit skin (attribute Kind)
	local a = o.Parent
	while a and a ~= pg do
		local kind = a:IsA("GuiObject") and a:GetAttribute("Kind")
		if kind and KIND[kind] then return KIND[kind], a end
		if a:IsA("GuiObject") and a.BackgroundTransparency < 0.5 then return a.BackgroundColor3, a end
		a = a.Parent
	end
	return nil
end
local ok, test = pcall(function() return Color3.new(1, 1, 1):GetContrastRatio(Color3.new(0, 0, 0)) end)
if not ok then return "Color3:GetContrastRatio is not available in this Studio: " .. tostring(test) end
local low, n, unknown = {}, 0, 0
for _, d in pg:GetDescendants() do
	if (d:IsA("TextLabel") or d:IsA("TextButton")) and d.Text ~= "" and d.TextTransparency < 0.5 and shown(d) then
		n += 1
		local bg = d.BackgroundTransparency < 0.5 and d.BackgroundColor3 or backOf(d)
		if not bg then
			unknown += 1
		else
			local ratio = d.TextColor3:GetContrastRatio(bg)
			local outlined = d.TextStrokeTransparency < 0.5 or (d:FindFirstChildOfClass("UIStroke") ~= nil and d:FindFirstChildOfClass("UIStroke").Transparency < 0.5)
			if ratio < 3 and not outlined then table.insert(low, string.format("%.1f %s '%s'", ratio, d:GetFullName():gsub("^Players%.[^.]+%.PlayerGui%.", ""), string.sub(d.Text, 1, 18))) end
		end
	end
end
table.sort(low)
return n .. " texts, " .. unknown .. " over the world or an unknown skin (not judged), " .. #low .. " under 3:1 without an outline: " .. table.concat(low, " ## ", 1, math.min(#low, 14))
