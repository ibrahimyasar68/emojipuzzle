/// Bir yapboz parçasının tek bir kenarının biçimi (§11).
enum EdgeType {
  /// Düz kenar. Yalnızca board'un dış sınırında bulunur.
  flat,

  /// Hücrenin dışına taşan tırnak.
  tab,

  /// Hücrenin içine oyulmuş yuva.
  blank;

  /// Komşunun ortak kenarda taşıması gereken kenar tipi.
  ///
  /// `tab ↔ blank`, `flat` ise `flat` kalır (§11, kural 6).
  EdgeType get complement => switch (this) {
        EdgeType.flat => EdgeType.flat,
        EdgeType.tab => EdgeType.blank,
        EdgeType.blank => EdgeType.tab,
      };
}
