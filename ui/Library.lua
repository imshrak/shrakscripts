local environment = getgenv and getgenv() or _G
environment.ShrakScriptsUIWindows = environment.ShrakScriptsUIWindows or {}
local Library = {
    Version = "1.1.0",
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
Components.Theme = (function()
return function(palette)
    local bindings = setmetatable({}, { __mode = "k" })
    local animations = setmetatable({}, { __mode = "k" })
    local colors = {}
    for key in pairs(palette) do colors[key] = { ThemeRole = key } end
    function colors:Resolve(instance, properties)
        local result = {}
        local entries = bindings[instance] or {}
        bindings[instance] = entries
        for property, value in pairs(properties) do
            if type(value) == "table" and value.ThemeRole then
                entries[property] = value.ThemeRole
                result[property] = palette[value.ThemeRole]
            else
                entries[property] = nil
                result[property] = value
            end
        end
        return result
    end
    function colors:Set(instance, property, value)
        instance[property] = self:Resolve(instance, { [property] = value })[property]
    end
    function colors:Tween(service, instance, info, goal)
        local animation = service:Create(instance, info, self:Resolve(instance, goal))
        animations[animation] = true
        return animation
    end
    function colors:Refresh()
        for animation in pairs(animations) do animation:Cancel() end
        table.clear(animations)
        for instance, entries in pairs(bindings) do
            if instance.Parent then
                for property, role in pairs(entries) do instance[property] = palette[role] end
            end
        end
    end
    function colors:Cancel()
        for animation in pairs(animations) do animation:Cancel() end
        table.clear(animations)
    end
    return colors
end

end)()
Components.TabHighlight = (function()
return function(TweenService, Theme, tabList, track)
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
    Theme:Set(background, "BackgroundColor3", Theme.Hover)
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
    Theme:Set(highlight, "BackgroundColor3", Theme.Accent)
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
    track(background:GetPropertyChangedSignal("Position"):Connect(alignIndicator))
    track(background:GetPropertyChangedSignal("Size"):Connect(alignIndicator))

    local current, motion
    local function refresh()
        task.defer(function()
            if not current or not tabList.Parent then return end
            if motion then motion:Cancel() end
            local position = current.Button.AbsolutePosition - tabList.AbsolutePosition
            background.Position = UDim2.fromOffset(position.X, position.Y)
            background.Size = current.Button.Size
        end)
    end
    track(tabList:GetPropertyChangedSignal("CanvasPosition"):Connect(refresh))
    track(tabList:GetPropertyChangedSignal("AbsoluteSize"):Connect(refresh))
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
return function(create, text, corner, stroke, icon, track, tween, Theme, card, cardLabels, attachDismiss, touch)
    return function(tab, title, getOptions, getValue, onChange)
        local HEAD, ROW = touch and 56 or 42, touch and 40 or 28
        local frame = card(tab, HEAD)
        frame.Name = "SingleSelect"
        frame.ClipsDescendants = true
        local titleLabel = cardLabels(frame, title)
        if touch then
            titleLabel.Size = UDim2.new(1, -48, 0, 16)
            titleLabel.Position = UDim2.fromOffset(14, 8)
            titleLabel.TextWrapped = false
        end
        local summary = text({
            Size = touch and UDim2.new(1, -48, 0, 16) or UDim2.fromOffset(170, 16),
            Position = touch and UDim2.fromOffset(14, 30) or UDim2.new(1, -206, 0, 13),
            TextColor3 = Theme.Muted,
            TextXAlignment = touch and Enum.TextXAlignment.Left or Enum.TextXAlignment.Right,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = frame,
        })
        local chevron = icon("chevronDown", 16, UDim2.new(1, -30, 0, HEAD / 2 - 8), Theme.Muted, frame)
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
            ScrollingDirection = Enum.ScrollingDirection.Y,
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
                Theme:Set(rows[index].Box, "BackgroundColor3", active and Theme.Accent or Theme.Surface)
                Theme:Set(rows[index].Box.UIStroke, "Color", active and Theme.Accent or Theme.Faint)
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
                body.Size = UDim2.new(1, -16, 0, math.min(#options, touch and 4 or 6) * ROW)
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
                        Position = UDim2.fromOffset(8, (ROW - 14) / 2),
                        BackgroundColor3 = Theme.Surface,
                        Parent = row,
                    }, { corner(3), stroke(Theme.Faint) })
                    local mark = icon("check", 12, UDim2.fromOffset(1, 1), Theme.OnAccent, box)
                    text({ Size = UDim2.new(1, -40, 1, 0), Position = UDim2.fromOffset(32, 0), Text = option.Name, Parent = row })
                    rows[index] = { Box = box, Mark = mark }
                    track(row.MouseEnter:Connect(function() tween(row, { BackgroundTransparency = 0 }) end))
                    track(row.MouseLeave:Connect(function() tween(row, { BackgroundTransparency = 1 }) end))
                    track(row.Activated:Connect(function()
                        onChange(option.Value)
                        updateSelection()
                        setOpen(false)
                    end))
                end
            end
            updateSelection()
        end
        track(head.Activated:Connect(function()
            if not open then refresh() end
            setOpen(not open)
        end))
        attachDismiss(frame, tab.ScrollPage or tab.Page, function() return open end, setOpen)
        refresh()
        return frame, refresh
    end
end

end)()
Components.DialogDrag = (function()
return function(create, track, beginDrag, touch)
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
        addHandle(overlay, UDim2.new(1, touch and -100 or -84, 0, 48))
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
    group.Visible = false
    group.Parent = window

    local function directContent()
        content.Parent = window
        content.Position = group.Position
        group.Visible = false
    end
    local function fadeContent()
        if content.Parent ~= group then
            content.Parent = group
            content.Position = UDim2.new()
        end
        group.Visible = true
    end

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
        local animation = Theme:Tween(TweenService, object, TweenInfo.new(duration, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out), goal)
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
        Theme:Set(window, "BackgroundColor3", Theme.Surface)
        window.BackgroundTransparency = button.BackgroundTransparency
        corner.CornerRadius = buttonCorner.CornerRadius
        Theme:Set(outline, "Color", Theme.Border)
        outline.Thickness = 1
        outline.Transparency = 0
    end

    if desired then
        window.Size = expandedSize
        window.Position = openPosition
        Theme:Set(window, "BackgroundColor3", Theme.Window)
        corner.CornerRadius = UDim.new(0, 10)
        group.GroupTransparency = 0
        content.Visible = true
        window.Visible = true
        button.Visible = false
        directContent()
    else
        closedAppearance()
        group.GroupTransparency = 1
        content.Visible = false
        window.Visible = false
        button.Visible = true
        popupVisible(false)
        directContent()
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
        fadeContent()
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
                directContent()
            else
                state = "closed"
                closedAppearance()
                content.Visible = false
                window.Visible = false
                button.Visible = true
                directContent()
            end
        end)
    end
    function controller.Toggle()
        controller.SetOpen(not desired)
    end
    function controller.IsOpen()
        return desired
    end
    function controller.GetExpandedSize() return expandedSize end
    function controller.GetExpandedPosition() return state == "open" and window.Position or openPosition end
    function controller.CanDrag() return state == "open" end
    function controller.SetLayout(size, position)
        expandedSize, openPosition = size, position
        group.Size = size
        serial += 1
        for _, animation in ipairs(tweens) do animation:Cancel() end
        table.clear(tweens)
        ghost.Visible = false
        if desired then
            state = "open"
            window.Size, window.Position = size, position
            Theme:Set(window, "BackgroundColor3", Theme.Window)
            window.BackgroundTransparency = 0
            corner.CornerRadius = UDim.new(0, 10)
            group.GroupTransparency = 0
            content.Visible, window.Visible, button.Visible = true, true, false
        else
            state = "closed"
            closedAppearance()
            group.GroupTransparency = 1
            content.Visible, window.Visible, button.Visible = false, false, true
        end
        popupVisible(desired)
        directContent()
    end
    return controller
end

end)()
Components.LauncherControls = (function()
return function(button, UserInputService, track, activate)
    local drag
    local suppressUntil = 0
    local function began(input)
        if not drag and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            drag = { Input = input, Position = input.Position, Start = button.Position, Moved = false }
        end
    end
    local function changed(input)
        if drag and (drag.Input.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseMovement or input == drag.Input) then
            local delta = input.Position - drag.Position
            if delta.Magnitude > 4 then drag.Moved = true end
            if drag.Moved then
                button.Position = UDim2.fromOffset(math.floor(drag.Start.X.Offset + delta.X), math.floor(drag.Start.Y.Offset + delta.Y))
            end
        end
    end
    local function ended(input)
        if drag and (drag.Input.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseButton1 or input == drag.Input) then
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
    track(UserInputService.WindowFocusReleased:Connect(function() drag = nil end))
    track(button.Activated:Connect(clicked))
    return { Began = began, Changed = changed, Ended = ended, Click = clicked }
end

end)()
Components.Launcher = (function()
return function(button, label, TweenService, track, applyLogo, logoData, Theme)
    local palette = Theme or { Surface = Color3.fromRGB(17, 17, 17), Hover = Color3.fromRGB(26, 26, 26), Border = Color3.fromRGB(38, 38, 38), Text = Color3.fromRGB(245, 245, 245) }
    button.Name = "MenuButton"
    button.Size = UDim2.fromOffset(52, 52)
    palette:Set(button, "BackgroundColor3", palette.Surface)
    button.BackgroundTransparency = 0
    button.BorderSizePixel = 0
    button.AutoButtonColor = false
    button:FindFirstChildWhichIsA("UICorner").CornerRadius = UDim.new(0, 16)
    local outline = button:FindFirstChildWhichIsA("UIStroke")
    palette:Set(outline, "Color", palette.Border)
    outline.Thickness = 1
    outline.Transparency = 0
    label.Name = "LauncherLogo"
    label.Position = UDim2.fromOffset(8, 8)
    label.Size = UDim2.fromOffset(36, 36)
    label.Font = Enum.Font.GothamBlack
    label.Text = "S"
    label.TextSize = 38
    palette:Set(label, "TextColor3", palette.Text)
    label.Visible = true
    local mark = applyLogo and applyLogo(button, label, logoData) or label
    if mark:IsA("ImageLabel") then palette:Set(mark, "ImageColor3", palette.Text) end

    track(button.MouseEnter:Connect(function()
        palette:Tween(TweenService, button, TweenInfo.new(0.12), { BackgroundColor3 = palette.Hover }):Play()
    end))
    track(button.MouseLeave:Connect(function()
        palette:Tween(TweenService, button, TweenInfo.new(0.12), { BackgroundColor3 = palette.Surface }):Play()
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
Components.Drag = (function()
return function(UserInputService, track, getPosition, setPosition, canDrag)
    local drag
    local function began(input)
        if drag or canDrag and not canDrag() then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            drag = { Input = input, Point = input.Position, Position = getPosition() }
        end
    end
    local function changed(input)
        if not drag then return end
        local mouse = drag.Input.UserInputType == Enum.UserInputType.MouseButton1
        if mouse and input.UserInputType == Enum.UserInputType.MouseMovement or not mouse and input == drag.Input then
            setPosition(drag.Position + Vector2.new(input.Position.X - drag.Point.X, input.Position.Y - drag.Point.Y))
        end
    end
    local function ended(input)
        if drag and (input == drag.Input or drag.Input.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseButton1) then
            drag = nil
        end
    end
    track(UserInputService.InputChanged:Connect(changed))
    track(UserInputService.InputEnded:Connect(ended))
    track(UserInputService.WindowFocusReleased:Connect(function() drag = nil end))
    return { Begin = began, Change = changed, End = ended }
end

end)()
Components.Responsive = (function()
return function(screen, window, menu, config, track, resizeContent)
    local controller = {}
    function controller.Bounds()
        local bounds = screen.AbsoluteSize
        if bounds.X <= 0 or bounds.Y <= 0 then
            local camera = workspace.CurrentCamera
            return camera and camera.ViewportSize or Vector2.new(1280, 720)
        end
        return bounds
    end
    function controller.Clamp(point, size, bounds)
        bounds = bounds or controller.Bounds()
        local marginX = math.min(8, math.max(0, (bounds.X - size.X) / 2))
        local marginY = math.min(8, math.max(0, (bounds.Y - size.Y) / 2))
        return Vector2.new(
            math.floor(math.clamp(point.X, marginX, math.max(marginX, bounds.X - size.X - marginX))),
            math.floor(math.clamp(point.Y, marginY, math.max(marginY, bounds.Y - size.Y - marginY)))
        )
    end
    function controller.Position()
        local point, bounds = window.Position, controller.Bounds()
        return Vector2.new(point.X.Scale * bounds.X + point.X.Offset, point.Y.Scale * bounds.Y + point.Y.Offset)
    end
    function controller.Move(point)
        local size = menu.GetExpandedSize()
        point = controller.Clamp(point, Vector2.new(size.X.Offset, size.Y.Offset))
        window.Position = UDim2.fromOffset(point.X, point.Y)
    end
    function controller.Refresh(bounds)
        if not window.Parent then return end
        bounds = bounds or controller.Bounds()
        local width = math.min(config.Width or 560, math.max(1, bounds.X - 16))
        local height = math.min(config.Height or 400, math.max(1, bounds.Y - 16))
        local position = menu.GetExpandedPosition()
        local point = controller.Clamp(Vector2.new(position.X.Scale * bounds.X + position.X.Offset, position.Y.Scale * bounds.Y + position.Y.Offset), Vector2.new(width, height), bounds)
        resizeContent(width, height)
        menu.SetLayout(UDim2.fromOffset(width, height), UDim2.fromOffset(point.X, point.Y))
    end
    track(screen:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() controller.Refresh() end))
    controller.Refresh()
    return controller
end

end)()
local createWindow = (function()
return function(Library, config, Components)
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local environment = getgenv and getgenv() or _G
local id = config.Id or "ShrakScriptsUI"
if Library.Windows[id] then Library.Windows[id]:Unload() end
local Hub = { Active = true, Toggles = {}, Options = {}, Controls = {}, Tabs = {}, UnloadCallbacks = {} }
local connections = {}
local beginDrag
local TOUCH = config.Mobile == true or config.Mobile == nil and UserInputService.TouchEnabled
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

local Colors = Components.Theme(Theme)

local Fonts = {
    Regular = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Regular),
    Medium = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Medium),
    Bold = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold),
}

local function create(className, properties, children)
    local instance = Instance.new(className)
    for key, value in pairs(Colors:Resolve(instance, properties)) do
        instance[key] = value
    end
    for _, child in ipairs(children or {}) do
        child.Parent = instance
    end
    if instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
        instance:SetAttribute("BaseTextSize", instance.TextSize)
        if config.TextScale then instance.TextSize = math.round(instance.TextSize * config.TextScale) end
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
    properties.TextColor3 = properties.TextColor3 or Colors.Text
    properties.TextXAlignment = properties.TextXAlignment or Enum.TextXAlignment.Left
    return create("TextLabel", properties)
end

local function tween(instance, goal, duration)
    Colors:Tween(TweenService, instance, TweenInfo.new(duration or 0.14, Enum.EasingStyle.Quad), goal):Play()
end

local Icons = Components.Icons
local function icon(name, size, position, color, parent)
    return create("ImageLabel", {
        Size = UDim2.fromOffset(size, size),
        Position = position,
        BackgroundTransparency = 1,
        Image = Icons[name],
        ImageColor3 = color or Colors.Muted,
        ScaleType = Enum.ScaleType.Fit,
        Parent = parent,
    })
end

local camera = Workspace.CurrentCamera
local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
local WIDTH = math.min(config.Width or 560, math.max(1, viewport.X - 16))
local HEIGHT = math.min(config.Height or 400, math.max(1, viewport.Y - 16))
local SIDEBAR = WIDTH < 500 and 112 or 156

local screen = create("ScreenGui", {
    Name = id,
    Enabled = false,
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    Parent = config.Parent or Players.LocalPlayer:WaitForChild("PlayerGui"),
})

local window = create("Frame", {
    Size = UDim2.fromOffset(WIDTH, HEIGHT),
    Position = config.Position or UDim2.fromOffset(math.floor((viewport.X - WIDTH) / 2), math.floor((viewport.Y - HEIGHT) / 2)),
    BackgroundColor3 = Colors.Window,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    Parent = screen,
}, { corner(10), stroke(Colors.Border) })

local content = create("Frame", {
    Size = UDim2.fromOffset(WIDTH, HEIGHT),
    BackgroundTransparency = 1,
    Parent = window,
})

local sidebar = create("Frame", {
    Size = UDim2.new(0, SIDEBAR, 1, 0),
    BackgroundColor3 = Colors.Sidebar,
    BorderSizePixel = 0,
    Parent = content,
}, { corner(10) })

create("Frame", {
    Size = UDim2.new(0, 12, 1, 0),
    Position = UDim2.new(1, -12, 0, 0),
    BackgroundColor3 = Colors.Sidebar,
    BorderSizePixel = 0,
    Parent = sidebar,
})

create("Frame", {
    Size = UDim2.new(0, 1, 1, 0),
    Position = UDim2.new(1, 0, 0, 0),
    BackgroundColor3 = Colors.Border,
    BorderSizePixel = 0,
    Parent = sidebar,
})

local header = create("Frame", {
    Size = UDim2.new(1, 0, 0, 58),
    BackgroundTransparency = 1,
    Parent = sidebar,
})

local windowTitle = text({
    Size = UDim2.new(1, WIDTH < 500 and -24 or -32, 0, 18),
    Position = UDim2.fromOffset(WIDTH < 500 and 12 or 16, 14),
    FontFace = Fonts.Bold,
    TextSize = WIDTH < 500 and 14 or 16,
    TextTruncate = Enum.TextTruncate.AtEnd,
    Text = config.Title or "ShrakScripts",
    Parent = header,
})

local windowSubtitle = text({
    Size = UDim2.new(1, WIDTH < 500 and -24 or -32, 0, 14),
    Position = UDim2.fromOffset(WIDTH < 500 and 12 or 16, 33),
    TextSize = 12,
    TextColor3 = Colors.Faint,
    Text = config.Subtitle or "ShrakScripts UI",
    TextTruncate = Enum.TextTruncate.AtEnd,
    Parent = header,
})

local tabArea = create("Frame", {
    Size = UDim2.new(1, -16, 1, -66),
    Position = UDim2.fromOffset(8, 62),
    BackgroundTransparency = 1,
    ClipsDescendants = true,
    Parent = sidebar,
})
local tabList = create("ScrollingFrame", {
    Name = "TabList",
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 0,
    CanvasSize = UDim2.new(),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ScrollingDirection = Enum.ScrollingDirection.Y,
    Parent = tabArea,
}, { create("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }) })

local topBar = create("Frame", {
    Size = UDim2.new(1, -SIDEBAR - 1, 0, 48),
    Position = UDim2.fromOffset(SIDEBAR + 1, 0),
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
        Size = UDim2.fromOffset(TOUCH and 40 or 26, TOUCH and 40 or 26),
        Position = UDim2.new(1, offset, 0, TOUCH and 4 or 11),
        BackgroundColor3 = Colors.Window,
        AutoButtonColor = false,
        Text = "",
        Parent = topBar,
    }, { corner(6) })
    local glyph = icon(iconName, 16, UDim2.fromOffset(TOUCH and 12 or 5, TOUCH and 12 or 5), Colors.Muted, button)
    track(button.MouseEnter:Connect(function()
        tween(button, { BackgroundColor3 = Colors.Hover })
        tween(glyph, { ImageColor3 = hoverColor or Colors.Text })
    end))
    track(button.MouseLeave:Connect(function()
        tween(button, { BackgroundColor3 = Colors.Window })
        tween(glyph, { ImageColor3 = Colors.Muted })
    end))
    return button
end

local closeButton = windowButton(TOUCH and -48 or -38, "x")
local minimizeButton = windowButton(TOUCH and -92 or -68, "minus")

local headerBorder = create("Frame", {
    Size = UDim2.new(1, -SIDEBAR - 1, 0, 1),
    Position = UDim2.fromOffset(SIDEBAR + 1, 48),
    BackgroundColor3 = Colors.Border,
    BorderSizePixel = 0,
    Parent = content,
})

local pages = create("Frame", {
    Size = UDim2.new(1, -SIDEBAR - 1, 1, -49),
    Position = UDim2.fromOffset(SIDEBAR + 1, 49),
    BackgroundTransparency = 1,
    Parent = content,
})

local tabs = {}
local moveTabHighlight = Components.TabHighlight(TweenService, Colors, tabList, track)

local function selectTab(target)
    Hub.SelectedTab = target
    for _, tab in ipairs(tabs) do
        local active = tab == target
        tab.Page.Visible = active
        tab.Button.BackgroundTransparency = 1
        tween(tab.Label, { TextColor3 = active and Colors.Text or Colors.Muted })
        tab.Indicator.Visible = false
        tween(tab.Icon, { ImageColor3 = active and Colors.Text or Colors.Muted })
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
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ScrollBarImageColor3 = Colors.Border,
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
        Size = UDim2.new(1, 0, 0, TOUCH and 44 or 34),
        BackgroundColor3 = Colors.Hover,
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Text = "",
        LayoutOrder = #tabs,
        Parent = tabList,
    }, { corner(6) })
    local indicator = create("Frame", {
        Size = UDim2.fromOffset(2, 16),
        Position = UDim2.fromOffset(0, 9),
        BackgroundColor3 = Colors.Accent,
        BorderSizePixel = 0,
        Visible = false,
        Parent = button,
    }, { corner(1) })
    local tabIcon = icon(iconName, 16, UDim2.new(0, 12, 0.5, -8), Colors.Muted, button)
    local label = text({
        Size = UDim2.new(1, -44, 1, 0),
        Position = UDim2.fromOffset(38, 0),
        FontFace = Fonts.Medium,
        TextSize = TOUCH and 13 or 14,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextColor3 = Colors.Muted,
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
    track(button.Activated:Connect(function()
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
        TextColor3 = Colors.Faint,
        Text = string.upper(title),
        Parent = holder,
    })
end

local function card(tab, height)
    local frame = create("Frame", {
        Size = UDim2.new(1, 0, 0, height),
        BackgroundColor3 = Colors.Surface,
        BorderSizePixel = 0,
        LayoutOrder = nextOrder(tab),
        Parent = tab.Page,
    }, { corner(8), stroke(Colors.Border) })
    return frame
end

local function cardLabels(frame, title, description)
    local label = text({
        Size = TOUCH and not description and UDim2.new(1, -76, 1, 0) or UDim2.new(1, -90, 0, 16),
        Position = UDim2.fromOffset(14, TOUCH and not description and 0 or description and 9 or 13),
        FontFace = Fonts.Medium,
        TextSize = TOUCH and 13 or 14,
        TextWrapped = TOUCH and not description,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Text = title,
        Parent = frame,
    })
    if description then
        text({
            Size = UDim2.new(1, -90, 0, 14),
            Position = UDim2.fromOffset(14, 26),
            TextSize = 12,
            TextColor3 = Colors.Muted,
            Text = description,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = frame,
        })
    end
    return label
end

local resetters = {}

local function addToggle(tab, title, onChange)
    local frame = card(tab, TOUCH and 48 or 42)
    cardLabels(frame, title)
    local switch = create("Frame", {
        Size = UDim2.fromOffset(34, 18),
        Position = UDim2.new(1, -48, 0.5, -9),
        BackgroundColor3 = Colors.Border,
        Parent = frame,
    }, { round() })
    local knob = create("Frame", {
        Size = UDim2.fromOffset(14, 14),
        Position = UDim2.fromOffset(2, 2),
        BackgroundColor3 = Colors.Muted,
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
        tween(switch, { BackgroundColor3 = value and Colors.Accent or Colors.Border })
        tween(knob, {
            Position = UDim2.fromOffset(value and 18 or 2, 2),
            BackgroundColor3 = value and Colors.OnAccent or Colors.Muted,
        })
        onChange(value)
    end
    track(hitbox.Activated:Connect(function()
        set(not enabled)
    end))
    track(hitbox.MouseEnter:Connect(function()
        tween(frame, { BackgroundColor3 = Colors.Hover })
    end))
    track(hitbox.MouseLeave:Connect(function()
        tween(frame, { BackgroundColor3 = Colors.Surface })
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
    local scrollPage = tab.ScrollPage or tab.Page
    local frame = card(tab, TOUCH and 66 or 58)
    local titleLabel = cardLabels(frame, title)
    titleLabel.Size = UDim2.new(1, -100, 0, 16)
    titleLabel.Position = UDim2.fromOffset(14, 13)
    titleLabel.TextWrapped = false
    local valueLabel = text({
        Size = UDim2.fromOffset(80, 16),
        Position = UDim2.new(1, -94, 0, 13),
        FontFace = Fonts.Medium,
        TextColor3 = Colors.Muted,
        TextXAlignment = Enum.TextXAlignment.Right,
        Text = tostring(value),
        Parent = frame,
    })
    local bar = create("Frame", {
        Size = UDim2.new(1, -28, 0, 4),
        Position = UDim2.fromOffset(14, 40),
        BackgroundColor3 = Colors.Border,
        BorderSizePixel = 0,
        Parent = frame,
    }, { round() })
    local fill = create("Frame", {
        Size = UDim2.fromScale((value - min) / (max - min), 1),
        BackgroundColor3 = Colors.Accent,
        BorderSizePixel = 0,
        Parent = bar,
    }, { round() })
    local knob = create("Frame", {
        Size = UDim2.fromOffset(12, 12),
        Position = UDim2.new((value - min) / (max - min), -6, 0.5, -6),
        BackgroundColor3 = Colors.Accent,
        Parent = bar,
    }, { round(), stroke(Colors.Window, 2) })
    local hitbox = create("TextButton", {
        Size = UDim2.new(1, 0, 0, TOUCH and 40 or 24),
        Position = UDim2.fromOffset(0, TOUCH and 26 or 30),
        BackgroundTransparency = 1,
        Text = "",
        Parent = frame,
    })
    local dragInput, scrolling
    local function update(x)
        local alpha = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local scale = 10 ^ (rounding or 0)
        local result = math.clamp(math.round((min + (max - min) * alpha) * scale) / scale, min, max)
        alpha = (result - min) / (max - min)
        fill.Size = UDim2.fromScale(alpha, 1)
        knob.Position = UDim2.new(alpha, -6, 0.5, -6)
        valueLabel.Text = tostring(result)
        onChange(result)
    end
    track(hitbox.InputBegan:Connect(function(input)
        if not dragInput and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            dragInput = input
            scrolling = scrollPage.ScrollingEnabled
            scrollPage.ScrollingEnabled = false
            update(input.Position.X)
        end
    end))
    track(UserInputService.InputChanged:Connect(function(input)
        if dragInput and (dragInput.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseMovement or input == dragInput) then
            update(input.Position.X)
        end
    end))
    track(UserInputService.InputEnded:Connect(function(input)
        if dragInput and (input == dragInput or dragInput.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseButton1) then
            dragInput = nil
            scrollPage.ScrollingEnabled = scrolling
        end
    end))
    track(UserInputService.WindowFocusReleased:Connect(function()
        if dragInput then dragInput = nil scrollPage.ScrollingEnabled = scrolling end
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
    local ROW, HEAD = TOUCH and 40 or 28, TOUCH and 56 or 42
    local listHeight = #options * ROW + (TOUCH and 56 or 44)
    local frame = card(tab, HEAD)
    frame.ClipsDescendants = true
    local titleLabel = cardLabels(frame, title)
    if TOUCH then
        titleLabel.Size = UDim2.new(1, -48, 0, 16)
        titleLabel.Position = UDim2.fromOffset(14, 8)
        titleLabel.TextWrapped = false
    end
    local summary = text({
        Size = TOUCH and UDim2.new(1, -48, 0, 16) or UDim2.fromOffset(170, 16),
        Position = TOUCH and UDim2.fromOffset(14, 30) or UDim2.new(1, -206, 0, 13),
        TextColor3 = Colors.Muted,
        TextXAlignment = TOUCH and Enum.TextXAlignment.Left or Enum.TextXAlignment.Right,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = frame,
    })
    local chevron = icon("chevronDown", 16, UDim2.new(1, -30, 0, HEAD / 2 - 8), Colors.Muted, frame)
    local headButton = create("TextButton", {
        Size = UDim2.new(1, 0, 0, HEAD),
        BackgroundTransparency = 1,
        Text = "",
        Parent = frame,
    })
    create("Frame", {
        Size = UDim2.new(1, -28, 0, 1),
        Position = UDim2.fromOffset(14, HEAD),
        BackgroundColor3 = Colors.Border,
        BorderSizePixel = 0,
        Parent = frame,
    })
    local checks = {}
    local function refresh()
        local names = {}
        for _, option in ipairs(options) do
            local on = selected[option.Name] == true
            local check = checks[option.Name]
            Colors:Set(check.Box, "BackgroundColor3", on and Colors.Accent or Colors.Surface)
            Colors:Set(check.Box.UIStroke, "Color", on and Colors.Accent or Colors.Faint)
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
            BackgroundColor3 = Colors.Hover,
            BackgroundTransparency = 1,
            AutoButtonColor = false,
            Text = "",
            Parent = frame,
        }, { corner(5) })
        local box = create("Frame", {
            Size = UDim2.fromOffset(14, 14),
            Position = UDim2.fromOffset(8, (ROW - 14) / 2),
            BackgroundColor3 = Colors.Surface,
            Parent = row,
        }, { corner(3), stroke(Colors.Faint) })
        local mark = icon("check", 12, UDim2.fromOffset(1, 1), Colors.OnAccent, box)
        mark.Visible = false
        create("Frame", {
            Size = UDim2.fromOffset(6, 6),
            Position = UDim2.fromOffset(32, (ROW - 6) / 2),
            BackgroundColor3 = option.Color or Colors.Muted,
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
        track(row.Activated:Connect(function()
            selected[option.Name] = not selected[option.Name] or nil
            refresh()
            if onChange then onChange(selected) end
        end))
    end
    local function quickButton(label, x, callback)
        local button = create("TextButton", {
            Size = UDim2.fromOffset(64, TOUCH and 40 or 24),
            Position = UDim2.fromOffset(x, HEAD + 10 + #options * ROW),
            BackgroundColor3 = Colors.Hover,
            AutoButtonColor = false,
            FontFace = Fonts.Medium,
            TextSize = 13,
            TextColor3 = Colors.Text,
            Text = label,
            Parent = frame,
        }, { corner(5) })
        track(button.Activated:Connect(function()
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
    track(headButton.Activated:Connect(function()
        open = not open
        tween(frame, { Size = UDim2.new(1, 0, 0, open and HEAD + listHeight or HEAD) }, 0.18)
        tween(chevron, { Rotation = open and 180 or 0 }, 0.18)
    end))
    Components.DropdownDismiss(UserInputService, track)(frame, tab.ScrollPage or tab.Page, function() return open end, function(value)
        open = value
        tween(frame, { Size = UDim2.new(1, 0, 0, open and HEAD + listHeight or HEAD) }, 0.18)
        tween(chevron, { Rotation = open and 180 or 0 }, 0.18)
    end)
    refresh()
    return frame, refresh
end

local attachDropdownDismiss = Components.DropdownDismiss(UserInputService, track)
local addSingleSelect = Components.SingleSelect(create, text, corner, stroke, icon, track, tween, Colors, card, cardLabels, attachDropdownDismiss, TOUCH)

local function addButton(tab, title, description, callback)
    local frame = card(tab, TOUCH and (description and 58 or 48) or (description and 50 or 42))
    cardLabels(frame, title, description)
    icon("chevronRight", 16, UDim2.new(1, -30, 0.5, -8), Colors.Muted, frame)
    local hitbox = create("TextButton", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = "",
        Parent = frame,
    })
    track(hitbox.MouseEnter:Connect(function()
        tween(frame, { BackgroundColor3 = Colors.Hover })
    end))
    track(hitbox.MouseLeave:Connect(function()
        tween(frame, { BackgroundColor3 = Colors.Surface })
    end))
    track(hitbox.Activated:Connect(callback))
    return frame
end

local Lighting = game:GetService("Lighting")
local popup
local attachDialogDrag = Components.DialogDrag(create, track, function(input)
    beginDrag(input)
end, TOUCH)
local INVITE_URL = "https://discord.gg/" .. DISCORD_CODE

local function closeDiscordPopup()
    if not popup then
        return
    end
    local current = popup
    popup = nil
    TweenService:Create(current.Panel, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = UDim2.new(0.5, 0, 0.5, 12) }):Play()
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
        Size = UDim2.fromOffset(math.min(340, WIDTH - 32), 180),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 12),
        BackgroundColor3 = Colors.Window,
        ZIndex = 11,
        Parent = overlay,
    }, { corner(12), stroke(Colors.Border) }), "BackgroundTransparency")

    attachDialogDrag(overlay, panel)

    local dismiss = create("TextButton", {
        Size = UDim2.fromOffset(TOUCH and 40 or 28, TOUCH and 40 or 28),
        Position = UDim2.new(1, TOUCH and -48 or -44, 0, TOUCH and 8 or 16),
        BackgroundColor3 = Colors.Window,
        AutoButtonColor = false,
        Text = "",
        ZIndex = 12,
        Parent = panel,
    }, { corner(6) })
    local dismissIcon = icon("x", 16, UDim2.fromOffset(TOUCH and 12 or 6, TOUCH and 12 or 6), Colors.Muted, dismiss)
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
        TextColor3 = Colors.Muted,
        Text = "Updates, new scripts and support.",
        ZIndex = 12,
        Parent = panel,
    }), "TextTransparency")

    local field = faded(create("TextButton", {
        Size = UDim2.new(1, -48, 0, 36),
        Position = UDim2.fromOffset(24, 80),
        BackgroundColor3 = Colors.Surface,
        AutoButtonColor = false,
        Text = "",
        ZIndex = 12,
        Parent = panel,
    }, { corner(8), stroke(Colors.Border) }), "BackgroundTransparency")
    faded(text({
        Size = UDim2.new(1, -50, 1, 0),
        Position = UDim2.fromOffset(14, 0),
        FontFace = Fonts.Medium,
        Text = "discord.gg/" .. DISCORD_CODE,
        ZIndex = 13,
        Parent = field,
    }), "TextTransparency")
    local fieldCopy = icon("copy", 16, UDim2.new(1, -28, 0, 10), Colors.Muted, field)
    fieldCopy.ZIndex = 13
    faded(fieldCopy, "ImageTransparency")

    local function actionButton(label, x, primary)
        local button = create("TextButton", {
            Size = UDim2.new(0.5, -30, 0, 36),
            Position = UDim2.new(x, x == 0 and 24 or 6, 1, -54),
            BackgroundColor3 = primary and Colors.Accent or Colors.Surface,
            AutoButtonColor = false,
            FontFace = Fonts.Bold,
        TextSize = TOUCH and 13 or 14,
            TextColor3 = primary and Colors.OnAccent or Colors.Text,
            Text = label,
            ZIndex = 12,
            Parent = panel,
        }, { corner(8), stroke(primary and Colors.Accent or Colors.Border) })
        faded(button, "BackgroundTransparency")
        faded(button, "TextTransparency")
        track(button.MouseEnter:Connect(function()
            tween(button, { BackgroundColor3 = primary and Colors.Muted or Colors.Hover })
        end))
        track(button.MouseLeave:Connect(function()
            tween(button, { BackgroundColor3 = primary and Colors.Accent or Colors.Surface })
        end))
        return button
    end

    local closeChoice = actionButton("Close", 0, false)
    local copyChoice = actionButton("Copy Invite", 0.5, true)

    local function onCopy()
        local copied = copyInvite()
        copyChoice.Text = copied and "Copied" or "Not supported"
        fieldCopy.Image = copied and Icons.copyCheck or Icons.copy
        Colors:Set(fieldCopy, "ImageColor3", copied and Colors.Text or Colors.Muted)
    end

    track(closeChoice.Activated:Connect(closeDiscordPopup))
    track(dismiss.Activated:Connect(closeDiscordPopup))
    track(copyChoice.Activated:Connect(onCopy))
    track(field.Activated:Connect(onCopy))
    track(dismiss.MouseEnter:Connect(function()
        tween(dismiss, { BackgroundColor3 = Colors.Hover })
        tween(dismissIcon, { ImageColor3 = Colors.Text })
    end))
    track(dismiss.MouseLeave:Connect(function()
        tween(dismiss, { BackgroundColor3 = Colors.Window })
        tween(dismissIcon, { ImageColor3 = Colors.Muted })
    end))
    track(field.MouseEnter:Connect(function()
        tween(field, { BackgroundColor3 = Colors.Hover })
    end))
    track(field.MouseLeave:Connect(function()
        tween(field, { BackgroundColor3 = Colors.Surface })
    end))

    popup = { Overlay = overlay, Panel = panel, Blur = blur, Fade = fade }
    tween(overlay, { BackgroundTransparency = 0.35 }, 0.2)
    tween(blur, { Size = 16 }, 0.2)
    TweenService:Create(panel, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Position = UDim2.fromScale(0.5, 0.5) }):Play()
end

local function resizeContent(width, height)
    WIDTH, HEIGHT = width, height
    SIDEBAR = width < 500 and 112 or 156
    content.Size = UDim2.fromOffset(width, height)
    sidebar.Size = UDim2.new(0, SIDEBAR, 1, 0)
    topBar.Size = UDim2.new(1, -SIDEBAR - 1, 0, 48)
    topBar.Position = UDim2.fromOffset(SIDEBAR + 1, 0)
    headerBorder.Size = UDim2.new(1, -SIDEBAR - 1, 0, 1)
    headerBorder.Position = UDim2.fromOffset(SIDEBAR + 1, 48)
    pages.Size = UDim2.new(1, -SIDEBAR - 1, 1, -49)
    pages.Position = UDim2.fromOffset(SIDEBAR + 1, 49)
    windowTitle:SetAttribute("BaseTextSize", width < 500 and 14 or 16)
    windowTitle.TextSize = math.round((width < 500 and 14 or 16) * (config.TextScale or 1))
    windowTitle.Size = UDim2.new(1, width < 500 and -24 or -32, 0, 18)
    windowTitle.Position = UDim2.fromOffset(width < 500 and 12 or 16, 14)
    windowSubtitle.Size = UDim2.new(1, width < 500 and -24 or -32, 0, 14)
    windowSubtitle.Position = UDim2.fromOffset(width < 500 and 12 or 16, 33)
    if popup then popup.Panel.Size = UDim2.fromOffset(math.min(340, width - 32), 180) end
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
