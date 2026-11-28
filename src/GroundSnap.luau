-- GroundSnap (ServerScriptService.GroundSnap), run by PixelServer once the caves are built. Town and Mine Map Overhaul 2026-11-27
-- (vault Briefs/Town and Mine Map Overhaul 2.2 and Whole Game Polish audit mesh 1):
--   snap(caves): every ore deposit stands on rock. A ray straight down from just over each deposit's foot finds the floor (cave
--     rock only: Walls, Floor, Ramps, the Clay hall, the camp and the gate); the deposit moves so its foot sits 0.35 studs into it.
--     A deposit with no floor within 2.5 studs is moved down to the floor under it (up to 14 studs) or, with none, taken away.
--   clearZips(caves, r): no prop, crystal or decor piece within r studs of a zip line's ride path (the rope, the rider hanging
--     3 studs under it): a cyan prism sliced across the L1 Root Zipline and the camera (audit mesh 1, 6:14).
local M = {}
local SOLID = { Walls = true, Floor = true, Ramps = true, Clay = true, Camp = true, Gate = true }

local function solids(caves)
	local list = {}
	for _, c in caves:GetChildren() do
		local n = c.Name:gsub("^L2_", "")
		if SOLID[n] then table.insert(list, c) end
	end
	return list
end
M.solids = solids

function M.snap(caves)
	local dep = caves:FindFirstChild("Deposits")
	if not dep then return 0, 0, 0 end
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Include
	rp.FilterDescendantsInstances = solids(caves)
	local moved, pruned, ok = 0, 0, 0
	for _, d in dep:GetChildren() do
		if d:IsA("Model") and #d:GetChildren() > 0 then
			local cf, size = d:GetBoundingBox()
			local bottom = cf.Position.Y - size.Y / 2
			local core = d.PrimaryPart and d.PrimaryPart.Position or cf.Position
			local from = Vector3.new(core.X, bottom + 2, core.Z)
			local hit = workspace:Raycast(from, Vector3.new(0, -4.5, 0), rp) or workspace:Raycast(from, Vector3.new(0, -16, 0), rp)
			if hit then
				local shift = hit.Position.Y - 0.35 - bottom
				if math.abs(shift) > 0.1 then
					d:PivotTo(d:GetPivot() + Vector3.new(0, shift, 0))
					moved += 1
				else
					ok += 1
				end
			else
				d:Destroy()
				pruned += 1
			end
		end
	end
	dep:SetAttribute("SnapMoved", moved)
	dep:SetAttribute("SnapPruned", pruned)
	return moved, pruned, ok
end

local function distToSeg(p, a, b)
	local ab = b - a
	local t = math.clamp((p - a):Dot(ab) / math.max(ab:Dot(ab), 1e-6), 0, 1)
	return (p - (a + ab * t)).Magnitude
end
M.distToSeg = distToSeg

function M.ropes(caves)
	local out = {}
	local z = caves:FindFirstChild("Ziplines")
	for _, r in z and z:GetChildren() or {} do
		local a, b = r:GetAttribute("ZipA"), r:GetAttribute("ZipB")
		if typeof(a) == "Vector3" and typeof(b) == "Vector3" then table.insert(out, { a - Vector3.new(0, 3, 0), b - Vector3.new(0, 3, 0) }) end
	end
	return out
end

function M.clearZips(caves, r)
	local n = 0
	for _, seg in M.ropes(caves) do
		for _, fname in { "Props", "Decor", "Landmark" } do -- set dressing only: never the rock, the landmarks' stone or the ride's own posts
			local f = caves:FindFirstChild(fname)
			for _, p in f and f:GetDescendants() or {} do
				if p:IsA("BasePart") and p.Parent and (fname ~= "Landmark" or string.find(p.Name, "Crystal")) and math.max(p.Size.X, p.Size.Y, p.Size.Z) < 24 and distToSeg(p.Position, seg[1], seg[2]) < r + math.max(p.Size.X, p.Size.Y, p.Size.Z) / 2 then
					local m = p:FindFirstAncestorOfClass("Model")
					if fname ~= "Landmark" and m and m ~= f and m:IsDescendantOf(f) then m:Destroy() else p:Destroy() end -- a landmark loses only the crystal, never the whole model
					n += 1
				end
			end
		end
	end
	caves:SetAttribute("ZipCleared", n)
	return n
end

-- wayfinding(caves, C) (Town and Mine Map Overhaul 2.4: light = attention): warm lantern posts every 34 studs along the main
-- route from Camp 1 to the Cathedral landmark (the server's PathfindingService finds it; side branches stay cool and dark), and
-- a Lamplighter's wooden signpost at each fork: one board points back to CAMP 1, one on to the ROOT WARDEN, and at the Swallow
-- Hole and the Old Tube a third names the place. Layer 1 only (the spots without the L2_ prefix). No collision.
local WOOD, WOOD_D, CARVED, WARM = Color3.fromRGB(150, 104, 64), Color3.fromRGB(70, 44, 30), Color3.fromRGB(255, 240, 210), Color3.fromRGB(255, 196, 120)
local function prop(parent, name, size, cf, color, mat)
	local p = Instance.new("Part")
	p.Name, p.Size, p.CFrame, p.Color, p.Material = name, size, cf, color, mat or Enum.Material.Wood
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	p.Parent = parent
	return p
end
local function board(parent, at, dir, words)
	-- a board pointing along dir; each side reads with its arrow on the right side for the one looking at it
	local flat = Vector3.new(dir.X, 0, dir.Z)
	if flat.Magnitude < 0.01 then return end
	flat = flat.Unit
	local b = prop(parent, "SignBoard", Vector3.new(0.3, 0.95, 4.6), CFrame.lookAt(at + flat * 2.1, at + flat * 4), WOOD_D)
	prop(parent, "SignTip", Vector3.new(0.32, 0.6, 0.6), b.CFrame * CFrame.new(0, 0, -2.45) * CFrame.Angles(math.rad(45), 0, 0), WOOD_D)
	for _, face in { Enum.NormalId.Right, Enum.NormalId.Left } do
		local sg = Instance.new("SurfaceGui")
		sg.Face, sg.SizingMode, sg.PixelsPerStud, sg.LightInfluence = face, Enum.SurfaceGuiSizingMode.PixelsPerStud, 50, 0.35
		local t = Instance.new("TextLabel")
		t.Size, t.BackgroundTransparency, t.TextScaled, t.Font, t.TextColor3 = UDim2.fromScale(1, 1), 1, true, Enum.Font.FredokaOne, CARVED
		t.Text = face == Enum.NormalId.Right and (words .. "  ->") or ("<-  " .. words)
		local pad = Instance.new("UIPadding")
		pad.PaddingLeft, pad.PaddingRight, pad.PaddingTop, pad.PaddingBottom = UDim.new(0.04, 0), UDim.new(0.04, 0), UDim.new(0.12, 0), UDim.new(0.12, 0)
		pad.Parent = t
		t.Parent = sg
		sg.Parent = b
	end
end
function M.wayfinding(caves, C)
	local folder = Instance.new("Folder")
	folder.Name = "Wayfinding"
	folder.Parent = caves
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Include
	rp.FilterDescendantsInstances = solids(caves)
	local function floor(p)
		local h = workspace:Raycast(p + Vector3.new(0, 4, 0), Vector3.new(0, -20, 0), rp)
		return h and h.Position
	end
	local function spot(n)
		local o = caves:FindFirstChild("Spot_" .. n)
		local a = o and o.Value
		return a and (a:IsA("Attachment") and a.WorldPosition or (a:IsA("BasePart") and a.Position)) or nil
	end
	local camp = spot("Camp") or C.CAVE_ORIGIN
	local gateF = caves:FindFirstChild("Gate")
	local gate
	if gateF then
		local sum, n = Vector3.zero, 0
		for _, p in gateF:GetDescendants() do if p:IsA("BasePart") then sum += p.Position n += 1 end end
		if n > 0 then gate = sum / n end
	end
	local nLamp, nSign = 0, 0
	local goal = spot("Cathedral") or gate -- the main route runs from the camp to the central landmark (the Warden's Deep Gate is beside the camp)
	if goal then -- the main route's lanterns
		local path = game:GetService("PathfindingService"):CreatePath({ AgentRadius = 2, AgentHeight = 5, AgentCanJump = true, WaypointSpacing = 4 })
		local ok = pcall(function() path:ComputeAsync(camp + Vector3.new(0, 3, 0), goal) end)
		if ok and path.Status == Enum.PathStatus.Success then
			local walked, last = 0, nil
			local wps = path:GetWaypoints()
			for i, w in wps do
				if last then walked += (w.Position - last).Magnitude end
				last = w.Position
				if walked >= 34 and (w.Position - camp).Magnitude > 48 and (w.Position - goal).Magnitude > 14 and i < #wps then
					walked = 0
					local nxt = wps[math.min(#wps, i + 1)].Position
					local side = Vector3.new(-(nxt - w.Position).Z, 0, (nxt - w.Position).X)
					side = side.Magnitude > 0.01 and side.Unit or Vector3.xAxis
					local f = floor(w.Position + side * 3) or w.Position
					local post = prop(folder, "RouteLanternPost", Vector3.new(0.6, 5, 0.6), CFrame.new(f + Vector3.new(0, 2.3, 0)) * CFrame.Angles(0, 0.35, 0), WOOD_D)
					local lamp = prop(folder, "RouteLantern", Vector3.new(0.6, 0.8, 0.6), CFrame.new(f + Vector3.new(0, 5.4, 0)), WARM, Enum.Material.Neon)
					prop(folder, "RouteLanternCap", Vector3.new(1.1, 0.22, 1.1), CFrame.new(f + Vector3.new(0, 5.92, 0)), Color3.fromRGB(44, 38, 52), Enum.Material.Metal)
					local l = Instance.new("PointLight")
					l.Color, l.Range, l.Brightness, l.Shadows = WARM, 26, 0.42, false
					l.Parent = lamp
					local _ = post
					nLamp += 1
				end
			end
		end
	end
	local NAMES = { SwallowHole = "SWALLOW HOLE", OldTube = "OLD TUBE" }
	for _, n in { "B1", "B2", "B3", "B4", "B5", "SwallowHole", "OldTube", "Canyon", "Cathedral", "SumpGate" } do
		local p = spot(n)
		local f = p and floor(p)
		if f and (f - camp).Magnitude > 40 then
			local base = f + Vector3.new(2.5, 0, 2.5)
			prop(folder, "SignPost", Vector3.new(0.5, 6.4, 0.5), CFrame.new(base + Vector3.new(0, 2.95, 0)) * CFrame.Angles(0, 0.35, 0), WOOD) -- sunk and turned a little: no face shared with the voxel floor or walls (z-fight scan)
			prop(folder, "SignPostFoot", Vector3.new(1.3, 0.5, 1.3), CFrame.new(base + Vector3.new(0, 0.12, 0)) * CFrame.Angles(0, 0.8, 0), Color3.fromRGB(80, 72, 90), Enum.Material.Slate)
			board(folder, base + Vector3.new(0, 5.6, 0), camp - base, "CAMP 1")
			if gate and (gate - base).Magnitude > 20 then board(folder, base + Vector3.new(0, 4.5, 0), gate - base, "ROOT WARDEN") end
			if NAMES[n] then board(folder, base + Vector3.new(0, 3.4, 0), p - base + Vector3.new(0.01, 0, 0.01), NAMES[n]) end
			nSign += 1
		end
	end
	caves:SetAttribute("RouteLanterns", nLamp)
	caves:SetAttribute("ForkSigns", nSign)
	return nLamp, nSign
end

return M
