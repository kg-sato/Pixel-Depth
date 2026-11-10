-- ServerScriptService.ZFix: removes z-fighting from a built model (the user, 2026-11-08: "parts clip instead of merging ... check
-- for this automatically"). Two visible block parts whose faces lie on the same plane, face the same way and overlap flicker;
-- ZFix pushes the smaller part's face 0.04 studs outward so one face always wins. HubBuilder and CaveBuilder call it last.
-- Covers blocks that are axis-aligned or turned in 90-degree steps (what the builders make). The check that it worked is
-- Games/Pixel Depth/spike/zfight_scan.luau (same face test, read only).
local ZFix = {}

local EPS, PUSH = 0.02, 0.04

local function axisOf(v)
	if math.abs(v.X) > 0.999 then return 1 elseif math.abs(v.Y) > 0.999 then return 2 elseif math.abs(v.Z) > 0.999 then return 3 end
end

local function facesOf(p)
	local cf, sz = p.CFrame, p.Size
	local local3 = { cf.RightVector, cf.UpVector, cf.LookVector }
	local ext, map = { 0, 0, 0 }, {}
	for i = 1, 3 do
		local a = axisOf(local3[i])
		if not a then return nil end
		ext[a] = ({ sz.X, sz.Y, sz.Z })[i] / 2
		map[a] = i -- world axis -> local size index
	end
	local c = { cf.Position.X, cf.Position.Y, cf.Position.Z }
	local out = {}
	for a = 1, 3 do
		local b, d = a % 3 + 1, (a + 1) % 3 + 1
		for _, s in { -1, 1 } do
			table.insert(out, { p = p, a = a, s = s, li = map[a], k = c[a] + s * ext[a], b0 = c[b] - ext[b], b1 = c[b] + ext[b], d0 = c[d] - ext[d], d1 = c[d] + ext[d], vol = sz.X * sz.Y * sz.Z })
		end
	end
	return out
end

-- one pass; returns the number of faces pushed
local function pass(root, PUSH)
	local buckets = {}
	for _, p in root:GetDescendants() do
		if p:IsA("Part") and p.Shape == Enum.PartType.Block and p.Transparency < 0.95 then
			for _, f in facesOf(p) or {} do
				local key = f.a .. ":" .. f.s .. ":" .. math.floor(f.k / EPS + 0.5)
				buckets[key] = buckets[key] or {}
				table.insert(buckets[key], f)
			end
		end
	end
	local pushed = {} -- [part] = { [face key] = true }: each face moves once
	local n = 0
	for _, list in buckets do
		if #list > 1 then
			table.sort(list, function(x, y) return x.b0 < y.b0 end)
			for i = 1, #list do
				local f = list[i]
				for j = i + 1, #list do
					local g = list[j]
					if g.b0 >= f.b1 - EPS then break end
					if f.p ~= g.p and math.min(f.d1, g.d1) - math.max(f.d0, g.d0) > EPS and math.min(f.b1, g.b1) - math.max(f.b0, g.b0) > EPS
						and (f.p.Color ~= g.p.Color or f.p.Material ~= g.p.Material or f.p.MaterialVariant ~= g.p.MaterialVariant
							or f.p:FindFirstChildWhichIsA("Texture") or g.p:FindFirstChildWhichIsA("Texture")) then -- same colour, different skins still flicker
						local m = f.vol <= g.vol and f or g -- the smaller part steps forward
						local tag = m.a .. ":" .. m.s
						pushed[m.p] = pushed[m.p] or {}
						if not pushed[m.p][tag] then
							pushed[m.p][tag] = true
							local p = m.p
							local sz = { p.Size.X, p.Size.Y, p.Size.Z }
							sz[m.li] += PUSH
							local shift = Vector3.new(m.a == 1 and 1 or 0, m.a == 2 and 1 or 0, m.a == 3 and 1 or 0) * (m.s * PUSH / 2)
							p.Size = Vector3.new(sz[1], sz[2], sz[3])
							p.CFrame = p.CFrame + shift
							n += 1
						end
					end
				end
			end
		end
	end
	return n
end

-- passes until clean (a face pushed in one pass can land on another pushed face; the next pass separates them)
function ZFix.fix(root)
	local total = 0
	for i = 1, 8 do
		local n = pass(root, PUSH + (i - 1) * 0.012) -- a different step each pass: two faces pushed by the same step stayed coplanar (11 hub lane pairs, 2026-11-10)
		total += n
		if n == 0 then break end
	end
	return total
end

return ZFix
