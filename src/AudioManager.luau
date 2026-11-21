-- AudioManager (ReplicatedStorage.Shared.AudioManager), started by PixelClient (the user's overnight directive, 2026-11-10).
--   * panic: with fear over 70 % or the torch under 20 % every game sound is muffled (an equaliser on one sound group) and a
--     heartbeat comes in, faster and higher as the fear grows. The heartbeat is the soft "land" thud played as lub-dub.
--   * footsteps: E.vmHook.stepPitch() gives Juice a pitch for the floor underfoot (planks hollow, wet rock bright)
--   * drips: in the caves a drop falls from the ceiling near you every 2 to 5 s, rings on the floor and plinks from there
-- Directive v13 phase 2 (vault Research/Audio/Subterranean Soundscapes and Dynamic Audio (2026-11-20)), our own sounds in
-- Config.CAVE_SFX (audio/pd_cave_sfx.py):
--   * biome beds: town hearth, Rootholm wind, Clay kiln hum, Glitterhall shimmer, Muspell rumble. The bed of where you stand
--     plays in gestures of 40 to 70 s, then rests 18 to 35 s in silence so drips and clinks stand out (Pikmin 2); moving to
--     another biome crossfades over 1.8 s on a cosine curve, never a hard cut.
--   * room size by ear: five rays (up, and four ways round) five times a second measure the space; a vault rings (Hangar),
--     a hall echoes (Cave), a tunnel tightens (StoneCorridor) and a squeeze or a Gloomling within 18 studs goes dry and close
--     (PaddedCell); now and then a tight blind corner goes dry with nothing there (a false alarm, by design).
--   * threats by ear: a Gloomling within 60 studs skitters from where it is; behind rock its sound is muffled (low-passed).
--   * ducking: during a Perfect Strike dial, a boss slam and a hatch the beds dip 6 dB and come back over 0.25 s.
--   * strikes: E.vmHook.strikeStem(perfect) plays the two-element hit (a low body thump under the biome's material ring),
--     every swing a little higher or lower (0.93 to 1.08).
--   * world events: Spore Storm, Kiln Surge, Golden Vein and Crystal Rift have their own stings; the escape has a drum loop.
--   * mobile: SoundService.AcousticSimulationEnabled stays off on low graphics; the ray probe is the cheap stand-in.
-- Not heard by Claude: every file is measured instead (audio/pd_audit.py table in the vault note).
local M = {}

function M.start(E)
	local SoundService, RunService = game:GetService("SoundService"), game:GetService("RunService")
	local plr, cave, tween, C = E.plr, E.cave, E.tween, E.C
	local IDS = C.CAVE_SFX or {}
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
	pcall(function() -- the engine's acoustic simulation is costly on phones: off on low graphics, the ray probe below stands in
		local low = UserSettings().GameSettings.SavedQualityLevel.Value <= 6 or game:GetService("UserInputService").PreferredInput == Enum.PreferredInput.Touch
		if low then SoundService.AcousticSimulationEnabled = false end
	end)

	local thud = SoundService:FindFirstChild("Pixel_land")
	local heart = thud and thud:Clone() -- outside the group: the heartbeat stays clear while the world goes dull
	if heart then
		heart.Name, heart.Volume = "PixelHeart", 0
		heart.SoundGroup = nil -- the clone carried the group over
		heart.Parent = SoundService
	end

	local function sound(name, vol, parent) -- a one-off from Config.CAVE_SFX
		local id = IDS[name]
		if not id then return nil end
		local s = Instance.new("Sound")
		s.Name, s.SoundId, s.Volume = "Cave_" .. name, "rbxassetid://" .. id, vol or 0.5
		s.PlaybackSpeed = 0.93 + math.random() * 0.15 -- never the same twice (aud01: random pitch beats a static sample)
		s.Parent = parent or SoundService
		s:Play()
		task.delay(6, function() if s.Parent then s:Destroy() end end)
		return s
	end
	E.vmHook.caveSound = sound

	E.vmHook.stepPitch = function()
		local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
		local m = hum and hum.FloorMaterial
		if m == Enum.Material.Wood or m == Enum.Material.WoodPlanks then return 0.72 end -- a hollow clack
		if m == Enum.Material.Cobblestone or m == Enum.Material.Glass or m == Enum.Material.Ice then return 1.22 end -- a damp tap
		return 1 -- cave rock: the plain crunch
	end

	-- ------------------------------------------------------------------ where am I: town, root, clay, glitter, muspell
	local BIOME_OF_LAYER = { "root", "clay", "glitter", "muspell" }
	local boxes
	local function biome()
		if plr:GetAttribute("InCave") ~= true then return "town" end
		local h = E.hrp()
		if not h then return "root" end
		local p = h.Position
		if not boxes then
			boxes = {}
			local caves = workspace:FindFirstChild("Caves")
			for _, m in caves and caves:GetDescendants() or {} do
				if m:IsA("Model") and m:GetAttribute("Layer") and #m:GetChildren() > 3 then
					local ok, cf, size = pcall(function() return m:GetBoundingBox() end)
					if ok and size.Magnitude > 60 then table.insert(boxes, { cf = cf, size = size, L = m:GetAttribute("Layer") }) end
				end
			end
		end
		for _, b in boxes do
			local lp = b.cf:PointToObjectSpace(p)
			if math.abs(lp.X) <= b.size.X / 2 and math.abs(lp.Y) <= b.size.Y / 2 and math.abs(lp.Z) <= b.size.Z / 2 then
				return BIOME_OF_LAYER[b.L] or "root"
			end
		end
		if C.CAVE2_ORIGIN and (p - C.CAVE2_ORIGIN).Magnitude < 260 then return "clay" end
		return "root"
	end
	E.vmHook.biome = biome

	-- ------------------------------------------------------------------ beds: gestures, rests, cosine crossfades, ducking
	local BEDS = { town = { "town_hearth", 0.5 }, root = { "rootholm_wind", 0.55 }, clay = { "clay_kiln_hum", 0.6 }, glitter = { "glitter_shimmer", 0.55 }, muspell = { "muspell_rumble", 0.6 } }
	local beds = {}
	for k, b in BEDS do
		if IDS[b[1]] then
			local s = Instance.new("Sound")
			s.Name, s.SoundId, s.Looped, s.Volume = "Bed_" .. b[1], "rbxassetid://" .. IDS[b[1]], true, 0
			s.Parent = SoundService
			beds[k] = { s = s, top = b[2], g = 0 } -- g: 0..1 along the cosine fade
		end
	end
	local here, gestureEnds, restEnds = nil, os.clock() + 40 + math.random() * 30, 0
	local duck, duckUntil = 1, 0
	E.vmHook.duck = function(sec) duckUntil = math.max(duckUntil, os.clock() + (sec or 1)) end
	local function bedStep(dt, now)
		local b = biome()
		if b ~= here then
			here = b
			gestureEnds, restEnds = now + 40 + math.random() * 30, 0 -- a new place starts with its bed playing
		end
		if restEnds > 0 and now >= restEnds then
			restEnds, gestureEnds = 0, now + 40 + math.random() * 30
		elseif restEnds == 0 and now >= gestureEnds then
			restEnds = now + 18 + math.random() * 17 -- the breathing window (aud03: 18 to 35 s)
		end
		local hud = E.caveHud
		local ps = hud and hud:FindFirstChild("PerfectStrike")
		local wantDuck = (now < duckUntil or (ps and ps.Visible) or E.vmHook.hatchBusy == true) and 0.5 or 1 -- -6 dB
		duck += (wantDuck - duck) * math.min(1, dt / (wantDuck < duck and 0.05 or 0.25))
		for k, d in beds do
			local on = k == here and restEnds == 0
			d.g = math.clamp(d.g + (on and 1 or -1) * dt / 1.8, 0, 1)
			local v = d.top * (1 - math.cos(math.pi * d.g)) / 2 * duck
			if v > 0.001 and not d.s.IsPlaying then d.s:Play() end
			if v <= 0.001 and d.s.IsPlaying and d.g == 0 then d.s:Pause() end
			d.s.Volume = v
		end
	end

	-- ------------------------------------------------------------------ the room by ear (5 Hz, five rays)
	local probeParams = RaycastParams.new()
	probeParams.FilterType = Enum.RaycastFilterType.Exclude
	local DIRS = { Vector3.new(0, 1, 0), Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0), Vector3.new(0, 0, 1), Vector3.new(0, 0, -1) }
	local roomWant, roomSince, roomNow = nil, 0, nil
	local falseUntil, nextFalse = 0, os.clock() + 25
	local nearGloom = math.huge
	local function gloomDist(p)
		local best = math.huge
		local f = workspace:FindFirstChild("Gloom")
		for _, g in f and f:GetChildren() or {} do
			local pp = g:IsA("Model") and g.PrimaryPart or (g:IsA("BasePart") and g)
			if pp then best = math.min(best, (pp.Position - p).Magnitude) end
		end
		return best
	end
	local function probe(now)
		local h = E.hrp()
		if not h then return end
		local head = h.Position + Vector3.new(0, 1.5, 0)
		probeParams.FilterDescendantsInstances = { plr.Character, workspace.CurrentCamera, workspace:FindFirstChild("ClientFX"), workspace:FindFirstChild("Gloom") }
		local sum, open = 0, 0
		for _, d in DIRS do
			local r = workspace:Raycast(head, d * 70, probeParams)
			local dist = r and (head - r.Position).Magnitude or 70
			sum += dist
			if dist >= 70 then open += 1 end
		end
		local avg = sum / #DIRS
		nearGloom = gloomDist(head)
		local want
		if nearGloom < 18 or avg < 6 or now < falseUntil then want = Enum.ReverbType.PaddedCell -- dry and close: something breathes behind you
		elseif avg < 14 then want = Enum.ReverbType.StoneCorridor
		elseif avg < 32 then want = Enum.ReverbType.Cave
		else want = Enum.ReverbType.Hangar end -- a vault: you are small in it
		if avg < 10 and now > nextFalse then -- a blind corner tightens with nothing there now and then (aud02: break the rule you taught)
			nextFalse = now + 40 + math.random() * 40
			if math.random() < 0.35 then falseUntil = now + 3 end
		end
		if want ~= roomWant then roomWant, roomSince = want, now end
		if roomWant ~= roomNow and now - roomSince > 0.6 then -- held 0.6 s: no flicker at a doorway
			roomNow = roomWant
			SoundService.AmbientReverb = roomNow
		end
	end

	-- ------------------------------------------------------------------ Gloomlings by ear, muffled behind rock
	local nextSkitter = os.clock() + 4
	local function skitter(now)
		local h = E.hrp()
		local f = workspace:FindFirstChild("Gloom")
		if not h or not f then return end
		local best, bd, bestG
		for _, g in f:GetChildren() do
			local pp = g:IsA("Model") and g.PrimaryPart or (g:IsA("BasePart") and g)
			local d = pp and (pp.Position - h.Position).Magnitude
			if d and d < 60 and (not bd or d < bd) then best, bd, bestG = pp, d, g end
		end
		if not best then return end
		local clay = bestG:GetAttribute("Seen") ~= nil -- a clayling (only they carry Seen): a ceramic scrape, and only while it moves unseen
		if clay and bestG:GetAttribute("Seen") == true then return end
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { plr.Character, workspace.CurrentCamera, f, workspace:FindFirstChild("ClientFX") }
		local hit = workspace:Raycast(h.Position, best.Position - h.Position, params)
		local s = sound(clay and "clay_scrape" or "stalker_skitter", clay and 0.5 or 0.55, best)
		if s then
			s.RollOffMode, s.RollOffMinDistance, s.RollOffMaxDistance = Enum.RollOffMode.InverseTapered, 8, 70
			if hit then -- behind rock: the bright legs are gone, only a low scrabble comes through
				local lpf = Instance.new("EqualizerSoundEffect")
				lpf.HighGain, lpf.MidGain, lpf.LowGain = -30, -10, 2
				lpf.Parent = s
			end
		end
	end

	-- ------------------------------------------------------------------ strikes and world events
	E.vmHook.strikeStem = function(perfect)
		local RING = { town = "root_thock", root = "root_thock", clay = "clay_squelch", glitter = "crystal_chime", muspell = "basalt_flint" }
		sound("thump", perfect and 0.55 or 0.5)
		sound(RING[here or "root"] or "root_thock", perfect and 0.45 or 0.35)
	end
	E.R.Fx.OnClientEvent:Connect(function(kind)
		if kind == "kilnSurge" then sound("kiln_surge", 0.6)
		elseif kind == "goldSurge" then sound("golden_vein", 0.6)
		elseif kind == "crystalRift" then sound("crystal_rift", 0.6)
		elseif kind == "bossSlam" then E.vmHook.duck(1.6)
		elseif kind == "clayShift" then sound("clay_scrape", 0.4) end
	end)
	workspace:GetAttributeChangedSignal("SporeStorm"):Connect(function()
		local ends = workspace:GetAttribute("SporeStorm")
		if ends and ends > workspace:GetServerTimeNow() and plr:GetAttribute("InCave") then sound("spore_storm", 0.55) end
	end)
	local drum
	if IDS.escape_drum then
		drum = Instance.new("Sound")
		drum.Name, drum.SoundId, drum.Looped, drum.Volume = "EscapeDrum", "rbxassetid://" .. IDS.escape_drum, true, 0
		drum.Parent = SoundService
	end
	local escapeAt

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

	local inCave, panic, nextBeat, nextDrip, nextProbe = nil, false, 0, os.clock() + 3, 0
	RunService.Heartbeat:Connect(function(dt)
		local now = os.clock()
		local c = plr:GetAttribute("InCave") == true
		if c ~= inCave then
			inCave = c
			if not c then roomNow, roomWant = nil, nil SoundService.AmbientReverb = Enum.ReverbType.Plain end
		end
		if c and now >= nextProbe then
			nextProbe = now + 0.2 -- 5 Hz
			pcall(probe, now)
		end
		pcall(bedStep, dt, now)
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
		if c and now >= nextSkitter then
			nextSkitter = now + 5 + math.random() * 6
			pcall(skitter, now)
		end
		if drum then -- the escape: a drum loop that speeds up the longer the chase runs
			local esc = workspace:FindFirstChild("MinecartEscape") ~= nil
			if esc and not escapeAt then escapeAt = now drum:Play() end
			if not esc and escapeAt then escapeAt = nil end
			local want = esc and 0.45 or 0
			drum.Volume += (want - drum.Volume) * math.min(1, dt * 3)
			if esc then drum.PlaybackSpeed = 1 + math.min((now - escapeAt) / 40, 1) * 0.15 end
			if not esc and drum.IsPlaying and drum.Volume < 0.01 then drum:Stop() end
		end
	end)
end

return M
