return function(button, label, Library, config)
    label.Name = "LauncherLetter"
    local image = config.LauncherImage
    if type(image) == "number" then image = "rbxassetid://" .. image end
    if not image then
        local base = config.AssetBase or Library.AssetBase
        local url = base:gsub("/*$", "/") .. "launcher-s.png"
        image = Library.AssetCache[url]
        if not image then
            local ok, result = pcall(function()
                local loader = getcustomasset or getsynasset
                if not loader or not writefile then return end
                local data = game:HttpGet(url)
                assert(data:sub(1, 8) == "\137PNG\r\n\26\n", "Invalid launcher PNG")
                local folder = config.CacheFolder or "ShrakScriptsUI"
                if makefolder then pcall(makefolder, folder) end
                local path = folder .. "/launcher-s.png"
                writefile(path, data)
                return loader(path)
            end)
            if ok then image = result end
            if image then Library.AssetCache[url] = image end
        end
    end
    if type(image) ~= "string" or image == "" then label.Visible = true return label end
    local mark = Instance.new("ImageLabel")
    mark.Name = "LauncherLogo"
    mark.Position = UDim2.fromOffset(8, 8)
    mark.Size = UDim2.fromOffset(36, 36)
    mark.BackgroundTransparency = 1
    mark.Image = image
    mark.ScaleType = Enum.ScaleType.Fit
    mark.Parent = button
    label.Visible = false
    return mark
end
