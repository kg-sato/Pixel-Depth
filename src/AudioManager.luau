-- AudioManager (ReplicatedStorage.Shared.AudioManager), started by PixelClient (the user's overnight directive, 2026-11-10).
--   * reverb: the caves ring (ReverbType.Cave), the town is open air (Plain)
--   * panic: with fear over 70 % or the torch under 20 % every game sound is muffled (an equaliser on one sound group) and a
--     heartbeat comes in, faster and higher as the fear grows. The heartbeat is the soft "land" thud played as lub-dub.
--   * footsteps: E.vmHook.stepPitch() gives Juice a pitch for the floor underfoot (planks hollow, wet rock bright)
--   * drips: in the caves a drop falls from the ceiling near you every 2 to 5 s, rings on the floor and plinks from there
-- No new sound assets: everything is made from the 18 sounds in PixelClient's SFX table. Not heard by Claude.
local M = {}

function M.start(E)
	local SoundService, RunService = game:GetService("SoundService"), game:GetService("RunService")
	local plr, cave, tween = E.plr, E.cave, E.tween
	local calm = false
	pcall(function() calm = game:GetService("GuiService").ReducedMotionEnabled end)

	local group = Instance.new("SoundGroup")
	group.Name = "PixelMaster"
	group.Parent = SoundService
	local eq = Instance.new("EqualizerSoundEffect")
	eq.HighGain, eq.MidGain, eq.LowGain = 0, 0, 0
	eq.Parent = group
	local function adopt(s)
		if s:IsA("Sound") and s.Name ~= "PixelHeart" and s.SoundGroup == nil then s.SoundGroup = group end
	end
	for _, s in SoundService:GetDescendants() do adopt(s) end
	SoundService.DescendantAdded:Connect(adopt)

	local thud = SoundService:FindFirstChild("Pixel_land")
	local heart = thud and thud:Clone() -- outside the group: the heartbeat stays clear while the world goes dull
	if heart then
		heart.Name, heart.Volume = "PixelHeart", 0
		heart.SoundGroup = nil -- the clone carried the group over
		heart.Parent = SoundService
	end

	E.vmHook.stepPitch = function()
		local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
		local m = hum and hum.FloorMaterial
		if m == Enum.Material.Wood or m == Enum.Material.WoodPlanks then return 0.72 end -- a hollow clack
		if m == Enum.Material.Cobblestone or m == Enum.Material.Glass or m == Enum.Material.Ice then return 1.22 end -- a damp tap
		return 1 -- cave rock: the plain crunch
	end

	local function drip() -- one drop: ceiling to floor near the player, a ring where it lands, a plink from that spot
		local h = E.hrp()
		local base = SoundService:FindFirstChild("Pixel_pluck")
		if not h or not base then return end
		local params = RaycastParams.new()
		params.FilterDescendantsInstances = { plr.Character, workspace.CurrentCamera, workspace:FindFirstChild("ClientFX") }
		local at = h.Position + Vector3.new(math.random(-14, 14), 0, math.random(-14, 14))
		local up = workspace:Raycast(at, Vector3.new(0, 40, 0), params)
		local down = up and workspace:Raycast(up.Position - Vector3.new(0, 0.5, 0), Vector3.new(0, -80, 0), params)
		if not down then return end
		local drop = Instance.new("Part")
		drop.Size, drop.Color, drop.Material, drop.Transparency = Vector3.new(0.12, 0.3, 0.12), Color3.fromRGB(170, 220, 255), Enum.Material.Glass, 0.3
		drop.Anchored, drop.CanCollide, drop.CanQuery, drop.CanTouch, drop.CastShadow = true, false, false, false, false
		drop.Position = up.Position - Vector3.new(0, 0.3, 0)
		drop.Parent = workspace:FindFirstChild("ClientFX") or workspace
		local fall = math.clamp(math.sqrt((up.Position.Y - down.Position.Y) / 40), 0.2, 1.2)
		tween(drop, fall, { Position = down.Position }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		task.delay(fall, function()
			drop.Size, drop.Shape = Vector3.new(0.05, 0.4, 0.4), Enum.PartType.Cylinder -- the ring: a thin disc, 0.05 over the floor
			drop.CFrame = CFrame.new(down.Position + Vector3.new(0, 0.05, 0)) * CFrame.Angles(0, 0, math.pi / 2)
			drop.Transparency = 0.45
			tween(drop, 0.7, { Size = Vector3.new(0.05, 3.2, 3.2), Transparency = 1 })
			local s = base:Clone()
			s.PlaybackSpeed, s.Volume = 2 + math.random() * 0.5, 0.35
			s.RollOffMode, s.RollOffMinDistance, s.RollOffMaxDistance = Enum.RollOffMode.InverseTapered, 6, 50
			s.Parent = drop -- a sound in a part plays from that spot, left or right of you
			s:Play()
			task.delay(1.2, function() drop:Destroy() end)
		end)
	end

	local inCave, panic, nextBeat, nextDrip = nil, false, 0, os.clock() + 3
	RunService.Heartbeat:Connect(function()
		local now = os.clock()
		local c = plr:GetAttribute("InCave") == true
		if c ~= inCave then
			inCave = c
			SoundService.AmbientReverb = c and Enum.ReverbType.Cave or Enum.ReverbType.Plain
		end
		local fear, fuel = cave and cave.fear or 0, cave and cave.fuel or 1
		local p = c and (fear > 0.7 or fuel < 0.2)
		if p ~= panic then
			panic = p
			tween(eq, 0.8, { HighGain = p and -18 or 0, MidGain = p and -6 or 0 })
		end
		if p and heart and now >= nextBeat then
			local k = math.clamp(math.max((fear - 0.7) / 0.3, (0.2 - fuel) / 0.2), 0, 1)
			nextBeat = now + 1.05 - 0.45 * k
			for i, d in { 0, 0.16 } do -- lub-dub
				task.delay(d, function()
					local s = heart:Clone()
					s.Volume, s.PlaybackSpeed = i == 1 and 0.55 or 0.4, (0.9 + 0.4 * k) * (i == 1 and 0.6 or 0.7)
					s.Parent = SoundService
					s:Play()
					task.delay(1, function() s:Destroy() end)
				end)
			end
		end
		if c and not calm and now >= nextDrip then
			nextDrip = now + 2 + math.random() * 3
			pcall(drip)
		end
	end)
end

return M
