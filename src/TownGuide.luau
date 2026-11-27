-- TownGuide (ReplicatedStorage.Shared.TownGuide), started by PixelClient. Town overhaul 2026-11-27 (vault Briefs/Town and Mine
-- Map Overhaul 1.3): the signpost in the square names the six one-job stations and its "Guide me" prompt opens this picker. The
-- chosen station gets a beam of gold light and a trail of glowing gold voxel tiles along the walkable path to it (the client's
-- PathfindingService; a straight line where it finds none). The trail clears on arrival, after 45 s, on a new choice, or on the
-- ride down. Also E.vmHook.townGuide(key) for other menus (Shared.JourneyUI's GUIDE ME). Display only: this player's screen.
local PathfindingService = game:GetService("PathfindingService")
local PPS = game:GetService("ProximityPromptService")
local RunService = game:GetService("RunService")
local M = {}
local GOLD = Color3.fromRGB(255, 206, 84)
-- key, label, station model in the Hub, the part to walk to (first found)
M.STATIONS = {
	{ "mine", "MINE", "HubCart", { "Seat", "Body" } },
	{ "sell", "SELL", "SellStall", { "CounterTop" } },
	{ "forge", "FORGE", "Forge", { "Anvil" } },
	{ "refinery", "REFINERY", "GeodeRefinery", { "CrackBench", "Apron" } },
	{ "eggs", "EGGS", "Incubator", { "Base" } },
	{ "quests", "QUESTS", "NoticeBoard", { "Board" } },
}

local function targetOf(key)
	local hub = workspace:FindFirstChild("Hub")
	for _, d in M.STATIONS do
		if d[1] == key then
			local m = hub and hub:FindFirstChild(d[3], true)
			if not m then return nil end
			for _, n in d[4] do
				local p = m:FindFirstChild(n, true)
				if p and p:IsA("BasePart") then return p.Position, d[2] end
			end
			return m:GetPivot().Position, d[2]
		end
	end
	return nil
end
M.targetOf = targetOf

function M.start(E)
	local plr = E.plr
	local folder
	local token = 0
	local function clear()
		token += 1
		if folder then folder:Destroy() folder = nil end
	end
	local function ground(p)
		local rp = RaycastParams.new()
		rp.FilterType = Enum.RaycastFilterType.Exclude
		rp.FilterDescendantsInstances = { plr.Character, workspace.CurrentCamera }
		local hit = workspace:Raycast(p + Vector3.new(0, 6, 0), Vector3.new(0, -30, 0), rp)
		return hit and hit.Position or p
	end
	local function guide(key)
		clear()
		local my = token
		local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
		local goal, label = targetOf(key)
		if not (hrp and goal) or plr:GetAttribute("InCave") then return false end
		folder = Instance.new("Folder")
		folder.Name = "TownGuideTrail"
		folder.Parent = workspace.CurrentCamera
		local foot = ground(goal)
		local beam = Instance.new("Part") -- the beacon: a tall shaft of soft gold light over the station
		beam.Name, beam.Anchored, beam.CanCollide, beam.CanQuery, beam.CanTouch, beam.CastShadow = "GuideBeam", true, false, false, false, false
		beam.Material, beam.Color, beam.Transparency, beam.Size = Enum.Material.Neon, GOLD, 0.55, Vector3.new(1.4, 46, 1.4)
		beam.CFrame = CFrame.new(foot + Vector3.new(0, 23, 0))
		beam.Parent = folder
		local l = Instance.new("PointLight")
		l.Color, l.Range, l.Brightness = GOLD, 16, 1.2
		l.Parent = beam
		local pts = {}
		local path = PathfindingService:CreatePath({ AgentRadius = 2, AgentHeight = 5, AgentCanJump = true, WaypointSpacing = 3 })
		local ok = pcall(function() path:ComputeAsync(hrp.Position, foot) end)
		if ok and path.Status == Enum.PathStatus.Success then
			for _, w in path:GetWaypoints() do table.insert(pts, w.Position) end
		else -- shortcut: a straight line when the navmesh has no route; fine on the open town square
			local a, b = hrp.Position, foot
			local n = math.max(2, math.floor((b - a).Magnitude / 3))
			for i = 0, n do table.insert(pts, ground(a:Lerp(b, i / n))) end
		end
		if my ~= token then return false end
		local tiles = {}
		for i, p in pts do
			if i > 1 and i % 1 == 0 then
				local prev = pts[i - 1]
				local t = Instance.new("Part") -- a glowing gold voxel tile, turned along the way
				t.Name, t.Anchored, t.CanCollide, t.CanQuery, t.CanTouch, t.CastShadow = "GuideTile", true, false, false, false, false
				t.Material, t.Color, t.Size = Enum.Material.Neon, GOLD, Vector3.new(1.7, 0.2, 1.7)
				local flat = Vector3.new(p.X - prev.X, 0, p.Z - prev.Z)
				t.CFrame = (flat.Magnitude > 0.05 and CFrame.lookAt(p, p + flat) or CFrame.new(p)) * CFrame.new(0, 0.12, 0) * CFrame.Angles(0, math.rad(45), 0)
				t.Transparency = 0.15
				t.Parent = folder
				table.insert(tiles, t)
			end
		end
		E.toast("FOLLOW THE GOLD TRAIL TO " .. label, GOLD, true)
		if E.sfx then E.sfx("pop", 1.2) end
		local t0 = os.clock()
		local conn
		conn = RunService.Heartbeat:Connect(function()
			if my ~= token or not folder then conn:Disconnect() return end
			local h = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
			local tt = os.clock() - t0
			for i, t in tiles do t.Transparency = 0.15 + 0.5 * (0.5 + 0.5 * math.sin(tt * 5 - i * 0.6)) end -- a wave running toward the station
			beam.Transparency = 0.5 + 0.15 * math.sin(tt * 3)
			if tt > 45 or plr:GetAttribute("InCave") or (h and (Vector3.new(h.Position.X, 0, h.Position.Z) - Vector3.new(foot.X, 0, foot.Z)).Magnitude < 8) then
				conn:Disconnect()
				clear()
			end
		end)
		return true
	end
	E.vmHook.townGuide = guide

	-- the picker: six buttons, one per station
	local win = E.panel(E.gui, E.S(640, 330), E.S(640, 330), Vector2.new(0.5, 0.5), "panel")
	E.fit(win, 640, 330)
	win.Name, win.Visible = "TownGuide", false
	if E.addModal then E.addModal(win) end
	win.ClipsDescendants = true
	local title = E.text(win, "GUIDE ME TO", UDim2.fromScale(0.6, 0.13), UDim2.fromScale(0.5, 0.11), Vector2.new(0.5, 0.5), E.WHITE, 700, false)
	title.Font, title.ZIndex = E.HEAD or title.Font, 6
	local close = E.closeButton(win, "TownGuideClose")
	for i, d in M.STATIONS do
		local col, row = (i - 1) % 3, (i - 1) // 3
		local b = E.button(win, d[2], UDim2.fromScale(0.28, 0.27), UDim2.fromScale(0.05 + col * 0.31, 0.24 + row * 0.35), nil, ({ "mint", "butter", "pink", "lilac", "pink", "sky" })[i])
		b.Name, b.ZIndex = "Guide" .. d[2], 6
		b.Activated:Connect(function()
			E.closePanel(win)
			guide(d[1])
		end)
	end
	close.Activated:Connect(function() E.closePanel(win) end)
	PPS.PromptTriggered:Connect(function(prompt)
		if prompt.Parent and prompt.Parent:GetAttribute("Station") == "guide" and not win.Visible then E.openPanel(win) end
	end)
	plr:GetAttributeChangedSignal("InCave"):Connect(function() if plr:GetAttribute("InCave") then clear() end end)
	plr:GetAttributeChangedSignal("DevGuide"):Connect(function() -- Studio test hook: player attribute DevGuide = a station key
		local k = plr:GetAttribute("DevGuide")
		if k == "picker" then E.openPanel(win) elseif type(k) == "string" then guide(k) end
	end)
end

return M
