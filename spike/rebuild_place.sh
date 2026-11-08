#!/bin/sh
# Rebuild the Pixel Depths place in an open Studio (Edit mode) from this repo: scripts from src/, ProfileStore from Vendor/,
# and the ten forge pickaxes (uploaded models) into ServerStorage.Pickaxes. Needed because the place file is only saved by the owner.
# Usage (Git Bash, from the Roblox workspace root): sh "Games/Pixel Depth/spike/rebuild_place.sh"
set -e
cd "$(dirname "$0")/../../.."
G="Games/Pixel Depth/src"
T=$(mktemp -d)
cat > "$T/mk.luau" <<'EOF'
local RS = game:GetService("ReplicatedStorage")
local shared = RS:FindFirstChild("Shared") or Instance.new("Folder")
shared.Name, shared.Parent = "Shared", RS
local function ensure(parent, cls, name)
	local o = parent:FindFirstChild(name) or Instance.new(cls)
	o.Name, o.Parent = name, parent
end
ensure(shared, "ModuleScript", "Config")
ensure(shared, "ModuleScript", "PixelText")
ensure(game.ServerScriptService, "ModuleScript", "ProfileStore")
ensure(game.ServerScriptService, "ModuleScript", "HubBuilder")
ensure(game.ServerScriptService, "Script", "PixelServer")
ensure(game.StarterPlayer.StarterPlayerScripts, "LocalScript", "PixelClient")
ensure(game.ServerStorage, "Folder", "Pickaxes")
return "ok"
EOF
python tools/studio_live.py execute_luau --file "$T/mk.luau" code '{"datamodel_type": "Edit"}'
python tools/studio_push.py ReplicatedStorage.Shared.Config "$G/Config.luau" ReplicatedStorage.Shared.PixelText "$G/PixelText.luau" \
  ServerScriptService.ProfileStore Vendor/ProfileStore.luau ServerScriptService.HubBuilder "$G/HubBuilder.luau" ServerScriptService.PixelServer "$G/PixelServer.server.luau" \
  StarterPlayer.StarterPlayerScripts.PixelClient "$G/PixelClient.client.luau"
# model asset ids from the 2026-11-08 round-3 upload (tools/uploads.json)
for pair in HeartGemPickaxe:101768114810250 StarlightPickaxe:81295531773852 MoonlitPickaxe:70495499058268 RoseThornPickaxe:112314007926438 \
            PearlTidePickaxe:72299060876910 GalaxyPickaxe:116319680368162 SakuraPickaxe:105086268168654 LotusCrystalPickaxe:108157861136669 \
            RoyalHeartPickaxe:116953172891323 SilverWingPickaxe:82182646923493; do
  n=${pair%%:*}; id=${pair##*:}
  python tools/studio_live.py insert_asset "{\"assetId\": \"$id\", \"assetType\": \"Model\", \"assetName\": \"$n\", \"parentPath\": \"ServerStorage.Pickaxes\"}" | grep -o '"status":"[a-z]*"'
done
python tools/studio_live.py execute_luau --file "$G/install_pickaxes.luau" code '{"datamodel_type": "Edit"}'
printf 'local n = 0\nfor _, d in game.ServerStorage.Pickaxes:GetDescendants() do if d:IsA("SurfaceAppearance") then d:Destroy(); n += 1 end end\nreturn "removed " .. n\n' > "$T/rmsa.luau"
python tools/studio_live.py execute_luau --file "$T/rmsa.luau" code '{"datamodel_type": "Edit"}'
rm -rf "$T"
