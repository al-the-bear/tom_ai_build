/// Declares the section-type prefix used for two-stage ID matching.
///
/// Applied to model classes. When the DocSpecs schema resolver encounters a
/// section heading, it first matches the prefix (case-insensitive, YAML
/// declaration order, first match wins) to determine the section type, then
/// validates the full ID with the [PatternCheckId] annotation if present.
class Prefix {
  /// The heading prefix that identifies this section type.
  ///
  /// Matched case-insensitively, in YAML declaration order, first match wins —
  /// so a prefix that is itself a prefix of another one shadows it unless the
  /// longer of the two is declared first.
  final String prefix;

  /// Declares [prefix] as the annotated type's heading prefix.
  const Prefix(this.prefix);
}
