-- RoofFade (ReplicatedStorage.Shared.RoofFade), started by PixelClient. Directive v13 (Gemini full1121a, first-minute town 5.2:
-- "a striped awning hid the player for 80 s, no fade"): in town, a roof or awning between the high camera and your miner fades to
-- see-through, and comes back when you step out from under it. Only this player's view changes (LocalTransparencyModifier).
-- Town overhaul 2026-11-27 (vault Briefs/Town and Mine Map Overhaul, 1.1): the old pass fired 15 rays across the lower screen and
-- a 26-stud sphere round the camera every 0.1 s and snapped every part within 6.5 studs of a hit between 0 and 0.72, so walls,
-- tree trunks and whole houses strobed while you walked. Now only parts HubBuilder tags RoofFadeTarget (roofs, ridges, awnings
-- and their scallops, the glass roof) can fade; two rays (camera to chest and head) pick them; a station's roof fades as one
-- group over 0.25 s and stays faded until the sight line clears that roof's box by 1.5 studs. In the caves, ropes, beams and
-- crystals at the lens still fade out of the way, but never water (it vanished under your feet). Display only.
local RunService = game:GetService("RunService")
local M = {}
local FADE = 0.72 -- how see-through a faded roof gets
local TIME = 0.25 -- seconds for a roof to fade in or out
local HYST = 1.5 -- studs: a faded roof stays faded while the sight line passes within this of its box

local function isWater(p)
	if p.Name == "StreamWater" or p.Name == "Water" or p:GetAttribute("Water") then return true end
	local par = p.Parent
	return par ~= nil and (par.Name == "V2Water" or par:GetAttribute("Water") == true)
end
M.isWater = isWater

local function segHitsBox(a, b, lo, hi) -- the segment a..b against an axis-aligned box (slab test)
	local d = b - a
	local t0, t1 = 0, 1
	for _, ax in { "X", "Y", "Z" } do
		local da, aa, l, h = d[ax], a[ax], lo[ax], hi[ax]
		if math.abs(da) < 1e-6 then
			if aa < l or aa > h then return false end
		else
			local u0, u1 = (l - aa) / da, (h - aa) / da
			if u0 > u1 then u0, u1 = u1, u0 end
			t0, t1 = math.max(t0, u0), math.min(t1, u1)
			if t0 > t1 then return false end
		end
	end
	return true
end
M.segHitsBox = segHitsBox

function M.start(E)
	local plr = E.plr
	-- town roofs: one group per station model; each knows its parts, its box and how faded it is now
	local groups, ofPart, list = {}, {}, {}
	local function add(p)
		if not p:IsA("BasePart") or ofPart[p] then return end
		local key = p.Parent
		local g = groups[key]
		if not g then
			g = { parts = {}, a = 0, want = false, lo = Vector3.one * math.huge, hi = -Vector3.one * math.huge }
			groups[key] = g
		end
		table.insert(g.parts, p)
		ofPart[p] = g
		table.insert(list, p)
		local r = math.max(p.Size.X, p.Size.Y, p.Size.Z) / 2 -- shortcut: a sphere round each part, so a turned awning still fits its box; fine for roofs
		g.lo = g.lo:Min(p.Position - Vector3.one * r)
		g.hi = g.hi:Max(p.Position + Vector3.one * r)
	end
	local function scan()
		local hub = workspace:FindFirstChild("Hub")
		if not hub then return false end
		for _, d in hub:GetDescendants() do if d:GetAttribute("RoofFadeTarget") then add(d) end end
		return #list > 0
	end
	task.spawn(function() for _ = 1, 60 do if scan() then break end task.wait(1) end end)
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Include
	local caveFaded = {} -- [part] = true while faded (the cave branch keeps its snap fade: it is first person and the eye is inside the part)
	local decor, decorAt = {}, -10
	local last = 0
	RunService.RenderStepped:Connect(function(dt)
		local now = os.clock()
		local ch = plr.Character
		local h = ch and ch:FindFirstChild("HumanoidRootPart")
		local inCave = plr:GetAttribute("InCave") == true
		if now - last >= 0.1 then
			last = now
			for _, g in groups do g.want = false end
			if h and not inCave and #list > 0 then
				rp.FilterDescendantsInstances = list
				local cam = workspace.CurrentCamera.CFrame.Position
				for _, target in { h.Position + Vector3.new(0, 1.2, 0), h.Position + Vector3.new(0, 2.6, 0) } do -- chest and head
					local from = cam
					for _ = 1, 3 do -- step through up to three roofs along the line
						local dir = target - from
						if dir.Magnitude < 1 then break end
						local hit = workspace:Raycast(from, dir, rp)
						if not hit then break end
						local g = ofPart[hit.Instance]
						if g then g.want = true end
						from = hit.Position + dir.Unit * 0.3
					end
					for _, g in groups do -- hysteresis: a faded roof holds while the line still passes near its box
						if g.a > 0 and not g.want and segHitsBox(cam, target, g.lo - Vector3.one * HYST, g.hi + Vector3.one * HYST) then g.want = true end
					end
				end
			end
			-- caves: thin ropes and beams near the first-person eye, and glowing crystals at the lens (tour views full1122e)
			local want = {}
			if h and inCave then
				local cam = workspace.CurrentCamera.CFrame.Position
				local camera = workspace.CurrentCamera
				local near = workspace:GetPartBoundsInRadius(cam, 7)
				if now - decorAt > 5 then -- decor and zip ropes have CanQuery off (spatial queries never return them): a list of them, refreshed every 5 s
					decorAt, decor = now, {}
					local caves = workspace:FindFirstChild("Caves")
					for _, f in { caves and caves:FindFirstChild("Ziplines"), caves and caves:FindFirstChild("Decor") } do
						for _, p in f and f:GetChildren() or {} do if p:IsA("BasePart") then table.insert(decor, { p, math.max(p.Size.X, p.Size.Y, p.Size.Z) / 2 }) end end
					end
				end
				for _, d in decor do
					if d[1].Parent and (d[1].Position - cam).Magnitude < 7 + d[2] then table.insert(near, d[1]) end
				end
				for _, p in near do
					local s = p.Size
					if p.Transparency < 1 and not p:IsDescendantOf(ch) and not p:IsDescendantOf(camera) and not isWater(p) and (caveFaded[p] or p.LocalTransparencyModifier < 0.01) then
						local lp = p.CFrame:PointToObjectSpace(cam)
						local c = Vector3.new(math.clamp(lp.X, -s.X / 2, s.X / 2), math.clamp(lp.Y, -s.Y / 2, s.Y / 2), math.clamp(lp.Z, -s.Z / 2, s.Z / 2))
						local d = (lp - c).Magnitude -- its own nearest point, not its bounding box (a long diagonal rope's box is huge)
						local thin = math.min(s.X, s.Y, s.Z) <= 1.5 and math.max(s.X, s.Y, s.Z) >= 3
						if (thin or p.Name == "ZipFlag") and (d < 2.6 or (d < 7 and p.CFrame:PointToWorldSpace(c).Y > cam.Y + 1.2)) then want[p] = true -- a rope or beam close above the eye (Orchestrator 2026-11-23: a beam slices the Camp 1 view)
						elseif (p.Material == Enum.Material.Neon or p.Material == Enum.Material.Glass) and d < 2.2 and not (p.Parent and p.Parent.Name == "Deposit") then want[p] = true end -- a glowing crystal at the lens filled 65% of the view on the zipline
					end
				end
			end
			for p in caveFaded do
				if not want[p] then
					if p.Parent then p.LocalTransparencyModifier = 0 end
					caveFaded[p] = nil
				end
			end
			for p in want do
				if not caveFaded[p] then
					p.LocalTransparencyModifier = 0.92 -- in first person a ghost rope across the view still read as a beam
					caveFaded[p] = true
				end
			end
		end
		for _, g in groups do -- the smooth part: every frame each roof eases toward faded or solid
			local goal = g.want and FADE or 0
			if g.a ~= goal then
				local step = FADE * dt / TIME
				g.a = goal > g.a and math.min(goal, g.a + step) or math.max(goal, g.a - step)
				for _, p in g.parts do if p.Parent then p.LocalTransparencyModifier = g.a end end
			end
		end
	end)
end

return M
