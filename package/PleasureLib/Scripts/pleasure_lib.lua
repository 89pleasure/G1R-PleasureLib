local VERSION = "0.3.31"

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

local GAME_SETTINGS_PAGE_CLASS =
    "/Game/UI/CoreMenus/Settings/W_SettingsPage_Game.W_SettingsPage_Game_C"
local GAME_SETTINGS_PAGE_ACTIVATED = GAME_SETTINGS_PAGE_CLASS .. ":BP_OnActivated"
local SETTINGS_PAGE_REINITIALIZE = "/Script/G1R.SettingsPageWidget:Reinitialize"
local SETTINGS_PAGE_APPLY_CHANGES = "/Script/G1R.SettingsPageWidget:ApplyChanges"
local SETTINGS_PAGE_DISCARD_CHANGES = "/Script/G1R.SettingsPageWidget:DiscardChanges"
local GAME_SETTINGS_ROW_CLASS =
    "/Game/UI/CoreMenus/Settings/W_SettingsRow.W_SettingsRow_C"
local GAME_SETTINGS_ROW_CREATE_WIDGET =
    GAME_SETTINGS_ROW_CLASS .. ":Create Setting Widget"
local GAME_SETTINGS_ROW_SET_ENABLED =
    GAME_SETTINGS_ROW_CLASS .. ":Set Enabled Selectable"
local GAME_SETTINGS_HEADER_CLASS =
    "/Game/UI/CoreMenus/Settings/W_SettingsSectionHeader.W_SettingsSectionHeader_C"
local GAME_SETTINGS_BOOL_WIDGET_CLASS =
    "/Game/UI/CoreMenus/Settings/W_Setting_Bool.W_Setting_Bool_C"
local BOOL_WIDGET_VALUE_CHANGED =
    GAME_SETTINGS_BOOL_WIDGET_CLASS .. ":OnValueChanged"
local GAME_SETTINGS_BOOL_OBJECT_CLASS = "/Script/G1R.SettingObject_Bool_Test"
local BOOL_WIDGET_SET_VALUE = "/Script/G1R.SettingObjectWidget_Bool:SetValue"
local BOOL_SETTING_SET_VALUE = "/Script/G1R.SettingObject_Bool:SetValue"
local WIDGET_BLUEPRINT_LIBRARY = "/Script/UMG.Default__WidgetBlueprintLibrary"
local INTERNATIONALIZATION_LIBRARY =
    "/Script/Engine.Default__KismetInternationalizationLibrary"

local MOD_SECTION_TRANSLATIONS = {
    en = "Mods",
    de = "Mods",
    fr = "Mods",
    it = "Mod",
    es = "Mods",
    pl = "Mody",
    ru = "Моды",
    ["zh-hans"] = "模组",
    ["zh-cn"] = "模组",
    ja = "Mod",
    ["pt-br"] = "Mods",
}

local game_settings_state = {
    entries = {},
    order = {},
    pages = {},
    notify_registered = false,
    page_activated_hook_registered = false,
    page_reinitialize_hook_registered = false,
    page_apply_hook_registered = false,
    page_discard_hook_registered = false,
    bool_widget_value_hook_registered = false,
    bool_setting_value_hook_registered = false,
    bool_widget_changed_hook_registered = false,
    bindings_by_widget = {},
    bindings_by_setting = {},
}

local function object_identity(object)
    if not is_valid_object(object) then return "" end
    local address = try(function()
        if type(object.GetAddress) ~= "function" then return nil end
        return object:GetAddress()
    end)
    local numeric_address = tonumber(address)
    if numeric_address ~= nil and numeric_address ~= 0 then
        return tostring(address)
    end
    return object_full_name(object)
end

local function is_game_settings_page(page)
    return is_valid_object(page)
        and object_full_name(page):find("W_SettingsPage_Game_C", 1, true) ~= nil
end

local function set_object_property(object, property_name, value)
    if not is_valid_object(object) then return false end
    local ok = pcall(function() object[property_name] = value end)
    if ok then return true end
    local fallback_ok, result = pcall(function()
        if type(object.SetPropertyValue) ~= "function" then return false end
        object:SetPropertyValue(property_name, value)
        return true
    end)
    return fallback_ok and result == true
end

local function current_language(runtime)
    local library = runtime:find_object(INTERNATIONALIZATION_LIBRARY)
    local language = runtime:try(function()
        return library:GetCurrentLanguage()
    end)
    language = runtime:unwrap(language)
    if type(language) == "userdata" or type(language) == "table" then
        language = runtime:try(function() return language:ToString() end)
    end
    local normalized = lower(language):gsub("_", "-")
    if normalized == "" then return "en" end
    return normalized
end

local function localized_value(runtime, translations, field, fallback)
    translations = type(translations) == "table" and translations or {}
    local language = current_language(runtime)
    local base = language:match("^([^-]+)") or language
    local selected = translations[language]
        or translations[base]
        or translations.en
        or translations["en-us"]

    if type(selected) == "string" then
        if field == "name" then return selected end
    elseif type(selected) == "table" then
        local value = selected[field]
        if value == nil and field == "name" then value = selected.label end
        if value ~= nil then return tostring(value) end
    end
    return tostring(fallback or "")
end

local function localized_section_name(runtime)
    local language = current_language(runtime)
    local base = language:match("^([^-]+)") or language
    return MOD_SECTION_TRANSLATIONS[language]
        or MOD_SECTION_TRANSLATIONS[base]
        or MOD_SECTION_TRANSLATIONS.en
end

local function to_text(runtime, value)
    local text = tostring(value or "")
    local converted = runtime:try(function() return FText(text) end)
    if converted ~= nil then return converted end

    local library = runtime:find_object("/Script/Engine.Default__KismetTextLibrary")
    return runtime:try(function() return library:Conv_StringToText(text) end)
end

local function setting_value(entry)
    local value = entry.runtime:try(entry.get)
    if value == nil then value = entry.default end
    return value == true
end

local function resolve_persist_value(value)
    if type(value) == "function" then
        local ok, resolved = pcall(value)
        if ok then return resolved end
        return nil
    end
    return value
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

local function create_user_widget(runtime, page, class_path)
    local library = runtime:find_object(WIDGET_BLUEPRINT_LIBRARY)
    local widget_class = runtime:find_object(class_path)
    if not is_valid_object(library) or not is_valid_object(widget_class) then
        return nil
    end

    local owning_player = runtime:try(function() return page:GetOwningPlayer() end)
    return runtime:try(function()
        return library:Create(page, widget_class, owning_player)
    end)
end

local function construct_object(runtime, class_path, outer)
    local object_class = runtime:find_object(class_path)
    if not is_valid_object(object_class) or not is_valid_object(outer) then return nil end
    return runtime:try(function()
        return StaticConstructObject(object_class, outer)
    end)
end

local function append_settings_row(page, row)
    local rows = try(function() return page.m_SettingsRowWidgets end)
    if rows == nil then return false end
    for index = 1, #rows do
        local existing = unwrap(try(function() return rows[index] end))
        if object_identity(existing) == object_identity(row) then return true end
    end
    return pcall(function()
        rows[#rows + 1] = row
    end)
end

local function update_setting_description(runtime, setting, entry)
    local name = localized_value(runtime, entry.translations, "name", entry.id)
    local description = localized_value(runtime, entry.translations,
        "description", "")
    local name_text = to_text(runtime, name)
    local description_text = to_text(runtime, description)

    set_object_property(setting, "m_DisplayName", name_text)
    runtime:try(function()
        setting.m_Description.m_Title = name_text
        setting.m_Description.m_Text = description_text
    end)
    return name_text
end

local function synchronize_binding(binding)
    local entry = binding.entry
    local runtime = entry.runtime
    if not is_valid_object(binding.row) or not is_valid_object(binding.setting) then
        return false
    end

    local name_text = update_setting_description(runtime, binding.setting, entry)
    runtime:try(function()
        if is_valid_object(binding.row.Text_Name) then
            binding.row.Text_Name:SetText(name_text)
        end
    end)

    local value = setting_value(entry)
    binding.synchronizing = true
    runtime:try(function() binding.setting:SetValue(value) end)
    runtime:try(function() binding.setting:ConfirmValue() end)
    runtime:try(function()
        if is_valid_object(binding.widget) then
            binding.widget:SetValue(value, true)
        end
    end)
    binding.synchronizing = false
    return true
end

local function enable_binding(binding)
    local runtime = binding.entry.runtime
    local set_enabled_function = runtime:find_object(
        GAME_SETTINGS_ROW_SET_ENABLED)
    if is_valid_object(set_enabled_function) then
        runtime:try(function()
            return set_enabled_function(binding.row, true)
        end)
    end
    runtime:try(function() binding.row:SetIsEnabled(true) end)
    runtime:try(function() binding.widget:SetIsEnabled(true) end)
    runtime:try(function() binding.row:OnAvailabilityChanged(true) end)
    runtime:try(function() binding.widget:OnAvailabilityChanged(true) end)
    runtime:try(function() binding.widget.Button_On:SetIsEnabled(true) end)
    runtime:try(function() binding.widget.Button_Off:SetIsEnabled(true) end)
    runtime:try(function() binding.widget.Button_Toggle:SetIsEnabled(true) end)
    runtime:try(function() binding.widget.Slider_Value:SetIsEnabled(true) end)
end

local function ensure_mod_header(runtime, page, page_state, panel)
    if is_valid_object(page_state.header) then
        local parent = runtime:unwrap(runtime:try(function()
            return page_state.header:GetParent()
        end))
        if object_identity(parent) ~= object_identity(panel) then
            local added = runtime:try(function()
                return panel:AddChildToVerticalBox(page_state.header)
            end)
            if added == nil then return false end
        end
        return true
    end
    local header = create_user_widget(runtime, page, GAME_SETTINGS_HEADER_CLASS)
    if not is_valid_object(header) then return false end

    local title_text = to_text(runtime, localized_section_name(runtime))
    set_object_property(header, "title", title_text)
    runtime:try(function()
        if is_valid_object(header.TextBlock_Title) then
            header.TextBlock_Title:SetText(title_text)
        end
    end)
    local added = runtime:try(function()
        return panel:AddChildToVerticalBox(header)
    end)
    if added == nil then return false end

    page_state.header = header
    return true
end

local function link_bool_setting_widget(runtime, row, widget, setting)
    if not is_valid_object(widget) then return false end
    set_object_property(row, "m_SettingWidget", widget)
    runtime:try(function() widget:SetSettingObject(setting) end)
    set_object_property(widget, "m_GenericSetting", setting)
    set_object_property(widget, "m_Setting", setting)
    runtime:try(function() widget:SetAutoApplyChanges(true) end)

    local linked_setting = runtime:unwrap(runtime:try(function()
        return widget.m_Setting
    end))
    return object_identity(linked_setting) == object_identity(setting)
end

local function create_bool_setting_widget(runtime, row, setting)
    local create_widget_function = runtime:find_object(
        GAME_SETTINGS_ROW_CREATE_WIDGET)
    if is_valid_object(create_widget_function) then
        local ok, result = pcall(function()
            return create_widget_function(row)
        end)
        local widget = runtime:unwrap(runtime:try(function()
            return row.m_SettingWidget
        end))
        local container = runtime:unwrap(runtime:try(function()
            return row.SizeBox_SettingsEntry
        end))
        local content = runtime:unwrap(runtime:try(function()
            return container:GetContent()
        end))
        if is_valid_object(content) then widget = content end

        if ok and is_valid_object(widget)
            and link_bool_setting_widget(runtime, row, widget, setting)
        then
            return widget, nil
        end

        runtime:debug_log("native settings row widget creation failed"
            .. " ok=" .. tostring(ok)
            .. " result=" .. safe_to_string(runtime:unwrap(result))
            .. " widget=" .. object_full_name(widget)
            .. " content=" .. object_full_name(content))
    end

    runtime:debug_log("falling back to direct bool widget creation")
    local widget = create_user_widget(runtime, row, GAME_SETTINGS_BOOL_WIDGET_CLASS)
    if not is_valid_object(widget) then return nil, "bool widget creation failed" end
    if not link_bool_setting_widget(runtime, row, widget, setting) then
        return nil, "bool widget setting link failed"
    end

    local parent = runtime:unwrap(runtime:try(function() return widget:GetParent() end))
    if not is_valid_object(parent) then
        local container = runtime:unwrap(runtime:try(function()
            return row.SizeBox_SettingsEntry
        end))
        if not is_valid_object(container) then
            return nil, "settings row value container missing"
        end
        runtime:try(function() container:SetContent(widget) end)
        local content = runtime:unwrap(runtime:try(function()
            return container:GetContent()
        end))
        if object_identity(content) ~= object_identity(widget) then
            if is_valid_object(content)
                and link_bool_setting_widget(runtime, row, content, setting)
            then
                runtime:debug_log("reused native bool widget already owned by settings row"
                    .. " widget=" .. object_full_name(content))
                runtime:try(function() widget:RemoveFromParent() end)
                widget = content
            else
                return nil, "bool widget could not be set as row content"
                    .. "; requested=" .. object_full_name(widget)
                    .. "; actual=" .. object_full_name(content)
            end
        end
    end
    return widget, nil
end

local function unindex_binding(binding)
    local widget_key = object_identity(binding and binding.widget)
    if widget_key ~= "" then game_settings_state.bindings_by_widget[widget_key] = nil end
    local setting_key = object_identity(binding and binding.setting)
    if setting_key ~= "" then game_settings_state.bindings_by_setting[setting_key] = nil end
end

local function index_binding(binding)
    local widget_key = object_identity(binding.widget)
    if widget_key ~= "" then
        game_settings_state.bindings_by_widget[widget_key] = binding
    end
    local setting_key = object_identity(binding.setting)
    if setting_key ~= "" then
        game_settings_state.bindings_by_setting[setting_key] = binding
    end
end

local function ensure_binding_attached(runtime, binding, panel)
    if not is_valid_object(binding.row) or not is_valid_object(binding.setting) then
        return false
    end

    local parent = runtime:unwrap(runtime:try(function()
        return binding.row:GetParent()
    end))
    if object_identity(parent) ~= object_identity(panel) then
        local added = runtime:try(function()
            return panel:AddChildToVerticalBox(binding.row)
        end)
        if added == nil then return false end
    end

    local container = runtime:unwrap(runtime:try(function()
        return binding.row.SizeBox_SettingsEntry
    end))
    local content = runtime:unwrap(runtime:try(function()
        return container:GetContent()
    end))
    if is_valid_object(content)
        and object_identity(content) ~= object_identity(binding.widget)
    then
        link_bool_setting_widget(runtime, binding.row, content, binding.setting)
        unindex_binding(binding)
        binding.widget = content
        index_binding(binding)
    elseif not is_valid_object(binding.widget) then
        local widget = create_bool_setting_widget(runtime, binding.row,
            binding.setting)
        if not is_valid_object(widget) then return false end
        unindex_binding(binding)
        binding.widget = widget
        index_binding(binding)
    elseif not is_valid_object(content) then
        runtime:try(function()
            return container:SetContent(binding.widget)
        end)
        content = runtime:unwrap(runtime:try(function()
            return container:GetContent()
        end))
        if object_identity(content) ~= object_identity(binding.widget) then
            return false
        end
    end

    -- The page's row registry can become read-only after Reinitialize. The row
    -- is already registered from its first insertion; attachment and content
    -- validity are authoritative when the same page instance is reopened.
    if not append_settings_row(binding.page, binding.row) then
        runtime:debug_log("game setting '" .. binding.entry.id
            .. "' row registry unavailable after reattach; keeping binding")
    end
    return true
end

local function inject_bool_setting(runtime, page, page_state, entry, panel)
    local existing_binding = page_state.bindings[entry.id]
    if existing_binding ~= nil
        and ensure_binding_attached(runtime, existing_binding, panel)
    then
        return synchronize_binding(existing_binding)
    elseif existing_binding ~= nil then
        unindex_binding(existing_binding)
        runtime:try(function() existing_binding.row:RemoveFromParent() end)
        page_state.bindings[entry.id] = nil
    end

    local row = create_user_widget(runtime, page, GAME_SETTINGS_ROW_CLASS)
    if not is_valid_object(row) then
        runtime:debug_log("game setting '" .. entry.id
            .. "' failed: settings row could not be created")
        return false
    end
    local setting = construct_object(runtime, GAME_SETTINGS_BOOL_OBJECT_CLASS, row)
    if not is_valid_object(setting) then
        runtime:debug_log("game setting '" .. entry.id
            .. "' failed: bool setting object could not be constructed")
        return false
    end

    local name_text = update_setting_description(runtime, setting, entry)
    local value = setting_value(entry)
    set_object_property(setting, "m_DefaultValue", value)
    -- Both are restriction masks. Zero matches an unrestricted native Game
    -- setting and avoids relying on the page's row registry during cold-start.
    set_object_property(setting, "m_PlatformExclusivityMask", 0)
    set_object_property(setting, "m_InputAvailabilityMask", 0)

    runtime:try(function() setting:SetValue(value) end)
    runtime:try(function() setting:ConfirmValue() end)
    set_object_property(row, "m_Setting", setting)
    set_object_property(row, "m_AutoApplyChanges", true)

    runtime:try(function()
        if is_valid_object(row.Text_Name) then row.Text_Name:SetText(name_text) end
    end)
    local widget, widget_error = create_bool_setting_widget(runtime, row, setting)
    if not is_valid_object(widget) then
        runtime:debug_log("game setting '" .. entry.id
            .. "' failed: " .. tostring(widget_error))
        return false
    end
    runtime:try(function() row:Reinitialize() end)
    runtime:try(function() widget:SetValue(value, true) end)
    local added = runtime:try(function() return panel:AddChildToVerticalBox(row) end)
    if added == nil then
        runtime:debug_log("game setting '" .. entry.id
            .. "' failed: row could not be added to Game settings panel")
        return false
    end

    local binding = {
        entry = entry,
        page = page,
        row = row,
        setting = setting,
        widget = widget,
        synchronizing = false,
    }
    if not append_settings_row(page, row) then
        runtime:try(function() row:RemoveFromParent() end)
        runtime:debug_log("game setting '" .. entry.id
            .. "' failed: row could not be appended to page registry")
        return false
    end
    page_state.bindings[entry.id] = binding
    index_binding(binding)
    return true
end

local function inject_game_settings(runtime, page)
    page = runtime:unwrap(page)
    if not is_valid_object(page) then return false end
    local panel = runtime:unwrap(runtime:try(function()
        return page.VerticalBox_Content
    end))
    if not is_valid_object(panel) then return false end

    local page_key = object_identity(page)
    if page_key == "" then return false end
    local page_state = game_settings_state.pages[page_key]
    if page_state == nil then
        page_state = { page = page, bindings = {} }
        game_settings_state.pages[page_key] = page_state
    end

    if #game_settings_state.order > 0 then
        ensure_mod_header(runtime, page, page_state, panel)
    end
    local injected = 0
    for _, id in ipairs(game_settings_state.order) do
        local entry = game_settings_state.entries[id]
        if entry ~= nil and inject_bool_setting(runtime, page, page_state,
            entry, panel)
        then
            injected = injected + 1
        end
    end
    for _, binding in pairs(page_state.bindings) do
        enable_binding(binding)
    end
    return injected > 0
end

local function apply_bool_setting_value(binding, value)
    local entry = binding.entry
    local runtime = entry.runtime
    value = value == true

    local accepted = true
    if type(entry.set) == "function" then
        local ok, result = pcall(entry.set, value)
        accepted = ok and result ~= false
        if not ok then
            runtime:log("game setting '" .. entry.id .. "' failed: "
                .. safe_to_string(result))
        end
    end

    if accepted and type(entry.persist) == "table" then
        local path = resolve_persist_value(entry.persist.path)
        local key = resolve_persist_value(entry.persist.key)
        if path ~= nil and key ~= nil then
            local persisted = update_ini_value(path, key,
                value and "true" or "false")
            if not persisted then
                runtime:log("Could not persist game setting '" .. entry.id .. "'")
            end
        end
    end

    if not accepted then synchronize_binding(binding) end
    return accepted
end

local function bool_parameter_value(runtime, parameter)
    local value = runtime:unwrap(parameter)
    if type(value) == "boolean" then return value end
    local text = lower(value)
    if text == "true" or text == "1" then return true end
    if text == "false" or text == "0" then return false end
    return nil
end

local function handle_native_bool_value(runtime, binding, parameter, source)
    if binding == nil or binding.synchronizing == true then return end
    local value = bool_parameter_value(runtime, parameter)
    if value == nil then
        runtime:debug_log("game setting native value unavailable"
            .. " source=" .. tostring(source)
            .. " parameter=" .. safe_to_string(parameter))
        return
    end
    if value == setting_value(binding.entry) then return end

    if apply_bool_setting_value(binding, value) then
        -- The generic test setting is not backed by Gothic's own config. Keep
        -- its native value in sync with the mod value or the widget will read
        -- the previous value back and visually undo the user's click.
        binding.synchronizing = true
        runtime:try(function() binding.setting:SetValue(value) end)
        runtime:try(function() binding.setting:ConfirmValue() end)
        binding.synchronizing = false
    end
end

local function commit_game_settings_page(runtime, page)
    page = runtime:unwrap(page)
    if not is_game_settings_page(page) then return end

    local page_state = game_settings_state.pages[object_identity(page)]
    if page_state == nil then return end

    for _, binding in pairs(page_state.bindings) do
        if is_valid_object(binding.setting) then
            local widget_value = runtime:unwrap(runtime:try(function()
                if not is_valid_object(binding.widget) then return nil end
                return binding.widget:GetValue()
            end))
            local setting_object_value = runtime:unwrap(runtime:try(function()
                return binding.setting:GetValue()
            end))
            local value = widget_value
            if type(value) ~= "boolean" then value = setting_object_value end

            if type(value) == "boolean" then
                local accepted = true
                if value ~= setting_value(binding.entry) then
                    accepted = apply_bool_setting_value(binding, value)
                end

                -- SettingObject keeps a separate confirmed value and reverts to
                -- it when the settings menu closes. Confirm the UI value before
                -- Gothic runs ApplyChanges/DiscardChanges.
                if accepted then
                    binding.synchronizing = true
                    runtime:try(function() binding.setting:SetValue(value) end)
                    runtime:try(function() binding.setting:ConfirmValue() end)
                    binding.synchronizing = false
                end
            end
        end
    end
end

local function binding_for_bool_widget(runtime, context)
    local widget = runtime:unwrap(context)
    local widget_key = object_identity(widget)
    local binding = game_settings_state.bindings_by_widget[widget_key]
    if binding ~= nil then return widget, binding end

    -- A settings page recreation can replace the row's bool widget after the
    -- binding was indexed. Recover it through the linked native SettingObject
    -- so the replacement widget's very first value change is not lost.
    local setting = runtime:unwrap(runtime:try(function()
        return widget.m_Setting
    end))
    if not is_valid_object(setting) then
        setting = runtime:unwrap(runtime:try(function()
            return widget.m_GenericSetting
        end))
    end
    binding = game_settings_state.bindings_by_setting[object_identity(setting)]

    -- Some replacement widgets expose their setting only after their first
    -- Blueprint event. The owning row already references the widget by then,
    -- so use that relationship as a final recovery path.
    if binding == nil then
        for _, page_state in pairs(game_settings_state.pages) do
            for _, candidate in pairs(page_state.bindings) do
                local row_widget = runtime:unwrap(runtime:try(function()
                    return candidate.row.m_SettingWidget
                end))
                local container = runtime:unwrap(runtime:try(function()
                    return candidate.row.SizeBox_SettingsEntry
                end))
                local content = runtime:unwrap(runtime:try(function()
                    return container:GetContent()
                end))
                if object_identity(row_widget) == widget_key
                    or object_identity(content) == widget_key
                then
                    binding = candidate
                    break
                end
            end
            if binding ~= nil then break end
        end
    end

    if binding ~= nil then
        unindex_binding(binding)
        binding.widget = widget
        index_binding(binding)
    end
    return widget, binding
end

local function ensure_game_settings_hooks(runtime)
    if game_settings_state.page_activated_hook_registered ~= true
        and is_valid_object(runtime:find_object(GAME_SETTINGS_PAGE_ACTIVATED))
    then
        if runtime:register_hook(GAME_SETTINGS_PAGE_ACTIVATED, function(context)
            local page = runtime:unwrap(context)
            runtime:delay_game_thread(0, function()
                inject_game_settings(runtime, page)
                ensure_game_settings_hooks(runtime)
            end)
            return nil
        end) then
            game_settings_state.page_activated_hook_registered = true
        end
    end

    if game_settings_state.page_reinitialize_hook_registered ~= true
        and is_valid_object(runtime:find_object(SETTINGS_PAGE_REINITIALIZE))
    then
        if runtime:register_hook(SETTINGS_PAGE_REINITIALIZE,
            function(context)
                local page = runtime:unwrap(context)
                if is_game_settings_page(page) then
                    inject_game_settings(runtime, page)
                end
                return nil
            end,
            function(context)
                local page = runtime:unwrap(context)
                if is_game_settings_page(page) then
                    runtime:delay_game_thread(0, function()
                        inject_game_settings(runtime, page)
                    end)
                end
                return nil
            end)
        then
            game_settings_state.page_reinitialize_hook_registered = true
        end
    end

    if game_settings_state.page_apply_hook_registered ~= true
        and is_valid_object(runtime:find_object(SETTINGS_PAGE_APPLY_CHANGES))
    then
        if runtime:register_hook(SETTINGS_PAGE_APPLY_CHANGES, function(context)
            commit_game_settings_page(runtime, context)
            return nil
        end) then
            game_settings_state.page_apply_hook_registered = true
        end
    end

    if game_settings_state.page_discard_hook_registered ~= true
        and is_valid_object(runtime:find_object(SETTINGS_PAGE_DISCARD_CHANGES))
    then
        if runtime:register_hook(SETTINGS_PAGE_DISCARD_CHANGES, function(context)
            commit_game_settings_page(runtime, context)
            return nil
        end) then
            game_settings_state.page_discard_hook_registered = true
        end
    end

    if game_settings_state.bool_widget_value_hook_registered ~= true
        and is_valid_object(runtime:find_object(BOOL_WIDGET_SET_VALUE))
    then
        if runtime:register_hook(BOOL_WIDGET_SET_VALUE, noop,
            function(context, new_value)
                local _, binding = binding_for_bool_widget(runtime, context)
                handle_native_bool_value(runtime, binding, new_value,
                    "widget.SetValue")
                return nil
            end)
        then
            game_settings_state.bool_widget_value_hook_registered = true
        end
    end

    if game_settings_state.bool_setting_value_hook_registered ~= true
        and is_valid_object(runtime:find_object(BOOL_SETTING_SET_VALUE))
    then
        if runtime:register_hook(BOOL_SETTING_SET_VALUE, noop,
            function(context, new_value)
                local setting = runtime:unwrap(context)
                local binding = game_settings_state.bindings_by_setting[
                    object_identity(setting)]
                handle_native_bool_value(runtime, binding, new_value,
                    "setting.SetValue")
                return nil
            end)
        then
            game_settings_state.bool_setting_value_hook_registered = true
        end
    end

    if game_settings_state.bool_widget_changed_hook_registered ~= true
        and is_valid_object(runtime:find_object(BOOL_WIDGET_VALUE_CHANGED))
    then
        if runtime:register_hook(BOOL_WIDGET_VALUE_CHANGED,
            function(context, new_value)
                local _, binding = binding_for_bool_widget(runtime, context)
                handle_native_bool_value(runtime, binding, new_value,
                    "widget.OnValueChanged")
                return nil
            end)
        then
            game_settings_state.bool_widget_changed_hook_registered = true
        end
    end
end

local function ensure_game_settings_notifications(runtime)
    if game_settings_state.notify_registered == true then return true end
    if type(NotifyOnNewObject) ~= "function" then return false end

    local ok = pcall(function()
        NotifyOnNewObject(GAME_SETTINGS_PAGE_CLASS, function(_page)
            ensure_game_settings_hooks(runtime)
            runtime:delay_game_thread(0, function()
                ensure_game_settings_hooks(runtime)
            end)
        end)
    end)
    game_settings_state.notify_registered = ok
    return ok
end

local function register_game_bool_setting(runtime, options)
    options = type(options) == "table" and options or {}
    local id = trim(options.id)
    if id == "" then
        runtime:log("register_game_bool_setting requires a non-empty id")
        return nil
    end
    if type(options.get) ~= "function" or type(options.set) ~= "function" then
        runtime:log("game setting '" .. id .. "' requires get and set callbacks")
        return nil
    end

    local entry = game_settings_state.entries[id]
    if entry == nil then table.insert(game_settings_state.order, id) end
    entry = {
        id = id,
        runtime = runtime,
        default = options.default == true,
        get = options.get,
        set = options.set,
        persist = options.persist,
        translations = options.translations,
    }
    game_settings_state.entries[id] = entry

    ensure_game_settings_notifications(runtime)
    ensure_game_settings_hooks(runtime)
    for _, page in ipairs(runtime:find_all_of("W_SettingsPage_Game_C")) do
        local target_page = page
        runtime:delay_game_thread(0, function()
            inject_game_settings(runtime, target_page)
            ensure_game_settings_hooks(runtime)
        end)
    end

    return {
        id = id,
        refresh = function()
            for _, page_state in pairs(game_settings_state.pages) do
                local binding = page_state.bindings[id]
                if binding ~= nil then synchronize_binding(binding) end
            end
        end,
    }
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

    function runtime:register_game_bool_setting(options)
        return register_game_bool_setting(self, options)
    end

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
