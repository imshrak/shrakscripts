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
