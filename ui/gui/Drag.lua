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
