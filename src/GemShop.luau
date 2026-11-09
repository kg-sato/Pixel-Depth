-- GemShop (ReplicatedStorage.Shared.GemShop), started by PixelClient: the gem shop opened from the gem pill (roadmap i74).
-- Three Developer Product packs from C.GEM_PACKS; a pack whose product id is 0 (not created yet) shows SOON. The client only
-- prompts; the server's receipt handler (ServerScriptService.Shop) grants the gems. Where paid random items are restricted the
-- footnote says gem egg rolls are off (the server enforces it).
local MarketplaceService = game:GetService("MarketplaceService")
local M = {}

function M.start(E)
	local C, plr, gui, new, S, fit, panel, button, text, icon = E.C, E.plr, E.gui, E.new, E.S, E.fit, E.panel, E.button, E.text, E.icon
	local openPanel, closePanel, closeButton, ribbonTitle, toast, sfx, INK, GOLD = E.openPanel, E.closePanel, E.closeButton, E.ribbonTitle, E.toast, E.sfx, E.INK, E.GOLD
	local shop = panel(gui, S(640, 380), S(640, 340), Vector2.new(0.5, 0.5), "panel")
	fit(shop, 640, 380)
	shop.Name, shop.Visible = "GemShop", false
	ribbonTitle(shop, "GEM SHOP", "ribbonPink", 0.42)
	local close = closeButton(shop, "Close")
	close.Activated:Connect(function() closePanel(shop) end)
	for k, pack in C.GEM_PACKS do
		local x = 0.2 + (k - 1) * 0.3
		local card = panel(shop, UDim2.fromScale(0.27, 0.62), UDim2.fromScale(x, 0.5), Vector2.new(0.5, 0.5), "pill")
		local ic = icon(card, "gem", UDim2.fromScale(0.5, 0.34), UDim2.fromScale(0.5, 0.27), Vector2.new(0.5, 0.5))
		new("UIAspectRatioConstraint", ic, { AspectRatio = 1 })
		text(card, "+" .. pack.gems .. " GEMS", UDim2.fromScale(0.86, 0.14), UDim2.fromScale(0.5, 0.56), Vector2.new(0.5, 0.5), INK, 700, false)
		local ready = pack.id and pack.id > 0
		local b = button(card, ready and ("R$ " .. pack.robux) or "SOON", UDim2.fromScale(0.86, 0.22), UDim2.fromScale(0.5, 0.82), Vector2.new(0.5, 0.5), ready and "mint" or "off")
		b.Activated:Connect(function()
			if not ready then toast("Gem packs are coming soon", INK) return end
			MarketplaceService:PromptProductPurchase(plr, pack.id)
		end)
	end
	local foot = text(shop, "", UDim2.fromScale(0.86, 0.07), UDim2.fromScale(0.5, 0.9), Vector2.new(0.5, 0.5), INK, 500, false)
	local function footnote()
		foot.Text = plr:GetAttribute("PaidRandomRestricted") and "Gems level up your pickaxes. Egg rolls with gems are off where you live."
			or "Gems level up your pickaxes and roll eggs. Egg odds are shown at the incubator."
	end
	plr:GetAttributeChangedSignal("PaidRandomRestricted"):Connect(footnote)
	footnote()
	-- the gem pill opens it
	task.spawn(function()
		local pill = gui:WaitForChild("GemPill", 30)
		if not pill then return end
		local hit = new("TextButton", pill, { Name = "OpenShop", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 10 })
		hit.Activated:Connect(function()
			if shop.Visible then closePanel(shop) else openPanel(shop) sfx("click") end
		end)
	end)
	E.R.Fx.OnClientEvent:Connect(function(kind, gems)
		if kind == "gemsBought" then
			toast("+" .. gems .. " GEMS  -  THANK YOU!", GOLD, true)
			sfx("sparkle", 1.1)
		elseif kind == "gemRollsOff" then
			toast("Egg rolls with gems are off where you live. Eggs still come from the mine!", INK, true)
		end
	end)
end

return M
