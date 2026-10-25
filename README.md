# DexUI

A Roblox UI library. Version 3 is being rebuilt from scratch in `src/ui/Library.lua`.

## Load

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/tntntnv2-afk/DexUI/main/loader.lua"))()
```

The loader caches the library in `DexUI/library_cache.lua`, starts from the cache, and refreshes it from GitHub in the background.

The old library (v2) is still at `DexUI.lua` in the repo root, so scripts that load it keep working.

## Custom images

Images live in `assets/` and are downloaded the first time they're used, then cached in the executor's `DexUI/assets/` folder and shown with `getcustomasset`. Executors without file functions get the `Fallback` image instead (or nothing).

```lua
Library:DefineAsset("Logo", { Path = "assets/logo.png", Version = 1 })
Library:DefineAsset("Spinner", {
	Path = "assets/spinner.png",
	Version = 1,
	Sheet = { Width = 48, Height = 48, Columns = 20, Frames = 40, Fps = 30 },
	Fallback = "rbxassetid://0",
})

local logo = Library:Image(parent, "Logo", { Size = UDim2.fromOffset(120, 32) })
local id = Library:GetAsset("Logo")
```

- **Version:** bump it whenever you replace an image. The cache file name includes the version, so everyone downloads the new one.
- **Sheet:** makes the image an animated sprite sheet. Frames go left to right, then top to bottom. Every image on the sheet plays from one shared clock.
- **Path / Url:** `Path` is relative to the repo root. `Url` can point anywhere instead.
- **GetAsset** waits for the download, so call it inside `task.spawn`. `Image` does that for you and fills the image in when it's ready (`OnLoaded` and `OnFailed` callbacks are optional).

### Making an animated sheet

```
pip install pillow numpy
python tools/make_sheet.py logo.gif assets/logo_anim.png --height 64 --bg 12,12,15
```

It prints the `DefineAsset` line to paste. `--bg` turns a solid background colour transparent. `--crop x0,y0,x1,y1` trims the frames first. Sheets stay within 1024 x 1024 (Roblox's limit).

## Building blocks

- `Library:CreateScreenGui(name)`: a protected ScreenGui in `gethui()` or CoreGui
- `Library:Create(class, props, children)`: makes an instance. `Theme = { BackgroundColor3 = "Surface" }` keeps a property on a theme colour.
- `Library:SetTheme({ ... })` and `Library:OnThemeChanged(fn)`
- `Library:Tween(instance, goals, info)`
- `Library:Connect(signal, fn)`: disconnected on unload
- `Library:OnUnload(fn)` and `Library:Unload()`

## Layout

```
loader.lua            entry point, caches the library
src/ui/Library.lua    DexUI v3
assets/               images (see assets/README.md)
examples/assets.lua   loads two images to test the asset pipeline
tools/make_sheet.py   GIF or PNG frames -> sprite sheet
tools/check.py        compiles every Lua file and checks asset paths
DexUI.lua             DexUI v2, kept for older scripts
```

Run `python tools/check.py` before committing.
