# Egg references round 4: the seven eggs still under 8 after round 3; each prompt keeps the winning design and pushes palette and cube clarity
cd /c/Users/kgsat/Documents/Roblox
STYLE="isometric 3D voxel art, the whole egg is built from visible chunky cubes with stepped pixel edges like a MagicaVoxel model, no smooth surfaces, per-cube colour variation, soft ambient occlusion, cosy hue-shifted pastel night palette with lilac and plum shadows and soft rim light, three-quarter view from slightly above, the egg stands on a small round voxel stone plinth, centered, dark plum background #2a1f40, game asset render, clean, no text."
gen() { python tools/comfy_wide.py "pdegg4_$1" "$2 $STYLE" --w 1024 --h 1024 --variants 2 --seed $3; }
gen 02_moss "A pale lilac brick voxel egg with chunky mint voxel leaf clusters and soft green moss cubes growing over one side, a few tiny pink flower cubes." 411
gen 03_ember "A dark plum basalt voxel egg split by glowing butter-yellow and warm rose magma seams between its big cubes, a few glowing ember cubes floating above." 421
gen 04_crystal "A lilac brick voxel egg with a crown of chunky violet amethyst crystal cubes bursting from its top and side, crystals glowing softly." 431
gen 06_gold "A butter-gold voxel egg with stepped square terraces opening into a square window that holds a floating glowing rose gem cube." 451
gen 07_obsidian "A black and deep plum brick voxel egg with a square opening framed in glowing rose, inside it a floating butter-amber eye cube with a dark slit pupil." 461
gen 08_cosmic "A deep plum voxel egg whose front opens into stepped cubic rings like a portal, glowing violet and rose star cubes swirling inside like a galaxy." 471
gen 10_bone "A cream voxel egg with a chunky cubic horned dragon skull on top, the egg sits on stacked blocky timber logs with lilac crystal cubes, bone white and butter tones." 491
echo DONE
