-- Travel (ServerScriptService.Travel): quick ways to move in the caves (Next Systems Plan, phase B, 2026-11-13).
--   * the hearthstone (wheel slot HOME, Shared.Hearth): stand still for C.HOME.hold seconds and the server moves you to the
--     nearest camp landing with nothing lost. Refused outside the caves, on a ride, in a minigame or a boss fight and while a
--     Gloomling holds you. The server keeps the clock of the hold and the cooldown (C.HOME.cool, saved with the other cooldowns).
--   * root ziplines in Camp 1's caves: two across the chasm (one each way, each sloping down) and one across the grotto lake
--     (both ways). The server builds them from the bridge posts and the lake, checks the rider stands at the handle, and puts a
--     rider who did not arrive at the far end. Shared.ClayClient carries the rider (Fx "zip", the rope, reversed).
-- Nothing here pays or takes anything.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local C = require(RS:WaitForChild("Shared"):WaitForChild("Config"))
local M = {}

local BARK, ROPE, MINT = Color3.fromRGB(86, 60, 44), Color3.fromRGB(150, 128, 92), Color3.fromRGB(120, 255, 200)

function M.init(ctx)
	local caves = workspace:FindFirstChild("Caves")
	if not caves then return end
	local folder = Instance.new("Folder")
	folder.Name = "Ziplines"
	folder.Parent = caves

	local function refuse(plr) -- why this player may not travel now (nil = may)
		local s = ctx.data[plr]
		if not s or not ctx.hrpOf(plr) then return "Not now" end
		if not plr:GetAttribute("InCave") then return "Caves only" end
		if plr:GetAttribute("GrabbedUntil") then return "Grabbed!" end
		if ctx.busy(plr) or s.mg or s.boss then return "Not now" end
		return nil
	end

	-- ---------------------------------------------------------------- ziplines
	local function part(name, size, cf, color, props)
		local p = Instance.new("Part")
		p.Name, p.Size, p.CFrame, p.Color, p.Anchored = name, size, cf, color, true
		p.Material, p.TopSurface, p.BottomSurface = Enum.Material.Wood, Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		for k, v in props or {} do p[k] = v end
		p.Parent = folder
		return p
	end
	local DECO = { CanCollide = false, CanQuery = false, CastShadow = false }
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	local function ground(p) -- the floor under a point (nil: no floor, the line is not built)
		local r = workspace:Raycast(p + Vector3.new(0, 14, 0), Vector3.new(0, -40, 0), rp)
		return r and r.Position
	end
	local zipN = 0
	local zips = {} -- [prompt] = { rope, rev, goal, secs }
	local function line(a0, b0, ha, hb, twoWay) -- floor points and the rope's height over each
		local fa, fb = ground(a0), ground(b0)
		if not fa or not fb then return end
		local a, b = fa + Vector3.new(0, ha, 0), fb + Vector3.new(0, hb, 0)
		local len = (b - a).Magnitude
		for _, e in { { fa, ha }, { fb, hb } } do -- a root post at each end with a glowing knot on top
			part("ZipPost", Vector3.new(0.9, e[2] + 0.9, 0.9), CFrame.new(e[1] + Vector3.new(0, (e[2] + 0.9) / 2 - 0.3, 0)), BARK)
			local knot = part("ZipKnot", Vector3.new(0.7, 0.7, 0.7), CFrame.new(e[1] + Vector3.new(0, e[2] + 0.75, 0)), MINT, { Material = Enum.Material.Neon, Shape = Enum.PartType.Ball, CanCollide = false, CastShadow = false })
			local l = Instance.new("PointLight")
			l.Color, l.Range, l.Brightness = MINT, 14, 0.9
			l.Parent = knot
		end
		local rope = part("ZipRope", Vector3.new(0.24, 0.24, len), CFrame.lookAt((a + b) / 2, b), ROPE, DECO)
		rope:SetAttribute("ZipA", a)
		rope:SetAttribute("ZipB", b)
		for k = 1, 3 do part("ZipFlag", Vector3.new(0.1, 0.8, 0.6), CFrame.lookAt(a + (b - a) * k / 4 - Vector3.new(0, 0.55, 0), b), k % 2 == 0 and MINT or ROPE, DECO) end
		local dir = (b - a).Unit
		for _, rev in twoWay and { false, true } or { false } do
			local from, to, d = rev and b or a, rev and a or b, rev and -dir or dir
			local handle = part("ZipHandle", Vector3.new(1.5, 0.3, 0.3), CFrame.lookAt(from + d * 1.6 - Vector3.new(0, 0.9, 0), from + d * 3 - Vector3.new(0, 0.9, 0)) * CFrame.Angles(0, math.pi / 2, 0), MINT, { CanCollide = false })
			local pr = Instance.new("ProximityPrompt")
			pr.ActionText, pr.ObjectText, pr.KeyboardKeyCode, pr.GamepadKeyCode = "Ride", "Root zipline", Enum.KeyCode.F, Enum.KeyCode.ButtonX
			pr.MaxActivationDistance, pr.RequiresLineOfSight, pr.Style, pr.HoldDuration = 10, false, Enum.ProximityPromptStyle.Custom, 0
			zipN += 1
			pr:SetAttribute("Zip", zipN) -- 1 and 2: the chasm lines, 3 and 4: the grotto line each way
			rope:SetAttribute("Rope", rope:GetAttribute("Rope") or zipN)
			-- a prompt only shows while its point is on screen: the grip hangs from the handle to eye height on a root strand
			local drop = (rev and hb or ha) - 0.9 - 4.2
			part("ZipStrand", Vector3.new(0.18, drop, 0.18), CFrame.new(handle.Position - Vector3.new(0, drop / 2, 0)), BARK, DECO)
			local grip = part("ZipGrip", Vector3.new(0.9, 0.9, 0.9), CFrame.new(handle.Position - Vector3.new(0, drop, 0)), MINT, { Material = Enum.Material.Neon, Shape = Enum.PartType.Ball, CanCollide = false, CastShadow = false })
			pr.Parent = grip
			zips[pr] = { rope = rope, rev = rev, goal = (rev and fa or fb) + Vector3.new(0, 3, 0) - d * 2, secs = len / 30 }
			pr.Triggered:Connect(function(plr)
				local s, z = ctx.data[plr], zips[pr]
				if refuse(plr) or not ctx.nearPrompt(plr, pr) or os.clock() < (s.zipCool or 0) then return end
				s.zipCool = os.clock() + z.secs + 1
				ctx.fx:FireClient(plr, "zip", z.rope, z.rev)
				task.delay(z.secs + 0.6, function() -- a rider who is not at the far end by now is put there (nothing owns them: not grabbed, no minigame)
					local hrp = ctx.hrpOf(plr)
					if hrp and ctx.data[plr] == s and not refuse(plr) and (hrp.Position - z.goal).Magnitude > 14 then
						hrp.AssemblyLinearVelocity = Vector3.zero
						hrp.CFrame = CFrame.new(z.goal)
					end
				end)
			end)
		end
	end
	local posts, water = {}, nil
	for _, d in caves:GetDescendants() do
		if d.Name == "BridgePost" then table.insert(posts, d.Position) end
		if d.Name == "Water" and d.Parent.Name == "Grotto" then water = d end
	end
	rp.FilterDescendantsInstances = water and { water, folder } or { folder }
	if #posts == 4 then -- the chasm: the two bridge ends, a line on each side of the bridge, each sloping down the way it runs
		table.sort(posts, function(p, q) return (p - posts[1]).Magnitude < (q - posts[1]).Magnitude end) -- 1 and 2 are one end
		local a, b = (posts[1] + posts[2]) / 2, (posts[3] + posts[4]) / 2
		local ax = (b - a).Unit
		local side = ax:Cross(Vector3.yAxis)
		line(a - ax * 8 + side * 12, b + ax * 8 + side * 12, 9, 6)
		line(b + ax * 8 - side * 12, a - ax * 8 - side * 12, 10, 6)
	end
	if water then -- the grotto: over the lake from the entrance shore to the far shore, both ways
		line((water.CFrame * CFrame.new(-60, 0, 0)).Position, (water.CFrame * CFrame.new(54, 0, 0)).Position, 8, 8, true)
	end

	-- ---------------------------------------------------------------- hearthstone
	local R = ctx.remote("Travel")
	local chan = {} -- [plr] = { t, p }: a hold that has started
	Players.PlayerRemoving:Connect(function(plr) chan[plr] = nil end)
	R.OnServerEvent:Connect(function(plr, what)
		local s, hrp = ctx.data[plr], ctx.hrpOf(plr)
		if not s or not hrp then return end
		if what == "home" then
			local c = chan[plr]
			if c and os.clock() - c.t < 0.5 then return end -- a fast repeat
			local why, left = refuse(plr), ctx.coolLeft(s, "home")
			if why or left > 0 then
				chan[plr] = nil
				ctx.fx:FireClient(plr, "home", "no", why or left)
				return
			end
			chan[plr] = { t = os.clock(), p = hrp.Position }
			ctx.fx:FireClient(plr, "home", "go", C.HOME.hold)
		elseif what == "homeStop" then
			chan[plr] = nil
		elseif what == "homeEnd" then
			local c = chan[plr]
			chan[plr] = nil
			if not c then return end
			local dt, why = os.clock() - c.t, refuse(plr)
			if dt < C.HOME.hold - 0.15 or dt > C.HOME.hold + 3 or (hrp.Position - c.p).Magnitude > C.HOME.still then why = why or "Stand still" end
			if why then
				ctx.fx:FireClient(plr, "home", "no", why)
				return
			end
			local best
			for _, l in ctx.landings() do
				if not best or (l.Position - hrp.Position).Magnitude < (best.Position - hrp.Position).Magnitude then best = l end
			end
			if not best then return end
			ctx.coolSet(s, "home", C.HOME.cool)
			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.CFrame = best.CFrame + Vector3.new(0, 3, 0)
			ctx.fx:FireClient(plr, "home", "done", C.HOME.cool)
			if ctx.analytics then ctx.analytics.event(s, "Hearthstone") end
		end
	end)
end

return M
