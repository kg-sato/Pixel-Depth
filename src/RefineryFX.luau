-- RefineryFX (ReplicatedStorage.Shared.RefineryFX), started by PixelClient. Master Directive v15 (@marctgamer's in-world cooking
-- pot, vault Social References Review (2026-11-23)): the Surface Refinery's open crucible (ServerScriptService.Retention builds
-- it: CrucibleMelt, the STIR prompt on CrucibleStirPoint) shows THIS player's own job, so it is all local:
--   * no job: the melt is a cold bed of dark ash slag and the tongs rest on the rim;
--   * a job running (player attribute RefineAt): the melt glows warm amber, then molten gold, then crystal cyan as the job
--     nears its end, domes of liquid bob on it, glowing bubbles and embers rise, and an iron paddle stirs round the bowl;
--   * the STIR prompt shows while the job runs and was not stirred yet (player attribute RefineStirred); a stir the server
--     accepts bursts forge sparks out of the bowl.
-- Display only: the server owns the job, the clock and the one stir a job.
local RunService = game:GetService("RunService")
local M = {}

function M.start(E)
	local plr = E.plr or game:GetService("Players").LocalPlayer
	local AMBER, GOLDM, CYAN = Color3.fromRGB(205, 82, 22), Color3.fromRGB(214, 150, 38), Color3.fromRGB(54, 170, 205) -- neon glows by its colour: full-strength tints burned the melt white from the town camera (v15 still)
	local SLAG = Color3.fromRGB(58, 48, 62)
	local melt, prompt, folder
	local domes, bubbles, paddle = {}, {}, nil
	local total, lastAt = nil, nil
	local function find()
		local hub = workspace:FindFirstChild("Hub")
		melt = hub and hub:FindFirstChild("CrucibleMelt", true)
		local pt = hub and hub:FindFirstChild("CrucibleStirPoint", true)
		prompt = pt and pt:FindFirstChildOfClass("ProximityPrompt")
		return melt ~= nil
	end
	local function bit(size, color, mat)
		local p = Instance.new("Part")
		p.Size, p.Color, p.Material, p.Anchored = size, color, mat or Enum.Material.Neon, true
		p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = false, false, false, false
		p.Parent = folder
		return p
	end
	local function build()
		folder = Instance.new("Folder")
		folder.Name = "RefineryFX"
		folder.Parent = workspace
		for k = 1, 5 do domes[k] = bit(Vector3.new(0.5, 0.3, 0.5), GOLDM) end -- liquid domes that swell and sink on the melt
		for k = 1, 8 do bubbles[k] = { p = bit(Vector3.new(0.22, 0.22, 0.22), GOLDM), t0 = -10, x = 0, z = 0 } end
		local IRON, WOOD = Color3.fromRGB(70, 60, 92), Color3.fromRGB(120, 80, 52)
		paddle = { handle = bit(Vector3.new(0.22, 3.4, 0.22), WOOD, Enum.Material.Wood), blade = bit(Vector3.new(0.7, 0.9, 0.14), IRON, Enum.Material.Metal), grip = bit(Vector3.new(0.3, 0.3, 0.3), IRON, Enum.Material.Metal) }
		local em = Instance.new("ParticleEmitter") -- embers spitting off the melt
		em.Texture, em.Rate, em.Lifetime, em.Speed, em.SpreadAngle = "rbxasset://textures/particles/sparkles_main.dds", 0, NumberRange.new(0.8, 1.5), NumberRange.new(2, 4), Vector2.new(25, 25)
		em.Size, em.LightEmission, em.Acceleration = NumberSequence.new(0.2, 0), 1, Vector3.new(0, -3, 0)
		em.Color = ColorSequence.new(Color3.fromRGB(255, 226, 140), Color3.fromRGB(255, 100, 40))
		em.EmissionDirection = Enum.NormalId.Top
		em.Name = "MeltEmbers"
		em.Parent = melt
	end
	local function setActive(on)
		for _, d in domes do d.Transparency = on and 0 or 1 end
		for _, b in bubbles do b.p.Transparency = 1 end
		for _, q in paddle do q.Transparency = on and 0 or 1 end
		local em = melt:FindFirstChild("MeltEmbers")
		if em then em.Rate = on and 6 or 0 end
		if not on then melt.Color, melt.Material = SLAG, Enum.Material.Slate end
	end
	local active = nil
	local nextBubble = 0
	RunService.Heartbeat:Connect(function()
		if not melt or not melt.Parent then
			if not find() then return end
			if folder then folder:Destroy() end -- the town was built again: start over on the new crucible
			build()
			active = nil
		end
		local cam = workspace.CurrentCamera
		if (cam.CFrame.Position - melt.Position).Magnitude > 160 then return end -- out of sight in the caves: nothing to animate
		local at = plr:GetAttribute("RefineAt")
		local now = workspace:GetServerTimeNow()
		local on = type(at) == "number"
		if on ~= active then active = on setActive(on) end
		if prompt then prompt.Enabled = on and at > now + 1 and not plr:GetAttribute("RefineStirred") end
		if not on then total, lastAt = nil, nil return end
		if at ~= lastAt then -- a new job (or a stir moved its end): measure the whole job from here
			if not lastAt or at > lastAt then total = math.max(at - now, 1) end
			lastAt = at
		end
		local p = math.clamp(1 - (at - now) / (total or 1), 0, 1)
		local c = p < 0.5 and AMBER:Lerp(GOLDM, p / 0.5) or GOLDM:Lerp(CYAN, (p - 0.5) / 0.5)
		if now >= at then c = CYAN:Lerp(Color3.new(1, 1, 1), (math.sin(os.clock() * 4) + 1) * 0.15) end -- done: a cool crystal glow that pulses, come and take it
		melt.Color, melt.Material = c, Enum.Material.Neon
		local t = os.clock()
		local top = melt.CFrame * CFrame.new(0, melt.Size.Y / 2, 0)
		for k, d in domes do -- domes swell and sink in turn
			local ph = (t * 0.9 + k * 0.37) % 1
			local h = math.sin(ph * math.pi)
			d.Color = c:Lerp(Color3.new(1, 1, 1), 0.12)
			d.Size = Vector3.new(0.35 + h * 0.35, 0.08 + h * 0.3, 0.35 + h * 0.35)
			d.CFrame = top * CFrame.new(math.cos(k * 2.4) * 0.8, d.Size.Y / 2 - 0.02, math.sin(k * 2.4) * 0.6)
		end
		if t > nextBubble then -- a glowing bubble rises out of the melt
			nextBubble = t + 0.22
			for _, b in bubbles do
				if t - b.t0 > 1.2 then
					b.t0, b.x, b.z = t, math.random(-10, 10) / 10, math.random(-8, 8) / 10
					break
				end
			end
		end
		for _, b in bubbles do
			local u = (t - b.t0) / 1.2
			if u >= 0 and u < 1 then
				b.p.Color = c:Lerp(Color3.new(1, 1, 1), 0.25)
				b.p.Transparency = u * 0.9
				b.p.Size = Vector3.one * (0.24 - u * 0.14)
				b.p.CFrame = top * CFrame.new(b.x, 0.15 + u * 1.6, b.z) * CFrame.Angles(u * 3, u * 2, 0)
			else
				b.p.Transparency = 1
			end
		end
		local a = t * 0.8 -- the paddle walks round the bowl, dipping into the melt
		local dip = top * CFrame.new(math.cos(a) * 0.6, 0, math.sin(a) * 0.45)
		local lean = CFrame.Angles(math.sin(a) * 0.35, 0, -math.cos(a) * 0.35 - 0.15)
		paddle.blade.CFrame = dip * CFrame.new(0, 0.05 + math.sin(t * 3) * 0.08, 0) * lean * CFrame.new(0, 0.15, 0)
		paddle.handle.CFrame = paddle.blade.CFrame * CFrame.new(0, 2.1, 0)
		paddle.grip.CFrame = paddle.handle.CFrame * CFrame.new(0, 1.75, 0)
	end)
	E.R.Fx.OnClientEvent:Connect(function(kind, a)
		if kind == "refine" and a == "stir" and melt then -- the stir the server took: a burst of forge sparks out of the bowl
			if E.burst then pcall(E.burst, melt.Position + Vector3.new(0, 0.6, 0), Vector3.yAxis, Color3.fromRGB(255, 200, 90), 36) end
			if E.shake then pcall(E.shake, 0.25) end
			local em = melt:FindFirstChild("MeltEmbers")
			if em then em:Emit(40) end
		end
	end)
end

return M
