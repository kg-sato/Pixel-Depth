-- SoulTree (ServerScriptService.SoulTree), started by PixelServer. Metaprogression at the campfire (brief: vault
-- Projects/Pixel-_/Briefs/Soul Tree (2026-11-11).md): gloomlings flattened by a flare drop Gloom Shards, and at Camp 1's
-- campfire the shards buy ranks in three nodes (C.SOUL_TREE.nodes) that ServerScriptService.Gloom reads through
-- M.rank: Thick Hide (softer hits), Spare Flare (more flares per dive), Long Shield (a longer golden shield).
-- The server owns everything: shards are earned here (capped per hour), a buy is checked for the node, the rank, the
-- cost and the distance to the campfire prompt.
-- OFF by default (C.SOUL_TREE.on): the feature adds a saved field (profile.Data.soul). While the flag is false the
-- field is never read or written and every rank is 0.
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local C = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))
local T = C.SOUL_TREE

local M = {}
local ctx

function M.clean(d) -- a saved value (any shape) to a safe session value
	local out = { shards = 0, nodes = {} }
	if type(d) == "table" then
		if type(d.shards) == "number" and d.shards == d.shards then out.shards = math.clamp(math.floor(d.shards), 0, 9999) end
		for id, def in T.nodes do
			local r = type(d.nodes) == "table" and d.nodes[id]
			if type(r) == "number" and r == r then out.nodes[id] = math.clamp(math.floor(r), 0, def.max) end
		end
	end
	return out
end

function M.rank(s, id)
	if not T.on or not s or not s.soul then return 0 end
	return s.soul.nodes[id] or 0
end

function M.earn(s, n) -- n gloomlings flattened; at most T.perHour shards an hour
	if not T.on or not ctx or not s or not s.soul or n <= 0 then return end
	-- one saved timestamp holds the whole allowance (Codex review 2026-11-11: a count kept only in the session came back
	-- full after a rejoin): every shard adds 3600 / perHour seconds of debt, and the debt may not pass one hour
	local slice = 3600 / T.perHour
	local debt = ctx.coolLeft(s, "soulDebt")
	n = math.min(n, math.floor((3600 - debt) / slice + 0.001))
	if n <= 0 then return end
	ctx.coolSet(s, "soulDebt", debt + n * slice)
	s.soul.shards += n
	ctx.fx:FireClient(s.player, "soulShard", n, s.soul.shards)
	ctx.sendState(s)
end

function M.init(c)
	ctx = c
	if not T.on then return end
	local remote = c.remote("Soul")
	local last = {}
	remote.OnServerEvent:Connect(function(plr, what, id)
		local s = c.data[plr]
		if not s or not s.soul then return end
		local now = os.clock()
		if now - (last[plr] or 0) < 0.3 then return end
		last[plr] = now
		if what == "sync" then return c.sendState(s) end -- the panel asks for the current numbers when it opens
		if what ~= "buy" or type(id) ~= "string" then return end
		local def = T.nodes[id]
		if not def then return end
		local near = false
		for _, pr in CollectionService:GetTagged("SoulTree") do
			if c.nearPrompt(plr, pr) then near = true break end
		end
		if not near then return end
		local rank = s.soul.nodes[id] or 0
		local cost = def.cost[rank + 1]
		if rank >= def.max or not cost or s.soul.shards < cost then
			c.fx:FireClient(plr, "soulNo", id)
			return
		end
		s.soul.shards -= cost
		s.soul.nodes[id] = rank + 1
		if c.analytics then c.analytics.event(s, "SoulNode", rank + 1) end
		c.sendState(s)
		c.fx:FireClient(plr, "soulBought", id, rank + 1)
	end)
	Players.PlayerRemoving:Connect(function(plr) last[plr] = nil end)
	if game:GetService("RunService"):IsStudio() then -- Studio test hook: player attribute DevSoul = n sets the shards
		local function hook(plr)
			plr:GetAttributeChangedSignal("DevSoulEarn"):Connect(function() -- DevSoulEarn = n: earn n shards through the capped path
				local s, n = c.data[plr], plr:GetAttribute("DevSoulEarn")
				if s and type(n) == "number" then M.earn(s, n) end
			end)
			plr:GetAttributeChangedSignal("DevSoul"):Connect(function()
				local s, n = c.data[plr], plr:GetAttribute("DevSoul")
				if s and s.soul and type(n) == "number" then
					s.soul.shards = math.clamp(math.floor(n), 0, 9999)
					c.sendState(s)
				end
			end)
		end
		Players.PlayerAdded:Connect(hook)
		for _, plr in Players:GetPlayers() do hook(plr) end
	end
end

return M
