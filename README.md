# PleasureLib

Shared UE4SS Lua helpers for Lenna's Gothic 1 Remake mods.

This is a small dependency-style mod intended to reduce repeated defensive Lua
code across mods. It deliberately contains only generic helpers: logging,
`pcall` wrappers, INI parsing, UE object validation, `StaticFindObject` fallback
lookup, delayed callbacks, and hook registration.

## Documentation

- [API documentation](API.md)
- [NexusMods description draft](nexus.md)
- [NexusMods BBCode description](nexus_description.bbcode)

## Installation

Copy `package/PleasureLib` into the game's UE4SS mods directory:

```text
G1R/Binaries/Win64/ue4ss/Mods/PleasureLib/
```

Mods can then load it with:

```lua
local pleasureLib = require("pleasure_lib_loader").new("MyMod")
if type(pleasureLib) ~= "table" then return end
```

For load-order-independent mods, include a tiny `pleasure_lib_loader.lua` next
to the mod's `main.lua`. The loader first uses `_G.RequirePleasureLib` or
`_G.PleasureLib` when the shared mod already loaded, then tries
`require("pleasure_lib")`, and finally falls back to
`../PleasureLib/Scripts/pleasure_lib.lua` from the neighboring mod folder.

The library is idempotent and returns the existing global instance when it has
already been loaded.

`runtime:capture_new_objects(options, callback)` records a UObject baseline and
returns only matching objects that appear during a short sampling window.
Options include `filter`, `key`, `sample_delays_ms`, and `finish_delay_ms`; the
returned handle provides `cancel()`. This supports focused runtime tracing
without dumping all loaded objects.

Example loader:

```lua
local Loader = {}

local function script_directory()
    local ok, info = pcall(function()
        return debug.getinfo(1, "S")
    end)
    if not ok or not info or not info.source then return nil end

    local source = tostring(info.source)
    if source:sub(1, 1) == "@" then source = source:sub(2) end
    return source:match("^(.*[\\/])[^\\/]*$")
end

function Loader.load()
    if type(_G.RequirePleasureLib) == "function" then
        local lib = _G.RequirePleasureLib()
        if type(lib) == "table" then return lib end
    end
    if type(_G.PleasureLib) == "table" then return _G.PleasureLib end

    local ok, lib = pcall(require, "pleasure_lib")
    if ok and type(lib) == "table" then return lib end

    local dir = script_directory()
    if dir then
        ok, lib = pcall(dofile, dir .. "..\\..\\PleasureLib\\Scripts\\pleasure_lib.lua")
        if ok and type(lib) == "table" then return lib end
    end
    return nil
end

function Loader.load_or_log(mod_name)
    local lib = Loader.load()
    if type(lib) ~= "table" then
        print("[" .. tostring(mod_name or "Mod") .. "] PleasureLib is required but could not be loaded.\n")
        return nil
    end
    return lib
end

function Loader.new(mod_name, options)
    local lib = Loader.load_or_log(mod_name)
    if type(lib) ~= "table" then return nil end

    options = options or {}
    options.mod = options.mod or mod_name
    return lib.new(options)
end

return Loader
```

## Current Status

Prototype. Keep the API small until at least two mods use the same helper
without needing mod-specific behavior.

## Nexus Assets

Nexus image assets are stored in `assets/nexus` and can be regenerated with:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\generate_nexus_assets.ps1
```
