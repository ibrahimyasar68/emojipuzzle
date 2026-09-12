import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// §33 — no picture in this app comes from the platform's emoji font.
///
/// "Emoji/görsel asset'leri platform emoji glyph'lerinden alınmaz.
/// `Text("🍎")` kullanılmaz." A glyph is drawn by whatever font the device
/// happens to have: it looks different on every phone, it cannot be cut
/// into puzzle pieces, and on some devices it is not there at all. The
/// artwork ships with the app instead (OpenMoji, see assets/LICENSES.md),
/// and so do the icons.
///
/// Read from the source, not from memory.
final _emoji = RegExp(
  r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\u{1F000}-\u{1F2FF}]',
  unicode: true,
);

List<File> _dartFilesIn(String directory) => Directory(directory)
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'))
    .toList();

void main() {
  test('no emoji glyphs anywhere in the app (§33)', () {
    final files = _dartFilesIn('lib');
    expect(files, isNotEmpty);

    final offences = <String>[];
    for (final file in files) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        // Comments may name an emoji; only code is the problem.
        if (line.trimLeft().startsWith('//')) continue;
        if (_emoji.hasMatch(line)) {
          offences.add('${file.path}:${i + 1}: ${line.trim()}');
        }
      }
    }

    expect(
      offences,
      isEmpty,
      reason: 'these draw a platform glyph instead of a shipped asset:\n'
          '${offences.join('\n')}',
    );
  });

  test('the detector would notice one', () {
    expect(_emoji.hasMatch("const a = '🍎';"), isTrue);
    expect(_emoji.hasMatch("const a = 'apple';"), isFalse);
  });

  test('every shipped asset is accounted for in LICENSES.md (§33)', () {
    final licences = File('assets/LICENSES.md').readAsStringSync();

    final shipped = <String>[
      for (final directory in ['assets/images/puzzles', 'assets/audio/sfx'])
        ...Directory(directory)
            .listSync()
            .whereType<File>()
            .map((f) => f.uri.pathSegments.last),
    ];

    expect(shipped, isNotEmpty);
    for (final asset in shipped) {
      expect(
        licences.contains(asset),
        isTrue,
        reason: '$asset ships with the app but is not in assets/LICENSES.md',
      );
    }
  });

  test('the release build asks for no permissions (§35)', () {
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();

    // No ads, no analytics, nothing to send: a child's game has no reason
    // to reach the network, and asking would be a question the store and
    // the parent both deserve a "no" to.
    expect(
      manifest.contains('uses-permission'),
      isFalse,
      reason: 'the shipped manifest should ask for nothing at all',
    );
  });
}
