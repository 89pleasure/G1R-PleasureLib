# PleasureLib API

PleasureLib is a small UE4SS Lua helper library for Gothic 1 Remake mods. It is
intended to centralize generic, defensive helper code that multiple mods can
share without depending on one specific mod's behavior.

Current version: `0.3.31`

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

#### `runtime:update_ini_value(path, key, value)`

Updates the first matching `key=value` line in an existing INI file without
discarding its other lines or comments. The key comparison is case-insensitive.
If the key does not exist, it is appended. Returns `true` on success.

### Native Game Settings

#### `runtime:register_game_bool_setting(options)`

Registers a native ON/OFF row under `Settings -> Game -> Mods`. PleasureLib
creates and connects the game's own settings row and boolean widget, so mouse,
keyboard, controller focus, and the settings detail panel use the vanilla UI.

Required options:

- `id`: globally unique, stable setting identifier. Prefix it with the mod name.
- `get()`: returns the current boolean value.
- `set(value)`: applies the new value. Return `false` to reject the change.

Optional options:

- `default`: fallback boolean when `get()` does not return a value.
- `persist.path`: INI path or callback returning the path.
- `persist.key`: INI key or callback returning the key.
- `translations`: localized display names and descriptions by language code.

Translation lookup first tries the complete current language code, then its base
language, then `en`. Gothic 1 Remake language codes such as `de`, `fr`, `it`,
`es`, `pl`, `ru`, `zh-hans`, `ja`, and `pt-br` can be supplied. The `Mods`
section heading is localized by PleasureLib.

Example:

```lua
pleasureLib:register_game_bool_setting({
    id = "MyMod.ShowExtraInfo",
    default = false,
    get = function()
        return config.ShowExtraInfo == true
    end,
    set = function(value)
        config.ShowExtraInfo = value == true
        return true
    end,
    persist = {
        path = function() return config_path end,
        key = "ShowExtraInfo",
    },
    translations = {
        en = {
            name = "Show extra information",
            description = "Shows additional information in the inventory.",
        },
        de = {
            name = "Zusätzliche Informationen anzeigen",
            description = "Zeigt zusätzliche Informationen im Inventar an.",
        },
    },
})
```

The returned handle contains the setting `id` and a `refresh()` function. Call
`refresh()` if the mod changes the value outside the settings menu and the
visible native widget should be synchronized.

Registration is safe before the settings assets are loaded. PleasureLib waits
for the Game settings page and prevents duplicate rows when the page is opened
again. INI persistence occurs when the native toggle reports its change, with a
lifecycle commit when the settings page applies or discards its pending values.

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

#### `runtime:register_hook(path, handler[, post_handler])`

Registers a UE4SS hook through `RegisterHook`. Logs a readable error on failure.
The optional third argument is forwarded as UE4SS's post-handler, which is
required for a true post-hook on native `/Script/` functions.
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
