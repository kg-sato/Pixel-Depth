# Pixel-_ (new Roblox game, started 2026-11-07)

Working title "Pixel Depths" (folder name Pixel-_; second word still open). Status: **prototype 1** (first-minute loop works in Studio). Spec: `Roblox Dev/Projects/Pixel-_/Briefs/Game Spec v1 for Gemini.md`; current state and gaps: `Roblox Dev/Projects/Pixel-_/Prototype 1 Status.md`.

- Place: `Pixel Depth.rbxlx` (folder renamed from `Pixel-_` on 2026-11-08; open it in Studio; scripts are mirrored in `src/`: `Config.luau` = ReplicatedStorage.Shared.Config, `PixelText.luau` = ReplicatedStorage.Shared.PixelText (Pixelify Sans bitmap font), `PixelServer.server.luau` = ServerScriptService.PixelServer, `PixelClient.client.luau` = StarterPlayerScripts.PixelClient). Push with `..\..\tools\studio_push.py`; test the first minute with `spike/play_test.py <UserId>`. An empty place is rebuilt from the repo with `sh spike/rebuild_place.sh` (scripts, ProfileStore, the ten pickaxe models).
- Pickaxes: `blender/` (builder `pickaxe_hero.py`, `specs/`, `build_all.sh`, outputs in `blender/out/`); 3D viewer https://claude.ai/artifact/PztRmp6gewqeNx9GV3apsK.
- **All UI and art come from the Claude Design board only (the user, 2026-11-08):** https://claude.ai/artifact/PuHdRUnt1QTJcf5sxtyQT1. Change the board first, then build Roblox from it. Exports for Roblox: `art/board_export/`.
- World technique (spike, 2026-11-07): one Part per block, rows windowed around the player; not Terrain, not EditableMesh.

This folder is the game only (its own git repo, branch `main`, local only for now: no GitHub remote yet). The shared Roblox workspace is the parent `C:\Users\kgsat\Documents\Roblox`; its `CLAUDE.md` loads together with this one and holds the general rules (skill router, vault first, grading, uploads, hardware). Use the shared tools from there (`..\..\tools\studio_live.py`, `..\..\tools\agy_task.py`, `..\..\Hunyuan3D`, `..\..\ComfyUI`, `..\..\UI Kit`, ...).

## Where things go
- Code, place file (`Pixel-_.rbxl` once created), Studio exports, refs, captures, this game's scripts and outputs: here.
- Notes: the vault at `..\..\Roblox Dev\Projects\Pixel-_\` (hub `Pixel-_ Hub.md`; Backlog, Systems, Bug Log, Briefs, Game Design Doc as the game grows). Shared lessons go to `Roblox Dev/Research/`.
- Generated art and models from the shared generators: copy the results into this folder (`outputs/`), not into the generators' own folders.

## Lessons carried over from the archived xianxia game (`..\Xianxia`)
- Pick an art style we can build reliably: avoid hand-modelled organic hero assets (hair, fur, dragons) as the core of the look.
- For any model from concept art: trace every part on each view at zoom with a grid and overlay the trace before building; keep each part under its triangle budget so nothing gets decimated.
- Keep the setup lean: one folder, one repo, few standing rules. Add rules here only when the user states them.
