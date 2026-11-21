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
	local GOLD, PALE = Color3.fromRGB(255, 214, 110), Color3.fromRGB(226, 216, 250)
	local function plate(ped)
		local bb = Instance.new("BillboardGui")
		bb.Name, bb.Size, bb.StudsOffsetWorldSpace, bb.AlwaysOnTop, bb.MaxDistance, bb.LightInfluence = "CrewPlate", UDim2.fromScale(5, 1.6), Vector3.new(0, 4.6, 0), false, 90, 0
		bb.Adornee, bb.Enabled = ped, false
		local f = Instance.new("Frame")
		f.Size, f.BackgroundColor3, f.BackgroundTransparency, f.BorderSizePixel = UDim2.fromScale(1, 1), Color3.fromRGB(24, 14, 42), 0.12, 0
		f.Parent = bb
		local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0.3, 0) c.Parent = f
		local s = Instance.new("UIStroke") s.Color, s.Thickness, s.Transparency = GOLD, 1.5, 0.25 s.Parent = f
		local function line(name, y, h, col, font)
			local l = Instance.new("TextLabel")
			l.Name, l.BackgroundTransparency, l.Size, l.Position, l.AnchorPoint = name, 1, UDim2.fromScale(0.92, h), UDim2.fromScale(0.5, y), Vector2.new(0.5, 0.5)
			l.Font, l.TextScaled, l.TextColor3, l.Text = font or Enum.Font.FredokaOne, true, col, ""
			l.Parent = f
			return l
		end
		local who = line("Who", 0.3, 0.42, Color3.new(1, 1, 1))
		local info = line("Info", 0.74, 0.3, PALE, Enum.Font.GothamBold)
		bb.Parent = E.plr:WaitForChild("PlayerGui")
		return bb, who, info
	end
	for n, p in peds do p.bb, p.who, p.info = plate(p.part) end

	local function refresh(n)
		local p = peds[n]
		local ped = p.part
		local who, pet = ped:GetAttribute("Who"), ped:GetAttribute("Pet")
		for _, b in props[n] or {} do
			b.LocalTransparencyModifier = who and 1 or 0
			for _, l in b:GetDescendants() do if l:IsA("Light") then l.Enabled = who == nil end end
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
				m.Parent = workspace:FindFirstChild("ClientFX") or workspace
				p.model, p.petName = m, pet
			end
		end
		p.bb.Enabled = who ~= nil
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
