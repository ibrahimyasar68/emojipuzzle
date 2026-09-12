import 'package:emoji_puzzle_kids/features/puzzle/models/drag_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DragState', () {
    const drag = DragState(
      pieceId: 3,
      grabOffset: Offset(20, 8),
      pointerBoardLocal: Offset(120, 90),
      fromScale: 0.5,
    );

    test('the piece hangs off the grab point, not the finger centre (§9)', () {
      expect(drag.pieceOriginBoardLocal, const Offset(100, 82));
    });

    test('moving keeps the grab offset, so the piece never jumps', () {
      final moved = drag.movedTo(const Offset(300, 210));

      expect(moved.grabOffset, drag.grabOffset);
      expect(moved.pieceId, drag.pieceId);
      expect(moved.fromScale, drag.fromScale);
      expect(moved.pieceOriginBoardLocal, const Offset(280, 202));
      // The piece moved by exactly what the finger moved.
      expect(
        moved.pieceOriginBoardLocal - drag.pieceOriginBoardLocal,
        moved.pointerBoardLocal - drag.pointerBoardLocal,
      );
    });

    test('value equality', () {
      expect(drag.movedTo(const Offset(120, 90)), drag);
      expect(drag.movedTo(const Offset(121, 90)), isNot(drag));
    });
  });
}
