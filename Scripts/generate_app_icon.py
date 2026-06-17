#!/usr/bin/env python3
"""Generate the FocusFlow macOS app icon.

The icon is drawn programmatically so the committed .icns can be regenerated
without relying on a design tool export.
"""

from __future__ import annotations

import math
import shutil
import subprocess
import tempfile
from pathlib import Path

try:
    from PIL import Image, ImageDraw
except ImportError as exc:
    raise SystemExit("Pillow is required: python3 -m pip install pillow") from exc


ROOT_DIR = Path(__file__).resolve().parents[1]
RESOURCES_DIR = ROOT_DIR / "FocusFlow" / "Resources"
PREVIEW_PATH = RESOURCES_DIR / "FocusFlowIcon.png"
ICNS_PATH = RESOURCES_DIR / "FocusFlow.icns"


def lerp(a: int, b: int, t: float) -> int:
    return round(a + (b - a) * t)


def gradient(size: int) -> Image.Image:
    top_left = (31, 56, 82)
    bottom_right = (38, 171, 158)
    warm = (242, 181, 72)

    image = Image.new("RGBA", (size, size))
    pixels = image.load()

    for y in range(size):
        for x in range(size):
            tx = x / (size - 1)
            ty = y / (size - 1)
            t = (tx * 0.45) + (ty * 0.55)
            base = tuple(lerp(top_left[i], bottom_right[i], t) for i in range(3))

            glow_distance = math.hypot((x - size * 0.72) / size, (y - size * 0.24) / size)
            glow = max(0.0, 1.0 - glow_distance * 3.2)
            color = tuple(lerp(base[i], warm[i], glow * 0.34) for i in range(3))
            pixels[x, y] = (*color, 255)

    return image


def rounded_rect_mask(size: int, radius: int) -> Image.Image:
    mask = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0, size, size), radius=radius, fill=255)
    return mask


def arc_endpoint(center: tuple[int, int], radius: int, angle_degrees: float) -> tuple[float, float]:
    radians = math.radians(angle_degrees)
    return (
        center[0] + math.cos(radians) * radius,
        center[1] + math.sin(radians) * radius,
    )


def draw_rounded_arc(
    draw: ImageDraw.ImageDraw,
    bbox: tuple[int, int, int, int],
    start: float,
    end: float,
    fill: tuple[int, int, int, int],
    width: int,
) -> None:
    draw.arc(bbox, start=start, end=end, fill=fill, width=width)
    radius = (bbox[2] - bbox[0]) // 2
    center = ((bbox[0] + bbox[2]) // 2, (bbox[1] + bbox[3]) // 2)
    cap_radius = width // 2
    for angle in (start, end):
        x, y = arc_endpoint(center, radius, angle)
        draw.ellipse(
            (x - cap_radius, y - cap_radius, x + cap_radius, y + cap_radius),
            fill=fill,
        )


def generate_master() -> Image.Image:
    scale = 3
    size = 1024
    canvas_size = size * scale
    image = gradient(canvas_size)

    mask = rounded_rect_mask(canvas_size, 210 * scale)
    image.putalpha(mask)

    overlay = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    # Minimal timer mark.
    ring_bbox = (250 * scale, 270 * scale, 774 * scale, 794 * scale)
    draw.ellipse(ring_bbox, outline=(247, 252, 250, 255), width=62 * scale)
    draw_rounded_arc(
        draw,
        ring_bbox,
        start=250,
        end=350,
        fill=(255, 198, 92, 255),
        width=62 * scale,
    )

    draw.rounded_rectangle(
        (438 * scale, 178 * scale, 586 * scale, 252 * scale),
        radius=34 * scale,
        fill=(247, 252, 250, 255),
    )

    center = (512 * scale, 532 * scale)
    draw.line(
        [center, (512 * scale, 404 * scale)],
        fill=(247, 252, 250, 255),
        width=34 * scale,
    )
    draw.line(
        [center, (622 * scale, 596 * scale)],
        fill=(247, 252, 250, 255),
        width=34 * scale,
    )
    draw.ellipse(
        (
            center[0] - 34 * scale,
            center[1] - 34 * scale,
            center[0] + 34 * scale,
            center[1] + 34 * scale,
        ),
        fill=(247, 252, 250, 255),
    )

    image.alpha_composite(overlay)
    return image.resize((size, size), Image.Resampling.LANCZOS)


def write_iconset(master: Image.Image, iconset_dir: Path) -> None:
    sizes = [
        (16, "icon_16x16.png"),
        (32, "icon_16x16@2x.png"),
        (32, "icon_32x32.png"),
        (64, "icon_32x32@2x.png"),
        (128, "icon_128x128.png"),
        (256, "icon_128x128@2x.png"),
        (256, "icon_256x256.png"),
        (512, "icon_256x256@2x.png"),
        (512, "icon_512x512.png"),
        (1024, "icon_512x512@2x.png"),
    ]
    for size, filename in sizes:
        master.resize((size, size), Image.Resampling.LANCZOS).save(iconset_dir / filename)


def main() -> None:
    if shutil.which("iconutil") is None:
        raise SystemExit("iconutil is required to create FocusFlow.icns")

    RESOURCES_DIR.mkdir(parents=True, exist_ok=True)
    master = generate_master()
    master.save(PREVIEW_PATH)

    with tempfile.TemporaryDirectory(suffix=".iconset") as iconset:
        iconset_dir = Path(iconset)
        write_iconset(master, iconset_dir)
        subprocess.run(
            ["iconutil", "-c", "icns", str(iconset_dir), "-o", str(ICNS_PATH)],
            check=True,
        )

    print(f"Wrote {PREVIEW_PATH}")
    print(f"Wrote {ICNS_PATH}")


if __name__ == "__main__":
    main()
