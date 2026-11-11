-- PetCompanion (ReplicatedStorage.Shared.PetCompanion), started by PixelClient (the user's overnight directive, 2026-11-10: the
-- crew pets had perks but walked behind you, so in the first-person caves you never saw them). In a cave the lead pet now
-- bounds along at the left edge of the view with a small miner's lantern on a collar, and it is a living radar:
--   * a rare deposit within 30 studs: it turns to it, hops and chirps (once per deposit)
--   * a Gloomling within 25 studs: its lantern flickers red and it cowers low beside the pickaxe
-- PixelClient's crew loop asks E.vmHook.petPose(i, pet, hrp, now, dt) for every pet; nil keeps the old follow-behind place.
local M = {}

function M.start(E)
	local plr, hook, sfx = E.plr, E.vmHook, E.sfx
	local WARM, RED = Color3.fromRGB(255, 196, 120), Color3.fromRGB(255, 84, 104)
	local dressed = setmetatable({}, { __mode = "k" }) -- pet model -> { bead, light }
	local chirped = setmetatable({}, { __mode = "k" }) -- deposits the pet has already pointed out
	local nextScan, rare, gloomNear, hopAt = 0, nil, false, -10

	local function dress(model) -- the collar lantern: a dark band under the head and a small glowing bead
		local root = model.PrimaryPart
		local function cube(size, off, color, neon)
			local p = Instance.new("Part")
			p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
			p.Size, p.Color, p.Material = size, color, neon and Enum.Material.Neon or Enum.Material.SmoothPlastic
			p.CFrame = root.CFrame * CFrame.new(off)
			p.Name = "Collar"
			p.Parent = model
			return p
		end
		cube(Vector3.new(1.56, 0.16, 1.36), Vector3.new(0, 0.5, -0.05), Color3.fromRGB(58, 46, 70))
		cube(Vector3.new(0.3, 0.36, 0.3), Vector3.new(0, 0.3, -0.8), Color3.fromRGB(70, 60, 66))
		local bead = cube(Vector3.new(0.3, 0.34, 0.3), Vector3.new(0, 0.3, -1.03), WARM, true)
		local light = Instance.new("PointLight")
		light.Range, light.Brightness, light.Color, light.Shadows = 11, 0.6, WARM, false
		light.Parent = bead
		for _, d in model:GetDescendants() do -- the pet's own back glow is 1.2: this close to the camera it burned out
			if d:IsA("PointLight") and d ~= light then d.Brightness = 0.25 end
			if d:IsA("BasePart") and d.Material == Enum.Material.Neon and d ~= bead then d.Color = d.Color:Lerp(Color3.new(0, 0, 0), 0.45) end -- so did its neon back
		end
		dressed[model] = { bead = bead, light = light }
		return dressed[model]
	end

	hook.petPose = function(i, pet, h, now, dt)
		if i ~= 1 or plr:GetAttribute("InCave") ~= true or plr.CameraMode ~= Enum.CameraMode.LockFirstPerson then return nil end
		local cam = workspace.CurrentCamera
		if cam.CameraType == Enum.CameraType.Scriptable then return nil end -- a ride or a cutscene owns the view
		local d = dressed[pet.model] or dress(pet.model)
		if now >= nextScan then -- twice a second: the nearest rare deposit and any Gloomling close by
			nextScan = now + 0.5
			rare, gloomNear = nil, false
			local best = 30
			local deps = workspace:FindFirstChild("Caves") and workspace.Caves:FindFirstChild("Deposits")
			for _, dep in deps and deps:GetChildren() or {} do
				local c = dep.PrimaryPart
				if c and dep:GetAttribute("Ore") == 3 and c.Transparency < 1 then
					local m = (c.Position - h.Position).Magnitude
					if m < best then best, rare = m, dep end
				end
			end
			local gl = workspace:FindFirstChild("Gloom")
			for _, g in gl and gl:GetChildren() or {} do
				if g:IsA("BasePart") and (g.Position - h.Position).Magnitude < 25 then gloomNear = true end
			end
			if rare and not gloomNear and not chirped[rare] then
				chirped[rare] = true
				hopAt = now
				sfx("sparkle", 1.6)
				task.delay(0.12, function() sfx("sparkle", 1.9) end)
			end
		end
		local hop = math.clamp((now - hopAt) / 0.9, 0, 1)
		local bounce = hop < 1 and math.abs(math.sin(hop * math.pi * 3)) * 0.9 * (1 - hop) or 0
		local moving = h.AssemblyLinearVelocity.Magnitude > 2
		local bob = moving and math.abs(math.sin(now * 9)) * 0.35 or math.sin(now * 2.2) * 0.12 -- it bounds when you walk, floats when you stand
		local off = gloomNear and Vector3.new(2.6, -2.5, -4.2) or Vector3.new(-7.2, -0.9 + bob + bounce, -10.5) -- out in the open, left of and above the torch hand (nearer, it sat in the hand) -- cowering: low, by the pickaxe
		local goal = cam.CFrame:PointToWorldSpace(off)
		pet.pos = pet.pos:Lerp(goal, 1 - math.exp(-dt * (gloomNear and 12 or 7)))
		local face = rare and not gloomNear and rare.PrimaryPart.Position or pet.pos + cam.CFrame.LookVector * 3 + cam.CFrame.RightVector * 8 -- it trots ahead, half turned to you
		local flat = Vector3.new(face.X, pet.pos.Y, face.Z)
		local shiver = gloomNear and Vector3.new(math.noise(now * 22, 1) * 0.08, 0, math.noise(now * 22, 2) * 0.08) or Vector3.zero
		local cf = CFrame.lookAt(pet.pos + shiver, flat + shiver) * CFrame.new(0, 0, 0) * CFrame.Angles(gloomNear and 0.35 or -bounce * 0.3, 0, 0)
		local c = gloomNear and RED:Lerp(WARM, math.noise(now * 14, 5) * 0.5 + 0.5) or WARM
		d.bead.Color, d.light.Color = c, c
		d.light.Brightness = gloomNear and 0.2 + math.abs(math.noise(now * 18, 9)) * 0.5 or 0.6
		return cf
	end
end

return M
