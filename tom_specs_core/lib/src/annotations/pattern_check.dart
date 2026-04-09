/// Declares a regex pattern that a field value must match.
///
/// Applied to `String?` fields. Used for validating field content format
/// (e.g., date patterns, identifier formats).
class PatternCheck {
  final String pattern;
  final String? errorMessage;

  const PatternCheck(this.pattern, {this.errorMessage});
}
