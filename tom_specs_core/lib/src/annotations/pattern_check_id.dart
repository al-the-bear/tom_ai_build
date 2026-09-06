/// Declares a regex pattern that section IDs must match after prefix resolution.
///
/// Applied to model classes. This is stage two of the two-stage ID matching:
/// first the [Prefix] annotation resolves the section type, then this pattern
/// validates the full ID format.
class PatternCheckId {
  /// The regular expression a section id must match, in Dart `RegExp` syntax.
  ///
  /// Applied unanchored, like [PatternCheck.pattern] — anchor it explicitly
  /// when the whole id has to match. An explicit `@PatternCheckId` is the
  /// author's own id-format rule and **wins over** the check the schema
  /// generator would otherwise derive from a list's `@SectionIdPattern`.
  final String pattern;

  /// The message reported when an id does not match.
  ///
  /// When null the validator falls back to a generated message quoting the
  /// regex.
  final String? errorMessage;

  /// Requires ids of the annotated section type to match [pattern].
  const PatternCheckId(this.pattern, {this.errorMessage});
}
