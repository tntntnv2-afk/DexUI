# Assets

Images DexUI downloads at runtime. Keep them PNG (JPG works too), at most 1024 x 1024.

- One file per image, lower-case names with underscores: `wordmark.png`, `icon_anim.png`.
- Animated images are sprite sheets made with `tools/make_sheet.py`. Use `_anim` at the end of the name.
- Replacing an image: overwrite the file and bump its `Version` in `DefineAsset`, or players keep the cached copy.
- Every `DefineAsset` path in `src/` has to exist here; `tools/check.py` fails otherwise.

## Icons

`icons.png` is a white icon atlas: 64 px cells, 16 per row. The icons are from [Lucide](https://lucide.dev) (ISC licence, see `LUCIDE_LICENSE.txt`).

To add icons, put the names in `NAMES` in `tools/make_icons.js`, then run it from a folder with `lucide-static@0.460.0` and `playwright` installed:

```
npm i lucide-static@0.460.0 playwright
node /path/to/DexUI/tools/make_icons.js /path/to/DexUI/assets/icons.png
```

Paste the printed `ICON_NAMES` line over the one in `src/ui/Library.lua` and bump the `Icons` asset `Version`.
