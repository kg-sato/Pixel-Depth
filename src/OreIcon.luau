-- OreIcon (ReplicatedStorage.Shared.OreIcon): a small live 3D ore for reward cards. Demo audit 08: the extraction card showed a
-- flat grey circle with a white curl ("2D clipart"). This is a ViewportFrame with a chunky voxel ore cluster in the ore's
-- colour: a rock foot, faceted crystals with lighter caps and a darker shade side, lit from the upper left with a rim light.
-- It turns slowly and bobs while its card is on screen (nothing runs while it is hidden).
local RunService = game:GetService("RunService")
local M = {}

-- parent: a GuiObject; props: Size, Position, AnchorPoint, ZIndex. Returns { frame, set(color) }.
function M.make(parent, props)
	local vf = Instance.new("ViewportFrame")
	vf.Name, vf.BackgroundTransparency = "OreIcon", 1
	vf.Ambient, vf.LightColor, vf.LightDirection = Color3.fromRGB(190, 170, 220), Color3.fromRGB(255, 244, 226), Vector3.new(0.6, -1, -0.5)
	for k, v in props do vf[k] = v end
	local ar = Instance.new("UIAspectRatioConstraint")
	ar.AspectRatio = 1
	ar.Parent = vf
	local world = Instance.new("WorldModel")
	world.Parent = vf
	local model = Instance.new("Model")
	model.Parent = world
	local tinted = {}
	local function block(size, cf, shade, rock)
		local p = Instance.new("Part")
		p.Size, p.CFrame, p.Anchored = size, cf, true
		p.Material, p.TopSurface, p.BottomSurface = Enum.Material.SmoothPlastic, Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.Color = rock and Color3.fromRGB(86, 68, 112):Lerp(Color3.new(0, 0, 0), shade) or Color3.new(1, 1, 1)
		p.Parent = model
		if not rock then table.insert(tinted, { p, shade }) end
		return p
	end
	block(Vector3.new(3.4, 0.06, 3.0), CFrame.new(0.2, 0.02, 0.2), 0.75, true).Transparency = 0.45 -- a soft contact shadow
	-- the rock foot
	block(Vector3.new(2.6, 0.7, 2.2), CFrame.new(0, 0.35, 0), 0, true)
	block(Vector3.new(1.5, 0.5, 1.4), CFrame.new(0.5, 0.85, -0.2) * CFrame.Angles(0, 0.4, 0), 0.15, true)
	-- crystals: each a column with a lighter cap and a small bright glint cube; the tallest in the middle
	for _, c in { { 0, 0, 2.4, 0.9, 0.1, 0.06 }, { -0.85, 0.3, 1.5, 0.7, -0.3, -0.22 }, { 0.8, -0.35, 1.7, 0.75, 0.5, 0.25 }, { 0.15, 0.75, 1.0, 0.6, 0.9, -0.1 }, { -0.4, -0.7, 0.9, 0.55, -0.6, 0.3 } } do
		local base = CFrame.new(c[1], 0.6, c[2]) * CFrame.Angles(c[6], c[5], c[6] * 0.7)
		block(Vector3.new(c[4], c[3], c[4]), base * CFrame.new(0, c[3] / 2, 0), 0)
		block(Vector3.new(c[4] * 0.68, c[4] * 0.5, c[4] * 0.68), base * CFrame.new(0, c[3] + c[4] * 0.2, 0), -0.55) -- the cap, lighter
		block(Vector3.new(c[4] * 0.3, c[4] * 0.3, c[4] * 0.3), base * CFrame.new(0, c[3] + c[4] * 0.55, 0), -0.9).Material = Enum.Material.Neon -- a gleaming tip
		block(Vector3.new(c[4] * 0.3, c[3] * 0.5, c[4] * 0.3), base * CFrame.new(c[4] * 0.38, c[3] * 0.6, c[4] * 0.38), -0.6) -- a specular glint down one edge
		block(Vector3.new(c[4] * 1.04, c[3] * 0.3, c[4] * 1.04), base * CFrame.new(0, c[3] * 0.15, 0), 0.3) -- the shaded root (ambient occlusion)
	end
	model.PrimaryPart = model:FindFirstChildWhichIsA("BasePart")
	local cam = Instance.new("Camera")
	cam.FieldOfView = 34
	cam.CFrame = CFrame.lookAt(Vector3.new(0, 4.6, 7.4), Vector3.new(0, 1.5, 0))
	cam.Parent = vf
	vf.CurrentCamera = cam
	vf.Parent = parent
	local home = model:GetPivot()
	local conn
	local function run()
		if conn then return end
		conn = RunService.RenderStepped:Connect(function()
			if not vf:IsDescendantOf(game) then conn:Disconnect() conn = nil return end
			local p, on = vf, true
			while p and p:IsA("GuiObject") do
				if not p.Visible then on = false break end
				p = p.Parent
			end
			if not on then conn:Disconnect() conn = nil return end
			local t = os.clock()
			model:PivotTo(home * CFrame.new(0, math.sin(t * 2.2) * 0.14, 0) * CFrame.Angles(0, t * 0.9, 0))
		end)
	end
	local api = { frame = vf }
	function api.set(color)
		for _, e in tinted do
			local c = color:Lerp(Color3.fromHSV(select(1, color:ToHSV()), math.min(select(2, color:ToHSV()) * 1.5 + 0.15, 1), math.min(select(3, color:ToHSV()) * 1.25 + 0.1, 1)), 0.7) -- richer than the raw ore colour: dull ores read as mud on a card
			e[1].Color = e[2] >= 0 and c:Lerp(Color3.new(0, 0, 0), e[2]) or c:Lerp(Color3.new(1, 1, 1), -e[2])
		end
		run()
	end
	return api
end

return M
