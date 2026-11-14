-- Hearth (ReplicatedStorage.Shared.Hearth), started by PixelClient. The hearthstone (Next Systems Plan, phase B, 2026-11-13):
-- the wheel's HOME slot (it replaces WARDROBE in the caves) asks the server for a hold; a mint ring fills for C.HOME.hold
-- seconds under a jelly HOME while you stand still, then the server moves you to the nearest camp landing with nothing lost.
-- Walking away or a busy moment cancels it. The server (ServerScriptService.Travel) keeps the clock of the hold and the
-- cooldown and refuses on a ride, in a minigame, in a boss fight and while a Gloomling holds you. This module only draws.
local RunService = game:GetService("RunService")
local M = {}

function M.start(E)
	local C, plr, hook, new = E.C, E.plr, E.vmHook, E.new
	local R = E.R:WaitForChild("Travel", 10)
	if not R or not C.HOME then return end
	local Radial = require(script.Parent:WaitForChild("Radial"))
	local MINT = Color3.fromRGB(120, 255, 200)
	local box = new("Frame", E.gui, { Name = "Hearth", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.11, 0.11), SizeConstraint = Enum.SizeConstraint.RelativeYY, BackgroundTransparency = 1, Visible = false, ZIndex = 40 })
	local scale = new("UIScale", box, { Scale = 1 })
	local ring = Radial.arc(box, { name = "HoldRing", thick = 0.13, color = MINT, track = Color3.fromRGB(30, 21, 58), trackTransparency = 0.25, z = 41, value = 0 })
	local label = E.text(box, "HOME", UDim2.fromScale(2.4, 0.42), UDim2.fromScale(0.5, 1.25), Vector2.new(0.5, 0.5), MINT) -- round the crosshair; the label ends over the toast lane (0.655)
	label.Name, label.Font, label.ZIndex = "Label", E.HEAD or label.Font, 41
	local flash = new("Frame", E.top or E.gui, { Name = "HearthFlash", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(200, 255, 232), BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false, ZIndex = 90 })
	local coolUntil, hold = 0, nil -- hold = { t0, secs, p }

	local function stop(tell)
		if not hold then return end
		hold = nil
		box.Visible = false
		if tell then R:FireServer("homeStop") end
	end
	hook.home = function()
		if hold then return end
		R:FireServer("home")
	end
	hook.homeWhy = function()
		local left = coolUntil - os.clock()
		return left > 0 and string.format("%d:%02d", left // 60, left % 60) or nil
	end

	E.R.Fx.OnClientEvent:Connect(function(kind, what, a)
		if kind ~= "home" or plr:GetAttribute("DevRawHearth") then return end -- test hook: spike/travel_test.py sends every message itself
		if what == "go" then
			local h = E.hrp()
			hold = { t0 = os.clock(), secs = a, p = h and h.Position }
			ring.set(0)
			scale.Scale = 0.6
			box.Visible = true
			E.tween(scale, 0.25, { Scale = 1 }, Enum.EasingStyle.Back)
			E.sfx("open", 1.4)
		elseif what == "done" then
			stop(false)
			coolUntil = os.clock() + a
			flash.BackgroundTransparency, flash.Visible = 0.1, true
			E.tween(flash, 0.9, { BackgroundTransparency = 1 })
			task.delay(0.95, function() flash.Visible = false end)
			E.sfx("land", 0.8)
			E.toast("HOME SAFE", MINT, true)
		elseif what == "no" then
			stop(false)
			if type(a) == "number" then
				coolUntil = os.clock() + a
				E.toast(string.format("HOME READY IN %d:%02d", a // 60, a % 60), MINT)
			else
				E.toast(string.upper(tostring(a)), MINT)
			end
		end
	end)
	RunService.RenderStepped:Connect(function()
		if not hold then return end
		local h = E.hrp()
		local k = (os.clock() - hold.t0) / hold.secs
		if not h or not hold.p or (h.Position - hold.p).Magnitude > C.HOME.still - 2 or not plr:GetAttribute("InCave") or plr:GetAttribute("GrabbedUntil") or E.cave.mgBusy then
			stop(true)
			E.toast("HOME CANCELLED", MINT)
			return
		end
		ring.set(math.min(k, 1))
		if k >= 1 then
			hold = nil -- the ring stays full until the server answers
			R:FireServer("homeEnd")
			task.delay(1.5, function() if not hold then box.Visible = false end end)
		end
	end)
end

return M
