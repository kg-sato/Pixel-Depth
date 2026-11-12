-- Sonar (ReplicatedStorage.Shared.Sonar), started by PixelClient. Cave utility: press T in the caves and the pickaxe
-- taps the rock. A luminous shell grows out from the player; every ore deposit within 50 studs lights up through the rock
-- for 5 seconds (Highlight, AlwaysOnTop). Client only: it reveals what the player can already see on the server, so it
-- pays nothing and needs no remote. Cooldown 12 s. Q is the minecart lift key in the mine, so the sonar uses T.
local M = {}

local RANGE, SHOW, COOLDOWN = 50, 5, 12

function M.start(E)
	local UIS, RunService = game:GetService("UserInputService"), game:GetService("RunService")
	local plr = E.plr
	local MINT = Color3.fromRGB(127, 220, 180)
	local readyAt = 0

	local function deposits()
		local out = {}
		local caves = workspace:FindFirstChild("Caves")
		local folder = caves and caves:FindFirstChild("Deposits")
		if folder then
			for _, d in folder:GetChildren() do
				if d:IsA("Model") and d.PrimaryPart then table.insert(out, d) end
			end
		end
		return out
	end

	local function pulse(origin)
		local folder = workspace:FindFirstChild("Sonar") or Instance.new("Folder")
		folder.Name, folder.Parent = "Sonar", workspace
		local shell = Instance.new("Part")
		shell.Name, shell.Shape, shell.Material = "Shell", Enum.PartType.Ball, Enum.Material.Neon
		shell.Color = MINT
		shell.Anchored, shell.CanCollide, shell.CanQuery, shell.CanTouch, shell.CastShadow = true, false, false, false, false
		shell.Transparency = 0.7
		shell.Size = Vector3.new(1, 1, 1)
		shell.Position = origin
		local mesh = Instance.new("SpecialMesh") -- a negative scale turns the faces inward: a plain Ball is invisible from inside
		mesh.MeshType, mesh.Scale = Enum.MeshType.Sphere, Vector3.new(-2, -2, -2)
		mesh.Parent = shell
		shell.Parent = folder
		local t0 = os.clock()
		local conn
		conn = RunService.RenderStepped:Connect(function()
			local k = (os.clock() - t0) / 1.4
			if k >= 1 then
				conn:Disconnect()
				shell:Destroy()
				return
			end
			local r = 2 + (RANGE * 2 + 6) * (1 - (1 - k) ^ 2)
			mesh.Scale = Vector3.new(-r, -r, -r)
			shell.Transparency = 0.55 + 0.45 * k
		end)
	end

	local function reveal(list)
		local highlights = {}
		for _, d in list do
			local h = Instance.new("Highlight")
			h.Name = "SonarGlow"
			h.Adornee = d
			h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			h.FillColor, h.OutlineColor = MINT, Color3.fromRGB(230, 255, 245)
			h.FillTransparency, h.OutlineTransparency = 0.75, 0.2
			h.Parent = d
			table.insert(highlights, h)
		end
		task.delay(SHOW, function()
			for _, h in highlights do
				if h.Parent then h:Destroy() end
			end
		end)
	end

	local function ping()
		local h = E.hrp()
		if not h or not plr:GetAttribute("InCave") then return end
		local now = os.clock()
		if now < readyAt then return end
		readyAt = now + COOLDOWN
		pulse(h.Position)
		local near = {}
		for _, d in deposits() do
			if (d.PrimaryPart.Position - h.Position).Magnitude <= RANGE then table.insert(near, d) end
		end
		reveal(near)
		pcall(E.sfx, "sparkle", 1.25)
		if #near == 0 then
			E.toast("Sonar: nothing within 50 studs", nil, false, 2)
		else
			E.toast("Sonar: " .. #near .. " deposit" .. (#near == 1 and "" or "s"), nil, false, 3)
		end
	end

	UIS.InputBegan:Connect(function(io, gp)
		if gp or io.KeyCode ~= Enum.KeyCode.T then return end
		ping()
	end)
end

return M
