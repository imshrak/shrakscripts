local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/imshrak/shrakscripts/refs/heads/main/ui/Library.lua"))()
local Window = Library:CreateWindow({
    Id = "ShrakCustomizationExample",
    Title = "ShrakScripts",
    Subtitle = "Controls and customization",
    Width = 640,
    Height = 520,
    ThemePreset = "Nord",
    DeferShow = true,
    ConfigFolder = "ShrakScripts/Examples",
})
local Main = Window:AddTab("Main", "user")
local Features = Main:AddGroupbox("Features")
local Enabled = Features:AddToggle("Enabled", { Text = "Enabled", Tooltip = "Shows the dependent controls below." })
Features:AddSlider("Strength", { Text = "Strength", Min = 0, Max = 100, Default = 25 }):SetDependency(Enabled)
Features:AddInput("Message", { Text = "Message", Default = "Hello", Placeholder = "Enter a message", MaxLength = 80 })
Features:AddKeybind("ActionKey", { Text = "Action key", Default = "F", Mode = "Hold", Callback = function(active)
    Window:Notify({ Title = "Action", Text = active and "Pressed" or "Released", Duration = 2 })
end })
Features:AddColorPicker("Tint", { Text = "Tint", Default = Color3.fromRGB(136, 192, 208), Transparency = 0.15, Callback = function(value, control)
    print(value:ToHex(), control.Transparency)
end })
local Pages = Main:AddTabbox("Details")
local First = Pages:AddTab("General")
First:AddDropdown("Mode", { Text = "Mode", Values = { "Balanced", "Fast", "Quiet" }, Default = "Balanced" })
local Second = Pages:AddTab("About")
Second:AddLabel("Drag the title bar. Click color swatches to open the picker.")
Second:AddButton({ Text = "Notification", Callback = function() Window:Notify({ Title = "ShrakScripts UI", Text = "Themes and profiles are in Settings." }) end })
local Settings = Window:AddTab("Settings", "settings")
Window:AddThemeSection(Settings)
Window:AddConfigSection(Settings)
Settings:AddButton({ Text = "Unload", Callback = function() Window:Unload() end })
Window:Ready()
return Window
