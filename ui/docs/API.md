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
| `Parent` | Parent for the ScreenGui. Defaults to LocalPlayer.PlayerGui; survives character respawns. A custom parent remains supported. |
| `Theme` | Color3 overrides for Window, Sidebar, Surface, Hover, Border, Text, Muted, Faint, Accent, and OnAccent. |
| `DiscordInvite` | Invite code or discord.gg URL. |
| `ShowDiscordPrompt` | Show the invitation dialog after creation. Default false. |
| `LauncherImage` | Override the launcher with a Roblox image URI or numeric asset ID. |
| `AssetBase` | Override the base URL containing launcher-s.png, useful for forks. |
| `CacheFolder` | Executor asset cache folder. Defaults to ShrakScriptsUI. |
| `OnPanic` | Callback for the panic key. Defaults to turning off window toggles. |
| `Mobile` | Optional boolean override for larger touch controls. Defaults to automatic touchscreen detection. |
| `ThemePreset` | Initial Dark, Nord, Dracula, or Light palette. Theme overrides apply after the preset. |
| `FontFamily` | Roblox font-family asset URL, such as rbxasset://fonts/families/BuilderSans.json. |
| `TextScale` | Text-size multiplier from 0.75 to 1.5. Defaults to 1. |
| `UnlockMouse` | Unlock and show the mouse while the menu is open. Default true. Disable if the consumer manages cursor state itself. |
| `ConfigFolder` | Relative executor workspace folder for named profiles. Defaults to ShrakScripts/Profiles/ plus the window ID. |

Window methods:

| Method | Behavior |
| --- | --- |
| `Window:AddTab(title, icon)` | Create and return a tab. |
| `Window:Ready()` | Finish setup and reveal the completed UI. Call after all controls when DeferShow is true. Repeated calls have no effect. |
| `Window:SelectTab(nameOrTab)` | Select a tab and animate the sidebar highlight. |
| `Window:Show()` / `Hide()` / `Toggle()` | Control the animated window/launcher transition. |
| `Window:IsOpen()` | Return the requested visibility state. |
| `Window:StopAll()` | Set all toggles and keybind active states to false and run changed callbacks. |
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

## Groups and nested tabs

```lua
local Group = Main:AddGroupbox("General", { Collapsed = false })
Group:AddToggle("Enabled", { Text = "Enabled" })
Group:SetCollapsed(true)

local Pages = Main:AddTabbox("Details")
local First = Pages:AddTab("First")
local Second = Pages:AddTab("Second")
First:AddLabel("First page")
Second:AddSlider("Amount", { Min = 0, Max = 100, Default = 25 })
Pages:SelectTab("Second")
```

Groups and inner tabs support the same control methods as main tabs. IDs remain unique across the entire window. `AddGroupBox` and `AddTabBox` are aliases. Nested sliders and pickers pause scrolling on the containing main page during a drag. `Main:AddDivider(optionalTitle)` adds a separator.

## Text inputs

```lua
local Input = Main:AddInput("Name", {
    Text = "Name",
    Default = "Example",
    Placeholder = "Enter text",
    MaxLength = 64,
    Finished = true,
    Callback = function(value) print(value) end,
})
Input:SetValue("Updated")
```

`Finished` defaults to true: commit on focus loss or Enter. Set it to false to commit while typing. `Numeric = true` accepts only values understood by tonumber. Optional `Validate = function(value) return boolean end` adds validation. Invalid edits restore the last accepted value when focus leaves. Values are strings; `SetValue` returns the control on success or `false, reason` when validation rejects it. MaxLength counts bytes.

## Keybinds

```lua
local Key = Main:AddKeybind("Action", {
    Text = "Action key",
    Default = "F",
    Mode = "Hold",
    Callback = function(active, control) print(active, control.Value) end,
})
Key:OnChanged(function(value) print("Binding:", value) end)
Key:OnClick(function(active) print("Active:", active) end)
Key:SetValue(Enum.KeyCode.G)
Key:SetMode("Toggle")
```

Click the binding to capture a key or MouseButton1/2/3. Escape cancels; Backspace/Delete clears to None. Click the mode to cycle Toggle, Hold, Always. `AddKeyPicker` is an alias. `Value` is a key name string; `Active` and `GetState()` are the activation state. `SetValue(value, quiet)` changes the binding; `SetMode(mode, quiet)` changes its mode. `SetActive(boolean, quiet)` changes activation directly.

`Callback` and `OnClick` receive activation changes. `OnChanged` receives binding changes. Inputs consumed by another UI or typed into a text box do not trigger actions. Hold releases on key-up or focus loss; keybinds work with the menu minimized. Captured keys do not also trigger another binding. Defaults are silent unless FireOnInit is true.

## Color pickers

```lua
local Color = Main:AddColorPicker("Tint", {
    Text = "Tint",
    Default = Color3.fromRGB(136, 192, 208),
    Transparency = 0.2,
    Callback = function(value, control) print(value, control.Transparency) end,
})
Color:SetValueRGB(Color3.fromRGB(255, 80, 100), 0.4)
Color:SetValue({ H = 0.5, S = 1, V = 1 }, true, 0.1)
Color:SetTransparency(0.5)
```

Click the swatch for a saturation/value square, hue strip, hex field, and transparency slider. RGB values remain Color3 objects in `Value`. `Transparency` is 0 (opaque) through 1 (transparent). `SetValue(value, quiet, optionalTransparency)` accepts Color3 or HSV components; `SetValueRGB(color, optionalTransparency, quiet)` is a convenience alias. Changes to color or transparency invoke Callback/OnChanged with `(Color3, control)`. The picker dismisses on outside input, page scrolling, or hidden ancestors.

## Tooltips, visibility, disabled state, and dependencies

Every control, button, label, groupbox, divider, and tabbox exposes `Frame`, `SetVisible(boolean)`, `SetDisabled(boolean)`, and `SetTooltip(text)`. Options may contain Visible, Disabled, Tooltip, IgnoreConfig, Dependency, and DependencyValue. Disabled controls block pointer interaction; disabled keybinds also stop activation. Programmatic SetValue remains available.

```lua
local Enabled = Main:AddToggle("Enabled", { Text = "Enabled", Tooltip = "Show extra settings" })
local Amount = Main:AddSlider("Amount", { Min = 0, Max = 100 })
Amount:SetDependency(Enabled, true)
Amount:SetupDependencies({ { Enabled, true }, { Mode, "Advanced" } })
Amount:SetTooltip("Extra settings")
```

All SetupDependencies entries must match. Expected values can also be predicates receiving `(value, sourceControl)` and returning true/false. Replacing dependencies disconnects their logical effect. Conditional visibility still updates for silent SetValue calls and quiet profile imports. Explicit SetVisible(false) takes precedence over dependencies.

## Live customization

```lua
Window:SetTheme("Dracula")
Window:SetTheme({ Accent = Color3.fromRGB(100, 190, 255) })
Window:ResetTheme()
Window:SetFont("rbxasset://fonts/families/RobotoMono.json")
Window:SetTextScale(1.1)
Window:SetSize(640, 480)
Window:SetTitle("New title", "New subtitle")
Window:SetMenuKeybind("RightControl")
Window:AddThemeSection(Settings)
```

SetTheme accepts a named preset or a partial table using the ten Theme roles above. Existing controls, newly created controls, hover/selected states, and launcher colors use the current palette. Color-picker selections keep their own colors. Theme editors synchronize with programmatic color changes. ResetTheme restores the initially configured palette. SetSize requires at least 280 x 220 and fits the actual viewport; SetTextScale accepts 0.75–1.5. SetFont preserves regular/medium/bold weights for library text.

AddThemeSection builds preset, color, font, text-size, window-size and menu-key controls. It returns a groupbox. This library keeps its own API; it does not emulate every Obsidian method or addon.

## Notifications

```lua
local Notice = Window:Notify({ Title = "Saved", Text = "Profile saved", Duration = 4 })
Notice:SetText("Updated")
Notice:Close()
Window:Notify("Done", 2)
```

Notifications stack at the bottom right with at most five visible. Click to dismiss. Duration defaults to four seconds; zero keeps the notification until closed or unloaded.

## Profiles

```lua
Window:AddConfigSection(Settings)
local ok, errorMessage = Window:SaveConfig("Default")
local ok, errorMessage = Window:LoadConfig("Default")
local names = Window:ListConfigs()
local ok, errorMessage = Window:DeleteConfig("Default")

local json = Window:ExportConfig()
local ok, errorMessage = Window:ImportConfig(json, { Quiet = true })
local data = Window:GetConfig({ Ignore = { Temporary = true }, IncludeTheme = false })
```

Profiles contain typed values, multi-selection maps, color transparency, keybind modes, theme colors, font, text scale, window dimensions, and the menu key. Runtime keybind activation is not saved. `IgnoreConfig = true` excludes a control. AddThemeSection and AddConfigSection exclude their management controls automatically. There is no implicit autoload.

ExportConfig/GetConfig and ImportConfig support `Ignore = { ID = true }` and `IncludeTheme = false` (also excludes window appearance settings). ImportConfig accepts JSON or a table, ignores unavailable IDs, validates matching types, and restores previous UI values if application fails. By default callbacks run after successful application, with toggles last; Quiet suppresses them. Use Quiet only when your consumer synchronizes its own state separately. Button/label contents and window positions are not saved.

File methods return success and an optional error string. Saving requires writefile, makefolder and isfolder; loading requires readfile; listing requires listfiles/isfolder; deletion requires delfile. JSON export/import works without these executor file APIs. Profile names accept letters, numbers, spaces, underscores and hyphens, up to 64 characters. ConfigFolder must be relative and cannot contain parent traversal. Deletion applies immediately to the selected named profile.

## Cursor and cleanup

Open menus use a modal button and a late render step to unlock/show the mouse. Closing or unloading restores the captured behavior and cursor visibility after the last managed window closes. `UnlockMouse = false` opts out for consumers with their own cursor manager. This does not change character movement or camera orientation. The default ScreenGui parent is PlayerGui to avoid executor-dependent access failures with protected UI containers; supply Parent to override it.

## Testing

Run the bundled checks in a Roblox client after loading Library:

```lua
local base = "https://raw.githubusercontent.com/imshrak/shrakscripts/refs/heads/main/ui/"
loadstring(game:HttpGet(base .. "tests/smoke.lua"))()(Library)
loadstring(game:HttpGet(base .. "tests/input.lua"))()(Library)
```

The smoke test creates a hidden window, checks the control API, profile round trips/rollback, themes, nested layouts, and optional file persistence, then unloads. The input test checks shared cursor ownership and restoration; when getconnections is available it also invokes only newly registered input handlers with synthetic input objects. It does not send gameplay key events. Successful runs print SHRAK_UI_SMOKE_PASSED and SHRAK_UI_INPUT_PASSED.
