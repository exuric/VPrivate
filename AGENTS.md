# Larp V4 project

Private Roblox Luau codebase: GUI (guis/larp2.lua), game modules
(games/<PlaceId>.lua), shared libraries (libraries/), loader
(init.lua/main.lua). Short lowercase commits to main, regenerating
profiles/manifest.txt and bumping profiles/commit.txt each time. Verify
.lua edits with tools/balcheck2.py before committing.
main.lua + init.lua are GENERATED: edit tools/src/main.lua or
tools/src/init.lua, then run python tools/obfuscate.py on it and
python tools/verify_obf.py to prove the output before committing.
