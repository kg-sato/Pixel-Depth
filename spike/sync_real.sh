#!/bin/sh
# Copy tonight's work from this session clone into the real Games/Pixel Depth folder (the user's OK, 2026-11-09: the session
# hook refuses the file tools there). Only files git sees as changed or new under src/ and spike/; never the place file.
C="$(cd "$(dirname "$0")/.." && pwd)"; R="/c/Users/kgsat/Documents/Roblox/Games/Pixel Depth"
cd "$C" && git status --porcelain -- src spike | cut -c4- | tr -d '"' | while read -r f; do
	cmp -s "$C/$f" "$R/$f" || { cp "$C/$f" "$R/$f" && echo "synced $f"; }
done
