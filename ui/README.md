# ShrakScripts UI

A reusable Roblox UI library with the ShrakScripts dark menu, sliding sidebar highlight, rounded S launcher, animated minimize/reopen transition, draggable window, and optional Discord invite dialog.

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

Right Shift opens or minimizes the menu. Drag the header to move the window, or drag the minimized launcher. End turns off all toggles unless the script supplies `OnPanic`. The Discord prompt is optional and never joins or opens Discord automatically.

## Documentation

- [API reference](docs/API.md)
- [Create a new script](docs/NEW_SCRIPT.md)
- [Runnable example](examples/basic.lua)
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
  build.py
```

`Library.lua` is the generated entry point. All GUI components are bundled into it, so consumers only load that Lua URL. Assets are fetched separately from `ui/assets/`; users do not need to copy folders manually.

Edit the GUI sources in `gui/`, then run `python ui/build.py` from the repository root. Commit the edited sources and rebuilt `Library.lua` together. The build requires Python 3 and uses only its standard library.
