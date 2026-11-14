-- SellFountain (ReplicatedStorage.Shared.SellFountain), started by PixelClient. Directive v9 (2026-11-13), cutscene 5: selling
-- is seen in the world. When the server says ore was sold (Fx "sold"), glowing ore cubes arc from the player into the
-- nearest sell station and a fountain of coins bursts up out of it. Display only: the server has already paid. Left out with
-- the Fast cutscenes setting (attribute FastCine).
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local M = {}

function M.start(E)
	local plr = E.plr
	local folder = Instance.new("Folder")
	folder.Name = "SellFX"
	folder.Parent = workspace
	local function bit(size, pos, color, mat)
		local p = Instance.new("Part")
		p.Size, p.Position, p.Color, p.Material, p.Anchored = size, pos, color, mat, true
		p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = false, false, false, false
		p.Parent = folder
		return p
	end
	local function arc(p, from, to, height, secs, spin, done)
		local t0 = os.clock()
		local conn
		conn = RunService.RenderStepped:Connect(function()
			local k = (os.clock() - t0) / secs
			if k >= 1 or not p.Parent then
				conn:Disconnect()
				if done then done() else p:Destroy() end
				return
			end
			p.CFrame = CFrame.new(from:Lerp(to, k) + Vector3.new(0, math.sin(k * math.pi) * height, 0)) * CFrame.Angles(k * spin, k * spin * 0.7, 0)
		end)
	end
	E.R.Fx.OnClientEvent:Connect(function(kind, gold, _, moved)
		if kind ~= "sold" or plr:GetAttribute("FastCine") or type(gold) ~= "number" or gold <= 0 then return end
		local h = E.hrp()
		if not h then return end
		local stall, best = nil, 60
		for _, d in workspace:FindFirstChild("Hub") and workspace.Hub:GetDescendants() or {} do
			if d:IsA("BasePart") and d:GetAttribute("Station") == "sell" then
				local m = (d.Position - h.Position).Magnitude
				if m < best then stall, best = d, m end
			end
		end
		if not stall then return end
		local top = stall.Position + Vector3.new(0, stall.Size.Y / 2 + 0.6, 0)
		local cols = {}
		for key in moved or {} do
			local L, idx = string.match(tostring(key), "^(%d+)%.(%d+)$")
			local ore = L and E.C.LAYERS[tonumber(L)] and E.C.LAYERS[tonumber(L)][4][tonumber(idx)]
			if ore then table.insert(cols, ore[2]) end
		end
		if #cols == 0 then cols = { Color3.fromRGB(150, 110, 255), Color3.fromRGB(120, 232, 255) } end
		for i = 1, 9 do -- the ore leaves the pack in a stream
			task.delay(i * 0.05, function()
				local cube = bit(Vector3.new(0.7, 0.7, 0.7), h.Position, cols[(i - 1) % #cols + 1], Enum.Material.Neon)
				arc(cube, h.Position + Vector3.new(0, 1.5, 0), top, 4 + (i % 3), 0.42, 9)
			end)
		end
		task.delay(0.62, function() -- the fountain
			E.sfx("coin", 1.2)
			if E.shake then E.shake(0.25) end
			if E.burst then E.burst(top, Vector3.yAxis, Color3.fromRGB(255, 214, 107), 26) end
			for i = 1, 14 do
				local a = i / 14 * math.pi * 2
				local coin = bit(Vector3.new(0.14, 0.8, 0.8), top, Color3.fromRGB(255, 205, 80), Enum.Material.Neon)
				coin.Shape = Enum.PartType.Cylinder
				local out = top + Vector3.new(math.cos(a) * (2.2 + i % 3), 0.2, math.sin(a) * (2.2 + i % 3))
				arc(coin, top, out, 5.5 + (i % 4) * 0.8, 0.75 + (i % 3) * 0.08, 14, function()
					TweenService:Create(coin, TweenInfo.new(0.25), { Transparency = 1, Size = Vector3.new(0.05, 0.3, 0.3) }):Play()
					task.delay(0.27, function() coin:Destroy() end)
				end)
			end
		end)
	end)
end

return M
