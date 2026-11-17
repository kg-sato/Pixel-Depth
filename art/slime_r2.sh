# Render every slime glyph set and the loading logo letters (about 30 min on the RTX 4060 Ti). Run from the game folder.
B="/c/Users/kgsat/Downloads/blender-5.3.0-beta+v53.32f5c9c48bca-windows.amd64-release/blender-5.3.0-beta+v53.32f5c9c48bca-windows.amd64-release/blender.exe"
ALL="ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!?+%:-/.',()&<>="
"$B" -b -P art/pd_slime_glyphs.py -- art/slime_logo "PIXELDHT~" pink 512 > /dev/null 2>&1; echo logo
"$B" -b -P art/pd_slime_glyphs.py -- art/slime_pink "$ALL" pink 256 > /dev/null 2>&1; echo pink
