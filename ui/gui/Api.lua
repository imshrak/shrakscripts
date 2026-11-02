local function register(id, kind, value, callback)
    assert(type(id) == "string" and id ~= "" and not Hub.Controls[id], "Control ID must be unique: " .. tostring(id))
    local control = { Id = id, Type = kind, Value = value, Callback = callback, Changed = {} }
    function control:OnChanged(callback)
        assert(type(callback) == "function", "OnChanged expects a function")
        table.insert(self.Changed, callback)
        return self
    end
    function control:GetValue() return self.Value end
    Hub.Controls[id] = control
    if kind == "Toggle" then Hub.Toggles[id] = control else Hub.Options[id] = control end
    return control
end

local function fire(control)
    for _, refresh in ipairs(control.Dependents or {}) do refresh() end
    Library:_Call(control.Callback, control.Value, control)
    for _, callback in ipairs(control.Changed) do Library:_Call(callback, control.Value, control) end
end

local function normalize(values)
    if type(values) == "function" then values = values() end
    local result = {}
    for _, item in ipairs(values or {}) do
        if type(item) == "table" then
            local value = item.Value
            if value == nil then value = item.Name end
            table.insert(result, { Name = tostring(item.Name or value), Value = value, Color = item.Color })
        else
            table.insert(result, { Name = tostring(item), Value = item })
        end
    end
    return result
end

local function copySelection(target, value)
    table.clear(target)
    for key, enabled in pairs(value or {}) do
        if type(key) == "number" then target[enabled] = true
        elseif enabled then target[key] = true end
    end
end

local Tab = {}
function Tab:AddSection(title)
    addSection(self, title)
    return self
end
function Tab:AddToggle(id, options)
    options = options or {}
    local control = register(id, "Toggle", false, options.Callback)
    local silent = true
    local _, set, frame = addToggle(self, options.Text or id, function(value)
        local changed = control.Value ~= value
        control.Value = value
        if changed and not silent then fire(control) end
    end)
    control.Frame = frame
    frame.Name = "Toggle_" .. id
    function control:SetValue(value, quiet)
        silent = quiet == true
        set(value == true)
        silent = false
        return self
    end
    control:SetValue(options.Default == true, true)
    if options.FireOnInit then fire(control) end
    return control
end
function Tab:AddSlider(id, options)
    options = options or {}
    local min, max = options.Min or 0, options.Max or 100
    assert(type(min) == "number" and type(max) == "number" and max > min, "Slider Max must exceed Min")
    local control = register(id, "Slider", math.clamp(options.Default or min, min, max), options.Callback)
    local frame, set = addSlider(self, options.Text or id, min, max, control.Value, function(value)
        if control.Value ~= value then control.Value = value fire(control) end
    end, options.Rounding or 0)
    control.Frame = frame
    frame.Name = "Slider_" .. id
    function control:SetValue(value, quiet)
        assert(type(value) == "number", "Slider value must be numeric")
        local result = set(value)
        if self.Value ~= result then self.Value = result if not quiet then fire(self) end end
        return self
    end
    control:SetValue(control.Value, true)
    if options.FireOnInit then fire(control) end
    return control
end
function Tab:AddDropdown(id, options)
    options = options or {}
    local control
    if options.Multi then
        control = register(id, "MultiDropdown", {}, options.Callback)
        local values = normalize(options.Values)
        local allowed = {}
        for _, item in ipairs(values) do
            assert(type(item.Value) == "string" and item.Name == item.Value, "Multi dropdown values must be strings")
            allowed[item.Value] = true
        end
        copySelection(control.Value, options.Default)
        local frame, refresh = addMultiSelect(self, options.Text or id, values, control.Value, options.Placeholder or "None", function() fire(control) end)
        control.Frame = frame
        function control:SetValue(value, quiet)
            local selected = {}
            copySelection(selected, value)
            for key in pairs(selected) do assert(allowed[key], "Unknown dropdown value: " .. tostring(key)) end
            local changed = false
            for key in pairs(self.Value) do if not selected[key] then changed = true end end
            for key in pairs(selected) do if not self.Value[key] then changed = true end end
            copySelection(self.Value, selected)
            refresh()
            if changed and not quiet then fire(self) end
            return self
        end
        function control:Refresh() refresh() return self end
    else
        local values = normalize(options.Values)
        local value = options.Default
        if value == nil and values[1] then value = values[1].Value end
        control = register(id, "Dropdown", value, options.Callback)
        local frame, refresh = addSingleSelect(self, options.Text or id, function() return normalize(options.Values) end, function() return control.Value end, function(value)
            if control.Value ~= value then control.Value = value fire(control) end
        end)
        control.Frame = frame
        function control:SetValue(value, quiet)
            local valid = false
            local choices = normalize(options.Values)
            if value == nil and (#choices == 0 or options.AllowNull) then valid = true end
            for _, item in ipairs(choices) do if item.Value == value then valid = true break end end
            assert(valid, "Unknown dropdown value: " .. tostring(value))
            local changed = self.Value ~= value
            self.Value = value
            refresh()
            if changed and not quiet then fire(self) end
            return self
        end
        function control:Refresh() refresh() return self end
        function control:SetValues(values)
            options.Values = values
            local choices, found = normalize(values), false
            for _, item in ipairs(choices) do if item.Value == self.Value then found = true break end end
            if not found then self:SetValue(choices[1] and choices[1].Value or nil) else refresh() end
            return self
        end
    end
    control.Frame.Name = "Dropdown_" .. id
    if options.FireOnInit then fire(control) end
    return control
end
function Tab:AddButton(options, callback)
    if type(options) == "string" then options = { Text = options, Callback = callback } end
    assert(type(options) == "table" and type(options.Callback) == "function", "Button requires a callback")
    local button = {}
    function button:Press() if not self.Disabled then Library:_Call(options.Callback, self) end return self end
    button.Frame = addButton(self, options.Text or "Button", options.Description, function() button:Press() end)
    function button:SetText(value) self.Frame:FindFirstChildWhichIsA("TextLabel").Text = tostring(value) return self end
    return button
end
function Tab:AddLabel(value)
    local frame = card(self, 42)
    local label = text({ Text = tostring(value), Position = UDim2.fromOffset(14, 0), Size = UDim2.new(1, -28, 1, 0), Parent = frame })
    local control = { Frame = frame }
    function control:SetText(value) label.Text = tostring(value) return self end
    return control
end

local aliases = { zap = "farm", ["paw-print"] = "pets", gift = "rewards", settings = "settings", user = "user" }
function Hub:AddTab(title, glyph)
    if type(title) == "table" then glyph, title = title.Icon, title.Title end
    assert(type(title) == "string" and not self.Tabs[title], "Tab title must be unique")
    local tab = addTab(title, aliases[glyph] or glyph or "farm")
    tab.Window = self
    setmetatable(tab, { __index = Tab })
    self.Tabs[title] = tab
    return tab
end
function Hub:SelectTab(target)
    if type(target) == "string" then target = self.Tabs[target] end
    assert(target and target.Window == self, "Unknown tab")
    selectTab(target)
    return self
end
function Hub:ShowDiscordPrompt(invite)
    if invite then DISCORD_CODE = tostring(invite):gsub("^https?://discord%.gg/", ""):gsub("^discord%.gg/", "") INVITE_URL = "https://discord.gg/" .. DISCORD_CODE end
    assert(DISCORD_CODE ~= "", "Set DiscordInvite before showing the invite prompt")
    showDiscordPopup()
    return self
end
function Hub:OnUnload(callback)
    assert(type(callback) == "function", "OnUnload expects a function")
    table.insert(self.UnloadCallbacks, callback)
    return self
end
function Hub:StopAll()
    for _, control in pairs(self.Toggles) do control:SetValue(false) end
    for _, control in pairs(self.Options) do if control.Type == "Keybind" then control:SetActive(false) end end
    return self
end
function Hub:Unload()
    if not self.Active then return end
    self.Active = false
    for _, callback in ipairs(self.UnloadCallbacks) do Library:_Call(callback, self) end
    for _, reset in ipairs(resetters) do pcall(reset) end
    for _, connection in ipairs(connections) do connection:Disconnect() end
    if popup then popup.Blur:Destroy() popup = nil end
    screen:Destroy()
    if Library.Windows[id] == self then Library.Windows[id] = nil end
end
Hub.Screen, Hub.Frame, Hub.Theme = screen, window, Theme
