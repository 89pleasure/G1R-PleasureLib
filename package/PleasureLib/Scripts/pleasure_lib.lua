local VERSION = "0.4.67"

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

local MOD_SETTINGS_MAIN_CLASS =
    "/Game/UI/CoreMenus/Settings/W_SettingsMain.W_SettingsMain_C"
local MOD_SETTINGS_PAGE_CLASS =
    "/Game/UI/CoreMenus/Settings/W_SettingsPage_Test.W_SettingsPage_Test_C"
local MOD_SETTINGS_PAGE_ACTIVATED = MOD_SETTINGS_PAGE_CLASS .. ":BP_OnActivated"
local SETTINGS_MAIN_CREATE_PAGE_BUTTONS =
    "/Script/G1R.SettingsMainWidget:CreatePageButtons"
local SETTINGS_MAIN_FOCUS_ACTIVE_BUTTON =
    "/Script/G1R.SettingsMainWidget:FocusActiveButton"
local SETTINGS_MAIN_ACTIVE_PAGE_CHANGED = MOD_SETTINGS_MAIN_CLASS
    .. ":BndEvt__W_SettingsMain_WidgetSwitcher_Pages_"
    .. "K2Node_ComponentBoundEvent_1_"
    .. "OnActiveIndexChangedDelegate__DelegateSignature"
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
local WIDGET_SET_VISIBILITY = "/Script/UMG.Widget:SetVisibility"
local INTERNATIONALIZATION_LIBRARY =
    "/Script/Engine.Default__KismetInternationalizationLibrary"
local WIDGET_VISIBILITY_COLLAPSED = 1
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
    main_notify_registered = false,
    page_notify_registered = false,
    create_page_buttons_hook_registered = false,
    focus_active_button_hook_registered = false,
    active_page_changed_hook_registered = false,
    page_activated_hook_registered = false,
    page_reinitialize_hook_registered = false,
    page_apply_hook_registered = false,
    page_discard_hook_registered = false,
    bool_widget_value_hook_registered = false,
    bool_setting_value_hook_registered = false,
    bool_widget_changed_hook_registered = false,
    native_pages_by_main = {},
    create_page_button_batches = {},
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

local function is_mod_settings_page(page)
    return is_valid_object(page)
        and object_full_name(page):find("W_SettingsPage_Test_C", 1, true) ~= nil
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

local function set_widget_visibility(runtime, widget, visibility)
    if not is_valid_object(widget) then return end
    set_object_property(widget, "Visibility", visibility)

    -- In some cold-start runs UE4SS resolves the concrete Blueprint row but
    -- not inherited UWidget methods through UObject.__index. Invoke the native
    -- reflected UFunction explicitly so the live Slate widget is updated too.
    local set_visibility_function = runtime:find_object(WIDGET_SET_VISIBILITY)
    if is_valid_object(set_visibility_function) then
        local reflected_ok = pcall(function()
            return set_visibility_function(widget, visibility)
        end)
        if reflected_ok then return end
    end

    pcall(function()
        return widget:SetVisibility(visibility)
    end)
end

local function set_bool_property(object, property_name, value)
    value = value == true
    if not is_valid_object(object) then return false end

    pcall(function() object[property_name] = value end)
    local current = try(function() return object[property_name] end)
    if current == value then return true end

    pcall(function()
        if type(object.SetPropertyValue) == "function" then
            object:SetPropertyValue(property_name, value)
        end
    end)
    current = try(function() return object[property_name] end)
    return current == value
end

local function set_integer_property(object, property_name, value)
    value = math.floor(tonumber(value) or 0)
    if not is_valid_object(object) then return false end

    pcall(function() object[property_name] = value end)
    local current = try(function() return object[property_name] end)
    if tonumber(current) == value then return true end

    pcall(function()
        if type(object.SetPropertyValue) == "function" then
            object:SetPropertyValue(property_name, value)
        end
    end)
    current = try(function() return object[property_name] end)
    return tonumber(current) == value
end

local function configure_setting_availability(runtime, setting)
    local platform_set = set_integer_property(setting,
        "m_PlatformExclusivityMask", 0)
    local input_set = set_integer_property(setting,
        "m_InputAvailabilityMask", 0)
    if not platform_set or not input_set then
        runtime:debug_log("could not initialize setting availability masks"
            .. " platform=" .. tostring(platform_set)
            .. " input=" .. tostring(input_set))
        return false
    end
    return true
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

local function settings_row_registered(page, row)
    local rows = try(function() return page.m_SettingsRowWidgets end)
    if rows == nil then return nil end
    for index = 1, #rows do
        local existing = unwrap(try(function() return rows[index] end))
        if object_identity(existing) == object_identity(row) then return true end
    end
    return false
end

local function panel_child_count(runtime, panel)
    return tonumber(runtime:unwrap(runtime:try(function()
        return panel:GetChildrenCount()
    end)))
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

    configure_setting_availability(runtime, binding.setting)
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
    configure_setting_availability(runtime, binding.setting)
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

local function ensure_mod_header(runtime, page, page_state, panel, section)
    section = trim(section)
    if section == "" then section = "Mods" end
    page_state.headers = page_state.headers or {}
    local header = page_state.headers[section]
    if is_valid_object(header) then
        -- Some UE4SS runs expose the live panel object while inherited UPanel
        -- functions temporarily return nil. The existing header is still
        -- valid and visible; treating nil as "detached" would add it again.
        if panel_child_count(runtime, panel) == nil then return header end
        local parent = runtime:unwrap(runtime:try(function()
            return header:GetParent()
        end))
        if object_identity(parent) ~= object_identity(panel) then
            local added = runtime:try(function()
                return panel:AddChildToVerticalBox(header)
            end)
            if added == nil then return false end
        end
        return header
    end
    header = create_user_widget(runtime, page, GAME_SETTINGS_HEADER_CLASS)
    if not is_valid_object(header) then return nil end

    local title_text = to_text(runtime, section)
    set_object_property(header, "title", title_text)
    runtime:try(function()
        if is_valid_object(header.TextBlock_Title) then
            header.TextBlock_Title:SetText(title_text)
        end
    end)
    local added = runtime:try(function()
        return panel:AddChildToVerticalBox(header)
    end)
    if added == nil then return nil end

    page_state.headers[section] = header
    return header
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

local function current_row_setting_widget(runtime, row)
    local widget = runtime:unwrap(runtime:try(function()
        return row.m_SettingWidget
    end))
    local container = runtime:unwrap(runtime:try(function()
        return row.SizeBox_SettingsEntry
    end))
    local content = runtime:unwrap(runtime:try(function()
        return container:GetContent()
    end))
    if is_valid_object(content) then return content end
    if is_valid_object(widget) then return widget end
    return nil
end

local function create_bool_setting_widget(runtime, row, setting)
    local widget = current_row_setting_widget(runtime, row)
    if is_valid_object(widget)
        and link_bool_setting_widget(runtime, row, widget, setting)
    then
        return widget, nil
    end

    local create_widget_function = runtime:find_object(
        GAME_SETTINGS_ROW_CREATE_WIDGET)
    if is_valid_object(create_widget_function) then
        local ok, result = pcall(function()
            return create_widget_function(row)
        end)
        widget = current_row_setting_widget(runtime, row)

        if ok and is_valid_object(widget)
            and link_bool_setting_widget(runtime, row, widget, setting)
        then
            return widget, nil
        end

        runtime:debug_log("native settings row widget creation failed"
            .. " ok=" .. tostring(ok)
            .. " result=" .. safe_to_string(runtime:unwrap(result))
            .. " widget=" .. object_full_name(widget)
            .. " content=" .. object_full_name(widget))
    end

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

local function retain_registered_binding(runtime, binding)
    if settings_row_registered(binding.page, binding.row) ~= true then
        return false
    end
    local row_setting = runtime:unwrap(runtime:try(function()
        return binding.row.m_Setting
    end))
    if object_identity(row_setting) ~= object_identity(binding.setting) then
        return false
    end

    local current_widget = runtime:unwrap(runtime:try(function()
        return binding.row.m_SettingWidget
    end))
    local linked_widget = nil
    if is_valid_object(current_widget) then
        local current_setting = runtime:unwrap(runtime:try(function()
            return current_widget.m_Setting
        end))
        local current_generic_setting = runtime:unwrap(runtime:try(function()
            return current_widget.m_GenericSetting
        end))
        if object_identity(current_widget) == object_identity(binding.widget)
            or object_identity(current_setting) == object_identity(binding.setting)
            or object_identity(current_generic_setting)
                == object_identity(binding.setting)
        then
            linked_widget = current_widget
        end
    end
    if not is_valid_object(linked_widget) and is_valid_object(binding.widget) then
        local widget_setting = runtime:unwrap(runtime:try(function()
            return binding.widget.m_Setting
        end))
        local generic_setting = runtime:unwrap(runtime:try(function()
            return binding.widget.m_GenericSetting
        end))
        if object_identity(widget_setting) == object_identity(binding.setting)
            or object_identity(generic_setting) == object_identity(binding.setting)
        then
            linked_widget = binding.widget
        end
    end
    if not is_valid_object(linked_widget) then return false end

    if object_identity(linked_widget) ~= object_identity(binding.widget) then
        link_bool_setting_widget(runtime, binding.row, linked_widget,
            binding.setting)
        unindex_binding(binding)
        binding.widget = linked_widget
        index_binding(binding)
    end
    return true
end

local function ensure_binding_attached(runtime, binding, panel)
    if not is_valid_object(binding.row) or not is_valid_object(binding.setting) then
        return false
    end

    -- In the broken UMG reflection state, GetParent/GetContent and all panel
    -- child queries return nil although the row remains valid and registered.
    -- Keep that authoritative native binding instead of removing it and
    -- appending a duplicate on every page activation.
    local child_count = panel_child_count(runtime, panel)
    if child_count == nil and retain_registered_binding(runtime, binding) then
        return is_valid_object(binding.widget)
    elseif child_count == nil then
        return nil
    end

    local parent = runtime:unwrap(runtime:try(function()
        return binding.row:GetParent()
    end))
    if object_identity(parent) ~= object_identity(panel) then
        runtime:try(function() binding.row:RemoveFromParent() end)
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
            if retain_registered_binding(runtime, binding) then return true end
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
        and is_valid_object(existing_binding.row)
        and is_valid_object(existing_binding.setting)
    then
        existing_binding.entry = entry
        existing_binding.page = page
        local attached = ensure_binding_attached(runtime, existing_binding,
            panel)
        if attached == true then
            page_state.bindings[entry.id] = existing_binding
            return synchronize_binding(existing_binding)
        elseif attached == nil then
            return false
        end
    end
    if existing_binding ~= nil then
        unindex_binding(existing_binding)
        runtime:try(function() existing_binding.row:RemoveFromParent() end)
        page_state.bindings[entry.id] = nil
    end

    local use_native_row = page_state.native_bool_claimed ~= true
        and is_valid_object(page_state.native_bool_row)
    local row = use_native_row and page_state.native_bool_row
        or create_user_widget(runtime, page, GAME_SETTINGS_ROW_CLASS)
    if not is_valid_object(row) then
        runtime:debug_log("mod setting '" .. entry.id
            .. "' failed: settings row could not be created")
        return false
    end
    local setting = use_native_row and runtime:unwrap(runtime:try(function()
        return row.m_Setting
    end)) or construct_object(runtime, GAME_SETTINGS_BOOL_OBJECT_CLASS, row)
    if not is_valid_object(setting) then
        runtime:debug_log("mod setting '" .. entry.id
            .. "' failed: bool setting object unavailable")
        return false
    end

    local name_text = update_setting_description(runtime, setting, entry)
    local value = setting_value(entry)
    set_object_property(setting, "m_DefaultValue", value)
    -- Both are restriction masks. Zero matches an unrestricted native Game
    -- setting and avoids relying on the page's row registry during cold-start.
    if not configure_setting_availability(runtime, setting) then
        runtime:debug_log("mod setting '" .. entry.id
            .. "' availability initialization failed")
    end

    runtime:try(function() setting:SetValue(value) end)
    runtime:try(function() setting:ConfirmValue() end)
    set_object_property(row, "m_Setting", setting)
    set_object_property(row, "m_AutoApplyChanges", true)

    runtime:try(function()
        if is_valid_object(row.Text_Name) then row.Text_Name:SetText(name_text) end
    end)
    -- The native Test-page bool row is already fully initialized. Newly
    -- created rows need Reinitialize before we retain their visible widget.
    if not use_native_row then
        runtime:try(function() row:Reinitialize() end)
    end
    configure_setting_availability(runtime, setting)
    local widget, widget_error = create_bool_setting_widget(runtime, row, setting)
    if not is_valid_object(widget) then
        runtime:debug_log("mod setting '" .. entry.id
            .. "' failed: " .. tostring(widget_error))
        return false
    end
    configure_setting_availability(runtime, setting)
    link_bool_setting_widget(runtime, row, widget, setting)
    runtime:try(function() widget:SetValue(value, true) end)
    local parent = runtime:unwrap(runtime:try(function()
        return row:GetParent()
    end))
    if object_identity(parent) ~= object_identity(panel) then
        local added = runtime:try(function()
            return panel:AddChildToVerticalBox(row)
        end)
        if added == nil then
            runtime:debug_log("mod setting '" .. entry.id
                .. "' failed: row could not be added to Mods settings panel")
            return false
        end
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
        runtime:debug_log("mod setting '" .. entry.id
            .. "' failed: row could not be appended to page registry")
        return false
    end
    page_state.bindings[entry.id] = binding
    if use_native_row then page_state.native_bool_claimed = true end
    index_binding(binding)
    return true
end

local function ensure_mod_section_order(runtime, page_state, panel)
    local section_widgets = {}
    local added_sections = {}
    for _, id in ipairs(game_settings_state.order) do
        local entry = game_settings_state.entries[id]
        local binding = page_state.bindings[id]
        local section = entry and entry.section or "Mods"
        if added_sections[section] ~= true then
            local header = page_state.headers and page_state.headers[section]
            if is_valid_object(header) then table.insert(section_widgets, header) end
            added_sections[section] = true
        end
        if binding ~= nil and is_valid_object(binding.row) then
            table.insert(section_widgets, binding.row)
        end
    end
    if #section_widgets == 0 then return true end

    local child_count = panel_child_count(runtime, panel)
    if child_count == nil then return true end
    local first_section_index = child_count - #section_widgets
    local correctly_ordered = first_section_index >= 0
    if correctly_ordered then
        for offset, widget in ipairs(section_widgets) do
            local child = runtime:unwrap(runtime:try(function()
                return panel:GetChildAt(first_section_index + offset - 1)
            end))
            if not is_valid_object(child) then return true end
            if object_identity(child) ~= object_identity(widget) then
                correctly_ordered = false
                break
            end
        end
    end
    if correctly_ordered then return true end

    for _, widget in ipairs(section_widgets) do
        runtime:try(function() widget:RemoveFromParent() end)
    end
    for _, widget in ipairs(section_widgets) do
        local added = runtime:try(function()
            return panel:AddChildToVerticalBox(widget)
        end)
        if added == nil then
            runtime:debug_log("native Mods settings section reorder failed")
            return false
        end
    end
    return true
end

local function initialize_mod_settings_page(runtime, page, page_state, panel)
    if page_state.initialized == true then return true end

    local rows = runtime:try(function() return page.m_SettingsRowWidgets end)
    local native_bool_row = nil
    local native_test_rows = {}
    if rows ~= nil then
        for index = 1, #rows do
            local row = runtime:unwrap(runtime:try(function() return rows[index] end))
            local setting = runtime:unwrap(runtime:try(function()
                return row.m_Setting
            end))
            local setting_name = object_full_name(setting)
            if setting_name:find(
                "SettingObject_Bool_Test", 1, true) ~= nil
            then
                native_bool_row = row
            elseif setting_name:find("SettingObject_Int_Test", 1, true)
                    ~= nil
                or setting_name:find("SettingObject_Float_Test", 1, true)
                    ~= nil
                or setting_name:find("SettingObject_Enum_Test", 1, true)
                    ~= nil
            then
                table.insert(native_test_rows, row)
            end
        end
    end
    if not is_valid_object(native_bool_row) then
        local child_count = tonumber(runtime:unwrap(runtime:try(function()
            return panel:GetChildrenCount()
        end))) or 0
        for index = 0, child_count - 1 do
            local child = runtime:unwrap(runtime:try(function()
                return panel:GetChildAt(index)
            end))
            if object_full_name(child):find("SettingsRow_Bool", 1, true) ~= nil then
                native_bool_row = child
                break
            end
        end
    end
    if not is_valid_object(native_bool_row) then return false end
    local native_bool_setting = runtime:unwrap(runtime:try(function()
        return native_bool_row.m_Setting
    end))
    if not is_valid_object(native_bool_setting) then return false end

    -- Keep Gothic's fully initialized bool row and collapse the unrelated
    -- Enum/Float/Int test rows. Removing them is temporary because the page's
    -- native Reinitialize adds its registered rows back on activation.
    if #native_test_rows == 0 then
        local child_count = panel_child_count(runtime, panel) or 0
        for index = 0, child_count - 1 do
            local child = runtime:unwrap(runtime:try(function()
                return panel:GetChildAt(index)
            end))
            local setting = runtime:unwrap(runtime:try(function()
                return child.m_Setting
            end))
            local setting_name = object_full_name(setting)
            if setting_name:find("SettingObject_Int_Test", 1, true) ~= nil
                or setting_name:find("SettingObject_Float_Test", 1, true)
                    ~= nil
                or setting_name:find("SettingObject_Enum_Test", 1, true)
                    ~= nil
            then
                table.insert(native_test_rows, child)
            end
        end
    end
    page_state.native_test_rows = {}
    for _, child in ipairs(native_test_rows) do
        set_widget_visibility(runtime, child, WIDGET_VISIBILITY_COLLAPSED)
        table.insert(page_state.native_test_rows, child)
    end

    page_state.bindings = {}
    page_state.headers = {}
    page_state.native_bool_row = native_bool_row
    page_state.native_bool_claimed = false
    page_state.initialized = true
    return true
end

local function collapse_native_test_rows(runtime, page_state)
    for _, row in ipairs(page_state.native_test_rows or {}) do
        if is_valid_object(row) then
            set_widget_visibility(runtime, row, WIDGET_VISIBILITY_COLLAPSED)
        end
    end
end

local function inject_game_settings(runtime, page)
    page = runtime:unwrap(page)
    if not is_mod_settings_page(page) then return false end
    local panel = runtime:unwrap(runtime:try(function()
        return page.VerticalBox_Content
    end))
    if not is_valid_object(panel) then return false end

    local page_key = object_identity(page)
    if page_key == "" then return false end
    local page_state = game_settings_state.pages[page_key]
    if page_state == nil then
        page_state = { bindings = {}, headers = {} }
        game_settings_state.pages[page_key] = page_state
    end
    if not initialize_mod_settings_page(runtime, page, page_state, panel) then
        runtime:log("Could not initialize the native Mods settings page")
        return false
    end
    collapse_native_test_rows(runtime, page_state)

    local injected = 0
    for _, id in ipairs(game_settings_state.order) do
        local entry = game_settings_state.entries[id]
        if entry ~= nil then
            ensure_mod_header(runtime, page, page_state, panel, entry.section)
        end
        if entry ~= nil and inject_bool_setting(runtime, page, page_state, entry,
            panel)
        then
            injected = injected + 1
        end
    end
    ensure_mod_section_order(runtime, page_state, panel)
    for _, binding in pairs(page_state.bindings) do
        enable_binding(binding)
    end
    collapse_native_test_rows(runtime, page_state)
    return injected > 0
end

local function switcher_widget_count(runtime, switcher)
    local count = tonumber(runtime:unwrap(runtime:try(function()
        return switcher:GetNumWidgets()
    end)))
    if count ~= nil then return count end

    -- CommonActivatableWidgetSwitcher inherits PanelWidget. In this game its
    -- concrete wrapper can expose the inherited panel methods even when the
    -- WidgetSwitcher convenience methods are temporarily unavailable.
    count = tonumber(runtime:unwrap(runtime:try(function()
        return switcher:GetChildrenCount()
    end)))
    if count ~= nil then return count end

    local slots = runtime:try(function() return switcher.Slots end)
    if slots ~= nil then
        return tonumber(runtime:try(function() return #slots end))
    end
    return nil
end

local function switcher_widget_at(runtime, switcher, index)
    local page = runtime:unwrap(runtime:try(function()
        return switcher:GetWidgetAtIndex(index)
    end))
    if is_valid_object(page) then return page end
    page = runtime:unwrap(runtime:try(function()
        return switcher:GetChildAt(index)
    end))
    if is_valid_object(page) then return page end

    local slots = runtime:try(function() return switcher.Slots end)
    local slot = runtime:unwrap(runtime:try(function()
        return slots[index + 1]
    end))
    return runtime:unwrap(runtime:try(function()
        return slot.Content
    end))
end

local function find_mod_settings_page(runtime, switcher)
    local count = switcher_widget_count(runtime, switcher) or 0
    for index = 0, count - 1 do
        local page = switcher_widget_at(runtime, switcher, index)
        if is_mod_settings_page(page) then return page end
    end
    return nil
end

local function enable_mod_settings_page(runtime, page)
    page = runtime:unwrap(page)
    if not is_mod_settings_page(page) then return false end

    -- SetIsEnabled(true) is accepted by UE4SS for this widget but leaves the
    -- reflected bit false. CreatePageButtons reads this exact UWidget bit
    -- (offset 0xD9, mask 0x04), so update it directly first. Calling the native
    -- setter afterwards synchronizes the live UMG state without relying on an
    -- unsafe construction-time object notification.
    local written = set_bool_property(page, "bIsEnabled", true)
    runtime:try(function() page:SetIsEnabled(true) end)
    return written
end

local function settings_page_button_for(runtime, main, switcher, target_page,
    button_base, resolve_button)
    local settings_page_class = runtime:find_object(
        "/Script/G1R.SettingsPageWidget")
    if not is_valid_object(settings_page_class) then return nil end

    local ordinal = 0
    local target_ordinal = nil
    local count = switcher_widget_count(runtime, switcher) or 0
    for index = 0, count - 1 do
        local page = switcher_widget_at(runtime, switcher, index)
        local is_settings_page = is_valid_object(page)
            and runtime:try(function()
                return page:IsA(settings_page_class)
            end) == true
        local enabled = is_settings_page and runtime:try(function()
            return page.bIsEnabled
        end) == true
        if enabled then
            ordinal = ordinal + 1
            if object_identity(page) == object_identity(target_page) then
                target_ordinal = ordinal
            end
        end
    end
    if target_ordinal == nil then return nil, nil, ordinal end
    -- Never index the still-empty native TArray from CreatePageButtons' pre-
    -- hook. UE4SS grows a TArray when an out-of-range index is accessed, which
    -- would insert a null slot before Gothic appends its real buttons.
    if resolve_button == false then
        return nil, target_ordinal, ordinal
    end
    return runtime:unwrap(runtime:try(function()
        return main.m_PageButtons[
            (tonumber(button_base) or 0) + target_ordinal]
    end)), target_ordinal, ordinal
end

local function finalize_native_mod_settings_page(runtime, main,
    supplied_switcher, button_base)
    main = runtime:unwrap(main)
    if not is_valid_object(main)
        or object_full_name(main):find("W_SettingsMain_C", 1, true) == nil
    then
        return nil
    end
    local switcher = runtime:unwrap(supplied_switcher)
    if not is_valid_object(switcher) then
        switcher = runtime:unwrap(runtime:try(function()
            return main.WidgetSwitcher_Pages
        end))
    end
    if not is_valid_object(switcher) then return nil end

    local page = find_mod_settings_page(runtime, switcher)
    if not is_valid_object(page) then return nil end
    enable_mod_settings_page(runtime, page)

    local main_key = object_identity(main)
    if main_key == "" then return page end

    local state = game_settings_state.native_pages_by_main[main_key]
    local button = state and runtime:unwrap(state.button) or nil
    -- A button can only be mapped to this page after CreatePageButtons has
    -- produced the complete native batch. Positional lookup without that
    -- confirmation maps ordinal 1 to the Game button when the dormant Test
    -- page was skipped, which would rename Game to Mods.
    if state == nil and button_base == nil then return page end
    -- SettingsMain can be reused. Gothic then clears the visible panel and
    -- appends a fresh native button batch while the previous button UObjects
    -- remain valid in m_PageButtons. An explicit batch base must therefore
    -- always replace the cached (now hidden) button with the new visible one.
    if button_base ~= nil or not is_valid_object(button) then
        button = settings_page_button_for(runtime, main, switcher,
            page, button_base)
    end
    if not is_valid_object(button) then return page end

    local display_name = to_text(runtime, localized_section_name(runtime))
    runtime:try(function() button:SetDisplayName(display_name) end)
    runtime:try(function()
        if is_valid_object(button.TextBlock_Name) then
            button.TextBlock_Name:SetText(display_name)
        end
    end)
    if state == nil then
        state = {}
        game_settings_state.native_pages_by_main[main_key] = state
    end
    state.main = main
    state.page = page
    state.button = button
    return page, button
end

local function activate_native_mod_settings_page(runtime, page)
    page = runtime:unwrap(page)
    if not is_mod_settings_page(page) then return false end

    local display_name = to_text(runtime, localized_section_name(runtime))
    for _, state in pairs(game_settings_state.native_pages_by_main) do
        if object_identity(state.page) == object_identity(page) then
            runtime:try(function()
                state.button:SetDisplayName(display_name)
            end)
            runtime:try(function()
                if is_valid_object(state.button.TextBlock_Name) then
                    state.button.TextBlock_Name:SetText(display_name)
                end
            end)
            runtime:try(function()
                if is_valid_object(state.main.TextBlock_Title) then
                    state.main.TextBlock_Title:SetText(display_name)
                end
            end)
        end
    end
    return inject_game_settings(runtime, page)
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
    if not is_mod_settings_page(page) then return end

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
    if game_settings_state.create_page_buttons_hook_registered ~= true
        and is_valid_object(runtime:find_object(
            SETTINGS_MAIN_CREATE_PAGE_BUTTONS))
    then
        if runtime:register_hook(SETTINGS_MAIN_CREATE_PAGE_BUTTONS,
            function(context, pages_switcher)
                local main = runtime:unwrap(context)
                if object_full_name(main):find(
                    "W_SettingsMain_C", 1, true) == nil
                then
                    return nil
                end

                -- Use the UFunction parameter. During W_SettingsMain
                -- construction, the bound WidgetSwitcher_Pages property is
                -- not guaranteed to be initialized before this call.
                local switcher = runtime:unwrap(pages_switcher)
                local page = find_mod_settings_page(runtime, switcher)
                -- CreatePageButtons skips every SettingsPageWidget for which
                -- UWidget::GetIsEnabled() returns false. Enabling the dormant
                -- Test page here lets Gothic create and bind its native button.
                enable_mod_settings_page(runtime, page)
                local main_key = object_identity(main)
                local button_base = tonumber(runtime:try(function()
                    return #main.m_PageButtons
                end)) or 0
                local _, _, expected_buttons =
                    settings_page_button_for(runtime, main, switcher, page,
                        button_base, false)
                if main_key ~= "" then
                    game_settings_state.create_page_button_batches[main_key] = {
                        button_base = button_base,
                        expected_buttons = expected_buttons,
                    }
                end
                return nil
            end,
            function(context, pages_switcher)
                local main = runtime:unwrap(context)
                if object_full_name(main):find(
                    "W_SettingsMain_C", 1, true) == nil
                then
                    return nil
                end

                local main_key = object_identity(main)
                local switcher = runtime:unwrap(pages_switcher)
                local button_count = tonumber(runtime:try(function()
                    return #main.m_PageButtons
                end)) or 0
                local batch = game_settings_state.create_page_button_batches[
                    main_key]
                local button_base = batch and batch.button_base or 0
                local expected_buttons = batch and batch.expected_buttons or 0
                game_settings_state.create_page_button_batches[main_key] = nil
                local added_buttons = button_count - button_base
                -- The switcher can contain native pages that Gothic includes
                -- independently of their reflected bIsEnabled value. Require
                -- at least the complete raw-enabled batch: this accepts the
                -- observed stable 9/8 build while rejecting the unsafe 7/8
                -- partial build from 0.4.38.
                if expected_buttons > 0
                    and added_buttons >= expected_buttons
                then
                    runtime:delay_game_thread(0, function()
                        finalize_native_mod_settings_page(runtime, main,
                            switcher, button_base)
                    end)
                else
                    runtime:log("Native Mods page was skipped; deferring "
                        .. "finalization until the next page-button build")
                end
                return nil
            end
        ) then
            game_settings_state.create_page_buttons_hook_registered = true
        end
    end

    if game_settings_state.focus_active_button_hook_registered ~= true
        and is_valid_object(runtime:find_object(
            SETTINGS_MAIN_FOCUS_ACTIVE_BUTTON))
    then
        if runtime:register_hook(SETTINGS_MAIN_FOCUS_ACTIVE_BUTTON,
            function()
                return nil
            end,
            function(context)
                local main = runtime:unwrap(context)
                if object_full_name(main):find(
                    "W_SettingsMain_C", 1, true) ~= nil
                then
                    runtime:delay_game_thread(0, function()
                        finalize_native_mod_settings_page(runtime, main)
                    end)
                end
                return nil
            end
        ) then
            game_settings_state.focus_active_button_hook_registered = true
        end
    end

    if game_settings_state.active_page_changed_hook_registered ~= true
        and is_valid_object(runtime:find_object(
            SETTINGS_MAIN_ACTIVE_PAGE_CHANGED))
    then
        if runtime:register_hook(SETTINGS_MAIN_ACTIVE_PAGE_CHANGED,
            function(context)
                local main = runtime:unwrap(context)
                runtime:delay_game_thread(0, function()
                    finalize_native_mod_settings_page(runtime, main)
                end)
                return nil
            end)
        then
            game_settings_state.active_page_changed_hook_registered = true
        end
    end

    if game_settings_state.page_activated_hook_registered ~= true
        and is_valid_object(runtime:find_object(MOD_SETTINGS_PAGE_ACTIVATED))
    then
        if runtime:register_hook(MOD_SETTINGS_PAGE_ACTIVATED, function(context)
            local page = runtime:unwrap(context)
            runtime:delay_game_thread(0, function()
                activate_native_mod_settings_page(runtime, page)
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
            noop,
            function(context)
                local page = runtime:unwrap(context)
                if is_mod_settings_page(page) then
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
    if type(NotifyOnNewObject) ~= "function" then return false end

    if game_settings_state.page_notify_registered ~= true then
        game_settings_state.page_notify_registered = pcall(function()
            NotifyOnNewObject(MOD_SETTINGS_PAGE_CLASS, function(page)
                page = runtime:unwrap(page)
                local full_name = object_full_name(page)
                if full_name:find("Default__", 1, true) ~= nil then return end

                -- Seed only the reflected gate read by CreatePageButtons. Do
                -- not call widget functions or touch FText/content while the
                -- instance is still being constructed.
                pcall(function()
                    page.bIsEnabled = true
                end)
            end)
        end)
    end
    if game_settings_state.main_notify_registered ~= true then
        game_settings_state.main_notify_registered = pcall(function()
            NotifyOnNewObject(MOD_SETTINGS_MAIN_CLASS, function()
                ensure_game_settings_hooks(runtime)
                -- CreatePageButtons is called after this notification and is
                -- the definitive ready signal for this instance.
            end)
        end)
    end
    return game_settings_state.page_notify_registered == true
        and game_settings_state.main_notify_registered == true
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
        section = trim(options.section or options.group or runtime.mod_name),
        default = options.default == true,
        get = options.get,
        set = options.set,
        persist = options.persist,
        translations = options.translations,
    }
    game_settings_state.entries[id] = entry

    ensure_game_settings_notifications(runtime)
    ensure_game_settings_hooks(runtime)
    for _, main in ipairs(runtime:find_all_of("W_SettingsMain_C")) do
        local target_main = main
        runtime:delay_game_thread(0, function()
            finalize_native_mod_settings_page(runtime, target_main)
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
