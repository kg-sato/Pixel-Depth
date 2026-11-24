-- HeatBeat (ReplicatedStorage.Shared.HeatBeat). Master Directive v15 (@neochampy's anvil heat window, vault Social References
-- Review (2026-11-23)): HEAT & BLOW, a one-press beat inside the forging scenes of a new pickaxe (ForgeCutscene before the
-- hammer slam, ForgeStory before the name card). The scene holds while a compact HEARTH HEAT gauge sweeps; Space, a click
-- or a tap inside the gold band is a PERFECT FORGE: the scene adds its own flash and sparks, this module shows the words and
-- plays the anvil chord, and the server pays 5% of the pickaxe's price back. The server owns the needle's clock and the
-- judgement (PixelServer HeatR, C.HEAT, a one-use token from the purchase); the beat never waits long for it.
--   local beat = HeatBeat.new(gui, token, sfx)   -- nil without a token or the remote
--   beat:start()   beat:step()   (each frame; the scene's clock holds while beat.on)   beat:stop()
--   beat.onPerfect(rebate), beat.onMiss()        -- optional scene hooks
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local CAS = game:GetService("ContextActionService")
local M = {}
M.__index = M
local WHITE = Color3.new(1, 1, 1)

function M.new(gui, token, sfx)
	local Cfg = require(RS.Shared:WaitForChild("Config"))
	local H = Cfg.HEAT
	local R = RS:FindFirstChild("Remotes") and RS.Remotes:FindFirstChild("Heat")
	if type(token) ~= "string" or not H or not R then return nil end
	local self = setmetatable({ on = false, token = token, R = R, Cfg = Cfg, H = H, sfx = sfx or function() end }, M)
	local function frame(props)
		local f = Instance.new("Frame")
		f.BorderSizePixel = 0
		for k, v in props do f[k] = v end
		f.Parent = props.Parent or gui
		return f
	end
	local gauge = frame({ Name = "HearthHeat", Size = UDim2.fromScale(0.44, 0.13), Position = UDim2.fromScale(0.5, 0.22), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.fromRGB(22, 10, 18), BackgroundTransparency = 0.12, Visible = false, ZIndex = 20 })
	Instance.new("UICorner", gauge).CornerRadius = UDim.new(0.3, 0)
	local edge = Instance.new("UIStroke")
	edge.Color, edge.Thickness, edge.Transparency = Color3.fromRGB(214, 150, 70), 3, 0.05 -- a bronze rim (Gemini v15_r1: "unstyled, flat")
	edge.Parent = gauge
	local bar = frame({ Parent = gauge, Size = UDim2.fromScale(0.92, 0.26), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = WHITE, ZIndex = 21 })
	Instance.new("UICorner", bar).CornerRadius = UDim.new(0.5, 0)
	local grad = Instance.new("UIGradient") -- crimson at the cold and the scorched ends, white-hot gold in the middle
	grad.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(150, 30, 40)), ColorSequenceKeypoint.new(0.3, Color3.fromRGB(240, 110, 40)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 200, 90)), ColorSequenceKeypoint.new(0.7, Color3.fromRGB(240, 110, 40)), ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 30, 40)) })
	grad.Parent = bar
	local band = frame({ Parent = bar, Name = "Perfect", Size = UDim2.fromScale(H.band * 2, 1.5), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.fromRGB(255, 226, 120), BackgroundTransparency = 0.25, ZIndex = 22 })
	local bandEdge = Instance.new("UIStroke")
	bandEdge.Color, bandEdge.Thickness = Color3.fromRGB(255, 244, 200), 2
	bandEdge.Parent = band
	local needle = frame({ Parent = bar, Name = "Needle", Size = UDim2.fromScale(0.012, 2.1), Position = UDim2.fromScale(0, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = WHITE, ZIndex = 23 })
	local nEdge = Instance.new("UIStroke")
	nEdge.Color, nEdge.Thickness = Color3.fromRGB(40, 16, 20), 2
	nEdge.Parent = needle
	local function words(parent, txt, size, pos, color, xa, z)
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency, l.Font, l.TextScaled, l.Text, l.TextColor3, l.ZIndex = 1, Enum.Font.FredokaOne, true, txt, color, z or 22
		l.Size, l.Position, l.AnchorPoint, l.TextXAlignment = size, pos, Vector2.new(0.5, 0.5), xa or Enum.TextXAlignment.Center
		local st = Instance.new("UIStroke")
		st.Color, st.Thickness = Color3.fromRGB(30, 10, 16), 2
		st.Parent = l
		local c = Instance.new("UITextSizeConstraint")
		c.MinTextSize = 13
		c.Parent = l
		l.Parent = parent
		return l, st
	end
	local touchOnly = UIS.TouchEnabled and not UIS.KeyboardEnabled
	words(gauge, "HEARTH HEAT", UDim2.fromScale(0.6, 0.27), UDim2.fromScale(0.5, 0.17), Color3.fromRGB(255, 196, 110))
	words(gauge, touchOnly and "TAP THE BAR IN THE GOLD!" or "STRIKE IN THE GOLD!   SPACE / CLICK THE BAR", UDim2.fromScale(0.8, 0.22), UDim2.fromScale(0.5, 0.83), WHITE) -- under the bar, not squeezed beside the title
	local result, rStroke = words(gui, "", UDim2.fromScale(0.6, 0.12), UDim2.fromScale(0.5, 0.36), WHITE, nil, 21)
	rStroke.Color, rStroke.Thickness = Color3.fromRGB(70, 30, 10), 4
	result.Visible = false
	local hit = Instance.new("TextButton") -- the whole gauge is the STRIKE button for a mouse or a finger
	hit.Name, hit.Text, hit.BackgroundTransparency, hit.AutoButtonColor, hit.ZIndex = "Strike", "", 1, false, 25
	hit.Size, hit.Position, hit.AnchorPoint = UDim2.fromScale(1.1, 1.6), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5)
	hit.Parent = gauge
	hit.Activated:Connect(function() self:press() end)
	self.flash = frame({ Name = "HeatFlash", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(255, 236, 190), BackgroundTransparency = 1, ZIndex = 19 }) -- the golden impact frame
	self.gauge, self.needle, self.result = gauge, needle, result
	return self
end

function M:stop()
	if self.con then self.con:Disconnect() self.con = nil end
	if self.on then
		self.on = false
		self.gauge.Visible = false
		CAS:UnbindAction("PD_HeatStrike")
	end
end

function M:start()
	if self.on then return end
	self.on, self.at, self.startT, self.pressed = true, os.clock(), nil, false
	self.con = self.R.OnClientEvent:Connect(function(kind, id, a)
		if id ~= self.token or not self.on then return end
		if kind == "start" and type(a) == "number" then
			self.startT = a
			self.gauge.Visible = true
			self.sfx("open", 1.3)
		elseif kind == "perfect" then
			local r = self.result
			r.Text, r.TextColor3, r.Visible = "PERFECT FORGE!" .. ((tonumber(a) or 0) > 0 and ("   +" .. tostring(a) .. " COINS") or ""), Color3.fromRGB(255, 220, 110), true
			self.sfx("upgrade", 0.85)
			self.sfx("clink", 1.0)
			self.sfx("clink", 1.5)
			self.flash.BackgroundTransparency = 0.2
			game:GetService("TweenService"):Create(self.flash, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 }):Play()
			if self.onPerfect then pcall(self.onPerfect, tonumber(a) or 0) end
			task.delay(0.6, function() self:stop() end)
			task.delay(1.6, function() r.Visible = false end)
		elseif kind == "miss" then
			local r = self.result
			r.Text, r.TextColor3, r.Visible = "GOOD STRIKE", Color3.fromRGB(236, 220, 200), true
			self.sfx("clink", 0.9)
			if self.onMiss then pcall(self.onMiss) end
			task.delay(0.4, function() self:stop() end)
			task.delay(1.2, function() r.Visible = false end)
		end
	end)
	CAS:BindActionAtPriority("PD_HeatStrike", function(_, state)
		if state ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Pass end
		if self:press() then return Enum.ContextActionResult.Sink end
		return Enum.ContextActionResult.Pass
	end, false, 3000, Enum.KeyCode.Space, Enum.KeyCode.ButtonA) -- clicks and taps go to the gauge's own button, so a click on SKIP never spends the strike (Codex)
	self.R:FireServer("start", self.token)
end

function M:press() -- one strike a beat, only once the server has started the needle
	if not (self.on and self.startT and not self.pressed) then return false end
	self.pressed = true
	self.R:FireServer("press", self.token)
	self.sfx("hit", 1.1)
	return true
end

function M:step() -- each frame while on: move the needle; give up when the server is silent or the time is out
	if not self.on then return end
	local el = self.startT and (workspace:GetServerTimeNow() - self.startT) or 0
	if self.startT then self.needle.Position = UDim2.fromScale(self.Cfg.heatAt(el), 0.5) end
	if (not self.startT and os.clock() - self.at > 0.9) or el > self.H.secs + (self.pressed and 0.9 or 0.1) then self:stop() end
end

return M
