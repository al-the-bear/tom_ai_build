/// Declares the minimum number of items required in a list field.
///
/// Applied to `List<T>` fields. A value of 1 means at least one item is
/// required. If omitted, the default minimum is 0.
///
/// In the outline, shown as part of the `(min,max)-:` prefix on list lines.
class Min {
  /// The inclusive lower bound on the list's item count.
  ///
  /// `1` makes the list mandatory. Absent the annotation the bound is `0`.
  final int count;

  /// Requires the annotated list to hold at least [count] items.
  const Min(this.count);
}
