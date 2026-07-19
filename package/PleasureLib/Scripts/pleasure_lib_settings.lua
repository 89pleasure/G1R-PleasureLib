return function(dependencies)
    local noop = dependencies.noop
    local try = dependencies.try
    local trim = dependencies.trim
    local lower = dependencies.lower
    local unwrap = dependencies.unwrap
    local is_valid_object = dependencies.is_valid_object
    local safe_to_string = dependencies.safe_to_string
    local object_full_name = dependencies.object_full_name
    local update_ini_value = dependencies.update_ini_value

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
    local GAME_SETTINGS_DETAILS_CLASS =
        "/Game/UI/CoreMenus/Settings/W_SettingsDetails.W_SettingsDetails_C"
    local SETTINGS_DETAILS_SET = GAME_SETTINGS_DETAILS_CLASS .. ":SetDetails"
    local SETTINGS_DETAILS_CLEAR = GAME_SETTINGS_DETAILS_CLASS .. ":ClearDetails"
    local SETTINGS_PAGE_APPLY_CHANGES = "/Script/G1R.SettingsPageWidget:ApplyChanges"
    local SETTINGS_PAGE_DISCARD_CHANGES = "/Script/G1R.SettingsPageWidget:DiscardChanges"
    local GAME_SETTINGS_ROW_CLASS =
        "/Game/UI/CoreMenus/Settings/W_SettingsRow.W_SettingsRow_C"
    local GAME_SETTINGS_ROW_CREATE_WIDGET =
        GAME_SETTINGS_ROW_CLASS .. ":Create Setting Widget"
    local GAME_SETTINGS_ROW_SET_ENABLED =
        GAME_SETTINGS_ROW_CLASS .. ":Set Enabled Selectable"
    local GAME_SETTINGS_ROW_UPDATE_VISUALS =
        GAME_SETTINGS_ROW_CLASS .. ":Update Visuals"
    local GAME_SETTINGS_HEADER_CLASS =
        "/Game/UI/CoreMenus/Settings/W_SettingsSectionHeader.W_SettingsSectionHeader_C"
    local WIDGET_BLUEPRINT_LIBRARY = "/Script/UMG.Default__WidgetBlueprintLibrary"
    local WIDGET_SET_CLIPPING = "/Script/UMG.Widget:SetClipping"
    local WIDGET_SET_VISIBILITY = "/Script/UMG.Widget:SetVisibility"
    local INTERNATIONALIZATION_LIBRARY =
        "/Script/Engine.Default__KismetInternationalizationLibrary"
    local WIDGET_CLIPPING_CLIP_TO_BOUNDS = 1
    local WIDGET_VISIBILITY_COLLAPSED = 1
    local ENUM_WIDGET_SPINNER = 0
    local ENUM_WIDGET_DROPDOWN = 1
    local NATIVE_TEST_ROW_NAMES = {
        SettingsRow_Bool = true,
        SettingsRow_Int = true,
        SettingsRow_Float = true,
        SettingsRow_Enum = true,
        SettingsRow_Enum_Dropdown = true,
    }
    local GAME_SETTING_TYPES = {
        bool = {
            object_class = "/Script/G1R.SettingObject_Bool_Test",
            widget_class =
                "/Game/UI/CoreMenus/Settings/W_Setting_Bool.W_Setting_Bool_C",
            setting_set_value = "/Script/G1R.SettingObject_Bool:SetValue",
            widget_set_value =
                "/Script/G1R.SettingObjectWidget_Bool:SetValue",
            widget_changed = {
                "/Game/UI/CoreMenus/Settings/W_Setting_Bool.W_Setting_Bool_C"
                    .. ":OnValueChanged",
            },
            native_name = "SettingObject_Bool_Test",
        },
        int = {
            object_class = "/Script/G1R.SettingObject_Int_Test",
            widget_class =
                "/Game/UI/CoreMenus/Settings/W_Setting_Int.W_Setting_Int_C",
            setting_set_value = "/Script/G1R.SettingObject_Int:SetValue",
            widget_set_value =
                "/Script/G1R.SettingObjectWidget_Int:SetValue",
            widget_changed = {
                "/Game/UI/CoreMenus/Settings/W_Setting_Int.W_Setting_Int_C"
                    .. ":OnValueChanged",
            },
            native_name = "SettingObject_Int_Test",
        },
        float = {
            object_class = "/Script/G1R.SettingObject_Float_Test",
            widget_class =
                "/Game/UI/CoreMenus/Settings/W_Setting_Float.W_Setting_Float_C",
            setting_set_value = "/Script/G1R.SettingObject_Float:SetValue",
            widget_set_value =
                "/Script/G1R.SettingObjectWidget_Float:SetValue",
            widget_changed = {
                "/Game/UI/CoreMenus/Settings/W_Setting_Float.W_Setting_Float_C"
                    .. ":OnValueChanged",
            },
            native_name = "SettingObject_Float_Test",
        },
        enum = {
            object_class = "/Script/G1R.SettingObject_Enum_Test",
            widget_class =
                "/Game/UI/CoreMenus/Settings/W_Setting_Enum.W_Setting_Enum_C",
            dropdown_widget_class =
                "/Game/UI/CoreMenus/Settings/W_Setting_EnumDropDown"
                    .. ".W_Setting_EnumDropDown_C",
            setting_set_value = "/Script/G1R.SettingObject_Enum:SetValue",
            widget_set_value =
                "/Script/G1R.SettingObjectWidget_Enum:SetValue",
            widget_changed = {
                "/Game/UI/CoreMenus/Settings/W_Setting_Enum.W_Setting_Enum_C"
                    .. ":OnValueChanged",
                "/Game/UI/CoreMenus/Settings/W_Setting_EnumDropDown"
                    .. ".W_Setting_EnumDropDown_C:OnValueChanged",
            },
            native_name = "SettingObject_Enum_Test",
        },
    }
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
        row_visuals_hook_registered = false,
        page_apply_hook_registered = false,
        page_discard_hook_registered = false,
        value_hooks_registered = {},
        native_pages_by_main = {},
        create_page_button_batches = {},
        bindings_by_widget = {},
        bindings_by_setting = {},
        bindings_by_row = {},
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

    local function is_native_test_row(row)
        local full_name = object_full_name(row)
        local short_name = full_name:match("([^%.: ]+)$")
        return short_name ~= nil and NATIVE_TEST_ROW_NAMES[short_name] == true
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

    local function set_widget_clipping(runtime, widget, clipping)
        if not is_valid_object(widget) then return false end

        -- SScrollBox is a clipping proxy. Invoke the reflected setter so its
        -- nested Slate widgets receive the new clipping state immediately.
        local set_clipping_function = runtime:find_object(WIDGET_SET_CLIPPING)
        if is_valid_object(set_clipping_function) then
            local reflected_ok = pcall(function()
                return set_clipping_function(widget, clipping)
            end)
            if reflected_ok then return true end
        end

        local member_ok = pcall(function()
            return widget:SetClipping(clipping)
        end)
        if member_ok then return true end

        -- Construction-time reflection can expose the property before either
        -- setter. Keep the raw value as a seed for the next Slate rebuild.
        return set_object_property(widget, "Clipping", clipping)
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

    local function finite_number(value)
        local number = tonumber(value)
        if number == nil or number ~= number
            or number == math.huge or number == -math.huge
        then
            return nil
        end
        return number
    end

    local function clamp_number(value, minimum, maximum)
        if minimum ~= nil and value < minimum then return minimum end
        if maximum ~= nil and value > maximum then return maximum end
        return value
    end

    local function coerce_setting_value(entry, value)
        if entry.kind == "bool" then
            if type(value) == "boolean" then return value end
            return nil
        end

        local number = finite_number(value)
        if number == nil then return nil end
        if entry.kind == "int" or entry.kind == "enum" then
            number = math.floor(number)
        end
        return clamp_number(number, entry.minimum, entry.maximum)
    end

    local function setting_value(entry)
        local value = entry.runtime:try(entry.get)
        value = coerce_setting_value(entry, value)
        if value == nil then value = coerce_setting_value(entry, entry.default) end
        if value ~= nil then return value end
        if entry.kind == "bool" then return false end
        return entry.minimum or 0
    end

    local function setting_values_equal(entry, left, right)
        if entry.kind == "float" then
            left = finite_number(left)
            right = finite_number(right)
            return left ~= nil and right ~= nil and math.abs(left - right) <= 0.000001
        end
        return left == right
    end

    local function localized_enum_value(runtime, entry, index)
        local translations = entry.value_translations
        if type(translations) == "table" then
            local language = current_language(runtime)
            local base = language:match("^([^-]+)") or language
            local selected = translations[language]
                or translations[base]
                or translations.en
                or translations["en-us"]
            if type(selected) == "table" then
                local value = selected[index]
                if type(value) == "table" then
                    value = value.name or value.label
                end
                if value ~= nil then return tostring(value) end
            end
        end

        local value = entry.values[index]
        if type(value) == "table" then
            local fallback = value.name or value.label or value.value or index - 1
            return localized_value(runtime,
                value.translations or value.labels or value, "name", fallback)
        end
        if value ~= nil then return tostring(value) end
        return tostring(index - 1)
    end

    local function resolve_persist_value(value)
        if type(value) == "function" then
            local ok, resolved = pcall(value)
            if ok then return resolved end
            return nil
        end
        return value
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

    local function configure_setting_type(runtime, setting, entry)
        local value = setting_value(entry)

        if entry.kind == "bool" then
            set_bool_property(setting, "m_DefaultValue", entry.default)
        elseif entry.kind == "int" then
            set_integer_property(setting, "m_DefaultValue", entry.default)
            set_integer_property(setting, "m_MinValue", entry.minimum)
            set_integer_property(setting, "m_MaxValue", entry.maximum)
        elseif entry.kind == "float" then
            set_object_property(setting, "m_DefaultValue", entry.default)
            set_object_property(setting, "m_MinValue", entry.minimum)
            set_object_property(setting, "m_MaxValue", entry.maximum)
            set_object_property(setting, "m_StepSize", entry.step)
            set_bool_property(setting, "m_AlwaysShowSign",
                entry.always_show_sign)
        elseif entry.kind == "enum" then
            set_integer_property(setting, "m_DefaultValue", entry.default)
            set_integer_property(setting, "m_WidgetType", entry.enum_widget)
            set_bool_property(setting, "m_ShouldValueWrapAround",
                entry.wrap_around)

            local names = runtime:try(function()
                return setting.m_ValueNames
            end)
            local array_ready = names ~= nil and pcall(function()
                names:Empty()
                for index = 1, #entry.values do
                    names[index] = to_text(runtime,
                        localized_enum_value(runtime, entry, index))
                end
            end)
            if not array_ready then
                runtime:debug_log("mod setting '" .. entry.id
                    .. "' enum value names could not be initialized")
                return false
            end
            runtime:try(function() setting:Refresh() end)
        end

        runtime:try(function() setting:SetValue(value) end)
        runtime:try(function() setting:ConfirmValue() end)
        return true
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
        configure_setting_type(runtime, binding.setting, entry)
        runtime:try(function()
            if is_valid_object(binding.widget) then
                binding.widget:SetSettingObject(binding.setting)
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
        runtime:try(function() binding.widget.Slider:SetIsEnabled(true) end)
        runtime:try(function() binding.widget.Button_ArrowLeft:SetIsEnabled(true) end)
        runtime:try(function() binding.widget.Button_ArrowRight:SetIsEnabled(true) end)
        runtime:try(function() binding.widget.Button_Center:SetIsEnabled(true) end)
        runtime:try(function() binding.widget.ComboBox_Options:SetIsEnabled(true) end)
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

    local function link_setting_widget(runtime, row, widget, setting)
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

    local function create_setting_widget(runtime, row, setting, entry)
        local widget = current_row_setting_widget(runtime, row)
        if is_valid_object(widget)
            and link_setting_widget(runtime, row, widget, setting)
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
                and link_setting_widget(runtime, row, widget, setting)
            then
                return widget, nil
            end

            runtime:debug_log("native settings row widget creation failed"
                .. " ok=" .. tostring(ok)
                .. " result=" .. safe_to_string(runtime:unwrap(result))
                .. " widget=" .. object_full_name(widget)
                .. " content=" .. object_full_name(widget))
        end

        local setting_type = GAME_SETTING_TYPES[entry.kind]
        local widget_class = setting_type and setting_type.widget_class
        if entry.kind == "enum" and entry.enum_widget == ENUM_WIDGET_DROPDOWN then
            widget_class = setting_type and setting_type.dropdown_widget_class
        end
        local widget = create_user_widget(runtime, row, widget_class)
        if not is_valid_object(widget) then
            return nil, entry.kind .. " widget creation failed"
        end
        if not link_setting_widget(runtime, row, widget, setting) then
            return nil, entry.kind .. " widget setting link failed"
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
                    and link_setting_widget(runtime, row, content, setting)
                then
                    runtime:try(function() widget:RemoveFromParent() end)
                    widget = content
                else
                    return nil, entry.kind
                        .. " widget could not be set as row content"
                        .. "; requested=" .. object_full_name(widget)
                        .. "; actual=" .. object_full_name(content)
                end
            end
        end
        return widget, nil
    end

    local function unindex_binding(binding)
        local row_key = object_identity(binding and binding.row)
        if row_key ~= "" then game_settings_state.bindings_by_row[row_key] = nil end
        local widget_key = object_identity(binding and binding.widget)
        if widget_key ~= "" then game_settings_state.bindings_by_widget[widget_key] = nil end
        local setting_key = object_identity(binding and binding.setting)
        if setting_key ~= "" then game_settings_state.bindings_by_setting[setting_key] = nil end
    end

    local function index_binding(binding)
        local row_key = object_identity(binding.row)
        if row_key ~= "" then
            game_settings_state.bindings_by_row[row_key] = binding
        end
        local widget_key = object_identity(binding.widget)
        if widget_key ~= "" then
            game_settings_state.bindings_by_widget[widget_key] = binding
        end
        local setting_key = object_identity(binding.setting)
        if setting_key ~= "" then
            game_settings_state.bindings_by_setting[setting_key] = binding
        end
    end

    local function binding_for_game_settings_row(row)
        local binding = game_settings_state.bindings_by_row[
            object_identity(row)]
        if binding == nil
            or not is_valid_object(binding.page)
            or object_identity(binding.row) ~= object_identity(row)
        then
            return nil
        end
        return binding
    end

    local function update_game_settings_details(runtime, binding, selected)
        local details = runtime:unwrap(runtime:try(function()
            return binding.page.m_SettingsDetailWidget
        end))
        if not is_valid_object(details) then return false end

        if selected == true then
            local description = runtime:try(function()
                return binding.setting.m_Description
            end)
            local set_details = runtime:find_object(SETTINGS_DETAILS_SET)
            if description == nil or not is_valid_object(set_details) then
                return false
            end
            return runtime:try(function()
                set_details(details, description)
                return true
            end) == true
        end

        local clear_details = runtime:find_object(SETTINGS_DETAILS_CLEAR)
        if not is_valid_object(clear_details) then return false end
        return runtime:try(function()
            clear_details(details)
            return true
        end) == true
    end

    local function update_details_for_game_settings_row(runtime, row, selected)
        local binding = binding_for_game_settings_row(row)
        if binding == nil then return end
        update_game_settings_details(runtime, binding, selected)
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
            link_setting_widget(runtime, binding.row, linked_widget,
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
            link_setting_widget(runtime, binding.row, content, binding.setting)
            unindex_binding(binding)
            binding.widget = content
            index_binding(binding)
        elseif not is_valid_object(binding.widget) then
            local widget = create_setting_widget(runtime, binding.row,
                binding.setting, binding.entry)
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

    local function entry_signature(entry)
        if entry.kind == "enum" then
            return entry.kind .. ":" .. tostring(entry.enum_widget)
        end
        return entry.kind
    end

    local function inject_setting(runtime, page, page_state, entry, panel)
        local existing_binding = page_state.bindings[entry.id]
        if existing_binding ~= nil
            and is_valid_object(existing_binding.row)
            and is_valid_object(existing_binding.setting)
            and existing_binding.signature == entry_signature(entry)
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

        local row = create_user_widget(runtime, page, GAME_SETTINGS_ROW_CLASS)
        if not is_valid_object(row) then
            runtime:debug_log("mod setting '" .. entry.id
                .. "' failed: settings row could not be created")
            return false
        end
        local setting_type = GAME_SETTING_TYPES[entry.kind]
        local setting = construct_object(runtime, setting_type.object_class, row)
        if not is_valid_object(setting) then
            runtime:debug_log("mod setting '" .. entry.id
                .. "' failed: " .. entry.kind .. " setting object unavailable")
            return false
        end

        local name_text = update_setting_description(runtime, setting, entry)
        local value = setting_value(entry)
        -- Both are restriction masks. Zero matches an unrestricted native Game
        -- setting and avoids relying on the page's row registry during cold-start.
        if not configure_setting_availability(runtime, setting) then
            runtime:debug_log("mod setting '" .. entry.id
                .. "' availability initialization failed")
        end

        if not configure_setting_type(runtime, setting, entry) then
            return false
        end
        set_object_property(row, "m_Setting", setting)
        set_object_property(row, "m_AutoApplyChanges", true)

        runtime:try(function()
            if is_valid_object(row.Text_Name) then row.Text_Name:SetText(name_text) end
        end)
        runtime:try(function() row:Reinitialize() end)
        configure_setting_availability(runtime, setting)
        local widget, widget_error = create_setting_widget(runtime, row, setting,
            entry)
        if not is_valid_object(widget) then
            runtime:debug_log("mod setting '" .. entry.id
                .. "' failed: " .. tostring(widget_error))
            return false
        end
        configure_setting_availability(runtime, setting)
        link_setting_widget(runtime, row, widget, setting)
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
            signature = entry_signature(entry),
            synchronizing = false,
        }
        if not append_settings_row(page, row) then
            runtime:try(function() row:RemoveFromParent() end)
            runtime:debug_log("mod setting '" .. entry.id
                .. "' failed: row could not be appended to page registry")
            return false
        end
        page_state.bindings[entry.id] = binding
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

        local native_rows = {}
        local native_row_keys = {}
        local function add_native_row(row)
            if not is_valid_object(row) then return end
            -- Every API row uses the same typed Test setting classes as the
            -- original examples. A later mod can therefore distinguish them
            -- only by the five stable WidgetTree row names, not by setting
            -- class. Generated rows have runtime W_SettingsRow_C_* names.
            if not is_native_test_row(row) then return end
            local setting = runtime:unwrap(runtime:try(function()
                return row.m_Setting
            end))
            if not is_valid_object(setting) then return end

            local setting_name = object_full_name(setting)
            local is_native_test_setting = false
            for _, setting_type in pairs(GAME_SETTING_TYPES) do
                if setting_name:find(setting_type.native_name, 1, true) ~= nil then
                    is_native_test_setting = true
                    break
                end
            end
            if not is_native_test_setting then return end

            local row_key = object_identity(row)
            if row_key == "" or native_row_keys[row_key] == true then return end
            native_row_keys[row_key] = true

            table.insert(native_rows, {
                row = row,
            })
        end

        local rows = runtime:try(function() return page.m_SettingsRowWidgets end)
        if rows ~= nil then
            for index = 1, #rows do
                add_native_row(runtime:unwrap(runtime:try(function()
                    return rows[index]
                end)))
            end
        end

        local child_count = panel_child_count(runtime, panel)
        if child_count ~= nil then
            for index = 0, child_count - 1 do
                add_native_row(runtime:unwrap(runtime:try(function()
                    return panel:GetChildAt(index)
                end)))
            end
        end
        if #native_rows == 0 then return false end

        page_state.bindings = {}
        page_state.headers = {}
        page_state.native_rows = native_rows
        for _, candidate in ipairs(native_rows) do
            set_widget_visibility(runtime, candidate.row,
                WIDGET_VISIBILITY_COLLAPSED)
        end
        page_state.initialized = true
        return true
    end

    local function hide_native_test_rows(runtime, page_state)
        for _, candidate in ipairs(page_state.native_rows or {}) do
            if is_valid_object(candidate.row) then
                set_widget_visibility(runtime, candidate.row,
                    WIDGET_VISIBILITY_COLLAPSED)
            end
        end
    end

    local function inject_game_settings(runtime, page)
        page = runtime:unwrap(page)
        if not is_mod_settings_page(page) then return false end
        local scroll_box = runtime:unwrap(runtime:try(function()
            return page.ScrollBox_Content
        end))
        if is_valid_object(scroll_box)
            and not set_widget_clipping(runtime, scroll_box,
                WIDGET_CLIPPING_CLIP_TO_BOUNDS)
        then
            runtime:debug_log("native Mods settings scroll clipping failed")
        end
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
        hide_native_test_rows(runtime, page_state)

        local injected = 0
        for _, id in ipairs(game_settings_state.order) do
            local entry = game_settings_state.entries[id]
            if entry ~= nil then
                ensure_mod_header(runtime, page, page_state, panel, entry.section)
            end
            if entry ~= nil and inject_setting(runtime, page, page_state, entry,
                panel)
            then
                injected = injected + 1
            end
        end
        ensure_mod_section_order(runtime, page_state, panel)
        for _, binding in pairs(page_state.bindings) do
            enable_binding(binding)
        end
        hide_native_test_rows(runtime, page_state)
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

    local function persist_setting_value(entry, value)
        if type(entry.persist) ~= "table" then return true end

        local path = resolve_persist_value(entry.persist.path)
        local key = resolve_persist_value(entry.persist.key)
        if path == nil or key == nil then return true end

        local serialized = value
        if type(entry.persist.serialize) == "function" then
            local ok, result = pcall(entry.persist.serialize, value)
            if not ok then return false end
            serialized = result
        elseif type(value) == "boolean" then
            serialized = value and "true" or "false"
        end
        return update_ini_value(path, key, tostring(serialized))
    end

    local function apply_setting_value(binding, value)
        local entry = binding.entry
        local runtime = entry.runtime
        value = coerce_setting_value(entry, value)
        if value == nil then return false end

        local accepted = true
        if type(entry.set) == "function" then
            local ok, result = pcall(entry.set, value)
            accepted = ok and result ~= false
            if not ok then
                runtime:log("game setting '" .. entry.id .. "' failed: "
                    .. safe_to_string(result))
            end
        end

        if accepted then
            local persisted = persist_setting_value(entry, value)
            if not persisted then
                runtime:log("Could not persist game setting '" .. entry.id .. "'")
            end
        end

        if not accepted then synchronize_binding(binding) end
        return accepted
    end

    local function native_parameter_value(runtime, entry, parameter)
        local value = runtime:unwrap(parameter)
        if entry.kind == "bool" then
            if type(value) == "boolean" then return value end
            local text = lower(value)
            if text == "true" or text == "1" then return true end
            if text == "false" or text == "0" then return false end
            return nil
        end
        return coerce_setting_value(entry, value)
    end

    local function handle_native_setting_value(runtime, binding, parameter, source)
        if binding == nil or binding.synchronizing == true then return end
        local value = native_parameter_value(runtime, binding.entry, parameter)
        if value == nil then
            runtime:debug_log("game setting native value unavailable"
                .. " source=" .. tostring(source)
                .. " parameter=" .. safe_to_string(parameter))
            return
        end
        if setting_values_equal(binding.entry, value,
            setting_value(binding.entry))
        then
            return
        end

        if apply_setting_value(binding, value) then
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
                local value = coerce_setting_value(binding.entry, widget_value)
                if value == nil then
                    value = coerce_setting_value(binding.entry,
                        setting_object_value)
                end

                if value ~= nil then
                    local accepted = true
                    if not setting_values_equal(binding.entry, value,
                        setting_value(binding.entry))
                    then
                        accepted = apply_setting_value(binding, value)
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

    local function binding_for_setting_widget(runtime, context)
        local widget = runtime:unwrap(context)
        local widget_key = object_identity(widget)
        local binding = game_settings_state.bindings_by_widget[widget_key]
        if binding ~= nil then return widget, binding end

        -- A settings page recreation can replace the row's setting widget after the
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

        if game_settings_state.row_visuals_hook_registered ~= true
            and is_valid_object(runtime:find_object(
                GAME_SETTINGS_ROW_UPDATE_VISUALS))
        then
            if runtime:register_hook(GAME_SETTINGS_ROW_UPDATE_VISUALS,
                function(context, is_focused)
                    update_details_for_game_settings_row(
                        runtime,
                        runtime:unwrap(context),
                        runtime:unwrap(is_focused) == true)
                    return nil
                end
            ) then
                game_settings_state.row_visuals_hook_registered = true
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

        for kind, setting_type in pairs(GAME_SETTING_TYPES) do
            local kind_name = kind
            local hook_state = game_settings_state.value_hooks_registered[kind]
            if hook_state == nil then
                hook_state = { changed = {} }
                game_settings_state.value_hooks_registered[kind] = hook_state
            end

            if hook_state.widget ~= true
                and is_valid_object(runtime:find_object(
                    setting_type.widget_set_value))
            then
                if runtime:register_hook(setting_type.widget_set_value, noop,
                    function(context, new_value)
                        local _, binding = binding_for_setting_widget(runtime,
                            context)
                        handle_native_setting_value(runtime, binding, new_value,
                            kind_name .. ".widget.SetValue")
                        return nil
                    end)
                then
                    hook_state.widget = true
                end
            end

            if hook_state.setting ~= true
                and is_valid_object(runtime:find_object(
                    setting_type.setting_set_value))
            then
                if runtime:register_hook(setting_type.setting_set_value, noop,
                    function(context, new_value)
                        local setting = runtime:unwrap(context)
                        local binding = game_settings_state.bindings_by_setting[
                            object_identity(setting)]
                        handle_native_setting_value(runtime, binding, new_value,
                            kind_name .. ".setting.SetValue")
                        return nil
                    end)
                then
                    hook_state.setting = true
                end
            end

            for changed_index, changed_path in ipairs(
                setting_type.widget_changed)
            do
                if hook_state.changed[changed_index] ~= true
                    and is_valid_object(runtime:find_object(changed_path))
                then
                    if runtime:register_hook(changed_path,
                        function(context, new_value)
                            local _, binding = binding_for_setting_widget(runtime,
                                context)
                            handle_native_setting_value(runtime, binding, new_value,
                                kind_name .. ".widget.OnValueChanged")
                            return nil
                        end)
                    then
                        hook_state.changed[changed_index] = true
                    end
                end
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

    local function option_number(options, names, fallback)
        for _, name in ipairs(names) do
            local value = finite_number(options[name])
            if value ~= nil then return value end
        end
        return fallback
    end

    local function prepare_setting_entry(runtime, options, kind, api_name)
        options = type(options) == "table" and options or {}
        local id = trim(options.id)
        if id == "" then
            runtime:log(api_name .. " requires a non-empty id")
            return nil
        end
        if type(options.get) ~= "function" or type(options.set) ~= "function" then
            runtime:log("game setting '" .. id .. "' requires get and set callbacks")
            return nil
        end

        local section = trim(options.section or options.group or runtime.mod_name)
        if section == "" then section = runtime.mod_name end
        local entry = {
            kind = kind,
            id = id,
            runtime = runtime,
            section = section,
            get = options.get,
            set = options.set,
            persist = options.persist,
            translations = options.translations,
        }

        if kind == "bool" then
            entry.default = options.default == true
            return entry
        end

        if kind == "enum" then
            local values = options.values or options.options
            if type(values) ~= "table" or #values == 0 then
                runtime:log("enum game setting '" .. id
                    .. "' requires a non-empty values list")
                return nil
            end
            entry.values = values
            entry.value_translations = options.value_translations
            entry.minimum = 0
            entry.maximum = #values - 1
            local default = finite_number(options.default) or 0
            entry.default = clamp_number(math.floor(default),
                entry.minimum, entry.maximum)

            local widget = lower(options.widget or options.widget_type
                or options.style or "spinner")
            if widget == "dropdown" or widget == "1"
                or options.dropdown == true
            then
                entry.enum_widget = ENUM_WIDGET_DROPDOWN
            elseif widget == "spinner" or widget == "0" then
                entry.enum_widget = ENUM_WIDGET_SPINNER
            else
                runtime:log("enum game setting '" .. id
                    .. "' widget must be 'spinner' or 'dropdown'")
                return nil
            end
            entry.wrap_around = options.wrap_around == true
                or options.wrap == true
            return entry
        end

        local default_minimum = 0
        local default_maximum = kind == "float" and 1 or 100
        local minimum = option_number(options,
            { "minimum", "min", "min_value" }, default_minimum)
        local maximum = option_number(options,
            { "maximum", "max", "max_value" }, default_maximum)
        if kind == "int" then
            minimum = math.floor(minimum)
            maximum = math.floor(maximum)
        end
        if maximum <= minimum then
            runtime:log(kind .. " game setting '" .. id
                .. "' requires maximum greater than minimum")
            return nil
        end
        entry.minimum = minimum
        entry.maximum = maximum

        local default = finite_number(options.default) or minimum
        if kind == "int" then default = math.floor(default) end
        entry.default = clamp_number(default, minimum, maximum)

        if kind == "float" then
            local step = option_number(options, { "step", "step_size" },
                (maximum - minimum) / 100)
            if step <= 0 then
                runtime:log("float game setting '" .. id
                    .. "' requires a positive step")
                return nil
            end
            entry.step = step
            entry.always_show_sign = options.always_show_sign == true
        end
        return entry
    end

    local function register_game_setting(runtime, options, kind, api_name)
        local entry = prepare_setting_entry(runtime, options, kind, api_name)
        if entry == nil then return nil end
        local id = entry.id

        if game_settings_state.entries[id] == nil then
            table.insert(game_settings_state.order, id)
        end
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

    local function register_game_bool_setting(runtime, options)
        return register_game_setting(runtime, options, "bool",
            "register_game_bool_setting")
    end

    local function register_game_int_setting(runtime, options)
        return register_game_setting(runtime, options, "int",
            "register_game_int_setting")
    end

    local function register_game_float_setting(runtime, options)
        return register_game_setting(runtime, options, "float",
            "register_game_float_setting")
    end

    local function register_game_enum_setting(runtime, options)
        return register_game_setting(runtime, options, "enum",
            "register_game_enum_setting")
    end

    return {
        register_game_bool_setting = register_game_bool_setting,
        register_game_int_setting = register_game_int_setting,
        register_game_float_setting = register_game_float_setting,
        register_game_enum_setting = register_game_enum_setting,
    }
end
