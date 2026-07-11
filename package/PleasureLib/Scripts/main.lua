local function script_directory()
    local ok, info = pcall(function()
        if type(debug) ~= "table" or type(debug.getinfo) ~= "function" then
            return nil
        end
        return debug.getinfo(1, "S")
    end)
    if not ok or not info or not info.source then return nil end

    local source = tostring(info.source)
    if source:sub(1, 1) == "@" then
        source = source:sub(2)
    end
    return source:match("^(.*[\\/])[^\\/]*$")
end

local dir = script_directory()
local ok, lib = false, nil
if dir then
    if type(package) == "table" and type(package.path) == "string" then
        local lib_path = dir .. "?.lua"
        if not string.find(package.path, lib_path, 1, true) then
            package.path = lib_path .. ";" .. package.path
        end
    end

    ok, lib = pcall(dofile, dir .. "pleasure_lib.lua")
end

if ok and type(lib) == "table" then
    _G.PleasureLib = lib
    _G.RequirePleasureLib = function()
        return lib
    end
    print("[PleasureLib] loaded v" .. tostring(lib.VERSION or "unknown") .. "\n")
else
    print("[PleasureLib] failed to load pleasure_lib.lua\n")
end
