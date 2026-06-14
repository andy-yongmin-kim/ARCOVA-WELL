from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parent.parent
ASSETS_DIR = ROOT / 'assets' / 'icon'

NAVY = '#1A2B48'
OFF_WHITE = '#FCFAF5'
SAGE = '#A8C5BC'
GOLD = '#D6A04B'
def hex_rgba(value: str, alpha: int = 255) -> tuple[int, int, int, int]:
    value = value.lstrip('#')
    return tuple(int(value[i : i + 2], 16) for i in (0, 2, 4)) + (alpha,)


def load_font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    candidates = [
        '/System/Library/Fonts/SFNSRounded.ttf' if bold else '/System/Library/Fonts/SFNS.ttf',
        '/System/Library/Fonts/Avenir Next.ttc',
        '/System/Library/Fonts/HelveticaNeue.ttc',
    ]
    for path in candidates:
        try:
            return ImageFont.truetype(path, size=size)
        except OSError:
            continue
    return ImageFont.load_default()


def arc_points(cx: float, cy: float, radius: float, angle_deg: float) -> tuple[float, float]:
    angle = math.radians(angle_deg)
    return cx + radius * math.cos(angle), cy + radius * math.sin(angle)


def draw_mark(base: Image.Image, center: tuple[float, float], scale: float, dark: bool) -> None:
    draw = ImageDraw.Draw(base)
    arch_color = hex_rgba(OFF_WHITE if dark else NAVY)
    orb_color = hex_rgba(SAGE)
    spark_color = hex_rgba(GOLD)

    cx, cy = center
    arch_radius = scale * 0.235
    stroke = max(12, int(scale * 0.09))
    bbox = [
        cx - arch_radius,
        cy - arch_radius * 1.03,
        cx + arch_radius,
        cy + arch_radius * 0.97,
    ]
    start_angle = 205
    end_angle = 335

    draw.arc(bbox, start=start_angle, end=end_angle, fill=arch_color, width=stroke)

    for angle in (start_angle, end_angle):
        x, y = arc_points(cx, cy - arch_radius * 0.03, arch_radius, angle)
        draw.ellipse(
            [x - stroke / 2, y - stroke / 2, x + stroke / 2, y + stroke / 2],
            fill=arch_color,
        )

    orb_radius = scale * 0.105
    orb_y = cy + scale * 0.08
    draw.ellipse(
        [cx - orb_radius, orb_y - orb_radius, cx + orb_radius, orb_y + orb_radius],
        fill=orb_color,
    )

    spark_radius = scale * 0.028
    spark_y = cy - scale * 0.205
    draw.ellipse(
        [cx - spark_radius, spark_y - spark_radius, cx + spark_radius, spark_y + spark_radius],
        fill=spark_color,
    )


def build_icon() -> Image.Image:
    image = Image.new('RGBA', (1024, 1024), hex_rgba(NAVY))

    glow = Image.new('RGBA', image.size, (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow)
    glow_draw.ellipse([312, 404, 712, 804], fill=hex_rgba(SAGE, 34))
    glow = glow.filter(ImageFilter.GaussianBlur(42))
    image.alpha_composite(glow)

    draw_mark(image, center=(512, 470), scale=600, dark=True)
    return image


def build_padded_icon() -> Image.Image:
    image = Image.new('RGBA', (1024, 1024), (0, 0, 0, 0))
    draw_mark(image, center=(512, 482), scale=520, dark=False)
    return image


def build_splash() -> Image.Image:
    size = 1800
    image = Image.new('RGBA', (size, size), (0, 0, 0, 0))

    glow = Image.new('RGBA', image.size, (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow)
    glow_draw.ellipse([450, 360, 1350, 1260], fill=hex_rgba(SAGE, 20))
    glow_draw.ellipse([575, 485, 1225, 1135], fill=hex_rgba(NAVY, 12))
    glow = glow.filter(ImageFilter.GaussianBlur(88))
    image.alpha_composite(glow)

    draw_mark(image, center=(900, 760), scale=720, dark=False)

    draw = ImageDraw.Draw(image)
    title_font = load_font(116, bold=True)
    title = 'Arcova Well'
    title_bbox = draw.textbbox((0, 0), title, font=title_font)
    title_x = (size - (title_bbox[2] - title_bbox[0])) / 2
    title_y = 1185
    draw.text((title_x, title_y), title, fill=hex_rgba(NAVY), font=title_font)

    return image


def main() -> None:
    ASSETS_DIR.mkdir(parents=True, exist_ok=True)
    build_icon().save(ASSETS_DIR / 'app_icon.png')
    build_padded_icon().save(ASSETS_DIR / 'app_icon_padded.png')
    build_splash().save(ASSETS_DIR / 'splash_screen.png')


if __name__ == '__main__':
    main()
