# ShrakScripts UI

A reusable Roblox UI library with the ShrakScripts dark menu, sliding sidebar highlight, rounded S launcher, animated minimize/reopen transition, draggable window, and optional Discord invite dialog.

Version 1.1 adds text inputs, keyboard/mouse keybinds with Hold/Toggle/Always modes, HSV and hex color pickers with transparency, collapsible groupboxes, nested tabs, tooltips, disabled controls, and conditional visibility. Customize colors live with Dark, Nord, Dracula and Light presets, change fonts and text size, and save named profiles with the built-in settings sections. The menu unlocks the cursor while open and restores it when closed.

## Quick start

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/imshrak/shrakscripts/refs/heads/main/ui/Library.lua"))()
local Window = Library:CreateWindow({ Id = "MyScript", Title = "My Script", DeferShow = true })
local Main = Window:AddTab("Main", "zap")
Main:AddSection("Features")
Main:AddToggle("AutoFarm", {
    Text = "Auto Farm",
    Default = false,
    Callback = function(enabled)
        print("Auto Farm:", enabled)
    end,
})
Window:Ready()
```

Use `DeferShow = true` and call `Window:Ready()` after adding every tab and control. The menu stays hidden throughout setup, including any game-data or asset loading.

Run this in an executor with `game:HttpGet` and `loadstring`. The library loads its launcher PNG from this repository and caches it using `writefile` and `getcustomasset` when available. It falls back to an S letter if the custom image cannot be loaded. Menu icons use the IDs listed in [assets/icons.lua](assets/icons.lua), sourced from icons.rest.

Right Shift opens or minimizes the menu. Drag the title area or top bar with a mouse or finger to move the window, or drag the minimized launcher. The menu fits smaller screens, adapts to rotation, and uses larger touch controls on mobile. Tabs and pages scroll vertically; tap the S launcher to reopen without a keyboard. End turns off all toggles unless the script supplies `OnPanic`. The Discord prompt is optional and never joins or opens Discord automatically.

## Documentation

- [API reference](docs/API.md)
- [Create a new script](docs/NEW_SCRIPT.md)
- [Runnable example](examples/basic.lua)
- [Customization example](examples/customization.lua)
- [Asset details](assets/README.md)

This library has its own documented API. The loading and Window/Tab/Control organization follow the familiar pattern used by libraries such as [Obsidian](https://docs.mspaint.cc/obsidian).

## Repository layout

```text
ui/
  Library.lua
  assets/
  gui/
  docs/
  examples/
  tests/
  build.py
```

`Library.lua` is the generated entry point. All GUI components are bundled into it, so consumers only load that Lua URL. Assets are fetched separately from `ui/assets/`; users do not need to copy folders manually.

Edit the GUI sources in `gui/`, then run `python ui/build.py` from the repository root. Commit the edited sources and rebuilt `Library.lua` together. The build requires Python 3 and uses only its standard library.

`tests/smoke.lua` returns a function accepting the loaded library and exercises controls, themes, grouped layouts, profile rollback and optional file persistence in a Roblox client. `tests/input.lua` checks cursor ownership across windows and keybind input handlers; handler simulation uses `getconnections` when available. Both unload their test windows. See [the API reference](docs/API.md#testing) for invocation.
