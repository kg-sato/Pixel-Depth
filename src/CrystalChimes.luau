-- CrystalChimes (ReplicatedStorage.Shared.CrystalChimes), started by PixelClient. Directive v10, "Crystal Resonance Chimes
-- (Camp 2 Clay Caves)": three tall crystals stand in a row in the Clay Caves hall. Strike any of them to wake them: each
-- then shows a number, 1, 2 and 3, in an order the server picked. Run and strike them in that order before the time is up
-- and all three shatter and pay. A wrong crystal ends the try. Nothing locks the view: it is all in the world.
-- The server (ClayCaves) owns the order, the clock, the pay and the cooldown; this module shows the numbers, the ringing,
-- the shatter and the toasts.
local TweenService = game:GetService("TweenService")
local M = {}

function M.start(E)
	local C, R = E.C, E.R
	if not C.CHIMES then return end
	local GOLD, WHITE = Color3.fromRGB(255, 214, 107), Color3.new(1, 1, 1)
	local function chimes()
		local out = {}
		local cv = workspace:FindFirstChild("Caves")
		for _, d in cv and cv:GetDescendants() or {} do
			if d:IsA("BasePart") and d:GetAttribute("ChimeCrystal") then out[d:GetAttribute("ChimeCrystal")] = d end
		end
		return out
	end
	local function badge(p)
		local bb = p:FindFirstChild("ChimeNumber")
		if bb then return bb, bb.Num end
		bb = Instance.new("BillboardGui")
		bb.Name, bb.Size, bb.StudsOffsetWorldSpace, bb.LightInfluence, bb.MaxDistance, bb.Enabled = "ChimeNumber", UDim2.fromOffset(46, 46), Vector3.new(0, p.Size.Y / 2 + 3.4, 0), 0, 35, false -- a fixed 46 px badge: at 2.2 studs it filled the top of the view up close and ran over the HUD (full1119d 321 s, 2026-11-19)
		local t = Instance.new("TextLabel")
		t.Name, t.Size, t.BackgroundColor3, t.BackgroundTransparency, t.TextScaled, t.Font, t.TextColor3 = "Num", UDim2.fromScale(1, 1), Color3.fromRGB(36, 17, 56), 0.15, true, Enum.Font.FredokaOne, WHITE
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.5, 0)
		corner.Parent = t
		local st = Instance.new("UIStroke")
		st.Color, st.Thickness = Color3.fromRGB(224, 176, 255), 2
		st.Parent = t
		t.Parent = bb
		bb.Parent = p
		return bb, t
	end
	local run = 0
	local function hideAll()
		for _, p in chimes() do
			local bb = p:FindFirstChild("ChimeNumber")
			if bb then bb.Enabled = false end
		end
	end
	local function ring(p, pitch)
		local was = p.Size
		p.Size = was * 1.12
		TweenService:Create(p, TweenInfo.new(0.35, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), { Size = was }):Play()
		if E.burst then E.burst(p.Position + Vector3.new(0, p.Size.Y / 2, 0), Vector3.yAxis, p.Color, 10) end
		pcall(E.sfx, "pluck", pitch)
	end
	R.Fx.OnClientEvent:Connect(function(kind, what, a, b)
		if kind ~= "chime" then return end
		local cs = chimes()
		if what == "cool" then
			E.toast("THE CHIMES ARE STILL.  THEY RING AGAIN IN " .. tostring(a) .. " MIN", WHITE)
		elseif what == "start" and type(a) == "table" then
			run += 1
			local me = run
			for n, k in a do
				local p = cs[k]
				if p then
					local bb, t = badge(p)
					t.Text, t.TextColor3 = tostring(n), WHITE
					bb.Enabled = true
					ring(p, 0.8 + n * 0.1)
				end
			end
			E.toast("THE CHIMES WAKE!  STRIKE 1, 2, 3 IN ORDER", GOLD, true)
			task.delay(tonumber(b) or C.CHIMES.secs, function() if run == me then hideAll() end end)
		elseif what == "hit" then
			local p = cs[a]
			if p then
				ring(p, 1 + (tonumber(b) or 1) * 0.2)
				local bb, t = badge(p)
				t.TextColor3 = GOLD
			end
		elseif what == "miss" then
			run += 1
			hideAll()
			pcall(E.sfx, "click", 0.6)
			E.toast("WRONG CRYSTAL.  THE CHIMES FALL SILENT", WHITE)
		elseif what == "done" then
			run += 1
			hideAll()
			for _, p in cs do -- the shatter: every crystal bursts, vanishes and grows back
				if E.burst then E.burst(p.Position, Vector3.yAxis, p.Color, 40) end
				p.LocalTransparencyModifier = 1
				task.delay(6, function() if p.Parent then p.LocalTransparencyModifier = 0 end end)
			end
			pcall(E.sfx, "upgrade", 1.3)
			if E.shake then E.shake(0.6) end
			E.toast("RESONANCE!  +" .. tostring(a) .. " COINS", GOLD, true)
		end
	end)
end

return M
