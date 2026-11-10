-- Temporary spectator camera for recordings (Client, run through: python spike/night.py lua Client @spike/spectator_cam.luau).
-- In the mine/cave: over-the-shoulder chase view. Translates the first-person camera back and up (rotation kept, so the
-- first-person camera script's look vector is unchanged), shows the local character, hides the first-person hands and torch.
-- In the minecart ride down and the escape ride up (workspace.MinecartRide / MinecartEscape, scripted cameras): pulls their
-- camera back and up too and shows the seated rider, so the cart and rider are in frame instead of the cart's rim.
-- Off again: night.py lua Client "game:GetService('RunService'):UnbindFromRenderStep('SpecCam')"
local RunService = game:GetService("RunService")
local plr = game.Players.LocalPlayer
local cam = workspace.CurrentCamera
local BACK, UP, SIDE, MARGIN = 11, 3.5, 1.2, 0.6
local RBACK, RUP = 9, 2.4 -- rides: the tunnel is narrow
RunService:UnbindFromRenderStep("SpecCam")
local rp = RaycastParams.new()
rp.FilterType = Enum.RaycastFilterType.Exclude
local function pull(origin, want, ignore)
	rp.FilterDescendantsInstances = ignore
	local dir = want - origin
	local hit = workspace:Raycast(origin, dir, rp)
	if hit then return origin + dir.Unit * math.max(1, (hit.Position - origin).Magnitude - MARGIN) end
	return want
end
RunService:BindToRenderStep("SpecCam", Enum.RenderPriority.Last.Value + 1, function()
	local char = plr.Character
	if not char then return end
	local base = cam.CFrame
	local ride = workspace:FindFirstChild("MinecartEscape") or workspace:FindFirstChild("MinecartRide")
	if ride then
		local ignore = { cam, char }
		for _, m in ride:GetChildren() do
			if m:IsA("Model") and (m.Name == "HubCart" or m:FindFirstChildOfClass("Humanoid")) then
				table.insert(ignore, m)
				if m:FindFirstChildOfClass("Humanoid") then
					for _, d in m:GetDescendants() do
						if d:IsA("BasePart") or d:IsA("Decal") then d.LocalTransparencyModifier = 0 end
					end
				end
			end
		end
		local focus = base.Position + base.LookVector * 3
		cam.CFrame = base.Rotation + pull(focus, focus - base.LookVector * RBACK + Vector3.new(0, RUP, 0), ignore)
		return
	end
	if not (plr:GetAttribute("InMine") or plr:GetAttribute("InCave")) then return end
	local head = char:FindFirstChild("Head")
	local origin = head and head.Position or base.Position
	local want = base.Position - base.LookVector * BACK + Vector3.new(0, UP, 0) + base.RightVector * SIDE
	cam.CFrame = base.Rotation + pull(origin, want, { char, cam })
	for _, d in char:GetDescendants() do
		if d:IsA("BasePart") or d:IsA("Decal") then d.LocalTransparencyModifier = 0 end
	end
	for _, d in cam:GetDescendants() do -- first-person hands and torch clone
		if d:IsA("BasePart") then d.LocalTransparencyModifier = 1 end
	end
end)
return "spectator cam bound"
