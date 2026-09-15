import 'dart:math' as math;

import 'package:emoji_puzzle_kids/features/colouring/data/car_catalog.dart';
import 'package:emoji_puzzle_kids/core/constants/puzzle_config.dart';
import 'package:emoji_puzzle_kids/features/colouring/models/car_model.dart';
import 'package:emoji_puzzle_kids/features/colouring/widgets/colouring_layout.dart';

import 'colouring_layout_test.dart' show colouringScreens;
import 'package:flutter_test/flutter_test.dart';

/// Grid step, in design units, for measuring the visible part of each part.
const _step = 0.5;

/// The radius, in design units, of the largest disc that fits inside what
/// can be seen of [part] once the parts drawn over it are taken away.
double inscribedRadiusOf(CarModel model, CarPart part) {
  final above = model.parts.sublist(model.parts.indexOf(part) + 1);
  final width = (CarModel.designSize.width / _step).round();
  final height = (CarModel.designSize.height / _step).round();

  bool visible(int x, int y) {
    if (x < 0 || y < 0 || x > width || y > height) return false;
    final point = Offset(x * _step, y * _step);
    if (!part.path.contains(point)) return false;
    return !above.any((p) => p.path.contains(point));
  }

  final mask = [
    for (var y = 0; y <= height; y++)
      [for (var x = 0; x <= width; x++) visible(x, y)],
  ];
  bool at(int x, int y) =>
      x >= 0 && y >= 0 && x <= width && y <= height && mask[y][x];

  final edge = <Offset>[];
  final inside = <Offset>[];
  for (var y = -1; y <= height + 1; y++) {
    for (var x = -1; x <= width + 1; x++) {
      if (at(x, y)) {
        inside.add(Offset(x.toDouble(), y.toDouble()));
      } else if (at(x + 1, y) || at(x - 1, y) || at(x, y + 1) || at(x, y - 1)) {
        edge.add(Offset(x.toDouble(), y.toDouble()));
      }
    }
  }

  var best = 0.0;
  for (final centre in inside) {
    var nearest = double.infinity;
    for (final e in edge) {
      nearest = math.min(nearest, (e - centre).distance);
      if (nearest <= best) break;
    }
    best = math.max(best, nearest);
  }
  return best * _step;
}

void main() {
  test('three different cars, five or six parts each (§24.2, K-8)', () {
    final models = CarCatalog.models;
    expect(models, hasLength(3));
    expect(models.map((m) => m.id).toSet(), hasLength(models.length));

    for (final model in models) {
      expect(model.parts.length, inInclusiveRange(5, 6), reason: model.id);
      expect(
        model.parts.map((p) => p.id).toSet(),
        hasLength(model.parts.length),
        reason: '${model.id}: part ids are unique',
      );
      for (final part in model.parts) {
        final bounds = part.path.getBounds();
        expect(
          (Offset.zero & CarModel.designSize).intersect(bounds),
          bounds,
          reason: '${model.id}/${part.id} stays on the drawing',
        );
      }
    }
  });

  test(
      'every part can be hit with a child\'s finger, on every screen '
      '(§2, K-8)', () {
    // The smallest drawing scale the layout ever uses.
    final smallest = colouringScreens.values
        .map((size) => ColouringLayout.of(size).scale)
        .reduce(math.min);
    final needed = PuzzleConfig.minTouchTargetSize / 2 / smallest;

    for (final model in CarCatalog.models) {
      for (final part in model.parts) {
        final radius = inscribedRadiusOf(model, part);
        // ignore: avoid_print
        print('${model.id}/${part.id}: ${radius.toStringAsFixed(2)} units, '
            'needs ${needed.toStringAsFixed(2)}');
        expect(
          radius,
          greaterThanOrEqualTo(needed),
          reason: '${model.id}/${part.id}: a 64 px disc must fit inside what '
              'can be seen of it at scale ${smallest.toStringAsFixed(2)}',
        );
      }
    }
  });

  test('a tap goes to the part on top', () {
    final sedan = CarCatalog.models.firstWhere((m) => m.id == 'sedan');

    expect(sedan.partAt(const Offset(25, 66))?.id, 'rear-wheel',
        reason: 'the wheel is drawn over the body');
    expect(sedan.partAt(const Offset(50, 50))?.id, 'body');
    expect(sedan.partAt(const Offset(40, 25))?.id, 'rear-window');
    expect(sedan.partAt(const Offset(2, 2)), isNull, reason: 'paper');
  });
}
