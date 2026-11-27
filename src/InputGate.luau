-- InputGate (ReplicatedStorage.Shared.InputGate): the first cave tool keys on Roblox's Input Action System (directive v13
-- phase 1, vault Research/Roblox Engine/First-Person Feel, Mobile Touch and Cross-Tier Lighting (2026-11-20) section 3).
-- A Gameplay InputContext (priority 1000) holds the actions Flare (R, ButtonY), Sonar (T) and Ping (Z); a Modal InputContext
-- (priority 2000, Sink) binds the same keys and is enabled while a panel, the tool wheel or a minigame is up, so a key pressed
-- behind an open menu never throws a flare. Modules call M.on(action, fn); where the engine has no InputContext the call
-- returns false and the module keeps its own UserInputService handler.
local UIS = game:GetService("UserInputService")
local M = { ready = false }
local actions = {}

local BIND = {
	Flare = { Enum.KeyCode.R, Enum.KeyCode.ButtonY },
	Sonar = { Enum.KeyCode.T },
	Ping = { Enum.KeyCode.Z },
}

local function context(name, priority, sink, parent)
	local c = Instance.new("InputContext")
	c.Name, c.Priority, c.Sink = name, priority, sink
	for a, keys in BIND do
		local act = Instance.new("InputAction")
		act.Name = a
		pcall(function() act.Type = Enum.InputActionType.Bool end)
		for _, k in keys do
			local b = Instance.new("InputBinding")
			b.KeyCode = k
			b.Parent = act
		end
		act.Parent = c
	end
	c.Parent = parent
	return c
end

function M.init(plr)
	if M.ready then return true end
	local ok = pcall(function()
		local pg = plr:WaitForChild("PlayerGui")
		local folder = Instance.new("ScreenGui") -- not a Folder: a respawn cleared PlayerGui's folder and R, T and Z went dead (playtest 2026-11-27)
		folder.Name, folder.ResetOnSpawn = "PixelInput", false
		folder.Parent = pg
		M.gameplay = context("Gameplay", 1000, false, folder)
		M.modal = context("Modal", 2000, true, folder)
		M.modal.Enabled = false
		for _, act in M.gameplay:GetChildren() do
			if act:IsA("InputAction") then
				actions[act.Name] = act
			end
		end
	end)
	M.ready = ok
	return ok
end

function M.on(name, fn) -- true: the action is wired through the Gameplay context
	local act = M.ready and actions[name]
	if not act then return false end
	act.Pressed:Connect(function()
		if UIS:GetFocusedTextBox() then return end -- typing in chat is not a flare
		fn()
	end)
	return true
end

function M.setModal(on)
	if M.modal and M.modal.Enabled ~= on then M.modal.Enabled = on end
end

function M.start(E) -- a heartbeat keeps the Modal context in step with the open panels, the tool wheel and minigames
	if not M.init(E.plr) then return end
	local hook = E.vmHook
	game:GetService("RunService").Heartbeat:Connect(function()
		local m = (E.isBusy and E.isBusy()) or (hook and hook.wheelOpen) or false
		if not m and hook then
			for _, f in hook.modals or {} do
				if f.Visible then m = true break end
			end
		end
		M.setModal(m == true)
	end)
end

return M
