/// Limits the maximum nesting depth of subsections within this section type.
///
/// Applied to model classes. A value of 0 means no subsections are allowed;
/// 1 means direct children only; etc.
class MaxDepth {
  final int levels;

  const MaxDepth(this.levels);
}
