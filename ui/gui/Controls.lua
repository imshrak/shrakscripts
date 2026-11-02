local tooltip = text({ Name = "Tooltip", Size = UDim2.fromOffset(260, 0), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true, TextSize = 13, Visible = false, ZIndex = 200, Parent = screen })
tooltip.BackgroundTransparency = 0
Colors:Set(tooltip, "BackgroundColor3", Colors.Surface)
create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = tooltip })
create("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), Parent = tooltip })
local tooltipOwner
local function visible(frame)
    local current = frame
    while current and current ~= screen do
        if current:IsA("GuiObject") and not current.Visible then return false end
        current = current.Parent
    end
    return current == screen and screen.Enabled and Hub.Active
end
local function enabled(frame)
    while frame and frame ~= screen do
        if frame:GetAttribute("ControlEnabled") == false then return false end
        frame = frame.Parent
    end
    return Hub.Active
end
local function decorate(control, options)
    options = options or {}
    control.Visible, control.Disabled = options.Visible ~= false, options.Disabled == true
    control.IgnoreConfig = options.IgnoreConfig == true
    control.Settings = options
    control.Tooltip = options.Tooltip
    local shield
    function control:SetVisible(value)
        self.Visible = value == true
        self.Frame.Visible = self.Visible and self.DependencyVisible ~= false
        self.Frame:SetAttribute("ControlEnabled", self.Frame.Visible and not self.Disabled)
        if not self.Frame.Visible and tooltipOwner == self.Frame then tooltip.Visible = false end
        return self
    end
    function control:SetDisabled(value)
        self.Disabled = value == true
        if not shield then
            shield = create("TextButton", { Name = "DisabledOverlay", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(), BackgroundTransparency = 0.6, Text = "", AutoButtonColor = false, ZIndex = 100, Parent = self.Frame }, { corner(8) })
        end
        shield.Visible = self.Disabled
        self.Frame:SetAttribute("ControlEnabled", self.Visible and self.DependencyVisible ~= false and not self.Disabled)
        if self.Disabled then
            for _, option in pairs(Hub.Options) do
                if option.Type == "Keybind" and (option == self or option.Frame:IsDescendantOf(self.Frame)) then option:SetActive(false) end
            end
        end
        return self
    end
    function control:SetTooltip(value) self.Tooltip = value return self end
    function control:SetDependency(source, expected)
        return self:SetupDependencies({ { source, expected } })
    end
    function control:SetupDependencies(dependencies)
        self.DependencyVersion = (self.DependencyVersion or 0) + 1
        local version = self.DependencyVersion
        local function refresh()
            if self.DependencyVersion ~= version or not Hub.Active then return end
            local allowed = true
            for _, dependency in ipairs(dependencies) do
                local source, expected = dependency[1], dependency[2]
                if type(expected) == "function" then
                    local ok, result = pcall(expected, source.Value, source)
                    if not ok or result ~= true then allowed = false end
                elseif source.Value ~= (expected == nil and true or expected) then allowed = false end
            end
            self.DependencyVisible = allowed
            self:SetVisible(self.Visible)
        end
        for _, dependency in ipairs(dependencies) do
            local source = dependency[1]
            assert(source and type(source.OnChanged) == "function", "Dependency requires a control")
            source.Dependents = source.Dependents or {}
            table.insert(source.Dependents, refresh)
        end
        refresh()
        return self
    end
    track(control.Frame.MouseEnter:Connect(function()
        if control.Tooltip and visible(control.Frame) then
            tooltipOwner = control.Frame
            tooltip.Text, tooltip.Visible = tostring(control.Tooltip), true
        end
    end))
    track(control.Frame.MouseLeave:Connect(function()
        if tooltipOwner == control.Frame then tooltip.Visible = false end
    end))
    control:SetVisible(control.Visible)
    if control.SetValue then
        local setValue = control.SetValue
        control.SetValue = function(self, ...)
            local result, reason = setValue(self, ...)
            for _, refresh in ipairs(self.Dependents or {}) do refresh() end
            return result, reason
        end
    end
    if control.Disabled then control:SetDisabled(true) end
    if options.Dependency then control:SetDependency(options.Dependency, options.DependencyValue) end
    return control
end
for _, method in ipairs({ "AddToggle", "AddSlider", "AddDropdown", "AddButton", "AddLabel" }) do
    local original = Tab[method]
    Tab[method] = function(self, id, options)
        local settings = method == "AddButton" and id or options
        local control = original(self, id, options)
        return decorate(control, type(settings) == "table" and settings or {})
    end
end

local function field(parent, properties)
    properties.BackgroundColor3 = properties.BackgroundColor3 or Colors.Hover
    properties.TextColor3 = properties.TextColor3 or Colors.Text
    properties.PlaceholderColor3 = Colors.Faint
    properties.FontFace = Fonts.Regular
    properties.TextSize = 14
    properties.ClearTextOnFocus = false
    properties.Parent = parent
    return create("TextBox", properties, { corner(5), stroke(Colors.Border) })
end
function Tab:AddInput(id, options)
    options = options or {}
    local control = register(id, "Input", "", options.Callback)
    control.Frame = card(self, TOUCH and 88 or 78)
    control.Frame.Name = "Input_" .. id
    cardLabels(control.Frame, options.Text or id).Size = UDim2.new(1, -28, 0, 16)
    local box = field(control.Frame, { Name = "Input", Text = "", PlaceholderText = options.Placeholder or "Enter text", Size = UDim2.new(1, -28, 0, TOUCH and 36 or 28), Position = UDim2.fromOffset(14, 36), TextXAlignment = Enum.TextXAlignment.Left })
    create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), Parent = box })
    control.TextBox = box
    function control:SetValue(value, quiet)
        value = tostring(value == nil and "" or value)
        if options.MaxLength then value = value:sub(1, options.MaxLength) end
        if options.Numeric and not tonumber(value) then return false, "Enter a number" end
        if options.Validate then
            local ok, accepted = pcall(options.Validate, value)
            if not ok or not accepted then return false, "Invalid input" end
        end
        local changed = self.Value ~= value
        self.Value = value
        if box.Text ~= value then box.Text = value end
        if changed and not quiet then fire(self) end
        return self
    end
    track(box:GetPropertyChangedSignal("Text"):Connect(function()
        if options.Finished ~= false or not box:IsFocused() then return end
        control:SetValue(box.Text)
    end))
    track(box.FocusLost:Connect(function()
        if not control.Disabled then control:SetValue(box.Text) end
        box.Text = control.Value
    end))
    assert(control:SetValue(options.Default or (options.Numeric and "0" or ""), true), "Invalid input default")
    decorate(control, options)
    if options.FireOnInit then fire(control) end
    return control
end

local function keyName(value)
    if typeof(value) == "EnumItem" then value = value.Name end
    value = tostring(value or "None")
    assert(value == "None" or Enum.KeyCode[value] or value:match("^MouseButton[123]$"), "Invalid keybind: " .. value)
    return value
end
function Tab:AddKeybind(id, options)
    options = options or {}
    local control = register(id, "Keybind", "None", nil)
    control.Mode, control.Active, control.Triggered = options.Mode or "Toggle", false, {}
    control.Frame = card(self, TOUCH and 88 or 78)
    control.Frame.Name = "Keybind_" .. id
    cardLabels(control.Frame, options.Text or id).Size = UDim2.new(1, -28, 0, 16)
    local button = create("TextButton", { Name = "Bind", Text = "None", Size = UDim2.new(0.6, -18, 0, TOUCH and 36 or 28), Position = UDim2.fromOffset(14, 36), BackgroundColor3 = Colors.Hover, TextColor3 = Colors.Text, FontFace = Fonts.Medium, TextSize = 14, AutoButtonColor = false, Parent = control.Frame }, { corner(5), stroke(Colors.Border) })
    local modeButton = create("TextButton", { Name = "Mode", Text = control.Mode, Size = UDim2.new(0.4, -18, 0, TOUCH and 36 or 28), Position = UDim2.new(0.6, 4, 0, 36), BackgroundColor3 = Colors.Hover, TextColor3 = Colors.Muted, FontFace = Fonts.Regular, TextSize = 13, AutoButtonColor = false, Parent = control.Frame }, { corner(5) })
    function control:SetActive(value, quiet)
        value = value == true
        local changed = self.Active ~= value
        self.Active = value
        if changed and not quiet then
            Library:_Call(options.Callback, value, self)
            for _, callback in ipairs(self.Triggered) do Library:_Call(callback, value, self) end
        end
        return self
    end
    function control:OnClick(callback) table.insert(self.Triggered, callback) return self end
    function control:GetState() return self.Active end
    function control:SetMode(mode, quiet)
        assert(mode == "Toggle" or mode == "Hold" or mode == "Always", "Invalid keybind mode")
        self.Mode, modeButton.Text = mode, mode
        self:SetActive(mode == "Always", quiet)
        return self
    end
    function control:SetValue(value, quiet)
        value = keyName(value)
        local changed = self.Value ~= value
        self.Value, button.Text = value, value
        self:SetActive(self.Mode == "Always", quiet)
        if Hub.BindingControl == self then Hub.BindingControl = nil end
        if changed and not quiet then fire(self) end
        return self
    end
    track(button.Activated:Connect(function()
        if control.Disabled then return end
        if Hub.BindingControl then Hub.BindingControl:SetValue(Hub.BindingControl.Value, true) end
        Hub.BindingControl = control
        button.Text = "Press a key..."
    end))
    track(modeButton.Activated:Connect(function()
        local modes = { Toggle = "Hold", Hold = "Always", Always = "Toggle" }
        if not control.Disabled then control:SetMode(modes[control.Mode]) end
    end))
    track(UserInputService.InputBegan:Connect(function(input, processed)
        if not Hub.Active then return end
        if Hub.BindingControl == control then
            Hub.LastCapturedInput = input
            if input.KeyCode == Enum.KeyCode.Escape then control:SetValue(control.Value, true)
            elseif input.KeyCode == Enum.KeyCode.Backspace or input.KeyCode == Enum.KeyCode.Delete then control:SetValue("None")
            elseif input.KeyCode ~= Enum.KeyCode.Unknown then control:SetValue(input.KeyCode)
            elseif input.UserInputType.Name:match("^MouseButton[123]$") then control:SetValue(input.UserInputType.Name) end
            return
        end
        if Hub.BindingControl or Hub.LastCapturedInput == input or processed or not enabled(control.Frame) or UserInputService:GetFocusedTextBox() then return end
        local name = input.KeyCode == Enum.KeyCode.Unknown and input.UserInputType.Name or input.KeyCode.Name
        if name == control.Value then
            if control.Mode == "Hold" then control:SetActive(true)
            elseif control.Mode == "Toggle" then control:SetActive(not control.Active) end
        end
    end))
    track(UserInputService.InputEnded:Connect(function(input)
        local name = input.KeyCode == Enum.KeyCode.Unknown and input.UserInputType.Name or input.KeyCode.Name
        if name == control.Value and control.Mode == "Hold" then control:SetActive(false) end
    end))
    track(UserInputService.WindowFocusReleased:Connect(function()
        if Hub.BindingControl == control then control:SetValue(control.Value, true) end
        if control.Mode == "Hold" then control:SetActive(false) end
    end))
    control:SetValue(options.Default or "None", true)
    control:SetMode(control.Mode, true)
    decorate(control, options)
    if options.FireOnInit then Library:_Call(options.Callback, control.Active, control) end
    return control
end
Tab.AddKeyPicker = Tab.AddKeybind

function Tab:AddColorPicker(id, options)
    options = options or {}
    local control = register(id, "ColorPicker", Color3.new(1, 1, 1), options.Callback)
    control.Transparency = math.clamp(options.Transparency or 0, 0, 1)
    local head, expanded = TOUCH and 52 or 42, false
    control.Frame = card(self, head)
    control.Frame.Name, control.Frame.ClipsDescendants = "ColorPicker_" .. id, true
    cardLabels(control.Frame, options.Text or options.Title or id)
    local swatch = create("TextButton", { Name = "Swatch", Text = "", Size = UDim2.fromOffset(40, 22), Position = UDim2.new(1, -54, 0, (head - 22) / 2), AutoButtonColor = false, Parent = control.Frame }, { corner(5), stroke(Colors.Border) })
    local body = create("Frame", { Size = UDim2.new(1, -28, 0, 236), Position = UDim2.fromOffset(14, head + 4), BackgroundTransparency = 1, Parent = control.Frame })
    local square = create("TextButton", { Name = "SaturationValue", Size = UDim2.new(1, -32, 0, 112), BackgroundColor3 = Color3.new(1, 0, 0), Text = "", AutoButtonColor = false, Parent = body }, { corner(4) })
    local white = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Active = false, Parent = square }, { corner(4), create("UIGradient", { Transparency = NumberSequence.new(0, 1) }) })
    create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(), BorderSizePixel = 0, Parent = white }, { corner(4), create("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0) }) })
    local marker = create("Frame", { Size = UDim2.fromOffset(8, 8), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, ZIndex = 3, Parent = square }, { round(), stroke(Color3.new(1, 1, 1), 2) })
    local hue = create("TextButton", { Name = "Hue", Size = UDim2.fromOffset(20, 112), Position = UDim2.new(1, -20, 0, 0), BackgroundColor3 = Color3.new(1, 1, 1), AutoButtonColor = false, Text = "", Parent = body }, { corner(4) })
    local stops = {}
    for index = 0, 6 do table.insert(stops, ColorSequenceKeypoint.new(index / 6, Color3.fromHSV(index / 6, 1, 1))) end
    create("UIGradient", { Rotation = 90, Color = ColorSequence.new(stops), Parent = hue })
    local hex = field(body, { Name = "Hex", Size = UDim2.new(1, 0, 0, 30), Position = UDim2.fromOffset(0, 122), Text = "#FFFFFF", PlaceholderText = "#RRGGBB" })
    local internal = { Page = body, ScrollPage = self.ScrollPage or self.Page, Order = 0 }
    local alphaFrame, setAlpha = addSlider(internal, "Transparency", 0, 1, control.Transparency, function(value) control:SetValue(control.Value, false, value) end, 2)
    alphaFrame.Position, alphaFrame.Size = UDim2.fromOffset(0, 158), UDim2.new(1, 0, 0, 64)
    local h, s, v = 0, 0, 1
    function control:SetValue(value, quiet, transparency)
        if type(value) == "table" then value = Color3.fromHSV(value.H or value[1], value.S or value[2], value.V or value[3]) end
        assert(typeof(value) == "Color3", "Color picker requires Color3 or HSV")
        transparency = math.clamp(transparency == nil and self.Transparency or transparency, 0, 1)
        local changed = self.Value ~= value or self.Transparency ~= transparency
        self.Value, self.Transparency = value, transparency
        h, s, v = value:ToHSV()
        swatch.BackgroundColor3, swatch.BackgroundTransparency = value, transparency
        square.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        marker.Position = UDim2.fromScale(s, 1 - v)
        hex.Text = "#" .. value:ToHex():upper()
        setAlpha(transparency)
        if changed and not quiet then fire(self) end
        return self
    end
    function control:SetValueRGB(value, transparency, quiet) return self:SetValue(value, quiet, transparency) end
    function control:SetTransparency(value, quiet) return self:SetValue(self.Value, quiet, value) end
    local function setOpen(value)
        expanded = value
        control.Frame.Size = UDim2.new(1, 0, 0, expanded and head + 240 or head)
    end
    track(swatch.Activated:Connect(function() if not control.Disabled then setOpen(not expanded) end end))
    track(hex.FocusLost:Connect(function()
        local value = hex.Text:gsub("#", "")
        if value:match("^%x%x%x%x%x%x$") then control:SetValue(Color3.fromHex(value)) else hex.Text = "#" .. control.Value:ToHex():upper() end
    end))
    local dragInput, dragKind, scrolling
    local scrollPage = self.ScrollPage or self.Page
    local function update(input)
        if dragKind == "Hue" then
            h = math.clamp((input.Position.Y - hue.AbsolutePosition.Y) / math.max(1, hue.AbsoluteSize.Y), 0, 1)
        else
            s = math.clamp((input.Position.X - square.AbsolutePosition.X) / math.max(1, square.AbsoluteSize.X), 0, 1)
            v = 1 - math.clamp((input.Position.Y - square.AbsolutePosition.Y) / math.max(1, square.AbsoluteSize.Y), 0, 1)
        end
        local selectedHue = h
        control:SetValue(Color3.fromHSV(h, s, v))
        h = selectedHue
    end
    for _, object in ipairs({ square, hue }) do
        track(object.InputBegan:Connect(function(input)
            if not control.Disabled and not dragInput and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
                dragInput, dragKind, scrolling = input, object.Name, scrollPage.ScrollingEnabled
                scrollPage.ScrollingEnabled = false
                update(input)
            end
        end))
    end
    local function stopDrag()
        if dragInput then dragInput = nil scrollPage.ScrollingEnabled = scrolling end
    end
    track(UserInputService.InputChanged:Connect(function(input)
        if dragInput and (input == dragInput or dragInput.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseMovement) then update(input) end
    end))
    track(UserInputService.InputEnded:Connect(function(input)
        if dragInput and (input == dragInput or input.UserInputType == Enum.UserInputType.MouseButton1) then stopDrag() end
    end))
    track(UserInputService.WindowFocusReleased:Connect(stopDrag))
    attachDropdownDismiss(control.Frame, scrollPage, function() return expanded end, function(value) stopDrag() setOpen(value) end)
    control:SetValue(options.Default or Color3.new(1, 1, 1), true)
    decorate(control, options)
    if options.FireOnInit then fire(control) end
    return control
end

function Tab:AddDivider(title)
    local frame = card(self, title and 30 or 12)
    frame.BackgroundTransparency = 1
    frame:FindFirstChildWhichIsA("UIStroke"):Destroy()
    if title then text({ Text = title, Size = UDim2.fromScale(1, 1), TextColor3 = Colors.Muted, TextSize = 12, Parent = frame })
    else create("Frame", { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.fromScale(0, 0.5), BackgroundColor3 = Colors.Border, BorderSizePixel = 0, Parent = frame }) end
    return decorate({ Frame = frame })
end
function Tab:AddGroupbox(title, options)
    options = options or {}
    local frame = card(self, 0)
    frame.Name, frame.AutomaticSize = "Groupbox_" .. title, Enum.AutomaticSize.Y
    local headerButton = create("TextButton", { Size = UDim2.new(1, 0, 0, TOUCH and 46 or 36), BackgroundTransparency = 1, Text = "", Parent = frame })
    text({ Text = title, FontFace = Fonts.Bold, Size = UDim2.new(1, -50, 1, 0), Position = UDim2.fromOffset(12, 0), Parent = headerButton })
    local arrow = text({ Text = "−", Size = UDim2.fromOffset(28, 36), Position = UDim2.new(1, -36, 0, 0), TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = Colors.Muted, Parent = headerButton })
    local body = create("Frame", { Size = UDim2.new(1, -16, 0, 0), Position = UDim2.fromOffset(8, TOUCH and 46 or 36), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = frame }, { create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }), create("UIPadding", { PaddingBottom = UDim.new(0, 8) }) })
    local group = setmetatable({ Frame = frame, Page = body, ScrollPage = self.ScrollPage or self.Page, Window = self.Window, Order = 0 }, { __index = Tab })
    function group:SetCollapsed(value)
        self.Collapsed = value == true
        body.Visible, arrow.Text = not self.Collapsed, self.Collapsed and "+" or "−"
        return self
    end
    track(headerButton.Activated:Connect(function() if not group.Disabled then group:SetCollapsed(not group.Collapsed) end end))
    decorate(group, options)
    group:SetCollapsed(options.Collapsed == true)
    return group
end
Tab.AddGroupBox = Tab.AddGroupbox

function Tab:AddTabbox(title, options)
    options = options or {}
    local frame = card(self, 0)
    frame.Name, frame.AutomaticSize = "Tabbox_" .. title, Enum.AutomaticSize.Y
    local header = create("ScrollingFrame", { Name = "Tabs", BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, -16, 0, TOUCH and 44 or 36), Position = UDim2.fromOffset(8, 4), ScrollBarThickness = 1, ScrollingDirection = Enum.ScrollingDirection.X, AutomaticCanvasSize = Enum.AutomaticSize.X, CanvasSize = UDim2.new(), Parent = frame }, { create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }) })
    local box = decorate({ Frame = frame, Tabs = {}, Window = self.Window }, options)
    function box:SelectTab(target)
        if type(target) == "string" then target = self.Tabs[target] end
        assert(target and target.Tabbox == self, "Unknown inner tab")
        for _, inner in pairs(self.Tabs) do
            local selected = inner == target
            inner.Page.Visible = selected
            Colors:Set(inner.Button, "BackgroundColor3", selected and Colors.Hover or Colors.Surface)
            Colors:Set(inner.Button, "TextColor3", selected and Colors.Text or Colors.Muted)
        end
        self.SelectedTab = target
        return self
    end
    local scrollPage = self.ScrollPage or self.Page
    function box:AddTab(name)
        assert(type(name) == "string" and not self.Tabs[name], "Inner tab title must be unique")
        local button = create("TextButton", { Text = name, Size = UDim2.fromOffset(0, TOUCH and 36 or 28), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = Colors.Surface, TextColor3 = Colors.Muted, FontFace = Fonts.Medium, TextSize = 13, AutoButtonColor = false, Parent = header }, { corner(5), create("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }) })
        local page = create("Frame", { Name = name, Size = UDim2.new(1, -16, 0, 0), Position = UDim2.fromOffset(8, TOUCH and 52 or 44), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Visible = false, Parent = frame }, { create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }), create("UIPadding", { PaddingBottom = UDim.new(0, 8) }) })
        local inner = setmetatable({ Name = name, Page = page, ScrollPage = scrollPage, Button = button, Window = self.Window, Tabbox = self, Order = 0 }, { __index = Tab })
        self.Tabs[name] = inner
        track(button.Activated:Connect(function() if not box.Disabled then box:SelectTab(inner) end end))
        if not self.SelectedTab then self:SelectTab(inner) end
        return inner
    end
    return box
end
Tab.AddTabBox = Tab.AddTabbox
