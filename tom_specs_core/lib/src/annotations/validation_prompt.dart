/// Provides an AI validation prompt for the section content.
///
/// Applied to model classes. The prompt is used by AI-assisted validators to
/// check that the section content meets domain-specific quality criteria.
class ValidationPrompt {
  /// The prompt handed to the AI validator, phrased as the criterion the
  /// content has to meet.
  ///
  /// It is judged against the section's own content, so it must carry whatever
  /// context the judgement needs rather than assuming the surrounding
  /// document.
  final String prompt;

  /// Declares [prompt] as the AI validation criterion for the annotated class.
  const ValidationPrompt(this.prompt);
}
