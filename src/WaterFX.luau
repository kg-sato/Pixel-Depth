-- WaterFX (ReplicatedStorage.Shared.WaterFX), started by PixelClient. Master Directive v16 3.3 (DfeYlzJMHgI, "stylized chunky
-- water"): the town stream flows (its ripple texture drifts downstream), its white foam collars shimmer in a travelling wave, and
-- stepping or landing in the water throws a voxel splash column with a foam ring. Reduced Motion keeps the water still and
-- skips the splash. Display only.
local RunService = game:GetService("RunService")
local M = {}

function M.start(E)
	local plr = E.plr
	local calm = false
	pcall(function() calm = game:GetService("GuiService").ReducedMotionEnabled end)
	local waters, textures, foams = {}, {}, {}
	local function scan()
		table.clear(waters) table.clear(textures) table.clear(foams)
		for _, g in workspace:GetDescendants() do
			if g.Name == "Stream" and (g:IsA("Model") or g:IsA("Folder")) then
				for _, p in g:GetChildren() do
					if p.Name == "Water" and p:IsA("BasePart") then
						table.insert(waters, p)
						local t = p:FindFirstChildOfClass("Texture")
						if t then table.insert(textures, t) end
					elseif p.Name == "Foam" and p:IsA("BasePart") then
						table.insert(foams, { p = p, base = p.Transparency })
					end
				end
			end
		end
	end
	task.delay(3, scan)
	task.delay(12, scan) -- the town is built by the server at start
	local t = 0
	RunService.Heartbeat:Connect(function(dt)
		if calm or #textures == 0 then return end
		t += dt
		for _, tx in textures do tx.OffsetStudsV = (tx.OffsetStudsV - dt * 0.9) % 6 end
		for i, f in foams do
			if i % 2 == (math.floor(t * 4) % 2) then -- half the collars per frame
				f.p.Transparency = f.base + 0.25 * (0.5 + 0.5 * math.sin(t * 2.2 - i * 0.35))
			end
		end
	end)
	local fx = Instance.new("Folder")
	fx.Name = "WaterFX"
	fx.Parent = workspace
	local lastSplash = 0
	local function inWater(pos)
		for _, w in waters do
			local l = w.CFrame:PointToObjectSpace(pos)
			if math.abs(l.X) < w.Size.X / 2 and math.abs(l.Z) < w.Size.Z / 2 and l.Y > -3.5 and l.Y < 1.5 then return w end
		end
		return nil
	end
	local function splash(at, top)
		if calm or os.clock() - lastSplash < 0.45 then return end
		lastSplash = os.clock()
		local base = Vector3.new(at.X, top, at.Z)
		for k = 1, 12 do
			local q = Instance.new("Part")
			q.Size = Vector3.one * (0.25 + (k % 3) * 0.08)
			q.Anchored, q.CanCollide, q.CanQuery, q.CanTouch, q.CastShadow = true, false, false, false, false
			q.Material, q.Color, q.Transparency = Enum.Material.SmoothPlastic, k % 3 == 0 and Color3.fromRGB(170, 236, 246) or Color3.fromRGB(246, 252, 255), 0.1
			local a = k / 12 * math.pi * 2
			local out = Vector3.new(math.cos(a), 0, math.sin(a))
			q.CFrame = CFrame.new(base + out * 0.4)
			q.Parent = fx
			local up = 2.2 + (k % 4) * 0.5
			local t0 = os.clock()
			local c
			c = RunService.Heartbeat:Connect(function()
				local u = os.clock() - t0
				if u > 0.7 or not q.Parent then c:Disconnect() q:Destroy() return end
				q.CFrame = CFrame.new(base + out * (0.4 + u * 2.2) + Vector3.new(0, up * u - 6 * u * u, 0)) * CFrame.Angles(u * 6, u * 4, 0)
				q.Transparency = 0.1 + u / 0.7 * 0.9
			end)
		end
		local ring = Instance.new("Part")
		ring.Shape, ring.Size = Enum.PartType.Cylinder, Vector3.new(0.05, 1, 1)
		ring.Anchored, ring.CanCollide, ring.CanQuery, ring.CanTouch, ring.CastShadow = true, false, false, false, false
		ring.Material, ring.Color, ring.Transparency = Enum.Material.SmoothPlastic, Color3.fromRGB(246, 252, 255), 0.2
		ring.CFrame = CFrame.new(base + Vector3.new(0, 0.03, 0)) * CFrame.Angles(0, 0, math.pi / 2)
		ring.Parent = fx
		E.tween(ring, 0.55, { Size = Vector3.new(0.05, 4.5, 4.5), Transparency = 1 })
		task.delay(0.6, function() ring:Destroy() end)
		pcall(function() E.sfx("splash", 1) end)
	end
	local waterTop = require(script.Parent:WaitForChild("CaveSwim")).waterTop -- the cave pools are terrain water (2026-11-27)
	local function caveWater(hrp) -- the surface under the feet in a cave pool or stream, or nil
		if not plr:GetAttribute("InCave") then return nil end
		local top = waterTop(hrp.Position - Vector3.new(0, 2.6, 0))
		return top and top > hrp.Position.Y - 3.4 and top or nil
	end
	local was = false
	local wasCave = false
	task.spawn(function()
		while true do -- stepping into a cave pool or stream: the same voxel splash and foam ring
			task.wait(0.12)
			local ch = plr.Character
			local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
			local top = hrp and caveWater(hrp)
			if top and not wasCave then splash(hrp.Position, top) end
			wasCave = top ~= nil
		end
	end)
	task.spawn(function()
		while true do
			task.wait(0.1)
			local ch = plr.Character
			local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
			local w = hrp and #waters > 0 and inWater(hrp.Position - Vector3.new(0, 2.6, 0))
			if w and not was then splash(hrp.Position, w.Position.Y + w.Size.Y / 2) end
			was = w ~= nil and w ~= false
		end
	end)
	local function hook(ch)
		local hum = ch:WaitForChild("Humanoid", 10)
		if not hum then return end
		hum.StateChanged:Connect(function(_, new)
			if new == Enum.HumanoidStateType.Landed then
				local hrp = ch:FindFirstChild("HumanoidRootPart")
				local w = hrp and inWater(hrp.Position - Vector3.new(0, 2.6, 0))
				if w then splash(hrp.Position, w.Position.Y + w.Size.Y / 2)
				elseif hrp then local top = caveWater(hrp) if top then splash(hrp.Position, top) end end
			end
		end)
	end
	if plr.Character then task.spawn(hook, plr.Character) end
	plr.CharacterAdded:Connect(hook)
end

return M
