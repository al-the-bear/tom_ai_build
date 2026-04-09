/// Declares the minimum number of items required in a list field.
///
/// Applied to `List<T>` fields. A value of 1 means at least one item is
/// required. If omitted, the default minimum is 0.
///
/// In the outline, shown as part of the `(min,max)-:` prefix on list lines.
class Min {
  final int count;

  const Min(this.count);
}
