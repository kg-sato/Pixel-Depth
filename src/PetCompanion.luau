-- PetCompanion (ReplicatedStorage.Shared.PetCompanion), started by PixelClient. The crew pets as living company.
-- First built for the overnight directive of 2026-11-10 (the lead pet at the edge of the first-person view, a living radar);
-- grown in plan phase A, 2026-11-13 (vault: Briefs/Next Systems Plan (2026-11-13).md):
--   * FACES. Every pet, in town and in the caves, wears one of eight jelly faces on the front of its head (Config.PET_FACE):
--     calm, a blink now and then, sleepy after you stand still 8 s, greedy when it scents a rare deposit, scared near a
--     Gloomling, proud after a PERFECT strike, happy after an extraction, a hatch or the daily chest, hurt when you are hit or
--     grabbed, curious while it answers the whistle.
--   * THE CREW IN VIEW. In a cave, in first person, up to three crew pets trot at the left of the view (the lead in front and
--     largest), each with a small lantern on its collar. More than three stay behind you as before.
--   * THE WHISTLE (key X, or the wheel's CHEER slot, which reads WHISTLE in the caves). The lead pet runs to the nearest
--     deposit within Config.WHISTLE.reach studs and stands on it under a gold jelly mark for .show seconds; then .cool
--     seconds until the next. It only shows a place the player could find anyway: nothing is given, so it is client only.
--   * as before: it hops and chirps at a rare deposit within 30 studs (once each), its lantern flickers red near a Gloomling.
-- PixelClient's crew loop asks E.vmHook.petPose(i, pet, hrp, now, dt) for every pet; nil keeps the follow-behind place.
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local M = {}

function M.start(E)
	local plr, hook, sfx, C = E.plr, E.vmHook, E.sfx, E.C
	local WARM, RED = Color3.fromRGB(255, 196, 120), Color3.fromRGB(255, 84, 104)
	local GOLD, PINKJ, MINTJ = Color3.fromRGB(255, 205, 80), Color3.fromRGB(255, 120, 190), Color3.fromRGB(120, 235, 180)
	local JellyText = E.GLASS and require(script.Parent:WaitForChild("JellyText"))
	local FACE, W = C.PET_FACE, C.WHISTLE or { reach = 40, show = 8, cool = 30 }
	local recs = setmetatable({}, { __mode = "k" }) -- pet model -> its record (face, collar, mood mark)
	local chirped = setmetatable({}, { __mode = "k" }) -- deposits the pet has already pointed out
	local nextScan, rare, gloomNear, hopAt = 0, nil, false, -10
	-- where each of the first three pets keeps to in the first-person view (camera space), and its size
	local SLOT = {
		{ off = Vector3.new(-7.4, -0.4, -10), scale = 1.6 },
		{ off = Vector3.new(-10.6, -1.0, -14.5), scale = 1.25 },
		{ off = Vector3.new(-5.0, -1.1, -15.5), scale = 1.25 },
	}

	-- moments the whole crew feels for a few seconds
	local moment, momentUntil = nil, 0
	local function feel(name, secs)
		moment, momentUntil = name, os.clock() + secs
	end
	local lastHp = plr:GetAttribute("HP")
	plr:GetAttributeChangedSignal("HP"):Connect(function()
		local hp = plr:GetAttribute("HP")
		if lastHp and hp and hp < lastHp then feel("hurt", 2.5) end
		lastHp = hp
	end)
	if E.R and E.R:FindFirstChild("Fx") then
		E.R.Fx.OnClientEvent:Connect(function(kind, _, b)
			if kind == "mgStrike" and b == true then feel("proud", 2.2)
			elseif kind == "mgEnd" or kind == "hatch" or kind == "dailyChest" or kind == "sold" then feel("happy", 3)
			elseif kind == "grabbed" or kind == "caught" then feel("hurt", 2.5) end
		end)
	end
	local stillSince, lastPos = os.clock(), nil

	local function rec(model)
		local d = recs[model]
		if d then return d end
		d = { face = "", seed = math.random() * 4 }
		recs[model] = d
		local head = FACE and model:FindFirstChild("Head")
		if head then
			for _, p in model:GetChildren() do -- the two block eyes make way for the face
				if p.Name == "Eye" then p.Transparency = 1 end
			end
			local sg = Instance.new("SurfaceGui")
			sg.Name, sg.Face, sg.LightInfluence, sg.Brightness = "Face", Enum.NormalId.Front, 0.25, 1.3
			sg.SizingMode, sg.CanvasSize = Enum.SurfaceGuiSizingMode.FixedSize, Vector2.new(230, 200)
			sg.Parent = head
			local img = Instance.new("ImageLabel")
			img.BackgroundTransparency, img.ScaleType = 1, Enum.ScaleType.Fit
			img.Size, img.Position, img.AnchorPoint = UDim2.fromScale(1.22, 1.22), UDim2.fromScale(0.5, 0.52), Vector2.new(0.5, 0.5)
			img.Image = FACE.calm
			img.Parent = sg
			local sc = Instance.new("UIScale")
			sc.Parent = img
			d.img, d.sc, d.face = img, sc, "calm"
		end
		return d
	end
	local function show(d, name, snap)
		if not d.img or d.face == name then return end
		d.face = name
		d.img.Image = FACE[name] or FACE.calm
		if not snap then -- a new feeling lands with a small pop; a blink does not
			d.sc.Scale = 1.3
			TweenService:Create(d.sc, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
		end
	end

	local function dress(model, d, lead) -- the collar lantern: a dark band under the head and a small glowing bead
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
		light.Range, light.Brightness, light.Color, light.Shadows = lead and 9 or 6, 0.3, WARM, false
		light.Parent = bead
		for _, p in model:GetDescendants() do -- the pet's own back glow is 1.2: this close to the camera it burned out
			if p:IsA("PointLight") and p ~= light then p.Brightness = 0.25 end
			if p:IsA("BasePart") and p.Material == Enum.Material.Neon and p ~= bead then p.Color = p.Color:Lerp(Color3.new(0, 0, 0), 0.45) end -- so did its neon back
		end
		d.bead, d.light = bead, light
		if lead and JellyText then -- a mood mark over the lead's head
			local bb = Instance.new("BillboardGui")
			bb.Name, bb.Size, bb.StudsOffsetWorldSpace, bb.LightInfluence, bb.AlwaysOnTop, bb.MaxDistance = "Mood", UDim2.fromScale(2.4, 1.5), Vector3.new(0, 2.5, 0), 0, false, 80
			bb.Adornee, bb.Enabled = root, false
			bb.Parent = model
			local holder = Instance.new("Frame")
			holder.Size, holder.BackgroundTransparency = UDim2.fromScale(1, 1), 1
			holder.Parent = bb
			d.mood = { bb = bb, text = JellyText.new(holder, "!", { color = GOLD, glow = true }), state = "" }
		end
	end

	-- the whistle
	local whistle = { at = -1000, untilT = 0, dep = nil, mark = nil }
	local hasPet = false
	local function whistleWhy()
		if plr:GetAttribute("InCave") ~= true then return "Caves only" end
		if not hasPet then return "No pet yet" end
		local left = W.cool - (os.clock() - whistle.at)
		if left > 0 then return "Ready in " .. math.ceil(left) .. " s" end
		return nil
	end
	hook.whistleWhy = whistleWhy
	hook.whistle = function()
		if whistleWhy() or (E.isBusy and E.isBusy()) then
			pcall(sfx, "error", 1)
			return false
		end
		local h = E.hrp()
		local deps = workspace:FindFirstChild("Caves") and workspace.Caves:FindFirstChild("Deposits")
		local best, bd
		for _, dep in h and deps and deps:GetChildren() or {} do
			local c = dep.PrimaryPart
			if c and c.Transparency < 1 then -- an extracted deposit hides until it grows back
				local m = (c.Position - h.Position).Magnitude
				if m <= W.reach and (not bd or m < bd) then best, bd = dep, m end
			end
		end
		whistle.at = os.clock()
		pcall(sfx, "sparkle", 2.2)
		task.delay(0.1, function() pcall(sfx, "sparkle", 2.6) end)
		if not best then -- it looked and found nothing: a short cooldown only
			whistle.at = os.clock() - W.cool + 5
			feel("sleepy", 2)
			if E.toast then E.toast("NO ORE NEAR", MINTJ) end
			return false
		end
		if whistle.mark then whistle.mark:Destroy() end
		whistle.dep, whistle.untilT = best, os.clock() + W.show
		feel("curious", W.show)
		local core = best.PrimaryPart
		local bb = Instance.new("BillboardGui")
		bb.Name, bb.Size, bb.StudsOffsetWorldSpace, bb.LightInfluence, bb.AlwaysOnTop, bb.MaxDistance = "WhistleMark", UDim2.fromScale(5, 1.8), Vector3.new(0, 5.2, 0), 0, false, 120
		bb.Adornee = core
		bb.Parent = plr:WaitForChild("PlayerGui")
		local holder = Instance.new("Frame")
		holder.Size, holder.BackgroundTransparency = UDim2.fromScale(1, 1), 1
		holder.Parent = bb
		if JellyText then JellyText.new(holder, "HERE!", { color = GOLD, glow = true, pop = true }) end
		local glow = Instance.new("PointLight")
		glow.Name, glow.Color, glow.Range, glow.Brightness, glow.Shadows = "WhistleGlow", GOLD, 14, 1.4, false
		glow.Parent = core
		whistle.mark = bb
		task.delay(W.show, function()
			bb:Destroy()
			glow:Destroy()
			if whistle.mark == bb then whistle.mark, whistle.dep = nil, nil end
		end)
		return true
	end
	UIS.InputBegan:Connect(function(io, gp)
		if not gp and io.KeyCode == Enum.KeyCode.X then hook.whistle() end
	end)

	hook.petPose = function(i, pet, h, now, dt)
		local d = rec(pet.model)
		if i == 1 then
			hasPet = true
			if lastPos and (h.Position - lastPos).Magnitude > 0.05 then stillSince = now end
			lastPos = h.Position
		end
		local inCave = plr:GetAttribute("InCave") == true
		local cam = workspace.CurrentCamera
		local view = inCave and i <= #SLOT and plr.CameraMode == Enum.CameraMode.LockFirstPerson and cam.CameraType ~= Enum.CameraType.Scriptable
		-- the face
		local want = "calm"
		if now < momentUntil then want = moment
		elseif inCave and gloomNear then want = "scared"
		elseif inCave and rare and now - hopAt < 3 then want = "greedy"
		elseif now - stillSince > 8 then want = "sleepy" end
		local blink = want == "calm" and (now + d.seed) % 4.2 < 0.13
		show(d, blink and "sleepy" or want, blink or d.face == "sleepy" and want == "calm")
		if not view then
			if d.big then -- back in town, or a ride owns the view: its own size again
				d.big = false
				pet.model:ScaleTo(d.scale0)
			end
			return nil
		end
		local slot = SLOT[i]
		if not d.bead then dress(pet.model, d, i == 1) end
		if not d.big then -- big enough to read at the edge of the view
			d.big, d.scale0 = true, d.scale0 or pet.model:GetScale()
			pet.model:ScaleTo(d.scale0 * slot.scale)
		end
		if i == 1 and now >= nextScan then -- twice a second: the nearest rare deposit and any Gloomling close by
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
		local hop = math.clamp((now - hopAt - (i - 1) * 0.12) / 0.9, 0, 1) -- the others hop a beat after the lead
		local bounce = (hop > 0 and hop < 1) and math.abs(math.sin(hop * math.pi * 3)) * 0.9 * (1 - hop) or 0
		local moving = h.AssemblyLinearVelocity.Magnitude > 2
		local bob = moving and math.abs(math.sin(now * 9 + i * 1.7)) * 0.35 or math.sin(now * 2.2 + i) * 0.12 -- it bounds when you walk, floats when you stand
		local goal = cam.CFrame:PointToWorldSpace(gloomNear and slot.off + Vector3.new(0, -1, 0) or slot.off + Vector3.new(0, bob + bounce, 0))
		local called = i == 1 and whistle.dep and now < whistle.untilT and whistle.dep.PrimaryPart
		if called then goal = called.Position + Vector3.new(0, 2.6 + math.abs(math.sin(now * 7)) * 0.5, 0) end -- answering the whistle: it stands on the deposit and hops
		pet.pos = pet.pos:Lerp(goal, 1 - math.exp(-dt * (called and 4 or (gloomNear and 12 or 7))))
		local face = called and cam.CFrame.Position or (rare and not gloomNear and rare.PrimaryPart.Position) or pet.pos + cam.CFrame.LookVector * (moving and 3 or -4) + cam.CFrame.RightVector * 8 -- walking: it trots ahead, half turned; standing: it turns its face to you
		local flat = Vector3.new(face.X, pet.pos.Y, face.Z)
		local shiver = gloomNear and Vector3.new(math.noise(now * 22, i) * 0.08, 0, math.noise(now * 22, i + 4) * 0.08) or Vector3.zero
		local aim = CFrame.lookAt(pet.pos + shiver, flat + shiver) * CFrame.Angles(gloomNear and 0.35 or -bounce * 0.3, 0, 0)
		d.rot = d.rot and d.rot:Lerp(aim.Rotation, 1 - math.exp(-dt * 6)) or aim.Rotation -- it turns its body, it does not snap
		local cf = CFrame.new(aim.Position) * d.rot
		local c = gloomNear and RED:Lerp(WARM, math.noise(now * 14, 5 + i) * 0.5 + 0.5) or WARM
		d.bead.Color, d.light.Color = c, c
		d.light.Brightness = gloomNear and 0.2 + math.abs(math.noise(now * 18, 9 + i)) * 0.5 or 0.3
		if d.mood then
			local wantM = gloomNear and "scared" or ((rare and now - hopAt < 2.2) and "found" or "")
			if wantM ~= d.mood.state then
				d.mood.state = wantM
				d.mood.bb.Enabled = wantM ~= ""
				if wantM ~= "" then
					d.mood.text.tint(wantM == "scared" and PINKJ or GOLD)
					d.mood.text.set(wantM == "scared" and "!!" or "!")
					d.mood.text.pop(0.05)
				end
			end
		end
		return cf
	end
end

return M
