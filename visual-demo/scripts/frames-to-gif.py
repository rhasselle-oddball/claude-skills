"""Build a looping GIF from numbered PNG frames.

Usage: frames-to-gif.py OUT.gif "frames/name-*.png" [x y width height]

Crop box is optional; pass the final-state bounding box plus padding so
every frame has the same size. Frame timing: first frame 900ms, middle
frames 450ms, last frame held 3500ms.
"""
import glob
import sys

from PIL import Image

out, pattern, *box = sys.argv[1:]
files = sorted(glob.glob(pattern))
frames = [Image.open(f).convert('RGB') for f in files]
if box:
    x, y, w, h = map(int, box)
    frames = [f.crop((x, y, x + w, y + h)) for f in frames]

durations = [900] + [450] * (len(frames) - 2) + [3500]
palette = [f.convert('P', palette=Image.Palette.ADAPTIVE, colors=64) for f in frames]
palette[0].save(out, save_all=True, append_images=palette[1:],
                duration=durations[:len(frames)], loop=0, optimize=True)
print(out, frames[0].size, len(frames))
