local VERSION = "0.5.1"

if type(_G) == "table" and type(rawget(_G, "PleasureLib")) == "table"
    and rawget(_G, "PleasureLib").VERSION == VERSION
then
    return rawget(_G, "PleasureLib")
end

local PleasureLib = {
    VERSION = VERSION,
}

local function noop()
end

local function try(fn)
    if type(fn) ~= "function" then return nil end
    local ok, result = pcall(fn)
    if ok then return result end
    return nil
end

local function trim(value)
    return tostring(value or ""):match("^%s*(.-)%s*$")
end

local function lower(value)
    return string.lower(trim(value))
end

local function upper(value)
    return string.upper(trim(value))
end

local function parse_bool(value, default)
    local text = lower(value)
    if text == "" then return default end
    if text == "true" or text == "1" or text == "yes" or text == "on" then
        return true
    end
    if text == "false" or text == "0" or text == "no" or text == "off" then
        return false
    end
    return default
end

local function parse_ini(content)
    local result = {}
    for line in string.gmatch(tostring(content or ""), "[^\r\n]+") do
        local stripped = trim(line)
        if stripped ~= "" and stripped:sub(1, 1) ~= ";"
            and stripped:sub(1, 1) ~= "#"
            and stripped:sub(1, 1) ~= "["
        then
            local key, value = stripped:match("^([%w_%.%-]+)%s*=%s*(.-)%s*$")
            if key and value then
                result[upper(key)] = trim(value)
            end
        end
    end
    return result
end

local function split_list(value, separator_pattern)
    local result = {}
    local pattern = separator_pattern or "([^;]+)"
    for part in string.gmatch(tostring(value or ""), pattern) do
        local text = trim(part)
        if text ~= "" then
            table.insert(result, text)
        end
    end
    return result
end

local function copy_array(values)
    local result = {}
    for _, value in ipairs(values or {}) do
        table.insert(result, value)
    end
    return result
end

local function unwrap(value)
    if value == nil then return nil end
    local kind = type(value)
    if kind == "number" or kind == "string" or kind == "boolean" then
        return value
    end
    if kind == "userdata" or kind == "table" then
        local unwrapped = try(function()
            if type(value.get) == "function" then return value:get() end
            if type(value.Get) == "function" then return value:Get() end
            return value
        end)
        if unwrapped ~= nil then return unwrapped end
    end
    return value
end

local function is_valid_object(object)
    if object == nil then return false end
    if type(object) ~= "userdata" and type(object) ~= "table" then return false end

    local valid = unwrap(try(function()
        if type(object.IsValid) ~= "function" then return nil end
        return object:IsValid()
    end))
    if valid == true then return true end
    if valid == false then return false end

    return try(function()
        if type(object.GetFullName) ~= "function" then return false end
        return object:GetFullName() ~= nil
    end) == true
end

local function safe_to_string(value)
    local ok, text = pcall(function()
        return tostring(value)
    end)
    if ok and text ~= nil then return text end
    return "<unprintable " .. type(value) .. ">"
end

local function object_full_name(object)
    if not is_valid_object(object) then return "" end
    return safe_to_string(try(function()
        if type(object.GetFullName) == "function" then
            return object:GetFullName()
        end
        if type(object.GetName) == "function" then
            return object:GetName()
        end
        return ""
    end) or "")
end

local function script_directory(stack_level)
    local info = try(function()
        if type(debug) ~= "table" or type(debug.getinfo) ~= "function" then
            return nil
        end
        return debug.getinfo(stack_level or 2, "S")
    end)
    if not info or not info.source then return nil end

    local source = tostring(info.source)
    if source:sub(1, 1) == "@" then
        source = source:sub(2)
    end
    return source:match("^(.*[\\/])[^\\/]*$")
end

local function read_text_file(path)
    local file = try(function()
        if type(io) ~= "table" or type(io.open) ~= "function" then return nil end
        return io.open(path, "r")
    end)
    if not file then return nil end

    local content = file:read("*a")
    file:close()
    return content
end

local function write_text_file(path, content)
    local file = try(function()
        if type(io) ~= "table" or type(io.open) ~= "function" then return nil end
        return io.open(path, "w")
    end)
    if not file then return false end

    file:write(tostring(content or ""))
    file:close()
    return true
end

local function update_ini_value(path, key, value)
    path = tostring(path or "")
    key = trim(key)
    if path == "" or key == "" then return false end

    local content = read_text_file(path)
    if content == nil then return false end

    local newline = content:find("\r\n", 1, true) and "\r\n" or "\n"
    local lines = {}
    local replaced = false
    for line in (content .. "\n"):gmatch("(.-)\r?\n") do
        local current_key = line:match("^%s*([%w_%.%-]+)%s*=")
        if not replaced and current_key ~= nil
            and upper(current_key) == upper(key)
        then
            table.insert(lines, key .. "=" .. tostring(value))
            replaced = true
        else
            table.insert(lines, line)
        end
    end

    if #lines > 0 and lines[#lines] == "" then table.remove(lines, #lines) end
    if not replaced then table.insert(lines, key .. "=" .. tostring(value)) end
    return write_text_file(path, table.concat(lines, newline) .. newline)
end

local pleasure_lib_directory = script_directory(1)
if pleasure_lib_directory == nil then
    error("PleasureLib could not resolve its Scripts directory")
end

local settings_factory = dofile(
    pleasure_lib_directory .. "pleasure_lib_settings.lua"
)
if type(settings_factory) ~= "function" then
    error("pleasure_lib_settings.lua must return a factory function")
end

local settings = settings_factory({
    noop = noop,
    try = try,
    trim = trim,
    lower = lower,
    unwrap = unwrap,
    is_valid_object = is_valid_object,
    safe_to_string = safe_to_string,
    object_full_name = object_full_name,
    update_ini_value = update_ini_value,
})
if type(settings) ~= "table"
    or type(settings.register_game_bool_setting) ~= "function"
    or type(settings.register_game_int_setting) ~= "function"
    or type(settings.register_game_float_setting) ~= "function"
    or type(settings.register_game_enum_setting) ~= "function"
then
    error("pleasure_lib_settings.lua returned an invalid settings module")
end

function PleasureLib.new(options)
    options = options or {}
    local mod_name = options.mod_name or options.mod or "PleasureLib"
    local debug_enabled = options.debug == true
    local object_cache = {}

    local runtime = {
        mod_name = mod_name,
        object_cache = object_cache,
    }

    function runtime:log(message)
        print("[" .. tostring(self.mod_name) .. "] " .. tostring(message) .. "\n")
    end

    function runtime:set_debug(value)
        debug_enabled = value == true
    end

    function runtime:debug_log(message)
        if debug_enabled == true then
            self:log("[debug] " .. tostring(message))
        end
    end

    function runtime:safe(label, fn)
        local ok, result = pcall(fn)
        if ok then return result end
        self:log(tostring(label or "operation") .. " failed: "
            .. safe_to_string(result))
        return nil
    end

    function runtime:try(fn)
        return try(fn)
    end

    function runtime:trim(value)
        return trim(value)
    end

    function runtime:lower(value)
        return lower(value)
    end

    function runtime:upper(value)
        return upper(value)
    end

    function runtime:parse_bool(value, default)
        return parse_bool(value, default)
    end

    function runtime:parse_ini(content)
        return parse_ini(content)
    end

    function runtime:split_list(value, separator_pattern)
        return split_list(value, separator_pattern)
    end

    function runtime:copy_array(values)
        return copy_array(values)
    end

    function runtime:unwrap(value)
        return unwrap(value)
    end

    function runtime:is_valid(object)
        return is_valid_object(object)
    end

    function runtime:safe_to_string(value)
        return safe_to_string(value)
    end

    function runtime:full_name(object)
        return object_full_name(object)
    end

    function runtime:script_directory(stack_level)
        return script_directory(stack_level or 3)
    end

    function runtime:read_text_file(path)
        return read_text_file(path)
    end

    function runtime:write_text_file(path, content)
        return write_text_file(path, content)
    end

    function runtime:update_ini_value(path, key, value)
        return update_ini_value(path, key, value)
    end

    function runtime:find_object(path)
        local cached = object_cache[path]
        if is_valid_object(cached) then return cached end
        if type(StaticFindObject) ~= "function" then return nil end

        local object = try(function()
            return StaticFindObject(nil, nil, path, false)
        end)
        if not is_valid_object(object) then
            object = try(function()
                return StaticFindObject(path)
            end)
        end

        if is_valid_object(object) then
            object_cache[path] = object
            return object
        end
        return nil
    end

    function runtime:find_all_of(class_name)
        if type(FindAllOf) ~= "function" then return {} end
        local objects = try(function()
            return FindAllOf(class_name)
        end)
        if type(objects) == "table" then return objects end
        return {}
    end

    function runtime:capture_new_objects(options, on_complete)
        options = options or {}
        if type(ForEachUObject) ~= "function" then
            self:log("ForEachUObject unavailable")
            return nil
        end
        if type(on_complete) ~= "function" then return nil end

        local filter = options.filter
        if type(filter) ~= "function" then filter = function() return true end end
        local key = options.key
        if type(key) ~= "function" then
            key = function(object) return object_full_name(object) end
        end
        local sample_delays = options.sample_delays_ms or { 50, 150, 300, 500 }
        local finish_delay = tonumber(options.finish_delay_ms)
            or ((tonumber(sample_delays[#sample_delays]) or 0) + 50)
        local cancelled = false

        local function scan(target)
            ForEachUObject(function(object)
                if not is_valid_object(object) then return end
                local ok_filter, matches = pcall(filter, object)
                if not ok_filter or matches ~= true then return end
                local ok_key, object_key = pcall(key, object)
                if ok_key and object_key ~= nil and tostring(object_key) ~= "" then
                    target[tostring(object_key)] = object
                end
            end)
        end

        local baseline = {}
        local captured = {}
        scan(baseline)

        local function sample()
            if cancelled then return end
            local current = {}
            scan(current)
            for object_key, object in pairs(current) do
                if baseline[object_key] == nil then captured[object_key] = object end
            end
        end

        for _, delay_ms in ipairs(sample_delays) do
            self:delay_game_thread(tonumber(delay_ms) or 0, sample)
        end
        self:delay_game_thread(finish_delay, function()
            if cancelled then return end
            local results = {}
            for object_key, object in pairs(captured) do
                table.insert(results, { key = object_key, object = object })
            end
            table.sort(results, function(a, b) return a.key < b.key end)
            self:safe("capture-new-objects completion", function()
                on_complete(results)
            end)
        end)

        return { cancel = function() cancelled = true end }
    end

    function runtime:delay(ms, fn)
        if type(fn) ~= "function" then return false end
        if type(ExecuteWithDelay) ~= "function" then return false end
        ExecuteWithDelay(ms, fn)
        return true
    end

    function runtime:delay_game_thread(ms, fn)
        if type(fn) ~= "function" then return false end
        if type(ExecuteInGameThreadWithDelay) == "function" then
            ExecuteInGameThreadWithDelay(ms, function()
                self:safe("delayed game-thread callback", fn)
            end)
            return true
        end
        if type(ExecuteWithDelay) == "function" then
            ExecuteWithDelay(ms, function()
                if type(ExecuteInGameThread) == "function" then
                    ExecuteInGameThread(function()
                        self:safe("delayed game-thread callback", fn)
                    end)
                else
                    self:safe("delayed callback", fn)
                end
            end)
            return true
        end
        return false
    end

    function runtime:register_hook(path, handler, post_handler)
        if type(RegisterHook) ~= "function" then
            self:log("RegisterHook unavailable")
            return false
        end
        local ok, err = pcall(function()
            if type(post_handler) == "function" then
                RegisterHook(path, handler, post_handler)
            else
                RegisterHook(path, handler)
            end
        end)
        if not ok then
            self:log("Could not register hook " .. tostring(path) .. ": "
                .. safe_to_string(err))
            return false
        end
        return true
    end

    runtime.register_game_bool_setting = settings.register_game_bool_setting
    runtime.register_game_int_setting = settings.register_game_int_setting
    runtime.register_game_float_setting = settings.register_game_float_setting
    runtime.register_game_enum_setting = settings.register_game_enum_setting

    return runtime
end

PleasureLib.noop = noop
PleasureLib.try = try
PleasureLib.trim = trim
PleasureLib.lower = lower
PleasureLib.upper = upper
PleasureLib.parse_bool = parse_bool
PleasureLib.parse_ini = parse_ini
PleasureLib.split_list = split_list
PleasureLib.copy_array = copy_array
PleasureLib.unwrap = unwrap
PleasureLib.is_valid = is_valid_object
PleasureLib.safe_to_string = safe_to_string
PleasureLib.full_name = object_full_name
PleasureLib.script_directory = script_directory
PleasureLib.read_text_file = read_text_file
PleasureLib.write_text_file = write_text_file
PleasureLib.update_ini_value = update_ini_value

_G.PleasureLib = PleasureLib

return PleasureLib
