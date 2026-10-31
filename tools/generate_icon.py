"""Draw a crisp original Маяк lighthouse launcher icon (no external assets)."""
from pathlib import Path
from math import hypot
from PIL import Image, ImageDraw, ImageFilter

SIZE = 1024
icon = Image.new("RGBA", (SIZE, SIZE), (5, 16, 33, 255))
pixels = icon.load()

# Midnight navy gradient, brightest behind the lamp.
for y in range(SIZE):
    for x in range(SIZE):
        d = min(1, hypot((x - 525) / 850, (y - 355) / 800))
        glow = (1 - d) ** 2
        pixels[x, y] = (
            int(5 + 6 * y / SIZE + 11 * glow),
            int(16 + 10 * y / SIZE + 29 * glow),
            int(32 + 21 * y / SIZE + 48 * glow),
            255,
        )

# Two light beams, soft luminous core and distant blue night glow.
beam = Image.new("RGBA", icon.size, (0, 0, 0, 0))
d = ImageDraw.Draw(beam)
d.polygon([(511, 331), (35, 176), (22, 417)], fill=(12, 117, 244, 102))
d.polygon([(513, 331), (990, 157), (999, 426)], fill=(16, 131, 255, 105))
beam_blur = beam.filter(ImageFilter.GaussianBlur(52))
icon = Image.alpha_composite(icon, beam_blur)
icon = Image.alpha_composite(icon, beam)

halo = Image.new("RGBA", icon.size, (0, 0, 0, 0))
hd = ImageDraw.Draw(halo)
hd.ellipse((410, 228, 614, 434), fill=(41, 178, 255, 112))
icon = Image.alpha_composite(icon, halo.filter(ImageFilter.GaussianBlur(62)))

# Layered rocky coast: keeps the silhouette bold at small sizes.
draw = ImageDraw.Draw(icon)
draw.polygon(
    [(0, 854), (125, 795), (262, 825), (351, 748), (505, 807),
     (662, 755), (798, 819), (930, 763), (1024, 809), (1024, 1024), (0, 1024)],
    fill=(13, 36, 63, 255),
)
draw.polygon(
    [(0, 954), (167, 889), (310, 921), (457, 853), (613, 908),
     (746, 865), (919, 921), (1024, 885), (1024, 1024), (0, 1024)],
    fill=(7, 21, 39, 255),
)

# Lighthouse shadow, tower, window, roof and signal light.
shadow = Image.new("RGBA", icon.size, (0, 0, 0, 0))
sd = ImageDraw.Draw(shadow)
sd.polygon([(450, 441), (578, 441), (622, 855), (408, 855)], fill=(1, 11, 27, 180))
icon = Image.alpha_composite(icon, shadow.filter(ImageFilter.GaussianBlur(25)))

draw = ImageDraw.Draw(icon)
draw.polygon([(464, 450), (561, 450), (605, 831), (422, 831)], fill=(226, 243, 255, 255))
draw.polygon([(523, 450), (562, 450), (605, 831), (556, 831)], fill=(128, 191, 239, 255))
draw.polygon([(446, 453), (581, 453), (571, 476), (456, 476)], fill=(11, 40, 71, 255))
draw.rounded_rectangle((478, 363, 548, 444), radius=9, fill=(223, 246, 255, 255))
draw.rounded_rectangle((489, 374, 537, 437), radius=7, fill=(23, 163, 249, 255))
draw.line((503, 380, 503, 433), fill=(241, 252, 255, 255), width=6)
draw.polygon([(458, 365), (513, 319), (566, 365)], fill=(229, 245, 255, 255))
draw.line((444, 368, 581, 368), fill=(109, 196, 252, 255), width=12)
draw.line((513, 299, 513, 319), fill=(232, 249, 255, 255), width=9)
draw.ellipse((501, 284, 525, 308), fill=(245, 252, 255, 255))
draw.rounded_rectangle((494, 601, 525, 673), radius=12, fill=(17, 49, 82, 255))
draw.rounded_rectangle((405, 826, 622, 864), radius=12, fill=(221, 242, 254, 255))
draw.line((444, 484, 424, 817), fill=(255, 255, 255, 70), width=7)

output = Path("assets/brand/mayak_icon.png")
output.parent.mkdir(parents=True, exist_ok=True)
icon.convert("RGB").save(output, optimize=True)
print(f"Created {output}")

android = Path("android/app/src/main/res")
densities = {
    "mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192
}
for density, size in densities.items():
    folder = android / f"mipmap-{density}"
    folder.mkdir(parents=True, exist_ok=True)
    icon.resize((size, size), Image.Resampling.LANCZOS).convert("RGB").save(
        folder / "ic_launcher.png", optimize=True
    )
print("Generated Android launcher assets at 48–192 px")
