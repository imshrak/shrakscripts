return function(create, text, corner, stroke, icon, track, tween, Theme, card, cardLabels, attachDismiss)
    return function(tab, title, getOptions, getValue, onChange)
        local HEAD, ROW = 42, 28
        local frame = card(tab, HEAD)
        frame.Name = "SingleSelect"
        frame.ClipsDescendants = true
        cardLabels(frame, title)
        local summary = text({
            Size = UDim2.fromOffset(170, 16),
            Position = UDim2.new(1, -206, 0, 13),
            TextColor3 = Theme.Muted,
            TextXAlignment = Enum.TextXAlignment.Right,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = frame,
        })
        local chevron = icon("chevronDown", 16, UDim2.new(1, -30, 0, 13), Theme.Muted, frame)
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
                rows[index].Box.BackgroundColor3 = active and Theme.Accent or Theme.Surface
                rows[index].Box.UIStroke.Color = active and Theme.Accent or Theme.Faint
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
                body.Size = UDim2.new(1, -16, 0, math.min(#options, 6) * ROW)
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
                        Position = UDim2.fromOffset(8, 7),
                        BackgroundColor3 = Theme.Surface,
                        Parent = row,
                    }, { corner(3), stroke(Theme.Faint) })
                    local mark = icon("check", 12, UDim2.fromOffset(1, 1), Theme.OnAccent, box)
                    text({ Size = UDim2.new(1, -40, 1, 0), Position = UDim2.fromOffset(32, 0), Text = option.Name, Parent = row })
                    rows[index] = { Box = box, Mark = mark }
                    track(row.MouseEnter:Connect(function() tween(row, { BackgroundTransparency = 0 }) end))
                    track(row.MouseLeave:Connect(function() tween(row, { BackgroundTransparency = 1 }) end))
                    track(row.MouseButton1Click:Connect(function()
                        onChange(option.Value)
                        updateSelection()
                        setOpen(false)
                    end))
                end
            end
            updateSelection()
        end
        track(head.MouseButton1Click:Connect(function()
            if not open then refresh() end
            setOpen(not open)
        end))
        attachDismiss(frame, tab.Page, function() return open end, setOpen)
        refresh()
        return frame, refresh
    end
end
