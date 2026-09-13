"""Uygulama ikonunu tek bir kaynak görselden üretir.

Kullanım:
    python3 tool/generate_app_icon.py [kaynak.png]

Varsayılan kaynak `docs/branding/app-icon-source.png`. Pillow ve numpy gerekir.

Kaynak görselin köşeleri önceden yuvarlatılmış ve zemini beyaz. Mağazalar ve
işletim sistemleri köşe maskesini kendileri uygular, bu yüzden önce beyaz
kenar ve köşeler komşu renklerle doldurulup tam kare bir ana görsel
çıkarılır. Sonra sağ alt köşedeki büyük "IY Labs" rozeti kaldırılır ve
yerine Android'in daire maskesine sığan küçük bir rozet konur. Android, iOS
ve mağaza boyutlarının hepsi o ana görselden üretilir.
"""

import json
import math
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
SOURCE = (
    Path(sys.argv[1])
    if len(sys.argv) > 1
    else ROOT / "docs/branding/app-icon-source.png"
)
RES = ROOT / "android/app/src/main/res"
IOS = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
BRANDING = ROOT / "docs/branding"

MASTER = 1024

# Android yoğunluk çarpanları (mdpi = 1).
DENSITIES = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}

# Adaptive icon: katman 108 dp, maskeden sonra görünen alan ortadaki 72 dp,
# hiçbir maskenin kesmediği güvenli bölge ortadaki 66 dp.
ADAPTIVE_LAYER_DP = 108
ADAPTIVE_VISIBLE_DP = 72
ADAPTIVE_SAFE_DP = 66
LEGACY_DP = 48

# Aşağıdakiler ana görselin 1024 px koordinatlarında, bu kaynak görsele özgü
# ölçümlerdir. Kaynak değişirse yeniden ölçülmelidir.
#
# Büyük rozet bu noktanın sağında ve altında aranır.
SWOOSH_REGION = (600, 700)
# "IY Labs" yazısı ve üstündeki parıltı, lacivert zeminiyle birlikte.
BADGE_TEXT_BOX = (715, 843, 970, 984)
# Rozetin altında kalan kırmızı parçanın sağ alt köşesi. Görünen kısmından
# ölçüldü: sağ kenar x=909, alt kenar y=913 ve y≈715'ten sonra kenar
# 200 px yarıçaplı bir yay çiziyor (740→907, 760→904, 790→891).
RED_RIGHT, RED_BOTTOM, RED_CORNER = 909, 913, 200
# Kenar kesitlerinin rozetin hiç değmediği, dümdüz olduğu yerler.
RED_RIGHT_SAMPLE_Y, RED_BOTTOM_SAMPLE_X = 640, 620
# Yeni rozet: yazı %74 ölçekte, tamamen kırmızı parçanın üstünde ve
# köşeleri 66 dp güvenli bölgenin içinde.
BADGE_SCALE = 0.74
BADGE_BOX = (628, 661, 871, 791)

STEPS4 = [(-1, 0), (1, 0), (0, -1), (0, 1)]
STEPS8 = STEPS4 + [(-1, -1), (-1, 1), (1, -1), (1, 1)]


def _to_image(mask):
    return Image.fromarray((mask * 255).astype("uint8"))


def outer_white_mask(img):
    """Kenardaki beyaz payı ve yuvarlatılmış köşeleri işaretler.

    Doldurma dört köşeden başlar; çizimin içindeki beyazlar (gözler, yazı)
    kenara bağlı olmadığı için etkilenmez.
    """
    marker = (1, 2, 3)
    filled = img.copy()
    w, h = img.size
    for xy in [(0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)]:
        ImageDraw.floodfill(filled, xy, marker, thresh=110)
    mask = np.all(np.asarray(filled) == marker, axis=2)
    # Kenar yumuşatma pikselleri beyazla mavinin karışımıdır ve eşiği geçemez;
    # maske birkaç piksel genişletilerek onlar da kapsanır.
    return np.asarray(_to_image(mask).filter(ImageFilter.MaxFilter(9))) > 0


def _shift(a, dy, dx):
    """a[y+dy, x+dx] değerini (y, x)'e taşır; görüntü dışı sıfırdır (sarmalamaz)."""
    h, w = a.shape[:2]
    pad = ((1, 1), (1, 1)) + ((0, 0),) * (a.ndim - 2)
    return np.pad(a, pad)[1 + dy : 1 + dy + h, 1 + dx : 1 + dx + w]


def _onion_fill(values, mask):
    """İşaretli pikselleri dışarıdan içeriye, bilinen komşularının ortalamasıyla doldurur."""
    out = values.astype(np.float64)
    known = ~mask
    out[mask] = 0
    while not known.all():
        total = np.zeros_like(out)
        count = np.zeros(mask.shape)
        weighted = out * known[..., None]
        for dy, dx in STEPS8:
            total += _shift(weighted, dy, dx)
            count += _shift(known, dy, dx)
        grow = ~known & (count > 0)
        if not grow.any():
            break
        out[grow] = total[grow] / count[grow][:, None]
        known = known | grow
    return out


def _smooth_inside(values, mask, iterations=400):
    """İşaretli bölgeyi, kenarları sabit tutarak yumuşatır (Laplace)."""
    ones = np.ones(mask.shape)
    count = sum(_shift(ones, dy, dx) for dy, dx in STEPS4)
    for _ in range(iterations):
        total = sum(_shift(values, dy, dx) for dy, dx in STEPS4)
        values[mask] = (total / count[..., None])[mask]
    return values


def fill_from_neighbours(rgb, mask):
    return _onion_fill(rgb, mask).round().clip(0, 255).astype(np.uint8)


def build_master(path):
    """Kaynaktan köşesiz, kenara kadar dolu 1024×1024 ana görseli üretir."""
    img = Image.open(path).convert("RGB")
    mask = outer_white_mask(img)
    ys, xs = np.where(~mask)
    # Plakanın kendisine kırpılır; kare olması için kısa kenar esas alınır.
    side = min(xs.max() - xs.min(), ys.max() - ys.min()) + 1
    cx = (xs.min() + xs.max() + 1) // 2
    cy = (ys.min() + ys.max() + 1) // 2
    box = (cx - side // 2, cy - side // 2, cx - side // 2 + side, cy - side // 2 + side)
    rgb = np.asarray(img)[box[1] : box[3], box[0] : box[2]]
    filled = fill_from_neighbours(rgb, mask[box[1] : box[3], box[0] : box[2]])
    return Image.fromarray(filled).resize((MASTER, MASTER), Image.LANCZOS)


def _swoosh_masks(master):
    """Büyük rozetin maskesini döndürür: yalnızca lacivert, ve yazı dahil tamamı."""
    filled = master.copy()
    ImageDraw.floodfill(filled, (MASTER - 2, MASTER - 2), (1, 2, 3), thresh=90)
    ys, xs = np.mgrid[0:MASTER, 0:MASTER]
    navy = np.all(np.asarray(filled) == (1, 2, 3), axis=2)
    navy &= (xs >= SWOOSH_REGION[0]) & (ys >= SWOOSH_REGION[1])
    # Parçaların altındaki koyu gölge çizgileri de lacivertle birleşiyor; ince
    # oldukları için açma (önce daralt, sonra genişlet) işlemiyle atılır.
    opened = _to_image(navy).filter(ImageFilter.MinFilter(15)).filter(ImageFilter.MaxFilter(15))
    navy = np.asarray(opened) > 127
    # Yazı lacivertin içinde bir deliktir; dışarıdan ulaşılamayan her şey rozete dahil.
    outside = _to_image(~navy).convert("RGB")
    ImageDraw.floodfill(outside, (0, 0), (9, 9, 9), thresh=0)
    whole = ~np.all(np.asarray(outside) == (9, 9, 9), axis=2)
    return navy, whole


def _red_corner(xs, ys, image):
    """Kırmızı parçanın sağ alt köşesini görünen kenar kesitlerinden yeniden çizer.

    Her piksel için parça sınırına işaretli mesafe hesaplanır; renk, sağ
    kenarın ve alt kenarın o mesafedeki kesitinden alınır. Yayın üzerinde iki
    kesit açıya göre karıştırılır.
    """
    qx = xs - (RED_RIGHT - RED_CORNER)
    qy = ys - (RED_BOTTOM - RED_CORNER)
    corner = (qx > 0) & (qy > 0)
    distance = np.where(
        corner,
        np.hypot(qx, qy) - RED_CORNER,
        np.where(qx > 0, xs - RED_RIGHT, np.where(qy > 0, ys - RED_BOTTOM, np.maximum(qx, qy) - RED_CORNER)),
    )
    angle = np.where(corner, np.arctan2(qy, qx) / (np.pi / 2), np.where(qy > qx, 1.0, 0.0))
    distance = np.clip(distance, -60, 110)
    right = image[RED_RIGHT_SAMPLE_Y, np.clip(np.round(RED_RIGHT + distance).astype(int), 0, MASTER - 1)]
    bottom = image[np.clip(np.round(RED_BOTTOM + distance).astype(int), 0, MASTER - 1), RED_BOTTOM_SAMPLE_X]
    return right * (1 - angle[..., None]) + bottom * angle[..., None]


def replace_badge(master):
    """Büyük rozeti kaldırır, yerine güvenli bölgeye sığan küçük bir rozet koyar.

    Büyük rozet daire maskeli launcher'larda (Pixel) kesiliyor ve yalnızca
    "IY" görünüyordu.
    """
    image = np.asarray(master).astype(np.float64)
    navy_mask, whole = _swoosh_masks(master)
    navy = tuple(int(v) for v in np.median(image[navy_mask], axis=0))
    text = master.crop(BADGE_TEXT_BOX)
    hole = np.asarray(_to_image(whole).filter(ImageFilter.MaxFilter(11))) > 0

    # Rozetin altı: sentezlenen köşe, sonra kenardaki farkın içeri yayılmasıyla
    # çevresine dikişsiz bağlanır.
    x0, y0 = 560, 680
    ys, xs = np.mgrid[y0:MASTER, x0:MASTER]
    synth = _red_corner(xs, ys, image)
    inside = hole[y0:, x0:]
    residual = image[y0:, x0:] - synth
    residual = _smooth_inside(_onion_fill(residual, inside), inside)
    block = image[y0:, x0:]
    block[inside] = (synth + residual)[inside]
    cleaned = Image.fromarray(image.round().clip(0, 255).astype(np.uint8)).convert("RGBA")

    left, top, right, bottom = BADGE_BOX
    height = bottom - top
    tw, th = round(text.width * BADGE_SCALE), round(text.height * BADGE_SCALE)
    shadow = Image.new("RGBA", cleaned.size, (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle((left, top + 8, right, bottom + 8), radius=height // 2, fill=(0, 10, 40, 110))
    cleaned = Image.alpha_composite(cleaned, shadow.filter(ImageFilter.GaussianBlur(9)))
    pill = Image.new("RGBA", cleaned.size, (0, 0, 0, 0))
    ImageDraw.Draw(pill).rounded_rectangle(BADGE_BOX, radius=height // 2, fill=navy + (255,))
    result = Image.alpha_composite(cleaned, pill).convert("RGB")
    result.paste(
        text.resize((tw, th), Image.LANCZOS),
        (left + (right - left - tw) // 2, top + (height - th) // 2),
    )
    return result


def check_badge_in_safe_zone():
    safe = MASTER / 2 * ADAPTIVE_SAFE_DP / ADAPTIVE_VISIBLE_DP
    left, top, right, bottom = BADGE_BOX
    farthest = max(math.hypot(x - MASTER / 2, y - MASTER / 2) for x in (left, right) for y in (top, bottom))
    print(f"rozetin en uzak köşesi: {farthest:.0f} px, güvenli bölge: {safe:.0f} px")
    if farthest > safe:
        sys.exit("rozet 66 dp güvenli bölgenin dışına taşıyor")


def save_png(img, path):
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path, "PNG", optimize=True)


def write_android(master):
    for name, scale in DENSITIES.items():
        folder = RES / f"mipmap-{name}"
        # API 24–25 için düz ikon.
        legacy = round(LEGACY_DP * scale)
        save_png(master.resize((legacy, legacy), Image.LANCZOS), folder / "ic_launcher.png")
        # API 26+ için ön plan katmanı: çizim görünen 72 dp'yi doldurur, dıştaki
        # 18 dp'lik pay (maske ve paralaks efekti için) kenar renkleriyle uzatılır.
        layer = round(ADAPTIVE_LAYER_DP * scale)
        visible = round(ADAPTIVE_VISIBLE_DP * scale)
        pad = (layer - visible) // 2
        art = np.asarray(master.resize((visible, visible), Image.LANCZOS))
        padded = np.pad(art, ((pad, layer - visible - pad), (pad, layer - visible - pad), (0, 0)), mode="edge")
        save_png(Image.fromarray(padded), folder / "ic_launcher_foreground.png")

    # Ön plan opak olduğu için arka plan yalnızca paralaks sırasında görünür;
    # üst kenarın rengi seçilir.
    top = np.median(np.asarray(master)[:8].reshape(-1, 3), axis=0).astype(int)
    colour = "#{:02X}{:02X}{:02X}".format(*top)
    (RES / "values").mkdir(exist_ok=True)
    (RES / "values/ic_launcher_background.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        "<resources>\n"
        f'    <color name="ic_launcher_background">{colour}</color>\n'
        "</resources>\n"
    )
    (RES / "mipmap-anydpi-v26").mkdir(exist_ok=True)
    (RES / "mipmap-anydpi-v26/ic_launcher.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@color/ic_launcher_background" />\n'
        '    <foreground android:drawable="@mipmap/ic_launcher_foreground" />\n'
        "</adaptive-icon>\n"
    )


def write_ios(master):
    # App Store alfa kanalı kabul etmez; hepsi RGB kaydedilir.
    contents = json.loads((IOS / "Contents.json").read_text())
    for image in contents["images"]:
        points = float(image["size"].split("x")[0])
        pixels = round(points * int(image["scale"].rstrip("x")))
        save_png(master.resize((pixels, pixels), Image.LANCZOS), IOS / image["filename"])


def main():
    check_badge_in_safe_zone()
    master = replace_badge(build_master(SOURCE))
    edge = np.concatenate([np.asarray(master)[[0, -1]].reshape(-1, 3), np.asarray(master)[:, [0, -1]].reshape(-1, 3)])
    near_white = int((edge.min(axis=1) > 200).sum())
    print(f"kenarda beyaza yakın piksel: {near_white}")
    save_png(master, BRANDING / "app-icon-1024.png")
    save_png(master.resize((512, 512), Image.LANCZOS), BRANDING / "play-store-icon-512.png")
    write_android(master)
    write_ios(master)
    print("tamam")


if __name__ == "__main__":
    main()
