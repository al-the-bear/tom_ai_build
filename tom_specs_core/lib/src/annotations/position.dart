/// Declares the ordering position of a subsection field within its parent.
///
/// Applied to singular or list fields that represent subsections.
///
/// The default position (no annotation) is **relative** — sections appear in
/// the order they are declared in the class.
///
/// Values:
/// - `'first'` — must appear before all other subsections.
/// - `'last'` — must appear after all other subsections.
/// - `'any'` — may appear in any position regardless of declaration order.
///
/// Emitted as `position` in the DocSpecs `subsection-declarations` block,
/// which is keyed by document-section name — so a position binds one level
/// below the root and deeper ordering stays declaration order.
class Position {
  /// The ordering constraint: `'first'`, `'last'` or `'any'`.
  ///
  /// No other value is meaningful; omitting the annotation altogether is what
  /// selects the default, which is declaration order.
  final String position;

  /// Fixes the annotated subsection's ordering to [position].
  const Position(this.position);
}
