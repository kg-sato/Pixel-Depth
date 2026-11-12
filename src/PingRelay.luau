-- PingRelay (ServerScriptService.PingRelay), started by PixelServer. Relays a cave callout (Shared.Ping) to the miners
-- nearby. The server checks what a client could fake: the sender is in the caves, the spot is a real position within
-- reach of the sender, the kind is one of three words, and at most one ping every 2 seconds per player. No free text
-- travels; the receiver shows the sender's name from the Player object.
local Players = game:GetService("Players")

local M = {}
local KINDS = { ore = true, gloom = true, here = true }
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
	Players.PlayerRemoving:Connect(function(plr) last[plr] = nil end)
end

return M
