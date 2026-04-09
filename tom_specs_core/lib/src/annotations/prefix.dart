/// Declares the section-type prefix used for two-stage ID matching.
///
/// Applied to model classes. When the DocSpecs schema resolver encounters a
/// section heading, it first matches the prefix (case-insensitive, YAML
/// declaration order, first match wins) to determine the section type, then
/// validates the full ID with [@PatternCheckId] if present.
class Prefix {
  final String prefix;

  const Prefix(this.prefix);
}
