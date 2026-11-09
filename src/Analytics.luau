-- Analytics (ServerScriptService.Analytics): AnalyticsService events for the launch kit (roadmap phase 11).
-- Server only; every call is protected so analytics can never break a grant or a save.
-- - Onboarding funnel (once per player, flags saved in tips): 1 Joined, 2 RodeDown, 3 FirstDeposit, 4 FirstBank,
--   5 FirstPickaxe, 6 Escaped, 7 FirstUpgrade.
-- - Economy: Coins and Gems, sources and sinks with a SKU, logged after the change with the balance it left.
-- - Custom: GloomCatch, GloomRescue, Drowned, EscapeSeconds, DepositGrade.
local AnalyticsService = game:GetService("AnalyticsService")
local M = {}

local STEPS = { "Joined", "RodeDown", "FirstDeposit", "FirstBank", "FirstPickaxe", "Escaped", "FirstUpgrade" }
local INDEX = {}
for i, n in STEPS do INDEX[n] = i end

function M.step(s, name) -- an onboarding step, once per player (s.tips is saved)
	local i = INDEX[name]
	if not i or not s or not s.tips or s.tips["ob" .. i] then return end
	s.tips["ob" .. i] = true
	pcall(function() AnalyticsService:LogOnboardingFunnelStepEvent(s.player, i, name) end)
end

function M.earn(s, currency, amount, balance, sku, kind) -- a source (coins or gems in)
	if not s or not amount or amount <= 0 then return end
	pcall(function()
		AnalyticsService:LogEconomyEvent(s.player, Enum.AnalyticsEconomyFlowType.Source, currency, amount, balance,
			(kind or Enum.AnalyticsEconomyTransactionType.Gameplay).Name, sku)
	end)
end

function M.spend(s, currency, amount, balance, sku, kind) -- a sink (coins or gems out)
	if not s or not amount or amount <= 0 then return end
	pcall(function()
		AnalyticsService:LogEconomyEvent(s.player, Enum.AnalyticsEconomyFlowType.Sink, currency, amount, balance,
			(kind or Enum.AnalyticsEconomyTransactionType.Shop).Name, sku)
	end)
end

function M.event(s, name, value)
	if not s then return end
	pcall(function() AnalyticsService:LogCustomEvent(s.player, name, value or 1) end)
end

M.IAP = Enum.AnalyticsEconomyTransactionType.IAP
M.GAMEPLAY = Enum.AnalyticsEconomyTransactionType.Gameplay
M.SHOP = Enum.AnalyticsEconomyTransactionType.Shop
return M
