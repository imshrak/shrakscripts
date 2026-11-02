local HttpService = game:GetService("HttpService")
local function encodeValue(value)
    local kind = typeof(value)
    if kind == "Color3" then return { Kind = "Color3", Hex = value:ToHex() } end
    if kind == "EnumItem" then return { Kind = "Enum", Enum = tostring(value.EnumType), Name = value.Name } end
    if type(value) == "table" then
        local result = {}
        for key, item in pairs(value) do result[key] = encodeValue(item) end
        return result
    end
    assert(value == nil or kind == "string" or kind == "boolean" or kind == "number", "Unsupported config value: " .. kind)
    return value
end
local function decodeValue(value)
    if type(value) ~= "table" then return value end
    if value.Kind == "Color3" then return Color3.fromHex(value.Hex) end
    if value.Kind == "Enum" then return Enum[value.Enum:gsub("^Enum%.", "")][value.Name] end
    local result = {}
    for key, item in pairs(value) do result[key] = decodeValue(item) end
    return result
end
function Hub:GetConfig(options)
    options = options or {}
    local result = { Version = 1, Controls = {} }
    for key, control in pairs(self.Controls) do
        if not control.IgnoreConfig and not (options.Ignore and options.Ignore[key]) then
            result.Controls[key] = { Type = control.Type, Value = encodeValue(control.Value) }
            if control.Type == "Keybind" then result.Controls[key].Mode = control.Mode end
            if control.Type == "ColorPicker" then result.Controls[key].Transparency = control.Transparency end
        end
    end
    if options.IncludeTheme ~= false then
        result.Theme = encodeValue(Theme)
        result.Window = { Width = config.Width or 560, Height = config.Height or 400, TextScale = config.TextScale or 1, FontFamily = config.FontFamily or "rbxasset://fonts/families/BuilderSans.json", MenuKeybind = (config.ToggleKeybind or Enum.KeyCode.RightShift).Name }
    end
    return result
end
function Hub:ExportConfig(options) return HttpService:JSONEncode(self:GetConfig(options)) end
function Hub:ImportConfig(data, options)
    options = options or {}
    local ok, message = pcall(function()
        if type(data) == "string" then data = HttpService:JSONDecode(data) end
        assert(type(data) == "table" and data.Version == 1 and type(data.Controls) == "table", "Unsupported configuration")
        local changes, previous = {}, {}
        for key, entry in pairs(data.Controls) do
            local control = self.Controls[key]
            if control and not control.IgnoreConfig and not (options.Ignore and options.Ignore[key]) then
                assert(type(entry) == "table" and entry.Type == control.Type, "Control type mismatch: " .. key)
                local value = decodeValue(entry.Value)
                if control.Type == "Toggle" then assert(type(value) == "boolean", "Invalid toggle: " .. key) end
                if control.Type == "Slider" then assert(type(value) == "number" and value == value and math.abs(value) < math.huge, "Invalid slider: " .. key) end
                if control.Type == "Input" then assert(type(value) == "string", "Invalid input: " .. key) end
                if control.Type == "Keybind" then keyName(value) end
                if control.Type == "MultiDropdown" then assert(type(value) == "table", "Invalid selection: " .. key) end
                changes[key] = { Value = value, Mode = entry.Mode, Transparency = entry.Transparency }
                previous[key] = { Value = decodeValue(encodeValue(control.Value)), Mode = control.Mode, Transparency = control.Transparency, Active = control.Active }
            end
        end
        local oldTheme = table.clone(Theme)
        local oldWindow = self:GetConfig().Window
        local newTheme = data.Theme and decodeValue(data.Theme)
        local function applyWindow(value)
            if not value then return end
            assert(type(value) == "table", "Invalid window settings")
            self:SetSize(value.Width, value.Height)
            self:SetTextScale(value.TextScale)
            self:SetFont(value.FontFamily)
            self:SetMenuKeybind(value.MenuKeybind)
        end
        local function apply(control, value)
            if control.Type == "Keybind" then control:SetMode(value.Mode or control.Mode, true) end
            if control.Type == "ColorPicker" then
                assert(value.Transparency == nil or type(value.Transparency) == "number", "Invalid transparency")
                control:SetValue(value.Value, true, value.Transparency)
            else
                local accepted, reason = control:SetValue(value.Value, true)
                assert(accepted, reason)
            end
        end
        local valid, reason = pcall(function()
            if newTheme and options.IncludeTheme ~= false then self:SetTheme(newTheme) end
            if options.IncludeTheme ~= false then applyWindow(data.Window) end
            for key, value in pairs(changes) do apply(self.Controls[key], value) end
        end)
        if not valid then
            for key, value in pairs(previous) do
                pcall(apply, self.Controls[key], value)
                if self.Controls[key].Type == "Keybind" then self.Controls[key]:SetActive(value.Active, true) end
            end
            self:SetTheme(oldTheme)
            applyWindow(oldWindow)
            error(reason, 0)
        end
        if not options.Quiet then
            local ordered = {}
            for key in pairs(changes) do table.insert(ordered, key) end
            table.sort(ordered, function(a, b)
                local at, bt = self.Controls[a].Type == "Toggle", self.Controls[b].Type == "Toggle"
                if at ~= bt then return not at end
                return a < b
            end)
            for _, key in ipairs(ordered) do
                local control = self.Controls[key]
                if control.Type == "Keybind" then
                    fire(control)
                    control:SetActive(previous[key].Active, true)
                    control:SetActive(control.Mode == "Always")
                else fire(control) end
            end
        end
    end)
    return ok, ok and nil or tostring(message)
end
local function profilePath(name)
    assert(type(name) == "string" and name:match("^[%w_%- ]+$") and #name <= 64, "Use a profile name with letters, numbers, spaces, _ or -")
    local folder = config.ConfigFolder or "ShrakScripts/Profiles/" .. id:gsub("[^%w_%-]", "_")
    assert(not folder:find("..", 1, true) and not folder:find(":", 1, true) and not folder:match("^[/\\]"), "ConfigFolder must be a relative folder")
    folder = folder:gsub("\\", "/"):gsub("/+$", "")
    return folder .. "/" .. name .. ".json", folder
end
function Hub:SaveConfig(name, options)
    local ok, message = pcall(function()
        assert(type(writefile) == "function" and type(makefolder) == "function" and type(isfolder) == "function", "File saving is unavailable; use ExportConfig")
        local path, folder = profilePath(name)
        local current = ""
        for segment in folder:gmatch("[^/]+") do
            current = current == "" and segment or current .. "/" .. segment
            if not isfolder(current) then makefolder(current) end
        end
        writefile(path, self:ExportConfig(options))
    end)
    return ok, ok and nil or tostring(message)
end
function Hub:LoadConfig(name, options)
    local ok, data = pcall(function()
        assert(type(readfile) == "function", "File loading is unavailable; use ImportConfig")
        local path = profilePath(name)
        return readfile(path)
    end)
    if not ok then return false, tostring(data) end
    return self:ImportConfig(data, options)
end
function Hub:ListConfigs()
    if type(listfiles) ~= "function" or type(isfolder) ~= "function" then return {} end
    local _, folder = profilePath("Default")
    if not isfolder(folder) then return {} end
    local result = {}
    for _, path in ipairs(listfiles(folder)) do
        local name = path:gsub("\\", "/"):match("/([^/]+)%.json$")
        if name then table.insert(result, name) end
    end
    table.sort(result)
    return result
end
function Hub:DeleteConfig(name)
    local ok, message = pcall(function()
        assert(type(delfile) == "function", "File deletion is unavailable")
        local path = profilePath(name)
        delfile(path)
    end)
    return ok, ok and nil or tostring(message)
end
function Hub:AddConfigSection(tab)
    local group = tab:AddGroupbox("Profiles")
    self.SectionCounter = (self.SectionCounter or 0) + 1
    local prefix = "__Profiles_" .. self.SectionCounter
    local name = group:AddInput(prefix .. "Name", { Text = "Profile name", Default = "Default", IgnoreConfig = true })
    local chosen = group:AddDropdown(prefix .. "Saved", { Text = "Saved profiles", Values = function() return self:ListConfigs() end, IgnoreConfig = true })
    local function report(ok, message) self:Notify({ Title = "Profiles", Text = ok and "Done" or message, Duration = 4 }) chosen:Refresh() end
    group:AddButton({ Text = "Save profile", Callback = function() report(self:SaveConfig(name.Value)) end })
    group:AddButton({ Text = "Load profile", Callback = function() report(self:LoadConfig(chosen.Value or name.Value)) end })
    group:AddButton({ Text = "Delete selected profile", Callback = function() report(self:DeleteConfig(chosen.Value or name.Value)) end })
    group:AddButton({ Text = "Refresh profiles", Callback = function() chosen:Refresh() end })
    return group
end
