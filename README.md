# Dexori UI

A Roblox UI library, built on the Kompile UI v5 base: a window with a sidebar of icon tabs, a header with the page title, game and search, card groupboxes, toggles with keybinds and colour pickers, sliders, dropdowns, inputs, labels, dividers, an ESP preview, notifications, a keybind list, a watermark, themes, UI scale, and saved configs with autoload.

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
- **Sheet:** makes the image an animated sprite sheet. Frames go left to right, then top to bottom. `Fps` sets the speed, or `Durations` (milliseconds per frame) keeps a GIF's own timing. Every animated image plays from one shared clock.
- **Path / Url:** `Path` is relative to the repo root. `Url` can point anywhere instead.
- **GetAsset** waits for the download, so call it inside `task.spawn`. `Image` does that for you and fills the image in when it's ready (`OnLoaded` and `OnFailed` callbacks are optional).

### Making an animated sheet

```
pip install pillow numpy
python tools/make_sheet.py logo.gif assets/logo_anim.png --height 64 --bg 12,12,15
```

It prints the `DefineAsset` line to paste. `--bg` turns a solid background colour transparent. `--crop x0,y0,x1,y1` trims the frames first. Sheets stay within 1024 x 1024 (Roblox's limit).

Two names are special: `Icon` is the mark at the top of the sidebar, in the watermark and on the mobile toggle button, and `Wordmark` is what `Library.BuildLogo` shows. Both default to the animated Dexori D (`assets/dexori_d_anim.png`); define either again to swap it. If an image can't load, the logo falls back to the text "dexori".

## Quick start

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/tntntnv2-afk/DexUI/main/loader.lua"))()
Library:SetFolder("Dexori/my-script")
local Window = Library:CreateWindow({
	Title = "Dexori",
	Footer = "Dexori Hub",
	FooterRight = "made by me · build 1",
	Badge = "Premium",
	ToggleKey = "RightControl",
})
Window:AddSection("Main")
local Farm = Window:AddTab("Auto Farm", "sprout")
local Box = Farm:AddLeftGroupbox("Farming")
Box:AddToggle("AutoFarm", { Text = "Auto Farm", Description = "Farms the nearest mobs" }):AddKeybind("AutoFarmKey", { Default = "None" })
Box:AddSlider("Distance", { Text = "Distance", Min = 2, Max = 20, Default = 8, Suffix = " studs" })
Box:AddButton({ Label = "Nearest mob", Text = "Teleport", Func = function() end })
Window:AddSection("Other")
Library:BuildSettingsTab(Window)
Library:LoadAutoload()
```

`examples/showcase.lua` has every element in one window.

## Window

`CreateWindow` options, all optional:

- `Title`: name at the top of the sidebar. `Subtitle`: the line under it (default `v1.0 · Script Hub`).
- `Game`: text in the pill next to the page title. Leave it out to show the current place's name, or `false` to hide the pill.
- `Badge`: small tag under your name in the user card, like `"Premium"`. Without it the card shows `@username`. `User = false` hides the card.
- `Footer` and `FooterRight`: left and right footer text. FPS and ping are always shown on the right.
- `Width`, `Height` (default 780 x 520), `ToggleKey`.
- `AutoShow = false` starts with the menu hidden. Players can also turn on **Silent load** in Settings → Menu; it's saved in `<folder>/silent_load.txt` and works the same way (`Library:SetSilentLoad`, `Library:GetSilentLoad`).

Below 600 px wide the sidebar shrinks to icons only.

- `Window:AddSection("Main")`: a heading in the sidebar.
- `Window:AddTab(name, icon)`: a sidebar tab. `icon` is a name from the icon list; `Tab:SetIcon`, `Tab:SetTitle`.
- `Library:SetGame`, `SetFooter`, `SetFooterRight`, `SetSubtitle` change the header and footer later.
- The minimize button hides the menu; the close button unloads it after a second click.

## Icons

`assets/icons.png` holds 139 [Lucide](https://lucide.dev) icons. Use any of them by name:

```lua
local glyph = Library:Icon(parent, "swords", 16, { Theme = { ImageColor3 = "Accent" } })
Library:SetIcon(glyph, "skull")
```

Some handy names: `house`, `sprout`, `swords`, `sword`, `crosshair`, `map-pin`, `layout-grid`, `settings`, `star`, `eye`, `user`, `users`, `zap`, `shield`, `target`, `flame`, `skull`, `coins`, `trophy`, `gem`, `bell`, `palette`, `keyboard`, `bot`, `ghost`, `compass`, `globe`, `sparkles`, `crown`, `gamepad-2`. The full list is `ICON_NAMES` in `src/ui/Library.lua`; `assets/README.md` explains adding more.

## Building blocks

- Toggles, sliders, dropdowns, inputs, keybinds and colour pickers take `Text` and an optional `Description` (grey line under the label).
- `AddButton({ Text, Func })` is a full-width outlined button. Add `Label` (and `Description`) to get a row with the label on the left and the button on the right.
- `AddStats({ { Label = "Time", Value = "00:00" }, { Label = "Gold", Value = "0", Accent = true } })` returns an object with `:Set(label, value)`.
- `AddProgress({ Text = "Level 47", Value = 0.68 })` returns an object with `:SetValue(0..1)` and `:SetText()`.
- `Library.Options[id]`: every toggle, slider, dropdown, input, keybind and colour picker by id (`.Value`, `:SetValue()`, `:OnChanged()`)
- `Library:Notify(title, text, seconds)`
- `Library:SetTheme({ ... })`
- `Library:SaveConfig(name)`, `LoadConfig`, `DeleteConfig`, `ListConfigs`, `SetAutoload`, `LoadAutoload`
- `Library:OnUnload(fn)` and `Library:Unload()`

## Target card

A floating card for the mob or boss you're fighting: a live 3D portrait, a health bar with a white "damage taken" chunk that drains after each hit, floating damage numbers, a state chip, distance, time on target, DPS, time left and session kills. It sits under the watermark until it's dragged, fades in when you set a target and fades out shortly after the target dies.

```lua
local Card = Library:CreateTargetCard()
Card:AddSettings(SomeGroupbox)

Card:SetTarget(bossModel)
Card:SetTarget({ Model = bossModel, Name = "Akaza", Subtitle = "Upper Moon 3", Badge = "Boss" })
Card:SetState("Fighting")
Card:SetTarget(nil)
```

- `SetTarget` takes a model (it finds the Humanoid and root itself) or a table with `Model`, `Humanoid`, `Root`, `Name`, `Subtitle`, `Badge`, `Icon`. Call it every frame if you like; the same model doesn't reset the stats, and a boss that already died isn't counted twice.
- No Humanoid? Pass `Health` and `MaxHealth` and update with `Card:SetHealth(hp, max)`.
- `SetState` knows `Fighting`, `Attacking`, `Dodging`, `Looting`, `Finishing`, `Gripping`, `Retreating`, `Healing`, `Resetting`, `Waiting` and `Defeated`, each with its own colour, or any text with an optional colour.
- `Card:AddBar("Shield", { Color = Color3.fromRGB(96, 165, 250) })` adds a thin bar under the health bar; `GetBar(name):Set(value, max)`, `:SetVisible()`, `:SetColor()`.
- `AddSettings(groupbox)` adds the show toggle, damage numbers toggle, scale slider and a reset position button.
- Options: `CreateTargetCard({ Width = 330, Scale = 1, AutoHide = true, HideDelay = 1.6, ShowDistance = true, DamageNumbers = true, Portrait = true, Icon = "skull", OnDefeated = function(target, seconds) end })`.
- `Card.Kills`, `Card:ResetKills()`, `Card:SetEnabled()`, `Card:SetScale()`, `Card:ResetPosition()`, `Card:Destroy()`.

## Layout

```
loader.lua            entry point, caches the library
src/ui/Library.lua    Dexori UI
assets/               images the library downloads (see assets/README.md)
art/                  the original Dexori GIFs, not loaded at runtime
examples/showcase.lua every element in one window
examples/assets.lua   shows the Wordmark and Icon images to test the image pipeline
tools/make_sheet.py   GIF or PNG frames -> sprite sheet
tools/make_icons.js   Lucide icons -> assets/icons.png
tools/check.py        compiles every Lua file and checks asset paths
DexUI.lua             DexUI v2, kept for older scripts
```

Run `python tools/check.py` before committing.
