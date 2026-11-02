local bubble = create("TextButton", {
    Position = config.LauncherPosition or UDim2.fromOffset(22, 104),
    Size = UDim2.fromOffset(52, 52),
    BackgroundColor3 = Colors.Surface,
    AutoButtonColor = false,
    Text = "",
    Visible = false,
    Parent = screen,
}, { corner(16), stroke(Colors.Border) })
local bubbleIcon = text({ Size = UDim2.fromScale(1, 1), FontFace = Fonts.Bold, TextSize = 38, TextXAlignment = Enum.TextXAlignment.Center, Text = "S", Parent = bubble })
Components.Launcher(bubble, bubbleIcon, TweenService, track, function(button, label)
    return Components.Assets(button, label, Library, config)
end, nil, Colors)
local menu = Components.MenuTransition(TweenService, window, content, bubble, Colors, function() return popup end, UDim2.fromOffset(WIDTH, HEIGHT), config.AutoShow ~= false)
Hub.Menu, Hub.LauncherButton = menu, bubble
local layout = Components.Responsive(screen, window, menu, config, track, resizeContent)
local drag = Components.Drag(UserInputService, track, layout.Position, layout.Move, menu.CanDrag)
Hub.Layout, Hub.Drag = layout, drag
beginDrag = drag.Begin
local function dragHandle(parent, name, size)
    local handle = create("TextButton", {
        Name = name,
        Size = size,
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Text = "",
        ZIndex = 3,
        Parent = parent,
    })
    track(handle.InputBegan:Connect(beginDrag))
end
dragHandle(header, "TitleDragHandle", UDim2.fromScale(1, 1))
dragHandle(topBar, "TopBarDragHandle", UDim2.new(1, TOUCH and -100 or -84, 1, 0))
Hub.LauncherControls = Components.LauncherControls(bubble, UserInputService, track, function() menu.SetOpen(true) end)
track(minimizeButton.Activated:Connect(function() menu.SetOpen(false) end))
track(closeButton.Activated:Connect(function() Hub:Unload() end))
track(UserInputService.InputBegan:Connect(function(input, processed)
    if processed or Hub.BindingControl or UserInputService:GetFocusedTextBox() then return end
    if input.KeyCode == (config.ToggleKeybind or Enum.KeyCode.RightShift) then menu.Toggle()
    elseif input.KeyCode == (config.PanicKeybind or Enum.KeyCode.End) then
        if config.OnPanic then Library:_Call(config.OnPanic, Hub) else Hub:StopAll() end
    end
end))
function Hub:Show() menu.SetOpen(true) return self end
function Hub:Hide() menu.SetOpen(false) return self end
function Hub:Toggle() menu.Toggle() return self end
function Hub:IsOpen() return menu.IsOpen() end
function Hub:Ready()
    if not self.Active or self.Loaded then return self end
    layout.Refresh()
    self.Loaded = true
    if config.ShowDiscordPrompt then
        self:ShowDiscordPrompt()
        popup.Blur.Enabled = menu.IsOpen()
        popup.Overlay.Visible = menu.IsOpen()
    end
    screen.Enabled = true
    return self
end
__WINDOW_EXTRAS__
Library.Windows[id] = Hub
if not config.DeferShow then task.defer(function() Hub:Ready() end) end
return Hub
