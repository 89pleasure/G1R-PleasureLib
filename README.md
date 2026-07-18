# PleasureLib

Shared UE4SS Lua helpers for Gothic 1 Remake mods.

PleasureLib reduces repeated defensive Lua code across mods. It deliberately
contains only generic helpers: logging, protected calls, INI parsing and
updates, UE object validation and lookup, delayed callbacks, hook registration,
runtime object capture, and native mod settings on a dedicated Mods page in the
game's settings menu.

## Documentation

The [PleasureLib Wiki](https://github.com/89pleasure/G1R-PleasureLib/wiki) is
the canonical documentation:

- [Installation](https://github.com/89pleasure/G1R-PleasureLib/wiki/Installation)
- [Getting started](https://github.com/89pleasure/G1R-PleasureLib/wiki/Getting-Started)
- [Recommended loader](https://github.com/89pleasure/G1R-PleasureLib/wiki/Recommended-Loader)
- [API: core utilities](https://github.com/89pleasure/G1R-PleasureLib/wiki/API-Core-Utilities)
- [API: Unreal and runtime](https://github.com/89pleasure/G1R-PleasureLib/wiki/API-Unreal-and-Runtime)
- [Native game settings](https://github.com/89pleasure/G1R-PleasureLib/wiki/Native-Game-Settings)
- [Recipes](https://github.com/89pleasure/G1R-PleasureLib/wiki/Recipes)

Repository maintenance files:

- [NexusMods description draft](nexus.md)
- [NexusMods BBCode description](nexus_description.bbcode)

## Quick Start

Copy `package/PleasureLib` into the game's UE4SS mods directory:

```text
G1R/Binaries/Win64/ue4ss/Mods/PleasureLib/
```

Mods should include the recommended `pleasure_lib_loader.lua` and create a
local runtime instance:

```lua
local pleasureLib = require("pleasure_lib_loader").new("MyMod")
if type(pleasureLib) ~= "table" then return end

pleasureLib:log("loaded")
```

The loader makes consuming mods independent of `mods.txt` load order. See the
[Getting Started](https://github.com/89pleasure/G1R-PleasureLib/wiki/Getting-Started)
guide for the complete setup.

## Native Settings API

Runtime instances expose the game's four native value types:

- `register_game_bool_setting(options)`
- `register_game_int_setting(options)` with `minimum`, `maximum`, and `default`
- `register_game_float_setting(options)` with `minimum`, `maximum`, `step`,
  `default`, and optional `always_show_sign`
- `register_game_enum_setting(options)` with a `values` list, a zero-based
  numeric value, and `widget = "spinner"` or `widget = "dropdown"`

Every registration requires a stable `id` plus `get()` and `set(value)`
callbacks. The existing `section`, `translations`, and `persist` options are
shared by all four types.

## Current Status

Stable. Current version: `0.5.0`.

PleasureLib is used by multiple released mods, including Extended Item
Tooltips, QuickBites, and Let Snaf Cook. The public API remains deliberately
small and generic so consuming mods do not inherit mod-specific behavior.

## Nexus Assets

Nexus image assets are stored in `assets/nexus` and can be regenerated with:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\generate_nexus_assets.ps1
```
