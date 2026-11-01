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
