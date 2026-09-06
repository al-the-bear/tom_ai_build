/// The key a section is reached by in the DocSpecs access API.
///
/// Applied to a section field. Without it a section is addressed by its
/// section-type name; with it, by [key] — which is also the value a
/// [ForEach] on the corresponding registry matches against.
///
/// Emitted as `access-key` on the section's `document: sections:` entry. Only
/// top-level sections have such an entry, so an access key on a deeper
/// section has no DocSpecs representation.
class AccessKey {
  /// The key the section is addressed by.
  ///
  /// Compared literally, never resolved: a `@ForEach` naming this registry
  /// matches its entries on the same string, so a key changed here and not
  /// there silently stops pairing rather than failing to resolve.
  final String key;

  /// Declares [key] as the annotated section's access key.
  const AccessKey(this.key);
}
