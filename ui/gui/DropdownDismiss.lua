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
