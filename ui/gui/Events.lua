local dragStart, startPosition
beginDrag = function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragStart = input.Position
        startPosition = window.Position
    end
end
track(topBar.InputBegan:Connect(beginDrag))
track(UserInputService.InputChanged:Connect(function(input)
    if dragStart and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        window.Position = UDim2.fromOffset(math.floor(startPosition.X.Offset + delta.X), math.floor(startPosition.Y.Offset + delta.Y))
    end
end))
track(UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragStart = nil end
end))
local bubble = create("TextButton", {
    Position = config.LauncherPosition or UDim2.fromOffset(22, 104),
    Size = UDim2.fromOffset(52, 52),
    BackgroundColor3 = Theme.Surface,
    AutoButtonColor = false,
    Text = "",
    Visible = false,
    Parent = screen,
}, { corner(16), stroke(Theme.Border) })
local bubbleIcon = text({ Size = UDim2.fromScale(1, 1), FontFace = Fonts.Bold, TextSize = 38, TextXAlignment = Enum.TextXAlignment.Center, Text = "S", Parent = bubble })
Components.Launcher(bubble, bubbleIcon, TweenService, track, function(button, label)
    return Components.Assets(button, label, Library, config)
end, nil, Theme)
local menu = Components.MenuTransition(TweenService, window, content, bubble, Theme, function() return popup end, UDim2.fromOffset(WIDTH, HEIGHT), config.AutoShow ~= false)
Hub.Menu, Hub.LauncherButton = menu, bubble
Hub.LauncherControls = Components.LauncherControls(bubble, UserInputService, track, function() menu.SetOpen(true) end)
track(minimizeButton.MouseButton1Click:Connect(function() menu.SetOpen(false) end))
track(closeButton.MouseButton1Click:Connect(function() Hub:Unload() end))
track(UserInputService.InputBegan:Connect(function(input, processed)
    if processed or UserInputService:GetFocusedTextBox() then return end
    if input.KeyCode == (config.ToggleKeybind or Enum.KeyCode.RightShift) then menu.Toggle()
    elseif input.KeyCode == (config.PanicKeybind or Enum.KeyCode.End) then
        if config.OnPanic then Library:_Call(config.OnPanic, Hub) else Hub:StopAll() end
    end
end))
function Hub:Show() menu.SetOpen(true) return self end
function Hub:Hide() menu.SetOpen(false) return self end
function Hub:Toggle() menu.Toggle() return self end
function Hub:IsOpen() return menu.IsOpen() end
Library.Windows[id] = Hub
if config.ShowDiscordPrompt then task.defer(function() if Hub.Active then Hub:ShowDiscordPrompt() end end) end
return Hub
