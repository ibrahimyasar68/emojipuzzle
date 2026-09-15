import 'dart:ui' show Offset, Path, Radius, RRect, Rect;

import '../models/car_model.dart';

/// Boyama defterindeki arabalar, sırayla (§24.2, K-7).
///
/// Her parça, en dar ekranda (320 dp) bile görünen alanına 64 px'lik bir
/// daire sığacak kadar iri çizilmiştir (§2, K-8). Bu tahmin değil, ölçüdür:
/// `test/features/colouring/car_catalog_test.dart`. Küçük ayrıntılar (far,
/// jant) bu yüzden parça değil, boyanmayan süs çizgisidir.
abstract final class CarCatalog {
  static final List<CarModel> models = [
    _sedan(),
    _pickup(),
    _racer(),
    _truck(),
    _tractor(),
  ];

  static CarModel _sedan() => CarModel(
        id: 'sedan',
        parts: [
          CarPart(
            id: 'body',
            path: Path()
              ..addRRect(
                RRect.fromRectAndRadius(
                  const Rect.fromLTRB(3, 36, 97, 66),
                  const Radius.circular(9),
                ),
              ),
          ),
          CarPart(
            id: 'rear-window',
            path: _polygon(const [
              Offset(17, 37),
              Offset(30, 8),
              Offset(49, 8),
              Offset(49, 37),
            ]),
          ),
          CarPart(
            id: 'front-window',
            path: _polygon(const [
              Offset(53, 37),
              Offset(53, 8),
              Offset(71, 8),
              Offset(86, 37),
            ]),
          ),
          CarPart(id: 'rear-wheel', path: _circle(const Offset(25, 66), 13.5)),
          CarPart(id: 'front-wheel', path: _circle(const Offset(75, 66), 13.5)),
        ],
        details: [
          _circle(const Offset(25, 66), 5),
          _circle(const Offset(75, 66), 5),
          Path()
            ..moveTo(51, 38)
            ..lineTo(51, 56),
          Path()
            ..moveTo(56, 44)
            ..lineTo(62, 44),
        ],
      );

  static CarModel _pickup() => CarModel(
        id: 'pickup',
        parts: [
          CarPart(
            id: 'bed',
            path: Path()
              ..addRRect(
                RRect.fromRectAndRadius(
                  const Rect.fromLTRB(3, 30, 51, 64),
                  const Radius.circular(4),
                ),
              ),
          ),
          CarPart(
            id: 'cab',
            path: _polygon(const [
              Offset(49, 30),
              Offset(97, 30),
              Offset(97, 64),
              Offset(49, 64),
            ]),
          ),
          CarPart(
            id: 'window',
            path: _polygon(const [
              Offset(49, 31),
              Offset(49, 6),
              Offset(72, 6),
              Offset(94, 31),
            ]),
          ),
          CarPart(id: 'rear-wheel', path: _circle(const Offset(25, 66), 12.5)),
          CarPart(id: 'front-wheel', path: _circle(const Offset(76, 66), 12.5)),
        ],
        details: [
          _circle(const Offset(25, 66), 4.5),
          _circle(const Offset(76, 66), 4.5),
          Path()
            ..moveTo(84, 40)
            ..lineTo(92, 40),
        ],
      );

  static CarModel _racer() => CarModel(
        id: 'racer',
        parts: [
          CarPart(
            id: 'spoiler',
            path: Path()
              ..addRRect(
                RRect.fromRectAndRadius(
                  const Rect.fromLTRB(2, 12, 29, 36),
                  const Radius.circular(4),
                ),
              ),
          ),
          CarPart(
            id: 'body',
            path: _polygon(const [
              Offset(3, 64),
              Offset(3, 40),
              Offset(28, 34),
              Offset(62, 34),
              Offset(97, 46),
              Offset(97, 64),
            ]),
          ),
          CarPart(
            id: 'helmet',
            path: Path()..addOval(const Rect.fromLTRB(34, 10, 64, 38)),
          ),
          CarPart(id: 'rear-wheel', path: _circle(const Offset(22, 66), 13.5)),
          CarPart(id: 'front-wheel', path: _circle(const Offset(78, 66), 13.5)),
        ],
        details: [
          _circle(const Offset(22, 66), 5),
          _circle(const Offset(78, 66), 5),
          Path()
            ..moveTo(14, 36)
            ..lineTo(14, 41),
          Path()
            ..moveTo(40, 22)
            ..lineTo(58, 22),
        ],
      );

  /// Kamyon: büyük kasa, önde kabin, üç teker. Cam kabinin içinde bir süs
  /// çizgisidir: ayrı bir parça olsaydı kabini dokunulamayacak kadar
  /// inceltirdi (K-8).
  static CarModel _truck() => CarModel(
        id: 'truck',
        parts: [
          CarPart(
            id: 'box',
            path: Path()
              ..addRRect(
                RRect.fromRectAndRadius(
                  const Rect.fromLTRB(3, 10, 62, 60),
                  const Radius.circular(3),
                ),
              ),
          ),
          CarPart(
            id: 'cab',
            path: _polygon(const [
              Offset(64, 60),
              Offset(64, 14),
              Offset(80, 14),
              Offset(97, 34),
              Offset(97, 60),
            ]),
          ),
          CarPart(id: 'rear-wheel', path: _circle(const Offset(17, 67), 12)),
          CarPart(id: 'middle-wheel', path: _circle(const Offset(44, 67), 12)),
          CarPart(id: 'front-wheel', path: _circle(const Offset(81, 67), 12)),
        ],
        details: [
          _polygon(const [
            Offset(68, 18),
            Offset(79, 18),
            Offset(91, 32),
            Offset(68, 32),
          ]),
          _circle(const Offset(17, 67), 4.5),
          _circle(const Offset(44, 67), 4.5),
          _circle(const Offset(81, 67), 4.5),
          Path()
            ..moveTo(22, 16)
            ..lineTo(22, 50),
          Path()
            ..moveTo(42, 16)
            ..lineTo(42, 50),
        ],
      );

  /// Traktör: arkada yüksek kabin ve kocaman teker, önde kaput, ızgaralı ön
  /// panel ve küçük teker. Egzoz, cam ve ızgara çizgileri süstür.
  ///
  /// Ön panel bir far değil, bilerek dikdörtgen: aynı yere konan yuvarlak
  /// bir far teker kadar büyük olmak zorundaydı (64 px, K-8) ve boyanınca
  /// havada duran üçüncü bir teker gibi görünüyordu.
  static CarModel _tractor() => CarModel(
        id: 'tractor',
        parts: [
          CarPart(
            id: 'cab',
            path: Path()
              ..addRRect(
                RRect.fromRectAndRadius(
                  const Rect.fromLTRB(8, 3, 44, 32),
                  const Radius.circular(4),
                ),
              ),
          ),
          CarPart(
            id: 'hood',
            path: Path()
              ..addRRect(
                RRect.fromRectAndRadius(
                  const Rect.fromLTRB(30, 30, 75, 58),
                  const Radius.circular(4),
                ),
              ),
          ),
          CarPart(
            id: 'grille',
            path: Path()
              ..addRRect(
                RRect.fromRectAndRadius(
                  const Rect.fromLTRB(73, 30, 97, 58),
                  const Radius.circular(4),
                ),
              ),
          ),
          CarPart(id: 'rear-wheel', path: _circle(const Offset(25, 57), 21)),
          CarPart(id: 'front-wheel', path: _circle(const Offset(82, 68), 12)),
        ],
        details: [
          Path()
            ..addRRect(
              RRect.fromRectAndRadius(
                const Rect.fromLTRB(14, 8, 38, 26),
                const Radius.circular(2),
              ),
            ),
          Path()
            ..moveTo(62, 30)
            ..lineTo(62, 14),
          for (final y in const [37.0, 43.0, 49.0])
            Path()
              ..moveTo(78, y)
              ..lineTo(92, y),
          _circle(const Offset(25, 57), 8),
          _circle(const Offset(82, 68), 4.5),
        ],
      );

  static Path _polygon(List<Offset> points) => Path()..addPolygon(points, true);

  static Path _circle(Offset centre, double radius) =>
      Path()..addOval(Rect.fromCircle(center: centre, radius: radius));
}
