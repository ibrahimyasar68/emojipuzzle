import 'dart:io';
import 'dart:ui' as ui;

import 'package:emoji_puzzle_kids/features/puzzle/data/puzzle_catalog.dart';
import 'package:emoji_puzzle_kids/features/puzzle/models/puzzle_category.dart';
import 'package:flutter_test/flutter_test.dart';

const _catalog = PuzzleCatalog.v1;

void main() {
  group('the picture pool (§4, K-12, K-15)', () {
    test('twenty-one pictures, no levels', () {
      expect(_catalog.puzzles, hasLength(21));
    });

    test('ids and asset paths are unique and follow §34 naming', () {
      final ids = _catalog.puzzles.map((p) => p.id).toList();
      final paths = _catalog.puzzles.map((p) => p.imagePath).toList();

      expect(ids.toSet(), hasLength(ids.length));
      expect(paths.toSet(), hasLength(paths.length));
      for (final puzzle in _catalog.puzzles) {
        expect(puzzle.imagePath, startsWith('assets/images/puzzles/'));
        expect(puzzle.imagePath, endsWith('.png'));
        expect(puzzle.displayName, isNotEmpty);
      }
    });

    test('a pool of at least fifteen: a whole game never repeats a picture',
        () {
      // Three cars of five stages each (K-15).
      expect(_catalog.puzzles.length, greaterThanOrEqualTo(3 * 5));
    });

    test('the new pictures sit in the categories they belong to (K-12)', () {
      const categories = {
        'strawberry_01': PuzzleCategory.fruits,
        'watermelon_01': PuzzleCategory.fruits,
        'pineapple_01': PuzzleCategory.fruits,
        'airplane_01': PuzzleCategory.vehicles,
        'bicycle_01': PuzzleCategory.vehicles,
        'moon_01': PuzzleCategory.nature,
        'saturn_01': PuzzleCategory.nature,
        'turtle_01': PuzzleCategory.animals,
        'sheep_01': PuzzleCategory.animals,
      };
      for (final entry in categories.entries) {
        expect(_catalog.byId(entry.key).category, entry.value,
            reason: entry.key);
      }
    });

    test('the album groups every picture, each category once', () {
      final grouped = _catalog.byCategory;
      expect(
        grouped.values.expand((p) => p).map((p) => p.id).toSet(),
        _catalog.puzzles.map((p) => p.id).toSet(),
      );
      expect(grouped.keys, PuzzleCategory.values);
    });

    test('Eşyalar holds the book, the microscope and the binoculars (K-14)',
        () {
      expect(
        _catalog.byCategory[PuzzleCategory.objects]!.map((p) => p.id),
        ['book_01', 'microscope_01', 'binoculars_01'],
      );
    });

    test('every picture is a file that ships (§34)', () {
      for (final puzzle in _catalog.puzzles) {
        expect(
          File(puzzle.imagePath).existsSync(),
          isTrue,
          reason: puzzle.imagePath,
        );
      }
    });

    testWidgets('every picture is square, with a transparent ground (§34)', (
      tester,
    ) async {
      await tester.runAsync(() async {
        for (final puzzle in _catalog.puzzles) {
          final bytes = File(puzzle.imagePath).readAsBytesSync();
          final codec = await ui.instantiateImageCodec(bytes);
          final image = (await codec.getNextFrame()).image;
          final pixels = (await image.toByteData())!;
          expect(image.width, image.height, reason: puzzle.id);
          expect(image.width, lessThanOrEqualTo(1024), reason: puzzle.id);
          // The corner is empty: the app paints the ground (§34).
          expect(pixels.getUint8(3), 0, reason: puzzle.id);
          image.dispose();
          codec.dispose();
        }
      });
    });

    test('lookups find pictures, or say they are not there', () {
      expect(_catalog.byId('dog_01').displayName, 'Köpek');
      expect(() => _catalog.byId('nope'), throwsArgumentError);
      expect(_catalog.findById('dog_01')?.id, 'dog_01');
      expect(_catalog.findById('dragon_99'), isNull);
    });
  });
}
