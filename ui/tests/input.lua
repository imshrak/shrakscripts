return function(Library)
    local inputService = game:GetService("UserInputService")
    local runService = game:GetService("RunService")
    local restore = {}
    for _, window in pairs(Library.Windows) do
        if window.Active and window:IsOpen() then table.insert(restore, window) end
    end
    local windows = {}
    local function frame() runService.RenderStepped:Wait() runService.RenderStepped:Wait() end
    local ok, message = xpcall(function()
        for _, window in ipairs(restore) do window:Hide() end
        frame()
        local behavior, iconEnabled = inputService.MouseBehavior, inputService.MouseIconEnabled
        local before, beforeEnded = {}, {}
        if getconnections then
            for _, connection in ipairs(getconnections(inputService.InputBegan)) do
                if connection.Function then before[connection.Function] = true end
            end
            for _, connection in ipairs(getconnections(inputService.InputEnded)) do
                if connection.Function then beforeEnded[connection.Function] = true end
            end
        end
        local first = Library:CreateWindow({ Id = "ShrakUIInputA", DeferShow = true })
        table.insert(windows, first)
        local tab = first:AddTab("Input")
        local events = {}
        local key = tab:AddKeybind("KeyA", { Default = "F", Mode = "Hold", Callback = function(value) table.insert(events, value) end })
        local other = tab:AddKeybind("KeyB", { Default = "G", Mode = "Toggle" })
        first:Ready()
        frame()
        assert(inputService.MouseBehavior == Enum.MouseBehavior.Default and inputService.MouseIconEnabled)
        local second = Library:CreateWindow({ Id = "ShrakUIInputB", DeferShow = true })
        table.insert(windows, second)
        second:AddTab("Other"):AddLabel("Cursor ownership")
        second:Ready()
        first:Hide()
        frame()
        assert(inputService.MouseBehavior == Enum.MouseBehavior.Default and inputService.MouseIconEnabled)
        second:Hide()
        frame()
        assert(inputService.MouseBehavior == behavior and inputService.MouseIconEnabled == iconEnabled)
        if getconnections then
            local callbacks = {}
            for _, connection in ipairs(getconnections(inputService.InputBegan)) do
                if connection.Function and not before[connection.Function] then table.insert(callbacks, connection.Function) end
            end
            local function press(code, processed)
                local input = { KeyCode = Enum.KeyCode[code], UserInputType = Enum.UserInputType.Keyboard, Position = Vector3.zero }
                for _, callback in ipairs(callbacks) do callback(input, processed == true) end
            end
            press("F")
            assert(key.Active and events[#events] == true)
            frame()
            assert(key.Active)
            local release = { KeyCode = Enum.KeyCode.F, UserInputType = Enum.UserInputType.Keyboard, Position = Vector3.zero }
            for _, connection in ipairs(getconnections(inputService.InputEnded)) do
                if connection.Function and not beforeEnded[connection.Function] then connection.Function(release) end
            end
            assert(not key.Active)
            press("F", true)
            assert(not key.Active)
            first:Show()
            frame()
            first.BindingControl = key
            press("G")
            assert(key.Value == "G" and not other.Active)
            press("G")
            assert(key.Active and other.Active)
            key:SetDisabled(true)
            assert(not key.Active)
            first.BindingControl = key
            press("Escape")
            assert(not first.BindingControl and key.Value == "G")
            first.BindingControl = key
            first:Hide()
            frame()
            assert(not first.BindingControl)
        end
        first:Show()
        frame()
        first:Unload()
        frame()
        assert(inputService.MouseBehavior == behavior and inputService.MouseIconEnabled == iconEnabled)
        print("SHRAK_UI_INPUT_PASSED", Library.Version, #events)
    end, debug.traceback)
    for _, window in ipairs(windows) do window:Unload() end
    for _, window in ipairs(restore) do if window.Active then window:Show() end end
    assert(ok, message)
    return true
end
