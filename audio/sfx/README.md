# Sound effects (2026-11-10)

Soft, cute UI and impact sounds. All from Kenney's packs (kenney.nl, Creative Commons Zero: no credit needed, kept here anyway).
`audio/pd_sfx.py <out folder>` trims, fades and levels the picked files (peak 0.85; the pack files clip above 1.0); it expects the
unpacked packs in `./kenney/`. Uploaded with `tools/upload_asset.py` (logged in `tools/uploads.json`). The ids are used in the `SFX`
table of `src/PixelClient.client.luau`.

| name | pack | file | asset id | used for |
|---|---|---|---|---|
| click | Interface Sounds | drop_001 | 118078655883816 | buttons |
| tab | Interface Sounds | select_005 | 108382314361659 | quest tabs |
| open | Interface Sounds | maximize_007 | 122439587120394 | a panel opens |
| close | Interface Sounds | minimize_007 | 139837639994797 | a panel closes |
| pop | Interface Sounds | drop_003 | 98559989688124 | toasts |
| error | Interface Sounds | error_004 | 129224473501721 | not enough coins or ore |
| coin | Interface Sounds | glass_005 | 130614539116248 | coins |
| sparkle | Interface Sounds | glass_004 | 96727638802500 | sparkles, stars |
| upgrade | Interface Sounds | confirmation_002 | 124702248480385 | upgrades, forge |
| pluck | Interface Sounds | pluck_002 | 80200426277557 | egg found |
| hit | Impact Sounds | impactMining_002 | 84749599799318 | pickaxe hit |
| breakRock | Impact Sounds | impactMining_004 | 73576495438405 | rock breaks |
| clink | Impact Sounds | impactGlass_light_001 | 109535777937742 | crit, hammer |
| step | Impact Sounds | footstep_concrete_000 | 101247424367019 | footsteps (Juice) |
| land | Impact Sounds | impactSoft_medium_000 | 88699226385252 | landing (Juice) |
| swing | RPG Audio | cloth1 | 82582582223321 | pickaxe swing |
| claim | Music Jingles | jingles_PIZZI00 | 93961639592928 | quest claimed |
| hatch | Music Jingles | jingles_STEEL00 | 90744422601646 | egg hatches |

Not heard by Claude: picked by name, length and brightness (measured), all 18 load in Play. Volumes are first guesses.
The minecart ride and escape loops (rumble, thud) still use Creator Store audio.
