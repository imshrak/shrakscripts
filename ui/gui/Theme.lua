return function(palette)
    local bindings = setmetatable({}, { __mode = "k" })
    local animations = setmetatable({}, { __mode = "k" })
    local colors = {}
    for key in pairs(palette) do colors[key] = { ThemeRole = key } end
    function colors:Resolve(instance, properties)
        local result = {}
        local entries = bindings[instance] or {}
        bindings[instance] = entries
        for property, value in pairs(properties) do
            if type(value) == "table" and value.ThemeRole then
                entries[property] = value.ThemeRole
                result[property] = palette[value.ThemeRole]
            else
                entries[property] = nil
                result[property] = value
            end
        end
        return result
    end
    function colors:Set(instance, property, value)
        instance[property] = self:Resolve(instance, { [property] = value })[property]
    end
    function colors:Tween(service, instance, info, goal)
        local animation = service:Create(instance, info, self:Resolve(instance, goal))
        animations[animation] = true
        return animation
    end
    function colors:Refresh()
        for animation in pairs(animations) do animation:Cancel() end
        table.clear(animations)
        for instance, entries in pairs(bindings) do
            if instance.Parent then
                for property, role in pairs(entries) do instance[property] = palette[role] end
            end
        end
    end
    function colors:Cancel()
        for animation in pairs(animations) do animation:Cancel() end
        table.clear(animations)
    end
    return colors
end
