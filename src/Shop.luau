-- Shop (ServerScriptService.Shop): gems for Robux (roadmap i74, the user's yes "with full handling", 2026-11-08).
-- Developer Products from C.GEM_PACKS (ids are 0 until the owner creates the products on the Creator Dashboard; a pack with id 0
-- shows "SOON" and can never be bought). One server-owned receipt path: the receipt id and the gems are written to the same
-- ProfileStore document, a duplicate receipt grants nothing, and the receipt is acknowledged only after a save that holds it.
-- Paid random items: gems can roll eggs, so where PolicyService says paid random items are restricted (or the lookup fails)
-- the server refuses gem egg rolls; eggs still come free from the mine and the daily chest, and gems still level pickaxes.
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local PolicyService = game:GetService("PolicyService")
local RS = game:GetService("ReplicatedStorage")
local C = require(RS:WaitForChild("Shared"):WaitForChild("Config"))
local M = {}
local ctx

local byId = {}
for _, p in C.GEM_PACKS do if p.id and p.id > 0 then byId[p.id] = p end end

local function grantOnce(s, purchaseId, gems) -- true once a save holding this receipt is confirmed
	local profile = s.profile
	if not profile or not profile:IsActive() then return false end
	local d = profile.Data
	d.receipts = d.receipts or {}
	if not table.find(d.receipts, purchaseId) then
		while #d.receipts >= 50 do table.remove(d.receipts, 1) end
		table.insert(d.receipts, purchaseId)
		s.gems += gems
		d.gems = s.gems -- the receipt and the gems live in the same document, so they save together
		ctx.sendState(s)
		ctx.fx:FireClient(s.player, "gemsBought", gems)
		local A = require(game:GetService("ServerScriptService"):WaitForChild("Analytics"))
		A.earn(s, "Gems", gems, s.gems, "GemPack_" .. gems, A.IAP)
	end
	local function holds(data) return data and data.receipts and table.find(data.receipts, purchaseId) ~= nil end
	if holds(profile.LastSavedData) then return true end
	local done = false
	local conn = profile.OnAfterSave:Connect(function(last) if holds(last) then done = true end end)
	profile:Save()
	local t0 = os.clock()
	while not done and profile:IsActive() and os.clock() - t0 < 30 do task.wait(0.2) end
	conn:Disconnect()
	return done
end

function M.init(c)
	ctx = c
	MarketplaceService.ProcessReceipt = function(info)
		local plr = Players:GetPlayerByUserId(info.PlayerId)
		local s = plr and ctx.data[plr]
		if not s then return Enum.ProductPurchaseDecision.NotProcessedYet end -- delivered again when they are back
		local pack = byId[info.ProductId]
		if not pack then
			warn("[Shop] unknown product", info.ProductId)
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		local ok, granted = pcall(grantOnce, s, tostring(info.PurchaseId), pack.gems)
		if ok and granted then return Enum.ProductPurchaseDecision.PurchaseGranted end
		if not ok then warn("[Shop] grant failed: " .. tostring(granted)) end
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local function policy(plr)
		local ok, info = pcall(function() return PolicyService:GetPolicyInfoForPlayerAsync(plr) end)
		plr:SetAttribute("PaidRandomRestricted", not ok or info.ArePaidRandomItemsRestricted == true) -- a failed lookup counts as restricted
	end
	Players.PlayerAdded:Connect(policy)
	for _, p in Players:GetPlayers() do task.spawn(policy, p) end
end

-- the hatch station asks before spending gems on an egg roll
function M.gemRollsAllowed(plr) return plr:GetAttribute("PaidRandomRestricted") == false end

return M
