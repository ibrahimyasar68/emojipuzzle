"""Play Store'un istediği öne çıkan grafiği (1024×500) üretir.

Kullanım:
    python3 tool/generate_store_graphics.py

Pillow gerekir. `docs/store/feature-graphic-1024x500.png` yazar.

Görselin parçaları projenin kendi malzemesidir: uygulama ikonu
(`docs/branding/app-icon-1024.png`), havuzdaki OpenMoji resimleri ve
oyunun kendi renkleri (`AppPalette.light`). Yazı tipi Flutter SDK ile
gelen Roboto'dur (Apache 2.0).
"""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "docs/store"
FONTS = Path.home() / "flutter/flutter/bin/cache/artifacts/material_fonts"

W, H = 1024, 500
SUPER = 2

# AppPalette.light renkleri.
BACKGROUND = (238, 232, 225)
INK = (74, 64, 57)
MUTED = (110, 100, 91)
BUTTON = (252, 200, 60)


def _font(name, size):
    return ImageFont.truetype(str(FONTS / name), size)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    image = Image.new("RGB", (W * SUPER, H * SUPER), BACKGROUND)
    draw = ImageDraw.Draw(image)

    # Sağ üstte ve sol altta, zeminin bir ton koyusuyla iki büyük daire:
    # oyunun Home ekranındaki yuvarlak dille aynı.
    draw.ellipse(
        (W * 0.62 * SUPER, -H * 0.45 * SUPER, W * 1.45 * SUPER, H * 1.45 * SUPER),
        fill=(231, 224, 216),
    )

    icon = Image.open(ROOT / "docs/branding/app-icon-1024.png").convert("RGBA")
    side = int(300 * SUPER)
    icon = icon.resize((side, side), Image.LANCZOS)
    # Köşeleri yuvarlat: mağaza ikonu maskeliyor, burada biz maskeliyoruz.
    mask = Image.new("L", (side, side), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, side - 1, side - 1), radius=int(side * 0.22), fill=255
    )
    image.paste(icon, (int(72 * SUPER), int((H - 300) / 2 * SUPER)), mask)

    title = _font("Roboto-Black.ttf", int(84 * SUPER))
    subtitle = _font("Roboto-Medium.ttf", int(34 * SUPER))
    left = int(424 * SUPER)
    lines = [
        (title, "EmojiPuzzle", int(186 * SUPER), INK),
        (subtitle, "3–5 yaş için yapboz", int(292 * SUPER), MUTED),
        (subtitle, "Reklamsız · çevrimdışı", int(340 * SUPER), MUTED),
    ]
    for font, text, y, colour in lines:
        width = draw.textlength(text, font=font)
        # Sağ kenarda 48 px pay kalmalı: taşan metni mağaza kırpar.
        if left + width > (W - 48) * SUPER:
            raise SystemExit(
                f"'{text}' {width / SUPER:.0f} px, sığmıyor — punto ya da metin kısalmalı"
            )
        draw.text((left, y), text, font=font, fill=colour)

    # Havuzdan üç resim, köşede küçük bir şerit hâlinde.
    for index, name in enumerate(["apple", "lion", "car", "book"]):
        picture = Image.open(
            ROOT / f"assets/images/puzzles/{name}.png"
        ).convert("RGBA")
        size = int(74 * SUPER)
        picture = picture.resize((size, size), Image.LANCZOS)
        x = int((618 + index * 92) * SUPER)
        y = int(74 * SUPER)
        image.paste(picture, (x, y), picture)

    image.resize((W, H), Image.LANCZOS).save(
        OUT / "feature-graphic-1024x500.png", optimize=True
    )
    print(OUT / "feature-graphic-1024x500.png")


if __name__ == "__main__":
    main()
