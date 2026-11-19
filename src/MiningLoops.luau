-- MiningLoops (ReplicatedStorage.Shared.MiningLoops), started by PixelClient. The cave side of vault Briefs/Cave Mining Loops
-- (2026-11-19), after Research/Game Design/Unique Mining Loops (2026-11-08):
--   * Echo Tap: click (or tap) a cave wall within C.ECHO.reach studs and a pastel number shows on the rock for C.ECHO.show s:
--     how many ore deposits still show within C.ECHO.radius studs of that point. Client only, pays nothing.
--   * Vein Chains: the server pops same-ore deposits next to a flawless extraction (Fx "veinChain"); each gets a burst here.
--   * Root Pulse: the server warns (Fx "pulseWarn") and breathes (Fx "pulse", ore lost, glow seconds); every deposit glows.
local M = {}

function M.start(E)
	local C, R, plr, toast, sfx = E.C, E.R, E.plr, E.toast, E.sfx
	local UIS, TweenService = game:GetService("UserInputService"), game:GetService("TweenService")
	local INK = Color3.fromRGB(22, 8, 30)
	local PASTEL = { [0] = Color3.fromRGB(196, 186, 220), Color3.fromRGB(150, 236, 196), Color3.fromRGB(255, 226, 140), Color3.fromRGB(255, 160, 210) }
	local fx = Instance.new("Folder")
	fx.Name, fx.Parent = "MiningLoopsFx", workspace

	local function deposits()
		local caves = workspace:FindFirstChild("Caves")
		local folder = caves and caves:FindFirstChild("Deposits")
		local out = {}
		for _, d in folder and folder:GetChildren() or {} do
			if d:IsA("Model") and d.PrimaryPart and d.PrimaryPart.Transparency < 1 then table.insert(out, d) end -- claimed ones are hidden for this player
		end
		return out
	end

	-- ===== Echo Tap
	local E_ = C.ECHO
	local ready = 0
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	local function echo(screenPos)
		if not E_ or not plr:GetAttribute("InCave") or os.clock() < ready then return end
		if (E.isBusy and E.isBusy()) or (E.vmHook and E.vmHook.modalOpen) then return end
		local cam = workspace.CurrentCamera
		local ray = cam:ViewportPointToRay(screenPos.X, screenPos.Y)
		rp.FilterDescendantsInstances = { plr.Character, fx, workspace:FindFirstChild("Sonar") }
		local hit = workspace:Raycast(ray.Origin, ray.Direction * (E_.reach + 4), rp)
		if not hit or not hit.Instance.Anchored then return end
		local dep = workspace:FindFirstChild("Caves") and workspace.Caves:FindFirstChild("Deposits")
		if dep and hit.Instance:IsDescendantOf(dep) then return end -- a deposit is mined, not tapped
		ready = os.clock() + E_.cool
		local n = 0
		for _, d in deposits() do if (d.PrimaryPart.Position - hit.Position).Magnitude <= E_.radius then n += 1 end end
		local a = Instance.new("Attachment")
		a.WorldPosition = hit.Position + hit.Normal * 0.4
		local host = workspace.Terrain
		a.Parent = host
		local bb = Instance.new("BillboardGui")
		bb.Size, bb.LightInfluence, bb.AlwaysOnTop, bb.MaxDistance, bb.Adornee = UDim2.fromOffset(58, 58), 0, false, 40, a
		local t = Instance.new("TextLabel")
		t.Size, t.BackgroundTransparency, t.Text, t.Font, t.TextScaled = UDim2.fromScale(1, 1), 1, tostring(n), Enum.Font.FredokaOne, true
		t.TextColor3, t.TextStrokeColor3, t.TextStrokeTransparency = PASTEL[math.min(n, 3)], INK, 0.1
		t.Parent = bb
		local sc = Instance.new("UIScale")
		sc.Scale, sc.Parent = 0.4, t
		bb.Parent = plr:WaitForChild("PlayerGui")
		TweenService:Create(sc, TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
		if sfx then sfx("click", 0.6 + math.min(n, 4) * 0.15) end -- the echo rings higher the more ore it hears
		task.delay(E_.show, function()
			TweenService:Create(t, TweenInfo.new(0.4), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
			task.delay(0.45, function() bb:Destroy() a:Destroy() end)
		end)
	end
	if game:GetService("RunService"):IsStudio() then plr:GetAttributeChangedSignal("DevEcho"):Connect(function() echo(workspace.CurrentCamera.ViewportSize / 2) end) end -- test hook (spike): a tap at the screen centre
	UIS.InputBegan:Connect(function(input, gp)
		if gp then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			local mouse = UIS.MouseBehavior == Enum.MouseBehavior.LockCenter and workspace.CurrentCamera.ViewportSize / 2 or UIS:GetMouseLocation() - game:GetService("GuiService"):GetGuiInset()
			echo(mouse)
		elseif input.UserInputType == Enum.UserInputType.Touch then
			echo(Vector2.new(input.Position.X, input.Position.Y))
		end
	end)

	-- ===== glow and bursts
	local function glowAll(seconds, color)
		for _, d in deposits() do
			local h = Instance.new("Highlight")
			h.FillColor, h.FillTransparency, h.OutlineColor, h.OutlineTransparency = color, 0.75, color, 0.1
			h.DepthMode, h.Adornee, h.Parent = Enum.HighlightDepthMode.AlwaysOnTop, d, fx
			task.delay(seconds, function()
				TweenService:Create(h, TweenInfo.new(0.6), { FillTransparency = 1, OutlineTransparency = 1 }):Play()
				task.delay(0.65, function() h:Destroy() end)
			end)
		end
	end
	local function burst(at, color)
		local b = Instance.new("Part")
		b.Shape, b.Material, b.Color, b.Transparency = Enum.PartType.Ball, Enum.Material.Neon, color, 0.25
		b.Anchored, b.CanCollide, b.CanQuery, b.CanTouch, b.CastShadow = true, false, false, false, false
		b.Size, b.Position, b.Parent = Vector3.new(1, 1, 1), at, fx
		TweenService:Create(b, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.new(7, 7, 7), Transparency = 1 }):Play()
		task.delay(0.5, function() b:Destroy() end)
	end

	R:WaitForChild("Fx").OnClientEvent:Connect(function(kind, a, b, c)
		if kind == "veinChain" then -- a: the popped deposits, b: ore paid, c: the ore colour
			for i, d in a do
				task.delay(i * 0.12, function() if d.Parent then burst(d:GetPivot().Position, c or Color3.new(1, 1, 1)) if sfx then sfx("sparkle", 1 + i * 0.12) end end end)
			end
			toast(string.format("VEIN CHAIN x%d!  +%d ORE", #a, b), c or Color3.fromRGB(255, 226, 140), true)
		elseif kind == "pulseWarn" then
			toast(string.format("THE ROOTS STIR...  THEY BREATHE IN %d s. BANK AT CAMP!", a), Color3.fromRGB(255, 180, 120), true)
			if sfx then sfx("swing", 0.5) end
		elseif kind == "pulse" then
			glowAll(b or 6, Color3.fromRGB(255, 140, 210))
			if E.shake then E.shake(0.25) end
			if a and a > 0 then
				toast(string.format("THE ROOTS BREATHED: -%d UNBANKED ORE. CAMP KEEPS IT SAFE", a), Color3.fromRGB(224, 96, 110), true)
			else
				toast("THE ROOTS BREATHE: EVERY VEIN GLOWS!", Color3.fromRGB(255, 160, 210), true)
			end
		end
	end)
end

return M
