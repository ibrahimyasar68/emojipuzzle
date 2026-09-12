import 'dart:math' show min;
import 'dart:ui' show Rect, Size;

import '../../../../core/constants/puzzle_config.dart';

/// A tray arrangement: how many rows and columns, and how big each piece is.
class TrayLayout {
  const TrayLayout({
    required this.traySize,
    required this.rows,
    required this.columns,
    required this.itemSize,
    required this.spacing,
    required this.meetsTouchTarget,
  });

  final Size traySize;
  final int rows;
  final int columns;
  final Size itemSize;
  final double spacing;

  /// Whether every item clears [PuzzleConfig.minTouchTargetSize] (§2).
  final bool meetsTouchTarget;

  int get slotCount => rows * columns;

  /// Where a slot sits inside the tray. Slots are row-major and fixed for
  /// the whole puzzle (§16.2).
  Rect slotRect(int slotIndex) {
    assert(
      slotIndex >= 0 && slotIndex < slotCount,
      'slot $slotIndex out of range 0..${slotCount - 1}',
    );
    final row = slotIndex ~/ columns;
    final column = slotIndex % columns;

    final contentWidth = columns * itemSize.width + (columns - 1) * spacing;
    final contentHeight = rows * itemSize.height + (rows - 1) * spacing;

    return Rect.fromLTWH(
      (traySize.width - contentWidth) / 2 + column * (itemSize.width + spacing),
      (traySize.height - contentHeight) / 2 + row * (itemSize.height + spacing),
      itemSize.width,
      itemSize.height,
    );
  }

  @override
  String toString() => 'TrayLayout(${rows}x$columns, item $itemSize)';
}

/// Fits the pieces into the tray without scrolling (§16.1).
///
/// The piece size is derived, never fixed: a constant scale would break the
/// 64 px touch target on a small phone, and the touch target is the rule
/// that does not bend.
abstract final class TrayLayoutCalculator {
  static TrayLayout calculate({
    required Size traySize,
    required int pieceCount,
    required Size boardPieceSize,
    double spacing = PuzzleConfig.trayItemSpacing,
    double minTouchTarget = PuzzleConfig.minTouchTargetSize,
    double preferredScale = PuzzleConfig.trayPreferredPieceScale,
  }) {
    assert(pieceCount > 0, 'pieceCount must be positive');
    assert(!boardPieceSize.isEmpty, 'boardPieceSize must be non-empty');

    final aspectRatio = boardPieceSize.width / boardPieceSize.height;

    TrayLayout? best;
    var bestDistance = double.infinity;
    // Ascending rows, so the first candidate is also the flattest one.
    TrayLayout? fewestRows;

    for (var rows = 1; rows <= pieceCount; rows++) {
      final columns = (pieceCount / rows).ceil();
      final widthCap = (traySize.width - (columns - 1) * spacing) / columns;
      final heightCap = (traySize.height - (rows - 1) * spacing) / rows;
      if (widthCap <= 0 || heightCap <= 0) continue;

      final itemWidth = min(widthCap, heightCap * aspectRatio);
      final itemHeight = itemWidth / aspectRatio;

      final candidate = TrayLayout(
        traySize: traySize,
        rows: rows,
        columns: columns,
        itemSize: Size(itemWidth, itemHeight),
        spacing: spacing,
        // §16.1 only names the width; a piece taller than it is wide would
        // otherwise sneak under the target on its other axis.
        meetsTouchTarget:
            itemWidth >= minTouchTarget && itemHeight >= minTouchTarget,
      );
      fewestRows ??= candidate;
      if (!candidate.meetsTouchTarget) continue;

      final distance =
          (itemWidth / boardPieceSize.width - preferredScale).abs();
      if (distance < bestDistance) {
        bestDistance = distance;
        best = candidate;
      }
    }

    assert(
      best != null,
      'no tray layout keeps $pieceCount pieces at ${minTouchTarget}px in '
      '$traySize — this grid cannot be played on this screen (§2, §16.1)',
    );

    // Release builds must still show something, so fall back to the
    // flattest arrangement rather than crashing a child's game.
    final result = best ?? fewestRows;
    if (result == null) {
      throw StateError('tray $traySize is too small for any layout');
    }
    return result;
  }
}
