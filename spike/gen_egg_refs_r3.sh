# Egg references round 3: only the five eggs under 7 in Gemini r2 (art/eggs/grades/eggs_r2.md), with its prompt fixes
cd /c/Users/kgsat/Documents/Roblox
STYLE="isometric 3D voxel art, the whole egg is built from visible chunky cubes with stepped pixel edges like a MagicaVoxel model, no smooth surfaces, per-cube colour variation, soft ambient occlusion, hue-shifted pastel night palette with lilac and plum shadows, three-quarter view from slightly above, the egg stands on a small round voxel stone plinth, centered, dark plum background #2a1f40, game asset render, clean, no text."
gen() { python tools/comfy_wide.py "pdegg3_$1" "$2 $STYLE" --w 1024 --h 1024 --variants 2 --seed $3; }
gen 02_moss "A lilac and plum stone voxel egg with stepped cubic moss patches and chunky 3D voxel leaf clusters climbing it like blocky pixel ivy terraces, mint voxel foliage, strictly no thin vines or tendrils." 311
gen 03_ember "A chunky cubic basalt egg of dark plum and deep lilac stone blocks with glowing magma seams in soft butter yellow and warm rose between the cubes, no pitch black, no neon red." 321
gen 05_tide "A voxel tide egg with a curling ocean wave built from stepped cubic blocks wrapping around it, translucent mint and aqua voxel splash, butter-cream cubic foam crest, zero smooth curves." 341
gen 07_obsidian "A dark obsidian egg built from staggered cubic bricks with deep plum edge bevels and a central square opening revealing a floating glowing butter-amber voxel eye cube." 361
gen 10_bone "A chunky cream voxel egg topped with a stylized cubic horned dragon skull, resting on a pedestal of stacked blocky timber logs, bone-white and butter with lilac shading in the gaps, no thin twigs." 391
echo DONE
