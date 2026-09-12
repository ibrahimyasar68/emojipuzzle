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

    // A tray is a shelf: it is looked along, not down. Arrangements at
    // least as wide as they are tall are considered first, and the rest
    // only if none of those can hold the pieces at full size.
    //
    // Without this a tall tray — a tablet, where the board stops at 500 px
    // and everything below it is spare — produces a single column of
    // pieces running down the middle of the screen. Every piece is still
    // big enough to hit, so nothing fails; it simply stops looking like a
    // tray (§16.1, §40).
    //
    // The margin around the outside is the first thing given up when space
    // runs short — a phone held sideways with nine pieces has none to
    // spare — and the shelf shape is the second. The touch target is never
    // given up (§2).
    for (final (shelvesOnly, outerMargin) in const [
      (true, true),
      (true, false),
      (false, true),
      (false, false),
    ]) {
      final layout = _bestFit(
        traySize: traySize,
        pieceCount: pieceCount,
        boardPieceSize: boardPieceSize,
        aspectRatio: aspectRatio,
        spacing: spacing,
        minTouchTarget: minTouchTarget,
        preferredScale: preferredScale,
        shelvesOnly: shelvesOnly,
        outerMargin: outerMargin,
      );
      if (layout != null) return layout;
    }

    return _fallback(
      traySize: traySize,
      pieceCount: pieceCount,
      aspectRatio: aspectRatio,
      spacing: spacing,
      minTouchTarget: minTouchTarget,
    );
  }

  /// The arrangement whose pieces land closest to [preferredScale], or null
  /// when none of them keeps every piece above the touch target.
  static TrayLayout? _bestFit({
    required Size traySize,
    required int pieceCount,
    required Size boardPieceSize,
    required double aspectRatio,
    required double spacing,
    required double minTouchTarget,
    required double preferredScale,
    required bool shelvesOnly,
    required bool outerMargin,
  }) {
    final edges = outerMargin ? 1 : -1;
    TrayLayout? best;
    var bestDistance = double.infinity;

    for (var rows = 1; rows <= pieceCount; rows++) {
      final columns = (pieceCount / rows).ceil();
      // The gap is counted on the outside edges as well, not only between
      // pieces: a tray whose content is exactly as wide as the tray leaves
      // the outermost pieces flush against the screen, where a jigsaw tab
      // has nowhere to stick out (§16.1).
      final widthCap = (traySize.width - (columns + edges) * spacing) / columns;
      final heightCap = (traySize.height - (rows + edges) * spacing) / rows;
      if (widthCap <= 0 || heightCap <= 0) continue;

      final itemWidth = min(widthCap, heightCap * aspectRatio);
      final itemHeight = itemWidth / aspectRatio;

      if (shelvesOnly && columns < rows) continue;

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
      if (!candidate.meetsTouchTarget) continue;

      final distance =
          (itemWidth / boardPieceSize.width - preferredScale).abs();
      if (distance < bestDistance) {
        bestDistance = distance;
        best = candidate;
      }
    }

    return best;
  }

  /// Nothing fits at full size. Release builds must still show something,
  /// so the flattest arrangement is used rather than crashing a child's
  /// game; debug builds say so first.
  static TrayLayout _fallback({
    required Size traySize,
    required int pieceCount,
    required double aspectRatio,
    required double spacing,
    required double minTouchTarget,
  }) {
    assert(
      false,
      'no tray layout keeps $pieceCount pieces at ${minTouchTarget}px in '
      '$traySize — this grid cannot be played on this screen (§2, §16.1)',
    );

    for (var rows = 1; rows <= pieceCount; rows++) {
      final columns = (pieceCount / rows).ceil();
      final widthCap = (traySize.width - (columns + 1) * spacing) / columns;
      final heightCap = (traySize.height - (rows + 1) * spacing) / rows;
      if (widthCap <= 0 || heightCap <= 0) continue;

      final itemWidth = min(widthCap, heightCap * aspectRatio);
      return TrayLayout(
        traySize: traySize,
        rows: rows,
        columns: columns,
        itemSize: Size(itemWidth, itemWidth / aspectRatio),
        spacing: spacing,
        meetsTouchTarget: false,
      );
    }
    throw StateError('tray $traySize is too small for any layout');
  }
}
