-- PetVoxels (ReplicatedStorage.Shared.PetVoxels): the 13 voxel pets (2026-11-17, brief: vault Projects/Pixel-_/Briefs/
-- Egg Hatching v3 (2026-11-17).md; designs and build: design3d/pets/pets.py -> build_pets.py -> make_lua.py).
-- Each pet is a Model asset of MeshParts named "<Part>__<Role>". The server loads them once into ReplicatedStorage.PetMeshes
-- (InsertService only runs on the server); the client clones one per pet, paints each MeshPart from the palette (Accent and
-- Ring glow as Neon) and moves the parts every frame about their joints (Shared.PetVoxelsData pivots), so the pets live:
--   * idle: the body breathes, the head nods and looks about, the tail sways, wings tuck and open, rings orbit
--   * moving: the legs swing in pairs, the body bobs on each step, the head and tail lag behind (follow-through, research
--     note Craft Videos for Weak Grades: ears, tails and wings settle after the body stops)
--   * a blink every 3 to 5 s (the Eye and Shine parts flatten for 0.12 s)
-- The model faces -Z like the old cube pets, its pivot (the invisible Root) sits 0.92 studs above the feet as before, so the
-- follow code, PetCompanion and the hatch show keep working. Display only.
local RS = game:GetService("ReplicatedStorage")
local DATA = require(script.Parent:WaitForChild("PetVoxelsData"))
local M = {}
M.DATA = DATA
local GLOW = {} -- Neon bloomed whole manes and rings into white blobs in the game's lighting (capture pets_lineup2); the accent glows through its PointLight instead
local FLIP = CFrame.Angles(0, math.pi, 0) -- the meshes look +Z; the game's pets look -Z
local ROOT_Y = 0.92

-- server: load every pet's meshes into ReplicatedStorage.PetMeshes (once, in the background)
function M.serverLoad()
	local folder = RS:FindFirstChild("PetMeshes") or Instance.new("Folder")
	folder.Name, folder.Parent = "PetMeshes", RS
	local IS = game:GetService("InsertService")
	for name, d in DATA do
		if not folder:FindFirstChild(name) then
			local ok, got = pcall(function() return IS:LoadAsset(d.id) end)
			if ok and got then
				local m = got:FindFirstChildWhichIsA("Model") or got
				m.Name = name
				for _, p in m:GetDescendants() do
					if p:IsA("BasePart") then p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false end
				end
				m.Parent = folder
				if got ~= m then got:Destroy() end
			else
				warn("PetVoxels: could not load", name, got)
			end
		end
	end
end

-- client: a fresh, painted model for this pet, or nil while its meshes have not arrived
function M.build(name)
	local d = DATA[name]
	local folder = RS:FindFirstChild("PetMeshes")
	local src = d and folder and folder:FindFirstChild(name)
	if not src then return nil end
	local parts = {}
	local lo, hi = Vector3.new(math.huge, math.huge, math.huge), Vector3.new(-math.huge, -math.huge, -math.huge)
	for _, p in src:GetDescendants() do
		if p:IsA("BasePart") then
			table.insert(parts, p)
			local h = p.Size / 2
			lo, hi = lo:Min(p.Position - h), hi:Max(p.Position + h)
		end
	end
	if #parts == 0 then return nil end
	local origin = CFrame.new((lo.X + hi.X) / 2, lo.Y, (lo.Z + hi.Z) / 2) -- the feet, centred (as the voxels were)
	local m = Instance.new("Model")
	m.Name = name
	local root = Instance.new("Part")
	root.Name, root.Size, root.Transparency = "Root", Vector3.new(0.2, 0.2, 0.2), 1
	root.Anchored, root.CanCollide, root.CanQuery, root.CanTouch = true, false, false, false
	root.CFrame = CFrame.new(0, ROOT_Y, 0)
	root.Parent = m
	m.PrimaryPart = root
	local rig = { pieces = {}, seed = math.random() * 10, w = 0, lastPos = nil, scale0 = 1 }
	for _, p in parts do
		local c = p:Clone()
		local part, role = string.match(p.Name, "^(.-)__(.+)$")
		part, role = part or "Body", role or "Main"
		c.Name = part == "Head" and role == "Main" and "Head" or (part .. "_" .. role) -- PetCompanion looks for "Head"
		c.Color = d.palette[role] or Color3.new(1, 1, 1)
		c.Material = GLOW[role] and Enum.Material.Neon or Enum.Material.SmoothPlastic
		c.Anchored, c.CanCollide, c.CanQuery, c.CanTouch, c.CastShadow = true, false, false, false, false
		local rest = FLIP * origin:ToObjectSpace(p.CFrame) -- in the pet's own frame: feet at 0, looking -Z
		local piv = d.pivots[part]
		piv = piv and (FLIP * CFrame.new(piv)).Position or Vector3.zero
		table.insert(rig.pieces, { p = c, part = part, role = role, rest = rest, piv = piv, size = c.Size })
		c.CFrame = CFrame.new(0, 0, 0) * rest
		c.Parent = m
	end
	for _, g in rig.pieces do
		if g.role == "Accent" and g.part == "Body" and not rig.light then -- the signature glow lights the pet's feet a little
			local l = Instance.new("PointLight")
			l.Color, l.Range, l.Brightness = d.palette.Accent, 4, 0.35 -- soft: brighter lights washed out faces and white coats (Gemini n17_hatch)
			l.Parent = g.p
			rig.light = l
		end
	end
	m:SetAttribute("Voxel", true)
	M.rigs[m] = rig
	m.WorldPivot = root.CFrame
	return m
end
M.rigs = setmetatable({}, { __mode = "k" })

-- every frame, after the model was pivoted: pose the parts. now: os.clock(); moving: overrides the speed guess
function M.animate(m, now, dt, moving)
	local rig = M.rigs[m]
	if not rig or not m.PrimaryPart then return end
	dt = math.min(dt or 1 / 60, 1 / 20)
	local root = m.PrimaryPart.CFrame
	local pos = root.Position
	if moving == nil then
		local v = rig.lastPos and (pos - rig.lastPos).Magnitude / math.max(dt, 1e-3) or 0
		moving = v > 2.5
	end
	rig.lastPos = pos
	rig.w += ((moving and 1 or 0) - rig.w) * math.min(1, dt * 6) -- 0 standing .. 1 walking, eased (the lag is the follow-through)
	local w, t, s = rig.w, now + rig.seed, m:GetScale()
	local base = root * CFrame.new(0, -ROOT_Y * s, 0) -- the feet
	local step = math.sin(t * 11)
	local breathe = math.sin(t * 2.2)
	local bodyLift = (math.abs(step) * 0.06 * w + breathe * 0.012 * (1 - w)) -- studs
	local blink = (t % (3 + rig.seed % 2)) < 0.12
	for _, g in rig.pieces do
		local rot = CFrame.identity
		local lift = bodyLift
		local name = g.part
		if name == "Head" then
			rot = CFrame.Angles(math.sin(t * 1.3) * 0.06 * (1 - w) - step * 0.05 * w, math.sin(t * 0.7) * 0.25 * (1 - w), math.sin(t * 0.9) * 0.05)
		elseif string.sub(name, 1, 3) == "Leg" then
			local n = tonumber(string.sub(name, 4)) or 1
			local phase = (n % 2 == (n > 2 and 1 or 0)) and 1 or -1 -- diagonal pairs swing together
			rot = CFrame.Angles(step * 0.55 * w * phase, 0, 0)
			lift = 0
		elseif string.sub(name, 1, 3) == "Arm" then
			rot = CFrame.Angles(-step * 0.5 * w + breathe * 0.05, 0, 0)
		elseif name == "Tail" then
			rot = CFrame.Angles(0.1 * w, math.sin(t * (3 + 5 * w)) * (0.35 + 0.2 * w), 0)
		elseif string.sub(name, 1, 4) == "Wing" or string.sub(name, 1, 3) == "Fin" then
			local side = string.sub(name, -1) == "L" and -1 or 1
			rot = CFrame.Angles(0, 0, side * (math.sin(t * (4 + 10 * w)) * (0.18 + 0.3 * w)))
		elseif string.sub(name, 1, 4) == "Ring" then -- the nine rings orbit and bob about the spirit
			local n = tonumber(string.sub(name, 5)) or 1
			local a = t * 0.8
			local off = Vector3.new(g.piv.X, 0, g.piv.Z)
			local turned = CFrame.Angles(0, a, 0) * off
			g.p.CFrame = base * CFrame.new(turned.X * s, (g.piv.Y + math.sin(t * 2 + n) * 0.12 + bodyLift) * s, turned.Z * s) * CFrame.Angles(0, a + n, 0) * (CFrame.new(-g.piv) * g.rest).Rotation
			continue
		end
		local pv = g.piv * s
		local cf = base * CFrame.new(0, lift * s, 0) * CFrame.new(pv) * rot * CFrame.new(-pv) * (g.rest.Rotation + g.rest.Position * s)
		if g.role == "Eye" or g.role == "Shine" then
			local want = blink and Vector3.new(g.size.X, g.size.Y * 0.15, g.size.Z) or g.size
			if g.p.Size ~= want * s then g.p.Size = want * s end
		end
		g.p.CFrame = cf
	end
end

return M
