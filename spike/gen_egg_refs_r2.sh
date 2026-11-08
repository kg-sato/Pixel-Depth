# Egg references round 2: Gemini r1 asked for real cubic stepping on every egg (art/eggs/grades/eggs_r1.md)
cd /c/Users/kgsat/Documents/Roblox
STYLE="isometric 3D voxel art, the whole egg is built from visible chunky cubes with stepped pixel edges like a MagicaVoxel model, no smooth surfaces, per-cube colour variation, soft ambient occlusion, hue-shifted pastel night palette with lilac and plum shadows, three-quarter view from slightly above, the egg stands on a small round voxel stone plinth, centered, dark plum background #2a1f40, game asset render, clean, no text."
gen() { python tools/comfy_wide.py "pdegg2_$1" "$2 $STYLE" --w 1024 --h 1024 --variants 2 --seed $3; }
gen 01_fossil "A cream sandstone voxel egg with a stepped cubic ammonite spiral carved into its blocks and a few bone-white cubes, a tuft of voxel moss at the base." 201
gen 02_moss "A lilac stone voxel egg wrapped in orthogonal cubic green vine tendrils with blocky pixel leaves and two glowing mint bud cubes." 211
gen 03_ember "A dark plum basalt voxel egg covered all over in thin glowing orange and rose magma fissures between its cubes, a few ember cubes rising." 221
gen 04_crystal "A lilac voxel egg with stepped cubic amethyst crystal clusters protruding from its surface, violet and plum shading." 231
gen 05_tide "A teal tile voxel egg with a blocky white seafoam wave crest that sticks out past the egg's outline, pale blue highlights." 241
gen 06_gold "A warm butter-gold voxel egg with a stepped square spiral relief and an inset square gem socket holding a glowing rose crystal cube." 251
gen 07_obsidian "A glossy jet-black voxel obsidian egg with sharp reflective block facets, lilac rim light, and one inset glowing amber eye made of square pixels." 261
gen 08_cosmic "A deep plum-black voxel egg with a pixelated galaxy spiral of tiny glowing star cubes, and chunky stepped voxel smoke rings curling around it." 271
gen 09_prism "A mythic voxel egg covered in cubic scales in a pastel gradient from rose to mint to butter to sky blue, sparkling cube highlights." 281
gen 10_bone "A cream voxel egg seated in a blocky briar nest of square twigs, a chunky low-resolution voxel dragon skull resting on top of the egg." 291
echo DONE
