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
