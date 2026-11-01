from pathlib import Path
import re

root = Path(__file__).resolve().parent
components = ["TabHighlight", "DropdownDismiss", "SingleSelect", "DialogDrag", "MenuTransition", "LauncherControls", "Launcher", "Assets", "Drag", "Responsive"]
source = '''local environment = getgenv and getgenv() or _G
environment.ShrakScriptsUIWindows = environment.ShrakScriptsUIWindows or {}
local Library = {
    Version = "1.0.1",
    Windows = environment.ShrakScriptsUIWindows,
    AssetCache = {},
    AssetBase = "https://raw.githubusercontent.com/imshrak/shrakscripts/refs/heads/main/ui/assets/",
}
function Library:_Call(callback, ...)
    if type(callback) ~= "function" then return end
    local ok, message = pcall(callback, ...)
    if not ok then warn("[ShrakScripts UI] " .. tostring(message)) end
end
local Components = {}
'''
source += "Components.Icons = (function()\n" + (root / "assets/icons.lua").read_text(encoding="utf-8") + "\nend)()\n"
for name in components:
    source += "Components." + name + " = (function()\n" + (root / "gui" / (name + ".lua")).read_text(encoding="utf-8") + "\nend)()\n"
window = (root / "gui/Window.lua").read_text(encoding="utf-8")
window = window.replace("__PUBLIC_API__", (root / "gui/Api.lua").read_text(encoding="utf-8"))
window = window.replace("__WINDOW_EVENTS__", (root / "gui/Events.lua").read_text(encoding="utf-8"))
source += "local createWindow = (function()\n" + window + "\nend)()\n"
source += '''function Library:CreateWindow(config)
    return createWindow(self, config or {}, Components)
end
function Library:Unload()
    local windows = {}
    for _, window in pairs(self.Windows) do table.insert(windows, window) end
    for _, window in ipairs(windows) do window:Unload() end
end
return Library
'''
assert "__PUBLIC_API__" not in source and "__WINDOW_EVENTS__" not in source
assert not re.search(r"\b(?:TapSimulator|RebirthService|Runtime\.)", source)
assert not re.search(r"^\s*--", source, re.M)
(root / "Library.lua").write_text(source, encoding="utf-8")
print("Built ui/Library.lua:", len(source), "characters")
