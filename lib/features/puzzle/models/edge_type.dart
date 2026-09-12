/// Shape of one side of a jigsaw piece (§11).
enum EdgeType {
  /// Straight side. Only on the outer border of the board.
  flat,

  /// Knob that sticks out of the cell.
  tab,

  /// Socket cut into the cell.
  blank;

  /// The edge a neighbour must have on the shared side.
  ///
  /// `tab ↔ blank`, and `flat` stays `flat` (§11 rule 6).
  EdgeType get complement => switch (this) {
        EdgeType.flat => EdgeType.flat,
        EdgeType.tab => EdgeType.blank,
        EdgeType.blank => EdgeType.tab,
      };
}
