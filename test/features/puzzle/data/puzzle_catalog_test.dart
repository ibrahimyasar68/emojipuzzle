import 'package:emoji_puzzle_kids/features/puzzle/data/puzzle_catalog.dart';
import 'package:emoji_puzzle_kids/features/puzzle/models/puzzle_grid.dart';
import 'package:flutter_test/flutter_test.dart';

const _catalog = PuzzleCatalog.v1;

/// §4 — the ladder K-1 = A settled on, six to a level since K-12.
const _expected = {
  1: ['apple_01', 'cat_01', 'ball_01', 'strawberry_01', 'moon_01', 'sheep_01'],
  2: [
    'banana_01',
    'dog_01',
    'bus_01',
    'watermelon_01',
    'bicycle_01',
    'turtle_01',
  ],
  3: [
    'car_01',
    'sun_01',
    'lion_01',
    'pineapple_01',
    'airplane_01',
    'saturn_01',
  ],
};

void main() {
  group('v1 content (§4)', () {
    test('three levels, six puzzles each (K-12)', () {
      expect(_catalog.levels, hasLength(3));
      expect(_catalog.puzzles, hasLength(18));
      for (final level in _catalog.levels) {
        expect(level.puzzles, hasLength(6), reason: 'level ${level.index}');
      }
    });

    test('the new pictures sit in the categories they belong to (K-12)', () {
      const categories = {
        'strawberry_01': 'fruits',
        'watermelon_01': 'fruits',
        'pineapple_01': 'fruits',
        'airplane_01': 'vehicles',
        'bicycle_01': 'vehicles',
        'moon_01': 'nature',
        'saturn_01': 'nature',
        'turtle_01': 'animals',
        'sheep_01': 'animals',
      };
      for (final entry in categories.entries) {
        expect(
          _catalog.byId(entry.key).category.name,
          entry.value,
          reason: entry.key,
        );
      }
    });

    test('every level has a fruit, and no category is left out', () {
      for (final level in _catalog.levels) {
        expect(
          level.puzzles.map((p) => p.category.name),
          contains('fruits'),
          reason: 'level ${level.index}',
        );
      }
      expect(_catalog.byCategory.keys, hasLength(5));
    });

    test('the puzzles are the ones the spec names, in order', () {
      for (final level in _catalog.levels) {
        expect(
          level.puzzles.map((p) => p.id).toList(),
          _expected[level.index],
        );
      }
    });

    test('each level has its own grid', () {
      const grids = {
        1: PuzzleGrid(rows: 2, columns: 2),
        2: PuzzleGrid(rows: 2, columns: 3),
        3: PuzzleGrid(rows: 3, columns: 3),
      };
      for (final level in _catalog.levels) {
        for (final puzzle in level.puzzles) {
          expect(puzzle.grid, grids[level.index], reason: puzzle.id);
        }
      }
    });

    test('every level needs two completions to open the next (§4)', () {
      for (final level in _catalog.levels) {
        expect(level.requiredCompletions, 2);
      }
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

    test('lookups find puzzles and their level', () {
      expect(_catalog.byId('dog_01').displayName, 'Köpek');
      expect(_catalog.levelOf('dog_01').index, 2);
      expect(() => _catalog.byId('nope'), throwsArgumentError);
      expect(() => _catalog.levelOf('nope'), throwsArgumentError);
    });
  });

  group('unlocking (§4)', () {
    test('level 1 is always open, and alone at the start', () {
      expect(_catalog.unlockedLevelCount({}), 1);
      expect(_catalog.isLevelUnlocked(1, {}), isTrue);
      expect(_catalog.isLevelUnlocked(2, {}), isFalse);
    });

    test('one completion is not enough', () {
      expect(_catalog.unlockedLevelCount({'apple_01'}), 1);
    });

    test('two completions open the next level', () {
      expect(_catalog.unlockedLevelCount({'apple_01', 'cat_01'}), 2);
    });

    test('and two more open the last one', () {
      expect(
        _catalog.unlockedLevelCount({
          'apple_01',
          'cat_01',
          'banana_01',
          'dog_01',
        }),
        3,
      );
    });

    test('the ladder never skips a rung', () {
      // Every level 2 puzzle done, but level 1 left unfinished: level 2
      // itself was never open, so nothing above level 1 is either.
      expect(
        _catalog.unlockedLevelCount({'banana_01', 'dog_01', 'bus_01'}),
        1,
      );
    });

    test('unlocking never runs past the last level', () {
      final everything = _catalog.puzzles.map((p) => p.id).toSet();
      expect(_catalog.unlockedLevelCount(everything), 3);
    });
  });

  group('what to play next', () {
    test('starts at the very first puzzle', () {
      expect(_catalog.firstUnsolved({})?.id, 'apple_01');
    });

    test('walks along the level before moving up', () {
      expect(_catalog.firstUnsolved({'apple_01'})?.id, 'cat_01');
      // Level 2 is open now, but the third level 1 puzzle comes first.
      expect(_catalog.firstUnsolved({'apple_01', 'cat_01'})?.id, 'ball_01');
    });

    test('moves up once a level is finished', () {
      expect(
        _catalog.firstUnsolved(_expected[1]!.toSet())?.id,
        'banana_01',
      );
    });

    test('never offers a puzzle from a locked level', () {
      // Only one level 1 puzzle done: level 2 is shut, so the answer has to
      // come from level 1.
      final next = _catalog.firstUnsolved({'apple_01'});
      expect(_catalog.levelOf(next!.id).index, 1);
    });

    test('null when everything open is solved', () {
      final everything = _catalog.puzzles.map((p) => p.id).toSet();
      expect(_catalog.firstUnsolved(everything), isNull);
    });
  });
}
