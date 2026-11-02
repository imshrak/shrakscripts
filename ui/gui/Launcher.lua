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
