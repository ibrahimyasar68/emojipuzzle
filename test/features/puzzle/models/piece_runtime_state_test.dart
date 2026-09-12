import 'package:emoji_puzzle_kids/features/puzzle/models/piece_runtime_state.dart';
import 'package:emoji_puzzle_kids/features/puzzle/models/piece_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PieceRuntimeState', () {
    test('starts in the tray with a clean slate', () {
      const state = PieceRuntimeState(pieceId: 2, traySlotIndex: 5);

      expect(state.status, PieceStatus.inTray);
      expect(state.dragOffset, isNull);
      expect(state.failedAttempts, 0);
    });

    test('copyWith touches only what it is given', () {
      const state = PieceRuntimeState(
        pieceId: 2,
        traySlotIndex: 5,
        failedAttempts: 2,
      );

      final dragged = state.copyWith(
        status: PieceStatus.dragging,
        dragOffset: const Offset(12, 34),
      );

      expect(dragged.pieceId, 2);
      expect(dragged.traySlotIndex, 5, reason: 'the slot never moves (§16.2)');
      expect(dragged.failedAttempts, 2);
      expect(dragged.status, PieceStatus.dragging);
      expect(dragged.dragOffset, const Offset(12, 34));
    });

    test('clearDragOffset wins over keeping the old value', () {
      const state = PieceRuntimeState(
        pieceId: 0,
        traySlotIndex: 0,
        status: PieceStatus.dragging,
        dragOffset: Offset(5, 5),
      );

      expect(state.copyWith().dragOffset, const Offset(5, 5));
      expect(state.copyWith(clearDragOffset: true).dragOffset, isNull);
    });

    test('value equality', () {
      const a = PieceRuntimeState(pieceId: 1, traySlotIndex: 3);
      const b = PieceRuntimeState(pieceId: 1, traySlotIndex: 3);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(a.copyWith(failedAttempts: 1)));
    });

    test('rejects nonsense', () {
      int negative() => -1;
      expect(
        () => PieceRuntimeState(pieceId: negative(), traySlotIndex: 0),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => PieceRuntimeState(pieceId: 0, traySlotIndex: negative()),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
