#!/usr/bin/env python3
"""Regenerate every OmniConvert app icon from the brand mark.

Source of truth
---------------
The mark is the OmniConvert brand sign: an "O" ring nested inside a "C" ring,
closed by a tangential conversion arrow -- one continuous stroke family,
geometric, rounded, still legible at 16 px. It is authored on a 32x32 grid with
the brand gradient ``#4F46E5 -> #06B6D4`` (indigo -> cyan, 135 degrees), which
is the palette published by the marketing site's brand page. The geometry
constants below are those brand numbers copied verbatim, so this script is
self-contained (no imports from any other repository, no network, no icon
library) while staying pixel-consistent with the published SVG lockups.

Two compositions are produced
-----------------------------
``plate``
    Rounded square, corner radius 23.5% of the edge, brand gradient plate with
    the white mark at 70% of the edge, transparent outside the corners.
    Used by the surfaces that do not apply their own mask: Windows ``.ico``,
    the macOS ``.appiconset`` and the web favicon / PWA icons.
``square``
    Full-bleed gradient square with the white mark scaled down, so the OS mask
    (or the launch surface) can never clip the mark:
    55% of the edge for maskable web icons and iOS (mark stays inside the
    central 80% safe zone), 60% for the Android launcher mipmaps.

Every file is rasterised at ``SUPERSAMPLE`` x and downscaled with LANCZOS, and
PNGs are written with ``optimize=True``. Re-running the script is idempotent:
the same inputs produce byte-identical files.

Usage:
    python tool/generate_app_icons.py
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageChops, ImageDraw

REPO_ROOT = Path(__file__).resolve().parents[1]

# --------------------------------------------------------------------- geometry
# Brand grid: the mark is drawn in a 32x32 box and scaled from there.
GRID = 32.0
CX = CY = GRID / 2.0

R_OUT = 11.5           # outer "C" radius
W_OUT = 3.15           # outer "C" stroke width
R_IN = 5.6             # inner "O" radius
W_IN = 2.7             # inner "O" stroke width
ARC_START = 346.0      # lower end of the opening, just above 3 o'clock
ARC_SWEEP = 284.0      # clockwise sweep that lands the arrow at 12 o'clock
ARROW_LEN = 6.8        # how far the arrow head reaches past the ring end
ARROW_HALF = 2.6       # half width of the arrow head base
ARROW_BACK = 0.4       # how far the arrow head base sits behind the ring end
ARROW_ROUND = 1.1      # corner rounding radius of the arrow head

# ------------------------------------------------------------------ composition
GRADIENT = ("#4F46E5", "#06B6D4")  # brand indigo -> brand cyan, 135 degrees
WHITE = "#FFFFFF"

PLATE_RADIUS = 0.235        # corner radius as a fraction of the edge
PLATE_MARK_SCALE = 0.70     # white mark size on a plate icon
SAFE_MARK_SCALE = 0.55      # maskable / iOS: inside the central 80% safe zone
ANDROID_MARK_SCALE = 0.60   # Android launcher mipmaps

SUPERSAMPLE = 8             # rasterise 8x, then LANCZOS down
MAX_CANVAS = 4096           # cap the working canvas so 1024 px stays cheap

WEB_ICON = REPO_ROOT / "web" / "icons"
FAVICON = REPO_ROOT / "web" / "favicon.png"
WINDOWS_ICO = REPO_ROOT / "windows" / "runner" / "resources" / "app_icon.ico"
MACOS_SET = REPO_ROOT / "macos" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
IOS_SET = REPO_ROOT / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
ANDROID_RES = REPO_ROOT / "android" / "app" / "src" / "main" / "res"

WINDOWS_ICO_SIZES = (16, 24, 32, 48, 64, 128, 256)
MACOS_SIZES = (16, 32, 64, 128, 256, 512, 1024)
ANDROID_MIPMAPS = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}
# ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json
IOS_ICONS = {
    "Icon-App-20x20@1x.png": 20,
    "Icon-App-20x20@2x.png": 40,
    "Icon-App-20x20@3x.png": 60,
    "Icon-App-29x29@1x.png": 29,
    "Icon-App-29x29@2x.png": 58,
    "Icon-App-29x29@3x.png": 87,
    "Icon-App-40x40@1x.png": 40,
    "Icon-App-40x40@2x.png": 80,
    "Icon-App-40x40@3x.png": 120,
    "Icon-App-60x60@2x.png": 120,
    "Icon-App-60x60@3x.png": 180,
    "Icon-App-76x76@1x.png": 76,
    "Icon-App-76x76@2x.png": 152,
    "Icon-App-83.5x83.5@2x.png": 167,
    "Icon-App-1024x1024@1x.png": 1024,
}


# ----------------------------------------------------------------------- maths
def polar(angle_deg: float, radius: float) -> tuple[float, float]:
    rad = np.deg2rad(angle_deg)
    return CX + radius * float(np.cos(rad)), CY + radius * float(np.sin(rad))


def arc_sample(radius: float, start: float, end: float, step: float = 0.75):
    count = max(2, int(abs(end - start) / step) + 1)
    return [polar(start + (end - start) * i / (count - 1), radius) for i in range(count)]


ARC_END = ARC_START + ARC_SWEEP  # 630 deg -> 12 o'clock, tangent is horizontal
ARC_POINTS = arc_sample(R_OUT, ARC_START, ARC_END)
RING_POINTS = arc_sample(R_IN, 0.0, 360.0, step=1.5)


def arrow_triangle() -> list[tuple[float, float]]:
    """Filled head at 12 o'clock pointing right: the one direction nobody misreads."""
    end_rad = np.deg2rad(ARC_END)
    px, py = polar(ARC_END, R_OUT)
    # tangent for a clockwise sweep in screen coordinates (y grows downwards)
    tx, ty = -float(np.sin(end_rad)), float(np.cos(end_rad))
    nx, ny = -ty, tx
    tip = (px + tx * ARROW_LEN, py + ty * ARROW_LEN)
    base_x, base_y = px - tx * ARROW_BACK, py - ty * ARROW_BACK
    left = (base_x + nx * ARROW_HALF, base_y + ny * ARROW_HALF)
    right = (base_x - nx * ARROW_HALF, base_y - ny * ARROW_HALF)
    return [tip, left, right]


ARROW = arrow_triangle()


def hex_to_rgb(value: str) -> tuple[int, int, int]:
    value = value.lstrip("#")
    return (int(value[0:2], 16), int(value[2:4], 16), int(value[4:6], 16))


# ----------------------------------------------------------------- rasterising
def supersample_for(size: int) -> int:
    """Supersample factor, capped so huge icons do not allocate gigabytes."""
    return max(1, min(SUPERSAMPLE, MAX_CANVAS // max(size, 1)))


def gradient_layer(canvas: int) -> Image.Image:
    """Diagonal 135 degree brand gradient, opaque, as an RGBA layer."""
    start = np.array(hex_to_rgb(GRADIENT[0]), dtype=np.float64)
    end = np.array(hex_to_rgb(GRADIENT[1]), dtype=np.float64)
    # Every pixel on the anti-diagonal x + y shares one colour, so build a
    # lookup table instead of a full float64 ramp (keeps 1024 px icons cheap).
    steps = np.arange(2 * canvas - 1, dtype=np.float64)
    t = steps / (2.0 * (canvas - 1))
    lut = np.clip(start[None, :] + (end - start)[None, :] * t[:, None], 0, 255)
    lut = lut.astype(np.uint8)
    yy, xx = np.indices((canvas, canvas), dtype=np.int32)
    array = lut[yy + xx]
    return Image.fromarray(array, mode="RGB").convert("RGBA")


def _disk(canvas: int, radius: float, k: float) -> Image.Image:
    """Filled circle mask of ``radius`` brand units, centred on the grid."""
    mask = Image.new("L", (canvas, canvas), 0)
    cx, cy, r = CX * k, CY * k, radius * k
    ImageDraw.Draw(mask).ellipse((cx - r, cy - r, cx + r, cy + r), fill=255)
    return mask


def _annulus(canvas: int, radius: float, width: float, k: float) -> Image.Image:
    """Ring of ``width`` brand units centred on ``radius`` (exact, no stroke joins)."""
    return ImageChops.subtract(
        _disk(canvas, radius + width / 2.0, k),
        _disk(canvas, radius - width / 2.0, k),
    )


def _wedge(canvas: int, radius: float, start: float, end: float, k: float) -> Image.Image:
    """Pie slice from ``start`` to ``end`` degrees, used to cut the "C" open."""
    mask = Image.new("L", (canvas, canvas), 0)
    points = [(CX * k, CY * k)]
    points += [(x * k, y * k) for x, y in arc_sample(radius, start, end, step=0.5)]
    ImageDraw.Draw(mask).polygon(points, fill=255)
    return mask


def mark_mask(canvas: int) -> Image.Image:
    """Alpha mask of the mark drawn on a ``canvas``-pixel square.

    The rings are rasterised as true annuli (circle minus circle, cut by a
    wedge) instead of thick polylines: a stroked polyline in Pillow leaves
    visible comb-like seams where the segments join, which is unacceptable in
    an app icon. Both ring edges therefore land exactly on
    ``radius +- width / 2``, i.e. on the numbers the brand SVG uses.
    """
    k = canvas / GRID

    # outer "C": annulus opened by the arc sweep, with round caps on both ends
    ring = ImageChops.multiply(
        _annulus(canvas, R_OUT, W_OUT, k),
        _wedge(canvas, R_OUT + W_OUT, ARC_START, ARC_END, k),
    )
    caps = Image.new("L", (canvas, canvas), 0)
    cap_draw = ImageDraw.Draw(caps)
    cap_r = W_OUT / 2.0 * k
    for angle in (ARC_START, ARC_END):
        x, y = (value * k for value in polar(angle, R_OUT))
        cap_draw.ellipse((x - cap_r, y - cap_r, x + cap_r, y + cap_r), fill=255)
    ring = ImageChops.lighter(ring, caps)

    # inner "O": full annulus
    inner = _annulus(canvas, R_IN, W_IN, k)

    # arrow head at 12 o'clock, corners rounded by ARROW_ROUND
    arrow = Image.new("L", (canvas, canvas), 0)
    draw = ImageDraw.Draw(arrow)
    triangle = [(x * k, y * k) for x, y in ARROW]
    draw.polygon(triangle, fill=255)
    corner = ARROW_ROUND * k
    for x, y in triangle:
        draw.ellipse((x - corner, y - corner, x + corner, y + corner), fill=255)

    return ImageChops.lighter(ImageChops.lighter(ring, inner), arrow)


def _compose(size: int, plate: bool, mark_scale: float) -> Image.Image:
    factor = supersample_for(size)
    canvas = size * factor
    layer = Image.new("RGBA", (canvas, canvas), (0, 0, 0, 0))
    gradient = gradient_layer(canvas)

    if plate:
        plate_mask = Image.new("L", (canvas, canvas), 0)
        ImageDraw.Draw(plate_mask).rounded_rectangle(
            (0, 0, canvas - 1, canvas - 1),
            radius=max(1, int(round(canvas * PLATE_RADIUS))),
            fill=255,
        )
        layer.paste(gradient, (0, 0), plate_mask)
    else:
        layer.paste(gradient, (0, 0))

    inner = max(2, int(round(canvas * mark_scale)))
    offset = (canvas - inner) // 2
    white = Image.new("RGBA", (inner, inner), hex_to_rgb(WHITE) + (255,))
    layer.paste(white, (offset, offset), mark_mask(inner))
    return layer.resize((size, size), Image.LANCZOS)


def plate_icon(size: int) -> Image.Image:
    """Rounded 23.5% plate, brand gradient, white mark at 70%."""
    return _compose(size, plate=True, mark_scale=PLATE_MARK_SCALE)


def square_icon(size: int, mark_scale: float) -> Image.Image:
    """Full-bleed gradient square with a centred white mark (maskable friendly)."""
    return _compose(size, plate=False, mark_scale=mark_scale)


# ----------------------------------------------------------------------- output
def save_png(image: Image.Image, path: Path, alpha: bool = True) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if not alpha:
        image = image.convert("RGB")  # iOS rejects icons that carry an alpha channel
    image.save(path, format="PNG", optimize=True)


def save_ico(path: Path, sizes=WINDOWS_ICO_SIZES) -> None:
    """Multi-resolution .ico; every frame is rendered at its own size."""
    path.parent.mkdir(parents=True, exist_ok=True)
    frames = [plate_icon(size) for size in sizes]
    frames[-1].save(
        path,
        format="ICO",
        sizes=[(size, size) for size in sizes],
        append_images=frames,
    )


def write_all() -> list[Path]:
    written: list[Path] = []

    def emit(path: Path) -> None:
        written.append(path)

    # --- web: favicon + PWA icons (rounded plate) -----------------------------
    save_png(plate_icon(32), FAVICON)
    emit(FAVICON)
    save_png(plate_icon(192), WEB_ICON / "Icon-192.png")
    emit(WEB_ICON / "Icon-192.png")
    save_png(plate_icon(512), WEB_ICON / "Icon-512.png")
    emit(WEB_ICON / "Icon-512.png")

    # --- web: maskable icons (full bleed, mark in the 80% safe zone) ----------
    save_png(square_icon(192, SAFE_MARK_SCALE), WEB_ICON / "Icon-maskable-192.png")
    emit(WEB_ICON / "Icon-maskable-192.png")
    save_png(square_icon(512, SAFE_MARK_SCALE), WEB_ICON / "Icon-maskable-512.png")
    emit(WEB_ICON / "Icon-maskable-512.png")

    # --- windows -------------------------------------------------------------
    save_ico(WINDOWS_ICO)
    emit(WINDOWS_ICO)

    # --- macos ---------------------------------------------------------------
    for size in MACOS_SIZES:
        path = MACOS_SET / f"app_icon_{size}.png"
        save_png(plate_icon(size), path)
        emit(path)

    # --- android -------------------------------------------------------------
    for folder, size in ANDROID_MIPMAPS.items():
        path = ANDROID_RES / folder / "ic_launcher.png"
        save_png(square_icon(size, ANDROID_MARK_SCALE), path)
        emit(path)

    # --- ios (square, opaque: the system applies the rounded mask) -----------
    for name, size in IOS_ICONS.items():
        path = IOS_SET / name
        save_png(square_icon(size, SAFE_MARK_SCALE), path, alpha=False)
        emit(path)

    return written


# ---------------------------------------------------------------- self-check
def mark_bbox(image: Image.Image, threshold: int = 200) -> tuple[int, int, int, int]:
    """Bounding box of the near-white mark inside a gradient square."""
    rgb = np.asarray(image.convert("RGB"), dtype=np.uint8)
    pixels = rgb.min(axis=2) >= threshold
    rows = np.flatnonzero(pixels.any(axis=1))
    cols = np.flatnonzero(pixels.any(axis=0))
    if rows.size == 0 or cols.size == 0:
        raise AssertionError("no mark pixels found")
    return int(cols[0]), int(rows[0]), int(cols[-1]) + 1, int(rows[-1]) + 1


def verify() -> None:
    expected: list[tuple[Path, int]] = [(FAVICON, 32)]
    expected += [(WEB_ICON / f"Icon-{s}.png", s) for s in (192, 512)]
    expected += [(WEB_ICON / f"Icon-maskable-{s}.png", s) for s in (192, 512)]
    expected += [(MACOS_SET / f"app_icon_{s}.png", s) for s in MACOS_SIZES]
    expected += [(ANDROID_RES / f / "ic_launcher.png", s) for f, s in ANDROID_MIPMAPS.items()]
    expected += [(IOS_SET / name, s) for name, s in IOS_ICONS.items()]

    for path, size in expected:
        with Image.open(path) as image:
            assert image.size == (size, size), f"{path}: {image.size} != {size}"
            if path.parent == IOS_SET:
                assert image.mode == "RGB", f"{path}: iOS icons must be RGB, got {image.mode}"
            else:
                assert image.mode == "RGBA", f"{path}: expected RGBA, got {image.mode}"

    for size in (192, 512):
        with Image.open(WEB_ICON / f"Icon-maskable-{size}.png") as image:
            left, top, right, bottom = mark_bbox(image)
            low, high = 0.1 * size, 0.9 * size
            assert low <= left and low <= top, f"maskable {size}: mark starts at {left},{top}"
            assert right <= high and bottom <= high, f"maskable {size}: mark ends at {right},{bottom}"

    with Image.open(WINDOWS_ICO) as image:
        ico_sizes = sorted(image.ico.sizes())
    assert len(ico_sizes) == len(WINDOWS_ICO_SIZES), f"ico has {len(ico_sizes)} sizes: {ico_sizes}"
    assert ico_sizes == [(s, s) for s in WINDOWS_ICO_SIZES], f"ico sizes {ico_sizes}"


def main() -> int:
    written = write_all()
    verify()
    total = sum(path.stat().st_size for path in written)
    for path in written:
        print(f"{path.stat().st_size:>8}  {path.relative_to(REPO_ROOT).as_posix()}")
    print(f"{len(written)} files, {total} bytes; self-check passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())