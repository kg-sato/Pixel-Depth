-- one-time install of the forge pickaxes in ServerStorage.Pickaxes (src/install_pickaxes.luau): unpack, materials, gem light and sparkles
local FX = {
	HeartGemPickaxe = { glow = "#c79bff", light = "#d6b0ff", spark = { "#ffffff", "#d6e8ff" } },
	StarlightPickaxe = { glow = "#ff7fd0", light = "#ff7fd0", spark = { "#ffffff", "#e0c8ff" } },
	MoonlitPickaxe = { glow = "#d8e4ff", light = "#a9c0ff", spark = { "#ffffff", "#b9c8ff" } },
	RoseThornPickaxe = { glow = "#cfe0ff", light = "#ffb0d8", spark = { "#ffffff", "#d6ecff" } },
	PearlTidePickaxe = { glow = "#fff0f8", light = "#ffd0ea", spark = { "#ffffff", "#e2f0ff" } },
	GalaxyPickaxe = { glow = "#8a7cff", light = "#8a7cff", spark = { "#ffffff", "#9fd0ff" } },
	SakuraPickaxe = { glow = "#ffc0dc", light = "#ffc0dc", spark = { "#ffffff", "#ffd0e4" } },
	LotusCrystalPickaxe = { glow = "#e8e4ff", light = "#d7b8ff", spark = { "#ffffff", "#e6dcff" } },
	RoyalHeartPickaxe = { glow = "#ff4f9a", light = "#ff4f9a", spark = { "#ffffff", "#ffd6ea" } },
	SilverWingPickaxe = { glow = "#2f6bff", light = "#2f6bff", spark = { "#ffffff", "#cfe0ff" } },
	WoodPickaxe = { glow = "#9fe3c4", light = "#ffe6a8", spark = { "#ffffff", "#d8f5e6" } }, -- starters: a soft glint only
	StonePickaxe = { glow = "#ffb0cc", light = "#f0d8ff", spark = { "#ffffff", "#e6dcff" } },
	CopperPickaxe = { glow = "#ffc8a0", light = "#ffd6a0", spark = { "#ffffff", "#ffe6c8" } },
	BogIronPickaxe = { glow = "#c8f0b0", light = "#e0f0c8", spark = { "#ffffff", "#e6f5dc" } },
	RootflintPickaxe = { glow = "#a8e6c8", light = "#e9e0c0", spark = { "#ffffff", "#dff5e8" } },
	AshcoalPickaxe = { glow = "#ffae96", light = "#ffb89a", spark = { "#ffffff", "#ffd6c8" } },
}
local out = {}
for _, m in game.ServerStorage.Pickaxes:GetChildren() do
	local fx = FX[m.Name]
	local link = m:FindFirstChildOfClass("PackageLink")
	if link then link:Destroy() end
	for _, grp in m:GetChildren() do -- flatten the per-material sub-models into the pickaxe model
		if grp:IsA("Model") then
			local cls = grp.Name:match("_(%a+)$")
			for _, p in grp:GetChildren() do
				if p:IsA("MeshPart") then
					p.Name = cls
					p.Color = Color3.new(1, 1, 1)
					p.Material = (cls == "Glass" and Enum.Material.Glass) or (cls == "Metal" and Enum.Material.Metal) or (cls == "Neon" and Enum.Material.Neon) or Enum.Material.SmoothPlastic
					if cls == "Glass" then p.Transparency = 0.2 end
					if cls == "Neon" and fx then p.Color = Color3.fromHex(fx.glow) end
					p.Parent = m
				end
			end
			grp:Destroy()
		end
	end
	local gem = m:FindFirstChild("Neon") or m:FindFirstChild("Glass")
	if gem and fx and not gem:FindFirstChild("GemLight") then
		local l = Instance.new("PointLight")
		l.Name, l.Color, l.Range, l.Brightness, l.Shadows = "GemLight", Color3.fromHex(fx.light), 7, 1.6, false
		l.Parent = gem
		local e = Instance.new("ParticleEmitter")
		e.Name = "Sparkles"
		e.Color = ColorSequence.new(Color3.fromHex(fx.spark[1]), Color3.fromHex(fx.spark[2]))
		e.LightEmission, e.Rate, e.Lifetime, e.Speed = 1, 5, NumberRange.new(0.6, 1.1), NumberRange.new(0.3, 1)
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.3, 0.22), NumberSequenceKeypoint.new(1, 0) })
		e.SpreadAngle, e.Rotation = Vector2.new(180, 180), NumberRange.new(0, 360)
		e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		e.Parent = gem
	end
	local h = m:FindFirstChild("SmoothPlastic") or m:FindFirstChildWhichIsA("BasePart")
	m.PrimaryPart = h
	local n = 0
	for _, p in m:GetDescendants() do if p:IsA("MeshPart") then n += 1 end end
	table.insert(out, m.Name .. " parts=" .. n .. " primary=" .. tostring(h and h.Name))
end
return table.concat(out, "; ")
