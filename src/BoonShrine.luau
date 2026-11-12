-- BoonShrine (ServerScriptService.BoonShrine), started by PixelServer. Boon shrines (the user's directive v6.0; vault
-- Research/Game Design and Market/Fastest-Growing New Roblox Games (2026-11-11).md, "short-session choices"): the glowing
-- rune of every hidden cave shrine offers a blessing, once per shrine per dive. The server draws two of the three boons
-- in C.BOON, the player picks one, and ServerScriptService.Gloom applies it (a spare flare, a golden shield, or full
-- hearts with a fresh torch). Nothing is saved: a boon lasts for the dive, so there is no new saved field.
-- The server owns it all: the offer is drawn and kept here, and a pick is checked against that offer, the shrine it came
-- from and the distance to its prompt.
local Players = game:GetService("Players")
local C = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))

local M = {}

function M.init(ctx)
	local remote = ctx.remote("Boon")
	local rng = Random.new()
	local last = {}
	local function watch(plr) -- a dive ends when the player leaves the caves: every shrine can bless again next time
		plr:GetAttributeChangedSignal("InCave"):Connect(function()
			local s = ctx.data[plr]
			if s and not plr:GetAttribute("InCave") then s.boons, s.boonOffer = nil, nil end
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, plr in Players:GetPlayers() do watch(plr) end
	Players.PlayerRemoving:Connect(function(plr) last[plr] = nil end)

	game:GetService("ProximityPromptService").PromptTriggered:Connect(function(prompt, plr)
		local id = prompt:GetAttribute("BoonShrine")
		if not id then return end
		local s = ctx.data[plr]
		if not s or not plr:GetAttribute("InCave") or ctx.busy(plr) or not ctx.nearPrompt(plr, prompt) then return end
		s.boons = s.boons or {}
		if s.boons[id] then
			ctx.fx:FireClient(plr, "boonSpent")
			return
		end
		local offer = s.boonOffer
		if not offer or offer.id ~= id then -- the same two until one is taken: praying again does not reroll
			local kinds = table.clone(C.BOON.order)
			table.remove(kinds, rng:NextInteger(1, #kinds))
			offer = { id = id, prompt = prompt, kinds = kinds }
			s.boonOffer = offer
		end
		ctx.fx:FireClient(plr, "boonOffer", offer.kinds[1], offer.kinds[2])
	end)

	remote.OnServerEvent:Connect(function(plr, what, i)
		local s = ctx.data[plr]
		local now = os.clock()
		if not s or now - (last[plr] or 0) < 0.3 then return end
		last[plr] = now
		local offer = s.boonOffer
		if what ~= "pick" or not offer or (i ~= 1 and i ~= 2) then return end
		if not plr:GetAttribute("InCave") or ctx.busy(plr) or not offer.prompt.Parent or not ctx.nearPrompt(plr, offer.prompt) then return end
		local kind = offer.kinds[i]
		if not ctx.apply(plr, kind) then return end
		s.boons = s.boons or {}
		s.boons[offer.id] = true
		s.boonOffer = nil
		if ctx.analytics then ctx.analytics.event(s, "Boon") end
		ctx.fx:FireClient(plr, "boonTaken", kind)
	end)
end

return M
