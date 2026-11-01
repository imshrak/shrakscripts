# Assets

- `launcher-s.png` is the transparent angular S launcher logo selected for ShrakScripts.
- `icons.lua` maps UI icon names to icons.rest Roblox asset IDs.

The library downloads the launcher PNG from its AssetBase URL, writes it to the executor's ShrakScriptsUI cache folder, and uses getcustomasset to display it. No manual file installation is needed. A plain S is used if image loading is unavailable.

The GUI implementation is bundled into Library.lua by `python ui/build.py`. The PNG remains a separate repository asset so updating it does not require placing Base64 image data in each consuming game script.
