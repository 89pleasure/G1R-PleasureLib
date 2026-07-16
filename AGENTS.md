# Repository Guidelines

This repository contains `PleasureLib`, a small UE4SS Lua helper mod for Gothic
1 Remake mods.

- Runtime code lives in `package/PleasureLib/Scripts/pleasure_lib.lua`.
- Keep the API generic; do not add behavior that belongs to only one mod.
- Keep helpers defensive around UE4SS and Unreal objects.
- Prefer ASCII in source and docs.
- Package output is `package/PleasureLib.zip`; do not edit it by hand.
- Before changing the custom in-game settings navigation, read
  `SETTINGS_UI_DECISIONS.md` and treat its failed approaches as a hard
  exclusion list unless new evidence explicitly invalidates an entry.
