# Assets

Images DexUI downloads at runtime. Keep them PNG (JPG works too), at most 1024 x 1024.

- One file per image, lower-case names with underscores: `wordmark.png`, `icon_anim.png`.
- Animated images are sprite sheets made with `tools/make_sheet.py`. Use `_anim` at the end of the name.
- Replacing an image: overwrite the file and bump its `Version` in `DefineAsset`, or players keep the cached copy.
- Every `DefineAsset` path in `src/` has to exist here; `tools/check.py` fails otherwise.
