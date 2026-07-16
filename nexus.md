# PleasureLib

Small shared UE4SS Lua helper library for Gothic 1 Remake mods.

PleasureLib is not a gameplay mod by itself. It is a lightweight dependency for
mods that want to share the same defensive Lua helpers instead of copying the
same code into every project.

## What It Does

PleasureLib currently provides generic helpers for:

- Mod-prefixed logging
- Safe `pcall` wrappers
- Simple INI parsing
- Targeted INI value updates without discarding comments or unrelated options
- Boolean and list parsing
- Text file read/write helpers
- Defensive UE object validation
- UE4SS wrapper unwrapping
- Cached `StaticFindObject` lookup
- Safe `FindAllOf` access
- Delayed callbacks and game-thread callbacks
- Defensive hook registration
- Focused runtime capture of newly created UE objects
- Localized native ON/OFF settings on a dedicated Settings -> Mods page

The native settings API activates the game's unused native test page as a
dedicated Mods category. It creates native settings rows and boolean widgets,
groups them by mod, and can persist changes to a mod INI.

Version 0.4.0 moves mod settings out of the vanilla Game page. The dedicated
Mods page owns its complete row container, avoiding conflicts with category
reinitialization and allowing every mod to receive its own section.

The library intentionally avoids mod-specific gameplay behavior. It is meant to
stay small, boring, and reusable.

## Requirements

- Gothic 1 Remake
- UE4SS
- A mod that uses PleasureLib

## Installation

Extract the archive into the UE4SS mods folder:

```text
G1R/Binaries/Win64/ue4ss/Mods/PleasureLib/
```

The final folder should contain:

```text
PleasureLib/
  enabled.txt
  readme.txt
  Scripts/
    main.lua
    pleasure_lib.lua
```

## Load Order

If you maintain `Mods/mods.txt`, you can place PleasureLib before mods that use
it:

```text
PleasureLib : 1
SomeDependentMod : 1
```

However, supported dependent mods should also include their own fallback loader.
That fallback allows them to load PleasureLib from the neighboring mod folder
even when `mods.txt` was not edited manually.

## For Players

Install this only when another mod lists PleasureLib as a requirement. You do
not need to configure anything else.

If a dependent mod reports that PleasureLib could not be loaded, check that both
folders are next to each other in the UE4SS mods directory:

```text
Mods/PleasureLib/
Mods/TheOtherMod/
```

## For Mod Authors

Use a tiny loader in your mod and create a local runtime:

```lua
local pleasureLib = require("pleasure_lib_loader").new("MyMod")
if type(pleasureLib) ~= "table" then return end

pleasureLib:log("loaded")
local object = pleasureLib:find_object("/Game/Some/Object.Path")
```

The preferred API is the per-mod runtime instance (`pleasureLib:*`). Static
helpers on `_G.PleasureLib` exist for compatibility, but the runtime keeps the
log prefix and object cache scoped to your mod.

See the [PleasureLib Wiki](https://github.com/89pleasure/G1R-PleasureLib/wiki)
for installation, the recommended loader, API documentation, and recipes.

For a localized native boolean option, use
`runtime:register_game_bool_setting(options)`. It supports getter/setter
callbacks, localized names and descriptions, an optional default, and optional
INI persistence.

## Compatibility

PleasureLib is plain Lua for UE4SS. It does not overwrite game assets and does
not patch gameplay by itself.

Because this is a shared dependency, multiple mods can load it. The library is
idempotent and returns the existing global instance when the same version has
already been loaded.

## Uninstallation

Remove the `PleasureLib` folder from the UE4SS mods directory.

Do not remove it while installed mods still list it as a requirement.

## Current Version

`0.4.0`

## Credits

Created by Lenna for Gothic 1 Remake UE4SS mods.
