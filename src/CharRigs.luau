-- CharRigs (ReplicatedStorage.Shared.CharRigs), started by PixelClient (2026-11-28): the v17 voxel NPC characters
-- (design3d/chars/npcs_vox.py; uploads and rig data in Shared.CharRigData; ServerScriptService.CharRigLoader loads the meshes into
-- ReplicatedStorage.CharMeshes) stand in for the old part-built placeholders. A placeholder stays where it is, so its
-- ProximityPrompts, speech anchors (WickHead, SmudgeHead, MossHead, KeeperHead, Body) and boss hooks (WardenEye, Knot1..3,
-- Cracks, openDoor) keep working; it only hides for this player (LocalTransparencyModifier). The voxel rig stands on its feet,
-- scaled to its height, facing where its eyes looked, follows it when it moves (a boss's slam and slump), lives through
-- Shared.PetVoxels' rig motion (breathing, weight shifts, a look round), turns its head to a player close by, and plays acts on
-- the boss events (BossClient calls M.act). GloomClient builds the Gloomling and Clayling through M.make / M.animate / M.play.
local M = {}
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local PV = require(script.Parent:WaitForChild("PetVoxels"))
local CHAR = PV.CHAR or {}
local ROOT_Y = 0.92 -- PetVoxels: a rig's pivot sits this far above its feet at scale 1

local MODELS = { Bolt = "Bolt", Maribel = "Maribel", Pip = "Pip", Juniper = "Juniper", Tock = "Tock", Warden = "RootWarden", KilnGolem = "KilnGolem" }
local NAMED = { MossLegs = "Moss", MossBody = "Moss", MossScarf = "Moss", MossHead = "Moss", MossHelmet = "Moss", MossLamp = "Moss", MossEye = "Moss", MossSatchel = "Moss",
	Keeper = "KilnKeeper", KeeperApron = "KilnKeeper", KeeperEye = "KilnKeeper", KeeperHat = "KilnKeeper", KeeperHead = "KilnKeeper", KeeperPaw = "KilnKeeper", KeeperSnout = "KilnKeeper" }
local KEEP = { Quest = true, Knot1 = true, Knot2 = true, Knot3 = true, Cracks = true } -- parts of a placeholder model that stay visible
local BOSS = { RootWarden = true, KilnGolem = true }
local SIZE = { RootWarden = 1.15, KilnGolem = 1.1 } -- the bosses stand a little taller than their old block bodies
M.BOSSNAME = { "RootWarden", "KilnGolem" } -- BossClient's boss numbers

local groups = {} -- placeholder key (its Model, or the folder holding a camp NPC's loose parts) -> one mount
local vis

local function charOf(p) -- the character a placeholder part belongs to, and the key of its placeholder
	if not p:IsA("BasePart") then return nil end
	local caves = p:FindFirstAncestor("Caves")
	local a = p.Parent
	while a and a ~= workspace do
		if KEEP[a.Name] then return nil end
		if a:IsA("Model") and MODELS[a.Name] and (caves or a:FindFirstAncestor("Hub")) then return MODELS[a.Name], a end
		a = a.Parent
	end
	if not caves then return nil end
	local n = p.Name
	if NAMED[n] then return NAMED[n], p.Parent end
	if string.sub(n, 1, 4) == "Wick" then return "Wick", p.Parent end
	if string.sub(n, 1, 6) == "Smudge" then return "Smudge", p.Parent end
	return nil
end

local function add(p)
	local char, key = charOf(p)
	if not char or not CHAR[char] then return end
	local k = tostring(char) .. "|" .. key:GetFullName()
	local g = groups[k]
	if not g then
		g = { char = char, key = key, parts = {} }
		groups[k] = g
	end
	g.parts[p] = true
	g.t, g.dirty = os.clock(), true
end

local function hide(g, on)
	for p in g.parts do
		if p.Parent then
			p.LocalTransparencyModifier = on and 1 or 0
			for _, d in p:GetChildren() do
				if d:IsA("Decal") then d.LocalTransparencyModifier = on and 1 or 0 elseif d:IsA("SurfaceGui") then d.Enabled = not on end
			end
		end
	end
end

local function headSet(r) -- the bones that turn with the head (the head, its jaw, lid and ears)
	local set = {}
	for part in r.par do
		local a = part
		while a do
			if a == "Head" then set[part] = true break end
			a = r.par[a]
		end
	end
	return set
end

local function mount(g)
	g.dirty = false
	local lo, hi = Vector3.new(math.huge, math.huge, math.huge), Vector3.new(-math.huge, -math.huge, -math.huge)
	local eyes, ne, anchor, big = Vector3.zero, 0, nil, -1
	for p in g.parts do
		if p.Parent and p:IsDescendantOf(workspace) then
			local h = p.Size / 2
			lo, hi = lo:Min(p.Position - h), hi:Max(p.Position + h)
			if string.find(p.Name, "Eye") then eyes += p.Position ne += 1 end
			local v = p.Size.X * p.Size.Y * p.Size.Z
			if v > big then anchor, big = p, v end
		else
			g.parts[p] = nil
		end
	end
	if g.rig then g.rig:Destroy() g.rig = nil end
	if not anchor then return end
	local c = (lo + hi) / 2
	local front = ne > 0 and (eyes / ne - c) * Vector3.new(1, 0, 1) or Vector3.zero
	if front.Magnitude < 0.05 then front = anchor.CFrame.LookVector * Vector3.new(1, 0, 1) end
	local feet = Vector3.new(c.X, lo.Y, c.Z)
	local ground = CFrame.lookAt(feet, feet + front.Unit)
	local rig = PV.build(g.char)
	if not rig then g.dirty = true return end -- the meshes have not arrived yet: try again
	local d = CHAR[g.char]
	local s = math.clamp((hi.Y - lo.Y) / d.height * (SIZE[g.char] or 1), 0.3, 3)
	rig:ScaleTo(s)
	vis = vis or workspace:FindFirstChild("CharRigsVis") or Instance.new("Folder")
	vis.Name, vis.Parent = "CharRigsVis", workspace
	rig:PivotTo(ground * CFrame.new(0, ROOT_Y * s, 0)) -- on its spot at once: a far rig is not moved each frame, and the town sits at the origin
	do -- a soft fill light in front of the chest: the slate Warden read as a black shape in the dark cave (still 2026-11-28)
		local h = d.height * s
		local at = Instance.new("Attachment")
		at.Name, at.Position = "CharFill", Vector3.new(0, h * 0.5 - ROOT_Y * s, -math.max(2, h * 0.45))
		local l = Instance.new("PointLight")
		l.Color, l.Range, l.Brightness, l.Shadows = Color3.fromRGB(255, 236, 214), math.max(8, h * 1.4), BOSS[g.char] and 1.1 or 0.45, false
		l.Parent = at
		at.Parent = rig.PrimaryPart
	end
	rig.Parent = vis
	g.rig, g.s, g.anchor, g.rel, g.yaw = rig, s, anchor, anchor.CFrame:ToObjectSpace(ground), 0
	local r = PV.rigs[rig]
	g.head = r and r.par and headSet(r) or {}
	hide(g, true)
end

local function turnHead(g, r, dt) -- the head turns to a player close by (bosses: only in a fight), then back
	local hrp = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	local root = g.rig.PrimaryPart.CFrame
	local want = 0
	local reach = (BOSS[g.char] and 46 or 20) * math.max(g.s, 0.6)
	if hrp and (not BOSS[g.char] or Players.LocalPlayer:GetAttribute("BossFight")) then
		local rel = root:PointToObjectSpace(hrp.Position)
		if rel.Magnitude < reach then want = math.clamp(math.atan2(-rel.X, -rel.Z), -0.9, 0.9) end
	end
	g.yaw += (want - g.yaw) * math.min(1, dt * 3)
	if math.abs(g.yaw) < 0.003 or not r.piv.Head then return end
	local P = (root * CFrame.new(0, -ROOT_Y * g.s, 0) * CFrame.new(r.piv.Head * g.s)).Position
	local turn = CFrame.new(P) * CFrame.Angles(0, g.yaw, 0) * CFrame.new(-P)
	for _, pc in r.pieces do
		if g.head[pc.part] then pc.p.CFrame = turn * pc.p.CFrame end
	end
end

function M.start()
	if M.started then return end
	M.started = true
	workspace.DescendantAdded:Connect(add)
	task.spawn(function() -- the placeholders already there
		for _, d in workspace:GetDescendants() do add(d) end
	end)
	task.spawn(function() -- mount a placeholder once its parts stop arriving; hide it again in case a fade showed it
		while true do
			task.wait(0.5)
			local now = os.clock()
			for k, g in groups do
				if g.anchor and not g.anchor:IsDescendantOf(workspace) then -- its placeholder is gone (a cave rebuilt): mount again
					g.dirty, g.anchor = true, nil
				end
				if g.dirty and now - g.t > 0.8 then mount(g) end
				if g.rig then hide(g, true) end
				if not next(g.parts) then
					if g.rig then g.rig:Destroy() end
					groups[k] = nil
				end
			end
		end
	end)
	RunService.RenderStepped:Connect(function(dt)
		local now = os.clock()
		local cam = workspace.CurrentCamera.CFrame.Position
		local fight = Players.LocalPlayer:GetAttribute("BossFight")
		for _, g in groups do
			local rig = g.rig
			if rig and g.anchor and g.anchor.Parent then
				local ground = g.anchor.CFrame * g.rel
				if (ground.Position - cam).Magnitude < 170 then
					rig:PivotTo(ground * CFrame.new(0, ROOT_Y * g.s, 0))
					local r = PV.rigs[rig]
					if r and BOSS[g.char] and not fight and not r.act then r.nextAct = now + 4 end -- an asleep boss only breathes
					PV.animate(rig, now, dt, false)
					if r then turnHead(g, r, dt) end
					if BOSS[g.char] then -- the boss's knots (Perfect Strike targets) sit in the rig's sockets
						local feet = rig.PrimaryPart.CFrame * CFrame.new(0, -ROOT_Y * g.s, 0)
						local an = CHAR[g.char].anchors or {}
						for k = 1, 3 do
							local kn, a = g.key:FindFirstChild("Knot" .. k), an["Knot" .. k]
							if kn and a and kn:IsA("Model") then
								local at = feet * Vector3.new(-a[2].X * g.s, a[2].Y * g.s, -a[2].Z * g.s) -- PetVoxels' FLIP: the meshes look +Z, the rigs -Z
								kn:PivotTo(CFrame.new(at) * kn:GetPivot().Rotation)
							end
						end
					end
				end
			end
		end
	end)
end

-- a boss event (BossClient): its rig plays one of the PetVoxels acts (roar, rear, armflex, stomp, shake, look)
function M.act(char, act)
	for _, g in groups do
		if g.char == char and g.rig then M.play(g.rig, act) end
	end
end
function M.play(m, act)
	local r = m and PV.rigs[m]
	if r and act then r.act, r.actT, r.burst, r.hit = act, os.clock(), false, false end
end

-- a free-standing rig (GloomClient's Gloomling and Clayling): height in studs; nil while the meshes are loading
function M.make(char, height)
	local d = CHAR[char]
	local rig = d and PV.build(char)
	if rig then rig:ScaleTo(math.clamp(height / d.height, 0.2, 3)) end
	return rig
end
function M.animate(m, now, dt, moving) PV.animate(m, now, dt, moving) end
M.ROOT_Y = ROOT_Y

return M
