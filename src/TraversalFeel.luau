-- TraversalFeel (ReplicatedStorage.Shared.TraversalFeel), started by PixelClient. Directive v13 phase 3 (vault Research/Roblox
-- Engine/First-Person Feel, Mobile Touch and Cross-Tier Lighting (2026-11-20), section 1): generous jumps on narrow ledges and
-- laggy phones.
--   * coyote time: a jump pressed up to 0.13 s after walking off an edge still jumps
--   * jump buffer: a jump pressed up to 0.12 s before landing jumps on the landing frame
-- Only the local humanoid's own jump state changes (Roblox already trusts the client with its character's movement); no
-- reward, cooldown or currency is touched. Player attribute DevNoCoyote turns it off for tests.
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local M = {}
local COYOTE, BUFFER = 0.13, 0.12

function M.start(E)
	local plr = E.plr
	local lastGround, jumpedAt, bufferUntil = 0, 0, 0
	local function hum()
		local c = plr.Character
		return c and c:FindFirstChildOfClass("Humanoid")
	end
	local function grounded(h)
		return h.FloorMaterial ~= Enum.Material.Air
	end
	local function canJump(h)
		return h.Health > 0 and h.JumpPower + h.JumpHeight > 0 and h:GetStateEnabled(Enum.HumanoidStateType.Jumping) and not h.Sit
	end
	UIS.JumpRequest:Connect(function()
		if plr:GetAttribute("DevNoCoyote") then return end
		local h = hum()
		if not h or grounded(h) or not canJump(h) then return end
		local now = os.clock()
		if now - lastGround <= COYOTE and now - jumpedAt > 0.3 then -- just off the edge: still a jump
			jumpedAt = now
			h:ChangeState(Enum.HumanoidStateType.Jumping)
		else
			bufferUntil = now + BUFFER -- pressed a moment early: jump on landing
		end
	end)
	local wasGround = true
	RunService.Heartbeat:Connect(function()
		local h = hum()
		if not h then return end
		local g = grounded(h)
		local now = os.clock()
		if g then
			lastGround = now
			if not wasGround and now < bufferUntil and canJump(h) then
				bufferUntil, jumpedAt = 0, now
				h:ChangeState(Enum.HumanoidStateType.Jumping)
			end
		end
		if h:GetState() == Enum.HumanoidStateType.Jumping then jumpedAt = math.max(jumpedAt, now - 0.01) end
		wasGround = g
	end)
end

return M
