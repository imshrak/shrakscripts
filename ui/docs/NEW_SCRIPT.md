# Create a new script

Keep game behavior in your script and use ShrakScripts UI to display controls. Copy [examples/basic.lua](../examples/basic.lua) as a starting point.

## 1. Load and create a window

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/imshrak/shrakscripts/refs/heads/main/ui/Library.lua"))()
local Window = Library:CreateWindow({ Id = "MyGameScript", Title = "My Game", DeferShow = true })
local Main = Window:AddTab("Main", "zap")
```

Use a stable, unique ID so running your script again replaces its own window.

## 2. Connect controls to state

```lua
local state = { Enabled = false, Amount = 10 }
Main:AddToggle("Enabled", { Text = "Enabled", Callback = function(value) state.Enabled = value end })
Main:AddSlider("Amount", { Text = "Amount", Min = 1, Max = 100, Default = state.Amount, Callback = function(value) state.Amount = value end })
```

Control defaults are silent. Your initial state should match the configured defaults. Use FireOnInit when you explicitly want initialization callbacks.

## 3. Stop your work when the window unloads

```lua
local running = true
local worker = task.spawn(function()
    while running do
        if state.Enabled then print("Amount:", state.Amount) end
        task.wait(1)
    end
end)
Window:OnUnload(function()
    running = false
    state.Enabled = false
    if coroutine.status(worker) ~= "dead" then task.cancel(worker) end
end)
```

The library cleans up its GUI and input connections. Your script owns its workers, game connections, and feature cleanup.

## 4. Update controls from code

```lua
Window.Toggles.Enabled:SetValue(false)
Window.Options.Amount:SetValue(20)
Window:StopAll()
```

SetValue updates the visuals and fires callbacks only when the value changes. Pass true as its second argument for a silent change. Use SetValue rather than assigning Value directly.

## 5. Reveal the completed menu

After creating every tab, control, and cleanup callback, finish setup with:

```lua
Window:Ready()
```

DeferShow keeps the UI hidden during setup, even when loading assets or game data yields. Ready reveals the complete menu and its optional Discord prompt.

## Optional Discord prompt

Set DiscordInvite and ShowDiscordPrompt in CreateWindow, or call Window:ShowDiscordPrompt later. The prompt copies an invite only when the user clicks Copy. It does not launch or join Discord.

## Forks and version pinning

When forking the repository, change the Library.lua loader URL and pass AssetBase pointing to your fork's ui/assets/ directory. A branch URL follows updates; use a commit SHA in both URLs to pin a version.
