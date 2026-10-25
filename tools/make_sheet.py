"""Turn an animated GIF (or a folder of PNG frames) into a sprite sheet DexUI can play.

  python tools/make_sheet.py logo.gif assets/logo_anim.png --height 64
  python tools/make_sheet.py logo.gif assets/logo_anim.png --height 64 --crop 28,24,1032,280 --bg 12,12,15
  python tools/make_sheet.py frames_dir assets/spinner.png --height 48 --fps 30

--bg makes a solid background colour transparent (for GIFs exported on a dark background).
Prints the Library:DefineAsset line to paste into the library or your script.
Needs Pillow and numpy:  pip install pillow numpy
"""
import argparse
import os
import sys

import numpy as np
from PIL import Image, ImageSequence

MAX_SIDE = 1024


def load_frames(source):
    if os.path.isdir(source):
        names = sorted(n for n in os.listdir(source) if n.lower().endswith(".png"))
        return [Image.open(os.path.join(source, n)).convert("RGBA") for n in names], None
    image = Image.open(source)
    duration = image.info.get("duration")
    return [frame.convert("RGBA") for frame in ImageSequence.Iterator(image)], duration


def key_out(frame, bg):
    pixels = np.asarray(frame).astype(np.float32)
    rgb = pixels[..., :3]
    background = np.array(bg, np.float32)
    span = max(255 - background.max(), 1)
    lifted = np.clip(rgb - background, 0, None)
    alpha = np.clip(lifted.max(axis=2) / span, 0, 1)
    colour = np.clip(lifted / np.maximum(alpha[..., None] * span, 1e-3) * 255, 0, 255)
    colour = colour * (alpha[..., None] > 0.003)
    return Image.fromarray(np.dstack([colour, alpha * 255]).astype(np.uint8), "RGBA")


def premultiplied_resize(frame, size):
    pixels = np.asarray(frame).astype(np.float32)
    alpha = pixels[..., 3:4] / 255
    pixels[..., :3] *= alpha
    small = np.asarray(Image.fromarray(pixels.astype(np.uint8), "RGBA").resize(size, Image.LANCZOS)).astype(np.float32)
    a = small[..., 3:4]
    small[..., :3] = np.where(a > 0, np.clip(small[..., :3] * 255 / np.maximum(a, 1), 0, 255), 0)
    return Image.fromarray(small.astype(np.uint8), "RGBA")


def build(source, out, height, crop=None, bg=None, fps=None):
    frames, duration = load_frames(source)
    if not frames:
        raise SystemExit("no frames found")
    if crop:
        frames = [f.crop(crop) for f in frames]
    if bg:
        frames = [key_out(f, bg) for f in frames]
    width = round(height * frames[0].width / frames[0].height)
    if width > MAX_SIDE or height > MAX_SIDE:
        raise SystemExit("a single frame is bigger than 1024 px")
    columns = max(1, MAX_SIDE // width)
    rows = -(-len(frames) // columns)
    while rows * height > MAX_SIDE:
        frames = frames[::2]
        rows = -(-len(frames) // columns)
    sheet = Image.new("RGBA", (min(columns, len(frames)) * width, rows * height), (0, 0, 0, 0))
    for index, frame in enumerate(frames):
        sheet.paste(premultiplied_resize(frame, (width, height)), ((index % columns) * width, (index // columns) * height))
    sheet.save(out, optimize=True)
    if fps is None:
        fps = round(1000 / duration) if duration else 20
    name = os.path.splitext(os.path.basename(out))[0]
    rel = os.path.relpath(out).replace(os.sep, "/")
    print(f"{len(frames)} frames, {width}x{height} each, sheet {sheet.size[0]}x{sheet.size[1]}")
    print(f'Library:DefineAsset("{name}", {{ Path = "{rel}", Version = 1, Sheet = {{ Width = {width}, Height = {height}, Columns = {columns}, Frames = {len(frames)}, Fps = {fps} }} }})')


def main(argv):
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("source")
    parser.add_argument("out")
    parser.add_argument("--height", type=int, required=True)
    parser.add_argument("--crop", help="x0,y0,x1,y1")
    parser.add_argument("--bg", help="r,g,b background to make transparent")
    parser.add_argument("--fps", type=int)
    args = parser.parse_args(argv)
    crop = tuple(int(v) for v in args.crop.split(",")) if args.crop else None
    bg = tuple(int(v) for v in args.bg.split(",")) if args.bg else None
    build(args.source, args.out, args.height, crop, bg, args.fps)


if __name__ == "__main__":
    main(sys.argv[1:])
