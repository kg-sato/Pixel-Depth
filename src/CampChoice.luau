-- CampChoice (ReplicatedStorage.Shared.CampChoice), started by PixelClient. Choose your camp at the town cart (Next Systems
-- Plan, phase B, 2026-11-13): a player who has beaten the Root Warden and reached the Clay Caves gets a small panel with two
-- buttons, CAMP 1 and CAMP 2, when they ask for the ride down; everyone else rides to Camp 1 as before. The panel is one of
-- the menus, so it stands in the world (Shared.SpatialPanels). The server checks the unlock again (Surface "down", 2).
local M = {}

function M.start(E)
	local R, hook = E.R, E.vmHook
	local win = E.panel(E.gui, E.S(520, 250), E.S(640, 330), Vector2.new(0.5, 0.5), "panel")
	E.fit(win, 520, 250)
	win.Name, win.Visible = "CampChoice", false
	if E.addModal then E.addModal(win) end
	win.ClipsDescendants = true -- directive v10: the ribbon title hung across the panel's top edge; the title now sits inside
	local title = E.text(win, "RIDE DOWN TO", UDim2.fromScale(0.6, 0.14), UDim2.fromScale(0.5, 0.12), Vector2.new(0.5, 0.5), E.WHITE, 700, false)
	title.Font, title.ZIndex = E.HEAD or title.Font, 6
	local close = E.closeButton(win, "CampChoiceClose")
	local open = false -- the tips of the last state: both gates passed
	R.State.OnClientEvent:Connect(function(st) open = st ~= nil and st.tips ~= nil and st.tips.gate1 == true and st.tips.clay == true end)
	local function go(n)
		E.closePanel(win)
		R.Surface:FireServer("down", n)
	end
	for i, d in { { "CAMP 1", "lilac", "Root Caves", "root" }, { "CAMP 2", "pink", "Clay Caves", "kiln" } } do -- directive v13: Camp 2 wears the kiln, not a sack
		local b = E.button(win, d[1], UDim2.fromScale(0.4, 0.42), UDim2.fromScale(0.07 + (i - 1) * 0.46, 0.27), nil, d[2], E.ICON[d[4]] and d[4] or nil)
		b.Name, b.ZIndex = "Camp" .. i, 6
		local sub = E.text(win, d[3], UDim2.fromScale(0.4, 0.11), UDim2.fromScale(0.07 + (i - 1) * 0.46, 0.74), nil, E.WHITE, 700, false)
		sub.ZIndex = 6
		b.Activated:Connect(function() go(i) end)
	end
	close.Activated:Connect(function() E.closePanel(win) end)
	R.Fx.OnClientEvent:Connect(function(kind) if kind == "campPick" and not win.Visible then E.openPanel(win) end end) -- the cart's own prompt (the server saw both camps open)
	-- PixelClient asks before it sends the ride down: true = the panel took it
	hook.campPick = function()
		if not open or win.Visible then return win.Visible end
		E.openPanel(win)
		return true
	end
end

return M
