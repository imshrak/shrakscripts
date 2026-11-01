# API reference

## Load the library

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/imshrak/shrakscripts/refs/heads/main/ui/Library.lua"))()
```

`Library.Version` is the library version. `Library.Windows` contains active windows by ID. `Library:Unload()` unloads every window created through this shared registry.

## CreateWindow

```lua
local Window = Library:CreateWindow({
    Id = "MyScript",
    Title = "My Script",
    Subtitle = "ShrakScripts UI",
    Width = 560,
    Height = 400,
    AutoShow = true,
    ToggleKeybind = Enum.KeyCode.RightShift,
    PanicKeybind = Enum.KeyCode.End,
    LauncherPosition = UDim2.fromOffset(22, 104),
})
```

Creating another window with the same ID unloads the previous instance. Use different IDs for independent windows.

Optional fields:

| Field | Purpose |
| --- | --- |
| `Position` | Expanded window position as a UDim2. Defaults to centered. |
| `DeferShow` | Keep the entire UI hidden until Window:Ready() is called after setup. Default false. |
| `Parent` | Parent for the ScreenGui. Defaults to gethui/CoreGui. |
| `Theme` | Color3 overrides for Window, Sidebar, Surface, Hover, Border, Text, Muted, Faint, Accent, and OnAccent. |
| `DiscordInvite` | Invite code or discord.gg URL. |
| `ShowDiscordPrompt` | Show the invitation dialog after creation. Default false. |
| `LauncherImage` | Override the launcher with a Roblox image URI or numeric asset ID. |
| `AssetBase` | Override the base URL containing launcher-s.png, useful for forks. |
| `CacheFolder` | Executor asset cache folder. Defaults to ShrakScriptsUI. |
| `OnPanic` | Callback for the panic key. Defaults to turning off window toggles. |
| `Mobile` | Optional boolean override for larger touch controls. Defaults to automatic touchscreen detection. |

Window methods:

| Method | Behavior |
| --- | --- |
| `Window:AddTab(title, icon)` | Create and return a tab. |
| `Window:Ready()` | Finish setup and reveal the completed UI. Call after all controls when DeferShow is true. Repeated calls have no effect. |
| `Window:SelectTab(nameOrTab)` | Select a tab and animate the sidebar highlight. |
| `Window:Show()` / `Hide()` / `Toggle()` | Control the animated window/launcher transition. |
| `Window:IsOpen()` | Return the requested visibility state. |
| `Window:StopAll()` | Set all toggles to false and run changed callbacks. |
| `Window:ShowDiscordPrompt(optionalInvite)` | Open the draggable invitation dialog. |
| `Window:OnUnload(callback)` | Register cleanup to run before GUI destruction. |
| `Window:Unload()` | Run cleanup and remove the window and its connections. |

`Window.Frame`, `Window.Screen`, `Window.LauncherButton`, and `Window.Theme` expose the underlying UI objects. `Window.Toggles`, `Window.Options`, and `Window.Controls` contain controls by ID.

The ScreenGui stays disabled during construction and launcher-asset loading. With `DeferShow = true`, it also stays disabled while your script builds controls or waits for game data. Call `Window:Ready()` at the end of setup; the optional Discord prompt appears at that point too. Without DeferShow, the library reveals the UI on the next deferred task for compatibility with existing scripts.

The title/subtitle area, the top bar, and the invitation dialog support mouse and single-finger dragging. The window fits the available device-safe area and stays within its edges. It adapts when the viewport changes or the device rotates. Touchscreens receive larger tab, toggle, button, slider, and dropdown targets, with dropdown summaries on a separate line. Tabs and pages scroll vertically; the minimized S launcher opens the menu without a keyboard. Extra touches do not take over an active drag or slider.

When open, menu content renders directly in the window for sharp text and icons. The CanvasGroup is used only during the minimize/reopen fade and is left empty once the transition completes.

## Tabs and sections

```lua
local Main = Window:AddTab("Main", "zap")
Main:AddSection("Progression")
```

Available icon names: `farm`, `pets`, `rewards`, `user`, `settings`, `x`, `minus`, `chevronDown`, `chevronRight`, `check`, `copy`, `copyCheck`. Aliases: `zap`, `paw-print`, and `gift`. See [the icon map](../assets/icons.lua) for the exact icons.rest assets.

## Toggles

```lua
local Enabled = Main:AddToggle("Enabled", {
    Text = "Enabled",
    Default = false,
    Callback = function(value) print(value) end,
})
Enabled:SetValue(true)
Enabled:SetValue(false, true)
Enabled:OnChanged(function(value) print("Changed:", value) end)
```

The second SetValue argument suppresses callbacks when true. Defaults are applied silently; set `FireOnInit = true` to call the callback with the initial value. Callbacks receive `(value, control)`. `GetValue()` and `.Value` return the current value. Duplicate IDs within a window are rejected.

## Sliders

```lua
local Amount = Main:AddSlider("Amount", {
    Text = "Amount",
    Min = 0,
    Max = 100,
    Default = 25,
    Rounding = 0,
    Callback = function(value) print(value) end,
})
Amount:SetValue(50)
```

Rounding is the number of decimal places. Values are clamped to the range. Max must exceed Min.

## Single dropdowns

```lua
local Tier = Main:AddDropdown("Tier", {
    Text = "Tier",
    Values = {
        { Name = "Automatic", Value = 0 },
        { Name = "+75K", Value = 75000 },
    },
    Default = 0,
    Callback = function(value) print(value) end,
})
Tier:SetValue(75000)
Tier:Refresh()
```

Values may be plain strings, Name/Value tables, or a function returning that array. Dynamic values refresh when opened. A single dropdown closes after selecting, clicking outside, scrolling the parent page, hiding the menu, or changing tabs. Scrolling inside its option list keeps it open. The list shows at most six rows at once and scrolls for additional values.

## Multiple-selection dropdowns

```lua
local Items = Main:AddDropdown("Items", {
    Text = "Items",
    Multi = true,
    Values = { "Golden", "Diamond" },
    Default = { Golden = true },
    Placeholder = "None",
    Callback = function(selected) print(selected.Golden == true) end,
})
Items:SetValue({ "Golden", "Diamond" })
```

Multi dropdown values are strings. Values passed to callbacks and GetValue are maps such as `{ Golden = true }`. SetValue accepts either a map or an array of selected strings. The All and Clear buttons update callbacks too. Multi dropdowns use the original expandable checklist style.

## Buttons and labels

```lua
local Message = Main:AddLabel("Ready")
Message:SetText("Running")
local Action = Main:AddButton({
    Text = "Run",
    Description = "Optional button description",
    Callback = function() Message:SetText("Clicked") end,
})
Action:Press()
Action:SetText("Run again")
```

Toggle titles have no subtitles. Button descriptions are optional. Buttons return Press and SetText methods; labels return SetText. The library reports callback errors with a ShrakScripts UI warning.
