/// Declares the maximum number of items allowed in a list field.
///
/// Applied to `List<T>` fields. If omitted, there is no upper limit (∞).
///
/// In the outline, shown as part of the `(min,max)-:` prefix on list lines.
class Max {
  final int count;

  const Max(this.count);
}
