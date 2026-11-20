-- GeodeCrack (ReplicatedStorage.Shared.GeodeCrack), started by PixelClient. Directive v10, "Geode Timing Crack (Surface
-- Anvil)": put a geode on Bolt's workbench beside the anvil in town (its prompt; the anvil has the forge's own prompt) and a ring closes in on the geode's glowing seam; one press when
-- the ring is ON the seam cracks it clean. The view is never locked: the ring floats over the anvil in the world.
-- The server takes the geode, keeps the clock and judges the press with the same sums as this module (Config.crackAt); this
-- module draws the geode, the seam and the closing ring, sends the one press and shows what the server paid.
-- Press: Space, E, gamepad A, a click or a tap.
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local M = {}

function M.start(E)
	local C, R = E.C, E.R
	local K = C.CRACK
	local CrackR = R:WaitForChild("Crack", 10)
	if not K or not CrackR then return end
	local GOLD, WHITE, PINK = Color3.fromRGB(255, 214, 107), Color3.new(1, 1, 1), Color3.fromRGB(255, 0, 127)
	local live -- { t0, folder, ring, conn, sent }
	local function anvil()
		local f = workspace:FindFirstChild("Hub") and workspace.Hub:FindFirstChild("Forge")
		for _, d in f and f:GetDescendants() or {} do -- the part that carries the crack prompt (Bolt's workbench)
			if d:IsA("ProximityPrompt") and d:GetAttribute("GeodeCrack") then return d.Parent end
		end
		return nil
	end
	local function clear()
		if not live then return end
		if live.conn then live.conn:Disconnect() end
		if live.folder then live.folder:Destroy() end
		live = nil
	end
	local function bit(parent, size, cf, color, mat, tr)
		local p = Instance.new("Part")
		p.Size, p.CFrame, p.Color, p.Material, p.Transparency, p.Anchored = size, cf, color, mat, tr or 0, true
		p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = false, false, false, false
		p.Parent = parent
		return p
	end
	local function press()
		if not live or live.sent then return end
		live.sent = true
		CrackR:FireServer()
	end
	UIS.InputBegan:Connect(function(input, typing)
		if typing or not live then return end
		local k, t = input.KeyCode, input.UserInputType
		if k == Enum.KeyCode.Space or k == Enum.KeyCode.E or k == Enum.KeyCode.ButtonA or t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then press() end
	end)
	R.Fx.OnClientEvent:Connect(function(kind, what, a, b, c)
		if kind ~= "crack" then return end
		if what == "none" then
			E.toast("NO GEODE TO CRACK.  JARS IN THE CLAY CAVES HOLD THEM", WHITE)
		elseif what == "start" and type(a) == "number" then
			clear()
			local an = anvil()
			if not an then return end
			local folder = Instance.new("Folder")
			folder.Name = "GeodeCrackFX"
			folder.Parent = workspace
			local top = an.CFrame * CFrame.new(0, an.Size.Y / 2 + 0.55, 0)
			bit(folder, Vector3.new(1.1, 1, 1.1), top * CFrame.Angles(0.2, 0.6, 0.1), Color3.fromRGB(92, 84, 112), Enum.Material.Slate)
			bit(folder, Vector3.new(0.16, 0.9, 0.16), top * CFrame.new(0, 0.1, 0) * CFrame.Angles(0.5, 0.3, 0.9), Color3.fromRGB(200, 140, 255), Enum.Material.Neon)
			local holder = bit(folder, Vector3.new(0.2, 0.2, 0.2), top * CFrame.new(0, 2.4, 0), WHITE, Enum.Material.SmoothPlastic, 1)
			local bb = Instance.new("BillboardGui")
			bb.Name, bb.Size, bb.LightInfluence, bb.MaxDistance = "CrackRing", UDim2.fromScale(4.6, 4.6), 0, 80
			local function ring(scale, color, thick)
				local f = Instance.new("Frame")
				f.Size, f.Position, f.AnchorPoint, f.BackgroundTransparency = UDim2.fromScale(scale, scale), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5), 1
				local corner = Instance.new("UICorner")
				corner.CornerRadius = UDim.new(0.5, 0)
				corner.Parent = f
				local st = Instance.new("UIStroke")
				st.Color, st.Thickness = color, thick
				st.Parent = f
				f.Parent = bb
				return f, st
			end
			local _, seamStroke = ring(K.seam, GOLD, 5) -- the seam: where the closing ring must be
			local lastTick -- (2026-11-17, Shared.StrikeJuice's recipe: a cue before the hit) ticks rising in pitch as the ring nears the seam, and the seam heats up
			local closing, stroke = ring(1, Color3.fromRGB(0, 240, 255), 4)
			local word = Instance.new("TextLabel")
			word.Size, word.Position, word.AnchorPoint, word.BackgroundTransparency = UDim2.fromScale(1.6, 0.16), UDim2.fromScale(0.5, -0.06), Vector2.new(0.5, 0.5), 1
			word.Text, word.TextScaled, word.Font, word.TextColor3 = (UIS.TouchEnabled and not UIS.KeyboardEnabled) and "TAP ON THE GOLD RING" or "SPACE ON THE GOLD RING", true, Enum.Font.FredokaOne, WHITE
			local ws = Instance.new("UIStroke")
			ws.Color, ws.Thickness = Color3.fromRGB(60, 24, 90), 2
			ws.Parent = word
			word.Parent = bb
			bb.Parent = holder
			live = { t0 = a, folder = folder, sent = false, at = top.Position }
			live.conn = RunService.RenderStepped:Connect(function()
				local u = (workspace:GetServerTimeNow() - a - K.open) / K.shrink
				local r = 1 - math.clamp(u, 0, 1)
				closing.Size = UDim2.fromScale(r, r)
				stroke.Color = Color3.fromRGB(0, 240, 255):Lerp(PINK, math.clamp(u, 0, 1))
				closing.Visible = u < 1
				local gap = r - K.seam -- > 0: the ring is still outside the seam
				local near = gap > 0 and math.clamp(1 - gap / 0.3, 0, 1) or 0
				seamStroke.Thickness = 5 + near * 5
				seamStroke.Color = GOLD:Lerp(WHITE, near * 0.5)
				if math.abs(gap) < K.perfect / K.shrink then stroke.Color, seamStroke.Color = Color3.fromRGB(80, 255, 160), Color3.fromRGB(80, 255, 160) end -- the perfect moment flashes green (Gemini full1120s: "no cue at the sweet spot")
				local step = (gap > 0 and gap < 0.3) and math.floor(gap / 0.06) or -1
				if step >= 0 and lastTick and step ~= lastTick and not live.sent then E.sfx("tick", 1 + (4 - step) * 0.12) end
				lastTick = step
			end)
			E.sfx("click", 0.8)
		elseif what == "done" then
			local at = live and live.at
			clear()
			local tier, gems, gold = a, tonumber(b) or 0, tonumber(c) or 0
			if at and E.burst then
				local col = tier == "perfect" and GOLD or Color3.fromRGB(200, 140, 255)
				E.burst(at, Vector3.yAxis, col, tier == "perfect" and 40 or (tier == "good" and 22 or 8))
				if tier ~= "bad" then task.delay(0.22, function() E.burst(at + Vector3.new(0, 0.6, 0), Vector3.yAxis, col:Lerp(Color3.new(1, 1, 1), 0.3), tier == "perfect" and 18 or 10) end) end -- a second, lighter puff: the first was gone in 0.2 s (Gemini full1119l)
			end
			E.sfx(tier == "bad" and "click" or "upgrade", tier == "perfect" and 1.4 or 1.1)
			if tier == "perfect" then E.sfx("ping", 1.2) E.sfx("crack", 1.1) E.sfx("flawless", 1) -- one sound per grade (Shared.StrikeJuice's set)
			elseif tier == "good" then E.sfx("ping", 1) E.sfx("crack", 0.9)
			else E.sfx("thud", 0.9) E.sfx("crack", 0.7) end
			E.toast((tier == "perfect" and "PERFECT CRACK!" or (tier == "good" and "GEODE CRACKED!" or "CRACKED BADLY.")) .. "  +" .. gems .. " GEMS  +" .. gold .. " COINS", tier == "bad" and WHITE or GOLD, tier ~= "bad")
		end
	end)
end

return M
