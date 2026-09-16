"""Eşyalar kategorisinin resimlerini (kitap, mikroskop, dürbün) kodla çizer.

Kullanım:
    python3 tool/generate_object_images.py

Pillow gerekir. `assets/images/puzzles/` altına `book.png`,
`microscope.png` ve `binoculars.png` yazar (§34: 1024×1024, 1:1, şeffaf
zemin).

Üslup havuzdaki OpenMoji resimlerine uyar: 72 birimlik ızgara, 2 birim
kalınlıkta yuvarlak uçlu siyah çizgi, düz renkler (OpenMoji paletinden).
Çizimler bu projenin kendi eseridir; OpenMoji dosyası kopyalanmadı ya da
uyarlanmadı.

Kenarlar yumuşak olsun diye 4 kat büyük çizilip küçültülür. Aynı betik
aynı baytları üretir.
"""

import math
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets/images/puzzles"

SIZE = 1024
SUPER = 4
GRID = 72
U = SIZE * SUPER / GRID  # bir ızgara biriminin piksel karşılığı

LINE = 2.0  # OpenMoji çizgi kalınlığı, birim
THIN = 1.5  # sayfa satırları gibi iç ayrıntılar

# OpenMoji paleti.
BLACK = (0, 0, 0, 255)
WHITE = (255, 255, 255, 255)
LIGHT_BLUE = (146, 211, 245, 255)  # #92D3F5
BLUE = (97, 178, 228, 255)  # #61B2E4
DARK_BLUE = (30, 80, 160, 255)  # #1E50A0
RED = (210, 47, 39, 255)  # #D22F27
LIGHT_RED = (234, 90, 71, 255)  # #EA5A47
YELLOW = (252, 234, 43, 255)  # #FCEA2B
ORANGE = (241, 179, 28, 255)  # #F1B31C
LIGHT_GREY = (208, 207, 206, 255)  # #D0CFCE
GREY = (155, 155, 154, 255)  # #9B9B9A
DARK_GREY = (63, 63, 63, 255)  # #3F3F3F


class Pen:
    """Izgara biriminde çizer; çizgiler ortalanmış ve uçları yuvarlaktır."""

    def __init__(self):
        self.image = Image.new("RGBA", (SIZE * SUPER,) * 2, (0, 0, 0, 0))
        self.draw = ImageDraw.Draw(self.image)

    @staticmethod
    def _px(points):
        return [(x * U, y * U) for x, y in points]

    def _dots(self, points, width):
        r = width * U / 2
        for x, y in self._px(points):
            self.draw.ellipse((x - r, y - r, x + r, y + r), fill=BLACK)

    def polyline(self, points, width=LINE, colour=BLACK):
        px = self._px(points)
        self.draw.line(px, fill=colour, width=round(width * U), joint="curve")
        r = width * U / 2
        for x, y in (px[0], px[-1]):
            self.draw.ellipse((x - r, y - r, x + r, y + r), fill=colour)

    def polygon(self, points, fill, width=LINE):
        self.draw.polygon(self._px(points), fill=fill)
        if width:
            self.polyline(list(points) + [points[0], points[1]], width)
            self._dots(points, width)

    def circle(self, cx, cy, r, fill, width=LINE):
        if width:
            outer = (r + width / 2) * U
            self.draw.ellipse(
                (cx * U - outer, cy * U - outer, cx * U + outer, cy * U + outer),
                fill=BLACK,
            )
        inner = (r - width / 2) * U
        self.draw.ellipse(
            (cx * U - inner, cy * U - inner, cx * U + inner, cy * U + inner),
            fill=fill,
        )

    def rounded(self, x0, y0, x1, y1, radius, fill, width=LINE):
        h = width / 2
        self.draw.rounded_rectangle(
            ((x0 - h) * U, (y0 - h) * U, (x1 + h) * U, (y1 + h) * U),
            radius=(radius + h) * U,
            fill=BLACK,
        )
        self.draw.rounded_rectangle(
            ((x0 + h) * U, (y0 + h) * U, (x1 - h) * U, (y1 - h) * U),
            radius=max(radius - h, 0) * U,
            fill=fill,
        )

    def save(self, name):
        small = self.image.resize((SIZE, SIZE), Image.LANCZOS)
        small.save(OUT / name, optimize=True)


def _strip(p0, p1, half):
    """p0'dan p1'e uzanan, [half] yarı genişlikli dikdörtgen."""
    dx, dy = p1[0] - p0[0], p1[1] - p0[1]
    length = math.hypot(dx, dy)
    nx, ny = -dy / length * half, dx / length * half
    return [
        (p0[0] + nx, p0[1] + ny),
        (p1[0] + nx, p1[1] + ny),
        (p1[0] - nx, p1[1] - ny),
        (p0[0] - nx, p0[1] - ny),
    ]


def _along(p0, p1, t):
    return (p0[0] + (p1[0] - p0[0]) * t, p0[1] + (p1[1] - p0[1]) * t)


def _ring(cx, cy, r_in, r_out, start, end, steps=48):
    """Açılar derece; saat yönünde (ekranda y aşağı)."""
    outer, inner = [], []
    for i in range(steps + 1):
        a = math.radians(start + (end - start) * i / steps)
        outer.append((cx + r_out * math.cos(a), cy + r_out * math.sin(a)))
        inner.append((cx + r_in * math.cos(a), cy + r_in * math.sin(a)))
    return outer + inner[::-1]


def book():
    """Açık kitap, önden ve biraz yukarıdan."""
    pen = Pen()
    # Kapak, sayfaların altından taşar.
    pen.polygon(
        [(4, 20), (36, 26), (68, 20), (68, 54), (36, 60), (4, 54)], RED
    )
    # Kurdele, sırttan sarkar.
    pen.polygon(
        [(40, 50), (45, 49), (45, 64), (42.5, 61.5), (40, 64)], ORANGE
    )
    # Sayfalar; sırtta birleşir.
    left = [(8, 14), (36, 20), (36, 56), (8, 50)]
    right = [(64, 14), (36, 20), (36, 56), (64, 50)]
    pen.polygon(left, WHITE)
    pen.polygon(right, WHITE)
    # Satırlar, sayfanın üst kenarına paralel.
    slope = 6 / 28
    for i in range(5):
        y = 22 + i * 6
        pen.polyline([(12, y), (32, y + 20 * slope)], THIN, GREY)
        pen.polyline([(60, y), (40, y + 20 * slope)], THIN, GREY)
    # Sırt, en üstte.
    pen.polyline([(36, 20), (36, 56)])
    pen.save("book.png")


def microscope():
    """Yandan mikroskop: eğik tüp, C kol, tabla, taban."""
    pen = Pen()
    # Taban ve gövde ayağı.
    pen.rounded(12, 56, 60, 64, 3, GREY)
    pen.rounded(36, 44, 46, 58, 1, LIGHT_GREY)
    # C kol: tüpün arkasından dönüp tablaya iner.
    pen.polygon(_ring(32, 32, 9, 16, -115, 70), LIGHT_GREY)
    # Tabla ve üstündeki lam.
    pen.rounded(14, 42, 50, 48, 1.5, DARK_GREY)
    pen.rounded(20, 39.5, 38, 42.5, 0.8, LIGHT_BLUE)
    # Odak düğmesi.
    pen.circle(47, 33, 4, ORANGE)
    # Tüp: göz merceği yukarıda, objektif aşağıda.
    top, bottom = (22, 10), (30, 34)
    pen.polygon(_strip(_along(top, bottom, 1), (31.5, 38.5), 3), DARK_GREY)
    pen.polygon(_strip(top, bottom, 5.5), BLUE)
    pen.polygon(_strip((20.8, 6.4), _along(top, bottom, 0.12), 6.5), DARK_BLUE)
    # Tüpün üstünde bir parlama çizgisi.
    pen.polyline(
        [_along((20, 11), (28, 35), 0.3), _along((20, 11), (28, 35), 0.75)],
        THIN,
        WHITE,
    )
    pen.save("microscope.png")


def binoculars():
    """Önden dürbün: yukarıda göz mercekleri, aşağıda büyük mercekler."""
    pen = Pen()
    # Köprü ve odak tekerleği, gövdelerin arkasında.
    pen.rounded(28, 26, 44, 42, 2, LIGHT_GREY)
    pen.rounded(32, 16, 40, 30, 2, ORANGE)
    for y in (20, 23, 26):
        pen.polyline([(33.5, y), (38.5, y)], THIN)
    for cx in (21, 51):
        # Göz merceği.
        pen.rounded(cx - 6.5, 10, cx + 6.5, 22, 2, DARK_GREY)
        # Gövde, aşağı doğru genişler.
        pen.polygon(
            [(cx - 8, 20), (cx + 8, 20), (cx + 12, 50), (cx - 12, 50)],
            DARK_BLUE,
        )
        # Büyük mercek: çerçeve, cam, parlama.
        pen.circle(cx, 51, 12, DARK_GREY)
        pen.circle(cx, 51, 8, LIGHT_BLUE)
        pen.circle(cx - 3, 48, 2.2, WHITE, width=0)
    pen.save("binoculars.png")


if __name__ == "__main__":
    book()
    microscope()
    binoculars()
    for name in ("book.png", "microscope.png", "binoculars.png"):
        print(OUT / name)
