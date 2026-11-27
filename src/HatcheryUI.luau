-- HatcheryUI (ReplicatedStorage.Shared.HatcheryUI), started by PixelClient. Town overhaul 2026-11-27 (vault Briefs/Town and Mine
-- Map Overhaul 1.2, one station = one job): the egg incubator had three F prompts at once (odds on the sign post, hatch on the
-- base, buy at Maribel). Its one prompt now opens this panel: BUY EGG, ODDS and HATCH. The server checks the distance to the
-- hatchery again (remote Hatchery) and runs the same buyEgg and hatch code as the old prompts. The panel is one of the menus,
-- so it stands in the world (Shared.SpatialPanels).
local M = {}

function M.start(E)
	local R, C = E.R, E.C
	local HatchR = R:WaitForChild("Hatchery", 30)
	if not HatchR then return end
	local win = E.panel(E.gui, E.S(640, 300), E.S(640, 330), Vector2.new(0.5, 0.5), "panel")
	E.fit(win, 640, 300)
	win.Name, win.Visible = "HatcheryUI", false
	if E.addModal then E.addModal(win) end
	win.ClipsDescendants = true
	local title = E.text(win, "EGG HATCHERY", UDim2.fromScale(0.6, 0.13), UDim2.fromScale(0.5, 0.12), Vector2.new(0.5, 0.5), E.WHITE, 700, false)
	title.Font, title.ZIndex = E.HEAD or title.Font, 6
	local close = E.closeButton(win, "HatcheryClose")
	local eggs = 0
	local subs = {}
	local function refresh()
		if subs.HATCH then subs.HATCH.Text = eggs > 0 and (eggs .. (eggs == 1 and " EGG READY" or " EGGS READY")) or (C.EGG_GEMS .. " GEMS AN EGG") end
	end
	R.State.OnClientEvent:Connect(function(st) if type(st) == "table" and st.eggs then eggs = st.eggs refresh() end end)
	local function odds()
		E.closePanel(win)
		local o = E.gui:FindFirstChild("Odds")
		if o and not o.Visible then E.openPanel(o) end
	end
	local defs = {
		{ "BUY EGG", "mint", C.EGG_COINS .. " COINS", "egg", function() HatchR:FireServer("buyEgg") end },
		{ "ODDS", "lilac", "WHAT HATCHES", "dice", odds },
		{ "HATCH", "pink", "", "star", function() HatchR:FireServer("hatch") E.closePanel(win) end },
	}
	for i, d in defs do
		local x = 0.05 + (i - 1) * 0.31
		local b = E.button(win, d[1], UDim2.fromScale(0.28, 0.4), UDim2.fromScale(x, 0.3), nil, d[2], E.ICON[d[4]] and d[4] or nil)
		b.Name, b.ZIndex = "Hatch" .. d[1]:gsub(" ", ""), 6
		local sub = E.text(win, d[3], UDim2.fromScale(0.28, 0.1), UDim2.fromScale(x, 0.76), nil, E.WHITE, 700, false)
		sub.ZIndex = 6
		local cap = Instance.new("UITextSizeConstraint")
		cap.MinTextSize, cap.MaxTextSize = 12, 28
		cap.Parent = sub
		subs[d[1]] = sub
		b.Activated:Connect(d[5])
	end
	refresh()
	close.Activated:Connect(function() E.closePanel(win) end)
	R.Fx.OnClientEvent:Connect(function(kind) if kind == "openHatchery" and not win.Visible then refresh() E.openPanel(win) end end)
	E.vmHook.hatchery = function() if not win.Visible then refresh() E.openPanel(win) end end
	E.plr:GetAttributeChangedSignal("DevHatchery"):Connect(function() -- Studio test hook: "open" the panel, "odds" its ODDS button
		local v = E.plr:GetAttribute("DevHatchery")
		if v == "open" then E.vmHook.hatchery() elseif v == "odds" then odds() end
	end)
end

return M
