local environment = getgenv and getgenv() or _G
environment.ShrakScriptsUIWindows = environment.ShrakScriptsUIWindows or {}
local Library = {
    Version = "1.0.1",
    Windows = environment.ShrakScriptsUIWindows,
    AssetCache = {},
    AssetBase = "https://raw.githubusercontent.com/imshrak/shrakscripts/refs/heads/main/ui/assets/",
}
function Library:_Call(callback, ...)
    if type(callback) ~= "function" then return end
    local ok, message = pcall(callback, ...)
    if not ok then warn("[ShrakScripts UI] " .. tostring(message)) end
end
local Components = {}
Components.Icons = (function()
return {
    farm = "rbxassetid://109718589733073",
    pets = "rbxassetid://97578437331341",
    rewards = "rbxassetid://87706885156127",
    user = "rbxassetid://114567720540659",
    settings = "rbxassetid://106205298246017",
    x = "rbxassetid://116396312853810",
    minus = "rbxassetid://95070996149109",
    chevronDown = "rbxassetid://71457658246709",
    chevronRight = "rbxassetid://101007429951147",
    check = "rbxassetid://86817768619372",
    copy = "rbxassetid://116378866141355",
    copyCheck = "rbxassetid://92397569046734",
}

end)()
Components.TabHighlight = (function()
return function(TweenService, Theme, tabList)
    local baseZ = tabList:GetAttribute("TabHighlightBaseZIndex") or tabList.ZIndex
    tabList:SetAttribute("TabHighlightBaseZIndex", baseZ)
    tabList.ZIndex = baseZ + 1

    local backgroundLayer = Instance.new("Frame")
    backgroundLayer.Name = "TabHighlightBackgroundLayer"
    backgroundLayer.BackgroundTransparency = 1
    backgroundLayer.Size = tabList.Size
    backgroundLayer.Position = tabList.Position
    backgroundLayer.ZIndex = baseZ
    backgroundLayer.Parent = tabList.Parent

    local background = Instance.new("Frame")
    background.Name = "TabButtonHighlight"
    background.BackgroundColor3 = Theme.Hover
    background.BorderSizePixel = 0
    background.Visible = false
    background.Parent = backgroundLayer
    local backgroundCorner = Instance.new("UICorner")
    backgroundCorner.CornerRadius = UDim.new(0, 6)
    backgroundCorner.Parent = background

    local layer = Instance.new("Frame")
    layer.Name = "TabHighlightLayer"
    layer.BackgroundTransparency = 1
    layer.Size = tabList.Size
    layer.Position = tabList.Position
    layer.ZIndex = baseZ + 2
    layer.Parent = tabList.Parent

    local highlight = Instance.new("Frame")
    highlight.Name = "TabHighlight"
    highlight.BackgroundColor3 = Theme.Accent
    highlight.Size = UDim2.fromOffset(2, 16)
    highlight.BorderSizePixel = 0
    highlight.Visible = false
    highlight.Parent = layer
    local rounded = Instance.new("UICorner")
    rounded.CornerRadius = UDim.new(0, 1)
    rounded.Parent = highlight

    local function alignIndicator()
        local position = background.Position
        highlight.Position = UDim2.fromOffset(position.X.Offset, position.Y.Offset + (background.Size.Y.Offset - 16) / 2)
    end
    background:GetPropertyChangedSignal("Position"):Connect(alignIndicator)
    background:GetPropertyChangedSignal("Size"):Connect(alignIndicator)

    local current, motion
    return function(tab)
        if current == tab then
            return
        end
        if motion then
            motion:Cancel()
        end
        local position = tab.Button.AbsolutePosition - tabList.AbsolutePosition
        local goal = { Position = UDim2.fromOffset(position.X, position.Y), Size = tab.Button.Size }
        if current then
            motion = TweenService:Create(background, TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), goal)
            motion:Play()
        else
            background.Position = goal.Position
            background.Size = goal.Size
            background.Visible = true
            highlight.Visible = true
        end
        current = tab
    end
end

end)()
Components.DropdownDismiss = (function()
return function(UserInputService, track)
    return function(frame, page, isOpen, setOpen)
        local function close()
            if frame.Parent and isOpen() then
                setOpen(false)
            end
        end
        local function contains(object, point)
            local position, size = object.AbsolutePosition, object.AbsoluteSize
            return point.X >= position.X and point.Y >= position.Y
                and point.X < position.X + size.X and point.Y < position.Y + size.Y
        end
        local function inside(point)
            return frame.Parent and contains(frame, point) and contains(page, point)
        end
        local function inputBegan(input)
            local kind = input.UserInputType
            if isOpen() and (kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.MouseButton2 or kind == Enum.UserInputType.Touch)
                and not inside(Vector2.new(input.Position.X, input.Position.Y)) then
                close()
            end
        end
        local function inputChanged(input)
            if isOpen() and input.UserInputType == Enum.UserInputType.MouseWheel and not inside(UserInputService:GetMouseLocation()) then
                close()
            end
        end
        track(UserInputService.InputBegan:Connect(inputBegan))
        track(UserInputService.InputChanged:Connect(inputChanged))
        track(page:GetPropertyChangedSignal("CanvasPosition"):Connect(close))
        local ancestor = frame.Parent
        while ancestor do
            local current = ancestor
            if current:IsA("GuiObject") then
                track(current:GetPropertyChangedSignal("Visible"):Connect(function()
                    if not current.Visible then close() end
                end))
                if not current.Visible then close() end
            elseif current:IsA("ScreenGui") then
                track(current:GetPropertyChangedSignal("Enabled"):Connect(function()
                    if not current.Enabled then close() end
                end))
                if not current.Enabled then close() end
                break
            end
            ancestor = current.Parent
        end
        frame:SetAttribute("DismissOnOutside", true)
        return { Close = close, InputBegan = inputBegan, InputChanged = inputChanged }
    end
end

end)()
Components.SingleSelect = (function()
return function(create, text, corner, stroke, icon, track, tween, Theme, card, cardLabels, attachDismiss)
    return function(tab, title, getOptions, getValue, onChange)
        local HEAD, ROW = 42, 28
        local frame = card(tab, HEAD)
        frame.Name = "SingleSelect"
        frame.ClipsDescendants = true
        cardLabels(frame, title)
        local summary = text({
            Size = UDim2.fromOffset(170, 16),
            Position = UDim2.new(1, -206, 0, 13),
            TextColor3 = Theme.Muted,
            TextXAlignment = Enum.TextXAlignment.Right,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = frame,
        })
        local chevron = icon("chevronDown", 16, UDim2.new(1, -30, 0, 13), Theme.Muted, frame)
        local head = create("TextButton", {
            Name = "ChoiceHeader",
            Size = UDim2.new(1, 0, 0, HEAD),
            BackgroundTransparency = 1,
            Text = "",
            Parent = frame,
        })
        local body = create("ScrollingFrame", {
            Name = "Choices",
            Size = UDim2.new(1, -16, 0, 0),
            Position = UDim2.fromOffset(8, HEAD + 6),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = Theme.Border,
            CanvasSize = UDim2.new(),
            Parent = frame,
        })
        local open = false
        local options, rows = {}, {}
        local function updateSelection()
            local selected = getValue()
            summary.Text = selected == nil and "Select" or tostring(selected)
            for index, option in ipairs(options) do
                local active = option.Value == selected
                rows[index].Box.BackgroundColor3 = active and Theme.Accent or Theme.Surface
                rows[index].Box.UIStroke.Color = active and Theme.Accent or Theme.Faint
                rows[index].Mark.Visible = active
                if active then summary.Text = option.Name end
            end
        end
        local function setOpen(value)
            open = value
            tween(frame, { Size = UDim2.new(1, 0, 0, open and HEAD + body.Size.Y.Offset + 12 or HEAD) }, 0.18)
            tween(chevron, { Rotation = open and 180 or 0 }, 0.18)
        end
        local function refresh()
            local latest = getOptions()
            local changed = #latest ~= #options
            for index, option in ipairs(latest) do
                if not options[index] or options[index].Value ~= option.Value or options[index].Name ~= option.Name then changed = true break end
            end
            if changed then
                body:ClearAllChildren()
                options, rows = latest, {}
                body.Size = UDim2.new(1, -16, 0, math.min(#options, 6) * ROW)
                body.CanvasSize = UDim2.fromOffset(0, #options * ROW)
                for index, option in ipairs(options) do
                    local row = create("TextButton", {
                        Size = UDim2.new(1, -4, 0, ROW),
                        Position = UDim2.fromOffset(0, (index - 1) * ROW),
                        BackgroundColor3 = Theme.Hover,
                        BackgroundTransparency = 1,
                        AutoButtonColor = false,
                        Text = "",
                        Parent = body,
                    }, { corner(5) })
                    row:SetAttribute("ChoiceValue", option.Value)
                    local box = create("Frame", {
                        Size = UDim2.fromOffset(14, 14),
                        Position = UDim2.fromOffset(8, 7),
                        BackgroundColor3 = Theme.Surface,
                        Parent = row,
                    }, { corner(3), stroke(Theme.Faint) })
                    local mark = icon("check", 12, UDim2.fromOffset(1, 1), Theme.OnAccent, box)
                    text({ Size = UDim2.new(1, -40, 1, 0), Position = UDim2.fromOffset(32, 0), Text = option.Name, Parent = row })
                    rows[index] = { Box = box, Mark = mark }
                    track(row.MouseEnter:Connect(function() tween(row, { BackgroundTransparency = 0 }) end))
                    track(row.MouseLeave:Connect(function() tween(row, { BackgroundTransparency = 1 }) end))
                    track(row.MouseButton1Click:Connect(function()
                        onChange(option.Value)
                        updateSelection()
                        setOpen(false)
                    end))
                end
            end
            updateSelection()
        end
        track(head.MouseButton1Click:Connect(function()
            if not open then refresh() end
            setOpen(not open)
        end))
        attachDismiss(frame, tab.Page, function() return open end, setOpen)
        refresh()
        return frame, refresh
    end
end

end)()
Components.DialogDrag = (function()
return function(create, track, beginDrag)
    local function addHandle(parent, size)
        if parent:FindFirstChild("DiscordDragHandle") then
            return
        end
        local handle = create("TextButton", {
            Name = "DiscordDragHandle",
            Size = size,
            BackgroundTransparency = 1,
            AutoButtonColor = false,
            Text = "",
            ZIndex = 14,
            Parent = parent,
        })
        track(handle.InputBegan:Connect(beginDrag))
    end
    return function(overlay, panel)
        addHandle(overlay, UDim2.new(1, -84, 0, 48))
        addHandle(panel, UDim2.new(1, -56, 0, 68))
    end
end

end)()
Components.MenuTransition = (function()
return function(TweenService, window, content, button, Theme, getPopup, expandedSize, initialOpen, initialPosition)
    local corner = window:FindFirstChildWhichIsA("UICorner")
    local outline = window:FindFirstChildWhichIsA("UIStroke")
    local buttonCorner = button:FindFirstChildWhichIsA("UICorner")
    local group = Instance.new("CanvasGroup")
    group.Name = "MenuContentFade"
    group.Size = content.Size
    group.Position = content.Position
    group.BackgroundTransparency = 1
    group.BorderSizePixel = 0
    group.Parent = window
    content.Position = UDim2.new()
    content.Parent = group

    local logo = button:FindFirstChild("LauncherLogo") or button:FindFirstChildWhichIsA("TextLabel")
    local ghost = logo:Clone()
    ghost.Name = "MenuMorphLogo"
    ghost.AnchorPoint = Vector2.new(0.5, 0.5)
    ghost.Position = UDim2.fromScale(0.5, 0.5)
    ghost.ZIndex = 50
    ghost.Visible = false
    ghost.Parent = window
    local opacity = ghost:IsA("ImageLabel") and "ImageTransparency" or "TextTransparency"
    ghost[opacity] = 1

    local desired = initialOpen ~= false
    local state = desired and "open" or "closed"
    local openPosition = initialPosition or window.Position
    local serial = 0
    local tweens = {}
    local function animate(object, goal, duration, style, direction)
        local animation = TweenService:Create(object, TweenInfo.new(duration, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out), goal)
        table.insert(tweens, animation)
        animation:Play()
        return animation
    end
    local function popupVisible(visible)
        local popup = getPopup and getPopup()
        if popup then
            popup.Blur.Enabled = visible
            popup.Overlay.Visible = visible
        end
    end
    local function closedAppearance()
        window.Position = button.Position
        window.Size = button.Size
        window.BackgroundColor3 = Theme.Surface
        window.BackgroundTransparency = button.BackgroundTransparency
        corner.CornerRadius = buttonCorner.CornerRadius
        outline.Color = Theme.Border
        outline.Thickness = 1
        outline.Transparency = 0
    end

    if desired then
        window.Size = expandedSize
        window.Position = openPosition
        window.BackgroundColor3 = Theme.Window
        corner.CornerRadius = UDim.new(0, 10)
        group.GroupTransparency = 0
        content.Visible = true
        window.Visible = true
        button.Visible = false
    else
        closedAppearance()
        group.GroupTransparency = 1
        content.Visible = false
        window.Visible = false
        button.Visible = true
        popupVisible(false)
    end

    local controller = {}
    function controller.SetOpen(open)
        if not window.Parent or desired == open then return end
        if not open and state == "open" then openPosition = window.Position end
        desired = open
        serial += 1
        local token = serial
        for _, animation in ipairs(tweens) do animation:Cancel() end
        table.clear(tweens)
        local wasClosed = state == "closed"
        state = open and "opening" or "closing"
        button.Visible = false
        if open and wasClosed then
            closedAppearance()
            ghost[opacity] = 0
            group.GroupTransparency = 1
        end
        window.Visible = true
        ghost.Visible = true
        local duration = open and 0.28 or 0.24
        local movement
        if open then
            content.Visible = true
            popupVisible(false)
            animate(ghost, { [opacity] = 1 }, 0.08)
            movement = animate(window, { Position = openPosition, Size = expandedSize, BackgroundColor3 = Theme.Window, BackgroundTransparency = 0 }, duration, Enum.EasingStyle.Quint)
            animate(corner, { CornerRadius = UDim.new(0, 10) }, duration, Enum.EasingStyle.Quint)
            task.delay(0.06, function()
                if token == serial and window.Parent then animate(group, { GroupTransparency = 0 }, 0.16) end
            end)
        else
            popupVisible(false)
            animate(group, { GroupTransparency = 1 }, 0.08)
            movement = animate(window, { Position = button.Position, Size = button.Size, BackgroundColor3 = Theme.Surface, BackgroundTransparency = button.BackgroundTransparency }, duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            animate(corner, { CornerRadius = buttonCorner.CornerRadius }, duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.delay(0.08, function()
                if token == serial and window.Parent then content.Visible = false end
            end)
            task.delay(0.12, function()
                if token == serial and window.Parent then animate(ghost, { [opacity] = 0 }, 0.1) end
            end)
        end
        movement.Completed:Once(function(playback)
            if token ~= serial or not window.Parent or playback ~= Enum.PlaybackState.Completed then return end
            ghost.Visible = false
            if desired then
                state = "open"
                group.GroupTransparency = 0
                content.Visible = true
                popupVisible(true)
            else
                state = "closed"
                closedAppearance()
                content.Visible = false
                window.Visible = false
                button.Visible = true
            end
        end)
    end
    function controller.Toggle()
        controller.SetOpen(not desired)
    end
    function controller.IsOpen()
        return desired
    end
    return controller
end

end)()
Components.LauncherControls = (function()
return function(button, UserInputService, track, activate)
    local drag
    local suppressUntil = 0
    local function began(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            drag = { Input = input, Position = input.Position, Start = button.Position, Moved = false }
        end
    end
    local function changed(input)
        if drag and (input.UserInputType == Enum.UserInputType.MouseMovement or input == drag.Input) then
            local delta = input.Position - drag.Position
            if delta.Magnitude > 4 then drag.Moved = true end
            if drag.Moved then
                button.Position = UDim2.fromOffset(math.floor(drag.Start.X.Offset + delta.X), math.floor(drag.Start.Y.Offset + delta.Y))
            end
        end
    end
    local function ended(input)
        if drag and (input.UserInputType == Enum.UserInputType.MouseButton1 or input == drag.Input) then
            if drag.Moved then suppressUntil = os.clock() + 0.15 end
            drag = nil
        end
    end
    local function clicked()
        if not (drag and drag.Moved) and os.clock() >= suppressUntil then activate() end
    end
    track(button.InputBegan:Connect(began))
    track(UserInputService.InputChanged:Connect(changed))
    track(UserInputService.InputEnded:Connect(ended))
    track(button.Activated:Connect(clicked))
    return { Began = began, Changed = changed, Ended = ended, Click = clicked }
end

end)()
Components.Launcher = (function()
return function(button, label, TweenService, track, applyLogo, logoData, Theme)
    local palette = Theme or { Surface = Color3.fromRGB(17, 17, 17), Hover = Color3.fromRGB(26, 26, 26), Border = Color3.fromRGB(38, 38, 38), Text = Color3.fromRGB(245, 245, 245) }
    button.Name = "MenuButton"
    button.Size = UDim2.fromOffset(52, 52)
    button.BackgroundColor3 = palette.Surface
    button.BackgroundTransparency = 0
    button.BorderSizePixel = 0
    button.AutoButtonColor = false
    button:FindFirstChildWhichIsA("UICorner").CornerRadius = UDim.new(0, 16)
    local outline = button:FindFirstChildWhichIsA("UIStroke")
    outline.Color = palette.Border
    outline.Thickness = 1
    outline.Transparency = 0
    label.Name = "LauncherLogo"
    label.Position = UDim2.fromOffset(8, 8)
    label.Size = UDim2.fromOffset(36, 36)
    label.Font = Enum.Font.GothamBlack
    label.Text = "S"
    label.TextSize = 38
    label.TextColor3 = palette.Text
    label.Visible = true
    local mark = applyLogo and applyLogo(button, label, logoData) or label
    if mark:IsA("ImageLabel") then mark.ImageColor3 = palette.Text end

    track(button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.12), { BackgroundColor3 = palette.Hover }):Play()
    end))
    track(button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.12), { BackgroundColor3 = palette.Surface }):Play()
    end))
    local function clampPosition()
        local canvas = button.Parent and button.Parent.AbsoluteSize
        if not canvas or canvas.X <= 0 or canvas.Y <= 0 then return end
        local point = button.Position
        local goal = UDim2.fromOffset(
            math.clamp(point.X.Scale * canvas.X + point.X.Offset, 8, math.max(8, canvas.X - 60)),
            math.clamp(point.Y.Scale * canvas.Y + point.Y.Offset, 8, math.max(8, canvas.Y - 60))
        )
        if button.Position ~= goal then button.Position = goal end
    end
    track(button:GetPropertyChangedSignal("Position"):Connect(clampPosition))
    track(button.Parent:GetPropertyChangedSignal("AbsoluteSize"):Connect(clampPosition))
    clampPosition()
    return mark
end

end)()
Components.Assets = (function()
return function(button, label, Library, config)
    label.Name = "LauncherLetter"
    local image = config.LauncherImage
    if type(image) == "number" then image = "rbxassetid://" .. image end
    if not image then
        local base = config.AssetBase or Library.AssetBase
        local url = base:gsub("/*$", "/") .. "launcher-s.png"
        image = Library.AssetCache[url]
        if not image then
            local ok, result = pcall(function()
                local loader = getcustomasset or getsynasset
                if not loader or not writefile then return end
                local data = game:HttpGet(url)
                assert(data:sub(1, 8) == "\137PNG\r\n\26\n", "Invalid launcher PNG")
                local folder = config.CacheFolder or "ShrakScriptsUI"
                if makefolder then pcall(makefolder, folder) end
                local path = folder .. "/launcher-s.png"
                writefile(path, data)
                return loader(path)
            end)
            if ok then image = result end
            if image then Library.AssetCache[url] = image end
        end
    end
    if type(image) ~= "string" or image == "" then label.Visible = true return label end
    local mark = Instance.new("ImageLabel")
    mark.Name = "LauncherLogo"
    mark.Position = UDim2.fromOffset(8, 8)
    mark.Size = UDim2.fromOffset(36, 36)
    mark.BackgroundTransparency = 1
    mark.Image = image
    mark.ScaleType = Enum.ScaleType.Fit
    mark.Parent = button
    label.Visible = false
    return mark
end

end)()
local createWindow = (function()
return function(Library, config, Components)
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local environment = getgenv and getgenv() or _G
local id = config.Id or "ShrakScriptsUI"
if Library.Windows[id] then Library.Windows[id]:Unload() end
local Hub = { Active = true, Toggles = {}, Options = {}, Controls = {}, Tabs = {}, UnloadCallbacks = {} }
local connections = {}
local beginDrag
local DISCORD_CODE = tostring(config.DiscordInvite or ""):gsub("^https?://discord%.gg/", ""):gsub("^discord%.gg/", "")
local function track(connection)
    table.insert(connections, connection)
    return connection
end
local Theme = {
    Window = Color3.fromRGB(8, 8, 8),
    Sidebar = Color3.fromRGB(12, 12, 12),
    Surface = Color3.fromRGB(17, 17, 17),
    Hover = Color3.fromRGB(26, 26, 26),
    Border = Color3.fromRGB(38, 38, 38),
    Text = Color3.fromRGB(245, 245, 245),
    Muted = Color3.fromRGB(140, 140, 140),
    Faint = Color3.fromRGB(80, 80, 80),
    Accent = Color3.fromRGB(255, 255, 255),
    OnAccent = Color3.fromRGB(8, 8, 8),
}

for key, value in pairs(config.Theme or {}) do
    assert(Theme[key] and typeof(value) == "Color3", "Invalid theme color: " .. tostring(key))
    Theme[key] = value
end

local Fonts = {
    Regular = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Regular),
    Medium = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Medium),
    Bold = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold),
}

local function create(className, properties, children)
    local instance = Instance.new(className)
    for key, value in pairs(properties) do
        instance[key] = value
    end
    for _, child in ipairs(children or {}) do
        child.Parent = instance
    end
    return instance
end

local function corner(radius)
    return create("UICorner", { CornerRadius = UDim.new(0, radius) })
end

local function round()
    return create("UICorner", { CornerRadius = UDim.new(0.5, 0) })
end

local function stroke(color, thickness)
    return create("UIStroke", { Color = color, Thickness = thickness or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
end

local function text(properties)
    properties.BackgroundTransparency = 1
    properties.FontFace = properties.FontFace or Fonts.Regular
    properties.TextSize = properties.TextSize or 14
    properties.TextColor3 = properties.TextColor3 or Theme.Text
    properties.TextXAlignment = properties.TextXAlignment or Enum.TextXAlignment.Left
    return create("TextLabel", properties)
end

local function tween(instance, goal, duration)
    TweenService:Create(instance, TweenInfo.new(duration or 0.14, Enum.EasingStyle.Quad), goal):Play()
end

local Icons = Components.Icons
local function icon(name, size, position, color, parent)
    return create("ImageLabel", {
        Size = UDim2.fromOffset(size, size),
        Position = position,
        BackgroundTransparency = 1,
        Image = Icons[name],
        ImageColor3 = color or Theme.Muted,
        ScaleType = Enum.ScaleType.Fit,
        Parent = parent,
    })
end

local camera = Workspace.CurrentCamera
local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
local WIDTH, HEIGHT = config.Width or 560, config.Height or 400

local screen = create("ScreenGui", {
    Name = id,
    Enabled = false,
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    Parent = config.Parent or (gethui and gethui() or CoreGui),
})

local window = create("Frame", {
    Size = UDim2.fromOffset(WIDTH, HEIGHT),
    Position = config.Position or UDim2.fromOffset(math.floor((viewport.X - WIDTH) / 2), math.floor((viewport.Y - HEIGHT) / 2)),
    BackgroundColor3 = Theme.Window,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    Parent = screen,
}, { corner(10), stroke(Theme.Border) })

local content = create("Frame", {
    Size = UDim2.fromOffset(WIDTH, HEIGHT),
    BackgroundTransparency = 1,
    Parent = window,
})

local sidebar = create("Frame", {
    Size = UDim2.new(0, 156, 1, 0),
    BackgroundColor3 = Theme.Sidebar,
    BorderSizePixel = 0,
    Parent = content,
}, { corner(10) })

create("Frame", {
    Size = UDim2.new(0, 12, 1, 0),
    Position = UDim2.new(1, -12, 0, 0),
    BackgroundColor3 = Theme.Sidebar,
    BorderSizePixel = 0,
    Parent = sidebar,
})

create("Frame", {
    Size = UDim2.new(0, 1, 1, 0),
    Position = UDim2.new(1, 0, 0, 0),
    BackgroundColor3 = Theme.Border,
    BorderSizePixel = 0,
    Parent = sidebar,
})

local header = create("Frame", {
    Size = UDim2.new(1, 0, 0, 58),
    BackgroundTransparency = 1,
    Parent = sidebar,
})

text({
    Size = UDim2.new(1, -32, 0, 18),
    Position = UDim2.fromOffset(16, 14),
    FontFace = Fonts.Bold,
    TextSize = 16,
    Text = config.Title or "ShrakScripts",
    Parent = header,
})

text({
    Size = UDim2.new(1, -32, 0, 14),
    Position = UDim2.fromOffset(16, 33),
    TextSize = 12,
    TextColor3 = Theme.Faint,
    Text = config.Subtitle or "ShrakScripts UI",
    Parent = header,
})

local tabList = create("Frame", {
    Size = UDim2.new(1, -16, 1, -66),
    Position = UDim2.fromOffset(8, 62),
    BackgroundTransparency = 1,
    Parent = sidebar,
}, { create("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }) })

local topBar = create("Frame", {
    Size = UDim2.new(1, -157, 0, 48),
    Position = UDim2.fromOffset(157, 0),
    BackgroundTransparency = 1,
    Parent = content,
})

local pageTitle = text({
    Size = UDim2.new(1, -100, 0, 20),
    Position = UDim2.fromOffset(20, 15),
    FontFace = Fonts.Bold,
    TextSize = 15,
    Text = "",
    Parent = topBar,
})

local function windowButton(offset, iconName, hoverColor)
    local button = create("TextButton", {
        Size = UDim2.fromOffset(26, 26),
        Position = UDim2.new(1, offset, 0, 11),
        BackgroundColor3 = Theme.Window,
        AutoButtonColor = false,
        Text = "",
        Parent = topBar,
    }, { corner(6) })
    local glyph = icon(iconName, 16, UDim2.fromOffset(5, 5), Theme.Muted, button)
    track(button.MouseEnter:Connect(function()
        tween(button, { BackgroundColor3 = Theme.Hover })
        tween(glyph, { ImageColor3 = hoverColor or Theme.Text })
    end))
    track(button.MouseLeave:Connect(function()
        tween(button, { BackgroundColor3 = Theme.Window })
        tween(glyph, { ImageColor3 = Theme.Muted })
    end))
    return button
end

local closeButton = windowButton(-38, "x")
local minimizeButton = windowButton(-68, "minus")

create("Frame", {
    Size = UDim2.new(1, -157, 0, 1),
    Position = UDim2.fromOffset(157, 48),
    BackgroundColor3 = Theme.Border,
    BorderSizePixel = 0,
    Parent = content,
})

local pages = create("Frame", {
    Size = UDim2.new(1, -157, 1, -49),
    Position = UDim2.fromOffset(157, 49),
    BackgroundTransparency = 1,
    Parent = content,
})

local tabs = {}
local moveTabHighlight = Components.TabHighlight(TweenService, Theme, tabList)

local function selectTab(target)
    for _, tab in ipairs(tabs) do
        local active = tab == target
        tab.Page.Visible = active
        tab.Button.BackgroundTransparency = 1
        tween(tab.Label, { TextColor3 = active and Theme.Text or Theme.Muted })
        tab.Indicator.Visible = false
        tween(tab.Icon, { ImageColor3 = active and Theme.Text or Theme.Muted })
    end
    pageTitle.Text = target.Name
    moveTabHighlight(target)
end

local function addTab(name, iconName)
    local page = create("ScrollingFrame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Theme.Border,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(),
        Visible = false,
        Parent = pages,
    }, {
        create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
        create("UIPadding", {
            PaddingTop = UDim.new(0, 14),
            PaddingBottom = UDim.new(0, 14),
            PaddingLeft = UDim.new(0, 20),
            PaddingRight = UDim.new(0, 20),
        }),
    })
    local button = create("TextButton", {
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = Theme.Hover,
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Text = "",
        LayoutOrder = #tabs,
        Parent = tabList,
    }, { corner(6) })
    local indicator = create("Frame", {
        Size = UDim2.fromOffset(2, 16),
        Position = UDim2.fromOffset(0, 9),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Visible = false,
        Parent = button,
    }, { corner(1) })
    local tabIcon = icon(iconName, 16, UDim2.fromOffset(12, 9), Theme.Muted, button)
    local label = text({
        Size = UDim2.new(1, -44, 1, 0),
        Position = UDim2.fromOffset(38, 0),
        FontFace = Fonts.Medium,
        TextColor3 = Theme.Muted,
        Text = name,
        Parent = button,
    })
    local tab = {
        Name = name,
        Page = page,
        Button = button,
        Label = label,
        Indicator = indicator,
        Icon = tabIcon,
        Order = 0,
    }
    table.insert(tabs, tab)
    track(button.MouseButton1Click:Connect(function()
        selectTab(tab)
    end))
    if #tabs == 1 then
        selectTab(tab)
    end
    return tab
end

local function nextOrder(tab)
    tab.Order += 1
    return tab.Order
end

local function addSection(tab, title)
    local holder = create("Frame", {
        Size = UDim2.new(1, 0, 0, tab.Order == 0 and 18 or 30),
        BackgroundTransparency = 1,
        LayoutOrder = nextOrder(tab),
        Parent = tab.Page,
    })
    text({
        Size = UDim2.new(1, 0, 0, 14),
        Position = UDim2.new(0, 2, 1, -16),
        FontFace = Fonts.Bold,
        TextSize = 12,
        TextColor3 = Theme.Faint,
        Text = string.upper(title),
        Parent = holder,
    })
end

local function card(tab, height)
    local frame = create("Frame", {
        Size = UDim2.new(1, 0, 0, height),
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        LayoutOrder = nextOrder(tab),
        Parent = tab.Page,
    }, { corner(8), stroke(Theme.Border) })
    return frame
end

local function cardLabels(frame, title, description)
    text({
        Size = UDim2.new(1, -90, 0, 16),
        Position = UDim2.fromOffset(14, description and 9 or 13),
        FontFace = Fonts.Medium,
        Text = title,
        Parent = frame,
    })
    if description then
        text({
            Size = UDim2.new(1, -90, 0, 14),
            Position = UDim2.fromOffset(14, 26),
            TextSize = 12,
            TextColor3 = Theme.Muted,
            Text = description,
            Parent = frame,
        })
    end
end

local resetters = {}

local function addToggle(tab, title, onChange)
    local frame = card(tab, 42)
    cardLabels(frame, title)
    local switch = create("Frame", {
        Size = UDim2.fromOffset(34, 18),
        Position = UDim2.new(1, -48, 0.5, -9),
        BackgroundColor3 = Theme.Border,
        Parent = frame,
    }, { round() })
    local knob = create("Frame", {
        Size = UDim2.fromOffset(14, 14),
        Position = UDim2.fromOffset(2, 2),
        BackgroundColor3 = Theme.Muted,
        Parent = switch,
    }, { round() })
    local hitbox = create("TextButton", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = "",
        Parent = frame,
    })
    local enabled = false
    local function set(value)
        enabled = value
        tween(switch, { BackgroundColor3 = value and Theme.Accent or Theme.Border })
        tween(knob, {
            Position = UDim2.fromOffset(value and 18 or 2, 2),
            BackgroundColor3 = value and Theme.OnAccent or Theme.Muted,
        })
        onChange(value)
    end
    track(hitbox.MouseButton1Click:Connect(function()
        set(not enabled)
    end))
    track(hitbox.MouseEnter:Connect(function()
        tween(frame, { BackgroundColor3 = Theme.Hover })
    end))
    track(hitbox.MouseLeave:Connect(function()
        tween(frame, { BackgroundColor3 = Theme.Surface })
    end))
    local function reset()
        if enabled then
            set(false)
        end
    end
    table.insert(resetters, reset)
    return reset, set, frame
end


local function addSlider(tab, title, min, max, value, onChange, rounding)
    local frame = card(tab, 58)
    cardLabels(frame, title)
    local valueLabel = text({
        Size = UDim2.fromOffset(80, 16),
        Position = UDim2.new(1, -94, 0, 13),
        FontFace = Fonts.Medium,
        TextColor3 = Theme.Muted,
        TextXAlignment = Enum.TextXAlignment.Right,
        Text = tostring(value),
        Parent = frame,
    })
    local bar = create("Frame", {
        Size = UDim2.new(1, -28, 0, 4),
        Position = UDim2.fromOffset(14, 40),
        BackgroundColor3 = Theme.Border,
        BorderSizePixel = 0,
        Parent = frame,
    }, { round() })
    local fill = create("Frame", {
        Size = UDim2.fromScale((value - min) / (max - min), 1),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Parent = bar,
    }, { round() })
    local knob = create("Frame", {
        Size = UDim2.fromOffset(12, 12),
        Position = UDim2.new((value - min) / (max - min), -6, 0.5, -6),
        BackgroundColor3 = Theme.Accent,
        Parent = bar,
    }, { round(), stroke(Theme.Window, 2) })
    local hitbox = create("TextButton", {
        Size = UDim2.new(1, 0, 0, 24),
        Position = UDim2.fromOffset(0, 30),
        BackgroundTransparency = 1,
        Text = "",
        Parent = frame,
    })
    local dragging = false
    local function update(x)
        local alpha = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local scale = 10 ^ (rounding or 0)
        local result = math.round((min + (max - min) * alpha) * scale) / scale
        alpha = (result - min) / (max - min)
        fill.Size = UDim2.fromScale(alpha, 1)
        knob.Position = UDim2.new(alpha, -6, 0.5, -6)
        valueLabel.Text = tostring(result)
        onChange(result)
    end
    track(hitbox.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            update(input.Position.X)
        end
    end))
    track(UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            update(input.Position.X)
        end
    end))
    track(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))
    local function setValue(result)
        local scale = 10 ^ (rounding or 0)
        result = math.clamp(math.round(result * scale) / scale, min, max)
        local alpha = (result - min) / (max - min)
        fill.Size = UDim2.fromScale(alpha, 1)
        knob.Position = UDim2.new(alpha, -6, 0.5, -6)
        valueLabel.Text = tostring(result)
        return result
    end
    return frame, setValue
end

local function addMultiSelect(tab, title, options, selected, emptyText, onChange)
    local ROW, HEAD = 28, 42
    local listHeight = #options * ROW + 44
    local frame = card(tab, HEAD)
    frame.ClipsDescendants = true
    cardLabels(frame, title)
    local summary = text({
        Size = UDim2.fromOffset(170, 16),
        Position = UDim2.new(1, -206, 0, 13),
        TextColor3 = Theme.Muted,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = frame,
    })
    local chevron = icon("chevronDown", 16, UDim2.new(1, -30, 0, 13), Theme.Muted, frame)
    local headButton = create("TextButton", {
        Size = UDim2.new(1, 0, 0, HEAD),
        BackgroundTransparency = 1,
        Text = "",
        Parent = frame,
    })
    create("Frame", {
        Size = UDim2.new(1, -28, 0, 1),
        Position = UDim2.fromOffset(14, HEAD),
        BackgroundColor3 = Theme.Border,
        BorderSizePixel = 0,
        Parent = frame,
    })
    local checks = {}
    local function refresh()
        local names = {}
        for _, option in ipairs(options) do
            local on = selected[option.Name] == true
            local check = checks[option.Name]
            check.Box.BackgroundColor3 = on and Theme.Accent or Theme.Surface
            check.Box.UIStroke.Color = on and Theme.Accent or Theme.Faint
            check.Mark.Visible = on
            if on then
                table.insert(names, option.Name)
            end
        end
        summary.Text = #names == 0 and emptyText or #names <= 2 and table.concat(names, ", ") or (#names .. " selected")
    end
    for index, option in ipairs(options) do
        local row = create("TextButton", {
            Size = UDim2.new(1, -16, 0, ROW),
            Position = UDim2.fromOffset(8, HEAD + 6 + (index - 1) * ROW),
            BackgroundColor3 = Theme.Hover,
            BackgroundTransparency = 1,
            AutoButtonColor = false,
            Text = "",
            Parent = frame,
        }, { corner(5) })
        local box = create("Frame", {
            Size = UDim2.fromOffset(14, 14),
            Position = UDim2.fromOffset(8, 7),
            BackgroundColor3 = Theme.Surface,
            Parent = row,
        }, { corner(3), stroke(Theme.Faint) })
        local mark = icon("check", 12, UDim2.fromOffset(1, 1), Theme.OnAccent, box)
        mark.Visible = false
        create("Frame", {
            Size = UDim2.fromOffset(6, 6),
            Position = UDim2.fromOffset(32, 11),
            BackgroundColor3 = option.Color or Theme.Muted,
            Parent = row,
        }, { round() })
        text({
            Size = UDim2.new(1, -52, 1, 0),
            Position = UDim2.fromOffset(46, 0),
            Text = option.Name,
            Parent = row,
        })
        checks[option.Name] = { Box = box, Mark = mark }
        track(row.MouseEnter:Connect(function()
            tween(row, { BackgroundTransparency = 0 })
        end))
        track(row.MouseLeave:Connect(function()
            tween(row, { BackgroundTransparency = 1 })
        end))
        track(row.MouseButton1Click:Connect(function()
            selected[option.Name] = not selected[option.Name] or nil
            refresh()
            if onChange then onChange(selected) end
        end))
    end
    local function quickButton(label, x, callback)
        local button = create("TextButton", {
            Size = UDim2.fromOffset(64, 24),
            Position = UDim2.fromOffset(x, HEAD + 10 + #options * ROW),
            BackgroundColor3 = Theme.Hover,
            AutoButtonColor = false,
            FontFace = Fonts.Medium,
            TextSize = 13,
            TextColor3 = Theme.Text,
            Text = label,
            Parent = frame,
        }, { corner(5) })
        track(button.MouseButton1Click:Connect(function()
            callback()
            refresh()
            if onChange then onChange(selected) end
        end))
    end
    quickButton("All", 14, function()
        for _, option in ipairs(options) do
            selected[option.Name] = true
        end
    end)
    quickButton("Clear", 84, function()
        table.clear(selected)
    end)
    local open = false
    track(headButton.MouseButton1Click:Connect(function()
        open = not open
        tween(frame, { Size = UDim2.new(1, 0, 0, open and HEAD + listHeight or HEAD) }, 0.18)
        tween(chevron, { Rotation = open and 180 or 0 }, 0.18)
    end))
    refresh()
    return frame, refresh
end

local attachDropdownDismiss = Components.DropdownDismiss(UserInputService, track)
local addSingleSelect = Components.SingleSelect(create, text, corner, stroke, icon, track, tween, Theme, card, cardLabels, attachDropdownDismiss)

local function addButton(tab, title, description, callback)
    local frame = card(tab, description and 50 or 42)
    cardLabels(frame, title, description)
    icon("chevronRight", 16, UDim2.new(1, -30, 0.5, -8), Theme.Muted, frame)
    local hitbox = create("TextButton", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = "",
        Parent = frame,
    })
    track(hitbox.MouseEnter:Connect(function()
        tween(frame, { BackgroundColor3 = Theme.Hover })
    end))
    track(hitbox.MouseLeave:Connect(function()
        tween(frame, { BackgroundColor3 = Theme.Surface })
    end))
    track(hitbox.MouseButton1Click:Connect(callback))
    return frame
end

local Lighting = game:GetService("Lighting")
local popup
local attachDialogDrag = Components.DialogDrag(create, track, function(input)
    beginDrag(input)
end)
local INVITE_URL = "https://discord.gg/" .. DISCORD_CODE

local function closeDiscordPopup()
    if not popup then
        return
    end
    local current = popup
    popup = nil
    TweenService:Create(current.Panel, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = UDim2.new(0.5, -170, 0.5, -78) }):Play()
    tween(current.Overlay, { BackgroundTransparency = 1 }, 0.16)
    tween(current.Blur, { Size = 0 }, 0.16)
    for _, item in ipairs(current.Fade) do
        tween(item[1], { [item[2]] = 1 }, 0.12)
    end
    task.delay(0.16, function()
        current.Overlay:Destroy()
        current.Blur:Destroy()
    end)
end

local function copyInvite()
    if setclipboard then
        pcall(setclipboard, INVITE_URL)
        return true
    end
    return false
end

local function showDiscordPopup()
    if popup then
        return
    end
    local fade = {}
    local function faded(instance, property)
        table.insert(fade, { instance, property })
        return instance
    end

    local blur = create("BlurEffect", { Size = 0, Parent = Lighting })
    local overlay = create("TextButton", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Text = "",
        ZIndex = 10,
        Parent = content,
    }, { corner(10) })

    local panel = faded(create("Frame", {
        Size = UDim2.fromOffset(340, 180),
        Position = UDim2.new(0.5, -170, 0.5, -78),
        BackgroundColor3 = Theme.Window,
        ZIndex = 11,
        Parent = overlay,
    }, { corner(12), stroke(Theme.Border) }), "BackgroundTransparency")

    attachDialogDrag(overlay, panel)

    local dismiss = create("TextButton", {
        Size = UDim2.fromOffset(28, 28),
        Position = UDim2.new(1, -44, 0, 16),
        BackgroundColor3 = Theme.Window,
        AutoButtonColor = false,
        Text = "",
        ZIndex = 12,
        Parent = panel,
    }, { corner(6) })
    local dismissIcon = icon("x", 16, UDim2.fromOffset(6, 6), Theme.Muted, dismiss)
    dismissIcon.ZIndex = 13
    faded(dismissIcon, "ImageTransparency")

    faded(text({
        Size = UDim2.new(1, -48, 0, 22),
        Position = UDim2.fromOffset(24, 22),
        FontFace = Fonts.Bold,
        TextSize = 20,
        Text = "Join Discord?",
        ZIndex = 12,
        Parent = panel,
    }), "TextTransparency")
    faded(text({
        Size = UDim2.new(1, -48, 0, 18),
        Position = UDim2.fromOffset(24, 48),
        TextColor3 = Theme.Muted,
        Text = "Updates, new scripts and support.",
        ZIndex = 12,
        Parent = panel,
    }), "TextTransparency")

    local field = faded(create("TextButton", {
        Size = UDim2.new(1, -48, 0, 36),
        Position = UDim2.fromOffset(24, 80),
        BackgroundColor3 = Theme.Surface,
        AutoButtonColor = false,
        Text = "",
        ZIndex = 12,
        Parent = panel,
    }, { corner(8), stroke(Theme.Border) }), "BackgroundTransparency")
    faded(text({
        Size = UDim2.new(1, -50, 1, 0),
        Position = UDim2.fromOffset(14, 0),
        FontFace = Fonts.Medium,
        Text = "discord.gg/" .. DISCORD_CODE,
        ZIndex = 13,
        Parent = field,
    }), "TextTransparency")
    local fieldCopy = icon("copy", 16, UDim2.new(1, -28, 0, 10), Theme.Muted, field)
    fieldCopy.ZIndex = 13
    faded(fieldCopy, "ImageTransparency")

    local function actionButton(label, x, primary)
        local button = create("TextButton", {
            Size = UDim2.new(0.5, -30, 0, 36),
            Position = UDim2.new(x, x == 0 and 24 or 6, 1, -54),
            BackgroundColor3 = primary and Theme.Accent or Theme.Surface,
            AutoButtonColor = false,
            FontFace = Fonts.Bold,
            TextSize = 14,
            TextColor3 = primary and Theme.OnAccent or Theme.Text,
            Text = label,
            ZIndex = 12,
            Parent = panel,
        }, { corner(8), stroke(primary and Theme.Accent or Theme.Border) })
        faded(button, "BackgroundTransparency")
        faded(button, "TextTransparency")
        track(button.MouseEnter:Connect(function()
            tween(button, { BackgroundColor3 = primary and Theme.Muted or Theme.Hover })
        end))
        track(button.MouseLeave:Connect(function()
            tween(button, { BackgroundColor3 = primary and Theme.Accent or Theme.Surface })
        end))
        return button
    end

    local closeChoice = actionButton("Close", 0, false)
    local copyChoice = actionButton("Copy Invite", 0.5, true)

    local function onCopy()
        local copied = copyInvite()
        copyChoice.Text = copied and "Copied" or "Not supported"
        fieldCopy.Image = copied and Icons.copyCheck or Icons.copy
        fieldCopy.ImageColor3 = copied and Theme.Text or Theme.Muted
    end

    track(closeChoice.MouseButton1Click:Connect(closeDiscordPopup))
    track(dismiss.MouseButton1Click:Connect(closeDiscordPopup))
    track(copyChoice.MouseButton1Click:Connect(onCopy))
    track(field.MouseButton1Click:Connect(onCopy))
    track(dismiss.MouseEnter:Connect(function()
        tween(dismiss, { BackgroundColor3 = Theme.Hover })
        tween(dismissIcon, { ImageColor3 = Theme.Text })
    end))
    track(dismiss.MouseLeave:Connect(function()
        tween(dismiss, { BackgroundColor3 = Theme.Window })
        tween(dismissIcon, { ImageColor3 = Theme.Muted })
    end))
    track(field.MouseEnter:Connect(function()
        tween(field, { BackgroundColor3 = Theme.Hover })
    end))
    track(field.MouseLeave:Connect(function()
        tween(field, { BackgroundColor3 = Theme.Surface })
    end))

    popup = { Overlay = overlay, Panel = panel, Blur = blur, Fade = fade }
    tween(overlay, { BackgroundTransparency = 0.35 }, 0.2)
    tween(blur, { Size = 16 }, 0.2)
    TweenService:Create(panel, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Position = UDim2.new(0.5, -170, 0.5, -90) }):Play()
end


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
            for _, item in ipairs(normalize(options.Values)) do if item.Value == value then valid = true break end end
            assert(valid, "Unknown dropdown value: " .. tostring(value))
            local changed = self.Value ~= value
            self.Value = value
            refresh()
            if changed and not quiet then fire(self) end
            return self
        end
        function control:Refresh() refresh() return self end
    end
    control.Frame.Name = "Dropdown_" .. id
    if options.FireOnInit then fire(control) end
    return control
end
function Tab:AddButton(options, callback)
    if type(options) == "string" then options = { Text = options, Callback = callback } end
    assert(type(options) == "table" and type(options.Callback) == "function", "Button requires a callback")
    local button = {}
    function button:Press() Library:_Call(options.Callback, self) return self end
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
function Hub:Ready()
    if not self.Active or self.Loaded then return self end
    self.Loaded = true
    if config.ShowDiscordPrompt then
        self:ShowDiscordPrompt()
        popup.Blur.Enabled = menu.IsOpen()
        popup.Overlay.Visible = menu.IsOpen()
    end
    screen.Enabled = true
    return self
end
Library.Windows[id] = Hub
if not config.DeferShow then task.defer(function() Hub:Ready() end) end
return Hub

end

end)()
function Library:CreateWindow(config)
    return createWindow(self, config or {}, Components)
end
function Library:Unload()
    local windows = {}
    for _, window in pairs(self.Windows) do table.insert(windows, window) end
    for _, window in ipairs(windows) do window:Unload() end
end
return Library
