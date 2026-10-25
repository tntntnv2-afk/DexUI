# Dexori UI

A Roblox UI library, built on the Kompile UI v5 base: windows with tabs and groupboxes, toggles with keybinds and colour pickers, sliders, dropdowns, inputs, labels, dividers, an ESP preview, notifications, a keybind list, a watermark, themes, UI scale, and saved configs with autoload.

## Load

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/tntntnv2-afk/DexUI/main/loader.lua"))()
```

The loader caches the library in `Dexori/library_cache.lua`, starts from the cache, and refreshes it from GitHub in the background.

The old library (v2) is still at `DexUI.lua` in the repo root, so scripts that load it keep working.

## Custom images

Images live in `assets/` and are downloaded the first time they're used, then cached in the executor's `Dexori/assets/` folder and shown with `getcustomasset`. Executors without file functions get the `Fallback` image instead (or nothing).

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

Two names are special: define `Wordmark` and the window title bar and watermark use it instead of the text logo, and define `Icon` for the mobile toggle button. Either can be a still image or an animated sheet.

## Quick start

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/tntntnv2-afk/DexUI/main/loader.lua"))()
Library:SetFolder("Dexori/my-script")
local Window = Library:CreateWindow({ Title = "Dexori", Subtitle = "My script", Footer = "Dexori", ToggleKey = "RightControl" })
local Main = Window:AddTab("Main")
local Box = Main:AddLeftGroupbox("Things")
Box:AddToggle("MyToggle", { Text = "Do the thing", Default = false }):AddKeybind("MyToggleKey", { Default = "None" })
Box:AddSlider("MySlider", { Text = "Amount", Min = 0, Max = 100, Default = 50, Rounding = 0 })
Library:BuildSettingsTab(Window)
Library:LoadAutoload()
```

`examples/showcase.lua` has every element in one window.

## Building blocks

- `Library.Options[id]`: every toggle, slider, dropdown, input, keybind and colour picker by id (`.Value`, `:SetValue()`, `:OnChanged()`)
- `Library:Notify(title, text, seconds)`
- `Library:SetTheme({ ... })`
- `Library:SaveConfig(name)`, `LoadConfig`, `DeleteConfig`, `ListConfigs`, `SetAutoload`, `LoadAutoload`
- `Library:OnUnload(fn)` and `Library:Unload()`

## Layout

```
loader.lua            entry point, caches the library
src/ui/Library.lua    Dexori UI
assets/               images (see assets/README.md)
examples/showcase.lua every element in one window
examples/assets.lua   loads assets/wordmark.png and assets/icon_anim.png to test images
tools/make_sheet.py   GIF or PNG frames -> sprite sheet
tools/check.py        compiles every Lua file and checks asset paths
DexUI.lua             DexUI v2, kept for older scripts
```

Run `python tools/check.py` before committing.
