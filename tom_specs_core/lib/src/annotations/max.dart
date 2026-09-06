/// Declares the maximum number of items allowed in a list field.
///
/// Applied to `List<T>` fields. If omitted, there is no upper limit (∞).
///
/// In the outline, shown as part of the `(min,max)-:` prefix on list lines.
class Max {
  /// The inclusive upper bound on the list's item count.
  final int count;

  /// Caps the annotated list at [count] items.
  const Max(this.count);
}
