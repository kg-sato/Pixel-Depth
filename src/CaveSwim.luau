-- CaveSwim (ReplicatedStorage.Shared.CaveSwim): swimming in the grotto lake with an air bar (feedback batch phase 4, i58).
-- Client only; the server decides the penalty. The lake is a Glass slab (Caves.Grotto.Water) over a basin, not Terrain water, so
-- swimming is ours: in the water a VectorForce cancels most of gravity, W swims where the camera looks (up and down too), Space
-- rises, idle sinks slowly. With the head under the surface the air bar drains (C.SWIM.air seconds); at the surface it refills.
-- Out of air you pass out: the client asks the server ("drown"), which checks you are in the lake, takes 25% of the unbanked ore
-- and wakes you at Camp 1. Under the surface the screen turns teal.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local C = require(script.Parent.Config)

local M = {}
local S = C.SWIM
local INK, CREAM, SKY, PINK = Color3.fromRGB(62, 42, 86), Color3.fromRGB(255, 250, 243), Color3.fromRGB(142, 200, 255), Color3.fromRGB(255, 157, 176)

-- where a point is relative to the lake: inside its footprint and how far below the surface
local function lakeOf(water, pos)
	local p = water.CFrame:PointToObjectSpace(pos)
	local inside = math.abs(p.X) < water.Size.X / 2 and math.abs(p.Z) < water.Size.Z / 2
	return inside, water.Position.Y + water.Size.Y / 2
end
M.lakeOf = lakeOf

-- opt: { water = the lake Part, gui = a ScreenGui for the air bar, drown = fn() (asks the server), sfx = fn(name, pitch),
--        active = fn() -> bool (false while a cutscene or minigame owns the player) }
-- returns a stop function
function M.start(opt)
	local plr = Players.LocalPlayer
	local cam = workspace.CurrentCamera
	local sfx = opt.sfx or function() end
	local air, swimming, under, passedOut = S.air, false, false, false
	local force, att, savedWalk

	-- the air bar: a soft pill with a bubble icon and a fill that turns pink when low
	local bar = Instance.new("Frame")
	bar.Name, bar.Size, bar.Position, bar.AnchorPoint = "AirBar", UDim2.fromScale(0.22, 0.035), UDim2.fromScale(0.5, 0.8), Vector2.new(0.5, 0.5)
	bar.BackgroundColor3, bar.Visible, bar.BorderSizePixel = CREAM, false, 0
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = bar
	local st = Instance.new("UIStroke")
	st.Color, st.Thickness = INK, 3
	st.Parent = bar
	local fill = Instance.new("Frame")
	fill.Size, fill.BackgroundColor3, fill.BorderSizePixel = UDim2.fromScale(1, 1), SKY, 0
	corner:Clone().Parent = fill
	fill.Parent = bar
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency, label.Font, label.TextScaled, label.Text, label.TextColor3 = 1, Enum.Font.FredokaOne, true, "AIR", INK
	label.Size, label.Position, label.AnchorPoint, label.ZIndex = UDim2.fromScale(0.9, 0.8), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5), 2
	label.Parent = bar
	local scale = Instance.new("UIScale")
	scale.Parent = bar
	bar.Parent = opt.gui
	local tint = Instance.new("Frame") -- under the surface the world turns teal
	tint.Name, tint.Size, tint.BackgroundColor3, tint.BackgroundTransparency, tint.BorderSizePixel = "Underwater", UDim2.fromScale(1, 1), Color3.fromRGB(40, 150, 170), 1, 0
	tint.ZIndex = 0
	tint.Parent = opt.gui

	local function setSwim(on, hrp, hum)
		if on == swimming then return end
		swimming = on
		if on then
			att = Instance.new("Attachment")
			att.Name = "SwimAtt"
			att.Parent = hrp
			force = Instance.new("VectorForce")
			force.Name, force.Attachment0, force.RelativeTo, force.ApplyAtCenterOfMass = "SwimLift", att, Enum.ActuatorRelativeTo.World, true
			force.Parent = hrp
			savedWalk = hum.WalkSpeed
			hum.WalkSpeed = S.speed
			sfx("swing", 0.5)
		else
			if force then force:Destroy() force = nil end
			if att then att:Destroy() att = nil end
			if savedWalk and hum then hum.WalkSpeed = savedWalk end
			savedWalk = nil
		end
	end

	local conn = RunService.Heartbeat:Connect(function(dt)
		local char = plr.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local head = char and char:FindFirstChild("Head")
		local water = opt.water
		if not hrp or not hum or not head or not water or not water.Parent or (opt.active and not opt.active()) or hrp.Anchored then
			setSwim(false, hrp, hum)
			bar.Visible, tint.BackgroundTransparency = false, 1
			return
		end
		local inside, surf = lakeOf(water, hrp.Position)
		local wet = swimming and hrp.Position.Y < surf + 0.3 or hrp.Position.Y < surf - 0.6 -- in deeper than the hips; out once above the surface
		setSwim(inside and wet and not passedOut, hrp, hum)
		under = inside and head.Position.Y < surf - 0.2
		local camUnder = select(1, lakeOf(water, cam.CFrame.Position)) and cam.CFrame.Position.Y < surf
		tint.BackgroundTransparency = camUnder and 0.72 or 1
		if swimming then
			force.Force = Vector3.new(0, hrp.AssemblyMass * workspace.Gravity * 0.98, 0)
			local v = hrp.AssemblyLinearVelocity
			local nearTop = head.Position.Y > surf - 1.6
			local float = (surf + 0.9 - head.Position.Y) * 4 -- a spring that holds the eyes just above the water
			local wantY
			if UIS:IsKeyDown(Enum.KeyCode.Space) or UIS:IsGamepadButtonDown(Enum.UserInputType.Gamepad1, Enum.KeyCode.ButtonA) or hum.Jump then
				wantY = nearTop and math.min(S.rise, float + 2) or S.rise
			elseif hum.MoveDirection.Magnitude > 0.1 then
				local y = cam.CFrame.LookVector.Y * S.speed
				wantY = (nearTop and y > -2) and float or y -- at the surface you paddle along it unless you look down to dive
			else
				wantY = nearTop and float or -S.sink
			end
			hrp.AssemblyLinearVelocity = Vector3.new(v.X, v.Y + (wantY - v.Y) * math.min(1, dt * 6), v.Z)
		end
		-- air: drains with the head under, refills fast at the surface
		if under and not passedOut then
			air = math.max(0, air - dt)
		else
			air = math.min(S.air, air + dt * S.air / S.refill)
		end
		bar.Visible = under or air < S.air - 0.05
		local k = air / S.air
		fill.Size = UDim2.fromScale(k, 1)
		fill.BackgroundColor3 = k < 0.3 and PINK or SKY
		scale.Scale = k < 0.3 and 1 + 0.06 * math.sin(os.clock() * 12) or 1
		if air <= 0 and not passedOut then
			passedOut = true
			setSwim(false, hrp, hum)
			sfx("breakRock", 0.5)
			if opt.drown then opt.drown() end
			task.delay(3, function()
				passedOut = false
				air = S.air
			end)
		end
	end)
	return function()
		conn:Disconnect()
		local char = plr.Character
		setSwim(false, char and char:FindFirstChild("HumanoidRootPart"), char and char:FindFirstChildOfClass("Humanoid"))
		bar:Destroy()
		tint:Destroy()
	end
end

return M
