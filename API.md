# PleasureLib API

PleasureLib is a small UE4SS Lua helper library for Gothic 1 Remake mods. It is
intended to centralize generic, defensive helper code that multiple mods can
share without depending on one specific mod's behavior.

Current version: `0.2.0`

## Recommended Usage

Use a small loader file in your mod and create a local instance for your mod:

```lua
local pleasureLib = require("pleasure_lib_loader").new("MyMod")
if type(pleasureLib) ~= "table" then return end
```

Then call helpers through that local instance:

```lua
local config = pleasureLib:parse_ini(pleasureLib:read_text_file(config_path))
local npc = pleasureLib:find_object("/Game/Some/Object.Path")

pleasureLib:register_hook("/Script/Engine.PlayerController:ClientRestart", function()
    pleasureLib:log("hook fired")
end)
```

This keeps mod-specific state, such as the log prefix and object cache, scoped to
your mod.

## Installation Layout

Players should have PleasureLib installed next to the consuming mod:

```text
G1R/Binaries/Win64/ue4ss/Mods/PleasureLib/
G1R/Binaries/Win64/ue4ss/Mods/MyMod/
```

The recommended loader first uses `_G.RequirePleasureLib` or `_G.PleasureLib`
when PleasureLib has already been loaded by UE4SS. If not, it tries
`require("pleasure_lib")` and finally falls back to loading the neighboring
`PleasureLib/Scripts/pleasure_lib.lua` file directly. This means your mod can
still work even if the player did not maintain `mods.txt`.

## Constructor

### `PleasureLib.new(options)`

Creates a per-mod runtime instance.

Parameters:

- `options.mod` or `options.mod_name`: log prefix for this mod.
- `options.debug`: set to `true` to enable debug logging.

Returns:

- A runtime table with the instance methods listed below.

Example:

```lua
local runtime = PleasureLib.new({ mod = "MyMod", debug = false })
```

## Runtime Methods

### Logging And Errors

#### `runtime:log(message)`

Prints a UE4SS log line prefixed with the runtime mod name.

#### `runtime:set_debug(value)`

Enables debug logging when `value == true`; disables it otherwise.

#### `runtime:debug_log(message)`

Logs a debug message only when debug mode is enabled.

#### `runtime:safe(label, fn)`

Runs `fn` through `pcall`. On success, returns the function result. On failure,
logs a readable error with `label` and returns `nil`.

#### `runtime:try(fn)`

Runs `fn` through `pcall`. On success, returns the function result. On failure,
returns `nil` without logging.

### Strings And Config

#### `runtime:trim(value)`

Returns `value` as a string with leading and trailing whitespace removed.

#### `runtime:lower(value)`

Trims `value` and converts it to lowercase.

#### `runtime:upper(value)`

Trims `value` and converts it to uppercase.

#### `runtime:parse_bool(value, default)`

Parses common boolean strings.

Truthy values: `true`, `1`, `yes`, `on`

Falsy values: `false`, `0`, `no`, `off`

Returns `default` when the value is empty or unknown.

#### `runtime:parse_ini(content)`

Parses simple `KEY=value` style INI content into a table with uppercase keys.
Blank lines, section headers, and lines starting with `;` or `#` are ignored.

#### `runtime:split_list(value, separator_pattern)`

Splits a string into a trimmed array. By default this expects semicolon-separated
values.

Example:

```lua
local entries = pleasureLib:split_list("A; B; C")
```

#### `runtime:copy_array(values)`

Returns a shallow copied array using `ipairs`.

### Files

#### `runtime:script_directory(stack_level)`

Returns the directory of the calling Lua file. When called as a normal instance
method, no argument is needed.

#### `runtime:read_text_file(path)`

Reads an entire text file. Returns the content string or `nil`.

#### `runtime:write_text_file(path, content)`

Writes text content to a file. Returns `true` on success and `false` on failure.

### Unreal And UE4SS Helpers

#### `runtime:unwrap(value)`

Attempts to unwrap UE4SS wrapper objects by calling `get()` or `Get()` when
available. Primitive values are returned unchanged.

#### `runtime:is_valid(object)`

Defensively checks whether a UE object looks usable. It first tries `IsValid()`
and then falls back to checking whether `GetFullName()` can be called.

#### `runtime:safe_to_string(value)`

Converts a value to string through `pcall`. Returns a fallback string if the
value cannot be printed safely.

#### `runtime:full_name(object)`

Returns `GetFullName()` for a valid object, then falls back to `GetName()`, and
finally to an empty string.

#### `runtime:find_object(path)`

Finds an object with `StaticFindObject` and caches valid results per runtime
instance. It tries both common UE4SS call styles:

```lua
StaticFindObject(nil, nil, path, false)
StaticFindObject(path)
```

Returns the object or `nil`.

#### `runtime:find_all_of(class_name)`

Calls `FindAllOf(class_name)` when available. Always returns a table; returns an
empty table when UE4SS does not provide the function or the call fails.

#### `runtime:capture_new_objects(options, on_complete)`

Captures UE objects that appear after a baseline scan. This is useful for
focused runtime tracing after a menu action, spawn, load, or interaction.

Options:

- `filter(object)`: optional predicate. Return `true` to include an object.
- `key(object)`: optional stable key function. Defaults to `full_name`.
- `sample_delays_ms`: optional array of sampling delays. Defaults to
  `{ 50, 150, 300, 500 }`.
- `finish_delay_ms`: optional completion delay. Defaults to the last sample
  delay plus 50 ms.

Callback:

```lua
pleasureLib:capture_new_objects({
    filter = function(object)
        return string.find(pleasureLib:full_name(object), "BP_Item", 1, true) ~= nil
    end,
}, function(results)
    for _, entry in ipairs(results) do
        pleasureLib:log(entry.key)
    end
end)
```

Returns:

- A handle with `cancel()` when capture starts.
- `nil` when `ForEachUObject` or the callback is unavailable.

### Timing And Hooks

#### `runtime:delay(ms, fn)`

Runs `fn` with `ExecuteWithDelay` when available. Returns `true` when scheduled,
otherwise `false`.

#### `runtime:delay_game_thread(ms, fn)`

Schedules `fn` on the game thread when possible. It prefers
`ExecuteInGameThreadWithDelay`, then falls back to `ExecuteWithDelay` plus
`ExecuteInGameThread`, and finally runs through a delayed safe callback when no
game-thread helper exists.

Returns `true` when scheduled, otherwise `false`.

#### `runtime:register_hook(path, handler)`

Registers a UE4SS hook through `RegisterHook`. Logs a readable error on failure.
Returns `true` on success and `false` on failure.

## Static Exports

PleasureLib also exposes some helpers directly on `_G.PleasureLib`, for example
`PleasureLib.trim`, `PleasureLib.parse_ini`, and `PleasureLib.is_valid`.

These exist for compatibility and simple utility use. For normal mod code,
prefer `PleasureLib.new(...)` and use the returned local runtime instance.

## Hot Reload Notes

PleasureLib is idempotent. If the same version has already been loaded, loading
`pleasure_lib.lua` again returns the existing `_G.PleasureLib` table.

Each call to `PleasureLib.new(...)` creates a fresh per-mod runtime with its own
log prefix, debug flag, and object cache. This makes reload behavior predictable
for consuming mods.

