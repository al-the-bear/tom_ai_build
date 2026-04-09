/// Marks a field as the key used for registry access and for-each matching.
///
/// Applied to `String?` fields. When a class participates in a `@ForEach`
/// relationship, this annotation identifies which field provides the key value
/// for matching against registry entries.
class AccessKey {
  final String key;

  const AccessKey(this.key);
}
