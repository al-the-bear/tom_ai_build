/// Declares the section ID pattern for items in a `List<T>` field.
///
/// Applied to list fields. The pattern uses a suffix (e.g., `-xx`) indicating
/// each list item gets a unique numbered section in the target document.
///
/// This implies a section level: the field is a section, each list item is a
/// subsection.
///
/// Example: `@SectionIdPattern('ACCH-ITEM-xxx')` → first item is
/// ACCH-ITEM-001, second ACCH-ITEM-002, etc.
class SectionIdPattern {
  final String pattern;

  const SectionIdPattern(this.pattern);
}
