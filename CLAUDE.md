# Pixel-_ (new Roblox game, started 2026-11-07)

Working title "Pixel-_"; the second word is still open. Status: **concept research**, nothing built yet. The idea is being researched in a separate chat ("Pixel-_ game idea: research a new Roblox market"); its findings go to the vault note `Roblox Dev/Projects/Pixel-_/Game Idea Research.md`. Do not start building until the user has picked the concept.

This folder is the game only (its own git repo, branch `main`, local only for now: no GitHub remote yet). The shared Roblox workspace is the parent `C:\Users\kgsat\Documents\Roblox`; its `CLAUDE.md` loads together with this one and holds the general rules (skill router, vault first, grading, uploads, hardware). Use the shared tools from there (`..\..\tools\studio_live.py`, `..\..\tools\agy_task.py`, `..\..\Hunyuan3D`, `..\..\ComfyUI`, `..\..\UI Kit`, ...).

## Where things go
- Code, place file (`Pixel-_.rbxl` once created), Studio exports, refs, captures, this game's scripts and outputs: here.
- Notes: the vault at `..\..\Roblox Dev\Projects\Pixel-_\` (hub `Pixel-_ Hub.md`; Backlog, Systems, Bug Log, Briefs, Game Design Doc as the game grows). Shared lessons go to `Roblox Dev/Research/`.
- Generated art and models from the shared generators: copy the results into this folder (`outputs/`), not into the generators' own folders.

## Lessons carried over from the archived xianxia game (`..\Xianxia`)
- Pick an art style we can build reliably: avoid hand-modelled organic hero assets (hair, fur, dragons) as the core of the look.
- For any model from concept art: trace every part on each view at zoom with a grid and overlay the trace before building; keep each part under its triangle budget so nothing gets decimated.
- Keep the setup lean: one folder, one repo, few standing rules. Add rules here only when the user states them.
