local themeDefaults = table.clone(Theme)
local presets = {
    Dark = table.clone(Theme),
    Nord = { Window = Color3.fromRGB(36, 41, 51), Sidebar = Color3.fromRGB(41, 46, 57), Surface = Color3.fromRGB(46, 52, 64), Hover = Color3.fromRGB(59, 66, 82), Border = Color3.fromRGB(76, 86, 106), Text = Color3.fromRGB(236, 239, 244), Muted = Color3.fromRGB(170, 184, 202), Faint = Color3.fromRGB(120, 139, 160), Accent = Color3.fromRGB(136, 192, 208), OnAccent = Color3.fromRGB(36, 41, 51) },
    Dracula = { Window = Color3.fromRGB(30, 31, 41), Sidebar = Color3.fromRGB(34, 35, 46), Surface = Color3.fromRGB(40, 42, 54), Hover = Color3.fromRGB(55, 57, 73), Border = Color3.fromRGB(68, 71, 90), Text = Color3.fromRGB(248, 248, 242), Muted = Color3.fromRGB(179, 174, 201), Faint = Color3.fromRGB(116, 109, 148), Accent = Color3.fromRGB(189, 147, 249), OnAccent = Color3.fromRGB(30, 31, 41) },
    Light = { Window = Color3.fromRGB(250, 250, 252), Sidebar = Color3.fromRGB(240, 241, 246), Surface = Color3.fromRGB(255, 255, 255), Hover = Color3.fromRGB(230, 233, 241), Border = Color3.fromRGB(206, 211, 224), Text = Color3.fromRGB(28, 32, 43), Muted = Color3.fromRGB(85, 95, 116), Faint = Color3.fromRGB(130, 139, 156), Accent = Color3.fromRGB(89, 78, 213), OnAccent = Color3.fromRGB(255, 255, 255) },
}
Hub.ThemePresets = presets
function Hub:SetTheme(value)
    if type(value) == "string" then value = assert(presets[value], "Unknown theme") end
    assert(type(value) == "table", "Theme requires a preset name or color table")
    for key, color in pairs(value) do assert(Theme[key] and typeof(color) == "Color3", "Invalid theme color: " .. tostring(key)) end
    for key, color in pairs(value) do Theme[key] = color end
    layout.Refresh()
    Colors:Refresh()
    for role, editors in pairs(self.ThemeEditors or {}) do
        for _, editor in ipairs(editors) do editor:SetValue(Theme[role], true) end
    end
    return self
end
function Hub:ResetTheme() return self:SetTheme(themeDefaults) end
function Hub:SetSize(width, height)
    assert(type(width) == "number" and type(height) == "number" and width >= 280 and height >= 220, "Window size must be at least 280 x 220")
    config.Width, config.Height = width, height
    layout.Refresh()
    return self
end
function Hub:SetTitle(title, subtitle)
    windowTitle.Text = tostring(title)
    if subtitle ~= nil then windowSubtitle.Text = tostring(subtitle) end
    return self
end
function Hub:SetMenuKeybind(value) config.ToggleKeybind = Enum.KeyCode[keyName(value)] return self end
function Hub:SetFont(family)
    assert(type(family) == "string", "Font requires a family asset URL")
    local old = table.clone(Fonts)
    for key, font in pairs(old) do Fonts[key] = Font.new(family, font.Weight, font.Style) end
    config.FontFamily = family
    for _, instance in ipairs(screen:GetDescendants()) do
        if instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
            for key, font in pairs(old) do if instance.FontFace == font then instance.FontFace = Fonts[key] break end end
        end
    end
    return self
end
function Hub:SetTextScale(value)
    assert(type(value) == "number" and value >= 0.75 and value <= 1.5, "Text scale must be between 0.75 and 1.5")
    config.TextScale = value
    for _, instance in ipairs(screen:GetDescendants()) do
        if instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
            local base = instance:GetAttribute("BaseTextSize") or instance.TextSize
            instance:SetAttribute("BaseTextSize", base)
            instance.TextSize = math.round(base * value)
        end
    end
    return self
end
local notificationStack = create("Frame", { Name = "Notifications", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -16, 1, -16), Size = UDim2.new(0, math.min(300, screen.AbsoluteSize.X - 32), 1, -32), ZIndex = 150, Parent = screen }, { create("UIListLayout", { Padding = UDim.new(0, 8), VerticalAlignment = Enum.VerticalAlignment.Bottom, SortOrder = Enum.SortOrder.LayoutOrder }) })
local notices, noticeOrder = {}, 0
function Hub:Notify(options, duration)
    if type(options) ~= "table" then options = { Text = tostring(options), Duration = duration } end
    if not self.Active then return end
    noticeOrder += 1
    local panel = create("TextButton", { Name = "Notification", Text = "", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = Colors.Surface, AutoButtonColor = false, LayoutOrder = noticeOrder, ZIndex = 150, Parent = notificationStack }, { corner(8), stroke(Colors.Border), create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }), create("UIPadding", { PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }) })
    if options.Title then text({ Text = tostring(options.Title), FontFace = Fonts.Bold, Size = UDim2.new(1, 0, 0, 18), LayoutOrder = 0, ZIndex = 151, Parent = panel }) end
    local label = text({ Text = tostring(options.Text or ""), TextWrapped = true, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 1, ZIndex = 151, Parent = panel })
    local notice = { Frame = panel }
    local connection
    function notice:Close()
        if not self.Frame then return end
        if connection then connection:Disconnect() connection = nil end
        self.Frame:Destroy()
        self.Frame = nil
        local index = table.find(notices, self)
        if index then table.remove(notices, index) end
    end
    function notice:SetText(value) if self.Frame then label.Text = tostring(value) end return self end
    connection = panel.Activated:Connect(function() notice:Close() end)
    table.insert(notices, notice)
    while #notices > 5 do notices[1]:Close() end
    local seconds = options.Duration == nil and 4 or options.Duration
    if seconds > 0 then task.delay(seconds, function() notice:Close() end) end
    return notice
end
function Hub:AddThemeSection(tab)
    local group = tab:AddGroupbox("Appearance")
    self.SectionCounter = (self.SectionCounter or 0) + 1
    local prefix = "__Theme_" .. self.SectionCounter
    group:AddDropdown(prefix .. "Preset", { Text = "Theme", Values = { "Dark", "Nord", "Dracula", "Light" }, Default = config.ThemePreset or "Dark", IgnoreConfig = true, Callback = function(value) self:SetTheme(value) end })
    self.ThemeEditors = self.ThemeEditors or {}
    for _, role in ipairs({ "Accent", "Window", "Sidebar", "Surface", "Hover", "Border", "Text", "Muted", "Faint", "OnAccent" }) do
        local picker = group:AddColorPicker(prefix .. role, { Text = role, Default = Theme[role], IgnoreConfig = true, Callback = function(value) self:SetTheme({ [role] = value }) end })
        self.ThemeEditors[role] = self.ThemeEditors[role] or {}
        table.insert(self.ThemeEditors[role], picker)
    end
    group:AddDropdown(prefix .. "Font", { Text = "Font", Values = { "BuilderSans", "GothamSSm", "RobotoMono" }, Default = "BuilderSans", IgnoreConfig = true, Callback = function(value) self:SetFont("rbxasset://fonts/families/" .. value .. ".json") end })
    group:AddSlider(prefix .. "TextScale", { Text = "Text size", Min = 0.75, Max = 1.5, Default = config.TextScale or 1, Rounding = 2, IgnoreConfig = true, Callback = function(value) self:SetTextScale(value) end })
    group:AddSlider(prefix .. "Width", { Text = "Window width", Min = 360, Max = 1000, Default = config.Width or 560, IgnoreConfig = true, Callback = function(value) self:SetSize(value, config.Height or 400) end })
    group:AddSlider(prefix .. "Height", { Text = "Window height", Min = 260, Max = 800, Default = config.Height or 400, IgnoreConfig = true, Callback = function(value) self:SetSize(config.Width or 560, value) end })
    group:AddKeybind(prefix .. "MenuKey", { Text = "Menu key", Default = config.ToggleKeybind or Enum.KeyCode.RightShift, IgnoreConfig = true }):OnChanged(function(value) if value ~= "None" and not value:match("^MouseButton") then self:SetMenuKeybind(value) end end)
    group:AddButton({ Text = "Reset colors", Callback = function() self:ResetTheme() end })
    return group
end
local RunService = game:GetService("RunService")
local cursorName = "ShrakUI_Cursor_" .. HttpService:GenerateGUID(false)
local cursorModal = create("TextButton", { Name = "CursorUnlock", Size = UDim2.fromOffset(1, 1), BackgroundTransparency = 1, Text = "", Modal = true, Selectable = false, Visible = false, Parent = screen })
local cursorState = environment.ShrakScriptsUICursor or { Owners = {} }
environment.ShrakScriptsUICursor = cursorState
local function releaseCursor()
    cursorState.Owners[Hub] = nil
    cursorModal.Visible = false
    if not next(cursorState.Owners) and cursorState.Snapshot then
        local saved = cursorState.Snapshot
        cursorState.Snapshot = nil
        UserInputService.MouseBehavior, UserInputService.MouseIconEnabled = saved.Behavior, saved.IconEnabled
    end
end
local function updateExtras()
    local opened = Hub.Active and Hub.Loaded and screen.Enabled and menu.IsOpen()
    if tooltip.Visible then
        if not opened or not tooltipOwner or not visible(tooltipOwner) then tooltip.Visible = false
        else
            local point = UserInputService:GetMouseLocation()
            local bounds = screen.AbsoluteSize
            tooltip.Position = UDim2.fromOffset(math.clamp(point.X + 12, 0, math.max(0, bounds.X - tooltip.AbsoluteSize.X)), math.clamp(point.Y + 18, 0, math.max(0, bounds.Y - tooltip.AbsoluteSize.Y)))
        end
    end
    if not opened and Hub.BindingControl then Hub.BindingControl:SetValue(Hub.BindingControl.Value, true) end
    if config.UnlockMouse ~= false and opened then
        if not cursorState.Snapshot then cursorState.Snapshot = { Behavior = UserInputService.MouseBehavior, IconEnabled = UserInputService.MouseIconEnabled } end
        cursorState.Owners[Hub] = true
        cursorModal.Visible = true
        UserInputService.MouseBehavior, UserInputService.MouseIconEnabled = Enum.MouseBehavior.Default, true
    else releaseCursor() end
end
RunService:BindToRenderStep(cursorName, Enum.RenderPriority.Last.Value + 100, updateExtras)
Hub:OnUnload(function()
    Colors:Cancel()
    RunService:UnbindFromRenderStep(cursorName)
    releaseCursor()
    for _, control in pairs(Hub.Options) do if control.Type == "Keybind" then control:SetActive(false) end end
    while #notices > 0 do notices[1]:Close() end
end)
track(screen:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() notificationStack.Size = UDim2.new(0, math.max(1, math.min(300, screen.AbsoluteSize.X - 32)), 1, -32) end))
if config.ThemePreset then Hub:SetTheme(config.ThemePreset) end
if config.Theme then Hub:SetTheme(config.Theme) end
themeDefaults = table.clone(Theme)
if config.FontFamily then Hub:SetFont(config.FontFamily) end
if config.TextScale then Hub:SetTextScale(config.TextScale) end
