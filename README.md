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

## Current Status

Prototype. Keep the API small until at least two mods use the same helper
without needing mod-specific behavior.

## Nexus Assets

Nexus image assets are stored in `assets/nexus` and can be regenerated with:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\generate_nexus_assets.ps1
```
