return function(Library, config, Components)
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local environment = getgenv and getgenv() or _G
local id = config.Id or "ShrakScriptsUI"
if Library.Windows[id] then Library.Windows[id]:Unload() end
local Hub = { Active = true, Toggles = {}, Options = {}, Controls = {}, Tabs = {}, UnloadCallbacks = {} }
local connections = {}
local beginDrag
local DISCORD_CODE = tostring(config.DiscordInvite or ""):gsub("^https?://discord%.gg/", ""):gsub("^discord%.gg/", "")
local function track(connection)
    table.insert(connections, connection)
    return connection
end
local Theme = {
    Window = Color3.fromRGB(8, 8, 8),
    Sidebar = Color3.fromRGB(12, 12, 12),
    Surface = Color3.fromRGB(17, 17, 17),
    Hover = Color3.fromRGB(26, 26, 26),
    Border = Color3.fromRGB(38, 38, 38),
    Text = Color3.fromRGB(245, 245, 245),
    Muted = Color3.fromRGB(140, 140, 140),
    Faint = Color3.fromRGB(80, 80, 80),
    Accent = Color3.fromRGB(255, 255, 255),
    OnAccent = Color3.fromRGB(8, 8, 8),
}

for key, value in pairs(config.Theme or {}) do
    assert(Theme[key] and typeof(value) == "Color3", "Invalid theme color: " .. tostring(key))
    Theme[key] = value
end

local Fonts = {
    Regular = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Regular),
    Medium = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Medium),
    Bold = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold),
}

local function create(className, properties, children)
    local instance = Instance.new(className)
    for key, value in pairs(properties) do
        instance[key] = value
    end
    for _, child in ipairs(children or {}) do
        child.Parent = instance
    end
    return instance
end

local function corner(radius)
    return create("UICorner", { CornerRadius = UDim.new(0, radius) })
end

local function round()
    return create("UICorner", { CornerRadius = UDim.new(0.5, 0) })
end

local function stroke(color, thickness)
    return create("UIStroke", { Color = color, Thickness = thickness or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
end

local function text(properties)
    properties.BackgroundTransparency = 1
    properties.FontFace = properties.FontFace or Fonts.Regular
    properties.TextSize = properties.TextSize or 14
    properties.TextColor3 = properties.TextColor3 or Theme.Text
    properties.TextXAlignment = properties.TextXAlignment or Enum.TextXAlignment.Left
    return create("TextLabel", properties)
end

local function tween(instance, goal, duration)
    TweenService:Create(instance, TweenInfo.new(duration or 0.14, Enum.EasingStyle.Quad), goal):Play()
end

local Icons = Components.Icons
local function icon(name, size, position, color, parent)
    return create("ImageLabel", {
        Size = UDim2.fromOffset(size, size),
        Position = position,
        BackgroundTransparency = 1,
        Image = Icons[name],
        ImageColor3 = color or Theme.Muted,
        ScaleType = Enum.ScaleType.Fit,
        Parent = parent,
    })
end

local camera = Workspace.CurrentCamera
local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
local WIDTH, HEIGHT = config.Width or 560, config.Height or 400

local screen = create("ScreenGui", {
    Name = id,
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    Parent = config.Parent or (gethui and gethui() or CoreGui),
})

local window = create("Frame", {
    Size = UDim2.fromOffset(WIDTH, HEIGHT),
    Position = config.Position or UDim2.fromOffset(math.floor((viewport.X - WIDTH) / 2), math.floor((viewport.Y - HEIGHT) / 2)),
    BackgroundColor3 = Theme.Window,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    Parent = screen,
}, { corner(10), stroke(Theme.Border) })

local content = create("Frame", {
    Size = UDim2.fromOffset(WIDTH, HEIGHT),
    BackgroundTransparency = 1,
    Parent = window,
})

local sidebar = create("Frame", {
    Size = UDim2.new(0, 156, 1, 0),
    BackgroundColor3 = Theme.Sidebar,
    BorderSizePixel = 0,
    Parent = content,
}, { corner(10) })

create("Frame", {
    Size = UDim2.new(0, 12, 1, 0),
    Position = UDim2.new(1, -12, 0, 0),
    BackgroundColor3 = Theme.Sidebar,
    BorderSizePixel = 0,
    Parent = sidebar,
})

create("Frame", {
    Size = UDim2.new(0, 1, 1, 0),
    Position = UDim2.new(1, 0, 0, 0),
    BackgroundColor3 = Theme.Border,
    BorderSizePixel = 0,
    Parent = sidebar,
})

local header = create("Frame", {
    Size = UDim2.new(1, 0, 0, 58),
    BackgroundTransparency = 1,
    Parent = sidebar,
})

text({
    Size = UDim2.new(1, -32, 0, 18),
    Position = UDim2.fromOffset(16, 14),
    FontFace = Fonts.Bold,
    TextSize = 16,
    Text = config.Title or "ShrakScripts",
    Parent = header,
})

text({
    Size = UDim2.new(1, -32, 0, 14),
    Position = UDim2.fromOffset(16, 33),
    TextSize = 12,
    TextColor3 = Theme.Faint,
    Text = config.Subtitle or "ShrakScripts UI",
    Parent = header,
})

local tabList = create("Frame", {
    Size = UDim2.new(1, -16, 1, -66),
    Position = UDim2.fromOffset(8, 62),
    BackgroundTransparency = 1,
    Parent = sidebar,
}, { create("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }) })

local topBar = create("Frame", {
    Size = UDim2.new(1, -157, 0, 48),
    Position = UDim2.fromOffset(157, 0),
    BackgroundTransparency = 1,
    Parent = content,
})

local pageTitle = text({
    Size = UDim2.new(1, -100, 0, 20),
    Position = UDim2.fromOffset(20, 15),
    FontFace = Fonts.Bold,
    TextSize = 15,
    Text = "",
    Parent = topBar,
})

local function windowButton(offset, iconName, hoverColor)
    local button = create("TextButton", {
        Size = UDim2.fromOffset(26, 26),
        Position = UDim2.new(1, offset, 0, 11),
        BackgroundColor3 = Theme.Window,
        AutoButtonColor = false,
        Text = "",
        Parent = topBar,
    }, { corner(6) })
    local glyph = icon(iconName, 16, UDim2.fromOffset(5, 5), Theme.Muted, button)
    track(button.MouseEnter:Connect(function()
        tween(button, { BackgroundColor3 = Theme.Hover })
        tween(glyph, { ImageColor3 = hoverColor or Theme.Text })
    end))
    track(button.MouseLeave:Connect(function()
        tween(button, { BackgroundColor3 = Theme.Window })
        tween(glyph, { ImageColor3 = Theme.Muted })
    end))
    return button
end

local closeButton = windowButton(-38, "x")
local minimizeButton = windowButton(-68, "minus")

create("Frame", {
    Size = UDim2.new(1, -157, 0, 1),
    Position = UDim2.fromOffset(157, 48),
    BackgroundColor3 = Theme.Border,
    BorderSizePixel = 0,
    Parent = content,
})

local pages = create("Frame", {
    Size = UDim2.new(1, -157, 1, -49),
    Position = UDim2.fromOffset(157, 49),
    BackgroundTransparency = 1,
    Parent = content,
})

local tabs = {}
local moveTabHighlight = Components.TabHighlight(TweenService, Theme, tabList)

local function selectTab(target)
    for _, tab in ipairs(tabs) do
        local active = tab == target
        tab.Page.Visible = active
        tab.Button.BackgroundTransparency = 1
        tween(tab.Label, { TextColor3 = active and Theme.Text or Theme.Muted })
        tab.Indicator.Visible = false
        tween(tab.Icon, { ImageColor3 = active and Theme.Text or Theme.Muted })
    end
    pageTitle.Text = target.Name
    moveTabHighlight(target)
end

local function addTab(name, iconName)
    local page = create("ScrollingFrame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Theme.Border,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(),
        Visible = false,
        Parent = pages,
    }, {
        create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
        create("UIPadding", {
            PaddingTop = UDim.new(0, 14),
            PaddingBottom = UDim.new(0, 14),
            PaddingLeft = UDim.new(0, 20),
            PaddingRight = UDim.new(0, 20),
        }),
    })
    local button = create("TextButton", {
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = Theme.Hover,
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Text = "",
        LayoutOrder = #tabs,
        Parent = tabList,
    }, { corner(6) })
    local indicator = create("Frame", {
        Size = UDim2.fromOffset(2, 16),
        Position = UDim2.fromOffset(0, 9),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Visible = false,
        Parent = button,
    }, { corner(1) })
    local tabIcon = icon(iconName, 16, UDim2.fromOffset(12, 9), Theme.Muted, button)
    local label = text({
        Size = UDim2.new(1, -44, 1, 0),
        Position = UDim2.fromOffset(38, 0),
        FontFace = Fonts.Medium,
        TextColor3 = Theme.Muted,
        Text = name,
        Parent = button,
    })
    local tab = {
        Name = name,
        Page = page,
        Button = button,
        Label = label,
        Indicator = indicator,
        Icon = tabIcon,
        Order = 0,
    }
    table.insert(tabs, tab)
    track(button.MouseButton1Click:Connect(function()
        selectTab(tab)
    end))
    if #tabs == 1 then
        selectTab(tab)
    end
    return tab
end

local function nextOrder(tab)
    tab.Order += 1
    return tab.Order
end

local function addSection(tab, title)
    local holder = create("Frame", {
        Size = UDim2.new(1, 0, 0, tab.Order == 0 and 18 or 30),
        BackgroundTransparency = 1,
        LayoutOrder = nextOrder(tab),
        Parent = tab.Page,
    })
    text({
        Size = UDim2.new(1, 0, 0, 14),
        Position = UDim2.new(0, 2, 1, -16),
        FontFace = Fonts.Bold,
        TextSize = 12,
        TextColor3 = Theme.Faint,
        Text = string.upper(title),
        Parent = holder,
    })
end

local function card(tab, height)
    local frame = create("Frame", {
        Size = UDim2.new(1, 0, 0, height),
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        LayoutOrder = nextOrder(tab),
        Parent = tab.Page,
    }, { corner(8), stroke(Theme.Border) })
    return frame
end

local function cardLabels(frame, title, description)
    text({
        Size = UDim2.new(1, -90, 0, 16),
        Position = UDim2.fromOffset(14, description and 9 or 13),
        FontFace = Fonts.Medium,
        Text = title,
        Parent = frame,
    })
    if description then
        text({
            Size = UDim2.new(1, -90, 0, 14),
            Position = UDim2.fromOffset(14, 26),
            TextSize = 12,
            TextColor3 = Theme.Muted,
            Text = description,
            Parent = frame,
        })
    end
end

local resetters = {}

local function addToggle(tab, title, onChange)
    local frame = card(tab, 42)
    cardLabels(frame, title)
    local switch = create("Frame", {
        Size = UDim2.fromOffset(34, 18),
        Position = UDim2.new(1, -48, 0.5, -9),
        BackgroundColor3 = Theme.Border,
        Parent = frame,
    }, { round() })
    local knob = create("Frame", {
        Size = UDim2.fromOffset(14, 14),
        Position = UDim2.fromOffset(2, 2),
        BackgroundColor3 = Theme.Muted,
        Parent = switch,
    }, { round() })
    local hitbox = create("TextButton", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = "",
        Parent = frame,
    })
    local enabled = false
    local function set(value)
        enabled = value
        tween(switch, { BackgroundColor3 = value and Theme.Accent or Theme.Border })
        tween(knob, {
            Position = UDim2.fromOffset(value and 18 or 2, 2),
            BackgroundColor3 = value and Theme.OnAccent or Theme.Muted,
        })
        onChange(value)
    end
    track(hitbox.MouseButton1Click:Connect(function()
        set(not enabled)
    end))
    track(hitbox.MouseEnter:Connect(function()
        tween(frame, { BackgroundColor3 = Theme.Hover })
    end))
    track(hitbox.MouseLeave:Connect(function()
        tween(frame, { BackgroundColor3 = Theme.Surface })
    end))
    local function reset()
        if enabled then
            set(false)
        end
    end
    table.insert(resetters, reset)
    return reset, set, frame
end


local function addSlider(tab, title, min, max, value, onChange, rounding)
    local frame = card(tab, 58)
    cardLabels(frame, title)
    local valueLabel = text({
        Size = UDim2.fromOffset(80, 16),
        Position = UDim2.new(1, -94, 0, 13),
        FontFace = Fonts.Medium,
        TextColor3 = Theme.Muted,
        TextXAlignment = Enum.TextXAlignment.Right,
        Text = tostring(value),
        Parent = frame,
    })
    local bar = create("Frame", {
        Size = UDim2.new(1, -28, 0, 4),
        Position = UDim2.fromOffset(14, 40),
        BackgroundColor3 = Theme.Border,
        BorderSizePixel = 0,
        Parent = frame,
    }, { round() })
    local fill = create("Frame", {
        Size = UDim2.fromScale((value - min) / (max - min), 1),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Parent = bar,
    }, { round() })
    local knob = create("Frame", {
        Size = UDim2.fromOffset(12, 12),
        Position = UDim2.new((value - min) / (max - min), -6, 0.5, -6),
        BackgroundColor3 = Theme.Accent,
        Parent = bar,
    }, { round(), stroke(Theme.Window, 2) })
    local hitbox = create("TextButton", {
        Size = UDim2.new(1, 0, 0, 24),
        Position = UDim2.fromOffset(0, 30),
        BackgroundTransparency = 1,
        Text = "",
        Parent = frame,
    })
    local dragging = false
    local function update(x)
        local alpha = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local scale = 10 ^ (rounding or 0)
        local result = math.round((min + (max - min) * alpha) * scale) / scale
        alpha = (result - min) / (max - min)
        fill.Size = UDim2.fromScale(alpha, 1)
        knob.Position = UDim2.new(alpha, -6, 0.5, -6)
        valueLabel.Text = tostring(result)
        onChange(result)
    end
    track(hitbox.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            update(input.Position.X)
        end
    end))
    track(UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            update(input.Position.X)
        end
    end))
    track(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))
    local function setValue(result)
        local scale = 10 ^ (rounding or 0)
        result = math.clamp(math.round(result * scale) / scale, min, max)
        local alpha = (result - min) / (max - min)
        fill.Size = UDim2.fromScale(alpha, 1)
        knob.Position = UDim2.new(alpha, -6, 0.5, -6)
        valueLabel.Text = tostring(result)
        return result
    end
    return frame, setValue
end

local function addMultiSelect(tab, title, options, selected, emptyText, onChange)
    local ROW, HEAD = 28, 42
    local listHeight = #options * ROW + 44
    local frame = card(tab, HEAD)
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
    local headButton = create("TextButton", {
        Size = UDim2.new(1, 0, 0, HEAD),
        BackgroundTransparency = 1,
        Text = "",
        Parent = frame,
    })
    create("Frame", {
        Size = UDim2.new(1, -28, 0, 1),
        Position = UDim2.fromOffset(14, HEAD),
        BackgroundColor3 = Theme.Border,
        BorderSizePixel = 0,
        Parent = frame,
    })
    local checks = {}
    local function refresh()
        local names = {}
        for _, option in ipairs(options) do
            local on = selected[option.Name] == true
            local check = checks[option.Name]
            check.Box.BackgroundColor3 = on and Theme.Accent or Theme.Surface
            check.Box.UIStroke.Color = on and Theme.Accent or Theme.Faint
            check.Mark.Visible = on
            if on then
                table.insert(names, option.Name)
            end
        end
        summary.Text = #names == 0 and emptyText or #names <= 2 and table.concat(names, ", ") or (#names .. " selected")
    end
    for index, option in ipairs(options) do
        local row = create("TextButton", {
            Size = UDim2.new(1, -16, 0, ROW),
            Position = UDim2.fromOffset(8, HEAD + 6 + (index - 1) * ROW),
            BackgroundColor3 = Theme.Hover,
            BackgroundTransparency = 1,
            AutoButtonColor = false,
            Text = "",
            Parent = frame,
        }, { corner(5) })
        local box = create("Frame", {
            Size = UDim2.fromOffset(14, 14),
            Position = UDim2.fromOffset(8, 7),
            BackgroundColor3 = Theme.Surface,
            Parent = row,
        }, { corner(3), stroke(Theme.Faint) })
        local mark = icon("check", 12, UDim2.fromOffset(1, 1), Theme.OnAccent, box)
        mark.Visible = false
        create("Frame", {
            Size = UDim2.fromOffset(6, 6),
            Position = UDim2.fromOffset(32, 11),
            BackgroundColor3 = option.Color or Theme.Muted,
            Parent = row,
        }, { round() })
        text({
            Size = UDim2.new(1, -52, 1, 0),
            Position = UDim2.fromOffset(46, 0),
            Text = option.Name,
            Parent = row,
        })
        checks[option.Name] = { Box = box, Mark = mark }
        track(row.MouseEnter:Connect(function()
            tween(row, { BackgroundTransparency = 0 })
        end))
        track(row.MouseLeave:Connect(function()
            tween(row, { BackgroundTransparency = 1 })
        end))
        track(row.MouseButton1Click:Connect(function()
            selected[option.Name] = not selected[option.Name] or nil
            refresh()
            if onChange then onChange(selected) end
        end))
    end
    local function quickButton(label, x, callback)
        local button = create("TextButton", {
            Size = UDim2.fromOffset(64, 24),
            Position = UDim2.fromOffset(x, HEAD + 10 + #options * ROW),
            BackgroundColor3 = Theme.Hover,
            AutoButtonColor = false,
            FontFace = Fonts.Medium,
            TextSize = 13,
            TextColor3 = Theme.Text,
            Text = label,
            Parent = frame,
        }, { corner(5) })
        track(button.MouseButton1Click:Connect(function()
            callback()
            refresh()
            if onChange then onChange(selected) end
        end))
    end
    quickButton("All", 14, function()
        for _, option in ipairs(options) do
            selected[option.Name] = true
        end
    end)
    quickButton("Clear", 84, function()
        table.clear(selected)
    end)
    local open = false
    track(headButton.MouseButton1Click:Connect(function()
        open = not open
        tween(frame, { Size = UDim2.new(1, 0, 0, open and HEAD + listHeight or HEAD) }, 0.18)
        tween(chevron, { Rotation = open and 180 or 0 }, 0.18)
    end))
    refresh()
    return frame, refresh
end

local attachDropdownDismiss = Components.DropdownDismiss(UserInputService, track)
local addSingleSelect = Components.SingleSelect(create, text, corner, stroke, icon, track, tween, Theme, card, cardLabels, attachDropdownDismiss)

local function addButton(tab, title, description, callback)
    local frame = card(tab, description and 50 or 42)
    cardLabels(frame, title, description)
    icon("chevronRight", 16, UDim2.new(1, -30, 0.5, -8), Theme.Muted, frame)
    local hitbox = create("TextButton", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = "",
        Parent = frame,
    })
    track(hitbox.MouseEnter:Connect(function()
        tween(frame, { BackgroundColor3 = Theme.Hover })
    end))
    track(hitbox.MouseLeave:Connect(function()
        tween(frame, { BackgroundColor3 = Theme.Surface })
    end))
    track(hitbox.MouseButton1Click:Connect(callback))
    return frame
end

local Lighting = game:GetService("Lighting")
local popup
local attachDialogDrag = Components.DialogDrag(create, track, function(input)
    beginDrag(input)
end)
local INVITE_URL = "https://discord.gg/" .. DISCORD_CODE

local function closeDiscordPopup()
    if not popup then
        return
    end
    local current = popup
    popup = nil
    TweenService:Create(current.Panel, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = UDim2.new(0.5, -170, 0.5, -78) }):Play()
    tween(current.Overlay, { BackgroundTransparency = 1 }, 0.16)
    tween(current.Blur, { Size = 0 }, 0.16)
    for _, item in ipairs(current.Fade) do
        tween(item[1], { [item[2]] = 1 }, 0.12)
    end
    task.delay(0.16, function()
        current.Overlay:Destroy()
        current.Blur:Destroy()
    end)
end

local function copyInvite()
    if setclipboard then
        pcall(setclipboard, INVITE_URL)
        return true
    end
    return false
end

local function showDiscordPopup()
    if popup then
        return
    end
    local fade = {}
    local function faded(instance, property)
        table.insert(fade, { instance, property })
        return instance
    end

    local blur = create("BlurEffect", { Size = 0, Parent = Lighting })
    local overlay = create("TextButton", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Text = "",
        ZIndex = 10,
        Parent = content,
    }, { corner(10) })

    local panel = faded(create("Frame", {
        Size = UDim2.fromOffset(340, 180),
        Position = UDim2.new(0.5, -170, 0.5, -78),
        BackgroundColor3 = Theme.Window,
        ZIndex = 11,
        Parent = overlay,
    }, { corner(12), stroke(Theme.Border) }), "BackgroundTransparency")

    attachDialogDrag(overlay, panel)

    local dismiss = create("TextButton", {
        Size = UDim2.fromOffset(28, 28),
        Position = UDim2.new(1, -44, 0, 16),
        BackgroundColor3 = Theme.Window,
        AutoButtonColor = false,
        Text = "",
        ZIndex = 12,
        Parent = panel,
    }, { corner(6) })
    local dismissIcon = icon("x", 16, UDim2.fromOffset(6, 6), Theme.Muted, dismiss)
    dismissIcon.ZIndex = 13
    faded(dismissIcon, "ImageTransparency")

    faded(text({
        Size = UDim2.new(1, -48, 0, 22),
        Position = UDim2.fromOffset(24, 22),
        FontFace = Fonts.Bold,
        TextSize = 20,
        Text = "Join Discord?",
        ZIndex = 12,
        Parent = panel,
    }), "TextTransparency")
    faded(text({
        Size = UDim2.new(1, -48, 0, 18),
        Position = UDim2.fromOffset(24, 48),
        TextColor3 = Theme.Muted,
        Text = "Updates, new scripts and support.",
        ZIndex = 12,
        Parent = panel,
    }), "TextTransparency")

    local field = faded(create("TextButton", {
        Size = UDim2.new(1, -48, 0, 36),
        Position = UDim2.fromOffset(24, 80),
        BackgroundColor3 = Theme.Surface,
        AutoButtonColor = false,
        Text = "",
        ZIndex = 12,
        Parent = panel,
    }, { corner(8), stroke(Theme.Border) }), "BackgroundTransparency")
    faded(text({
        Size = UDim2.new(1, -50, 1, 0),
        Position = UDim2.fromOffset(14, 0),
        FontFace = Fonts.Medium,
        Text = "discord.gg/" .. DISCORD_CODE,
        ZIndex = 13,
        Parent = field,
    }), "TextTransparency")
    local fieldCopy = icon("copy", 16, UDim2.new(1, -28, 0, 10), Theme.Muted, field)
    fieldCopy.ZIndex = 13
    faded(fieldCopy, "ImageTransparency")

    local function actionButton(label, x, primary)
        local button = create("TextButton", {
            Size = UDim2.new(0.5, -30, 0, 36),
            Position = UDim2.new(x, x == 0 and 24 or 6, 1, -54),
            BackgroundColor3 = primary and Theme.Accent or Theme.Surface,
            AutoButtonColor = false,
            FontFace = Fonts.Bold,
            TextSize = 14,
            TextColor3 = primary and Theme.OnAccent or Theme.Text,
            Text = label,
            ZIndex = 12,
            Parent = panel,
        }, { corner(8), stroke(primary and Theme.Accent or Theme.Border) })
        faded(button, "BackgroundTransparency")
        faded(button, "TextTransparency")
        track(button.MouseEnter:Connect(function()
            tween(button, { BackgroundColor3 = primary and Theme.Muted or Theme.Hover })
        end))
        track(button.MouseLeave:Connect(function()
            tween(button, { BackgroundColor3 = primary and Theme.Accent or Theme.Surface })
        end))
        return button
    end

    local closeChoice = actionButton("Close", 0, false)
    local copyChoice = actionButton("Copy Invite", 0.5, true)

    local function onCopy()
        local copied = copyInvite()
        copyChoice.Text = copied and "Copied" or "Not supported"
        fieldCopy.Image = copied and Icons.copyCheck or Icons.copy
        fieldCopy.ImageColor3 = copied and Theme.Text or Theme.Muted
    end

    track(closeChoice.MouseButton1Click:Connect(closeDiscordPopup))
    track(dismiss.MouseButton1Click:Connect(closeDiscordPopup))
    track(copyChoice.MouseButton1Click:Connect(onCopy))
    track(field.MouseButton1Click:Connect(onCopy))
    track(dismiss.MouseEnter:Connect(function()
        tween(dismiss, { BackgroundColor3 = Theme.Hover })
        tween(dismissIcon, { ImageColor3 = Theme.Text })
    end))
    track(dismiss.MouseLeave:Connect(function()
        tween(dismiss, { BackgroundColor3 = Theme.Window })
        tween(dismissIcon, { ImageColor3 = Theme.Muted })
    end))
    track(field.MouseEnter:Connect(function()
        tween(field, { BackgroundColor3 = Theme.Hover })
    end))
    track(field.MouseLeave:Connect(function()
        tween(field, { BackgroundColor3 = Theme.Surface })
    end))

    popup = { Overlay = overlay, Panel = panel, Blur = blur, Fade = fade }
    tween(overlay, { BackgroundTransparency = 0.35 }, 0.2)
    tween(blur, { Size = 16 }, 0.2)
    TweenService:Create(panel, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Position = UDim2.new(0.5, -170, 0.5, -90) }):Play()
end


__PUBLIC_API__

__WINDOW_EVENTS__
end
