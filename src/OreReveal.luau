-- OreReveal (ReplicatedStorage.Shared.OreReveal), started by PixelClient. Master Directive v16 4.3 (the DgCswwMoMLG reference):
-- the first time a player ever cracks a layer's rarest ore (the server checks the Codex and sends Fx "oreReveal" once), a short
-- escalation stinger plays: the biome tag slides in, a ring expands, a black dot drops to the centre and bursts into the reveal
-- card with the ore's name in its own colour and its tier (RARE, MYTHIC from the fifth layer, SECRET for the Worldheart).
-- About 1.6 s, skipped by any click, tap or key. Every later find stays instant. Display only.
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local M = {}
local FONT = Enum.Font.FredokaOne
local INK = Color3.fromRGB(20, 12, 32)

local function tw(o, t, props, style, dir)
	local x = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	x:Play()
	return x
end

function M.start(E)
	local pg = E.plr:WaitForChild("PlayerGui")
	local busy = false
	local function play(layerName, oreName, color, tier)
		if busy then return end
		busy = true
		local gui = Instance.new("ScreenGui")
		gui.Name, gui.DisplayOrder, gui.IgnoreGuiInset, gui.ResetOnSpawn = "OreReveal", 60, true, false
		gui.Parent = pg
		local done = false
		local function finish()
			if done then return end
			done = true
			for _, o in gui:GetDescendants() do
				if o:IsA("TextLabel") then tw(o, 0.2, { TextTransparency = 1, TextStrokeTransparency = 1 })
				elseif o:IsA("Frame") then tw(o, 0.2, { BackgroundTransparency = 1 }) end
			end
			task.delay(0.25, function() gui:Destroy() busy = false end)
		end
		local skip = UIS.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.Keyboard then finish() end
		end)
		gui.Destroying:Connect(function() skip:Disconnect() end)
		local function label(txt, size, pos, col, z)
			local l = Instance.new("TextLabel")
			l.BackgroundTransparency, l.Font, l.TextScaled, l.Text, l.TextColor3, l.ZIndex = 1, FONT, true, txt, col, z or 3
			l.Size, l.Position, l.AnchorPoint = size, pos, Vector2.new(0.5, 0.5)
			l.TextStrokeColor3, l.TextStrokeTransparency = INK, 0
			l.Parent = gui
			return l
		end
		-- 1. the biome tag slides in from the left
		local tag = label(string.upper(layerName), UDim2.fromScale(0.34, 0.05), UDim2.fromScale(-0.2, 0.3), Color3.fromRGB(236, 224, 255))
		tw(tag, 0.3, { Position = UDim2.fromScale(0.5, 0.3) }, Enum.EasingStyle.Back)
		task.wait(0.3)
		if done then return end
		-- 2. a ring in the ore's colour expands from the centre
		local ring = Instance.new("Frame")
		ring.AnchorPoint, ring.Position, ring.Size, ring.BackgroundTransparency, ring.ZIndex = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.02, 0.02), 1, 2
		local ar = Instance.new("UIAspectRatioConstraint") ar.Parent = ring
		local rc = Instance.new("UICorner") rc.CornerRadius = UDim.new(0.5, 0) rc.Parent = ring
		local rs = Instance.new("UIStroke") rs.Color, rs.Thickness = color, 6 rs.Parent = ring
		ring.Parent = gui
		tw(ring, 0.45, { Size = UDim2.fromScale(0.6, 0.6) })
		tw(rs, 0.45, { Transparency = 1 })
		E.sfx("upgrade", 0.8)
		task.wait(0.3)
		if done then return end
		-- 3. a black dot drops to the centre
		local dot = Instance.new("Frame")
		dot.AnchorPoint, dot.Position, dot.Size, dot.BackgroundColor3, dot.ZIndex = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, -0.05), UDim2.fromScale(0.05, 0.05), Color3.new(0, 0, 0), 4
		local da = Instance.new("UIAspectRatioConstraint") da.Parent = dot
		local dc = Instance.new("UICorner") dc.CornerRadius = UDim.new(0.5, 0) dc.Parent = dot
		dot.Parent = gui
		tw(dot, 0.25, { Position = UDim2.fromScale(0.5, 0.5) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		task.wait(0.27)
		if done then return end
		-- 4. it bursts into the reveal card
		tw(dot, 0.2, { Size = UDim2.fromScale(0.42, 0.42), BackgroundTransparency = 0.25 })
		E.sfx("pop", 0.7)
		local name = label(string.upper(oreName), UDim2.fromScale(0.5, 0.09), UDim2.fromScale(0.5, 0.48), color, 5)
		local pill = label("FIRST " .. tier .. " FIND", UDim2.fromScale(0.26, 0.04), UDim2.fromScale(0.5, 0.56), tier == "SECRET" and Color3.new(1, 1, 1) or Color3.fromRGB(255, 212, 92), 5)
		local sc = Instance.new("UIScale") sc.Scale = 0.6 sc.Parent = name
		tw(sc, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
		pill.TextTransparency = 1
		tw(pill, 0.25, { TextTransparency = 0 })
		task.delay(1.1, finish)
	end
	M.play = play
	E.R.Fx.OnClientEvent:Connect(function(kind, layerName, oreName, color, tier)
		if kind ~= "oreReveal" then return end
		task.delay(1.2, play, layerName, oreName, color, tier) -- after the ore card lands
	end)
	E.plr:GetAttributeChangedSignal("DevOreReveal"):Connect(function() -- Studio test hook: plays the Worldheart reveal
		if E.plr:GetAttribute("DevOreReveal") then play("The Great Gap", "Worldheart", Color3.fromRGB(255, 222, 124), "SECRET") end
	end)
end

return M
