/// Declares a bidirectional "for-each" constraint between a list field and a
/// registry section type.
///
/// Applied to `List<T>` fields. For every entry registered under
/// [registryType], there must be a corresponding item in this list (matched
/// by [key]), and vice versa.
///
/// [registryType] names the registry by its **section id** — the model's own
/// vocabulary — which the DocSpecs generator lower-cases to the section-type
/// name. The registry must be reachable from the same document root;
/// a `@ForEach` that names one which is not fails schema generation rather
/// than emitting a link that validates nothing.
///
/// Emitted as `for-each` on the list's `document: sections:` entry. Only
/// top-level sections have such an entry, so a for-each on a deeper list has
/// no DocSpecs representation.
class ForEach {
  final String registryType;
  final String key;

  const ForEach(this.registryType, this.key);
}
