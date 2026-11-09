-- Z-fighting scan (read only): finds pairs of visible parts whose faces lie on the same plane, face the same way and overlap.
-- Covers axis-aligned and 90-degree-turned blocks (the hub and caves are built from them). Run in the Server (Play) or Edit context.
-- Returns a count per folder and the first examples with positions.
local roots = {}
for _, n in { "Hub", "Caves" } do
	local r = workspace:FindFirstChild(n)
	if r then table.insert(roots, r) end
end
local EPS = 0.02
local cell = 16
local grid, faces = {}, {}
local function axisOf(v)
	local ax, ay, az = math.abs(v.X), math.abs(v.Y), math.abs(v.Z)
	if ax > 0.999 then return 1, math.sign(v.X) elseif ay > 0.999 then return 2, math.sign(v.Y) elseif az > 0.999 then return 3, math.sign(v.Z) end
end
local skipped = 0
for _, root in roots do
	for _, p in root:GetDescendants() do
		if p:IsA("BasePart") and p.Transparency < 0.95 and p:IsA("Part") and p.Shape == Enum.PartType.Block then
			local cf, sz = p.CFrame, p.Size
			local axes = { cf.RightVector, cf.UpVector, cf.LookVector }
			local ok = true
			local info = {}
			for i = 1, 3 do
				local a, sgn = axisOf(axes[i])
				if not a then ok = false break end
				info[i] = { a = a, half = ({ sz.X, sz.Y, sz.Z })[i] / 2 }
			end
			if not ok then
				skipped += 1
			else
				local ext = { 0, 0, 0 }
				for i = 1, 3 do ext[info[i].a] = info[i].half end
				local c = { cf.Position.X, cf.Position.Y, cf.Position.Z }
				for a = 1, 3 do
					for _, s in { -1, 1 } do -- each face: axis, side, plane coordinate, rectangle on the other two axes
						local b, d = a % 3 + 1, (a + 1) % 3 + 1
						table.insert(faces, { p = p, root = root.Name, a = a, s = s, k = c[a] + s * ext[a], b0 = c[b] - ext[b], b1 = c[b] + ext[b], d0 = c[d] - ext[d], d1 = c[d] + ext[d] })
					end
				end
			end
		end
	end
end
-- bucket faces by axis, side and rounded plane coordinate, then test rectangle overlap inside each bucket
local buckets = {}
for _, f in faces do
	local key = f.a .. ":" .. f.s .. ":" .. math.floor(f.k / EPS + 0.5)
	buckets[key] = buckets[key] or {}
	table.insert(buckets[key], f)
end
local count, per, examples = 0, {}, {}
for _, list in buckets do
	if #list > 1 and #list < 4000 then
		table.sort(list, function(x, y) return x.b0 < y.b0 end)
		for i = 1, #list do
			local f = list[i]
			for j = i + 1, #list do
				local g = list[j]
				if g.b0 >= f.b1 - EPS then break end
				if f.p ~= g.p and math.min(f.d1, g.d1) - math.max(f.d0, g.d0) > EPS and math.min(f.b1, g.b1) - math.max(f.b0, g.b0) > EPS then
					if f.p.Color ~= g.p.Color or f.p.Material ~= g.p.Material then -- same look on both = no visible flicker
						count += 1
						per[f.root] = (per[f.root] or 0) + 1
						if #examples < 12 then
							table.insert(examples, f.p:GetFullName():gsub("Workspace%.", "") .. " | " .. g.p:GetFullName():gsub("Workspace%.", "") .. " @ " .. string.format("%.0f,%.0f,%.0f", f.p.Position.X, f.p.Position.Y, f.p.Position.Z))
						end
					end
				end
			end
		end
	end
end
local parts = {}
for k, v in per do table.insert(parts, k .. " " .. v) end
return "z-fight pairs " .. count .. " (" .. table.concat(parts, ", ") .. "), faces " .. #faces .. ", skipped rotated " .. skipped .. "\n" .. table.concat(examples, "\n")
