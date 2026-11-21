-- FtueGate (ReplicatedStorage.Shared.FtueGate), started by PixelClient. Directive v13 phase 6 (vault Research/Game Design/FTUE,
-- Co-Op Chemistry and Economy Pacing (2026-11-20), section 3.A, ftue01 progressive reveal): until the first upgrade (the Stone
-- Pickaxe) is forged, the secondary HUD stays out of the way: the town minimap, the touch TOOLS button and the tool wheel
-- (E.vmHook.ftueEarly, read by Shared.UtilityWheel). They appear the moment the server's state says the pickaxe is owned.
-- Display only.
local RunService = game:GetService("RunService")
local M = {}

function M.start(E)
	local hook = E.vmHook
	local early = false
	E.R.State.OnClientEvent:Connect(function(s)
		if type(s) == "table" then early = (s.pick or 1) < 2 end
	end)
	RunService:BindToRenderStep("FtueGate", Enum.RenderPriority.Last.Value + 30, function() -- last in the frame: after each widget's own code
		hook.ftueEarly = early
		if not early then return end
		for _, n in { "HubMinimap", "ToolsButton" } do
			local o = E.gui:FindFirstChild(n)
			if o and o.Visible then o.Visible = false end
		end
	end)
end

return M
