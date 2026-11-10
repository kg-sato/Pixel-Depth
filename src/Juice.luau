-- Juice (ReplicatedStorage.Shared.Juice), started by PixelClient. Small body and world animations the game lacked (the user,
-- 2026-11-10: "more animations for shop interactions, abilities, torches, eggs, pickaxe swings, walking around, claiming
-- dailies"). The first-person tool animations (swing variants, torch sway, flare thrust, landing dip) live in Shared.ViewHands.
--   * emotes: the miner waves when a shop opens and cheers on a purchase, a sale, a hatch, an egg find, the daily chest and a
--     quest claim (Roblox's own emote animations; E.vmHook.emote(name) for other modules)
--   * walking: dust puffs at the feet while walking, a bigger puff on landing
--   * eggs: the glowing heart of every nest and altar egg beats, faster as you come near
local M = {}

local EMOTE = { -- Roblox's default emote animations
	[Enum.HumanoidRigType.R15] = { wave = 507770239, cheer = 507770677, point = 507770453 },
	[Enum.HumanoidRigType.R6] = { wave = 128777973, cheer = 129423030, point = 128853357 },
}
local ON_FX = {
	openSell = "wave", openForge = "wave", openQuests = "point",
	bought = "cheer", upgraded = "cheer", boughtEgg = "cheer", sold = "cheer", soldPick = "cheer", hatch = "cheer",
	nestEgg = "cheer", egg = "cheer", dailyChest = "cheer", shrineGems = "cheer", noCoins = "point", needOre = "point",
}

function M.start(E)
	local R, plr, burst, sfx = E.R, E.plr, E.burst, E.sfx
	local RunService = game:GetService("RunService")
	local calm = false
	pcall(function() calm = game:GetService("GuiService").ReducedMotionEnabled end)

	local playing
	local function emote(name)
		local ch = plr.Character
		local hum = ch and ch:FindFirstChildOfClass("Humanoid")
		local an = hum and hum:FindFirstChildOfClass("Animator")
		local id = hum and EMOTE[hum.RigType] and EMOTE[hum.RigType][name]
		if not an or not id or plr:GetAttribute("Seated") then return end
		if playing then playing:Stop(0.1) end
		local a = Instance.new("Animation")
		a.AnimationId = "rbxassetid://" .. id
		local ok, tr = pcall(function() return an:LoadAnimation(a) end)
		if not ok or not tr then return end
		tr.Priority, tr.Looped = Enum.AnimationPriority.Action, false
		tr:Play(0.12)
		playing = tr
		task.delay(1.8, function() if playing == tr then tr:Stop(0.25) playing = nil end end) -- the clips loop for some rigs: cut them short
	end
	E.vmHook.emote = emote
	R.Fx.OnClientEvent:Connect(function(kind)
		local e = ON_FX[kind]
		if not e then return end
		emote(e)
		if e == "point" and kind ~= "openQuests" then sfx("error") end -- not enough coins or ore: a soft no
		local h = E.hrp()
		if h and e == "cheer" and burst then burst(h.Position + Vector3.new(0, 4.5, 0), Vector3.yAxis, E.GOLD, 14) end -- a little confetti over the head
	end)

	-- the Lost Lamplighters: a lantern found (the server pays), and the murals' one-line captions (client only)
	local GRAN = { "Gran: \"Fenn's lantern! He always walked in front.\"", "Gran: \"That one was Odda's. She sang the whole way down.\"", "Gran: \"The captain's lantern... so they did reach the bottom.\"" }
	local MURAL = { "The Lamplighters march down, lanterns held high.", "Something dark rises from below.", "They stayed, to keep the great light alive." }
	R.Fx.OnClientEvent:Connect(function(kind, i, n, gems)
		if kind == "lantern" then
			sfx("claim")
			emote("cheer")
			E.toast("LOST LANTERN " .. n .. " / " .. #GRAN .. "   +" .. gems .. " GEMS", E.GOLD, true)
			task.delay(1.4, function() E.toast(GRAN[i] or GRAN[1], E.GOLD, false) end)
		elseif kind == "lanternHave" then
			E.toast("You already carried this lantern home.", E.GOLD, false)
		end
	end)
	game:GetService("ProximityPromptService").PromptTriggered:Connect(function(prompt)
		local m = prompt:GetAttribute("Mural")
		if m then
			sfx("pluck", 0.8)
			E.toast(MURAL[m] or MURAL[1], E.GOLD, false)
		end
	end)

	-- the Lantern Ring by the trophy hall: the lanterns this player has carried home burn, the others hang dark
	local mine = {}
	local function lightRing(pop)
		local hub = workspace:FindFirstChild("Hub")
		for _, d in hub and hub:GetDescendants() or {} do
			local k = d:GetAttribute("Ring")
			if k then
				local on = mine[tostring(k)] == true
				local l = d:FindFirstChildOfClass("PointLight")
				local was = l and l.Enabled
				d.Material, d.Color = on and Enum.Material.Neon or Enum.Material.SmoothPlastic, on and Color3.fromRGB(255, 206, 130) or Color3.fromRGB(60, 54, 70)
				if l then l.Enabled, l.Range, l.Brightness = on, 26, 1.2 end
				if on and not was and pop and burst then burst(d.Position, Vector3.yAxis, E.GOLD, 12) end
			end
		end
	end
	R.State.OnClientEvent:Connect(function(st)
		if type(st) ~= "table" or type(st.lanterns) ~= "table" then return end
		local n, had = 0, 0
		for _ in mine do had += 1 end
		for _ in st.lanterns do n += 1 end
		mine = st.lanterns
		lightRing(n > had)
	end)
	task.delay(6, lightRing) -- the hub may still be streaming in at the first state
	game:GetService("ProximityPromptService").PromptTriggered:Connect(function(prompt)
		if prompt.Parent and prompt.Parent:GetAttribute("Station") == "ring" then
			local n = 0
			for _ in mine do n += 1 end
			sfx("pluck", 0.9)
			E.toast(n == 0 and "The Lantern Ring. Lost lanterns from the mine hang here." or (n .. " / " .. #GRAN .. " lost lanterns are home."), E.GOLD, false)
		end
	end)

	-- walking dust
	local dust, hum
	local function dress(ch)
		local root = ch:WaitForChild("HumanoidRootPart", 10)
		hum = ch:WaitForChild("Humanoid", 10)
		if not root or not hum then return end
		local at = Instance.new("Attachment")
		at.Name, at.Position = "FootDust", Vector3.new(0, -(root.Size.Y / 2 + hum.HipHeight) + 0.2, 0.4)
		at.Parent = root
		dust = Instance.new("ParticleEmitter")
		dust.Texture = "rbxasset://textures/particles/smoke_main.dds"
		dust.Color = ColorSequence.new(Color3.fromRGB(214, 204, 232))
		dust.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1.3) })
		dust.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(1, 1) })
		dust.Lifetime, dust.Speed, dust.Rate, dust.SpreadAngle = NumberRange.new(0.35, 0.6), NumberRange.new(0.6, 1.6), 0, Vector2.new(60, 60)
		dust.EmissionDirection, dust.Acceleration, dust.LightInfluence, dust.Rotation = Enum.NormalId.Back, Vector3.new(0, 1.5, 0), 1, NumberRange.new(0, 360)
		dust.Parent = at
		hum.StateChanged:Connect(function(_, new)
			if new == Enum.HumanoidStateType.Landed and dust.Parent then
				sfx("land")
				if not calm then dust:Emit(8) end
			end
		end)
	end
	if plr.Character then task.spawn(dress, plr.Character) end
	plr.CharacterAdded:Connect(dress)

	-- egg hearts
	local hearts, nextScan, nextStep = {}, 0, 0
	RunService.Heartbeat:Connect(function()
		local now = os.clock()
		if dust and dust.Parent and hum then
			local walking = hum.MoveDirection.Magnitude > 0.1 and hum.FloorMaterial ~= Enum.Material.Air and not plr:GetAttribute("Seated")
			dust.Rate = (walking and not calm) and 9 or 0
			if walking and now >= nextStep then -- soft footsteps, in time with the stride
				nextStep = now + 5 / math.max(hum.WalkSpeed, 8)
				sfx("step")
			end
		end
		if calm or not plr:GetAttribute("InCave") then return end
		if now >= nextScan then
			nextScan = now + 5
			table.clear(hearts)
			local caves = workspace:FindFirstChild("Caves")
			for _, d in caves and caves:GetDescendants() or {} do
				if d.Name == "EggCore" and d:IsA("BasePart") then
					local base = d:GetAttribute("Base") or d.Size
					d:SetAttribute("Base", base)
					table.insert(hearts, { p = d, base = base })
				end
			end
		end
		local h = E.hrp()
		if not h then return end
		for i, e in hearts do
			if e.p.Parent then
				local near = math.clamp(1 - (e.p.Position - h.Position).Magnitude / 30, 0, 1)
				local beat = math.max(0, math.sin(now * (2.5 + near * 6) + i)) ^ 4 -- a heartbeat: a short swell, a rest
				e.p.Size = e.base * (1 + beat * (0.12 + near * 0.3))
			end
		end
	end)
end

return M
