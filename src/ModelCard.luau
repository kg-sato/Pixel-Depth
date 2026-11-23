-- ModelCard (ReplicatedStorage.Shared.ModelCard): a live 3D model in a card instead of a flat render (2026-11-17, brief:
-- vault Projects/Pixel-_/Briefs/Egg Hatching v3 (2026-11-17).md). Used by the forge cards and detail art (pickaxes,
-- ReplicatedStorage.PickaxeArt) and the Codex pet cells (Shared.PetVoxels).
-- At rest the model turns slowly in its card. On hover (the owner: "a hover type of effect"; motion after @creatoroly's
-- clean product motion and the research note Craft Videos for Weak Grades) it:
--   * lifts and grows a little on a spring, and turns faster
--   * tilts toward the pointer (parallax), so it feels held, not printed
--   * a soft glow of its colour swells behind it, and a shine sweeps across once
-- A new model arrives soft and settles into focus (fade in and a small scale-up), the way Oly's elements rack into focus.
-- Touch has no hover: a tap gives the same lift for a moment. Only cards on screen are animated. Display only.
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local M = {}
local GLOW = "rbxassetid://77591933607769" -- the forge's soft radial glow (art/forge/fx)
local live = setmetatable({}, { __mode = "k" })

local function fit(cam, model, pad)
	local cf, size = model:GetBoundingBox()
	local r = math.max(size.X, size.Y, size.Z) / 2 -- the longest side fills the card (the bounding sphere left pickaxes tiny: capture forge3d)
	local d = r / math.tan(math.rad(cam.FieldOfView / 2)) * (pad or 1.12)
	return cf.Position, d
end

-- host: the GuiObject the model is drawn in (an image frame); hover: the GuiObject that reacts to the pointer (default host)
-- opts: { color = Color3 (glow), roll = degrees (a pickaxe leans), z = ZIndex, scale = 1, stroke = the card's border UIStroke if not on hover }
function M.attach(host, hover, opts)
	opts = opts or {}
	local z = opts.z or host.ZIndex
	local glow = Instance.new("ImageLabel")
	glow.Name, glow.BackgroundTransparency, glow.Image, glow.ImageTransparency = "CardGlow", 1, GLOW, 1
	glow.Size, glow.Position, glow.AnchorPoint, glow.ZIndex = UDim2.fromScale(1.15, 1.15), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5), z
	glow.ImageColor3 = opts.color or Color3.new(1, 1, 1)
	glow.Parent = host
	local vp = Instance.new("ViewportFrame")
	vp.Name, vp.BackgroundTransparency, vp.Size, vp.Position, vp.AnchorPoint, vp.ZIndex = "Card3D", 1, UDim2.fromScale(1, 1), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5), z + 1
	vp.Ambient, vp.LightColor, vp.LightDirection = Color3.fromRGB(175, 165, 200), Color3.fromRGB(255, 240, 225), Vector3.new(0.55, -0.7, 0.6) -- a warm key from the upper left of the camera over a cool plum fill (it was lighting the back: capture forge3d)
	local sc = Instance.new("UIScale")
	sc.Parent = vp
	vp.Parent = host
	local world = Instance.new("WorldModel")
	world.Parent = vp
	local cam = Instance.new("Camera")
	cam.FieldOfView = 30
	cam.Parent = vp
	vp.CurrentCamera = cam
	local shine = Instance.new("Frame") -- one sweep of light across the card on hover
	shine.Name, shine.BackgroundColor3, shine.BackgroundTransparency, shine.BorderSizePixel = "CardShine", Color3.new(1, 1, 1), 0.55, 0
	shine.Size, shine.Position, shine.Rotation, shine.ZIndex, shine.Visible = UDim2.fromScale(0.22, 1.5), UDim2.fromScale(-0.4, -0.25), 20, z + 2, false
	local g = Instance.new("UIGradient")
	g.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.25), NumberSequenceKeypoint.new(1, 1) })
	g.Parent = shine
	shine.Parent = host
	local h = { animate = opts.animate, host = host, vp = vp, sc = sc, world = world, cam = cam, glow = glow, shine = shine, model = nil, a = math.random() * 6, hov = 0, hv = 0, want = 0, tilt = Vector2.zero, roll = math.rad(opts.roll or 0), base = 1, tapUntil = 0 }
	local hv = hover or host
	if hv:IsA("GuiButton") then -- the card itself lifts and casts a soft shadow under it
		if not hv:FindFirstChildOfClass("UIScale") then -- a card that already has a UIScale keeps its own press animation
			h.lift = Instance.new("UIScale")
			h.lift.Name, h.lift.Parent = "CardLift", hv
		end
		local sh = Instance.new("ImageLabel")
		sh.Name, sh.BackgroundTransparency, sh.Image, sh.ImageColor3, sh.ImageTransparency = "CardShadow", 1, GLOW, Color3.new(0, 0, 0), 1
		sh.Size, sh.Position, sh.AnchorPoint, sh.ZIndex = UDim2.fromScale(1.3, 0.5), UDim2.fromScale(0.5, 1.02), Vector2.new(0.5, 0.5), math.max(hv.ZIndex - 1, 1)
		sh.Parent = hv
		h.shadow = sh
		local st = opts.stroke or hv:FindFirstChildOfClass("UIStroke") -- the border catches the glow colour and thickens on hover (Gemini n17_hatch: a sharp border sheen; the equipped card's border stole the focus)
		h.stroke = st
	end
	hv.MouseEnter:Connect(function()
		h.want = 1
		shine.Position, shine.Visible = UDim2.fromScale(-0.4, -0.25), true
		TweenService:Create(shine, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = UDim2.fromScale(1.2, -0.25) }):Play()
	end)
	hv.MouseLeave:Connect(function() h.want = 0 end)
	if hv:IsA("GuiButton") then hv.Activated:Connect(function() if UIS.TouchEnabled then h.tapUntil = os.clock() + 1.2 end end) end

	function h.set(model, color, dim)
		if h.model then h.model:Destroy() h.model = nil end
		if color then glow.ImageColor3 = color end
		vp.ImageColor3 = dim and (color and color:Lerp(Color3.new(1, 1, 1), 0.3) or Color3.fromRGB(120, 105, 150)) or Color3.new(1, 1, 1) -- a locked model takes its rarity tint, not one grey (Orchestrator round 2: ten locked pickaxes read as identical grey silhouettes)
		if not model then return end
		for _, d in model:GetDescendants() do
			if d:IsA("BasePart") then d.Anchored = true elseif d:IsA("Script") or d:IsA("LocalScript") then d:Destroy() end
		end
		model.Parent = world
		h.model = model
		local cf = model:GetPivot()
		h.rest = cf.Rotation
		local ctr, d = fit(cam, model)
		h.ctr, h.d = ctr, d
		h.offset = cf.Position - ctr -- turn about the middle of the model, not its pivot
		vp.ImageTransparency, sc.Scale = 1, 0.86 -- arrives soft, settles into focus
		TweenService:Create(vp, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { ImageTransparency = 0 }):Play()
		TweenService:Create(sc, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	end
	function h.destroy()
		live[h] = nil
		for _, o in { glow, vp, shine } do o:Destroy() end
	end
	live[h] = true
	return h
end

RunService.RenderStepped:Connect(function(dt)
	dt = math.min(dt, 1 / 20)
	local mouse = UIS:GetMouseLocation() - game:GetService("GuiService"):GetGuiInset()
	for h in live do
		local host = h.host
		if not host.Parent or not h.model or host.AbsoluteSize.X < 4 or not host:FindFirstAncestorWhichIsA("LayerCollector") or not host:FindFirstAncestorWhichIsA("LayerCollector").Enabled then continue end
		local want = (h.want > 0 or os.clock() < h.tapUntil) and 1 or 0
		h.hv += ((want - h.hov) * 180 - h.hv * 18) * dt -- an under-damped spring: the lift overshoots a little and settles
		h.hov += h.hv * dt
		local hov = h.hov
		h.a += dt * (0.6 + 2.2 * math.max(hov, 0))
		local tiltGoal = Vector2.zero
		if want > 0 and h.want > 0 then
			local c = host.AbsolutePosition + host.AbsoluteSize / 2
			local rel = (mouse - c) / (host.AbsoluteSize / 2)
			tiltGoal = Vector2.new(math.clamp(rel.X, -1, 1), math.clamp(rel.Y, -1, 1))
		end
		h.tilt = h.tilt:Lerp(tiltGoal, 1 - math.exp(-dt * 10))
		local spin = CFrame.Angles(h.tilt.Y * 0.5, math.sin(h.a * 0.8) * 0.75 + h.tilt.X * 0.8, 0) * CFrame.Angles(0, 0, h.roll) -- it sways to and fro instead of a full turn, so a thin pickaxe never shows only its edge (capture forge3d_2)
		h.model:PivotTo(CFrame.new(h.ctr) * spin * CFrame.new(h.offset) * h.rest)
		if h.animate then h.animate(h.model, os.clock(), dt, false) end -- a pet keeps breathing and blinking in its card
		h.cam.CFrame = CFrame.lookAt(h.ctr + Vector3.new(0, h.d * 0.12, -h.d), h.ctr)
		h.sc.Scale = h.vp.ImageTransparency > 0.05 and h.sc.Scale or (1 + 0.16 * hov) -- Gemini n17_hatch: the lift at 8% was barely seen
		h.vp.Position = UDim2.fromScale(0.5, 0.5 - 0.07 * hov)
		h.glow.ImageTransparency = 1 - math.clamp(hov, 0, 1) * 0.85
		if h.lift then h.lift.Scale = 1 + 0.08 * hov end -- the whole card rises toward you
		if h.shadow then h.shadow.ImageTransparency = 1 - math.clamp(hov, 0, 1) * 0.75 end
		if h.stroke then -- the card's own state colours the border at rest: take it when the hover starts, give it back when it ends
			local u = math.clamp(hov, 0, 1)
			if u > 0.01 then
				if not h.strokeC then h.strokeC, h.strokeT = h.stroke.Color, h.stroke.Thickness elseif h.stroke.Color ~= h.strokeW then h.strokeC = h.stroke.Color end -- the card changed state (equipped) under the pointer: that is the new rest
				h.stroke.Color, h.stroke.Thickness = h.strokeC:Lerp(h.glow.ImageColor3:Lerp(Color3.new(1, 1, 1), 0.45), u), h.strokeT + 1.5 * u
				h.strokeW = h.stroke.Color
			elseif h.strokeC then
				h.stroke.Color, h.stroke.Thickness, h.strokeC = h.strokeC, h.strokeT, nil
			end
		end
	end
end)

return M
