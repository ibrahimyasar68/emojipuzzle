import 'package:emoji_puzzle_kids/features/puzzle/models/edge_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EdgeType.complement', () {
    test('flat.complement == flat', () {
      expect(EdgeType.flat.complement, EdgeType.flat);
    });

    test('tab ↔ blank', () {
      expect(EdgeType.tab.complement, EdgeType.blank);
      expect(EdgeType.blank.complement, EdgeType.tab);
    });

    test('complement is an involution', () {
      for (final edge in EdgeType.values) {
        expect(edge.complement.complement, edge);
      }
    });
  });
}
