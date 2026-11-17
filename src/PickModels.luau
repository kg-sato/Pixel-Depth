-- PickModels (ReplicatedStorage.Shared.PickModels): the hybrid pickaxes (2026-11-17; the owner: the old ones were "just a stick",
-- the voxel remake lost the high-quality effects; "a medium between the 2 art styles"). Built by design3d/picks/pick_hybrid.py
-- after The Forge's pickaxes (art/refs_picks): a thick wrapped handle with metal rings, a socket block, deep curved bevelled
-- blades or a hammer, and our magical dressing (a raised tier mark, glowing inlays, gems, crystal shards, wings).
-- serverLoad() loads every tier's model (InsertService, server only), paints each MeshPart from its role, gives the glow
-- roles Neon and the gems Glass, adds a soft light on the gem from Rare up and drifting sparkles from Epic up, then puts the
-- model in ServerStorage.Pickaxes (the held pickaxe) and ReplicatedStorage.PickaxeArt (forge cards, cutscenes), replacing the
-- old model of that name. Called once at server start before anyone is given a pickaxe.
local RS = game:GetService("ReplicatedStorage")
local DATA = require(script.Parent:WaitForChild("PickModelsData"))
local M = {}
local SPARK = "rbxasset://textures/particles/sparkles_main.dds"

function M.serverLoad(C)
	local SS = game:GetService("ServerStorage")
	local IS = game:GetService("InsertService")
	local lib = SS:FindFirstChild("Pickaxes") or Instance.new("Folder")
	lib.Name, lib.Parent = "Pickaxes", SS
	local art = RS:FindFirstChild("PickaxeArt")
	local rarityOf = {}
	for i, d in C.PICKS do if d.model then rarityOf[d.model] = C.PICK_RARITY and C.PICK_RARITY[i] or 1 end end
	local n = 0
	local loaded, pending = {}, 0
	for name, d in DATA do -- all the loads at once: one after another held the loading screen about 20 s
		pending += 1
		task.spawn(function()
			local ok, got = pcall(function() return IS:LoadAsset(d.id) end)
			loaded[name] = { ok, got }
			pending -= 1
		end)
	end
	local t0 = os.clock()
	while pending > 0 and os.clock() - t0 < 30 do task.wait(0.05) end
	for name, d in DATA do
		local ok, got = table.unpack(loaded[name] or { false, "timed out" })
		if ok and got then
			local m = got:FindFirstChildWhichIsA("Model") or got
			m.Name = name
			local gem, head
			for _, p in m:GetDescendants() do
				if p:IsA("BasePart") then
					local part, role = string.match(p.Name, "^(.-)__(.+)$")
					role = role or "Head"
					if role == "Tex" then -- round 2: one baked texture (colour, occlusion, edge light) on all the solid parts; keep it
						p.Material = Enum.Material.SmoothPlastic
						head = head or p
					else
						p.Color = d.palette[role] or p.Color
						if role == "Accent" then p.Color = p.Color:Lerp(Color3.new(0, 0, 0), 0.3) end -- darker neon: full-bright marks bloomed into white blobs (Gemini r2)
						p.Material = (role == "Accent") and Enum.Material.Neon or ((role == "Gem" or role == "Crystal") and Enum.Material.Glass or (role == "Band" and Enum.Material.Metal or Enum.Material.SmoothPlastic))
					end
					if role == "Gem" then p.Transparency = 0.12 gem = gem or p end
					if role == "Crystal" then p.Transparency = 0.22 end
					if part == "Head" and role == "Head" then head = p end
					p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
				end
			end
			local r = rarityOf[name] or 1
			if gem and r >= 2 then
				local l = Instance.new("PointLight")
				l.Color, l.Range, l.Brightness = d.palette.Gem, 5, 0.6
				l.Parent = gem
			end
			if head and r >= 3 then -- sparkles drifting off the head (the high-quality effects the owner missed on the voxel set)
				local e = Instance.new("ParticleEmitter")
				e.Texture, e.Rate, e.LightEmission, e.LightInfluence = SPARK, 4 + r * 2, 1, 0
				e.Color = ColorSequence.new(d.palette.Accent, Color3.new(1, 1, 1))
				e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.4, 0.22), NumberSequenceKeypoint.new(1, 0) })
				e.Transparency, e.Lifetime, e.Speed, e.SpreadAngle = NumberSequence.new(0.1, 1), NumberRange.new(0.6, 1.2), NumberRange.new(0.3, 1), Vector2.new(180, 180)
				e.Parent = head
			end
			if head and r >= 2 then -- a trail off the blade tip in the tier colour: it streaks through every swing
				local cf, size = m:GetBoundingBox()
				local tip = head.CFrame:PointToObjectSpace(cf.Position + cf.RightVector * size.X * 0.45 + cf.UpVector * size.Y * 0.38)
				local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
				a0.Position, a1.Position = tip, tip + head.CFrame:VectorToObjectSpace(-cf.RightVector * 0.5)
				a0.Parent, a1.Parent = head, head
				local tr = Instance.new("Trail")
				tr.Attachment0, tr.Attachment1, tr.Lifetime, tr.LightEmission = a0, a1, 0.22, 0.8
				tr.Color = ColorSequence.new(d.palette.Accent, Color3.new(1, 1, 1))
				tr.Transparency = NumberSequence.new(0.35, 1)
				tr.MinLength = 0.15
				tr.Parent = head
			end
			m.PrimaryPart = m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart", true)
			local old = lib:FindFirstChild(name)
			if old then old:Destroy() end
			m.Parent = lib
			if art then
				local o2 = art:FindFirstChild(name)
				if o2 then o2:Destroy() end
				m:Clone().Parent = art
			end
			if got ~= m then got:Destroy() end
			n += 1
		else
			warn("PickModels: could not load", name, got)
		end
	end
	return n
end

return M
