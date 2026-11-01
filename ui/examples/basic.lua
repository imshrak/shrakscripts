local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/imshrak/shrakscripts/refs/heads/main/ui/Library.lua"))()

local Window = Library:CreateWindow({ Id = "ShrakScriptsExample", Title = "My Script", Subtitle = "ShrakScripts UI" })
local Main = Window:AddTab("Main", "zap")
Main:AddSection("Features")
Main:AddToggle("Enabled", { Text = "Enabled", Default = false, Callback = function(value) print("Enabled:", value) end })
Main:AddSlider("Amount", { Text = "Amount", Min = 1, Max = 100, Default = 25, Callback = function(value) print("Amount:", value) end })
Main:AddDropdown("Mode", { Text = "Mode", Values = { "Fast", "Balanced", "Slow" }, Default = "Balanced", Callback = function(value) print("Mode:", value) end })
Main:AddDropdown("Items", { Text = "Items", Multi = true, Values = { "First", "Second", "Third" }, Default = { First = true }, Callback = function(value) print("First selected:", value.First == true) end })
Main:AddButton({ Text = "Stop All", Callback = function() Window:StopAll() end })
Main:AddButton({ Text = "Unload", Callback = function() Window:Unload() end })
Window:OnUnload(function() print("My Script unloaded") end)
return Window
