# Egg references for the 3D egg models (the user's Pinterest pins in art/eggs/refs/pin1-5.jpg), local FLUX via tools/comfy_wide.py
cd /c/Users/kgsat/Documents/Roblox
STYLE="single voxel egg, MagicaVoxel render, chunky cubes with per-cube colour variation, soft ambient occlusion, hue-shifted pastel night palette with lilac and plum shadows, three-quarter view from slightly above, the egg stands on a small round stone plinth, centered, dark plum background #2a1f40, game asset render, clean, highly detailed, no text."
gen() { python tools/comfy_wide.py "pdegg_$1" "$2 $STYLE" --w 1024 --h 1024 --variants 2 --seed $3; }
gen 01_fossil "A cream fossil egg with an ammonite spiral imprint and tiny bone fragments pressed into the shell, mossy at the base." 101
gen 02_moss "A mossy root egg wrapped in twisting green vines with small leaves and a few glowing mint buds." 111
gen 03_ember "A dark basalt egg with a cracked crust and bright orange lava glowing through the cracks, tiny embers rising." 121
gen 04_crystal "A lilac crystal egg made of faceted amethyst scales, with small crystal shards growing out of its side." 131
gen 05_tide "A teal tide egg with a swirling white wave pattern wrapped around it, droplets and a pale blue shine." 141
gen 06_gold "A golden spiral egg with a carved gold spiral relief and a ruby set in the centre, warm glints." 151
gen 07_obsidian "A glossy black obsidian egg with a single glowing amber dragon eye socket set into the shell." 161
gen 08_cosmic "A cosmic void egg, black shell full of tiny stars and a grey nebula swirl, wisps of pale smoke curling around it." 171
gen 09_prism "A mythic prism egg covered in pastel rainbow scales, pink to mint to sky blue, sparkling." 181
gen 10_bone "A secret bone egg cradled by a small curled dragon skeleton, pale ivory skull resting on top, thorny twigs nest." 191
echo DONE
