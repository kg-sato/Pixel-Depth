-- Charms (ReplicatedStorage.Shared.Charms), started by PixelClient: the client side of the forge's charms (C.CHARMS; bought in
-- the forge's CHARMS tab, owned for good, decided by the server).
--   * Ore Magnet: the deposits' Extract prompts reach twice as far (the server allows the same distance)
--   * Ore Courier: a toast when the server has sent a full bag to the bank, with the ore it kept as its fee
-- The server marks what the player owns with the player attributes Charm_<id>.
local M = {}

function M.start(E)
	local C, plr = E.C, E.plr
	if not C.CHARMS_ON then return end
	local reach = C.DEPOSIT.reach
	local function widen()
		local caves = workspace:FindFirstChild("Caves")
		local deps = caves and caves:FindFirstChild("Deposits")
		local k = plr:GetAttribute("Charm_magnet") and 2 or 1
		for _, d in deps and deps:GetDescendants() or {} do
			if d:IsA("ProximityPrompt") and d.ActionText == "Extract" then d.MaxActivationDistance = reach * k end
		end
	end
	plr:GetAttributeChangedSignal("Charm_magnet"):Connect(widen)
	plr:GetAttributeChangedSignal("InCave"):Connect(function() task.delay(1, widen) end) -- deposits stream in with the caves
	task.delay(5, widen)
	game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Fx").OnClientEvent:Connect(function(kind, lost)
		if kind == "courier" then
			E.toast("ORE COURIER: BAG SENT TO THE BANK" .. ((lost or 0) > 0 and (" (-" .. lost .. " ORE FEE)") or ""), E.MINT)
			E.sfx("coin", 1.2)
		end
	end)
end

return M
