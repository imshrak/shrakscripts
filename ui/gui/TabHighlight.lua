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
