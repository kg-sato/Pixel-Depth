-- Clink (ReplicatedStorage.Shared.Clink), started by PixelClient. Directive v13 phase 6 (vault Research/Game Design/FTUE, Co-Op
-- Chemistry and Economy Pacing (2026-11-20), section 3.C; Deep Rock Galactic's salute): G (or CHEER on the tool wheel in town,
-- or the CLINK thumb button in the caves) raises your pickaxe with an anvil ring and a burst of gold sparks that everyone near
-- you sees. Two miners within 18 studs who clink within 2.5 s of each other get the warm pair bonus: +2 s on the torch, a cheer
-- and their pets hop. Every 15 s at most (the server keeps the clock: ServerScriptService.PingRelay).
-- Also the friend rescue by pickaxe (directive v13): swinging at a grabbed friend within 9 studs (E) frees them (Gloom).
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local M = {}

function M.start(E)
	local R, plr, hook, C = E.R, E.plr, E.vmHook, E.C
	local ClinkR = R:WaitForChild("Clink", 20)
	local StrikeR = R:WaitForChild("GloomStrike", 20)
	local GOLD = Color3.fromRGB(255, 210, 110)
	local readyAt = 0
	local function sparks(pos)
		local p = Instance.new("Part")
		p.Name, p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.Transparency, p.Size = "ClinkSpark", true, false, false, false, 1, Vector3.one
		p.Position = pos
		local e = Instance.new("ParticleEmitter")
		e.Texture, e.LightEmission, e.Color = "rbxasset://textures/particles/sparkles_main.dds", 1, ColorSequence.new(GOLD, Color3.fromRGB(255, 140, 60))
		e.Size, e.Lifetime, e.Speed, e.SpreadAngle = NumberSequence.new(0.45, 0), NumberRange.new(0.5, 0.9), NumberRange.new(6, 12), Vector2.new(60, 60)
		e.Acceleration = Vector3.new(0, -16, 0)
		e.Parent = p
		local l = Instance.new("PointLight")
		l.Color, l.Range, l.Brightness, l.Shadows = GOLD, 12, 1.4, false
		l.Parent = p
		p.Parent = workspace:FindFirstChild("ClientFX") or workspace
		e:Emit(34)
		task.delay(0.25, function() l.Enabled = false end)
		task.delay(1.4, function() p:Destroy() end)
	end
	local function nearForge()
		if plr:GetAttribute("InCave") then return false end
		local hub = workspace:FindFirstChild("Hub")
		local anvil = hub and hub:FindFirstChild("Anvil", true)
		local h = E.hrp and E.hrp()
		return anvil ~= nil and h ~= nil and (anvil.Position - h.Position).Magnitude < 18
	end
	hook.clink = function() -- true when it clinked (G by Bolt's anvil still opens the forge)
		if nearForge() or (E.isBusy and E.isBusy()) or plr:GetAttribute("Seated") then return false end
		if os.clock() < readyAt then
			if E.toast then E.toast("CLINK IN " .. math.ceil(readyAt - os.clock()) .. " S", E.LILAC, false) end
			return true
		end
		readyAt = os.clock() + 15
		if ClinkR then ClinkR:FireServer() end
		if hook.vmClink then hook.vmClink() end
		if hook.emote and not plr:GetAttribute("InCave") then hook.emote("cheer") end
		return true
	end
	E.R.Fx.OnClientEvent:Connect(function(kind, a, b)
		if kind == "clink" then
			sparks((b or Vector3.zero) + Vector3.new(0, 3, 0))
			if hook.caveSound then
				local h = E.hrp and E.hrp()
				local s = hook.caveSound("clink", (h and (h.Position - b).Magnitude < 4) and 0.6 or 0.45)
				if s and h and (h.Position - b).Magnitude >= 4 then -- a friend's clink rings from where they stand
					local at = Instance.new("Part")
					at.Anchored, at.CanCollide, at.CanQuery, at.CanTouch, at.Transparency, at.Size, at.Position = true, false, false, false, 1, Vector3.one, b
					at.Parent = workspace:FindFirstChild("ClientFX") or workspace
					s.Parent = at
					task.delay(3, function() at:Destroy() end)
				end
			elseif E.sfx then E.sfx("clink", 1.2) end
		elseif kind == "clinkPair" then -- the warm pair bonus: +2 s on the torch, a cheer, the pets hop
			-- the +2 s is the server's (PingRelay calls Gloom.slow); the torch follows its RelitAt attribute
			if E.toast then E.toast("CLINK WITH " .. string.upper(tostring(a)) .. "!  +2 S OF TORCH", GOLD, true) end
			if E.sfx then E.sfx("sparkle", 1.3) end
			if hook.petsHop then pcall(hook.petsHop) end
		elseif kind == "saviorBonus" then
			if E.toast then E.toast("SAVED " .. string.upper(tostring(a)) .. "!  +" .. tostring(b) .. " COINS", GOLD, true) end
			if E.sfx then E.sfx("coin", 1.2) end
		end
	end)
	-- the friend rescue by pickaxe: E near a grabbed friend frees them (the server checks the distance and the grab)
	UIS.InputBegan:Connect(function(io, gp)
		if gp or io.KeyCode ~= Enum.KeyCode.E or not StrikeR or not plr:GetAttribute("InCave") then return end
		local h = E.hrp and E.hrp()
		if not h then return end
		for _, o in Players:GetPlayers() do
			local oh = o ~= plr and o.Character and o.Character:FindFirstChild("HumanoidRootPart")
			if oh and o:GetAttribute("GrabbedUntil") and (oh.Position - h.Position).Magnitude <= 9 then
				StrikeR:FireServer(o)
				if hook.vmHold then hook.vmHold(0.05) hook.vmKick(1) end
				break
			end
		end
	end)
end

return M
