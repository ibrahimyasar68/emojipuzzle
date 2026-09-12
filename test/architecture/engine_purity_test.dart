import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// §5 / §41 — The puzzle engine must not depend on Flutter's widget layers.
///
/// Imports are followed transitively through project files, so the engine
/// cannot sneak a widget dependency in via a model or a core constant.

const _packageName = 'emoji_puzzle_kids';
const _engineDir = 'lib/features/puzzle/engine';
const _bannedImports = {
  'package:flutter/material.dart',
  'package:flutter/widgets.dart',
  'package:flutter/cupertino.dart',
};

final _directivePattern = RegExp(
  r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
  multiLine: true,
);

List<String> directivesIn(String source) =>
    _directivePattern.allMatches(source).map((m) => m.group(1)!).toList();

/// Absolute path of a project-local import, or null for `dart:` / other
/// packages.
String? resolveLocal(String uri, File from) {
  if (uri.startsWith('package:$_packageName/')) {
    final relative = uri.substring('package:$_packageName/'.length);
    return File('lib/$relative').absolute.path;
  }
  if (uri.startsWith('package:') || uri.startsWith('dart:')) return null;
  return from.absolute.uri.resolve(uri).toFilePath();
}

/// Human-readable violations: `chain → banned import`.
List<String> findViolations(Iterable<File> roots) {
  final violations = <String>[];
  final visited = <String>{};
  final queue = <(File, List<String>)>[
    for (final f in roots) (f, [f.path]),
  ];

  while (queue.isNotEmpty) {
    final (file, chain) = queue.removeAt(0);
    if (!visited.add(file.absolute.path)) continue;

    for (final uri in directivesIn(file.readAsStringSync())) {
      if (_bannedImports.contains(uri)) {
        violations.add('${chain.join(' → ')} imports $uri');
        continue;
      }
      final local = resolveLocal(uri, file);
      if (local != null) {
        final next = File(local);
        queue.add((next, [...chain, next.path]));
      }
    }
  }
  return violations;
}

void main() {
  group('detector self-check', () {
    test('finds banned imports in any quoting / combinator form', () {
      const source = '''
import 'dart:ui';
import "package:flutter/widgets.dart" show Widget;
  import 'package:flutter/material.dart' as m;
// import 'package:flutter/cupertino.dart';
export 'package:flutter/cupertino.dart';
''';
      final banned = directivesIn(source).where(_bannedImports.contains);
      expect(banned, [
        'package:flutter/widgets.dart',
        'package:flutter/material.dart',
        'package:flutter/cupertino.dart', // the export, not the comment
      ]);
    });
  });

  test('engine does not import Flutter widget libraries (transitively)', () {
    final engineFiles = Directory(_engineDir)
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();

    expect(engineFiles, isNotEmpty, reason: 'engine dir must not be empty');
    expect(findViolations(engineFiles), isEmpty);
  });
}
