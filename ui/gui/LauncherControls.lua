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
