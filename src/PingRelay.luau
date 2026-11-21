-- PingRelay (ServerScriptService.PingRelay), started by PixelServer. Relays a cave callout (Shared.Ping) to the miners
-- nearby. The server checks what a client could fake: the sender is in the caves, the spot is a real position within
-- reach of the sender, the kind is one of three words, and at most one ping every 2 seconds per player. No free text
-- travels; the receiver shows the sender's name from the Player object.
local Players = game:GetService("Players")

local M = {}
local KINDS = { ore = true, gloom = true, here = true, camp = true, help = true } -- directive v13: CAMP and HELP join (coop01)
local REACH, HEAR, EVERY = 160, 320, 2

function M.init(ctx)
	local remote = ctx.remote("Ping")
	local last = {}
	remote.OnServerEvent:Connect(function(plr, pos, kind)
		if typeof(pos) ~= "Vector3" or pos ~= pos or type(kind) ~= "string" or not KINDS[kind] then return end
		local hrp = ctx.hrpOf(plr)
		if not hrp or not plr:GetAttribute("InCave") or (pos - hrp.Position).Magnitude > REACH then return end
		local now = os.clock()
		if now - (last[plr] or 0) < EVERY then return end
		last[plr] = now
		for _, other in Players:GetPlayers() do
			local oh = ctx.hrpOf(other)
			if oh and other:GetAttribute("InCave") and (oh.Position - pos).Magnitude <= HEAR then
				ctx.fx:FireClient(other, "ping", pos, kind, plr.Name)
			end
		end
	end)
	-- directive v13: a rare find calls itself out: the server relays a RARE ping from the deposit to the miners nearby (no input)
	M.auto = function(plr, pos)
		if typeof(pos) ~= "Vector3" then return end
		for _, other in Players:GetPlayers() do
			local oh = ctx.hrpOf(other)
			if oh and other:GetAttribute("InCave") and (oh.Position - pos).Magnitude <= HEAR then
				ctx.fx:FireClient(other, "ping", pos, "rare", plr.Name)
			end
		end
	end
	if game:GetService("RunService"):IsStudio() then -- test hook (spike/coop_test.py): workspace attribute DevRarePing calls the first player's rare find
		workspace:GetAttributeChangedSignal("DevRarePing"):Connect(function()
			local p = workspace:GetAttribute("DevRarePing") and Players:GetPlayers()[1]
			local h = p and ctx.hrpOf(p)
			if h then M.auto(p, h.Position) end
		end)
	end
	-- the pickaxe clink (directive v13, Deep Rock's "Rock and Stone"): a salute anyone nearby sees; two miners within 18 studs
	-- who clink within 2.5 s of each other both get the warm pair bonus (Shared.Clink: +2 s of torch, a cheer from the pets).
	-- 15 s between clinks per player; nothing is paid.
	local clinkR = ctx.remote("Clink")
	local lastC, coolC = {}, {}
	clinkR.OnServerEvent:Connect(function(plr)
		local hrp = ctx.hrpOf(plr)
		if not hrp then return end
		local now = os.clock()
		if now < (coolC[plr] or 0) then return end
		coolC[plr] = now + 15
		lastC[plr] = now
		for _, other in Players:GetPlayers() do
			local oh = ctx.hrpOf(other)
			if oh and (oh.Position - hrp.Position).Magnitude < 70 then ctx.fx:FireClient(other, "clink", plr.UserId, hrp.Position) end
		end
		for other, t in lastC do
			local oh = other ~= plr and other.Parent and ctx.hrpOf(other)
			if oh and now - t <= 2.5 and (oh.Position - hrp.Position).Magnitude <= 18 then
				lastC[other], lastC[plr] = nil, nil -- one pair per clink
				if ctx.torch then ctx.torch(plr, 2) ctx.torch(other, 2) end -- the server's torch clock (Gloom.slow): +2 s each (Codex review 2026-11-20)
				ctx.fx:FireClient(plr, "clinkPair", other.Name)
				ctx.fx:FireClient(other, "clinkPair", plr.Name)
				break
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(plr) last[plr] = nil lastC[plr] = nil coolC[plr] = nil end)
end

return M
