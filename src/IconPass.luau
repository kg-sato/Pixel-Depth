-- IconPass (ReplicatedStorage.Shared.IconPass), started by PixelClient. The owner, 2026-11-18: "a lot of the icons need work and
-- some places need icons where there are none". Gemini went through the whole-game recording and listed the words that should
-- carry an icon (vault Briefs/UI Font and Icon Pass (2026-11-18).md). This puts a jelly icon (art/icons_jelly2, Config.UI_GLASS.icon)
-- in front of each of those words wherever it appears in the player's guis, and swaps it when the text changes (a timer that
-- shows the next event, a toast). The label keeps its text; the icon sits just left of where the text starts and the text moves
-- over by a padding, so labels made by any module get the same treatment. Display only.
local M = {}
local C = require(script.Parent:WaitForChild("Config"))
local ICON = (C.UI_GLASS and C.UI_GLASS.icon) or {}

-- the first rule whose pattern matches the label's text picks the icon (patterns run on the upper-cased text)
M.RULES = {
	{ "^MENU$", "book" }, { "^HOME$", "home" }, { "^DONE$", "check" }, { "^QUESTS$", "star" }, { "^ORE BANK$", "pouch" }, { "^ITEMS$", "chest" },
	{ "^SPORE STORM", "spore" }, { "^ROOTS STIR", "root" }, { "^THE WORLD TREE ROOTS", "root" }, { "^CRYSTAL RIFT", "gem" }, { "^GOLD SURGE", "coin" }, { "^KILN SURGE", "kiln" },
	{ "^PLAYTIME GIFT", "gift" }, { "^GIFT", "gift" },
	{ "^TIME$", "stopwatch" }, { "^DODGES$", "boot" }, { "^BOOSTS$", "boot" }, { "^THE GLOOM$", "skull" }, { "^BONUS$", "pouch" },
	{ "^CAMP 1$", "root" }, { "^CAMP 2$", "kiln" },
	{ "^ORE %d+/%d+", "pick" }, { "^COINS [%d,]+/[%d,]+", "coin" }, -- the next-upgrade tracker's progress line
	{ "^%+[%d,]+ GEMS?", "gem" }, { "^%+ ?[%d,]* ?GEM", "gem" }, { "^%+[%d,]+ COINS?", "coin" },
}
function M.pick(text)
	local up = string.upper(text or "")
	for _, r in M.RULES do
		if string.find(up, r[1]) and ICON[r[2]] then return r[2] end
	end
	return nil
end

local function hasOwnIcon(label) -- kit buttons already carry their icon beside the label (or inside it: the QUESTS TextButton was padded flat, directive v14)
	return label:FindFirstChild("Icon") ~= nil or (label.Parent ~= nil and label.Parent:FindFirstChild("Icon") ~= nil)
end

local function isShadow(label) -- a drop-shadow copy under the real words (float texts, toasts): one icon is enough
	for _, o in label.Parent and label.Parent:GetChildren() or {} do
		if o ~= label and o:IsA("TextLabel") and o.Text == label.Text and o.ZIndex > label.ZIndex then return true end
	end
	return false
end

function M.attach(label)
	if label:GetAttribute("IconPass") or hasOwnIcon(label) or isShadow(label) then return end
	local sg = label:FindFirstAncestorWhichIsA("SurfaceGui")
	if sg and string.sub(sg.Name, 1, 3) == "AR_" then return end -- the look-around controls list has its own key caps: a star beside "J Quests" read as stray (Orchestrator round 2)
	label:SetAttribute("IconPass", true)
	local icon, pad, base, size0, watched
	local queue
	local passT, passes, retry = 0, 0, false -- the re-place passes in the last half second (bounded: see queue)
	local function place()
		local key = M.pick(label.Text)
		if not key then
			if icon then icon.Visible = false end
			if pad then pad.PaddingLeft = base end
			return
		end
		local h = label.AbsoluteSize.Y
		if h < 6 then return end
		if not icon then
			pad = label:FindFirstChildOfClass("UIPadding")
			if not pad then pad = Instance.new("UIPadding") pad.Parent = label end
			base = pad.PaddingLeft
			icon = Instance.new("ImageLabel")
			icon.Name, icon.BackgroundTransparency, icon.ScaleType = "PassIcon", 1, Enum.ScaleType.Fit
			icon.AnchorPoint = Vector2.new(0.5, 0.5)
			icon.Parent = label
		end
		local text = label.TextBounds.Y > 0 and label.TextBounds.Y or h * 0.6
		-- k = screen pixels per offset unit here: a UIScale above the label (pop-ins) or a 3D panel's canvas scales offsets, so
		-- sizes are measured on screen and divided by k before they go into offsets (measured from the icon itself)
		local k = (icon.Size.X.Offset > 0 and icon.AbsoluteSize.X > 0) and icon.AbsoluteSize.X / icon.Size.X.Offset or 1
		local sAbs = math.clamp(math.max(text * 1.35, h * 0.72), math.min(12, h * 1.15), h * 1.15) -- a little taller than the capitals: an icon reads at the size of the word's line
		local s = sAbs / k
		if icon.Size.X.Offset > 0 and math.abs(icon.Size.X.Offset - s) * k < 1 then s = icon.Size.X.Offset sAbs = s * k end -- a scaled word's ink height and the icon's padding moved each other by a screen pixel a pass: keep the old size (and place by it)
		icon.Image, icon.Visible, icon.ZIndex = ICON[key], true, label.ZIndex + 2
		icon.Size = UDim2.fromOffset(s, s)
		pad.PaddingLeft = UDim.new(base.Scale, base.Offset + s * 1.05)
		if label.TextScaled and label.Parent:IsA("GuiObject") then -- a tight scaled word (MENU) would shrink to make room: widen it into the pill's spare width instead
			size0 = size0 or label.Size
			local grow = math.max(0, math.min(s * 1.05, (label.Parent.AbsoluteSize.X * 0.84 - (label.AbsoluteSize.X - (label.Size.X.Offset - size0.X.Offset) * k)) / k))
			local want = UDim2.new(size0.X.Scale, size0.X.Offset + grow, size0.Y.Scale, size0.Y.Offset)
			if label.Size ~= want then label.Size = want end
		end
		local xa = label.TextXAlignment
		local jel = label:FindFirstChild("Jelly")
		if jel and not jel:IsA("GuiObject") then jel = nil end -- JellyPress names its bounce UIScale "Jelly" too
		if jel and not watched then
			watched = true
			for _, prop in { "AbsoluteSize", "AbsolutePosition", "Visible" } do jel:GetPropertyChangedSignal(prop):Connect(queue) end
		end
		local left = base.Scale * label.AbsoluteSize.X + base.Offset * k -- where the padded area starts, on screen
		-- the icon is a child of the label, so it sits inside the padding: its offsets count from the padded corner, found from the icon's own place
		local padded = icon.AbsolutePosition.X + icon.AnchorPoint.X * icon.AbsoluteSize.X - icon.Position.X.Offset * k
		-- where the ink really starts: the 3D jelly row or Gumdrop's ink box (the plain glyphs are hidden and report no width), else the plain text
		local gum, box = label:FindFirstChild("Gum"), label:GetAttribute("GumBox")
		local inkX
		if jel and jel.Visible then
			inkX = jel.AbsolutePosition.X
		elseif gum and gum.Visible and box then
			inkX = gum.AbsolutePosition.X + box.Min.X
		else
			local w = label.TextBounds.X
			local inner = label.AbsoluteSize.X - left - (pad.PaddingRight.Scale * label.AbsoluteSize.X + pad.PaddingRight.Offset * k) - sAbs * 1.05
			inkX = padded + (xa == Enum.TextXAlignment.Left and 0 or (xa == Enum.TextXAlignment.Right and inner - w or (inner - w) / 2))
		end
		local want = UDim2.new(0, (inkX - sAbs * 0.6 - padded) / k, 0.5, 0) -- just left of where the text starts
		if (icon.Position.X.Offset - want.X.Offset) ^ 2 > 0.25 then -- one more pass once the new place has been drawn, but a few at most:
			-- a label whose ink width and icon place keep moving each other chained deferred passes until Roblox stopped it
			-- ("Maximum re-entrancy depth (80) exceeded calling task.defer", crew and Camp 2 tests, 2026-11-21)
			icon.Position = want
			queue()
		end
		icon.ImageTransparency = label.TextTransparency
	end
	local queued = false
	function queue()
		if queued then return end
		local now = os.clock()
		if now - passT > 0.5 then passT, passes = now, 0 end
		passes += 1
		if passes > 8 then -- the label's own signals (its size, ink width, jelly row) re-queue too: the bound sits here, with one late pass
			if not retry then retry = true task.delay(0.5, function() retry = false if label.Parent then queue() end end) end
			return
		end
		queued = true
		task.defer(function() queued = false if label.Parent then place() end end)
	end
	for _, p in { "Text", "AbsoluteSize", "TextBounds", "TextXAlignment", "TextTransparency" } do label:GetPropertyChangedSignal(p):Connect(queue) end
	label:GetAttributeChangedSignal("GumWidth"):Connect(queue)
	label:GetAttributeChangedSignal("GumBox"):Connect(queue)
	label.ChildAdded:Connect(function() task.defer(queue) end) -- the jelly row or the Gumdrop holder often arrives after the icon
	queue()
end

-- Master Directive v16 2.3 (uisk_r2: matte primary buttons looked unembellished): the primary calls to action get a thin warm brass
-- rim just inside their matte skin, the restraint-first accent of the DfO3Yiyys6r reference. Display only.
M.CTA = { "^FORGE$", "^SELL", "^INVEST", "STRIKE!$", "^GRAB", "^HATCH", "^BUY", "^CLAIM", "^OPEN$" }
function M.bevel(b)
	if b:FindFirstChild("Bevel") or not b:FindFirstChild("Skin") then return end
	local f = Instance.new("Frame")
	f.Name, f.BackgroundTransparency, f.AnchorPoint, f.Position, f.Size, f.ZIndex = "Bevel", 1, Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5), UDim2.new(1, -8, 1, -8), b.ZIndex
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 10)
	c.Parent = f
	local s = Instance.new("UIStroke")
	s.Color, s.Thickness, s.Transparency = Color3.fromRGB(232, 186, 96), 1.75, 0.15
	s.Parent = f
	f.Parent = b
end
local function cta(d)
	if not d:IsA("TextButton") then return end
	local up = string.upper(d.Text)
	for _, p in M.CTA do if string.find(up, p) then M.bevel(d) return end end
end

function M.start(E)
	local pg = E.plr:WaitForChild("PlayerGui")
	local function look(d)
		cta(d)
		if (d:IsA("TextLabel") or d:IsA("TextButton")) and not d:GetAttribute("IconPass") then
			if M.pick(d.Text) then M.attach(d) return end
			local c c = d:GetPropertyChangedSignal("Text"):Connect(function() -- a label that gets its words later (timers, toasts)
				if M.pick(d.Text) then c:Disconnect() M.attach(d) end
			end)
		end
	end
	for _, d in pg:GetDescendants() do look(d) end
	pg.DescendantAdded:Connect(function(d) task.defer(look, d) end)
end

-- self-check: the rules pick the right icons and leave plain words alone
assert(M.pick("SPORE STORM IN 03:47") == (ICON.spore and "spore" or nil) and M.pick("MENU") == (ICON.book and "book" or nil) and M.pick("MENUS") == nil and M.pick("+150 COINS") == (ICON.coin and "coin" or nil), "IconPass: rules")
return M
