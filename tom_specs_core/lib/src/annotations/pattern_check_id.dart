/// Declares a regex pattern that section IDs must match after prefix resolution.
///
/// Applied to model classes. This is stage two of the two-stage ID matching:
/// first the [@Prefix] resolves the section type, then this pattern validates
/// the full ID format.
class PatternCheckId {
  final String pattern;
  final String? errorMessage;

  const PatternCheckId(this.pattern, {this.errorMessage});
}
