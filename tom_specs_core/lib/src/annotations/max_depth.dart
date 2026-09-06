/// Limits the maximum nesting depth of subsections within this section type.
///
/// Applied to model classes. A value of 0 means no subsections are allowed;
/// 1 means direct children only; etc.
class MaxDepth {
  /// The deepest subsection nesting admitted below this section type.
  ///
  /// `0` forbids subsections outright; `1` admits direct children only.
  final int levels;

  /// Caps subsection nesting below the annotated class at [levels].
  const MaxDepth(this.levels);
}
