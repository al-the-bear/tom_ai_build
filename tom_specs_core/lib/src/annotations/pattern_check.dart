/// Declares a regex pattern that a field value must match.
///
/// Applied to `String?` fields. Used for validating field content format
/// (e.g., date patterns, identifier formats).
class PatternCheck {
  /// The regular expression the value must match, in Dart `RegExp` syntax.
  ///
  /// Applied **unanchored** (`RegExp(pattern).hasMatch(value)`), so a pattern
  /// that is meant to describe the whole value has to say so with `^` and `$`
  /// — without them a value that merely *contains* a match passes.
  final String pattern;

  /// The message reported when the value does not match.
  ///
  /// When null the validator falls back to a generated message that quotes the
  /// regex. That names the rule but not its intent, so supply this wherever
  /// the pattern is not self-explanatory to the author who has to satisfy it.
  final String? errorMessage;

  /// Requires the annotated field's value to match [pattern].
  const PatternCheck(this.pattern, {this.errorMessage});
}
