# Art

The original Dexori GIFs. They aren't loaded by the library; turn one into a sprite sheet in `assets/` with `tools/make_sheet.py` when it's needed.

- `dexori_icon_animated.gif`: the D on its own (512 x 512). Used for `assets/dexori_d_anim.png`.
- `dexori_logo_horizontal_animated.gif`: D + DEXORI (1200 x 400).
- `dexori_logo_animated_1080.gif`: the square logo (1080 x 1080).
- `dexori_intro_1080p.gif`: the 1080p intro (1920 x 1080).

All four are on a solid #0a0a0b background, so use `--bg 10,10,11`.

`assets/dexori_d_anim.png` was made with:

```
python tools/make_sheet.py art/dexori_icon_animated.gif assets/dexori_d_anim.png --height 128 --crop 106,95,426,415 --bg 10,10,11
```
