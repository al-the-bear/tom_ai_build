/// Declares a bidirectional "for-each" constraint between a list field and a
/// registry section type.
///
/// Applied to `List<T>` fields. For every entry registered under
/// [registryType], there must be a corresponding item in this list (matched
/// by [key]), and vice versa.
class ForEach {
  final String registryType;
  final String key;

  const ForEach(this.registryType, this.key);
}
