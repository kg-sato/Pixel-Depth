-- CrewHearth (ReplicatedStorage.Shared.CrewHearth), started by PixelClient. Directive v13 phase 4: the town's guest cabins are
-- the Crew Hearth. Each of the four oak pedestals on their porches (HubBuilder "CrewPedestal", attribute Crew = 1..4) shows one
-- player in this server: their lead pet stands on it, idling, with a small plate above it: name, pickaxe and escapes. The
-- server writes the attributes Who, Pet, Pick and Escapes (PixelServer); this module only draws them. An empty pedestal keeps
-- its traveller's bunk (the "BunkProp" bedroll and lantern), which hides while someone stands there.
local RunService = game:GetService("RunService")
local M = {}

function M.start(E)
	local hub = workspace:WaitForChild("Hub", 30)
	if not hub then return end
	local PV = require(script.Parent:WaitForChild("PetVoxels"))
	local peds, props = {}, {}
	for _, d in hub:GetDescendants() do
		local n = d:GetAttribute("Crew")
		if n and d.Name == "CrewPedestal" then peds[n] = { part = d }
		elseif n and d.Name == "BunkProp" then props[n] = props[n] or {} table.insert(props[n], d) end
	end
	local GOLD = Color3.fromRGB(255, 214, 110)
	-- the name plate is a carved oak plaque hung on the pedestal's plaza face, lit like the world (Gemini v13 round 1: a
	-- floating billboard broke the cabin's mood); it hides with its pedestal's player
	local function plate(ped)
		local board = Instance.new("Part")
		board.Name, board.Anchored, board.CanCollide, board.CanQuery, board.CanTouch, board.CastShadow = "CrewPlaque", true, false, false, false, false
		board.Size, board.Material, board.Color = Vector3.new(2.5, 1.05, 0.16), Enum.Material.Wood, Color3.fromRGB(122, 78, 44)
		board.CFrame = ped.CFrame * CFrame.new(0, 0.02, ped.Size.Z / 2 + 0.09) * CFrame.Angles(0, math.pi, 0) * CFrame.Angles(-0.1, 0, 0)
		local rim = Instance.new("Part") -- a darker frame proud of the board's edge
		rim.Name, rim.Anchored, rim.CanCollide, rim.CanQuery, rim.CanTouch, rim.CastShadow = "CrewPlaqueRim", true, false, false, false, false
		rim.Size, rim.Material, rim.Color, rim.CFrame = Vector3.new(2.68, 1.2, 0.1), Enum.Material.Wood, Color3.fromRGB(74, 44, 26), board.CFrame * CFrame.new(0, 0, 0.07)
		rim.Parent = board
		local sg = Instance.new("SurfaceGui")
		sg.Name, sg.Face, sg.SizingMode, sg.PixelsPerStud, sg.LightInfluence, sg.MaxDistance = "CrewPlate", Enum.NormalId.Front, Enum.SurfaceGuiSizingMode.PixelsPerStud, 80, 0.6, 90
		sg.Parent = board
		local function line(name, y, h, col, font)
			local l = Instance.new("TextLabel")
			l.Name, l.BackgroundTransparency, l.Size, l.Position, l.AnchorPoint = name, 1, UDim2.fromScale(0.9, h), UDim2.fromScale(0.5, y), Vector2.new(0.5, 0.5)
			l.Font, l.TextScaled, l.TextColor3, l.Text = font or Enum.Font.FredokaOne, true, col, ""
			local st = Instance.new("UIStroke") st.Color, st.Thickness, st.Transparency = Color3.fromRGB(48, 26, 12), 3, 0.1 st.Parent = l -- the carved groove
			l.Parent = sg
			return l
		end
		local who = line("Who", 0.34, 0.46, Color3.fromRGB(255, 232, 176))
		local info = line("Info", 0.77, 0.26, GOLD, Enum.Font.GothamBold)
		board.Parent = nil
		return board, who, info
	end
	for n, p in peds do p.bb, p.who, p.info = plate(p.part) end

	local function refresh(n)
		local p = peds[n]
		local ped = p.part
		local who, pet = ped:GetAttribute("Who"), ped:GetAttribute("Pet")
		local shown = who ~= nil and pet ~= nil -- the bunk steps aside only for a pet: a player with no pet keeps the lantern lit
		for _, b in props[n] or {} do
			b.LocalTransparencyModifier = shown and 1 or 0
			for _, l in b:GetDescendants() do if l:IsA("Light") then l.Enabled = not shown end end
		end
		if p.model and (not who or p.petName ~= pet) then p.model:Destroy() p.model = nil end
		if who and pet and not p.model then
			local ok, m = pcall(PV.build, pet)
			if ok and m then
				local _, size = m:GetBoundingBox()
				m:ScaleTo(math.clamp(1.7 / math.max(size.Y, 0.3), 0.3, 1.4))
				local _, s2 = m:GetBoundingBox()
				local top = ped.Position.Y + ped.Size.Y / 2 + 0.22 -- on the pedestal's cap
				local _, yaw = ped.CFrame:ToEulerAnglesYXZ()
				m:PivotTo(CFrame.new(ped.Position.X, top + s2.Y / 2, ped.Position.Z) * CFrame.Angles(0, yaw + math.pi, 0)) -- pets look -Z: it faces the plaza
				for _, d in m:GetDescendants() do if d:IsA("BasePart") then d.Anchored, d.CanCollide, d.CanQuery, d.CanTouch = true, false, false, false end end
				m:SetAttribute("CrewHearth", true) -- a display pet on a pedestal, not a companion (spike/pet_test.py counts companions)
				m.Parent = workspace:FindFirstChild("ClientFX") or workspace
				p.model, p.petName = m, pet
			end
		end
		p.bb.Parent = who and (workspace:FindFirstChild("ClientFX") or workspace) or nil
		if who then
			p.who.Text = who
			local esc = ped:GetAttribute("Escapes") or 0
			p.info.Text = string.upper(ped:GetAttribute("Pick") or "") .. "  \u{00B7}  " .. esc .. (esc == 1 and " ESCAPE" or " ESCAPES")
		end
	end
	for n, p in peds do
		for _, a in { "Who", "Pet", "Pick", "Escapes" } do p.part:GetAttributeChangedSignal(a):Connect(function() refresh(n) end) end
		refresh(n)
	end
	RunService.Heartbeat:Connect(function(dt) -- the pets idle only while the player is near the cabins
		local h = E.hrp and E.hrp()
		if not h then return end
		local now = os.clock()
		for _, p in peds do
			if p.model and (p.part.Position - h.Position).Magnitude < 120 then pcall(PV.animate, p.model, now, dt, false) end
		end
	end)
end

return M
