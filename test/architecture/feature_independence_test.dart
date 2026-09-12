import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'engine_purity_test.dart' show directivesIn;

/// §24 / §36 — the balloon mini game is its own feature.
///
/// "Ayrı bir feature modülüdür. Puzzle feature'ına bağımlı olmaz." A
/// reward that reaches into the puzzle for a piece, a provider or a colour
/// stops being a reward and becomes part of the puzzle screen, and the
/// next mini game (§47) has to start from nothing.
///
/// Read from the files themselves, not from memory.
const _packageName = 'emoji_puzzle_kids';

List<File> _dartFilesIn(String directory) => Directory(directory)
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'))
    .toList();

/// Imports that reach from [from] into [into], as `file → import`.
List<String> crossFeatureImports(String from, String into) {
  final offences = <String>[];
  for (final file in _dartFilesIn(from)) {
    for (final uri in directivesIn(file.readAsStringSync())) {
      final resolved = uri.startsWith('package:$_packageName/')
          ? 'lib/${uri.substring('package:$_packageName/'.length)}'
          : uri.startsWith('package:') || uri.startsWith('dart:')
              ? null
              : File(file.absolute.uri.resolve(uri).toFilePath())
                  .path
                  .replaceFirst('${Directory.current.path}/', '');
      if (resolved != null && resolved.startsWith(into)) {
        offences.add('${file.path} → $uri');
      }
    }
  }
  return offences;
}

void main() {
  test('the balloon game does not depend on the puzzle (§24, §36)', () {
    final balloonFiles = _dartFilesIn('lib/features/balloon');
    expect(balloonFiles, isNotEmpty, reason: 'the feature must exist');

    expect(
      crossFeatureImports('lib/features/balloon', 'lib/features/puzzle'),
      isEmpty,
    );
  });

  test('the detector would notice if it did', () {
    // The puzzle screen is allowed to reach into the balloon feature — it
    // is the one putting the reward on screen — so it makes a good proof
    // that this test is looking at anything at all.
    expect(
      crossFeatureImports('lib/features/puzzle', 'lib/features/balloon'),
      isNotEmpty,
    );
  });

  test('the celebration does not depend on the puzzle either (§36)', () {
    expect(
      crossFeatureImports('lib/features/celebration', 'lib/features/puzzle'),
      isEmpty,
    );
  });
}
