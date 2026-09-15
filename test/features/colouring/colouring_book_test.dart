import 'dart:convert';

import 'package:emoji_puzzle_kids/core/services/storage_service.dart';
import 'package:emoji_puzzle_kids/features/colouring/data/car_catalog.dart';
import 'package:emoji_puzzle_kids/features/colouring/providers/colouring_book.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Paint is a colour, not a place in a list (K-9).
const _red = 0xFFE53935;
const _blue = 0xFF1E88E5;

Future<StorageService> _storage([Map<String, Object> values = const {}]) {
  SharedPreferences.setMockInitialValues(values);
  return StorageService.create();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a new book opens on the first car, nothing painted', () async {
    final book = ColouringBook(storage: await _storage());
    addTearDown(book.dispose);
    book.load();

    expect(book.car.id, CarCatalog.models.first.id);
    expect(book.fills, isEmpty);
    expect(book.isCarComplete, isFalse);
  });

  test('a painted part keeps its colour after a restart (§24.2)', () async {
    final storage = await _storage();
    final first = ColouringBook(storage: storage);
    await first.paint('body', _blue);
    first.dispose();

    final second = ColouringBook(storage: storage)..load();
    addTearDown(second.dispose);
    expect(second.colourOf('body'), _blue);
    expect(second.car.id, 'sedan');
  });

  test('a part can be painted again', () async {
    final book = ColouringBook(storage: await _storage());
    addTearDown(book.dispose);

    await book.paint('body', _red);
    await book.paint('body', _blue);

    expect(book.colourOf('body'), _blue);
    expect(book.fills, hasLength(1));
  });

  test('parts that do not exist, and see-through paint, are ignored', () async {
    final book = ColouringBook(storage: await _storage());
    addTearDown(book.dispose);

    await book.paint('wing-of-a-plane', _red);
    await book.paint('body', 0x00FF0000);
    await book.paint('body', 0x80FF0000);
    await book.paint('body', -1);

    expect(book.fills, isEmpty);
  });

  test('painting every part completes the car', () async {
    final book = ColouringBook(storage: await _storage());
    addTearDown(book.dispose);

    final parts = book.car.parts;
    for (final part in parts.take(parts.length - 1)) {
      await book.paint(part.id, _red);
    }
    expect(book.isCarComplete, isFalse, reason: 'one part still white');

    await book.paint(parts.last.id, _red);
    expect(book.isCarComplete, isTrue);
  });

  test(
      'the next car is a different model, and the last leads back to '
      'the first', () async {
    final storage = await _storage();
    final book = ColouringBook(storage: storage);
    addTearDown(book.dispose);
    await book.paint('body', _red);

    final seen = <String>[book.car.id];
    for (var i = 0; i < CarCatalog.models.length; i++) {
      await book.startNextCar();
      expect(book.fills, isEmpty, reason: 'a new car starts white');
      seen.add(book.car.id);
    }

    expect(seen.toSet(), hasLength(CarCatalog.models.length));
    expect(seen.last, seen.first, reason: 'round again');

    await book.startNextCar();
    final reopened = ColouringBook(storage: storage)..load();
    addTearDown(reopened.dispose);
    expect(reopened.car.id, book.car.id, reason: 'the new car is saved too');
  });

  test('clearing progress takes the book back to a blank first car (§26)',
      () async {
    final storage = await _storage();
    final book = ColouringBook(storage: storage);
    addTearDown(book.dispose);
    await book.startNextCar();
    await book.paint('cab', _red);

    await book.clear();
    expect(book.car.id, CarCatalog.models.first.id);
    expect(book.fills, isEmpty);

    final reopened = ColouringBook(storage: storage)..load();
    addTearDown(reopened.dispose);
    expect(reopened.car.id, CarCatalog.models.first.id);
    expect(reopened.fills, isEmpty);
  });

  group('a damaged record is never shown to the child (§25.1)', () {
    for (final entry in <String, String>{
      'not JSON': '{{{',
      'a list': '[1, 2]',
      'a newer version': jsonEncode({'version': 99, 'car': 'pickup'}),
      'a car that no longer exists':
          jsonEncode({'version': 1, 'car': 'rocket', 'fills': <String, int>{}}),
      'fills of the wrong type':
          jsonEncode({'version': 1, 'car': 'sedan', 'fills': 'red'}),
    }.entries) {
      test(entry.key, () async {
        final book = ColouringBook(
          storage: await _storage({ColouringBook.storageKey: entry.value}),
        )..load();
        addTearDown(book.dispose);

        expect(book.car.id, CarCatalog.models.first.id);
        expect(book.fills, isEmpty);
      });
    }

    test('unknown parts and colours are dropped, the rest kept', () async {
      final book = ColouringBook(
        storage: await _storage({
          ColouringBook.storageKey: jsonEncode({
            'version': 1,
            'car': 'pickup',
            'fills': {
              'cab': _blue,
              'wing': _red,
              'bed': 0x20FFFFFF,
              'window': 'blue',
            },
          }),
        }),
      )..load();
      addTearDown(book.dispose);

      expect(book.car.id, 'pickup');
      expect(book.fills, {'cab': _blue});
    });
  });

  test('finished cars are remembered: the last three, oldest first (K-15)',
      () async {
    final storage = await _storage();
    final book = ColouringBook(storage: storage);
    addTearDown(book.dispose);

    for (var i = 0; i < 4; i++) {
      await book.paint(book.car.parts.first.id, _red);
      await book.startNextCar();
    }

    expect(
      book.recentCars.map((c) => c.model.id),
      [
        CarCatalog.models[1].id,
        CarCatalog.models[2].id,
        CarCatalog.models[3].id,
      ],
    );
    expect(
      book.recentCars.first.fills,
      {CarCatalog.models[1].parts.first.id: _red},
      reason: 'with the paint it had when it left',
    );

    final reopened = ColouringBook(storage: storage)..load();
    addTearDown(reopened.dispose);
    expect(
      reopened.recentCars.map((c) => c.model.id),
      book.recentCars.map((c) => c.model.id),
    );
    expect(reopened.recentCars.last.fills, book.recentCars.last.fills);

    await book.clear();
    expect(book.recentCars, isEmpty, reason: 'a reset forgets them too (§26)');
  });

  test('a remembered car this build no longer has is left out', () async {
    final book = ColouringBook(
      storage: await _storage({
        ColouringBook.storageKey: jsonEncode({
          'version': 1,
          'car': 'pickup',
          'fills': <String, int>{},
          'recent': [
            {'car': 'rocket', 'fills': <String, int>{}},
            {
              'car': 'sedan',
              'fills': {'body': _blue},
            },
            'not a car',
          ],
        }),
      }),
    )..load();
    addTearDown(book.dispose);

    expect(book.recentCars.map((c) => c.model.id), ['sedan']);
    expect(book.recentCars.single.fills, {'body': _blue});
  });

  test('a book saved before cars were remembered still opens', () async {
    final book = ColouringBook(
      storage: await _storage({
        ColouringBook.storageKey: jsonEncode({
          'version': 1,
          'car': 'racer',
          'fills': {'body': _red},
        }),
      }),
    )..load();
    addTearDown(book.dispose);

    expect(book.car.id, 'racer');
    expect(book.fills, {'body': _red});
    expect(book.recentCars, isEmpty);
  });
}
